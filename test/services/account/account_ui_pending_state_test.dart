import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/account/account_operation_client.dart';
import 'package:ko_lernen_app/services/account/account_transition_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_transition_journal.dart';
import 'package:ko_lernen_app/services/account/account_ui_operations.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'persisted replacement is surfaced by a fresh production reader',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      await SharedPreferencesReplacementTransitionJournalStore(
        preferences,
      ).write(
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
        ),
      );

      const operations = ProductionAccountUiOperations();
      final state = await operations.refreshPendingState();

      expect(state, AccountUiPendingState.replacementCancellable);
      expect(operations.pendingState.value, state);
    },
  );

  for (final pending in <String>['replacement', 'activation', 'deletion']) {
    test('persisted $pending blocks provider OAuth before linker', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      if (pending == 'deletion') {
        await preferences.setString(
          AuthService.accountDeletionCheckpointPreferenceKey,
          jsonEncode(_completedDeletion().toJson()),
        );
      } else {
        await SharedPreferencesReplacementTransitionJournalStore(
          preferences,
        ).write(
          pending == 'activation'
              ? _activationPendingReplacement()
              : _cancellableReplacement(),
        );
      }
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
    });
  }
}

AccountTransitionJournal _cancellableReplacement() {
  return AccountTransitionJournal.fromSession(
    const CloudWriteSession(
      uid: 'anonymous-source',
      epoch: 3,
      mode: CloudWriteMode.quiesced,
    ),
    replacementProvider: 'google',
    replacementTargetUid: 'durable-target',
    replacementRequestKey: 'replacement-request-1',
    replacementPhase: AccountReplacementPhase.targetVerified,
  );
}

AccountTransitionJournal _activationPendingReplacement() {
  return AccountTransitionJournal.fromSession(
    const CloudWriteSession(
      uid: 'anonymous-source',
      epoch: 4,
      mode: CloudWriteMode.cleanupPending,
    ),
    replacementProvider: 'google',
    replacementTargetUid: 'durable-target',
    replacementRequestKey: 'replacement-request-2',
    replacementPhase: AccountReplacementPhase.activationPending,
    replacementOperationId: 'replacement-operation-2',
    replacementOperationVersion: 5,
    reconciliationOperationId: 'replacement-operation-2',
    reconciliationCheckpoint: ReconciliationCheckpoint.completed,
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
