import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/config/tester_feedback_feature.dart';
import 'package:ko_lernen_app/data/hangul_strokes.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/chosung_quiz_screen.dart';
import 'package:ko_lernen_app/screens/daily_char_sheet.dart';
import 'package:ko_lernen_app/screens/grammar_screen.dart';
import 'package:ko_lernen_app/screens/hangul_screen.dart';
import 'package:ko_lernen_app/screens/home_screen.dart';
import 'package:ko_lernen_app/screens/kkeunmari_screen.dart';
import 'package:ko_lernen_app/screens/wordle_screen.dart';
import 'package:ko_lernen_app/services/content_feedback_service.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/kkeunmari_engine.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/chip.dart';
import 'package:ko_lernen_app/widgets/sori/content_feedback_card.dart';
import 'package:ko_lernen_app/widgets/stroke_canvas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_tut_chosung': true,
      'kl_tut_wordle': true,
      'kl_tut_kkeunmari': true,
      'kl_tut_grammar': true,
      'kl_tut_hangul': true,
    });
    await Storage.init();
    DataLoader.reset();
    KkeunmariEngine.reset();
    await DataLoader.loadVocab();
    await DataLoader.loadGrammar();
    await KkeunmariEngine.load();
  });

  testWidgets('stroke guide reports initial and replay completion', (
    tester,
  ) async {
    const perStroke = Duration(milliseconds: 100);
    final strokes = hangulStrokes['ㄷ']!;
    var completions = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: StrokeCanvas(
            letter: 'ㄷ',
            strokes: strokes,
            perStroke: perStroke,
            onCompleted: () => completions++,
          ),
        ),
      ),
    );

    expect(completions, 0);
    await tester.pump(
      perStroke * strokes.length + const Duration(microseconds: 1),
    );
    expect(completions, 1);

    await tester.tap(find.byType(StrokeCanvas));
    await tester.pump();
    await tester.pump(
      perStroke * strokes.length + const Duration(microseconds: 1),
    );
    expect(completions, 2);
  });

  testWidgets('Home daily card uses fallback copy without stroke data', (
    tester,
  ) async {
    await _setLargeView(tester);
    await tester.pumpWidget(_wrap(const HomeScreen(dailyCharacter: '가')));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Look at today’s letter'), findsOneWidget);
    expect(find.text('Watch the stroke-order guide'), findsNothing);
  });

  testWidgets('daily character requires the guide before completion feedback', (
    tester,
  ) async {
    await _setLargeView(tester);
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showDailyCharSheet(context, character: 'ㄷ'),
                child: const Text('Open daily character'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open daily character'));
    await tester.pump(const Duration(milliseconds: 500));

    final doneFinder = find.byWidgetPredicate(
      (widget) => widget is SoriButton && widget.label == 'Done',
    );
    var done = tester.widget<SoriButton>(doneFinder);
    final guide = tester.widget<StrokeCanvas>(find.byType(StrokeCanvas));
    expect(guide.strokes, isNotEmpty);
    expect(done.onTap, isNull);
    expect(find.byType(ContentFeedbackCard), findsNothing);

    await tester.pump(
      guide.perStroke * guide.strokes.length + const Duration(microseconds: 1),
    );
    done = tester.widget<SoriButton>(doneFinder);
    expect(done.onTap, isNotNull);
    done.onTap!();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Great job!'), findsOneWidget);
    final feedback = tester.widget<ContentFeedbackCard>(
      find.byType(ContentFeedbackCard),
    );
    expect(
      feedback.feedbackContext.scoreSummary,
      'guide_strokes:${guide.strokes.length}',
    );
    expect(find.text('Close'), findsOneWidget);

    tester
        .widget<SoriButton>(
          find.byWidgetPredicate(
            (widget) => widget is SoriButton && widget.label == 'Close',
          ),
        )
        .onTap!();
  });

  testWidgets('daily character without strokes allows fallback completion', (
    tester,
  ) async {
    await _setLargeView(tester);
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showDailyCharSheet(context, character: '가'),
                child: const Text('Open daily character'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open daily character'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Look at today’s letter'), findsOneWidget);
    expect(find.text('Watch the stroke-order guide'), findsNothing);
    expect(find.byType(StrokeCanvas), findsNothing);
    final done = tester.widget<SoriButton>(
      find.byWidgetPredicate(
        (widget) => widget is SoriButton && widget.label == 'Done',
      ),
    );
    expect(done.onTap, isNotNull);
    done.onTap!();
    await tester.pump(const Duration(seconds: 2));

    final feedback = tester.widget<ContentFeedbackCard>(
      find.byType(ContentFeedbackCard),
    );
    expect(feedback.feedbackContext.scoreSummary, 'guide_strokes:0');
  });

  testWidgets('Chosung renders feedback and resets identity for a new round', (
    tester,
  ) async {
    await _setLargeView(tester);
    await tester.pumpWidget(_wrap(const ChosungQuizScreen()));
    await _pumpUntil(tester, find.text('Skip'));

    await _skipChosungRound(tester);
    final firstCard = tester.widget<ContentFeedbackCard>(
      find.byType(ContentFeedbackCard),
    );

    tester
        .widget<SoriButton>(
          find.byWidgetPredicate(
            (widget) => widget is SoriButton && widget.label == 'Keep going',
          ),
        )
        .onTap!();
    await tester.pump();
    expect(find.byType(ContentFeedbackCard), findsNothing);

    await _skipChosungRound(tester);
    final secondCard = tester.widget<ContentFeedbackCard>(
      find.byType(ContentFeedbackCard),
    );

    expect(
      secondCard.feedbackContext.completionId,
      isNot(firstCard.feedbackContext.completionId),
    );
  });

  testWidgets('Wordle result is safe and a random round gets a new identity', (
    tester,
  ) async {
    await _setLargeView(tester);
    await tester.pumpWidget(_wrap(const WordleScreen()));
    await _pumpUntil(tester, find.byType(TextField));

    final first = await _loseWordle(tester);
    final answerText = tester.widget<Text>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text && widget.data?.startsWith('Answer: ') == true,
      ),
    );
    final actualTarget = answerText.data!.substring('Answer: '.length);
    final firstWire = first.feedbackContext.toWire();
    for (final field in ['contentId', 'contentLabel', 'scoreSummary']) {
      expect(
        firstWire[field],
        isNot(contains(actualTarget)),
        reason: '$field must not contain the live Wordle target',
      );
    }
    expect(first.feedbackContext.contentId, 'wordle_daily');
    expect(first.feedbackContext.contentLabel, 'Silben-Rätsel');
    expect(first.feedbackContext.scoreSummary, 'result:loss; guesses:6');

    await tester.tap(find.text('New word').first);
    await _pumpUntil(tester, find.byType(TextField));
    expect(find.byType(ContentFeedbackCard), findsNothing);

    final second = await _loseWordle(tester);
    expect(second.feedbackContext.contentId, 'wordle_random');
    expect(
      second.feedbackContext.completionId,
      isNot(first.feedbackContext.completionId),
    );
  });

  testWidgets('Kkeunmari timeout renders feedback and replay resets identity', (
    tester,
  ) async {
    await _setLargeView(tester);
    await tester.pumpWidget(_wrap(const KkeunmariScreen()));
    await _pumpUntil(tester, find.byType(TextField));

    await tester.pump(const Duration(seconds: 31));
    await tester.pump();
    final first = tester.widget<ContentFeedbackCard>(
      find.byType(ContentFeedbackCard),
    );
    expect(first.feedbackContext.contentId, 'kkeunmari');

    await tester.tap(find.text('Play again'));
    await _pumpUntil(tester, find.byType(TextField));
    expect(find.byType(ContentFeedbackCard), findsNothing);

    await tester.pump(const Duration(seconds: 31));
    await tester.pump();
    final second = tester.widget<ContentFeedbackCard>(
      find.byType(ContentFeedbackCard),
    );
    expect(
      second.feedbackContext.completionId,
      isNot(first.feedbackContext.completionId),
    );
  });

  testWidgets('grammar finish requires a meaningful study interaction', (
    tester,
  ) async {
    await _setLargeView(tester);
    await tester.pumpWidget(_wrap(const GrammarScreen()));
    await _pumpUntil(tester, find.byType(FlipCard));

    var finish = tester.widget<SoriButton>(
      find.byKey(const Key('grammar-finish-session')),
    );
    expect(finish.onTap, isNull);
    expect(find.byType(ContentFeedbackCard), findsNothing);

    await tester.tap(find.byType(FlipCard));
    await tester.pump();
    finish = tester.widget<SoriButton>(
      find.byKey(const Key('grammar-finish-session')),
    );
    expect(finish.onTap, isNotNull);

    await tester.tap(find.byKey(const Key('grammar-finish-session')));
    await tester.pump(const Duration(milliseconds: 500));
    final card = tester.widget<ContentFeedbackCard>(
      find.byType(ContentFeedbackCard),
    );
    expect(card.feedbackContext.contentType, 'grammar_session');
    expect(card.feedbackContext.scoreSummary, 'seen:1');

    final firstCompletionId = card.feedbackContext.completionId;
    await _closeFeedbackResult(tester);
    finish = tester.widget<SoriButton>(
      find.byKey(const Key('grammar-finish-session')),
    );
    expect(finish.onTap, isNull);
    expect(find.byType(ContentFeedbackCard), findsNothing);

    tester
        .widget<SoriButton>(
          find.byWidgetPredicate(
            (widget) => widget is SoriButton && widget.label == 'Got it',
          ),
        )
        .onTap!();
    await tester.pump();
    finish = tester.widget<SoriButton>(
      find.byKey(const Key('grammar-finish-session')),
    );
    expect(finish.onTap, isNotNull);
    await tester.tap(find.byKey(const Key('grammar-finish-session')));
    await tester.pump(const Duration(milliseconds: 500));
    final secondCard = tester.widget<ContentFeedbackCard>(
      find.byType(ContentFeedbackCard),
    );
    expect(secondCard.feedbackContext.completionId, isNot(firstCompletionId));
  });

  testWidgets('grammar level filter resets the current study interaction set', (
    tester,
  ) async {
    await _setLargeView(tester);
    await tester.pumpWidget(_wrap(const GrammarScreen()));
    await _pumpUntil(tester, find.byType(FlipCard));

    await tester.tap(find.byType(FlipCard));
    await tester.pump();
    expect(
      tester
          .widget<SoriButton>(find.byKey(const Key('grammar-finish-session')))
          .onTap,
      isNotNull,
    );

    final a2Filter = find.widgetWithText(SoriChip, 'A2');
    await tester.ensureVisible(a2Filter);
    await tester.tap(a2Filter);
    await tester.pump();

    expect(
      tester
          .widget<SoriButton>(find.byKey(const Key('grammar-finish-session')))
          .onTap,
      isNull,
    );

    await tester.tap(find.byType(FlipCard));
    await tester.pump();
    await tester.tap(find.byKey(const Key('grammar-finish-session')));
    await tester.pump(const Duration(milliseconds: 500));
    final card = tester.widget<ContentFeedbackCard>(
      find.byType(ContentFeedbackCard),
    );
    expect(card.feedbackContext.contentId, contains('grammar:A2:'));
    expect(card.feedbackContext.scoreSummary, 'seen:1');
  });

  testWidgets(
    'dismissing staged grammar filters preserves the active session',
    (tester) async {
      await _setLargeView(tester);
      await tester.pumpWidget(_wrap(const GrammarScreen()));
      await _pumpUntil(tester, find.byType(FlipCard));

      await tester.tap(find.byType(FlipCard));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('A2').last);
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      final a1Filter = tester.widget<SoriChip>(
        find.widgetWithText(SoriChip, 'A1').first,
      );
      expect(a1Filter.selected, isTrue);
      expect(
        tester
            .widget<SoriButton>(find.byKey(const Key('grammar-finish-session')))
            .onTap,
        isNotNull,
      );

      await tester.tap(find.byKey(const Key('grammar-finish-session')));
      await tester.pump(const Duration(milliseconds: 500));
      final card = tester.widget<ContentFeedbackCard>(
        find.byType(ContentFeedbackCard),
      );
      expect(card.feedbackContext.contentId, contains('grammar:A1:'));
      expect(card.feedbackContext.scoreSummary, 'seen:1');
    },
  );

  testWidgets('same-index Hangul random does not enable finish', (
    tester,
  ) async {
    await _setLargeView(tester);
    await tester.pumpWidget(
      _wrap(HangulScreen(cardsRandom: _SameIndexRandom())),
    );
    tester.widget<TabBar>(find.byType(TabBar)).controller!.index = 1;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    tester
        .widget<SoriButton>(
          find.byWidgetPredicate(
            (widget) => widget is SoriButton && widget.label == 'Random',
          ),
        )
        .onTap!();
    await tester.pump();

    final finish = tester.widget<SoriButton>(
      find.byKey(const Key('hangul-cards-finish')),
    );
    expect(finish.onTap, isNull);
  });

  testWidgets('Hangul cards finish requires a view or flip interaction', (
    tester,
  ) async {
    await _setLargeView(tester);
    await tester.pumpWidget(_wrap(const HangulScreen()));
    tester.widget<TabBar>(find.byType(TabBar)).controller!.index = 1;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    var finish = tester.widget<SoriButton>(
      find.byKey(const Key('hangul-cards-finish')),
    );
    expect(finish.onTap, isNull);
    expect(find.byType(ContentFeedbackCard), findsNothing);

    await tester.tap(find.byType(FlipCard));
    await tester.pump();
    finish = tester.widget<SoriButton>(
      find.byKey(const Key('hangul-cards-finish')),
    );
    expect(finish.onTap, isNotNull);

    await tester.tap(find.byKey(const Key('hangul-cards-finish')));
    await tester.pump(const Duration(milliseconds: 500));
    final card = tester.widget<ContentFeedbackCard>(
      find.byType(ContentFeedbackCard),
    );
    expect(card.feedbackContext.contentType, 'hangul_cards');
    expect(card.feedbackContext.level, isNull);

    final firstCompletionId = card.feedbackContext.completionId;
    await _closeFeedbackResult(tester);
    finish = tester.widget<SoriButton>(
      find.byKey(const Key('hangul-cards-finish')),
    );
    expect(finish.onTap, isNull);
    expect(find.byType(ContentFeedbackCard), findsNothing);

    tester
        .widget<SoriButton>(
          find.byWidgetPredicate(
            (widget) => widget is SoriButton && widget.label == 'Next',
          ),
        )
        .onTap!();
    await tester.pump();
    finish = tester.widget<SoriButton>(
      find.byKey(const Key('hangul-cards-finish')),
    );
    expect(finish.onTap, isNotNull);
    await tester.tap(find.byKey(const Key('hangul-cards-finish')));
    await tester.pump(const Duration(milliseconds: 500));
    final secondCard = tester.widget<ContentFeedbackCard>(
      find.byType(ContentFeedbackCard),
    );
    expect(secondCard.feedbackContext.completionId, isNot(firstCompletionId));
  });

  testWidgets('Hangul writing finish requires a completed canvas stroke', (
    tester,
  ) async {
    await _setLargeView(tester);
    await tester.pumpWidget(_wrap(const HangulScreen()));
    tester.widget<TabBar>(find.byType(TabBar)).controller!.index = 2;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    var finish = tester.widget<SoriButton>(
      find.byKey(const Key('hangul-writing-finish')),
    );
    expect(finish.onTap, isNull);
    expect(find.byType(ContentFeedbackCard), findsNothing);

    await _drawHangulStroke(tester);

    finish = tester.widget<SoriButton>(
      find.byKey(const Key('hangul-writing-finish')),
    );
    expect(finish.onTap, isNotNull);

    await tester.tap(find.byKey(const Key('hangul-writing-finish')));
    await tester.pump(const Duration(milliseconds: 500));
    final card = tester.widget<ContentFeedbackCard>(
      find.byType(ContentFeedbackCard),
    );
    expect(card.feedbackContext.contentType, 'hangul_writing');
    expect(card.feedbackContext.scoreSummary, 'strokes:1');
    expect(card.feedbackContext.level, isNull);

    final firstCompletionId = card.feedbackContext.completionId;
    await _closeFeedbackResult(tester);
    finish = tester.widget<SoriButton>(
      find.byKey(const Key('hangul-writing-finish')),
    );
    expect(finish.onTap, isNull);
    expect(find.byType(ContentFeedbackCard), findsNothing);

    await _drawHangulStroke(tester);
    finish = tester.widget<SoriButton>(
      find.byKey(const Key('hangul-writing-finish')),
    );
    expect(finish.onTap, isNotNull);
    await tester.tap(find.byKey(const Key('hangul-writing-finish')));
    await tester.pump(const Duration(milliseconds: 500));
    final secondCard = tester.widget<ContentFeedbackCard>(
      find.byType(ContentFeedbackCard),
    );
    expect(secondCard.feedbackContext.completionId, isNot(firstCompletionId));
  });
}

