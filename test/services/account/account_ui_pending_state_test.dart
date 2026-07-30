import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/services/account/account_transition_coordinator.dart';
import 'package:ko_lernen_app/services/account/account_transition_journal.dart';
import 'package:ko_lernen_app/services/account/account_ui_operations.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';

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
}
