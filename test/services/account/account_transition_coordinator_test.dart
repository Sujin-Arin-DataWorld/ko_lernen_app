import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/account_operation_client.dart';
import 'package:ko_lernen_app/services/account/account_reconciliation.dart';
import 'package:ko_lernen_app/services/account/account_transition_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_transition_journal.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/cloud_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('a conflict is inert until the user explicitly confirms', () {
    final harness = _Harness();

    harness.coordinator;

    expect(harness.events, isEmpty);
    expect(harness.sessions.current?.mode, CloudWriteMode.ready);
    expect(harness.journal.value, isNull);
  });

  test(
    'malformed durable replacement state fails closed without effects',
    () async {
      final harness = _Harness();
      harness.journal.value = const AccountTransitionJournal(
        version: AccountTransitionJournal.currentVersion,
        session: CloudWriteSession(
          uid: 'anonymous-source',
          epoch: 1,
          mode: CloudWriteMode.ready,
        ),
        replacementProvider: 'google',
      );

      final result = await harness.coordinator.resume(catalog: const {});

      expect(result.status, AccountTransitionStatus.blocked);
      expect(harness.events, isEmpty);
      expect(harness.sessions.current?.mode, CloudWriteMode.ready);
    },
  );

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
    'source freshness failure preserves the initial journal and quiesced session',
    () async {
      final harness = _Harness()
        ..operations.prepareFailures.add(
          const AccountOperationFailure(
            AccountOperationFailureCode.unavailable,
            retryable: true,
          ),
        );

      await expectLater(
        harness.coordinator.confirm(
          const ExistingAccountLinkConflict(AccountLinkProvider.google),
          catalog: const {},
        ),
        throwsA(isA<AccountOperationFailure>()),
      );

      expect(harness.operations.prepareCalls, 1);
      expect(
        harness.journal.value?.replacementPhase,
        AccountReplacementPhase.targetVerified,
      );
      expect(harness.sessions.current?.mode, CloudWriteMode.quiesced);
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
    'epoch race after prepared journal write blocks target attach',
    () async {
      final harness = _Harness();
      harness.journal.afterWrite = (journal) {
        if (journal.replacementPhase == AccountReplacementPhase.prepared) {
          harness.sessions
            ..transition(CloudWriteMode.blocked)
            ..transition(CloudWriteMode.reconciling);
        }
      };

      final result = await harness.coordinator.confirm(
        const ExistingAccountLinkConflict(AccountLinkProvider.google),
        catalog: const {},
      );

      expect(result.status, AccountTransitionStatus.blocked);
      expect(harness.operations.attachCalls, 0);
      expect(harness.operations.cleanupCalls, 0);
    },
  );

  test('mode race after cleanup journal write blocks cleanup effect', () async {
    final harness = _Harness();
    harness.journal.afterWrite = (journal) {
      if (journal.replacementPhase == AccountReplacementPhase.cleanupStarting &&
          harness.operations.cleanupCalls == 0) {
        harness.sessions.transition(CloudWriteMode.blocked);
      }
    };

    final result = await harness.coordinator.confirm(
      const ExistingAccountLinkConflict(AccountLinkProvider.google),
      catalog: const {},
    );

    expect(result.status, AccountTransitionStatus.blocked);
    expect(harness.operations.cleanupCalls, 0);
    expect(harness.identity.activationCalls, 0);
  });

  test('UID race during polling delay blocks status and activation', () async {
    final harness = _Harness();
    harness.pollDelay = () async {
      harness.identity.currentUid = 'different-source';
      harness.sessions.acquire('different-source');
    };

    final result = await harness.coordinator.confirm(
      const ExistingAccountLinkConflict(AccountLinkProvider.google),
      catalog: const {},
    );

    expect(result.status, AccountTransitionStatus.blocked);
    expect(harness.operations.statusCalls, 0);
    expect(harness.identity.activationCalls, 0);
  });

  test('epoch race after status blocks dispose and activation', () async {
    final harness = _Harness();
    harness.operations.afterStatus = () {
      harness.sessions
        ..transition(CloudWriteMode.blocked)
        ..transition(CloudWriteMode.cleanupPending);
    };

    final result = await harness.coordinator.confirm(
      const ExistingAccountLinkConflict(AccountLinkProvider.google),
      catalog: const {},
    );

    expect(result.status, AccountTransitionStatus.blocked);
    expect(harness.identity.activationCalls, 0);
    expect(
      harness.events.where((event) => event == 'dispose-target'),
      hasLength(1),
    );
  });

  test('mode race while disposing target blocks primary activation', () async {
    final harness = _Harness();
    harness.verifier.onDispose = () {
      harness.sessions.transition(CloudWriteMode.blocked);
    };

    final result = await harness.coordinator.confirm(
      const ExistingAccountLinkConflict(AccountLinkProvider.google),
      catalog: const {},
    );

    expect(result.status, AccountTransitionStatus.blocked);
    expect(harness.identity.activationCalls, 0);
    expect(
      harness.journal.value?.replacementPhase,
      AccountReplacementPhase.activationPending,
    );
  });

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
      expect(cancellable.operations.cancelCalls, 1);
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
      expect(pending.operations.cancelCalls, 0);
      expect(pending.journal.value, same(journalBeforeCancel));
      expect(pending.sessions.current?.mode, CloudWriteMode.cleanupPending);
      expect(
        pending.journal.value?.reconciliationCheckpoint,
        ReconciliationCheckpoint.completed,
      );
    },
  );

  test(
    'remote cancel failure preserves the exact journal and quiesced source',
    () async {
      final harness = _Harness()
        ..reconciliationResult = const AccountReconciliationResult(
          AccountReconciliationStatus.unavailable,
        )
        ..operations.cancelFailures.add(
          const AccountOperationFailure(
            AccountOperationFailureCode.unavailable,
            retryable: true,
          ),
        );
      await harness.coordinator.confirm(
        const ExistingAccountLinkConflict(AccountLinkProvider.google),
        catalog: const {},
      );
      final durable = harness.journal.value;

      expect(await harness.coordinator.cancel(), isFalse);
      expect(harness.operations.cancelCalls, 1);
      expect(harness.journal.value, same(durable));
      expect(harness.sessions.current?.mode, CloudWriteMode.reconciling);
    },
  );

  test(
    'cancel resolves an ambiguous prepare before deleting the initial journal',
    () async {
      final harness = _Harness();
      final quiesced = harness.sessions.transition(CloudWriteMode.quiesced);
      final journal = AccountTransitionJournal.fromSession(
        quiesced,
        replacementProvider: 'google',
        replacementTargetUid: 'durable-target',
        replacementRequestKey: 'request-key-1',
        replacementPhase: AccountReplacementPhase.targetVerified,
      );
      harness.journal.value = journal;

      expect(await harness.coordinator.cancel(), isTrue);
      expect(harness.operations.prepareCalls, 1);
      expect(harness.operations.cancelCalls, 1);
      expect(harness.journal.value, isNull);
      expect(harness.sessions.current?.mode, CloudWriteMode.ready);
    },
  );

  test(
    'source session race after remote cancel preserves the exact journal',
    () async {
      final harness = _Harness()
        ..reconciliationResult = const AccountReconciliationResult(
          AccountReconciliationStatus.unavailable,
        );
      await harness.coordinator.confirm(
        const ExistingAccountLinkConflict(AccountLinkProvider.google),
        catalog: const {},
      );
      final durable = harness.journal.value;
      harness.operations.afterCancel = () {
        harness.sessions
          ..transition(CloudWriteMode.blocked)
          ..transition(CloudWriteMode.reconciling);
      };

      expect(await harness.coordinator.cancel(), isFalse);
      expect(harness.operations.cancelCalls, 1);
      expect(harness.journal.value, same(durable));
      expect(harness.journal.deleteCalls, 0);
      expect(harness.sessions.current?.mode, CloudWriteMode.reconciling);
    },
  );

  test('unconfirmed cancellation result preserves the exact journal', () async {
    final harness = _Harness()
      ..reconciliationResult = const AccountReconciliationResult(
        AccountReconciliationStatus.unavailable,
      );
    await harness.coordinator.confirm(
      const ExistingAccountLinkConflict(AccountLinkProvider.google),
      catalog: const {},
    );
    final durable = harness.journal.value;
    harness.operations.cancelResults.add(
      _replacement(AccountOperationPhase.cancelled, version: 99),
    );

    expect(await harness.coordinator.cancel(), isFalse);
    expect(harness.journal.value, same(durable));
    expect(harness.journal.deleteCalls, 0);
    expect(harness.sessions.current?.mode, CloudWriteMode.reconciling);
  });

  test(
    'first journal failure restores only the exact quiesced source',
    () async {
      final harness = _Harness()..journal.failWriteAt = 1;

      final result = await harness.coordinator.confirm(
        const ExistingAccountLinkConflict(AccountLinkProvider.google),
        catalog: const {},
      );

      expect(result.status, AccountTransitionStatus.blocked);
      expect(harness.sessions.current?.uid, 'anonymous-source');
      expect(harness.sessions.current?.mode, CloudWriteMode.ready);
      expect(harness.operations.prepareCalls, 0);
    },
  );

  test(
    'partially persisted first journal is deleted before rollback',
    () async {
      final harness = _Harness()..journal.failAfterPersistAt = 1;

      final result = await harness.coordinator.confirm(
        const ExistingAccountLinkConflict(AccountLinkProvider.google),
        catalog: const {},
      );

      expect(result.status, AccountTransitionStatus.blocked);
      expect(harness.journal.value, isNull);
      expect(harness.journal.deleteCalls, 1);
      expect(harness.sessions.current?.mode, CloudWriteMode.ready);
      expect(harness.operations.prepareCalls, 0);
    },
  );

  test(
    'cancel session race neither deletes nor transitions a replacement',
    () async {
      final harness = _Harness()
        ..reconciliationResult = const AccountReconciliationResult(
          AccountReconciliationStatus.unavailable,
        );
      await harness.coordinator.confirm(
        const ExistingAccountLinkConflict(AccountLinkProvider.google),
        catalog: const {},
      );
      final durable = harness.journal.value;
      harness.journal.beforeConditionalDelete = () {
        harness.sessions
          ..transition(CloudWriteMode.blocked)
          ..transition(CloudWriteMode.reconciling);
      };

      expect(await harness.coordinator.cancel(), isFalse);
      expect(harness.journal.value, same(durable));
      expect(harness.journal.deleteCalls, 0);
      expect(harness.sessions.current?.mode, CloudWriteMode.reconciling);
    },
  );

  test('cancel compensation never overwrites a newer journal', () async {
    final harness = _Harness()
      ..reconciliationResult = const AccountReconciliationResult(
        AccountReconciliationStatus.unavailable,
      );
    await harness.coordinator.confirm(
      const ExistingAccountLinkConflict(AccountLinkProvider.google),
      catalog: const {},
    );
    final oldJournal = harness.journal.value!;
    late AccountTransitionJournal newerJournal;
    harness.journal.afterConditionalDelete = () {
      harness.sessions
        ..transition(CloudWriteMode.blocked)
        ..transition(CloudWriteMode.reconciling);
      final newerSession = harness.sessions.current;
      expect(newerSession, isNotNull);
      newerJournal = oldJournal.copyWith(session: newerSession);
      harness.journal.value = newerJournal;
    };

    expect(await harness.coordinator.cancel(), isFalse);
    expect(harness.journal.value, same(newerJournal));
    expect(harness.journal.deleteCalls, 1);
  });

  test('cancel compensation restores old journal only while absent', () async {
    final harness = _Harness()
      ..reconciliationResult = const AccountReconciliationResult(
        AccountReconciliationStatus.unavailable,
      );
    await harness.coordinator.confirm(
      const ExistingAccountLinkConflict(AccountLinkProvider.google),
      catalog: const {},
    );
    final oldJournal = harness.journal.value!;
    harness.journal.afterConditionalDelete = () {
      harness.sessions
        ..transition(CloudWriteMode.blocked)
        ..transition(CloudWriteMode.reconciling);
    };

    expect(await harness.coordinator.cancel(), isFalse);
    expect(harness.journal.value, same(oldJournal));
    expect(harness.journal.deleteCalls, 1);
  });

  test('successful cancel rejects a delayed stale phase CAS write', () async {
    final harness = _Harness()
      ..reconciliationResult = const AccountReconciliationResult(
        AccountReconciliationStatus.unavailable,
      );
    await harness.coordinator.confirm(
      const ExistingAccountLinkConflict(AccountLinkProvider.google),
      catalog: const {},
    );
    final oldJournal = harness.journal.value!;
    final delayed = Completer<void>();
    final phaseWrite = () async {
      await delayed.future;
      return harness.journal.writeIfCurrent(
        expected: oldJournal,
        next: oldJournal.copyWith(replacementOperationVersion: 99),
        isCurrent: () => harness.sessions.current == oldJournal.session,
      );
    }();

    expect(await harness.coordinator.cancel(), isTrue);
    expect(harness.sessions.current?.mode, CloudWriteMode.ready);
    delayed.complete();

    expect(await phaseWrite, isFalse);
    expect(harness.journal.value, isNull);
    expect(harness.sessions.current?.mode, CloudWriteMode.ready);
  });

  test(
    'newer phase CAS wins before cancel delete without entering ready',
    () async {
      final harness = _Harness()
        ..reconciliationResult = const AccountReconciliationResult(
          AccountReconciliationStatus.unavailable,
        );
      await harness.coordinator.confirm(
        const ExistingAccountLinkConflict(AccountLinkProvider.google),
        catalog: const {},
      );
      final oldJournal = harness.journal.value!;
      final newerJournal = oldJournal.copyWith(replacementOperationVersion: 99);
      harness.journal.beforeConditionalDelete = () {
        harness.journal.value = newerJournal;
      };

      expect(await harness.coordinator.cancel(), isFalse);
      expect(harness.journal.value, same(newerJournal));
      expect(harness.sessions.current?.mode, CloudWriteMode.reconciling);
    },
  );

  test(
    'pre-delivery cleanup failure proven reconciling remains cancellable',
    () async {
      final harness = _Harness()
        ..operations.cleanupFailures.add(
          const AccountOperationFailure(
            AccountOperationFailureCode.unavailable,
            retryable: true,
          ),
        )
        ..operations.statusResults.add(
          _replacement(AccountOperationPhase.reconciling, version: 2),
        );

      final result = await harness.coordinator.confirm(
        const ExistingAccountLinkConflict(AccountLinkProvider.google),
        catalog: const {},
      );

      expect(result.status, AccountTransitionStatus.cleanupPending);
      expect(harness.operations.cleanupCalls, 1);
      expect(harness.operations.statusCalls, 1);
      expect(
        harness.journal.value?.replacementPhase,
        AccountReplacementPhase.reconciled,
      );
      expect(harness.sessions.current?.mode, CloudWriteMode.reconciling);
      expect(await harness.coordinator.cancel(), isTrue);
    },
  );

  test(
    'ambiguous accepted cleanup response becomes non-cancellable pending',
    () async {
      final harness = _Harness()
        ..operations.cleanupFailures.add(
          const AccountOperationFailure(
            AccountOperationFailureCode.unavailable,
            retryable: true,
          ),
        )
        ..operations.statusResults.addAll([
          _replacement(AccountOperationPhase.sourceCleanupPending, version: 3),
          _replacement(AccountOperationPhase.sourceCleanupPending, version: 3),
        ]);

      final result = await harness.coordinator.confirm(
        const ExistingAccountLinkConflict(AccountLinkProvider.google),
        catalog: const {},
      );

      expect(result.status, AccountTransitionStatus.cleanupPending);
      expect(harness.operations.cleanupCalls, 1);
      expect(
        harness.journal.value?.replacementPhase,
        AccountReplacementPhase.cleanupPending,
      );
      expect(await harness.coordinator.cancel(), isFalse);
    },
  );

  test(
    'cleanupStarting rechecks reconciling then idempotently retries',
    () async {
      final journal = _cleanupJournal(
        phase: AccountReplacementPhase.cleanupStarting,
        operationVersion: 2,
      );
      final harness = _Harness(initialJournal: journal)
        ..operations.statusResults.addAll([
          _replacement(AccountOperationPhase.reconciling, version: 2),
          _replacement(AccountOperationPhase.sourceCleanupPending, version: 3),
        ]);

      final result = await harness.coordinator.resume(catalog: const {});

      expect(result.status, AccountTransitionStatus.cleanupPending);
      expect(harness.operations.cleanupCalls, 1);
      expect(
        harness.journal.value?.replacementPhase,
        AccountReplacementPhase.cleanupPending,
      );
      expect(harness.journal.value?.replacementOperationVersion, 3);
    },
  );

  test(
    'cleanupStarting accepted status never reissues destructive cleanup',
    () async {
      final journal = _cleanupJournal(
        phase: AccountReplacementPhase.cleanupStarting,
        operationVersion: 2,
      );
      final harness = _Harness(initialJournal: journal)
        ..operations.statusResults.addAll([
          _replacement(AccountOperationPhase.sourceCleanupPending, version: 3),
          _replacement(AccountOperationPhase.sourceCleanupPending, version: 3),
        ]);

      final result = await harness.coordinator.resume(catalog: const {});

      expect(result.status, AccountTransitionStatus.cleanupPending);
      expect(harness.operations.cleanupCalls, 0);
      expect(
        harness.journal.value?.replacementPhase,
        AccountReplacementPhase.cleanupPending,
      );
      expect(await harness.coordinator.cancel(), isFalse);
    },
  );

  for (final terminal in <bool>[false, true]) {
    test(
      'cold restart with deleted source ${terminal ? "activates after terminal status" : "stays pending"}',
      () async {
        final journal = _cleanupJournal(
          phase: AccountReplacementPhase.cleanupPending,
        );
        final harness =
            _Harness(
                sourceUid: null,
                initialJournal: journal,
                restoreInitialSession: false,
              )
              ..operations.statusPhase = terminal
                  ? AccountOperationPhase.completed
                  : AccountOperationPhase.sourceCleanupPending;

        final result = await harness.coordinator.resume(catalog: const {});

        expect(
          result.status,
          terminal
              ? AccountTransitionStatus.completed
              : AccountTransitionStatus.cleanupPending,
        );
        expect(harness.operations.statusCalls, 1);
        expect(harness.identity.activationCalls, terminal ? 1 : 0);
        if (!terminal) {
          expect(harness.journal.value, same(journal));
        }
      },
    );
  }

  test('cold recovery rejects the wrong freshly verified target', () async {
    final journal = _cleanupJournal(
      phase: AccountReplacementPhase.cleanupPending,
    );
    final harness = _Harness(
      sourceUid: null,
      initialJournal: journal,
      restoreInitialSession: false,
    )..verifier.targetUid = 'wrong-target';

    final result = await harness.coordinator.resume(catalog: const {});

    expect(result.status, AccountTransitionStatus.targetVerificationFailed);
    expect(harness.operations.statusCalls, 0);
    expect(harness.identity.activationCalls, 0);
    expect(harness.journal.value, same(journal));
  });

  test(
    'activation failure persists activationPending and resumes safely',
    () async {
      final journal = _cleanupJournal(
        phase: AccountReplacementPhase.cleanupPending,
      );
      final harness = _Harness(
        sourceUid: null,
        initialJournal: journal,
        restoreInitialSession: false,
      )..identity.activationFailure = StateError('provider unavailable');

      final first = await harness.coordinator.resume(catalog: const {});

      expect(first.status, AccountTransitionStatus.activationPending);
      expect(
        harness.journal.value?.replacementPhase,
        AccountReplacementPhase.activationPending,
      );
      expect(harness.identity.activationCalls, 1);

      harness.identity.activationFailure = null;
      final second = await harness.coordinator.resume(catalog: const {});

      expect(second.status, AccountTransitionStatus.completed);
      expect(harness.identity.activationCalls, 2);
      expect(harness.journal.value, isNull);
    },
  );

  test(
    'cold restart after primary sign-in completes the exact terminal journal',
    () async {
      final journal = _cleanupJournal(
        phase: AccountReplacementPhase.activationPending,
      );
      final harness = _Harness(
        sourceUid: 'durable-target',
        initialJournal: journal,
        restoreInitialSession: false,
      );
      final targetSession = harness.sessions.acquire('durable-target');

      final result = await harness.coordinator.resume(catalog: const {});

      expect(result.status, AccountTransitionStatus.completed);
      expect(harness.operations.statusCalls, 1);
      expect(harness.identity.activationCalls, 0);
      expect(harness.journal.value, isNull);
      expect(harness.sessions.current, targetSession);
    },
  );

  test(
    'preference journal deletion is exact and conditionally fenced',
    () async {
      SharedPreferences.setMockInitialValues(const {});
      final preferences = await SharedPreferences.getInstance();
      final store = SharedPreferencesReplacementTransitionJournalStore(
        preferences,
      );
      final journal = _cleanupJournal(
        phase: AccountReplacementPhase.activationPending,
      );
      await store.write(journal);
      final different = journal.copyWith(replacementOperationVersion: 5);

      expect(
        await store.writeIfCurrent(
          expected: journal,
          next: different,
          isCurrent: () => false,
        ),
        isFalse,
      );
      expect((await store.read())?.replacementOperationVersion, 4);
      expect(
        await store.writeIfCurrent(
          expected: journal,
          next: different,
          isCurrent: () => true,
        ),
        isTrue,
      );
      expect(
        await store.writeIfCurrent(
          expected: different,
          next: journal,
          isCurrent: () => true,
        ),
        isTrue,
      );
      expect(
        await store.deleteIfCurrent(expected: different, isCurrent: () => true),
        isFalse,
      );
      expect(await store.read(), isNotNull);
      expect(
        await store.deleteIfCurrent(expected: journal, isCurrent: () => false),
        isFalse,
      );
      expect(await store.read(), isNotNull);
      expect(
        await store.deleteIfCurrent(expected: journal, isCurrent: () => true),
        isTrue,
      );
      expect(await store.read(), isNull);

      final reconciliationStore =
          SharedPreferencesAccountTransitionJournalStore(preferences);
      await reconciliationStore.write(different);
      expect(
        await store.restoreIfAbsent(expected: journal, isCurrent: () => true),
        isFalse,
      );
      expect((await store.read())?.replacementOperationVersion, 5);
      expect(
        await store.deleteIfCurrent(expected: different, isCurrent: () => true),
        isTrue,
      );
      expect(
        await store.restoreIfAbsent(expected: journal, isCurrent: () => true),
        isTrue,
      );
      expect((await store.read())?.replacementOperationVersion, 4);
    },
  );
}

