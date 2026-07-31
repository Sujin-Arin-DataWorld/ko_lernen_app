import 'package:uuid/uuid.dart';

import 'content_feedback.dart';

typedef FeedbackCompletionIdFactory = String Function();

/// State-owned lifecycle for one immutable completion per game round.
class FeedbackCompletionSlot {
  FeedbackCompletion? _current;

  FeedbackCompletion? get current => _current;

  FeedbackCompletion complete(FeedbackCompletion Function() create) =>
      _current ??= create();

  void reset() => _current = null;
}

/// Guards a listening finish across its asynchronous XP persistence.
class ListeningFeedbackCompletionState {
  final FeedbackCompletionSlot _completion = FeedbackCompletionSlot();
  int _generation = 0;

  FeedbackCompletion? get current => _completion.current;

  Future<FeedbackCompletion?> finish({
    required Future<void> Function() persistXp,
    required FeedbackCompletion Function() create,
  }) async {
    final generation = _generation;
    final completion = _completion.complete(create);
    await persistXp();
    if (generation != _generation ||
        !identical(_completion.current, completion)) {
      return null;
    }
    return completion;
  }

  void reset() {
    _generation++;
    _completion.reset();
  }
}

/// Immutable feedback context allocated once when a learning round finishes.
class FeedbackCompletion {
  const FeedbackCompletion._(this.context);

  final ContentFeedbackContext context;

  factory FeedbackCompletion.cloze({
    FeedbackCompletionIdFactory? createId,
    required String contentLabel,
    required String? level,
    required int correct,
    required int total,
  }) => FeedbackCompletion._(
    _context(
      createId: createId,
      contentType: 'game',
      contentId: 'cloze',
      contentLabel: contentLabel,
      level: _level(level),
      scoreSummary: '$correct/$total; ${_percent(correct, total)}%',
    ),
  );

  factory FeedbackCompletion.dailyChallenge({
    FeedbackCompletionIdFactory? createId,
    required String contentLabel,
    required DateTime finishedAt,
    required int correct,
    required int total,
  }) => FeedbackCompletion._(
    _context(
      createId: createId,
      contentType: 'game',
      contentId: 'daily_challenge:${_localIsoDate(finishedAt)}',
      contentLabel: contentLabel,
      scoreSummary: '$correct/$total; ${_percent(correct, total)}%',
    ),
  );

  factory FeedbackCompletion.satzArcade({
    FeedbackCompletionIdFactory? createId,
    required String contentLabel,
    required String? level,
    required int passed,
    required int total,
  }) => FeedbackCompletion._(
    _context(
      createId: createId,
      contentType: 'game',
      contentId: 'satz_arcade',
      contentLabel: contentLabel,
      level: _level(level),
      scoreSummary: '$passed/$total',
    ),
  );

  factory FeedbackCompletion.speedMatch({
    FeedbackCompletionIdFactory? createId,
    required String contentLabel,
    required String? level,
    required int score,
  }) => FeedbackCompletion._(
    _context(
      createId: createId,
      contentType: 'game',
      contentId: 'speed_match',
      contentLabel: contentLabel,
      level: _level(level),
      scoreSummary: 'score:$score; seconds:60',
    ),
  );

  factory FeedbackCompletion.customPackQuiz({
    FeedbackCompletionIdFactory? createId,
    required String packId,
    required String contentLabel,
    required int correct,
    required int total,
  }) => FeedbackCompletion._(
    _customPackContext(
      createId: createId,
      packId: packId,
      mode: 'quiz',
      contentLabel: contentLabel,
      scoreSummary: '$correct/$total',
    ),
  );

  factory FeedbackCompletion.customPackMatching({
    FeedbackCompletionIdFactory? createId,
    required String packId,
    required String contentLabel,
    required int pairs,
    required int misses,
  }) => FeedbackCompletion._(
    _customPackContext(
      createId: createId,
      packId: packId,
      mode: 'matching',
      contentLabel: contentLabel,
      scoreSummary: 'pairs:$pairs; misses:$misses',
    ),
  );

  factory FeedbackCompletion.customPackTyping({
    FeedbackCompletionIdFactory? createId,
    required String packId,
    required String contentLabel,
    required int correct,
    required int total,
  }) => FeedbackCompletion._(
    _customPackContext(
      createId: createId,
      packId: packId,
      mode: 'typing',
      contentLabel: contentLabel,
      scoreSummary: '$correct/$total',
    ),
  );

  factory FeedbackCompletion.scenario({
    FeedbackCompletionIdFactory? createId,
    required String scenarioId,
    required String contentLabel,
    required String? level,
    required int passed,
    required int firstTryPassed,
    required int total,
  }) => FeedbackCompletion._(
    _context(
      createId: createId,
      contentType: 'scenario',
      contentId: scenarioId,
      contentLabel: contentLabel,
      level: _level(level),
      scoreSummary: 'passed:$passed/$total; firstTry:$firstTryPassed/$total',
    ),
  );

