import 'dart:convert';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage_service.dart';
import 'cloud_write_session.dart';

enum CloudBackupDeletionRemoteState { completed, pending }

/// Durable journal visibility for actions that could change account identity.
///
/// Both [loading] and [pending] fail closed. Only an authoritative [clear]
/// read permits a new backup, restore, link, or sign-out action.
enum CloudBackupDeletionJournalState { loading, clear, pending }

class CloudBackupDeletionIdentityChangeBlockedException implements Exception {
  const CloudBackupDeletionIdentityChangeBlockedException();
}

class CloudBackupDeletionInvocationOwnershipLostException implements Exception {
  const CloudBackupDeletionInvocationOwnershipLostException();
}

abstract interface class CloudBackupDeletionGateway {
  Future<CloudBackupDeletionRemoteState> deleteCloudBackup(
    String requestKey, {
    required String expectedUid,
  });
}

typedef CloudBackupDeletionCallableInvoker =
    Future<Object?> Function({
      required String callableName,
      required Map<String, Object?> payload,
      required HttpsCallableOptions callableOptions,
    });

class FirebaseCloudBackupDeletionGateway implements CloudBackupDeletionGateway {
  FirebaseCloudBackupDeletionGateway(this._invoke, {required this.currentUid});

  factory FirebaseCloudBackupDeletionGateway.production({
    required String? Function() currentUid,
  }) {
    return FirebaseCloudBackupDeletionGateway(({
      required callableName,
      required payload,
      required callableOptions,
    }) async {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west3');
      final result = await functions
          .httpsCallable(callableName, options: callableOptions)
          .call<Object?>(payload);
      return result.data;
    }, currentUid: currentUid);
  }

  final CloudBackupDeletionCallableInvoker _invoke;
  final String? Function() currentUid;

  @override
  Future<CloudBackupDeletionRemoteState> deleteCloudBackup(
    String requestKey, {
    required String expectedUid,
  }) async {
    final liveUid = currentUid()?.trim();
    if (liveUid == null || liveUid.isEmpty || liveUid != expectedUid) {
      throw const CloudBackupDeletionInvocationOwnershipLostException();
    }
    Object? raw;
    try {
      raw = await _invoke(
        callableName: 'deleteCloudBackup',
        payload: {'requestKey': requestKey},
        callableOptions: HttpsCallableOptions(limitedUseAppCheckToken: true),
      );
    } on FirebaseFunctionsException {
      throw const CloudBackupDeletionRemoteException();
    } catch (_) {
      throw const CloudBackupDeletionRemoteException();
    }
    if (raw is! Map || raw.length != 1 || raw['state'] is! String) {
      throw const CloudBackupDeletionRemoteException();
    }
    return switch (raw['state']) {
      'completed' => CloudBackupDeletionRemoteState.completed,
      'pending' => CloudBackupDeletionRemoteState.pending,
      _ => throw const CloudBackupDeletionRemoteException(),
    };
  }
}

class CloudBackupDeletionRemoteException implements Exception {
  const CloudBackupDeletionRemoteException();
}

@immutable
class CloudBackupDeletionJournal {
  const CloudBackupDeletionJournal._({
    required this.version,
    required this.session,
    required this.requestKey,
  });

  static const currentVersion = 1;
  static const storageKey = Storage.cloudBackupDeletionJournalPreferenceKey;
  static final RegExp _requestKeyPattern = RegExp(r'^[A-Za-z0-9_-]{43,128}$');

  final int version;
  final CloudWriteSession session;
  final String requestKey;

  factory CloudBackupDeletionJournal.pending({
    required CloudWriteSession session,
    required String requestKey,
  }) {
    final journal = CloudBackupDeletionJournal._(
      version: currentVersion,
      session: session,
      requestKey: requestKey,
    );
    journal._validate();
    return journal;
  }

