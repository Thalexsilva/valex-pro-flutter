import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valex_app/repositories/finance_repository.dart';
import 'package:valex_app/views/dashboard/dashboard_view.dart';
import 'package:valex_app/views/editor/editor_view.dart';
import 'package:valex_app/views/finance/finance_view.dart';
import 'package:valex_app/views/settings/settings_view.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  final widths = [360.0, 412.0, 768.0, 1024.0, 1440.0];

  group(
    'Testes de Responsividade e Ausência de RenderFlex Overflow (360, 412, 768, 1024, 1440 px)',
    () {
      for (var w in widths) {
        testWidgets(
          'DashboardView em largura ${w.toInt()}px renderiza sem erros',
          (WidgetTester tester) async {
            tester.view.physicalSize = Size(w, 900);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);

            await tester.pumpWidget(const MaterialApp(home: DashboardView()));
            await tester.pump(const Duration(milliseconds: 100));

            expect(find.byType(DashboardView), findsOneWidget);
          },
        );

        testWidgets(
          'EditorView em largura ${w.toInt()}px renderiza sem erros',
          (WidgetTester tester) async {
            tester.view.physicalSize = Size(w, 900);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);

            await tester.pumpWidget(const MaterialApp(home: EditorView()));
            await tester.pump(const Duration(milliseconds: 100));

            expect(find.byType(EditorView), findsWidgets);
          },
        );

        testWidgets(
          'FinanceView em largura ${w.toInt()}px renderiza sem erros',
          (WidgetTester tester) async {
            tester.view.physicalSize = Size(w, 900);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);

            final repo = FinanceRepository();
            await repo.loadState();

            await tester.pumpWidget(
              MaterialApp(home: FinanceView(repository: repo)),
            );
            await tester.pump(const Duration(milliseconds: 100));

            expect(find.byType(FinanceView), findsOneWidget);
          },
        );

        testWidgets(
          'SettingsView em largura ${w.toInt()}px renderiza sem erros',
          (WidgetTester tester) async {
            tester.view.physicalSize = Size(w, 900);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);

            await tester.pumpWidget(
              MaterialApp(home: SettingsView(onLogout: () {})),
            );
            await tester.pump(const Duration(milliseconds: 100));

            expect(find.byType(SettingsView), findsOneWidget);
          },
        );
      }
    },
  );
}
