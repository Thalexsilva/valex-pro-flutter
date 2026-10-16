import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/theme/app_theme.dart';
import 'package:valex_app/views/main_navigation_view.dart';

import '../support/e2e_fixtures.dart';
import '../support/fake_supabase_backend.dart';

/// Visits every instructor destination against the real repositories and an
/// in-memory backend, on phone and desktop widths, with populated, empty and
/// unavailable data. Any framework error (overflow, null crash, setState after
/// dispose) fails the sweep with the destination that produced it.
const _destinations = <int, String>{
  0: 'Visão Geral',
  1: 'Vendas & CRM',
  2: 'Mídia & Marketing',
  3: 'Alunos',
  4: 'Biblioteca',
  5: 'Financeiro',
  6: 'Editor Ativo',
  7: 'Configurações',
  8: 'Meu Perfil',
  9: 'Sobre',
};

enum _DataMode { populated, empty, offline }

void main() {
  late FakeSupabaseBackend backend;

  setUpAll(loadAppFonts);

  Future<void> openOnPhone(WidgetTester tester, int index) async {
    const bottom = {0: 'Início', 3: 'Alunos', 6: 'Editor', 5: 'Financeiro'};
    final label = bottom[index];
    if (label != null) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
      );
    } else {
      await tester.tap(find.byKey(const ValueKey('more_nav_destination')));
      await settleFrames(tester, frames: 3);
      await tester.tap(find.byKey(ValueKey('more_destination_$index')));
    }
    await settleFrames(tester);
  }

  Future<void> openOnDesktop(WidgetTester tester, int index) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text(_destinations[index]!),
      ),
    );
    await settleFrames(tester);
  }

  Future<void> scrollVisibleContent(WidgetTester tester) async {
    final center = tester.getCenter(find.byType(MainNavigationView));
    for (var i = 0; i < 3; i++) {
      await tester.dragFrom(center, const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 200));
    }
    for (var i = 0; i < 3; i++) {
      await tester.dragFrom(center, const Offset(0, 500));
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  for (final mode in _DataMode.values) {
    group(mode.name, () {
      setUp(() async {
        await resetAppSingletons();
        backend = FakeSupabaseBackend();
        if (mode != _DataMode.empty) seedTrainerWorkspace(backend);
        await backend.start();
        if (mode == _DataMode.offline) backend.failAll = true;
      });

      tearDown(() async {
        await resetAppSingletons();
        await backend.stop();
      });

      for (final (viewport, scale) in const [
        (Size(390, 844), 1.0),
        (Size(360, 780), 1.3),
        (Size(1280, 800), 1.0),
      ]) {
        final phone = viewport.width < 800;
        testWidgets('every instructor route renders (${mode.name}, '
            '${viewport.width.toInt()}px, text ${scale}x)', (tester) async {
          setViewport(tester, viewport);
          final failures = <String>[];

          final startErrors = await collectFlutterErrors(() async {
            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.darkTheme,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: MainNavigationView(onLogout: () {}),
              ),
            );
            await settleFrames(tester, frames: 8);
          });
          if (startErrors.isNotEmpty) {
            failures.add('start:\n${describeErrors(startErrors)}');
          }

          for (final index in _destinations.keys) {
            final errors = await collectFlutterErrors(() async {
              if (phone) {
                await openOnPhone(tester, index);
              } else {
                await openOnDesktop(tester, index);
              }
              await scrollVisibleContent(tester);
            });
            if (errors.isNotEmpty) {
              failures.add(
                '${_destinations[index]}:\n${describeErrors(errors)}',
              );
            }
          }

          await tester.pumpWidget(const SizedBox.shrink());
          await settleFrames(tester, frames: 4);
          expect(failures, isEmpty, reason: failures.join('\n\n'));
        });
      }
    });
  }
}
