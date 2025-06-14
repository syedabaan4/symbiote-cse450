import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/thread.dart';
import '../models/thought.dart';
import '../services/encryption_service.dart';
import 'threads_state.dart';

class ThreadDetailCubit extends Cubit<ThreadDetailState> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final EncryptionService _encryptionService;

  ThreadDetailCubit({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    EncryptionService? encryptionService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _encryptionService = encryptionService ?? EncryptionService(),
        super(ThreadDetailInitial());

  Future<void> loadThreadDetails(String threadId) async {
    try {
      emit(ThreadDetailLoading());
      
      final user = _auth.currentUser;
      if (user == null) {
        emit(const ThreadDetailError('User not authenticated'));
        return;
      }

      await _encryptionService.initialize(user);

      // Load thread
      final threadDoc = await _firestore
          .collection('threads')
          .doc(threadId)
          .get();

      if (!threadDoc.exists) {
        emit(const ThreadDetailError('Thread not found'));
        return;
      }

      final thread = Thread.fromFirestore(threadDoc);

      // Load thoughts for this thread
      final thoughtsSnapshot = await _firestore
          .collection('thoughts')
          .where('threadId', isEqualTo: threadId)
          .orderBy('createdAt', descending: false) // Oldest first for conversation flow
          .get();

      final thoughts = thoughtsSnapshot.docs
          .map((doc) => Thought.fromFirestore(doc))
          .toList();

      emit(ThreadDetailLoaded(thread, thoughts));
    } catch (e) {
      emit(ThreadDetailError('Failed to load thread details: ${e.toString()}'));
    }
  }

  Future<void> addThoughtToThread(String threadId, String content, {String? assistantMode}) async {
    if (content.trim().isEmpty) return;
    
    try {
      emit(ThoughtAdding());
      
      final user = _auth.currentUser;
      if (user == null) {
        emit(const ThreadDetailError('User not authenticated'));
        return;
      }

      await _encryptionService.initialize(user);
      final encrypted = _encryptionService.encryptText(content);

      // Create new thought
      final thoughtId = _firestore.collection('thoughts').doc().id;
      final thought = Thought(
        id: thoughtId,
        threadId: threadId,
        encryptedContent: encrypted['encryptedContent']!,
        iv: encrypted['iv']!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: user.uid,
        assistantMode: assistantMode,
      );

      // Update thread with new thought count and preview
      final batch = _firestore.batch();
      
      // Add the thought
      batch.set(_firestore.collection('thoughts').doc(thoughtId), thought.toFirestore());
      
      // Update thread
      batch.update(_firestore.collection('threads').doc(threadId), {
        'thoughtCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'lastThoughtPreview': encrypted['encryptedContent']!,
      });

      await batch.commit();

      emit(ThoughtAdded(thought));
      
      // Reload the thread details to get updated data
      await loadThreadDetails(threadId);
    } catch (e) {
      emit(ThreadDetailError('Failed to add thought: ${e.toString()}'));
    }
  }

  // Method for AI cubit to add AI responses optimistically
  void addAIThoughtOptimistically(Thought aiThought) {
    final currentState = state;
    if (currentState is ThreadDetailLoaded) {
      final updatedThoughts = [...currentState.thoughts, aiThought];
      final updatedThread = currentState.thread.copyWith(
        thoughtCount: currentState.thread.thoughtCount + 1,
        updatedAt: DateTime.now(),
      );
      emit(ThreadDetailLoaded(updatedThread, updatedThoughts));
    }
  }

  // Method to handle AI thought save failure
  void handleAIThoughtError(String error) {
    emit(ThreadDetailError(error));
  }

  String decryptThought(Thought thought) {
    try {
      if (thought.iv.isEmpty) {
        return '[This thought cannot be decrypted - created with older version]';
      }
      return _encryptionService.decryptText(thought.encryptedContent, thought.iv);
    } catch (e) {
      return '[Failed to decrypt thought]';
    }
  }

  String decryptThreadTitle(Thread thread) {
    try {
      return thread.title; // Thread titles are stored in plain text for now
    } catch (e) {
      return 'Untitled Thread';
    }
  }
} 