import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/account_reconciliation.dart';
import 'package:ko_lernen_app/services/account/account_switch_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_transition_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_transition_journal.dart';
import 'package:ko_lernen_app/services/account/cloud_read_result.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/app_startup_coordinator.dart';
import 'package:ko_lernen_app/services/auth_service.dart';
import 'package:ko_lernen_app/services/cloud_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'persisted switch resumes real reconciliation with a fresh epoch history',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final first = _RestartHarness(preferences);
      first.sessions.acquire('source');
      first.sessions.transition(CloudWriteMode.quiesced);
      first.sessions.transition(CloudWriteMode.ready);
      final interrupted = await first.coordinator.switchToExisting(
        provider: AccountLinkProvider.google,
        credential: GoogleAuthProvider.credential(idToken: 'local-test-token'),
        sourceUid: 'source',
        catalog: const {},
      );

      expect(interrupted.status, AccountSwitchStatus.mergeDeferred);
      expect(first.remoteWrites, 3, reason: 'Real CAS retries exhaust first.');
      expect(first.localWrites, 0);
      expect(first.backfills, 0);
      final persistedSwitch = await first.switchStore.read();
      final persistedMerge = await first.mergeStore.read();
      expect(persistedSwitch?.operationId, 'restart-operation');
      expect(
        persistedMerge?.reconciliationCheckpoint,
        ReconciliationCheckpoint.merged,
      );
      expect(persistedMerge?.remoteRevision, 7);
      expect(persistedMerge?.reconciliationLocalCustomPackBaseIds, isEmpty);
      expect(persistedMerge?.session, first.sessions.current);

      // Recreate process-local state from the exact native preference bytes.
      // No session object or fake reconciliation result survives this boundary.
      final persisted = <String, Object>{
        AccountSwitchJournal.storageKey: preferences.getString(
          AccountSwitchJournal.storageKey,
        )!,
        AccountSwitchJournal.reconciliationStorageKey: preferences.getString(
          AccountSwitchJournal.reconciliationStorageKey,
        )!,
      };
      SharedPreferences.setMockInitialValues(persisted);
      final restartedPreferences = await SharedPreferences.getInstance();
      final restarted = _RestartHarness(restartedPreferences)
        ..identity.currentUid = 'target'
        ..identity.currentIsAnonymous = false
        ..allowCommit = true;
      expect(restarted.sessions.current, isNull);

      final resolver = AccountStartupJournalResolver(
        sessions: restarted.sessions,
        hasLegacyReplacementJournal: () async => false,
        discardLegacyReplacement: () async {},
        readSwitch: restarted.switchStore.read,
        readDeletion: () async => null,
      );
      late AccountSwitchResult resumed;
      var signInChecks = 0;
      final started = await AppStartupCoordinator(
        initializeFirebase: () async => true,
        initializeAppCheck: () async {},
        currentUserId: () => restarted.identity.currentUid,
        restorePendingAccountState: resolver.restore,
        ensureSignedIn: () async {
          signInChecks += 1;
          if (signInChecks == 1) {
            expect(restarted.sessions.current, isNull);
          }
        },
        resumeAccountSwitch: () async {
          resumed = await restarted.coordinator.resume(
            liveUid: restarted.identity.currentUid,
            catalog: const {},
          );
        },
        synchronizeReadySession: (_) {
          expect(restarted.sessions.current?.mode, CloudWriteMode.ready);
          expect(
            restartedPreferences.containsKey(AccountSwitchJournal.storageKey),
            isFalse,
          );
        },
        resumeMediaCleanup: () async {},
        resumeBookshelfSync: () async {},
        resumeAccountOperation: () async {},
        initializeAccessSnapshot: () async {},
        enablePush: () async {},
        notificationsEnabled: () => false,
      ).start();
      expect(started, isTrue);
      expect(signInChecks, 2);

      expect(
        restarted.sessions.current?.epoch,
        isNot(persistedMerge!.session.epoch),
      );
      expect(resumed.status, AccountSwitchStatus.completed);
      expect(restarted.journalAtReconcile?.toJson(), persistedMerge.toJson());
      expect(restarted.sessionAtReconcile, persistedMerge.session);
      expect(restarted.remoteReads, 1);
      expect(restarted.remoteWrites, 1);
      expect(restarted.operationIds, ['restart-operation']);
      expect(restarted.expectedRevisions, [7]);
      expect(restarted.localWrites, 1);
      expect(restarted.local.fields, {'local_count': 2, 'remote_count': 3});
      expect(restarted.sessions.current?.mode, CloudWriteMode.ready);
      expect(restarted.backfills, 1);
      expect(await restarted.switchStore.read(), isNull);
      expect(await restarted.mergeStore.read(), isNull);

      final again = await restarted.coordinator.resume(
        liveUid: 'target',
        catalog: const {},
      );
      expect(again.status, AccountSwitchStatus.failed);
      expect(restarted.remoteWrites, 1);
      expect(restarted.backfills, 1);
    },
  );

  for (final scenario in [
    'exact current',
    'newer current',
    'other current',
    'cleared newer history',
    'wrong uid',
    'wrong mode',
    'wrong operation',
    'replacement metadata',
    'identity during read',
    'same uid reacquired during read',
    'marker during read',
    'read error',
    'actual identity mismatch',
    'target ready quarantine',
    'stale other ready quarantine',
    'read error ready quarantine',
  ]) {
    test('persisted switch recovery guards $scenario', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final harness = _RestartHarness(preferences)
        ..identity.currentUid = 'target'
        ..identity.currentIsAnonymous = false
        ..allowCommit = true;
      const savedSession = CloudWriteSession(
        uid: 'target',
        epoch: 7,
        mode: CloudWriteMode.reconciling,
      );
      const marker = AccountSwitchJournal(
        version: 1,
        sourceUid: 'source',
        targetUid: 'target',
        provider: 'google',
        operationId: 'restart-operation',
        createdAtMillis: 1000,
      );
      var journal = AccountTransitionJournal.fromSession(
        savedSession,
        reconciliationOperationId: marker.operationId,
        reconciliationCheckpoint: ReconciliationCheckpoint.merged,
        remoteRevision: 7,
        reconciliationLocalCustomPackBaseIds: const {},
      );
      switch (scenario) {
        case 'exact current':
          harness.sessions.resume(savedSession, expectedUid: 'target');
        case 'newer current':
        case 'cleared newer history':
          harness.sessions.resume(savedSession, expectedUid: 'target');
          harness.sessions.transition(CloudWriteMode.reconciling);
          if (scenario == 'cleared newer history') {
            harness.sessions.clear();
          }
        case 'other current':
          harness.sessions.acquire('other');
        case 'wrong uid':
          journal = journal.copyWith(
            session: const CloudWriteSession(
              uid: 'other',
              epoch: 7,
              mode: CloudWriteMode.reconciling,
            ),
          );
        case 'wrong mode':
          journal = journal.copyWith(
            session: const CloudWriteSession(
              uid: 'target',
              epoch: 7,
              mode: CloudWriteMode.ready,
            ),
          );
        case 'wrong operation':
          journal = journal.copyWith(reconciliationOperationId: 'other-op');
        case 'replacement metadata':
          journal = AccountTransitionJournal.fromSession(
            savedSession,
            reconciliationOperationId: marker.operationId,
            reconciliationCheckpoint: ReconciliationCheckpoint.merged,
            remoteRevision: 7,
            reconciliationLocalCustomPackBaseIds: const {},
            replacementProvider: 'google',
            replacementTargetUid: 'target',
            replacementRequestKey: 'request',
            replacementPhase: AccountReplacementPhase.reconciling,
            replacementOperationId: marker.operationId,
            replacementOperationVersion: 1,
          );
        case 'identity during read':
          harness.afterMergeRead = () async {
            harness.identity.currentUid = 'other';
          };
        case 'same uid reacquired during read':
          harness.afterMergeRead = () async {
            harness.sessions.acquire('target');
          };
        case 'marker during read':
          harness.afterMergeRead = () async {
            await harness.switchStore.write(
              const AccountSwitchJournal(
                version: 1,
                sourceUid: 'new-source',
                targetUid: 'target',
                provider: 'google',
                operationId: 'new-operation',
                createdAtMillis: 2000,
              ),
            );
          };
        case 'read error':
          harness.afterMergeRead = () async {
            throw StateError('read failed');
          };
        case 'actual identity mismatch':
          harness.identity.currentUid = 'other';
        case 'target ready quarantine':
          harness.sessions.resume(savedSession, expectedUid: 'target');
          harness.sessions.transition(CloudWriteMode.ready);
        case 'stale other ready quarantine':
          harness.sessions.acquire('other');
        case 'read error ready quarantine':
          harness.sessions.acquire('target');
          harness.afterMergeRead = () async {
            throw StateError('read failed');
          };
      }
      await harness.switchStore.write(marker);
      await harness.mergeStore.write(journal);
      final result = await harness.coordinator.resume(
        liveUid: 'target',
        catalog: const {},
      );
      if (scenario == 'exact current') {
        expect(result.status, AccountSwitchStatus.completed);
        expect(harness.journalAtReconcile?.toJson(), journal.toJson());
        expect(harness.sessionAtReconcile, savedSession);
        expect(harness.backfills, 1);
        expect(harness.remoteWrites, 1);
      } else {
        expect(result.status, AccountSwitchStatus.mergeDeferred);
        expect(harness.reconcileCalls, 0);
        expect(harness.remoteReads, 0);
        expect(harness.remoteWrites, 0);
        expect(harness.localWrites, 0);
        expect(harness.backfills, 0);
        expect(await harness.switchStore.read(), isNotNull);
        expect((await harness.mergeStore.read())?.toJson(), journal.toJson());
        if (scenario.endsWith('ready quarantine')) {
          expect(
            harness.resumeMergeReads,
            0,
            reason: 'Ready quarantine must not depend on reading merge data.',
          );
          var preparations = 0;
          var writes = 0;
          final backupResults = <CloudWriteResult>[];
          for (final uid in {harness.sessions.current!.uid, 'target'}) {
            backupResults.add(
              await CloudSync.backupWithSession(
                sessions: harness.sessions,
                uid: uid,
                prepare: () async {
                  preparations += 1;
                },
                write: () async {
                  writes += 1;
                },
              ),
            );
          }
          expect(
            preparations,
            0,
            reason: 'Deferred switch must fence ordinary backup preparation.',
          );
          expect(
            writes,
            0,
            reason: 'No unmerged payload may reach ordinary backup.',
          );
          expect(backupResults, everyElement(CloudWriteResult.blocked));
          expect(harness.sessions.current?.mode, CloudWriteMode.blocked);
        }
      }
    });
  }
}

