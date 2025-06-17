import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/ai_agent.dart';

class OpenRouterService {
  static const String _baseUrl = 'https://openrouter.ai/api/v1';
  static const String _model = 'deepseek/deepseek-r1-0528:free'; // Default model
  
  static final String? _apiKey = dotenv.env['API_KEY'];
  
  Future<String> generateResponse({
    required AIAgent agent,
    required List<String> conversationHistory,
    required String userMessage,
  }) async {
    try {
      final messages = _buildMessages(
        systemPrompt: agent.systemPrompt,
        conversationHistory: conversationHistory,
        userMessage: userMessage,
      );

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'symbiote-app', // Optional: for tracking
          'X-Title': 'Symbiote Journaling App', // Optional: for tracking
        },
        body: json.encode({
          'model': _model,
          'messages': messages,
          'max_tokens': 1000,
          'temperature': 0.7,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        throw Exception('API request failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to generate AI response: $e');
    }
  }

  List<Map<String, String>> _buildMessages({
    required String systemPrompt,
    required List<String> conversationHistory,
    required String userMessage,
  }) {
    final messages = <Map<String, String>>[];
    
    // Add system prompt
    messages.add({
      'role': 'system',
      'content': systemPrompt,
    });
    
    // Add conversation history
    // For simplicity, treating all history as user messages
    // In a more sophisticated setup, you might alternate between user and assistant
    for (int i = 0; i < conversationHistory.length; i++) {
      messages.add({
        'role': i % 2 == 0 ? 'user' : 'assistant',
        'content': conversationHistory[i],
      });
    }
    
    // Add current user message
    messages.add({
      'role': 'user',
      'content': userMessage,
    });
    
    return messages;
  }
} 