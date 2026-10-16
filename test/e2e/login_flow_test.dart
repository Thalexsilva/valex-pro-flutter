import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/main.dart';
import 'package:valex_app/views/main_navigation_view.dart';
import 'package:valex_app/views/students/student_portal_view.dart';

import '../support/e2e_fixtures.dart';
import '../support/fake_supabase_backend.dart';

/// Login journeys through the real app shell: splash, login and account
/// resolution against the in-memory backend.
void main() {
  late FakeSupabaseBackend backend;

  setUpAll(loadAppFonts);

  tearDown(() async {
    await resetAppSingletons();
    await backend.stop();
  });

  Future<void> signIn(WidgetTester tester, String email) async {
    setViewport(tester, const Size(390, 844));
    await tester.pumpWidget(const ValexApp());
    await tester.pump(const Duration(seconds: 3));
    await settleFrames(tester, frames: 4);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), email);
    await tester.enterText(fields.at(1), 'senha-de-teste');
    await tester.ensureVisible(find.text('ENTRAR'));
    await tester.tap(find.text('ENTRAR'));
    await settleFrames(tester, frames: 8);
  }

  group('student account', () {
    setUp(() async {
      await resetAppSingletons();
      backend = FakeSupabaseBackend(
        userId: 'student-ana',
        email: 'ana@example.com',
      );
      seedTrainerWorkspace(backend);
      backend.rpcs['claim_student_account'] = (_) => anaId;
      await backend.start(signIn: false);
    });

    testWidgets('login opens on Aluno and goes straight to the portal', (
      tester,
    ) async {
      setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(const ValexApp());
      await tester.pump(const Duration(seconds: 3));
      await settleFrames(tester, frames: 4);
      expect(find.text('Acesse sua avaliação e seus treinos.'), findsOneWidget);
      final selector = tester.widget<SegmentedButton<bool>>(
        find.byType(SegmentedButton<bool>),
      );
      expect(selector.selected, {true});

      await tester.pumpWidget(const SizedBox.shrink());
      await signIn(tester, 'ana@example.com');
      expect(find.byType(StudentPortalView), findsOneWidget);
    });
  });

  group('instructor account', () {
    setUp(() async {
      await resetAppSingletons();
      backend = FakeSupabaseBackend();
      seedTrainerWorkspace(backend);
      backend.rpcs['claim_student_account'] = (_) => null;
      await backend.start(signIn: false);
    });

    testWidgets('instructor who keeps Aluno selected can open the panel', (
      tester,
    ) async {
      await signIn(tester, 'treinador@example.com');
      expect(
        find.textContaining('Se você é instrutor, entre no painel'),
        findsOneWidget,
      );
      await tester.tap(find.text('Entrar como instrutor'));
      await settleFrames(tester, frames: 8);
      expect(find.byType(MainNavigationView), findsOneWidget);
    });
  });
}
