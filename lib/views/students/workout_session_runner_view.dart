import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/exercise_library_item.dart';
import '../../models/catalog_media_item.dart';
import '../../models/workout_model.dart';
import '../../models/student_model.dart';
import '../../repositories/student_workout_repository.dart';
import '../../services/catalog_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/exercise_media.dart';

/// WorkoutSessionRunnerView — Player Interativo de Execução de Treino para o Aluno
class WorkoutSessionRunnerView extends StatefulWidget {
  final WorkoutDay workoutDay;
  final String studentName;
  final VoidCallback onFinish;
  final Student? student;
  final String teacherName;

  const WorkoutSessionRunnerView({
    super.key,
    required this.workoutDay,
    required this.studentName,
    required this.onFinish,
    this.student,
    this.teacherName = 'seu instrutor',
  });

  @override
  State<WorkoutSessionRunnerView> createState() =>
      _WorkoutSessionRunnerViewState();
}

class _WorkoutSessionRunnerViewState extends State<WorkoutSessionRunnerView> {
  final _catalog = CatalogService.instance;
  // Os cronômetros usam o relógio do aparelho: com a tela bloqueada ou a aba
  // em segundo plano o Timer pausa, mas o tempo exibido continua correto.
  final DateTime _startedAt = DateTime.now();
  Timer? _sessionTimer;
  int _sessionSeconds = 0;

  // Cronômetro de descanso entre séries
  Timer? _restTimer;
  DateTime? _restEndsAt;
  int _restSecondsRemaining = 0;
  bool _isResting = false;
  bool _finished = false;

  // Estado das séries: Map<ExerciseIndex, Set<SetIndex>>
  final Map<int, Set<int>> _completedSets = {};
  final Map<String, double> _customLoads = {};

