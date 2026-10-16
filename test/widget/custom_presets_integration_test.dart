import '../support/student_fixtures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valex_app/models/workout_model.dart';
import 'package:valex_app/services/student_context_service.dart';
import 'package:valex_app/theme/app_theme.dart';
import 'package:valex_app/views/editor/editor_view.dart';
import 'package:valex_app/views/presets/presets_view.dart';

// Fake service to mock saving custom preset
class IntegrationFakeContextService extends StudentContextService {
  IntegrationFakeContextService()
    : super.forTesting(initialStudents: testStudents);

  bool presetSaved = false;
  String? savedPresetTitle;
  WorkoutSheet? savedPreset;

  @override
  Future<bool> saveActiveSheet(WorkoutSheet sheet) async {
    return true;
  }

  @override
  Future<bool> saveCustomPreset(WorkoutSheet sheet, String presetTitle) async {
    presetSaved = true;
    savedPresetTitle = presetTitle;
    savedPreset = sheet.deepCopy();
    return true;
  }
}

class PresetApplyFakeContextService extends StudentContextService {
  PresetApplyFakeContextService()
    : super.forTesting(initialStudents: testStudents);

  WorkoutSheet currentSheet = WorkoutSheet(
    studentId: 'st_1',
    studentName: 'Carlos Silva',
    gymName: '',
    month: '',
    teacher: '',
    cardioOptions: [],
    generalNotes: [],
    days: [WorkoutDay(dow: 'Treino antigo', muscle: 'Geral', exercises: [])],
  );
  int snapshotCalls = 0;
  int saveCalls = 0;
  bool snapshotSuccess = true;
  bool saveSuccess = true;

  @override
  WorkoutSheet getActiveSheet() => currentSheet;

  @override
  Future<bool> saveVersionSnapshot(WorkoutSheet sheet, String name) async {
    snapshotCalls++;
    expect(sheet.days.single.dow, 'Treino antigo');
    return snapshotSuccess;
  }

  @override
  Future<bool> saveActiveSheet(WorkoutSheet sheet) async {
    saveCalls++;
    currentSheet = sheet.deepCopy();
    return saveSuccess;
  }
}

