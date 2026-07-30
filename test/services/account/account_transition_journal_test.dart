import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/account_transition_journal.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';

void main() {
  test('resumes a versioned journal without retaining secret fields', () {
    final resumed = AccountTransitionJournal.fromJson({
      'version': 1,
      'uid': 'uid-a',
      'epoch': 7,
      'mode': 'cleanupPending',
      'idToken': 'must-not-persist',
      'accessToken': 'must-not-persist',
      'authorizationCode': 'must-not-persist',
      'proofToken': 'must-not-persist',
      'reauthenticationMaterial': 'must-not-persist',
    });

    expect(resumed.version, 1);
    expect(
      resumed.session,
      const CloudWriteSession(
        uid: 'uid-a',
        epoch: 7,
        mode: CloudWriteMode.cleanupPending,
      ),
    );
    expect(resumed.toJson(), {
      'version': 1,
      'uid': 'uid-a',
      'epoch': 7,
      'mode': 'cleanupPending',
    });
  });

  test('rejects an unsupported journal version', () {
    expect(
      () => AccountTransitionJournal.fromJson({
        'version': 2,
        'uid': 'uid-a',
        'epoch': 7,
        'mode': 'ready',
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects a journal with a nonpositive epoch', () {
    expect(
      () => AccountTransitionJournal.fromJson({
        'version': 1,
        'uid': 'uid-a',
        'epoch': 0,
        'mode': 'ready',
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects a journal with an unknown mode', () {
    expect(
      () => AccountTransitionJournal.fromJson({
        'version': 1,
        'uid': 'uid-a',
        'epoch': 7,
        'mode': 'deleting',
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('reconciliation metadata is allowlisted without secret material', () {
    final journal = AccountTransitionJournal.fromJson({
      'version': 1,
      'uid': 'uid-a',
      'epoch': 4,
      'mode': 'reconciling',
      'reconciliationOperationId': 'operation-1',
      'reconciliationCheckpoint': 'merged',
      'remoteRevision': 7,
      'credential': 'must-not-survive',
      'proofToken': 'must-not-survive',
    });

    expect(journal.reconciliationOperationId, 'operation-1');
    expect(journal.reconciliationCheckpoint, ReconciliationCheckpoint.merged);
    expect(journal.remoteRevision, 7);
    expect(journal.toJson(), {
      'version': 1,
      'uid': 'uid-a',
      'epoch': 4,
      'mode': 'reconciling',
      'reconciliationOperationId': 'operation-1',
      'reconciliationCheckpoint': 'merged',
      'remoteRevision': 7,
    });
  });
}
