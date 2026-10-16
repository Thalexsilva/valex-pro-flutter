import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valex_app/models/student_model.dart';
import 'package:valex_app/services/student_context_service.dart';
import 'package:valex_app/theme/app_theme.dart';
import 'package:valex_app/views/editor/editor_view.dart';
import 'package:valex_app/views/main_navigation_view.dart';
import 'package:valex_app/views/settings/settings_view.dart';
import 'package:valex_app/views/students/student_detail_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('menu móvel expõe módulos principais e configurações', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: MainNavigationView(onLogout: () {}),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(NavigationDestination), findsNWidgets(5));
    expect(find.text('Início'), findsWidgets);
    expect(find.text('Alunos'), findsWidgets);
    expect(find.text('Editor'), findsWidgets);
    expect(find.text('Financeiro'), findsWidgets);
    expect(find.text('Mais'), findsWidgets);

    await tester.tap(find.text('Mais'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Mais ferramentas'), findsOneWidget);
    expect(find.text('Vendas'), findsOneWidget);
    expect(find.text('Marketing'), findsOneWidget);
    expect(find.text('Biblioteca'), findsOneWidget);
    expect(find.text('Acessos'), findsOneWidget);
    expect(find.text('Sincronizar'), findsNothing);
    expect(find.text('Ajustes'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('more_destination_7')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SettingsView), findsOneWidget);
    expect(find.text('Configurações'), findsWidgets);
  });

  testWidgets('barra móvel permite alternar entre alunos, editor e início', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = StudentContextService.forTesting(
      allowOfflineWrites: true,
      initialStudents: [Student(id: 'mobile-nav', name: 'Aluno Teste')],
    );
    addTearDown(service.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: MainNavigationView(onLogout: () {}, contextService: service),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await tester.ensureVisible(find.text('Abrir editor'));
    await tester.tap(find.text('Abrir editor'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(EditorView), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Editor Ativo'), findsWidgets);
    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    await tester.tap(find.text('Alunos').last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Alunos'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Editor').last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(EditorView), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Início').last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Visão Geral'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CRM sem sessão não exibe leads fictícios', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: MainNavigationView(onLogout: () {}),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Mais'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('more_destination_1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Vendas & CRM'), findsWidgets);
    expect(find.text('Carlos Eduardo Silva'), findsNothing);
    expect(
      find.text('Não foi possível carregar os leads do CRM.'),
      findsOneWidget,
    );
  });

  testWidgets('perfil e edição da ficha preservam a navegação do instrutor', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = StudentContextService.forTesting(
      allowOfflineWrites: true,
      initialStudents: [Student(id: 'nav-student', name: 'Aluno Navegação')],
    );
    addTearDown(service.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: MainNavigationView(onLogout: () {}, contextService: service),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Alunos').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.tap(find.text('Aluno Navegação').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(StudentDetailView), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byTooltip('Voltar para alunos'), findsOneWidget);

    await tester.tap(find.byTooltip('Editar Ficha de Treino'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(EditorView), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Voltar ao aluno'), findsOneWidget);

    await tester.tap(find.text('Voltar ao aluno'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(StudentDetailView), findsOneWidget);
    await tester.tap(find.byTooltip('Voltar para alunos'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Aluno Navegação'), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
