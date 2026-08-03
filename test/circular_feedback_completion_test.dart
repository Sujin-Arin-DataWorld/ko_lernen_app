import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/feedback_completion.dart';

void main() {
  group('circular activity feedback contexts', () {
    test('daily Hangul reports the guided stroke count', () {
      final completion = FeedbackCompletion.dailyHangul(
        createId: () => 'daily-hangul-1',
        contentLabel: 'ㄱ',
        finishedAt: DateTime(2026, 7, 31, 23, 59),
        guidedStrokeCount: 2,
      );

      expect(completion.context.toWire(), {
        'completionId': 'daily-hangul-1',
        'contentType': 'daily_hangul',
        'contentId': 'daily-char:2026-07-31',
        'contentLabel': 'ㄱ',
        'scoreSummary': 'guide_strokes:2',
      });
    });

    test('Chosung contains only round aggregates', () {
      final completion = FeedbackCompletion.chosung(
        createId: () => 'chosung-1',
        contentLabel: 'Initial consonant quiz',
        level: 'b1',
        correct: 7,
        total: 10,
        averageDurationMs: 1250,
      );

      expect(completion.context.toWire(), {
        'completionId': 'chosung-1',
        'contentType': 'game',
        'contentId': 'chosung',
        'contentLabel': 'Initial consonant quiz',
        'level': 'B1',
        'scoreSummary': '7/10; avgMs:1250',
      });
    });

    test('daily Wordle payload excludes its target answer', () {
      final completion = FeedbackCompletion.wordle(
        createId: () => 'wordle-1',
        level: 'a2',
        roundKind: WordleRoundKind.daily,
        won: true,
        guessCount: 3,
      );

      final wire = completion.context.toWire();
      expect(wire, {
        'completionId': 'wordle-1',
        'contentType': 'game',
        'contentId': 'wordle_daily',
        'contentLabel': 'Silben-Rätsel',
        'level': 'A2',
        'scoreSummary': 'result:win; guesses:3',
      });
    });

    test('random Wordle uses a generic identity and loss aggregate', () {
      final completion = FeedbackCompletion.wordle(
        createId: () => 'wordle-2',
        level: null,
        roundKind: WordleRoundKind.random,
        won: false,
        guessCount: 6,
      );

      expect(completion.context.contentId, 'wordle_random');
      expect(completion.context.scoreSummary, 'result:loss; guesses:6');
    });

    test('Kkeunmari contains only chain length and end reason', () {
      final completion = FeedbackCompletion.kkeunmari(
        createId: () => 'kkeunmari-1',
        contentLabel: 'Word chain',
        chainLength: 8,
        endReason: 'tiger_stuck',
      );

      expect(completion.context.toWire(), {
        'completionId': 'kkeunmari-1',
        'contentType': 'game',
        'contentId': 'kkeunmari',
        'contentLabel': 'Word chain',
        'scoreSummary': 'chain:8; end:tiger_stuck',
      });
    });

    test('grammar session contains its filters and seen count only', () {
      final completion = FeedbackCompletion.grammarSession(
        createId: () => 'grammar-1',
        contentLabel: 'Grammar',
        level: 'A2',
        type: 'Particle',
        difficulty: 'Hard',
        seenCount: 4,
      );

      expect(completion.context.toWire(), {
        'completionId': 'grammar-1',
        'contentType': 'grammar_session',
        'contentId': 'grammar:A2:Particle:Hard',
        'contentLabel': 'Grammar',
        'level': 'A2',
        'scoreSummary': 'seen:4',
      });
    });

    test('Hangul cards and writing never fabricate a CEFR level', () {
      final cards = FeedbackCompletion.hangulCards(
        createId: () => 'cards-1',
        contentLabel: 'Hangul cards',
        interactionCount: 3,
      );
      final writing = FeedbackCompletion.hangulWriting(
        createId: () => 'writing-1',
        contentLabel: 'Hangul writing',
        strokeCount: 2,
      );

      expect(cards.context.toWire(), {
        'completionId': 'cards-1',
        'contentType': 'hangul_cards',
        'contentId': 'hangul:cards',
        'contentLabel': 'Hangul cards',
        'scoreSummary': 'interactions:3',
      });
      expect(writing.context.toWire(), {
        'completionId': 'writing-1',
        'contentType': 'hangul_writing',
        'contentId': 'hangul:writing',
        'contentLabel': 'Hangul writing',
        'scoreSummary': 'strokes:2',
      });
      expect(cards.context.level, isNull);
      expect(writing.context.level, isNull);
    });
  });

  test('new circular activity session receives a new completion identity', () {
    var allocations = 0;
    String createId() => 'round-${++allocations}';
    final slot = FeedbackCompletionSlot();

    final first = slot.complete(
      () => FeedbackCompletion.chosung(
        createId: createId,
        contentLabel: 'Chosung',
        level: 'A1',
        correct: 4,
        total: 10,
        averageDurationMs: 1000,
      ),
    );
    slot.reset();
    final second = slot.complete(
      () => FeedbackCompletion.chosung(
        createId: createId,
        contentLabel: 'Chosung',
        level: 'A1',
        correct: 6,
        total: 10,
        averageDurationMs: 900,
      ),
    );

    expect(first.context.completionId, 'round-1');
    expect(second.context.completionId, 'round-2');
  });
}
