import 'package:flutter/material.dart';

import '../../controllers/user_profile_controller.dart';
import '../../models/finance_models.dart';
import '../../models/student_model.dart';
import '../../repositories/finance_repository.dart';
import '../../repositories/student_workout_repository.dart';
import '../../services/student_context_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/carbon_card.dart';
import '../editor/editor_view.dart';

/// Visão operacional do treinador, com a mesma hierarquia em telas grandes e pequenas.
class DashboardView extends StatefulWidget {
  final StudentContextService? studentContext;
  final FinanceRepository? financeRepository;
  final StudentWorkoutRepository? activityRepository;
  final VoidCallback? onOpenEditor;
  final VoidCallback? onOpenStudents;

  const DashboardView({
    super.key,
    this.studentContext,
    this.financeRepository,
    this.activityRepository,
    this.onOpenEditor,
    this.onOpenStudents,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late final StudentContextService _studentContext;
  late final FinanceRepository _financeRepository;
  FinanceState? _financeState;
  bool _isLoadingFinance = true;
  String? _financeError;
  late final StudentWorkoutRepository _activityRepository;
  List<StudentWorkoutEntry> _activity = [];
  bool _isLoadingActivity = true;
  bool _activityError = false;

  @override
  void initState() {
    super.initState();
    _studentContext = widget.studentContext ?? StudentContextService();
    _financeRepository = widget.financeRepository ?? FinanceRepository();
    _activityRepository =
        widget.activityRepository ?? StudentWorkoutRepository();
    _financeRepository.addListener(_onFinanceChanged);
    _studentContext.addListener(_onStudentContextChanged);
    _loadFinance();
    _loadActivity();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadFinance(),
      _loadActivity(),
      _studentContext.refreshFromRemote(),
    ]);
  }

  Future<void> _loadActivity() async {
    if (mounted) {
      setState(() {
        _isLoadingActivity = true;
        _activityError = false;
      });
    }
    try {
      final entries = await _activityRepository.fetchRecentForTrainer();
      if (!mounted) return;
      setState(() => _activity = entries);
    } catch (_) {
      if (!mounted) return;
      setState(() => _activityError = true);
    } finally {
      if (mounted) setState(() => _isLoadingActivity = false);
    }
  }

  @override
  void dispose() {
    _financeRepository.removeListener(_onFinanceChanged);
    if (widget.financeRepository == null) _financeRepository.dispose();
    _studentContext.removeListener(_onStudentContextChanged);
    super.dispose();
  }

  void _onStudentContextChanged() {
    if (mounted) setState(() {});
  }

  void _onFinanceChanged() {
    if (mounted) setState(() => _financeState = _financeRepository.state);
  }

  Future<void> _loadFinance() async {
    if (mounted) {
      setState(() {
        _isLoadingFinance = true;
        _financeError = null;
      });
    }
    try {
      final state = await _financeRepository.loadState();
      if (!mounted) return;
      setState(() => _financeState = state);
    } catch (_) {
      if (!mounted) return;
      setState(() => _financeError = 'Não foi possível carregar o financeiro.');
    } finally {
      if (mounted) setState(() => _isLoadingFinance = false);
    }
  }

  String _financeAmount(double amount) {
    if (_isLoadingFinance) return '—';
    if (_financeError != null || _financeState == null) return 'Indisponível';
    return Formatters.formatBRL(amount);
  }

