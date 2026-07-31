import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/feedback_completion.dart';
import 'package:ko_lernen_app/screens/review_session_screen.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/screens/vocab_pack_result_screen.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';

void main() {
  test(
    'scenario result actions persist exactly once before navigation',
    () async {
      for (final action in ['complete', 'open-next']) {
        var persistenceCalls = 0;
        var navigationCalls = 0;

        await runScenarioResultAction(
          persistResult: () async => persistenceCalls++,
          navigate: () async => navigationCalls++,
        );

        expect(persistenceCalls, 1, reason: action);
        expect(navigationCalls, 1, reason: action);
      }
    },
  );

  test('scenario completion contains only safe aggregate result data', () {
    final completion = FeedbackCompletion.scenario(
      createId: () => 'scenario-completion',
      scenarioId: 'cafe-order',
      contentLabel: 'Im Cafe bestellen',
      level: 'a1',
      passed: 4,
      firstTryPassed: 3,
      total: 5,
    );

    expect(completion.context.toWire(), {
      'completionId': 'scenario-completion',
      'contentType': 'scenario',
      'contentId': 'cafe-order',
      'contentLabel': 'Im Cafe bestellen',
      'level': 'A1',
      'scoreSummary': 'passed:4/5; firstTry:3/5',
    });
  });

  test(
    'vocab result route retains its completion identity and actual level',
    () {
      final completion = FeedbackCompletion.vocabPack(
        createId: () => 'vocab-completion',
        packId: 'b2_work_1',
        contentLabel: 'Arbeit',
        level: 'B2',
        bossCorrect: 4,
        bossTotal: 5,
        quizCorrect: 7,
        quizTotal: 8,
      );
      final args = vocabPackResultArguments(
        packId: 'b2_work_1',
        packLevel: 'B2',
        bossAccuracy: 0.8,
        bossCorrect: 4,
        bossTotal: 5,
        quizCorrect: 7,
        quizTotal: 8,
        justCleared: true,
        nextUnlockedPackId: 'b2_work_2',
        feedbackCompletion: completion,
      );

      final screen = VocabPackResultScreen.fromArgs(args);

      expect(args['completionId'], 'vocab-completion');
      expect(args['packLevel'], 'B2');
      expect(screen.completionId, 'vocab-completion');
      expect(screen.packLevel, 'B2');
      expect(screen.feedbackContext, same(completion.context));
    },
  );

  test('listening restart resets the completed scenario identity', () {
    var allocations = 0;
    String createId() => 'listening-${++allocations}';
    final slot = FeedbackCompletionSlot();

    final first = slot.complete(
      () => FeedbackCompletion.listening(
        createId: createId,
        scenarioId: 'station',
        contentLabel: 'Am Bahnhof',
        level: 'A2',
        lines: 6,
        rate: 1.25,
      ),
    );
    slot.reset();
    final replay = slot.complete(
      () => FeedbackCompletion.listening(
        createId: createId,
        scenarioId: 'station',
        contentLabel: 'Am Bahnhof',
        level: 'A2',
        lines: 6,
        rate: 0.75,
      ),
    );

    expect(first.context.completionId, 'listening-1');
    expect(first.context.scoreSummary, 'lines:6; rate:1.25x');
    expect(replay.context.completionId, 'listening-2');
    expect(replay.context.scoreSummary, 'lines:6; rate:0.75x');
  });

  test('listening ignores a stale finish after scenario reset', () async {
    final persistXp = Completer<void>();
    final lifecycle = ListeningFeedbackCompletionState();

    final oldFinish = lifecycle.finish(
      persistXp: () => persistXp.future,
      create: () => FeedbackCompletion.listening(
        createId: () => 'old-completion',
        scenarioId: 'station',
        contentLabel: 'Am Bahnhof',
        level: 'A2',
        lines: 6,
        rate: 1,
      ),
    );

    expect(lifecycle.current?.context.completionId, 'old-completion');
    lifecycle.reset();
    expect(lifecycle.current, isNull);

    persistXp.complete();

    expect(await oldFinish, isNull);
    expect(lifecycle.current, isNull);
  });

  test('review callers remain distinguishable without word-list data', () {
    const today = ReviewSessionScreen();
    const hardWords = ReviewSessionScreen(
      feedbackContentId: 'hard_words',
      feedbackContentLabel: 'Schwierige Woerter',
    );
    const course = ReviewSessionScreen(
      feedbackContentId: 'personalized_course',
      feedbackContentLabel: 'Dein Tageskurs',
    );

    expect(today.feedbackContentId, 'today_review');
    expect(hardWords.feedbackContentId, 'hard_words');
    expect(course.feedbackContentId, 'personalized_course');

    final completion = FeedbackCompletion.review(
      createId: () => 'review-completion',
      contentId: course.feedbackContentId,
      contentLabel: course.feedbackContentLabel!,
      level: null,
      reviewed: 5,
      total: 5,
    );
    expect(completion.context.toWire(), {
      'completionId': 'review-completion',
      'contentType': 'review',
      'contentId': 'personalized_course',
      'contentLabel': 'Dein Tageskurs',
      'scoreSummary': 'reviewed:5; total:5',
    });
  });

  test('review reports a level only for a wholly one-level deck', () {
    expect(unambiguousReviewLevel(['a1', 'A1']), 'A1');
    expect(unambiguousReviewLevel(['A1', '']), isNull);
    expect(unambiguousReviewLevel(['A1', 'A2']), isNull);
  });

  test('custom pack replay keeps private valid feedback metadata', () {
    var allocations = 0;
    String createId() => 'custom-${++allocations}';
    final slot = FeedbackCompletionSlot();

    final first = slot.complete(
      () => FeedbackCompletion.customPackPlay(
        createId: createId,
        packId: 'cp_trip',
        learned: 2,
        total: 3,
      ),
    );
    slot.reset();
    final replay = slot.complete(
      () => FeedbackCompletion.customPackPlay(
        createId: createId,
        packId: 'cp_trip',
        learned: 3,
        total: 3,
      ),
    );

    expect(first.context.toWire(), {
      'completionId': 'custom-1',
      'contentType': 'custom_wordbook',
      'contentId': 'custom_pack:cp_trip:play',
      'contentLabel': 'custom_wordbook',
      'scoreSummary': 'learned:2; total:3',
    });
    const userAuthoredPackName =
        'private-name@example.com-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
    expect(first.context.validate().isValid, isTrue);
    expect(
      first.context.toWire().values.whereType<String>(),
      isNot(contains(userAuthoredPackName)),
    );
    expect(replay.context.completionId, 'custom-2');
    expect(replay.context.scoreSummary, 'learned:3; total:3');
  });

  test('legacy due session excludes initially empty and non-due states', () {
    var allocations = 0;
    final session = LegacyDueFeedbackSession();

    expect(
      session.completeIfEligible(
        isDueMode: true,
        dueIsEmpty: true,
        createId: () => 'legacy-${++allocations}',
        contentLabel: 'Heute lernen',
        level: null,
      ),
      isNull,
    );

    session.record(known: true);
    expect(
      session.completeIfEligible(
        isDueMode: false,
        dueIsEmpty: true,
        createId: () => 'legacy-${++allocations}',
        contentLabel: 'Heute lernen',
        level: null,
      ),
      isNull,
    );

    final completion = session.completeIfEligible(
      isDueMode: true,
      dueIsEmpty: true,
      createId: () => 'legacy-${++allocations}',
      contentLabel: 'Heute lernen',
      level: null,
    );

    expect(allocations, 1);
    expect(completion?.context.toWire(), {
      'completionId': 'legacy-1',
      'contentType': 'legacy_vocab',
      'contentId': 'due_session',
      'contentLabel': 'Heute lernen',
      'scoreSummary': 'processed:1; known:1; retry:0',
    });
  });
}
