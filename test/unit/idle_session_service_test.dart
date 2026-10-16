import 'package:flutter_test/flutter_test.dart';
import 'package:valex_app/services/idle_session_service.dart';

void main() {
  testWidgets('expires after ten minutes without activity', (tester) async {
    var now = DateTime(2026);
    var expired = 0;
    final session = IdleSessionService(
      now: () => now,
      onExpired: () => expired++,
    );
    addTearDown(session.stop);
    session.start();
    now = now.add(const Duration(minutes: 9));
    await tester.pump(const Duration(minutes: 9));
    expect(expired, 0);
    now = now.add(const Duration(minutes: 1));
    await tester.pump(const Duration(minutes: 1));
    expect(expired, 1);
  });

  testWidgets('interaction renews the deadline', (tester) async {
    var now = DateTime(2026);
    var expired = 0;
    final session = IdleSessionService(
      now: () => now,
      onExpired: () => expired++,
    );
    addTearDown(session.stop);
    session.start();
    now = now.add(const Duration(minutes: 9));
    await tester.pump(const Duration(minutes: 9));
    session.recordActivity();
    now = now.add(const Duration(minutes: 9));
    await tester.pump(const Duration(minutes: 9));
    expect(expired, 0);
    now = now.add(const Duration(minutes: 1));
    await tester.pump(const Duration(minutes: 1));
    expect(expired, 1);
  });

  testWidgets('returning after background suspension cannot renew expiry', (
    tester,
  ) async {
    var now = DateTime(2026);
    var expired = 0;
    final session = IdleSessionService(
      now: () => now,
      onExpired: () => expired++,
    );
    addTearDown(session.stop);
    session.start();
    // Wall time passes while the browser has suspended timers.
    now = now.add(const Duration(minutes: 11));
    session.recordActivity();
    session.checkExpired();
    expect(expired, 1);
    await tester.pump(const Duration(minutes: 10));
    expect(expired, 1);
  });
}
