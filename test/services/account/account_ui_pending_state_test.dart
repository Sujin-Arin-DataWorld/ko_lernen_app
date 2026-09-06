import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/account/account_operation_client.dart';
import 'package:ko_lernen_app/services/account/account_transition_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_transition_journal.dart';
import 'package:ko_lernen_app/services/account/account_ui_operations.dart';
import 'package:ko_lernen_app/services/account/cloud_backup_deletion.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a legacy replacement journal is ignored by a fresh production reader',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        AccountTransitionJournal.storageKey,
        jsonEncode(
          AccountTransitionJournal.fromSession(
            const CloudWriteSession(
              uid: 'anonymous-source',
              epoch: 3,
              mode: CloudWriteMode.quiesced,
            ),
            replacementProvider: 'google',
            replacementTargetUid: 'durable-target',
            replacementRequestKey: 'replacement-request-1',
            replacementPhase: AccountReplacementPhase.targetVerified,
          ).toJson(),
        ),
      );

      const operations = ProductionAccountUiOperations();
      final state = await operations.refreshPendingState();

      expect(state, AccountUiPendingState.none);
      expect(operations.pendingState.value, state);
    },
  );

  // T5: deletion accepts and finishes synchronously, so a non-completed
  // deletion journal (request never reached the server, or a legacy
  // mid-flight crash) no longer locks any account action — it is not even
  // reported as pending. Only a locally-completed checkpoint (server data
  // cleanup still running in the background) fences link/delete via
  // `deletionLocalCleanup`, so the Settings panel can offer a local-cleanup
  // retry.
  for (final phase in <AccountOperationPhase>[
    AccountOperationPhase.deletionRequested,
    AccountOperationPhase.blocked,
  ]) {
    test(
      'a non-completed deletion journal (${phase.name}) is reported as none',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(
          AuthService.accountDeletionCheckpointPreferenceKey,
          jsonEncode(_nonCompletedDeletion(phase).toJson()),
        );

        const operations = ProductionAccountUiOperations();
        final state = await operations.refreshPendingState();

        expect(state, AccountUiPendingState.none);
        expect(operations.pendingState.value, state);
      },
    );
  }

  test(
    'a locally-completed deletion checkpoint reports deletionLocalCleanup',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        AuthService.accountDeletionCheckpointPreferenceKey,
        jsonEncode(_completedDeletion().toJson()),
      );

      const operations = ProductionAccountUiOperations();

      expect(
        await operations.refreshPendingState(),
        AccountUiPendingState.deletionLocalCleanup,
      );
    },
  );

  test(
    'a pending cloud-backup-deletion journal alone is reported as none',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        CloudBackupDeletionJournal.storageKey,
        jsonEncode(
          CloudBackupDeletionJournal.pending(
            session: const CloudWriteSession(
              uid: 'durable-source',
              epoch: 6,
              mode: CloudWriteMode.cleanupPending,
            ),
            requestKey: 'Z' * 43,
          ).toJson(),
        ),
      );

      const operations = ProductionAccountUiOperations();

      // The cloud-backup-deletion journal only fences cloud-data operations
      // (see cloud_backup_deletion_test.dart / cloud_backup_deletion_service_
      // admission_test.dart) — the Settings panel shows its own resume card
      // via `cloudDeletionState`, so it must never lock link/delete too.
      expect(
        await operations.refreshPendingState(),
        AccountUiPendingState.none,
      );
    },
  );

  test(
    'a late failed durable read cannot overwrite a newer clear admission',
    () async {
      final lateResult = Completer<AccountUiPendingState>();
      final older = ProductionAccountUiOperations(
        pendingStateReader: () => lateResult.future,
      );
      final newer = ProductionAccountUiOperations(
        pendingStateReader: () async => AccountUiPendingState.none,
      );

      final olderRead = older.refreshPendingState();
      expect(await newer.refreshPendingState(), AccountUiPendingState.none);
      expect(newer.pendingState.value, AccountUiPendingState.none);

      lateResult.completeError(StateError('stale durable read failed'));
      expect(await olderRead, AccountUiPendingState.blocked);
      expect(newer.pendingState.value, AccountUiPendingState.none);
    },
  );

  test(
    'a late clear durable read cannot unlock a newer blocked admission',
    () async {
      final lateResult = Completer<AccountUiPendingState>();
      final older = ProductionAccountUiOperations(
        pendingStateReader: () => lateResult.future,
      );
      final newer = ProductionAccountUiOperations(
        pendingStateReader: () async => AccountUiPendingState.blocked,
      );

      final olderRead = older.refreshPendingState();
      expect(await newer.refreshPendingState(), AccountUiPendingState.blocked);
      expect(newer.pendingState.value, AccountUiPendingState.blocked);

      lateResult.complete(AccountUiPendingState.none);
      expect(await olderRead, AccountUiPendingState.blocked);
      expect(newer.pendingState.value, AccountUiPendingState.blocked);
    },
  );

  test(
    'a completed deletion checkpoint still blocks provider OAuth before linker',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        AuthService.accountDeletionCheckpointPreferenceKey,
        jsonEncode(_completedDeletion().toJson()),
      );
      var providerCalls = 0;
      final operations = ProductionAccountUiOperations(
        providerLinker: (provider) async {
          providerCalls += 1;
          return const AccountUiLinkCompleted();
        },
      );

      final result = await operations.link(AccountLinkProvider.google);

      expect(result, isA<AccountUiLinkBlocked>());
      expect(providerCalls, 0);
      expect(operations.pendingState.value, isNot(AccountUiPendingState.none));
    },
  );

  test(
    'a pending cloud-backup-deletion journal no longer blocks provider OAuth',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        CloudBackupDeletionJournal.storageKey,
        jsonEncode(
          CloudBackupDeletionJournal.pending(
            session: const CloudWriteSession(
              uid: 'durable-source',
              epoch: 6,
              mode: CloudWriteMode.cleanupPending,
            ),
            requestKey: 'Z' * 43,
          ).toJson(),
        ),
      );
      var providerCalls = 0;
      final operations = ProductionAccountUiOperations(
        providerLinker: (provider) async {
          providerCalls += 1;
          return const AccountUiLinkCompleted();
        },
      );

      final result = await operations.link(AccountLinkProvider.google);

      expect(result, isA<AccountUiLinkCompleted>());
      expect(providerCalls, 1);
      expect(operations.pendingState.value, AccountUiPendingState.none);
    },
  );
}

