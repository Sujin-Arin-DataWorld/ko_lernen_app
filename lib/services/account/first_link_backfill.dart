import 'cloud_write_session.dart';

typedef FirstDurableLinkUploader =
    Future<CloudWriteResult> Function(CloudWriteSession session);

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
    return backfill.run(session: session, uid: normalizedSourceUid);
  }
}

/// Copies locally owned data only after a successful anonymous-to-durable
/// link that kept the same Firebase UID.
///
/// The caller must already hold the identity-mutation admission lane. Calling
/// that admission again here would deadlock against the backup-deletion gate.
/// This class instead fences every source upload to the exact ready session and
/// rechecks the replacement journal before each irreversible cloud write.
class FirstDurableLinkBackfill {
  const FirstDurableLinkBackfill({
    required this.sessions,
    required this.currentUid,
    required this.hasReplacementJournal,
    required this.uploadBookshelf,
    required this.uploadPackProgress,
  });

  final CloudWriteSessionController sessions;
  final String? Function() currentUid;
  final Future<bool> Function() hasReplacementJournal;
  final FirstDurableLinkUploader uploadBookshelf;
  final FirstDurableLinkUploader uploadPackProgress;

  Future<CloudWriteResult> run({
    required CloudWriteSession session,
    required String uid,
  }) async {
    var result = _verifySource(session, uid);
    if (result != CloudWriteResult.completed) return result;

    result = await _verifyNoReplacement(session, uid);
    if (result != CloudWriteResult.completed) return result;

    result = await _runUploader(uploadBookshelf, session, uid);
    if (result != CloudWriteResult.completed) return result;

    result = await _verifyNoReplacement(session, uid);
    if (result != CloudWriteResult.completed) return result;

    return _runUploader(uploadPackProgress, session, uid);
  }

  Future<CloudWriteResult> _verifyNoReplacement(
    CloudWriteSession session,
    String uid,
  ) async {
    try {
      if (await hasReplacementJournal()) {
        return CloudWriteResult.blocked;
      }
    } catch (_) {
      return CloudWriteResult.blocked;
    }
    return _verifySource(session, uid);
  }

  Future<CloudWriteResult> _runUploader(
    FirstDurableLinkUploader uploader,
    CloudWriteSession session,
    String uid,
  ) async {
    final beforeUpload = _verifySource(session, uid);
    if (beforeUpload != CloudWriteResult.completed) return beforeUpload;
    try {
      final uploaded = await uploader(session);
      if (uploaded != CloudWriteResult.completed) return uploaded;
    } catch (_) {
      final afterFailure = _verifySource(session, uid);
      return afterFailure == CloudWriteResult.completed
          ? CloudWriteResult.blocked
          : afterFailure;
    }
    return _verifySource(session, uid);
  }

  CloudWriteResult _verifySource(CloudWriteSession session, String uid) {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty || normalizedUid != session.uid) {
      return CloudWriteResult.blocked;
    }
    if (currentUid()?.trim() != normalizedUid) {
      return CloudWriteResult.stale;
    }
    return CloudWriteFence(sessions).verify(session, uid: normalizedUid);
  }
}
