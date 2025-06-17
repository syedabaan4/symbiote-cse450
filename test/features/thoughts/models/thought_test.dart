import 'package:flutter_test/flutter_test.dart';
import 'package:symbiote/features/thoughts/models/thought.dart';

void main() {
  group('Thought', () {
    final now = DateTime.now();
    final thought = Thought(
      id: '1',
      threadId: 'thread1',
      encryptedContent: 'encrypted',
      iv: 'iv',
      createdAt: now,
      userId: 'user1',
    );

    test('supports value equality', () {
      expect(
        thought,
        equals(
          Thought(
            id: '1',
            threadId: 'thread1',
            encryptedContent: 'encrypted',
            iv: 'iv',
            createdAt: now,
            userId: 'user1',
          ),
        ),
      );
    });

    test('copyWith creates a copy with updated values', () {
      final updatedThought = thought.copyWith(
        encryptedContent: 'new_encrypted',
        assistantMode: 'test_mode',
      );

      expect(updatedThought.id, '1');
      expect(updatedThought.encryptedContent, 'new_encrypted');
      expect(updatedThought.assistantMode, 'test_mode');
      expect(updatedThought.userId, 'user1');
    });

    test('copyWith creates a copy with no new values', () {
      final copiedThought = thought.copyWith();
      expect(copiedThought, equals(thought));
    });
  });
} 