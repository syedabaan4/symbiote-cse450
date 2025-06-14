import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';
import 'tasks_state.dart';

class TasksCubit extends Cubit<TasksState> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  TasksCubit({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        super(const TasksInitial());

  Future<void> loadTasks() async {
    try {
      emit(const TasksLoading());
      
      final user = _auth.currentUser;
      if (user == null) {
        emit(const TasksError('User not authenticated'));
        return;
      }

      final snapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final tasks = snapshot.docs
          .map((doc) => Task.fromFirestore(doc))
          .toList();

      emit(TasksLoaded(tasks));
    } catch (e) {
      emit(TasksError('Failed to load tasks: ${e.toString()}'));
    }
  }

  Future<void> createTasksFromAIResponse(
    String aiResponse, {
    String? sourceThreadId,
    String? sourceThoughtId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        emit(const TasksError('User not authenticated'));
        return;
      }

      // Parse tasks from AI response (assumes tasks start with "- ")
      final taskLines = aiResponse
          .split('\n')
          .where((line) => line.trim().startsWith('- '))
          .map((line) => line.trim().substring(2).trim())
          .where((task) => task.isNotEmpty)
          .toList();

      if (taskLines.isEmpty) {
        return; // No tasks to create
      }

      final batch = _firestore.batch();
      final now = DateTime.now();

      for (final taskContent in taskLines) {
        final taskId = _firestore.collection('tasks').doc().id;
        final task = Task(
          id: taskId,
          content: taskContent,
          isCompleted: false,
          createdAt: now,
          updatedAt: now,
          userId: user.uid,
          sourceThreadId: sourceThreadId,
          sourceThoughtId: sourceThoughtId,
        );

        batch.set(
          _firestore.collection('tasks').doc(taskId),
          task.toFirestore(),
        );
      }

      await batch.commit();
      
      // Reload tasks to show the new ones
      await loadTasks();
    } catch (e) {
      emit(TasksError('Failed to create tasks: ${e.toString()}'));
    }
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        emit(const TasksError('User not authenticated'));
        return;
      }

      // Get current state
      final currentState = state;
      if (currentState is! TasksLoaded) return;

      // Find the task to toggle
      final taskIndex = currentState.tasks.indexWhere((task) => task.id == taskId);
      if (taskIndex == -1) {
        emit(const TasksError('Task not found'));
        return;
      }

      // Create updated task list with toggled task
      final tasks = List<Task>.from(currentState.tasks);
      final originalTask = tasks[taskIndex];
      final updatedTask = originalTask.copyWith(
        isCompleted: !originalTask.isCompleted,
        updatedAt: DateTime.now(),
      );
      tasks[taskIndex] = updatedTask;

      // Update UI immediately
      emit(TasksLoaded(tasks));

      // Update Firebase in background
      try {
        await _firestore
            .collection('tasks')
            .doc(taskId)
            .update(updatedTask.toFirestore());
      } catch (e) {
        // If Firebase update fails, revert the UI change
        tasks[taskIndex] = originalTask;
        emit(TasksLoaded(tasks));
        emit(TasksError('Failed to update task: ${e.toString()}'));
      }
    } catch (e) {
      emit(TasksError('Failed to update task: ${e.toString()}'));
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        emit(const TasksError('User not authenticated'));
        return;
      }

      // Get current state
      final currentState = state;
      if (currentState is! TasksLoaded) return;

      // Find the task to delete
      final taskIndex = currentState.tasks.indexWhere((task) => task.id == taskId);
      if (taskIndex == -1) {
        emit(const TasksError('Task not found'));
        return;
      }

      // Create updated task list without the deleted task
      final tasks = List<Task>.from(currentState.tasks);
      final deletedTask = tasks[taskIndex];
      tasks.removeAt(taskIndex);

      // Update UI immediately
      emit(TasksLoaded(tasks));

      // Delete from Firebase in background
      try {
        await _firestore.collection('tasks').doc(taskId).delete();
      } catch (e) {
        // If Firebase delete fails, restore the task
        tasks.insert(taskIndex, deletedTask);
        emit(TasksLoaded(tasks));
        emit(TasksError('Failed to delete task: ${e.toString()}'));
      }
    } catch (e) {
      emit(TasksError('Failed to delete task: ${e.toString()}'));
    }
  }
} 