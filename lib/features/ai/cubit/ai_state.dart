import 'package:equatable/equatable.dart';

abstract class AIState extends Equatable {
  const AIState();

  @override
  List<Object?> get props => [];
}

class AIInitial extends AIState {
  const AIInitial();
}

class AIGenerating extends AIState {
  const AIGenerating();
}

class AIResponseGenerated extends AIState {
  final String response;
  final String threadId;

  const AIResponseGenerated({
    required this.response,
    required this.threadId,
  });

  @override
  List<Object?> get props => [response, threadId];
}

class AIError extends AIState {
  final String message;

  const AIError(this.message);

  @override
  List<Object?> get props => [message];
} 