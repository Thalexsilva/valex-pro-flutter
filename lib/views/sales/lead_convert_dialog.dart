import 'package:flutter/material.dart';
import '../../models/sales_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class LeadConvertDialog extends StatefulWidget {
  final LeadItem lead;
  final Function({required LeadItem lead, required String gymName}) onConvert;

  const LeadConvertDialog({
    super.key,
    required this.lead,
    required this.onConvert,
  });

  @override
  State<LeadConvertDialog> createState() => _LeadConvertDialogState();
}

class _LeadConvertDialogState extends State<LeadConvertDialog> {
  late final TextEditingController _gymController;

  @override
  void initState() {
    super.initState();
    _gymController = TextEditingController(text: 'VALEX Consultoria');
  }

  @override
  void dispose() {
    _gymController.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onConvert(lead: widget.lead, gymName: _gymController.text.trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final lead = widget.lead;

    return Dialog(
      backgroundColor: AppColors.carbon2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusCard),
        side: BorderSide(color: AppColors.green.withValues(alpha: 0.3)),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.celebration_rounded,
                    color: AppColors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONVERTER EM ALUNO',
                        style: AppTheme.headlineMd(color: AppColors.green),
                      ),
                      Text(
                        'Matrícula e ativação imediata no sistema',
                        style: AppTheme.bodyMd(color: AppColors.steelDim),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.carbon3, height: 24),

            // Card resumo do Lead
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.carbon1,
                borderRadius: BorderRadius.circular(AppColors.radiusSm),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lead.name,
                        style: AppTheme.bodyMd(
                          color: Colors.white,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        Formatters.formatBRL(lead.estimatedValue),
                        style: AppTheme.bodyMd(
                          color: AppColors.goldLight,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 14,
                        color: AppColors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lead.phone,
                        style: AppTheme.bodyMd(color: AppColors.steel),
                      ),
                      if (lead.instagram.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.alternate_email,
                          size: 14,
                          color: AppColors.goldLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          lead.instagram,
                          style: AppTheme.bodyMd(color: AppColors.steel),
                        ),
                      ],
                    ],
                  ),
                  if (lead.objective.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Objetivo: ${lead.objective}',
                      style: AppTheme.bodyMd(color: AppColors.steelDim),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _gymController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Academia / Local de Treino',
                prefixIcon: Icon(
                  Icons.location_on_outlined,
                  color: AppColors.blueLight,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Benefícios automáticos
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppColors.radiusXs),
                border: Border.all(
                  color: AppColors.blue.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚡ Ações Automáticas na Conversão:',
                    style: AppTheme.labelCaps(color: AppColors.blueLight),
                  ),
                  const SizedBox(height: 6),
                  const _ActionItem(
                    text:
                        'Registro do Aluno na aba "Alunos" com ficha pronta para edição',
                  ),
                  const _ActionItem(
                    text:
                        'Timeline de eventos do aluno inicializada com dados comerciais',
                  ),
                  const _ActionItem(
                    text: 'Status do Lead atualizado para "Convertido (Ganho)"',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Ações
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'CANCELAR',
                    style: TextStyle(color: AppColors.steelDim),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppColors.radiusBtn),
                    ),
                  ),
                  onPressed: _submit,
                  child: const Text(
                    'CONFIRMAR CONVERSÃO',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final String text;
  const _ActionItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✓ ',
            style: TextStyle(
              color: AppColors.green,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.steel, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
