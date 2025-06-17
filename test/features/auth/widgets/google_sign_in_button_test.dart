import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:symbiote/features/auth/widgets/google_sign_in_button.dart';

void main() {
  testWidgets('GoogleSignInButton renders correctly and handles tap',
      (WidgetTester tester) async {
    bool pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GoogleSignInButton(
            onPressed: () {
              pressed = true;
            },
          ),
        ),
      ),
    );

    expect(find.byType(GoogleSignInButton), findsOneWidget);

    expect(find.text('Sign in with Google'), findsOneWidget);

    expect(find.byType(Image), findsOneWidget);

    await tester.tap(find.byType(GoogleSignInButton));
    await tester.pump();

    expect(pressed, isTrue);
  });
} 