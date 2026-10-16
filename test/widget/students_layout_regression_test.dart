import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valex_app/models/student_model.dart';
import 'package:valex_app/services/student_context_service.dart';
import 'package:valex_app/views/students/students_view.dart';
import 'package:valex_app/views/students/student_detail_view.dart';

void main() {
  for (final width in [320.0, 700.0, 920.0, 1200.0]) {
    testWidgets('students fit available width $width inside desktop window', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = StudentContextService.forTesting(
        allowOfflineWrites: true,
        initialStudents: [
          Student(
            id: 'layout-test',
            name:
                'Nome de aluno bastante longo para testar a disposição dos campos',
            email: 'endereco.muito.longo.para.testar@example.com',
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              height: 500,
              child: StudentsView(contextService: service),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Nome de aluno'), findsOneWidget);
      expect(find.text('AÇÕES'), width >= 1000 ? findsOneWidget : findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      service.dispose();
    });
  }
  testWidgets('new student details never fabricate invoice or Pix payment', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentDetailView(
            student: Student(id: 'new-student', name: 'Aluno novo'),
            onEdit: () {},
            onToggleArchive: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Treino'), findsOneWidget);
    expect(find.text('Anamnese'), findsOneWidget);
    final lastPayment = tester.getRect(find.text('Último Pagamento'));
    expect(lastPayment.right, lessThanOrEqualTo(390));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Faturas'));
    await tester.pumpAndSettle();
    expect(
      find.text('Nenhuma fatura registrada para este aluno.'),
      findsOneWidget,
    );
    expect(find.textContaining('inv_001'), findsNothing);
    await tester.ensureVisible(find.text('Pagamentos'));
    await tester.tap(find.text('Pagamentos'));
    await tester.pumpAndSettle();
    expect(
      find.text('Nenhum pagamento registrado para este aluno.'),
      findsOneWidget,
    );
    expect(find.textContaining('04/07/2026'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('student actions and summary fit a 320 px phone', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentDetailView(
            student: Student(id: 'narrow-student', name: 'Aluno'),
            onEdit: () {},
            onToggleArchive: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.text('Avaliação 360°')).right,
      lessThanOrEqualTo(320),
    );
    expect(
      tester.getRect(find.text('Último Pagamento')).right,
      lessThanOrEqualTo(320),
    );
    expect(tester.takeException(), isNull);
  });
}
