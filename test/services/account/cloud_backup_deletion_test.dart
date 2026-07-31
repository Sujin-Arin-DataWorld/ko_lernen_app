import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:ko_lernen_app/services/account/cloud_backup_deletion.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/account/first_link_backfill_journal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CloudBackupDeletionCoordinator', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test(
      'journal state stays loading until an authoritative absence read completes',
      () async {
        final readStarted = Completer<void>();
        final releaseRead = Completer<void>();
        final journal = _MemoryJournalStore()
          ..readStarted = readStarted
          ..readBarrier = releaseRead.future;
        final coordinator = CloudBackupDeletionCoordinator(
          sessions: CloudWriteSessionController()..acquire('durable'),
          currentUid: () => 'durable',
          journalStore: journal,
          gateway: _Gateway(),
          createRequestKey: () => 'A' * 43,
        );

        expect(
          coordinator.journalState.value,
          CloudBackupDeletionJournalState.loading,
        );
        final refreshed = coordinator.refreshJournalState();
        await readStarted.future;
        expect(
          coordinator.journalState.value,
          CloudBackupDeletionJournalState.loading,
        );

        releaseRead.complete();

        expect(await refreshed, CloudBackupDeletionJournalState.clear);
        expect(
          coordinator.journalState.value,
          CloudBackupDeletionJournalState.clear,
        );
        expect(coordinator.pending.value, isFalse);
      },
    );

    test(
      'identity mutation fails closed when the journal is pending',
      () async {
        final sessions = CloudWriteSessionController()..acquire('durable');
        final journal = _MemoryJournalStore()
          ..value = CloudBackupDeletionJournal.pending(
            session: sessions.transition(CloudWriteMode.cleanupPending),
            requestKey: 'B' * 43,
          );
        final coordinator = CloudBackupDeletionCoordinator(
          sessions: sessions,
          currentUid: () => 'durable',
          journalStore: journal,
          gateway: _Gateway(),
          createRequestKey: () => 'unused',
        );
        var mutationCalls = 0;

        await expectLater(
          coordinator.runIdentityMutation(() async {
            mutationCalls += 1;
          }),
          throwsA(isA<CloudBackupDeletionIdentityChangeBlockedException>()),
        );

        expect(mutationCalls, 0);
        expect(
          coordinator.journalState.value,
          CloudBackupDeletionJournalState.pending,
        );
        expect(coordinator.pending.value, isTrue);
      },
    );

    test(
      'identity mutation waits for an in-flight deletion then rechecks its journal',
      () async {
        final callStarted = Completer<void>();
        final releaseCall = Completer<void>();
        final gateway = _Gateway()
          ..callStarted = callStarted
          ..callBarrier = releaseCall.future
          ..responses.add(CloudBackupDeletionRemoteState.pending);
        final coordinator = CloudBackupDeletionCoordinator(
          sessions: CloudWriteSessionController()..acquire('durable'),
          currentUid: () => 'durable',
          journalStore: _MemoryJournalStore(),
          gateway: gateway,
          createRequestKey: () => 'C' * 43,
        );
        var mutationCalls = 0;

        final deletion = coordinator.run();
        await callStarted.future;
        final mutation = coordinator.runIdentityMutation(() async {
          mutationCalls += 1;
        });

        expect(mutationCalls, 0);
        releaseCall.complete();
        expect(await deletion, CloudWriteResult.blocked);
        await expectLater(
          mutation,
          throwsA(isA<CloudBackupDeletionIdentityChangeBlockedException>()),
        );
        expect(mutationCalls, 0);
      },
    );

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
      'completed remote deletion retains its journal until the same-UID '
      'first-link receipt clears, then restart resumes the exact request',
      () async {
        final firstSessions = CloudWriteSessionController()..acquire('durable');
        final deletionJournal = _MemoryJournalStore();
        final firstLinkJournal = _MemoryFirstLinkJournalStore()
          ..value = FirstDurableLinkBackfillJournal.pending(
            uid: 'durable',
            token: 'pending-first-link',
          )
          ..failedClears = 1;
        final gateway = _Gateway()
          ..responses.addAll(<CloudBackupDeletionRemoteState>[
            CloudBackupDeletionRemoteState.completed,
            CloudBackupDeletionRemoteState.completed,
          ]);
        final firstCoordinator = CloudBackupDeletionCoordinator(
          sessions: firstSessions,
          currentUid: () => 'durable',
          journalStore: deletionJournal,
          firstLinkJournalStore: firstLinkJournal,
          gateway: gateway,
          createRequestKey: () => 'R' * 43,
        );

        expect(await firstCoordinator.run(), CloudWriteResult.blocked);
        final retainedDeletion = await deletionJournal.read();
        expect(retainedDeletion, isNotNull);
        expect(await firstLinkJournal.read(), isNotNull);
        expect(firstSessions.current!.mode, CloudWriteMode.cleanupPending);

        final restartedSessions = CloudWriteSessionController();
        final restartedCoordinator = CloudBackupDeletionCoordinator(
          sessions: restartedSessions,
          currentUid: () => 'durable',
          journalStore: deletionJournal,
          firstLinkJournalStore: firstLinkJournal,
          gateway: gateway,
          createRequestKey: () => 'unused',
        );

        expect(await restartedCoordinator.run(), CloudWriteResult.completed);
        expect(await deletionJournal.read(), isNull);
        expect(await firstLinkJournal.read(), isNull);
        expect(restartedSessions.current!.mode, CloudWriteMode.ready);
        expect(gateway.requestKeys, <String>['R' * 43, 'R' * 43]);
      },
    );

    test('first-link compare-clear that throws after removal is accepted only '
        'after a reread proves the same-UID receipt absent', () async {
      final sessions = CloudWriteSessionController()..acquire('durable');
      final deletionJournal = _MemoryJournalStore();
      final firstLinkJournal = _MemoryFirstLinkJournalStore()
        ..value = FirstDurableLinkBackfillJournal.pending(
          uid: 'durable',
          token: 'removed-before-error',
        )
        ..clearThenThrow = 1;
      final coordinator = CloudBackupDeletionCoordinator(
        sessions: sessions,
        currentUid: () => 'durable',
        journalStore: deletionJournal,
        firstLinkJournalStore: firstLinkJournal,
        gateway: _Gateway()
          ..responses.add(CloudBackupDeletionRemoteState.completed),
        createRequestKey: () => 'S' * 43,
      );

      expect(await coordinator.run(), CloudWriteResult.completed);
      expect(await deletionJournal.read(), isNull);
      expect(await firstLinkJournal.read(), isNull);
      expect(sessions.current!.mode, CloudWriteMode.ready);
    });

    test(
      'clear that removes natively then throws completes the exact session',
      () async {
        final sessions = CloudWriteSessionController()..acquire('durable');
        final journal = _MemoryJournalStore()..clearThenThrow = 1;
        final coordinator = CloudBackupDeletionCoordinator(
          sessions: sessions,
          currentUid: () => 'durable',
          journalStore: journal,
          gateway: _Gateway()
            ..responses.add(CloudBackupDeletionRemoteState.completed),
          createRequestKey: () => 'C' * 43,
        );

        expect(await coordinator.run(), CloudWriteResult.completed);
        expect(await journal.read(), isNull);
        expect(sessions.current!.mode, CloudWriteMode.ready);
        expect(
          coordinator.journalState.value,
          CloudBackupDeletionJournalState.clear,
        );
      },
    );

    test(
      'clear that retains the journal then throws stays pending for same-key retry',
      () async {
        final sessions = CloudWriteSessionController()..acquire('durable');
        final journal = _MemoryJournalStore()..failedClears = 1;
        final gateway = _Gateway()
          ..responses.add(CloudBackupDeletionRemoteState.completed)
          ..responses.add(CloudBackupDeletionRemoteState.completed);
        final coordinator = CloudBackupDeletionCoordinator(
          sessions: sessions,
          currentUid: () => 'durable',
          journalStore: journal,
          gateway: gateway,
          createRequestKey: () => 'D' * 43,
        );

        expect(await coordinator.run(), CloudWriteResult.blocked);
        expect((await journal.read())!.requestKey, 'D' * 43);
        expect(sessions.current!.mode, CloudWriteMode.cleanupPending);
        expect(coordinator.pending.value, isTrue);

        expect(await coordinator.run(), CloudWriteResult.completed);
        expect(gateway.requestKeys, ['D' * 43, 'D' * 43]);
        expect(await journal.read(), isNull);
        expect(sessions.current!.mode, CloudWriteMode.ready);
      },
    );

    test('completed A cannot clear a persisted newer B journal', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      addTearDown(
        () => SharedPreferences.setMockInitialValues(<String, Object>{}),
      );
      const durableStore = SharedPreferencesCloudBackupDeletionJournalStore();
      final sessions = CloudWriteSessionController()..acquire('durable');
      CloudBackupDeletionJournal? replacementJournal;
      CloudWriteSession? replacementSession;
      final journal = _PersistingReplacementBeforeClearStore(
        delegate: durableStore,
        beforeClear: () async {
          sessions.acquire('durable');
          replacementSession = sessions.transition(
            CloudWriteMode.cleanupPending,
          );
          replacementJournal = CloudBackupDeletionJournal.pending(
            session: replacementSession!,
            requestKey: 'B' * 43,
          );
          return replacementJournal!;
        },
      );
      final coordinator = CloudBackupDeletionCoordinator(
        sessions: sessions,
        currentUid: () => 'durable',
        journalStore: journal,
        gateway: _Gateway()
          ..responses.add(CloudBackupDeletionRemoteState.completed),
        createRequestKey: () => 'A' * 43,
      );

      expect(await coordinator.run(), CloudWriteResult.stale);
      expect(await durableStore.read(), replacementJournal);
      expect(sessions.current, replacementSession);
      expect(sessions.current!.mode, CloudWriteMode.cleanupPending);
      expect(
        coordinator.journalState.value,
        CloudBackupDeletionJournalState.pending,
      );
    });

    test(
      'clear reconciliation retains a persisted B journal after native failure',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        addTearDown(
          () => SharedPreferences.setMockInitialValues(<String, Object>{}),
        );
        const durableStore = SharedPreferencesCloudBackupDeletionJournalStore();
        final sessions = CloudWriteSessionController()..acquire('durable');
        CloudBackupDeletionJournal? replacementJournal;
        CloudWriteSession? replacementSession;
        final journal = _PersistingReplacementBeforeClearStore(
          delegate: durableStore,
          throwAfterReplacement: true,
          beforeClear: () async {
            sessions.acquire('durable');
            replacementSession = sessions.transition(
              CloudWriteMode.cleanupPending,
            );
            replacementJournal = CloudBackupDeletionJournal.pending(
              session: replacementSession!,
              requestKey: 'C' * 43,
            );
            return replacementJournal!;
          },
        );
        final coordinator = CloudBackupDeletionCoordinator(
          sessions: sessions,
          currentUid: () => 'durable',
          journalStore: journal,
          gateway: _Gateway()
            ..responses.add(CloudBackupDeletionRemoteState.completed),
          createRequestKey: () => 'A' * 43,
        );

        expect(await coordinator.run(), CloudWriteResult.blocked);
        expect(await durableStore.read(), replacementJournal);
        expect(sessions.current, replacementSession);
        expect(sessions.current!.mode, CloudWriteMode.cleanupPending);
        expect(
          coordinator.journalState.value,
          CloudBackupDeletionJournalState.pending,
        );
      },
    );

    test('clear reconciliation never mutates a newer session', () async {
      final sessions = CloudWriteSessionController()..acquire('durable');
      CloudWriteSession? replacement;
      final journal = _MemoryJournalStore()
        ..clearThenThrow = 1
        ..onClear = () {
          replacement = sessions.acquire('new-user');
        };
      final coordinator = CloudBackupDeletionCoordinator(
        sessions: sessions,
        currentUid: () => 'durable',
        journalStore: journal,
        gateway: _Gateway()
          ..responses.add(CloudBackupDeletionRemoteState.completed),
        createRequestKey: () => 'E' * 43,
      );

      expect(await coordinator.run(), CloudWriteResult.stale);
      expect(await journal.read(), isNull);
      expect(sessions.current, same(replacement));
      expect(sessions.current!.uid, 'new-user');
      expect(sessions.current!.mode, CloudWriteMode.ready);
    });

    test(
      'gateway boundary rejects a changed UID before the callable is invoked',
      () async {
        var liveUid = 'durable';
        var callableInvocations = 0;
        final gateway = FirebaseCloudBackupDeletionGateway(
          ({
            required callableName,
            required payload,
            required callableOptions,
          }) async {
            callableInvocations += 1;
            return {'state': 'completed'};
          },
          currentUid: () {
            liveUid = 'new-user';
            return liveUid;
          },
        );
        final coordinator = CloudBackupDeletionCoordinator(
          sessions: CloudWriteSessionController()..acquire('durable'),
          currentUid: () => liveUid,
          journalStore: _MemoryJournalStore(),
          gateway: gateway,
          createRequestKey: () => 'F' * 43,
        );

        expect(await coordinator.run(), CloudWriteResult.stale);
        expect(callableInvocations, 0);
        expect(coordinator.pending.value, isTrue);
      },
    );

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

        var newRequestAdmissionCalls = 0;
        expect(
          await coordinator.run(
            canStart: () async {
              newRequestAdmissionCalls += 1;
              return false;
            },
          ),
          CloudWriteResult.completed,
        );
        expect(newRequestAdmissionCalls, 0);
        expect(gateway.requestKeys, ['C' * 43]);
        expect(restartedSessions.current!.uid, 'durable');
        expect(restartedSessions.current!.mode, CloudWriteMode.ready);
        expect(await journal.read(), isNull);
      },
    );

    test(
      'an unknown old-UID journal blocks a new identity then resumes after restart',
      () async {
        var liveUid = 'old-user';
        final journal = _MemoryJournalStore();
        final initialSessions = CloudWriteSessionController()
          ..acquire('old-user');
        final initialGateway = _Gateway()
          ..error = StateError('unknown remote outcome');
        final initial = CloudBackupDeletionCoordinator(
          sessions: initialSessions,
          currentUid: () => liveUid,
          journalStore: journal,
          gateway: initialGateway,
          createRequestKey: () => 'D' * 43,
        );

        expect(await initial.run(), CloudWriteResult.blocked);
        final pending = await journal.read();
        expect(pending, isNotNull);
        expect(pending!.requestKey, 'D' * 43);

        liveUid = 'new-user';
        final newIdentitySessions = CloudWriteSessionController()
          ..acquire('new-user');
        final newIdentityGateway = _Gateway();
        final whileNewIdentity = CloudBackupDeletionCoordinator(
          sessions: newIdentitySessions,
          currentUid: () => liveUid,
          journalStore: journal,
          gateway: newIdentityGateway,
          createRequestKey: () => 'must-not-be-used',
        );

        expect(await whileNewIdentity.run(), CloudWriteResult.blocked);
        expect((await journal.read())!.session, pending.session);
        expect((await journal.read())!.requestKey, pending.requestKey);
        expect(newIdentityGateway.requestKeys, isEmpty);
        expect(newIdentitySessions.current!.mode, CloudWriteMode.ready);
        expect(whileNewIdentity.pending.value, isTrue);

        liveUid = 'old-user';
        final resumedSessions = CloudWriteSessionController();
        final resumedGateway = _Gateway()
          ..responses.add(CloudBackupDeletionRemoteState.completed);
        final resumed = CloudBackupDeletionCoordinator(
          sessions: resumedSessions,
          currentUid: () => liveUid,
          journalStore: journal,
          gateway: resumedGateway,
          createRequestKey: () => 'must-not-be-used',
        );

        expect(await resumed.run(), CloudWriteResult.completed);
        expect(resumedGateway.requestKeys, ['D' * 43]);
        expect(await journal.read(), isNull);
        expect(resumedSessions.current!.uid, 'old-user');
        expect(resumedSessions.current!.mode, CloudWriteMode.ready);
      },
    );

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

    test(
      'journal write failure rolls back only its exact session so retry works',
      () async {
        final sessions = CloudWriteSessionController()..acquire('durable');
        final journal = _MemoryJournalStore()..failedWrites = 1;
        final gateway = _Gateway()
          ..responses.add(CloudBackupDeletionRemoteState.completed);
        var requestCount = 0;
        final coordinator = CloudBackupDeletionCoordinator(
          sessions: sessions,
          currentUid: () => 'durable',
          journalStore: journal,
          gateway: gateway,
          createRequestKey: () => requestCount++ == 0 ? 'I' * 43 : 'J' * 43,
        );

        expect(await coordinator.run(), CloudWriteResult.blocked);
        expect(await journal.read(), isNull);
        expect(gateway.requestKeys, isEmpty);
        expect(sessions.current!.uid, 'durable');
        expect(sessions.current!.mode, CloudWriteMode.ready);
        expect(coordinator.pending.value, isFalse);

        expect(await coordinator.run(), CloudWriteResult.completed);
        expect(gateway.requestKeys, ['J' * 43]);
        expect(await journal.read(), isNull);
        expect(sessions.current!.mode, CloudWriteMode.ready);
      },
    );

    test('journal write failure never rolls back a newer session', () async {
      final sessions = CloudWriteSessionController()..acquire('durable');
      CloudWriteSession? replacement;
      final journal = _MemoryJournalStore()
        ..failedWrites = 1
        ..onWrite = (_) {
          replacement = sessions.acquire('new-user');
        };
      final gateway = _Gateway();
      final coordinator = CloudBackupDeletionCoordinator(
        sessions: sessions,
        currentUid: () => 'durable',
        journalStore: journal,
        gateway: gateway,
        createRequestKey: () => 'K' * 43,
      );

      expect(await coordinator.run(), CloudWriteResult.blocked);
      expect(await journal.read(), isNull);
      expect(gateway.requestKeys, isEmpty);
      expect(sessions.current, same(replacement));
      expect(sessions.current!.uid, 'new-user');
      expect(sessions.current!.mode, CloudWriteMode.ready);
      expect(coordinator.pending.value, isFalse);
    });

    test(
      'write-after-persist failure retains the exact retry journal',
      () async {
        final sessions = CloudWriteSessionController()..acquire('durable');
        final journal = _MemoryJournalStore()..writeThenThrow = 1;
        final gateway = _Gateway()
          ..responses.add(CloudBackupDeletionRemoteState.completed);
        final coordinator = CloudBackupDeletionCoordinator(
          sessions: sessions,
          currentUid: () => 'durable',
          journalStore: journal,
          gateway: gateway,
          createRequestKey: () => 'L' * 43,
        );

        expect(await coordinator.run(), CloudWriteResult.blocked);
        expect((await journal.read())!.requestKey, 'L' * 43);
        expect(sessions.current!.mode, CloudWriteMode.cleanupPending);
        expect(gateway.requestKeys, isEmpty);
        expect(coordinator.pending.value, isTrue);

        expect(await coordinator.run(), CloudWriteResult.completed);
        expect(gateway.requestKeys, ['L' * 43]);
        expect(await journal.read(), isNull);
        expect(sessions.current!.mode, CloudWriteMode.ready);
      },
    );

    test(
      'a replacement during journal persistence never invokes the old UID',
      () async {
        var liveUid = 'durable';
        final sessions = CloudWriteSessionController()..acquire('durable');
        CloudWriteSession? replacement;
        final journal = _MemoryJournalStore()
          ..onWrite = (_) {
            liveUid = 'new-user';
            replacement = sessions.acquire(liveUid);
          };
        final gateway = _Gateway()
          ..responses.add(CloudBackupDeletionRemoteState.completed);
        final coordinator = CloudBackupDeletionCoordinator(
          sessions: sessions,
          currentUid: () => liveUid,
          journalStore: journal,
          gateway: gateway,
          createRequestKey: () => 'M' * 43,
        );

        expect(await coordinator.run(), CloudWriteResult.blocked);
        expect((await journal.read())!.requestKey, 'M' * 43);
        expect(gateway.requestKeys, isEmpty);
        expect(sessions.current, same(replacement));
        expect(coordinator.pending.value, isTrue);
      },
    );
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
      }, currentUid: () => 'durable');

      final result = await gateway.deleteCloudBackup(
        'F' * 43,
        expectedUid: 'durable',
      );

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
    expect(await store.clearIfCurrent(journal), isTrue);
    expect(await store.read(), isNull);
  });

  test(
    'shared preferences compare-delete retains a different full journal',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const store = SharedPreferencesCloudBackupDeletionJournalStore();
      final expected = CloudBackupDeletionJournal.pending(
        session: const CloudWriteSession(
          uid: 'durable',
          epoch: 2,
          mode: CloudWriteMode.cleanupPending,
        ),
        requestKey: 'J' * 43,
      );
      final newer = CloudBackupDeletionJournal.pending(
        session: const CloudWriteSession(
          uid: 'durable',
          epoch: 3,
          mode: CloudWriteMode.cleanupPending,
        ),
        requestKey: 'K' * 43,
      );
      await store.write(expected);
      await store.write(newer);

      expect(await store.clearIfCurrent(expected), isFalse);
      expect(await store.read(), newer);
    },
  );

  test(
    'shared preferences keeps the journal when native removal returns false',
    () async {
      final originalPlatform = SharedPreferencesStorePlatform.instance;
      addTearDown(() {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        SharedPreferencesStorePlatform.instance = originalPlatform;
      });
      final journal = CloudBackupDeletionJournal.pending(
        session: const CloudWriteSession(
          uid: 'durable',
          epoch: 4,
          mode: CloudWriteMode.cleanupPending,
        ),
        requestKey: 'L' * 43,
      );
      SharedPreferences.setMockInitialValues(<String, Object>{});
      SharedPreferencesStorePlatform.instance =
          _RetainingRemoveStore.withData(<String, Object>{
            'flutter.${CloudBackupDeletionJournal.storageKey}': jsonEncode(
              journal.toJson(),
            ),
          });
      const store = SharedPreferencesCloudBackupDeletionJournalStore();

      expect(await store.clearIfCurrent(journal), isFalse);
      expect(await store.read(), journal);
    },
  );

  test(
    'shared preferences journal reads reload native state before recovery',
    () async {
      addTearDown(
        () => SharedPreferences.setMockInitialValues(<String, Object>{}),
      );
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const store = SharedPreferencesCloudBackupDeletionJournalStore();
      final journal = CloudBackupDeletionJournal.pending(
        session: const CloudWriteSession(
          uid: 'durable',
          epoch: 3,
          mode: CloudWriteMode.cleanupPending,
        ),
        requestKey: 'N' * 43,
      );

      await store.write(journal);
      await SharedPreferencesStorePlatform.instance.remove(
        'flutter.${CloudBackupDeletionJournal.storageKey}',
      );

      expect(await store.read(), isNull);
    },
  );

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
  int failedWrites = 0;
  int writeThenThrow = 0;
  int failedClears = 0;
  int clearThenThrow = 0;
  Completer<void>? readStarted;
  Future<void>? readBarrier;
  void Function(CloudBackupDeletionJournal journal)? onWrite;
  void Function()? onClear;

  @override
  Future<bool> clearIfCurrent(CloudBackupDeletionJournal expected) async {
    onClear?.call();
    if (failedClears > 0) {
      failedClears -= 1;
      throw StateError('journal clear failed');
    }
    if (value != expected) return false;
    value = null;
    if (clearThenThrow > 0) {
      clearThenThrow -= 1;
      throw StateError('journal clear failed after removal');
    }
    return true;
  }

  @override
  Future<CloudBackupDeletionJournal?> read() async {
    readStarted?.complete();
    await readBarrier;
    return value;
  }

  @override
  Future<void> write(CloudBackupDeletionJournal journal) async {
    onWrite?.call(journal);
    if (failedWrites > 0) {
      failedWrites -= 1;
      throw StateError('journal write failed');
    }
    value = journal;
    if (writeThenThrow > 0) {
      writeThenThrow -= 1;
      throw StateError('journal write failed after persistence');
    }
  }
}

