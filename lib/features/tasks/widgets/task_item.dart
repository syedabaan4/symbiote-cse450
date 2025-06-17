import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final Function(DateTime) onSetReminder;
  final VoidCallback onRemoveReminder;

  const TaskItem({
    super.key,
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
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          
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
          
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ReminderMenu(
                task: task,
                onSetReminder: onSetReminder,
                onRemoveReminder: onRemoveReminder,
              ),
              const SizedBox(width: 8),
              
              GestureDetector(
                onTap: () => _showDeleteConfirmation(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Task', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18)),
        content: Text(
          'Are you sure you want to delete this task?',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.red.shade600)),
          ),
        ],
      ),
    );
  }
}

class _ReminderMenu extends StatelessWidget {
  final Task task;
  final Function(DateTime) onSetReminder;
  final VoidCallback onRemoveReminder;

  const _ReminderMenu({
    required this.task,
    required this.onSetReminder,
    required this.onRemoveReminder,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: task.reminderDateTime != null ? Colors.blue.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          task.reminderDateTime != null ? Icons.notifications_active : Icons.notifications_none,
          size: 16,
          color: task.reminderDateTime != null ? Colors.blue.shade600 : Colors.grey.shade400,
        ),
      ),
      onSelected: (value) => _handleAction(context, value),
      itemBuilder: (context) => [
        PopupMenuItem(value: 'set_1hour', child: Text('Remind in 1 hour', style: GoogleFonts.inter())),
        PopupMenuItem(value: 'set_tomorrow', child: Text('Remind tomorrow', style: GoogleFonts.inter())),
        PopupMenuItem(value: 'set_custom', child: Text('Custom reminder', style: GoogleFonts.inter())),
        if (task.reminderDateTime != null)
          PopupMenuItem(value: 'remove', child: Text('Remove reminder', style: GoogleFonts.inter(color: Colors.red))),
      ],
    );
  }

  void _handleAction(BuildContext context, String value) {
    switch (value) {
      case 'set_1hour':
        onSetReminder(DateTime.now().add(const Duration(hours: 1)));
        break;
      case 'set_tomorrow':
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        onSetReminder(DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9));
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
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey.shade600))),
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