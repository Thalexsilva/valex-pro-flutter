import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/utils/formatters.dart';

void main() {
  test('BRL groups thousands without duplicating digits', () {
    expect(Formatters.formatBRL(1450), 'R\$ 1.450,00');
    expect(Formatters.formatBRL(1234567.89), 'R\$ 1.234.567,89');
    expect(Formatters.formatBRL(-1450.5), 'R\$ -1.450,50');
    expect(Formatters.formatBRL(0), 'R\$ 0,00');
  });
}
