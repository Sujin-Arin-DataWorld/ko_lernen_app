import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/config/tester_feedback_feature.dart';
import 'package:ko_lernen_app/models/content_feedback.dart';
import 'package:ko_lernen_app/services/content_feedback_client.dart';
import 'package:ko_lernen_app/services/content_feedback_outbox.dart';
import 'package:ko_lernen_app/services/content_feedback_service.dart';
import 'package:ko_lernen_app/services/content_feedback_version_provider.dart';

void main() {
  test(
    'resume reports only the feedback ID durably removed from the outbox',
    () async {
      final store = _MemoryStore(<ContentFeedbackOutboxItem>[
        _pending('feedback-delivered'),
        _pending('feedback-retained'),
      ]);
      final service = _service(
        store: store,
        client: _SequencedClient(<Object>[
          ContentFeedbackAcknowledgement.accepted,
          const ContentFeedbackClientFailure(
            ContentFeedbackFailureCategory.unavailable,
            retryable: true,
          ),
        ]),
      );

      final result = await service.resumePending();

      expect(result.delivered, 1);
      expect(result.deliveredFeedbackIds, const <String>{'feedback-delivered'});
      expect(
        store.items.map((item) => item.submission.feedbackId),
        const <String>['feedback-retained'],
      );
    },
  );

  test('resume does not report an ID when durable deletion fails', () async {
    final store = _MemoryStore(
      <ContentFeedbackOutboxItem>[_pending('feedback-still-queued')],
      failNextClear: true,
    );
    final service = _service(
      store: store,
      client: _SequencedClient(<Object>[ContentFeedbackAcknowledgement.accepted]),
    );

    final result = await service.resumePending();

    expect(result.delivered, 0);
    expect(result.deliveredFeedbackIds, isEmpty);
    expect(
      store.items.map((item) => item.submission.feedbackId),
      const <String>['feedback-still-queued'],
    );
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

class _MemoryStore implements FeedbackOutboxStore {
  _MemoryStore(List<ContentFeedbackOutboxItem> items, {this.failNextClear = false})
    : items = List.of(items);

  List<ContentFeedbackOutboxItem> items;
  bool failNextClear;

  @override
  Future<void> clear() async {
    if (failNextClear) {
      failNextClear = false;
      throw StateError('clear failed');
    }
    items.clear();
  }

  @override
  Future<List<ContentFeedbackOutboxItem>> read() async => List.of(items);

  @override
  Future<void> write(List<ContentFeedbackOutboxItem> value) async {
    items = List.of(value);
  }
}

class _SequencedClient implements ContentFeedbackClient {
  _SequencedClient(List<Object> responses) : _responses = List.of(responses);

  final List<Object> _responses;

  @override
  Future<ContentFeedbackDelivery> submit(
    ContentFeedbackSubmission submission, {
    required String expectedOwnerUid,
  }) async {
    final response = _responses.removeAt(0);
    if (response is ContentFeedbackClientFailure) throw response;
    return ContentFeedbackDelivery(
      acknowledgement: response as ContentFeedbackAcknowledgement,
    );
  }
}

class _VersionProvider implements ContentFeedbackVersionProvider {
  const _VersionProvider();

  @override
  Future<String> readVersion() async => '2.0.1+6';
}