AccountReconciliationSnapshot _snapshot(Map<String, Object?> fields) =>
    AccountReconciliationSnapshot(
      fields: fields,
      srsCards: const {},
      customPacks: const {},
      packProgress: const {},
    );

class _RestartHarness {
  _RestartHarness(this.preferences);

  final SharedPreferences preferences;
  final sessions = CloudWriteSessionController();
  final identity = _Identity();
  late final switchStore = SharedPreferencesAccountSwitchJournalStore(
    preferences,
  );
  late final mergeStore = SharedPreferencesAccountTransitionJournalStore(
    preferences,
    storageKey: AccountSwitchJournal.reconciliationStorageKey,
  );
  var local = _snapshot({'local_count': 2});
  var remote = _snapshot({'remote_count': 3});
  bool allowCommit = false;
  int remoteReads = 0;
  int remoteWrites = 0;
  int localWrites = 0;
  int backfills = 0;
  int reconcileCalls = 0;
  int resumeMergeReads = 0;
  AccountTransitionJournal? journalAtReconcile;
  CloudWriteSession? sessionAtReconcile;
  Future<void> Function()? afterMergeRead;
  final operationIds = <String>[];
  final expectedRevisions = <int?>[];

  late final coordinator = AccountSwitchCoordinator(
    sessions: sessions,
    identity: identity,
    journalStore: switchStore,
    reconciliationJournalStore: _ReadHookStore(mergeStore, () async {
      resumeMergeReads += 1;
      await afterMergeRead?.call();
    }),
    localPreflight: () async {},
    ownershipTransition: ({required oldUid, required transition}) async {
      sessions.transition(CloudWriteMode.quiesced);
      await transition();
      sessions.transition(CloudWriteMode.cleanupPending);
      return CloudWriteResult.completed;
    },
    rebindPush: () async {},
    reconcile:
        ({
          required targetUid,
          required session,
          required operationId,
          required catalog,
        }) async {
          reconcileCalls += 1;
          sessionAtReconcile = session;
          journalAtReconcile = await mergeStore.read();
          return AccountReconciliationCoordinator(
            sessions: sessions,
            journalStore: mergeStore,
            readRemote: () async {
              remoteReads += 1;
              return CloudReadResult.present(remote, revision: 7);
            },
            loadLocal: () => local,
            writeRemote:
                (
                  snapshot, {
                  required expectedRevision,
                  required operationId,
                }) async {
                  remoteWrites += 1;
                  operationIds.add(operationId);
                  expectedRevisions.add(expectedRevision);
                  if (!allowCommit) {
                    return const ReconciliationWriteResult.revisionConflict();
                  }
                  remote = snapshot;
                  return const ReconciliationWriteResult.committed(revision: 8);
                },
            writeLocal:
                (snapshot, {required session, required sessions}) async {
                  expect(sessions.current, session);
                  localWrites += 1;
                  local = snapshot;
                },
          ).reconcile(
            session: session,
            operationId: operationId,
            catalog: catalog,
          );
        },
    activateBackfill: (_) async {
      backfills += 1;
    },
    clearReconciliationJournal: () async {
      await preferences.remove(AccountSwitchJournal.reconciliationStorageKey);
    },
    newOperationId: () => 'restart-operation',
  );
}

class _ReadHookStore implements AccountTransitionJournalStore {
  _ReadHookStore(this.delegate, this.afterRead);
  final AccountTransitionJournalStore delegate;
  final Future<void> Function() afterRead;

  @override
  Future<AccountTransitionJournal?> read() async {
    final result = await delegate.read();
    await afterRead();
    return result;
  }

  @override
  Future<void> write(AccountTransitionJournal journal) =>
      delegate.write(journal);
  @override
  Future<bool> writeIfCurrent({
    required AccountTransitionJournal expected,
    required AccountTransitionJournal next,
    required bool Function() isCurrent,
  }) => delegate.writeIfCurrent(
    expected: expected,
    next: next,
    isCurrent: isCurrent,
  );
  @override
  Future<bool> restoreIfAbsent({
    required AccountTransitionJournal expected,
    required bool Function() isCurrent,
  }) => delegate.restoreIfAbsent(expected: expected, isCurrent: isCurrent);
}

class _Identity implements AccountSwitchIdentity {
  @override
  String? currentUid = 'source';
  @override
  bool currentIsAnonymous = true;

  @override
  Future<String> signInWithCredential(AuthCredential credential) async {
    currentUid = 'target';
    currentIsAnonymous = false;
    return 'target';
  }
}
