import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../../drawer/widgets/app_drawer.dart';
import '../../moods/pages/mood_log_dialog.dart';
import '../../moods/pages/mood_tracker_page.dart';
import '../../tasks/pages/tasks_page.dart';
import '../cubit/threads_cubit.dart';
import '../cubit/threads_state.dart';
import '../../ai/models/ai_agent.dart';
import 'thread_entry_page.dart';
import 'thread_detail_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $amPm';
  }

  String _getAgentDisplayName(AIAgentType? agentType) {
    if (agentType == null) return 'General';
    switch (agentType) {
      case AIAgentType.reflective:
        return 'Reflective';
      case AIAgentType.creative:
        return 'Creative';
      case AIAgentType.organize:
        return 'Organize';
    }
  }

  Color _getAgentColor(AIAgentType? agentType) {
    if (agentType == null) return Colors.grey.shade100;
    switch (agentType) {
      case AIAgentType.reflective:
        return Colors.green.shade100;
      case AIAgentType.creative:
        return Colors.red.shade100;
      case AIAgentType.organize:
        return Colors.blue.shade100;
    }
  }

  Color _getAgentTextColor(AIAgentType? agentType) {
    if (agentType == null) return Colors.grey.shade600;
    switch (agentType) {
      case AIAgentType.reflective:
        return Colors.green.shade700;
      case AIAgentType.creative:
        return Colors.red.shade700;
      case AIAgentType.organize:
        return Colors.blue.shade700;
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, String threadId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Thread'),
        content: const Text('Are you sure you want to delete this thread? This will delete all thoughts in this thread and cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<ThreadsCubit>().deleteThread(threadId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is Authenticated) {
              context.read<ThreadsCubit>().loadThreads();
            }
          },
        ),
        BlocListener<ThreadsCubit, ThreadsState>(
          listener: (context, state) {
            if (state is ThreadCreated || state is ThreadDeleted) {
              context.read<ThreadsCubit>().loadThreads();
            }
          },
        ),
      ],
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is Authenticated) {
            final threadsState = context.read<ThreadsCubit>().state;
            if (threadsState is ThreadsInitial) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<ThreadsCubit>().loadThreads();
              });
            }
          }
          
          return Scaffold(
            drawer: const AppDrawer(),
            body: SafeArea(
              child: BlocBuilder<ThreadsCubit, ThreadsState>(
                builder: (context, state) {
                  if (state is ThreadsLoading) {
                    return Center(child: LoadingAnimationWidget.fourRotatingDots(color: Colors.black, size: 30));
                  }
              
                  if (state is ThreadsError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: ${state.message}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.read<ThreadsCubit>().loadThreads(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
              
                  if (state is ThreadsLoaded) {
                    if (state.threads.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.forum_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No threads yet',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap the + button to start your first thread',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }
              
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                                              // Hello User text
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Text(
                          'Hello, ${authState is Authenticated ? (authState.user.displayName ?? authState.user.email?.split('@')[0] ?? 'User') : 'User'}!',
                          style: GoogleFonts.pixelifySans(
                            fontSize: 40,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                        // Grid view
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 0,
                        mainAxisSpacing: 0,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: state.threads.length,
                      itemBuilder: (context, index) {
                        final thread = state.threads[index];
              
                        return Card(
                          elevation: 2,
                          shadowColor: Colors.black.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                                                  child: InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ThreadDetailPage(threadId: thread.id),
                              ),
                            );
                            // Refresh threads when returning from thread detail
                            if (context.mounted) {
                              context.read<ThreadsCubit>().loadThreads();
                            }
                          },
                            onLongPress: () => _showDeleteDialog(context, thread.id),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top row: logo (left) and agent type (right)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Logo (top left)
                                      Image.asset(
                                        'assets/images/logo.png',
                                        width: 16,
                                        height: 16,
                                      ),
                                      // Agent type (top right)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getAgentColor(thread.aiAgentType),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _getAgentDisplayName(thread.aiAgentType),
                                          style: GoogleFonts.pixelifySans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: _getAgentTextColor(thread.aiAgentType),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Middle: Last thought content
                                  Expanded(
                                    child: FutureBuilder<String>(
                                      future: context.read<ThreadsCubit>().getLatestThoughtContent(thread.id),
                                      builder: (context, snapshot) {
                                        final content = snapshot.connectionState == ConnectionState.done
                                            ? (snapshot.data ?? 'No content')
                                            : 'Loading...';
                                        return Text(
                                          content,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            height: 1.3,
                                            color: Colors.grey.shade700,
                                          ),
                                          maxLines: 10,
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      },
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 12,),
                                  
                                  // Bottom: Time (bottom left)
                                  Align(
                                    alignment: Alignment.bottomLeft,
                                    child: Text(
                                      _formatTime(thread.updatedAt),
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
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
            bottomNavigationBar: BottomAppBar(
              height: 65,
              color: Colors.deepPurple,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // App Drawer (far left)
                    Builder(
                      builder: (context) => IconButton(
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        icon: const Icon(Icons.menu, color: Colors.white),
                        iconSize: 22,
                      ),
                    ),
                    // Tasks (left-center)
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TasksPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.task_alt, color: Colors.white),
                      iconSize: 22,
                    ),
                    // Add Entry (center)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ThreadEntryPage(),
                            ),
                          );
                          // Refresh threads when returning from thread entry
                          if (context.mounted) {
                            context.read<ThreadsCubit>().loadThreads();
                          }
                        },
                        icon: Icon(Icons.add_sharp, color: Colors.black),
                        iconSize: 24,
                      ),
                    ),
                    // Mood (right-center)
                    IconButton(
                      onPressed: () async {
                        showDialog(
                          context: context,
                          builder: (context) => const MoodLogDialog(),
                        );
                      },
                      icon: const Icon(Icons.sentiment_satisfied_alt, color: Colors.white),
                      iconSize: 22,
                    ),
                    // Mood Tracker (far right)
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MoodTrackerPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.analytics_outlined, color: Colors.white),
                      iconSize: 22,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 