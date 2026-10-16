import 'package:flutter/material.dart';
import '../../models/marketing_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/carbon_card.dart';

class CampaignFormDialog extends StatefulWidget {
  final MarketingCampaign? campaign;

  const CampaignFormDialog({super.key, this.campaign});

  @override
  State<CampaignFormDialog> createState() => _CampaignFormDialogState();
}

class _CampaignFormDialogState extends State<CampaignFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _budgetController;
  late final TextEditingController _spentController;
  late final TextEditingController _leadsController;
  late final TextEditingController _studentsController;
  late final TextEditingController _revenueController;
  late final TextEditingController _audienceController;
  late final TextEditingController _utmController;

  late MarketingPlatform _selectedPlatform;
  late CampaignObjective _selectedObjective;
  late FunnelStage _selectedFunnelStage;
  late CampaignStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    final c = widget.campaign;

    _nameController = TextEditingController(text: c?.name ?? '');
    _budgetController = TextEditingController(
      text: c != null ? c.dailyBudget.toStringAsFixed(2) : '20.00',
    );
    _spentController = TextEditingController(
      text: c != null ? c.totalSpent.toStringAsFixed(2) : '0.00',
    );
    _leadsController = TextEditingController(
      text: c != null ? c.leadsGenerated.toString() : '0',
    );
    _studentsController = TextEditingController(
      text: c != null ? c.wonStudents.toString() : '0',
    );
    _revenueController = TextEditingController(
      text: c != null ? c.revenueGenerated.toStringAsFixed(2) : '0.00',
    );
    _audienceController = TextEditingController(
      text: c?.targetAudience ?? 'Homens e Mulheres 25-45 | Fitness & Saúde',
    );
    _utmController = TextEditingController(
      text: c?.utmCampaign ?? 'campanha_nova_2026',
    );

    _selectedPlatform = c?.platform ?? MarketingPlatform.meta;
    _selectedObjective = c?.objective ?? CampaignObjective.leads;
    _selectedFunnelStage = c?.funnelStage ?? FunnelStage.tofu;
    _selectedStatus = c?.status ?? CampaignStatus.active;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    _spentController.dispose();
    _leadsController.dispose();
    _studentsController.dispose();
    _revenueController.dispose();
    _audienceController.dispose();
    _utmController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final dailyBudget =
        double.tryParse(_budgetController.text.replaceAll(',', '.')) ?? 20.0;
    final totalSpent =
        double.tryParse(_spentController.text.replaceAll(',', '.')) ?? 0.0;
    final leads = int.tryParse(_leadsController.text.trim()) ?? 0;
    final students = int.tryParse(_studentsController.text.trim()) ?? 0;
    final revenue =
        double.tryParse(_revenueController.text.replaceAll(',', '.')) ?? 0.0;
    final audience = _audienceController.text.trim();
    final utm = _utmController.text.trim().replaceAll(' ', '_').toLowerCase();

    final result = MarketingCampaign(
      id:
          widget.campaign?.id ??
          'camp_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      platform: _selectedPlatform,
      objective: _selectedObjective,
      funnelStage: _selectedFunnelStage,
      status: _selectedStatus,
      dailyBudget: dailyBudget,
      totalSpent: totalSpent,
      leadsGenerated: leads,
      wonStudents: students,
      revenueGenerated: revenue,
      targetAudience: audience,
      utmCampaign: utm,
      createdAt: widget.campaign?.createdAt ?? DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.campaign != null;

    return Dialog(
      backgroundColor: AppColors.carbon,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: AppColors.blueLight,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit
                              ? 'Editar Campanha de Mídia'
                              : 'Nova Campanha de Mídia',
                          style: AppTheme.headlineSm(),
                        ),
                        Text(
                          'Configure orçamento, públicos e tags UTM de rastreamento',
                          style: AppTheme.bodySm(color: AppColors.steelDim),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.steel),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.carbon3),
              const SizedBox(height: 12),

              // Formulário com Scroll
              Expanded(
                child: ListView(
                  children: [
                    // Nome da Campanha
                    TextFormField(
                      controller: _nameController,
                      style: AppTheme.inputText(),
                      decoration: const InputDecoration(
                        labelText: 'Nome da Campanha *',
                        hintText: 'Ex: Hipertrofia Express (TOFU - Reels)',
                        prefixIcon: Icon(
                          Icons.label_outline,
                          color: AppColors.steel,
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Informe o nome da campanha'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Plataforma & Etapa do Funil
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<MarketingPlatform>(
                            initialValue: _selectedPlatform,
                            dropdownColor: AppColors.carbon2,
                            style: AppTheme.inputText(),
                            decoration: const InputDecoration(
                              labelText: 'Plataforma',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                            items: MarketingPlatform.values.map((p) {
                              return DropdownMenuItem(
                                value: p,
                                child: Text(
                                  p.label,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedPlatform = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<FunnelStage>(
                            initialValue: _selectedFunnelStage,
                            dropdownColor: AppColors.carbon2,
                            style: AppTheme.inputText(),
                            decoration: const InputDecoration(
                              labelText: 'Etapa do Funil',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                            items: FunnelStage.values.map((s) {
                              return DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s.label,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedFunnelStage = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Objetivo & Status
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<CampaignObjective>(
                            initialValue: _selectedObjective,
                            dropdownColor: AppColors.carbon2,
                            style: AppTheme.inputText(),
                            decoration: const InputDecoration(
                              labelText: 'Objetivo',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                            items: CampaignObjective.values.map((o) {
                              return DropdownMenuItem(
                                value: o,
                                child: Text(
                                  o.label,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedObjective = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<CampaignStatus>(
                            initialValue: _selectedStatus,
                            dropdownColor: AppColors.carbon2,
                            style: AppTheme.inputText(),
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                            items: CampaignStatus.values.map((s) {
                              return DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s.label,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedStatus = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Orçamento Diário & Total Gasto
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _budgetController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: AppTheme.inputText(),
                            decoration: const InputDecoration(
                              labelText: 'Orçamento Diário (R\$)',
                              prefixIcon: Icon(
                                Icons.attach_money,
                                color: AppColors.emerald,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _spentController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: AppTheme.inputText(),
                            decoration: const InputDecoration(
                              labelText: 'Total Investido (R\$)',
                              prefixIcon: Icon(
                                Icons.payments_outlined,
                                color: AppColors.steel,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Leads & Alunos Ganhos
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _leadsController,
                            keyboardType: TextInputType.number,
                            style: AppTheme.inputText(),
                            decoration: const InputDecoration(
                              labelText: 'Leads Gerados',
                              prefixIcon: Icon(
                                Icons.people_outline,
                                color: AppColors.blueLight,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _studentsController,
                            keyboardType: TextInputType.number,
                            style: AppTheme.inputText(),
                            decoration: const InputDecoration(
                              labelText: 'Alunos Convertidos',
                              prefixIcon: Icon(
                                Icons.check_circle_outline,
                                color: AppColors.emerald,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Faturamento Gerado
                    TextFormField(
                      controller: _revenueController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: AppTheme.inputText(),
                      decoration: const InputDecoration(
                        labelText: 'Faturamento Atribuído (R\$)',
                        prefixIcon: Icon(
                          Icons.trending_up,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Tag UTM Campaign
                    TextFormField(
                      controller: _utmController,
                      style: AppTheme.inputText(),
                      decoration: const InputDecoration(
                        labelText: 'Tag utm_campaign (sem espaços) *',
                        hintText: 'ex: estagnacao_inverno_2026',
                        prefixIcon: Icon(Icons.link, color: AppColors.steel),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Informe a tag UTM'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Público Alvo / Direcionamento
                    TextFormField(
                      controller: _audienceController,
                      maxLines: 2,
                      style: AppTheme.inputText(),
                      decoration: const InputDecoration(
                        labelText: 'Público Alvo / Segmentação',
                        hintText:
                            'Ex: Homens 25-40, Dores Articulares, Foco em Hipertrofia',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card de Projeção / Indicadores em Tempo Real
                    CarbonCard(
                      padding: const EdgeInsets.all(14),
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PROJEÇÃO / INDICADORES CALCULADOS',
                            style: AppTheme.labelCaps(
                              color: AppColors.blueLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _MetricMini(
                                label: 'CPL Estimado',
                                value: _calculateLiveCPL(),
                                color: AppColors.blueLight,
                              ),
                              _MetricMini(
                                label: 'CAC Estimado',
                                value: _calculateLiveCAC(),
                                color: AppColors.emerald,
                              ),
                              _MetricMini(
                                label: 'ROAS Real',
                                value: _calculateLiveROAS(),
                                color: AppColors.gold,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Divider(color: AppColors.carbon3),
              const SizedBox(height: 12),

              // Ações
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save, size: 18),
                    label: Text(
                      isEdit ? 'Salvar Alterações' : 'Criar Campanha',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _calculateLiveCPL() {
    final spent =
        double.tryParse(_spentController.text.replaceAll(',', '.')) ?? 0.0;
    final leads = int.tryParse(_leadsController.text.trim()) ?? 0;
    if (leads <= 0) return 'R\$ 0,00';
    return 'R\$ ${(spent / leads).toStringAsFixed(2)}';
  }

  String _calculateLiveCAC() {
    final spent =
        double.tryParse(_spentController.text.replaceAll(',', '.')) ?? 0.0;
    final won = int.tryParse(_studentsController.text.trim()) ?? 0;
    if (won <= 0) return 'R\$ 0,00';
    return 'R\$ ${(spent / won).toStringAsFixed(2)}';
  }

  String _calculateLiveROAS() {
    final spent =
        double.tryParse(_spentController.text.replaceAll(',', '.')) ?? 0.0;
    final rev =
        double.tryParse(_revenueController.text.replaceAll(',', '.')) ?? 0.0;
    if (spent <= 0) return '0.0x';
    return '${(rev / spent).toStringAsFixed(1)}x';
  }
}

class _MetricMini extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricMini({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.steelDim),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontFamily: 'BebasNeue', fontSize: 18, color: color),
        ),
      ],
    );
  }
}
