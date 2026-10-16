import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Articulação com dor e nível de severidade
class JointPainItem {
  final String joint;
  final String severity; // 'Leve', 'Moderada', 'Severa'

  const JointPainItem({required this.joint, this.severity = 'Moderada'});

  Map<String, dynamic> toJson() => {'joint': joint, 'severity': severity};

  factory JointPainItem.fromJson(Map<String, dynamic> json) => JointPainItem(
    joint: json['joint'] as String? ?? '',
    severity: json['severity'] as String? ?? 'Moderada',
  );
}

/// InteractiveBodyPainSelector — Seletor Anatômico Visual de Dores Articulares & Biomecânica
class InteractiveBodyPainSelector extends StatefulWidget {
  final List<String> selectedJoints;
  final Function(List<String> updatedJoints) onChanged;

  const InteractiveBodyPainSelector({
    super.key,
    required this.selectedJoints,
    required this.onChanged,
  });

  @override
  State<InteractiveBodyPainSelector> createState() =>
      _InteractiveBodyPainSelectorState();
}

class _InteractiveBodyPainSelectorState
    extends State<InteractiveBodyPainSelector> {
  static const List<Map<String, dynamic>> _bodyJoints = [
    {
      'id': 'Ombro Direito',
      'label': 'Ombro D',
      'icon': Icons.accessibility_new_rounded,
      'region': 'Membros Superiores',
    },
    {
      'id': 'Ombro Esquerdo',
      'label': 'Ombro E',
      'icon': Icons.accessibility_new_rounded,
      'region': 'Membros Superiores',
    },
    {
      'id': 'Cotovelo Direito',
      'label': 'Cotovelo D',
      'icon': Icons.fitness_center_rounded,
      'region': 'Membros Superiores',
    },
    {
      'id': 'Cotovelo Esquerdo',
      'label': 'Cotovelo E',
      'icon': Icons.fitness_center_rounded,
      'region': 'Membros Superiores',
    },
    {
      'id': 'Punho / Mãos',
      'label': 'Punhos/Mãos',
      'icon': Icons.pan_tool_outlined,
      'region': 'Membros Superiores',
    },
    {
      'id': 'Coluna Cervical',
      'label': 'Cervical',
      'icon': Icons.person_outline,
      'region': 'Coluna & Tronco',
    },
    {
      'id': 'Coluna Torácica',
      'label': 'Torácica',
      'icon': Icons.shield_outlined,
      'region': 'Coluna & Tronco',
    },
    {
      'id': 'Coluna Lombar',
      'label': 'Lombar',
      'icon': Icons.airline_seat_recline_normal_rounded,
      'region': 'Coluna & Tronco',
    },
    {
      'id': 'Quadril / Pelve',
      'label': 'Quadril/Pelve',
      'icon': Icons.directions_walk_rounded,
      'region': 'Membros Inferiores',
    },
    {
      'id': 'Joelho Direito',
      'label': 'Joelho D',
      'icon': Icons.transfer_within_a_station_rounded,
      'region': 'Membros Inferiores',
    },
    {
      'id': 'Joelho Esquerdo',
      'label': 'Joelho E',
      'icon': Icons.transfer_within_a_station_rounded,
      'region': 'Membros Inferiores',
    },
    {
      'id': 'Tornozelo / Pés',
      'label': 'Tornozelos/Pés',
      'icon': Icons.do_not_step_rounded,
      'region': 'Membros Inferiores',
    },
  ];

  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selectedJoints);
  }

  @override
  void didUpdateWidget(covariant InteractiveBodyPainSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedJoints != widget.selectedJoints) {
      _selected = Set.from(widget.selectedJoints);
    }
  }

  void _toggleJoint(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
    widget.onChanged(_selected.toList());
  }

  @override
  Widget build(BuildContext context) {
    final regions = [
      'Membros Superiores',
      'Coluna & Tronco',
      'Membros Inferiores',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'MAPA ANATÔMICO DE DORES ARTICULARES',
                style: AppTheme.labelCaps(color: AppColors.steel),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (_selected.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.amber.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '⚠️ ${_selected.length} alertas biomecânicos',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.amber,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Clique sobre as regiões onde sente dor ou desconforto durante os movimentos para calibrar a prescrição segura de exercícios.',
          style: AppTheme.bodyMd(color: AppColors.steel),
        ),
        const SizedBox(height: 16),
        ...regions.map((region) {
          final jointsInRegion = _bodyJoints
              .where((j) => j['region'] == region)
              .toList();
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.carbon3,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  region.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blueLight,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: jointsInRegion.map((j) {
                    final id = j['id'] as String;
                    final label = j['label'] as String;
                    final icon = j['icon'] as IconData;
                    final isSelected = _selected.contains(id);

                    return InkWell(
                      onTap: () => _toggleJoint(id),
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.crimson.withValues(alpha: 0.2)
                              : AppColors.carbon2,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.crimson
                                : Colors.white12,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? Icons.warning_amber_rounded : icon,
                              size: 16,
                              color: isSelected
                                  ? AppColors.crimson
                                  : AppColors.steel,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
