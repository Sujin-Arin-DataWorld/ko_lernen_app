import 'dart:async';

/// Serializes media/custom-pack mutations so two writers cannot interleave.
///
/// A process-local waiter queue avoids retaining a completed [Future] from a
/// disposed widget-test fake-async zone. Such a tail can never be pumped by a
/// later test and used to leave `quickAdd` waiting forever.
class MediaMutationLock {
  static _MediaMutationLockState _state = _MediaMutationLockState();

  /// Test-only: release and discard state abandoned by a previous fake zone.
  static void resetForTesting() {
    final abandoned = _state;
    _state = _MediaMutationLockState();
    final pending = List<Completer<void>>.from(abandoned.waiters);
    abandoned.waiters.clear();
    abandoned.busy = false;
    for (final waiter in pending) {
      if (!waiter.isCompleted) {
        waiter.complete();
      }
    }
  }

  static Future<T> run<T>(Future<T> Function() operation) async {
    // Capture one generation. A test reset swaps [_state], so an abandoned
    // owner's finally block can never release a waiter from the fresh test.
    final state = _state;
    if (state.busy) {
      final gate = Completer<void>();
      state.waiters.add(gate);
      await gate.future;
    } else {
      state.busy = true;
    }
    try {
      return await operation();
    } finally {
      if (state.waiters.isNotEmpty) {
        final next = state.waiters.removeAt(0);
        if (!next.isCompleted) {
          next.complete();
        }
      } else {
        state.busy = false;
      }
    }
  }
}

class _MediaMutationLockState {
  bool busy = false;
  final List<Completer<void>> waiters = <Completer<void>>[];
}
