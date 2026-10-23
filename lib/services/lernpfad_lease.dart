import 'account/cloud_write_session.dart';
import 'local_data_lifetime.dart';

/// Captured before async work, including reads. Account A -> B -> A and local
/// deletion invalidate the old screen even if its UID appears again later.
class LernpfadLease {
  LernpfadLease({CloudWriteSessionController? sessions})
    : sessions = sessions ?? cloudWriteSessionController,
      session = (sessions ?? cloudWriteSessionController).current,
      identityEpoch = (sessions ?? cloudWriteSessionController).identityEpoch;
  final CloudWriteSessionController sessions;
  final CloudWriteSession? session;
  final int identityEpoch;
  final LocalDataLifetimeLease lifetime = LocalDataLifetime.capture();
  String get owner => session == null ? 'guest' : 'uid:${session!.uid}';
  void assertCurrent() {
    lifetime.assertCurrent();
    if (sessions.identityEpoch != identityEpoch ||
        sessions.current != session ||
        (session == null && sessions.hasBeenActivated) ||
        (session != null && session!.mode != CloudWriteMode.ready)) {
      throw StateError('Lernpfad account changed');
    }
  }
}
