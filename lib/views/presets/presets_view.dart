import 'dart:convert';

import 'package:flutter/material.dart';
import '../../models/workout_model.dart';
import '../../models/training_methods.dart';
import '../editor/dialogs/exercise_library_sheet.dart';
import '../../services/student_context_service.dart';
import '../../services/catalog_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class PresetsView extends StatefulWidget {
  final VoidCallback? onOpenEditor;
  final StudentContextService? contextService;
  const PresetsView({super.key, this.onOpenEditor, this.contextService});

  @override
  State<PresetsView> createState() => _PresetsViewState();
}

class _PresetsViewState extends State<PresetsView> {
  late final StudentContextService _contextService =
      widget.contextService ?? StudentContextService();
  String _selectedTab = 'presets'; // 'presets' or 'acervo'
  bool _isApplyingPreset = false;
  @override
  void initState() {
    super.initState();
    _contextService.addListener(_onContextUpdated);
    CatalogService.instance.addListener(_onContextUpdated);
  }

  @override
  void dispose() {
    _contextService.removeListener(_onContextUpdated);
    CatalogService.instance.removeListener(_onContextUpdated);
    super.dispose();
  }

  void _onContextUpdated() {
    if (mounted) setState(() {});
  }

  void _applyNativePreset(String key) async {
    if (_isApplyingPreset) return;
    final activeSt = _contextService.activeStudent;
    if (activeSt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um aluno antes de aplicar um preset!'),
          backgroundColor: AppColors.crimson,
        ),
      );
      return;
    }

    List<WorkoutDay> newDays = [];
    if (key == 'blank') {
      newDays = [
        WorkoutDay(
          dow: 'Treino A',
          muscle: 'Geral',
          icon: 'chest',
          cardio: true,
          exercises: [],
        ),
      ];
    } else if (key == 'abc') {
      newDays = [
        WorkoutDay(
          dow: 'Treino A',
          muscle: 'Peito & Tríceps',
          icon: 'chest',
          cardio: true,
          exercises: [
            WorkoutExercise(
              title: 'Peck Deck',
              muscle: 'Peito',
              cue: 'Fechamento cadenciado e escápulas travadas',
              sets: [
                '[warmup]Aquecimento: 12-15 reps @ 50%',
                '[prep]Série de preparação: 10 reps @ 65%',
                '[work]Série de trabalho: 8-12 reps @ 75%',
              ],
            ),
            WorkoutExercise(
              title: 'Supino reto',
              muscle: 'Peito',
              cue: 'Escápulas retraídas, barra na linha do mamilo',
              sets: [
                '[prep]Série de preparação: 12 reps @ 60%',
                '[work]2ª Série: 10 reps @ 70%',
                '[work]3ª Série: 8 reps @ 80%',
              ],
            ),
            WorkoutExercise(
              title: 'Tríceps na polia com barra',
              muscle: 'Tríceps',
              cue: 'Cotovelos fixos ao lado do tronco',
              sets: [
                '[prep]Série de preparação: 12 reps',
                '[work]Série de trabalho: 10 reps',
                '[work]Série de trabalho: 8 reps',
              ],
            ),
          ],
        ),
        WorkoutDay(
          dow: 'Treino B',
          muscle: 'Costas & Bíceps',
          icon: 'back',
          cardio: true,
          exercises: [
            WorkoutExercise(
              title: 'Puxada frontal',
              muscle: 'Costas',
              cue: 'Puxar em direção ao peitoral superior',
              sets: [
                '[warmup]Aquecimento: 12-15 reps',
                '[prep]Preparação: 10 reps',
                '[work]Trabalho: 8-10 reps',
              ],
            ),
            WorkoutExercise(
              title: 'Remada Baixa com triângulo',
              muscle: 'Costas',
              cue: 'Coluna ereta, puxada no abdômen',
              sets: [
                '[prep]Preparação: 12 reps',
                '[work]Trabalho: 10 reps',
                '[work]Trabalho: 8 reps',
              ],
            ),
            WorkoutExercise(
              title: 'Scott no banco',
              muscle: 'Bíceps',
              cue: 'Extensão controlada e contração no topo',
              sets: [
                '[prep]Preparação: 12 reps',
                '[work]Trabalho: 8-10 reps',
                '[work]Trabalho: 8-10 reps',
              ],
            ),
          ],
        ),
        WorkoutDay(
          dow: 'Treino C',
          muscle: 'Pernas & Ombros',
          icon: 'quad',
          cardio: false,
          exercises: [
            WorkoutExercise(
              title: 'Agachamento barra guiada',
              muscle: 'Quadríceps',
              cue: 'Alinhamento dos joelhos e pés a 30°',
              sets: [
                '[warmup]Aquecimento: 15 reps',
                '[prep]Preparação: 12 reps',
                '[work]Trabalho: 8-10 reps',
                '[work]Trabalho: 8-10 reps',
              ],
            ),
            WorkoutExercise(
              title: 'Leg Press 45°',
              muscle: 'Quadríceps',
              cue: 'Pés na largura dos ombros, não hiperestender',
              sets: [
                '[prep]Preparação: 12 reps',
                '[work]Trabalho: 10 reps',
                '[work]Trabalho: 8 reps',
              ],
            ),
            WorkoutExercise(
              title: 'Elevação lateral com halteres',
              muscle: 'Ombros',
              cue: 'Elevação controlada até a altura dos ombros',
              sets: [
                '[prep]Preparação: 15 reps',
                '[work]Trabalho: 12 reps',
                '[work]Trabalho: 10 reps',
              ],
            ),
          ],
        ),
      ];
    } else if (key == 'full') {
      newDays = [
        WorkoutDay(
          dow: 'Treino A',
          muscle: 'Full Body Integrado',
          icon: 'chest',
          cardio: true,
          exercises: [
            WorkoutExercise(
              title: 'Agachamento Livre',
              muscle: 'Quadríceps',
              cue: 'Pés paralelos, descida controlada',
              sets: [
                '[warmup]12 reps @ 50%',
                '[prep]10 reps @ 65%',
                '[work]8 reps @ 80%',
                '[work]8 reps @ 80%',
              ],
            ),
            WorkoutExercise(
              title: 'Supino Reto com Barra',
              muscle: 'Peito',
              cue: 'Escápulas firmes no banco',
              sets: [
                '[warmup]12 reps @ 50%',
                '[prep]10 reps @ 70%',
                '[work]8 reps @ 80%',
              ],
            ),
            WorkoutExercise(
              title: 'Puxada Frontal Aberta',
              muscle: 'Costas',
              cue: 'Puxar até o esterno',
              sets: [
                '[prep]12 reps @ 60%',
                '[work]10 reps @ 75%',
                '[work]8 reps @ 80%',
              ],
            ),
            WorkoutExercise(
              title: 'Desenvolvimento com Halteres',
              muscle: 'Ombros',
              cue: 'Cotovelos alinhados a 45°',
              sets: [
                '[prep]12 reps @ 60%',
                '[work]10 reps @ 75%',
                '[work]8 reps @ 80%',
              ],
            ),
            WorkoutExercise(
              title: 'Elevação Pélvica',
              muscle: 'Glúteos',
              cue: 'Pico de contração de 2s no topo',
              sets: [
                '[prep]15 reps @ 50%',
                '[work]12 reps @ 70%',
                '[work]12 reps @ 70%',
              ],
            ),
          ],
        ),
      ];
    }

    await _applyPresetDays(
      presetName: switch (key) {
        'blank' => 'Ficha em Branco',
        'abc' => 'Treino ABC Clássico',
        _ => 'Treino Full Body',
      },
      studentName: activeSt.name,
      days: newDays,
    );
  }

  void _applyCustomPreset(WorkoutSheet preset) async {
    if (_isApplyingPreset) return;
    final activeSt = _contextService.activeStudent;
    if (activeSt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um aluno antes de aplicar um preset!'),
          backgroundColor: AppColors.crimson,
        ),
      );
      return;
    }

    final clonedDays = preset.days.map((d) => d.deepCopy()).toList();
    await _applyPresetDays(
      presetName: preset.studentName,
      studentName: activeSt.name,
      days: clonedDays,
    );
  }

  Future<void> _applyPresetDays({
    required String presetName,
    required String studentName,
    required List<WorkoutDay> days,
  }) async {
    final currentSheet = _contextService.getActiveSheet().deepCopy();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.carbon2,
        title: const Text('Aplicar modelo à ficha?'),
        content: Text(
          'Aluno: $studentName\n'
          'Modelo: $presetName\n'
          'Treinos atuais: ${currentSheet.days.length}\n'
          'Treinos do modelo: ${days.length}\n\n'
          '${currentSheet.days.isEmpty ? 'O modelo será aplicado à ficha deste aluno.' : 'Os treinos atuais serão substituídos. Uma versão será salva no histórico antes da troca.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              currentSheet.days.isEmpty
                  ? 'Aplicar modelo'
                  : 'Substituir treinos',
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _isApplyingPreset) return;

    setState(() => _isApplyingPreset = true);
    try {
      if (currentSheet.days.isNotEmpty) {
        final snapshotName =
            'Antes de $presetName · ${DateTime.now().toIso8601String()}';
        final snapshotSaved = await _contextService.saveVersionSnapshot(
          currentSheet,
          snapshotName,
        );
        if (!mounted) return;
        if (!snapshotSaved) {
          _showPresetMessage(
            'Não foi possível salvar a versão anterior. A ficha não foi substituída.',
            success: false,
          );
          return;
        }
      }

      final updatedSheet = currentSheet.copyWith(
        days: days.map((day) => day.deepCopy()).toList(),
      );
      bool saved;
      try {
        saved = await _contextService.saveActiveSheet(updatedSheet);
      } catch (_) {
        saved = false;
      }
      if (!mounted) return;
      if (!saved) {
        // O serviço atualiza o cache local antes de confirmar a escrita remota.
        // Restaurar a ficha anterior mantém o editor coerente após uma falha.
        try {
          await _contextService.saveActiveSheet(currentSheet);
        } catch (_) {}
        if (!mounted) return;
        _showPresetMessage(
          'Não foi possível salvar o modelo na ficha de $studentName. A ficha anterior foi restaurada neste aparelho.',
          success: false,
        );
        return;
      }
      _showPresetMessage(
        'Modelo "$presetName" aplicado à ficha de $studentName.',
        success: true,
      );
      widget.onOpenEditor?.call();
    } catch (_) {
      if (mounted) {
        _showPresetMessage(
          'Não foi possível aplicar o modelo. Tente novamente.',
          success: false,
        );
      }
    } finally {
      if (mounted) setState(() => _isApplyingPreset = false);
    }
  }

  void _showPresetMessage(String message, {required bool success}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? AppColors.green : AppColors.crimson,
        ),
      );
  }

  void _deleteCustomPreset(String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.carbon2,
        title: Text(
          'Excluir Preset',
          style: AppTheme.headlineMd(color: Colors.white),
        ),
        content: Text(
          'Tem certeza que deseja excluir o preset "$title"? Esta ação não pode ser desfeita.',
          style: AppTheme.bodyMd(color: AppColors.steel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final deleted = await _contextService.deleteCustomPreset(title);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              deleted
                  ? 'Preset "$title" removido.'
                  : 'Não foi possível excluir "$title". Tente novamente.',
            ),
            backgroundColor: deleted ? AppColors.crimson : null,
          ),
        );
      }
    }
  }

  void _showPresetPreviewDialog(String title, List<WorkoutDay> days) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.carbon2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 580,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '👁️ Prévia do Preset: $title',
                      style: AppTheme.headlineMd(color: AppColors.blueLight),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.steel),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: days.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (c, idx) {
                    final day = days[idx];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.carbon3,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.blue.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  day.dow,
                                  style: AppTheme.labelCaps(
                                    color: AppColors.blueLight,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  day.muscle,
                                  style: AppTheme.bodyMd(color: Colors.white),
                                ),
                              ),
                              Text(
                                '${day.exercises.length} exercícios',
                                style: AppTheme.bodyMd(
                                  color: AppColors.steelDim,
                                ),
                              ),
                            ],
                          ),
                          if (day.exercises.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            ...day.exercises.map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(
                                  left: 6.0,
                                  top: 4.0,
                                ),
                                child: Text(
                                  '• ${e.title} (${e.sets.length} séries)',
                                  style: AppTheme.bodyMd(
                                    color: AppColors.steel,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Fechar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveCurrentAsPresetDialog() {
    final activeSheet = _contextService.getActiveSheet();
    final controller = TextEditingController(
      text: 'Preset - ${activeSheet.studentName}',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.carbon2,
        title: Text(
          'Salvar Ficha Atual como Preset',
          style: AppTheme.headlineMd(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Digite um título para salvar a estrutura atual de ${activeSheet.days.length} dia(s) no seu acervo pessoal:',
              style: AppTheme.bodyMd(color: AppColors.steel),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: AppTheme.inputText(),
              decoration: const InputDecoration(labelText: 'Título do Preset'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                Navigator.pop(ctx);
                final success = await _contextService.saveCustomPreset(
                  activeSheet,
                  title,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Preset "$title" salvo com sucesso!'
                            : 'Erro ao salvar preset.',
                      ),
                      backgroundColor: success
                          ? AppColors.green
                          : AppColors.crimson,
                    ),
                  );
                }
              }
            },
            child: const Text('Salvar Preset'),
          ),
        ],
      ),
    );
  }

  Future<bool> _addExerciseToSheet(Exercise exercise) async {
    final student = _contextService.activeStudent;
    if (student == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Selecione um aluno para adicionar à ficha.'),
          ),
        );
      return false;
    }
    final activeSheet = _contextService.getActiveSheet();
    final isCardio =
        exercise.muscle == 'Cardio' || exercise.muscle == 'Aeróbico';
    var destination = activeSheet.days.isEmpty ? 'new_day' : '0';
    if (activeSheet.days.length > 1 || isCardio) {
      final selected = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.carbon2,
          title: Text(
            'Adicionar em qual treino?',
            style: AppTheme.headlineSm(),
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (index, day) in activeSheet.days.indexed)
                    ListTile(
                      title: Text(day.dow, style: AppTheme.bodyLg()),
                      subtitle: Text(
                        day.muscle,
                        style: AppTheme.bodyMd(color: AppColors.steel),
                      ),
                      onTap: () => Navigator.pop(ctx, '$index'),
                    ),
                  if (activeSheet.days.isEmpty)
                    ListTile(
                      title: Text('Criar Treino A', style: AppTheme.bodyLg()),
                      onTap: () => Navigator.pop(ctx, 'new_day'),
                    ),
                  if (isCardio)
                    ListTile(
                      leading: const Icon(
                        Icons.directions_run,
                        color: AppColors.blueLight,
                      ),
                      title: Text('Página de cardio', style: AppTheme.bodyLg()),
                      subtitle: Text(
                        'Adicionar como opção aeróbica',
                        style: AppTheme.bodyMd(color: AppColors.steel),
                      ),
                      onTap: () => Navigator.pop(ctx, 'cardio_page'),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      );
      if (!mounted) return false;
      if (selected == null) return false;
      destination = selected;
    }
    if (_contextService.activeStudent?.id != student.id) return false;
    final updated = activeSheet.deepCopy();
    String destinationLabel;
    if (destination == 'cardio_page') {
      final prescription = exercise.sets
          .map((set) => set.replaceAll(RegExp(r'\[\w+\]'), '').trim())
          .join(' · ');
      updated.cardioOptions.add('${exercise.title}: $prescription');
      destinationLabel = 'página de cardio';
    } else {
      if (destination == 'new_day') {
        updated.days.add(
          WorkoutDay(dow: 'Treino A', muscle: exercise.muscle, exercises: []),
        );
      }
      final dayIndex = destination == 'new_day'
          ? updated.days.length - 1
          : int.parse(destination);
      updated.days[dayIndex].exercises.add(exercise.deepCopy());
      destinationLabel = updated.days[dayIndex].dow;
    }
    var saved = false;
    try {
      saved = await _contextService.saveActiveSheet(updated);
    } catch (_) {
      // The service may have kept a local copy before synchronization failed.
    }
    final appliedLocally =
        _contextService.activeStudent?.id == student.id &&
        jsonEncode(_contextService.getActiveSheet().toJson()) ==
            jsonEncode(updated.toJson());
    final accepted = saved || appliedLocally;
    if (!mounted) return accepted;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            saved
                ? '${exercise.title} adicionado em $destinationLabel.'
                : appliedLocally
                ? '${exercise.title} adicionado neste dispositivo. Não foi possível sincronizar agora.'
                : 'Não foi possível salvar. Sua prescrição continua aberta para tentar novamente.',
          ),
          duration: const Duration(seconds: 3),
          action: accepted && widget.onOpenEditor != null
              ? SnackBarAction(
                  label: 'Ver ficha',
                  onPressed: widget.onOpenEditor!,
                )
              : null,
        ),
      );
    return accepted;
  }

  @override
  Widget build(BuildContext context) {
    final customPresets = _contextService.customPresets;
    final totalExercises = StudentContextService.exerciseLibrary.length;

    return Scaffold(
      backgroundColor: AppColors.carbon,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Banner (Biblioteca PRO - .dash-welcome-header) ────
              Container(
                padding: const EdgeInsets.all(28.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.blue.withValues(alpha: 0.15),
                      AppColors.carbon2.withValues(alpha: 0.95),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.blue.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, bannerConstraints) {
                    final narrow = bannerConstraints.maxWidth < 700;

                    final textColumn = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Modelos & Catálogo de Exercícios',
                          style: AppTheme.headlineLg(color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Modelos de ficha, exercícios e métodos organizados para montar cada prescrição.',
                          style: AppTheme.bodyMd(color: AppColors.steel),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '3 modelos nativos  •  ${customPresets.length} pessoais  •  ${totalExercises == 0 ? 'Catálogo online' : '$totalExercises exercícios'}',
                          style: AppTheme.bodySm(color: AppColors.steelDim),
                        ),
                      ],
                    );

                    final saveButton = ElevatedButton.icon(
                      onPressed: _saveCurrentAsPresetDialog,
                      icon: const Icon(Icons.bookmark_add, size: 18),
                      label: const Text('Salvar Ficha Atual como Preset'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                    );

                    if (narrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          textColumn,
                          const SizedBox(height: 16),
                          SizedBox(width: double.infinity, child: saveButton),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: textColumn),
                        const SizedBox(width: 16),
                        saveButton,
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // ── Segmented Tabs (.library-segmented-tabs) ─────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.carbon2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TabButton(
                        label:
                            '⚡ Presets de Ficha (${3 + customPresets.length})',
                        isSelected: _selectedTab == 'presets',
                        onTap: () => setState(() => _selectedTab = 'presets'),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _TabButton(
                        label: 'Exercícios e métodos',
                        isSelected: _selectedTab == 'acervo',
                        onTap: () => setState(() => _selectedTab = 'acervo'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Tab Content ─────────────────────────────────────────────
              if (_selectedTab == 'presets')
                _buildPresetsTab(customPresets)
              else
                _buildAcervoTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetsTab(List<WorkoutSheet> customPresets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('📦', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              'TEMPLATES DO SISTEMA',
              style: AppTheme.labelCaps(color: AppColors.blueLight),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _PresetCard(
              icon: '📄',
              title: 'Ficha em Branco',
              badge: '0 DIAS · TELA LIMPA',
              desc:
                  'Template vazio para você montar uma divisão do zero com total liberdade.',
              tags: const ['Do Zero', 'Livre'],
              onPreview: () => _showPresetPreviewDialog('Ficha em Branco', [
                WorkoutDay(
                  dow: 'Treino A',
                  muscle: 'Personalizado',
                  exercises: [],
                ),
              ]),
              onApply: () => _applyNativePreset('blank'),
            ),
            _PresetCard(
              icon: '⚡',
              title: 'Treino ABC Clássico',
              badge: '3 DIAS · DIVISÃO CLÁSSICA',
              desc:
                  'Divisão em 3 sessões: Peito/Tríceps, Costas/Bíceps e Pernas/Ombros.',
              tags: const ['Hipertrofia', 'ABC', 'Popular'],
              onPreview: () => _showPresetPreviewDialog('Treino ABC Clássico', [
                WorkoutDay(
                  dow: 'Treino A',
                  muscle: 'Peito & Tríceps',
                  exercises: [
                    WorkoutExercise(title: 'Peck Deck'),
                    WorkoutExercise(title: 'Supino reto'),
                    WorkoutExercise(title: 'Tríceps na polia'),
                  ],
                ),
                WorkoutDay(
                  dow: 'Treino B',
                  muscle: 'Costas & Bíceps',
                  exercises: [
                    WorkoutExercise(title: 'Puxada frontal'),
                    WorkoutExercise(title: 'Remada Baixa'),
                    WorkoutExercise(title: 'Scott no banco'),
                  ],
                ),
                WorkoutDay(
                  dow: 'Treino C',
                  muscle: 'Pernas & Ombros',
                  exercises: [
                    WorkoutExercise(title: 'Agachamento barra guiada'),
                    WorkoutExercise(title: 'Leg Press'),
                    WorkoutExercise(title: 'Elevação lateral'),
                  ],
                ),
              ]),
              onApply: () => _applyNativePreset('abc'),
            ),
            _PresetCard(
              icon: '💪',
              title: 'Treino Full Body',
              badge: '1 DIA · CORPO INTEIRO',
              desc:
                  'Treino integrado de corpo inteiro focado em grandes grupamentos musculares.',
              tags: const ['Força', 'Condicionamento'],
              onPreview: () => _showPresetPreviewDialog('Treino Full Body', [
                WorkoutDay(
                  dow: 'Treino A',
                  muscle: 'Full Body Integrado',
                  exercises: [
                    WorkoutExercise(title: 'Agachamento Livre'),
                    WorkoutExercise(title: 'Supino Reto com Barra'),
                    WorkoutExercise(title: 'Puxada Frontal Aberta'),
                    WorkoutExercise(title: 'Desenvolvimento com Halteres'),
                    WorkoutExercise(title: 'Elevação Pélvica'),
                  ],
                ),
              ]),
              onApply: () => _applyNativePreset('full'),
            ),
          ],
        ),

        const SizedBox(height: 36),

        Row(
          children: [
            const Text('⭐', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'MEUS PRESETS PERSONALIZADOS',
                style: AppTheme.labelCaps(color: AppColors.gold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (customPresets.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: AppColors.carbon2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text(
                  'Nenhum preset pessoal salvo ainda.',
                  style: AppTheme.headlineMd(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Clique no botão "Salvar Ficha Atual como Preset" acima para salvar sua montagem personalizada.',
                  style: AppTheme.bodyMd(color: AppColors.steel),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: customPresets.map((p) {
              return _PresetCard(
                icon: '⭐',
                title: p.studentName,
                badge: 'PERSONAL · ${p.days.length} DIA(S)',
                desc:
                    'Preset com ${p.days.length} dia(s) e ${p.volumeSummary['totalEx']} exercícios configurados.',
                tags: const ['Preset Salvo', 'Personalizado'],
                isCustom: true,
                onPreview: () =>
                    _showPresetPreviewDialog(p.studentName, p.days),
                onApply: () => _applyCustomPreset(p),
                onDelete: () => _deleteCustomPreset(p.studentName),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildAcervoTab() {
    final media = MediaQuery.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Exercícios em português e ${TrainingMethods.all.isEmpty ? 'métodos de treino' : '${TrainingMethods.all.length} métodos de treino'}. '
          'Escolha o exercício, revise a prescrição e adicione à ficha.',
          style: AppTheme.bodyLg(color: AppColors.steel),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: (media.size.height - media.viewInsets.bottom - 80).clamp(
            460.0,
            800.0,
          ),
          child: ExerciseLibrarySheet(
            embedded: true,
            onAddAsync: _addExerciseToSheet,
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyMd(
              color: isSelected ? Colors.white : AppColors.steel,
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  final String icon;
  final String title;
  final String badge;
  final String desc;
  final List<String> tags;
  final bool isCustom;
  final VoidCallback onPreview;
  final VoidCallback onApply;
  final VoidCallback? onDelete;

  const _PresetCard({
    required this.icon,
    required this.title,
    required this.badge,
    required this.desc,
    required this.tags,
    this.isCustom = false,
    required this.onPreview,
    required this.onApply,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Largura fixa de 340 quando há espaço; encolhe para não ultrapassar o
    // Wrap em telas estreitas (mobile), onde 340 sozinho já causa overflow.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 340 ? constraints.maxWidth : 340.0;
        return Container(
          width: width,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.carbon2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCustom
                  ? AppColors.gold.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isCustom
                            ? AppColors.gold.withValues(alpha: 0.15)
                            : AppColors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isCustom
                              ? AppColors.gold.withValues(alpha: 0.3)
                              : AppColors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        badge,
                        style: AppTheme.labelCaps(
                          color: isCustom
                              ? AppColors.gold
                              : AppColors.blueLight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(title, style: AppTheme.headlineMd(color: Colors.white)),
              const SizedBox(height: 6),
              Text(
                desc,
                style: AppTheme.bodyMd(color: AppColors.steel),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: tags
                    .map(
                      (t) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.carbon3,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          t,
                          style: AppTheme.bodySm(color: AppColors.steelDim),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onPreview,
                      child: const Text('👁️ Prévia'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onApply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCustom
                            ? AppColors.gold
                            : AppColors.blue,
                        foregroundColor: isCustom ? Colors.black : Colors.white,
                      ),
                      child: const Text('⚡ Aplicar'),
                    ),
                  ),
                  if (onDelete != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.crimson,
                      ),
                      tooltip: 'Excluir Preset',
                      onPressed: onDelete,
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
