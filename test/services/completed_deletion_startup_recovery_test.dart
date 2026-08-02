import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/config/tester_feedback_feature.dart';
import 'package:ko_lernen_app/models/content_feedback.dart';
import 'package:ko_lernen_app/screens/settings_screen.dart';
import 'package:ko_lernen_app/services/account/account_operation_client.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/app_startup_coordinator.dart';
import 'package:ko_lernen_app/services/auth_service.dart';
import 'package:ko_lernen_app/services/content_feedback_client.dart';
import 'package:ko_lernen_app/services/content_feedback_lifecycle.dart';
import 'package:ko_lernen_app/services/content_feedback_outbox.dart';
import 'package:ko_lernen_app/services/content_feedback_service.dart';
import 'package:ko_lernen_app/services/content_feedback_version_provider.dart';

void main() {
  const context = ContentFeedbackContext(
    completionId: 'startup-completion',
    contentType: 'scenario',
    contentId: 'airport',
    contentLabel: 'At the airport',
    level: 'A1',
    scoreSummary: '8/10',
  );
  const draft = ContentFeedbackDraft(
    category: FeedbackCategory.content,
    message: 'The dialogue was useful.',
  );

  test(
    'marker-only startup recovers and clears cleanup before feedback resumes',
    () async {
      const deletedUid = 'deleted-source';
      const replacementUid = 'new-anonymous';
      final checkpoint = _completedJournal(deletedUid);
      final completed = _JournalStore(null);
      final handoff = _JournalStore(checkpoint);
      final events = <String>[];
      var pendingRemoteResumes = 0;
      var recoveryCalls = 0;
      final client = _Client();
      bool journalActive() =>
          completed.journal != null || handoff.journal != null;
      Future<bool> activationBlocked(String candidateDeletedUid) async {
        final marker = handoff.journal;
        return completed.journal != null ||
            marker?.operation?.phase != AccountOperationPhase.completed ||
            marker?.session.uid != candidateDeletedUid;
      }

      late final ContentFeedbackLifecycle lifecycle;
      lifecycle = ContentFeedbackLifecycle(
        initialService: _service(
          currentUid: () => replacementUid,
          deletionActive: () async => journalActive(),
          client: _Client(),
        ),
        createService: () => _service(
          currentUid: () => replacementUid,
          deletionActive: () async => journalActive(),
          client: client,
        ),
        currentIdentity: () => (uid: replacementUid, isAnonymous: true),
        durableJournalActive: activationBlocked,
      );
      final recoveryGate = CompletedAccountDeletionRecoveryGate(
        readCheckpoint: () async =>
            await completed.read() ?? await handoff.read(),
        recoverCompleted: (_) async {
          recoveryCalls += 1;
          events.add('identity-recovery');
        },
        closeFeedback: lifecycle.closeAndDiscard,
      );
      final operations = _CleanupOperations(
        events: events,
        deleteRemote: recoveryGate.run,
      );
      final workflow = AccountDeletionWorkflow(
        operations,
        completeCheckpoint: () =>
            CompletedDeletionFeedbackActivationCoordinator(
              completedStore: completed,
              activationStore: handoff,
              activateFeedback: lifecycle.activateAfterCompletedDeletion,
            ).run(),
      );
      final startup = _startup(
        restoration: () => journalActive()
            ? const AccountStartupRestoration.localCleanupPending()
            : const AccountStartupRestoration.none(),
        resumePendingRemote: () async => pendingRemoteResumes += 1,
        resumeCompletedCleanup: workflow.run,
      );

      expect(await startup.start(), isTrue);
      final submitted = await lifecycle.submit(context, draft);

      expect(recoveryCalls, 1);
      expect(pendingRemoteResumes, 0);
      expect(events, <String>[
        'identity-recovery',
        'local-reset',
        'push-disable',
        'image-delete',
        'tts-clear',
        'memory-reset',
      ]);
      expect(completed.journal, isNull);
      expect(handoff.journal, isNull);
      expect(submitted.status, ContentFeedbackSubmitStatus.accepted);
      expect(client.expectedOwnerUids, [replacementUid]);
    },
  );

  test(
    'primary completed startup retries identity recovery before local cleanup',
    () async {
      const deletedUid = 'deleted-source';
      final completed = _JournalStore(_completedJournal(deletedUid));
      final handoff = _JournalStore(null);
      final events = <String>[];
      var currentUid = deletedUid;
      var pendingRemoteResumes = 0;
      final lifecycle = ContentFeedbackLifecycle(
        initialService: _service(
          currentUid: () => currentUid,
          deletionActive: () async =>
              completed.journal != null || handoff.journal != null,
          client: _Client(),
        ),
        createService: () => _service(
          currentUid: () => currentUid,
          deletionActive: () async =>
              completed.journal != null || handoff.journal != null,
          client: _Client(),
        ),
        currentIdentity: () => (uid: currentUid, isAnonymous: true),
        durableJournalActive: (candidateDeletedUid) async {
          final marker = handoff.journal;
          return completed.journal != null ||
              marker?.session.uid != candidateDeletedUid;
        },
      );
      final recoveryGate = CompletedAccountDeletionRecoveryGate(
        readCheckpoint: completed.read,
        recoverCompleted: (_) async {
          events.add('identity-recovery');
          currentUid = 'recovered-anonymous';
        },
        closeFeedback: lifecycle.closeAndDiscard,
      );
      final workflow = AccountDeletionWorkflow(
        _CleanupOperations(events: events, deleteRemote: recoveryGate.run),
        completeCheckpoint: () =>
            CompletedDeletionFeedbackActivationCoordinator(
              completedStore: completed,
              activationStore: handoff,
              activateFeedback: lifecycle.activateAfterCompletedDeletion,
            ).run(),
      );

      expect(
        await _startup(
          restoration: () =>
              completed.journal != null || handoff.journal != null
              ? const AccountStartupRestoration.localCleanupPending()
              : const AccountStartupRestoration.none(),
          resumePendingRemote: () async => pendingRemoteResumes += 1,
          resumeCompletedCleanup: workflow.run,
        ).start(),
        isTrue,
      );

      expect(pendingRemoteResumes, 0);
      expect(events.first, 'identity-recovery');
      expect(
        events.indexOf('identity-recovery'),
        lessThan(events.indexOf('local-reset')),
      );
      expect(currentUid, 'recovered-anonymous');
      expect(completed.journal, isNull);
      expect(handoff.journal, isNull);
    },
  );

  test(
    'failed startup identity recovery retains marker and blocks feedback',
    () async {
      const deletedUid = 'deleted-source';
      const replacementUid = 'new-anonymous';
      final completed = _JournalStore(null);
      final handoff = _JournalStore(_completedJournal(deletedUid));
      var pendingRemoteResumes = 0;
      final client = _Client();
      final lifecycle = ContentFeedbackLifecycle(
        initialService: _service(
          currentUid: () => replacementUid,
          deletionActive: () async => handoff.journal != null,
          client: client,
        ),
        createService: () => _service(
          currentUid: () => replacementUid,
          deletionActive: () async => handoff.journal != null,
          client: client,
        ),
        currentIdentity: () => (uid: replacementUid, isAnonymous: true),
        durableJournalActive: (_) async => false,
      );
      final recoveryGate = CompletedAccountDeletionRecoveryGate(
        readCheckpoint: handoff.read,
        recoverCompleted: (_) async {
          throw AccountDeletionRecoveryException(<Object>[
            StateError('identity recovery unavailable'),
          ]);
        },
        closeFeedback: lifecycle.closeAndDiscard,
      );
      final workflow = AccountDeletionWorkflow(
        _CleanupOperations(events: <String>[], deleteRemote: recoveryGate.run),
        completeCheckpoint: () =>
            CompletedDeletionFeedbackActivationCoordinator(
              completedStore: completed,
              activationStore: handoff,
              activateFeedback: lifecycle.activateAfterCompletedDeletion,
            ).run(),
      );

      await expectLater(
        _startup(
          restoration: () =>
              const AccountStartupRestoration.localCleanupPending(),
          resumePendingRemote: () async => pendingRemoteResumes += 1,
          resumeCompletedCleanup: workflow.run,
        ).start(),
        throwsA(
          isA<AccountDeletionFailure>().having(
            (failure) => failure.identityRecoveryPending,
            'identityRecoveryPending',
            isTrue,
          ),
        ),
      );
      final submitted = await lifecycle.submit(context, draft);

      expect(pendingRemoteResumes, 0);
      expect(completed.journal, isNull);
      expect(handoff.journal?.session.uid, deletedUid);
      expect(submitted.status, ContentFeedbackSubmitStatus.blockedByDeletion);
      expect(client.expectedOwnerUids, isEmpty);
    },
  );

  test(
    'wrong durable identity leaves marker and all local account data untouched',
    () async {
      const deletedUid = 'deleted-source';
      final completed = _JournalStore(_completedJournal(deletedUid));
      final events = <String>[];
      var pendingRemoteResumes = 0;
      var googleCleanupCalls = 0;
      var feedbackCloses = 0;
      final recoveryGate = CompletedAccountDeletionRecoveryGate(
        readCheckpoint: completed.read,
        recoverCompleted: (checkpoint) => recoverCompletedDeletionIdentity(
          checkpoint: checkpoint,
          currentUid: 'different-durable-account',
          currentIsAnonymous: false,
          cleanupGoogleProvider: () async => googleCleanupCalls += 1,
          recoverFirebaseIdentity: () async {
            fail('wrong durable identity must not be replaced');
          },
        ),
        closeFeedback: () async => feedbackCloses += 1,
      );
      final workflow = AccountDeletionWorkflow(
        _CleanupOperations(events: events, deleteRemote: recoveryGate.run),
        completeCheckpoint: () async {
          fail('wrong durable identity must not complete cleanup');
        },
      );

      await expectLater(
        _startup(
          restoration: () =>
              const AccountStartupRestoration.localCleanupPending(),
          resumePendingRemote: () async => pendingRemoteResumes += 1,
          resumeCompletedCleanup: workflow.run,
        ).start(),
        throwsA(
          isA<AccountOperationFailure>().having(
            (failure) => failure.code,
            'code',
            AccountOperationFailureCode.blocked,
          ),
        ),
      );

      expect(pendingRemoteResumes, 0);
      expect(googleCleanupCalls, 0);
      expect(feedbackCloses, 0);
      expect(events, isEmpty);
      expect(completed.journal?.session.uid, deletedUid);
    },
  );

  test(
    'checkpoint vanishing before recovery aborts without remote or local work',
    () async {
      final events = <String>[];
      var pendingRemoteResumes = 0;
      var recoveryCalls = 0;
      var feedbackCloses = 0;
      final recoveryGate = CompletedAccountDeletionRecoveryGate(
        readCheckpoint: () async => null,
        recoverCompleted: (_) async => recoveryCalls += 1,
        closeFeedback: () async => feedbackCloses += 1,
      );
      final workflow = AccountDeletionWorkflow(
        _CleanupOperations(events: events, deleteRemote: recoveryGate.run),
      );

      await expectLater(
        _startup(
          // The first startup read observed a completed checkpoint, but the
          // recovery-only gate must authoritatively reread it.
          restoration: () =>
              const AccountStartupRestoration.localCleanupPending(),
          resumePendingRemote: () async => pendingRemoteResumes += 1,
          resumeCompletedCleanup: workflow.run,
        ).start(),
        throwsA(isA<AccountOperationFailure>()),
      );

      expect(pendingRemoteResumes, 0);
      expect(recoveryCalls, 0);
      expect(feedbackCloses, 0);
      expect(events, isEmpty);
    },
  );
}

