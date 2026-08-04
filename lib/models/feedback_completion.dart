import 'package:uuid/uuid.dart';

import 'content_feedback.dart';

typedef FeedbackCompletionIdFactory = String Function();

enum WordleRoundKind { daily, random }

enum BookAnalysisFeedbackSource { online, offline, rateLimited }

extension BookAnalysisFeedbackSourceWire on BookAnalysisFeedbackSource {
  String get wireName => switch (this) {
    BookAnalysisFeedbackSource.online => 'online',
    BookAnalysisFeedbackSource.offline => 'offline',
    BookAnalysisFeedbackSource.rateLimited => 'rate_limited',
  };
}

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
  Future<FeedbackCompletion?>? _finishResult;

  FeedbackCompletion? get current => _completion.current;

  Future<FeedbackCompletion?> finish({
    required Future<void> Function() persistXp,
    required FeedbackCompletion Function() create,
  }) {
    final existingResult = _finishResult;
    if (existingResult != null) return existingResult;

    final generation = _generation;
    final completion = _completion.complete(create);
    late final Future<FeedbackCompletion?> result;
    result = Future<void>.sync(persistXp).then<FeedbackCompletion?>(
      (_) {
        if (generation != _generation ||
            !identical(_completion.current, completion)) {
          return null;
        }
        return completion;
      },
      onError: (Object error, StackTrace stackTrace) {
        if (generation == _generation && identical(_finishResult, result)) {
          _finishResult = null;
        }
        return Future<FeedbackCompletion?>.error(error, stackTrace);
      },
    );
    _finishResult = result;
    return result;
  }

  void reset() {
    _generation++;
    _finishResult = null;
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

  factory FeedbackCompletion.dailyHangul({
    FeedbackCompletionIdFactory? createId,
    required String contentLabel,
    required DateTime finishedAt,
    required int guidedStrokeCount,
  }) => FeedbackCompletion._(
    _context(
      createId: createId,
      contentType: 'daily_hangul',
      contentId: 'daily-char:${_localIsoDate(finishedAt)}',
      contentLabel: contentLabel,
      scoreSummary: 'guide_strokes:$guidedStrokeCount',
    ),
  );

  factory FeedbackCompletion.chosung({
    FeedbackCompletionIdFactory? createId,
    required String contentLabel,
    required String? level,
    required int correct,
    required int total,
    required int averageDurationMs,
  }) => FeedbackCompletion._(
    _context(
      createId: createId,
      contentType: 'game',
      contentId: 'chosung',
      contentLabel: contentLabel,
      level: _level(level),
      scoreSummary: '$correct/$total; avgMs:$averageDurationMs',
    ),
  );

  factory FeedbackCompletion.wordle({
    FeedbackCompletionIdFactory? createId,
    required String? level,
    required WordleRoundKind roundKind,
    required bool won,
    required int guessCount,
  }) => FeedbackCompletion._(
    _context(
      createId: createId,
      contentType: 'game',
      contentId: switch (roundKind) {
        WordleRoundKind.daily => 'wordle_daily',
        WordleRoundKind.random => 'wordle_random',
      },
      contentLabel: 'Silben-Rätsel',
      level: _level(level),
      scoreSummary: 'result:${won ? 'win' : 'loss'}; guesses:$guessCount',
    ),
  );

  factory FeedbackCompletion.kkeunmari({
    FeedbackCompletionIdFactory? createId,
    required String contentLabel,
    required int chainLength,
    required String endReason,
  }) => FeedbackCompletion._(
    _context(
      createId: createId,
      contentType: 'game',
      contentId: 'kkeunmari',
      contentLabel: contentLabel,
      scoreSummary: 'chain:$chainLength; end:$endReason',
    ),
  );

  factory FeedbackCompletion.grammarSession({
    FeedbackCompletionIdFactory? createId,
    required String contentLabel,
    required String level,
    required String type,
    required String difficulty,
    required int seenCount,
  }) => FeedbackCompletion._(
    _context(
      createId: createId,
      contentType: 'grammar_session',
      contentId: 'grammar:$level:$type:$difficulty',
      contentLabel: contentLabel,
      level: level == 'Alle' ? null : _level(level),
      scoreSummary: 'seen:$seenCount',
    ),
  );

  factory FeedbackCompletion.hangulCards({
    FeedbackCompletionIdFactory? createId,
    required String contentLabel,
    required int interactionCount,
  }) => FeedbackCompletion._(
    _context(
      createId: createId,
      contentType: 'hangul_cards',
      contentId: 'hangul:cards',
      contentLabel: contentLabel,
      scoreSummary: 'interactions:$interactionCount',
    ),
  );

  factory FeedbackCompletion.hangulWriting({
    FeedbackCompletionIdFactory? createId,
    required String contentLabel,
    required int strokeCount,
  }) => FeedbackCompletion._(
    _context(
      createId: createId,
      contentType: 'hangul_writing',
      contentId: 'hangul:writing',
      contentLabel: contentLabel,
      scoreSummary: 'strokes:$strokeCount',
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
    required int correct,
    required int total,
  }) => FeedbackCompletion._(
    _customPackContext(
      createId: createId,
      packId: packId,
      mode: 'quiz',
      scoreSummary: '$correct/$total',
    ),
  );

  factory FeedbackCompletion.customPackMatching({
    FeedbackCompletionIdFactory? createId,
    required String packId,
    required int pairs,
    required int misses,
  }) => FeedbackCompletion._(
    _customPackContext(
      createId: createId,
      packId: packId,
      mode: 'matching',
      scoreSummary: 'pairs:$pairs; misses:$misses',
    ),
  );

  factory FeedbackCompletion.customPackTyping({
    FeedbackCompletionIdFactory? createId,
    required String packId,
    required int correct,
    required int total,
  }) => FeedbackCompletion._(
    _customPackContext(
      createId: createId,
      packId: packId,
      mode: 'typing',
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
    required int learned,
    required int total,
  }) => FeedbackCompletion._(
    _context(
      createId: createId,
      contentType: 'custom_wordbook',
      contentId: 'custom_pack:$packId:play',
      contentLabel: 'custom_wordbook',
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

  factory FeedbackCompletion.bookAnalysis({
    FeedbackCompletionIdFactory? createId,
    required int words,
    required int grammar,
    required int sentences,
    required BookAnalysisFeedbackSource source,
  }) => FeedbackCompletion._(
    _context(
      createId: createId,
      contentType: 'book_analysis',
      contentId: 'book_analysis',
      contentLabel: 'book_analysis',
      scoreSummary:
          'words:$words; grammar:$grammar; sentences:$sentences; '
          'source:${source.wireName}',
    ),
  );

  factory FeedbackCompletion.questReward({
    FeedbackCompletionIdFactory? createId,
    required String questId,
    required String questType,
    required int target,
  }) => FeedbackCompletion._(
    _context(
      createId: createId,
      contentType: 'quest_reward',
      contentId: questId,
      contentLabel: 'quest_reward',
      scoreSummary: 'type:$questType; target:$target',
    ),
  );

  factory FeedbackCompletion.milestone({
    FeedbackCompletionIdFactory? createId,
    required String milestoneId,
    required String milestoneType,
    required int value,
  }) => FeedbackCompletion._(
    _context(
      createId: createId,
      contentType: 'milestone',
      contentId: milestoneId,
      contentLabel: 'milestone',
      scoreSummary: 'type:$milestoneType; value:$value',
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
  required String scoreSummary,
}) => _context(
  createId: createId,
  contentType: 'custom_wordbook_game',
  contentId: 'custom_pack:$packId:$mode',
  contentLabel: 'custom_wordbook',
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
