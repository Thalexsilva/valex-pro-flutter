import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valex_app/views/settings/settings_view.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'SettingsView renders all tabs and diagnostic sections properly',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(MaterialApp(home: SettingsView(onLogout: () {})));

      await tester.pumpAndSettle();

      // 1. Verifica AppBar e Tabs
      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('Sincronização'), findsNothing);
      expect(find.text('Dados e Backup'), findsOneWidget);
      expect(find.text('Diagnósticos'), findsOneWidget);
      expect(find.text('Sobre'), findsOneWidget);
      expect(find.byTooltip('Sair da conta'), findsOneWidget);

      // 2. Dados e Backup é a aba inicial
      expect(find.text('Exportar Dados (JSON)'), findsOneWidget);
      expect(find.text('Importar Backup JSON'), findsOneWidget);
      expect(find.text('Zona de Perigo (Destrutivo)'), findsOneWidget);

      // 3. Navega para Diagnósticos
      await tester.tap(find.text('Diagnósticos'));
      await tester.pumpAndSettle();

      expect(find.text('Tentar novamente'), findsOneWidget);

      // 4. Navega para Sobre
      await tester.tap(find.text('Sobre'));
      await tester.pumpAndSettle();
      expect(
        find.text('VALEX - Sistema de Gestão para Personal Trainers'),
        findsOneWidget,
      );
    },
  );
}
