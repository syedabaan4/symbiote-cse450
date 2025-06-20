import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_vertical_heatmap/flutter_vertical_heatmap.dart';
import '../cubit/mood_cubit.dart';
import '../cubit/mood_state.dart';
import '../models/mood.dart';

class MoodTrackerPage extends StatelessWidget {
  const MoodTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MoodCubit>().loadMoods();
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        title: Text(
          'Mood Tracker',
          style: GoogleFonts.pixelifySans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: BlocConsumer<MoodCubit, MoodState>(
        listener: (context, state) {
          if (state is MoodError) {
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
          if (state is MoodLoading) {
            return Center(
              child: LoadingAnimationWidget.fourRotatingDots(
                color: Colors.deepPurple,
                size: 30,
              ),
            );
          }

          if (state is MoodLoaded) {
            if (state.moods.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '🌈',
                      style: TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No mood data yet',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start tracking your mood from the home page',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              );
            }

            final heatmapData = context.read<MoodCubit>().getMoodHeatmapData(state.moods);

            return Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text(
                            'Your Mood Journey',
                            style: GoogleFonts.pixelifySans(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 24),
                          HeatMap(
                            startDate: DateTime.now().subtract(const Duration(days: 365)),
                            endDate: DateTime.now(),
                            datasets: heatmapData,
                            size: 32,
                            colorTipSize: 32,
                            margin: const EdgeInsets.all(4),
                            colorsets: {
                              1: Colors.red.shade300,
                              2: Colors.orange.shade300,
                              3: Colors.yellow.shade600,
                              4: Colors.lightGreen.shade300,
                              5: Colors.green.shade400,
                            },
                            colorTipLabel: const ["😢", "😞", "😐", "😊", "😄"],
                            onClick: (date) {
                              final mood = heatmapData[date];
                              if (mood != null) {
                                final moodObj = Mood(id: '', value: mood, date: date, userId: '');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${date.day}/${date.month}/${date.year}: ${moodObj.emoji} ${moodObj.label} ($mood/5)',
                                      style: GoogleFonts.inter(fontSize: 14),
                                    ),
                                    duration: const Duration(seconds: 2),
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
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return  Center(child: LoadingAnimationWidget.fourRotatingDots(color: Colors.deepPurple, size: 30));
        },
      ),
    );
  }
} 