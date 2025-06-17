import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:symbiote/features/auth/cubit/auth_cubit.dart';
import 'package:symbiote/features/drawer/widgets/app_drawer.dart';

void main() {
  testWidgets('AppDrawer renders drawer items', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          drawer: BlocProvider(
            create: (context) => AuthCubit(),
            child: const AppDrawer(),
          ),
        ),
      ),
    );

    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Mood'), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
