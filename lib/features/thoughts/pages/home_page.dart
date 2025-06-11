import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../../drawer/widgets/app_drawer.dart';
import '../cubit/thoughts_cubit.dart';
import '../cubit/thoughts_state.dart';
import 'thought_entry_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thoughtDate = DateTime(date.year, date.month, date.day);

    if (thoughtDate == today) {
      return 'Today';
    } else if (thoughtDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, String thoughtId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Thought'),
        content: const Text('Are you sure you want to delete this thought? This action cannot be undone.'),
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
      context.read<ThoughtsCubit>().deleteThought(thoughtId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is Authenticated) {
              context.read<ThoughtsCubit>().loadThoughts();
            }
          },
        ),
        BlocListener<ThoughtsCubit, ThoughtsState>(
          listener: (context, state) {
            if (state is ThoughtSaved || state is ThoughtDeleted) {
              context.read<ThoughtsCubit>().loadThoughts();
            }
          },
        ),
      ],
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is Authenticated) {
            final thoughtsState = context.read<ThoughtsCubit>().state;
            if (thoughtsState is ThoughtsInitial) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<ThoughtsCubit>().loadThoughts();
              });
            }
          }
          
          return Scaffold(
            drawer: const AppDrawer(),
            appBar: AppBar(
              centerTitle: true,
              title: Text(
                'My Thoughts',
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
                  onPressed: () => context.read<ThoughtsCubit>().loadThoughts(),
                ),
              ],
            ),
            body: BlocBuilder<ThoughtsCubit, ThoughtsState>(
              builder: (context, state) {
                if (state is ThoughtsLoading) {
                  return Center(child: LoadingAnimationWidget.fourRotatingDots(color: Colors.black, size: 30));
                }

                if (state is ThoughtsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${state.message}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.read<ThoughtsCubit>().loadThoughts(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is ThoughtsLoaded) {
                  if (state.thoughts.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No thoughts yet',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap the + button to add your first thought',
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
                      crossAxisSpacing: 0.5,
                      mainAxisSpacing: 0,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: state.thoughts.length,
                    itemBuilder: (context, index) {
                      final thought = state.thoughts[index];
                      final decryptedContent = context
                          .read<ThoughtsCubit>()
                          .decryptThought(thought);

                      return Card(
                        elevation: 0,
                        child: InkWell(
                          onTap: () {
                            // TODO: Navigate to thought chat/thread
                          },
                          onLongPress: () => _showDeleteDialog(context, thought.id),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    decryptedContent,
                                    maxLines: 6,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _formatDate(thought.createdAt),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
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
                    builder: (context) => const ThoughtEntryPage(),
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