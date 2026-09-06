import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/account_reconciliation.dart';
import 'package:ko_lernen_app/services/account/account_switch_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_transition_coordinator.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/pack_progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

AuthCredential _credential() =>
    GoogleAuthProvider.credential(idToken: 'id-token', accessToken: 'token');

void main() {
  group('AccountSwitchCoordinator.switchToExisting', () {
    test(
      'happy path: signs in, journals before merging, and completes with backfill',
      () async {
        final harness = _Harness();
        final credential = _credential();

        final result = await harness.coordinator.switchToExisting(
          provider: AccountLinkProvider.google,
          credential: credential,
          sourceUid: harness.sourceUid,
          catalog: harness.catalog,
        );

        expect(harness.localPreflightCalls, 1);
        expect(harness.identity.signInCalls, 1);
        expect(harness.identity.lastCredential, same(credential));

        final journalAtReconcile = harness.reconcileJournalAtCallTime;
        expect(journalAtReconcile, isNotNull);
        expect(journalAtReconcile!.sourceUid, harness.sourceUid);
        expect(journalAtReconcile.targetUid, harness.targetUid);
        expect(journalAtReconcile.provider, AccountLinkProvider.google.name);
        expect(journalAtReconcile.operationId.length, 36);

        expect(harness.reconcileCalls, 1);
        expect(harness.reconcileLastTargetUid, harness.targetUid);
        expect(harness.reconcileLastSession?.mode, CloudWriteMode.reconciling);
        expect(harness.reconcileLastSession?.uid, harness.targetUid);
        expect(harness.reconcileLastOperationId, journalAtReconcile.operationId);

        expect(result.status, AccountSwitchStatus.completed);
        expect(result.targetUid, harness.targetUid);
        expect(harness.sessions.current?.uid, harness.targetUid);
        expect(harness.sessions.current?.mode, CloudWriteMode.ready);
        expect(harness.journalStore.value, isNull);
        expect(harness.journalStore.clearCalls, 1);
        expect(harness.counters.clearReconciliationJournalCalls, 1);
        expect(harness.counters.activateBackfillCalls, 1);
        expect(harness.counters.lastBackfillUid, harness.targetUid);
      },
    );

    test(
      'signIn failure propagates, restores a fresh ready source session, and rebinds push',
      () async {
        final harness = _Harness();
        final beforeEpoch = harness.sessions.current!.epoch;
        harness.identity.signInError = () =>
            FirebaseAuthException(code: 'invalid-credential');

        await expectLater(
          harness.coordinator.switchToExisting(
            provider: AccountLinkProvider.google,
            credential: _credential(),
            sourceUid: harness.sourceUid,
            catalog: harness.catalog,
          ),
          throwsA(isA<FirebaseAuthException>()),
        );

        expect(harness.journalStore.value, isNull);
        expect(harness.sessions.current?.uid, harness.sourceUid);
        expect(harness.sessions.current?.mode, CloudWriteMode.ready);
        expect(harness.sessions.current?.epoch, greaterThan(beforeEpoch));
        expect(harness.counters.rebindPushCalls, 1);
      },
    );

    test(
      'a source session that is not ready fails without signing in',
      () async {
        final harness = _Harness();
        harness.sessions.transition(CloudWriteMode.quiesced);

        final result = await harness.coordinator.switchToExisting(
          provider: AccountLinkProvider.google,
          credential: _credential(),
          sourceUid: harness.sourceUid,
          catalog: harness.catalog,
        );

        expect(result.status, AccountSwitchStatus.failed);
        expect(harness.identity.signInCalls, 0);
        expect(harness.journalStore.value, isNull);
      },
    );

    test(
      'a malformed local snapshot fails before any identity change',
      () async {
        final harness = _Harness();
        final sessionBefore = harness.sessions.current;
        harness.localPreflightOverride = () async {
          throw const FormatException('bad local snapshot');
        };

        final result = await harness.coordinator.switchToExisting(
          provider: AccountLinkProvider.google,
          credential: _credential(),
          sourceUid: harness.sourceUid,
          catalog: harness.catalog,
        );

        expect(result.status, AccountSwitchStatus.failed);
        expect(harness.identity.signInCalls, 0);
        expect(harness.journalStore.value, isNull);
        expect(harness.sessions.current, same(sessionBefore));
      },
    );

    test(
      'a deferred merge keeps the session reconciling and the journal intact',
      () async {
        final harness = _Harness()
          ..reconcileResult = const AccountReconciliationResult(
            AccountReconciliationStatus.unavailable,
          );

        final result = await harness.coordinator.switchToExisting(
          provider: AccountLinkProvider.google,
          credential: _credential(),
          sourceUid: harness.sourceUid,
          catalog: harness.catalog,
        );

        expect(result.status, AccountSwitchStatus.mergeDeferred);
        expect(result.targetUid, harness.targetUid);
        expect(harness.journalStore.value, isNotNull);
        expect(harness.sessions.current?.mode, CloudWriteMode.reconciling);
        expect(harness.sessions.current?.uid, harness.targetUid);
        expect(harness.counters.activateBackfillCalls, 0);
        expect(harness.counters.clearReconciliationJournalCalls, 0);
        expect(harness.journalStore.clearCalls, 0);
      },
    );

    test('a blocked merge still completes with the cloud copy winning', () async {
      final harness = _Harness()
        ..reconcileResult = const AccountReconciliationResult(
          AccountReconciliationStatus.blocked,
          conflicts: [
            AccountReconciliationConflict(
              kind: AccountReconciliationConflictKind.packProgress,
              id: 'pack-a',
            ),
          ],
        );

      final result = await harness.coordinator.switchToExisting(
        provider: AccountLinkProvider.google,
        credential: _credential(),
        sourceUid: harness.sourceUid,
        catalog: harness.catalog,
      );

      expect(result.status, AccountSwitchStatus.completed);
      expect(result.targetUid, harness.targetUid);
      expect(harness.journalStore.value, isNull);
      expect(harness.counters.clearReconciliationJournalCalls, 1);
      expect(harness.sessions.current?.mode, CloudWriteMode.ready);
      expect(harness.sessions.current?.uid, harness.targetUid);
      expect(harness.counters.activateBackfillCalls, 1);
    });

    test('a reconcile exception is treated as a deferred merge', () async {
      final harness = _Harness()..reconcileThrows = () => StateError('boom');

      final result = await harness.coordinator.switchToExisting(
        provider: AccountLinkProvider.google,
        credential: _credential(),
        sourceUid: harness.sourceUid,
        catalog: harness.catalog,
      );

      expect(result.status, AccountSwitchStatus.mergeDeferred);
      expect(harness.journalStore.value, isNotNull);
      expect(harness.sessions.current?.mode, CloudWriteMode.reconciling);
      expect(harness.counters.activateBackfillCalls, 0);
    });

    test(
      'an existing journal blocks a new switch instead of overwriting it',
      () async {
        final harness = _Harness();
        final existing = AccountSwitchJournal(
          version: AccountSwitchJournal.currentVersion,
          sourceUid: harness.sourceUid,
          targetUid: harness.targetUid,
          provider: AccountLinkProvider.google.name,
          operationId: 'earlier-op',
          createdAtMillis: 500,
        );
        harness.journalStore.value = existing;

        final result = await harness.coordinator.switchToExisting(
          provider: AccountLinkProvider.google,
          credential: _credential(),
          sourceUid: harness.sourceUid,
          catalog: harness.catalog,
        );

        expect(result.status, AccountSwitchStatus.failed);
        expect(harness.identity.signInCalls, 0);
        expect(harness.journalStore.value, same(existing));
      },
    );
  });

  group('AccountSwitchCoordinator.resume', () {
    test('resume acquires the target session and completes the merge', () async {
      final harness = _Harness();
      final journal = AccountSwitchJournal(
        version: AccountSwitchJournal.currentVersion,
        sourceUid: harness.sourceUid,
        targetUid: harness.targetUid,
        provider: AccountLinkProvider.google.name,
        operationId: 'resume-op-1',
        createdAtMillis: 1000,
      );
      harness.journalStore.value = journal;
      harness.sessions.clear();
      harness.identity.currentUid = harness.targetUid;
      harness.identity.currentIsAnonymous = false;

      final result = await harness.coordinator.resume(
        liveUid: harness.targetUid,
        catalog: harness.catalog,
      );

      expect(result.status, AccountSwitchStatus.completed);
      expect(harness.sessions.current?.uid, harness.targetUid);
      expect(harness.sessions.current?.mode, CloudWriteMode.ready);
      expect(harness.journalStore.value, isNull);
      expect(harness.counters.clearReconciliationJournalCalls, 1);
      expect(harness.reconcileLastSession?.mode, CloudWriteMode.reconciling);
      expect(harness.reconcileLastOperationId, 'resume-op-1');
    });

    test(
      'resume discards the journal when the live uid does not match the target',
      () async {
        final harness = _Harness();
        final journal = AccountSwitchJournal(
          version: AccountSwitchJournal.currentVersion,
          sourceUid: harness.sourceUid,
          targetUid: harness.targetUid,
          provider: AccountLinkProvider.google.name,
          operationId: 'resume-op-2',
          createdAtMillis: 1000,
        );
        harness.journalStore.value = journal;

        final result = await harness.coordinator.resume(
          liveUid: 'someone-else',
          catalog: harness.catalog,
        );

        expect(result.status, AccountSwitchStatus.failed);
        expect(harness.journalStore.value, isNull);
        expect(harness.counters.clearReconciliationJournalCalls, 1);
        expect(harness.reconcileCalls, 0);
      },
    );

    test('resume with no journal is a silent no-op', () async {
      final harness = _Harness();

      final result = await harness.coordinator.resume(
        liveUid: harness.targetUid,
        catalog: harness.catalog,
      );

      expect(result.status, AccountSwitchStatus.failed);
      expect(harness.reconcileCalls, 0);
      expect(harness.counters.clearReconciliationJournalCalls, 0);
      expect(harness.journalStore.clearCalls, 0);
    });
  });

  group('AccountSwitchJournal', () {
    test('round-trips through JSON', () {
      const journal = AccountSwitchJournal(
        version: AccountSwitchJournal.currentVersion,
        sourceUid: 'source',
        targetUid: 'target',
        provider: 'google',
        operationId: 'operation-1',
        createdAtMillis: 12345,
      );

      final decoded = AccountSwitchJournal.fromJson(journal.toJson());

      expect(decoded, journal);
      expect(decoded.hashCode, journal.hashCode);
    });

    test('fromJson rejects a wrong version', () {
      expect(
        () => AccountSwitchJournal.fromJson({
          'version': 2,
          'sourceUid': 'source',
          'targetUid': 'target',
          'provider': 'google',
          'operationId': 'op-1',
          'createdAtMillis': 1,
        }),
        throwsFormatException,
      );
    });

    test('fromJson rejects an empty uid', () {
      expect(
        () => AccountSwitchJournal.fromJson({
          'version': AccountSwitchJournal.currentVersion,
          'sourceUid': '',
          'targetUid': 'target',
          'provider': 'google',
          'operationId': 'op-1',
          'createdAtMillis': 1,
        }),
        throwsFormatException,
      );
    });

    test('fromJson rejects a non-int createdAtMillis', () {
      expect(
        () => AccountSwitchJournal.fromJson({
          'version': AccountSwitchJournal.currentVersion,
          'sourceUid': 'source',
          'targetUid': 'target',
          'provider': 'google',
          'operationId': 'op-1',
          'createdAtMillis': '1',
        }),
        throwsFormatException,
      );
    });
  });

  group('SharedPreferencesAccountSwitchJournalStore', () {
    test('removes a corrupt entry and returns null', () async {
      SharedPreferences.setMockInitialValues({
        AccountSwitchJournal.storageKey: 'not-json',
      });
      final preferences = await SharedPreferences.getInstance();
      final store = SharedPreferencesAccountSwitchJournalStore(preferences);

      final result = await store.read();

      expect(result, isNull);
      expect(preferences.containsKey(AccountSwitchJournal.storageKey), isFalse);
    });

    test('round-trips a journal and clears it', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final store = SharedPreferencesAccountSwitchJournalStore(preferences);
      const journal = AccountSwitchJournal(
        version: AccountSwitchJournal.currentVersion,
        sourceUid: 'source',
        targetUid: 'target',
        provider: 'google',
        operationId: 'operation-1',
        createdAtMillis: 12345,
      );

      await store.write(journal);
      expect(await store.read(), journal);

      await store.clear();
      expect(await store.read(), isNull);
    });
  });
}

