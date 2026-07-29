import 'package:flutter/foundation.dart';

/// The permission state for cloud writes during an account transition.
enum CloudWriteMode { ready, quiesced, reconciling, cleanupPending, blocked }

/// A UID-bound lease for cloud writes.
@immutable
class CloudWriteSession {
  const CloudWriteSession({
    required this.uid,
    required this.epoch,
    required this.mode,
  });

  final String uid;
  final int epoch;
  final CloudWriteMode mode;

  CloudWriteSession copyWith({CloudWriteMode? mode}) {
    return CloudWriteSession(uid: uid, epoch: epoch, mode: mode ?? this.mode);
  }

  @override
  bool operator ==(Object other) {
    return other is CloudWriteSession &&
        other.uid == uid &&
        other.epoch == epoch &&
        other.mode == mode;
  }

  @override
  int get hashCode => Object.hash(uid, epoch, mode);
}

/// Keeps a single in-memory session current while account identity changes.
class CloudWriteSessionController {
  CloudWriteSession? _current;
  int _latestEpoch = 0;

  CloudWriteSession? get current => _current;

  CloudWriteSession acquire(String uid) {
    _requireUid(uid);
    final session = CloudWriteSession(
      uid: uid,
      epoch: ++_latestEpoch,
      mode: CloudWriteMode.ready,
    );
    _current = session;
    return session;
  }

  /// Restores a durable session after an interrupted account operation.
  CloudWriteSession resume(CloudWriteSession session) {
    _validateSession(session);
    final current = _current;
    if (current != null && current != session) {
      throw StateError('A different cloud-write session is already current.');
    }
    if (session.epoch < _latestEpoch) {
      throw StateError('Cannot resume a stale cloud-write session.');
    }
    _latestEpoch = session.epoch;
    _current = session;
    return session;
  }

  CloudWriteSession transition(CloudWriteMode mode) {
    final current = _requireCurrent();
    final next = CloudWriteSession(
      uid: current.uid,
      epoch: ++_latestEpoch,
      mode: mode,
    );
    _current = next;
    return next;
  }

  void assertCurrent(CloudWriteSession session) {
    _validateSession(session);
    final current = _requireCurrent();
    if (current.uid != session.uid) {
      throw StateError(
        'Cloud-write session UID does not match the current UID.',
      );
    }
    if (current.epoch != session.epoch) {
      throw StateError('Cloud-write session epoch is stale.');
    }
    if (current.mode != session.mode) {
      throw StateError('Cloud-write session mode is no longer current.');
    }
  }

  void clear() {
    _current = null;
  }

  CloudWriteSession _requireCurrent() {
    final current = _current;
    if (current == null) {
      throw StateError('No cloud-write session is active.');
    }
    return current;
  }

  void _validateSession(CloudWriteSession session) {
    _requireUid(session.uid);
    if (session.epoch < 1) {
      throw ArgumentError.value(
        session.epoch,
        'session.epoch',
        'must be greater than zero',
      );
    }
  }

  void _requireUid(String uid) {
    if (uid.trim().isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'must not be empty');
    }
  }
}
