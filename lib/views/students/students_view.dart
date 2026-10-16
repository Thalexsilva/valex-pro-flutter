import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/student_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/carbon_card.dart';
import '../../widgets/status_dot.dart';
import 'student_detail_view.dart';
import 'student_form_dialog.dart';
import 'anamnese_form_wizard_view.dart';
import 'anamnese_student_picker.dart';
import '../../repositories/student_repository.dart';
import '../../services/student_context_service.dart';

class StudentsView extends StatefulWidget {
  const StudentsView({super.key, this.contextService});

  final StudentContextService? contextService;

  @override
  State<StudentsView> createState() => _StudentsViewState();
}

class _StudentsViewState extends State<StudentsView> {
  String _filterStatus = 'all'; // 'all' | 'active' | 'overdue' | 'archived'
  String _searchQuery = '';
  final _searchController = TextEditingController();

  final StudentRepository _studentRepository = StudentRepository();
  Map<String, StudentFinancialSummary> _summaries = {};
  Set<String> _summaryIds = {};
  bool _summaryError = false;
  late final StudentContextService _contextService;

  @override
  void initState() {
    super.initState();
    _contextService = widget.contextService ?? StudentContextService();
    _contextService.addListener(_onContextChanged);
    _initialLoad();
  }

  @override
  void dispose() {
    _contextService.removeListener(_onContextChanged);
    _searchController.dispose();
    super.dispose();
  }

  bool get _isLoading => !_contextService.isInitialized;

  Future<void> _initialLoad() async {
    await _contextService.init();
    if (!mounted) return;
    setState(() {});
    await _ensureSummaries();
  }

  void _onContextChanged() {
    if (!mounted) return;
    setState(() {});
    _ensureSummaries();
  }