AccountTransitionJournal _cleanupJournal({
  required AccountReplacementPhase phase,
  int operationVersion = 4,
}) {
  return AccountTransitionJournal.fromSession(
    const CloudWriteSession(
      uid: 'anonymous-source',
      epoch: 8,
      mode: CloudWriteMode.cleanupPending,
    ),
    replacementProvider: 'google',
    replacementTargetUid: 'durable-target',
    replacementRequestKey: 'request-1',
    replacementPhase: phase,
    replacementOperationId: 'replacement-operation-1',
    replacementOperationVersion: operationVersion,
    reconciliationOperationId: 'replacement-operation-1',
    reconciliationCheckpoint: ReconciliationCheckpoint.completed,
  );
}

class _Harness {
  _Harness({
    this.sourceUid = 'anonymous-source',
    AccountTransitionJournal? initialJournal,
    CloudWriteSession? initialSession,
    bool restoreInitialSession = true,
  }) {
    identity = _FakeIdentity(sourceUid, events);
    verifier = _FakeVerifier(events);
    operations = _FakeOperations(events, identity);
    journal.value = initialJournal;
    final restoredSession = initialSession ?? initialJournal?.session;
    if (!restoreInitialSession) {
      return;
    }
    if (restoredSession == null) {
      if (sourceUid == null) return;
      sessions.acquire(sourceUid!);
    } else {
      sessions.resume(restoredSession, expectedUid: restoredSession.uid);
    }
  }

