/// Process-local generation for app-owned data stored on this device.
///
/// A restore captures a [LocalDataLifetimeLease] before it starts remote I/O.
/// Explicit local/account resets invalidate every outstanding lease before
/// deleting data, so a late remote response cannot repopulate the new, empty
/// data lifetime.
abstract final class LocalDataLifetime {
  static int _epoch = 0;

  static LocalDataLifetimeLease capture() => LocalDataLifetimeLease._(_epoch);

  /// Starts a new local-data lifetime synchronously.
  ///
  /// Reset callers must invoke this after reset admission succeeds and before
  /// the first destructive mutation.
  static void invalidate() {
    _epoch += 1;
  }

  static bool _isCurrent(int epoch) => epoch == _epoch;
}

final class LocalDataLifetimeLease {
  const LocalDataLifetimeLease._(this._epoch);

  final int _epoch;

  bool get isCurrent => LocalDataLifetime._isCurrent(_epoch);

  void assertCurrent() {
    if (!isCurrent) {
      throw const StaleLocalDataLifetimeException();
    }
  }
}

/// Benign cancellation signal for work admitted before an explicit reset.
final class StaleLocalDataLifetimeException implements Exception {
  const StaleLocalDataLifetimeException();

  @override
  String toString() => 'Local data lifetime is stale.';
}
