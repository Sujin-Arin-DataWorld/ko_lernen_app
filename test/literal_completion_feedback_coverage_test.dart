import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/data/beta_mission_catalog.dart';
import 'package:ko_lernen_app/models/content_feedback.dart';
import 'package:ko_lernen_app/models/feedback_completion.dart';

const requiredFeedbackTypes = <String>{
  'scenario',
  'vocab_pack',
  'review',
  'custom_wordbook',
  'custom_wordbook_game',
  'legacy_vocab',
  'listening',
  'game',
  'grammar_session',
  'hangul_cards',
  'hangul_writing',
  'daily_hangul',
  'book_analysis',
  'quest_reward',
  'milestone',
};

void main() {
  test(
    'literal completion inventory keeps all learning routes mission matched and result routes feedback only',
    () {
      var sequence = 0;
      String createId() => 'literal-completion-${++sequence}';

      final learningSurfaces =
          <({String name, ContentFeedbackContext context, String missionId})>[
            (
              name: 'Cloze',
              context: FeedbackCompletion.cloze(
                createId: createId,
                contentLabel: 'Cloze',
                level: 'a1',
                correct: 4,
                total: 5,
              ).context,
              missionId: 'beta_games',
            ),
            (
              name: 'Daily Challenge',
              context: FeedbackCompletion.dailyChallenge(
                createId: createId,
                contentLabel: 'Daily Challenge',
                finishedAt: DateTime.utc(2026, 8, 2),
                correct: 7,
                total: 10,
              ).context,
              missionId: 'beta_games',
            ),
            (
              name: 'Satz Arcade',
              context: FeedbackCompletion.satzArcade(
                createId: createId,
                contentLabel: 'Satz Arcade',
                level: 'a2',
                passed: 6,
                total: 8,
              ).context,
              missionId: 'beta_games',
            ),
            (
              name: 'Speed Match',
              context: FeedbackCompletion.speedMatch(
                createId: createId,
                contentLabel: 'Speed Match',
                level: 'b1',
                score: 12,
              ).context,
              missionId: 'beta_games',
            ),
            (
              name: 'Custom Pack Quiz',
              context: FeedbackCompletion.customPackQuiz(
                createId: createId,
                packId: 'pack-quiz',
                correct: 9,
                total: 10,
              ).context,
              missionId: 'beta_word_work',
            ),
            (
              name: 'Custom Pack Matching',
              context: FeedbackCompletion.customPackMatching(
                createId: createId,
                packId: 'pack-matching',
                pairs: 8,
                misses: 1,
              ).context,
              missionId: 'beta_word_work',
            ),
            (
              name: 'Custom Pack Typing',
              context: FeedbackCompletion.customPackTyping(
                createId: createId,
                packId: 'pack-typing',
                correct: 6,
                total: 8,
              ).context,
              missionId: 'beta_word_work',
            ),
            (
              name: 'Chosung',
              context: FeedbackCompletion.chosung(
                createId: createId,
                contentLabel: 'Chosung',
                level: 'a1',
                correct: 4,
                total: 5,
                averageDurationMs: 900,
              ).context,
              missionId: 'beta_games',
            ),
            (
              name: 'Silben-Rätsel',
              context: FeedbackCompletion.wordle(
                createId: createId,
                level: 'a2',
                roundKind: WordleRoundKind.daily,
                won: true,
                guessCount: 4,
              ).context,
              missionId: 'beta_games',
            ),
            (
              name: 'Kkeunmari',
              context: FeedbackCompletion.kkeunmari(
                createId: createId,
                contentLabel: 'Kkeunmari',
                chainLength: 11,
                endReason: 'timeout',
              ).context,
              missionId: 'beta_games',
            ),
            (
              name: 'Daily Hangul',
              context: FeedbackCompletion.dailyHangul(
                createId: createId,
                contentLabel: 'Daily Hangul',
                finishedAt: DateTime.utc(2026, 8, 2),
                guidedStrokeCount: 12,
              ).context,
              missionId: 'beta_language_form',
            ),
            (
              name: 'Grammar',
              context: FeedbackCompletion.grammarSession(
                createId: createId,
                contentLabel: 'Grammar',
                level: 'A2',
                type: 'particles',
                difficulty: 'normal',
                seenCount: 5,
              ).context,
              missionId: 'beta_language_form',
            ),
            (
              name: 'Hangul Cards',
              context: FeedbackCompletion.hangulCards(
                createId: createId,
                contentLabel: 'Hangul Cards',
                interactionCount: 14,
              ).context,
              missionId: 'beta_language_form',
            ),
            (
              name: 'Hangul Writing',
              context: FeedbackCompletion.hangulWriting(
                createId: createId,
                contentLabel: 'Hangul Writing',
                strokeCount: 18,
              ).context,
              missionId: 'beta_language_form',
            ),
            (
              name: 'Scenario',
              context: FeedbackCompletion.scenario(
                createId: createId,
                scenarioId: 'scenario:cafe',
                contentLabel: 'Cafe',
                level: 'a1',
                passed: 4,
                firstTryPassed: 3,
                total: 5,
              ).context,
              missionId: 'beta_scenario',
            ),
            (
              name: 'Listening',
              context: FeedbackCompletion.listening(
                createId: createId,
                scenarioId: 'listening:market',
                contentLabel: 'Market listening',
                level: 'a2',
                lines: 9,
                rate: 1,
              ).context,
              missionId: 'beta_listening',
            ),
            (
              name: 'Review',
              context: FeedbackCompletion.review(
                createId: createId,
                contentId: 'review:daily',
                contentLabel: 'Daily review',
                level: 'b1',
                reviewed: 11,
                total: 12,
              ).context,
              missionId: 'beta_word_work',
            ),
            (
              name: 'Legacy Due',
              context: FeedbackCompletion.legacyDue(
                createId: createId,
                contentLabel: 'Due cards',
                level: 'a1',
                processed: 9,
                known: 6,
                retry: 3,
              ).context,
              missionId: 'beta_word_work',
            ),
            (
              name: 'Custom Pack Play',
              context: FeedbackCompletion.customPackPlay(
                createId: createId,
                packId: 'pack-play',
                learned: 6,
                total: 7,
              ).context,
              missionId: 'beta_word_work',
            ),
            (
              name: 'Vocab Pack Result',
              context: FeedbackCompletion.vocabPack(
                createId: createId,
                packId: 'vocab:food',
                contentLabel: 'Food',
                level: 'a1',
                bossCorrect: 4,
                bossTotal: 5,
                quizCorrect: 9,
                quizTotal: 10,
              ).context,
              missionId: 'beta_word_work',
            ),
          ];
      final feedbackOnlySurfaces =
          <({String name, ContentFeedbackContext context})>[
            (
              name: 'Book Result',
              context: FeedbackCompletion.bookAnalysis(
                createId: createId,
                words: 4,
                grammar: 1,
                sentences: 2,
                source: BookAnalysisFeedbackSource.offline,
              ).context,
            ),
            (
              name: 'Quest completion',
              context: FeedbackCompletion.questReward(
                createId: createId,
                questId: 'quest:daily-1',
                questType: 'daily',
                target: 1,
              ).context,
            ),
            (
              name: 'Home Milestone',
              context: FeedbackCompletion.milestone(
                createId: createId,
                milestoneId: 'milestone:streak-7',
                milestoneType: 'streak',
                value: 7,
              ).context,
            ),
          ];

      expect(learningSurfaces, hasLength(20));
      expect(feedbackOnlySurfaces, hasLength(3));
      expect(
        [
          ...learningSurfaces.map((surface) => surface.name),
          ...feedbackOnlySurfaces.map((surface) => surface.name),
        ],
        equals(const [
          'Cloze',
          'Daily Challenge',
          'Satz Arcade',
          'Speed Match',
          'Custom Pack Quiz',
          'Custom Pack Matching',
          'Custom Pack Typing',
          'Chosung',
          'Wordle',
          'Kkeunmari',
          'Daily Hangul',
          'Grammar',
          'Hangul Cards',
          'Hangul Writing',
          'Scenario',
          'Listening',
          'Review',
          'Legacy Due',
          'Custom Pack Play',
          'Vocab Pack Result',
          'Book Result',
          'Quest completion',
          'Home Milestone',
        ]),
      );
      expect({
        for (final surface in [
          ...learningSurfaces.map((surface) => surface.context),
          ...feedbackOnlySurfaces.map((surface) => surface.context),
        ])
          surface.contentType,
      }, equals(requiredFeedbackTypes));

      for (final surface in learningSurfaces) {
        expect(
          surface.context.validate().isValid,
          isTrue,
          reason: '${surface.name} context must remain valid.',
        );
        expect(
          missionFor(surface.context)?.id,
          surface.missionId,
          reason: '${surface.name} must remain Passport mission matched.',
        );
      }

      for (final surface in feedbackOnlySurfaces) {
        expect(
          surface.context.validate().isValid,
          isTrue,
          reason: '${surface.name} context must remain valid.',
        );
        expect(
          missionFor(surface.context),
          isNull,
          reason: '${surface.name} must remain feedback-only.',
        );
        expect(
          nextMission(const <String>{}, surface.context),
          isNull,
          reason: '${surface.name} must not earn a Passport mission.',
        );
      }
    },
  );
}
