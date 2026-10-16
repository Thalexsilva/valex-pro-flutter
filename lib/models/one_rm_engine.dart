/// Engine Científico de Cálculo de 1RM (Repetição Máxima) e Zonas de Intensidade
class IntensityZone {
  final int pct;
  final String reps;
  final String zone;
  final int targetKg;

  const IntensityZone({
    required this.pct,
    required this.reps,
    required this.zone,
    required this.targetKg,
  });
}

class OneRmEngine {
  /// Calcula a 1RM estimada baseada na carga executada e repetições
  /// Fórmulas: 'epley', 'brzycki' ou 'lander'
  static int calculate1RM(double weight, int reps, {String formula = 'epley'}) {
    if (weight <= 0) return 0;
    if (reps <= 1) return weight.round();

    double rm = weight;

    switch (formula.toLowerCase()) {
      case 'brzycki':
        // Fórmula de Brzycki: 1RM = w / (1.0278 - 0.0278 * r)
        final denom = 1.0278 - (0.0278 * reps);
        rm = denom > 0 ? weight / denom : weight;
        break;
      case 'lander':
        // Fórmula de Lander: 1RM = (100 * w) / (101.3 - 2.67123 * r)
        final denom = 101.3 - (2.67123 * reps);
        rm = denom > 0 ? (100 * weight) / denom : weight;
        break;
      case 'epley':
      default:
        // Fórmula de Epley: 1RM = w * (1 + r / 30)
        rm = weight * (1 + (reps / 30.0));
        break;
    }

    return rm.round();
  }

  /// Gera a tabela de 10 zonas de intensidade baseadas no 1RM
  static List<IntensityZone> getIntensityZones(int oneRepMax) {
    const rawZones = [
      (100, '1 rep', 'Força Máxima'),
      (95, '2 reps', 'Força Pura'),
      (90, '3-4 reps', 'Força & Hipertrofia'),
      (85, '5-6 reps', 'Hipertrofia Densa'),
      (80, '7-8 reps', 'Hipertrofia Ideal'),
      (75, '9-10 reps', 'Hipertrofia Metabólica'),
      (70, '11-12 reps', 'Resistência de Força'),
      (65, '13-15 reps', 'Resistência Muscular'),
      (60, '15+ reps', 'Aquecimento / Validação'),
      (50, '20+ reps', 'Preparação Articular'),
    ];

    return rawZones.map((z) {
      final targetKg = ((oneRepMax * z.$1) / 100.0).round();
      return IntensityZone(
        pct: z.$1,
        reps: z.$2,
        zone: z.$3,
        targetKg: targetKg,
      );
    }).toList();
  }
}
