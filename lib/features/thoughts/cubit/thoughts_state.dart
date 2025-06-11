import 'package:equatable/equatable.dart';
import '../models/thought.dart';

abstract class ThoughtsState extends Equatable {
  const ThoughtsState();

  @override
  List<Object?> get props => [];
}

class ThoughtsInitial extends ThoughtsState {}

class ThoughtsLoading extends ThoughtsState {}

class ThoughtsLoaded extends ThoughtsState {
  final List<Thought> thoughts;

  const ThoughtsLoaded(this.thoughts);

  @override
  List<Object?> get props => [thoughts];
}

class ThoughtSaving extends ThoughtsState {}

class ThoughtSaved extends ThoughtsState {
  final Thought thought;

  const ThoughtSaved(this.thought);

  @override
  List<Object?> get props => [thought];
}

class ThoughtsError extends ThoughtsState {
  final String message;

  const ThoughtsError(this.message);

  @override
  List<Object?> get props => [message];
} 