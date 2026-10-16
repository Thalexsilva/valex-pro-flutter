import 'package:flutter_test/flutter_test.dart';

class MockStudent {
  final String id;
  final String trainerId;
  final String name;

  MockStudent({required this.id, required this.trainerId, required this.name});
}

class MockWorkoutSheet {
  final String id;
  final String studentId;
  final String trainerId;
  final String name;

  MockWorkoutSheet({
    required this.id,
    required this.studentId,
    required this.trainerId,
    required this.name,
  });
}

class MockDatabase {
  final List<MockStudent> students = [];
  final List<MockWorkoutSheet> sheets = [];

  // Simula constraint de FK Composta: FOREIGN KEY (student_id, trainer_id) REFERENCES students(id, trainer_id)
  void insertWorkoutSheet({
    required String activeUserId,
    required String sheetId,
    required String studentId,
    required String sheetTrainerId,
    required String name,
  }) {
    // 1. RLS Check
    if (activeUserId != sheetTrainerId) {
      throw Exception('RLS Violation: Auth UID mismatch (403 Forbidden)');
    }

    // 2. Composite FK Constraint Check
    final studentExistsForTenant = students.any(
      (s) => s.id == studentId && s.trainerId == sheetTrainerId,
    );

    if (!studentExistsForTenant) {
      throw Exception(
        'FK Composite Constraint Violation: (student_id, trainer_id) not found in students table',
      );
    }

    sheets.add(
      MockWorkoutSheet(
        id: sheetId,
        studentId: studentId,
        trainerId: sheetTrainerId,
        name: name,
      ),
    );
  }

  List<MockWorkoutSheet> selectWorkoutSheets(String activeUserId) {
    // RLS SELECT
    return sheets.where((s) => s.trainerId == activeUserId).toList();
  }

  void updateWorkoutSheet(String activeUserId, String sheetId, String newName) {
    final index = sheets.indexWhere(
      (s) => s.id == sheetId && s.trainerId == activeUserId,
    );
    if (index < 0) {
      throw Exception(
        'RLS Violation: Record not found or unauthorized to update',
      );
    }
    final existing = sheets[index];
    sheets[index] = MockWorkoutSheet(
      id: existing.id,
      studentId: existing.studentId,
      trainerId: existing.trainerId,
      name: newName,
    );
  }
}

void main() {
  group(
    'Testes de Validação de FK Composta e RLS Multi-Tenant (Simulação Estrita)',
    () {
      late MockDatabase db;
      final trainerA = 'trainer_uuid_aaa';
      final trainerB = 'trainer_uuid_bbb';

      final studentA = MockStudent(
        id: 'st_aaa',
        trainerId: trainerA,
        name: 'Aluno A',
      );
      final studentB = MockStudent(
        id: 'st_bbb',
        trainerId: trainerB,
        name: 'Aluno B',
      );

      setUp(() {
        db = MockDatabase();
        db.students.add(studentA);
        db.students.add(studentB);
      });

      test('1 & 3. Treinador A cria ficha para Aluno A (Sucesso)', () {
        expect(
          () => db.insertWorkoutSheet(
            activeUserId: trainerA,
            sheetId: 'sheet_1',
            studentId: studentA.id,
            sheetTrainerId: trainerA,
            name: 'Ficha de Treino A',
          ),
          returnsNormally,
        );
        expect(db.sheets.length, equals(1));
      });

      test(
        '4 & 5. Treinador A tenta criar ficha apontando para Aluno B (Rejeição por FK Composta)',
        () {
          expect(
            () => db.insertWorkoutSheet(
              activeUserId: trainerA,
              sheetId: 'sheet_invalid',
              studentId: studentB.id, // Pertence ao Trainer B!
              sheetTrainerId: trainerA,
              name: 'Ficha Cruzada Inválida',
            ),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('FK Composite Constraint Violation'),
              ),
            ),
          );
        },
      );

      test(
        '6 & 7. Treinador B tenta ler ficha de Treinador A (Rejeição por RLS)',
        () {
          db.insertWorkoutSheet(
            activeUserId: trainerA,
            sheetId: 'sheet_1',
            studentId: studentA.id,
            sheetTrainerId: trainerA,
            name: 'Ficha de Treino A',
          );

          final sheetsVisibleToB = db.selectWorkoutSheets(trainerB);
          expect(
            sheetsVisibleToB,
            isEmpty,
            reason:
                'RLS impede Treinador B de visualizar fichas de Treinador A',
          );
        },
      );

      test(
        '8 & 9. Treinador B tenta alterar ficha de Treinador A (Rejeição por RLS)',
        () {
          db.insertWorkoutSheet(
            activeUserId: trainerA,
            sheetId: 'sheet_1',
            studentId: studentA.id,
            sheetTrainerId: trainerA,
            name: 'Ficha de Treino A',
          );

          expect(
            () => db.updateWorkoutSheet(trainerB, 'sheet_1', 'Nome Hackeado'),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('RLS Violation'),
              ),
            ),
          );
        },
      );
    },
  );
}
