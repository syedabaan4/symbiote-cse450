import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class Mood extends Equatable {
  final String id;
  final int value; // 1-5 scale (1 = very sad, 5 = very happy)
  final DateTime date; // Store only the date (not timestamp)
  final String userId;

  const Mood({
    required this.id,
    required this.value,
    required this.date,
    required this.userId,
  });

  factory Mood.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Mood(
      id: doc.id,
      value: data['value'] as int,
      date: (data['date'] as Timestamp).toDate(),
      userId: data['userId'] as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'value': value,
      'date': Timestamp.fromDate(date),
      'userId': userId,
    };
  }

  // Helper method to get mood emoji based on value
  String get emoji {
    switch (value) {
      case 1:
        return '😢';
      case 2:
        return '😞';
      case 3:
        return '😐';
      case 4:
        return '😊';
      case 5:
        return '😄';
      default:
        return '😐';
    }
  }

  // Helper method to get mood label
  String get label {
    switch (value) {
      case 1:
        return 'Very Bad';
      case 2:
        return 'Bad';
      case 3:
        return 'Okay';
      case 4:
        return 'Good';
      case 5:
        return 'Great';
      default:
        return 'Okay';
    }
  }

  // Helper method to get mood color for heatmap
  Color get color {
    switch (value) {
      case 1:
        return Colors.red.shade300;
      case 2:
        return Colors.orange.shade300;
      case 3:
        return Colors.yellow.shade300;
      case 4:
        return Colors.lightGreen.shade300;
      case 5:
        return Colors.green.shade400;
      default:
        return Colors.grey.shade300;
    }
  }

  @override
  List<Object?> get props => [id, value, date, userId];
} 