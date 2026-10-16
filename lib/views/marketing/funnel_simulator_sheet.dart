import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/carbon_card.dart';

class FunnelSimulatorSheet extends StatefulWidget {
  const FunnelSimulatorSheet({super.key});

  @override
  State<FunnelSimulatorSheet> createState() => _FunnelSimulatorSheetState();
}

class _FunnelSimulatorSheetState extends State<FunnelSimulatorSheet> {
  double _dailyBudget = 25.0; // R$ 10 a R$ 150
  double _planPrice = 450.0; // R$ 150 a R$ 1200
  double _cplEstimated = 7.50; // CPL estimado em reais
  double _salesConvRate = 15.0; // Taxa de conversão Lead -> Aluno (%)

  @override
  Widget build(BuildContext context) {
    final monthlySpend = _dailyBudget * 30;
    final monthlyLeads =
        (_cplEstimated > 0 ? (monthlySpend / _cplEstimated) : 0).round();
    final monthlyStudents = ((monthlyLeads * (_salesConvRate / 100))).round();
    final monthlyGrossRevenue = monthlyStudents * _planPrice;
    final monthlyNetProfit = monthlyGrossRevenue - monthlySpend;
    final roas = monthlySpend > 0 ? (monthlyGrossRevenue / monthlySpend) : 0.0;
    final cac = monthlyStudents > 0 ? (monthlySpend / monthlyStudents) : 0.0;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.carbon,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calculate_rounded,
                  color: AppColors.gold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Simulador Visual de Lucro & ROAS',
                      style: AppTheme.headlineSm(),
                    ),
                    Text(
                      'Arraste os controles para projetar faturamento e novos alunos',
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

          // Painel com Scroll
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.65,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                // Scorecard de Lucro Projetado (Hero Card)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.emerald.withValues(alpha: 0.2),
                        AppColors.carbon2,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.emerald.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'QUANTO SOBRA LIMPO NO SEU BOLSO',
                                style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 0.8,
                                  color: AppColors.steelDim,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'R\$ ${monthlyNetProfit.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontFamily: 'BebasNeue',
                                  fontSize: 34,
                                  color: AppColors.emerald,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'MULTIPLICADOR',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.goldLight,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${roas.toStringAsFixed(1)}x',
                                  style: const TextStyle(
                                    fontFamily: 'BebasNeue',
                                    fontSize: 22,
                                    color: AppColors.gold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.carbon3),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _MetricMiniText(
                            label: 'PAGO AO INSTA',
                            value: 'R\$ ${monthlySpend.toStringAsFixed(0)}',
                          ),
                          _MetricMiniText(
                            label: 'NO WHATSAPP',
                            value: '$monthlyLeads pessoas',
                            color: AppColors.blueLight,
                          ),
                          _MetricMiniText(
                            label: 'MATRICULADOS',
                            value: '$monthlyStudents alunos',
                            color: AppColors.emerald,
                          ),
                          _MetricMiniText(
                            label: 'CUSTO P/ ALUNO',
                            value: 'R\$ ${cac.toStringAsFixed(0)}',
                            color: AppColors.steel,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.carbon3.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '💡 Se você colocar R\$ ${_dailyBudget.toStringAsFixed(0)}/dia no Instagram (R\$ ${monthlySpend.toStringAsFixed(0)} no mês), cerca de $monthlyLeads pessoas vão te chamar no WhatsApp. Fechando $monthlyStudents alunos no plano de R\$ ${_planPrice.toStringAsFixed(0)}, sobram R\$ ${monthlyNetProfit.toStringAsFixed(0)} limpos no seu bolso!',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.paper,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Slider 1: Orçamento Diário
                CarbonCard(
                  padding: const EdgeInsets.all(14),
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '1. Quanto investir por dia em anúncios',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'R\$ ${_dailyBudget.toStringAsFixed(0)} / dia',
                            style: const TextStyle(
                              fontFamily: 'BebasNeue',
                              fontSize: 18,
                              color: AppColors.blueLight,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _dailyBudget,
                        min: 10.0,
                        max: 150.0,
                        divisions: 14,
                        activeColor: AppColors.blue,
                        onChanged: (val) => setState(() => _dailyBudget = val),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'R\$ 10/dia (Mínimo)',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.steelDim,
                            ),
                          ),
                          Text(
                            'R\$ 150/dia (Escala)',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.steelDim,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Slider 2: Preço Médio do Plano do Personal
                CarbonCard(
                  padding: const EdgeInsets.all(14),
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '2. Valor da sua Consultoria / Mensalidade',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'R\$ ${_planPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontFamily: 'BebasNeue',
                              fontSize: 18,
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _planPrice,
                        min: 150.0,
                        max: 1200.0,
                        divisions: 21,
                        activeColor: AppColors.gold,
                        onChanged: (val) => setState(() => _planPrice = val),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'R\$ 150 (Mensal)',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.steelDim,
                            ),
                          ),
                          Text(
                            'R\$ 1.200 (Anual VIP)',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.steelDim,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Sliders de Calibragem Avançada
                Row(
                  children: [
                    Expanded(
                      child: CarbonCard(
                        padding: const EdgeInsets.all(12),
                        borderRadius: BorderRadius.circular(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Custo p/ Mensagem: R\$ ${_cplEstimated.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.steel,
                              ),
                            ),
                            Slider(
                              value: _cplEstimated,
                              min: 3.0,
                              max: 20.0,
                              divisions: 17,
                              activeColor: AppColors.blueLight,
                              onChanged: (val) =>
                                  setState(() => _cplEstimated = val),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CarbonCard(
                        padding: const EdgeInsets.all(12),
                        borderRadius: BorderRadius.circular(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Taxa de Fechamento: ${_salesConvRate.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.emerald,
                              ),
                            ),
                            Slider(
                              value: _salesConvRate,
                              min: 5.0,
                              max: 40.0,
                              divisions: 7,
                              activeColor: AppColors.emerald,
                              onChanged: (val) =>
                                  setState(() => _salesConvRate = val),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Botão de Aplicar Meta
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Meta simulada salva: ${_dailyBudget.toStringAsFixed(0)}/dia ➔ R\$ ${monthlyGrossRevenue.toStringAsFixed(0)} faturamento!',
                    ),
                    backgroundColor: AppColors.emerald,
                  ),
                );
              },
              icon: const Icon(Icons.check, size: 20),
              label: const Text(
                'APLICAR ESTA ESTRATÉGIA NO VALEX',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricMiniText extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricMiniText({
    required this.label,
    required this.value,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: AppColors.steelDim),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontFamily: 'BebasNeue', fontSize: 16, color: color),
        ),
      ],
    );
  }
}
