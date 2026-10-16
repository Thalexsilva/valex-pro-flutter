import 'package:flutter/material.dart';

import '../../models/finance_models.dart';
import '../../theme/app_colors.dart';

class FinancePlanDraft {
  const FinancePlanDraft({
    required this.name,
    required this.price,
    required this.type,
    required this.interval,
  });

  final String name;
  final double price;
  final String type;
  final String interval;
}

class FinanceSubscriptionDraft {
  const FinanceSubscriptionDraft({
    required this.studentId,
    required this.studentName,
    required this.planId,
    required this.startDate,
    required this.amount,
    required this.autoRenew,
  });

  final String studentId;
  final String studentName;
  final String planId;
  final String startDate;
  final double amount;
  final bool autoRenew;
}

class FinanceInvoiceDraft {
  const FinanceInvoiceDraft({
    required this.studentId,
    required this.studentName,
    required this.planId,
    required this.dueDate,
    required this.amount,
  });

  final String studentId;
  final String studentName;
  final String planId;
  final String dueDate;
  final double amount;
}

Future<FinancePlanDraft?> showCreatePlanDialog(BuildContext context) async {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  var type = 'subscription';
  var interval = 'Mensal';

  final result = await showDialog<FinancePlanDraft>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setModalState) => AlertDialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: AppColors.carbon2,
        title: const Text('Novo plano'),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nome do plano',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Informe o nome do plano.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Valor',
                      prefixText: 'R\$ ',
                    ),
                    validator: _validateMoney,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: const [
                      DropdownMenuItem(
                        value: 'subscription',
                        child: Text('Recorrente'),
                      ),
                      DropdownMenuItem(
                        value: 'one_time',
                        child: Text('Venda avulsa'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setModalState(() => type = value);
                    },
                  ),
                  if (type == 'subscription') ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: interval,
                      decoration: const InputDecoration(labelText: 'Ciclo'),
                      items: const [
                        DropdownMenuItem(
                          value: 'Mensal',
                          child: Text('Mensal'),
                        ),
                        DropdownMenuItem(
                          value: 'Trimestral',
                          child: Text('Trimestral'),
                        ),
                        DropdownMenuItem(
                          value: 'Semestral',
                          child: Text('Semestral'),
                        ),
                        DropdownMenuItem(value: 'Anual', child: Text('Anual')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => interval = value);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                dialogContext,
                FinancePlanDraft(
                  name: nameController.text.trim(),
                  price: _parseMoney(priceController.text)!,
                  type: type,
                  interval: interval,
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Criar plano'),
          ),
        ],
      ),
    ),
  );
  await Future<void>.delayed(kThemeAnimationDuration);
  nameController.dispose();
  priceController.dispose();
  return result;
}

Future<FinanceSubscriptionDraft?> showCreateSubscriptionDialog(
  BuildContext context, {
  required Map<String, String> students,
  required List<PlanItem> plans,
}) async {
  final recurringPlans = plans
      .where(
        (plan) =>
            plan.active &&
            plan.status == 'active' &&
            plan.type == 'subscription',
      )
      .toList();
  if (students.isEmpty || recurringPlans.isEmpty) return null;

  final formKey = GlobalKey<FormState>();
  var studentId = students.keys.first;
  var planId = recurringPlans.first.id;
  var autoRenew = true;
  final amountController = TextEditingController(
    text: recurringPlans.first.price.toStringAsFixed(2).replaceAll('.', ','),
  );
  final startController = TextEditingController(text: _today());

  final result = await showDialog<FinanceSubscriptionDraft>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setModalState) => AlertDialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: AppColors.carbon2,
        title: const Text('Nova assinatura'),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: studentId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Aluno'),
                    items: students.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setModalState(() => studentId = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: planId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Plano'),
                    items: recurringPlans
                        .map(
                          (plan) => DropdownMenuItem(
                            value: plan.id,
                            child: Text(plan.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      final selected = recurringPlans.firstWhere(
                        (plan) => plan.id == value,
                      );
                      setModalState(() {
                        planId = value;
                        amountController.text = selected.price
                            .toStringAsFixed(2)
                            .replaceAll('.', ',');
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Valor contratado',
                      prefixText: 'R\$ ',
                    ),
                    validator: _validateMoney,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: startController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Data de início',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    onTap: () async {
                      final picked = await _pickDate(
                        context,
                        startController.text,
                      );
                      if (picked != null) startController.text = picked;
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: autoRenew,
                    title: const Text('Renovação automática'),
                    onChanged: (value) =>
                        setModalState(() => autoRenew = value),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                dialogContext,
                FinanceSubscriptionDraft(
                  studentId: studentId,
                  studentName: students[studentId]!,
                  planId: planId,
                  startDate: startController.text,
                  amount: _parseMoney(amountController.text)!,
                  autoRenew: autoRenew,
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Criar assinatura'),
          ),
        ],
      ),
    ),
  );
  await Future<void>.delayed(kThemeAnimationDuration);
  amountController.dispose();
  startController.dispose();
  return result;
}

