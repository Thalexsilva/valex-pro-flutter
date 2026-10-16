import 'package:flutter/material.dart';
import '../models/anamnese_model.dart';
import '../theme/app_colors.dart';
import 'carbon_card.dart';

/// BioimpedanceDashboardCard — Painel Visual Interativo de Composição Corporal
class BioimpedanceDashboardCard extends StatelessWidget {
  final BioimpedanceData bio;
  final BioimpedanceData? previousBio;
  final VoidCallback? onViewDocument;

  const BioimpedanceDashboardCard({
    super.key,
    required this.bio,
    this.previousBio,
    this.onViewDocument,
  });

  @override
  Widget build(BuildContext context) {
    final bf = bio.bodyFatPercent;
    final muscle = bio.muscleMassKg;
    final fat = bio.fatMassKg;
    final bmr = bio.basalMetabolicRateKcal;
    final visceral = bio.visceralFatLevel;
    final water = bio.totalBodyWaterLiters;

    // Delta calculations
    final deltaBf = (bf != null && previousBio?.bodyFatPercent != null)
        ? bf - previousBio!.bodyFatPercent!
        : null;
    final deltaMuscle = (muscle != null && previousBio?.muscleMassKg != null)
        ? muscle - previousBio!.muscleMassKg!
        : null;
    final deltaFat = (fat != null && previousBio?.fatMassKg != null)
        ? fat - previousBio!.fatMassKg!
        : null;

    return CarbonCard(
      padding: const EdgeInsets.all(20),
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.monitor_weight_outlined,
                  color: AppColors.blueLight,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COMPOSIÇÃO CORPORAL & BIOIMPEDÂNCIA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    if (bio.assessmentDate != null)
                      Text(
                        'Data do Laudo: ${bio.assessmentDate!.day.toString().padLeft(2, '0')}/${bio.assessmentDate!.month.toString().padLeft(2, '0')}/${bio.assessmentDate!.year}${bio.deviceModel != null ? " • ${bio.deviceModel}" : ""}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.steel,
                        ),
                      ),
                  ],
                ),
              ),
              if (bio.hasFile && onViewDocument != null)
                OutlinedButton.icon(
                  icon: const Icon(Icons.description_outlined, size: 14),
                  label: const Text(
                    'Ver Laudo',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blueLight,
                    side: BorderSide(
                      color: AppColors.blue.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onPressed: onViewDocument,
                ),
            ],
          ),
          const SizedBox(height: 18),

          // Delta Longitudinal Banner (se houver histórico)
          if (deltaMuscle != null || deltaFat != null || deltaBf != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.emerald.withValues(alpha: 0.15),
                    AppColors.carbon3,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.emerald.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.trending_up_rounded,
                    color: AppColors.emerald,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Evolução vs. Avaliação Anterior: '
                      '${deltaMuscle != null ? "${deltaMuscle >= 0 ? "+" : ""}${deltaMuscle.toStringAsFixed(1)} kg Massa Magra • " : ""}'
                      '${deltaFat != null ? "${deltaFat <= 0 ? "" : "+"}${deltaFat.toStringAsFixed(1)} kg Gordura • " : ""}'
                      '${deltaBf != null ? "${deltaBf <= 0 ? "" : "+"}${deltaBf.toStringAsFixed(1)}% BF" : ""}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Main Visual Comparison: Massa Magra vs Massa Gorda
          if (muscle != null || fat != null || bf != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.carbon3,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _MetricTile(
                        label: 'GORDURA CORPORAL (% BF)',
                        value: bf != null ? '${bf.toStringAsFixed(1)}%' : '--',
                        valueColor: _getBfColor(bf),
                        subtitle: _getBfClassification(bf),
                      ),
                      _MetricTile(
                        label: 'MASSA MAGRA',
                        value: muscle != null
                            ? '${muscle.toStringAsFixed(1)} kg'
                            : '--',
                        valueColor: AppColors.vibrantBlue,
                        subtitle: 'Músculo e Órgãos',
                      ),
                      _MetricTile(
                        label: 'MASSA GORDA',
                        value: fat != null
                            ? '${fat.toStringAsFixed(1)} kg'
                            : '--',
                        valueColor: AppColors.crimson,
                        subtitle: 'Tecido Adiposo',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Segmented Proportion Bar
                  if (muscle != null && fat != null && (muscle + fat) > 0) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        height: 10,
                        child: Row(
                          children: [
                            Expanded(
                              flex: (muscle * 10).toInt(),
                              child: Container(color: AppColors.vibrantBlue),
                            ),
                            Expanded(
                              flex: (fat * 10).toInt(),
                              child: Container(color: AppColors.crimson),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '🟦 Massa Magra: ${((muscle / (muscle + fat)) * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.steel,
                          ),
                        ),
                        Text(
                          '🟥 Massa Gorda: ${((fat / (muscle + fat)) * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.steel,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Secondary Metrics Grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (bmr != null)
                _SecondaryMetricBadge(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: AppColors.amber,
                  label: 'Metabolismo Basal',
                  value: '${bmr.toStringAsFixed(0)} kcal/dia',
                ),
              if (visceral != null)
                _SecondaryMetricBadge(
                  icon: Icons.health_and_safety_rounded,
                  iconColor: _getVisceralColor(visceral),
                  label: 'Gordura Visceral',
                  value:
                      'Nível $visceral (${_getVisceralClassification(visceral)})',
                ),
              if (water != null)
                _SecondaryMetricBadge(
                  icon: Icons.water_drop_rounded,
                  iconColor: AppColors.blueLight,
                  label: 'Água Corporal',
                  value: '${water.toStringAsFixed(1)} Litros',
                ),
              if (bio.boneMassKg != null)
                _SecondaryMetricBadge(
                  icon: Icons.fitness_center_rounded,
                  iconColor: Colors.white70,
                  label: 'Massa Óssea',
                  value: '${bio.boneMassKg!.toStringAsFixed(1)} kg',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getBfColor(double? bf) {
    if (bf == null) return Colors.white;
    if (bf < 14) return AppColors.blueLight;
    if (bf <= 24) return AppColors.emerald;
    if (bf <= 30) return AppColors.amber;
    return AppColors.crimson;
  }

  String _getBfClassification(double? bf) {
    if (bf == null) return 'Não informado';
    if (bf < 10) return 'Excelente (Atleta)';
    if (bf <= 17) return 'Fitness / Ótimo';
    if (bf <= 24) return 'Saudável / Normal';
    if (bf <= 30) return 'Moderadamente Elevado';
    return 'Elevado / Atenção';
  }

  Color _getVisceralColor(int level) {
    if (level <= 9) return AppColors.emerald;
    if (level <= 14) return AppColors.amber;
    return AppColors.crimson;
  }

  String _getVisceralClassification(int level) {
    if (level <= 9) return 'Excelente';
    if (level <= 14) return 'Atenção';
    return 'Alto Risco';
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final String subtitle;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.steel,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AppColors.steel),
        ),
      ],
    );
  }
}

class _SecondaryMetricBadge extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _SecondaryMetricBadge({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.carbon3,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: AppColors.steel),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