  /// Um único pedido para o resumo financeiro de todos os alunos; refeito só
  /// quando a lista muda ou o instrutor puxa para atualizar.
  Future<void> _ensureSummaries({bool force = false}) async {
    final ids = _contextService.allStudents.map((s) => s.id).toSet();
    if (!force && setEquals(ids, _summaryIds)) return;
    _summaryIds = ids;
    try {
      final summaries = await _studentRepository.fetchFinancialSummaries(
        ids.toList(),
      );
      if (!mounted) return;
      setState(() {
        _summaries = summaries;
        _summaryError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _summaryError = true);
    }
  }

  Future<void> _refresh() async {
    await _contextService.refreshFromRemote();
    await _ensureSummaries(force: true);
  }

  Student? _currentStudent(String id) {
    for (final student in _contextService.allStudents) {
      if (student.id == id) return student;
    }
    return null;
  }

  Future<void> _openAnamnese() async {
    final students = _contextService.allStudents
        .where((s) => !s.isArchived)
        .toList();
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastre um aluno ativo antes de iniciar a anamnese.'),
        ),
      );
      _openFormDialog();
      return;
    }
    final student = await showDialog<Student>(
      context: context,
      builder: (_) => AnamneseStudentPicker(students: students),
    );
    if (!mounted || student == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AnamneseFormWizardView(student: student, onCompleted: _refresh),
      ),
    );
  }

  static int _compareNames(Student a, Student b) => Formatters.normalizeSearch(
    a.name,
  ).compareTo(Formatters.normalizeSearch(b.name));

  List<_StudentRowData> get _studentsData {
    final students = _contextService.allStudents..sort(_compareNames);
    return [
      for (final student in students)
        _StudentRowData(
          student: student,
          summary: _summaries[student.id] ?? StudentFinancialSummary(),
          isArchived: student.status == StudentStatus.archived,
        ),
    ];
  }

  bool get _hasFilters => _filterStatus != 'all' || _searchQuery.isNotEmpty;

  List<_StudentRowData> _filter(List<_StudentRowData> rows) {
    final query = Formatters.normalizeSearch(_searchQuery);
    final queryDigits = Formatters.digitsOnly(_searchQuery);
    return rows.where((item) {
      final isPending =
          item.summary.badge == FinancialBadge.overdue ||
          item.summary.badge == FinancialBadge.dueToday;
      if (_filterStatus == 'active' && item.isArchived) return false;
      if (_filterStatus == 'overdue' && !isPending) return false;
      if (_filterStatus == 'archived' && !item.isArchived) return false;

      if (query.isEmpty) return true;
      final student = item.student;
      if (Formatters.normalizeSearch(student.name).contains(query) ||
          Formatters.normalizeSearch(item.summary.planName).contains(query) ||
          Formatters.normalizeSearch(student.email).contains(query)) {
        return true;
      }
      // CPF e telefone com ou sem pontuação.
      return queryDigits.length >= 3 &&
          (Formatters.digitsOnly(student.cpf).contains(queryDigits) ||
              Formatters.digitsOnly(student.phone).contains(queryDigits));
    }).toList();
  }

  static bool _hasDueDate(StudentFinancialSummary summary) =>
      summary.nextDueDate.isNotEmpty && summary.nextDueDate != '-';

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filterStatus = 'all';
    });
  }

  void _openFormDialog({Student? student}) {
    final current = student == null ? null : _currentStudent(student.id);
    showDialog(
      context: context,
      builder: (context) => Theme(
        data: AppTheme.darkTheme,
        child: StudentFormDialog(
          student: current ?? student,
          onSave: _contextService.saveStudent,
        ),
      ),
    );
  }

  Widget _statusPanel({
    required IconData icon,
    required String title,
    String? detail,
    Widget? action,
  }) {
    return SliverToBoxAdapter(
      child: CarbonCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(icon, size: 36, color: AppColors.steel),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTheme.headlineSm(),
            ),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: AppTheme.bodyMd(),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              Center(child: action),
            ],
          ],
        ),
      ),
    );
  }

  /// Lista como sliver da mesma rolagem do cabeçalho: em celulares baixos a
  /// lista tinha só uma faixa estreita abaixo dos filtros.
  Widget _listSliver(bool isCompact) {
    if (_isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.blue),
          ),
        ),
      );
    }
    final all = _studentsData;
    final rows = _filter(all);
    if (all.isEmpty && _contextService.isRefreshing) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.blue),
          ),
        ),
      );
    }
    if (all.isEmpty && _contextService.remoteError != null) {
      return _statusPanel(
        icon: Icons.cloud_off_rounded,
        title: 'Não foi possível carregar seus alunos',
        detail: 'Verifique a conexão e tente novamente.',
        action: FilledButton.icon(
          onPressed: _refresh,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Tentar novamente'),
        ),
      );
    }
    if (all.isEmpty) {
      return _statusPanel(
        icon: Icons.person_add_alt_1_outlined,
        title: 'Nenhum aluno cadastrado ainda',
        detail:
            'Cadastre o primeiro aluno com o e-mail dele para liberar o '
            'portal e montar a ficha.',
        action: FilledButton.icon(
          onPressed: () => _openFormDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Cadastrar aluno'),
        ),
      );
    }
    if (rows.isEmpty) {
      return _statusPanel(
        icon: Icons.search_off_rounded,
        title: 'Nenhum aluno encontrado',
        detail: 'Nenhum aluno corresponde à busca ou ao filtro escolhido.',
        action: _hasFilters
            ? OutlinedButton(
                onPressed: _clearFilters,
                child: const Text('Limpar busca e filtro'),
              )
            : null,
      );
    }
    return DecoratedSliver(
      decoration: BoxDecoration(
        color: AppColors.carbon2,
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        border: Border.all(color: AppColors.dividerColor),
      ),
      sliver: SliverList.separated(
        itemCount: rows.length + (isCompact ? 0 : 1),
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (!isCompact && index == 0) return _buildTableHeader();
          final item = rows[index - (isCompact ? 0 : 1)];
          return isCompact ? _buildMobileCard(item) : _buildTableRow(item);
        },
      ),
    );
  }

  Widget? _syncNotice() {
    final message = _contextService.remoteError != null
        ? _contextService.remoteError!
        : _summaryError
        ? 'Resumo financeiro indisponível no momento. Puxe para atualizar.'
        : null;
    if (message == null || _contextService.allStudents.isEmpty) return null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          decoration: BoxDecoration(
            color: AppColors.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_off_rounded, color: AppColors.amber),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppTheme.bodyMd(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: _refresh,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notice = _syncNotice();
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final isCompact = constraints.maxWidth < 1000 * textScale;
        return Scaffold(
          backgroundColor: AppColors.carbon,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      isCompact ? 16 : 32,
                      isCompact ? 16 : 32,
                      isCompact ? 16 : 32,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Text('Alunos', style: AppTheme.headlineLg()),
                          const SizedBox(height: 4),
                          Text(
                            'Encontre alunos e acompanhe suas fichas.',
                            style: AppTheme.bodyMd(color: AppColors.steelDim),
                          ),
                          const SizedBox(height: 24),

                          // Toolbar
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SizedBox(
                                width: constraints.maxWidth > 600
                                    ? 300
                                    : double.infinity,
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (v) =>
                                      setState(() => _searchQuery = v),
                                  style: AppTheme.inputText(),
                                  decoration: const InputDecoration(
                                    labelText: 'Buscar alunos',
                                    hintText: 'Nome, CPF ou telefone',
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: AppColors.blue,
                                    ),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.carbon2,
                                  border: Border.all(
                                    color: const Color(0x1AFFFFFF),
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppColors.radiusSm,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _filterStatus,
                                    dropdownColor: AppColors.carbon2,
                                    isDense: true,
                                    icon: const Icon(
                                      Icons.arrow_drop_down,
                                      color: AppColors.steel,
                                    ),
                                    style: AppTheme.bodyMd(color: Colors.white),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        setState(
                                          () => _filterStatus = newValue,
                                        );
                                      }
                                    },
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'all',
                                        child: Text('Todos'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'active',
                                        child: Text('Ativos'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'overdue',
                                        child: Text('Atrasados'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'archived',
                                        child: Text('Inativos'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _isLoading ? null : _openAnamnese,
                                icon: const Icon(
                                  Icons.assignment_add,
                                  size: 18,
                                  color: AppColors.vibrantBlue,
                                ),
                                label: const Text('Nova Anamnese 360°'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _openFormDialog(),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Novo Aluno'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          ?notice,
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      isCompact ? 16 : 32,
                      0,
                      isCompact ? 16 : 32,
                      isCompact ? 24 : 32,
                    ),
                    sliver: _listSliver(isCompact),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('NOME', style: AppTheme.labelCaps())),
          Expanded(flex: 2, child: Text('PLANO', style: AppTheme.labelCaps())),
          Expanded(
            flex: 2,
            child: Text('VENCIMENTO', style: AppTheme.labelCaps()),
          ),
          Expanded(flex: 2, child: Text('STATUS', style: AppTheme.labelCaps())),
          SizedBox(
            width: 104,
            child: Text(
              'AÇÕES',
              style: AppTheme.labelCaps(),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(_StudentRowData data) {
    StatusType dotStatus;
    if (data.isArchived) {
      dotStatus = StatusType.inactive;
    } else if (data.summary.badge == FinancialBadge.overdue) {
      dotStatus = StatusType.overdue;
    } else if (data.summary.badge == FinancialBadge.dueToday) {
      dotStatus = StatusType.pending;
    } else {
      dotStatus = StatusType.active;
    }

    return InkWell(
      onTap: () => _openStudentDetails(data),
      hoverColor: Colors.white.withValues(alpha: 0.02),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.student.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyLg(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.student.email.isNotEmpty
                        ? data.student.email
                        : data.student.phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyMd(color: AppColors.steel),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                data.isArchived ? '-' : data.summary.planName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyMd(color: Colors.white),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                data.isArchived || !_hasDueDate(data.summary)
                    ? '—'
                    : Formatters.formatDateBR(data.summary.nextDueDate),
                style: AppTheme.bodyMd(),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusBgColor(dotStatus),
                    borderRadius: BorderRadius.circular(AppColors.radiusXs),
                    border: Border.all(
                      color: _getStatusColor(dotStatus).withValues(alpha: 0.2),
                    ),
                  ),
                  child: StatusLabel(status: dotStatus),
                ),
              ),
            ),
            SizedBox(
              width: 104,
              child: Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        size: 18,
                        color: AppColors.steel,
                      ),
                      onPressed: () => _openFormDialog(student: data.student),
                      tooltip: 'Editar',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: AppColors.steel,
                      ),
                      tooltip: 'Abrir ficha',
                      onPressed: () => _openStudentDetails(data),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleArchive(String studentId) async {
    final student = _currentStudent(studentId);
    if (student == null) return;
    final nextStatus = student.isArchived
        ? StudentStatus.active
        : StudentStatus.archived;
    final saved = await _contextService.updateStudentStatus(
      student.id,
      nextStatus,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          !saved
              ? 'Não foi possível atualizar ${student.name}. Tente novamente.'
              : nextStatus == StudentStatus.archived
              ? '${student.name} arquivado.'
              : '${student.name} reativado.',
        ),
      ),
    );
  }

  Widget _buildMobileCard(_StudentRowData data) {
    final statusColor = data.isArchived
        ? AppColors.steel
        : data.summary.badge == FinancialBadge.overdue
        ? AppColors.crimson
        : AppColors.emerald;
    return InkWell(
      onTap: () => _openStudentDetails(data),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.blue.withValues(alpha: 0.18),
                  child: Text(
                    data.student.name.trim().isEmpty
                        ? '?'
                        : data.student.name
                              .trim()
                              .characters
                              .first
                              .toUpperCase(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.student.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodyLg(),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.student.email.isNotEmpty
                            ? data.student.email
                            : data.student.phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodyMd(color: AppColors.steel),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StudentInfoChip(
                  icon: Icons.workspace_premium_outlined,
                  label: data.isArchived ? 'Arquivado' : data.summary.planName,
                ),
                if (!data.isArchived && _hasDueDate(data.summary))
                  _StudentInfoChip(
                    icon: Icons.event_outlined,
                    label:
                        'Vence ${Formatters.formatDateBR(data.summary.nextDueDate)}',
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 4,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => _openFormDialog(student: data.student),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
                const SizedBox(width: 4),
                FilledButton.tonalIcon(
                  onPressed: () => _openStudentDetails(data),
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Abrir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openStudentDetails(_StudentRowData data) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          body: SafeArea(
            child: StudentDetailView(
              student: data.student,
              contextService: _contextService,
              onEdit: () => _openFormDialog(student: data.student),
              onToggleArchive: () => _toggleArchive(data.student.id),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(StatusType status) {
    switch (status) {
      case StatusType.active:
        return AppColors.emerald;
      case StatusType.pending:
        return AppColors.amber;
      case StatusType.overdue:
        return AppColors.crimson;
      case StatusType.inactive:
        return AppColors.steel;
    }
  }

  Color _getStatusBgColor(StatusType status) {
    switch (status) {
      case StatusType.active:
        return AppColors.paidBg;
      case StatusType.pending:
        return AppColors.pendingBg;
      case StatusType.overdue:
        return AppColors.overdueBg;
      case StatusType.inactive:
        return AppColors.carbon3;
    }
  }
}

class _StudentInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StudentInfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.carbon3,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.steel),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyMd(color: AppColors.steel),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentRowData {
  final Student student;
  final StudentFinancialSummary summary;
  final bool isArchived;

  _StudentRowData({
    required this.student,
    required this.summary,
    required this.isArchived,
  });
}
