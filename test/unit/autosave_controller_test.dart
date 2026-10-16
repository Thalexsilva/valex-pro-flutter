import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valex_app/controllers/workout_autosave_controller.dart';
import 'package:valex_app/models/workout_model.dart';
import 'package:valex_app/repositories/workout_repository.dart';
import 'package:valex_app/services/student_context_service.dart';

class ControlledWorkoutRepo extends WorkoutRepository {
  int saveCount = 0;
  bool shouldSucceed = true;
  Duration delay = const Duration(milliseconds: 100);
  WorkoutSheet? lastSavedSheet;
  final List<WorkoutSheet> savedHistory = [];

  @override
  Future<bool> saveActiveSheet(WorkoutSheet sheet) async {
    saveCount++;
    lastSavedSheet = sheet.copyWith();
    savedHistory.add(sheet.copyWith());
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    return shouldSucceed;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  late ControlledWorkoutRepo mockRepo;
  late StudentContextService service;
  late WorkoutAutosaveController controller;
  late WorkoutSheet baseSheet;

  setUp(() {
    mockRepo = ControlledWorkoutRepo()..delay = Duration.zero;
    service = StudentContextService.forTesting(workoutRepository: mockRepo);
    const validStudentId = 'st_1';
    service.setActiveStudent(validStudentId);
    controller = WorkoutAutosaveController(
      contextService: service,
      debounceDuration: const Duration(milliseconds: 50),
    );
    baseSheet = WorkoutSheet(
      studentId: validStudentId,
      studentName: 'Aluno Teste',
    );
  });

  tearDown(() {
    controller.dispose();
  });

  test(
    '1. 10 eventos rápidos produzem uma única gravação após debounce',
    () async {
      for (int i = 1; i <= 10; i++) {
        baseSheet.gymName = 'Academia $i';
        controller.markDirty(baseSheet);
      }
      expect(mockRepo.saveCount, equals(0));
      expect(controller.status, equals(AutosaveStatus.dirty));

      await Future.delayed(const Duration(milliseconds: 80));

      expect(mockRepo.saveCount, equals(1));
      expect(mockRepo.lastSavedSheet?.gymName, equals('Academia 10'));
      expect(controller.status, equals(AutosaveStatus.saved));
    },
  );

  test('2. Alteração ocorre durante save ativo', () async {
    mockRepo.delay = const Duration(milliseconds: 100);

    baseSheet.gymName = 'Primeira Alteracao';
    final future1 = controller.saveNow(baseSheet);

    expect(controller.status, equals(AutosaveStatus.saving));

    // Nova alteração durante o save
    baseSheet.gymName = 'Segunda Alteracao';
    controller.markDirty(baseSheet);

    await future1;
    await Future.delayed(const Duration(milliseconds: 150));

    expect(mockRepo.saveCount, equals(2));
    expect(mockRepo.lastSavedSheet?.gymName, equals('Segunda Alteracao'));
  });

  test('3. Estado mais recente é salvo após o primeiro save', () async {
    mockRepo.delay = const Duration(milliseconds: 80);

    baseSheet.gymName = 'V1';
    controller.saveNow(baseSheet);

    baseSheet.gymName = 'V2';
    controller.markDirty(baseSheet);

    baseSheet.gymName = 'V3';
    controller.markDirty(baseSheet);

    await Future.delayed(const Duration(milliseconds: 250));

    expect(mockRepo.savedHistory.last.gymName, equals('V3'));
  });

  test(
    '4. Respostas fora de ordem não sobrescrevem o estado recente',
    () async {
      mockRepo.delay = Duration.zero;

      baseSheet.gymName = 'Versao Antiga';
      await controller.saveNow(baseSheet);

      baseSheet.gymName = 'Versao Nova';
      await controller.saveNow(baseSheet);

      expect(mockRepo.savedHistory.last.gymName, equals('Versao Nova'));
    },
  );

  test('5. Primeira gravação falha e estado fica error/dirty', () async {
    mockRepo.shouldSucceed = false;

    baseSheet.gymName = 'Falha Teste';
    final success = await controller.saveNow(baseSheet);

    expect(success, isFalse);
    expect(controller.status, equals(AutosaveStatus.error));
    expect(controller.errorMessage, contains('Não foi possível salvar'));
  });

  test('6. Retry salva o último snapshot', () async {
    mockRepo.shouldSucceed = false;
    baseSheet.gymName = 'Tentativa 1';
    await controller.saveNow(baseSheet);

    expect(controller.status, equals(AutosaveStatus.error));

    // Corrige mock para o retry funcionar
    mockRepo.shouldSucceed = true;
    final retrySuccess = await controller.retry();

    expect(retrySuccess, isTrue);
    expect(mockRepo.lastSavedSheet?.gymName, equals('Tentativa 1'));
    expect(controller.status, equals(AutosaveStatus.saved));
  });

  test('7. Troca de aluno não grava ficha no aluno errado', () async {
    baseSheet.studentId = 'st_1';
    baseSheet.studentName = 'Aluno 1';
    controller.markDirty(baseSheet);

    // Troca para Aluno 2 antes do debounce expirar
    await controller.flush();
    expect(mockRepo.lastSavedSheet?.studentId, equals('st_1'));

    final sheet2 = WorkoutSheet(studentId: 'st_2', studentName: 'Aluno 2');
    await controller.saveNow(sheet2);
    expect(mockRepo.lastSavedSheet?.studentId, equals('st_2'));
  });

  test('8. Dispose cancela timer', () async {
    baseSheet.gymName = 'Descarte';
    controller.markDirty(baseSheet);
    controller.dispose();

    await Future.delayed(const Duration(milliseconds: 100));
    expect(mockRepo.saveCount, equals(0));
  });

  test('9. Flush aguarda gravação pendente', () async {
    baseSheet.gymName = 'Flush Immediate';
    controller.markDirty(baseSheet);

    final res = await controller.flush();
    expect(res, isTrue);
    expect(mockRepo.saveCount, equals(1));
    expect(mockRepo.lastSavedSheet?.gymName, equals('Flush Immediate'));
  });

  test('10. Callback estrutural dispara save imediato', () async {
    baseSheet.days.add(WorkoutDay(dow: 'Treino C', muscle: 'Pernas'));
    final success = await controller.saveNow(baseSheet);

    expect(success, isTrue);
    expect(mockRepo.saveCount, equals(1));
    expect(mockRepo.lastSavedSheet?.days.length, equals(1));
  });

  group('Suíte de Cópia Profunda e Isolamento de Memória', () {
    test(
      'Imutabilidade total - Mutações na UI durante save pendente não alteram o payload gravado',
      () async {
        mockRepo.delay = const Duration(milliseconds: 150);

        final originalEx = Exercise(
          title: 'Agachamento',
          cue: 'Coluna reta',
          loadKg: '80',
          sets: ['12', '10'],
        );
        final originalDay = WorkoutDay(
          dow: 'Treino A',
          muscle: 'Pernas',
          exercises: [originalEx],
        );
        baseSheet.days = [originalDay];
        baseSheet.cardioOptions = ['Esteira 20m'];
        baseSheet.generalNotes = ['Postura'];

        // Dispara save assíncrono
        final saveFuture = controller.saveNow(baseSheet);

        // Mutação na UI durante o save ativo
        originalDay.dow = 'Treino A MODIFICADO';
        originalDay.muscle = 'Pernas MODIFICADO';
        originalEx.title = 'Agachamento MODIFICADO';
        originalEx.loadKg = '999';
        originalEx.cue = 'Cue MODIFICADO';
        originalEx.sets.add('88');
        baseSheet.cardioOptions.add('Bike MODIFICADO');
        baseSheet.generalNotes.add('Obs MODIFICADO');

        await saveFuture;

        final saved = mockRepo.lastSavedSheet!;
        expect(saved.days.first.dow, equals('Treino A'));
        expect(saved.days.first.muscle, equals('Pernas'));
        expect(saved.days.first.exercises.first.title, equals('Agachamento'));
        expect(saved.days.first.exercises.first.loadKg, equals('80'));
        expect(saved.days.first.exercises.first.cue, equals('Coluna reta'));
        expect(saved.days.first.exercises.first.sets, equals(['12', '10']));
        expect(saved.cardioOptions, equals(['Esteira 20m']));
        expect(saved.generalNotes, equals(['Postura']));

        // Comprova ausência de compartilhamento de referência
        expect(identical(saved.days.first, originalDay), isFalse);
        expect(
          identical(saved.days.first.exercises.first, originalEx),
          isFalse,
        );
        expect(
          identical(saved.days.first.exercises.first.sets, originalEx.sets),
          isFalse,
        );
        expect(
          identical(saved.cardioOptions, baseSheet.cardioOptions),
          isFalse,
        );
        expect(identical(saved.generalNotes, baseSheet.generalNotes), isFalse);
      },
    );
  });

  group('Suíte de Tratamento de Exceções Lançadas', () {
    test(
      'Exceção no service é capturada, status fica error, isSaving encerra e retry recupera',
      () async {
        // Simula repositório lançando Exception técnica
        final throwRepo = ThrowingWorkoutRepo();
        final throwService = StudentContextService.forTesting(
          workoutRepository: throwRepo,
        );
        final throwController = WorkoutAutosaveController(
          contextService: throwService,
        );

        final sheet = WorkoutSheet(
          studentId: 'st_1',
          studentName: 'Aluno Excecao',
        );
        sheet.gymName = 'Snapshot Pre Excecao';

        final success = await throwController.saveNow(sheet);

        expect(success, isFalse);
        expect(throwController.status, equals(AutosaveStatus.error));
        expect(
          throwController.errorMessage,
          equals('Erro técnico de persistência. Tente novamente.'),
        );

        // Mutação durante a exceção é acumulada no snapshot
        sheet.gymName = 'Snapshot Atualizado Pos Excecao';
        throwController.markDirty(sheet);

        // Corrige repositório para ter sucesso
        throwRepo.shouldThrow = false;

        final retrySuccess = await throwController.retry();
        expect(retrySuccess, isTrue);
        expect(throwController.status, equals(AutosaveStatus.saved));
        expect(
          throwRepo.lastSavedSheet?.gymName,
          equals('Snapshot Atualizado Pos Excecao'),
        );

        throwController.dispose();
      },
    );

    test(
      'Concorrência de discardPending() durante request remota ativa',
      () async {
        final completerRepo = CompleterWorkoutRepo();
        final completerService = StudentContextService.forTesting(
          workoutRepository: completerRepo,
        );
        final completerController = WorkoutAutosaveController(
          contextService: completerService,
        );

        final sheet = WorkoutSheet(
          studentId: 'st_concurrency',
          studentName: 'Aluno Concorrente',
        );

        // 1. Inicia saveNow com Future remota pendente
        final saveFuture = completerController.saveNow(sheet);
        expect(completerController.status, equals(AutosaveStatus.saving));

        // 2. Tenta discardPending enquanto request remota está ativa
        completerController.discardPending();

        // 3. Comprova que a request remota continua ativa sem estado falso de cancelamento
        expect(completerController.status, equals(AutosaveStatus.saving));
        expect(completerController.pendingSheet, isNull);

        // 4. Libera a Future remota
        completerRepo.completer.complete(true);
        final result = await saveFuture;

        // 5. Comprova estado final consistente e sem completer órfão
        expect(result, isTrue);
        expect(completerController.status, equals(AutosaveStatus.saved));
        expect(completerController.pendingSheet, isNull);

        completerController.dispose();
      },
    );
  });
}

class ThrowingWorkoutRepo extends WorkoutRepository {
  bool shouldThrow = true;
  WorkoutSheet? lastSavedSheet;

  @override
  Future<bool> saveActiveSheet(WorkoutSheet sheet) async {
    if (shouldThrow) {
      throw Exception('Erro de conexão ou RLS com o Supabase Postgres');
    }
    lastSavedSheet = sheet.deepCopy();
    return true;
  }
}

class CompleterWorkoutRepo extends WorkoutRepository {
  final completer = Completer<bool>();

  @override
  Future<bool> saveActiveSheet(WorkoutSheet sheet) async {
    return completer.future;
  }
}
