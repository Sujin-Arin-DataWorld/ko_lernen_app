import 'dart:async';

import 'package:uuid/uuid.dart';

import '../config/tester_feedback_feature.dart';
import '../data/beta_mission_catalog.dart';
import '../models/content_feedback.dart';
import 'content_feedback_client.dart';
import 'content_feedback_outbox.dart';
import 'content_feedback_version_provider.dart';

typedef ContentFeedbackUidReader = String? Function();
typedef ContentFeedbackIdFactory = String Function();
typedef ContentFeedbackClock = DateTime Function();
typedef ContentFeedbackStringReader = String Function();
typedef ContentFeedbackDeletionStateReader = Future<bool> Function();

enum ContentFeedbackSubmitStatus {
  disabled,
  closed,
  invalid,
  blockedByDeletion,
  queueFull,
  accepted,
  duplicateCompletion,
  pending,
  failed,
}

class ContentFeedbackSubmitResult {
  const ContentFeedbackSubmitResult({
    required this.status,
    this.feedbackId,
    this.failure,
    this.stampAccepted = false,
    this.passportCompletedMissionIds = const <String>{},
    this.nextMissionId,
  });

  final ContentFeedbackSubmitStatus status;
  final String? feedbackId;
  final ContentFeedbackFailureCategory? failure;
  final bool stampAccepted;
  final Set<String> passportCompletedMissionIds;
  final String? nextMissionId;
}

class ContentFeedbackResumeResult {
  const ContentFeedbackResumeResult({
    this.delivered = 0,
    this.discarded = 0,
    this.remaining = 0,
    this.disabled = false,
    this.closed = false,
    this.blockedByDeletion = false,
  });

  final int delivered;
  final int discarded;
  final int remaining;
  final bool disabled;
  final bool closed;
  final bool blockedByDeletion;
}

class ContentFeedbackService {
  ContentFeedbackService({
    required this.featureGate,
    required this.outboxStore,
    required this.client,
    required this.currentUid,
    required this.versionProvider,
    required this.createFeedbackId,
    required this.now,
    required this.platform,
    required this.locale,
    required this.deletionActive,
  });

  factory ContentFeedbackService.production({
    required ContentFeedbackUidReader currentUid,
    required ContentFeedbackDeletionStateReader deletionActive,
    required ContentFeedbackStringReader platform,
    required ContentFeedbackStringReader locale,
    TesterFeedbackFeatureGate featureGate = const TesterFeedbackFeatureGate(),
  }) {
    return ContentFeedbackService(
      featureGate: featureGate,
      outboxStore: SecureFeedbackOutboxStore(),
      client: ContentFeedbackCallableClient.firebase(),
      currentUid: currentUid,
      versionProvider: const PackageContentFeedbackVersionProvider(),
      createFeedbackId: const Uuid().v4,
      now: DateTime.now,
      platform: platform,
      locale: locale,
      deletionActive: deletionActive,
    );
  }

  final TesterFeedbackFeatureGate featureGate;
  final FeedbackOutboxStore outboxStore;
  final ContentFeedbackClient client;
  final ContentFeedbackUidReader currentUid;
  final ContentFeedbackVersionProvider versionProvider;
  final ContentFeedbackIdFactory createFeedbackId;
  final ContentFeedbackClock now;
  final ContentFeedbackStringReader platform;
  final ContentFeedbackStringReader locale;
  final ContentFeedbackDeletionStateReader deletionActive;

  Future<void> _tail = Future<void>.value();
  bool _closed = false;

  Future<ContentFeedbackSubmitResult> submit(
    ContentFeedbackContext context,
    ContentFeedbackDraft draft,
  ) {
    if (!featureGate.isEnabled) {
      return Future.value(
        const ContentFeedbackSubmitResult(
          status: ContentFeedbackSubmitStatus.disabled,
        ),
      );
    }
    return _runExclusive(() => _submit(context, draft));
  }

