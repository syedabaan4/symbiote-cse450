import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../thoughts/models/thread.dart';
import '../../thoughts/models/thought.dart';
import '../../thoughts/services/encryption_service.dart';
import '../models/ai_agent.dart';
import '../services/openrouter_service.dart';
import 'ai_state.dart';

class AICubit extends Cubit<AIState> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final EncryptionService _encryptionService;
  final OpenRouterService _openRouterService;

  AICubit({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    EncryptionService? encryptionService,
    OpenRouterService? openRouterService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _encryptionService = encryptionService ?? EncryptionService(),
        _openRouterService = openRouterService ?? OpenRouterService(),
        super(const AIInitial());

  Future<void> generateReflection({
    required String threadId,
    required AIAgentType agentType,
  }) async {
    try {
      emit(const AIGenerating());

      final user = _auth.currentUser;
      if (user == null) {
        emit(const AIError('User not authenticated'));
        return;
      }

      await _encryptionService.initialize(user);

      // Get thread and its thoughts
      final threadDoc = await _firestore
          .collection('threads')
          .doc(threadId)
          .get();

      if (!threadDoc.exists) {
        emit(const AIError('Thread not found'));
        return;
      }

      final thread = Thread.fromFirestore(threadDoc);

      // Get all thoughts in the thread
      final thoughtsSnapshot = await _firestore
          .collection('thoughts')
          .where('threadId', isEqualTo: threadId)
          .orderBy('createdAt', descending: false)
          .get();

      // Decrypt thoughts to build conversation history
      final conversationHistory = <String>[];
      for (final doc in thoughtsSnapshot.docs) {
        final thought = Thought.fromFirestore(doc);
        try {
          final decryptedContent = _encryptionService.decryptText(
            thought.encryptedContent,
            thought.iv,
          );
          conversationHistory.add(decryptedContent);
        } catch (e) {
          // Skip thoughts that can't be decrypted
          continue;
        }
      }

      if (conversationHistory.isEmpty) {
        emit(const AIError('No thoughts found to reflect on'));
        return;
      }

      // Get the AI agent
      final agent = AIAgent.getByType(agentType);

      // Generate AI response
      final aiResponse = await _openRouterService.generateResponse(
        agent: agent,
        conversationHistory: conversationHistory.take(conversationHistory.length - 1).toList(),
        userMessage: conversationHistory.last,
      );

      // Encrypt and save AI response as a thought
      final encrypted = _encryptionService.encryptText(aiResponse);
      
      final thoughtId = _firestore.collection('thoughts').doc().id;
      final aiThought = Thought(
        id: thoughtId,
        threadId: threadId,
        encryptedContent: encrypted['encryptedContent']!,
        iv: encrypted['iv']!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: user.uid,
        assistantMode: agentType.name, // Mark as AI-generated
      );

      // Update thread's thought count and last preview
      final updatedThread = thread.copyWith(
        thoughtCount: thread.thoughtCount + 1,
        updatedAt: DateTime.now(),
        lastThoughtPreview: encrypted['encryptedContent']!,
      );

      // Use batch to update both thread and add thought
      final batch = _firestore.batch();
      batch.set(
        _firestore.collection('thoughts').doc(thoughtId),
        aiThought.toFirestore(),
      );
      batch.update(
        _firestore.collection('threads').doc(threadId),
        updatedThread.toFirestore(),
      );
      await batch.commit();

      emit(AIResponseGenerated(response: aiResponse, threadId: threadId));
    } catch (e) {
      emit(AIError('Failed to generate reflection: $e'));
    }
  }
} 