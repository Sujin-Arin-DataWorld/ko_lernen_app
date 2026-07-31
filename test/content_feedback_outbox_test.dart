import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/config/tester_feedback_feature.dart';
import 'package:ko_lernen_app/models/content_feedback.dart';
import 'package:ko_lernen_app/services/content_feedback_client.dart';
import 'package:ko_lernen_app/services/content_feedback_outbox.dart';
import 'package:ko_lernen_app/services/content_feedback_service.dart';
import 'package:ko_lernen_app/services/content_feedback_version_provider.dart';

void main() {
  const context = ContentFeedbackContext(
    completionId: 'completion-42',
    contentType: 'scenario',
    contentId: 'cafe-order',
    contentLabel: 'At the cafe',
    level: 'A1',
    scoreSummary: '7/10',
  );
  const draft = ContentFeedbackDraft(
    category: FeedbackCategory.bug,
    message: 'The audio stops after one word.',
    issueArea: FeedbackIssueArea.audio,
  );

  group('ContentFeedbackService', () {
    test('persists before network and retries the same feedback ID', () async {
      final events = <String>[];
      final store = MemoryFeedbackOutboxStore(events: events);
      final client = FakeFeedbackClient(
        events: events,
        responses: [
          const ContentFeedbackClientFailure(
            ContentFeedbackFailureCategory.unavailable,
            retryable: true,
          ),
          ContentFeedbackAcknowledgement.accepted,
        ],
      );
      var allocatedIds = 0;
      final service = buildService(
        store: store,
        client: client,
        createFeedbackId: () {
          allocatedIds += 1;
          return 'feedback-once';
        },
      );

      final first = await service.submit(context, draft);

      expect(first.status, ContentFeedbackSubmitStatus.pending);
      expect(first.feedbackId, 'feedback-once');
      expect(events.first, 'write:feedback-once');
      expect(
        events.indexOf('write:feedback-once'),
        lessThan(events.indexOf('call:feedback-once')),
      );
      expect(store.items.single.submission.feedbackId, 'feedback-once');
      expect(store.items.single.retry.attemptCount, 1);

      final resumed = await service.resumePending();

      expect(resumed.delivered, 1);
      expect(client.feedbackIds, ['feedback-once', 'feedback-once']);
      expect(store.items, isEmpty);
      expect(allocatedIds, 1);
    });

    test('does not call the network when durable append fails', () async {
      final store = MemoryFeedbackOutboxStore(failNextWrite: true);
      final client = FakeFeedbackClient();
      final service = buildService(store: store, client: client);

      final result = await service.submit(context, draft);

      expect(result.status, ContentFeedbackSubmitStatus.failed);
      expect(result.failure, ContentFeedbackFailureCategory.storageUnavailable);
      expect(client.feedbackIds, isEmpty);
    });

    test('removes duplicate-completion acknowledgements', () async {
      final store = MemoryFeedbackOutboxStore();
      final service = buildService(
        store: store,
        client: FakeFeedbackClient(
          responses: [ContentFeedbackAcknowledgement.duplicateCompletion],
        ),
      );

      final result = await service.submit(context, draft);

      expect(result.status, ContentFeedbackSubmitStatus.duplicateCompletion);
      expect(store.items, isEmpty);
    });

    test(
      'returns authoritative passport values after durable delivery',
      () async {
        final store = MemoryFeedbackOutboxStore();
        final service = buildService(
          store: store,
          client: FakeFeedbackClient(
            responses: const [
              ContentFeedbackDelivery(
                acknowledgement: ContentFeedbackAcknowledgement.accepted,
                stampAccepted: true,
                passportCompletedMissionIds: <String>{'beta_scenario'},
                nextMissionId: 'beta_word_work',
              ),
            ],
          ),
        );

        final result = await service.submit(context, draft);

        expect(result.status, ContentFeedbackSubmitStatus.accepted);
        expect(result.stampAccepted, isTrue);
        expect(result.passportCompletedMissionIds, <String>{'beta_scenario'});
        expect(result.nextMissionId, 'beta_word_work');
        expect(store.items, isEmpty);
      },
    );

    test('keeps an acknowledged item pending when local erase fails', () async {
      final store = MemoryFeedbackOutboxStore(failNextClear: true);
      final service = buildService(store: store, client: FakeFeedbackClient());

      final result = await service.submit(context, draft);

      expect(result.status, ContentFeedbackSubmitStatus.pending);
      expect(result.failure, ContentFeedbackFailureCategory.storageUnavailable);
      expect(store.items.single.submission.feedbackId, 'new-feedback');
    });

    test('refuses item 21 without deleting the existing 20', () async {
      final existing = List<ContentFeedbackOutboxItem>.generate(
        feedbackOutboxMaxItems,
        (index) => pendingItem('feedback-$index'),
      );
      final store = MemoryFeedbackOutboxStore(items: existing);
      final client = FakeFeedbackClient();
      final service = buildService(store: store, client: client);

      final result = await service.submit(context, draft);

      expect(result.status, ContentFeedbackSubmitStatus.queueFull);
      expect(
        store.items.map((item) => item.submission.feedbackId),
        existing.map((item) => item.submission.feedbackId),
      );
      expect(client.feedbackIds, isEmpty);
    });

    test(
      'submission discards stale-UID records before applying the cap',
      () async {
        final store = MemoryFeedbackOutboxStore(
          items: List<ContentFeedbackOutboxItem>.generate(
            feedbackOutboxMaxItems,
            (index) => pendingItem('old-feedback-$index', ownerUid: 'old-uid'),
          ),
        );
        final client = FakeFeedbackClient();
        final service = buildService(store: store, client: client);

        final result = await service.submit(context, draft);

        expect(result.status, ContentFeedbackSubmitStatus.accepted);
        expect(client.feedbackIds, ['new-feedback']);
        expect(store.items, isEmpty);
      },
    );

    test(
      'rechecks UID after persistence immediately before the callable',
      () async {
        var liveUid = 'current-uid';
        final store = MemoryFeedbackOutboxStore(
          onWrite: (writeCount) {
            if (writeCount == 2) liveUid = 'replacement-uid';
          },
        );
        final client = FakeFeedbackClient();
        final service = buildService(
          store: store,
          client: client,
          currentUid: () => liveUid,
        );

        final result = await service.submit(context, draft);

        expect(result.status, ContentFeedbackSubmitStatus.failed);
        expect(
          result.failure,
          ContentFeedbackFailureCategory.authenticationRequired,
        );
        expect(client.feedbackIds, isEmpty);
        expect(store.items, isEmpty);
      },
    );

    test(
      'keeps the initial write pending when UID changes and discard fails',
      () async {
        var liveUid = 'current-uid';
        final store = MemoryFeedbackOutboxStore(
          failNextClear: true,
          onWrite: (writeCount) {
            if (writeCount == 1) liveUid = 'replacement-uid';
          },
        );
        final client = FakeFeedbackClient();
        final service = buildService(
          store: store,
          client: client,
          currentUid: () => liveUid,
        );

        final result = await service.submit(context, draft);

        expect(result.status, ContentFeedbackSubmitStatus.pending);
        expect(result.feedbackId, 'new-feedback');
        expect(
          result.failure,
          ContentFeedbackFailureCategory.storageUnavailable,
        );
        expect(client.feedbackIds, isEmpty);
        expect(store.items.single.submission.feedbackId, 'new-feedback');
      },
    );

    test('discards another UID and drains only the current UID', () async {
      final store = MemoryFeedbackOutboxStore(
        items: [
          pendingItem('old-feedback', ownerUid: 'old-uid'),
          pendingItem('current-feedback'),
        ],
      );
      final client = FakeFeedbackClient(
        responses: [ContentFeedbackAcknowledgement.accepted],
      );
      final service = buildService(store: store, client: client);

      final result = await service.resumePending();

      expect(result.discarded, 1);
      expect(result.delivered, 1);
      expect(client.feedbackIds, ['current-feedback']);
      expect(store.items, isEmpty);
    });

    test(
      'post-delete restart discards the old anonymous UID without sending',
      () async {
        final store = MemoryFeedbackOutboxStore(
          items: [pendingItem('old-feedback', ownerUid: 'old-anonymous')],
        );
        final client = FakeFeedbackClient();
        final service = buildService(
          store: store,
          client: client,
          currentUid: () => 'new-anonymous',
        );

        final result = await service.resumePending();

        expect(result.discarded, 1);
        expect(result.delivered, 0);
        expect(client.feedbackIds, isEmpty);
        expect(store.items, isEmpty);
      },
    );

    test('does not read or drain while deletion is active', () async {
      final store = MemoryFeedbackOutboxStore(
        items: [pendingItem('pending-feedback')],
      );
      final client = FakeFeedbackClient();
      final service = buildService(
        store: store,
        client: client,
        deletionActive: () async => true,
      );

      final result = await service.resumePending();

      expect(result.blockedByDeletion, isTrue);
      expect(store.readCount, 0);
      expect(client.feedbackIds, isEmpty);
    });

    test('closeAndDiscard closes future work and erases the queue', () async {
      final store = MemoryFeedbackOutboxStore(
        items: [pendingItem('pending-feedback')],
      );
      final client = FakeFeedbackClient();
      final service = buildService(store: store, client: client);

      await service.closeAndDiscard();
      final resumed = await service.resumePending();
      final submitted = await service.submit(context, draft);

      expect(store.clearCount, 1);
      expect(store.items, isEmpty);
      expect(resumed.closed, isTrue);
      expect(submitted.status, ContentFeedbackSubmitStatus.closed);
      expect(client.feedbackIds, isEmpty);
    });

    test(
      'closeAndDiscard stops a submit paused in its final deletion gate',
      () async {
        final finalGateStarted = Completer<void>();
        final releaseFinalGate = Completer<bool>();
        var deletionReads = 0;
        final store = MemoryFeedbackOutboxStore();
        final client = FakeFeedbackClient();
        final service = buildService(
          store: store,
          client: client,
          deletionActive: () {
            deletionReads += 1;
            if (deletionReads == 3) {
              finalGateStarted.complete();
              return releaseFinalGate.future;
            }
            return Future<bool>.value(false);
          },
        );

        final submit = service.submit(context, draft);
        await finalGateStarted.future;
        final discard = service.closeAndDiscard();
        releaseFinalGate.complete(false);

        final result = await submit;
        await discard;

        expect(result.status, ContentFeedbackSubmitStatus.closed);
        expect(client.feedbackIds, isEmpty);
        expect(store.items, isEmpty);
      },
    );

    test(
      'closeAndDiscard stops a resume paused in its final deletion gate',
      () async {
        final finalGateStarted = Completer<void>();
        final releaseFinalGate = Completer<bool>();
        var deletionReads = 0;
        final store = MemoryFeedbackOutboxStore(
          items: [pendingItem('pending-feedback')],
        );
        final client = FakeFeedbackClient();
        final service = buildService(
          store: store,
          client: client,
          deletionActive: () {
            deletionReads += 1;
            if (deletionReads == 3) {
              finalGateStarted.complete();
              return releaseFinalGate.future;
            }
            return Future<bool>.value(false);
          },
        );

        final resume = service.resumePending();
        await finalGateStarted.future;
        final discard = service.closeAndDiscard();
        releaseFinalGate.complete(false);

        final result = await resume;
        await discard;

        expect(result.delivered, 0);
        expect(result.closed, isTrue);
        expect(client.feedbackIds, isEmpty);
        expect(store.items, isEmpty);
      },
    );

    test('disabled feature is a dependency-free no-op', () async {
      final store = MemoryFeedbackOutboxStore();
      final client = FakeFeedbackClient();
      final service = buildService(
        store: store,
        client: client,
        featureEnabled: false,
        currentUid: () => throw StateError('auth must not be read'),
        deletionActive: () => throw StateError('gate must not be read'),
        versionProvider: ThrowingVersionProvider(),
        createFeedbackId: () => throw StateError('UUID must not be read'),
      );

      final submitted = await service.submit(context, draft);
      final resumed = await service.resumePending();

      expect(submitted.status, ContentFeedbackSubmitStatus.disabled);
      expect(resumed.disabled, isTrue);
      expect(store.readCount, 0);
      expect(store.writeCount, 0);
      expect(client.feedbackIds, isEmpty);
    });

    test('production service preserves the disabled no-op gate', () async {
      final service = ContentFeedbackService.production(
        featureGate: const TesterFeedbackFeatureGate(enabled: false),
        currentUid: () => throw StateError('auth must not be read'),
        deletionActive: () => throw StateError('gate must not be read'),
        platform: () => throw StateError('platform must not be read'),
        locale: () => throw StateError('locale must not be read'),
      );

      final result = await service.resumePending();

      expect(result.disabled, isTrue);
    });
  });

  group('SecureFeedbackOutboxStore', () {
    test(
      'discards malformed records and rewrites only validated items',
      () async {
        final secureStorage = MemoryFeedbackSecureStorage();
        final valid = pendingItem('valid-feedback');
        secureStorage.values[SecureFeedbackOutboxStore.storageKey] = jsonEncode(
          [
            valid.toJson(),
            {
              'payload': {...valid.submission.toWire(), 'message': 'x' * 1001},
              'createdAt': valid.createdAt.toIso8601String(),
              'ownerUid': valid.ownerUid,
              'retry': {'attemptCount': 0, 'lastFailure': null},
              'status': 'pending',
            },
            {'payload': 'not-a-map'},
          ],
        );
        final store = SecureFeedbackOutboxStore(storage: secureStorage);

        final items = await store.read();

        expect(items.map((item) => item.submission.feedbackId), [
          'valid-feedback',
        ]);
        final rewritten =
            jsonDecode(
                  secureStorage.values[SecureFeedbackOutboxStore.storageKey]!,
                )
                as List<Object?>;
        expect(rewritten, hasLength(1));
      },
    );

    test(
      'rejects an over-capacity write without touching stored data',
      () async {
        final secureStorage = MemoryFeedbackSecureStorage();
        secureStorage.values[SecureFeedbackOutboxStore.storageKey] = 'sentinel';
        final store = SecureFeedbackOutboxStore(storage: secureStorage);
        final items = List<ContentFeedbackOutboxItem>.generate(
          feedbackOutboxMaxItems + 1,
          (index) => pendingItem('feedback-$index'),
        );

        await expectLater(store.write(items), throwsStateError);

        expect(
          secureStorage.values[SecureFeedbackOutboxStore.storageKey],
          'sentinel',
        );
      },
    );
  });

  group('ContentFeedbackCallableClient', () {
    test(
      'uses the protected callable and limited-use App Check token',
      () async {
        String? name;
        Map<String, Object?>? data;
        HttpsCallableOptions? options;
        final client = ContentFeedbackCallableClient(({
          required callableName,
          required payload,
          required callableOptions,
        }) async {
          name = callableName;
          data = payload;
          options = callableOptions;
          return {'accepted': true, 'duplicate': false};
        });
        final submission = pendingItem('feedback-callable').submission;

        final result = await client.submit(submission);

        expect(result.acknowledgement, ContentFeedbackAcknowledgement.accepted);
        expect(result.stampAccepted, isFalse);
        expect(result.passportCompletedMissionIds, isEmpty);
        expect(result.nextMissionId, isNull);
        expect(name, 'submitTesterFeedback');
        expect(data, submission.toWire());
        expect(options?.limitedUseAppCheckToken, isTrue);
      },
    );

    test(
      'parses authoritative passport values from an accepted response',
      () async {
        final client = ContentFeedbackCallableClient(({
          required callableName,
          required payload,
          required callableOptions,
        }) async {
          return {
            'accepted': true,
            'duplicate': false,
            'stampAccepted': true,
            'passportCompletedMissionIds': ['beta_scenario'],
            'nextMissionId': 'beta_word_work',
            'nextMissionLabelKey': 'testerFeedbackMissionWordWork',
          };
        });

        final result = await client.submit(
          pendingItem(
            'feedback-authoritative',
            betaMissionId: 'beta_scenario',
          ).submission,
        );

        expect(result.acknowledgement, ContentFeedbackAcknowledgement.accepted);
        expect(result.stampAccepted, isTrue);
        expect(result.passportCompletedMissionIds, <String>{'beta_scenario'});
        expect(result.nextMissionId, 'beta_word_work');
      },
    );

    test(
      'defaults passport data when the stamped mission mismatches content',
      () async {
        final client = ContentFeedbackCallableClient(({
          required callableName,
          required payload,
          required callableOptions,
        }) async {
          return {
            'accepted': true,
            'duplicate': false,
            'stampAccepted': true,
            'passportCompletedMissionIds': ['beta_scenario'],
            'nextMissionId': 'beta_word_work',
            'nextMissionLabelKey': 'testerFeedbackMissionWordWork',
          };
        });

        final result = await client.submit(
          pendingItem(
            'feedback-mission-content-mismatch',
            betaMissionId: 'beta_scenario',
            contentType: 'listening',
          ).submission,
        );

        expect(result.acknowledgement, ContentFeedbackAcknowledgement.accepted);
        expect(result.stampAccepted, isFalse);
        expect(result.passportCompletedMissionIds, isEmpty);
        expect(result.nextMissionId, isNull);
      },
    );

    test('defaults passport data when completed mission IDs repeat', () async {
      final client = ContentFeedbackCallableClient(({
        required callableName,
        required payload,
        required callableOptions,
      }) async {
        return {
          'accepted': true,
          'duplicate': false,
          'stampAccepted': true,
          'passportCompletedMissionIds': ['beta_scenario', 'beta_scenario'],
          'nextMissionId': 'beta_word_work',
          'nextMissionLabelKey': 'testerFeedbackMissionWordWork',
        };
      });

      final result = await client.submit(
        pendingItem(
          'feedback-duplicate-mission-ids',
          betaMissionId: 'beta_scenario',
        ).submission,
      );

      expect(result.acknowledgement, ContentFeedbackAcknowledgement.accepted);
      expect(result.stampAccepted, isFalse);
      expect(result.passportCompletedMissionIds, isEmpty);
      expect(result.nextMissionId, isNull);
    });

    test(
      'defaults passport data when next mission is known but not first',
      () async {
        final client = ContentFeedbackCallableClient(({
          required callableName,
          required payload,
          required callableOptions,
        }) async {
          return {
            'accepted': true,
            'duplicate': false,
            'stampAccepted': true,
            'passportCompletedMissionIds': ['beta_scenario'],
            'nextMissionId': 'beta_listening',
            'nextMissionLabelKey': 'testerFeedbackMissionListening',
          };
        });

        final result = await client.submit(
          pendingItem(
            'feedback-wrong-next-mission',
            betaMissionId: 'beta_scenario',
          ).submission,
        );

        expect(result.acknowledgement, ContentFeedbackAcknowledgement.accepted);
        expect(result.stampAccepted, isFalse);
        expect(result.passportCompletedMissionIds, isEmpty);
        expect(result.nextMissionId, isNull);
      },
    );

    test(
      'defaults malformed passport fields without trusting server prose',
      () async {
        final client = ContentFeedbackCallableClient(({
          required callableName,
          required payload,
          required callableOptions,
        }) async {
          return {
            'accepted': true,
            'duplicate': false,
            'stampAccepted': true,
            'passportCompletedMissionIds': ['beta_scenario', 7],
            'nextMissionId': 'beta_injected',
            'nextMissionLabelKey': 'Untrusted instructions',
          };
        });

        final result = await client.submit(
          pendingItem(
            'feedback-malformed-response',
            betaMissionId: 'beta_scenario',
          ).submission,
        );

        expect(result.acknowledgement, ContentFeedbackAcknowledgement.accepted);
        expect(result.stampAccepted, isFalse);
        expect(result.passportCompletedMissionIds, isEmpty);
        expect(result.nextMissionId, isNull);
      },
    );

    test(
      'defaults passport data when a duplicate response claims a stamp',
      () async {
        final client = ContentFeedbackCallableClient(({
          required callableName,
          required payload,
          required callableOptions,
        }) async {
          return {
            'accepted': false,
            'duplicate': true,
            'stampAccepted': true,
            'passportCompletedMissionIds': ['beta_scenario'],
            'nextMissionId': 'beta_word_work',
          };
        });

        final result = await client.submit(
          pendingItem('feedback-duplicate-response').submission,
        );

        expect(
          result.acknowledgement,
          ContentFeedbackAcknowledgement.duplicateCompletion,
        );
        expect(result.stampAccepted, isFalse);
        expect(result.passportCompletedMissionIds, isEmpty);
        expect(result.nextMissionId, isNull);
      },
    );
  });
}

