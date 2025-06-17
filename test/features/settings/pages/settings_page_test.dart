import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:symbiote/features/auth/cubit/auth_cubit.dart';
import 'package:symbiote/features/settings/pages/settings_page.dart';

void main() {
  late AuthCubit authCubit;

  setUp(() {
    authCubit = AuthCubit();
  });

  Widget createWidgetForTesting({required Widget child}) {
    return BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('SettingsPage', () {
    testWidgets('renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetForTesting(child: const SettingsPage()));
      
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Security'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('tapping sign out shows confirmation dialog', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetForTesting(child: const SettingsPage()));
      
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Are you sure you want to sign out?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      
      await tester.tap(find.text('Sign Out').last);
      await tester.pumpAndSettle();
      
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
} 