  factory FeedbackCompletion.vocabPack({
    FeedbackCompletionIdFactory? createId,
    required String packId,
    required String contentLabel,
    required String level,
    required int bossCorrect,
    required int bossTotal,
    required int quizCorrect,
    required int quizTotal,
  }) => FeedbackCompletion._(
    _context(
      createId: createId,
      contentType: 'vocab_pack',
      contentId: packId,
      contentLabel: contentLabel,
      level: _level(level),
      scoreSummary:
          'boss:$bossCorrect/$bossTotal; quiz:$quizCorrect/$quizTotal',
    ),
  );

  factory FeedbackCompletion.listening({
    FeedbackCompletionIdFactory? createId,
    required String scenarioId,
    required String contentLabel,
    required String? level,
    required int lines,
    required double rate,
  }) => FeedbackCompletion._(
    _context(
      createId: createId,
      contentType: 'listening',
      contentId: scenarioId,
      contentLabel: contentLabel,
      level: _level(level),
      scoreSummary: 'lines:$lines; rate:${_rate(rate)}x',
    ),
  );

  factory FeedbackCompletion.review({
    FeedbackCompletionIdFactory? createId,
    required String contentId,
    required String contentLabel,
    required String? level,
    required int reviewed,
    required int total,
  }) => FeedbackCompletion._(
    _context(
      createId: createId,
      contentType: 'review',
      contentId: contentId,
      contentLabel: contentLabel,
      level: _level(level),
      scoreSummary: 'reviewed:$reviewed; total:$total',
    ),
  );

  factory FeedbackCompletion.customPackPlay({
    FeedbackCompletionIdFactory? createId,
    required String packId,
    required String contentLabel,
    required int learned,
    required int total,
  }) => FeedbackCompletion._(
    _context(
      createId: createId,
      contentType: 'custom_wordbook',
      contentId: 'custom_pack:$packId:play',
      contentLabel: contentLabel,
      scoreSummary: 'learned:$learned; total:$total',
    ),
  );

  factory FeedbackCompletion.legacyDue({
    FeedbackCompletionIdFactory? createId,
    required String contentLabel,
    required String? level,
    required int processed,
    required int known,
    required int retry,
  }) => FeedbackCompletion._(
    _context(
      createId: createId,
      contentType: 'legacy_vocab',
      contentId: 'due_session',
      contentLabel: contentLabel,
      level: _level(level),
      scoreSummary: 'processed:$processed; known:$known; retry:$retry',
    ),
  );
}

/// Session-only eligibility gate for the legacy due-card result.
class LegacyDueFeedbackSession {
  final FeedbackCompletionSlot _completion = FeedbackCompletionSlot();
  int _processed = 0;
  int _known = 0;
  int _retry = 0;

  FeedbackCompletion? get current => _completion.current;
  int get processed => _processed;

  void record({required bool known}) {
    _processed++;
    if (known) {
      _known++;
    } else {
      _retry++;
    }
  }

  FeedbackCompletion? completeIfEligible({
    required bool isDueMode,
    required bool dueIsEmpty,
    required String contentLabel,
    required String? level,
    FeedbackCompletionIdFactory? createId,
  }) {
    if (!isDueMode || !dueIsEmpty || _processed == 0) return null;
    return _completion.complete(
      () => FeedbackCompletion.legacyDue(
        createId: createId,
        contentLabel: contentLabel,
        level: level,
        processed: _processed,
        known: _known,
        retry: _retry,
      ),
    );
  }

  void reset() {
    _completion.reset();
    _processed = 0;
    _known = 0;
    _retry = 0;
  }
}

ContentFeedbackContext _customPackContext({
  FeedbackCompletionIdFactory? createId,
  required String packId,
  required String mode,
  required String contentLabel,
  required String scoreSummary,
}) => _context(
  createId: createId,
  contentType: 'custom_wordbook_game',
  contentId: 'custom_pack:$packId:$mode',
  contentLabel: contentLabel,
  scoreSummary: scoreSummary,
);

ContentFeedbackContext _context({
  FeedbackCompletionIdFactory? createId,
  required String contentType,
  required String contentId,
  required String contentLabel,
  String? level,
  required String scoreSummary,
}) => ContentFeedbackContext(
  completionId: (createId ?? _createCompletionId)(),
  contentType: contentType,
  contentId: contentId,
  contentLabel: contentLabel,
  level: level,
  scoreSummary: scoreSummary,
);

String _createCompletionId() => const Uuid().v4();

String? _level(String? level) => level?.toUpperCase();

String _rate(double rate) =>
    rate.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

int _percent(int count, int total) =>
    total == 0 ? 0 : ((count / total) * 100).round();

String _localIsoDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
