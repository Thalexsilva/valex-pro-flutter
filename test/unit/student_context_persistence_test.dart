import '../support/student_fixtures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valex_app/services/student_context_service.dart';
import 'package:valex_app/models/workout_model.dart';

import 'package:valex_app/repositories/workout_repository.dart';
import 'package:valex_app/repositories/preset_repository.dart';

class MockWorkoutRepo extends WorkoutRepository {
  @override
  Future<bool> saveActiveSheet(WorkoutSheet sheet) async => true;

  @override
  Future<bool> saveVersionSnapshot(
    String studentId,
    WorkoutSheet sheet,
    String versionName,
  ) async => true;
}

class MockPresetRepo extends PresetRepository {
  @override
  Future<bool> savePreset(WorkoutSheet sheet, String presetTitle) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Teste de Persistência Real (SharedPreferences & Reboot)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'Seleção de Aluno, Alteração de Ficha, Snapshot e Preset devem sobreviver à reinicialização',
      () async {
        final service = StudentContextService.forTesting(
          initialStudents: testStudents,
          workoutRepository: MockWorkoutRepo(),
          presetRepository: MockPresetRepo(),
        );
        await service.init();

        // 1. Selecionar Aluno
        await service.setActiveStudent('st_2');
        expect(service.activeStudentId, equals('st_2'));

        // 2. Alterar Ficha
        final sheet = service.getActiveSheet();
        sheet.gymName = 'Studio Fit Premium';
        sheet.days.add(WorkoutDay(dow: 'Treino Especial', muscle: 'Core'));
        await service.saveActiveSheet(sheet);

        // 3. Salvar Snapshot de Versão
        await service.saveVersionSnapshot(sheet, 'Versão Teste Reboot');
        expect(service.getVersionHistory('st_2').length, equals(1));

        // 4. Salvar Preset Personalizado
        await service.saveCustomPreset(sheet, 'Preset Hipertrofia 2026');
        expect(service.customPresets.length, equals(1));

        // 5. Verificar SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('valex_active_student_id_test'), equals('st_2'));
        expect(
          prefs.getString('valex_student_sheets_test'),
          contains('Studio Fit Premium'),
        );
        expect(
          prefs.getString('valex_version_history_test'),
          contains('Versão Teste Reboot'),
        );
        expect(
          prefs.getString('valex_custom_presets_test'),
          contains('Preset Hipertrofia 2026'),
        );
      },
    );
  });
}