  factory CloudBackupDeletionJournal.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    final uid = json['uid'];
    final epoch = json['epoch'];
    final mode = json['mode'];
    final requestKey = json['requestKey'];
    if (version is! int ||
        uid is! String ||
        epoch is! int ||
        mode is! String ||
        requestKey is! String ||
        mode != CloudWriteMode.cleanupPending.name) {
      throw const FormatException('Invalid cloud backup deletion journal.');
    }
    final journal = CloudBackupDeletionJournal._(
      version: version,
      session: CloudWriteSession(
        uid: uid,
        epoch: epoch,
        mode: CloudWriteMode.cleanupPending,
      ),
      requestKey: requestKey,
    );
    journal._validate();
    return journal;
  }

  Map<String, Object> toJson() {
    _validate();
    return {
      'version': version,
      'uid': session.uid,
      'epoch': session.epoch,
      'mode': session.mode.name,
      'requestKey': requestKey,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is CloudBackupDeletionJournal &&
        other.version == version &&
        other.session == session &&
        other.requestKey == requestKey;
  }

  @override
  int get hashCode => Object.hash(version, session, requestKey);

  void _validate() {
    if (version != currentVersion ||
        session.uid.trim().isEmpty ||
        session.uid.length > 128 ||
        session.epoch < 1 ||
        session.mode != CloudWriteMode.cleanupPending ||
        !_requestKeyPattern.hasMatch(requestKey)) {
      throw const FormatException('Invalid cloud backup deletion journal.');
    }
  }
}

abstract interface class CloudBackupDeletionJournalStore {
  Future<CloudBackupDeletionJournal?> read();
  Future<void> write(CloudBackupDeletionJournal journal);

  /// Removes the durable journal only when it is still [expected].
  ///
  /// The coordinator invokes this while holding its shared serial gate, so a
  /// second app-owned deletion cannot write a replacement between the durable
  /// comparison and removal.
  Future<bool> clearIfCurrent(CloudBackupDeletionJournal expected);
}

class SharedPreferencesCloudBackupDeletionJournalStore
    implements CloudBackupDeletionJournalStore {
  const SharedPreferencesCloudBackupDeletionJournalStore();

  @override
  Future<bool> clearIfCurrent(CloudBackupDeletionJournal expected) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    final encoded = preferences.getString(
      CloudBackupDeletionJournal.storageKey,
    );
    if (encoded == null || encoded.isEmpty) return false;
    final decoded = jsonDecode(encoded);
    if (decoded is! Map) {
      throw const FormatException('Invalid cloud backup deletion journal.');
    }
    final current = CloudBackupDeletionJournal.fromJson(
      decoded.map((key, value) => MapEntry(key.toString(), value)),
    );
    if (current != expected) return false;
    await preferences.remove(CloudBackupDeletionJournal.storageKey);
    // Legacy SharedPreferences removes the local cache entry before the
    // platform result arrives. Reload instead of trusting that cache so a
    // native false/retained A or a replacement B remains a pending journal.
    await preferences.reload();
    final remaining = preferences.getString(
      CloudBackupDeletionJournal.storageKey,
    );
    return remaining == null || remaining.isEmpty;
  }

  @override
  Future<CloudBackupDeletionJournal?> read() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    final encoded = preferences.getString(
      CloudBackupDeletionJournal.storageKey,
    );
    if (encoded == null || encoded.isEmpty) return null;
    final decoded = jsonDecode(encoded);
    if (decoded is! Map) {
      throw const FormatException('Invalid cloud backup deletion journal.');
    }
    return CloudBackupDeletionJournal.fromJson(
      decoded.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  @override
  Future<void> write(CloudBackupDeletionJournal journal) async {
    final preferences = await SharedPreferences.getInstance();
    final wrote = await preferences.setString(
      CloudBackupDeletionJournal.storageKey,
      jsonEncode(journal.toJson()),
    );
    if (!wrote) {
      throw StateError('Cloud backup deletion journal was not persisted.');
    }
  }
}

typedef CloudBackupDeletionRequestKeyFactory = String Function();

/// Serializes backup deletion and app-owned identity changes.
///
/// The critical section intentionally spans the callable future. An app-owned
/// sign-out or link action therefore cannot switch Firebase Auth identity
/// between the coordinator's ownership check and its callable invocation.
class CloudBackupDeletionAuthGate {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() action) {
    final operation = _tail.then((_) => action());
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return operation;
  }
}

class CloudBackupDeletionCoordinator {
  CloudBackupDeletionCoordinator({
    required this.sessions,
    required this.currentUid,
    required this.journalStore,
    required this.gateway,
    CloudBackupDeletionRequestKeyFactory? createRequestKey,
    CloudBackupDeletionAuthGate? authGate,
  }) : createRequestKey = createRequestKey ?? createSecureRequestKey,
       _authGate = authGate ?? CloudBackupDeletionAuthGate();

