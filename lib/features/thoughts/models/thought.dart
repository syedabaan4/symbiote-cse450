import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Thought extends Equatable {
  final String id;
  final String threadId; // Reference to the thread this thought belongs to
  final String encryptedContent;
  final String iv; 
  final DateTime createdAt;
  final String userId;
  final String? assistantMode; 

  const Thought({
    required this.id,
    required this.threadId,
    required this.encryptedContent,
    required this.iv,
    required this.createdAt,
    required this.userId,
    this.assistantMode,
  });

  factory Thought.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Thought(
      id: doc.id,
      threadId: data['threadId'] as String,
      encryptedContent: data['encryptedContent'] as String,
      iv: data['iv'] as String? ?? '', 
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      userId: data['userId'] as String,
      assistantMode: data['assistantMode'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'threadId': threadId,
      'encryptedContent': encryptedContent,
      'iv': iv,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
      'assistantMode': assistantMode,
    };
  }

  Thought copyWith({
    String? id,
    String? threadId,
    String? encryptedContent,
    String? iv,
    DateTime? createdAt,
    String? userId,
    String? assistantMode,
  }) {
    return Thought(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      encryptedContent: encryptedContent ?? this.encryptedContent,
      iv: iv ?? this.iv,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      assistantMode: assistantMode ?? this.assistantMode,
    );
  }

  @override
  List<Object?> get props => [
        id,
        threadId,
        encryptedContent,
        iv,
        createdAt,
        userId,
        assistantMode,
      ];
} 