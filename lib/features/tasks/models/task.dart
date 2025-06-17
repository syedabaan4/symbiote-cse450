import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Task extends Equatable {
  final String id;
  final String content;
  final String? category; 
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final String? sourceThreadId; 
  final String? sourceThoughtId; 
  final DateTime? reminderDateTime; 
  final int? notificationId; 

  const Task({
    required this.id,
    required this.content,
    this.category,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    this.sourceThreadId,
    this.sourceThoughtId,
    this.reminderDateTime,
    this.notificationId,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      content: data['content'] as String,
      category: data['category'] as String?,
      isCompleted: data['isCompleted'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      userId: data['userId'] as String,
      sourceThreadId: data['sourceThreadId'] as String?,
      sourceThoughtId: data['sourceThoughtId'] as String?,
      reminderDateTime: data['reminderDateTime'] != null 
          ? (data['reminderDateTime'] as Timestamp).toDate()
          : null,
      notificationId: data['notificationId'] as int?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'content': content,
      'category': category,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userId': userId,
      'sourceThreadId': sourceThreadId,
      'sourceThoughtId': sourceThoughtId,
      'reminderDateTime': reminderDateTime != null 
          ? Timestamp.fromDate(reminderDateTime!)
          : null,
      'notificationId': notificationId,
    };
  }

  Task copyWith({
    String? id,
    String? content,
    String? category,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    String? sourceThreadId,
    String? sourceThoughtId,
    DateTime? reminderDateTime,
    int? notificationId,
  }) {
    return Task(
      id: id ?? this.id,
      content: content ?? this.content,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      sourceThreadId: sourceThreadId ?? this.sourceThreadId,
      sourceThoughtId: sourceThoughtId ?? this.sourceThoughtId,
      reminderDateTime: reminderDateTime ?? this.reminderDateTime,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        content,
        category,
        isCompleted,
        createdAt,
        updatedAt,
        userId,
        sourceThreadId,
        sourceThoughtId,
        reminderDateTime,
        notificationId,
      ];
} 