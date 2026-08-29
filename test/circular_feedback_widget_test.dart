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
import 'package:ko_lernen_app/screens/kkeunmari_screen.dart';
import 'package:ko_lernen_app/services/content_feedback_service.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/kkeunmari_engine.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/content_feed.dart';
import 'package:ko_lernen_app/widgets/sori/chip.dart';
import 'package:ko_lernen_app/widgets/sori/content_feedback_card.dart';
import 'package:ko_lernen_app/widgets/stroke_canvas.dart';

import 'helpers/deck_actions.dart';

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
      'kl_tut_hangulWriteRules': true,
      // 4방향 덱 코치는 전체 화면 스포트라이트라 탭을 삼킨다. 이 파일은
      // 피드백 수집 계약을 보는 곳이라 코치를 이미 본 사용자로 시작한다.
      'kl_tut_soriDeck': true,
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

  testWidgets('Kkeunmari pauses its turn countdown in the background', (
    tester,
  ) async {
    await _setLargeView(tester);
    await tester.pumpWidget(_wrap(const KkeunmariScreen()));
    await _pumpUntil(tester, find.byType(TextField));

    final timerText = find.byWidgetPredicate(
      (widget) =>
          widget is Text && RegExp(r'^\d+s$').hasMatch(widget.data ?? ''),
    );
    int remaining() =>
        int.parse(tester.widget<Text>(timerText).data!.replaceFirst('s', ''));

    final before = remaining();
    await tester.pump(const Duration(seconds: 2));
    expect(remaining(), before - 2);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final pausedAt = remaining();
    await tester.pump(const Duration(seconds: 5));
    expect(remaining(), pausedAt);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 1));
    expect(remaining(), pausedAt - 1);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  // 2026-08-26: Task 8 (cbc88819) removed the manual
  // `grammar-finish-session` icon button — SRS 판정의 마지막 카드가 곧 세션
  // 종료다(grammar_screen.dart:363-366 `_judge` 참고), 별도 버튼이 필요
  // 없어졌다. 그 버튼을 관통해 확인하던 두 계약(레벨 필터 변경 시 세션 리셋 /
  // 시트 취소 시 세션·칩 보존)은 여전히 살아있는 행동이라 남은 표면으로
  // 다시 고정한다:
  //   - `_sessionSeen` 은 `_finishSession` 의 `seen:N` 페이로드로만 관측되고,
  //     그 경로는 이제 오직 "마지막 카드 판정"뿐이다 — 그래서 아래 두 테스트는
  //     `SoriContentFeed.onSkip`/`onNext` 콜백을 직접 호출해 덱 끝까지
  //     이동한 뒤 자동 종료를 받는다(버튼이 있던 시절처럼 아무 때나 종료를
  //     부를 수 없다).
  //   - 칩 보존은 그대로 `SoriChip.selected` 로 직접 관측된다(버튼과 무관).
  testWidgets('grammar level filter resets the study session set', (
    tester,
  ) async {
    await _setLargeView(tester);
    await tester.pumpWidget(_wrap(const GrammarScreen()));
    await _pumpUntil(tester, find.byType(FlipCard));
    await _dismissGrammarPlanOnboarding(tester);

    // Seed a session before switching levels — this must not survive the
    // filter change below.
    await tester.tap(find.byType(FlipCard));
    await tester.pump();

    // A1 이 초기 레벨이므로(SharedPreferences 'kl_user_level': 'a1'), A2 로
    // 갈아타 실제로 다른 덱이 되는지 및 그 카드 수를 데이터에서 직접 구한다 —
    // 카드 수를 하드코딩하지 않기 위함.
    final allGrammar = await DataLoader.loadGrammar();
    final a2Count = allGrammar.where((g) => g.level == 'A2').length;
    expect(a2Count, greaterThan(1));

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    final a2Filter = find.byKey(const Key('sori-level-sheet-A2'));
    expect(a2Filter, findsOneWidget);
    await tester.tap(a2Filter);
    await tester.pumpAndSettle();

    // Skip through every card but the last — `_skipCurrent` never touches
    // `_sessionSeen` (only `_judge`/`_onFlip` do), so this stays a clean
    // probe of the filter-triggered reset.
    for (var i = 0; i < a2Count - 1; i++) {
      tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).onSkip!();
      await tester.pump();
    }

    // Judging the last card is now the *only* remaining path to
    // `_finishSession` (grammar_screen.dart:363-366).
    tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).onNext!();
    await tester.pump(const Duration(milliseconds: 500));

    final card = tester.widget<ContentFeedbackCard>(
      find.byType(ContentFeedbackCard),
    );
    expect(card.feedbackContext.contentId, contains('grammar:A2:'));
    // If `_sessionSeen.clear()` (grammar_screen.dart:272) had not run on the
    // level switch, the pre-switch flip would leak into this session and
    // this would read 'seen:2' instead.
    expect(card.feedbackContext.scoreSummary, 'seen:1');
  });

  testWidgets(
    'dismissing staged grammar filters preserves the active session and level selection',
    (tester) async {
      await _setLargeView(tester);
      await tester.pumpWidget(_wrap(const GrammarScreen()));
      await _pumpUntil(tester, find.byType(FlipCard));
      await _dismissGrammarPlanOnboarding(tester);

      await tester.tap(find.byType(FlipCard));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.filter_list_rounded));
      await tester.pumpAndSettle();

      // Stage a secondary-filter change, then dismiss via system back instead
      // of "Apply" — the staged value must never reach `_applyFilters`.
      final t = AppL10n.of(tester.element(find.byType(GrammarScreen)));
      await tester.tap(find.widgetWithText(SoriChip, t.grammarEasy));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      final a1Filter = tester.widget<SoriChip>(
        find.byKey(const Key('sori-level-sheet-A1')),
      );
      expect(a1Filter.selected, isTrue);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      final allGrammar = await DataLoader.loadGrammar();
      final a1Count = allGrammar.where((g) => g.level == 'A1').length;
      expect(a1Count, greaterThan(1));

      // Skip to the last card of the *still-A1* deck without judging, then
      // judge it once. If dismissing the sheet had cleared `_sessionSeen`
      // (as "Apply" does), only this final judgment would be counted and
      // the payload below would read 'seen:1' instead of 'seen:2'.
      for (var i = 0; i < a1Count - 1; i++) {
        tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).onSkip!();
        await tester.pump();
      }
      tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).onNext!();
      await tester.pump(const Duration(milliseconds: 500));

      final card = tester.widget<ContentFeedbackCard>(
        find.byType(ContentFeedbackCard),
      );
      expect(card.feedbackContext.contentId, contains('grammar:A1:'));
      expect(card.feedbackContext.scoreSummary, 'seen:2');
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

    // Sori Deck 3.0(2026-08-18): 전폭 버튼 5단이 원형 판정 바 + 44dp 보조
    // 아이콘 행으로 바뀌었다. Zufällig 는 이제 아이콘 버튼이다.
    tester
        .widget<IconButton>(find.byKey(const Key('hangul-cards-random')))
        .onPressed!();
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

    // 'Weiter' 전폭 버튼은 덱 바의 ↓(넘어가기)로 흡수됐다 — 같은 `_next`.
    tapDeckAction(tester, 'Skip');
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

  // 2026-08-17 테스터(Amor): "일부러 획순을 틀려도 인식하지 못하고 그냥
  // 진행된다." 예전 이 테스트는 구석에 10px 사선 하나만 긋고 Finish 가 열리는
  // 것을 **정답으로 단언**하고 있었다. 이제 Finish 는 획순까지 맞게 완성한
  // 글자가 하나 있어야 열린다.
  testWidgets('Hangul writing finish requires a correctly completed letter', (
    tester,
  ) async {
    await _setLargeView(tester);
    await tester.pumpWidget(_wrap(const HangulScreen()));
    tester.widget<TabBar>(find.byType(TabBar)).controller!.index = 2;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // 2026-08-18: Finish 는 글자를 정확히 완성하기 전엔 **아예 렌더되지
    // 않는다**(비활성 자리만 차지하던 죽은 공간을 없애 캔버스에 세로 공간을
    // 넘겼다). 그래서 "비활성" 이 아니라 "부재" 를 단언한다.
    expect(_hangulFinish, findsNothing);
    expect(find.byType(ContentFeedbackCard), findsNothing);

    // 아무 낙서로는 열리지 않는다.
    await _scribbleHangul(tester);
    expect(_hangulFinish, findsNothing);

    await _traceHangulLetter(tester, 'ㄱ');

    expect(_hangulFinish, findsOneWidget);
    expect(tester.widget<SoriButton>(_hangulFinish).onTap, isNotNull);

    await tester.tap(find.byKey(const Key('hangul-writing-finish')));
    await tester.pump(const Duration(milliseconds: 500));
    final card = tester.widget<ContentFeedbackCard>(
      find.byType(ContentFeedbackCard),
    );
    expect(card.feedbackContext.contentType, 'hangul_writing');
    expect(
      card.feedbackContext.scoreSummary,
      'letters:1; strokes:2; mode:strict',
    );
    expect(card.feedbackContext.level, isNull);

    final firstCompletionId = card.feedbackContext.completionId;
    await _closeFeedbackResult(tester);
    expect(_hangulFinish, findsNothing);
    expect(find.byType(ContentFeedbackCard), findsNothing);

    await _traceHangulLetter(tester, 'ㄱ');
    expect(_hangulFinish, findsOneWidget);
    await tester.tap(find.byKey(const Key('hangul-writing-finish')));
    await tester.pump(const Duration(milliseconds: 500));
    final secondCard = tester.widget<ContentFeedbackCard>(
      find.byType(ContentFeedbackCard),
    );
    expect(secondCard.feedbackContext.completionId, isNot(firstCompletionId));
  });
}

