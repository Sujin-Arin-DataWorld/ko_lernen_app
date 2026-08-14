import 'dart:async';

/// Serializes media/custom-pack mutations so two writers cannot interleave.
///
/// The waiter list is process-local and must not retain a [Future] from a
/// previous widget-test fake-async zone — that leftover tail never completes
/// in the next test and `quickAdd` appears to no-op.
class MediaMutationLock {
  static bool _busy = false;
  static final List<Completer<void>> _waiters = <Completer<void>>[];

  /// Test-only. Drops an abandoned in-flight chain left by a previous test.
  /// Called from `Storage.resetForTesting` — do not use in production.
  static void resetForTesting() {
    _busy = false;
    final pending = List<Completer<void>>.from(_waiters);
    _waiters.clear();
    for (final waiter in pending) {
      if (!waiter.isCompleted) {
        waiter.complete();
      }
    }
  }

  static Future<T> run<T>(Future<T> Function() operation) async {
    if (_busy) {
      final gate = Completer<void>();
      _waiters.add(gate);
      await gate.future;
    } else {
      _busy = true;
    }
    try {
      return await operation();
    } finally {
      if (_waiters.isNotEmpty) {
        _waiters.removeAt(0).complete();
      } else {
        _busy = false;
      }
    }
  }
}
