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
    'marker-only startup finalizes activation without local cleanup',
    () async {
      const deletedUid = 'deleted-source';
      const replacementUid = 'new-anonymous';
      final completed = _JournalStore(null);
      final handoff = _JournalStore(_completedJournal(deletedUid));
      final oldStore = _Store()..items = [_pending('old', deletedUid)];
      final oldService = _service(
        store: oldStore,
        currentUid: () => replacementUid,
        deletionActive: () async => handoff.journal != null,
        client: _Client(),
      );
      final newClient = _Client();
      late final ContentFeedbackLifecycle lifecycle;
      lifecycle = ContentFeedbackLifecycle(
        initialService: oldService,
        createService: () => _service(
          currentUid: () => replacementUid,
          deletionActive: () async => handoff.journal != null,
          client: newClient,
        ),
        currentIdentity: () => (uid: replacementUid, isAnonymous: true),
        durableJournalActive: (_) async => false,
      );
      Future<void> finalize() async {
        assertCompletedDeletionFeedbackActivationIdentitySafe(
          checkpoint: handoff.journal!,
          currentUid: replacementUid,
          currentIsAnonymous: true,
        );
        await lifecycle.closeAndDiscard();
        await CompletedDeletionFeedbackActivationCoordinator(
          completedStore: completed,
          activationStore: handoff,
          activateFeedback: lifecycle.activateAfterCompletedDeletion,
        ).run();
      }

      final startup = _startup(
        restoration: () => handoff.journal == null
            ? const AccountStartupRestoration.none()
            : const AccountStartupRestoration.feedbackActivationPending(),
        resumePendingRemote: () async =>
            fail('must not resume remote deletion'),
        resumeFeedbackActivation: finalize,
      );

      expect(await startup.start(), isTrue);
      final submitted = await lifecycle.submit(context, draft);

      expect(oldStore.items, isEmpty);
      expect((await oldService.resumePending()).closed, isTrue);
      expect(handoff.journal, isNull);
      expect(submitted.status, ContentFeedbackSubmitStatus.accepted);
      expect(newClient.expectedOwnerUids, [replacementUid]);
    },
  );

  test(
    'primary completed startup stays fenced without automatic cleanup',
    () async {
      final events = <String>[];
      final startup = _startup(
        restoration: () =>
            const AccountStartupRestoration.localCleanupPending(),
        resumePendingRemote: () async => events.add('remote'),
        resumeFeedbackActivation: () async => events.add('activation'),
      );

      expect(await startup.start(), isTrue);
      expect(events, isEmpty);
    },
  );

  test(
    'failed activation keeps marker and retry never repeats cleanup',
    () async {
      final completed = _JournalStore(_completedJournal('deleted-source'));
      final handoff = _JournalStore(null);
      final results = <bool>[false, true];
      final coordinator = CompletedDeletionFeedbackActivationCoordinator(
        completedStore: completed,
        activationStore: handoff,
        activateFeedback: (_) async => results.removeAt(0),
      );
      AccountStartupRestoration restoration() => handoff.journal == null
          ? const AccountStartupRestoration.none()
          : const AccountStartupRestoration.feedbackActivationPending();

      await expectLater(
        coordinator.run(),
        throwsA(isA<AccountOperationFailure>()),
      );
      expect(completed.journal, isNull);
      expect(handoff.journal, isNotNull);

      expect(
        await _startup(
          restoration: restoration,
          resumePendingRemote: () async => fail('must not resume remote'),
          resumeFeedbackActivation: coordinator.run,
        ).start(),
        isTrue,
      );
      expect(handoff.journal, isNull);
    },
  );

  test(
    'wrong durable identity blocks before feedback close or cleanup',
    () async {
      final checkpoint = _completedJournal('deleted-source');
      final cleanupEvents = <String>[];
      var feedbackCloses = 0;
      final workflow = AccountDeletionWorkflow(
        _CleanupOperations(
          events: cleanupEvents,
          deleteRemote: () async => fail('remote must not run'),
        ),
        finalizePendingFeedbackActivation: () async {
          assertCompletedDeletionFeedbackActivationIdentitySafe(
            checkpoint: checkpoint,
            currentUid: 'different-durable-account',
            currentIsAnonymous: false,
          );
          feedbackCloses += 1;
          return true;
        },
      );

      await expectLater(
        workflow.run(),
        throwsA(isA<AccountOperationFailure>()),
      );
      expect(feedbackCloses, 0);
      expect(cleanupEvents, isEmpty);
    },
  );

  for (final recoveryFailure in <String>['google', 'firebase']) {
    test(
      '$recoveryFailure recovery failure closes and erases old feedback',
      () async {
        const deletedUid = 'deleted-source';
        final checkpoint = AccountDeletionJournal(
          version: AccountDeletionJournal.currentVersion,
          session: const CloudWriteSession(
            uid: deletedUid,
            epoch: 9,
            mode: CloudWriteMode.cleanupPending,
          ),
          requestKey: 'completed-startup-request',
          sourceProviders: recoveryFailure == 'google'
              ? const {'google'}
              : const {},
          operation: _completedJournal(deletedUid).operation,
        );
        final completed = _JournalStore(checkpoint);
        final oldStore = _Store()
          ..items = [_pending('private-old', deletedUid)];
        final currentUid = recoveryFailure == 'google'
            ? 'recovered-anonymous'
            : deletedUid;
        final oldService = _service(
          store: oldStore,
          currentUid: () => currentUid,
          deletionActive: () async => true,
          client: _Client(),
        );
        final lifecycle = ContentFeedbackLifecycle(
          initialService: oldService,
          createService: () => _service(
            currentUid: () => currentUid,
            deletionActive: () async => true,
            client: _Client(),
          ),
          currentIdentity: () => (uid: currentUid, isAnonymous: true),
          durableJournalActive: (_) async => true,
        );
        final gate = CompletedAccountDeletionRecoveryGate(
          readCheckpoint: completed.read,
          preflight: (journal) => assertCompletedDeletionRecoveryIdentitySafe(
            checkpoint: journal,
            currentUid: currentUid,
            currentIsAnonymous: true,
          ),
          closeFeedback: lifecycle.closeAndDiscard,
          recoverCompleted: (journal) => recoverCompletedDeletionIdentity(
            checkpoint: journal,
            currentUid: currentUid,
            currentIsAnonymous: true,
            cleanupGoogleProvider: () async {
              throw StateError('google unavailable');
            },
            recoverFirebaseIdentity: () async {
              throw StateError('firebase unavailable');
            },
          ),
        );
        final cleanupEvents = <String>[];

        await expectLater(
          AccountDeletionWorkflow(
            _CleanupOperations(events: cleanupEvents, deleteRemote: gate.run),
          ).run(),
          throwsA(isA<AccountDeletionFailure>()),
        );

        expect(oldStore.items, isEmpty);
        expect((await oldService.resumePending()).closed, isTrue);
        expect(completed.journal?.toJson(), checkpoint.toJson());
        expect(cleanupEvents, contains('local-reset'));
      },
    );
  }
}

