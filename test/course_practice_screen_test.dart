import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/smalltalk.dart';
import 'package:ko_lernen_app/screens/grammar_screen.dart';
import 'package:ko_lernen_app/screens/smalltalk_screen.dart';
import 'package:ko_lernen_app/services/course_checkpoint_questions.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/smalltalk_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/chip.dart';
import 'package:ko_lernen_app/widgets/sori/content_feed.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    // Course checks are the subject of these tests; do not let the first-run
    // full-screen coach consume their taps.
    await Storage.setTutSeen('grammar');
    await Storage.setTutSeen('smalltalk');
    // 4방향 덱 코치도 억제한다 — 전체 화면 스포트라이트가 탭을 삼킨다.
    await Storage.setTutSeen('soriDeck');
    DataLoader.reset();
    SmalltalkLoader.reset();
    CurriculumCatalog.reset();
  });

  testWidgets(
    'course grammar hides the target pattern until the scored check',
    (tester) async {
      final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
      final link = catalog.contentLinks.firstWhere(
        (item) =>
            item.contentKind == CurriculumContentKind.grammar &&
            item.courseUnitId == 'a1_03_topic_subject_particles' &&
            item.role == ContentLinkRole.assess,
      );
      final ids = courseContentIdsForContext(
        catalog: catalog,
        courseContext: CoursePracticeContext.fromLink(link),
        kind: CurriculumContentKind.grammar,
      )!;
      final target = (await DataLoader.loadGrammar()).firstWhere(
        (grammar) => ids.contains(grammar.id),
      );

      await tester.pumpWidget(
        _wrap(
          GrammarScreen(courseContext: CoursePracticeContext.fromLink(link)),
        ),
      );
      await _settleCourseScreen(tester);

      expect(find.text('Quick check'), findsOneWidget);
      expect(find.text(target.pattern), findsNothing);
      expect(
        find.byKey(const Key('grammar-choice-cta'), skipOffstage: false),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      await _disposeCourseScreen(tester);
    },
  );

  testWidgets(
    'B2 counterfactual checkpoint card opens its scored choices on tap',
    (tester) async {
      const targetId = 'grammar_b2_counterfactual_past';
      final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
      final link = catalog.contentLinks.singleWhere(
        (item) =>
            item.contentKind == CurriculumContentKind.grammar &&
            item.contentId == targetId &&
            item.courseUnitId == 'b2_04_complaint_resolution' &&
            item.role == ContentLinkRole.assess,
      );
      final context = CoursePracticeContext.fromLink(link);
      final scopedIds = courseContentIdsForContext(
        catalog: catalog,
        courseContext: context,
        kind: CurriculumContentKind.grammar,
      )!;
      final scopedGrammar = (await DataLoader.loadGrammar())
          .where((grammar) => scopedIds.contains(grammar.id))
          .toList(growable: false);
      final targetIndex = scopedGrammar.indexWhere(
        (grammar) => grammar.id == targetId,
      );
      expect(targetIndex, isNonNegative);
      await Storage.setGrammarLastIdx(targetIndex);

      await tester.pumpWidget(_wrap(GrammarScreen(courseContext: context)));
      await _settleCourseScreen(tester);

      final card = tester.widget<FlipCard>(find.byType(FlipCard));
      expect(card.onTap, isNotNull);
      expect(find.text('V-았/었더라면'), findsNothing);

      await tester.tap(find.byType(FlipCard));
      await tester.pumpAndSettle();

      expect(find.text('V-았/었더라면'), findsOneWidget);
      expect(find.text('Which pattern fits this example?'), findsWidgets);
      final correctChoice = find.widgetWithText(SoriButton, 'V-았/었더라면');
      expect(tester.widget<SoriButton>(correctChoice).onTap, isNotNull);
      await tester.drag(
        find.byType(SingleChildScrollView).last,
        const Offset(0, -240),
      );
      await tester.pump();
      await tester.tap(correctChoice);
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('Correct. This mission has recorded evidence.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await _disposeCourseScreen(tester);
    },
  );

  testWidgets('a one-card grammar deck never offers dead navigation', (
    tester,
  ) async {
    // `a1_02_self_intro_identity` links exactly one grammar card, so its deck
    // is 1 / 1. Wrapping navigation with `% _filtered.length` then returns the
    // same index, which made Weiter/Zurück/Zufällig look active while doing
    // nothing.
    //
    // 둘러보기에서도 같은 상태에 닿을 수 있다. 2026-08-19 이전에는 "Typ" 필터가
    // 그 지름길이었는데(type_de 214 행 중 고유값 213 개), 이제 화면이 2 건 이상인
    // 유형만 내주므로 남은 경로는 난이도 필터다 — 아래 테스트가 그쪽을 덮는다.
    final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
    final link = catalog.contentLinks.singleWhere(
      (item) =>
          item.contentKind == CurriculumContentKind.grammar &&
          item.courseUnitId == 'a1_02_self_intro_identity' &&
          item.role == ContentLinkRole.assess,
    );
    final context = CoursePracticeContext.fromLink(link);
    final scopedIds = courseContentIdsForContext(
      catalog: catalog,
      courseContext: context,
      kind: CurriculumContentKind.grammar,
    )!;
    expect(scopedIds, hasLength(1));

    await tester.pumpWidget(_wrap(GrammarScreen(courseContext: context)));
    await _settleCourseScreen(tester);

    expect(find.text('1 / 1'), findsOneWidget);
    // 판정은 한 장짜리 덱에서도 살아 있다 — 마지막 카드의 판정이 곧 세션
    // 종료이므로 막다른 길이 생기지 않는다. 하단 CTA 는 없앴고 판정은
    // 스와이프(와 Semantics 액션)로만 한다.
    final deck = tester.widget<SoriContentFeed>(find.byType(SoriContentFeed));
    expect(deck.onNext, isNotNull, reason: '다음/이해함');
    expect(deck.onHard, isNotNull, reason: '어렵다');
    expect(deck.onBookmark, isNotNull, reason: '보관');
    expect(deck.onSkip, isNull, reason: '한 장이라 넘길 카드가 없다');
    expect(find.byKey(const Key('grammar-judge-easy')), findsNothing);
    expect(find.byKey(const Key('grammar-judge-hard')), findsNothing);
    // 되돌릴 카드가 없으므로 실행취소는 꺼져 있어야 한다.
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('grammar-undo')))
          .onPressed,
      isNull,
      reason: 'undo must not look tappable on the first card',
    );
    expect(tester.takeException(), isNull);
    await _disposeCourseScreen(tester);
  });

  testWidgets('a filter that leaves one card keeps every control alive', (
    tester,
  ) async {
    // 1 / 1 덱은 여전히 도달 가능한 상태다 — 이 화면은 그때 움직이지 않는
    // Weiter 버튼 대신 필터를 돌려줘야 한다.
    //
    // 2026-08-19 이전에는 "Typ" 필터가 이 상태로 가는 지름길이었다(type_de 는
    // 214 행에 고유값 213 개라 유형 하나 = 카드 하나). 그게 Jin 이 실제로
    // 밟은 경로였고, 지금은 화면이 **2 건 이상인 유형만** 내주므로 그 길은
    // 막혀 있다. 계약 자체는 그대로 유효하니, 남은 경로인 난이도 필터로
    // 같은 상태를 만든다.
    final grammar = (await tester.runAsync(DataLoader.loadGrammar))!;
    expect(grammar, isNotEmpty);
    // 'Schwer' 는 Storage 의 어려움 목록만 남긴다 — 한 개만 넣어 1 / 1 을 만든다.
    await Storage.markGrammarHard(grammar.first.pattern);

    await tester.pumpWidget(_wrap(const GrammarScreen()));
    await _settleCourseScreen(tester);
    await _dismissGrammarPlanOnboarding(tester);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    final hardChip = find.widgetWithText(SoriChip, 'Difficult');
    await tester.ensureVisible(hardChip);
    await tester.pumpAndSettle();
    await tester.tap(hardChip);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SoriButton, 'Apply'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 1'), findsOneWidget);
    // 옛 Weiter/Zurück/Zufällig 와 판정 CTA 는 전부 사라졌고, 판정은 스와이프가
    // 맡는다. 남은 컨트롤은 실제로 동작하거나 정직하게 꺼져 있다.
    expect(find.widgetWithText(SoriButton, 'Next'), findsNothing);
    expect(find.widgetWithText(SoriButton, 'Random'), findsNothing);
    expect(find.byKey(const Key('grammar-judge-easy')), findsNothing);
    final browseDeck = tester.widget<SoriContentFeed>(
      find.byType(SoriContentFeed),
    );
    expect(browseDeck.onNext, isNotNull);
    expect(browseDeck.onHard, isNotNull);
    expect(browseDeck.onBookmark, isNotNull);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('grammar-undo')))
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
    await _disposeCourseScreen(tester);
  });

  testWidgets(
    'DE/EN 320dp 200% grammar chrome and filter follow the Sori contract',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      expect((await tester.runAsync(DataLoader.loadGrammar))!, isNotEmpty);

      for (final locale in const [Locale('de'), Locale('en')]) {
        await tester.pumpWidget(
          _wrap(
            const GrammarScreen(),
            locale: locale,
            textScaler: const TextScaler.linear(2),
            safeInsets: const EdgeInsets.only(top: 44, bottom: 34),
          ),
        );
        await _settleCourseScreen(tester);
        await _dismissGrammarPlanOnboarding(tester);

        final screenContext = tester.element(find.byType(GrammarScreen));
        final t = AppL10n.of(screenContext);
        final text = SoriTextTheme.of(screenContext);
        final counter = find.textContaining(RegExp(r'^\d+ / \d+$'));
        expect(counter, findsOneWidget);
        expect(
          tester.widget<Text>(counter).style,
          text.meta.copyWith(fontWeight: FontWeight.w700),
        );

        await tester.tap(find.byIcon(Icons.tune));
        await tester.pumpAndSettle();

        expect(find.text(t.filterLevel), findsOneWidget);
        final dropdowns = find.byType(DropdownButtonFormField<String>);
        expect(dropdowns, findsWidgets);
        expect(
          tester
              .widget<DropdownButtonFormField<String>>(dropdowns.first)
              .decoration
              .labelStyle,
          text.label,
        );
        expect(find.text(t.filterDifficulty), findsOneWidget);
        expect(
          tester.widget<Text>(find.text(t.filterDifficulty)).style,
          text.label,
        );
        expect(find.widgetWithText(SoriChip, t.filterAll), findsOneWidget);
        expect(find.widgetWithText(SoriChip, t.grammarEasy), findsOneWidget);
        expect(find.widgetWithText(SoriChip, t.grammarHard), findsOneWidget);
        expect(find.text('Leicht'), findsNothing);
        expect(find.text('Schwer'), findsNothing);
        expect(tester.takeException(), isNull);

        await tester.tapAt(const Offset(8, 8));
        await tester.pumpAndSettle();
      }
      await _disposeCourseScreen(tester);
    },
  );

  testWidgets('grammar library opens separate four-choice practice', (
    tester,
  ) async {
    // This test verifies the entry point rather than asset-bundle scheduling.
    // Preload the source just as the preceding course check does, so it stays
    // independent of a prior test resetting the shared loader cache.
    expect((await tester.runAsync(DataLoader.loadGrammar))!, isNotEmpty);
    await tester.pumpWidget(_wrap(const GrammarScreen()));
    await _settleCourseScreen(tester);
    await _dismissGrammarPlanOnboarding(tester);

    final cta = find.byKey(
      const Key('grammar-choice-cta'),
      skipOffstage: false,
    );
    expect(cta, findsOneWidget);
    await tester.ensureVisible(cta);
    await tester.tap(cta);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Grammar practice'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _disposeCourseScreen(tester);
  });

  testWidgets(
    'smalltalk assessment does not reveal the correct relationship before selection',
    (tester) async {
      final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
      final link = catalog.contentLinks.firstWhere(
        (item) =>
            item.contentKind == CurriculumContentKind.smalltalk &&
            item.courseUnitId == 'a2_02_plans_proposals' &&
            item.role == ContentLinkRole.assess,
      );

      await tester.pumpWidget(
        _wrap(
          SmalltalkScreen(courseContext: CoursePracticeContext.fromLink(link)),
        ),
      );
      await _settleCourseScreen(tester);

      await tester.tap(find.text('Quick check').first);
      await tester.pump();

      final relationshipLabels = SmalltalkRelationshipContext.values
          .map((context) => context.labelFor('en'))
          .toSet();
      final optionButtons = tester
          .widgetList<SoriButton>(find.byType(SoriButton))
          .where((button) => relationshipLabels.contains(button.label))
          .toList(growable: false);
      expect(optionButtons, hasLength(3));
      expect(optionButtons.every((button) => button.accent == null), isTrue);
      expect(optionButtons.every((button) => !button.destructive), isTrue);
      expect(tester.takeException(), isNull);
      await _disposeCourseScreen(tester);
    },
  );

  testWidgets(
    'practice-only smalltalk remains guidance and exposes no checkpoint action',
    (tester) async {
      final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
      final link = catalog.contentLinks.firstWhere(
        (item) =>
            item.contentKind == CurriculumContentKind.smalltalk &&
            item.courseUnitId == 'a1_04_order_request_object' &&
            item.role == ContentLinkRole.practice,
      );

      await tester.pumpWidget(
        _wrap(
          SmalltalkScreen(courseContext: CoursePracticeContext.fromLink(link)),
        ),
      );
      await _settleCourseScreen(tester);

      expect(find.text('Quick check'), findsNothing);
      expect(tester.takeException(), isNull);
      await _disposeCourseScreen(tester);
    },
  );
}

Widget _wrap(
  Widget child, {
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
  EdgeInsets safeInsets = EdgeInsets.zero,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: locale,
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, child) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        padding: safeInsets,
        viewPadding: safeInsets,
        textScaler: textScaler,
        disableAnimations: true,
      ),
      child: child!,
    );
  },
  home: child,
);

Future<void> _settleCourseScreen(WidgetTester tester) async {
  // Do not use pumpAndSettle here: the app deliberately contains entrance
  // animations. Two short frames are sufficient for the asset-backed loaders
  // and keep this regression test independent of animation lifetimes.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _disposeCourseScreen(WidgetTester tester) async {
  // Grammar/smalltalk own TTS and entrance widgets. Explicit disposal keeps
  // their delayed callbacks from leaking into the next widget test.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
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
