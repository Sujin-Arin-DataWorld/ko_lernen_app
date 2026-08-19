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
import 'package:ko_lernen_app/widgets/sori/content_feed.dart';

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
    // nothing. The browse path reaches the same state far more often: 180 of
    // 181 level+type filter combinations in `grammar.csv` leave one card.
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

  testWidgets('a type filter that leaves one card keeps every control alive', (
    tester,
  ) async {
    // This is the path Jin actually hit. The Typ facet is one-card-per-value
    // for 180 of its 181 values, so narrowing by type is the ordinary way to
    // land on a 1 / 1 deck — the browse deck must then hand back the filter
    // rather than a Weiter button that cannot move.
    final grammar = (await tester.runAsync(DataLoader.loadGrammar))!;
    expect(grammar, isNotEmpty);
    // Mirrors `_types` in the screen, so the menu order matches.
    final types = grammar.map((item) => item.typeDe).toSet().toList()..sort();
    final soleType = types.firstWhere(
      (type) => grammar.where((item) => item.typeDe == type).length == 1,
    );

    await tester.pumpWidget(_wrap(const GrammarScreen()));
    await _settleCourseScreen(tester);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<String>).last);
    await tester.pumpAndSettle();
    final typeItem = find.text(soleType).last;
    await tester.ensureVisible(typeItem);
    await tester.pumpAndSettle();
    await tester.tap(typeItem);
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

  testWidgets('grammar library opens separate four-choice practice', (
    tester,
  ) async {
    // This test verifies the entry point rather than asset-bundle scheduling.
    // Preload the source just as the preceding course check does, so it stays
    // independent of a prior test resetting the shared loader cache.
    expect((await tester.runAsync(DataLoader.loadGrammar))!, isNotEmpty);
    await tester.pumpWidget(_wrap(const GrammarScreen()));
    await _settleCourseScreen(tester);

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

Widget _wrap(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
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
