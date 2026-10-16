import 'dart:async';

/// Tracks user activity independently of token refreshes and background timers.
class IdleSessionService {
  IdleSessionService({required this.onExpired, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const timeout = Duration(minutes: 10);
  final void Function() onExpired;
  final DateTime Function() _now;
  DateTime? _deadline;
  Timer? _timer;

  void start() {
    _deadline = _now().add(timeout);
    _schedule();
  }

  void recordActivity() {
    if (_deadline == null || checkExpired()) return;
    start();
  }

  bool checkExpired() {
    final deadline = _deadline;
    if (deadline == null) return false;
    if (!_now().isBefore(deadline)) {
      stop();
      onExpired();
      return true;
    }
    _schedule();
    return false;
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(_deadline!.difference(_now()), checkExpired);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _deadline = null;
  }
}
