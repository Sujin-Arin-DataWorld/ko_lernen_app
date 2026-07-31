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

int _percent(int count, int total) =>
    total == 0 ? 0 : ((count / total) * 100).round();

String _localIsoDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
