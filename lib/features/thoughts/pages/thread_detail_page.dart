import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../cubit/thread_detail_cubit.dart';
import '../cubit/threads_state.dart';
import '../../ai/cubit/ai_cubit.dart';
import '../../ai/cubit/ai_state.dart';
import '../../tasks/cubit/tasks_cubit.dart';
import '../widgets/user_thought.dart';
import '../widgets/expandable_ai_reflection.dart';
import 'thread_entry_page.dart';

class ThreadDetailPage extends StatelessWidget {
  final String threadId;
  static final ScrollController _scrollController = ScrollController();

  const ThreadDetailPage({super.key, required this.threadId});

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Load thread details when page builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ThreadDetailCubit>().loadThreadDetails(threadId);
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
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
                  // AI reflection was already added optimistically, just show success message
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
                        onPressed: () => context
                            .read<ThreadDetailCubit>()
                            .loadThreadDetails(threadId),
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
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        itemCount: state.thoughts.length,
                        itemBuilder: (context, index) {
                          final thought = state.thoughts[index];
                          final decryptedContent = context
                              .read<ThreadDetailCubit>()
                              .decryptThought(thought);
                          final isAIThought = thought.assistantMode != null;

                          if (isAIThought) {
                            return ExpandableAIReflection(
                              content: decryptedContent,
                              threadId: threadId,
                              thought: thought,
                              onSaveTasks: () {
                                context
                                    .read<TasksCubit>()
                                    .createTasksFromAIResponse(
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
                              },
                            );
                          } else {
                            return UserThought(
                                content: decryptedContent,
                                createdAt: thought.createdAt);
                          }
                        },
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
      floatingActionButton: BlocBuilder<ThreadDetailCubit, ThreadDetailState>(
        builder: (context, state) {
          if (state is ThreadDetailLoaded && state.thoughts.isNotEmpty) {
            return Container(
              margin: const EdgeInsets.only(bottom: 0), // Position above bottom bar
              child: FloatingActionButton.small(
                onPressed: _scrollToBottom,
                backgroundColor: Colors.white.withOpacity(0.85),
                foregroundColor: Colors.grey.shade600,
                elevation: 1,
                splashColor: Colors.grey.shade100,
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BlocBuilder<ThreadDetailCubit, ThreadDetailState>(
        builder: (context, state) {
          if (state is ThreadDetailLoaded) {
            return BottomAppBar(
              height: 75,
              color: Colors.deepPurple,
              elevation: 4,
              child: SizedBox(
                height: 20,
                child: Row(
                  children: [
                    // Back button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip: 'Back',
                    ),
                    const Spacer(),
                    // Reflect button (centered)
                    BlocBuilder<AICubit, AIState>(
                      builder: (context, aiState) {
                        final isGenerating = aiState is AIGenerating;
                        return ElevatedButton.icon(
                          onPressed: isGenerating
                              ? null
                              : () {
                                  if (state.thread.aiAgentType != null) {
                                    context
                                        .read<AICubit>()
                                        .generateReflection(
                                          threadId: threadId,
                                          agentType: state.thread.aiAgentType!,
                                          threadDetailCubit:
                                              context.read<ThreadDetailCubit>(),
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
                          icon: isGenerating
                              ? LoadingAnimationWidget.staggeredDotsWave(
                                  color: Colors.black,
                                  size: 16,
                                )
                              : const Icon(Icons.auto_awesome, size: 18),
                          label: Text(
                            isGenerating ? 'Reflecting' : 'Reflect',
                            style: GoogleFonts.pixelifySans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isGenerating
                                ? Colors.white
                                : Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    // Add button (icon only, on the right)
                    IconButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ThreadEntryPage(
                              existingThreadId: threadId,
                            ),
                          ),
                        );
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.add_sharp,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                      tooltip: 'Add thought',
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
} 