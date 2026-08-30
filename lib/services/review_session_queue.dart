/// Owns the live review queue separately from the cards that were actually
/// served to the learner.
///
/// An original can be appended for one bounded repeat after its first wrong
/// judgment. Browsing [previous] and [nextHistory] only moves the history
/// cursor; it never changes pending work or records another judgment.
final class ReviewSessionQueue<T> {
  ReviewSessionQueue(Iterable<T> items, {required this.idOf}) {
    final originalIds = <String>{};
    for (final item in items) {
      if (originalIds.add(idOf(item))) {
        _pending.add(item);
      }
    }
    _originalCount = _pending.length;
    if (_pending.isEmpty) {
      _complete = true;
    } else {
      _serveNext();
    }
  }

  final String Function(T item) idOf;
  final List<T> _pending = <T>[];
  final List<T> _servedHistory = <T>[];
  final List<int> _servedPositions = <int>[];
  final Set<String> _firstJudgmentIds = <String>{};
  final Set<String> _requeuedOriginalIds = <String>{};

  int _historyCursor = -1;
  int _originalCount = 0;
  bool _complete = false;

  T? get current {
    if (_historyCursor < 0 || _historyCursor >= _servedHistory.length) {
      return null;
    }
    return _servedHistory[_historyCursor];
  }

  /// True when [current] is an earlier served card rather than the live card.
  bool get isBrowsingHistory {
    return _historyCursor >= 0 && _historyCursor < _servedHistory.length - 1;
  }

  /// One-based position in the original unique deck.
  ///
  /// Repeat presentations remain at the original denominator instead of
  /// inflating progress beyond 100 percent.
  int get servedPosition {
    if (_historyCursor < 0) {
      return 0;
    }
    return _servedPositions[_historyCursor];
  }

  int get originalCount => _originalCount;

  bool get isComplete => _complete;

  bool get canJudgeCurrent {
    return current != null && !isBrowsingHistory && !_complete;
  }

  /// Whether judging [current] should write first-session SRS/course evidence.
  bool get currentNeedsEvidence {
    final item = current;
    if (!canJudgeCurrent || item == null) {
      return false;
    }
    return !_firstJudgmentIds.contains(idOf(item));
  }

  bool get canDefer => canJudgeCurrent && _pending.isNotEmpty;

  bool get canGoPrevious => _historyCursor > 0;

  bool get canGoForward {
    return _historyCursor >= 0 && _historyCursor < _servedHistory.length - 1;
  }

  int get pendingCount => _pending.length;

  /// The card that would be visible underneath [current].
  T? get peekNext {
    if (isBrowsingHistory) {
      return _servedHistory[_historyCursor + 1];
    }
    if (_pending.isEmpty) {
      return null;
    }
    return _pending.first;
  }

  void recordJudgment({required bool correct}) {
    final item = current;
    if (!canJudgeCurrent || item == null) {
      return;
    }

    final id = idOf(item);
    _firstJudgmentIds.add(id);
    if (!correct && _requeuedOriginalIds.add(id)) {
      _pending.add(item);
    }

    if (_pending.isEmpty) {
      _complete = true;
      return;
    }
    _serveNext();
  }

  bool previous() {
    if (_historyCursor <= 0) {
      return false;
    }
    _historyCursor--;
    return true;
  }

  bool nextHistory() {
    if (_historyCursor < 0 || _historyCursor >= _servedHistory.length - 1) {
      return false;
    }
    _historyCursor++;
    return true;
  }

  /// Moves the live card behind all currently pending cards without judging it.
  bool defer() {
    final item = current;
    if (!canDefer || item == null) {
      return false;
    }
    _pending.add(item);
    _serveNext();
    return true;
  }

  void _serveNext() {
    final next = _pending.removeAt(0);
    final nextPosition = _firstJudgmentIds.length + 1;
    _servedHistory.add(next);
    _servedPositions.add(
      nextPosition > _originalCount ? _originalCount : nextPosition,
    );
    _historyCursor = _servedHistory.length - 1;
  }
}
