import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/config/tester_feedback_feature.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/chosung_quiz_screen.dart';
import 'package:ko_lernen_app/screens/daily_char_sheet.dart';
import 'package:ko_lernen_app/screens/grammar_screen.dart';
import 'package:ko_lernen_app/screens/hangul_screen.dart';
import 'package:ko_lernen_app/screens/kkeunmari_screen.dart';
import 'package:ko_lernen_app/screens/wordle_screen.dart';
import 'package:ko_lernen_app/services/content_feedback_service.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/kkeunmari_engine.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/content_feedback_card.dart';

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

  testWidgets('daily character stays open with feedback and explicit Close', (
    tester,
  ) async {
    await _setLargeView(tester);
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showDailyCharSheet(context),
                child: const Text('Open daily character'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open daily character'));
    await tester.pump(const Duration(milliseconds: 500));
    tester
        .widget<SoriButton>(
          find.byWidgetPredicate(
            (widget) => widget is SoriButton && widget.label == 'Done',
          ),
        )
        .onTap!();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Great job!'), findsOneWidget);
    expect(find.byType(ContentFeedbackCard), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);

    tester
        .widget<SoriButton>(
          find.byWidgetPredicate(
            (widget) => widget is SoriButton && widget.label == 'Close',
          ),
        )
        .onTap!();
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
    expect(first.feedbackContext.contentId, 'wordle_daily');
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
  });
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