AppStartupCoordinator _startup({
  required AccountStartupRestoration Function() restoration,
  required Future<void> Function() resumePendingRemote,
  required Future<void> Function() resumeCompletedCleanup,
}) {
  return AppStartupCoordinator(
    initializeFirebase: () async => true,
    initializeAppCheck: () async {},
    ensureSignedIn: () async {},
    currentUserId: () => 'live-uid',
    restorePendingAccountState: (_) async => restoration(),
    synchronizeReadySession: (_) {},
    resumeMediaCleanup: () async {},
    resumeBookshelfSync: () async {},
    resumeAccountOperation: resumePendingRemote,
    resumeCompletedAccountCleanup: resumeCompletedCleanup,
    initializePremium: () async {},
    enablePush: () async {},
    notificationsEnabled: () => false,
  );
}

AccountDeletionJournal _completedJournal(String uid) {
  return AccountDeletionJournal(
    version: AccountDeletionJournal.currentVersion,
    session: CloudWriteSession(
      uid: uid,
      epoch: 9,
      mode: CloudWriteMode.cleanupPending,
    ),
    requestKey: 'completed-startup-request',
    operation: const AccountOperationResult(
      operationId: 'completed-startup-operation',
      kind: AccountOperationKind.deletion,
      phase: AccountOperationPhase.completed,
      version: 2,
      attemptCount: 1,
      retryable: false,
    ),
  );
}

