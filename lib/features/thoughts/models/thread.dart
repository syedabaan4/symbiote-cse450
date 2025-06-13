import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Thread extends Equatable {
  final String id;
  final String title; // Generated from first thought or user-defined
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final int thoughtCount;
  final String? lastThoughtPreview; // Encrypted preview of last thought
  final Map<String, dynamic>? metadata;

  const Thread({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    required this.thoughtCount,
    this.lastThoughtPreview,
    this.metadata,
  });

  factory Thread.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Thread(
      id: doc.id,
      title: data['title'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      userId: data['userId'] as String,
      thoughtCount: data['thoughtCount'] as int? ?? 0,
      lastThoughtPreview: data['lastThoughtPreview'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userId': userId,
      'thoughtCount': thoughtCount,
      'lastThoughtPreview': lastThoughtPreview,
      'metadata': metadata,
    };
  }

  Thread copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    int? thoughtCount,
    String? lastThoughtPreview,
    Map<String, dynamic>? metadata,
  }) {
    return Thread(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      thoughtCount: thoughtCount ?? this.thoughtCount,
      lastThoughtPreview: lastThoughtPreview ?? this.lastThoughtPreview,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        createdAt,
        updatedAt,
        userId,
        thoughtCount,
        lastThoughtPreview,
        metadata,
      ];
} 