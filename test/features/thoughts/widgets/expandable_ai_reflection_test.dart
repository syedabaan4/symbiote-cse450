import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symbiote/features/thoughts/models/thought.dart';
import 'package:symbiote/features/thoughts/widgets/expandable_ai_reflection.dart';

void main() {
  final testThought = Thought(
    id: '1',
    threadId: 'thread1',
    encryptedContent: '',
    iv: '',
    createdAt: DateTime.now(),
    userId: 'user1',
  );

  testWidgets(
      'ExpandableAIReflection shows preview and expands/collapses on tap',
      (WidgetTester tester) async {
    const longContent =
        'This is a long piece of content that should definitely exceed the preview line limit and cause the expand button to appear. We need to make sure this text is long enough to wrap to more than three lines to properly test the expand and collapse functionality of the widget.';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ExpandableAIReflection(
              content: longContent,
              threadId: 'thread1',
              thought: testThought,
              onSaveTasks: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text(longContent, findRichText: true), findsOneWidget);
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
    expect(find.byIcon(Icons.expand_less), findsNothing);

    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.expand_more), findsNothing);
    expect(find.byIcon(Icons.expand_less), findsOneWidget);

    await tester.tap(find.byIcon(Icons.expand_less));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.expand_more), findsOneWidget);
    expect(find.byIcon(Icons.expand_less), findsNothing);
  });
} 