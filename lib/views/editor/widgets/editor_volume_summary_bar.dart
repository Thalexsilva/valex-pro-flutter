import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

/// Resumo de volume por grupo muscular & carga total (.volume-summary-bar).
/// Recebe o mapa produzido por `WorkoutSheet.volumeSummary` e é puramente
/// apresentacional — não depende de estado do editor.
class EditorVolumeSummaryBar extends StatelessWidget {
  final Map<String, dynamic> volume;

  const EditorVolumeSummaryBar({super.key, required this.volume});

  @override
  Widget build(BuildContext context) {
    final totalEx = volume['totalEx'] ?? 0;
    final totalSets = volume['totalSets'] ?? 0;
    final totalTonnage = (volume['totalTonnageKg'] as num?)?.toDouble() ?? 0.0;
    final Map<String, int> muscleSets =
        (volume['muscleSets'] as Map?)?.cast<String, int>() ?? {};
    final Map<String, double> muscleTonnage =
        (volume['muscleTonnage'] as Map?)?.cast<String, double>() ?? {};

    final sortedMuscles = muscleSets.keys.toList()
      ..sort((a, b) => (muscleSets[b] ?? 0).compareTo(muscleSets[a] ?? 0));

    final totalKgFormatted = totalTonnage > 0
        ? '${totalTonnage.toStringAsFixed(0)} kg'
        : '0 kg';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.carbon2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  const Text('📊 ', style: TextStyle(fontSize: 16)),
                  Text(
                    'Resumo de Volume por Grupo Muscular & Carga Total:',
                    style: AppTheme.labelCaps(color: AppColors.blueLight),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.blue.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Exercícios: $totalEx | Séries Totais: $totalSets | Tonnage: $totalKgFormatted',
                  style: AppTheme.bodyMd(color: Colors.white),
                ),
              ),
            ],
          ),
          if (sortedMuscles.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: sortedMuscles.map((m) {
                final sets = muscleSets[m] ?? 0;
                final kg = muscleTonnage[m] ?? 0.0;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.carbon3,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                      children: [
                        TextSpan(
                          text: '$m: ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        TextSpan(
                          text: '$sets séries',
                          style: const TextStyle(color: AppColors.steel),
                        ),
                        if (kg > 0)
                          TextSpan(
                            text: ' · ${kg.toStringAsFixed(0)} kg',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.green,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