ContentFeedbackService _service({
  required String? Function() currentUid,
  required Future<bool> Function() deletionActive,
  required ContentFeedbackClient client,
}) {
  return ContentFeedbackService(
    featureGate: const TesterFeedbackFeatureGate(enabled: true),
    outboxStore: _Store(),
    client: client,
    currentUid: currentUid,
    versionProvider: const _Version(),
    createFeedbackId: () => 'feedback-startup',
    now: () => DateTime.utc(2026, 8, 2),
    platform: () => 'android',
    locale: () => 'de',
    deletionActive: deletionActive,
  );
}

class _JournalStore implements AccountDeletionJournalStore {
  _JournalStore(this.journal);

  AccountDeletionJournal? journal;

  @override
  Future<AccountDeletionJournal?> read() async => journal;

  @override
  Future<void> write(AccountDeletionJournal value) async => journal = value;

  @override
  Future<void> clearCompleted(String operationId) async {
    if (journal?.operationId != operationId ||
        journal?.operation?.phase != AccountOperationPhase.completed) {
      throw StateError('completed journal mismatch');
    }
    journal = null;
  }
}

class _CleanupOperations implements AccountDeletionCleanupOperations {
  _CleanupOperations({required this.events, required this.deleteRemote});

  final List<String> events;
  final Future<void> Function() deleteRemote;