  final CloudWriteSessionController sessions;
  final String? Function() currentUid;
  final CloudBackupDeletionJournalStore journalStore;
  final CloudBackupDeletionGateway gateway;
  final CloudBackupDeletionRequestKeyFactory createRequestKey;
  final CloudBackupDeletionAuthGate _authGate;
  final ValueNotifier<CloudBackupDeletionJournalState> journalState =
      ValueNotifier<CloudBackupDeletionJournalState>(
        CloudBackupDeletionJournalState.loading,
      );
  final ValueNotifier<bool> pending = ValueNotifier<bool>(true);

  Future<CloudWriteResult>? _inFlight;

  static String createSecureRequestKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  void _setJournalState(CloudBackupDeletionJournalState state) {
    journalState.value = state;
    pending.value = state != CloudBackupDeletionJournalState.clear;
  }

  Future<CloudBackupDeletionJournalState> refreshJournalState() {
    return _authGate.run(_refreshJournalState);
  }

  Future<bool> refreshPending() async {
    return (await refreshJournalState()) !=
        CloudBackupDeletionJournalState.clear;
  }

  Future<CloudBackupDeletionJournalState> _refreshJournalState() async {
    _setJournalState(CloudBackupDeletionJournalState.loading);
    try {
      final journal = await journalStore.read();
      final state = journal == null
          ? CloudBackupDeletionJournalState.clear
          : CloudBackupDeletionJournalState.pending;
      _setJournalState(state);
      return state;
    } catch (_) {
      _setJournalState(CloudBackupDeletionJournalState.pending);
      return CloudBackupDeletionJournalState.pending;
    }
  }

  Future<bool> _canProveJournalAbsent() async {
    try {
      final absent = await journalStore.read() == null;
      _setJournalState(
        absent
            ? CloudBackupDeletionJournalState.clear
            : CloudBackupDeletionJournalState.pending,
      );
      return absent;
    } catch (_) {
      _setJournalState(CloudBackupDeletionJournalState.pending);
      return false;
    }
  }

  bool _ownsJournal(CloudBackupDeletionJournal journal) {
    final liveUid = currentUid()?.trim();
    return liveUid != null &&
        liveUid.isNotEmpty &&
        liveUid == journal.session.uid &&
        sessions.current == journal.session;
  }

  /// Runs an app-owned Firebase identity mutation only after a fresh durable
  /// journal read proves no resumable deletion exists.
  Future<T> runIdentityMutation<T>(Future<T> Function() mutation) {
    return runWithClearJournalAdmission(
      onAdmitted: mutation,
      onBlocked: () => Future<T>.error(
        const CloudBackupDeletionIdentityChangeBlockedException(),
      ),
    );
  }

  /// Runs a service operation only after a fresh durable journal read proves
  /// that no cloud-backup deletion must be resumed.
  ///
  /// The callback remains inside the same serial lane as journal writes and
  /// compare-delete, preventing a second app-owned operation from observing
  /// or replacing the journal between admission and its side effect.
  Future<T> runWithClearJournalAdmission<T>({
    required Future<T> Function() onAdmitted,
    required Future<T> Function() onBlocked,
  }) {
    return _authGate.run(() async {
      final state = await _refreshJournalState();
      if (state != CloudBackupDeletionJournalState.clear) {
        return onBlocked();
      }
      return onAdmitted();
    });
  }

  Future<CloudWriteResult> run() {
    final existing = _inFlight;
    if (existing != null) return existing;
    final operation = _authGate.run(_run);
    _inFlight = operation;
    return operation.whenComplete(() {
      if (identical(_inFlight, operation)) {
        _inFlight = null;
      }
    });
  }

