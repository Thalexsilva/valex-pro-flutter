import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/anamnese_model.dart';
import '../../models/student_model.dart';
import '../../models/finance_models.dart';
import '../../repositories/finance_repository.dart';
import '../../models/timeline_model.dart';
import '../../repositories/anamnese_repository.dart';
import '../../repositories/student_repository.dart';
import '../../repositories/student_workout_repository.dart';
import '../../services/anamnese_pdf_service.dart';
import '../../services/student_context_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../editor/editor_view.dart';
import '../finance/finance_creation_dialogs.dart';
import 'anamnese_detail_sheet.dart';
import 'anamnese_form_wizard_view.dart';
import 'anamnese_link_generator_dialog.dart';
import 'request_reassessment_dialog.dart';

class StudentDetailView extends StatefulWidget {
  final Student student;
  final StudentContextService? contextService;
  final StudentWorkoutRepository? activityRepository;
  final AnamneseRepository? assessmentRepository;
  final VoidCallback onEdit;
  final VoidCallback onToggleArchive;

  const StudentDetailView({
    super.key,
    required this.student,
    this.contextService,
    this.activityRepository,
    this.assessmentRepository,
    required this.onEdit,
    required this.onToggleArchive,
  });

  @override
  State<StudentDetailView> createState() => _StudentDetailViewState();
}