  final String? sourceUid;
  final events = <String>[];
  final sessions = CloudWriteSessionController();
  final journal = _MemoryJournal();
  late final _FakeIdentity identity;
  late final _FakeVerifier verifier;
  late final _FakeOperations operations;
  AccountReconciliationResult reconciliationResult =
      const AccountReconciliationResult(AccountReconciliationStatus.completed);
  int reconciliationCalls = 0;
  Future<void> Function() pollDelay = _noDelay;

  static Future<void> _noDelay() async {}

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
            final expected = journal.value!;
            final written = await journal.writeIfCurrent(
              expected: expected,
              next: expected.copyWith(
                reconciliationCheckpoint: ReconciliationCheckpoint.completed,
              ),
              isCurrent: () => sessions.current == session,
            );
            expect(written, isTrue);
          }
          return reconciliationResult;
        },
    maxStatusPolls: 1,
    pollDelay: pollDelay,
  );
}

class _FakeIdentity implements AccountTransitionIdentity {
  _FakeIdentity(this.currentUid, this.events);

  @override
  String? currentUid;
  final List<String> events;
  int activationCalls = 0;
  Object? activationFailure;

  @override
  bool get currentIsAnonymous =>
      currentUid == 'anonymous-source' || currentUid == 'different-source';

  @override
  Future<void> activateTarget(
    AccountLinkProvider provider, {
    required String expectedTargetUid,
    required CloudWriteSession expectedSourceSession,
    required CloudWriteSessionController sessions,
    required bool allowMissingSource,
  }) async {
    activationCalls += 1;
    events.add('activate:${provider.name}');
    if (activationFailure != null) throw activationFailure!;
    expect(expectedTargetUid, 'durable-target');
    currentUid = expectedTargetUid;
  }
}

