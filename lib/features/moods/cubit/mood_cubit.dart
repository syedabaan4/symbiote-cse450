import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mood.dart';
import 'mood_state.dart';

class MoodCubit extends Cubit<MoodState> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  MoodCubit({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        super(const MoodInitial());

  Future<void> loadMoods() async {
    try {
      emit(const MoodLoading());
      
      final user = _auth.currentUser;
      if (user == null) {
        emit(const MoodError('User not authenticated'));
        return;
      }

      final snapshot = await _firestore
          .collection('moods')
          .where('userId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .get();

      final moods = snapshot.docs
          .map((doc) => Mood.fromFirestore(doc))
          .toList();

      emit(MoodLoaded(moods));
    } catch (e) {
      emit(MoodError('Failed to load moods: ${e.toString()}'));
    }
  }

  Future<bool> hasLoggedMoodToday() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('moods')
          .where('userId', isEqualTo: user.uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('date', isLessThan: Timestamp.fromDate(tomorrow))
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> saveMoodForToday(int value) async {
    try {
      emit(const MoodSaving());
      
      final user = _auth.currentUser;
      if (user == null) {
        emit(const MoodError('User not authenticated'));
        return;
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      // Check if there's already a mood for today and delete it
      final existingSnapshot = await _firestore
          .collection('moods')
          .where('userId', isEqualTo: user.uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('date', isLessThan: Timestamp.fromDate(tomorrow))
          .get();

      // Delete existing mood for today if it exists
      final batch = _firestore.batch();
      for (final doc in existingSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Create new mood entry
      final moodId = _firestore.collection('moods').doc().id;
      final mood = Mood(
        id: moodId,
        value: value,
        date: today,
        userId: user.uid,
      );

      batch.set(
        _firestore.collection('moods').doc(moodId),
        mood.toFirestore(),
      );

      await batch.commit();

      emit(MoodSaved(mood));
      
      // Reload moods to show the updated data
      await loadMoods();
    } catch (e) {
      emit(MoodError('Failed to save mood: ${e.toString()}'));
    }
  }

  // Get moods as a map for heatmap (date -> mood value)
  Map<DateTime, int> getMoodHeatmapData(List<Mood> moods) {
    final Map<DateTime, int> heatmapData = {};
    
    for (final mood in moods) {
      final date = DateTime(mood.date.year, mood.date.month, mood.date.day);
      heatmapData[date] = mood.value;
    }
    
    return heatmapData;
  }
} 