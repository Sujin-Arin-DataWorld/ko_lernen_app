import 'dart:async';

import '../config/tester_feedback_feature.dart';
import '../models/content_feedback.dart';
import 'content_feedback_service.dart';

typedef ContentFeedbackServiceFactory = ContentFeedbackService Function();
typedef ContentFeedbackIdentityReader =
    ({String? uid, bool isAnonymous}) Function();
typedef ContentFeedbackDurableJournalReader =
    Future<bool> Function(String deletedUid);

/// Owns the process-local feedback service across an account deletion.
///
/// A closed service is never reopened. After the deletion checkpoint and all
/// other durable account journals are gone, a distinct anonymous identity can
/// receive a newly constructed production service instead.
class ContentFeedbackLifecycle implements FeedbackOutbox {
  ContentFeedbackLifecycle({
    required ContentFeedbackService initialService,
    required this.createService,
    required this.currentIdentity,
    required this.durableJournalActive,
  }) : _current = initialService,
       featureGate = initialService.featureGate;

  final ContentFeedbackServiceFactory createService;
  final ContentFeedbackIdentityReader currentIdentity;
  final ContentFeedbackDurableJournalReader durableJournalActive;
  final TesterFeedbackFeatureGate featureGate;

  ContentFeedbackService _current;
  ContentFeedbackService? _successfullyClosed;
  String? _activatedDeletedUid;
  Future<void> _transitionTail = Future<void>.value();

  Future<ContentFeedbackSubmitResult> submit(
    ContentFeedbackContext context,
    ContentFeedbackDraft draft,
  ) => _current.submit(context, draft);

  Future<ContentFeedbackResumeResult> resumePending() =>
      _current.resumePending();

  Future<Set<String>> readPassportState() => _current.readPassportState();

  @override
  Future<void> closeAndDiscard() => _serialize<void>(() async {
    final service = _current;
    await service.closeAndDiscard();
    if (identical(_current, service)) {
      _successfullyClosed = service;
    }
  });

  Future<bool> activateAfterCompletedDeletion(String deletedUid) {
    return _serialize<bool>(() => _activate(deletedUid));
  }

  Future<bool> _activate(String rawDeletedUid) async {
    final deletedUid = _normalizedUid(rawDeletedUid);
    if (deletedUid == null) return false;

    if (_activatedDeletedUid == deletedUid &&
        !identical(_successfullyClosed, _current)) {
      return _safeReplacementIdentity(deletedUid) != null &&
          !await _journalIsActive(deletedUid);
    }

    final oldService = _current;
    if (!identical(_successfullyClosed, oldService)) {
      try {
        await oldService.closeAndDiscard();
      } catch (_) {
        return false;
      }
      if (!identical(_current, oldService)) return false;
      _successfullyClosed = oldService;
    }

    if (await _journalIsActive(deletedUid)) return false;
    final identity = _safeReplacementIdentity(deletedUid);
    if (identity == null) return false;

    ContentFeedbackService replacement;
    try {
      replacement = createService();
    } catch (_) {
      return false;
    }

    // A second authoritative check keeps a journal or identity transition
    // that began during construction from receiving a live service.
    if (await _journalIsActive(deletedUid) ||
        _safeReplacementIdentity(deletedUid) != identity ||
        !identical(_current, oldService)) {
      try {
        await replacement.closeAndDiscard();
      } catch (_) {
        // It was never published, so its failed best-effort clear cannot make
        // it reachable by any feedback entrypoint.
      }
      return false;
    }

    _current = replacement;
    _successfullyClosed = null;
    _activatedDeletedUid = deletedUid;
    return true;
  }

  ({String uid, bool isAnonymous})? _safeReplacementIdentity(
    String deletedUid,
  ) {
    try {
      final identity = currentIdentity();
      final uid = _normalizedUid(identity.uid);
      if (uid == null || uid == deletedUid || !identity.isAnonymous) {
        return null;
      }
      return (uid: uid, isAnonymous: true);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _journalIsActive(String deletedUid) async {
    try {
      return await durableJournalActive(deletedUid);
    } catch (_) {
      return true;
    }
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _transitionTail = _transitionTail.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  static String? _normalizedUid(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty || value.length > 128) return null;
    return value;
  }
}
