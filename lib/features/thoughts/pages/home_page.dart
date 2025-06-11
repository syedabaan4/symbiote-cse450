import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/thoughts_cubit.dart';
import '../cubit/thoughts_state.dart';
import 'thought_entry_page.dart';

// TODO: rethink stateful widget choice
class HomePage extends StatefulWidget { 
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<ThoughtsCubit>().loadThoughts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Thoughts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ThoughtsCubit>().loadThoughts(),
          ),
        ],
      ),
      body: BlocConsumer<ThoughtsCubit, ThoughtsState>(
        listener: (context, state) {
          if (state is ThoughtSaved) {
            context.read<ThoughtsCubit>().loadThoughts();
          }
        },
        builder: (context, state) {
          if (state is ThoughtsLoading) {
            return const Center(child: CircularProgressIndicator());
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
                    borderRadius: BorderRadius.horizontal(),
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
          if (context.mounted) {
            context.read<ThoughtsCubit>().loadThoughts();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

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
} 