class _MemoryFirstLinkJournalStore
    implements FirstDurableLinkBackfillJournalStore {
  FirstDurableLinkBackfillJournal? value;
  int failedClears = 0;
  int clearThenThrow = 0;

  @override
  Future<bool> clearIfCurrent(FirstDurableLinkBackfillJournal expected) async {
    if (failedClears > 0) {
      failedClears -= 1;
      throw StateError('first-link receipt clear failed');
    }
    if (value != expected) return false;
    value = null;
    if (clearThenThrow > 0) {
      clearThenThrow -= 1;
      throw StateError('first-link receipt clear failed after removal');
    }
    return true;
  }

  @override
  Future<bool> createIfAbsent(FirstDurableLinkBackfillJournal journal) async {
    if (value != null) return false;
    value = journal;
    return true;
  }

  @override
  Future<FirstDurableLinkBackfillJournal?> read() async => value;

  @override
  Future<bool> replaceIfCurrent({
    required FirstDurableLinkBackfillJournal expected,
    required FirstDurableLinkBackfillJournal next,
  }) async {
    if (value != expected) return false;
    value = next;
    return true;
  }
}

class _PersistingReplacementBeforeClearStore
    implements CloudBackupDeletionJournalStore {
  _PersistingReplacementBeforeClearStore({
    required this.delegate,
    required this.beforeClear,
    this.throwAfterReplacement = false,
  });

  final CloudBackupDeletionJournalStore delegate;
  final Future<CloudBackupDeletionJournal> Function() beforeClear;
  final bool throwAfterReplacement;
  bool _inserted = false;

  @override
  Future<bool> clearIfCurrent(CloudBackupDeletionJournal expected) async {
    if (!_inserted) {
      _inserted = true;
      await delegate.write(await beforeClear());
    }
    if (throwAfterReplacement) {
      throw StateError('native compare-delete failed after replacement');
    }
    return delegate.clearIfCurrent(expected);
  }

  @override
  Future<CloudBackupDeletionJournal?> read() => delegate.read();

  @override
  Future<void> write(CloudBackupDeletionJournal journal) =>
      delegate.write(journal);
}

class _RetainingRemoveStore extends InMemorySharedPreferencesStore {
  _RetainingRemoveStore.withData(super.data) : super.withData();

  @override
  Future<bool> remove(String key) async => false;
}

class _Gateway implements CloudBackupDeletionGateway {
  final List<CloudBackupDeletionRemoteState> responses = [];
  final List<String> requestKeys = [];
  final List<String> expectedUids = [];
  Completer<void>? callStarted;
  Future<void>? callBarrier;
  Object? error;

  @override
  Future<CloudBackupDeletionRemoteState> deleteCloudBackup(
    String requestKey, {
    required String expectedUid,
  }) async {
    requestKeys.add(requestKey);
    expectedUids.add(expectedUid);
    final started = callStarted;
    if (started != null && !started.isCompleted) {
      started.complete();
    }
    await callBarrier;
    if (error case final failure?) {
      throw failure;
    }
    return responses.isEmpty
        ? CloudBackupDeletionRemoteState.pending
        : responses.removeAt(0);
  }
}
