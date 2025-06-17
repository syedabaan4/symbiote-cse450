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

      
      final threadDoc = await _firestore
          .collection('threads')
          .doc(threadId)
          .get();

      if (!threadDoc.exists) {
        emit(const ThreadDetailError('Thread not found'));
        return;
      }

      final thread = Thread.fromFirestore(threadDoc);

      
      final thoughtsSnapshot = await _firestore
          .collection('thoughts')
          .where('threadId', isEqualTo: threadId)
          .orderBy('createdAt', descending: false) 
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

      
      final batch = _firestore.batch();
      
      
      batch.set(_firestore.collection('thoughts').doc(thoughtId), thought.toFirestore());
      
      
      batch.update(_firestore.collection('threads').doc(threadId), {
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      await batch.commit();

      emit(ThoughtAdded(thought));
      
      
      await loadThreadDetails(threadId);
    } catch (e) {
      emit(ThreadDetailError('Failed to add thought: ${e.toString()}'));
    }
  }

  
  void addAIThoughtOptimistically(Thought aiThought) {
    final currentState = state;
    if (currentState is ThreadDetailLoaded) {
      final updatedThoughts = [...currentState.thoughts, aiThought];
      final updatedThread = currentState.thread.copyWith(
        updatedAt: DateTime.now(),
      );
      emit(ThreadDetailLoaded(updatedThread, updatedThoughts));
    }
  }

  
  void handleAIThoughtError(String error) {
    emit(ThreadDetailError(error));
  }

  String decryptThought(Thought thought) {
    try {
      return _encryptionService.decryptText(thought.encryptedContent, thought.iv);
    } catch (e) {
      return '[Failed to decrypt thought]';
    }
  }
} 