import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

class ExpandableAIReflection extends StatefulWidget {
  final String content;
  final String threadId;
  final dynamic thought;
  final VoidCallback onSaveTasks;

  const ExpandableAIReflection({
    super.key,
    required this.content,
    required this.threadId,
    required this.thought,
    required this.onSaveTasks,
  });

  @override
  State<ExpandableAIReflection> createState() => _ExpandableAIReflectionState();
}

class _ExpandableAIReflectionState extends State<ExpandableAIReflection> {
  bool _isExpanded = false;
  static const int _previewLines = 3;

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
    final isOrganizeAgent = widget.thought.assistantMode == 'organize';
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp and organize menu positioning
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12, right: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 12,
                      color: Colors.blue.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(widget.thought.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.blue.shade400,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                if (isOrganizeAgent)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.grey.shade400,
                      size: 16,
                    ),
                    onSelected: (value) {
                      if (value == 'save_tasks') {
                        widget.onSaveTasks();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'save_tasks',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.task_alt,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Save to Tasks',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Card content
          SizedBox(
            width: double.infinity,
            child: Card(
              color: Colors.white,
              elevation: 6,
              shadowColor: Colors.black.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade100,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    crossFadeState: _isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectionArea(
                          child: GptMarkdown(
                            widget.content,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              height: 1.6,
                              color: Colors.grey.shade700,
                              letterSpacing: 0.2,
                            ),
                            maxLines: _previewLines,
                          ),
                        ),
                        if (_contentExceedsLines()) const SizedBox(height: 8),
                        if (_contentExceedsLines())
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              InkWell(
                                onTap: () => setState(() => _isExpanded = true),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.expand_more,
                                    size: 18,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectionArea(
                          child: GptMarkdown(
                            widget.content,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              height: 1.6,
                              color: Colors.grey.shade700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () => setState(() => _isExpanded = false),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  Icons.expand_less,
                                  size: 18,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _contentExceedsLines() {
    // Use TextPainter to accurately determine overflow
    final tp = TextPainter(
      text: TextSpan(
        text: widget.content,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.6,
          letterSpacing: 0.2,
        ),
      ),
      maxLines: _previewLines,
      textDirection: TextDirection.ltr,
    );
    // Assume max width equals screen width minus typical padding (64 for card padding and list padding)
    tp.layout(maxWidth: MediaQuery.of(context).size.width - 76);
    return tp.didExceedMaxLines;
  }
} 