class _FakeIdentity implements AccountSwitchIdentity {
  _FakeIdentity({required this.currentUid});

  @override
  String? currentUid;

  @override
  bool currentIsAnonymous = true;

  String signInTargetUid = 'target';
  Object? Function()? signInError;
  int signInCalls = 0;
  AuthCredential? lastCredential;

  @override
  Future<String> signInWithCredential(AuthCredential credential) async {
    signInCalls += 1;
    lastCredential = credential;
    final errorFactory = signInError;
    if (errorFactory != null) {
      throw errorFactory()!;
    }
    currentUid = signInTargetUid;
    currentIsAnonymous = false;
    return signInTargetUid;
  }
}

class _InMemoryAccountSwitchJournalStore implements AccountSwitchJournalStore {
  AccountSwitchJournal? value;
  int writeCalls = 0;
  int clearCalls = 0;

  @override
  Future<AccountSwitchJournal?> read() async => value;

  @override
  Future<void> write(AccountSwitchJournal journal) async {
    writeCalls += 1;
    value = journal;
  }

  @override
  Future<void> clear() async {
    clearCalls += 1;
    value = null;
  }
}

class _Counters {
  int rebindPushCalls = 0;
  bool rebindPushThrows = false;
  int activateBackfillCalls = 0;
  bool activateBackfillThrows = false;
  String? lastBackfillUid;
  int clearReconciliationJournalCalls = 0;

