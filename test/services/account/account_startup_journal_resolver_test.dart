import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/services/account/account_operation_client.dart';
import 'package:ko_lernen_app/services/account/account_transition_journal.dart';
import 'package:ko_lernen_app/services/account/cloud_backup_deletion.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/app_startup_coordinator.dart';
import 'package:ko_lernen_app/services/auth_service.dart';

void main() {
  test(
    'rehydrates exact replacement source fence before ready startup',
    () async {
      final sessions = CloudWriteSessionController();
      final journal = _replacementJournal(
        mode: CloudWriteMode.reconciling,
        phase: AccountReplacementPhase.reconciling,
      );
      final resolver = AccountStartupJournalResolver(
        sessions: sessions,
        readReplacement: () async => journal,
        readDeletion: () async => null,
      );

      final restored = await resolver.restore('anonymous-source');

      expect(restored.kind, AccountStartupRestorationKind.replacement);
      expect(restored.session, journal.session);
      expect(sessions.current, journal.session);
      expect(sessions.current?.mode, CloudWriteMode.reconciling);
    },
  );

  test(
    'source-deleted activation pending stays fenced without auth creation',
    () async {
      final sessions = CloudWriteSessionController();
      final resolver = AccountStartupJournalResolver(
        sessions: sessions,
        readReplacement: () async => _replacementJournal(
          mode: CloudWriteMode.cleanupPending,
          phase: AccountReplacementPhase.activationPending,
        ),
        readDeletion: () async => null,
      );

      final restored = await resolver.restore(null);

      expect(restored.kind, AccountStartupRestorationKind.replacement);
      expect(restored.session, isNull);
      expect(sessions.current, isNull);
    },
  );

  test(
    'malformed journal fails closed and never creates a ready session',
    () async {
      final sessions = CloudWriteSessionController();
      final resolver = AccountStartupJournalResolver(
        sessions: sessions,
        readReplacement: () async => throw const FormatException('invalid'),
        readDeletion: () async => null,
      );

      final restored = await resolver.restore('anonymous-source');

      expect(restored.kind, AccountStartupRestorationKind.blocked);
      expect(sessions.current, isNull);
    },
  );

  test('simultaneous replacement and deletion journals fail closed', () async {
    final sessions = CloudWriteSessionController();
    final resolver = AccountStartupJournalResolver(
      sessions: sessions,
      readReplacement: () async => _replacementJournal(
        mode: CloudWriteMode.reconciling,
        phase: AccountReplacementPhase.reconciling,
      ),
      readDeletion: () async =>
          _deletionJournal(AccountOperationPhase.deletionRequested),
    );

    final restored = await resolver.restore('anonymous-source');

    expect(restored.kind, AccountStartupRestorationKind.blocked);
    expect(sessions.current, isNull);
  });

  test(
    'completed remote deletion becomes local-cleanup-only checkpoint',
    () async {
      final sessions = CloudWriteSessionController();
      final resolver = AccountStartupJournalResolver(
        sessions: sessions,
        readReplacement: () async => null,
        readDeletion: () async =>
            _deletionJournal(AccountOperationPhase.completed),
      );

      final restored = await resolver.restore('new-anonymous');

      expect(restored.kind, AccountStartupRestorationKind.localCleanupPending);
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
        readReplacement: () async => null,
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
        readReplacement: () async => null,
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
      readReplacement: () async => null,
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
      readReplacement: () async => null,
      readDeletion: () async => journal,
    );

    final restored = await resolver.restore('anonymous-source');

    expect(restored.kind, AccountStartupRestorationKind.deletion);
    expect(restored.session, journal.session);
    expect(sessions.current, journal.session);
  });

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
        readReplacement: () async => null,
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

AccountTransitionJournal _replacementJournal({
  required CloudWriteMode mode,
  required AccountReplacementPhase phase,
}) {
  final cleanup =
      phase == AccountReplacementPhase.cleanupPending ||
      phase == AccountReplacementPhase.activationPending;
  return AccountTransitionJournal.fromSession(
    CloudWriteSession(uid: 'anonymous-source', epoch: 8, mode: mode),
    replacementProvider: 'google',
    replacementTargetUid: 'durable-target',
    replacementRequestKey: 'request-key-1',
    replacementPhase: phase,
    replacementOperationId: 'replacement-operation-1',
    replacementOperationVersion: 4,
    reconciliationOperationId: 'replacement-operation-1',
    reconciliationCheckpoint: cleanup
        ? ReconciliationCheckpoint.completed
        : ReconciliationCheckpoint.remoteRead,
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
