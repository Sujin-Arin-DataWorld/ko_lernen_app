import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/account_operation_client.dart';
import 'package:ko_lernen_app/services/account/account_reconciliation.dart';
import 'package:ko_lernen_app/services/account/account_transition_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_transition_journal.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/cloud_sync_service.dart';

void main() {
  test('a conflict is inert until the user explicitly confirms', () {
    final harness = _Harness();

    harness.coordinator;

    expect(harness.events, isEmpty);
    expect(harness.sessions.current?.mode, CloudWriteMode.ready);
    expect(harness.journal.value, isNull);
  });

  test(
    'failed isolated target verification preserves source and starts nothing',
    () async {
      final harness = _Harness()..verifier.failure = StateError('rejected');

      final result = await harness.coordinator.confirm(
        const ExistingAccountLinkConflict(AccountLinkProvider.google),
        catalog: const {},
      );

      expect(result.status, AccountTransitionStatus.targetVerificationFailed);
      expect(harness.identity.currentUid, 'anonymous-source');
      expect(harness.operations.prepareCalls, 0);
      expect(harness.reconciliationCalls, 0);
      expect(harness.identity.activationCalls, 0);
      expect(harness.sessions.current?.mode, CloudWriteMode.ready);
      expect(harness.journal.value, isNull);
    },
  );

  test(
    'verified temporary target preserves the primary source through cleanup',
    () async {
      final harness = _Harness();

      final result = await harness.coordinator.confirm(
        const ExistingAccountLinkConflict(AccountLinkProvider.apple),
        catalog: const {},
      );

      expect(result.status, AccountTransitionStatus.completed);
      expect(
        harness.events,
        containsAllInOrder(<String>[
          'verify:apple',
          'prepare',
          'attach',
          'reconcile',
          'commit',
          'start-cleanup',
          'status:completed',
          'dispose-target',
          'activate:apple',
        ]),
      );
      expect(
        harness.events.indexOf('activate:apple'),
        greaterThan(harness.events.indexOf('status:completed')),
      );
      expect(harness.operations.primaryUidAtPrepare, 'anonymous-source');
      expect(harness.operations.primaryUidAtCleanup, 'anonymous-source');
      expect(harness.identity.currentUid, 'durable-target');
      expect(harness.sessions.current?.uid, 'durable-target');
      expect(harness.sessions.current?.mode, CloudWriteMode.ready);
      expect(harness.journal.value, isNull);
    },
  );

  test(
    'reconciliation failure remains resumable and never starts cleanup',
    () async {
      final harness = _Harness()
        ..reconciliationResult = const AccountReconciliationResult(
          AccountReconciliationStatus.unavailable,
        );

      final result = await harness.coordinator.confirm(
        const ExistingAccountLinkConflict(AccountLinkProvider.google),
        catalog: const {},
      );

      expect(result.status, AccountTransitionStatus.reconciliationPending);
      expect(harness.identity.currentUid, 'anonymous-source');
      expect(harness.operations.cleanupCalls, 0);
      expect(harness.identity.activationCalls, 0);
      expect(harness.sessions.current?.mode, CloudWriteMode.reconciling);
      expect(
        harness.journal.value?.replacementPhase,
        AccountReplacementPhase.reconciling,
      );
      expect(harness.events.last, 'dispose-target');
    },
  );

  test(
    'unexpected primary auth change after target attach blocks all work',
    () async {
      final harness = _Harness();
      harness.operations.afterAttach = () {
        harness.identity.currentUid = 'durable-target';
      };

      final result = await harness.coordinator.confirm(
        const ExistingAccountLinkConflict(AccountLinkProvider.google),
        catalog: const {},
      );

      expect(result.status, AccountTransitionStatus.blocked);
      expect(harness.reconciliationCalls, 0);
      expect(harness.operations.cleanupCalls, 0);
      expect(harness.identity.activationCalls, 0);
      expect(harness.journal.value, isNotNull);
    },
  );

  test(
    'production reconciliation factory reads only the secondary target remote',
    () async {
      final sessions = CloudWriteSessionController()
        ..acquire('anonymous-source');
      final sourceSession = sessions.transition(CloudWriteMode.reconciling);
      final target = _FakeReconciliationTarget();
      final coordinator = FirebaseTargetReconciliationFactory.create(
        target: target,
        sourceSession: sourceSession,
        sessions: sessions,
        journalStore: _MemoryJournal(),
        loadLocal: () => AccountReconciliationSnapshot.empty,
        writeLocal: (_, {required session, required sessions}) async {},
      );

      final result = await coordinator.reconcile(
        session: sourceSession,
        operationId: 'operation-1',
        catalog: const {},
      );

      expect(result.status, AccountReconciliationStatus.completed);
      expect(target.requestedFenceUid, 'anonymous-source');
      expect(target.rootReads, 1);
      expect(target.packReads, 1);
      expect(target.membershipReads, 2);
      expect(sessions.current, sourceSession);
    },
  );

  test(
    'restart resumes only for the exact source UID with a fresh target',
    () async {
      final first = _Harness()
        ..reconciliationResult = const AccountReconciliationResult(
          AccountReconciliationStatus.unavailable,
        );
      await first.coordinator.confirm(
        const ExistingAccountLinkConflict(AccountLinkProvider.google),
        catalog: const {},
      );
      final durable = first.journal.value!;

      final restarted = _Harness(
        initialJournal: durable,
        initialSession: durable.session,
      );
      final result = await restarted.coordinator.resume(catalog: const {});

      expect(result.status, AccountTransitionStatus.completed);
      expect(restarted.events.first, 'verify:google');
      expect(restarted.operations.prepareCalls, 0);
      expect(restarted.operations.attachCalls, 0);
      expect(restarted.identity.currentUid, 'durable-target');

      final mismatched = _Harness(
        sourceUid: 'different-source',
        initialJournal: durable,
        initialSession: durable.session,
      );
      final before = mismatched.sessions.current;
      final blocked = await mismatched.coordinator.resume(catalog: const {});

      expect(blocked.status, AccountTransitionStatus.blocked);
      expect(mismatched.events, isEmpty);
      expect(mismatched.sessions.current, before);
      expect(mismatched.journal.value, same(durable));
    },
  );

  test(
    'cancel is allowed before, but never after, source cleanup starts',
    () async {
      final cancellable = _Harness()
        ..reconciliationResult = const AccountReconciliationResult(
          AccountReconciliationStatus.unavailable,
        );
      await cancellable.coordinator.confirm(
        const ExistingAccountLinkConflict(AccountLinkProvider.google),
        catalog: const {},
      );

      final cancelled = await cancellable.coordinator.cancel();

      expect(cancelled, isTrue);
      expect(cancellable.journal.value, isNull);
      expect(cancellable.sessions.current?.uid, 'anonymous-source');
      expect(cancellable.sessions.current?.mode, CloudWriteMode.ready);

      final pending = _Harness()
        ..operations.statusPhase = AccountOperationPhase.sourceCleanupPending;
      final result = await pending.coordinator.confirm(
        const ExistingAccountLinkConflict(AccountLinkProvider.google),
        catalog: const {},
      );
      expect(result.status, AccountTransitionStatus.cleanupPending);
      final journalBeforeCancel = pending.journal.value;

      expect(await pending.coordinator.cancel(), isFalse);
      expect(pending.journal.value, same(journalBeforeCancel));
      expect(pending.sessions.current?.mode, CloudWriteMode.cleanupPending);
      expect(
        pending.journal.value?.reconciliationCheckpoint,
        ReconciliationCheckpoint.completed,
      );
    },
  );
}