  int? _rpeScore;
  final _feedbackController = TextEditingController();
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _catalog.addListener(_catalogChanged);
    _catalog.ensureLoaded();
    _startSessionTimer();
  }

  void _catalogChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _catalog.removeListener(_catalogChanged);
    _sessionTimer?.cancel();
    _restTimer?.cancel();
    _feedbackController.dispose();
    super.dispose();
  }

  ExerciseLibraryItem? _catalogItem(String title) {
    for (final item in _catalog.items) {
      if (item.title == title) return item;
    }
    return null;
  }

  Widget _exerciseMedia(Exercise exercise, ExerciseLibraryItem? item) {
    if (exercise.image.isNotEmpty || item == null) {
      return _mediaView(exercise, item, null);
    }
    return FutureBuilder<CatalogMediaItem?>(
      future: _catalog.mediaFor(item),
      builder: (context, snapshot) => _mediaView(exercise, item, snapshot.data),
    );
  }

  Widget _mediaView(
    Exercise exercise,
    ExerciseLibraryItem? item,
    CatalogMediaItem? media,
  ) {
    final animation = exercise.image.endsWith('.gif')
        ? exercise.image
        : media?.animationUrl ?? item?.animationUrl ?? '';
    final images = animation.isNotEmpty
        ? const <String>[]
        : exercise.image.isNotEmpty
        ? [exercise.image]
        : item?.images ?? const <String>[];
    return ExerciseMedia(
      images: images,
      animationUrl: animation,
      videoUrl: exercise.videoUrl.isNotEmpty
          ? exercise.videoUrl
          : item?.video ?? '',
      attribution: exercise.mediaAttribution.isNotEmpty
          ? exercise.mediaAttribution
          : media?.attribution ?? '',
    );
  }

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(
        () => _sessionSeconds = DateTime.now().difference(_startedAt).inSeconds,
      );
    });
  }

  bool get _hasProgress => _completedSets.values.any((sets) => sets.isNotEmpty);

  /// Sair no meio do treino descartaria as séries marcadas sem aviso.
  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.carbon2,
        title: const Text('Sair sem salvar o treino?'),
        content: Text(
          'Você marcou ${_getCompletedSetsCount()} de ${_getTotalSetsCount()} '
          'séries. Para registrar o treino, toque em "Concluir Treino".',
          style: AppTheme.bodyMd(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair sem salvar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuar treino'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      _finished = true;
      Navigator.of(context).pop();
    }
  }

  void _toggleSet(int exIndex, int setIndex) {
    setState(() {
      _completedSets.putIfAbsent(exIndex, () => {});
      final isDone = _completedSets[exIndex]!.contains(setIndex);
      if (isDone) {
        _completedSets[exIndex]!.remove(setIndex);
        _cancelRest();
      } else {
        _completedSets[exIndex]!.add(setIndex);
        final seconds = widget.workoutDay.exercises[exIndex].restSecondsForSet(
          setIndex,
        );
        if (seconds == 0) {
          _cancelRest();
        } else {
          _startRestTimer(seconds);
        }
      }
    });
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    setState(() {
      _isResting = true;
      _restEndsAt = DateTime.now().add(Duration(seconds: seconds));
      _restSecondsRemaining = seconds;
    });

    _restTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (!mounted) return;
      final endsAt = _restEndsAt;
      if (endsAt == null) return;
      final remaining =
          (endsAt.difference(DateTime.now()).inMilliseconds / 1000).ceil();
      if (remaining <= 0) {
        _cancelRest();
      } else if (remaining != _restSecondsRemaining) {
        setState(() => _restSecondsRemaining = remaining);
      }
    });
  }

  void _cancelRest() {
    _restTimer?.cancel();
    if (mounted) {
      setState(() {
        _isResting = false;
        _restEndsAt = null;
        _restSecondsRemaining = 0;
      });
    }
  }

  void _adjustRestTime(int deltaSeconds) {
    final next = (_restSecondsRemaining + deltaSeconds).clamp(5, 300);
    setState(() {
      _restSecondsRemaining = next;
      _restEndsAt = DateTime.now().add(Duration(seconds: next));
    });
  }

  double _calculateTotalTonnage() {
    double total = 0.0;
    for (int i = 0; i < widget.workoutDay.exercises.length; i++) {
      final ex = widget.workoutDay.exercises[i];
      final load =
          _customLoads['ex_$i'] ??
          double.tryParse(ex.loadKg.replaceAll(',', '.')) ??
          0.0;
      for (final s in _completedSets[i] ?? <int>{}) {
        final reps = (s < ex.sets.length)
            ? (double.tryParse(ex.sets[s]) ?? 10.0)
            : 10.0;
        total += reps * load;
      }
    }
    return total;
  }

  int _getTotalSetsCount() {
    int total = 0;
    for (final ex in widget.workoutDay.exercises) {
      total += ex.sets.length;
    }
    return total;
  }

  int _getCompletedSetsCount() {
    int count = 0;
    _completedSets.forEach((_, sets) => count += sets.length);
    return count;
  }

  static String _tons(double kg) =>
      (kg / 1000).toStringAsFixed(2).replaceAll('.', ',');

  String _formatDuration(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showCompletionDialog() {
    if (_getCompletedSetsCount() == 0) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Nenhuma série concluída'),
          content: const Text(
            'Marque ao menos uma série para registrar este treino. '
            'Você também pode sair sem registrar e enviar uma mensagem ao instrutor pelo portal.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Continuar treino'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _finished = true;
                Navigator.pop(context);
              },
              child: const Text('Sair sem registrar'),
            ),
          ],
        ),
      );
      return;
    }
    final tonnageKg = _calculateTotalTonnage();
    final tonnageTon = _tons(tonnageKg);
    final duration = _formatDuration(_sessionSeconds);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: AppColors.carbon2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.gold,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'TREINO CONCLUÍDO!',
                  style: AppTheme.headlineMd(color: Colors.white),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parabéns, ${widget.studentName}! Você concluiu seu ${widget.workoutDay.dow}.',
                  style: AppTheme.bodyMd(color: Colors.white),
                ),
                const SizedBox(height: 16),

                // KPIs do Treino
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.carbon3,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.emerald.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceAround,
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      _StatColumn('TEMPO', duration, AppColors.blueLight),
                      _StatColumn('TONELAGEM', '$tonnageTon t', AppColors.gold),
                      _StatColumn(
                        'SÉRIES',
                        '${_getCompletedSetsCount()}/${_getTotalSetsCount()}',
                        AppColors.emerald,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Percepção de Esforço (RPE 1-10)
                Text(
                  _rpeScore == null
                      ? 'PERCEPÇÃO DE ESFORÇO (RPE): selecione de 1 a 10'
                      : 'PERCEPÇÃO DE ESFORÇO (RPE): $_rpeScore/10',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blueLight,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var score = 1; score <= 10; score++)
                      ChoiceChip(
                        label: Text('$score'),
                        selected: _rpeScore == score,
                        onSelected: (_) =>
                            setModalState(() => _rpeScore = score),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Feedback para o treinador
                TextField(
                  controller: _feedbackController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: 2,
                  maxLength: 2000,
                  decoration: InputDecoration(
                    labelText: 'Comentário para ${widget.teacherName}',
                    hintText:
                        'Ex: Aumentei carga no supino, senti leve fadiga no ombro',
                  ),
                ),
                if (_saveError != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _saveError!,
                      style: const TextStyle(color: AppColors.crimsonText),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emerald,
                foregroundColor: AppColors.carbon1,
              ),
              onPressed: _saving || _rpeScore == null
                  ? null
                  : () async {
                      if (widget.student != null) {
                        setModalState(() => _saving = true);
                        try {
                          await StudentWorkoutRepository().saveSession(
                            student: widget.student!,
                            workoutDay: widget.workoutDay.dow,
                            completedSets: _completedSets,
                            durationSeconds: _sessionSeconds,
                            rpe: _rpeScore!,
                            feedback: _feedbackController.text,
                          );
                        } catch (_) {
                          if (!ctx.mounted) return;
                          setModalState(() {
                            _saving = false;
                            _saveError =
                                'Não foi possível salvar a sessão. Tente novamente.';
                          });
                          return;
                        }
                      }
                      if (!ctx.mounted) return;
                      _finished = true;
                      Navigator.pop(ctx);
                      widget.onFinish();
                      if (mounted && widget.student != null) {
                        Navigator.pop(context);
                      }
                    },
              child: Text(
                _rpeScore == null
                    ? 'Selecione o esforço para salvar'
                    : 'Salvar & Finalizar Sessão',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercises = widget.workoutDay.exercises;
    final totalSets = _getTotalSetsCount();
    final completedSets = _getCompletedSetsCount();
    final progress = totalSets > 0 ? (completedSets / totalSets) : 0.0;
    final tonnageKg = _calculateTotalTonnage();

    return PopScope(
      canPop: _finished || !_hasProgress,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: AppColors.carbon,
        appBar: AppBar(
          backgroundColor: AppColors.carbon2,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.workoutDay.dow} • ${widget.workoutDay.muscle}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Execução ao Vivo • ${widget.studentName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.steel),
              ),
            ],
          ),
          actions: [
            // Timer da Sessão
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.carbon3,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: AppColors.blueLight,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDuration(_sessionSeconds),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: progress,
              semanticsLabel:
                  'Progresso do treino: $completedSets de $totalSets séries concluídas',
              semanticsValue: '${(progress * 100).round()}',
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.emerald,
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: exercises.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Este treino ainda não tem exercícios. Peça ao instrutor para completar sua ficha.',
                            textAlign: TextAlign.center,
                            style: AppTheme.bodyMd(color: AppColors.steel),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: exercises.length,
                        itemBuilder: (context, exIdx) {
                          final ex = exercises[exIdx];
                          final catalogItem = _catalogItem(ex.title);
                          final doneSets = _completedSets[exIdx] ?? {};
                          final isAllDone = doneSets.length == ex.sets.length;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.carbon2,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isAllDone
                                    ? AppColors.emerald.withValues(alpha: 0.5)
                                    : Colors.white10,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Exercise Header
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: isAllDone
                                            ? AppColors.emerald
                                            : AppColors.blue,
                                        child: isAllDone
                                            ? const Icon(
                                                Icons.check,
                                                size: 16,
                                                color: Colors.white,
                                              )
                                            : Text(
                                                '${exIdx + 1}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              ex.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                            if (ex.cue.isNotEmpty)
                                              Text(
                                                '💡 ${ex.cue}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors.steel,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (ex.loadKg.trim().isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.carbon3,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            '${ex.loadKg} kg',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.gold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (ex.image.isNotEmpty ||
                                      ex.videoUrl.isNotEmpty ||
                                      catalogItem != null) ...[
                                    const SizedBox(height: 12),
                                    _exerciseMedia(ex, catalogItem),
                                  ],
                                  const SizedBox(height: 14),

                                  // Sets Row
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: List.generate(ex.sets.length, (
                                      setIdx,
                                    ) {
                                      final isDone = doneSets.contains(setIdx);
                                      final targetReps = ex.sets[setIdx];
                                      final prescription = targetReps
                                          .replaceFirst(
                                            RegExp(
                                              r'\[(?:prep|work|warmup)\]',
                                              caseSensitive: false,
                                            ),
                                            '',
                                          )
                                          .trim()
                                          .replaceFirst(
                                            RegExp(
                                              r'^\d+[ªº]?\s*Série\s*:\s*',
                                              caseSensitive: false,
                                            ),
                                            '',
                                          );
                                      final seriesLabel =
                                          RegExp(
                                            r'reps?|repeti',
                                            caseSensitive: false,
                                          ).hasMatch(prescription)
                                          ? prescription
                                          : '$prescription reps';

                                      return Semantics(
                                        button: true,
                                        checked: isDone,
                                        label:
                                            'Série ${setIdx + 1} de ${ex.sets.length}: $seriesLabel',
                                        onTap: () => _toggleSet(exIdx, setIdx),
                                        child: ExcludeSemantics(
                                          child: InkWell(
                                            onTap: () =>
                                                _toggleSet(exIdx, setIdx),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: AnimatedContainer(
                                              duration:
                                                  MediaQuery.disableAnimationsOf(
                                                    context,
                                                  )
                                                  ? Duration.zero
                                                  : const Duration(
                                                      milliseconds: 200,
                                                    ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isDone
                                                    ? AppColors.emerald
                                                    : AppColors.carbon3,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: isDone
                                                      ? AppColors.emerald
                                                      : Colors.white12,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isDone
                                                        ? Icons
                                                              .check_circle_rounded
                                                        : Icons
                                                              .radio_button_unchecked_rounded,
                                                    size: 16,
                                                    color: isDone
                                                        ? AppColors.carbon1
                                                        : AppColors.steel,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      'Série ${setIdx + 1}: $seriesLabel',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: isDone
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                        color: isDone
                                                            ? AppColors.carbon1
                                                            : Colors.white70,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // O descanso ocupa espaço próprio para não cobrir as séries.
              if (_isResting)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.carbon,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.vibrantBlue,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.vibrantBlue.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppColors.vibrantBlue,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$_restSecondsRemaining',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'INTERVALO DE DESCANSO',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.blueLight,
                                ),
                              ),
                              Text(
                                'Respire fundo e recupere o ATP',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.steel,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.white70,
                          ),
                          tooltip: 'Adicionar 15 segundos ao descanso',
                          onPressed: () => _adjustRestTime(15),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.crimson,
                          ),
                          tooltip: 'Pular descanso',
                          onPressed: _cancelRest,
                        ),
                      ],
                    ),
                  ),
                ),

              if (exercises.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.carbon2,
                    border: const Border(
                      top: BorderSide(color: Colors.white10),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final details = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'PROGRESSO: $completedSets / $totalSets séries',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.steel,
                            ),
                          ),
                          Text(
                            'Volume: ${_tons(tonnageKg)} toneladas',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      );
                      final finish = ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: progress >= 1.0
                              ? AppColors.emerald
                              : AppColors.blueAction,
                          foregroundColor: progress >= 1.0
                              ? AppColors.carbon1
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(Icons.flag_rounded, size: 18),
                        label: const Text('Concluir Treino'),
                        onPressed: _showCompletionDialog,
                      );
                      if (constraints.maxWidth < 390) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            details,
                            const SizedBox(height: 8),
                            finish,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: details),
                          finish,
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatColumn(this.label, this.value, this.valueColor);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.steel),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
