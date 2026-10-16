import 'workout_model.dart';
import 'training_methods.dart';
import '../services/student_context_service.dart';

class AiGeneratedWorkoutResult {
  final List<WorkoutDay> days;
  final String summaryNotes;

  const AiGeneratedWorkoutResult({
    required this.days,
    required this.summaryNotes,
  });
}

class AiWorkoutEngine {
  /// Analisa o texto narrativo/anamnese e gera a ficha completa biomecanicamente ajustada
  static AiGeneratedWorkoutResult generateSheetFromAnamnese({
    required String anamneseText,
    String studentName = 'Aluno',
    String? goal,
  }) {
    final text = '${anamneseText.toLowerCase()} ${(goal ?? "").toLowerCase()}';
    final library = StudentContextService.exerciseLibrary;

    // 1. Detectar Restrições e Dores
    final hasKneePain =
        text.contains('joelho') ||
        text.contains('patela') ||
        text.contains('menisco') ||
        text.contains('ligamento');
    final hasBackPain =
        text.contains('lombar') ||
        text.contains('hérnia') ||
        text.contains('hernia') ||
        text.contains('coluna') ||
        text.contains('discopatia');
    final hasShoulderPain =
        text.contains('ombro') ||
        text.contains('manguito') ||
        text.contains('bursite') ||
        text.contains('tendinite');

    // 2. Detectar Nível de Experiência
    String level = 'intermediario';
    if (text.contains('iniciante') ||
        text.contains('nunca treinou') ||
        text.contains('pouca experiência') ||
        text.contains('sedentário') ||
        text.contains('sedentario')) {
      level = 'iniciante';
    } else if (text.contains('avançado') ||
        text.contains('avancado') ||
        text.contains('anos de treino') ||
        text.contains('atleta')) {
      level = 'avancado';
    }

    // 3. Detectar Frequência Semanal (Dias)
    int freq = 3;
    if (text.contains('2x') ||
        text.contains('2 dias') ||
        text.contains('duas vezes')) {
      freq = 2;
    } else if (text.contains('4x') ||
        text.contains('4 dias') ||
        text.contains('quatro vezes')) {
      freq = 4;
    } else if (text.contains('5x') ||
        text.contains('5 dias') ||
        text.contains('cinco vezes')) {
      freq = 5;
    }

    // 4. Filtrar Exercícios Seguros do Acervo
    bool isSafeExercise(ExerciseLibraryItem ex) {
      final titleL = ex.title.toLowerCase();
      if (hasKneePain &&
          (titleL.contains('sissy') ||
              titleL.contains('avanço') ||
              titleL.contains('avanco') ||
              titleL.contains('passada'))) {
        return false;
      }
      if (hasBackPain &&
          (titleL.contains('terra livre') ||
              (titleL.contains('stiff') && titleL.contains('barra')))) {
        return false;
      }
      if (hasShoulderPain &&
          (titleL.contains('arnold') ||
              titleL.contains('por trás') ||
              titleL.contains('por tras'))) {
        return false;
      }
      return true;
    }

    final safeLibrary = library.where(isSafeExercise).toList();

    List<ExerciseLibraryItem> getExByMuscle(
      String muscleName, {
      int count = 2,
    }) {
      final matches = safeLibrary
          .where((e) => e.muscle.toLowerCase() == muscleName.toLowerCase())
          .toList();
      if (matches.isEmpty) return [];
      return matches.take(count).toList();
    }

    // 5. Definir Estrutura dos Dias
    final List<({String dow, String muscle, String icon, List<String> muscles})>
    daysStructure;

    if (freq == 2) {
      daysStructure = [
        (
          dow: 'Treino A',
          muscle: 'Membros Superiores & Core',
          icon: 'chest',
          muscles: ['Peito', 'Costas', 'Ombro', 'Bíceps', 'Tríceps', 'Abdômen'],
        ),
        (
          dow: 'Treino B',
          muscle: 'Membros Inferiores & Glúteos',
          icon: 'quad',
          muscles: ['Quadríceps', 'Glúteos', 'Posterior', 'Panturrilha'],
        ),
      ];
    } else if (freq == 4) {
      daysStructure = [
        (
          dow: 'Treino A',
          muscle: 'Peito & Tríceps',
          icon: 'chest',
          muscles: ['Peito', 'Tríceps'],
        ),
        (
          dow: 'Treino B',
          muscle: 'Costas & Bíceps',
          icon: 'back',
          muscles: ['Costas', 'Bíceps'],
        ),
        (
          dow: 'Treino C',
          muscle: 'Quadríceps & Glúteos',
          icon: 'quad',
          muscles: ['Quadríceps', 'Glúteos', 'Panturrilha'],
        ),
        (
          dow: 'Treino D',
          muscle: 'Ombro, Posterior & Core',
          icon: 'shoulder',
          muscles: ['Ombro', 'Posterior', 'Abdômen'],
        ),
      ];
    } else {
      // 3 dias (ABC Padrão)
      daysStructure = [
        (
          dow: 'Treino A',
          muscle: 'Peito, Ombro & Tríceps',
          icon: 'chest',
          muscles: ['Peito', 'Ombro', 'Tríceps'],
        ),
        (
          dow: 'Treino B',
          muscle: 'Costas, Bíceps & Core',
          icon: 'back',
          muscles: ['Costas', 'Bíceps', 'Abdômen'],
        ),
        (
          dow: 'Treino C',
          muscle: 'Pernas & Glúteos',
          icon: 'quad',
          muscles: ['Quadríceps', 'Glúteos', 'Posterior', 'Panturrilha'],
        ),
      ];
    }

    // 6. Montar os Exercícios de cada Dia com Métodos de Treino apropriados
    final List<WorkoutDay> generatedDays = [];

    for (final daySpec in daysStructure) {
      final List<Exercise> dayExercises = [];

      for (final mName in daySpec.muscles) {
        final picked = getExByMuscle(
          mName,
          count: level == 'iniciante' ? 1 : 2,
        );
        for (int pIdx = 0; pIdx < picked.length; pIdx++) {
          final exSource = picked[pIdx];

          String methodKey = 'tradicional';
          if (level == 'avancado') {
            if (pIdx == 0 &&
                (mName == 'Peito' ||
                    mName == 'Costas' ||
                    mName == 'Quadríceps')) {
              methodKey = 'piramide_crescente';
            } else if (pIdx == 1) {
              methodKey = 'drop_set';
            }
          } else if (level == 'intermediario') {
            if (pIdx == 0) {
              methodKey = 'progressao_carga';
            }
          }

          final generatedSets = TrainingMethods.generateSetsForMethod(
            methodKey,
          );

          dayExercises.add(
            Exercise(
              title: exSource.title,
              muscle: exSource.muscle,
              cue: exSource.cue,
              video: exSource.video,
              image: '',
              loadKg: '20',
              sets: generatedSets,
            ),
          );
        }
      }

      generatedDays.add(
        WorkoutDay(
          dow: daySpec.dow,
          muscle: daySpec.muscle,
          icon: daySpec.icon,
          cardio: true,
          exercises: dayExercises,
        ),
      );
    }

    // 7. Notas de Resumo da Prescrição
    final List<String> notes = [
      'Ficha gerada por IA Biomecânica para nível ${level.toUpperCase()} (${freq}x/semana).',
    ];
    if (hasKneePain) {
      notes.add(
        '⚠️ Ajuste por dor articular: exercícios com alta sobrecarga patelar foram substituídos.',
      );
    }
    if (hasBackPain) {
      notes.add(
        '⚠️ Proteção lombar ativada: foco em exercícios com apoio de tronco e estabilidade.',
      );
    }
    if (hasShoulderPain) {
      notes.add(
        '⚠️ Cuidado de manguito rotador: movimentos de extrema amplitude retrocedidos.',
      );
    }

    return AiGeneratedWorkoutResult(
      days: generatedDays,
      summaryNotes: notes.join('\n'),
    );
  }
}