ContentFeedbackService buildService({
  required FeedbackOutboxStore store,
  required ContentFeedbackClient client,
  bool featureEnabled = true,
  String? Function()? currentUid,
  Future<bool> Function()? deletionActive,
  ContentFeedbackVersionProvider? versionProvider,
  String Function()? createFeedbackId,
}) {
  return ContentFeedbackService(
    featureGate: TesterFeedbackFeatureGate(enabled: featureEnabled),
    outboxStore: store,
    client: client,
    currentUid: currentUid ?? () => 'current-uid',
    versionProvider: versionProvider ?? FixedVersionProvider('2.0.1+6'),
    createFeedbackId: createFeedbackId ?? () => 'new-feedback',
    now: () => DateTime.utc(2026, 7, 31, 10),
    platform: () => 'android',
    locale: () => 'de',
    deletionActive: deletionActive ?? () async => false,
  );
}

ContentFeedbackOutboxItem pendingItem(
  String feedbackId, {
  String ownerUid = 'current-uid',
  String? betaMissionId,
  String contentType = 'scenario',
}) {
  return ContentFeedbackOutboxItem.pending(
    submission: ContentFeedbackSubmission(
      feedbackId: feedbackId,
      context: ContentFeedbackContext(
        completionId: 'completion-42',
        contentType: contentType,
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
      betaMissionId: betaMissionId,
    ),
    createdAt: DateTime.utc(2026, 7, 31, 10),
    ownerUid: ownerUid,
  );
}

class MemoryFeedbackOutboxStore implements FeedbackOutboxStore {
  MemoryFeedbackOutboxStore({
    List<ContentFeedbackOutboxItem>? items,
    this.events,
    this.failNextWrite = false,
    this.failNextClear = false,
    this.onWrite,
  }) : items = List.of(items ?? const []);

  List<ContentFeedbackOutboxItem> items;
  final List<String>? events;
  bool failNextWrite;
  bool failNextClear;
  final void Function(int writeCount)? onWrite;
  int readCount = 0;
  int writeCount = 0;
  int clearCount = 0;

  @override
  Future<void> clear() async {
    clearCount += 1;
    if (failNextClear) {
      failNextClear = false;
      throw StateError('clear failed');
    }
    items = [];
  }

  @override
  Future<List<ContentFeedbackOutboxItem>> read() async {
    readCount += 1;
    return List.of(items);
  }

  @override
  Future<void> write(List<ContentFeedbackOutboxItem> value) async {
    writeCount += 1;
    onWrite?.call(writeCount);
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('write failed');
    }
    items = List.of(value);
    events?.add(
      value.isEmpty
          ? 'write:empty'
          : 'write:${value.last.submission.feedbackId}',
    );
  }
}

