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
