import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../../drawer/widgets/app_drawer.dart';
import '../cubit/threads_cubit.dart';
import '../cubit/threads_state.dart';
import 'thread_entry_page.dart';
import 'thread_detail_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final threadDate = DateTime(date.year, date.month, date.day);

    if (threadDate == today) {
      return 'Today';
    } else if (threadDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
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
            appBar: AppBar(
              centerTitle: true,
              title: Text(
                'My Threads',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              backgroundColor: Colors.blueGrey.shade50,
              elevation: 0,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(
                    Icons.menu,
                    color: Colors.black,
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.black,
                  ),
                  onPressed: () => context.read<ThreadsCubit>().loadThreads(),
                ),
              ],
            ),
            body: BlocBuilder<ThreadsCubit, ThreadsState>(
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

                  return GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: state.threads.length,
                    itemBuilder: (context, index) {
                      final thread = state.threads[index];

                      return Card(
                        elevation: 1,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ThreadDetailPage(threadId: thread.id),
                              ),
                            );
                          },
                          onLongPress: () => _showDeleteDialog(context, thread.id),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        thread.title,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${thread.thoughtCount}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.blueGrey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDate(thread.updatedAt),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.grey[400],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }

                return const Center(child: CircularProgressIndicator());
              },
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ThreadEntryPage(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }
} 