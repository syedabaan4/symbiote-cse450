import 'package:bloc_test/bloc_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symbiote/features/tasks/cubit/tasks_cubit.dart';
import 'package:symbiote/features/tasks/cubit/tasks_state.dart';
import 'package:symbiote/features/tasks/models/task.dart';

void main() {
  group('TasksCubit', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late TasksCubit tasksCubit;
    late MockUser user;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      user = MockUser(uid: 'test_uid');
      mockAuth = MockFirebaseAuth(signedIn: true, mockUser: user);
      tasksCubit = TasksCubit(
        firestore: fakeFirestore,
        auth: mockAuth,
      );
    });

    test('initial state is TasksInitial', () {
      expect(tasksCubit.state, const TasksInitial());
    });

    blocTest<TasksCubit, TasksState>(
      'emits [TasksLoading, TasksLoaded] when loadTasks is called',
      build: () {
        fakeFirestore.collection('tasks').add({
          'content': 'Test Task',
          'isCompleted': false,
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
          'userId': user.uid,
        });
        return tasksCubit;
      },
      act: (cubit) => cubit.loadTasks(),
      expect: () => [
        const TasksLoading(),
        isA<TasksLoaded>(),
      ],
    );

    blocTest<TasksCubit, TasksState>(
      'emits [TasksLoaded] when a task is deleted',
      build: () {
        final docRef = fakeFirestore.collection('tasks').doc('task_to_delete');
        docRef.set({
          'content': 'Test Task',
          'isCompleted': false,
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
          'userId': user.uid,
        });
        tasksCubit.emit(TasksLoaded([
          Task(id: 'task_to_delete', content: 'Test Task', isCompleted: false, createdAt: DateTime.now(), updatedAt: DateTime.now(), userId: user.uid)
        ]));
        return tasksCubit;
      },
      act: (cubit) => cubit.deleteTask('task_to_delete'),
      expect: () => [isA<TasksLoaded>()],
      verify: (_) async {
        final snapshot = await fakeFirestore.collection('tasks').doc('task_to_delete').get();
        expect(snapshot.exists, isFalse);
      },
    );
  });
} 