import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symbiote/features/tasks/models/task.dart';
import 'package:symbiote/features/tasks/widgets/task_item.dart';

void main() {
  testWidgets('TaskItem renders correctly and handles interactions',
      (WidgetTester tester) async {
    final task = Task(
      id: '1',
      content: 'Test task',
      isCompleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: 'user1',
    );

    bool toggled = false;
    bool deleted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskItem(
            task: task,
            onToggle: () => toggled = true,
            onDelete: () => deleted = true,
            onSetReminder: (date) {},
            onRemoveReminder: () {},
          ),
        ),
      ),
    );

    expect(find.text('Test task'), findsOneWidget);

    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump();
    expect(toggled, isTrue);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle(); 

    expect(find.text('Delete Task'), findsOneWidget);
    expect(find.text('Are you sure you want to delete this task?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    
    expect(deleted, isTrue);
  });
} 