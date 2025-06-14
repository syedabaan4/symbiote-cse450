import 'package:equatable/equatable.dart';

enum AIAgentType {
  reflective,
  analytical,
  creative,
  organize,
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
      systemPrompt: 'You are an analytical journal assistant. When I share my thoughts, please provide logical analysis and help me break down complex situations. Your responses should be in plain text only, with no special formatting. Please limit your responses to a maximum of 80 words. Avoid lists or bullet points. Just provide a continuous, analytical response.',
    ),
    AIAgent(
      type: AIAgentType.creative,
      name: 'Creative Spark',
      description: 'Inspires creative thinking and new perspectives',
      systemPrompt: 'You are a creative journal assistant. When I share my thoughts, please help me explore new ideas and creative perspectives. Your responses should be in plain text only, with no special formatting. Please limit your responses to a maximum of 80 words. Avoid lists or bullet points. Just provide a continuous, creative response.',
    ),
    AIAgent(
      type: AIAgentType.organize,
      name: 'Task Organizer',
      description: 'Converts your thoughts into actionable tasks',
      systemPrompt: 'You are a task organization assistant. Based on the user\'s journal entries, identify and extract concrete, actionable tasks. Present each task as a separate line starting with "- " (dash and space). Focus only on specific actions the user needs to take. Keep tasks concise and clear. If no actionable tasks can be identified, respond with "No specific tasks identified from this entry."',
    ),
  ];

  static AIAgent getByType(AIAgentType type) {
    return availableAgents.firstWhere((agent) => agent.type == type);
  }

  @override
  List<Object?> get props => [type, name, description, systemPrompt];
} 