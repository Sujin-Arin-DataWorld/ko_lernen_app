import 'dart:async';

import 'package:flutter/foundation.dart';

/// The permission state for cloud writes during an account transition.
enum CloudWriteMode { ready, quiesced, reconciling, cleanupPending, blocked }

/// Benign outcome for work guarded by a cloud-write session.
enum CloudWriteResult { completed, stale, blocked }

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
  bool _hasBeenActivated = false;
  final ValueNotifier<CloudWriteSession?> _changes =
      ValueNotifier<CloudWriteSession?>(null);

  CloudWriteSession? get current => _current;
  bool get hasBeenActivated => _hasBeenActivated;
  ValueListenable<CloudWriteSession?> get changes => _changes;

  CloudWriteSession acquire(String uid) {
    _requireUid(uid);
    final session = CloudWriteSession(
      uid: uid,
      epoch: ++_latestEpoch,
      mode: CloudWriteMode.ready,
    );
    _hasBeenActivated = true;
    _setCurrent(session);
    return session;
  }

  /// Restores a durable session after an interrupted account operation.
  CloudWriteSession resume(
    CloudWriteSession session, {
    required String expectedUid,
  }) {
    _validateSession(session);
    _requireUid(expectedUid);
    if (session.uid != expectedUid) {
      throw StateError(
        'Cloud-write session UID does not match the authenticated account.',
      );
    }
    final current = _current;
    if (current != null && current != session) {
      throw StateError('A different cloud-write session is already current.');
    }
    if (session.epoch < _latestEpoch) {
      throw StateError('Cannot resume a stale cloud-write session.');
    }
    _latestEpoch = session.epoch;
    _hasBeenActivated = true;
    _setCurrent(session);
    return session;
  }

  CloudWriteSession transition(CloudWriteMode mode) {
    final current = _requireCurrent();
    final next = CloudWriteSession(
      uid: current.uid,
      epoch: ++_latestEpoch,
      mode: mode,
    );
    _setCurrent(next);
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
    _setCurrent(null);
  }

  void _setCurrent(CloudWriteSession? session) {
    _current = session;
    _changes.value = session;
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

/// Process-wide production session. Tests inject their own controller instead
/// of mutating this instance.
final CloudWriteSessionController cloudWriteSessionController =
    CloudWriteSessionController();

/// Aligns ordinary auth changes with a ready cloud-write session without
/// reopening an account transition that deliberately quiesced the source.
class CloudWriteSessionSynchronizer {
  const CloudWriteSessionSynchronizer(this.sessions);

  final CloudWriteSessionController sessions;

  CloudWriteResult synchronizeReady(String? uid) {
    final normalizedUid = uid?.trim();
    if (normalizedUid == null || normalizedUid.isEmpty) {
      return CloudWriteResult.blocked;
    }
    final current = sessions.current;
    if (current == null) {
      sessions.acquire(normalizedUid);
      return CloudWriteResult.completed;
    }
    if (current.mode != CloudWriteMode.ready) {
      return CloudWriteResult.blocked;
    }
    if (current.uid != normalizedUid) {
      sessions.acquire(normalizedUid);
    }
    return CloudWriteResult.completed;
  }
}

/// Re-validates a UID-bound session immediately before an irreversible action.
///
/// Preparatory reads may run between [readySnapshot] and [verify]. The action
/// itself is invoked only while the same UID, epoch, and ready mode remain
/// current. A late completion is reported as [CloudWriteResult.stale].
class CloudWriteFence {
  const CloudWriteFence(this.sessions);

  final CloudWriteSessionController sessions;

  CloudWriteSession? readySnapshot(String uid) {
    final current = sessions.current;
    if (current == null ||
        current.uid != uid ||
        current.mode != CloudWriteMode.ready) {
      return null;
    }
    return current;
  }

  CloudWriteResult verify(CloudWriteSession snapshot, {required String uid}) {
    if (snapshot.uid != uid || snapshot.mode != CloudWriteMode.ready) {
      return CloudWriteResult.stale;
    }
    try {
      sessions.assertCurrent(snapshot);
      return CloudWriteResult.completed;
    } on StateError {
      return CloudWriteResult.stale;
    }
  }

  Future<CloudWriteResult> run({
    required String uid,
    Future<void> Function()? prepare,
    required Future<void> Function() action,
  }) async {
    final snapshot = readySnapshot(uid);
    if (snapshot == null) {
      return CloudWriteResult.blocked;
    }
    return runWithSnapshot(
      snapshot: snapshot,
      uid: uid,
      prepare: prepare,
      action: action,
    );
  }

  Future<CloudWriteResult> runWithSnapshot({
    required CloudWriteSession snapshot,
    required String uid,
    Future<void> Function()? prepare,
    required Future<void> Function() action,
  }) async {
    final beforePreparation = verify(snapshot, uid: uid);
    if (beforePreparation != CloudWriteResult.completed) {
      return beforePreparation;
    }
    await prepare?.call();
    final beforeAction = verify(snapshot, uid: uid);
    if (beforeAction != CloudWriteResult.completed) {
      return beforeAction;
    }
    try {
      await action();
    } catch (error, stackTrace) {
      final afterFailure = verify(snapshot, uid: uid);
      if (afterFailure != CloudWriteResult.completed) {
        return afterFailure;
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
    return verify(snapshot, uid: uid);
  }

  Stream<T> bindStream<T>({required String uid, required Stream<T> source}) {
    final snapshot = readySnapshot(uid);
    if (snapshot == null) {
      return Stream<T>.empty();
    }

    late StreamController<T> controller;
    StreamSubscription<T>? sourceSubscription;
    late VoidCallback onSessionChanged;
    var closed = false;

    Future<void> close() async {
      if (closed) {
        return;
      }
      closed = true;
      sessions.changes.removeListener(onSessionChanged);
      await sourceSubscription?.cancel();
      await controller.close();
    }

    onSessionChanged = () {
      if (verify(snapshot, uid: uid) != CloudWriteResult.completed) {
        unawaited(close());
      }
    };

    controller = StreamController<T>(
      onListen: () {
        sessions.changes.addListener(onSessionChanged);
        sourceSubscription = source.listen(
          (value) {
            if (verify(snapshot, uid: uid) == CloudWriteResult.completed) {
              controller.add(value);
            } else {
              unawaited(close());
            }
          },
          onError: controller.addError,
          onDone: close,
        );
      },
      onCancel: close,
    );
    return controller.stream;
  }
}
