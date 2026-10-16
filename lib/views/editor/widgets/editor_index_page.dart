import 'package:flutter/material.dart';
import '../../../models/workout_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import 'day_badge_text.dart';

/// Página 2 (índice) da ficha virtual — equivalente a `.index-page` no
/// modelo legado (`js/pdf.js#renderIndexPage`).
class EditorIndexPage extends StatelessWidget {
  final WorkoutSheet sheet;
  final int totalPages;
  final ValueChanged<int> onTapDay;
  final VoidCallback onTapCardio;

  const EditorIndexPage({
    super.key,
    required this.sheet,
    required this.totalPages,
    required this.onTapDay,
    required this.onTapCardio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.paperCard,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: AppColors.carbon,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/logo.png', height: 24),
                    const SizedBox(width: 12),
                    Text(
                      'FICHA DE TREINO',
                      style: AppTheme.labelCaps(color: AppColors.blueLight),
                    ),
                  ],
                ),
                Text(
                  'SUMÁRIO DO PROGRAMA',
                  style: AppTheme.labelCaps(color: AppColors.steel),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Índice de Treinos',
                  style: AppTheme.displayLg(color: AppColors.ink),
                ),
                const SizedBox(height: 24),

                ...sheet.days.asMap().entries.map((e) {
                  final index = e.key;
                  final day = e.value;
                  final pageNo = 3 + index;

                  return InkWell(
                    onTap: () => onTapDay(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.blue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              getDayBadgeText(day.dow),
                              style: const TextStyle(
                                fontFamily: 'BebasNeue',
                                fontSize: 16,
                                color: AppColors.paperBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${day.dow} — ${day.muscle}',
                                  style: AppTheme.bodyLg(color: AppColors.ink),
                                ),
                                Text(
                                  '${day.exercises.length} exercícios',
                                  style: AppTheme.bodyMd(
                                    color: AppColors.paperMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Página $pageNo',
                            style: AppTheme.bodyMd(color: AppColors.paperMuted),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const Divider(height: 32, color: AppColors.line),

                InkWell(
                  onTap: onTapCardio,
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: const Text('🫀', style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Protocolo de Cardio & Observações',
                              style: AppTheme.bodyLg(color: AppColors.ink),
                            ),
                            Text(
                              'Orientações aeróbicas e cuidados gerais',
                              style: AppTheme.bodyMd(
                                color: AppColors.paperMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Página $totalPages',
                        style: AppTheme.bodyMd(color: AppColors.paperMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  'VALEX · Biomechanics & Rehabilitation',
                  style: AppTheme.labelCaps(color: AppColors.paperMuted),
                ),
                Text(
                  'Página 2 de $totalPages',
                  style: AppTheme.bodyMd(color: AppColors.paperMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
