import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Thought extends Equatable {
  final String id;
  final String encryptedContent;
  final String iv; 
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final String? assistantMode; 
  final Map<String, dynamic>? metadata; 

  const Thought({
    required this.id,
    required this.encryptedContent,
    required this.iv,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    this.assistantMode,
    this.metadata,
  });

  factory Thought.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Thought(
      id: doc.id,
      encryptedContent: data['encryptedContent'] as String,
      iv: data['iv'] as String? ?? '', 
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      userId: data['userId'] as String,
      assistantMode: data['assistantMode'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'encryptedContent': encryptedContent,
      'iv': iv,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userId': userId,
      'assistantMode': assistantMode,
      'metadata': metadata,
    };
  }

  Thought copyWith({
    String? id,
    String? encryptedContent,
    String? iv,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    String? assistantMode,
    Map<String, dynamic>? metadata,
  }) {
    return Thought(
      id: id ?? this.id,
      encryptedContent: encryptedContent ?? this.encryptedContent,
      iv: iv ?? this.iv,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      assistantMode: assistantMode ?? this.assistantMode,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        encryptedContent,
        iv,
        createdAt,
        updatedAt,
        userId,
        assistantMode,
        metadata,
      ];
} 