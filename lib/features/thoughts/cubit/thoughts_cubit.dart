import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/thought.dart';
import '../services/encryption_service.dart';
import 'thoughts_state.dart';

class ThoughtsCubit extends Cubit<ThoughtsState> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final EncryptionService _encryptionService;

  ThoughtsCubit({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    EncryptionService? encryptionService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _encryptionService = encryptionService ?? EncryptionService(),
        super(ThoughtsInitial());

  Future<void> loadThoughts() async {
    try {
      emit(ThoughtsLoading());
      
      final user = _auth.currentUser;
      if (user == null) {
        emit(const ThoughtsError('User not authenticated'));
        return;
      }

      await _encryptionService.initialize(user);

      final snapshot = await _firestore
          .collection('thoughts')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final thoughts = snapshot.docs
          .map((doc) => Thought.fromFirestore(doc))
          .toList();

      emit(ThoughtsLoaded(thoughts));
    } catch (e) {
      emit(ThoughtsError('Failed to load thoughts: ${e.toString()}'));
    }
  }

  Future<void> saveThought(String content, {String? assistantMode}) async {
    if (content.trim().isEmpty) return;
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        emit(const ThoughtsError('User not authenticated'));
        return;
      }

      await _encryptionService.initialize(user);

      final encrypted = _encryptionService.encryptText(content);

      final thoughtId = _firestore.collection('thoughts').doc().id;
      final thought = Thought(
        id: thoughtId,
        encryptedContent: encrypted['encryptedContent']!,
        iv: encrypted['iv']!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: user.uid,
        assistantMode: assistantMode,
      );

      await _firestore
          .collection('thoughts')
          .doc(thoughtId)
          .set(thought.toFirestore());

      emit(ThoughtSaved(thought));
    } catch (e) {
      emit(ThoughtsError('Failed to save thought: ${e.toString()}'));
    }
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

  Future<void> deleteThought(String thoughtId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        emit(const ThoughtsError('User not authenticated'));
        return;
      }

      await _firestore
          .collection('thoughts')
          .doc(thoughtId)
          .delete();

      emit(ThoughtDeleted(thoughtId));
    } catch (e) {
      emit(ThoughtsError('Failed to delete thought: ${e.toString()}'));
    }
  }
} 