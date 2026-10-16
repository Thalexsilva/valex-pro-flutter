import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/finance_models.dart';
import '../../repositories/finance_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../services/file_export_service.dart';
import 'finance_creation_dialogs.dart';

enum _FinanceCreateAction { plan, subscription, invoice }

class FinanceView extends StatefulWidget {
  final FinanceRepository? repository;

  const FinanceView({super.key, this.repository});

  @override
  State<FinanceView> createState() => _FinanceViewState();
}

class _FinanceViewState extends State<FinanceView>
    with SingleTickerProviderStateMixin {
  late final FinanceRepository _financeRepo;
  late final TabController _tabController;
  String _invoiceFilterStatus =
      'all'; // 'all' | 'pending' | 'overdue' | 'paid' | 'cancelled'
  bool _isLoading = true;
  String? _loadError;
  bool _exporting = false;
  bool _isMutating = false;

  Future<void> _exportReport(bool csv) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      await FileExportService.downloadText(
        csv ? 'valex-faturas.csv' : 'valex-financeiro.json',
        csv ? _financeRepo.exportInvoicesCsv() : _financeRepo.exportJson(),
        csv ? 'text/csv' : 'application/json',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao exportar. Tente novamente.')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _financeRepo = widget.repository ?? FinanceRepository();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      await _financeRepo.loadState();
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = 'Não foi possível carregar os dados financeiros.';
        });
      }
      return;
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createFinancialRecord(_FinanceCreateAction action) async {
    if (_isMutating) return;
    try {
      switch (action) {
        case _FinanceCreateAction.plan:
          final draft = await showCreatePlanDialog(context);
          if (draft == null || !mounted) return;
          await _runMutation(
            successMessage: 'Plano criado com sucesso.',
            operation: () => _financeRepo.createPlan(
              name: draft.name,
              price: draft.price,
              type: draft.type,
              interval: draft.interval,
            ),
          );
          return;
        case _FinanceCreateAction.subscription:
          final students = await _financeRepo.loadStudents();
          if (!mounted) return;
          final recurringPlans = _financeRepo.state.plans
              .where(
                (plan) =>
                    plan.active &&
                    plan.status == 'active' &&
                    plan.type == 'subscription',
              )
              .toList();
          if (students.isEmpty || recurringPlans.isEmpty) {
            _showMessage(
              students.isEmpty
                  ? 'Cadastre um aluno ativo antes de criar uma assinatura.'
                  : 'Crie um plano recorrente antes de criar uma assinatura.',
            );
            return;
          }
          final draft = await showCreateSubscriptionDialog(
            context,
            students: students,
            plans: recurringPlans,
          );
          if (draft == null || !mounted) return;
          await _runMutation(
            successMessage: 'Assinatura criada com sucesso.',
            operation: () => _financeRepo.createSubscription(
              studentId: draft.studentId,
              studentName: draft.studentName,
              planId: draft.planId,
              startDate: draft.startDate,
              amount: draft.amount,
              autoRenew: draft.autoRenew,
            ),
          );
          return;
        case _FinanceCreateAction.invoice:
          final students = await _financeRepo.loadStudents();
          if (!mounted) return;
          final plans = _financeRepo.state.plans
              .where((plan) => plan.active && plan.status == 'active')
              .toList();
          if (students.isEmpty || plans.isEmpty) {
            _showMessage(
              students.isEmpty
                  ? 'Cadastre um aluno ativo antes de emitir uma fatura.'
                  : 'Crie um plano antes de emitir uma fatura.',
            );
            return;
          }
          final draft = await showCreateInvoiceDialog(
            context,
            students: students,
            plans: plans,
          );
          if (draft == null || !mounted) return;
          await _runMutation(
            successMessage: 'Fatura emitida com sucesso.',
            operation: () => _financeRepo.createInvoice(
              studentId: draft.studentId,
              studentName: draft.studentName,
              planId: draft.planId,
              dueDate: draft.dueDate,
              amount: draft.amount,
            ),
          );
          return;
      }
    } on FinanceDataException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) {
        _showMessage(
          error.toString().replaceFirst('Invalid argument(s): ', ''),
        );
      }
    }
  }

  Future<void> _runMutation({
    required String successMessage,
    required Future<bool> Function() operation,
  }) async {
    setState(() => _isMutating = true);
    try {
      final saved = await operation();
      if (!mounted) return;
      setState(() {});
      _showMessage(
        saved
            ? successMessage
            : 'A operação não foi concluída. Tente novamente.',
      );
    } on FinanceDataException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) {
        _showMessage(
          error.toString().replaceFirst('Invalid argument(s): ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _cancelSubscription(SubscriptionItem subscription) async {
    if (_isMutating || subscription.status == 'cancelled') return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar assinatura?'),
        content: Text(
          'A assinatura de ${subscription.studentName} no ${subscription.planName} será cancelada. Faturas já emitidas permanecem no histórico.',
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
    await _runMutation(
      successMessage: 'Assinatura de ${subscription.studentName} cancelada.',
      operation: () => _financeRepo.cancelSubscription(subscription.id),
    );
  }

  Future<void> _changeSubscriptionPlan(SubscriptionItem subscription) async {
    if (_isMutating || subscription.status != 'active') return;
    final plans = _financeRepo.state.plans
        .where(
          (plan) =>
              plan.id != subscription.planId &&
              plan.active &&
              plan.status == 'active' &&
              plan.type == 'subscription',
        )
        .toList();
    if (plans.isEmpty) {
      _showMessage('Nenhum outro plano recorrente ativo disponível.');
      return;
    }
    final plan = await showDialog<PlanItem>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Alterar plano de ${subscription.studentName}'),
        children: [
          for (final plan in plans)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, plan),
              child: Text('${plan.name} • ${Formatters.formatBRL(plan.price)}'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
    if (plan == null || !mounted) return;
    await _runMutation(
      successMessage: 'Plano de ${subscription.studentName} alterado.',
      operation: () =>
          _financeRepo.changeSubscriptionPlan(subscription.id, plan.id),
    );
  }

  bool get _hasFinancialData {
    final state = _financeRepo.state;
    return state.plans.isNotEmpty ||
        state.subscriptions.isNotEmpty ||
        state.invoices.isNotEmpty ||
        state.payments.isNotEmpty ||
        state.cashFlow.isNotEmpty;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<InvoiceItem> get _filteredInvoices {
    final invoices = _financeRepo.state.invoices;
    if (_invoiceFilterStatus == 'all') return invoices;
    return invoices
        .where((inv) => inv.effectiveStatus() == _invoiceFilterStatus)
        .toList();
  }

  Future<void> _confirmPaymentDialog(InvoiceItem invoice) async {
    String selectedMethod = 'pix';
    final discountController = TextEditingController();
    final fineController = TextEditingController();
    final interestController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: AppColors.carbon2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Confirmar Baixa de Fatura',
              style: AppTheme.headlineMd(color: AppColors.blueLight),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aluno: ${invoice.studentName}',
                    style: AppTheme.bodyLg(color: Colors.white),
                  ),
                  Text(
                    'Plano: ${invoice.planName} • Valor: ${Formatters.formatBRL(invoice.originalAmount)}',
                    style: AppTheme.bodyMd(color: AppColors.steel),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedMethod,
                    dropdownColor: AppColors.carbon3,
                    decoration: const InputDecoration(
                      labelText: 'Forma de Pagamento',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'pix', child: Text('PIX')),
                      DropdownMenuItem(
                        value: 'cartao',
                        child: Text('Cartão de Crédito'),
                      ),
                      DropdownMenuItem(
                        value: 'debit',
                        child: Text('Cartão de Débito'),
                      ),
                      DropdownMenuItem(
                        value: 'dinheiro',
                        child: Text('Dinheiro'),
                      ),
                      DropdownMenuItem(
                        value: 'transfer',
                        child: Text('Transferência Bancária'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedMethod = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: discountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Desconto (R\$)',
                      hintText: '0,00',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: fineController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Multa (R\$)',
                      hintText: '0,00',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: AppColors.steel),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirmar Recebimento'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      final discount =
          double.tryParse(discountController.text.replaceAll(',', '.')) ?? 0.0;
      final fine =
          double.tryParse(fineController.text.replaceAll(',', '.')) ?? 0.0;
      final interest =
          double.tryParse(interestController.text.replaceAll(',', '.')) ?? 0.0;

      bool ok;
      try {
        ok = await _financeRepo.confirmPayment(
          invoiceId: invoice.id,
          paymentMethod: selectedMethod,
          discount: discount,
          fine: fine,
          interest: interest,
        );
      } catch (_) {
        ok = false;
      }

      if (mounted) {
        setState(() {});
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Pagamento nao confirmado. Verifique a conexao e tente novamente.',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Pagamento de ${invoice.studentName} confirmado com sucesso!',
              ),
            ),
          );
        }
      }
    }
  }

  void _copyBillingMessage(InvoiceItem invoice) {
    final text = Formatters.buildWhatsAppBillingMessage(
      studentName: invoice.studentName,
      planName: invoice.planName,
      amount: invoice.finalAmount,
      dueDate: invoice.dueDate,
    );
    final decoded = Uri.decodeComponent(text);
    Clipboard.setData(ClipboardData(text: decoded));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Mensagem de cobrança copiada para a área de transferência!',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final metrics = _financeRepo.metrics;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.carbon,
        body: Center(
          child: Semantics(
            label: 'Carregando dados financeiros',
            child: CircularProgressIndicator(color: AppColors.blueLight),
          ),
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: AppColors.carbon,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.crimson,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyLg(color: Colors.white),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.carbon,
      appBar: AppBar(
        backgroundColor: AppColors.carbon2,
        title: Text('Financeiro', style: AppTheme.headlineMd()),
        actions: [
          IconButton(
            tooltip: 'Sincronizar financeiro',
            onPressed: _isMutating ? null : _loadData,
            icon: const Icon(Icons.sync),
          ),
          PopupMenuButton<_FinanceCreateAction>(
            tooltip: 'Criar registro financeiro',
            enabled: !_isMutating,
            icon: const Icon(Icons.add_circle_outline),
            onSelected: _createFinancialRecord,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _FinanceCreateAction.plan,
                child: ListTile(
                  leading: Icon(Icons.sell_outlined),
                  title: Text('Novo plano'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _FinanceCreateAction.subscription,
                child: ListTile(
                  leading: Icon(Icons.autorenew),
                  title: Text('Nova assinatura'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _FinanceCreateAction.invoice,
                child: ListTile(
                  leading: Icon(Icons.receipt_long_outlined),
                  title: Text('Nova fatura'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.steelLight,
          unselectedLabelColor: AppColors.steel,
          indicatorColor: AppColors.blueLight,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Faturas'),
            Tab(text: 'Assinaturas'),
            Tab(text: 'Planos'),
            Tab(text: 'Livro Caixa'),
            Tab(text: 'Relatórios'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            if (_isMutating)
              const LinearProgressIndicator(
                minHeight: 3,
                color: AppColors.blueLight,
              ),
            if (_financeRepo.lastSyncError != null)
              MaterialBanner(
                backgroundColor: AppColors.amber.withValues(alpha: 0.12),
                leading: const Icon(
                  Icons.cloud_off_outlined,
                  color: AppColors.amber,
                ),
                content: Text(
                  _financeRepo.lastSyncError!,
                  style: AppTheme.bodyMd(color: Colors.white),
                ),
                actions: [
                  TextButton(
                    onPressed: _loadData,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            // Painel de Indicadores no Topo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.carbon2,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _MetricCard(
                      'MRR',
                      Formatters.formatBRL(metrics.mrr),
                      AppColors.blueLight,
                    ),
                    _MetricCard(
                      'ARR',
                      Formatters.formatBRL(metrics.arr),
                      AppColors.blueLight,
                    ),
                    _MetricCard(
                      'Recebido',
                      Formatters.formatBRL(metrics.receitaRecebida),
                      AppColors.emerald,
                    ),
                    _MetricCard(
                      'Previsto',
                      Formatters.formatBRL(metrics.receitaPrevista),
                      AppColors.amber,
                    ),
                    _MetricCard(
                      'Atrasado',
                      Formatters.formatBRL(metrics.receitaAtrasada),
                      AppColors.crimson,
                    ),
                    _MetricCard(
                      'Saldo Caixa',
                      Formatters.formatBRL(metrics.saldoCaixa),
                      AppColors.emerald,
                    ),
                    _MetricCard(
                      'Inadimplência',
                      '${metrics.inadimplenciaPercentual.toStringAsFixed(1)}%',
                      AppColors.amber,
                    ),
                  ],
                ),
              ),
            ),

            // Sub-Tab Views
            Expanded(
              child: !_hasFinancialData
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: AppColors.steel,
                              size: 40,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Nenhum dado financeiro cadastrado.',
                              textAlign: TextAlign.center,
                              style: AppTheme.bodyLg(color: AppColors.steel),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _isMutating
                                  ? null
                                  : () => _createFinancialRecord(
                                      _FinanceCreateAction.plan,
                                    ),
                              icon: const Icon(Icons.add),
                              label: const Text('Criar primeiro plano'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // Sub-Tab 1: Faturas
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    const Text(
                                      'Filtro: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.steel,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SegmentedButton<String>(
                                      segments: const [
                                        ButtonSegment(
                                          value: 'all',
                                          label: Text('Todas'),
                                        ),
                                        ButtonSegment(
                                          value: 'pending',
                                          label: Text('Pendentes'),
                                        ),
                                        ButtonSegment(
                                          value: 'overdue',
                                          label: Text('Atrasadas'),
                                        ),
                                        ButtonSegment(
                                          value: 'paid',
                                          label: Text('Pagas'),
                                        ),
                                      ],
                                      selected: {_invoiceFilterStatus},
                                      onSelectionChanged: (val) {
                                        setState(
                                          () =>
                                              _invoiceFilterStatus = val.first,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: _filteredInvoices.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Nenhuma fatura encontrada com este filtro.',
                                            style: AppTheme.bodyMd(
                                              color: AppColors.steel,
                                            ),
                                          ),
                                          if (_invoiceFilterStatus != 'all')
                                            TextButton(
                                              onPressed: () => setState(
                                                () => _invoiceFilterStatus =
                                                    'all',
                                              ),
                                              child: const Text(
                                                'Limpar filtro',
                                              ),
                                            ),
                                        ],
                                      ),
                                    )
                                  : isDesktop
                                  ? SingleChildScrollView(
                                      padding: const EdgeInsets.all(16),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: DataTable(
                                          columns: const [
                                            DataColumn(label: Text('ID')),
                                            DataColumn(label: Text('Aluno')),
                                            DataColumn(label: Text('Plano')),
                                            DataColumn(
                                              label: Text('Vencimento'),
                                            ),
                                            DataColumn(
                                              label: Text('Valor Final'),
                                            ),
                                            DataColumn(label: Text('Status')),
                                            DataColumn(label: Text('Ações')),
                                          ],
                                          rows: _filteredInvoices.map((inv) {
                                            final statusColor =
                                                Formatters.getFinanceStatusColor(
                                                  inv.effectiveStatus(),
                                                );
                                            return DataRow(
                                              cells: [
                                                DataCell(Text(inv.id)),
                                                DataCell(Text(inv.studentName)),
                                                DataCell(Text(inv.planName)),
                                                DataCell(
                                                  Text(
                                                    Formatters.formatDateBR(
                                                      inv.dueDate,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    Formatters.formatBRL(
                                                      inv.finalAmount,
                                                    ),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Chip(
                                                    label: Text(
                                                      Formatters.translateFinanceStatus(
                                                        inv.effectiveStatus(),
                                                      ),
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    backgroundColor:
                                                        statusColor,
                                                  ),
                                                ),
                                                DataCell(
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      if (inv.status != 'paid')
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons
                                                                .check_circle_outline,
                                                            color: AppColors
                                                                .emerald,
                                                          ),
                                                          tooltip:
                                                              'Baixar Fatura',
                                                          onPressed: () =>
                                                              _confirmPaymentDialog(
                                                                inv,
                                                              ),
                                                        ),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.copy_rounded,
                                                          color: AppColors
                                                              .blueLight,
                                                        ),
                                                        tooltip:
                                                            'Copiar Cobrança',
                                                        onPressed: () =>
                                                            _copyBillingMessage(
                                                              inv,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(12),
                                      itemCount: _filteredInvoices.length,
                                      itemBuilder: (context, index) {
                                        final inv = _filteredInvoices[index];
                                        final statusColor =
                                            Formatters.getFinanceStatusColor(
                                              inv.effectiveStatus(),
                                            );

                                        return Card(
                                          color: AppColors.carbon2,
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        inv.studentName,
                                                        style:
                                                            AppTheme.headlineMd(
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                      ),
                                                    ),
                                                    Chip(
                                                      label: Text(
                                                        Formatters.translateFinanceStatus(
                                                          inv.effectiveStatus(),
                                                        ),
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      backgroundColor:
                                                          statusColor,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Plano: ${inv.planName}',
                                                  style: AppTheme.bodyMd(
                                                    color: AppColors.steel,
                                                  ),
                                                ),
                                                Text(
                                                  'Vencimento: ${Formatters.formatDateBR(inv.dueDate)}',
                                                  style: AppTheme.bodyMd(
                                                    color: AppColors.steel,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Valor Final: ${Formatters.formatBRL(inv.finalAmount)}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: AppColors.emerald,
                                                  ),
                                                ),
                                                const Divider(
                                                  color: AppColors.carbon3,
                                                ),
                                                Wrap(
                                                  alignment: WrapAlignment.end,
                                                  spacing: 8,
                                                  runSpacing: 4,
                                                  children: [
                                                    if (inv.status != 'paid')
                                                      TextButton.icon(
                                                        icon: const Icon(
                                                          Icons
                                                              .check_circle_outline,
                                                          color:
                                                              AppColors.emerald,
                                                        ),
                                                        label: const Text(
                                                          'Baixar Fatura',
                                                          style: TextStyle(
                                                            color: AppColors
                                                                .emerald,
                                                          ),
                                                        ),
                                                        onPressed: () =>
                                                            _confirmPaymentDialog(
                                                              inv,
                                                            ),
                                                      ),
                                                    TextButton.icon(
                                                      icon: const Icon(
                                                        Icons.copy_rounded,
                                                        color:
                                                            AppColors.blueLight,
                                                      ),
                                                      label: const Text(
                                                        'Copiar Cobrança',
                                                        style: TextStyle(
                                                          color: AppColors
                                                              .blueLight,
                                                        ),
                                                      ),
                                                      onPressed: () =>
                                                          _copyBillingMessage(
                                                            inv,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),

                        // Sub-Tab 2: Assinaturas
                        _financeRepo.state.subscriptions.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Nenhuma assinatura cadastrada.',
                                      style: AppTheme.bodyMd(
                                        color: AppColors.steel,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _isMutating
                                          ? null
                                          : () => _createFinancialRecord(
                                              _FinanceCreateAction.subscription,
                                            ),
                                      child: const Text('Criar assinatura'),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount:
                                    _financeRepo.state.subscriptions.length,
                                itemBuilder: (context, index) {
                                  final sub =
                                      _financeRepo.state.subscriptions[index];
                                  return Card(
                                    color: AppColors.carbon2,
                                    child: ListTile(
                                      title: Text(
                                        sub.studentName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Plano: ${sub.planName} • Início: ${Formatters.formatDateBR(sub.startDate)}',
                                            style: const TextStyle(
                                              color: AppColors.steel,
                                            ),
                                          ),
                                          Text(
                                            '${Formatters.translateFinanceStatus(sub.status)} • ${Formatters.formatBRL(sub.contractedValue)}',
                                            style: TextStyle(
                                              color: sub.status == 'active'
                                                  ? AppColors.emerald
                                                  : AppColors.steel,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: sub.status == 'active'
                                          ? PopupMenuButton<String>(
                                              tooltip:
                                                  'Gerenciar assinatura de ${sub.studentName}',
                                              enabled: !_isMutating,
                                              onSelected: (action) =>
                                                  action == 'change'
                                                  ? _changeSubscriptionPlan(sub)
                                                  : _cancelSubscription(sub),
                                              itemBuilder: (context) => [
                                                if (_financeRepo.state.plans
                                                    .any(
                                                      (plan) =>
                                                          plan.id !=
                                                              sub.planId &&
                                                          plan.active &&
                                                          plan.status ==
                                                              'active' &&
                                                          plan.type ==
                                                              'subscription',
                                                    ))
                                                  const PopupMenuItem(
                                                    value: 'change',
                                                    child: Text(
                                                      'Alterar plano',
                                                    ),
                                                  ),
                                                const PopupMenuItem(
                                                  value: 'cancel',
                                                  child: Text(
                                                    'Cancelar assinatura',
                                                  ),
                                                ),
                                              ],
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              ),

                        // Sub-Tab 3: Planos
                        _financeRepo.state.plans.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Nenhum plano cadastrado.',
                                      style: AppTheme.bodyMd(
                                        color: AppColors.steel,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _isMutating
                                          ? null
                                          : () => _createFinancialRecord(
                                              _FinanceCreateAction.plan,
                                            ),
                                      child: const Text('Criar plano'),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _financeRepo.state.plans.length,
                                itemBuilder: (context, index) {
                                  final plan = _financeRepo.state.plans[index];
                                  return Card(
                                    color: AppColors.carbon2,
                                    child: ListTile(
                                      title: Text(
                                        plan.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${plan.category} • Ciclo: ${plan.interval}',
                                        style: const TextStyle(
                                          color: AppColors.steel,
                                        ),
                                      ),
                                      trailing: Text(
                                        Formatters.formatBRL(plan.price),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.blueLight,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                        // Sub-Tab 4: Livro Caixa (Append-Only Ledger)
                        _financeRepo.state.cashFlow.isEmpty
                            ? Center(
                                child: Text(
                                  'Nenhum lançamento no livro caixa. Os lançamentos aparecem após movimentações financeiras.',
                                  style: AppTheme.bodyMd(
                                    color: AppColors.steel,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _financeRepo.state.cashFlow.length,
                                itemBuilder: (context, index) {
                                  final cf = _financeRepo.state.cashFlow[index];
                                  final isInflow = cf.type == 'inflow';
                                  return Card(
                                    color: AppColors.carbon2,
                                    child: ListTile(
                                      leading: Icon(
                                        isInflow
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        color: isInflow
                                            ? AppColors.emerald
                                            : AppColors.crimson,
                                      ),
                                      title: Text(
                                        cf.description,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${cf.category} • ${Formatters.formatDateBR(cf.date)}',
                                        style: const TextStyle(
                                          color: AppColors.steel,
                                        ),
                                      ),
                                      trailing: Text(
                                        '${isInflow ? "+" : "-"}${Formatters.formatBRL(cf.amount)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isInflow
                                              ? AppColors.emerald
                                              : AppColors.crimson,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                        // Sub-Tab 5: Relatórios
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Relatórios & Projeções Financeiras',
                                style: AppTheme.headlineMd(
                                  color: AppColors.blueLight,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '• MRR Atual: ${Formatters.formatBRL(metrics.mrr)}',
                                style: AppTheme.bodyLg(color: Colors.white),
                              ),
                              Text(
                                '• ARR Projetado: ${Formatters.formatBRL(metrics.arr)}',
                                style: AppTheme.bodyLg(color: Colors.white),
                              ),
                              Text(
                                '• Receita Recebida: ${Formatters.formatBRL(metrics.receitaRecebida)}',
                                style: AppTheme.bodyLg(
                                  color: AppColors.emerald,
                                ),
                              ),
                              Text(
                                '• Receita em Atraso: ${Formatters.formatBRL(metrics.receitaAtrasada)}',
                                style: AppTheme.bodyLg(
                                  color: AppColors.crimson,
                                ),
                              ),
                              Text(
                                '• Taxa de Inadimplência: ${metrics.inadimplenciaPercentual.toStringAsFixed(1)}%',
                                style: AppTheme.bodyLg(color: AppColors.amber),
                              ),
                              const SizedBox(height: 24),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.download),
                                    label: const Text(
                                      'Exportar Relatório (CSV)',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.emerald,
                                    ),
                                    onPressed: _exporting
                                        ? null
                                        : () => _exportReport(true),
                                  ),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.code),
                                    label: const Text(
                                      'Exportar Relatório (JSON)',
                                    ),
                                    onPressed: _exporting
                                        ? null
                                        : () => _exportReport(false),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MetricCard(this.title, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.carbon3,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: AppColors.steel),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
