import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:symbiote/features/auth/cubit/auth_state.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/pages/login_page.dart';
import 'features/thoughts/cubit/threads_cubit.dart';
import 'features/thoughts/cubit/thread_detail_cubit.dart';
import 'features/ai/cubit/ai_cubit.dart';
import 'features/tasks/cubit/tasks_cubit.dart';
import 'features/moods/cubit/mood_cubit.dart';
import 'features/thoughts/pages/home_page.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize timezone and notification service
  tz.initializeTimeZones();
  
  // Set local timezone - this is crucial!
  final String timeZoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName));
  // Device timezone set for scheduled notifications
  
  await NotificationService().initialize();
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthCubit()),
        BlocProvider(create: (context) => ThreadsCubit()),
        BlocProvider(create: (context) => ThreadDetailCubit()),
        BlocProvider(create: (context) => AICubit()),
        BlocProvider(create: (context) => TasksCubit()),
        BlocProvider(create: (context) => MoodCubit()),
      ],
      child: MaterialApp(
        title: 'Symbiote',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
          useMaterial3: true,
        ),
        home: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is Authenticated) {
              return const HomePage();
            }
            return const LoginPage();
          },
        ),
      ),
    );
  }
}
