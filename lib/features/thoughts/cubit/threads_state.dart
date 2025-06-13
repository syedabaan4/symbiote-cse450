import 'package:equatable/equatable.dart';
import '../models/thread.dart';
import '../models/thought.dart';

abstract class ThreadsState extends Equatable {
  const ThreadsState();

  @override
  List<Object?> get props => [];
}

class ThreadsInitial extends ThreadsState {}

class ThreadsLoading extends ThreadsState {}

class ThreadsLoaded extends ThreadsState {
  final List<Thread> threads;

  const ThreadsLoaded(this.threads);

  @override
  List<Object?> get props => [threads];
}

class ThreadCreating extends ThreadsState {}

class ThreadCreated extends ThreadsState {
  final Thread thread;

  const ThreadCreated(this.thread);

  @override
  List<Object?> get props => [thread];
}

class ThreadDeleted extends ThreadsState {
  final String threadId;

  const ThreadDeleted(this.threadId);

  @override
  List<Object?> get props => [threadId];
}

class ThreadsError extends ThreadsState {
  final String message;

  const ThreadsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Separate state for individual thread details
abstract class ThreadDetailState extends Equatable {
  const ThreadDetailState();

  @override
  List<Object?> get props => [];
}

class ThreadDetailInitial extends ThreadDetailState {}

class ThreadDetailLoading extends ThreadDetailState {}

class ThreadDetailLoaded extends ThreadDetailState {
  final Thread thread;
  final List<Thought> thoughts;

  const ThreadDetailLoaded(this.thread, this.thoughts);

  @override
  List<Object?> get props => [thread, thoughts];
}

class ThoughtAdding extends ThreadDetailState {}

class ThoughtAdded extends ThreadDetailState {
  final Thought thought;

  const ThoughtAdded(this.thought);

  @override
  List<Object?> get props => [thought];
}

class ThreadDetailError extends ThreadDetailState {
  final String message;

  const ThreadDetailError(this.message);

  @override
  List<Object?> get props => [message];
} 