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
typedef ContentFeedbackPassportStateReader = Future<Set<String>> Function();

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
    this.passportStateAuthoritative = false,
    this.stampAccepted = false,
    this.passportCompletedMissionIds = const <String>{},
    this.nextMissionId,
  });

  final ContentFeedbackSubmitStatus status;
  final String? feedbackId;
  final ContentFeedbackFailureCategory? failure;
  final bool passportStateAuthoritative;
  final bool stampAccepted;
  final Set<String> passportCompletedMissionIds;
  final String? nextMissionId;
}

class ContentFeedbackResumeResult {
  const ContentFeedbackResumeResult({
    this.delivered = 0,
    this.deliveredFeedbackIds = const <String>{},
    this.discarded = 0,
    this.remaining = 0,
    this.disabled = false,
    this.closed = false,
    this.blockedByDeletion = false,
  });

  final int delivered;
  final Set<String> deliveredFeedbackIds;
  final int discarded;
  final int remaining;
  final bool disabled;
  final bool closed;
  final bool blockedByDeletion;
}

abstract interface class FeedbackOutbox {
  Future<void> closeAndDiscard();
}

class ContentFeedbackService implements FeedbackOutbox {
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
    this.passportReader,
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
      passportReader: ContentFeedbackPassportReader.firebase(
        currentUid: currentUid,
      ),
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
  final ContentFeedbackPassportReader? passportReader;

  Future<void> _tail = Future<void>.value();
  final Set<Future<dynamic>> _activeStorageOperations = <Future<dynamic>>{};
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

  Future<Set<String>> readPassportState() async {
    if (!featureGate.isEnabled) return const <String>{};
    if (_closed) return const <String>{};
    final deletionActive = await _deletionIsActive();
    if (_closed || deletionActive) return const <String>{};
    final reader = passportReader;
    if (reader == null) return const <String>{};
    try {
      return await reader.readCompletedMissionIds();
    } catch (_) {
      return const <String>{};
    }
  }

  @override
  Future<void> closeAndDiscard() async {
    _closed = true;
    // Deletion can hold the durable admission lane while feedback execution
    // is waiting to enter it, so close must never wait on [_tail]. Storage
    // operations have their own barrier and cannot depend on that lane.
    final alreadyStarted = List<Future<dynamic>>.of(_activeStorageOperations);
    final initialClear = _startStorageOperation<void>(
      outboxStore.clear,
      allowWhenClosed: true,
    );
    await Future.wait<void>(<Future<void>>[
      for (final operation in alreadyStarted) _settleStorage(operation),
      _settleStorage(initialClear),
    ]);
    // A pre-close write may have restored data after the initial clear. This
    // final clear is authoritative and its failure must reach deletion so its
    // durable journal remains resumable and polling cannot begin.
    await _startStorageOperation<void>(
      outboxStore.clear,
      allowWhenClosed: true,
    );
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
    final deletionActive = await _deletionIsActive();
    if (_closed) {
      return const ContentFeedbackSubmitResult(
        status: ContentFeedbackSubmitStatus.closed,
      );
    }
    if (deletionActive) {
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
      if (_closed) return _closedSubmission();
      return const ContentFeedbackSubmitResult(
        status: ContentFeedbackSubmitStatus.failed,
        failure: ContentFeedbackFailureCategory.unavailable,
      );
    }
    if (_closed) return _closedSubmission();

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
      queue = List.of(await _readOutbox());
      if (_closed) return _closedSubmission(feedbackId);
      queue.removeWhere(
        (queued) =>
            queued.ownerUid != uid ||
            queued.status == FeedbackOutboxLocalStatus.blocked,
      );
      if (queue.length >= feedbackOutboxMaxItems) {
        return ContentFeedbackSubmitResult(
          status: ContentFeedbackSubmitStatus.queueFull,
          feedbackId: feedbackId,
        );
      }
      queue.add(item);
      await _writeOutbox(queue);
    } catch (_) {
      if (_closed) return _closedSubmission(feedbackId);
      return ContentFeedbackSubmitResult(
        status: ContentFeedbackSubmitStatus.failed,
        feedbackId: feedbackId,
        failure: ContentFeedbackFailureCategory.storageUnavailable,
      );
    }
    if (_closed) return _closedSubmission(feedbackId);