class _FakeVerifier implements IsolatedTargetVerifier {
  _FakeVerifier(this.events);

  final List<String> events;
  Object? failure;
  String targetUid = 'durable-target';
  void Function()? onDispose;

  @override
  Future<VerifiedTargetContext> verify(AccountLinkProvider provider) async {
    events.add('verify:${provider.name}');
    if (failure != null) throw failure!;
    return _FakeTarget(events, targetUid, onDispose);
  }
}

class _FakeTarget implements VerifiedTargetContext {
  _FakeTarget(this.events, this.targetUid, this.onDispose);

  final List<String> events;
  final String targetUid;
  final void Function()? onDispose;

  @override
  String get uid => targetUid;

  @override
  bool get isAnonymous => false;

  @override
  Future<void> dispose() async {
    events.add('dispose-target');
    onDispose?.call();
  }
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
  int cancelCalls = 0;
  int statusCalls = 0;
  String? primaryUidAtPrepare;
  String? primaryUidAtCleanup;
  AccountOperationPhase statusPhase = AccountOperationPhase.completed;
  final List<AccountOperationResult> statusResults = [];
  final List<Object> cleanupFailures = [];
  final List<Object> cancelFailures = [];
  final List<Object> prepareFailures = [];
  final List<AccountOperationResult> cancelResults = [];
  void Function()? afterAttach;
  void Function()? afterCancel;
  void Function()? afterStatus;

