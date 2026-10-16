import 'package:flutter/material.dart';
import '../../../models/one_rm_engine.dart';
import '../../../models/workout_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

/// Calculadora Científica de Cargas & 1RM PRO.
///
/// Calcula o 1RM estimado (Epley/Brzycki/Lander), mostra as zonas de
/// intensidade e devolve a carga alvo escolhida via [onApply] — quem chamou
/// o diálogo decide como aplicar (na série específica ou na carga base do
/// exercício) e fecha o diálogo antes de notificar.
class CalcLoadDialog extends StatefulWidget {
  final Exercise exercise;
  final int? setIndex;
  final ValueChanged<int> onApply;

  const CalcLoadDialog({
    super.key,
    required this.exercise,
    required this.setIndex,
    required this.onApply,
  });

  @override
  State<CalcLoadDialog> createState() => _CalcLoadDialogState();
}

class _CalcLoadDialogState extends State<CalcLoadDialog> {
  late final TextEditingController baseKgController;
  late final TextEditingController repsController;
  late final TextEditingController customPctController;

  String selectedFormula = 'epley';
  int selectedPct = 70;

  @override
  void initState() {
    super.initState();
    final baseKgInitial =
        double.tryParse(widget.exercise.loadKg.replaceAll(',', '.')) ?? 80.0;
    baseKgController = TextEditingController(
      text: baseKgInitial > 0 ? baseKgInitial.toStringAsFixed(0) : '80',
    );
    repsController = TextEditingController(text: '8');
    customPctController = TextEditingController(text: '70');
  }

  @override
  void dispose() {
    baseKgController.dispose();
    repsController.dispose();
    customPctController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final setIndex = widget.setIndex;

    final testWeight =
        double.tryParse(baseKgController.text.replaceAll(',', '.')) ?? 0;
    final testReps = int.tryParse(repsController.text) ?? 1;
    final calculated1Rm = OneRmEngine.calculate1RM(
      testWeight,
      testReps,
      formula: selectedFormula,
    );
    final zones = OneRmEngine.getIntensityZones(calculated1Rm);

    final activePct = int.tryParse(customPctController.text) ?? selectedPct;
    final targetLoadResult = ((calculated1Rm * activePct) / 100.0).round();

    final setLabel = setIndex != null ? 'Série ${setIndex + 1}' : 'Carga Base';

    return Dialog(
      backgroundColor: AppColors.carbon2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 540,
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('📊 ', style: TextStyle(fontSize: 20)),
                      Text(
                        'Calculadora de Cargas & 1RM',
                        style: AppTheme.headlineMd(color: Colors.white),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.steel),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Alvo de Aplicação
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.carbon3,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.blue.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ALVO DE APLICAÇÃO',
                          style: AppTheme.labelCaps(color: AppColors.steelDim),
                        ),
                        Text(
                          ex.title.isNotEmpty ? ex.title : 'Exercício',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        setLabel,
                        style: AppTheme.labelCaps(color: AppColors.blueLight),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Seção 1: Estimativa de 1RM
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.carbon,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '📊 ESTIMATIVA DE 1RM',
                          style: AppTheme.labelCaps(color: AppColors.blueLight),
                        ),
                        DropdownButton<String>(
                          value: selectedFormula,
                          dropdownColor: AppColors.carbon3,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                          ),
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(
                              value: 'epley',
                              child: Text('Epley (Padrão)'),
                            ),
                            DropdownMenuItem(
                              value: 'brzycki',
                              child: Text('Brzycki'),
                            ),
                            DropdownMenuItem(
                              value: 'lander',
                              child: Text('Lander'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => selectedFormula = v);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: baseKgController,
                            keyboardType: TextInputType.number,
                            style: AppTheme.inputText(),
                            decoration: const InputDecoration(
                              labelText: 'Carga Testada (kg)',
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: repsController,
                            keyboardType: TextInputType.number,
                            style: AppTheme.inputText(),
                            decoration: const InputDecoration(
                              labelText: 'Reps Feitas',
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.blue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.blue.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '1RM ESTIMADO',
                                style: AppTheme.labelCaps(
                                  color: AppColors.steelDim,
                                ),
                              ),
                              Text(
                                '$calculated1Rm kg',
                                style: const TextStyle(
                                  fontFamily: 'BebasNeue',
                                  fontSize: 22,
                                  color: AppColors.blueLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Text(
                      'Tabela de Zonas de Intensidade (Clique para selecionar):',
                      style: TextStyle(fontSize: 10, color: AppColors.steelDim),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.carbon2,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: ListView.separated(
                        itemCount: zones.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, color: Colors.white10),
                        itemBuilder: (c, idx) {
                          final z = zones[idx];
                          final isSelected = activePct == z.pct;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                selectedPct = z.pct;
                                customPctController.text = z.pct.toString();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              color: isSelected
                                  ? AppColors.blue.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${z.pct}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.blueLight,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    '${z.targetKg} kg',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    z.reps,
                                    style: TextStyle(
                                      color: AppColors.steel,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    z.zone,
                                    style: TextStyle(
                                      color: AppColors.steelDim,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Seção 2: Porcentagem Rápida
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [30, 50, 60, 70, 80, 85, 90, 100].map((pct) {
                  final isSel = activePct == pct;
                  return ChoiceChip(
                    label: Text('$pct%'),
                    selected: isSel,
                    selectedColor: AppColors.blue,
                    backgroundColor: AppColors.carbon3,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : AppColors.steel,
                      fontSize: 11,
                    ),
                    onSelected: (_) {
                      setState(() {
                        selectedPct = pct;
                        customPctController.text = pct.toString();
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),

              // Carga Resultante Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.blue.withValues(alpha: 0.2),
                      AppColors.carbon3,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.blue.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CARGA ALVO RESULTANTE',
                          style: AppTheme.labelCaps(color: AppColors.steelDim),
                        ),
                        Text(
                          '≈ $targetLoadResult kg',
                          style: const TextStyle(
                            fontFamily: 'BebasNeue',
                            fontSize: 28,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blue.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: AppColors.blueLight),
                      ),
                      child: const Text(
                        '⚖️ Calculado',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.blueLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('✨ Aplicar Carga'),
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onApply(targetLoadResult);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
