import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../ai/models/ai_agent.dart';

class Thread extends Equatable {
  final String id;
  final String title; // Generated from first thought or user-defined
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final AIAgentType? aiAgentType; // AI agent chosen for this thread

  const Thread({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    this.aiAgentType,
  });

  factory Thread.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Thread(
      id: doc.id,
      title: data['title'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      userId: data['userId'] as String,
      aiAgentType: data['aiAgentType'] != null 
          ? AIAgentType.values.firstWhere(
              (e) => e.name == data['aiAgentType'],
              orElse: () => AIAgentType.reflective,
            )
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userId': userId,
      'aiAgentType': aiAgentType?.name,
    };
  }

  Thread copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    AIAgentType? aiAgentType,
  }) {
    return Thread(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      aiAgentType: aiAgentType ?? this.aiAgentType,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        createdAt,
        updatedAt,
        userId,
        aiAgentType,
      ];
} 