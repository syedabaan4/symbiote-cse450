import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../cubit/thread_detail_cubit.dart';
import '../cubit/threads_state.dart';
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
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/gradient-1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: BlocConsumer<ThreadDetailCubit, ThreadDetailState>(
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

                          return Container(
                            margin: const EdgeInsets.only(bottom: 32),
                            child: Text(
                              decryptedContent,
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                                color: Colors.black87,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Add button
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

 