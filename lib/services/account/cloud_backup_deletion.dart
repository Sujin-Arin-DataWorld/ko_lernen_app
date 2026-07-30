import 'dart:convert';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cloud_write_session.dart';

enum CloudBackupDeletionRemoteState { completed, pending }

abstract interface class CloudBackupDeletionGateway {
  Future<CloudBackupDeletionRemoteState> deleteCloudBackup(String requestKey);
}

typedef CloudBackupDeletionCallableInvoker =
    Future<Object?> Function({
      required String callableName,
      required Map<String, Object?> payload,
      required HttpsCallableOptions callableOptions,
    });

class FirebaseCloudBackupDeletionGateway implements CloudBackupDeletionGateway {
  FirebaseCloudBackupDeletionGateway(this._invoke);

  factory FirebaseCloudBackupDeletionGateway.production() {
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
    });
  }

  final CloudBackupDeletionCallableInvoker _invoke;

  @override
  Future<CloudBackupDeletionRemoteState> deleteCloudBackup(
    String requestKey,
  ) async {
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
  static const storageKey = 'kl_cloud_backup_deletion_journal_v1';
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
  Future<void> clear();
}

class SharedPreferencesCloudBackupDeletionJournalStore
    implements CloudBackupDeletionJournalStore {
  const SharedPreferencesCloudBackupDeletionJournalStore();

  @override
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    final removed = await preferences.remove(
      CloudBackupDeletionJournal.storageKey,
    );
    if (!removed &&
        preferences.containsKey(CloudBackupDeletionJournal.storageKey)) {
      throw StateError('Cloud backup deletion journal was not cleared.');
    }
  }

  @override
  Future<CloudBackupDeletionJournal?> read() async {
    final preferences = await SharedPreferences.getInstance();
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

class CloudBackupDeletionCoordinator {
  CloudBackupDeletionCoordinator({
    required this.sessions,
    required this.currentUid,
    required this.journalStore,
    required this.gateway,
    CloudBackupDeletionRequestKeyFactory? createRequestKey,
  }) : createRequestKey = createRequestKey ?? createSecureRequestKey;

  final CloudWriteSessionController sessions;
  final String? Function() currentUid;
  final CloudBackupDeletionJournalStore journalStore;
  final CloudBackupDeletionGateway gateway;
  final CloudBackupDeletionRequestKeyFactory createRequestKey;
  final ValueNotifier<bool> pending = ValueNotifier<bool>(false);

  Future<CloudWriteResult>? _inFlight;

  static String createSecureRequestKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  Future<bool> refreshPending() async {
    try {
      pending.value = await journalStore.read() != null;
    } catch (_) {
      pending.value = true;
    }
    return pending.value;
  }

  Future<CloudWriteResult> run() {
    final existing = _inFlight;
    if (existing != null) return existing;
    final operation = _run();
    _inFlight = operation;
    return operation.whenComplete(() {
      if (identical(_inFlight, operation)) {
        _inFlight = null;
      }
    });
  }

  Future<CloudWriteResult> _run() async {
    CloudBackupDeletionJournal? journal;
    try {
      journal = await journalStore.read();
    } catch (_) {
      pending.value = true;
      return CloudWriteResult.blocked;
    }

    final liveUid = currentUid()?.trim();
    if (liveUid == null || liveUid.isEmpty) {
      pending.value = journal != null;
      return CloudWriteResult.blocked;
    }

    if (journal != null && journal.session.uid != liveUid) {
      try {
        await journalStore.clear();
      } catch (_) {
        pending.value = true;
        return CloudWriteResult.blocked;
      }
      pending.value = false;
      return CloudWriteResult.stale;
    }

    if (journal == null) {
      final current = sessions.current;
      if (current == null ||
          current.uid != liveUid ||
          current.mode != CloudWriteMode.ready) {
        pending.value = false;
        return current?.uid == liveUid
            ? CloudWriteResult.blocked
            : CloudWriteResult.stale;
      }
      final pendingSession = sessions.transition(CloudWriteMode.cleanupPending);
      try {
        journal = CloudBackupDeletionJournal.pending(
          session: pendingSession,
          requestKey: createRequestKey(),
        );
        await journalStore.write(journal);
      } catch (_) {
        pending.value = true;
        return CloudWriteResult.blocked;
      }
    } else {
      final current = sessions.current;
      if (current == null) {
        try {
          sessions.resume(journal.session, expectedUid: liveUid);
        } on StateError {
          pending.value = true;
          return CloudWriteResult.blocked;
        }
      } else if (current != journal.session) {
        pending.value = true;
        return CloudWriteResult.blocked;
      }
    }

    pending.value = true;
    CloudBackupDeletionRemoteState remote;
    try {
      remote = await gateway.deleteCloudBackup(journal.requestKey);
    } catch (_) {
      return CloudWriteResult.blocked;
    }
    if (remote == CloudBackupDeletionRemoteState.pending) {
      return CloudWriteResult.blocked;
    }

    try {
      await journalStore.clear();
    } catch (_) {
      return CloudWriteResult.blocked;
    }
    pending.value = false;
    if (sessions.current != journal.session) {
      return CloudWriteResult.stale;
    }
    sessions.transition(CloudWriteMode.ready);
    return CloudWriteResult.completed;
  }
}
