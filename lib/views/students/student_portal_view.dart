import 'package:flutter/material.dart';
import '../../models/anamnese_model.dart';
import '../../models/student_model.dart';
import '../../models/workout_model.dart';
import '../../repositories/anamnese_repository.dart';
import '../../repositories/student_repository.dart';
import '../../repositories/student_workout_repository.dart';
import '../../repositories/workout_repository.dart';
import '../../services/anamnese_pdf_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bioimpedance_dashboard_card.dart';
import '../../widgets/carbon_card.dart';
import '../../widgets/posture_photo_gallery_viewer.dart';
import 'anamnese_detail_sheet.dart';
import 'anamnese_form_wizard_view.dart';
import 'workout_session_runner_view.dart';

/// StudentPortalView — Portal Exclusivo e Completo do Aluno.
/// No primeiro login (ou quando o instrutor solicitar reavaliação), guia obrigatoriamente para o Fluxo 360°.
class StudentPortalView extends StatefulWidget {
  final Student student;
  final VoidCallback onLogout;
  final StudentWorkoutRepository? activityRepository;

  const StudentPortalView({
    super.key,
    required this.student,
    required this.onLogout,
    this.activityRepository,
  });

  @override
  State<StudentPortalView> createState() => _StudentPortalViewState();
}

class _StudentPortalViewState extends State<StudentPortalView>
    with SingleTickerProviderStateMixin {
  final AnamneseRepository _anamneseRepo = AnamneseRepository();
  final WorkoutRepository _workoutRepo = WorkoutRepository();
  late final StudentWorkoutRepository _activityRepo =
      widget.activityRepository ?? StudentWorkoutRepository();
  final _commentController = TextEditingController();

  late TabController _tabController;
  late Student _student = widget.student;
  AnamneseModel? _anamnese;
  List<AnamneseModel> _anamneseHistory = [];
  WorkoutSheet? _activeSheet;
  bool _isLoading = true;
  bool _needs360 = false;
  bool _hasPrompted360 = false;
  bool _workoutLoadError = false;
  bool _assessmentLoadError = false;
  bool _activityLoadError = false;
  bool _isRefreshingActivity = false;
  bool _sendingComment = false;
  List<StudentWorkoutEntry> _activity = [];
  final GlobalKey _contactKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkStudentStatusAndLoadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  String get _teacherName {
    final name = _student.teacher.trim();
    return name.isEmpty ? 'seu instrutor' : name;
  }

  Future<void> _refresh() => _checkStudentStatusAndLoadData(showSpinner: false);

  Future<void> _refreshActivity() async {
    if (_isRefreshingActivity) return;
    setState(() => _isRefreshingActivity = true);
    try {
      final entries = await _activityRepo.fetchEntries(_student.id);
      if (!mounted) return;
      setState(() {
        _activity = entries;
        _activityLoadError = false;
      });
    } catch (_) {
      if (mounted) setState(() => _activityLoadError = true);
    } finally {
      if (mounted) setState(() => _isRefreshingActivity = false);
    }
  }

  /// Carrega cadastro, avaliação, ficha e atividade em paralelo. Uma falha de
  /// conexão na avaliação não é tratada como "primeiro acesso" e não bloqueia
  /// o treino.
  Future<void> _checkStudentStatusAndLoadData({bool showSpinner = true}) async {
    if (showSpinner) setState(() => _isLoading = true);

    final sid = widget.student.id;
    Future<Student?> studentFuture() async {
      try {
        return await StudentRepository().fetchStudentForCurrentAccount();
      } catch (_) {
        return null;
      }
    }

    Future<List<StudentWorkoutEntry>?> activityFuture() async {
      try {
        return await _activityRepo.fetchEntries(sid);
      } catch (_) {
        return null;
      }
    }

    final results = await Future.wait<Object?>([
      studentFuture(),
      _anamneseRepo.fetchHistoryResult(sid),
      _workoutRepo.fetchActiveSheetResult(sid),
      activityFuture(),
    ]);
    final current = results[0] as Student? ?? _student;
    final assessment = results[1] as AnamneseLoadResult;
    final workoutResult = results[2] as ActiveWorkoutLoadResult;
    final activity = results[3] as List<StudentWorkoutEntry>?;
    final needs =
        current.needsReassessment ||
        current.anamnesePending ||
        assessment.status == AnamneseLoadStatus.empty;

    if (mounted) {
      setState(() {
        _anamnese = assessment.latest ?? _anamnese;
        _student = current;
        if (assessment.history.isNotEmpty) {
          _anamneseHistory = assessment.history.reversed.toList();
        }
        _assessmentLoadError = assessment.status == AnamneseLoadStatus.error;
        _needs360 = needs;
        _workoutLoadError =
            workoutResult.status == ActiveWorkoutLoadStatus.error;
        if (!_workoutLoadError) _activeSheet = workoutResult.sheet;
        if (activity != null) _activity = activity;
        _activityLoadError = activity == null;
        _isLoading = false;
      });

      // Se for o primeiro login (sem anamnese) ou reavaliação exigida, abre o diálogo de boas-vindas do Fluxo 360°
      if (needs && !_hasPrompted360) {
        _hasPrompted360 = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _prompt360FlowDialog();
        });
      }
    }
  }

  /// Data da última execução registrada de cada treino.
  Map<String, DateTime> get _lastSessionByDay {
    final result = <String, DateTime>{};
    for (final entry in _activity) {
      if (entry.kind != 'session') continue;
      final current = result[entry.workoutDay];
      if (current == null || entry.createdAt.isAfter(current)) {
        result[entry.workoutDay] = entry.createdAt;
      }
    }
    return result;
  }

  static String _shortDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}';
  }

  void _prompt360FlowDialog() {
    final isFirstLogin = _anamnese == null;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        backgroundColor: AppColors.carbon2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isFirstLogin
                    ? AppColors.blue.withValues(alpha: 0.2)
                    : AppColors.gold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isFirstLogin ? Icons.waving_hand_rounded : Icons.sync_rounded,
                color: isFirstLogin ? AppColors.blueLight : AppColors.gold,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isFirstLogin
                    ? 'BEM-VINDO(A) AO VALEX!'
                    : 'REAVALIAÇÃO 360° SOLICITADA',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isFirstLogin
                  ? 'Olá, ${widget.student.name}! Para que seu treino seja montado sob medida e com segurança por $_teacherName, precisamos da sua Avaliação 360°.'
                  : 'Olá, ${widget.student.name}! Seu treinador solicitou a atualização dos seus dados, bioimpedância e fotos posturais para calibrar seu novo ciclo de treinos.',
              style: AppTheme.bodyMd(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Você pode consultar seu portal agora. Para iniciar os treinos, conclua a avaliação; o formulário permite salvar um rascunho.',
              style: AppTheme.bodyMd(color: AppColors.steel),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.carbon3,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.blue.withValues(alpha: 0.3),
                ),
              ),
              child: const Column(
                children: [
                  _StepTile(
                    icon: Icons.monitor_weight_outlined,
                    text: 'Metas, Biometria & Bioimpedância',
                  ),
                  SizedBox(height: 6),
                  _StepTile(
                    icon: Icons.health_and_safety_outlined,
                    text: 'PAR-Q+ & Histórico Articular',
                  ),
                  SizedBox(height: 6),
                  _StepTile(
                    icon: Icons.camera_alt_outlined,
                    text: 'Fotos Posturais Criptografadas',
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ver meu portal'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isFirstLogin
                  ? AppColors.blueAction
                  : AppColors.gold,
              foregroundColor: isFirstLogin ? Colors.white : AppColors.carbon,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
              isFirstLogin
                  ? 'Iniciar Fluxo 360° Agora'
                  : 'Iniciar Reavaliação 360°',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _open360Wizard();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _open360Wizard() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnamneseFormWizardView(student: _student),
      ),
    );

    if (mounted && result is AnamneseModel) {
      await _checkStudentStatusAndLoadData();
    }
  }

  void _startWorkoutRunner(WorkoutDay day) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutSessionRunnerView(
          workoutDay: day,
          studentName: _student.name,
          teacherName: _teacherName,
          student: _student,
          onFinish: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: AppColors.emerald,
                content: Text(
                  'Treino registrado com sucesso! Ótimo trabalho!',
                  style: TextStyle(color: AppColors.carbon1),
                ),
              ),
            );
            _checkStudentStatusAndLoadData();
          },
        ),
      ),
    );
  }

  Future<void> _sendComment() async {
    if (_sendingComment || _commentController.text.trim().isEmpty) return;
    setState(() => _sendingComment = true);
    try {
      await _activityRepo.sendComment(_student, _commentController.text);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível enviar. Tente novamente.'),
        ),
      );
      setState(() => _sendingComment = false);
      return;
    }

    if (!mounted) return;
    _commentController.clear();
    try {
      final entries = await _activityRepo.fetchEntries(_student.id);
      if (mounted) {
        setState(() {
          _activity = entries;
          _activityLoadError = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comentário enviado ao instrutor.')),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _activityLoadError = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Comentário enviado, mas a atividade não pôde ser atualizada. Atualize a página para vê-lo.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingComment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = _student;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.carbon,
        body: Center(child: CircularProgressIndicator(color: AppColors.blue)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.carbon,
      appBar: AppBar(
        backgroundColor: AppColors.carbon2,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 24,
              excludeFromSemantics: true,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'PORTAL DO ALUNO',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'BebasNeue',
                  letterSpacing: 1.5,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (_anamnese != null)
            IconButton(
              icon: const Icon(
                Icons.picture_as_pdf_rounded,
                color: AppColors.gold,
              ),
              tooltip: 'Exportar Meu Laudo PDF 360°',
              onPressed: () async {
                try {
                  final downloaded = await AnamnesePdfService.printOrSharePdf(
                    anamnese: _anamnese!,
                    student: student,
                  );
                  if (!downloaded) throw StateError('Download indisponível');
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Não foi possível baixar o laudo 360°. Tente novamente.',
                        ),
                      ),
                    );
                  }
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.steel),
            tooltip: 'Sair do Portal',
            onPressed: widget.onLogout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.vibrantBlue,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.steel,
          labelPadding: const EdgeInsets.symmetric(horizontal: 2),
          labelStyle: TextStyle(
            fontSize: MediaQuery.sizeOf(context).width < 480 ? 12 : 14,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.fitness_center_rounded, size: 18),
              text: 'Meus Treinos',
            ),
            Tab(
              icon: Icon(Icons.monitor_weight_outlined, size: 18),
              text: 'Bioimpedância',
            ),
            Tab(
              icon: Icon(Icons.camera_alt_outlined, size: 18),
              text: 'Postura 360°',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ABA 1: MEUS TREINOS
          _buildWorkoutsTab(student),

          // ABA 2: BIOIMPEDÂNCIA & COMPOSIÇÃO CORPORAL
          _buildBioimpedanceTab(student),

          // ABA 3: FOTOS POSTURAIS
          _buildPostureTab(student),
        ],
      ),
    );
  }

  Widget _buildWorkoutsTab(Student student) {
    final lastSessions = _lastSessionByDay;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_assessmentLoadError) ...[
                  CarbonCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.cloud_off_rounded,
                              color: AppColors.amber,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _anamnese == null
                                    ? 'Não foi possível verificar sua Avaliação 360°. '
                                          'Seus treinos continuam liberados.'
                                    : 'Mostrando a última avaliação salva neste '
                                          'aparelho.',
                                style: AppTheme.bodyMd(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _refresh,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Tentar novamente'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Banner 360 Pendente
                if (_needs360) ...[
                  _buildNeeds360Banner(),
                  const SizedBox(height: 20),
                ] else if (_anamnese != null) ...[
                  _buildAnamneseValidCard(student),
                  const SizedBox(height: 20),
                ],

                OutlinedButton.icon(
                  onPressed: () {
                    final target = _contactKey.currentContext;
                    if (target != null) {
                      Scrollable.ensureVisible(
                        target,
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Mensagem ao instrutor'),
                ),
                const SizedBox(height: 20),

                if (_workoutLoadError) ...[
                  CarbonCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Não foi possível carregar sua ficha',
                          style: AppTheme.headlineSm(),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _activeSheet == null
                              ? 'Verifique sua conexão e tente novamente.'
                              : 'Mostrando a última ficha carregada. Atualize quando a conexão voltar.',
                          style: AppTheme.bodyMd(),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _checkStudentStatusAndLoadData,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Ficha Ativa
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    Text(
                      'MINHA PERIODIZAÇÃO ATIVA',
                      style: AppTheme.labelCaps(color: AppColors.steel),
                    ),
                    if (_activeSheet != null)
                      Text(
                        '${_activeSheet!.days.length} dias de treino programados',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.blueLight,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (!_workoutLoadError &&
                    (_activeSheet == null || _activeSheet!.days.isEmpty)) ...[
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.carbon2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.fitness_center,
                            color: AppColors.steel,
                            size: 48,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Sua ficha de treino está sendo preparada por $_teacherName.',
                            style: AppTheme.bodyMd(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Assim que a prescrição for concluída, você poderá executar cada treino por aqui.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.steel,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if (_activeSheet != null &&
                    _activeSheet!.days.isNotEmpty) ...[
                  ..._activeSheet!.days.map((day) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Material(
                        color: AppColors.carbon2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: AppColors.blue.withValues(alpha: 0.25),
                          ),
                        ),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.blueAction,
                            radius: 18,
                            child: Text(
                              _dayInitials(day.dow),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          title: Text(
                            '${day.dow} — ${day.muscle}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            '${day.exercises.length} ${day.exercises.length == 1 ? 'exercício' : 'exercícios'} • '
                            '${lastSessions[day.dow] == null ? 'ainda não realizado' : 'último em ${_shortDate(lastSessions[day.dow]!)}'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.steel,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              child: Column(
                                children: [
                                  ...day.exercises.map((ex) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.carbon3,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  ex.title,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                if (ex.cue.isNotEmpty)
                                                  Text(
                                                    '💡 ${ex.cue}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppColors.steel,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.blue.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              ex.loadKg.trim().isEmpty
                                                  ? _setsLabel(ex.sets.length)
                                                  : '${_setsLabel(ex.sets.length)} • ${ex.loadKg} kg',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.blueLight,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  if (day.exercises.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Text(
                                        'Este dia ainda não tem exercícios. Peça ao instrutor para completar sua ficha.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppColors.steel,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 12),

                                  // Botão Iniciar Execução ao Vivo
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.blueAction,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.play_circle_fill_rounded,
                                        size: 20,
                                      ),
                                      label: Text(
                                        _needs360
                                            ? 'Conclua a avaliação 360° para treinar'
                                            : day.exercises.isEmpty
                                            ? 'Aguardando exercícios'
                                            : 'Iniciar ${day.dow}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      onPressed:
                                          _needs360 || day.exercises.isEmpty
                                          ? null
                                          : () => _startWorkoutRunner(day),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
                CarbonCard(
                  key: _contactKey,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Fale com seu instrutor',
                        style: AppTheme.headlineMd(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Envie dúvidas ou conte como foi seu treino.',
                        style: AppTheme.bodyMd(color: AppColors.steel),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _commentController,
                        maxLines: 3,
                        maxLength: 2000,
                        decoration: const InputDecoration(
                          labelText: 'Mensagem ao instrutor',
                          hintText: 'Escreva seu comentário...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _sendingComment ? null : _sendComment,
                          icon: const Icon(Icons.send_outlined),
                          label: Text(
                            _sendingComment
                                ? 'Enviando...'
                                : 'Enviar comentário',
                          ),
                        ),
                      ),
                      if (_activityLoadError) ...[
                        const SizedBox(height: 14),
                        Semantics(
                          liveRegion: true,
                          child: const Text(
                            'Não foi possível atualizar a atividade recente.',
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _isRefreshingActivity
                              ? null
                              : _refreshActivity,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(
                            _isRefreshingActivity
                                ? 'Atualizando...'
                                : 'Tentar novamente',
                          ),
                        ),
                      ],
                      if (_activity.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'Atividade recente',
                          style: AppTheme.bodyMd(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        ..._activity
                            .take(3)
                            .map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  '${_shortDate(entry.createdAt)} · '
                                  '${entry.kind == 'session' ? '${entry.workoutDay}: ${entry.feedback.isEmpty ? 'treino concluído' : entry.feedback}' : entry.feedback}',
                                  style: AppTheme.bodySm(
                                    color: AppColors.steel,
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBioimpedanceTab(Student student) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_anamnese?.bioimpedance != null &&
                  _anamnese!.bioimpedance!.hasMetrics) ...[
                BioimpedanceDashboardCard(
                  bio: _anamnese!.bioimpedance!,
                  previousBio: _anamneseHistory.length > 1
                      ? _anamneseHistory[1].bioimpedance
                      : null,
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.carbon2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.monitor_weight_outlined,
                          size: 48,
                          color: AppColors.steel,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Nenhum Laudo de Bioimpedância Registrado',
                          style: AppTheme.headlineMd(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Anexe seu laudo de bioimpedância para visualizar gráficos de massa magra, gordura visceral e metabolismo basal.',
                          style: AppTheme.bodyMd(color: AppColors.steel),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blueAction,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Anexar Laudo Agora'),
                          onPressed: _open360Wizard,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostureTab(Student student) {
    final photos = _anamnese?.posturePhotos ?? [];
    final baselinePhotos = _anamneseHistory.isNotEmpty
        ? _anamneseHistory.last.posturePhotos
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PosturePhotoGalleryViewer(
                photos: photos,
                baselinePhotos: baselinePhotos,
                onAddPhoto: (angle) => _open360Wizard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeeds360Banner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.blue.withValues(alpha: 0.3), AppColors.carbon2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.pending_actions_rounded,
                color: AppColors.blueLight,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'FLUXO 360° PENDENTE',
                  style: AppTheme.labelCaps(color: AppColors.blueLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _anamnese == null
                ? 'Complete seu primeiro cadastro 360° para liberar sua periodização personalizada.'
                : 'Seu instrutor solicitou uma reavaliação 360° para atualizar sua bioimpedância e metas.',
            style: AppTheme.headlineMd(color: Colors.white),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blueAction,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(
              _anamnese == null
                  ? 'Iniciar Primeiro Acesso 360°'
                  : 'Refazer Avaliação 360°',
            ),
            onPressed: _open360Wizard,
          ),
        ],
      ),
    );
  }

  Widget _buildAnamneseValidCard(Student student) {
    final summary = Row(
      children: [
        const CircleAvatar(
          backgroundColor: AppColors.emerald,
          radius: 20,
          child: Icon(Icons.check, color: AppColors.carbon1, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Avaliação 360° Vigente',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              Text(
                'Última avaliação: ${_anamnese?.createdAt.day.toString().padLeft(2, '0')}/${_anamnese?.createdAt.month.toString().padLeft(2, '0')}/${_anamnese?.createdAt.year} • ${_anamneseHistory.length} no histórico',
                style: AppTheme.bodyMd(color: AppColors.steel),
              ),
            ],
          ),
        ),
      ],
    );
    final action = OutlinedButton.icon(
      icon: const Icon(Icons.visibility_outlined, size: 16),
      label: const Text('Ver Anamnese'),
      onPressed: () {
        if (_anamnese != null) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AnamneseDetailSheet(
              anamnese: _anamnese!,
              student: student,
              onUpdated: _checkStudentStatusAndLoadData,
            ),
          );
        }
      },
    );
    return CarbonCard(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 480) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [summary, const SizedBox(height: 14), action],
            );
          }
          return Row(
            children: [
              Expanded(child: summary),
              const SizedBox(width: 12),
              action,
            ],
          );
        },
      ),
    );
  }
}

String _setsLabel(int count) => count == 1 ? '1 série' : '$count séries';

String _dayInitials(String dow) {
  final label = dow.replaceFirst(
    RegExp(r'^Treino\s*', caseSensitive: false),
    '',
  );
  final trimmed = label.trim();
  if (trimmed.isEmpty) return '•';
  return trimmed.characters.take(2).toString().toUpperCase();
}

class _StepTile extends StatelessWidget {
  final IconData icon;
  final String text;

  const _StepTile({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.blueLight),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ),
      ],
    );
  }
}