    return _deliverSubmitted(queue, item);
  }

  Future<ContentFeedbackSubmitResult> _deliverSubmitted(
    List<ContentFeedbackOutboxItem> queue,
    ContentFeedbackOutboxItem original,
  ) async {
    if (_closed) {
      return _closedSubmission(original.submission.feedbackId);
    }
    final deletionActive = await _deletionIsActive();
    if (_closed || deletionActive) {
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
        if (_closed) return _closedSubmission(original.submission.feedbackId);
        return ContentFeedbackSubmitResult(
          status: ContentFeedbackSubmitStatus.pending,
          feedbackId: original.submission.feedbackId,
          failure: ContentFeedbackFailureCategory.storageUnavailable,
        );
      }
      if (_closed) return _closedSubmission(original.submission.feedbackId);
      return ContentFeedbackSubmitResult(
        status: ContentFeedbackSubmitStatus.failed,
        feedbackId: original.submission.feedbackId,
        failure: ContentFeedbackFailureCategory.authenticationRequired,
      );
    }

    final attempted = original.recordAttempt();
    _replaceById(queue, attempted);
    try {
      await _writeOutbox(queue);
    } catch (_) {
      if (_closed) return _closedSubmission(original.submission.feedbackId);
      return ContentFeedbackSubmitResult(
        status: ContentFeedbackSubmitStatus.failed,
        feedbackId: original.submission.feedbackId,
        failure: ContentFeedbackFailureCategory.storageUnavailable,
      );
    }

    if (_closed) {
      return _closedSubmission(original.submission.feedbackId);
    }
    final deletionActiveAfterWrite = await _deletionIsActive();
    if (_closed) {
      return _closedSubmission(original.submission.feedbackId);
    }
    if (deletionActiveAfterWrite) {
      return ContentFeedbackSubmitResult(
        status: ContentFeedbackSubmitStatus.blockedByDeletion,
        feedbackId: original.submission.feedbackId,
      );
    }
    if (_validatedCurrentUid() != original.ownerUid) {
      try {
        await _discardById(queue, original.submission.feedbackId);
      } catch (_) {
        if (_closed) return _closedSubmission(original.submission.feedbackId);
        return ContentFeedbackSubmitResult(
          status: ContentFeedbackSubmitStatus.pending,
          feedbackId: original.submission.feedbackId,
          failure: ContentFeedbackFailureCategory.storageUnavailable,
        );
      }
      if (_closed) return _closedSubmission(original.submission.feedbackId);
      return ContentFeedbackSubmitResult(
        status: ContentFeedbackSubmitStatus.failed,
        feedbackId: original.submission.feedbackId,
        failure: ContentFeedbackFailureCategory.authenticationRequired,
      );
    }

    ContentFeedbackDelivery delivery;
    try {
      delivery = await client.submit(
        attempted.submission,
        expectedOwnerUid: attempted.ownerUid,
      );
    } on ContentFeedbackClientFailure catch (failure) {
      if (_closed) return _closedSubmission(attempted.submission.feedbackId);
      if (_validatedCurrentUid() != attempted.ownerUid) {
        return _discardChangedOwnerSubmission(queue, attempted);
      }
      if (failure.retryable) {
        await _retainFailure(queue, attempted, failure);
      } else {
        try {
          await _discardById(queue, attempted.submission.feedbackId);
        } catch (_) {
          // The attempt was durably persisted before the callable. Keep that
          // pending record when cleanup itself cannot be persisted.
        }
      }
      if (_closed) return _closedSubmission(attempted.submission.feedbackId);
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
      if (_closed) return _closedSubmission(attempted.submission.feedbackId);
      if (_validatedCurrentUid() != attempted.ownerUid) {
        return _discardChangedOwnerSubmission(queue, attempted);
      }
      await _retainFailure(queue, attempted, failure);
      if (_closed) return _closedSubmission(attempted.submission.feedbackId);
      return ContentFeedbackSubmitResult(
        status: ContentFeedbackSubmitStatus.pending,
        feedbackId: attempted.submission.feedbackId,
        failure: failure.category,
      );
    }
    if (_closed) return _closedSubmission(attempted.submission.feedbackId);
    if (_validatedCurrentUid() != attempted.ownerUid) {
      return _discardChangedOwnerSubmission(queue, attempted);
    }

    try {
      await _discardById(queue, attempted.submission.feedbackId);
      if (_closed) return _closedSubmission(attempted.submission.feedbackId);
      return ContentFeedbackSubmitResult(
        status:
            delivery.acknowledgement == ContentFeedbackAcknowledgement.accepted
            ? ContentFeedbackSubmitStatus.accepted
            : ContentFeedbackSubmitStatus.duplicateCompletion,
        feedbackId: attempted.submission.feedbackId,
        passportStateAuthoritative: delivery.passportStateAuthoritative,
        stampAccepted: delivery.stampAccepted,
        passportCompletedMissionIds: delivery.passportCompletedMissionIds,
        nextMissionId: delivery.nextMissionId,
      );
    } catch (_) {
      if (_closed) return _closedSubmission(attempted.submission.feedbackId);
      return ContentFeedbackSubmitResult(
        status: ContentFeedbackSubmitStatus.pending,
        feedbackId: attempted.submission.feedbackId,
        failure: ContentFeedbackFailureCategory.storageUnavailable,
      );
    }
  }

  Future<ContentFeedbackResumeResult> _resumePending() async {
    if (_closed) return const ContentFeedbackResumeResult(closed: true);
    final deletionActive = await _deletionIsActive();
    if (_closed) return const ContentFeedbackResumeResult(closed: true);
    if (deletionActive) {
      return const ContentFeedbackResumeResult(blockedByDeletion: true);
    }
    final uid = _validatedCurrentUid();
    if (uid == null) return const ContentFeedbackResumeResult();

    List<ContentFeedbackOutboxItem> queue;
    try {
      queue = List.of(await _readOutbox());
    } catch (_) {
      if (_closed) return const ContentFeedbackResumeResult(closed: true);
      return const ContentFeedbackResumeResult();
    }
    if (_closed) return const ContentFeedbackResumeResult(closed: true);
    final beforeOwnershipFilter = queue.length;
    queue.removeWhere(
      (item) =>
          item.ownerUid != uid ||
          item.status == FeedbackOutboxLocalStatus.blocked,
    );
    var discarded = beforeOwnershipFilter - queue.length;
    if (discarded > 0) {
      try {
        await _writeQueue(queue);
      } catch (_) {
        if (_closed) return const ContentFeedbackResumeResult(closed: true);
        return ContentFeedbackResumeResult(
          discarded: 0,
          remaining: beforeOwnershipFilter,
        );
      }
      if (_closed) return const ContentFeedbackResumeResult(closed: true);
    }

    var delivered = 0;
    final deliveredFeedbackIds = <String>{};
    final candidates = queue
        .where((item) => item.status == FeedbackOutboxLocalStatus.pending)
        .toList(growable: false);
    for (final original in candidates) {
      if (_closed) break;
      final deletionActiveBeforeWrite = await _deletionIsActive();
      if (_closed) break;
      if (deletionActiveBeforeWrite) {
        return ContentFeedbackResumeResult(
          delivered: delivered,
          deliveredFeedbackIds: deliveredFeedbackIds,
          discarded: discarded,
          remaining: queue.length,
          blockedByDeletion: true,
        );
      }
      if (_validatedCurrentUid() != uid) break;

      final attempted = original.recordAttempt();
      _replaceById(queue, attempted);
      try {
        await _writeOutbox(queue);
      } catch (_) {
        if (_closed) break;
        break;
      }
      if (_closed) break;
      final deletionActiveAfterWrite = await _deletionIsActive();
      if (_closed) break;
      if (deletionActiveAfterWrite) {
        return ContentFeedbackResumeResult(
          delivered: delivered,
          deliveredFeedbackIds: deliveredFeedbackIds,
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
            if (_closed) break;
            queue
              ..clear()
              ..addAll(retained);
            discarded += beforeLiveFilter - retained.length;
          } catch (_) {
            if (_closed) break;
            // Do not report a discard unless its durable write succeeded.
          }
        }
        break;
      }
      try {
        await client.submit(
          attempted.submission,
          expectedOwnerUid: attempted.ownerUid,
        );
        if (_closed) break;
        if (_validatedCurrentUid() != attempted.ownerUid) {
          if (await _tryDiscardChangedOwnerOnResume(queue, attempted)) {
            discarded += 1;
          }
          break;
        }
        await _discardById(queue, attempted.submission.feedbackId);
        deliveredFeedbackIds.add(attempted.submission.feedbackId);
        if (_closed) break;
        delivered += 1;
      } on ContentFeedbackClientFailure catch (failure) {
        if (_closed) break;
        if (_validatedCurrentUid() != attempted.ownerUid) {
          if (await _tryDiscardChangedOwnerOnResume(queue, attempted)) {
            discarded += 1;
          }
          break;
        }
        if (failure.retryable) {
          await _retainFailure(queue, attempted, failure);
        } else {
          try {
            await _discardById(queue, attempted.submission.feedbackId);
            discarded += 1;
          } catch (_) {
            // The prior attempted item remains durably pending. Do not turn a
            // failed cleanup into a permanently non-resumable blocked item.
          }
        }
        break;
      } catch (_) {
        if (_closed) break;
        if (_validatedCurrentUid() != attempted.ownerUid) {
          if (await _tryDiscardChangedOwnerOnResume(queue, attempted)) {
            discarded += 1;
          }
          break;
        }
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
    if (_closed) {
      return ContentFeedbackResumeResult(
        delivered: delivered,
        deliveredFeedbackIds: deliveredFeedbackIds,
        discarded: discarded,
        closed: true,
      );
    }
    return ContentFeedbackResumeResult(
      delivered: delivered,
      deliveredFeedbackIds: deliveredFeedbackIds,
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
    if (_closed) return;
    _replaceById(queue, attempted.recordFailure(failure));
    if (_closed) return;
    try {
      await _writeOutbox(queue);
    } catch (_) {
      // The previously persisted attempted item remains safe and retryable.
    }
  }

  Future<ContentFeedbackSubmitResult> _discardChangedOwnerSubmission(
    List<ContentFeedbackOutboxItem> queue,
    ContentFeedbackOutboxItem attempted,
  ) async {
    try {
      await _discardById(queue, attempted.submission.feedbackId);
    } catch (_) {
      return ContentFeedbackSubmitResult(
        status: ContentFeedbackSubmitStatus.pending,
        feedbackId: attempted.submission.feedbackId,
        failure: ContentFeedbackFailureCategory.storageUnavailable,
      );
    }
    return ContentFeedbackSubmitResult(
      status: ContentFeedbackSubmitStatus.failed,
      feedbackId: attempted.submission.feedbackId,
      failure: ContentFeedbackFailureCategory.authenticationRequired,
    );
  }

  Future<bool> _tryDiscardChangedOwnerOnResume(
    List<ContentFeedbackOutboxItem> queue,
    ContentFeedbackOutboxItem attempted,
  ) async {
    try {
      await _discardById(queue, attempted.submission.feedbackId);
      return true;
    } catch (_) {
      // Fail closed. The record remains owner-bound and the next account's
      // resume pass filters it before any callable can start.
      return false;
    }
  }

  ContentFeedbackSubmitResult _closedSubmission([String? feedbackId]) {
    return ContentFeedbackSubmitResult(
      status: ContentFeedbackSubmitStatus.closed,
      feedbackId: feedbackId,
    );
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
    return queue.isEmpty ? _clearOutbox() : _writeOutbox(queue);
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

  Future<List<ContentFeedbackOutboxItem>> _readOutbox() {
    return _startStorageOperation(outboxStore.read);
  }

  Future<void> _writeOutbox(List<ContentFeedbackOutboxItem> queue) {
    final snapshot = List<ContentFeedbackOutboxItem>.unmodifiable(queue);
    return _startStorageOperation(() => outboxStore.write(snapshot));
  }

  Future<void> _clearOutbox() {
    return _startStorageOperation(outboxStore.clear);
  }

  Future<T> _startStorageOperation<T>(
    Future<T> Function() action, {
    bool allowWhenClosed = false,
  }) {
    if (_closed && !allowWhenClosed) {
      return Future<T>.error(StateError('Feedback outbox is closed.'));
    }
    final operation = Future<T>.sync(action);
    _activeStorageOperations.add(operation);
    operation.then<void>(
      (_) => _activeStorageOperations.remove(operation),
      onError: (Object _, StackTrace __) {
        _activeStorageOperations.remove(operation);
      },
    );
    return operation;
  }

  Future<void> _settleStorage(Future<dynamic> operation) async {
    try {
      await operation;
    } catch (_) {
      // An admitted feedback operation owns its own storage error result.
      // Close still advances to the final authoritative clear.
    }
  }
}