  Future<void> rebindPush() async {
    rebindPushCalls += 1;
    if (rebindPushThrows) {
      throw StateError('rebind push failed');
    }
  }

  Future<void> activateBackfill(String uid) async {
    activateBackfillCalls += 1;
    lastBackfillUid = uid;
    if (activateBackfillThrows) {
      throw StateError('backfill failed');
    }
  }

  Future<void> clearReconciliationJournal() async {
    clearReconciliationJournalCalls += 1;
  }
}

/// Mimics `PushOwnershipTransitionCoordinator.run` precisely enough for the
/// coordinator's contract: it requires a ready session for `oldUid` (else
/// `blocked` without invoking `transition`), quiesces it, awaits
/// `transition()`, and on success moves to `cleanupPending`/`completed`; on
/// throw it moves to `blocked` and rethrows. Push-token removal and the
/// notification rebind sub-path are production `PushService` details outside
/// this coordinator's contract and are not modelled here.
class _Harness {
  _Harness() {
    identity = _FakeIdentity(currentUid: sourceUid)
      ..signInTargetUid = targetUid;
    sessions.acquire(sourceUid);
  }

  final String sourceUid = 'source';
  final String targetUid = 'target';
  final sessions = CloudWriteSessionController();
  final journalStore = _InMemoryAccountSwitchJournalStore();
  final counters = _Counters();
  final catalog = <String, PackCatalogEntry>{};
  late final _FakeIdentity identity;

