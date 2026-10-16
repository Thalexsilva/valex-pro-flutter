import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valex_app/views/students/anamnese_form_wizard_view.dart';
import 'package:valex_app/repositories/anamnese_repository.dart';
import 'package:valex_app/models/anamnese_model.dart';

void main() {
  testWidgets('new step scrolls to top and announces its title', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(360, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(home: AnamneseFormWizardView()));
    await tester.pumpAndSettle();
    final scrollable = find.byType(SingleChildScrollView).first;
    await tester.drag(scrollable, const Offset(0, -400));
    await tester.pumpAndSettle();
    final scrollPosition = tester
        .widget<SingleChildScrollView>(scrollable)
        .controller!
        .position;
    expect(scrollPosition.pixels, greaterThan(0));
    await tester.tap(find.text('Próximo Passo'));
    await tester.pumpAndSettle();
    expect(scrollPosition.pixels, 0);
    expect(find.bySemanticsLabel(RegExp('Passo 2 de 7')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('step navigation and route exit preserve the local draft', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const AnamneseFormWizardView(),
                ),
              ),
              child: const Text('Abrir avaliação'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir avaliação'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nome Completo *'),
      'Ana',
    );
    await tester.tap(find.text('Próximo Passo'));
    await tester.pumpAndSettle();
    expect(
      (await AnamneseRepository().getLocalDraft('temp_draft'))?.name,
      'Ana',
    );

    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nome Completo *'),
      'Ana Maria',
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Abrir avaliação'), findsOneWidget);
    expect(
      (await AnamneseRepository().getLocalDraft('temp_draft'))?.name,
      'Ana Maria',
    );
  });

  testWidgets('consent starts unchecked even when a draft had accepted it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AnamneseRepository().saveLocalDraft(
      AnamneseModel(
        id: 'draft-consent',
        studentId: 'temp_draft',
        name: 'Ana',
        consentAccepted: true,
      ),
    );
    await tester.pumpWidget(const MaterialApp(home: AnamneseFormWizardView()));
    await tester.pumpAndSettle();
    for (var step = 0; step < 6; step++) {
      await tester.tap(find.text('Próximo Passo'));
      await tester.pumpAndSettle();
    }
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Finalizar'),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('new assessment draft keeps unknown measurements empty', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: AnamneseFormWizardView()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Salvar Rascunho'));
    await tester.pumpAndSettle();

    final draft = await AnamneseRepository().getLocalDraft('temp_draft');
    expect(draft, isNotNull);
    expect(draft!.weightKg, 0);
    expect(draft.heightCm, 0);
    expect(draft.bioimpedance, isNull);
  });

  testWidgets('editing keeps assessment identity in the saved draft', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final existing = AnamneseModel(
      id: 'existing-assessment',
      studentId: 'temp_draft',
      name: 'Ana',
      weightKg: 62,
      heightCm: 165,
      age: 31,
      instructorNotes: 'Preservar notas',
      bodyPerception: 'Resposta anterior',
      alcoholHabit: 'Ocasional',
      createdAt: DateTime(2025, 1, 2),
    );
    await AnamneseRepository().saveLocalDraft(
      existing.copyWith(name: 'Ana atualizada'),
    );
    await tester.pumpWidget(
      MaterialApp(home: AnamneseFormWizardView(initialAnamnese: existing)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Salvar Rascunho'));
    await tester.pumpAndSettle();
    final draft = await AnamneseRepository().getLocalDraft('temp_draft');
    expect(draft?.id, existing.id);
    expect(draft?.name, 'Ana atualizada');
    expect(draft?.age, 31);
    expect(draft?.instructorNotes, 'Preservar notas');
    expect(draft?.bodyPerception, 'Resposta anterior');
    expect(draft?.alcoholHabit, 'Ocasional');
    expect(draft?.createdAt, DateTime(2025, 1, 2));
  });
  for (final width in [360.0, 1024.0]) {
    testWidgets('anamnese seven steps at $width px', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await AnamneseRepository().saveLocalDraft(
        AnamneseModel(
          id: 'draft',
          studentId: 'temp_draft',
          name: 'Teste',
          weightKg: 70,
          heightCm: 170,
          posturePhotos: [
            PosturePhoto(
              id: 'photo',
              angle: PostureAngle.front,
              url: 'storage://student-documents/student/posture/photo.jpg',
              fileName: 'photo.jpg',
              fileSizeBytes: 100,
            ),
          ],
        ),
      );
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(home: AnamneseFormWizardView()),
      );
      await tester.pumpAndSettle();
      for (var step = 0; step < 6; step++) {
        expect(tester.takeException(), isNull, reason: 'step $step');
        await tester.tap(find.text('Próximo Passo'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Finalizar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