class MemoryFeedbackSecureStorage implements FeedbackSecureStorage {
  final Map<String, String> values = {};

  @override
  Future<void> delete({required String key}) async {
    values.remove(key);
  }

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }
}

class FakeFeedbackClient implements ContentFeedbackClient {
  FakeFeedbackClient({this.events, List<Object>? responses})
    : responses = List.of(responses ?? const []);

  final List<String>? events;
  final List<Object> responses;
  final List<String> feedbackIds = [];

  @override
  Future<ContentFeedbackDelivery> submit(
    ContentFeedbackSubmission submission,
  ) async {
    feedbackIds.add(submission.feedbackId);
    events?.add('call:${submission.feedbackId}');
    final response = responses.isEmpty
        ? ContentFeedbackAcknowledgement.accepted
        : responses.removeAt(0);
    if (response is ContentFeedbackClientFailure) throw response;
    if (response is ContentFeedbackDelivery) return response;
    return ContentFeedbackDelivery(
      acknowledgement: response as ContentFeedbackAcknowledgement,
    );
  }
}

class ThrowingVersionProvider implements ContentFeedbackVersionProvider {
  @override
  Future<String> readVersion() => throw StateError('version must not be read');
}

class FixedVersionProvider implements ContentFeedbackVersionProvider {
  FixedVersionProvider(this.version);

  final String version;

  @override
  Future<String> readVersion() async => version;
}
