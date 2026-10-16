import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/services/file_export_service.dart';

void main() {
  group('Testes da Exportação Real de Arquivos CSV e JSON', () {
    test(
      'Formatação CSV deve conter UTF-8 BOM e escapar vírgulas, aspas e acentos',
      () {
        final records = [
          {
            'id': 'inv_001',
            'studentName': 'Carlos, Silva',
            'planName': 'Consultoria "Premium"',
            'amount': '180,00',
            'status': 'Pago',
            'dueDate': '05/08/2026',
          },
        ];

        final csv = FileExportService.generateCsvReport(records);
        expect(
          csv.startsWith('\uFEFF'),
          isTrue,
          reason: 'Deve iniciar com UTF-8 BOM',
        );
        expect(csv, contains('"Carlos, Silva"'));
        expect(csv, contains('"Consultoria ""Premium"""'));
        expect(csv, contains('"180,00"'));
      },
    );

    test('Formatação JSON deve produzir estrutura válida e indentada', () {
      final data = [
        {'id': 'inv_001', 'amount': 180.0, 'status': 'paid'},
      ];

      final jsonStr = FileExportService.generateJsonReport(data);
      expect(jsonStr, contains('"id": "inv_001"'));
      expect(jsonStr, contains('"amount": 180.0'));
      expect(jsonStr, contains('"status": "paid"'));
    });
  });
}