  Future<ContentFeedbackResumeResult> resumePending() {
    if (!featureGate.isEnabled) {
      return Future.value(const ContentFeedbackResumeResult(disabled: true));
    }
    return _runExclusive(_resumePending);
  }

  Future<void> closeAndDiscard() {
    _closed = true;
    return _runExclusive(outboxStore.clear);
  }

  Future<ContentFeedbackSubmitResult> _submit(
    ContentFeedbackContext context,
    ContentFeedbackDraft draft,
  ) async {
    if (_closed) {
      return const ContentFeedbackSubmitResult(
        status: ContentFeedbackSubmitStatus.closed,
      );
    }
    if (!context.validate().isValid || !draft.validate().isValid) {
      return const ContentFeedbackSubmitResult(
        status: ContentFeedbackSubmitStatus.invalid,
        failure: ContentFeedbackFailureCategory.invalidRequest,
      );
    }
    if (await _deletionIsActive()) {
      return const ContentFeedbackSubmitResult(
        status: ContentFeedbackSubmitStatus.blockedByDeletion,
      );
    }

    final uid = _validatedCurrentUid();
    if (uid == null) {
      return const ContentFeedbackSubmitResult(
        status: ContentFeedbackSubmitStatus.failed,
        failure: ContentFeedbackFailureCategory.authenticationRequired,
      );
    }

    String appVersion;
    try {
      appVersion = await versionProvider.readVersion();
    } catch (_) {
      return const ContentFeedbackSubmitResult(
        status: ContentFeedbackSubmitStatus.failed,
        failure: ContentFeedbackFailureCategory.unavailable,
      );
    }

    String feedbackId;
    try {
      feedbackId = createFeedbackId();
    } catch (_) {
      return const ContentFeedbackSubmitResult(
        status: ContentFeedbackSubmitStatus.failed,
        failure: ContentFeedbackFailureCategory.unavailable,
      );
    }
    final submission = ContentFeedbackSubmission(
      feedbackId: feedbackId,
      context: context,
      draft: draft,
      appVersion: appVersion,
      platform: platform(),
      locale: locale(),
      betaMissionId: missionFor(context)?.id,
    );
    if (!submission.validate().isValid) {
      return const ContentFeedbackSubmitResult(
        status: ContentFeedbackSubmitStatus.invalid,
        failure: ContentFeedbackFailureCategory.invalidRequest,
      );
    }

    final item = ContentFeedbackOutboxItem.pending(
      submission: submission,
      createdAt: now(),
      ownerUid: uid,
    );
    List<ContentFeedbackOutboxItem> queue;
    try {
      queue = List.of(await outboxStore.read());
      queue.removeWhere((queued) => queued.ownerUid != uid);
      if (queue.length >= feedbackOutboxMaxItems) {
        return ContentFeedbackSubmitResult(
          status: ContentFeedbackSubmitStatus.queueFull,
          feedbackId: feedbackId,
        );
      }
      queue.add(item);
      await outboxStore.write(queue);
    } catch (_) {
      return ContentFeedbackSubmitResult(
        status: ContentFeedbackSubmitStatus.failed,
        feedbackId: feedbackId,
        failure: ContentFeedbackFailureCategory.storageUnavailable,
      );
    }

    return _deliverSubmitted(queue, item);
  }

