import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:symbiote/features/export/cubit/export_cubit.dart';
import 'package:symbiote/features/export/cubit/export_state.dart';
import 'package:symbiote/features/export/pages/export_page.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class FakeExportCubit extends Cubit<ExportState> implements ExportCubit {
  FakeExportCubit(super.initialState);

  @override
  Future<void> exportData(String password) async {}
}

void main() {
  Widget createWidgetForTesting({required ExportCubit cubit}) {
    return BlocProvider<ExportCubit>.value(
      value: cubit,
      child: const MaterialApp(
        home: ExportPage(),
      ),
    );
  }

  group('ExportPage', () {
    testWidgets('renders initial state correctly', (WidgetTester tester) async {
      final cubit = FakeExportCubit(const ExportInitial());
      await tester.pumpWidget(createWidgetForTesting(cubit: cubit));

      expect(find.text('Export Data'), findsOneWidget);
      expect(find.text('Encryption Password'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('shows loading indicator when state is ExportLoading',
        (WidgetTester tester) async {
      final cubit = FakeExportCubit(const ExportLoading());
      await tester.pumpWidget(createWidgetForTesting(cubit: cubit));
      await tester.pump();

      expect(find.byType(LoadingAnimationWidget), findsOneWidget);
      expect(find.text('Export Encrypted Data'), findsNothing);
    });

    testWidgets('shows success dialog when state is ExportSuccess',
        (WidgetTester tester) async {
      final cubit = FakeExportCubit(const ExportInitial());
      await tester.pumpWidget(createWidgetForTesting(cubit: cubit));
      
      cubit.emit(const ExportSuccess());
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Export Complete'), findsOneWidget);
    });

    testWidgets('shows error snackbar when state is ExportError',
        (WidgetTester tester) async {
      final cubit = FakeExportCubit(const ExportInitial());
      await tester.pumpWidget(createWidgetForTesting(cubit: cubit));
      
      cubit.emit(const ExportError('Failed to export'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Failed to export'), findsOneWidget);
    });
  });
} 