  Future<CloudWriteResult> _run() async {
    CloudBackupDeletionJournal? journal;
    _setJournalState(CloudBackupDeletionJournalState.loading);
    try {
      journal = await journalStore.read();
    } catch (_) {
      _setJournalState(CloudBackupDeletionJournalState.pending);
      return CloudWriteResult.blocked;
    }

    _setJournalState(
      journal == null
          ? CloudBackupDeletionJournalState.clear
          : CloudBackupDeletionJournalState.pending,
    );

    final liveUid = currentUid()?.trim();
    if (liveUid == null || liveUid.isEmpty) {
      _setJournalState(
        journal == null
            ? CloudBackupDeletionJournalState.clear
            : CloudBackupDeletionJournalState.pending,
      );
      return CloudWriteResult.blocked;
    }

    if (journal != null && journal.session.uid != liveUid) {
      // A changed identity does not prove the old request completed. Keep the
      // UID-bound retry key until its original account can resume it or the
      // server confirms completion.
      _setJournalState(CloudBackupDeletionJournalState.pending);
      return CloudWriteResult.blocked;
    }

    if (journal == null) {
      final current = sessions.current;
      if (current == null ||
          current.uid != liveUid ||
          current.mode != CloudWriteMode.ready) {
        _setJournalState(CloudBackupDeletionJournalState.clear);
        return current?.uid == liveUid
            ? CloudWriteResult.blocked
            : CloudWriteResult.stale;
      }
      final pendingSession = sessions.transition(CloudWriteMode.cleanupPending);
      _setJournalState(CloudBackupDeletionJournalState.pending);
      CloudBackupDeletionJournal? attemptedJournal;
      try {
        attemptedJournal = CloudBackupDeletionJournal.pending(
          session: pendingSession,
          requestKey: createRequestKey(),
        );
        await journalStore.write(attemptedJournal);
        journal = attemptedJournal;
      } catch (_) {
        // A store may throw after a native write. Only restore the exact
        // in-memory fence when a read proves no durable retry journal exists.
        if (await _canProveJournalAbsent()) {
          if (sessions.current == pendingSession) {
            sessions.transition(CloudWriteMode.ready);
          }
          _setJournalState(CloudBackupDeletionJournalState.clear);
        } else {
          _setJournalState(CloudBackupDeletionJournalState.pending);
        }
        return CloudWriteResult.blocked;
      }
    } else {
      final current = sessions.current;
      if (current == null) {
        try {
          sessions.resume(journal.session, expectedUid: liveUid);
        } on StateError {
          _setJournalState(CloudBackupDeletionJournalState.pending);
          return CloudWriteResult.blocked;
        }
      } else if (current != journal.session) {
        _setJournalState(CloudBackupDeletionJournalState.pending);
        return CloudWriteResult.blocked;
      }
    }

    // An auth/session change during journal persistence must not send the old
    // request key under a different account's callable token.
    if (!_ownsJournal(journal)) {
      _setJournalState(CloudBackupDeletionJournalState.pending);
      return CloudWriteResult.blocked;
    }

    _setJournalState(CloudBackupDeletionJournalState.pending);
    CloudBackupDeletionRemoteState remote;
    try {
      remote = await gateway.deleteCloudBackup(
        journal.requestKey,
        expectedUid: journal.session.uid,
      );
    } on CloudBackupDeletionInvocationOwnershipLostException {
      _setJournalState(CloudBackupDeletionJournalState.pending);
      return CloudWriteResult.stale;
    } catch (_) {
      _setJournalState(CloudBackupDeletionJournalState.pending);
      return CloudWriteResult.blocked;
    }
    if (remote == CloudBackupDeletionRemoteState.pending) {
      return CloudWriteResult.blocked;
    }

    return _clearCompletedJournal(journal);
  }

  Future<CloudWriteResult> _clearCompletedJournal(
    CloudBackupDeletionJournal journal,
  ) async {
    try {
      final cleared = await journalStore.clearIfCurrent(journal);
      if (!cleared) {
        _setJournalState(CloudBackupDeletionJournalState.pending);
        return sessions.current == journal.session
            ? CloudWriteResult.blocked
            : CloudWriteResult.stale;
      }
    } catch (_) {
      if (!await _canProveJournalAbsent()) {
        _setJournalState(CloudBackupDeletionJournalState.pending);
        return CloudWriteResult.blocked;
      }
    }

    _setJournalState(CloudBackupDeletionJournalState.clear);
    if (sessions.current != journal.session) {
      return CloudWriteResult.stale;
    }
    sessions.transition(CloudWriteMode.ready);
    return CloudWriteResult.completed;
  }
}