  Future<ContentFeedbackSubmitResult> _deliverSubmitted(
    List<ContentFeedbackOutboxItem> queue,
    ContentFeedbackOutboxItem original,
  ) async {
    if (_closed || await _deletionIsActive()) {
      return ContentFeedbackSubmitResult(
        status: _closed
            ? ContentFeedbackSubmitStatus.closed
            : ContentFeedbackSubmitStatus.blockedByDeletion,
        feedbackId: original.submission.feedbackId,
      );
    }
    if (_validatedCurrentUid() != original.ownerUid) {
      try {
        await _discardById(queue, original.submission.feedbackId);
      } catch (_) {
        return ContentFeedbackSubmitResult(
          status: ContentFeedbackSubmitStatus.pending,
          feedbackId: original.submission.feedbackId,
          failure: ContentFeedbackFailureCategory.storageUnavailable,
        );
      }
      return ContentFeedbackSubmitResult(
        status: ContentFeedbackSubmitStatus.failed,
        feedbackId: original.submission.feedbackId,
        failure: ContentFeedbackFailureCategory.authenticationRequired,
      );
    }

    final attempted = original.recordAttempt();
    _replaceById(queue, attempted);
    try {
      await outboxStore.write(queue);
    } catch (_) {
      return ContentFeedbackSubmitResult(
        status: ContentFeedbackSubmitStatus.failed,
        feedbackId: original.submission.feedbackId,
        failure: ContentFeedbackFailureCategory.storageUnavailable,
      );
    }

    if (_closed) {
      return ContentFeedbackSubmitResult(
        status: ContentFeedbackSubmitStatus.closed,
        feedbackId: original.submission.feedbackId,
      );
    }
    if (await _deletionIsActive()) {
      return ContentFeedbackSubmitResult(
        status: ContentFeedbackSubmitStatus.blockedByDeletion,
        feedbackId: original.submission.feedbackId,
      );
    }
    if (_validatedCurrentUid() != original.ownerUid) {
      try {
        await _discardById(queue, original.submission.feedbackId);
      } catch (_) {
        return ContentFeedbackSubmitResult(
          status: ContentFeedbackSubmitStatus.pending,
          feedbackId: original.submission.feedbackId,
          failure: ContentFeedbackFailureCategory.storageUnavailable,
        );
      }
      return ContentFeedbackSubmitResult(
        status: ContentFeedbackSubmitStatus.failed,
        feedbackId: original.submission.feedbackId,
        failure: ContentFeedbackFailureCategory.authenticationRequired,
      );
    }

    ContentFeedbackAcknowledgement acknowledgement;
    try {
      acknowledgement = await client.submit(attempted.submission);
    } on ContentFeedbackClientFailure catch (failure) {
      await _retainFailure(queue, attempted, failure);
      return ContentFeedbackSubmitResult(
        status: failure.retryable
            ? ContentFeedbackSubmitStatus.pending
            : ContentFeedbackSubmitStatus.failed,
        feedbackId: attempted.submission.feedbackId,
        failure: failure.category,
      );
    } catch (_) {
      const failure = ContentFeedbackClientFailure(
        ContentFeedbackFailureCategory.unknown,
        retryable: true,
      );
      await _retainFailure(queue, attempted, failure);
      return ContentFeedbackSubmitResult(
        status: ContentFeedbackSubmitStatus.pending,
        feedbackId: attempted.submission.feedbackId,
        failure: failure.category,
      );
    }

    try {
      await _discardById(queue, attempted.submission.feedbackId);
      return ContentFeedbackSubmitResult(
        status: acknowledgement == ContentFeedbackAcknowledgement.accepted
            ? ContentFeedbackSubmitStatus.accepted
            : ContentFeedbackSubmitStatus.duplicateCompletion,
        feedbackId: attempted.submission.feedbackId,
      );
    } catch (_) {
      return ContentFeedbackSubmitResult(
        status: ContentFeedbackSubmitStatus.pending,
        feedbackId: attempted.submission.feedbackId,
        failure: ContentFeedbackFailureCategory.storageUnavailable,
      );
    }
  }

