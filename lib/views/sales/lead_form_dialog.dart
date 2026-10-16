import 'package:flutter/material.dart';
import '../../models/sales_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/whatsapp_link.dart';

class LeadFormDialog extends StatefulWidget {
  final LeadItem? lead;
  final Function(LeadItem lead, String? initialNote) onSave;

  const LeadFormDialog({super.key, this.lead, required this.onSave});

  @override
  State<LeadFormDialog> createState() => _LeadFormDialogState();
}

class _LeadFormDialogState extends State<LeadFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _instagramController;
  late final TextEditingController _emailController;
  late final TextEditingController _objectiveController;
  late final TextEditingController _planNameController;
  late final TextEditingController _valueController;
  late final TextEditingController _utmCampaignController;
  late final TextEditingController _initialNoteController;

  late LeadStatus _selectedStatus;
  late String _selectedOrigin;

  @override
  void initState() {
    super.initState();
    final l = widget.lead;
    _nameController = TextEditingController(text: l?.name ?? '');
    _phoneController = TextEditingController(text: l?.phone ?? '');
    _instagramController = TextEditingController(text: l?.instagram ?? '');
    _emailController = TextEditingController(text: l?.email ?? '');
    _objectiveController = TextEditingController(text: l?.objective ?? '');
    _planNameController = TextEditingController(
      text: l?.targetPlanName ?? 'Plano Trimestral',
    );
    _valueController = TextEditingController(
      text: l != null && l.estimatedValue > 0
          ? l.estimatedValue.toStringAsFixed(2)
          : '350.00',
    );
    _utmCampaignController = TextEditingController(text: l?.utmCampaign ?? '');
    _initialNoteController = TextEditingController();

    _selectedStatus = l?.status ?? LeadStatus.newLead;
    _selectedOrigin = l?.originChannel ?? 'meta_ads';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _instagramController.dispose();
    _emailController.dispose();
    _objectiveController.dispose();
    _planNameController.dispose();
    _valueController.dispose();
    _utmCampaignController.dispose();
    _initialNoteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final nowStr = DateTime.now().toIso8601String();
      final estVal =
          double.tryParse(_valueController.text.replaceAll(',', '.')) ?? 0.0;

      final updated =
          (widget.lead ??
                  LeadItem(
                    id: 'lead_${DateTime.now().millisecondsSinceEpoch}',
                    name: '',
                    createdAt: nowStr,
                    updatedAt: nowStr,
                  ))
              .copyWith(
                name: _nameController.text.trim(),
                phone: _phoneController.text.trim(),
                instagram: _instagramController.text.trim(),
                email: _emailController.text.trim(),
                objective: _objectiveController.text.trim(),
                originChannel: _selectedOrigin,
                targetPlanName: _planNameController.text.trim(),
                estimatedValue: estVal,
                status: _selectedStatus,
                utmCampaign: _utmCampaignController.text.trim().isNotEmpty
                    ? _utmCampaignController.text.trim()
                    : null,
                updatedAt: nowStr,
              );

      final note = _initialNoteController.text.trim();
      widget.onSave(updated, note.isNotEmpty ? note : null);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.lead != null;

    return Dialog(
      backgroundColor: AppColors.carbon2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isEdit ? 'EDITAR LEAD' : 'NOVO LEAD COMERCIAL',
                        style: AppTheme.headlineMd(color: AppColors.blueLight),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.steelDim),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(color: AppColors.carbon3, height: 24),

                // Nome
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nome do Prospect / Aluno *',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: AppColors.blueLight,
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nome é obrigatório'
                      : null,
                ),
                const SizedBox(height: 14),

                // Telefone WhatsApp e Instagram
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: TextFormField(
                        controller: _phoneController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'WhatsApp (DDD + Número) *',
                          helperText: 'Ex.: (11) 99999-9999',
                          prefixIcon: Icon(
                            Icons.chat_bubble_outline,
                            color: AppColors.green,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'WhatsApp é obrigatório';
                          }
                          if (WhatsAppLink.normalizePhone(v) == null) {
                            return 'Número inválido. Use DDD + número, ex.: (11) 99999-9999';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 5,
                      child: TextFormField(
                        controller: _instagramController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Instagram (@user)',
                          prefixIcon: Icon(
                            Icons.alternate_email,
                            color: AppColors.goldLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Objetivo
                TextFormField(
                  controller: _objectiveController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Objetivo / Dor Principal',
                    hintText:
                        'Ex: Hipertrofia, emagrecimento, dores no ombro...',
                    prefixIcon: Icon(
                      Icons.fitness_center_outlined,
                      color: AppColors.steel,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Canal de Origem e Plano
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedOrigin,
                        dropdownColor: AppColors.carbon2,
                        decoration: const InputDecoration(
                          labelText: 'Origem do Lead',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'meta_ads',
                            child: Text(
                              'Meta Ads (Anúncios)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'instagram_direct',
                            child: Text(
                              'Instagram Direct',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'indicacao',
                            child: Text(
                              'Indicação de Aluno 🔥',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'whatsapp',
                            child: Text(
                              'WhatsApp Direto',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'google',
                            child: Text(
                              'Google Search',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedOrigin = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _valueController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Valor Estimado (R\$)',
                          prefixIcon: Icon(
                            Icons.attach_money,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Plano de interesse e Campanha UTM
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: TextFormField(
                        controller: _planNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Plano / Oferta',
                          prefixIcon: Icon(
                            Icons.star_border_rounded,
                            color: AppColors.blueLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 5,
                      child: TextFormField(
                        controller: _utmCampaignController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Campanha (UTM)',
                          hintText: 'Ex: hipertrofia_q3',
                          prefixIcon: Icon(
                            Icons.campaign_outlined,
                            color: AppColors.steelDim,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Estágio
                DropdownButtonFormField<LeadStatus>(
                  isExpanded: true,
                  initialValue: _selectedStatus,
                  dropdownColor: AppColors.carbon2,
                  decoration: const InputDecoration(
                    labelText: 'Estágio Inicial no Funil',
                  ),
                  items: LeadStatus.values.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(
                        s.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStatus = val);
                  },
                ),
                const SizedBox(height: 16),

                // Nota Inicial (apenas se for novo lead)
                if (!isEdit) ...[
                  TextFormField(
                    controller: _initialNoteController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Anotação Inicial do Prospect (opcional)',
                      hintText: 'Ex: Pediu detalhes de preço no WhatsApp...',
                      prefixIcon: Icon(
                        Icons.note_alt_outlined,
                        color: AppColors.steelDim,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                const SizedBox(height: 8),

                // Ações
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'CANCELAR',
                        style: TextStyle(color: AppColors.steelDim),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppColors.radiusBtn,
                          ),
                        ),
                      ),
                      onPressed: _submit,
                      child: Text(
                        isEdit ? 'SALVAR' : 'CADASTRAR LEAD',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
