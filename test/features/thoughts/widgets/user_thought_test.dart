import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symbiote/features/thoughts/widgets/user_thought.dart';

void main() {
  testWidgets('UserThought displays content and formatted time',
      (WidgetTester tester) async {
    final testContent = 'This is a test thought.';
    final testDate = DateTime.now();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UserThought(
            content: testContent,
            createdAt: testDate,
          ),
        ),
      ),
    );

    expect(find.text(testContent), findsOneWidget);
    expect(find.byType(UserThought), findsOneWidget);
  });
} 