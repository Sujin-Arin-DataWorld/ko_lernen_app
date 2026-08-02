import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/config/tester_feedback_feature.dart';
import 'package:ko_lernen_app/models/content_feedback.dart';
import 'package:ko_lernen_app/screens/settings_screen.dart';
import 'package:ko_lernen_app/services/content_feedback_client.dart';
import 'package:ko_lernen_app/services/content_feedback_lifecycle.dart';
import 'package:ko_lernen_app/services/content_feedback_outbox.dart';
import 'package:ko_lernen_app/services/content_feedback_service.dart';
import 'package:ko_lernen_app/services/content_feedback_version_provider.dart';

void main() {
  const context = ContentFeedbackContext(
    completionId: 'completion-after-delete',
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
    'a stable pre-deletion callback submits through a fresh anonymous owner',
    () async {
      var uid = 'deleted-uid';
      var anonymous = true;
      var journalActive = false;
      final oldStore = _Store(items: [_pending('old-queued', 'deleted-uid')]);
      final oldClient = _Client();
      final oldService = _service(
        store: oldStore,
        client: oldClient,
        currentUid: () => uid,
        deletionActive: () async => journalActive,
      );
      final newClient = _Client();
      var factoryCalls = 0;
      final lifecycle = ContentFeedbackLifecycle(
        initialService: oldService,
        createService: () {
          factoryCalls += 1;
          return _service(
            store: _Store(),
            client: newClient,
            currentUid: () => uid,
            deletionActive: () async => journalActive,
          );
        },
        currentIdentity: () => (uid: uid, isAnonymous: anonymous),
        durableJournalActive: () async => journalActive,
      );
      final stableSubmit = lifecycle.submit;

      uid = 'new-anonymous-uid';
      anonymous = true;

      expect(
        await lifecycle.activateAfterCompletedDeletion('deleted-uid'),
        isTrue,
      );
      final submitted = await stableSubmit(context, draft);
      final oldResume = await oldService.resumePending();

      expect(submitted.status, ContentFeedbackSubmitStatus.accepted);
      expect(newClient.expectedOwnerUids, ['new-anonymous-uid']);
      expect(factoryCalls, 1);
      expect(oldResume.closed, isTrue);
      expect(oldClient.expectedOwnerUids, isEmpty);
      expect(oldStore.items, isEmpty);
    },
  );

  for (final unsafe
      in <({String name, String? uid, bool anonymous, bool journal})>[
        (name: 'empty UID', uid: '   ', anonymous: true, journal: false),
        (name: 'same UID', uid: 'deleted-uid', anonymous: true, journal: false),
        (
          name: 'different durable UID',
          uid: 'linked-user',
          anonymous: false,
          journal: false,
        ),
        (
          name: 'outstanding journal',
          uid: 'new-anonymous-uid',
          anonymous: true,
          journal: true,
        ),
      ]) {
    test('${unsafe.name} never activates a replacement', () async {
      var factoryCalls = 0;
      final oldService = _service(
        store: _Store(),
        client: _Client(),
        currentUid: () => unsafe.uid,
        deletionActive: () async => unsafe.journal,
      );
      final lifecycle = ContentFeedbackLifecycle(
        initialService: oldService,
        createService: () {
          factoryCalls += 1;
          return _service(
            store: _Store(),
            client: _Client(),
            currentUid: () => unsafe.uid,
            deletionActive: () async => unsafe.journal,
          );
        },
        currentIdentity: () => (uid: unsafe.uid, isAnonymous: unsafe.anonymous),
        durableJournalActive: () async => unsafe.journal,
      );

      expect(
        await lifecycle.activateAfterCompletedDeletion('deleted-uid'),
        isFalse,
      );
      expect(factoryCalls, 0);
      expect(
        (await oldService.submit(context, draft)).status,
        ContentFeedbackSubmitStatus.closed,
      );
    });
  }

  test('a failed authoritative clear never creates a replacement', () async {
    var factoryCalls = 0;
    final oldService = _service(
      store: _Store(failClearCounts: const {2}),
      client: _Client(),
      currentUid: () => 'new-anonymous-uid',
      deletionActive: () async => false,
    );
    final lifecycle = ContentFeedbackLifecycle(
      initialService: oldService,
      createService: () {
        factoryCalls += 1;
        return _service(
          store: _Store(),
          client: _Client(),
          currentUid: () => 'new-anonymous-uid',
          deletionActive: () async => false,
        );
      },
      currentIdentity: () => (uid: 'new-anonymous-uid', isAnonymous: true),
      durableJournalActive: () async => false,
    );

    expect(
      await lifecycle.activateAfterCompletedDeletion('deleted-uid'),
      isFalse,
    );
    expect(factoryCalls, 0);
    expect(
      (await oldService.submit(context, draft)).status,
      ContentFeedbackSubmitStatus.closed,
    );
  });

  test(
    'a completed-checkpoint restart activates only after local cleanup',
    () async {
      var uid = 'new-anonymous-uid';
      var journalActive = true;
      final oldClient = _Client();
      final newClient = _Client();
      final lifecycle = ContentFeedbackLifecycle(
        initialService: _service(
          store: _Store(items: [_pending('old-queued', 'deleted-uid')]),
          client: oldClient,
          currentUid: () => uid,
          deletionActive: () async => journalActive,
        ),
        createService: () => _service(
          store: _Store(),
          client: newClient,
          currentUid: () => uid,
          deletionActive: () async => journalActive,
        ),
        currentIdentity: () => (uid: uid, isAnonymous: true),
        durableJournalActive: () async => journalActive,
      );
      final events = <String>[];
      final operations = _CleanupOperations(
        events: events,
        deleteRemote: () async {
          events.add('completed-checkpoint-resume');
          await lifecycle.closeAndDiscard();
        },
      );
      final workflow = AccountDeletionWorkflow(
        operations,
        completeCheckpoint: () async {
          events.add('checkpoint-remove');
          journalActive = false;
          expect(
            await lifecycle.activateAfterCompletedDeletion('deleted-uid'),
            isTrue,
          );
          events.add('feedback-activate');
        },
      );

      await workflow.run();
      final submitted = await lifecycle.submit(context, draft);

      expect(events, <String>[
        'completed-checkpoint-resume',
        'local-reset',
        'push-disable',
        'image-delete',
        'tts-clear',
        'memory-reset',
        'checkpoint-remove',
        'feedback-activate',
      ]);
      expect(submitted.status, ContentFeedbackSubmitStatus.accepted);
      expect(newClient.expectedOwnerUids, ['new-anonymous-uid']);
      expect(oldClient.expectedOwnerUids, isEmpty);
    },
  );

  test(
    'remote deletion failure retains a closed service and journal',
    () async {
      var journalActive = true;
      var factoryCalls = 0;
      final oldService = _service(
        store: _Store(),
        client: _Client(),
        currentUid: () => 'deleted-uid',
        deletionActive: () async => journalActive,
      );
      final lifecycle = ContentFeedbackLifecycle(
        initialService: oldService,
        createService: () {
          factoryCalls += 1;
          return _service(
            store: _Store(),
            client: _Client(),
            currentUid: () => 'new-anonymous-uid',
            deletionActive: () async => journalActive,
          );
        },
        currentIdentity: () => (uid: 'deleted-uid', isAnonymous: true),
        durableJournalActive: () async => journalActive,
      );
      final operations = _CleanupOperations(
        events: <String>[],
        deleteRemote: () async {
          await lifecycle.closeAndDiscard();
          throw StateError('remote unavailable');
        },
      );

      await expectLater(
        AccountDeletionWorkflow(operations).run(),
        throwsStateError,
      );

      expect(journalActive, isTrue);
      expect(factoryCalls, 0);
      expect(
        (await oldService.submit(context, draft)).status,
        ContentFeedbackSubmitStatus.closed,
      );
      expect(operations.events, isEmpty);
    },
  );

  test('local cleanup failure retains a closed service and journal', () async {
    var uid = 'deleted-uid';
    var journalActive = true;
    var factoryCalls = 0;
    final oldService = _service(
      store: _Store(),
      client: _Client(),
      currentUid: () => uid,
      deletionActive: () async => journalActive,
    );
    final lifecycle = ContentFeedbackLifecycle(
      initialService: oldService,
      createService: () {
        factoryCalls += 1;
        return _service(
          store: _Store(),
          client: _Client(),
          currentUid: () => uid,
          deletionActive: () async => journalActive,
        );
      },
      currentIdentity: () => (uid: uid, isAnonymous: true),
      durableJournalActive: () async => journalActive,
    );
    final operations = _CleanupOperations(
      events: <String>[],
      deleteRemote: () async {
        await lifecycle.closeAndDiscard();
        uid = 'new-anonymous-uid';
      },
    )..localResetFailure = StateError('disk unavailable');
    var completionCalls = 0;
    final workflow = AccountDeletionWorkflow(
      operations,
      completeCheckpoint: () async {
        completionCalls += 1;
        journalActive = false;
        await lifecycle.activateAfterCompletedDeletion('deleted-uid');
      },
    );

    await expectLater(workflow.run(), throwsA(isA<AccountDeletionFailure>()));

    expect(journalActive, isTrue);
    expect(completionCalls, 0);
    expect(factoryCalls, 0);
    expect(
      (await oldService.submit(context, draft)).status,
      ContentFeedbackSubmitStatus.closed,
    );
  });
}

