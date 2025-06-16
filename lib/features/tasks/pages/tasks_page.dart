import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../cubit/tasks_cubit.dart';
import '../cubit/tasks_state.dart';
import '../models/task.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Load tasks when page builds
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

            // Group tasks by category
            final tasksByCategory = <String, List<Task>>{};
            
            for (final task in state.tasks) {
              final category = task.category ?? 'Personal';
              tasksByCategory.putIfAbsent(category, () => []);
              tasksByCategory[category]!.add(task);
            }

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Display tasks grouped by category
                ...tasksByCategory.entries.map((entry) {
                  final category = entry.key;
                  final categoryTasks = entry.value;
                  
                  // Separate completed and pending tasks within category
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
                        // Category header
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
                        
                        // Tasks content
                        if (pendingTasks.isNotEmpty || completedTasks.isNotEmpty) ...[
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Pending tasks
                                ...pendingTasks.map((task) => _TaskItem(
                                  task: task,
                                  onToggle: () => context.read<TasksCubit>().toggleTaskCompletion(task.id),
                                  onDelete: () => context.read<TasksCubit>().deleteTask(task.id),
                                  onSetReminder: (dateTime) => context.read<TasksCubit>().setTaskReminder(task.id, dateTime),
                                  onRemoveReminder: () => context.read<TasksCubit>().removeTaskReminder(task.id),
                                )),
                                
                                // Completed tasks section
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
                                  ...completedTasks.map((task) => _TaskItem(
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

class _TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final Function(DateTime) onSetReminder;
  final VoidCallback onRemoveReminder;

  const _TaskItem({
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onSetReminder,
    required this.onRemoveReminder,
  });

  @override
  Widget build(BuildContext context) {
          return Container(
        margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: task.isCompleted ? Colors.grey.shade700 : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: task.isCompleted ? Colors.grey.shade700 : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: task.isCompleted
                  ? Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Task content
          Expanded(
            child: Text(
              task.content,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: task.isCompleted ? Colors.grey.shade400 : Colors.grey.shade800,
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                height: 1.4,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reminder button
              PopupMenuButton<String>(
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: task.reminderDateTime != null 
                        ? Colors.blue.shade50 
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    task.reminderDateTime != null ? Icons.notifications_active : Icons.notifications_none,
                    size: 16,
                    color: task.reminderDateTime != null ? Colors.blue.shade600 : Colors.grey.shade400,
                  ),
                ),
                onSelected: (value) => _handleReminderAction(context, value),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'set_1hour',
                    child: Text('Remind in 1 hour', style: GoogleFonts.inter()),
                  ),
                  PopupMenuItem(
                    value: 'set_tomorrow',
                    child: Text('Remind tomorrow', style: GoogleFonts.inter()),
                  ),
                  PopupMenuItem(
                    value: 'set_custom',
                    child: Text('Custom reminder', style: GoogleFonts.inter()),
                  ),
                  if (task.reminderDateTime != null)
                    PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove reminder', style: GoogleFonts.inter(color: Colors.red)),
                    ),
                ],
              ),
              
              const SizedBox(width: 8),
              
              // Delete button
              GestureDetector(
                onTap: () => _showDeleteConfirmation(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Colors.red.shade400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Delete Task',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this task?',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDelete();
              },
              child: Text(
                'Delete',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.red.shade600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleReminderAction(BuildContext context, String action) {
    switch (action) {
      case 'set_1hour':
        final reminderTime = DateTime.now().add(const Duration(hours: 1));
        onSetReminder(reminderTime);
        break;
      case 'set_tomorrow':
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final reminderTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
        onSetReminder(reminderTime);
        break;
      case 'set_custom':
        _showCustomReminderDialog(context);
        break;
      case 'remove':
        onRemoveReminder();
        break;
    }
  }

  void _showCustomReminderDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Set Custom Reminder', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Date', style: GoogleFonts.inter()),
                subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => selectedDate = date);
                },
              ),
              ListTile(
                title: Text('Time', style: GoogleFonts.inter()),
                subtitle: Text(selectedTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(context: context, initialTime: selectedTime);
                  if (time != null) setState(() => selectedTime = time);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey.shade600)),
            ),
            TextButton(
              onPressed: () {
                final reminderDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
                Navigator.pop(context);
                onSetReminder(reminderDateTime);
              },
              child: Text('Set Reminder', style: GoogleFonts.inter(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}