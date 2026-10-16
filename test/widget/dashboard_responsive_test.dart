import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valex_app/repositories/finance_repository.dart';
import 'package:valex_app/services/student_context_service.dart';
import 'package:valex_app/theme/app_theme.dart';
import 'package:valex_app/views/dashboard/dashboard_view.dart';
import 'package:valex_app/widgets/carbon_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in [const Size(320, 720), const Size(1366, 900)]) {
    testWidgets('dashboard mantém indicadores legíveis em ${size.width}px', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(size);
      final repository = FinanceRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: DashboardView(
            studentContext: StudentContextService.forTesting(),
            financeRepository: repository,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Visão do negócio'), findsOneWidget);
      expect(find.text('Aluno em foco'), findsOneWidget);
      if (size.width == 320) {
        expect(
          tester.getSize(find.byType(CarbonCard).first).width,
          greaterThan(260),
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      repository.dispose();
      await tester.binding.setSurfaceSize(null);
    });
  }
}
