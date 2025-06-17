import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserThought extends StatelessWidget {
  final String content;
  final DateTime createdAt;

  const UserThought({
    super.key,
    required this.content,
    required this.createdAt,
  });

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    // Calculate day difference based on calendar days, not 24-hour periods
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final daysDifference = today.difference(entryDate).inDays;
    // Format time
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final timeStr = '$displayHour:$minute $amPm';
    // Format day
    String dayStr;
    if (daysDifference == 0) {
      dayStr = 'today';
    } else if (daysDifference == 1) {
      dayStr = 'yesterday';
    } else if (daysDifference < 7) {
      const days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
      dayStr = days[dateTime.weekday - 1];
    } else {
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      dayStr = '${dateTime.day} ${months[dateTime.month - 1]}';
    }
    return '$timeStr, $dayStr';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              _formatTime(createdAt),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
          ),
          // Content with journal-like styling
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Colors.grey.shade200,
                  width: 2,
                ),
              ),
            ),
            child: SelectableText(
              content,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                height: 1.7,
                color: Colors.black87,
                letterSpacing: 0.3,
              ),
            ),
          ),
          // Subtle separator
          Container(
            margin: const EdgeInsets.only(top: 24),
            height: 1,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(0.5),
            ),
          ),
        ],
      ),
    );
  }
} 