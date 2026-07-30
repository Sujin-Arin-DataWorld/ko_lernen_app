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

  test(
    'reconciliation custom-pack base ids round-trip sorted and allowlisted',
    () {
      final journal = AccountTransitionJournal.fromJson({
        'version': 1,
        'uid': 'uid-a',
        'epoch': 4,
        'mode': 'reconciling',
        'reconciliationLocalCustomPackBaseIds': ['cp-b', 'cp-a'],
        'credential': 'must-not-survive',
      });

      expect(journal.toJson()['reconciliationLocalCustomPackBaseIds'], [
        'cp-a',
        'cp-b',
      ]);
      expect(journal.toJson(), isNot(contains('credential')));
    },
  );

  test('reconciliation custom-pack base ids are strictly bounded', () {
    expect(
      () => AccountTransitionJournal.fromJson({
        'version': 1,
        'uid': 'uid-a',
        'epoch': 4,
        'mode': 'reconciling',
        'reconciliationLocalCustomPackBaseIds': List<String>.filled(
          513,
          'cp-a',
        ),
      }),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => AccountTransitionJournal.fromJson({
        'version': 1,
        'uid': 'uid-a',
        'epoch': 4,
        'mode': 'reconciling',
        'reconciliationLocalCustomPackBaseIds': ['cp-a', 'cp-a'],
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('replacement metadata round-trips without provider credentials', () {
    final journal = AccountTransitionJournal.fromJson({
      'version': 1,
      'uid': 'anonymous-source',
      'epoch': 4,
      'mode': 'reconciling',
      'replacementProvider': 'google',
      'replacementTargetUid': 'durable-target',
      'replacementRequestKey': 'request-key-1',
      'replacementPhase': 'reconciling',
      'replacementOperationId': 'operation-1',
      'replacementOperationVersion': 2,
      'reconciliationOperationId': 'operation-1',
      'credential': 'must-not-survive',
      'idToken': 'must-not-survive',
      'accessToken': 'must-not-survive',
      'authorizationCode': 'must-not-survive',
    });

    expect(journal.replacementPhase, AccountReplacementPhase.reconciling);
    expect(journal.toJson(), {
      'version': 1,
      'uid': 'anonymous-source',
      'epoch': 4,
      'mode': 'reconciling',
      'reconciliationOperationId': 'operation-1',
      'replacementProvider': 'google',
      'replacementTargetUid': 'durable-target',
      'replacementRequestKey': 'request-key-1',
      'replacementPhase': 'reconciling',
      'replacementOperationId': 'operation-1',
      'replacementOperationVersion': 2,
    });
  });

  test('partial or unsupported replacement metadata is rejected', () {
    for (final invalid in <Map<String, Object?>>[
      {
        'replacementProvider': 'google',
        'replacementTargetUid': 'durable-target',
      },
      {
        'replacementProvider': 'password',
        'replacementTargetUid': 'durable-target',
        'replacementRequestKey': 'request-1',
        'replacementPhase': 'targetVerified',
      },
      {
        'replacementProvider': 'apple',
        'replacementTargetUid': 'durable-target',
        'replacementRequestKey': 'request-1',
        'replacementPhase': 'cleanupPending',
        'replacementOperationId': 'operation-1',
      },
    ]) {
      expect(
        () => AccountTransitionJournal.fromJson({
          'version': 1,
          'uid': 'anonymous-source',
          'epoch': 4,
          'mode': 'reconciling',
          ...invalid,
        }),
        throwsA(isA<FormatException>()),
      );
    }
  });

  test('replacement phases enforce exact operation and session invariants', () {
    final base = <String, Object?>{
      'version': 1,
      'uid': 'anonymous-source',
      'epoch': 4,
      'replacementProvider': 'google',
      'replacementTargetUid': 'durable-target',
      'replacementRequestKey': 'request-1',
    };
    final invalid = <Map<String, Object?>>[
      {...base, 'mode': 'ready', 'replacementPhase': 'targetVerified'},
      {...base, 'mode': 'quiesced', 'replacementPhase': 'prepared'},
      {
        ...base,
        'mode': 'reconciling',
        'replacementPhase': 'prepared',
        'replacementOperationId': 'operation-1',
        'replacementOperationVersion': 1,
      },
      {
        ...base,
        'mode': 'reconciling',
        'replacementPhase': 'attached',
        'replacementOperationId': 'operation-1',
        'replacementOperationVersion': 1,
        'reconciliationOperationId': 'operation-other',
      },
      {
        ...base,
        'mode': 'reconciling',
        'replacementPhase': 'attached',
        'replacementOperationId': 'operation-1',
        'replacementOperationVersion': 1,
        'reconciliationOperationId': 'operation-1',
        'remoteRevision': 4,
      },
      {
        ...base,
        'mode': 'reconciling',
        'replacementPhase': 'reconciled',
        'replacementOperationId': 'operation-1',
        'replacementOperationVersion': 2,
        'reconciliationOperationId': 'operation-1',
      },
      {
        ...base,
        'mode': 'ready',
        'replacementPhase': 'cleanupPending',
        'replacementOperationId': 'operation-1',
        'replacementOperationVersion': 3,
        'reconciliationOperationId': 'operation-1',
        'reconciliationCheckpoint': 'completed',
      },
      {
        ...base,
        'mode': 'cleanupPending',
        'replacementPhase': 'activationPending',
        'replacementOperationId': 'operation-1',
        'replacementOperationVersion': 4,
        'reconciliationOperationId': 'operation-1',
      },
    ];

    for (final json in invalid) {
      expect(
        () => AccountTransitionJournal.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    }
  });

  test(
    'activation-pending journal round-trips as a valid non-secret state',
    () {
      final journal = AccountTransitionJournal.fromJson({
        'version': 1,
        'uid': 'anonymous-source',
        'epoch': 8,
        'mode': 'cleanupPending',
        'replacementProvider': 'apple',
        'replacementTargetUid': 'durable-target',
        'replacementRequestKey': 'request-1',
        'replacementPhase': 'activationPending',
        'replacementOperationId': 'operation-1',
        'replacementOperationVersion': 4,
        'reconciliationOperationId': 'operation-1',
        'reconciliationCheckpoint': 'completed',
        'authorizationCode': 'must-not-survive',
      });

      expect(
        journal.replacementPhase,
        AccountReplacementPhase.activationPending,
      );
      expect(journal.toJson(), isNot(contains('authorizationCode')));
      expect(
        AccountTransitionJournal.fromJson(journal.toJson()).toJson(),
        journal.toJson(),
      );
    },
  );
}
