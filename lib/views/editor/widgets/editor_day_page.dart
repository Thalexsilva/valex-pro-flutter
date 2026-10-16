import 'package:flutter/material.dart';
import '../../../models/workout_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import 'day_badge_text.dart';
import 'editor_exercise_card.dart';

/// Uma página de dia de treino (.day-page), páginas 3..N da ficha virtual —
/// equivalente a `js/pdf.js#renderDayPage`.
///
/// Recebe `day` por referência (mutável) e aplica edições de texto direto
/// nele; mudanças que precisam refletir na UI (toggle de cardio, reordenar
/// exercícios) passam por [mutate], que delega o `setState` para
/// `EditorView`.
class EditorDayPage extends StatelessWidget {
  final WorkoutDay day;
  final int dayIndex;
  final int pageNo;
  final int totalPages;

  /// Dias diferentes do atual, para o menu "Mover para outro dia" de cada
  /// exercício (índice real na ficha, rótulo do dia).
  final List<MapEntry<int, String>> otherDaysForMove;

  final void Function(VoidCallback mutation) mutate;
  final VoidCallback markDirty;

  final void Function(int delta) onMoveDay;
  final VoidCallback onDuplicateDay;
  final VoidCallback onDeleteDay;
  final VoidCallback onOpenLibrary;
  final VoidCallback onBackToIndex;

  final void Function(Exercise ex, int exIndex, [int? setIndex]) onOpenCalcLoad;
  final void Function(int exIndex, int setIndex) onToggleSetType;
  final void Function(int exIndex, int setIndex, String type) onSetTypeExplicit;
  final void Function(int exIndex, int setIndex, int delta) onMoveSet;
  final void Function(int exIndex, int setIndex) onDeleteSet;
  final void Function(int exIndex) onAddSet;
  final void Function(int exIndex) onDuplicateExercise;
  final void Function(int exIndex, int delta) onMoveExercise;
  final void Function(int exIndex, int targetDayIndex) onMoveExerciseToDay;
  final void Function(int exIndex) onDeleteExercise;

  const EditorDayPage({
    super.key,
    required this.day,
    required this.dayIndex,
    required this.pageNo,
    required this.totalPages,
    required this.otherDaysForMove,
    required this.mutate,
    required this.markDirty,
    required this.onMoveDay,
    required this.onDuplicateDay,
    required this.onDeleteDay,
    required this.onOpenLibrary,
    required this.onBackToIndex,
    required this.onOpenCalcLoad,
    required this.onToggleSetType,
    required this.onSetTypeExplicit,
    required this.onMoveSet,
    required this.onDeleteSet,
    required this.onAddSet,
    required this.onDuplicateExercise,
    required this.onMoveExercise,
    required this.onMoveExerciseToDay,
    required this.onDeleteExercise,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.paperCard,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day Header
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.carbon,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/images/logo.png', height: 20),
                        const SizedBox(width: 8),
                        Text(
                          'FICHA DE TREINO',
                          style: AppTheme.labelCaps(color: AppColors.blueLight),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.favorite,
                            color: day.cardio
                                ? AppColors.gold
                                : AppColors.steelDim,
                            size: 18,
                          ),
                          tooltip: day.cardio
                              ? 'Cardio ativado para este treino (clique para alternar)'
                              : 'Cardio desativado (clique para alternar)',
                          onPressed: () {
                            mutate(() {
                              day.cardio = !day.cardio;
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_upward,
                            color: AppColors.steel,
                            size: 18,
                          ),
                          tooltip: 'Mover treino para cima',
                          onPressed: () => onMoveDay(-1),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_downward,
                            color: AppColors.steel,
                            size: 18,
                          ),
                          tooltip: 'Mover treino para baixo',
                          onPressed: () => onMoveDay(1),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.copy,
                            color: AppColors.blueLight,
                            size: 18,
                          ),
                          tooltip: 'Duplicar dia',
                          onPressed: onDuplicateDay,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: AppColors.crimson,
                            size: 18,
                          ),
                          tooltip: 'Excluir dia',
                          onPressed: onDeleteDay,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        getDayBadgeText(day.dow),
                        style: const TextStyle(
                          fontFamily: 'BebasNeue',
                          fontSize: 26,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            initialValue: day.dow,
                            style: AppTheme.labelCaps(
                              color: AppColors.blueLight,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                            ),
                            onChanged: (v) {
                              day.dow = v;
                              markDirty();
                            },
                          ),
                          TextFormField(
                            initialValue: day.muscle,
                            style: AppTheme.headlineLg(color: Colors.white),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                            ),
                            onChanged: (v) {
                              day.muscle = v;
                              markDirty();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Day Body (Exercises)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (day.exercises.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: Text(
                      'Escolha um exercício da biblioteca. Depois, defina a prescrição para este treino.',
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyLg(color: AppColors.paperMuted),
                    ),
                  )
                else
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: day.exercises.length,
                    onReorderItem: (oldIndex, newIndex) {
                      mutate(() {
                        final ex = day.exercises.removeAt(oldIndex);
                        day.exercises.insert(newIndex, ex);
                      });
                    },
                    itemBuilder: (ctx, exIndex) {
                      final ex = day.exercises[exIndex];
                      return Container(
                        key: ObjectKey(ex),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: EditorExerciseCard(
                          exercise: ex,
                          displayIndex: exIndex,
                          otherDaysForMove: otherDaysForMove,
                          mutate: mutate,
                          markDirty: markDirty,
                          onOpenCalcLoad: (setIndex) =>
                              onOpenCalcLoad(ex, exIndex, setIndex),
                          onToggleSetType: (setIndex) =>
                              onToggleSetType(exIndex, setIndex),
                          onSetTypeExplicit: (setIndex, type) =>
                              onSetTypeExplicit(exIndex, setIndex, type),
                          onMoveSet: (setIndex, delta) =>
                              onMoveSet(exIndex, setIndex, delta),
                          onDeleteSet: (setIndex) =>
                              onDeleteSet(exIndex, setIndex),
                          onAddSet: () => onAddSet(exIndex),
                          onDuplicate: () => onDuplicateExercise(exIndex),
                          onMove: (delta) => onMoveExercise(exIndex, delta),
                          onMoveToDay: (targetDay) =>
                              onMoveExerciseToDay(exIndex, targetDay),
                          onDelete: () => onDeleteExercise(exIndex),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 12),

                // Add Exercise Buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.menu_book, size: 16),
                      label: const Text('Adicionar exercício'),
                      onPressed: onOpenLibrary,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.paperBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),

                if (day.cardio)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('🫀', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Finalizar com protocolo de Cardio — ver pág $totalPages',
                              style: AppTheme.bodyMd(color: AppColors.ink),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  'VALEX · Biomechanics & Rehabilitation',
                  style: AppTheme.labelCaps(color: AppColors.paperMuted),
                ),
                InkWell(
                  onTap: onBackToIndex,
                  child: Text(
                    'Voltar ao índice',
                    style: AppTheme.bodyMd(color: AppColors.paperBlue),
                  ),
                ),
                Text(
                  'Página $pageNo de $totalPages',
                  style: AppTheme.bodyMd(color: AppColors.paperMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
