import 'package:bloc_test/bloc_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symbiote/features/moods/cubit/mood_cubit.dart';
import 'package:symbiote/features/moods/cubit/mood_state.dart';

void main() {
  group('MoodCubit', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late MoodCubit moodCubit;
    late MockUser user;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      user = MockUser(uid: 'test_uid');
      mockAuth = MockFirebaseAuth(signedIn: true, mockUser: user);
      moodCubit = MoodCubit(
        firestore: fakeFirestore,
        auth: mockAuth,
      );
    });

    test('initial state is MoodInitial', () {
      expect(moodCubit.state, const MoodInitial());
    });

    blocTest<MoodCubit, MoodState>(
      'emits [MoodLoading, MoodLoaded] when loadMoods is called',
      build: () {
        fakeFirestore.collection('moods').add({
          'value': 5,
          'date': DateTime.now(),
          'userId': user.uid,
        });
        return moodCubit;
      },
      act: (cubit) => cubit.loadMoods(),
      expect: () => [
        const MoodLoading(),
        isA<MoodLoaded>(),
      ],
    );

    blocTest<MoodCubit, MoodState>(
      'emits [MoodSaving, MoodSaved, MoodLoading, MoodLoaded] when saveMoodForToday is called',
      build: () => moodCubit,
      act: (cubit) => cubit.saveMoodForToday(4),
      expect: () => [
        const MoodSaving(),
        isA<MoodSaved>(),
        const MoodLoading(),
        isA<MoodLoaded>(),
      ],
      verify: (_) async {
        final snapshot = await fakeFirestore.collection('moods').get();
        expect(snapshot.docs.length, 1);
        expect(snapshot.docs.first['value'], 4);
      },
    );
  });
} 