  @override
  Future<AccountOperationResult> prepare({
    required CloudWriteSession sourceSession,
    required String targetUid,
    required String requestKey,
  }) async {
    prepareCalls += 1;
    primaryUidAtPrepare = identity.currentUid;
    events.add('prepare');
    if (prepareFailures.isNotEmpty) throw prepareFailures.removeAt(0);
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
    if (cleanupFailures.isNotEmpty) throw cleanupFailures.removeAt(0);
    return _replacement(AccountOperationPhase.sourceCleanupPending, version: 3);
  }

  @override
  Future<AccountOperationResult> cancel({
    required CloudWriteSession sourceSession,
    required String operationId,
    required int expectedVersion,
  }) async {
    cancelCalls += 1;
    events.add('cancel');
    if (cancelFailures.isNotEmpty) throw cancelFailures.removeAt(0);
    final result = cancelResults.isEmpty
        ? _replacement(
            AccountOperationPhase.cancelled,
            version: expectedVersion + 1,
          )
        : cancelResults.removeAt(0);
    afterCancel?.call();
    return result;
  }

  @override
  Future<AccountOperationResult> getStatus({
    required VerifiedTargetContext target,
    required String operationId,
  }) async {
    statusCalls += 1;
    final result = statusResults.isEmpty
        ? _replacement(statusPhase, version: 4)
        : statusResults.removeAt(0);
    events.add('status:${result.phase.name}');
    afterStatus?.call();
    return result;
  }
}