  int localPreflightCalls = 0;
  Future<void> Function()? localPreflightOverride;

  AccountReconciliationResult reconcileResult = const AccountReconciliationResult(
    AccountReconciliationStatus.completed,
  );
  Object? Function()? reconcileThrows;
  int reconcileCalls = 0;
  String? reconcileLastTargetUid;
  CloudWriteSession? reconcileLastSession;
  String? reconcileLastOperationId;
  AccountSwitchJournal? reconcileJournalAtCallTime;

  Future<void> _localPreflight() async {
    localPreflightCalls += 1;
    final override = localPreflightOverride;
    if (override != null) {
      await override();
    }
  }

  Future<CloudWriteResult> _ownershipTransition({
    required String oldUid,
    required Future<void> Function() transition,
  }) async {
    final current = sessions.current;
    if (current == null ||
        current.uid != oldUid ||
        current.mode != CloudWriteMode.ready) {
      return CloudWriteResult.blocked;
    }
    sessions.transition(CloudWriteMode.quiesced);
    try {
      await transition();
    } catch (error, stackTrace) {
      sessions.transition(CloudWriteMode.blocked);
      Error.throwWithStackTrace(error, stackTrace);
    }
    sessions.transition(CloudWriteMode.cleanupPending);
    return CloudWriteResult.completed;
  }

  Future<AccountReconciliationResult> _reconcile({
    required String targetUid,
    required CloudWriteSession session,
    required String operationId,
    required Map<String, PackCatalogEntry> catalog,
  }) async {
    reconcileCalls += 1;
    reconcileLastTargetUid = targetUid;
    reconcileLastSession = session;
    reconcileLastOperationId = operationId;
    reconcileJournalAtCallTime = journalStore.value;
    final errorFactory = reconcileThrows;
    if (errorFactory != null) {
      throw errorFactory()!;
    }
    return reconcileResult;
  }

  AccountSwitchCoordinator get coordinator => AccountSwitchCoordinator(
    sessions: sessions,
    identity: identity,
    journalStore: journalStore,
    localPreflight: _localPreflight,
    ownershipTransition: _ownershipTransition,
    rebindPush: counters.rebindPush,
    reconcile: _reconcile,
    activateBackfill: counters.activateBackfill,
    clearReconciliationJournal: counters.clearReconciliationJournal,
  );
}
