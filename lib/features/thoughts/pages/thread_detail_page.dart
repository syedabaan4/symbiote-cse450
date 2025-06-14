import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../cubit/thread_detail_cubit.dart';
import '../cubit/threads_state.dart';
import '../../ai/cubit/ai_cubit.dart';
import '../../ai/cubit/ai_state.dart';
import '../../ai/models/ai_agent.dart';
import '../../tasks/cubit/tasks_cubit.dart';
import 'thread_entry_page.dart';

class ThreadDetailPage extends StatelessWidget {
  final String threadId;

  const ThreadDetailPage({
    super.key,
    required this.threadId,
  });

  @override
  Widget build(BuildContext context) {
    // Load thread details when page builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ThreadDetailCubit>().loadThreadDetails(threadId);
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<ThreadDetailCubit, ThreadDetailState>(
              listener: (context, state) {
                if (state is ThreadDetailError) {
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
            BlocListener<AICubit, AIState>(
              listener: (context, state) {
                if (state is AIResponseGenerated) {
                  // Reload thread details to show the new AI response
                  context.read<ThreadDetailCubit>().loadThreadDetails(threadId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'AI reflection added to your thread',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      backgroundColor: Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                } else if (state is AIError) {
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
          child: BlocBuilder<ThreadDetailCubit, ThreadDetailState>(
            builder: (context, state) {
              if (state is ThreadDetailLoading) {
                return Center(
                  child: LoadingAnimationWidget.fourRotatingDots(
                    color: Colors.black, 
                    size: 30,
                  ),
                );
              }
        
              if (state is ThreadDetailError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${state.message}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.read<ThreadDetailCubit>().loadThreadDetails(threadId),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
        
              if (state is ThreadDetailLoaded) {
                return Column(
                  children: [
                    // Thoughts list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        itemCount: state.thoughts.length,
                        itemBuilder: (context, index) {
                          final thought = state.thoughts[index];
                          final decryptedContent = context
                              .read<ThreadDetailCubit>()
                              .decryptThought(thought);
                          final isAIThought = thought.assistantMode != null;
                          final isOrganizeAgent = thought.assistantMode == 'organize';
        
                          return Container(
                            margin: const EdgeInsets.only(bottom: 26),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isAIThought) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'AI Reflection',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ),
                                      // Dropdown for organize agent
                                      if (isOrganizeAgent)
                                        PopupMenuButton<String>(
                                          icon: Icon(
                                            Icons.more_vert,
                                            color: Colors.grey.shade600,
                                            size: 18,
                                          ),
                                          onSelected: (value) {
                                            if (value == 'save_tasks') {
                                              context.read<TasksCubit>().createTasksFromAIResponse(
                                                decryptedContent,
                                                sourceThreadId: threadId,
                                                sourceThoughtId: thought.id,
                                              );
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Tasks saved successfully',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w400,
                                                    ),
                                                  ),
                                                  backgroundColor: Colors.green.shade600,
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                              );
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
                                  const SizedBox(height: 8),
                                ],
                                Text(
                                  decryptedContent,
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    height: 1.5,
                                    color: isAIThought ? Colors.black54 : Colors.black87,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        
                    // Action buttons
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.arrow_back,
                              color: Colors.grey.shade600,
                              size: 24,
                            ),
                          ),
                          const Spacer(),
                          
                          // Reflect button
                          BlocBuilder<AICubit, AIState>(
                            builder: (context, aiState) {
                              final isGenerating = aiState is AIGenerating;
                              return FloatingActionButton.extended(
                                onPressed: isGenerating ? null : () {
                                  if (state.thread.aiAgentType != null) {
                                    context.read<AICubit>().generateReflection(
                                      threadId: threadId,
                                      agentType: state.thread.aiAgentType!,
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'No AI agent assigned to this thread',
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
                                  }
                                },
                                backgroundColor: isGenerating ? Colors.grey.shade300 : Colors.purple.shade600,
                                foregroundColor: Colors.white,
                                icon: isGenerating 
                                    ? LoadingAnimationWidget.staggeredDotsWave(color: Colors.white, size: 16)
                                    : const Icon(Icons.auto_awesome),
                                label: Text(
                                  isGenerating ? 'Reflecting' : 'Reflect',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Add thought button
                          FloatingActionButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ThreadEntryPage(existingThreadId: threadId),
                                ),
                              );
                            },
                            backgroundColor: Colors.blueGrey.shade600,
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
        
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }
}

 