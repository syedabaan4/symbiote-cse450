import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../cubit/tasks_cubit.dart';
import '../cubit/tasks_state.dart';
import '../models/task.dart';
import '../widgets/task_item.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TasksCubit>().loadTasks();
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        title: Text(
          'Tasks',
          style: GoogleFonts.pixelifySans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: BlocConsumer<TasksCubit, TasksState>(
        listener: (context, state) {
          if (state is TasksError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                backgroundColor: Colors.red.shade400,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TasksLoading) {
            return Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: LoadingAnimationWidget.fourRotatingDots(color: Colors.blueGrey, size: 24)
              ),
            );
          }

          if (state is TasksError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading tasks',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Something went wrong. Please try again.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.read<TasksCubit>().loadTasks(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      'Retry',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is TasksLoaded) {
            if (state.tasks.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No tasks yet',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use the Task Organizer AI agent to\ncreate tasks from your thoughts',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            
            final tasksByCategory = <String, List<Task>>{};
            
            for (final task in state.tasks) {
              final category = task.category ?? 'Personal';
              tasksByCategory.putIfAbsent(category, () => []);
              tasksByCategory[category]!.add(task);
            }

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                
                ...tasksByCategory.entries.map((entry) {
                  final category = entry.key;
                  final categoryTasks = entry.value;
                  
                  
                  final pendingTasks = categoryTasks.where((task) => !task.isCompleted).toList();
                  final completedTasks = categoryTasks.where((task) => task.isCompleted).toList();
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  category,
                                  style: GoogleFonts.pixelifySans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${categoryTasks.length}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        
                        if (pendingTasks.isNotEmpty || completedTasks.isNotEmpty) ...[
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                
                                ...pendingTasks.map((task) => TaskItem(
                                  task: task,
                                  onToggle: () => context.read<TasksCubit>().toggleTaskCompletion(task.id),
                                  onDelete: () => context.read<TasksCubit>().deleteTask(task.id),
                                  onSetReminder: (dateTime) => context.read<TasksCubit>().setTaskReminder(task.id, dateTime),
                                  onRemoveReminder: () => context.read<TasksCubit>().removeTaskReminder(task.id),
                                )),
                                
                                
                                if (completedTasks.isNotEmpty) ...[
                                  if (pendingTasks.isNotEmpty) 
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: Divider(height: 1, color: Color(0xFFF3F4F6)),
                                    ),
                                  Text(
                                    'Completed',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...completedTasks.map((task) => TaskItem(
                                    task: task,
                                    onToggle: () => context.read<TasksCubit>().toggleTaskCompletion(task.id),
                                    onDelete: () => context.read<TasksCubit>().deleteTask(task.id),
                                    onSetReminder: (dateTime) => context.read<TasksCubit>().setTaskReminder(task.id, dateTime),
                                    onRemoveReminder: () => context.read<TasksCubit>().removeTaskReminder(task.id),
                                  )),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}