import 'package:equatable/equatable.dart';
import '../models/mood.dart';

abstract class MoodState extends Equatable {
  const MoodState();

  @override
  List<Object?> get props => [];
}

class MoodInitial extends MoodState {
  const MoodInitial();
}

class MoodLoading extends MoodState {
  const MoodLoading();
}

class MoodLoaded extends MoodState {
  final List<Mood> moods;

  const MoodLoaded(this.moods);

  @override
  List<Object?> get props => [moods];
}

class MoodError extends MoodState {
  final String message;

  const MoodError(this.message);

  @override
  List<Object?> get props => [message];
}

class MoodSaving extends MoodState {
  const MoodSaving();
}

class MoodSaved extends MoodState {
  final Mood mood;

  const MoodSaved(this.mood);

  @override
  List<Object?> get props => [mood];
} 