import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/sales_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class ObjectionBattlecardsSheet extends StatefulWidget {
  final LeadItem lead;

  const ObjectionBattlecardsSheet({super.key, required this.lead});

  @override
  State<ObjectionBattlecardsSheet> createState() =>
      _ObjectionBattlecardsSheetState();
}

class _ObjectionBattlecardsSheetState extends State<ObjectionBattlecardsSheet> {
  final List<BattlecardItem> _battlecards = BattlecardItem.defaultBattlecards;
  String? _expandedCardId;
  final Map<String, int> _selectedTabPerCard = {}; // 0 = WhatsApp, 1 = Audio

  void _copyToWhatsApp(String rawScript) {
    final customized = rawScript.replaceAll(
      '[Nome]',
      widget.lead.name.split(' ').first,
    );
    Clipboard.setData(ClipboardData(text: customized));

    final cleanPhone = widget.lead.phone.replaceAll(RegExp(r'\D'), '');
    final url =
        'https://wa.me/55$cleanPhone?text=${Uri.encodeComponent(customized)}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Roteiro copiado para ${widget.lead.name}!\nLink: $url'),
        backgroundColor: AppColors.green,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'ABRIR WHATSAPP',
          textColor: Colors.white,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: url));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.carbon1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.carbon3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.crimson,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BATTLECARDS DE OBJEÇÕES',
                      style: AppTheme.headlineMd(color: Colors.white),
                    ),
                    Text(
                      'Roteiros táticos de conversão para ${widget.lead.name}',
                      style: AppTheme.bodyMd(color: AppColors.steelDim),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Battlecards List
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _battlecards.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final card = _battlecards[index];
                final isExpanded = _expandedCardId == card.id;
                final activeTab = _selectedTabPerCard[card.id] ?? 0;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isExpanded
                        ? AppColors.carbon2
                        : AppColors.carbon2.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppColors.radiusCard),
                    border: Border.all(
                      color: isExpanded
                          ? AppColors.blueLight.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        onTap: () {
                          setState(() {
                            _expandedCardId = isExpanded ? null : card.id;
                          });
                        },
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.blue.withValues(
                            alpha: 0.2,
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: AppColors.blueLight,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          card.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          card.category,
                          style: const TextStyle(
                            color: AppColors.steelDim,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.steel,
                        ),
                      ),
                      if (isExpanded) ...[
                        const Divider(color: AppColors.carbon3, height: 1),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Root cause & Benefit chip
                              Row(
                                children: [
                                  const Icon(
                                    Icons.psychology_outlined,
                                    color: AppColors.goldLight,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Por que acontece: ${card.rootCause}',
                                      style: const TextStyle(
                                        color: AppColors.steel,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Tab Switcher: WhatsApp vs Audio
                              Row(
                                children: [
                                  _TabButton(
                                    label: 'WhatsApp (Texto)',
                                    icon: Icons.chat_bubble_outline,
                                    isSelected: activeTab == 0,
                                    onTap: () => setState(
                                      () => _selectedTabPerCard[card.id] = 0,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _TabButton(
                                    label: 'Roteiro de Áudio (20s)',
                                    icon: Icons.mic_none_rounded,
                                    isSelected: activeTab == 1,
                                    onTap: () => setState(
                                      () => _selectedTabPerCard[card.id] = 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Script Display Card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.carbon1,
                                  borderRadius: BorderRadius.circular(
                                    AppColors.radiusSm,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.05),
                                  ),
                                ),
                                child: Text(
                                  activeTab == 0
                                      ? card.whatsappScript.replaceAll(
                                          '[Nome]',
                                          widget.lead.name.split(' ').first,
                                        )
                                      : card.audioScript.replaceAll(
                                          '[Nome]',
                                          widget.lead.name.split(' ').first,
                                        ),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Action Button
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.green,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppColors.radiusBtn,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'COPIAR E USAR NO WHATSAPP',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  onPressed: () => _copyToWhatsApp(
                                    activeTab == 0
                                        ? card.whatsappScript
                                        : card.audioScript,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.blue.withValues(alpha: 0.25)
              : AppColors.carbon1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.blueLight
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.blueLight : AppColors.steelDim,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.blueLight : AppColors.steelDim,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
