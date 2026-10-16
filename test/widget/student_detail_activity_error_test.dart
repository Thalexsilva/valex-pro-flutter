import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valex_app/models/student_model.dart';
import 'package:valex_app/repositories/anamnese_repository.dart';
import 'package:valex_app/repositories/student_workout_repository.dart';
import 'package:valex_app/views/students/student_detail_view.dart';

class _ActivityRepository extends StudentWorkoutRepository {
  bool fail = true;

  @override
  Future<List<StudentWorkoutEntry>> fetchEntries(String studentId) async {
    if (fail) throw StateError('Atividade indisponível');
    return [];
  }
}

class _AssessmentRepository extends AnamneseRepository {
  bool fail = true;

  @override
  Future<AnamneseLoadResult> fetchHistoryResult(String studentId) async {
    return AnamneseLoadResult(
      fail ? AnamneseLoadStatus.error : AnamneseLoadStatus.empty,
      const [],
    );
  }
}

void main() {
  testWidgets('detalhe distingue erro de atividade de lista vazia', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final activityRepository = _ActivityRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentDetailView(
            student: Student(id: 'activity-test', name: 'Aluno Teste'),
            activityRepository: activityRepository,
            onEdit: () {},
            onToggleArchive: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comentários'));
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível carregar a atividade do aluno.'),
      findsOneWidget,
    );
    expect(find.text('Nenhum comentário ou treino registrado.'), findsNothing);

    activityRepository.fail = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível carregar a atividade do aluno.'),
      findsNothing,
    );
    expect(
      find.text('Nenhum comentário ou treino registrado.'),
      findsOneWidget,
    );
  });

  testWidgets('detalhe distingue falha de avaliação de ausência real', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final assessmentRepository = _AssessmentRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentDetailView(
            student: Student(id: 'assessment-test', name: 'Aluno Teste'),
            assessmentRepository: assessmentRepository,
            onEdit: () {},
            onToggleArchive: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Não foi possível consultar a avaliação 360°. Os dados exibidos podem estar desatualizados.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Nenhuma anamnese registrada para este aluno ainda.'),
      findsNothing,
    );

    assessmentRepository.fail = false;
    await tester.tap(find.text('Atualizar avaliação').first);
    await tester.pumpAndSettle();

    expect(find.text('Atualizar avaliação'), findsNothing);
    expect(
      find.text('Nenhuma anamnese registrada para este aluno ainda.'),
      findsOneWidget,
    );
  });
}
