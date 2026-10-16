import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/utils/prescription_load.dart';

void main() {
  test('percentuais explícitos de carga e legado continuam funcionando', () {
    expect(prescriptionLoadPercentage('[work]8 reps @ 75%'), 75);
    expect(prescriptionLoadPercentage('[prep]12 reps - 60%'), 60);
    expect(prescriptionLoadPercentage('8 reps @ 72,5%'), 72.5);
    expect(resolvePrescriptionLoad('100', '', '8 reps - 75%'), '≈ 75 kg');
    expect(resolvePrescriptionLoad('2,5', '', '12 reps'), '2.5 kg');
    expect(resolvePrescriptionLoad('100', '75%', '8 reps'), '75%');
  });

  test('redução de carga e intensidade não viram kg incorretos', () {
    for (final text in [
      'reduzir a carga em 10-15%',
      'Drop-Set: reduzir 30% e continuar',
      '20 min a 60-70% da FCM',
      'Caminhar com inclinação 5%',
      'Pedalar @ 70% FCM',
    ]) {
      expect(prescriptionLoadPercentage(text), isNull, reason: text);
      expect(resolvePrescriptionLoad('100', '', text), '', reason: text);
    }
  });
}