class _Harness {
  _Harness({
    this.sourceUid = 'anonymous-source',
    AccountTransitionJournal? initialJournal,
    CloudWriteSession? initialSession,
  }) {
    identity = _FakeIdentity(sourceUid, events);
    verifier = _FakeVerifier(events);
    operations = _FakeOperations(events, identity);
    journal.value = initialJournal;
    if (initialSession == null) {
      sessions.acquire(sourceUid);
    } else {
      sessions.resume(initialSession, expectedUid: initialSession.uid);
    }
  }

  final String sourceUid;
  final events = <String>[];
  final sessions = CloudWriteSessionController();
  final journal = _MemoryJournal();
  late final _FakeIdentity identity;
  late final _FakeVerifier verifier;
  late final _FakeOperations operations;
  AccountReconciliationResult reconciliationResult =
      const AccountReconciliationResult(AccountReconciliationStatus.completed);
  int reconciliationCalls = 0;

  AccountTransitionCoordinator get coordinator => AccountTransitionCoordinator(
    sessions: sessions,
    identity: identity,
    verifier: verifier,
    operations: operations,
    journalStore: journal,
    createRequestKey: () => 'request-key-1',
    reconcile:
        ({
          required target,
          required session,
          required operationId,
          required catalog,
        }) async {
          reconciliationCalls += 1;
          events.add('reconcile');
          expect(target.uid, 'durable-target');
          expect(session.mode, CloudWriteMode.reconciling);
          expect(journal.value?.reconciliationOperationId, operationId);
          if (reconciliationResult.status ==
              AccountReconciliationStatus.completed) {
            await journal.write(
              journal.value!.copyWith(
                reconciliationCheckpoint: ReconciliationCheckpoint.completed,
              ),
            );
          }
          return reconciliationResult;
        },
    maxStatusPolls: 1,
  );
}

class _FakeIdentity implements AccountTransitionIdentity {
  _FakeIdentity(this.currentUid, this.events);

  @override
  String? currentUid;
  final List<String> events;
  int activationCalls = 0;

  @override
  bool get currentIsAnonymous =>
      currentUid == 'anonymous-source' || currentUid == 'different-source';

