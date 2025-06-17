import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:symbiote/features/auth/cubit/auth_cubit.dart';
import 'package:symbiote/features/auth/pages/login_page.dart';
import 'package:symbiote/features/auth/pages/pin_auth_page.dart';
import 'package:symbiote/features/auth/pages/pin_setup_page.dart';
import 'package:symbiote/features/auth/widgets/google_sign_in_button.dart';
import 'package:pinput/pinput.dart';

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

  group('Auth Pages', () {
    testWidgets('LoginPage renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetForTesting(child: const LoginPage()));

      expect(find.text('The Quiet Space for a Loud Mind.'), findsOneWidget);
      expect(find.byType(GoogleSignInButton), findsOneWidget);
    });

    testWidgets('PinAuthPage renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetForTesting(child: const PinAuthPage()));

      expect(find.text('Enter PIN'), findsOneWidget);
      expect(find.text('Please enter your 6-digit PIN'), findsOneWidget);
      expect(find.byType(Pinput), findsOneWidget);
    });

    testWidgets('PinSetupPage renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetForTesting(child: const PinSetupPage()));

      expect(find.text('Setup PIN'), findsNWidgets(2));
      expect(find.text('Create a 6-digit PIN'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Enter PIN'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Confirm PIN'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('PinSetupPage shows error if PIN is not 6 digits',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetForTesting(child: const PinSetupPage()));

      await tester.enterText(find.widgetWithText(TextField, 'Enter PIN'), '123');
      await tester.enterText(
          find.widgetWithText(TextField, 'Confirm PIN'), '123');

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('PIN must be 6 digits'), findsOneWidget);
    });

    testWidgets('PinSetupPage shows error if PINs do not match',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetForTesting(child: const PinSetupPage()));

      await tester.enterText(
          find.widgetWithText(TextField, 'Enter PIN'), '123456');
      await tester.enterText(
          find.widgetWithText(TextField, 'Confirm PIN'), '654321');

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('PINs do not match'), findsOneWidget);
    });
  });
} 