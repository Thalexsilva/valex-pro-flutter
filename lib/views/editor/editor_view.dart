import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/catalog_service.dart';
import 'package:printing/printing.dart';
import '../../models/workout_model.dart';
import '../../models/ai_workout_engine.dart';
import '../../services/pdf_generator_service.dart';
import '../../services/student_context_service.dart';
import '../../theme/app_colors.dart';
import '../../controllers/workout_autosave_controller.dart';
import 'dialogs/calc_load_dialog.dart';
import 'dialogs/exercise_library_sheet.dart';
import 'dialogs/generate_ai_dialog.dart';
import 'dialogs/new_cycle_dialog.dart';
import 'dialogs/reset_sheet_dialog.dart';
import 'dialogs/save_preset_dialog.dart';
import 'dialogs/save_version_dialog.dart';
import 'dialogs/version_history_dialog.dart';
import 'widgets/editor_cardio_page.dart';
import 'widgets/editor_cover_page.dart';
import 'widgets/editor_day_page.dart';
import 'widgets/editor_folder_nav_bar.dart';
import 'widgets/editor_index_page.dart';
import 'widgets/editor_instructor_notes_box.dart';
import 'widgets/editor_toolbar.dart';
import 'widgets/editor_volume_summary_bar.dart';

class EditorView extends StatefulWidget {
  final String? studentId;
  final StudentContextService? contextService;
  final VoidCallback? onOpenPresets;
  final VoidCallback? onOpenStudents;
  const EditorView({
    super.key,
    this.studentId,
    this.contextService,
    this.onOpenPresets,
    this.onOpenStudents,
  });

  @override
  State<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  late final StudentContextService _contextService =
      widget.contextService ?? StudentContextService();
  late final WorkoutAutosaveController _autosaveController =
      WorkoutAutosaveController(contextService: _contextService);
  late WorkoutSheet _activeSheet;
  bool _showDocumentPages = false;

  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _dayKeys = {};
  GlobalKey _coverKey = GlobalKey();
  GlobalKey _indexKey = GlobalKey();
  GlobalKey _cardioKey = GlobalKey();

  /// Ficha adotada pelo editor. O editor trabalha na própria instância e só
  /// troca quando o aluno muda ou o servidor entrega uma versão nova; os
  /// salvamentos automáticos não recarregam a tela durante a digitação.
  String? _adoptedStudentId;
  int _adoptedRevision = 0;

  /// Incrementado quando a ficha é substituída, para recriar os campos que
  /// guardam o texto inicial (aluno, observações, dias e cardio).
  int _sheetGeneration = 0;

  @override
  void initState() {
    super.initState();
    if (widget.studentId != null) {
      _contextService.setActiveStudent(widget.studentId!);
    }
    _adoptContextSheet();
    _contextService.addListener(_onContextChanged);
    _autosaveController.addListener(_onAutosaveChanged);
  }

  void _adoptContextSheet() {
    _activeSheet = _contextService.getActiveSheet();
    _adoptedStudentId = _activeSheet.studentId;
    _adoptedRevision = _contextService.sheetRevision(_activeSheet.studentId);
    _replaceSheetWidgets();
  }

  void _replaceSheetWidgets() {
    _sheetGeneration++;
    _dayKeys.clear();
    _coverKey = GlobalKey();
    _indexKey = GlobalKey();
    _cardioKey = GlobalKey();
  }