Future<FinanceInvoiceDraft?> showCreateInvoiceDialog(
  BuildContext context, {
  required Map<String, String> students,
  required List<PlanItem> plans,
}) async {
  final activePlans = plans
      .where((plan) => plan.active && plan.status == 'active')
      .toList();
  if (students.isEmpty || activePlans.isEmpty) return null;

  final formKey = GlobalKey<FormState>();
  var studentId = students.keys.first;
  var planId = activePlans.first.id;
  final amountController = TextEditingController(
    text: activePlans.first.price.toStringAsFixed(2).replaceAll('.', ','),
  );
  final dueController = TextEditingController(
    text: DateTime.now()
        .add(const Duration(days: 7))
        .toIso8601String()
        .split('T')
        .first,
  );

  final result = await showDialog<FinanceInvoiceDraft>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setModalState) => AlertDialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: AppColors.carbon2,
        title: const Text('Nova fatura'),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: studentId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Aluno'),
                    items: students.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setModalState(() => studentId = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: planId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Plano'),
                    items: activePlans
                        .map(
                          (plan) => DropdownMenuItem(
                            value: plan.id,
                            child: Text(plan.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      final selected = activePlans.firstWhere(
                        (plan) => plan.id == value,
                      );
                      setModalState(() {
                        planId = value;
                        amountController.text = selected.price
                            .toStringAsFixed(2)
                            .replaceAll('.', ',');
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Valor da fatura',
                      prefixText: 'R\$ ',
                    ),
                    validator: _validateMoney,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: dueController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Vencimento',
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    onTap: () async {
                      final picked = await _pickDate(
                        context,
                        dueController.text,
                      );
                      if (picked != null) dueController.text = picked;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                dialogContext,
                FinanceInvoiceDraft(
                  studentId: studentId,
                  studentName: students[studentId]!,
                  planId: planId,
                  dueDate: dueController.text,
                  amount: _parseMoney(amountController.text)!,
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Emitir fatura'),
          ),
        ],
      ),
    ),
  );
  await Future<void>.delayed(kThemeAnimationDuration);
  amountController.dispose();
  dueController.dispose();
  return result;
}

String? _validateMoney(String? value) {
  final parsed = _parseMoney(value ?? '');
  return parsed == null || parsed < 0 ? 'Informe um valor válido.' : null;
}

double? _parseMoney(String value) {
  var normalized = value.replaceAll('R\$', '').replaceAll(' ', '').trim();
  if (normalized.contains(',')) {
    normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
  }
  return double.tryParse(normalized);
}

String _today() => DateTime.now().toIso8601String().split('T').first;

Future<String?> _pickDate(BuildContext context, String current) async {
  final initial = DateTime.tryParse(current) ?? DateTime.now();
  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
  );
  return picked?.toIso8601String().split('T').first;
}
