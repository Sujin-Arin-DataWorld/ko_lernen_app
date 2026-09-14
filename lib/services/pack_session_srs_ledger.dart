import 'local_data_lifetime.dart';
import 'storage_service.dart';

/// The evidence state for one vocabulary word during one pack session.
///
/// This is deliberately session-local. It is not an SRS card state and must
/// never be persisted or reconstructed from route data.
enum PackSessionSrsState { unrated, positive, negative }

/// The SRS write a caller should make for a newly recorded outcome.
///
/// Wrong-count tracking is intentionally separate: each genuine miss can
/// still update its existing wrong-count metric even when this ledger returns
/// [none] for duplicate SRS evidence.
enum PackSessionSrsAction { none, positive, negative }

extension PackSessionSrsActionX on PackSessionSrsAction {
  bool get writesSrs => this != PackSessionSrsAction.none;

  bool? get gotIt {
    switch (this) {
      case PackSessionSrsAction.none:
        return null;
      case PackSessionSrsAction.positive:
        return true;
      case PackSessionSrsAction.negative:
        return false;
    }
  }
}

/// Coalesces SRS evidence for the lifetime of one vocabulary-pack session.
///
/// The first positive outcome may write one positive SRS review. The first
/// negative outcome may write one negative SRS review, including after an
/// earlier positive outcome. A negative state is terminal for this session so
/// a later successful recognition or typing attempt cannot promote the card.
class PackSessionSrsLedger {
  final Map<String, PackSessionSrsState> _states =
      <String, PackSessionSrsState>{};

  PackSessionSrsState stateFor(String wordId) {
    if (wordId.trim().isEmpty) {
      return PackSessionSrsState.unrated;
    }
    return _states[wordId] ?? PackSessionSrsState.unrated;
  }

  PackSessionSrsAction recordPositive(String wordId) {
    if (wordId.trim().isEmpty ||
        stateFor(wordId) != PackSessionSrsState.unrated) {
      return PackSessionSrsAction.none;
    }
    _states[wordId] = PackSessionSrsState.positive;
    return PackSessionSrsAction.positive;
  }

  PackSessionSrsAction recordNegative(String wordId) {
    if (wordId.trim().isEmpty ||
        stateFor(wordId) == PackSessionSrsState.negative) {
      return PackSessionSrsAction.none;
    }
    _states[wordId] = PackSessionSrsState.negative;
    return PackSessionSrsAction.negative;
  }
}

/// Ephemeral route payload shared by Pack, result, and optional typed recall.
///
/// A valid instance owns one [ledger] for one exact [packId]. A missing,
/// malformed, or mismatched route argument is converted to [practiceOnly], so
/// recall stays usable but cannot write SRS or wrong-count evidence through
/// this session. It is intentionally not serializable.
class PackRecallSession {
  PackRecallSession.forPack({
    required String packId,
    PackSessionSrsLedger? ledger,
  }) : packId = packId.trim(),
       ledger = ledger ?? PackSessionSrsLedger(),
       _canRecordEvidence = packId.trim().isNotEmpty;

  PackRecallSession.practiceOnly()
    : packId = '',
      ledger = PackSessionSrsLedger(),
      _canRecordEvidence = false;

  /// Converts dynamic Navigator arguments into a safe, typed session.
  factory PackRecallSession.fromRouteArgument(
    Object? routeArgument, {
    required String expectedPackId,
  }) {
    if (routeArgument is PackRecallSession &&
        routeArgument.isValidForPack(expectedPackId)) {
      return routeArgument;
    }
    return PackRecallSession.practiceOnly();
  }

  final String packId;
  final PackSessionSrsLedger ledger;
  final bool _canRecordEvidence;
  final _lifetime = LocalDataLifetime.capture();
  Future<void> _writeTail = Future.value();
  PackSrsEvidenceAttempt? _pendingEvidence;

  /// Retain this attempt while the same judgment is retried. Session state is
  /// published only after its SRS card and daily study log are confirmed.
  PackSrsEvidenceAttempt evidenceAttempt({
    required String expectedPackId,
    required String wordId,
    required bool gotIt,
  }) => PackSrsEvidenceAttempt._(this, expectedPackId, wordId, gotIt);

  Future<bool> _saveEvidence(PackSrsEvidenceAttempt attempt) {
    final result = _writeTail.then((_) async {
      if (!isValidForPack(attempt.expectedPackId)) {
        return true;
      }
      _lifetime.assertCurrent();
      final pending = _pendingEvidence;
      if (pending != null) {
        await pending._persist();
        _pendingEvidence = null;
      }
      if (!attempt._saved) {
        _pendingEvidence = attempt;
        await attempt._persist();
        _pendingEvidence = null;
      }
      return true;
    });
    _writeTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  bool get isPracticeOnly => !_canRecordEvidence;

  bool isValidForPack(String expectedPackId) {
    return _canRecordEvidence &&
        expectedPackId.trim().isNotEmpty &&
        packId == expectedPackId.trim();
  }

  /// Records a positive outcome only when this route payload belongs to the
  /// active pack. Otherwise it is practice-only and produces no SRS write.
  PackSessionSrsAction recordPositiveFor({
    required String expectedPackId,
    required String wordId,
  }) {
    if (!isValidForPack(expectedPackId)) {
      return PackSessionSrsAction.none;
    }
    return ledger.recordPositive(wordId);
  }

  /// Records a negative outcome only when this route payload belongs to the
  /// active pack. Otherwise it is practice-only and produces no SRS write.
  PackSessionSrsAction recordNegativeFor({
    required String expectedPackId,
    required String wordId,
  }) {
    if (!isValidForPack(expectedPackId)) {
      return PackSessionSrsAction.none;
    }
    return ledger.recordNegative(wordId);
  }
}

/// One accepted answer, with the exact native attempt retained on failure.
class PackSrsEvidenceAttempt {
  PackSrsEvidenceAttempt._(
    this._session,
    this.expectedPackId,
    this.wordId,
    this.gotIt,
  );
  final PackRecallSession _session;
  final String expectedPackId;
  final String wordId;
  final bool gotIt;
  SrsReviewAttempt? _srs;
  bool _saved = false;

  Future<bool> save() => _session._saveEvidence(this);

  Future<void> _persist() async {
    _session._lifetime.assertCurrent();
    if (_saved) {
      return;
    }
    final state = _session.ledger.stateFor(wordId);
    final needsWrite =
        wordId.trim().isNotEmpty &&
        (gotIt
            ? state == PackSessionSrsState.unrated
            : state != PackSessionSrsState.negative);
    if (needsWrite) {
      final srs = _srs ??= SrsReviewAttempt(id: wordId, gotIt: gotIt);
      if (!await srs.save()) {
        _session._lifetime.assertCurrent();
        throw StateError('Pack SRS evidence has not been confirmed.');
      }
      _session._lifetime.assertCurrent();
      if (gotIt) {
        _session.ledger.recordPositive(wordId);
      } else {
        _session.ledger.recordNegative(wordId);
      }
    }
    _saved = true;
  }
}
