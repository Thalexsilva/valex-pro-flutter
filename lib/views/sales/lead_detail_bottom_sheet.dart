import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/sales_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import 'objection_battlecards_sheet.dart';

class LeadDetailBottomSheet extends StatefulWidget {
  final LeadItem lead;
  final Function(LeadItem) onUpdate;
  final Function(LeadStatus) onStatusChange;
  final VoidCallback onConvert;
  final Function(String) onAddNote;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const LeadDetailBottomSheet({
    super.key,
    required this.lead,
    required this.onUpdate,
    required this.onStatusChange,
    required this.onConvert,
    required this.onAddNote,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<LeadDetailBottomSheet> createState() => _LeadDetailBottomSheetState();
}

class _LeadDetailBottomSheetState extends State<LeadDetailBottomSheet> {
  final TextEditingController _noteController = TextEditingController();
  bool _isAddingNote = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _openBattlecards() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.85,
        child: ObjectionBattlecardsSheet(lead: widget.lead),
      ),
    );
  }

  void _sendWhatsAppMessage(String type) {
    String encoded;
    if (type == 'pitch') {
      encoded = Formatters.buildWhatsAppPitchMessage(
        leadName: widget.lead.name,
        planName: widget.lead.targetPlanName.isNotEmpty
            ? widget.lead.targetPlanName
            : 'Consultoria Personalizada',
        value: widget.lead.estimatedValue,
      );
    } else if (type == 'followup24') {
      encoded = Formatters.buildWhatsAppFollowUpMessage(
        leadName: widget.lead.name,
        followUpStage: 1,
      );
    } else if (type == 'followup48') {
      encoded = Formatters.buildWhatsAppFollowUpMessage(
        leadName: widget.lead.name,
        followUpStage: 2,
      );
    } else {
      return; // tipo desconhecido — não faz nada
    }

    final cleanPhone = widget.lead.phone.replaceAll(RegExp(r'\D'), '');
    final url = 'https://wa.me/55$cleanPhone?text=$encoded';
    final decodedText = Uri.decodeComponent(encoded);
    // Copia o texto legível da mensagem
    Clipboard.setData(ClipboardData(text: decodedText));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✅ Mensagem copiada para ${widget.lead.name}. Toque em WHATSAPP para abrir.',
        ),
        backgroundColor: AppColors.blue,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'WHATSAPP',
          textColor: Colors.white,
          onPressed: () {
            // Copia o link wa.me para o clipboard — o usuário pode colar no browser
            Clipboard.setData(ClipboardData(text: url));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Link WhatsApp copiado! Cole no navegador.'),
                backgroundColor: AppColors.green,
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lead = widget.lead;
    final priorityColor = Formatters.getLeadPriorityColor(lead.priority.value);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.5, 0.85, 0.95],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.carbon,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag Handle & Top Controls
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.carbon3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Scrollable Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    // ── Header: Avatar, Name, Score, Value ──────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Score Gauge Avatar
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: priorityColor.withValues(alpha: 0.15),
                            border: Border.all(color: priorityColor, width: 2),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${lead.score}',
                                  style: TextStyle(
                                    color: priorityColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    height: 1.0,
                                  ),
                                ),
                                const Text(
                                  'PTS',
                                  style: TextStyle(
                                    color: AppColors.steelDim,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      lead.name,
                                      style: AppTheme.headlineMd(
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: priorityColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: priorityColor.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      lead.priority.label,
                                      style: TextStyle(
                                        color: priorityColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (lead.objective.isNotEmpty)
                                Text(
                                  lead.objective,
                                  style: const TextStyle(
                                    color: AppColors.steel,
                                    fontSize: 13,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    Formatters.formatBRL(lead.estimatedValue),
                                    style: const TextStyle(
                                      color: AppColors.goldLight,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '• ${lead.targetPlanName.isNotEmpty ? lead.targetPlanName : "Proposta Padrão"}',
                                    style: const TextStyle(
                                      color: AppColors.steelDim,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Contact Bar ───────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.carbon2,
                        borderRadius: BorderRadius.circular(AppColors.radiusSm),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ContactAction(
                            icon: Icons.chat_rounded,
                            color: AppColors.green,
                            label: lead.phone.isNotEmpty
                                ? lead.phone
                                : 'Sem WhatsApp',
                            onTap: () => _sendWhatsAppMessage('pitch'),
                          ),
                          if (lead.instagram.isNotEmpty)
                            _ContactAction(
                              icon: Icons.alternate_email,
                              color: AppColors.goldLight,
                              label: lead.instagram,
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: lead.instagram),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Instagram copiado!'),
                                  ),
                                );
                              },
                            ),
                          _ContactAction(
                            icon: Icons.edit_outlined,
                            color: AppColors.steel,
                            label: 'Editar',
                            onTap: widget.onEdit,
                          ),
                          _ContactAction(
                            icon: Icons.delete_outline,
                            color: AppColors.crimson,
                            label: 'Excluir',
                            onTap: widget.onDelete,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Stage Stepper ─────────────────────────────────────────
                    Text(
                      'ESTÁGIO NO FUNIL COMERCIAL',
                      style: AppTheme.labelCaps(color: AppColors.steelDim),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: LeadStatus.values.map((stage) {
                          final isCurrent = lead.status == stage;
                          final c = Formatters.getLeadStatusColor(stage.value);
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(stage.label),
                              selected: isCurrent,
                              selectedColor: c.withValues(alpha: 0.25),
                              backgroundColor: AppColors.carbon2,
                              labelStyle: TextStyle(
                                color: isCurrent ? c : AppColors.steelDim,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 12,
                              ),
                              side: BorderSide(
                                color: isCurrent
                                    ? c
                                    : Colors.white.withValues(alpha: 0.06),
                              ),
                              onSelected: (_) => widget.onStatusChange(stage),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Quick Tactical Actions ────────────────────────────────
                    Text(
                      'AÇÕES RÁPIDAS DE ALTA CONVERSÃO',
                      style: AppTheme.labelCaps(color: AppColors.steelDim),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Battlecards Trigger
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.crimson.withValues(
                                alpha: 0.2,
                              ),
                              foregroundColor: AppColors.crimson,
                              side: const BorderSide(
                                color: AppColors.crimson,
                                width: 0.8,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.shield_outlined, size: 18),
                            label: const Text(
                              'BATTLECARDS',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            onPressed: _openBattlecards,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Follow-up Menu
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.blueLight,
                              side: const BorderSide(
                                color: AppColors.blue,
                                width: 0.8,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.send_rounded, size: 18),
                            label: const Text(
                              'ENVIAR PROPOSTA',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            onPressed: () => _sendWhatsAppMessage('pitch'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Conversion Button (if not already won)
                    if (lead.status != LeadStatus.won)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppColors.radiusBtn,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.celebration_rounded, size: 20),
                        label: const Text(
                          'CONVERTER EM ALUNO VALEX (1-CLIQUE)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        onPressed: widget.onConvert,
                      ),
                    const SizedBox(height: 20),

                    // ── Notes & Interaction Timeline ──────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'HISTÓRICO DE ATENDIMENTO',
                          style: AppTheme.labelCaps(color: AppColors.steelDim),
                        ),
                        TextButton.icon(
                          icon: Icon(
                            _isAddingNote
                                ? Icons.close
                                : Icons.add_comment_outlined,
                            size: 16,
                          ),
                          label: Text(_isAddingNote ? 'Cancelar' : 'Nova Nota'),
                          onPressed: () => setState(() {
                            if (_isAddingNote) _noteController.clear();
                            _isAddingNote = !_isAddingNote;
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    if (_isAddingNote) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.carbon2,
                          borderRadius: BorderRadius.circular(
                            AppColors.radiusSm,
                          ),
                          border: Border.all(
                            color: AppColors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _noteController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              decoration: const InputDecoration(
                                hintText:
                                    'Escreva a nota da conversa com o aluno...',
                                hintStyle: TextStyle(
                                  color: AppColors.steelDim,
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.blue,
                                ),
                                onPressed: () {
                                  final text = _noteController.text.trim();
                                  if (text.isNotEmpty) {
                                    widget.onAddNote(text);
                                    _noteController.clear();
                                    setState(() => _isAddingNote = false);
                                  }
                                },
                                child: const Text(
                                  'SALVAR NOTA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (lead.notes.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.carbon2.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(
                            AppColors.radiusSm,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Nenhuma anotação registrada ainda.',
                            style: TextStyle(
                              color: AppColors.steelDim,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    else
                      ...lead.notes.reversed.map((n) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.carbon2,
                            borderRadius: BorderRadius.circular(
                              AppColors.radiusSm,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.04),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    n.author,
                                    style: const TextStyle(
                                      color: AppColors.blueLight,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    Formatters.formatDateBR(n.timestamp),
                                    style: const TextStyle(
                                      color: AppColors.steelDim,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                n.content,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ContactAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ContactAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
