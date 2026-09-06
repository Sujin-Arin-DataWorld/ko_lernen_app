import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/services/account/account_deletion_status_receipt.dart';
import 'package:ko_lernen_app/services/account/account_operation_client.dart';
import 'package:ko_lernen_app/services/account/account_switch_coordinator.dart';
import 'package:ko_lernen_app/services/account/cloud_backup_deletion.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/app_startup_coordinator.dart';
import 'package:ko_lernen_app/services/auth_service.dart';

void main() {
  test(
    'a legacy replacement journal is discarded and startup continues as none',
    () async {
      final sessions = CloudWriteSessionController();
      var discardCalls = 0;
      final resolver = AccountStartupJournalResolver(
        sessions: sessions,
        hasLegacyReplacementJournal: () async => true,
        discardLegacyReplacement: () async {
          discardCalls += 1;
        },
        readSwitch: () async => null,
        readDeletion: () async => null,
      );

      final restored = await resolver.restore('anonymous-source');

      expect(restored.kind, AccountStartupRestorationKind.none);
      expect(discardCalls, 1);
      expect(sessions.current, isNull);
    },
  );

  test(
    'an unparseable legacy replacement journal is still discarded',
    () async {
      final sessions = CloudWriteSessionController();
      var discardCalls = 0;
      final resolver = AccountStartupJournalResolver(
        sessions: sessions,
        hasLegacyReplacementJournal: () async => true,
        discardLegacyReplacement: () async {
          discardCalls += 1;
        },
        readSwitch: () async => null,
        readDeletion: () async => null,
      );

      final restored = await resolver.restore(null);

      expect(restored.kind, AccountStartupRestorationKind.none);
      expect(discardCalls, 1);
    },
  );

  test('a pending account switch journal resolves to switchPending', () async {
    final sessions = CloudWriteSessionController();
    final resolver = AccountStartupJournalResolver(
      sessions: sessions,
      hasLegacyReplacementJournal: () async => false,
      discardLegacyReplacement: () async {},
      readSwitch: () async => _switchJournal(),
      readDeletion: () async => null,
    );

    final restored = await resolver.restore('anonymous-source');

    expect(restored.kind, AccountStartupRestorationKind.switchPending);
    expect(sessions.current, isNull);
  });

  test(
    'malformed durable state fails closed and never creates a ready session',
    () async {
      final sessions = CloudWriteSessionController();
      final resolver = AccountStartupJournalResolver(
        sessions: sessions,
        hasLegacyReplacementJournal: () async => false,
        discardLegacyReplacement: () async {},
        readSwitch: () async => throw const FormatException('invalid'),
        readDeletion: () async => null,
      );

      final restored = await resolver.restore('anonymous-source');

      expect(restored.kind, AccountStartupRestorationKind.blocked);
      expect(sessions.current, isNull);
    },
  );

  test('simultaneous switch and deletion journals fail closed', () async {
    final sessions = CloudWriteSessionController();
    final resolver = AccountStartupJournalResolver(
      sessions: sessions,
      hasLegacyReplacementJournal: () async => false,
      discardLegacyReplacement: () async {},
      readSwitch: () async => _switchJournal(),
      readDeletion: () async =>
          _deletionJournal(AccountOperationPhase.deletionRequested),
    );

    final restored = await resolver.restore('anonymous-source');

    expect(restored.kind, AccountStartupRestorationKind.blocked);
    expect(sessions.current, isNull);
  });

  test(
    'a deletion journal with no operation is cleared and reported as none',
    () async {
      final sessions = CloudWriteSessionController();
      var discardCalls = 0;
      final resolver = AccountStartupJournalResolver(
        sessions: sessions,
        hasLegacyReplacementJournal: () async => false,
        discardLegacyReplacement: () async {},
        readSwitch: () async => null,
        readDeletion: () async => AccountDeletionJournal.pending(
          session: const CloudWriteSession(
            uid: 'anonymous-source',
            epoch: 5,
            mode: CloudWriteMode.quiesced,
          ),
          requestKey: 'deletion-request-1',
        ),
        discardDeletion: () async {
          discardCalls += 1;
        },
      );

      final restored = await resolver.restore('anonymous-source');

      expect(restored.kind, AccountStartupRestorationKind.none);
      expect(discardCalls, 1);
      expect(sessions.current, isNull);
    },
  );

  test(
    'completed remote deletion becomes local-cleanup-only checkpoint',
    () async {
      final sessions = CloudWriteSessionController();
      final resolver = AccountStartupJournalResolver(
        sessions: sessions,
        hasLegacyReplacementJournal: () async => false,
        discardLegacyReplacement: () async {},
        readSwitch: () async => null,
        readDeletion: () async =>
            _deletionJournal(AccountOperationPhase.completed),
      );

      final restored = await resolver.restore('new-anonymous');

      expect(restored.kind, AccountStartupRestorationKind.localCleanupPending);
      expect(sessions.current, isNull);
    },
  );

  test(
    'completed deletion with an uncleared receipt retries receipt finalization',
    () async {
      final sessions = CloudWriteSessionController();
      final journal = _deletionJournal(AccountOperationPhase.completed);
      final receipt = AccountDeletionStatusReceipt.checked(
        sourceUid: journal.session.uid,
        requestKey: journal.requestKey,
        terminalStatusReceipt: 'A' * 43,
        operationId: journal.operationId,
      );
      final resolver = AccountStartupJournalResolver(
        sessions: sessions,
        hasLegacyReplacementJournal: () async => false,
        discardLegacyReplacement: () async {},
        readSwitch: () async => null,
        readDeletion: () async => journal,
        readDeletionStatusReceipt: () async => receipt,
      );

      final restored = await resolver.restore('new-anonymous');

      expect(
        restored.kind,
        AccountStartupRestorationKind.deletionReceiptPending,
      );
      expect(sessions.current, isNull);
    },
  );

  test(
    'feedback handoff alone is activation pending, not local cleanup pending',
    () async {
      final sessions = CloudWriteSessionController();
      final checkpoint = _deletionJournal(AccountOperationPhase.completed);
      final resolver = AccountStartupJournalResolver(
        sessions: sessions,
        hasLegacyReplacementJournal: () async => false,
        discardLegacyReplacement: () async {},
        readSwitch: () async => null,
        readDeletion: () async => null,
        readFeedbackActivation: () async => checkpoint,
      );

      final restored = await resolver.restore('new-anonymous');

      expect(
        restored.kind,
        AccountStartupRestorationKind.feedbackActivationPending,
      );
      expect(sessions.current, isNull);
    },
  );

  test(
    'matching completed and handoff journals are activation pending',
    () async {
      final sessions = CloudWriteSessionController();
      final checkpoint = _deletionJournal(AccountOperationPhase.completed);
      final resolver = AccountStartupJournalResolver(
        sessions: sessions,
        hasLegacyReplacementJournal: () async => false,
        discardLegacyReplacement: () async {},
        readSwitch: () async => null,
        readDeletion: () async => checkpoint,
        readFeedbackActivation: () async => checkpoint,
      );

      final restored = await resolver.restore('new-anonymous');

      expect(
        restored.kind,
        AccountStartupRestorationKind.feedbackActivationPending,
      );
      expect(sessions.current, isNull);
    },
  );

  test('mismatched completed and handoff journals fail closed', () async {
    final sessions = CloudWriteSessionController();
    final resolver = AccountStartupJournalResolver(
      sessions: sessions,
      hasLegacyReplacementJournal: () async => false,
      discardLegacyReplacement: () async {},
      readSwitch: () async => null,
      readDeletion: () async =>
          _deletionJournal(AccountOperationPhase.completed),
      readFeedbackActivation: () async => AccountDeletionJournal(
        version: AccountDeletionJournal.currentVersion,
        session: const CloudWriteSession(
          uid: 'another-source',
          epoch: 7,
          mode: CloudWriteMode.cleanupPending,
        ),
        requestKey: 'different-request',
        operation: const AccountOperationResult(
          operationId: 'different-operation',
          kind: AccountOperationKind.deletion,
          phase: AccountOperationPhase.completed,
          version: 5,
          attemptCount: 1,
          retryable: false,
        ),
      ),
    );

    final restored = await resolver.restore('new-anonymous');

    expect(restored.kind, AccountStartupRestorationKind.blocked);
    expect(sessions.current, isNull);
  });

  test('pending deletion resumes only for the exact live source', () async {
    final sessions = CloudWriteSessionController();
    final journal = _deletionJournal(AccountOperationPhase.deletionRequested);
    final resolver = AccountStartupJournalResolver(
      sessions: sessions,
      hasLegacyReplacementJournal: () async => false,
      discardLegacyReplacement: () async {},
      readSwitch: () async => null,
      readDeletion: () async => journal,
    );

    final restored = await resolver.restore('anonymous-source');

    expect(restored.kind, AccountStartupRestorationKind.deletion);
    expect(restored.session, journal.session);
    expect(sessions.current, journal.session);
  });

  test(
    'exact live source resumes explicitly even with a matching receipt '
    'present (T5 drops the receipt-priority OAuth-avoidance special case)',
    () async {
      final sessions = CloudWriteSessionController();
      final journal = _deletionJournal(AccountOperationPhase.deletionRequested);
      final receipt = AccountDeletionStatusReceipt.checked(
        sourceUid: journal.session.uid,
        requestKey: journal.requestKey,
        terminalStatusReceipt: 'A' * 43,
        operationId: journal.operationId,
      );
      final resolver = AccountStartupJournalResolver(
        sessions: sessions,
        hasLegacyReplacementJournal: () async => false,
        discardLegacyReplacement: () async {},
        readSwitch: () async => null,
        readDeletion: () async => journal,
        readDeletionStatusReceipt: () async => receipt,
      );

      final restored = await resolver.restore('anonymous-source');

      expect(restored.kind, AccountStartupRestorationKind.deletion);
      expect(restored.session, journal.session);
      expect(sessions.current, journal.session);
    },
  );

  test(
    'matching secure receipt restores pending deletion after source auth is gone',
    () async {
      final sessions = CloudWriteSessionController();
      final journal = _deletionJournal(
        AccountOperationPhase.processorCleanupPending,
      );
      final receipt = AccountDeletionStatusReceipt.checked(
        sourceUid: journal.session.uid,
        requestKey: journal.requestKey,
        terminalStatusReceipt: 'A' * 43,
        operationId: journal.operationId,
      );
      final resolver = AccountStartupJournalResolver(
        sessions: sessions,
        hasLegacyReplacementJournal: () async => false,
        discardLegacyReplacement: () async {},
        readSwitch: () async => null,
        readDeletion: () async => journal,
        readDeletionStatusReceipt: () async => receipt,
      );

      final restored = await resolver.restore(null);

      expect(
        restored.kind,
        AccountStartupRestorationKind.deletionReceiptPending,
      );
      expect(restored.session, isNull);
      expect(sessions.current, isNull);
    },
  );

  test(
    'a non-completed journal for a different anonymous identity is '
    'discarded and falls back to receipt verification, never blocked',
    () async {
      final sessions = CloudWriteSessionController();
      final journal = _deletionJournal(
        AccountOperationPhase.communityCleanupPending,
      );
      final receipt = AccountDeletionStatusReceipt.checked(
        sourceUid: journal.session.uid,
        requestKey: journal.requestKey,
        terminalStatusReceipt: 'A' * 43,
        operationId: journal.operationId,
      );
      var discardCalls = 0;
      final resolver = AccountStartupJournalResolver(
        sessions: sessions,
        hasLegacyReplacementJournal: () async => false,
        discardLegacyReplacement: () async {},
        readSwitch: () async => null,
        readDeletion: () async => journal,
        readDeletionStatusReceipt: () async => receipt,
        discardDeletion: () async {
          discardCalls += 1;
        },
      );

      final arbitraryAnonymous = await resolver.restore('fresh-anon');
      final unrelated = await resolver.restore('durable-other');

      expect(
        arbitraryAnonymous.kind,
        AccountStartupRestorationKind.deletionReceiptPending,
      );
      expect(
        unrelated.kind,
        AccountStartupRestorationKind.deletionReceiptPending,
      );
      expect(discardCalls, 2);
      expect(sessions.current, isNull);
    },
  );

  test(
    'an unmatched receipt still falls back to receipt verification, never '
    'blocked (the resolver itself no longer validates receipt matching)',
    () async {
      final sessions = CloudWriteSessionController();
      final journal = _deletionJournal(
        AccountOperationPhase.processorCleanupPending,
      );
      final receipt = AccountDeletionStatusReceipt.checked(
        sourceUid: journal.session.uid,
        requestKey: 'another-request',
        terminalStatusReceipt: 'A' * 43,
        operationId: journal.operationId,
      );
      final resolver = AccountStartupJournalResolver(
        sessions: sessions,
        hasLegacyReplacementJournal: () async => false,
        discardLegacyReplacement: () async {},
        readSwitch: () async => null,
        readDeletion: () async => journal,
        readDeletionStatusReceipt: () async => receipt,
      );

      final restored = await resolver.restore(null);

      expect(
        restored.kind,
        AccountStartupRestorationKind.deletionReceiptPending,
      );
      expect(sessions.current, isNull);
    },
  );

  test(
    'a discard failure never fences a deletion journal from resolving',
    () async {
      final sessions = CloudWriteSessionController();
      final resolver = AccountStartupJournalResolver(
        sessions: sessions,
        hasLegacyReplacementJournal: () async => false,
        discardLegacyReplacement: () async {},
        readSwitch: () async => null,
        readDeletion: () async => AccountDeletionJournal.pending(
          session: const CloudWriteSession(
            uid: 'anonymous-source',
            epoch: 5,
            mode: CloudWriteMode.quiesced,
          ),
          requestKey: 'deletion-request-1',
        ),
        discardDeletion: () async {
          throw StateError('storage unavailable');
        },
      );

      final restored = await resolver.restore('anonymous-source');

      expect(restored.kind, AccountStartupRestorationKind.none);
    },
  );

  test(
    'pending cloud backup deletion restores its exact cleanup fence',
    () async {
      final sessions = CloudWriteSessionController();
      final journal = CloudBackupDeletionJournal.pending(
        session: const CloudWriteSession(
          uid: 'durable-source',
          epoch: 9,
          mode: CloudWriteMode.cleanupPending,
        ),
        requestKey: 'Q' * 43,
      );
      final resolver = AccountStartupJournalResolver(
        sessions: sessions,
        hasLegacyReplacementJournal: () async => false,
        discardLegacyReplacement: () async {},
        readSwitch: () async => null,
        readDeletion: () async => null,
        readCloudBackupDeletion: () async => journal,
      );

      final restored = await resolver.restore('durable-source');

      expect(restored.kind, AccountStartupRestorationKind.cloudBackupDeletion);
      expect(restored.session, journal.session);
      expect(sessions.current, journal.session);
    },
  );
}

AccountSwitchJournal _switchJournal() {
  return const AccountSwitchJournal(
    version: AccountSwitchJournal.currentVersion,
    sourceUid: 'anonymous-source',
    targetUid: 'durable-target',
    provider: 'google',
    operationId: 'switch-operation-1',
    createdAtMillis: 0,
  );
}

AccountDeletionJournal _deletionJournal(AccountOperationPhase phase) {
  return AccountDeletionJournal(
    version: AccountDeletionJournal.currentVersion,
    session: const CloudWriteSession(
      uid: 'anonymous-source',
      epoch: 7,
      mode: CloudWriteMode.cleanupPending,
    ),
    requestKey: 'deletion-request-1',
    operation: AccountOperationResult(
      operationId: 'deletion-operation-1',
      kind: AccountOperationKind.deletion,
      phase: phase,
      version: 5,
      attemptCount: 1,
      retryable: phase != AccountOperationPhase.completed,
    ),
  );
}