  @override
  Future<void> activateTarget(
    AccountLinkProvider provider, {
    required String expectedTargetUid,
  }) async {
    activationCalls += 1;
    events.add('activate:${provider.name}');
    expect(expectedTargetUid, 'durable-target');
    currentUid = expectedTargetUid;
  }
}

class _FakeVerifier implements IsolatedTargetVerifier {
  _FakeVerifier(this.events);

  final List<String> events;
  Object? failure;

  @override
  Future<VerifiedTargetContext> verify(AccountLinkProvider provider) async {
    events.add('verify:${provider.name}');
    if (failure != null) throw failure!;
    return _FakeTarget(events);
  }
}

class _FakeTarget implements VerifiedTargetContext {
  _FakeTarget(this.events);

  final List<String> events;

  @override
  String get uid => 'durable-target';

  @override
  bool get isAnonymous => false;

  @override
  Future<void> dispose() async => events.add('dispose-target');
}

class _FakeReconciliationTarget implements AccountReconciliationTargetContext {
  String? requestedFenceUid;
  int rootReads = 0;
  int packReads = 0;
  int membershipReads = 0;

  @override
  String get uid => 'durable-target';

  @override
  bool get isAnonymous => false;

  @override
  Future<void> dispose() async {}

  @override
  FirebaseAccountReconciliationRemote reconciliationRemote({
    required String fenceUid,
  }) {
    requestedFenceUid = fenceUid;
    return FirebaseAccountReconciliationRemote(
      rootReader: (_) async {
        rootReads += 1;
        return const CloudSyncDocument.missing();
      },
      packReader: (_) async {
        packReads += 1;
        return const [];
      },
      membershipReader: (_) async {
        membershipReads += 1;
        return null;
      },
      rootWriter:
          ({
            required uid,
            required data,
            required expectedRevision,
            required operationId,
            required session,
            required sessions,
          }) async => throw StateError('unexpected root write'),
      packWriter:
          ({
            required uid,
            required progresses,
            required expectedRevisions,
            required expectedMembershipRevision,
            required expectedMembershipPackIds,
            required operationId,
            required session,
            required sessions,
          }) async => throw StateError('unexpected pack write'),
      compositeReader: (_) async =>
          throw StateError('unexpected composite read'),
    );
  }
}

class _FakeOperations implements ReplacementAccountOperations {
  _FakeOperations(this.events, this.identity);

  final List<String> events;
  final _FakeIdentity identity;
  int prepareCalls = 0;
  int attachCalls = 0;
  int cleanupCalls = 0;
  String? primaryUidAtPrepare;
  String? primaryUidAtCleanup;
  AccountOperationPhase statusPhase = AccountOperationPhase.completed;
  void Function()? afterAttach;

  @override
  Future<AccountOperationResult> prepare({
    required String targetUid,
    required String requestKey,
  }) async {
    prepareCalls += 1;
    primaryUidAtPrepare = identity.currentUid;
    events.add('prepare');
    return _replacement(AccountOperationPhase.prepared, version: 0);
  }

  @override
  Future<AccountOperationResult> attachTarget({
    required VerifiedTargetContext target,
    required String operationId,
    required int expectedVersion,
  }) async {
    attachCalls += 1;
    events.add('attach');
    afterAttach?.call();
    return _replacement(AccountOperationPhase.targetVerified, version: 1);
  }

  @override
  Future<AccountOperationResult> commitReconciliation({
    required VerifiedTargetContext target,
    required String operationId,
    required int expectedVersion,
  }) async {
    events.add('commit');
    return _replacement(AccountOperationPhase.reconciling, version: 2);
  }

  @override
  Future<AccountOperationResult> startSourceCleanup({
    required VerifiedTargetContext target,
    required String operationId,
    required int expectedVersion,
  }) async {
    cleanupCalls += 1;
    primaryUidAtCleanup = identity.currentUid;
    events.add('start-cleanup');
    return _replacement(AccountOperationPhase.sourceCleanupPending, version: 3);
  }

  @override
  Future<AccountOperationResult> getStatus({
    required VerifiedTargetContext target,
    required String operationId,
  }) async {
    events.add('status:${statusPhase.name}');
    return _replacement(statusPhase, version: 4);
  }
}

class _MemoryJournal
    implements
        ReplacementTransitionJournalStore,
        AccountTransitionJournalStore {
  AccountTransitionJournal? value;

  @override
  Future<void> delete() async => value = null;

  @override
  Future<AccountTransitionJournal?> read() async => value;

  @override
  Future<void> write(AccountTransitionJournal journal) async => value = journal;
}

AccountOperationResult _replacement(
  AccountOperationPhase phase, {
  required int version,
}) {
  return AccountOperationResult(
    operationId: 'replacement-operation-1',
    kind: AccountOperationKind.replacement,
    phase: phase,
    version: version,
    attemptCount: 0,
    retryable: phase != AccountOperationPhase.completed,
  );
}