ContentFeedbackService _service({
  required FeedbackOutboxStore store,
  required ContentFeedbackClient client,
  required String? Function() currentUid,
  required Future<bool> Function() deletionActive,
}) {
  var nextId = 0;
  return ContentFeedbackService(
    featureGate: const TesterFeedbackFeatureGate(enabled: true),
    outboxStore: store,
    client: client,
    currentUid: currentUid,
    versionProvider: const _Version(),
    createFeedbackId: () => 'feedback-${nextId += 1}',
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

class _Store implements FeedbackOutboxStore {
  _Store({
    List<ContentFeedbackOutboxItem>? items,
    this.failClearCounts = const {},
  }) : items = List.of(items ?? const []);

  List<ContentFeedbackOutboxItem> items;
  final Set<int> failClearCounts;
  int readCount = 0;
  int writeCount = 0;
  int clearCount = 0;

  @override
  Future<void> clear() async {
    clearCount += 1;
    if (failClearCounts.contains(clearCount)) throw StateError('clear failed');
    items.clear();
  }

  @override
  Future<List<ContentFeedbackOutboxItem>> read() async {
    readCount += 1;
    return List.of(items);
  }

  @override
  Future<void> write(List<ContentFeedbackOutboxItem> value) async {
    writeCount += 1;
    items = List.of(value);
  }
}

class _Client implements ContentFeedbackClient {
  final List<String> expectedOwnerUids = [];

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

class _CleanupOperations implements AccountDeletionCleanupOperations {
  _CleanupOperations({required this.events, required this.deleteRemote});

  final List<String> events;
  final Future<void> Function() deleteRemote;
  Object? localResetFailure;

  @override
  Future<void> deleteRemoteAccount() => deleteRemote();

  @override
  Future<void> resetLocalStorage() async {
    events.add('local-reset');
    if (localResetFailure case final failure?) throw failure;
  }

  @override
  Future<void> disablePush() async => events.add('push-disable');

  @override
  Future<void> deleteLocalImages() async => events.add('image-delete');

  @override
  Future<void> clearTtsCache() async => events.add('tts-clear');

  @override
  void resetInMemoryData() => events.add('memory-reset');
}