class _StudentDetailViewState extends State<StudentDetailView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  StudentFinancialSummary _summary = StudentFinancialSummary();
  List<StudentTimelineItem> _timeline = [];
  AnamneseModel? _anamnese;
  List<AnamneseModel> _anamneseHistory = [];
  List<StudentWorkoutEntry> _studentActivity = [];
  bool _activityLoadError = false;
  bool _isRefreshingActivity = false;
  bool _isLoading = true;
  List<InvoiceItem> _invoices = [];
  List<PaymentItem> _payments = [];
  List<SubscriptionItem> _subscriptions = [];
  List<PlanItem> _recurringPlans = [];
  bool _isChangingSubscription = false;
  String? _financeError;
  bool _summaryError = false;
  bool _timelineError = false;
  bool _assessmentError = false;

  late final StudentContextService _contextService =
      widget.contextService ?? StudentContextService();
  late final StudentWorkoutRepository _activityRepository =
      widget.activityRepository ?? StudentWorkoutRepository();
  late final AnamneseRepository _assessmentRepository =
      widget.assessmentRepository ?? AnamneseRepository();

  /// Cadastro atual do aluno: reflete edição e arquivamento feitos com a
  /// ficha aberta.
  Student get _student {
    for (final student in _contextService.allStudents) {
      if (student.id == widget.student.id) return student;
    }
    return widget.student;
  }

  void _onContextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _contextService.addListener(_onContextChanged);
    _loadData();
  }

  @override
  void didUpdateWidget(covariant StudentDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.student.id != widget.student.id) {
      _summary = StudentFinancialSummary();
      _timeline = [];
      _anamnese = null;
      _anamneseHistory = [];
      _studentActivity = [];
      _invoices = [];
      _payments = [];
      _subscriptions = [];
      _recurringPlans = [];
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    final id = widget.student.id;
    final repo = StudentRepository();
    final finance = FinanceRepository();

    Future<T?> optional<T>(Future<T> Function() fetch) async {
      try {
        return await fetch();
      } catch (_) {
        return null;
      }
    }

    Future<List<StudentWorkoutEntry>?> activity() async {
      try {
        return await _activityRepository.fetchEntries(id);
      } catch (_) {
        return null;
      }
    }

    Future<FinanceState?> financeState() async {
      try {
        return await finance.loadState();
      } catch (_) {
        return null;
      }
    }

    // Cada seção conserva seu último dado válido quando outra consulta falha.
    try {
      final results = await Future.wait<Object?>([
        optional(() => repo.fetchFinancialSummary(id)),
        optional(() => repo.fetchTimeline(id)),
        optional(() => _assessmentRepository.fetchHistoryResult(id)),
        activity(),
        financeState(),
      ]);
      final financialState = results[4] as FinanceState?;
      final financeError = financialState == null
          ? 'Não foi possível carregar os lançamentos. Tente novamente.'
          : finance.lastSyncError;
      final assessment = results[2] as AnamneseLoadResult?;
      if (mounted && widget.student.id == id) {
        setState(() {
          if (financialState != null) {
            _invoices = financialState.invoices
                .where((item) => item.studentId == id)
                .toList();
            _payments = financialState.payments
                .where((item) => item.studentId == id)
                .toList();
            _subscriptions = financialState.subscriptions
                .where((item) => item.studentId == id)
                .toList();
            _recurringPlans = financialState.plans
                .where(
                  (plan) =>
                      plan.active &&
                      plan.status == 'active' &&
                      plan.type == 'subscription',
                )
                .toList();
          }
          _financeError = financeError;
          final summary = results[0] as StudentFinancialSummary?;
          if (summary != null) _summary = summary;
          _summaryError = summary == null;
          final timeline = results[1] as List<StudentTimelineItem>?;
          if (timeline != null) _timeline = timeline;
          _timelineError = timeline == null;
          _assessmentError =
              assessment == null ||
              assessment.status == AnamneseLoadStatus.error;
          if (assessment != null && assessment.history.isNotEmpty) {
            _anamnese = assessment.latest;
            _anamneseHistory = assessment.history;
          } else if (assessment?.status == AnamneseLoadStatus.empty) {
            _anamnese = null;
            _anamneseHistory = [];
          }
          final activityEntries = results[3] as List<StudentWorkoutEntry>?;
          if (activityEntries != null) _studentActivity = activityEntries;
          _activityLoadError = activityEntries == null;
        });
      }
    } finally {
      finance.dispose();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshActivity() async {
    if (_isRefreshingActivity) return;
    setState(() => _isRefreshingActivity = true);
    try {
      final entries = await _activityRepository.fetchEntries(widget.student.id);
      if (!mounted) return;
      setState(() {
        _studentActivity = entries;
        _activityLoadError = false;
      });
    } catch (_) {
      if (mounted) setState(() => _activityLoadError = true);
    } finally {
      if (mounted) setState(() => _isRefreshingActivity = false);
    }
  }

  Future<void> _createFinanceRecord({required bool subscription}) async {
    final student = _student;
    final finance = FinanceRepository();
    try {
      await finance.loadState();
      if (!mounted) return;
      final plans = finance.state.plans
          .where(
            (plan) =>
                plan.active &&
                plan.status == 'active' &&
                (!subscription || plan.type == 'subscription'),
          )
          .toList();
      if (plans.isEmpty) {
        _showMessage(
          subscription
              ? 'Crie um plano recorrente no Financeiro antes de assinar.'
              : 'Crie um plano no Financeiro antes de emitir uma cobrança.',
        );
        return;
      }
      final students = {student.id: student.name};
      bool saved;
      if (subscription) {
        final draft = await showCreateSubscriptionDialog(
          context,
          students: students,
          plans: plans,
        );
        if (draft == null || !mounted) return;
        saved = await finance.createSubscription(
          studentId: draft.studentId,
          studentName: draft.studentName,
          planId: draft.planId,
          startDate: draft.startDate,
          amount: draft.amount,
          autoRenew: draft.autoRenew,
        );
      } else {
        final draft = await showCreateInvoiceDialog(
          context,
          students: students,
          plans: plans,
        );
        if (draft == null || !mounted) return;
        saved = await finance.createInvoice(
          studentId: draft.studentId,
          studentName: draft.studentName,
          planId: draft.planId,
          dueDate: draft.dueDate,
          amount: draft.amount,
        );
      }
      if (!mounted) return;
      _showMessage(
        !saved
            ? 'A operação não foi concluída. Tente novamente.'
            : subscription
            ? 'Assinatura criada.'
            : 'Cobrança emitida.',
      );
      if (saved) await _loadData();
    } on FinanceDataException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) {
        _showMessage(
          error.toString().replaceFirst('Invalid argument(s): ', ''),
        );
      }
    } finally {
      finance.dispose();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _manageSubscription(
    SubscriptionItem subscription, {
    required bool cancel,
  }) async {
    if (_isChangingSubscription) return;
    String? targetPlanId;
    if (cancel) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancelar assinatura?'),
          content: Text(
            'A assinatura de ${_student.name} no ${subscription.planName} será cancelada. Faturas já emitidas permanecem no histórico.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Voltar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar cancelamento'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    } else {
      final plans = _recurringPlans
          .where((plan) => plan.id != subscription.planId)
          .toList();
      if (plans.isEmpty) {
        _showMessage('Nenhum outro plano recorrente ativo disponível.');
        return;
      }
      targetPlanId = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text('Alterar plano de ${_student.name}'),
          children: [
            for (final plan in plans)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, plan.id),
                child: Text(
                  '${plan.name} • ${Formatters.formatBRL(plan.price)}',
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Voltar'),
            ),
          ],
        ),
      );
      if (targetPlanId == null || !mounted) return;
    }

    setState(() => _isChangingSubscription = true);
    final finance = FinanceRepository();
    try {
      await finance.loadState();
      final saved = cancel
          ? await finance.cancelSubscription(subscription.id)
          : await finance.changeSubscriptionPlan(
              subscription.id,
              targetPlanId!,
            );
      if (!mounted) return;
      _showMessage(
        saved
            ? cancel
                  ? 'Assinatura cancelada.'
                  : 'Plano alterado.'
            : 'A operação não foi concluída. Tente novamente.',
      );
      if (saved) await _loadData();
    } on FinanceDataException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) {
        _showMessage(
          error.toString().replaceFirst('Invalid argument(s): ', ''),
        );
      }
    } finally {
      finance.dispose();
      if (mounted) setState(() => _isChangingSubscription = false);
    }
  }

  static String _subscriptionLabel(String status) => status == 'Nenhum'
      ? 'Sem assinatura'
      : Formatters.translateFinanceStatus(status);

  static String _sessionTitle(StudentWorkoutEntry entry) {
    if (entry.kind != 'session') return 'Comentário do aluno';
    final day = entry.workoutDay.trim();
    if (day.isEmpty) return 'Treino concluído';
    return day.toLowerCase().startsWith('treino')
        ? '$day concluído'
        : 'Treino $day concluído';
  }

  static String _sessionDetail(StudentWorkoutEntry entry) {
    if (entry.kind != 'session') return entry.feedback;
    final parts = [
      if (entry.durationSeconds > 0)
        '${(entry.durationSeconds / 60).round()} min',
      if (entry.rpe != null) 'esforço ${entry.rpe}/10',
    ];
    final stats = parts.join(' • ');
    if (entry.feedback.isEmpty) {
      return stats.isEmpty ? 'Sem observações' : stats;
    }
    return stats.isEmpty ? entry.feedback : '$stats\n${entry.feedback}';
  }

  @override
  void dispose() {
    _contextService.removeListener(_onContextChanged);
    _tabController.dispose();
    super.dispose();
  }

  Widget _studentAction({
    required IconData icon,
    required String label,
    required String tooltip,
    required VoidCallback onPressed,
    Color color = AppColors.onSurface,
    double? width,
  }) {
    if (width == null) {
      return IconButton(
        icon: Icon(icon, color: color),
        tooltip: tooltip,
        onPressed: onPressed,
      );
    }
    return SizedBox(
      width: width,
      child: Tooltip(
        message: tooltip,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: color, size: 18),
          label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final student = _student;
    final summary = _summary;
    final compact = MediaQuery.sizeOf(context).width < 600;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // O cabeçalho rola junto com o conteúdo; as abas ficam fixas no topo.
    // Em celulares baixos o cabeçalho fixo esmagava as abas.
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: const Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (Navigator.canPop(context)) ...[
                      IconButton(
                        tooltip: 'Voltar para alunos',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 8),
                    ],
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.vibrantBlue,
                      child: Text(
                        student.name.isNotEmpty
                            ? student.name[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                student.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              Chip(
                                label: Text(
                                  student.isArchived ? 'Arquivado' : 'Ativo',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: student.isArchived
                                    ? AppColors.onSurfaceVariant
                                    : AppColors.emerald,
                              ),
                              if (_anamnese != null)
                                Chip(
                                  avatar: Text(
                                    _anamnese!.clinicalRisk.badgeEmoji,
                                  ),
                                  label: Text(
                                    _anamnese!.clinicalRisk ==
                                            ClinicalRiskLevel.low
                                        ? 'Apto'
                                        : 'Atenção',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: AppColors.carbon2,
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Email: ${student.email.isNotEmpty ? student.email : "Não informado"} • Tel: ${student.phone.isNotEmpty ? student.phone : "Não informado"}',
                            style: const TextStyle(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            student.email.isEmpty
                                ? 'Informe um e-mail para liberar o acesso do aluno.'
                                : 'O aluno entra no portal com uma conta criada neste e-mail.',
                            style: AppTheme.bodySm(color: AppColors.blueLight),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final actionWidth = !compact
                        ? null
                        : (constraints.maxWidth - 8) / 2;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _studentAction(
                          icon: Icons.sync_rounded,
                          color: AppColors.gold,
                          label: 'Avaliação 360°',
                          tooltip: 'Refazer / Solicitar Avaliação 360°',
                          width: actionWidth,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => RequestReassessmentDialog(
                                student: student,
                                onReassessmentTriggered: _loadData,
                              ),
                            );
                          },
                        ),
                        _studentAction(
                          icon: Icons.assignment_turned_in_outlined,
                          color: AppColors.emerald,
                          label: 'Anamnese',
                          tooltip: 'Anamnese 360° & Fotos',
                          width: actionWidth,
                          onPressed: () {
                            if (_assessmentError && _anamnese == null) {
                              _loadData();
                              return;
                            }
                            if (_anamnese != null) {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => AnamneseDetailSheet(
                                  anamnese: _anamnese!,
                                  student: student,
                                  onUpdated: _loadData,
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AnamneseFormWizardView(
                                    student: student,
                                    onCompleted: _loadData,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        _studentAction(
                          icon: Icons.share_outlined,
                          color: AppColors.blueLight,
                          label: 'Link WhatsApp',
                          tooltip: 'Gerar Link de Intake WhatsApp',
                          width: actionWidth,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) =>
                                  AnamneseLinkGeneratorDialog(student: student),
                            );
                          },
                        ),
                        _studentAction(
                          icon: Icons.fitness_center,
                          color: AppColors.blueLight,
                          label: 'Treino',
                          tooltip: 'Editar Ficha de Treino',
                          width: actionWidth,
                          onPressed: () {
                            (widget.contextService ?? StudentContextService())
                                .setActiveStudent(student.id);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditorView(
                                  studentId: student.id,
                                  contextService: widget.contextService,
                                ),
                              ),
                            );
                          },
                        ),
                        _studentAction(
                          icon: Icons.edit_outlined,
                          label: 'Perfil',
                          tooltip: 'Editar Perfil',
                          width: actionWidth,
                          onPressed: widget.onEdit,
                        ),
                        _studentAction(
                          icon: student.isArchived
                              ? Icons.unarchive
                              : Icons.archive_outlined,
                          label: student.isArchived
                              ? 'Desarquivar'
                              : 'Arquivar',
                          tooltip: student.isArchived
                              ? 'Desarquivar'
                              : 'Arquivar',
                          width: actionWidth,
                          onPressed: widget.onToggleArchive,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Painel-resumo financeiro no topo da ficha do aluno
                if (_summaryError) ...[
                  const Text(
                    'Resumo financeiro indisponível. Tente novamente.',
                  ),
                  TextButton(
                    onPressed: _loadData,
                    child: const Text('Atualizar ficha'),
                  ),
                ],
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.vibrantBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cellWidth = compact
                          ? (constraints.maxWidth - 16) / 2
                          : (constraints.maxWidth - 64) / 5;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _SummaryMetric(
                            'Plano Atual',
                            _summaryError ? 'Indisponível' : summary.planName,
                            AppColors.onSurface,
                            width: cellWidth,
                          ),
                          _SummaryMetric(
                            'Status',
                            _summaryError
                                ? 'Indisponível'
                                : _subscriptionLabel(
                                    summary.subscriptionStatus,
                                  ),
                            summary.subscriptionStatus == 'active'
                                ? AppColors.emerald
                                : AppColors.amber,
                            width: cellWidth,
                          ),
                          _SummaryMetric(
                            'Próximo Venc.',
                            _summaryError
                                ? 'Indisponível'
                                : _dateLabel(summary.nextDueDate),
                            AppColors.onSurface,
                            width: cellWidth,
                          ),
                          _SummaryMetric(
                            'Total Aberto',
                            _summaryError
                                ? 'Indisponível'
                                : Formatters.formatBRL(summary.totalOpen),
                            summary.totalOverdue > 0
                                ? AppColors.crimson
                                : AppColors.onSurface,
                            width: cellWidth,
                          ),
                          _SummaryMetric(
                            'Último Pagamento',
                            _summaryError
                                ? 'Indisponível'
                                : _dateLabel(summary.lastPaymentDate),
                            AppColors.emerald,
                            width: cellWidth,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _PinnedTabBar(
            color: Theme.of(context).scaffoldBackgroundColor,
            tabBar: TabBar(
              isScrollable: true,
              controller: _tabController,
              labelColor: AppColors.vibrantBlue,
              unselectedLabelColor: AppColors.onSurfaceVariant,
              indicatorColor: AppColors.vibrantBlue,
              tabs: const [
                Tab(text: 'Resumo'),
                Tab(text: 'Evolução'),
                Tab(text: 'Faturas'),
                Tab(text: 'Pagamentos'),
                Tab(text: 'Assinatura'),
                Tab(text: 'Histórico'),
                Tab(text: 'Comentários'),
              ],
            ),
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Resumo
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dados Cadastrais & Ficha',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• CPF: ${student.cpf.isNotEmpty ? student.cpf : "Não informado"}',
                      ),
                      Text(
                        '• Academia: ${student.gymName.isNotEmpty ? student.gymName : "Não informada"}',
                      ),
                      Text(
                        '• Vigência Ficha: ${student.month.isNotEmpty ? student.month : "Não informada"}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Icon(
                            Icons.health_and_safety_outlined,
                            color: AppColors.vibrantBlue,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Anamnese & Avaliação 360°',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (_anamnese != null)
                            Chip(
                              avatar: Text(_anamnese!.clinicalRisk.badgeEmoji),
                              label: Text(_anamnese!.clinicalRisk.label),
                              backgroundColor: AppColors.carbon2,
                            )
                          else
                            Chip(
                              label: Text(
                                _assessmentError
                                    ? 'Indisponível'
                                    : 'Não preenchida',
                                style: TextStyle(fontSize: 11),
                              ),
                              backgroundColor: AppColors.carbon2,
                            ),
                        ],
                      ),
                      if (_assessmentError) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Não foi possível consultar a avaliação 360°. Os dados exibidos podem estar desatualizados.',
                        ),
                        TextButton(
                          onPressed: _loadData,
                          child: const Text('Atualizar avaliação'),
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (student.needsReassessment ||
                          student.anamnesePending) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.pending_actions_rounded,
                                color: AppColors.gold,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Reavaliação 360° Solicitada',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.gold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      'O aluno responderá no próximo login ou pelo link de auto-atendimento.',
                                      style: AppTheme.bodyMd(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_anamnese != null) ...[
                        Text(
                          '• Biometria: ${_anamnese!.weightKg} kg | ${_anamnese!.heightCm} cm | IMC: ${_anamnese!.bmi} (${_anamnese!.bmiClassification})',
                        ),
                        Text(
                          '• Objetivo: ${_anamnese!.mainGoal} (${_anamnese!.specificGoals.isNotEmpty ? _anamnese!.specificGoals : "Sem detalhes"})',
                        ),
                        Text(
                          '• Frequência: ${_anamnese!.trainingDaysPerWeek} dias/semana • Duração: ${_anamnese!.sessionDuration}',
                        ),
                        if (_anamnese!.jointPains.isNotEmpty)
                          Text(
                            '⚠️ Dores Relatadas: ${_anamnese!.jointPains.join(", ")}',
                            style: const TextStyle(color: AppColors.amber),
                          ),
                        if (_anamnese!.posturePhotos.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            '📷 ${_anamnese!.posturePhotos.length} fotos posturais anexadas no cofre.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ] else ...[
                        Text(
                          _assessmentError
                              ? 'Avaliação indisponível no momento.'
                              : student.prontuarioText.isNotEmpty
                              ? student.prontuarioText
                              : 'Nenhuma anamnese registrada para este aluno ainda.',
                          style: const TextStyle(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: Colors.black,
                            ),
                            icon: const Icon(Icons.sync_rounded, size: 16),
                            label: const Text('Refazer Fluxo 360°'),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => RequestReassessmentDialog(
                                  student: student,
                                  onReassessmentTriggered: _loadData,
                                ),
                              );
                            },
                          ),
                          if (_anamnese != null) ...[
                            ElevatedButton.icon(
                              icon: const Icon(
                                Icons.visibility_outlined,
                                size: 16,
                              ),
                              label: const Text(
                                'Ver Avaliação Completa & Fotos',
                              ),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => AnamneseDetailSheet(
                                    anamnese: _anamnese!,
                                    student: student,
                                    onUpdated: _loadData,
                                  ),
                                );
                              },
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.carbon3,
                                foregroundColor: AppColors.gold,
                              ),
                              icon: const Icon(
                                Icons.picture_as_pdf_rounded,
                                size: 16,
                                color: AppColors.gold,
                              ),
                              label: const Text('Exportar Laudo PDF'),
                              onPressed: () =>
                                  AnamnesePdfService.printOrSharePdf(
                                    anamnese: _anamnese!,
                                    student: student,
                                  ),
                            ),
                          ],
                          OutlinedButton.icon(
                            icon: const Icon(Icons.edit_note, size: 16),
                            label: Text(
                              _anamnese != null
                                  ? 'Editar Respostas'
                                  : _assessmentError
                                  ? 'Atualizar avaliação'
                                  : 'Preencher Anamnese',
                            ),
                            onPressed: () {
                              if (_assessmentError && _anamnese == null) {
                                _loadData();
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AnamneseFormWizardView(
                                    student: student,
                                    initialAnamnese: _anamnese,
                                    onCompleted: _loadData,
                                  ),
                                ),
                              );
                            },
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.link, size: 16),
                            label: const Text('Gerar Link WhatsApp'),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    AnamneseLinkGeneratorDialog(
                                      student: student,
                                    ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Tab 2: Evolução
          _buildEvolutionTab(),

          _buildFinanceTab(false),
          _buildFinanceTab(true),

          // Tab 4: Assinatura (Com Estado Vazio Interativo)
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (summary.subscriptionStatus == 'Nenhum' ||
                  summary.subscriptionStatus == 'cancelled') ...[
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.card_membership_outlined,
                        size: 48,
                        color: AppColors.amber,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Aluno sem assinatura ativa',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Este aluno não possui nenhum plano recorrente ativo no momento.',
                        style: TextStyle(color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Assinar Plano'),
                            onPressed: () =>
                                _createFinanceRecord(subscription: true),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.receipt_long),
                            label: const Text('Emitir Cobrança Avulsa'),
                            onPressed: () =>
                                _createFinanceRecord(subscription: false),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text('Plano: ${summary.planName}'),
                          subtitle: Text(
                            'Status: ${_subscriptionLabel(summary.subscriptionStatus)}'
                            ' • Próximo vencimento: ${_dateLabel(summary.nextDueDate)}',
                          ),
                        ),
                        for (final subscription in _subscriptions.where(
                          (item) => item.status == 'active',
                        ))
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (_recurringPlans.any(
                                (plan) => plan.id != subscription.planId,
                              ))
                                OutlinedButton.icon(
                                  onPressed: _isChangingSubscription
                                      ? null
                                      : () => _manageSubscription(
                                          subscription,
                                          cancel: false,
                                        ),
                                  icon: const Icon(Icons.swap_horiz),
                                  label: const Text('Alterar plano'),
                                ),
                              OutlinedButton.icon(
                                onPressed: _isChangingSubscription
                                    ? null
                                    : () => _manageSubscription(
                                        subscription,
                                        cancel: true,
                                      ),
                                icon: const Icon(Icons.cancel_outlined),
                                label: const Text('Cancelar assinatura'),
                              ),
                            ],
                          ),
                        if (_subscriptions
                            .where((item) => item.status == 'active')
                            .isEmpty)
                          const Text(
                            'Não foi possível localizar o vínculo desta assinatura. Atualize a ficha e tente novamente.',
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_subscriptions.any((item) => item.status == 'cancelled')) ...[
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Text(
                          'Assinaturas canceladas',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      for (final subscription in _subscriptions.where(
                        (item) => item.status == 'cancelled',
                      ))
                        ListTile(
                          title: Text(subscription.planName),
                          subtitle: Text(
                            'Cancelada • Início: ${Formatters.formatDateBR(subscription.startDate)}',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          // Tab 5: Histórico (Timeline)
          _timelineError
              ? ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'Não foi possível atualizar o histórico do aluno.',
                    ),
                    TextButton(
                      onPressed: _loadData,
                      child: const Text('Atualizar histórico'),
                    ),
                    for (final item in _timeline)
                      ListTile(
                        title: Text(item.title),
                        subtitle: Text(item.description),
                      ),
                  ],
                )
              : _timeline.isEmpty
              ? const Center(
                  child: Text('Nenhum evento registrado no histórico.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _timeline.length,
                  itemBuilder: (context, index) {
                    final item = _timeline[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.history_toggle_off_rounded,
                        color: AppColors.vibrantBlue,
                      ),
                      title: Text(item.title),
                      subtitle: Text(
                        '${item.description}\n'
                        '${Formatters.formatDateBR(item.timestamp)}',
                      ),
                    );
                  },
                ),
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_activityLoadError) ...[
                Semantics(
                  liveRegion: true,
                  child: const Text(
                    'Não foi possível carregar a atividade do aluno.',
                  ),
                ),
                TextButton.icon(
                  onPressed: _isRefreshingActivity ? null : _refreshActivity,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    _isRefreshingActivity
                        ? 'Atualizando...'
                        : 'Tentar novamente',
                  ),
                ),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Atualizar'),
                ),
              ),
              if (_studentActivity.isEmpty && !_activityLoadError)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('Nenhum comentário ou treino registrado.'),
                  ),
                ),
              ..._studentActivity.map(
                (entry) => Card(
                  child: ListTile(
                    leading: Icon(
                      entry.kind == 'session'
                          ? Icons.fitness_center
                          : Icons.chat_bubble_outline,
                      color: AppColors.blueLight,
                    ),
                    title: Text(_sessionTitle(entry)),
                    subtitle: Text(_sessionDetail(entry)),
                    trailing: Text(
                      '${entry.createdAt.day.toString().padLeft(2, '0')}/${entry.createdAt.month.toString().padLeft(2, '0')}',
                      style: AppTheme.bodySm(color: AppColors.steel),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceTab(bool payments) {
    final rows = payments
        ? _payments
              .map(
                (item) => (
                  title: 'Pagamento • ${item.paymentMethod.toUpperCase()}',
                  detail:
                      '${_dateLabel(item.paymentDate)} • ${item.status == 'confirmed' ? 'Confirmado' : 'Estornado'}',
                  amount: item.amount,
                ),
              )
              .toList()
        : _invoices
              .map(
                (item) => (
                  title: item.planName,
                  detail:
                      'Vencimento: ${_dateLabel(item.dueDate)} • ${switch (item.effectiveStatus()) {
                        'paid' => 'Paga',
                        'pending' => 'Pendente',
                        'overdue' => 'Atrasada',
                        'cancelled' => 'Cancelada',
                        'draft' => 'Rascunho',
                        final other => other,
                      }}',
                  amount: item.finalAmount,
                ),
              )
              .toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_financeError != null) ...[
          Text(_financeError!),
          TextButton(
            onPressed: _loadData,
            child: const Text('Tentar novamente'),
          ),
        ],
        if (rows.isEmpty && _financeError == null)
          Text(
            payments
                ? 'Nenhum pagamento registrado para este aluno.'
                : 'Nenhuma fatura registrada para este aluno.',
          ),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.title, style: AppTheme.bodyLg()),
                const SizedBox(height: 4),
                Text(row.detail),
                const SizedBox(height: 8),
                Text(
                  'R\$ ${row.amount.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Divider(),
              ],
            ),
          ),
      ],
    );
  }

  String _dateLabel(String value) {
    if (value.isEmpty || value == '-') return '—';
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildEvolutionTab() {
    if (_anamneseHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _assessmentError
                  ? 'Não foi possível consultar a evolução do aluno.'
                  : 'Nenhuma anamnese/bioimpedância registrada para montar o gráfico longitudinal.',
            ),
            if (_assessmentError)
              TextButton(
                onPressed: _loadData,
                child: const Text('Atualizar evolução'),
              ),
          ],
        ),
      );
    }

    // Filtrar apenas as anamneses que possuem dados de bioimpedância válidos
    final bioHistory = _anamneseHistory
        .where((a) => a.bioimpedance != null && a.bioimpedance!.hasMetrics)
        .toList();

    if (bioHistory.length < 2) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'Gráfico longitudinal será gerado a partir da segunda avaliação de bioimpedância, permitindo visualizar a evolução real (Massa Magra vs. Gordura).',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.onSurfaceVariant),
          ),
        ),
      );
    }

    final spotsMassaMagra = <FlSpot>[];
    final spotsGordura = <FlSpot>[];

    // Sort chronologically if not already
    bioHistory.sort((a, b) {
      final aDate = a.bioimpedance?.assessmentDate ?? DateTime.now();
      final bDate = b.bioimpedance?.assessmentDate ?? DateTime.now();
      return aDate.compareTo(bDate);
    });

    for (var i = 0; i < bioHistory.length; i++) {
      final b = bioHistory[i].bioimpedance!;
      spotsMassaMagra.add(FlSpot(i.toDouble(), b.muscleMassKg ?? 0));
      spotsGordura.add(FlSpot(i.toDouble(), b.fatMassKg ?? 0));
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Evolução Longitudinal de Composição Corporal',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Acompanhe o delta de Massa Magra (Azul) vs. Massa Gorda (Vermelho) ao longo do tempo.',
          style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.carbon2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: Colors.white10, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final int index = value.toInt();
                      if (index >= 0 && index < bioHistory.length) {
                        final date =
                            bioHistory[index].bioimpedance?.assessmentDate ??
                            DateTime.now();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${date.day}/${date.month}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spotsMassaMagra,
                  isCurved: true,
                  color: AppColors.vibrantBlue,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.vibrantBlue.withValues(alpha: 0.1),
                  ),
                ),
                LineChartBarData(
                  spots: spotsGordura,
                  isCurved: true,
                  color: AppColors.crimson,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.crimson.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(color: AppColors.vibrantBlue, text: 'Massa Magra (kg)'),
            const SizedBox(width: 24),
            _LegendItem(color: AppColors.crimson, text: 'Massa Gorda (kg)'),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final double width;

  const _SummaryMetric(
    this.label,
    this.value,
    this.valueColor, {
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _PinnedTabBar extends SliverPersistentHeaderDelegate {
  const _PinnedTabBar({required this.tabBar, required this.color});

  final TabBar tabBar;
  final Color color;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ColoredBox(color: color, child: tabBar);

  @override
  bool shouldRebuild(_PinnedTabBar oldDelegate) =>
      oldDelegate.tabBar != tabBar || oldDelegate.color != color;
}