class _MemoryJournal
    implements
        ReplacementTransitionJournalStore,
        AccountTransitionJournalStore {
  AccountTransitionJournal? value;
  int writeCalls = 0;
  int deleteCalls = 0;
  int? failWriteAt;
  int? failAfterPersistAt;
  void Function()? beforeConditionalDelete;
  void Function()? afterConditionalDelete;
  void Function(AccountTransitionJournal journal)? afterWrite;

  @override
  Future<bool> deleteIfCurrent({
    required AccountTransitionJournal expected,
    required bool Function() isCurrent,
  }) async {
    beforeConditionalDelete?.call();
    if (!isCurrent() || !identical(value, expected)) return false;
    deleteCalls += 1;
    value = null;
    afterConditionalDelete?.call();
    return true;
  }

  @override
  Future<AccountTransitionJournal?> read() async => value;

  @override
  Future<bool> writeIfCurrent({
    required AccountTransitionJournal expected,
    required AccountTransitionJournal next,
    required bool Function() isCurrent,
  }) async {
    if (!identical(value, expected) || !isCurrent()) return false;
    value = next;
    afterWrite?.call(next);
    return true;
  }

  @override
  Future<bool> restoreIfAbsent({
    required AccountTransitionJournal expected,
    required bool Function() isCurrent,
  }) async {
    if (value != null) return identical(value, expected);
    if (!isCurrent()) return false;
    value = expected;
    return true;
  }

  @override
  Future<void> write(AccountTransitionJournal journal) async {
    writeCalls += 1;
    if (writeCalls == failWriteAt) {
      throw StateError('journal write failed');
    }
    value = journal;
    if (writeCalls == failAfterPersistAt) {
      throw StateError('journal write failed after persistence');
    }
    afterWrite?.call(journal);
  }
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
