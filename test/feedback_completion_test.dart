import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/content_feedback.dart';
import 'package:ko_lernen_app/models/feedback_completion.dart';

void main() {
  group('FeedbackCompletion shared game contexts', () {
    test('builds the cloze aggregate context', () {
      final completion = FeedbackCompletion.cloze(
        createId: () => 'cloze-completion',
        contentLabel: 'Cloze',
        level: 'b1',
        correct: 7,
        total: 10,
      );

      expect(completion.context.toWire(), {
        'completionId': 'cloze-completion',
        'contentType': 'game',
        'contentId': 'cloze',
        'contentLabel': 'Cloze',
        'level': 'B1',
        'scoreSummary': '7/10; 70%',
      });
    });

    test('builds the dated daily challenge aggregate context', () {
      final completion = FeedbackCompletion.dailyChallenge(
        createId: () => 'daily-completion',
        contentLabel: 'Daily challenge',
        finishedAt: DateTime(2026, 7, 31, 23, 59),
        correct: 8,
        total: 10,
      );

      expect(completion.context.toWire(), {
        'completionId': 'daily-completion',
        'contentType': 'game',
        'contentId': 'daily_challenge:2026-07-31',
        'contentLabel': 'Daily challenge',
        'scoreSummary': '8/10; 80%',
      });
    });

    test('builds the Satz Arcade aggregate context', () {
      final completion = FeedbackCompletion.satzArcade(
        createId: () => 'satz-completion',
        contentLabel: 'Build a sentence',
        level: 'a2',
        passed: 6,
        total: 8,
      );

      expect(completion.context.toWire(), {
        'completionId': 'satz-completion',
        'contentType': 'game',
        'contentId': 'satz_arcade',
        'contentLabel': 'Build a sentence',
        'level': 'A2',
        'scoreSummary': '6/8',
      });
    });

    test('builds the fixed-duration Speed Match aggregate context', () {
      final completion = FeedbackCompletion.speedMatch(
        createId: () => 'speed-completion',
        contentLabel: 'Speed Match',
        level: 'b2',
        score: 12,
      );

      expect(completion.context.toWire(), {
        'completionId': 'speed-completion',
        'contentType': 'game',
        'contentId': 'speed_match',
        'contentLabel': 'Speed Match',
        'level': 'B2',
        'scoreSummary': 'score:12; seconds:60',
      });
    });

    test('builds private and valid custom pack quiz feedback metadata', () {
      final completion = FeedbackCompletion.customPackQuiz(
        createId: () => 'quiz-completion',
        packId: 'pack-42',
        correct: 7,
        total: 9,
      );

      expectPrivateCustomPackContext(
        completion.context,
        completionId: 'quiz-completion',
        contentType: 'custom_wordbook_game',
        contentId: 'custom_pack:pack-42:quiz',
        scoreSummary: '7/9',
      );
    });

    test('builds private and valid custom pack matching feedback metadata', () {
      final completion = FeedbackCompletion.customPackMatching(
        createId: () => 'matching-completion',
        packId: 'pack-42',
        pairs: 6,
        misses: 2,
      );

      expectPrivateCustomPackContext(
        completion.context,
        completionId: 'matching-completion',
        contentType: 'custom_wordbook_game',
        contentId: 'custom_pack:pack-42:matching',
        scoreSummary: 'pairs:6; misses:2',
      );
    });

    test('builds private and valid custom pack typing feedback metadata', () {
      final completion = FeedbackCompletion.customPackTyping(
        createId: () => 'typing-completion',
        packId: 'pack-42',
        correct: 5,
        total: 9,
      );

      expectPrivateCustomPackContext(
        completion.context,
        completionId: 'typing-completion',
        contentType: 'custom_wordbook_game',
        contentId: 'custom_pack:pack-42:typing',
        scoreSummary: '5/9',
      );
    });
  });

  test('book analysis factory emits only bounded aggregate metadata', () {
    const sensitiveOcr = 'OCR_PRIVATE_TEXT_DO_NOT_TRANSMIT';
    const sensitiveImageLease = 'file:///private/camera/lease.jpg';

    final completion = FeedbackCompletion.bookAnalysis(
      createId: () => 'book-analysis-completion',
      words: 4,
      grammar: 1,
      sentences: 2,
      source: BookAnalysisFeedbackSource.offline,
    );
    final wire = completion.context.toWire();

    expect(completion.context.validate().isValid, isTrue);
    expect(wire, {
      'completionId': 'book-analysis-completion',
      'contentType': 'book_analysis',
      'contentId': 'book_analysis',
      'contentLabel': 'book_analysis',
      'scoreSummary': 'words:4; grammar:1; sentences:2; source:offline',
    });
    expect(wire.values.whereType<String>(), isNot(contains(sensitiveOcr)));
    expect(
      wire.values.whereType<String>(),
      isNot(contains(sensitiveImageLease)),
    );
  });

  test('quest reward factory emits only fixed aggregate metadata', () {
    const sensitiveDisplayName = 'private-tester@example.invalid';
    const sensitiveActivityHistory = 'finished scenario-99 at 10:14';

    final completion = FeedbackCompletion.questReward(
      createId: () => 'quest-reward-completion',
      questId: 'q_jangdokdae',
      questType: 'standing',
      target: 50,
    );
    final wire = completion.context.toWire();

    expect(completion.context.validate().isValid, isTrue);
    expect(wire, {
      'completionId': 'quest-reward-completion',
      'contentType': 'quest_reward',
      'contentId': 'q_jangdokdae',
      'contentLabel': 'quest_reward',
      'scoreSummary': 'type:standing; target:50',
    });
    expect(
      wire.values.whereType<String>(),
      isNot(contains(sensitiveDisplayName)),
    );
    expect(
      wire.values.whereType<String>(),
      isNot(contains(sensitiveActivityHistory)),
    );
  });

  test('milestone factory emits only fixed aggregate metadata', () {
    const sensitiveVocabularyId = 'private-vocabulary-id-42';
    const sensitiveHistory = 'streak: 1, 2, 3, 4, 5, 6, 7';

    final completion = FeedbackCompletion.milestone(
      createId: () => 'milestone-completion',
      milestoneId: 'streak_7',
      milestoneType: 'streak',
      value: 7,
    );
    final wire = completion.context.toWire();

    expect(completion.context.validate().isValid, isTrue);
    expect(wire, {
      'completionId': 'milestone-completion',
      'contentType': 'milestone',
      'contentId': 'streak_7',
      'contentLabel': 'milestone',
      'scoreSummary': 'type:streak; value:7',
    });
    expect(
      wire.values.whereType<String>(),
      isNot(contains(sensitiveVocabularyId)),
    );
    expect(wire.values.whereType<String>(), isNot(contains(sensitiveHistory)));
  });

  test('completion slot keeps one result ID and resets it for replay', () {
    var allocations = 0;
    String createId() => 'completion-${++allocations}';
    final slot = FeedbackCompletionSlot();

    final firstRound = slot.complete(
      () => FeedbackCompletion.cloze(
        createId: createId,
        contentLabel: 'Cloze',
        level: null,
        correct: 4,
        total: 10,
      ),
    );
    final duplicateFinish = slot.complete(
      () => FeedbackCompletion.cloze(
        createId: createId,
        contentLabel: 'Cloze',
        level: null,
        correct: 5,
        total: 10,
      ),
    );

    expect(firstRound.context.completionId, 'completion-1');
    expect(duplicateFinish, same(firstRound));
    expect(slot.current, same(firstRound));
    expect(allocations, 1);

    slot.reset();
    expect(slot.current, isNull);

    final replay = slot.complete(
      () => FeedbackCompletion.cloze(
        createId: createId,
        contentLabel: 'Cloze',
        level: null,
        correct: 9,
        total: 10,
      ),
    );

    expect(replay.context.completionId, 'completion-2');
    expect(allocations, 2);
  });
}

void expectPrivateCustomPackContext(
  ContentFeedbackContext context, {
  required String completionId,
  required String contentType,
  required String contentId,
  required String scoreSummary,
}) {
  const userAuthoredPackName =
      'private-name@example.com-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
  final wire = context.toWire();

  expect(context.validate().isValid, isTrue);
  expect(wire, {
    'completionId': completionId,
    'contentType': contentType,
    'contentId': contentId,
    'contentLabel': 'custom_wordbook',
    'scoreSummary': scoreSummary,
  });
  expect(
    wire.values.whereType<String>(),
    isNot(contains(userAuthoredPackName)),
  );
}
