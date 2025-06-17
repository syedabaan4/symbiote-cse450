import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/thread.dart';
import '../models/thought.dart';
import '../services/encryption_service.dart';
import '../../ai/models/ai_agent.dart';
import 'threads_state.dart';

class ThreadsCubit extends Cubit<ThreadsState> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final EncryptionService _encryptionService;

  ThreadsCubit({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    EncryptionService? encryptionService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _encryptionService = encryptionService ?? EncryptionService(),
        super(ThreadsInitial());

  Future<void> loadThreads() async {
    try {
      emit(ThreadsLoading());
      
      final user = _auth.currentUser;
      if (user == null) {
        emit(const ThreadsError('User not authenticated'));
        return;
      }

      await _encryptionService.initialize(user);

      final snapshot = await _firestore
          .collection('threads')
          .where('userId', isEqualTo: user.uid)
          .orderBy('updatedAt', descending: true)
          .get();

      final threads = snapshot.docs
          .map((doc) => Thread.fromFirestore(doc))
          .toList();

      emit(ThreadsLoaded(threads));
    } catch (e) {
      emit(ThreadsError('Failed to load threads: ${e.toString()}'));
    }
  }

  Future<Thread?> createThreadWithThought(String content, {String? assistantMode, AIAgentType? aiAgentType}) async {
    if (content.trim().isEmpty) return null;
    
    try {
      emit(ThreadCreating());
      
      final user = _auth.currentUser;
      if (user == null) {
        emit(const ThreadsError('User not authenticated'));
        return null;
      }

      await _encryptionService.initialize(user);
      final encrypted = _encryptionService.encryptText(content);

      // Create thread
      final threadId = _firestore.collection('threads').doc().id;
      final thread = Thread(
        id: threadId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: user.uid,
        aiAgentType: aiAgentType,
      );

      // Create first thought
      final thoughtId = _firestore.collection('thoughts').doc().id;
      final thought = Thought(
        id: thoughtId,
        threadId: threadId,
        encryptedContent: encrypted['encryptedContent']!,
        iv: encrypted['iv']!,
        createdAt: DateTime.now(),
        userId: user.uid,
        assistantMode: assistantMode,
      );

      // Use a batch to ensure both are created together
      final batch = _firestore.batch();
      batch.set(_firestore.collection('threads').doc(threadId), thread.toFirestore());
      batch.set(_firestore.collection('thoughts').doc(thoughtId), thought.toFirestore());
      await batch.commit();

      emit(ThreadCreated(thread));
      return thread;
    } catch (e) {
      emit(ThreadsError('Failed to create thread: ${e.toString()}'));
      return null;
    }
  }

  Future<void> deleteThread(String threadId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        emit(const ThreadsError('User not authenticated'));
        return;
      }

      // Delete all thoughts in the thread first
      final thoughtsSnapshot = await _firestore
          .collection('thoughts')
          .where('threadId', isEqualTo: threadId)
          .where('userId', isEqualTo: user.uid)
          .get();

      final batch = _firestore.batch();
      
      // Delete all thoughts
      for (final doc in thoughtsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete the thread
      batch.delete(_firestore.collection('threads').doc(threadId));
      
      await batch.commit();

      emit(ThreadDeleted(threadId));
    } catch (e) {
      emit(ThreadsError('Failed to delete thread: ${e.toString()}'));
    }
  }

  Future<String> getLatestThoughtContent(String threadId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'No content available';

      // Initialize encryption service (has its own check for already initialized)
      await _encryptionService.initialize(user);

      final thoughtsSnapshot = await _firestore
          .collection('thoughts')
          .where('threadId', isEqualTo: threadId)
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (thoughtsSnapshot.docs.isEmpty) {
        return 'No content available';
      }

      final latestThought = thoughtsSnapshot.docs.first;
      final thoughtData = latestThought.data();
      
      if (thoughtData['encryptedContent'] != null && thoughtData['iv'] != null) {
        try {
          final decryptedContent = _encryptionService.decryptText(
            thoughtData['encryptedContent'] as String,
            thoughtData['iv'] as String,
          );
          
          // Truncate to first 100 characters for preview
          if (decryptedContent.length > 100) {
            return '${decryptedContent.substring(0, 100)}...';
          }
          return decryptedContent;
        } catch (decryptionError) {
          return 'Unable to decrypt content';
        }
      }
      
      return 'Content not available';
    } catch (e) {
      return 'Preview not available';
    }
  }
} 