  Future<void> _selectStudent(String studentId) async {
    if (studentId == _activeSheet.studentId) return;
    final saved = await _autosaveController.flush();
    if (!mounted) return;
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Salve as alterações desta ficha antes de trocar de aluno.',
          ),
        ),
      );
      return;
    }
    await _contextService.setActiveStudent(studentId);
  }

  @override
  void dispose() {
    _contextService.removeListener(_onContextChanged);
    _autosaveController.removeListener(_onAutosaveChanged);
    _autosaveController.flush();
    _autosaveController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onContextChanged() {
    if (!mounted) return;
    final activeId = _contextService.activeStudentId ?? '';
    final revision = _contextService.sheetRevision(activeId);
    final hasLocalChanges =
        _autosaveController.isDirty || _autosaveController.isSaving;
    setState(() {
      if (activeId != _adoptedStudentId ||
          (revision != _adoptedRevision && !hasLocalChanges)) {
        _adoptContextSheet();
      }
    });
  }

  void _onAutosaveChanged() {
    if (mounted) setState(() {});
  }

  void _scrollToKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _openIndex() {
    setState(() => _showDocumentPages = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToKey(_indexKey);
    });
  }

  /// Aplica uma mutação nos dados e força rebuild — usado pelos widgets
  /// extraídos quando a alteração precisa refletir em outra parte da tela
  /// (ex.: nome do aluno na capa, toggle de cardio, reordenar itens).
  void _mutate(VoidCallback fn) {
    setState(fn);
    _autosaveController.markDirty(_activeSheet);
  }

  /// Marca a ficha como pendente de autosave sem forçar rebuild — usado nos
  /// campos de texto simples, cujo próprio controller já reflete o valor.
  void _markDirty() {
    _autosaveController.markDirty(_activeSheet);
  }

  // ── Workout Day Actions ───────────────────────────────────────────────────
  void _addWorkoutDay() {
    final letter = String.fromCharCode(65 + _activeSheet.days.length);
    setState(() {
      _activeSheet.days.add(
        WorkoutDay(
          dow: 'Treino $letter',
          muscle: 'Grupo Muscular',
          exercises: [],
        ),
      );
    });
    _autosaveController.markDirty(_activeSheet);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _dayKeys[_activeSheet.days.length - 1];
      if (key != null) _scrollToKey(key);
    });
  }

  void _duplicateWorkoutDay(int index) {
    final source = _activeSheet.days[index];
    final letter = String.fromCharCode(65 + _activeSheet.days.length);
    final clone = WorkoutDay(
      dow: 'Treino $letter',
      muscle: source.muscle,
      icon: source.icon,
      cardio: source.cardio,
      exercises: source.exercises.map((e) => e.deepCopy()).toList(),
    );
    setState(() {
      _activeSheet.days.insert(index + 1, clone);
    });
    _autosaveController.markDirty(_activeSheet);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dia de treino duplicado com sucesso!')),
    );
  }

  void _deleteWorkoutDay(int index) {
    if (_activeSheet.days.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A ficha precisa ter pelo menos 1 dia de treino.'),
        ),
      );
      return;
    }
    setState(() {
      _activeSheet.days.removeAt(index);
    });
    _autosaveController.markDirty(_activeSheet);
  }

  void _moveWorkoutDay(int index, int delta) {
    final newIndex = index + delta;
    if (newIndex < 0 || newIndex >= _activeSheet.days.length) return;
    setState(() {
      final day = _activeSheet.days.removeAt(index);
      _activeSheet.days.insert(newIndex, day);
    });
    _autosaveController.markDirty(_activeSheet);
  }

  // ── Exercise Actions ──────────────────────────────────────────────────────
  void _addExercise(WorkoutDay day, Exercise exercise) {
    if (!_activeSheet.days.contains(day)) return;
    setState(() {
      day.exercises.add(exercise.deepCopy());
    });
    _autosaveController.markDirty(_activeSheet);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${exercise.title} adicionado ao ${day.dow}.'),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  void _duplicateExercise(int dayIndex, int exIndex) {
    final ex = _activeSheet.days[dayIndex].exercises[exIndex];
    setState(() {
      _activeSheet.days[dayIndex].exercises.insert(exIndex + 1, ex.deepCopy());
    });
    _autosaveController.markDirty(_activeSheet);
  }

  void _deleteExercise(int dayIndex, int exIndex) {
    final sheet = _activeSheet;
    final day = sheet.days[dayIndex];
    final exercise = day.exercises[exIndex];
    setState(() {
      day.exercises.removeAt(exIndex);
    });
    _autosaveController.markDirty(_activeSheet);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${exercise.title} removido do treino.'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () {
              if (!mounted ||
                  !identical(_activeSheet, sheet) ||
                  !sheet.days.contains(day)) {
                return;
              }
              _mutate(
                () => day.exercises.insert(
                  exIndex.clamp(0, day.exercises.length),
                  exercise,
                ),
              );
            },
          ),
        ),
      );
  }

  void _moveExercise(int dayIndex, int exIndex, int delta) {
    final exercises = _activeSheet.days[dayIndex].exercises;
    final newIndex = exIndex + delta;
    if (newIndex < 0 || newIndex >= exercises.length) return;
    setState(() {
      final ex = exercises.removeAt(exIndex);
      exercises.insert(newIndex, ex);
    });
    _autosaveController.markDirty(_activeSheet);
  }

  void _moveExerciseToDay(int fromDayIndex, int exIndex, int targetDayIndex) {
    if (targetDayIndex < 0 ||
        targetDayIndex >= _activeSheet.days.length ||
        targetDayIndex == fromDayIndex) {
      return;
    }
    setState(() {
      final ex = _activeSheet.days[fromDayIndex].exercises.removeAt(exIndex);
      _activeSheet.days[targetDayIndex].exercises.add(ex);
    });
    _autosaveController.markDirty(_activeSheet);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Exercício movido para ${_activeSheet.days[targetDayIndex].dow}',
        ),
        backgroundColor: AppColors.green,
      ),
    );
  }

  // ── Set Actions ───────────────────────────────────────────────────────────
  void _addSet(int dayIndex, int exIndex) {
    setState(() {
      _activeSheet.days[dayIndex].exercises[exIndex].sets.add(
        '[work]Série de trabalho: 8-12 reps',
      );
    });
    _autosaveController.markDirty(_activeSheet);
  }

  void _deleteSet(int dayIndex, int exIndex, int setIndex) {
    setState(() {
      _activeSheet.days[dayIndex].exercises[exIndex].sets.removeAt(setIndex);
    });
    _autosaveController.markDirty(_activeSheet);
  }

  void _moveSet(int dayIndex, int exIndex, int setIndex, int delta) {
    final sets = _activeSheet.days[dayIndex].exercises[exIndex].sets;
    final newIndex = setIndex + delta;
    if (newIndex < 0 || newIndex >= sets.length) return;
    setState(() {
      final s = sets.removeAt(setIndex);
      sets.insert(newIndex, s);
    });
    _autosaveController.markDirty(_activeSheet);
  }

  void _toggleSetType(int dayIndex, int exIndex, int setIndex) {
    final current =
        _activeSheet.days[dayIndex].exercises[exIndex].sets[setIndex];
    String next;
    if (current.startsWith('[warmup]')) {
      next = current.replaceFirst('[warmup]', '[prep]');
    } else if (current.startsWith('[prep]')) {
      next = current.replaceFirst('[prep]', '[work]');
    } else if (current.startsWith('[work]')) {
      next = current.replaceFirst('[work]', '[warmup]');
    } else {
      next = '[warmup]$current';
    }
    setState(() {
      _activeSheet.days[dayIndex].exercises[exIndex].sets[setIndex] = next;
    });
    _autosaveController.markDirty(_activeSheet);
  }

  void _setSetTypeExplicit(
    int dayIndex,
    int exIndex,
    int setIndex,
    String targetType,
  ) {
    final current =
        _activeSheet.days[dayIndex].exercises[exIndex].sets[setIndex];
    String cleanLine = current.replaceAll(
      RegExp(r'^\[(warmup|prep|work)\]'),
      '',
    );
    String next = '[$targetType]$cleanLine';
    setState(() {
      _activeSheet.days[dayIndex].exercises[exIndex].sets[setIndex] = next;
    });
    _autosaveController.markDirty(_activeSheet);
  }

  // ── Modals & Dialogs ──────────────────────────────────────────────────────

  // 1. Calculadora Científica de Cargas & 1RM PRO
  void _openCalcLoadModal(
    Exercise ex,
    int dayIndex,
    int exIndex, [
    int? setIndex,
  ]) {
    showDialog(
      context: context,
      builder: (ctx) => CalcLoadDialog(
        exercise: ex,
        setIndex: setIndex,
        onApply: (targetLoadResult) {
          setState(() {
            if (setIndex != null && setIndex < ex.sets.length) {
              final currentLine = ex.sets[setIndex];
              final clean = currentLine.replaceAll(RegExp(r'\s*@\s*.*$'), '');
              ex.sets[setIndex] = '$clean @ ≈ $targetLoadResult kg';
            } else {
              ex.loadKg = targetLoadResult.toString();
            }
          });
          _autosaveController.markDirty(_activeSheet);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Carga de $targetLoadResult kg aplicada com sucesso!',
              ),
              backgroundColor: AppColors.green,
            ),
          );
        },
      ),
    );
  }

  // 2. Gerador Inteligente por IA Biomecânica
  bool _loadingGenerator = false;
  Future<void> _openGenerateAiModal() async {
    if (_loadingGenerator) return;
    _loadingGenerator = true;
    if (!CatalogService.instance.isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Carregando a biblioteca para montar o treino…'),
        ),
      );
    }
    final ready = await CatalogService.instance.ensureLoaded();
    _loadingGenerator = false;
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (!ready) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Não foi possível carregar a biblioteca.'),
          action: SnackBarAction(
            label: 'Tentar novamente',
            onPressed: _openGenerateAiModal,
          ),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => GenerateAiDialog(
        initialText: _activeSheet.instructorNotes.isNotEmpty
            ? _activeSheet.instructorNotes
            : 'Objetivo hipertrofia muscular, 3 treinos por semana, sem dores articulares relatadas.',
        studentName: _activeSheet.studentName,
        onGenerate: (anamneseText) {
          final result = AiWorkoutEngine.generateSheetFromAnamnese(
            anamneseText: anamneseText,
            studentName: _activeSheet.studentName,
          );

          setState(() {
            _replaceSheetWidgets();
            _activeSheet.days = result.days;
            if (result.summaryNotes.isNotEmpty) {
              _activeSheet.instructorNotes =
                  (_activeSheet.instructorNotes.isNotEmpty
                      ? '${_activeSheet.instructorNotes}\n\n'
                      : '') +
                  result.summaryNotes;
            }
          });
          _autosaveController.markDirty(_activeSheet);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚡ Ficha gerada com sucesso pela IA Biomecânica!'),
              backgroundColor: AppColors.green,
            ),
          );
        },
      ),
    );
  }

  // 3. Novo Ciclo de Treino
  void _openNewCycleDialog() {
    showDialog(
      context: context,
      builder: (ctx) => NewCycleDialog(
        initialCycleName: 'Ciclo 2 - Hipertrofia & Força',
        onConfirm: (newName) async {
          await _contextService.saveVersionSnapshot(
            _activeSheet,
            'Snapshot anterior',
          );
          setState(() {
            _activeSheet.currentVersionName = newName;
          });
          _autosaveController.markDirty(_activeSheet);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('📅 Novo ciclo "$newName" iniciado!'),
                backgroundColor: AppColors.green,
              ),
            );
          }
        },
      ),
    );
  }

  // 4. Modal de Snapshot / Histórico de Versões
  void _openVersionHistoryDialog() {
    final history = _contextService.getVersionHistory(_activeSheet.studentId);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => VersionHistoryDialog(
        history: history,
        onSaveSnapshotManual: _saveVersionDialog,
        onRestore: (version) async {
          final cloned = version.deepCopy();
          final success = await _contextService.saveActiveSheet(cloned);
          if (!mounted) return false;
          if (success) {
            setState(() {
              _activeSheet = cloned;
              _replaceSheetWidgets();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Versão "${version.currentVersionName}" restaurada!',
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Não foi possível salvar no servidor. Tente novamente.',
                ),
              ),
            );
          }
          return success;
        },
      ),
    );
  }

  // 5. Salvar Snapshot Manual
  void _saveVersionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SaveVersionDialog(
        initialName:
            'v${_activeSheet.days.length} - ${DateTime.now().day}/${DateTime.now().month}',
        onSave: (name) async {
          final ok = await _contextService.saveVersionSnapshot(
            _activeSheet,
            name,
          );
          if (!mounted) return ok;
          if (ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Versão "$name" salvo no histórico!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Não foi possível salvar no servidor. Tente novamente.',
                ),
              ),
            );
          }
          return ok;
        },
      ),
    );
  }

  // 6. Salvar como Preset Personalizado
  void _saveCustomPresetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SavePresetDialog(
        initialTitle:
            'Preset ${_activeSheet.studentName.isNotEmpty ? _activeSheet.studentName : "Personalizado"}',
        onSave: (title) async {
          final ok = await _contextService.saveCustomPreset(
            _activeSheet,
            title,
          );
          if (!mounted) return ok;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          if (ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Preset "$title" salvo com sucesso!'),
                backgroundColor: AppColors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Não foi possível salvar no servidor. Tente novamente.',
                ),
              ),
            );
          }
          return ok;
        },
      ),
    );
  }

  // 7. Resetar Ficha
  void _resetSheetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => ResetSheetDialog(
        onConfirm: () {
          setState(() {
            _replaceSheetWidgets();
            _activeSheet = WorkoutSheet(
              studentId: _activeSheet.studentId,
              studentName: _activeSheet.studentName,
              gymName: _activeSheet.gymName,
              days: [
                WorkoutDay(dow: 'Treino A', muscle: 'Geral', exercises: []),
              ],
            );
          });
          _autosaveController.markDirty(_activeSheet);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Ficha resetada.')));
        },
      ),
    );
  }

  // 8. Biblioteca de exercícios e métodos com prescrição guiada.
  void _openExerciseLibrarySheet(int dayIndex) {
    final day = _activeSheet.days[dayIndex];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 720),
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExerciseLibrarySheet(
        dayLabel: day.dow,
        onAdd: (exercise) => _addExercise(day, exercise),
      ),
    );
  }

  // 9. Impressão / PDF Preview
  void _openPdfPreview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: Text('Ficha de Treino - ${_activeSheet.studentName}'),
            backgroundColor: AppColors.carbon,
          ),
          body: PdfPreview(
            build: (format) =>
                PdfGeneratorService.generateWorkoutPdf(_activeSheet),
            canChangeOrientation: false,
            canChangePageFormat: false,
          ),
        ),
      ),
    );
  }

  // ── BUILD SYSTEM ──────────────────────────────────────────────────────────
  Widget _statusMessage({
    required IconData icon,
    required String title,
    String? detail,
    Widget? action,
    bool loading = false,
  }) {
    return Scaffold(
      backgroundColor: AppColors.carbon,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading)
                  const CircularProgressIndicator(color: AppColors.blue)
                else
                  Icon(icon, color: AppColors.steel, size: 36),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    detail,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.steel,
                    ),
                  ),
                ],
                if (action != null) ...[const SizedBox(height: 16), action],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_activeSheet.studentId.isEmpty) {
      if (!_contextService.isInitialized || _contextService.isRefreshing) {
        return _statusMessage(
          icon: Icons.people_outline,
          title: 'Carregando seus alunos…',
          loading: true,
        );
      }
      return _statusMessage(
        icon: Icons.person_search_outlined,
        title: 'Nenhum aluno selecionado',
        detail: 'Cadastre ou selecione um aluno para editar a ficha de treino.',
        action: widget.onOpenStudents == null
            ? null
            : FilledButton.icon(
                onPressed: widget.onOpenStudents,
                icon: const Icon(Icons.people_outline),
                label: const Text('Escolher aluno'),
              ),
      );
    }
    final sheetState = _contextService.sheetState(_activeSheet.studentId);
    if (sheetState == SheetLoadState.loading) {
      return _statusMessage(
        icon: Icons.description_outlined,
        title: 'Carregando a ficha de ${_activeSheet.studentName}…',
        loading: true,
      );
    }
    if (sheetState == SheetLoadState.failed && _activeSheet.days.isEmpty) {
      // Editar uma ficha em branco aqui poderia sobrescrever a do servidor.
      return _statusMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Não foi possível carregar a ficha',
        detail:
            'Verifique a conexão. A edição fica bloqueada para não '
            'substituir a ficha salva no servidor.',
        action: FilledButton.icon(
          onPressed: () => _contextService.retrySheet(_activeSheet.studentId),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Tentar novamente'),
        ),
      );
    }
    final totalPages = 3 + _activeSheet.days.length;
    final volume = _activeSheet.volumeSummary;

    return Scaffold(
      backgroundColor: AppColors.carbon,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.studentId != null && Navigator.canPop(context)) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final saved = await _autosaveController.flush();
                      if (!context.mounted) return;
                      if (saved) {
                        Navigator.of(context).pop();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Não foi possível salvar a ficha. Tente novamente antes de sair.',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Voltar ao aluno'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (sheetState == SheetLoadState.failed) ...[
                _centeredPageWidth(
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.amber.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          color: AppColors.amber,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Mostrando a cópia salva neste aparelho. A versão '
                            'do servidor não pôde ser carregada.',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _contextService.retrySheet(
                            _activeSheet.studentId,
                          ),
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // 1. Folder Navigation Bar (.folder-nav-bar)
              EditorFolderNavBar(
                students: _contextService.allStudents,
                activeStudentId: _activeSheet.studentId,
                onSelectStudent: _selectStudent,
                onOpenPresets:
                    widget.onOpenPresets ?? _openVersionHistoryDialog,
                getBackupJson: () => jsonEncode(_activeSheet.toJson()),
              ),

              const SizedBox(height: 12),

              // 2. Editor Toolbar (.editor-toolbar)
              KeyedSubtree(
                key: ValueKey(
                  'toolbar-${_activeSheet.studentId}-$_sheetGeneration',
                ),
                child: EditorToolbar(
                  activeSheet: _activeSheet,
                  isSaving: _autosaveController.isSaving,
                  isDirty: _autosaveController.isDirty,
                  saveError: _autosaveController.status == AutosaveStatus.error
                      ? _autosaveController.errorMessage
                      : null,
                  onRetrySave: _autosaveController.retry,
                  mutate: _mutate,
                  onAddWorkoutDay: _addWorkoutDay,
                  onOpenGenerateAi: _openGenerateAiModal,
                  onOpenNewCycle: _openNewCycleDialog,
                  onOpenVersionHistory: _openVersionHistoryDialog,
                  onOpenPdfPreview: _openPdfPreview,
                  onResetSheet: _resetSheetDialog,
                  onSaveSnapshot: _saveVersionDialog,
                  onSaveCustomPreset: _saveCustomPresetDialog,
                ),
              ),

              const SizedBox(height: 12),

              // 3. Volume Summary Bar (.volume-summary-bar)
              EditorVolumeSummaryBar(volume: volume),

              const SizedBox(height: 16),

              // 4. Prontuário Privado
              _centeredPageWidth(
                EditorInstructorNotesBox(
                  key: ValueKey(
                    'notes-${_activeSheet.studentId}-$_sheetGeneration',
                  ),
                  initialValue: _activeSheet.instructorNotes,
                  onChanged: (v) {
                    _activeSheet.instructorNotes = v;
                    _markDirty();
                  },
                ),
              ),

              const SizedBox(height: 24),

              // ── VIRTUAL PAGES (A4) ─────────────────────────────────────────
              _centeredPageWidth(
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      _showDocumentPages = !_showDocumentPages;
                    }),
                    icon: Icon(
                      _showDocumentPages
                          ? Icons.expand_less
                          : Icons.description_outlined,
                    ),
                    label: Text(
                      _showDocumentPages
                          ? 'Recolher capa e índice'
                          : 'Ver capa e índice da ficha',
                    ),
                  ),
                ),
              ),

              if (_showDocumentPages) ...[
                // Page 1: Cover Page
                _centeredPageWidth(
                  EditorCoverPage(key: _coverKey, sheet: _activeSheet),
                  a4Height: true,
                ),

                const SizedBox(height: 24),
              ],

              if (_activeSheet.days.isEmpty)
                _centeredPageWidth(
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.fitness_center,
                          color: AppColors.steel,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Comece pelo primeiro treino',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Crie um treino para escolher os exercícios da biblioteca.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.steel,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _addWorkoutDay,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.paperBlue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 48),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Criar primeiro treino'),
                        ),
                      ],
                    ),
                  ),
                ),

              if (_showDocumentPages) ...[
                // Page 2: Index Page
                _centeredPageWidth(
                  EditorIndexPage(
                    key: _indexKey,
                    sheet: _activeSheet,
                    totalPages: totalPages,
                    onTapDay: (index) {
                      final key = _dayKeys[index];
                      if (key != null) _scrollToKey(key);
                    },
                    onTapCardio: () => _scrollToKey(_cardioKey),
                  ),
                  a4Height: true,
                ),

                const SizedBox(height: 24),
              ],

              // Pages 3..N: Day Pages
              ..._activeSheet.days.asMap().entries.map((e) {
                final dayIndex = e.key;
                final day = e.value;
                final pageNo = 3 + dayIndex;

                if (!_dayKeys.containsKey(dayIndex)) {
                  _dayKeys[dayIndex] = GlobalKey();
                }

                final otherDaysForMove = _activeSheet.days
                    .asMap()
                    .entries
                    .where((d) => d.key != dayIndex)
                    .map((d) => MapEntry(d.key, d.value.dow))
                    .toList();

                return Padding(
                  key: _dayKeys[dayIndex],
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: _centeredPageWidth(
                    EditorDayPage(
                      day: day,
                      dayIndex: dayIndex,
                      pageNo: pageNo,
                      totalPages: totalPages,
                      otherDaysForMove: otherDaysForMove,
                      mutate: _mutate,
                      markDirty: _markDirty,
                      onMoveDay: (delta) => _moveWorkoutDay(dayIndex, delta),
                      onDuplicateDay: () => _duplicateWorkoutDay(dayIndex),
                      onDeleteDay: () => _deleteWorkoutDay(dayIndex),
                      onOpenLibrary: () => _openExerciseLibrarySheet(dayIndex),
                      onBackToIndex: _openIndex,
                      onOpenCalcLoad: (ex, exIndex, [setIndex]) =>
                          _openCalcLoadModal(ex, dayIndex, exIndex, setIndex),
                      onToggleSetType: (exIndex, setIndex) =>
                          _toggleSetType(dayIndex, exIndex, setIndex),
                      onSetTypeExplicit: (exIndex, setIndex, type) =>
                          _setSetTypeExplicit(
                            dayIndex,
                            exIndex,
                            setIndex,
                            type,
                          ),
                      onMoveSet: (exIndex, setIndex, delta) =>
                          _moveSet(dayIndex, exIndex, setIndex, delta),
                      onDeleteSet: (exIndex, setIndex) =>
                          _deleteSet(dayIndex, exIndex, setIndex),
                      onAddSet: (exIndex) => _addSet(dayIndex, exIndex),
                      onDuplicateExercise: (exIndex) =>
                          _duplicateExercise(dayIndex, exIndex),
                      onMoveExercise: (exIndex, delta) =>
                          _moveExercise(dayIndex, exIndex, delta),
                      onMoveExerciseToDay: (exIndex, targetDay) =>
                          _moveExerciseToDay(dayIndex, exIndex, targetDay),
                      onDeleteExercise: (exIndex) =>
                          _deleteExercise(dayIndex, exIndex),
                    ),
                  ),
                );
              }),

              // Page Final: Cardio & Observações
              _centeredPageWidth(
                EditorCardioPage(
                  key: _cardioKey,
                  sheet: _activeSheet,
                  pageNo: totalPages,
                  totalPages: totalPages,
                  mutate: _mutate,
                  markDirty: _markDirty,
                  onBackToIndex: _openIndex,
                ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _centeredPageWidth(Widget child, {bool a4Height = false}) {
    final compact = MediaQuery.sizeOf(context).width < 800;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 794,
          minHeight: a4Height && !compact ? 1123 : 0,
        ),
        child: child,
      ),
    );
  }
}