  @override
  Future<void> deleteRemoteAccount() => deleteRemote();

  @override
  Future<void> resetLocalStorage() async => events.add('local-reset');

  @override
  Future<void> disablePush() async => events.add('push-disable');

  @override
  Future<void> deleteLocalImages() async => events.add('image-delete');

  @override
  Future<void> clearTtsCache() async => events.add('tts-clear');

  @override
  void resetInMemoryData() => events.add('memory-reset');
}

class _Store implements FeedbackOutboxStore {
  List<ContentFeedbackOutboxItem> items = <ContentFeedbackOutboxItem>[];

  @override
  Future<void> clear() async => items.clear();

  @override
  Future<List<ContentFeedbackOutboxItem>> read() async => List.of(items);

  @override
  Future<void> write(List<ContentFeedbackOutboxItem> value) async {
    items = List.of(value);
  }
}

class _Client implements ContentFeedbackClient {
  final List<String> expectedOwnerUids = <String>[];

  @override
  Future<ContentFeedbackDelivery> submit(
    ContentFeedbackSubmission submission, {
    required String expectedOwnerUid,
  }) async {
    expectedOwnerUids.add(expectedOwnerUid);
    return const ContentFeedbackDelivery(
      acknowledgement: ContentFeedbackAcknowledgement.accepted,
    );
  }
}

class _Version implements ContentFeedbackVersionProvider {
  const _Version();

  @override
  Future<String> readVersion() async => '2.0.1+6';
}