void main() {
  SharedPreferences.setMockInitialValues({});

  testWidgets('aplicar modelo pede confirmação e preserva ficha ao cancelar', (
    tester,
  ) async {
    final service = PresetApplyFakeContextService();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: PresetsView(contextService: service),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('⚡ Aplicar').first);
    await tester.tap(find.text('⚡ Aplicar').first);
    await tester.pumpAndSettle();

    expect(find.text('Aplicar modelo à ficha?'), findsOneWidget);
    expect(find.textContaining('Aluno: Carlos Silva'), findsOneWidget);
    expect(find.textContaining('Treinos atuais: 1'), findsOneWidget);
    expect(find.textContaining('Treinos do modelo: 1'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(service.snapshotCalls, 0);
    expect(service.saveCalls, 0);
    expect(service.currentSheet.days.single.dow, 'Treino antigo');
  });

  testWidgets('aplicar modelo salva versão e só navega após gravação', (
    tester,
  ) async {
    final service = PresetApplyFakeContextService();
    var openEditorCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: PresetsView(
          contextService: service,
          onOpenEditor: () => openEditorCalls++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('⚡ Aplicar').first);
    await tester.tap(find.text('⚡ Aplicar').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Substituir treinos'));
    await tester.pumpAndSettle();

    expect(service.snapshotCalls, 1);
    expect(service.saveCalls, 1);
    expect(service.currentSheet.days.single.dow, 'Treino A');
    expect(openEditorCalls, 1);
    expect(find.textContaining('aplicado à ficha'), findsOneWidget);
  });

  testWidgets('falha de gravação restaura ficha e não navega', (tester) async {
    final service = PresetApplyFakeContextService()..saveSuccess = false;
    var openEditorCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: PresetsView(
          contextService: service,
          onOpenEditor: () => openEditorCalls++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('⚡ Aplicar').first);
    await tester.tap(find.text('⚡ Aplicar').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Substituir treinos'));
    await tester.pumpAndSettle();

    expect(service.snapshotCalls, 1);
    expect(service.saveCalls, 2);
    expect(service.currentSheet.days.single.dow, 'Treino antigo');
    expect(openEditorCalls, 0);
    expect(
      find.textContaining('Não foi possível salvar o modelo'),
      findsOneWidget,
    );
  });

  testWidgets('falha ao criar versão impede substituição', (tester) async {
    final service = PresetApplyFakeContextService()..snapshotSuccess = false;
    var openEditorCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: PresetsView(
          contextService: service,
          onOpenEditor: () => openEditorCalls++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('⚡ Aplicar').first);
    await tester.tap(find.text('⚡ Aplicar').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Substituir treinos'));
    await tester.pumpAndSettle();

    expect(service.snapshotCalls, 1);
    expect(service.saveCalls, 0);
    expect(service.currentSheet.days.single.dow, 'Treino antigo');
    expect(openEditorCalls, 0);
    expect(find.textContaining('A ficha não foi substituída'), findsOneWidget);
  });

  testWidgets(
    'Integration Test: General interaction flow and Custom Preset saving',
    (WidgetTester tester) async {
      final fakeService = IntegrationFakeContextService();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: EditorView(contextService: fakeService),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Add a new Workout Day
      await tester.tap(find.text('Novo treino'));
      await tester.pumpAndSettle();

      // We should see "Treino A" added
      expect(find.text('Treino A'), findsWidgets);

      // Selection does not add anything until a valid prescription is confirmed.
      expect(fakeService.getActiveSheet().days.single.exercises, isEmpty);
      await tester.ensureVisible(find.text('Adicionar exercício').first);
      await tester.tap(find.text('Adicionar exercício').first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('exercise-library-search')),
        'agachamento livre',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('exercise-library-item-Agachamento Livre com Barra'),
        ),
      );
      await tester.pumpAndSettle();
      expect(fakeService.getActiveSheet().days.single.exercises, isEmpty);

      Finder field(String id) => find.descendant(
        of: find.byKey(ValueKey('prescription-$id')),
        matching: find.byType(TextFormField),
      );
      await tester.ensureVisible(field('sets'));
      await tester.enterText(field('sets'), '3');
      await tester.ensureVisible(field('reps'));
      await tester.enterText(field('reps'), '8-12');
      await tester.ensureVisible(field('load'));
      await tester.enterText(field('load'), '12,5');
      await tester.tap(find.byKey(const ValueKey('prescription-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Agachamento Livre com Barra'), findsOneWidget);
      final addedExercise = fakeService
          .getActiveSheet()
          .days
          .single
          .exercises
          .single;
      expect(addedExercise.loadKg, '12,5');
      expect(addedExercise.sets, List.filled(3, '[work]8-12 reps'));

      // Detailed edits retain the set text and can return to the summary.
      await tester.ensureVisible(find.text('Editar detalhes'));
      await tester.tap(find.text('Editar detalhes'));
      await tester.pumpAndSettle();
      final firstSet = find.widgetWithText(
        TextFormField,
        'Descrição da série 1',
      );
      await tester.ensureVisible(firstSet);
      await tester.enterText(firstSet, '[work]8 reps @ 75%');
      await tester.ensureVisible(find.text('Concluir edição'));
      await tester.tap(find.text('Concluir edição'));
      await tester.pumpAndSettle();
      expect(find.text('8 reps @ 75%'), findsOneWidget);

      // Removing an exercise can be undone without losing the prescription.
      await tester.ensureVisible(find.byTooltip('Ações do exercício'));
      await tester.tap(find.byTooltip('Ações do exercício'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir exercício'));
      await tester.pumpAndSettle();
      expect(fakeService.getActiveSheet().days.single.exercises, isEmpty);
      await tester.tap(find.text('Desfazer'));
      await tester.pumpAndSettle();
      expect(
        fakeService.getActiveSheet().days.single.exercises.single.sets.first,
        '[work]8 reps @ 75%',
      );

      // 3. Save as Custom Preset
      await tester.ensureVisible(find.byTooltip('Mais ações do editor'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Mais ações do editor'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar como preset'));
      await tester.pumpAndSettle();

      expect(find.text('Salvar como Preset Personalizado'), findsOneWidget);

      await tester.enterText(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextField),
            )
            .first,
        'Preset de Força Perna',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar Preset'));
      await tester.pumpAndSettle();

      // Check if it was saved via the mock service
      expect(fakeService.presetSaved, isTrue);
      expect(fakeService.savedPresetTitle, equals('Preset de Força Perna'));
      expect(
        fakeService.savedPreset!.days.single.exercises.single.toJson(),
        addedExercise.toJson(),
      );
      expect(find.textContaining('salvo com sucesso'), findsOneWidget);
    },
  );
}