AppStartupCoordinator _startup({
  required AccountStartupRestoration Function() restoration,
  required Future<void> Function() resumePendingRemote,
  Future<void> Function()? resumeFeedbackActivation,
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
    resumeCompletedFeedbackActivation: resumeFeedbackActivation ?? () async {},
    initializeAccessSnapshot: () async {},
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
  FeedbackOutboxStore? store,
  required String? Function() currentUid,
  required Future<bool> Function() deletionActive,
  required ContentFeedbackClient client,
}) {
  return ContentFeedbackService(
    featureGate: const TesterFeedbackFeatureGate(enabled: true),
    outboxStore: store ?? _Store(),
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

ContentFeedbackOutboxItem _pending(String id, String ownerUid) {
  return ContentFeedbackOutboxItem.pending(
    submission: ContentFeedbackSubmission(
      feedbackId: id,
      context: const ContentFeedbackContext(
        completionId: 'old-completion',
        contentType: 'scenario',
        contentId: 'old-content',
        contentLabel: 'Old content',
        level: 'A1',
        scoreSummary: '1/1',
      ),
      draft: const ContentFeedbackDraft(
        category: FeedbackCategory.bug,
        message: 'Old private queue item.',
      ),
      appVersion: '2.0.1+6',
      platform: 'android',
      locale: 'de',
    ),
    createdAt: DateTime.utc(2026, 8, 2),
    ownerUid: ownerUid,
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

  @override
  Future<void> clearPending() async {
    if (journal?.operation != null) {
      throw StateError('pending journal mismatch');
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