Future<void> _closeFeedbackResult(WidgetTester tester) async {
  tester
      .widget<SoriButton>(
        find.byWidgetPredicate(
          (widget) => widget is SoriButton && widget.label == 'Close',
        ),
      )
      .onTap!();
  await tester.pumpAndSettle();
}

Future<void> _drawHangulStroke(WidgetTester tester) async {
  final canvas = tester.widget<GestureDetector>(
    find.byKey(const Key('hangul-practice-canvas')),
  );
  canvas.onPanStart!(
    DragStartDetails(
      globalPosition: Offset(10, 10),
      localPosition: Offset(10, 10),
    ),
  );
  canvas.onPanEnd!(DragEndDetails());
  await tester.pump();
}

Future<void> _skipChosungRound(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    tester
        .widget<SoriButton>(
          find.byWidgetPredicate(
            (widget) => widget is SoriButton && widget.label == 'Skip',
          ),
        )
        .onTap!();
    await tester.pump(const Duration(milliseconds: 1001));
    await tester.pump();
  }
  expect(find.byType(ContentFeedbackCard), findsOneWidget);
}

Future<ContentFeedbackCard> _loseWordle(WidgetTester tester) async {
  final length = tester.widget<TextField>(find.byType(TextField)).maxLength!;
  final guess = List.filled(length, '가').join();
  for (var i = 0; i < 6; i++) {
    await tester.enterText(find.byType(TextField), guess);
    await tester.tap(find.text('Submit'));
    await tester.pump();
  }
  expect(find.byType(ContentFeedbackCard), findsOneWidget);
  return tester.widget<ContentFeedbackCard>(find.byType(ContentFeedbackCard));
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int attempts = 40,
}) async {
  for (var i = 0; i < attempts; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets);
}

Future<void> _setLargeView(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _wrap(Widget child) {
  return ContentFeedbackControllerScope(
    featureGate: const TesterFeedbackFeatureGate(enabled: true),
    submitFeedback: (_, __) async => const ContentFeedbackSubmitResult(
      status: ContentFeedbackSubmitStatus.accepted,
    ),
    resumePending: () async => const ContentFeedbackResumeResult(),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: child,
    ),
  );
}

class _SameIndexRandom implements math.Random {
  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => 0;
}