  Future<ContentFeedbackResumeResult> _resumePending() async {
    if (_closed) return const ContentFeedbackResumeResult(closed: true);
    if (await _deletionIsActive()) {
      return const ContentFeedbackResumeResult(blockedByDeletion: true);
    }
    final uid = _validatedCurrentUid();
    if (uid == null) return const ContentFeedbackResumeResult();

    List<ContentFeedbackOutboxItem> queue;
    try {
      queue = List.of(await outboxStore.read());
    } catch (_) {
      return const ContentFeedbackResumeResult();
    }
    final beforeOwnershipFilter = queue.length;
    queue.removeWhere((item) => item.ownerUid != uid);
    var discarded = beforeOwnershipFilter - queue.length;
    if (discarded > 0) {
      try {
        await _writeQueue(queue);
      } catch (_) {
        return ContentFeedbackResumeResult(
          discarded: 0,
          remaining: beforeOwnershipFilter,
        );
      }
    }

    var delivered = 0;
    final candidates = queue
        .where((item) => item.status == FeedbackOutboxLocalStatus.pending)
        .toList(growable: false);
    for (final original in candidates) {
      if (_closed) break;
      if (await _deletionIsActive()) {
        return ContentFeedbackResumeResult(
          delivered: delivered,
          discarded: discarded,
          remaining: queue.length,
          blockedByDeletion: true,
        );
      }
      if (_validatedCurrentUid() != uid) break;

      final attempted = original.recordAttempt();
      _replaceById(queue, attempted);
      try {
        await outboxStore.write(queue);
      } catch (_) {
        break;
      }
      if (_closed) break;
      if (await _deletionIsActive()) {
        return ContentFeedbackResumeResult(
          delivered: delivered,
          discarded: discarded,
          remaining: queue.length,
          blockedByDeletion: true,
        );
      }
      final liveUid = _validatedCurrentUid();
      if (liveUid != uid) {
        if (liveUid != null) {
          final beforeLiveFilter = queue.length;
          final retained = List<ContentFeedbackOutboxItem>.of(queue)
            ..removeWhere((item) => item.ownerUid != liveUid);
          try {
            await _writeQueue(retained);
            queue
              ..clear()
              ..addAll(retained);
            discarded += beforeLiveFilter - retained.length;
          } catch (_) {
            // Do not report a discard unless its durable write succeeded.
          }
        }
        break;
      }
      try {
        await client.submit(attempted.submission);
        await _discardById(queue, attempted.submission.feedbackId);
        delivered += 1;
      } on ContentFeedbackClientFailure catch (failure) {
        await _retainFailure(queue, attempted, failure);
        break;
      } catch (_) {
        await _retainFailure(
          queue,
          attempted,
          const ContentFeedbackClientFailure(
            ContentFeedbackFailureCategory.unknown,
            retryable: true,
          ),
        );
        break;
      }
    }
    return ContentFeedbackResumeResult(
      delivered: delivered,
      discarded: discarded,
      remaining: queue.length,
      closed: _closed,
    );
  }

  Future<bool> _deletionIsActive() async {
    try {
      return await deletionActive();
    } catch (_) {
      return true;
    }
  }

  String? _validatedCurrentUid() {
    final uid = currentUid()?.trim();
    if (uid == null || uid.isEmpty || uid.length > 128) return null;
    return uid;
  }

  Future<void> _retainFailure(
    List<ContentFeedbackOutboxItem> queue,
    ContentFeedbackOutboxItem attempted,
    ContentFeedbackClientFailure failure,
  ) async {
    _replaceById(queue, attempted.recordFailure(failure));
    try {
      await outboxStore.write(queue);
    } catch (_) {
      // The previously persisted attempted item remains safe and retryable.
    }
  }

  Future<void> _discardById(
    List<ContentFeedbackOutboxItem> queue,
    String feedbackId,
  ) async {
    final retained = List<ContentFeedbackOutboxItem>.of(queue)
      ..removeWhere((item) => item.submission.feedbackId == feedbackId);
    await _writeQueue(retained);
    queue
      ..clear()
      ..addAll(retained);
  }

  Future<void> _writeQueue(List<ContentFeedbackOutboxItem> queue) {
    return queue.isEmpty ? outboxStore.clear() : outboxStore.write(queue);
  }

  void _replaceById(
    List<ContentFeedbackOutboxItem> queue,
    ContentFeedbackOutboxItem replacement,
  ) {
    final index = queue.indexWhere(
      (item) => item.submission.feedbackId == replacement.submission.feedbackId,
    );
    if (index < 0) throw StateError('Feedback outbox item is missing.');
    queue[index] = replacement;
  }

  Future<T> _runExclusive<T>(Future<T> Function() action) {
    final operation = _tail.then((_) => action());
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return operation;
  }
}
