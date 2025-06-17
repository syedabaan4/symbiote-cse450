import 'package:flutter_test/flutter_test.dart';
import 'package:symbiote/features/moods/models/mood.dart';
import 'package:flutter/material.dart';

void main() {
  group('Mood', () {
    final now = DateTime.now();
    final mood = Mood(
      id: '1',
      value: 5,
      date: now,
      userId: 'user1',
    );

    test('supports value equality', () {
      expect(
        mood,
        equals(
          Mood(
            id: '1',
            value: 5,
            date: now,
            userId: 'user1',
          ),
        ),
      );
    });

    test('correctly identifies emoji, label, and color based on value', () {
      expect(Mood(id: '', value: 1, date: now, userId: '').emoji, '😢');
      expect(Mood(id: '', value: 2, date: now, userId: '').emoji, '😞');
      expect(Mood(id: '', value: 3, date: now, userId: '').emoji, '😐');
      expect(Mood(id: '', value: 4, date: now, userId: '').emoji, '😊');
      expect(Mood(id: '', value: 5, date: now, userId: '').emoji, '😄');
      
      expect(Mood(id: '', value: 1, date: now, userId: '').label, 'Very Bad');
      expect(Mood(id: '', value: 5, date: now, userId: '').label, 'Great');

      expect(Mood(id: '', value: 1, date: now, userId: '').color, isA<Color>());
    });
  });
} 