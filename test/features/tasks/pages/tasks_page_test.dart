import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:symbiote/features/tasks/cubit/tasks_cubit.dart';
import 'package:symbiote/features/tasks/cubit/tasks_state.dart';
import 'package:symbiote/features/tasks/models/task.dart';
import 'package:symbiote/features/tasks/pages/tasks_page.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class FakeTasksCubit extends Cubit<TasksState> implements TasksCubit {
  FakeTasksCubit(super.initialState);

  @override
  Future<void> loadTasks() async {}
  @override
  Future<void> toggleTaskCompletion(String taskId) async {}
  @override
  Future<void> deleteTask(String taskId) async {}
  @override
  Future<void> setTaskReminder(String taskId, DateTime reminderDateTime) async {}
  @override
  Future<void> removeTaskReminder(String taskId) async {}
  Future<void> addTask(String content, {String? category, String? sourceThreadId, String? sourceThoughtId}) async {}
  @override
  Future<void> createTasksFromAIResponse(String aiResponse, {String? sourceThreadId, String? sourceThoughtId}) async {}
}

void main() {
  Widget createWidgetForTesting({required TasksCubit cubit}) {
    return BlocProvider<TasksCubit>.value(
      value: cubit,
      child: const MaterialApp(
        home: TasksPage(),
      ),
    );
  }

  group('TasksPage', () {
    testWidgets('shows loading indicator when state is TasksLoading',
        (WidgetTester tester) async {
      final cubit = FakeTasksCubit(const TasksLoading());
      await tester.pumpWidget(createWidgetForTesting(cubit: cubit));
      expect(find.byType(LoadingAnimationWidget), findsOneWidget);
    });

    testWidgets('shows error message when state is TasksError',
        (WidgetTester tester) async {
      final cubit = FakeTasksCubit(const TasksError('Failed to load'));
      await tester.pumpWidget(createWidgetForTesting(cubit: cubit));
      await tester.pumpAndSettle();
      expect(find.text('Error loading tasks'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('shows empty message when state is TasksLoaded with no tasks',
        (WidgetTester tester) async {
      final cubit = FakeTasksCubit(const TasksLoaded([]));
      await tester.pumpWidget(createWidgetForTesting(cubit: cubit));
      await tester.pumpAndSettle();
      expect(find.text('No tasks yet'), findsOneWidget);
    });

    testWidgets('displays tasks when state is TasksLoaded with tasks',
        (WidgetTester tester) async {
      final tasks = [
        Task(
          id: '1',
          content: 'Test task 1',
          isCompleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'user1',
        ),
        Task(
          id: '2',
          content: 'Test task 2',
          isCompleted: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: 'user1',
        ),
      ];
      final cubit = FakeTasksCubit(TasksLoaded(tasks));
      await tester.pumpWidget(createWidgetForTesting(cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.text('Test task 1'), findsOneWidget);
      expect(find.text('Test task 2'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });
  });
} 