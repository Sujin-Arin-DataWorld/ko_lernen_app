import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/config/tester_feedback_feature.dart';
import 'package:ko_lernen_app/main.dart';
import 'package:ko_lernen_app/models/content_feedback.dart';
import 'package:ko_lernen_app/services/content_feedback_client.dart';
import 'package:ko_lernen_app/services/content_feedback_lifecycle.dart';
import 'package:ko_lernen_app/services/content_feedback_outbox.dart';
import 'package:ko_lernen_app/services/content_feedback_service.dart';
import 'package:ko_lernen_app/services/content_feedback_version_provider.dart';
import 'package:ko_lernen_app/widgets/sori/content_feedback_card.dart';

void main() {
  testWidgets(
    'concurrent resumed signals stay serialized by the existing service gate',
    (tester) async {
      final store = _Store(<ContentFeedbackOutboxItem>[
        _pending('feedback-pending'),
      ]);
      final client = _BlockingClient();
      final service = _service(store: store, client: client);
      var factoryCalls = 0;
      final lifecycle = ContentFeedbackLifecycle(
        initialService: service,
        createService: () {
          factoryCalls += 1;
          return _service(store: _Store(const []), client: _BlockingClient());
        },
        currentIdentity: () => (uid: 'current-uid', isAnonymous: true),
        durableJournalActive: (_) async => false,
      );
      var resumeRequests = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: ContentFeedbackLifecycleObserver(
            resumePending: () {
              resumeRequests += 1;
              return lifecycle.resumePending();
            },
            onResumeResult: (_) {},
            child: const SizedBox.shrink(),
          ),
        ),
      );

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await client.started.future;

      expect(resumeRequests, 2);
      expect(client.submitCalls, 1);
      expect(client.maximumConcurrentCalls, 1);
      expect(factoryCalls, 0);

      client.release.complete();
      await tester.pumpAndSettle();

      expect(store.items, isEmpty);
      expect(client.maximumConcurrentCalls, 1);
      expect(factoryCalls, 0);

      await tester.pumpWidget(const SizedBox.shrink());
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(resumeRequests, 2);
    },
  );

  testWidgets('resumed delivery IDs are reported to the active card scope', (
    tester,
  ) async {
    final deliveries = ContentFeedbackResumeDeliveryNotifier();
    addTearDown(deliveries.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ContentFeedbackLifecycleObserver(
          resumePending: () async => const ContentFeedbackResumeResult(
            deliveredFeedbackIds: <String>{'feedback-delivered'},
          ),
          onResumeResult: deliveries.report,
          child: const SizedBox.shrink(),
        ),
      ),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(deliveries.deliveredFeedbackIds, const <String>{'feedback-delivered'});
  });

  testWidgets('disposed observers do not report a late resume result', (
    tester,
  ) async {
    final deliveries = ContentFeedbackResumeDeliveryNotifier();
    addTearDown(deliveries.dispose);
    final result = Completer<ContentFeedbackResumeResult>();
    await tester.pumpWidget(
      MaterialApp(
        home: ContentFeedbackLifecycleObserver(
          resumePending: () => result.future,
          onResumeResult: deliveries.report,
          child: const SizedBox.shrink(),
        ),
      ),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    result.complete(
      const ContentFeedbackResumeResult(
        deliveredFeedbackIds: <String>{'feedback-late'},
      ),
    );
    await tester.pumpAndSettle();

    expect(deliveries.deliveredFeedbackIds, isEmpty);
  });
}

ContentFeedbackService _service({
  required FeedbackOutboxStore store,
  required ContentFeedbackClient client,
}) {
  return ContentFeedbackService(
    featureGate: const TesterFeedbackFeatureGate(enabled: true),
    outboxStore: store,
    client: client,
    currentUid: () => 'current-uid',
    versionProvider: const _VersionProvider(),
    createFeedbackId: () => 'unused-feedback-id',
    now: () => DateTime.utc(2026, 8, 2),
    platform: () => 'android',
    locale: () => 'de',
    deletionActive: () async => false,
  );
}

ContentFeedbackOutboxItem _pending(String feedbackId) {
  return ContentFeedbackOutboxItem.pending(
    submission: ContentFeedbackSubmission(
      feedbackId: feedbackId,
      context: const ContentFeedbackContext(
        completionId: 'completion-42',
        contentType: 'scenario',
        contentId: 'cafe-order',
        contentLabel: 'At the cafe',
        level: 'A1',
        scoreSummary: '7/10',
      ),
      draft: const ContentFeedbackDraft(
        category: FeedbackCategory.bug,
        message: 'The audio stops after one word.',
        issueArea: FeedbackIssueArea.audio,
      ),
      appVersion: '2.0.1+6',
      platform: 'android',
      locale: 'de',
    ),
    createdAt: DateTime.utc(2026, 8, 2),
    ownerUid: 'current-uid',
  );
}

class _Store implements FeedbackOutboxStore {
  _Store(List<ContentFeedbackOutboxItem> items) : items = List.of(items);

  List<ContentFeedbackOutboxItem> items;

  @override
  Future<void> clear() async => items.clear();

  @override
  Future<List<ContentFeedbackOutboxItem>> read() async => List.of(items);

  @override
  Future<void> write(List<ContentFeedbackOutboxItem> value) async {
    items = List.of(value);
  }
}

class _BlockingClient implements ContentFeedbackClient {
  final Completer<void> started = Completer<void>();
  final Completer<void> release = Completer<void>();
  int submitCalls = 0;
  int _concurrentCalls = 0;
  int maximumConcurrentCalls = 0;

  @override
  Future<ContentFeedbackDelivery> submit(
    ContentFeedbackSubmission submission, {
    required String expectedOwnerUid,
  }) async {
    submitCalls += 1;
    _concurrentCalls += 1;
    if (_concurrentCalls > maximumConcurrentCalls) {
      maximumConcurrentCalls = _concurrentCalls;
    }
    if (!started.isCompleted) started.complete();
    await release.future;
    _concurrentCalls -= 1;
    return const ContentFeedbackDelivery(
      acknowledgement: ContentFeedbackAcknowledgement.accepted,
    );
  }
}

class _VersionProvider implements ContentFeedbackVersionProvider {
  const _VersionProvider();

  @override
  Future<String> readVersion() async => '2.0.1+6';
}
