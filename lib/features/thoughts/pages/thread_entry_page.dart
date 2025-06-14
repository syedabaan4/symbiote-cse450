import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../cubit/threads_cubit.dart';
import '../cubit/threads_state.dart';
import '../cubit/thread_detail_cubit.dart';
import '../../ai/models/ai_agent.dart';
import 'thread_detail_page.dart';

class ThreadEntryPage extends StatefulWidget {
  final String? existingThreadId;

  const ThreadEntryPage({
    super.key,
    this.existingThreadId,
  });

  @override
  State<ThreadEntryPage> createState() => _ThreadEntryPageState();
}

class _ThreadEntryPageState extends State<ThreadEntryPage> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;
  AIAgentType? _selectedAgent;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _discardContent() {
    Navigator.pop(context);
  }

  Future<void> _saveContent() async {
    final content = _textController.text.trim();
    if (content.isEmpty) {
      Navigator.pop(context);
      return;
    }

    if (widget.existingThreadId != null) {
      // Add thought to existing thread
      await context.read<ThreadDetailCubit>().addThoughtToThread(widget.existingThreadId!, content);
    } else {
      // Create new thread - require agent selection for new threads
      if (_selectedAgent == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please select an AI agent for your thread',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        return;
      }
      await context.read<ThreadsCubit>().createThreadWithThought(content, aiAgentType: _selectedAgent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<ThreadsCubit, ThreadsState>(
              listener: (context, state) {
                if (state is ThreadCreated) {
                  if (widget.existingThreadId == null) {
                    // Navigate to the new thread's detail page
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ThreadDetailPage(threadId: state.thread.id),
                      ),
                    );
                  } else {
                    Navigator.pop(context);
                  }
                } else if (state is ThreadsError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        state.message,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      backgroundColor: Colors.red.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              },
            ),
            BlocListener<ThreadDetailCubit, ThreadDetailState>(
              listener: (context, state) {
                if (state is ThoughtAdded) {
                  Navigator.pop(context);
                } else if (state is ThreadDetailError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        state.message,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      backgroundColor: Colors.red.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _discardContent,
                      icon: Icon(
                        Icons.close,
                        color: Colors.grey.shade600,
                        size: 24,
                      ),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(),
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(
                          Colors.transparent,
                        ),
                        overlayColor: WidgetStatePropertyAll(
                          Colors.grey.shade100,
                        ),
                      ),
                    ),
                    
                    // Save button with proper state management
                    BlocBuilder<ThreadsCubit, ThreadsState>(
                      builder: (context, threadsState) {
                        return BlocBuilder<ThreadDetailCubit, ThreadDetailState>(
                          builder: (context, detailState) {
                            final isCreating = widget.existingThreadId != null 
                                ? detailState is ThoughtAdding 
                                : threadsState is ThreadCreating;
                            
                            if (isCreating) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    LoadingAnimationWidget.staggeredDotsWave(color: Colors.white, size: 14),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Saving',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else if (_hasText) {
                              return TextButton(
                                onPressed: _saveContent,
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Save',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            } else {
                              return const SizedBox(width: 48);
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Agent selection for new threads
              if (widget.existingThreadId == null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose your AI companion:',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<AIAgentType>(
                            value: _selectedAgent,
                            hint: Text(
                              'Select an AI agent',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            isExpanded: true,
                            icon: Icon(
                              Icons.expand_more,
                              color: Colors.grey.shade600,
                            ),
                            items: AIAgent.availableAgents.map((agent) {
                              return DropdownMenuItem<AIAgentType>(
                                value: agent.type,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      agent.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      agent.description,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (AIAgentType? value) {
                              setState(() {
                                _selectedAgent = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
                  child: SingleChildScrollView(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: null,
                      minLines: 10, // Minimum height to fill the space
                      textAlignVertical: TextAlignVertical.top,
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        height: 1.6,
                        color: Colors.grey.shade900,
                        letterSpacing: 0.5,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.existingThreadId != null 
                            ? 'Continue your thoughts...'
                            : 'Start a new thread...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w400,
                          height: 1.6,
                          color: Colors.grey.shade400,
                          letterSpacing: -0.2,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      cursorColor: Colors.grey.shade700,
                      cursorWidth: 2,
                      cursorHeight: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 