final Finder _hangulFinish = find.byKey(const Key('hangul-writing-finish'));

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

/// 획순과 상관없는 낙서 — 판정에서 떨어져야 한다.
Future<void> _scribbleHangul(WidgetTester tester) async {
  final canvas = find.byKey(const Key('hangul-practice-canvas'));
  await tester.ensureVisible(canvas);
  await tester.pump();
  final bounds = tester.getRect(canvas);
  final gesture = await tester.startGesture(
    Offset(bounds.left + 8, bounds.bottom - 8),
  );
  await gesture.moveTo(Offset(bounds.left + 30, bounds.bottom - 20));
  await gesture.up();
  await tester.pump();
}

/// [letter] 의 기준 획을 순서대로, 실제 좌표로 따라 그린다.
Future<void> _traceHangulLetter(WidgetTester tester, String letter) async {
  final canvas = find.byKey(const Key('hangul-practice-canvas'));
  await tester.ensureVisible(canvas);
  await tester.pump();
  final bounds = tester.getRect(canvas);
  final scaleX = bounds.width / strokeCanvas.width;
  final scaleY = bounds.height / strokeCanvas.height;
  Offset at(Offset p) =>
      Offset(bounds.left + p.dx * scaleX, bounds.top + p.dy * scaleY);

  for (final stroke in hangulStrokes[letter]!) {
    final points = switch (stroke) {
      LineStroke(:final points) => points,
      CircleStroke(:final center, :final radius) => [
        for (var i = 0; i <= 24; i++)
          Offset(
            center.dx + radius * math.cos(i / 24 * 2 * math.pi),
            center.dy + radius * math.sin(i / 24 * 2 * math.pi),
          ),
      ],
    };
    final gesture = await tester.startGesture(at(points.first));
    for (final p in points.skip(1)) {
      await gesture.moveTo(at(p));
    }
    await gesture.up();
    await tester.pump();
  }
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

Future<void> _dismissGrammarPlanOnboarding(WidgetTester tester) async {
  if (find
      .byKey(const Key('grammar-plan-onboarding-sheet'))
      .evaluate()
      .isEmpty) {
    return;
  }
  await tester.tapAt(const Offset(8, 8));
  await tester.pump(const Duration(milliseconds: 300));
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