AccountDeletionJournal _completedDeletion() {
  return AccountDeletionJournal(
    version: AccountDeletionJournal.currentVersion,
    session: const CloudWriteSession(
      uid: 'anonymous-source',
      epoch: 5,
      mode: CloudWriteMode.cleanupPending,
    ),
    requestKey: 'deletion-request-1',
    operation: const AccountOperationResult(
      operationId: 'deletion-operation-1',
      kind: AccountOperationKind.deletion,
      phase: AccountOperationPhase.completed,
      version: 3,
      attemptCount: 1,
      retryable: false,
    ),
  );
}

AccountDeletionJournal _nonCompletedDeletion(AccountOperationPhase phase) {
  if (phase == AccountOperationPhase.blocked) {
    return AccountDeletionJournal(
      version: AccountDeletionJournal.currentVersion,
      session: const CloudWriteSession(
        uid: 'anonymous-source',
        epoch: 5,
        mode: CloudWriteMode.quiesced,
      ),
      requestKey: 'deletion-request-blocked',
      operation: const AccountOperationResult(
        operationId: 'deletion-operation-blocked',
        kind: AccountOperationKind.deletion,
        phase: AccountOperationPhase.blocked,
        version: 1,
        attemptCount: 1,
        retryable: false,
        blockedReason: AccountOperationBlockedReason.operationBlocked,
      ),
    );
  }
  return AccountDeletionJournal(
    version: AccountDeletionJournal.currentVersion,
    session: const CloudWriteSession(
      uid: 'anonymous-source',
      epoch: 5,
      mode: CloudWriteMode.quiesced,
    ),
    requestKey: 'deletion-request-pending',
    operation: AccountOperationResult(
      operationId: 'deletion-operation-1',
      kind: AccountOperationKind.deletion,
      phase: phase,
      version: 1,
      attemptCount: 1,
      retryable: true,
    ),
  );
}
