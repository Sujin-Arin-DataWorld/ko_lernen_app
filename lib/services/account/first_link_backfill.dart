import 'dart:convert';
import 'dart:math';

import 'cloud_write_session.dart';
import 'first_link_backfill_journal.dart';

typedef FirstDurableLinkUploader =
    Future<CloudWriteResult> Function(
      CloudWriteSession session, {
      required String operationId,
    });
typedef FirstDurableLinkBackfillTokenFactory = String Function();

String createSecureFirstDurableLinkBackfillToken() {
  final random = Random.secure();
  final bytes = List<int>.generate(24, (_) => random.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

/// Selects the first-link path only when Firebase Auth kept the anonymous
/// source UID while making that same identity durable.
class FirstDurableLinkActivation {
  const FirstDurableLinkActivation({
    required this.sessions,
    required this.backfill,
  });

  final CloudWriteSessionController sessions;
  final FirstDurableLinkBackfill backfill;

  Future<CloudWriteResult> activate({
    required String sourceUid,
    required String? linkedUid,
    required bool linkedIsAnonymous,
  }) {
    final normalizedSourceUid = sourceUid.trim();
    final normalizedLinkedUid = linkedUid?.trim();
    if (normalizedSourceUid.isEmpty ||
        normalizedLinkedUid == null ||
        normalizedLinkedUid.isEmpty ||
        linkedIsAnonymous) {
      return Future<CloudWriteResult>.value(CloudWriteResult.blocked);
    }
    if (normalizedSourceUid != normalizedLinkedUid) {
      return Future<CloudWriteResult>.value(CloudWriteResult.stale);
    }
    final session = CloudWriteFence(
      sessions,
    ).readySnapshot(normalizedSourceUid);
    if (session == null) {
      return Future<CloudWriteResult>.value(CloudWriteResult.blocked);
    }
    return backfill.begin(session: session, uid: normalizedSourceUid);
  }
}

/// Copies locally owned data only after a successful anonymous-to-durable
/// link that kept the same Firebase UID.
///
/// The caller of [begin] must already hold the identity-mutation admission
/// lane. Calling that admission again here would deadlock against the
/// backup-deletion gate. This class instead persists a narrow UID-bound
/// receipt before cloud writes, fences every write to the exact ready session,
/// and checks the other durable account journals before every component.
class FirstDurableLinkBackfill {
  FirstDurableLinkBackfill({
    required this.sessions,
    required this.currentUid,
    required this.hasBlockingAccountJournal,
    required this.journalStore,
    required this.uploadBookshelf,
    required this.uploadPackProgress,
    FirstDurableLinkBackfillTokenFactory? createToken,
  }) : createToken = createToken ?? createSecureFirstDurableLinkBackfillToken;

  final CloudWriteSessionController sessions;

  /// Returns the live durable UID, never an unverified journal UID.
  final String? Function() currentUid;

  /// Reads every *other* durable account-operation marker. The first-link
  /// receipt itself must not be included or it would block its own recovery.
  final Future<bool> Function() hasBlockingAccountJournal;
  final FirstDurableLinkBackfillJournalStore journalStore;
  final FirstDurableLinkBackfillTokenFactory createToken;
  final FirstDurableLinkUploader uploadBookshelf;
  final FirstDurableLinkUploader uploadPackProgress;

  Future<CloudWriteResult>? _inFlight;

  /// Starts a new receipt or continues the same-UID receipt that is already
  /// durable. It never overwrites a receipt belonging to another account.
  Future<CloudWriteResult> begin({
    required CloudWriteSession session,
    required String uid,
  }) {
    return _singleFlight(() => _begin(session: session, uid: uid));
  }

  /// Backwards-compatible name for callers that previously invoked the
  /// one-shot implementation directly.
  Future<CloudWriteResult> run({
    required CloudWriteSession session,
    required String uid,
  }) => begin(session: session, uid: uid);

  /// Resumes only a receipt for [expectedUid] using a fresh ready session.
  /// A persisted epoch is intentionally never reused after process restart.
  Future<CloudWriteResult> resume({required String expectedUid}) {
    return _singleFlight(() => _resume(expectedUid: expectedUid));
  }

  Future<CloudWriteResult> _begin({
    required CloudWriteSession session,
    required String uid,
  }) async {
    final normalizedUid = uid.trim();
    final initial = _verifySource(session, normalizedUid);
    if (initial != CloudWriteResult.completed) return initial;

    final safe = await _verifyNoBlockingAccountJournal(session, normalizedUid);
    if (safe != CloudWriteResult.completed) return safe;

    FirstDurableLinkBackfillJournal? journal;
    try {
      journal = await journalStore.read();
    } catch (_) {
      return _blockedOrStale(session, normalizedUid);
    }
    if (journal != null) {
      if (journal.uid != normalizedUid) return CloudWriteResult.blocked;
      return _runJournal(session: session, journal: journal);
    }

    final beforeReceipt = await _verifyNoBlockingAccountJournal(
      session,
      normalizedUid,
    );
    if (beforeReceipt != CloudWriteResult.completed) return beforeReceipt;

    late final FirstDurableLinkBackfillJournal pending;
    try {
      pending = FirstDurableLinkBackfillJournal.pending(
        uid: normalizedUid,
        token: createToken(),
      );
      final created = await journalStore.createIfAbsent(pending);
      if (created) {
        journal = pending;
      } else {
        journal = await journalStore.read();
        if (journal == null || journal.uid != normalizedUid) {
          return CloudWriteResult.blocked;
        }
      }
    } catch (_) {
      // No remote upload has started. If the platform cannot persist this
      // write-ahead receipt, a later process restart cannot be guaranteed to
      // recover it, so fail closed rather than copying untracked local data.
      return _blockedOrStale(session, normalizedUid);
    }

    final afterReceipt = await _verifyNoBlockingAccountJournal(
      session,
      normalizedUid,
    );
    if (afterReceipt != CloudWriteResult.completed) return afterReceipt;
    return _runJournal(session: session, journal: journal);
  }

  Future<CloudWriteResult> _resume({required String expectedUid}) async {
    final normalizedExpectedUid = expectedUid.trim();
    if (normalizedExpectedUid.isEmpty) return CloudWriteResult.blocked;

    FirstDurableLinkBackfillJournal? journal;
    try {
      journal = await journalStore.read();
    } catch (_) {
      return CloudWriteResult.blocked;
    }
    if (journal == null) return CloudWriteResult.completed;

    // A foreign receipt stays durable but inert. It is not evidence that the
    // live account may upload or clear data for that other UID.
    if (journal.uid != normalizedExpectedUid ||
        _liveUid() != normalizedExpectedUid) {
      return CloudWriteResult.blocked;
    }
    final session = CloudWriteFence(
      sessions,
    ).readySnapshot(normalizedExpectedUid);
    if (session == null) return CloudWriteResult.blocked;
    final verified = _verifySource(session, normalizedExpectedUid);
    if (verified != CloudWriteResult.completed) return verified;
    return _runJournal(session: session, journal: journal);
  }

  Future<CloudWriteResult> _runJournal({
    required CloudWriteSession session,
    required FirstDurableLinkBackfillJournal journal,
  }) async {
    var current = journal;
    final uid = current.uid;
    final initial = await _verifyCurrentJournal(session, current);
    if (initial != CloudWriteResult.completed) return initial;

    if (current.bookshelfPending) {
      final uploaded = await _runUploader(
        uploadBookshelf,
        session,
        uid,
        expectedJournal: current,
        operationId: current.operationId,
      );
      if (uploaded != CloudWriteResult.completed) return uploaded;

      final beforeReceipt = await _verifyCurrentJournal(session, current);
      if (beforeReceipt != CloudWriteResult.completed) return beforeReceipt;
      final next = current.markBookshelfCompleted();
      final recorded = await _replaceReceipt(
        expected: current,
        next: next,
        session: session,
      );
      if (recorded != CloudWriteResult.completed) return recorded;
      current = next;
    }

    if (current.packProgressPending) {
      final uploaded = await _runUploader(
        uploadPackProgress,
        session,
        uid,
        expectedJournal: current,
        operationId: current.operationId,
      );
      if (uploaded != CloudWriteResult.completed) return uploaded;

      final beforeReceipt = await _verifyCurrentJournal(session, current);
      if (beforeReceipt != CloudWriteResult.completed) return beforeReceipt;
      final next = current.markPackProgressCompleted();
      final recorded = await _replaceReceipt(
        expected: current,
        next: next,
        session: session,
      );
      if (recorded != CloudWriteResult.completed) return recorded;
      current = next;
    }

    if (!current.isComplete) return CloudWriteResult.blocked;
    final beforeClear = await _verifyCurrentJournal(session, current);
    if (beforeClear != CloudWriteResult.completed) return beforeClear;
    try {
      final cleared = await journalStore.clearIfCurrent(current);
      return cleared
          ? CloudWriteResult.completed
          : _blockedOrStale(session, uid);
    } catch (_) {
      return _blockedOrStale(session, uid);
    }
  }

  Future<CloudWriteResult> _replaceReceipt({
    required FirstDurableLinkBackfillJournal expected,
    required FirstDurableLinkBackfillJournal next,
    required CloudWriteSession session,
  }) async {
    final beforeWrite = _verifySource(session, expected.uid);
    if (beforeWrite != CloudWriteResult.completed) return beforeWrite;
    try {
      final replaced = await journalStore.replaceIfCurrent(
        expected: expected,
        next: next,
      );
      return replaced
          ? CloudWriteResult.completed
          : _blockedOrStale(session, expected.uid);
    } catch (_) {
      return _blockedOrStale(session, expected.uid);
    }
  }

  Future<CloudWriteResult> _verifyNoBlockingAccountJournal(
    CloudWriteSession session,
    String uid,
  ) async {
    final beforeRead = _verifySource(session, uid);
    if (beforeRead != CloudWriteResult.completed) return beforeRead;
    try {
      if (await hasBlockingAccountJournal()) {
        return CloudWriteResult.blocked;
      }
    } catch (_) {
      return _blockedOrStale(session, uid);
    }
    return _verifySource(session, uid);
  }

  Future<CloudWriteResult> _runUploader(
    FirstDurableLinkUploader uploader,
    CloudWriteSession session,
    String uid, {
    required FirstDurableLinkBackfillJournal expectedJournal,
    required String operationId,
  }) async {
    final beforeUpload = await _verifyCurrentJournal(session, expectedJournal);
    if (beforeUpload != CloudWriteResult.completed) return beforeUpload;
    try {
      final uploaded = await uploader(session, operationId: operationId);
      if (uploaded != CloudWriteResult.completed) return uploaded;
    } catch (_) {
      return _blockedOrStale(session, uid);
    }
    return _verifySource(session, uid);
  }

  Future<CloudWriteResult> _verifyCurrentJournal(
    CloudWriteSession session,
    FirstDurableLinkBackfillJournal expected,
  ) async {
    final safe = await _verifyNoBlockingAccountJournal(session, expected.uid);
    if (safe != CloudWriteResult.completed) return safe;
    try {
      final current = await journalStore.read();
      if (current != expected) return _blockedOrStale(session, expected.uid);
    } catch (_) {
      return _blockedOrStale(session, expected.uid);
    }
    return _verifyNoBlockingAccountJournal(session, expected.uid);
  }

  CloudWriteResult _blockedOrStale(CloudWriteSession session, String uid) {
    final verified = _verifySource(session, uid);
    return verified == CloudWriteResult.completed
        ? CloudWriteResult.blocked
        : verified;
  }

  CloudWriteResult _verifySource(CloudWriteSession session, String uid) {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty || normalizedUid != session.uid) {
      return CloudWriteResult.blocked;
    }
    if (_liveUid() != normalizedUid) return CloudWriteResult.stale;
    try {
      return CloudWriteFence(sessions).verify(session, uid: normalizedUid);
    } catch (_) {
      return CloudWriteResult.stale;
    }
  }

  String? _liveUid() {
    try {
      return currentUid()?.trim();
    } catch (_) {
      return null;
    }
  }

  Future<CloudWriteResult> _singleFlight(
    Future<CloudWriteResult> Function() operation,
  ) {
    final existing = _inFlight;
    if (existing != null) return existing;
    final started = operation();
    _inFlight = started;
    started.then<void>(
      (_) {
        if (identical(_inFlight, started)) _inFlight = null;
      },
      onError: (Object _, StackTrace __) {
        if (identical(_inFlight, started)) _inFlight = null;
      },
    );
    return started;
  }
}
