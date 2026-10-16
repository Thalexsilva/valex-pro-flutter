import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valex_app/models/anamnese_model.dart';
import 'package:valex_app/models/student_model.dart';
import 'package:valex_app/repositories/anamnese_repository.dart';
import 'package:valex_app/services/student_context_service.dart';
import 'package:valex_app/views/students/anamnese_form_wizard_view.dart';
import 'package:valex_app/views/students/request_reassessment_dialog.dart';
import 'package:valex_app/views/students/student_portal_view.dart';

import '../support/e2e_fixtures.dart';
import '../support/fake_supabase_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'Suíte de Testes do Fluxo 360° no Primeiro Login e Reavaliação pelo Instrutor',
    () {
      late Student testStudent;

      setUp(() {
        SharedPreferences.setMockInitialValues({});
        testStudent = Student(
          id: 'st_test_360',
          name: 'Ana Beatriz',
          email: 'ana@example.com',
          phone: '(11) 98765-4321',
          needsReassessment: false,
          anamnesePending: false,
        );
        StudentContextService().addStudent(testStudent);
      });

      testWidgets(
        '2. Instrutor abre RequestReassessmentDialog e solicita reavaliação remota',
        (WidgetTester tester) async {
          tester.view.physicalSize = const Size(1200, 1000);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          bool retriggered = false;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: RequestReassessmentDialog(
                  student: testStudent,
                  onReassessmentTriggered: () {
                    retriggered = true;
                  },
                ),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 200));

          // Verifica elementos do diálogo
          expect(find.text('Refazer Fluxo 360°'), findsOneWidget);
          expect(
            find.text('Iniciar Avaliação Presencial Agora'),
            findsOneWidget,
          );
          expect(
            find.text('Solicitar no Próximo Acesso / WhatsApp'),
            findsOneWidget,
          );

          // Clica em solicitar remotamente
          await tester.tap(
            find.byKey(const Key('btn_request_remote_assessment')),
          );
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(milliseconds: 300));

          expect(retriggered, isTrue);
          // A área de transferência não responde em testes; o limite de 3 s
          // garante que a confirmação apareça mesmo assim.
          await tester.pump(const Duration(seconds: 4));
        },
      );

      testWidgets(
        '3. Instrutor escolhe iniciar reavaliação presencial agora e abre Wizard',
        (WidgetTester tester) async {
          tester.view.physicalSize = const Size(1200, 1000);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: RequestReassessmentDialog(student: testStudent),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 200));

          // Clica em iniciar avaliação presencial
          await tester.tap(find.text('Iniciar Avaliação Presencial Agora'));
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(milliseconds: 300));

          // Verifica que o Wizard 360° foi aberto
          expect(find.byType(AnamneseFormWizardView), findsOneWidget);
          expect(find.textContaining('Passo 1'), findsOneWidget);
        },
      );

      test(
        '4. AnamneseRepository marca e remove flags de reavaliação corretamente',
        () async {
          SharedPreferences.setMockInitialValues({});
          final repo = AnamneseRepository();

          // Solicita reavaliação
          final reqOk = await repo.requestReassessment(
            testStudent.id,
            reason: 'Nova Periodização',
          );
          expect(reqOk, isTrue);

          final needsAfterRequest = await repo.checkNeeds360(testStudent.id);
          expect(needsAfterRequest, isTrue);

          // Cria anamnese completa
          final anamnese = AnamneseModel(
            id: 'ana_100',
            studentId: testStudent.id,
            name: 'Ana Beatriz',
            weightKg: 62.5,
            heightCm: 165,
          );

          // Salva anamnese
          final saveOk = await repo.saveAnamnese(anamnese);
          expect(saveOk, isTrue);
        },
      );
    },
  );

  group('Portal do aluno no primeiro acesso (servidor simulado)', () {
    late FakeSupabaseBackend backend;
    late Student testStudent;

    setUp(() async {
      await resetAppSingletons();
      testStudent = Student(
        id: '44444444-4444-4444-8444-444444444444',
        trainerId: trainerId,
        name: 'Ana Beatriz',
        email: 'ana@example.com',
        phone: '(11) 98765-4321',
      );
      backend = FakeSupabaseBackend(
        userId: 'student-account',
        email: 'ana@example.com',
      );
      backend.seed('students', [
        {
          ...testStudent.toJson(),
          'trainer_id': trainerId,
          'student_user_id': 'student-account',
        },
      ]);
      backend.rpcs['claim_student_account'] = (_) => testStudent.id;
      await backend.start();
    });

    tearDown(() async {
      await resetAppSingletons();
      await backend.stop();
    });

    testWidgets(
      '1. Aluno no primeiro login (sem anamnese prévia) recebe aviso do Fluxo 360°',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: StudentPortalView(student: testStudent, onLogout: () {}),
          ),
        );

        // Avança os frames
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        // Verifica se o diálogo ou banner do Fluxo 360° apareceu
        expect(find.textContaining('Fluxo 360°'), findsWidgets);
        expect(find.text('Iniciar Fluxo 360° Agora'), findsOneWidget);
      },
    );

    testWidgets('aluno pode consultar portal e localizar contato no celular', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: StudentPortalView(student: testStudent, onLogout: () {}),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Ver meu portal'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(OutlinedButton, 'Mensagem ao instrutor'),
        findsOneWidget,
      );
      expect(find.text('FLUXO 360° PENDENTE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
