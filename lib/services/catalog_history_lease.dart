import 'account/cloud_write_session.dart';
import 'local_data_lifetime.dart';

/// Captured before asynchronous launch preparation, including anonymous/local use.
final class CatalogHistoryLease {
  CatalogHistoryLease.capture()
    : _local = LocalDataLifetime.capture(),
      _historyGeneration = _testGeneration,
      session = cloudWriteSessionController.current;

  static int _testGeneration = 0;
  static void resetForTesting() {
    _testGeneration++;
  }

  final LocalDataLifetimeLease _local;
  final int _historyGeneration;
  final CloudWriteSession? session;

  bool get isCurrent =>
      _local.isCurrent &&
      _historyGeneration == _testGeneration &&
      session == cloudWriteSessionController.current &&
      (session == null || session!.mode == CloudWriteMode.ready);
}
