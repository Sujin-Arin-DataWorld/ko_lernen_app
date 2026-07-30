import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/account/cloud_backup_deletion.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';

void main() {
  group('CloudBackupDeletionCoordinator', () {
    test('unknown remote outcome keeps the exact session pending', () async {
      final sessions = CloudWriteSessionController()..acquire('durable');
      final journal = _MemoryJournalStore();
      final gateway = _Gateway()..error = StateError('private remote detail');
      final coordinator = CloudBackupDeletionCoordinator(
        sessions: sessions,
        currentUid: () => 'durable',
        journalStore: journal,
        gateway: gateway,
        createRequestKey: () => 'A' * 43,
      );

      final outcome = await coordinator.run();

      expect(outcome, CloudWriteResult.blocked);
      expect(sessions.current!.mode, CloudWriteMode.cleanupPending);
      expect((await journal.read())!.session, sessions.current);
      expect((await journal.read())!.requestKey, 'A' * 43);
      expect(gateway.requestKeys, ['A' * 43]);
      expect(coordinator.pending.value, isTrue);
    });

    test('pending response keeps the same journal for retry', () async {
      final sessions = CloudWriteSessionController()..acquire('durable');
      final journal = _MemoryJournalStore();
      final gateway = _Gateway()
        ..responses.add(CloudBackupDeletionRemoteState.pending)
        ..responses.add(CloudBackupDeletionRemoteState.completed);
      final coordinator = CloudBackupDeletionCoordinator(
        sessions: sessions,
        currentUid: () => 'durable',
        journalStore: journal,
        gateway: gateway,
        createRequestKey: () => 'B' * 43,
      );

      expect(await coordinator.run(), CloudWriteResult.blocked);
      final pending = await journal.read();
      expect(pending, isNotNull);
      expect(await coordinator.run(), CloudWriteResult.completed);

      expect(gateway.requestKeys, ['B' * 43, 'B' * 43]);
      expect(await journal.read(), isNull);
      expect(sessions.current!.mode, CloudWriteMode.ready);
      expect(coordinator.pending.value, isFalse);
    });

    test(
      'restart resumes the exact UID-bound session and request key',
      () async {
        final firstSessions = CloudWriteSessionController()..acquire('durable');
        final pendingSession = firstSessions.transition(
          CloudWriteMode.cleanupPending,
        );
        final stored = CloudBackupDeletionJournal.pending(
          session: pendingSession,
          requestKey: 'C' * 43,
        );
        final journal = _MemoryJournalStore()..value = stored;
        final restartedSessions = CloudWriteSessionController();
        final gateway = _Gateway()
          ..responses.add(CloudBackupDeletionRemoteState.completed);
        final coordinator = CloudBackupDeletionCoordinator(
          sessions: restartedSessions,
          currentUid: () => 'durable',
          journalStore: journal,
          gateway: gateway,
          createRequestKey: () => 'must-not-be-used',
        );

        expect(await coordinator.run(), CloudWriteResult.completed);
        expect(gateway.requestKeys, ['C' * 43]);
        expect(restartedSessions.current!.uid, 'durable');
        expect(restartedSessions.current!.mode, CloudWriteMode.ready);
        expect(await journal.read(), isNull);
      },
    );

    test('different live identity safely clears stale local journal', () async {
      final oldSessions = CloudWriteSessionController()..acquire('old-user');
      final journal = _MemoryJournalStore()
        ..value = CloudBackupDeletionJournal.pending(
          session: oldSessions.transition(CloudWriteMode.cleanupPending),
          requestKey: 'D' * 43,
        );
      final currentSessions = CloudWriteSessionController()
        ..acquire('new-user');
      final gateway = _Gateway();
      final coordinator = CloudBackupDeletionCoordinator(
        sessions: currentSessions,
        currentUid: () => 'new-user',
        journalStore: journal,
        gateway: gateway,
        createRequestKey: () => 'unused',
      );

      expect(await coordinator.run(), CloudWriteResult.stale);
      expect(await journal.read(), isNull);
      expect(gateway.requestKeys, isEmpty);
      expect(currentSessions.current!.uid, 'new-user');
      expect(currentSessions.current!.mode, CloudWriteMode.ready);
    });

    test('missing identity retains an unknown-outcome journal', () async {
      final sessions = CloudWriteSessionController()..acquire('durable');
      final journal = _MemoryJournalStore()
        ..value = CloudBackupDeletionJournal.pending(
          session: sessions.transition(CloudWriteMode.cleanupPending),
          requestKey: 'E' * 43,
        );
      final coordinator = CloudBackupDeletionCoordinator(
        sessions: sessions,
        currentUid: () => null,
        journalStore: journal,
        gateway: _Gateway(),
        createRequestKey: () => 'unused',
      );

      expect(await coordinator.run(), CloudWriteResult.blocked);
      expect(await journal.read(), isNotNull);
    });

    test('foreign cleanup fence never starts a backup deletion', () async {
      final sessions = CloudWriteSessionController()
        ..acquire('durable')
        ..transition(CloudWriteMode.cleanupPending);
      final gateway = _Gateway();
      final coordinator = CloudBackupDeletionCoordinator(
        sessions: sessions,
        currentUid: () => 'durable',
        journalStore: _MemoryJournalStore(),
        gateway: gateway,
        createRequestKey: () => 'H' * 43,
      );

      expect(await coordinator.run(), CloudWriteResult.blocked);
      expect(gateway.requestKeys, isEmpty);
      expect(await coordinator.journalStore.read(), isNull);
      expect(sessions.current!.mode, CloudWriteMode.cleanupPending);
    });
  });

  test(
    'Firebase gateway uses a limited-use App Check token and safe response',
    () async {
      String? name;
      Map<String, Object?>? data;
      HttpsCallableOptions? options;
      final gateway = FirebaseCloudBackupDeletionGateway(({
        required callableName,
        required payload,
        required callableOptions,
      }) async {
        name = callableName;
        data = payload;
        options = callableOptions;
        return {'state': 'completed'};
      });

      final result = await gateway.deleteCloudBackup('F' * 43);

      expect(result, CloudBackupDeletionRemoteState.completed);
      expect(name, 'deleteCloudBackup');
      expect(data, {'requestKey': 'F' * 43});
      expect(options!.limitedUseAppCheckToken, isTrue);
    },
  );

  test('journal rejects malformed keys and non-pending sessions', () {
    final ready = const CloudWriteSession(
      uid: 'durable',
      epoch: 1,
      mode: CloudWriteMode.ready,
    );
    expect(
      () => CloudBackupDeletionJournal.pending(
        session: ready,
        requestKey: 'G' * 43,
      ),
      throwsFormatException,
    );
    expect(
      () => CloudBackupDeletionJournal.fromJson({
        'version': 1,
        'uid': 'durable',
        'epoch': 2,
        'mode': 'cleanupPending',
        'requestKey': 'short',
      }),
      throwsFormatException,
    );
  });

  test('shared preferences stores only the exact deletion journal', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    const store = SharedPreferencesCloudBackupDeletionJournalStore();
    final journal = CloudBackupDeletionJournal.pending(
      session: const CloudWriteSession(
        uid: 'durable',
        epoch: 2,
        mode: CloudWriteMode.cleanupPending,
      ),
      requestKey: 'J' * 43,
    );

    await store.write(journal);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getKeys(), {CloudBackupDeletionJournal.storageKey});
    expect(await store.read(), isNotNull);
    await store.clear();
    expect(await store.read(), isNull);
  });

  test('default request keys are 256-bit base64url values', () {
    final keys = {
      for (var index = 0; index < 64; index += 1)
        CloudBackupDeletionCoordinator.createSecureRequestKey(),
    };

    expect(keys, hasLength(64));
    for (final key in keys) {
      expect(key, hasLength(43));
      expect(key, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
    }
  });
}

class _MemoryJournalStore implements CloudBackupDeletionJournalStore {
  CloudBackupDeletionJournal? value;

  @override
  Future<void> clear() async {
    value = null;
  }

  @override
  Future<CloudBackupDeletionJournal?> read() async => value;

  @override
  Future<void> write(CloudBackupDeletionJournal journal) async {
    value = journal;
  }
}

class _Gateway implements CloudBackupDeletionGateway {
  final List<CloudBackupDeletionRemoteState> responses = [];
  final List<String> requestKeys = [];
  Object? error;

  @override
  Future<CloudBackupDeletionRemoteState> deleteCloudBackup(
    String requestKey,
  ) async {
    requestKeys.add(requestKey);
    if (error case final failure?) {
      throw failure;
    }
    return responses.isEmpty
        ? CloudBackupDeletionRemoteState.pending
        : responses.removeAt(0);
  }
}
