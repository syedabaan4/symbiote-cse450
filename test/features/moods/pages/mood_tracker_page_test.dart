import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:symbiote/features/moods/cubit/mood_cubit.dart';
import 'package:symbiote/features/moods/cubit/mood_state.dart';
import 'package:symbiote/features/moods/models/mood.dart';
import 'package:symbiote/features/moods/pages/mood_tracker_page.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_vertical_heatmap/flutter_vertical_heatmap.dart';

class FakeMoodCubit extends Cubit<MoodState> implements MoodCubit {
  FakeMoodCubit(super.initialState);

  @override
  Future<void> loadMoods() async {}

  @override
  Future<void> saveMoodForToday(int value) async {}

  @override
  Future<bool> hasLoggedMoodToday() async => false;

  @override
  Map<DateTime, int> getMoodHeatmapData(List<Mood> moods) {
    final Map<DateTime, int> heatmapData = {};
    for (final mood in moods) {
      final date = DateTime(mood.date.year, mood.date.month, mood.date.day);
      heatmapData[date] = mood.value;
    }
    return heatmapData;
  }
}

void main() {
  Widget createWidgetForTesting({required MoodCubit cubit}) {
    return BlocProvider<MoodCubit>.value(
      value: cubit,
      child: const MaterialApp(
        home: MoodTrackerPage(),
      ),
    );
  }

  group('MoodTrackerPage', () {
    testWidgets('shows loading indicator when state is MoodLoading',
        (WidgetTester tester) async {
      final cubit = FakeMoodCubit(const MoodLoading());
      await tester.pumpWidget(createWidgetForTesting(cubit: cubit));
      expect(find.byType(LoadingAnimationWidget), findsOneWidget);
    });

    testWidgets('shows empty message when state is MoodLoaded with no moods',
        (WidgetTester tester) async {
      final cubit = FakeMoodCubit(const MoodLoaded([]));
      await tester.pumpWidget(createWidgetForTesting(cubit: cubit));
      await tester.pumpAndSettle();
      expect(find.text('No mood data yet'), findsOneWidget);
    });

    testWidgets('displays heatmap when state is MoodLoaded with moods',
        (WidgetTester tester) async {
      final moods = [
        Mood(id: '1', value: 5, date: DateTime.now(), userId: 'user1'),
      ];
      final cubit = FakeMoodCubit(MoodLoaded(moods));
      await tester.pumpWidget(createWidgetForTesting(cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.text('Your Mood Journey'), findsOneWidget);
      expect(find.byType(HeatMap), findsOneWidget);
    });
  });
} 