  @override
  Widget build(BuildContext context) {
    final activeStudent = _studentContext.activeStudent;
    final activeStudents = _studentContext.allStudents
        .where((student) => student.status == StudentStatus.active)
        .length;
    final metrics = _financeState?.metrics ?? FinanceMetricsData();

    return Scaffold(
      backgroundColor: AppColors.carbon,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1000;
              final padding = constraints.maxWidth < 600 ? 20.0 : 36.0;
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(padding, 32, padding, 48),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _header(wide),
                          if (_studentContext.isInitialized &&
                              _studentContext.allStudents.isEmpty &&
                              widget.onOpenStudents != null) ...[
                            const SizedBox(height: 24),
                            _firstStudentGuide(),
                          ],
                          const SizedBox(height: 36),
                          _sectionHeading(
                            'Visão do negócio',
                            'Indicadores em tempo real',
                          ),
                          const SizedBox(height: 18),
                          if (_financeError != null) ...[
                            _financeErrorPanel(),
                            const SizedBox(height: 16),
                          ],
                          if (wide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _studentsCard(activeStudents)),
                                const SizedBox(width: 16),
                                Expanded(flex: 2, child: _revenueCard(metrics)),
                              ],
                            )
                          else ...[
                            _studentsCard(activeStudents),
                            const SizedBox(height: 14),
                            _revenueCard(metrics),
                          ],
                          const SizedBox(height: 16),
                          if (wide)
                            Row(
                              children: [
                                Expanded(
                                  child: _smallMetric(
                                    'Recebido',
                                    metrics.receitaRecebida,
                                    Icons.payments_outlined,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _smallMetric(
                                    'Atrasos',
                                    metrics.receitaAtrasada,
                                    Icons.schedule_rounded,
                                    warning: true,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _smallMetric(
                                    'Caixa disponível',
                                    metrics.saldoCaixa,
                                    Icons.account_balance_outlined,
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _smallMetric(
                                    'Recebido',
                                    metrics.receitaRecebida,
                                    Icons.payments_outlined,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _smallMetric(
                                    'Atrasos',
                                    metrics.receitaAtrasada,
                                    Icons.schedule_rounded,
                                    warning: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _smallMetric(
                              'Caixa disponível',
                              metrics.saldoCaixa,
                              Icons.account_balance_outlined,
                            ),
                          ],
                          const SizedBox(height: 40),
                          _sectionHeading(
                            'Atividade dos alunos',
                            'Treinos concluídos e mensagens recentes',
                          ),
                          const SizedBox(height: 18),
                          _activityCard(),
                          const SizedBox(height: 40),
                          _sectionHeading(
                            'Aluno em foco',
                            'Acesso rápido à ficha ativa',
                          ),
                          const SizedBox(height: 18),
                          _studentCard(activeStudent),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(bool wide) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PAINEL DO TREINADOR',
          style: AppTheme.labelCaps(color: AppColors.blueLight),
        ),
        const SizedBox(height: 10),
        ListenableBuilder(
          listenable: UserProfileController(),
          builder: (context, _) => Semantics(
            header: true,
            child: Text(
              'Olá, ${UserProfileController().displayName}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.headlineLg(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Seu trabalho, seus alunos e seus números em um só lugar.',
          style: AppTheme.bodyMd(),
        ),
      ],
    );
    final mark = Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        color: AppColors.carbon2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.dividerColor),
      ),
      padding: const EdgeInsets.all(12),
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain,
        semanticLabel: 'VALEX',
      ),
    );
    return wide
        ? Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 24),
              mark,
            ],
          )
        : title;
  }

  Widget _sectionHeading(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(header: true, child: Text(title, style: AppTheme.headlineMd())),
      const SizedBox(height: 3),
      Text(subtitle, style: AppTheme.bodySm(color: AppColors.steelDim)),
    ],
  );

  Widget _firstStudentGuide() => CarbonCard(
    premiumBorder: false,
    solid: true,
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Comece pelo primeiro aluno',
            style: AppTheme.headlineMd(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Cadastre um aluno para montar a primeira ficha e acompanhar os treinos por aqui.',
          style: AppTheme.bodyMd(color: AppColors.steel),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: widget.onOpenStudents,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Cadastrar primeiro aluno'),
        ),
      ],
    ),
  );

  Widget _studentsCard(int count) => CarbonCard(
    premiumBorder: false,
    solid: true,
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _metricIcon(Icons.groups_2_outlined),
        const SizedBox(height: 20),
        Text(
          _studentContext.isInitialized ||
                  _studentContext.allStudents.isNotEmpty
              ? '$count'
              : '—',
          style: AppTheme.kpiXl(color: AppColors.steelLight),
        ),
        const SizedBox(height: 2),
        Text(
          'Alunos ativos',
          style: AppTheme.bodyMd(color: AppColors.steelLight),
        ),
        const SizedBox(height: 4),
        Text(
          'Na sua carteira agora',
          style: AppTheme.bodySm(color: AppColors.steelDim),
        ),
      ],
    ),
  );

  Widget _revenueCard(FinanceMetricsData metrics) => Container(
    decoration: BoxDecoration(
      color: AppColors.carbon2,
      borderRadius: BorderRadius.circular(AppColors.radiusCard),
      border: Border.all(color: AppColors.blue.withValues(alpha: 0.32)),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.blue.withValues(alpha: 0.17), AppColors.carbon2],
      ),
    ),
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _metricIcon(Icons.trending_up_rounded),
            const Spacer(),
            Text(
              'MENSAL',
              style: AppTheme.labelCaps(color: AppColors.blueLight),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          _financeAmount(metrics.mrr),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.kpiXl(color: AppColors.steelLight),
        ),
        const SizedBox(height: 2),
        Text(
          'Receita recorrente',
          style: AppTheme.bodyMd(color: AppColors.steelLight),
        ),
        const SizedBox(height: 4),
        Text(
          'Estimativa das assinaturas ativas',
          style: AppTheme.bodySm(color: AppColors.steelDim),
        ),
      ],
    ),
  );

  Widget _smallMetric(
    String label,
    double amount,
    IconData icon, {
    bool warning = false,
  }) => CarbonCard(
    premiumBorder: false,
    solid: true,
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 21,
          color: warning ? AppColors.amber : AppColors.blueLight,
        ),
        const SizedBox(height: 15),
        Text(
          _financeAmount(amount),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.kpiMd(color: AppColors.steelLight),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.bodySm(color: AppColors.steel),
        ),
      ],
    ),
  );

  Widget _metricIcon(IconData icon) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: AppColors.blue.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Icon(icon, color: AppColors.blueLight, size: 23),
  );

  Widget _financeErrorPanel() => Semantics(
    liveRegion: true,
    child: CarbonCard(
      premiumBorder: false,
      solid: true,
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.crimson),
          const SizedBox(width: 12),
          Expanded(child: Text(_financeError!, style: AppTheme.bodyMd())),
          TextButton(
            onPressed: _loadFinance,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    ),
  );

  static String _shortDate(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final time =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return 'hoje, $time';
    }
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}';
  }

  Widget _activityRow(StudentWorkoutEntry entry, Map<String, String> names) {
    final name = names[entry.studentId] ?? 'Aluno';
    final isSession = entry.kind == 'session';
    final day = entry.workoutDay.trim();
    final title = isSession
        ? '$name concluiu ${day.isEmpty ? 'um treino' : day}'
        : '$name enviou uma mensagem';
    final stats = [
      if (isSession && entry.durationSeconds > 0)
        '${(entry.durationSeconds / 60).round()} min',
      if (isSession && entry.rpe != null) 'esforço ${entry.rpe}/10',
    ].join(' • ');
    final detail = [
      if (stats.isNotEmpty) stats,
      if (entry.feedback.isNotEmpty) '“${entry.feedback}”',
    ].join('\n');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSession
                ? Icons.fitness_center_rounded
                : Icons.chat_bubble_outline_rounded,
            size: 20,
            color: isSession ? AppColors.emerald : AppColors.blueLight,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.bodyMd(color: Colors.white)),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodySm(color: AppColors.steelLight),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _shortDate(entry.createdAt),
            style: AppTheme.bodySm(color: AppColors.steel),
          ),
        ],
      ),
    );
  }

  Widget _activityCard() {
    final names = {
      for (final student in _studentContext.allStudents)
        student.id: student.name,
    };
    final pending = _studentContext.allStudents
        .where(
          (student) =>
              !student.isArchived &&
              (student.needsReassessment || student.anamnesePending),
        )
        .toList();
    final Widget body;
    if (_isLoadingActivity && _activity.isEmpty) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(color: AppColors.blue)),
      );
    } else if (_activityError && _activity.isEmpty) {
      body = Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.amber),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Não foi possível carregar a atividade dos alunos.',
              style: AppTheme.bodyMd(),
            ),
          ),
          TextButton(
            onPressed: _loadActivity,
            child: const Text('Tentar novamente'),
          ),
        ],
      );
    } else if (_activity.isEmpty) {
      body = Text(
        'Quando seus alunos concluírem treinos ou enviarem mensagens pelo '
        'portal, elas aparecem aqui.',
        style: AppTheme.bodyMd(),
      );
    } else {
      body = Column(
        children: [
          for (final (index, entry) in _activity.indexed) ...[
            if (index > 0) Divider(color: AppColors.dividerColor, height: 1),
            _activityRow(entry, names),
          ],
        ],
      );
    }
    return CarbonCard(
      premiumBorder: false,
      solid: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pending.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.pending_actions_rounded,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pending.length == 1
                        ? 'Avaliação 360° pendente: ${pending.first.name}'
                        : '${pending.length} avaliações 360° pendentes: '
                              '${pending.take(3).map((s) => s.name.split(' ').first).join(', ')}'
                              '${pending.length > 3 ? '…' : ''}',
                    style: AppTheme.bodyMd(color: Colors.white),
                  ),
                ),
                if (widget.onOpenStudents != null)
                  TextButton(
                    onPressed: widget.onOpenStudents,
                    child: const Text('Ver alunos'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: AppColors.dividerColor, height: 1),
            const SizedBox(height: 4),
          ],
          body,
        ],
      ),
    );
  }

  Widget _studentCard(Student? student) {
    if (student == null) {
      return CarbonCard(
        premiumBorder: false,
        solid: true,
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            _metricIcon(Icons.person_search_outlined),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Selecione ou cadastre um aluno para abrir a ficha ativa.',
                style: AppTheme.bodyMd(),
              ),
            ),
          ],
        ),
      );
    }

    return CarbonCard(
      premiumBorder: false,
      solid: true,
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 500;
          final details = Row(
            children: [
              _metricIcon(Icons.person_outline_rounded),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.headlineSm(),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      student.gymName.isEmpty
                          ? 'Academia não informada'
                          : student.gymName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodySm(),
                    ),
                  ],
                ),
              ),
            ],
          );
          final action = ElevatedButton.icon(
            onPressed:
                widget.onOpenEditor ??
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditorView(studentId: student.id),
                  ),
                ),
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Abrir editor'),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              compact
                  ? details
                  : Row(
                      children: [
                        Expanded(child: details),
                        const SizedBox(width: 16),
                        action,
                      ],
                    ),
              if (student.prontuarioText.isNotEmpty) ...[
                const SizedBox(height: 18),
                Divider(color: AppColors.dividerColor, height: 1),
                const SizedBox(height: 16),
                Text(
                  student.prontuarioText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyMd(),
                ),
              ],
              if (compact) ...[
                const SizedBox(height: 18),
                SizedBox(width: double.infinity, child: action),
              ],
            ],
          );
        },
      ),
    );
  }
}
