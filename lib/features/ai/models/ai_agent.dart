import 'package:equatable/equatable.dart';

enum AIAgentType {
  reflective,
  analytical,
  creative,
}

class AIAgent extends Equatable {
  final AIAgentType type;
  final String name;
  final String description;
  final String systemPrompt;

  const AIAgent({
    required this.type,
    required this.name,
    required this.description,
    required this.systemPrompt,
  });

  static const List<AIAgent> availableAgents = [
    AIAgent(
      type: AIAgentType.reflective,
      name: 'Reflective Sage',
      description: 'Helps you reflect deeply on your thoughts and experiences',
      systemPrompt: 'You are a supportive and insightful journal assistant. When I share my thoughts, please reflect on them and offer a fresh perspective or a gentle inquiry to help me explore further. Focus on my feelings and experiences. Your responses should be in plain text only, with no special formatting. Please limit your responses to a maximum of 80 words. Avoid lists or bullet points. Just provide a continuous, thoughtful response.',
    ),
    AIAgent(
      type: AIAgentType.analytical,
      name: 'Analytical Mind',
      description: 'Provides logical analysis and structured thinking',
      systemPrompt: 'You are an analytical AI that helps users break down complex thoughts and situations logically. Provide clear, structured insights.',
    ),
    AIAgent(
      type: AIAgentType.creative,
      name: 'Creative Spark',
      description: 'Inspires creative thinking and new perspectives',
      systemPrompt: 'You are a creative AI that helps users explore new ideas and perspectives. Encourage innovative thinking and creative solutions.',
    ),
  ];

  static AIAgent getByType(AIAgentType type) {
    return availableAgents.firstWhere((agent) => agent.type == type);
  }

  @override
  List<Object?> get props => [type, name, description, systemPrompt];
} 