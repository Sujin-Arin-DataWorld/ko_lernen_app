import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/grammar_study_plan.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/grammar_screen.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/grammar_plan_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/chip.dart';
import 'package:ko_lernen_app/widgets/sori/content_feedback_card.dart';
import 'package:ko_lernen_app/widgets/sori/content_feed.dart';
import 'package:ko_lernen_app/widgets/sori/spotlight_coach.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

// Sheet-button labels come from AppL10n rather than English literals so this
// test keeps passing if the copy changes again (as it did for the start CTA).
final AppL10n _l10n = lookupAppL10n(const Locale('en'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_tut_grammar': true,
      'kl_tut_soriDeck': true,
    });
    await Storage.init();
    DataLoader.reset();
    CurriculumCatalog.reset();
    await DataLoader.loadGrammar();
  });

  testWidgets('first free browse visit automatically shows one plan sheet', (
    tester,
  ) async {
    await _pumpGrammar(tester);

    expect(
      find.byKey(const Key('grammar-plan-onboarding-sheet')),
      findsOneWidget,
    );
    for (final n in const [3, 5, 7, 10]) {
      expect(find.byKey(Key('grammar-plan-items-$n')), findsOneWidget);
    }
    expect(
      tester
          .widget<SoriChip>(find.byKey(const Key('grammar-plan-items-5')))
          .selected,
      isTrue,
      reason: 'five items is the default selected pace',
    );
  });

  testWidgets(
    'daily-count chips keep the selected pace actionable at a 48dp target',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpGrammar(tester);

      final selected = find.byKey(const Key('grammar-plan-items-5'));
      final chip = tester.widget<SoriChip>(selected);
      final data = tester.getSemantics(selected).getSemanticsData();

      expect(
        chip.minInteractiveHeight,
        greaterThanOrEqualTo(SoriLayout.chromeRowTouchHeight),
      );
      expect(
        tester.getSize(selected).height,
        greaterThanOrEqualTo(SoriLayout.chromeRowTouchHeight),
      );
      expect(data.label, '5 per day');
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isSelected, ui.Tristate.isTrue);
      expect(data.hasAction(ui.SemanticsAction.tap), isTrue);

      await tester.tap(selected);
      await tester.pump();
      expect(tester.widget<SoriChip>(selected).selected, isTrue);
      expect(
        tester.widget<SoriChip>(selected),
        same(chip),
        reason: 'reselecting the active pace must not rebuild the chip group',
      );
      semantics.dispose();
    },
  );

  testWidgets(
    'an unseen grammar coach never covers the automatic plan onboarding sheet',
    (tester) async {
      await tester.runAsync(() async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('kl_tut_grammar', false);
      });

      await _pumpGrammar(
        tester,
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: GrammarScreen(),
        ),
      );
      for (var attempt = 0; attempt < 20; attempt++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(
        find.byKey(const Key('grammar-plan-onboarding-sheet')),
        findsOneWidget,
      );
      expect(find.byKey(kSpotlightTooltipKey), findsNothing);
    },
  );

  testWidgets(
    'starting a plan persists the current-level first curated slice',
    (tester) async {
      final curated = GrammarPlanService.curatedRowsForLevel(
        await DataLoader.loadGrammar(),
        'A1',
      );
      await _pumpGrammar(tester);

      await tester.tap(find.byKey(const Key('grammar-plan-items-3')));
      await tester.pump();
      _tapSheetButton(tester, _l10n.grammarPlanStartCta);
      await tester.pump(const Duration(milliseconds: 500));

      final plan = GrammarPlanService.decodePlans(
        Storage.grammarPlanRawJson,
      )['a1'];
      expect(plan?.itemsPerDay, 3);
      expect(plan?.servedIdsByDate, isEmpty);
      expect(find.byKey(const Key('grammar-plan-day-header')), findsOneWidget);
      expect(find.byKey(const Key('grammar-filter-row')), findsNothing);
      expect(find.text(curated[0].pattern), findsWidgets);
      expect(find.text('1 / 3'), findsOneWidget);

      tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).onSkip!();
      await tester.pump();
      expect(find.text(curated[1].pattern), findsWidgets);
    },
  );

  testWidgets(
    'a stored plan renders its localized day header and CSV-order slice',
    (tester) async {
      final curated = GrammarPlanService.curatedRowsForLevel(
        await DataLoader.loadGrammar(),
        'A1',
      );
      await _storePlans({
        'a1': const GrammarStudyPlan(
          level: 'a1',
          itemsPerDay: 5,
          servedIdsByDate: {},
        ),
      });

      await _pumpGrammar(tester);

      final totalDays = GrammarPlanService.totalDays(curated, 5);
      expect(
        find.byKey(const Key('grammar-plan-onboarding-sheet')),
        findsNothing,
      );
      expect(find.text('Day 1 of $totalDays'), findsOneWidget);
      expect(find.text('1 / 5'), findsOneWidget);
      expect(find.text(curated[0].pattern), findsWidgets);
      tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).onSkip!();
      await tester.pump();
      expect(find.text(curated[1].pattern), findsWidgets);
    },
  );

  testWidgets(
    'finishing a one-item day records once and opens only plan completion',
    (tester) async {
      final first = GrammarPlanService.curatedRowsForLevel(
        await DataLoader.loadGrammar(),
        'A1',
      ).first;
      await _storePlans({
        'a1': const GrammarStudyPlan(
          level: 'a1',
          itemsPerDay: 1,
          servedIdsByDate: {},
        ),
      });
      await _pumpGrammar(tester);

      await tester.tap(find.byType(FlipCard));
      await tester.pump();
      final feed = tester.widget<SoriContentFeed>(find.byType(SoriContentFeed));
      feed.onNext!();
      feed.onNext!();
      await tester.pump(const Duration(milliseconds: 500));

      final plan = GrammarPlanService.decodePlans(
        Storage.grammarPlanRawJson,
      )['a1'];
      expect(plan?.servedIdsByDate[Storage.todayIso()], [first.id]);
      expect(
        find.byKey(const Key('grammar-plan-completion-sheet')),
        findsOneWidget,
      );
      expect(find.byType(ContentFeedbackCard), findsNothing);
      _tapSheetButton(tester, _l10n.grammarPlanCompletionSkip);
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.byKey(const Key('grammar-plan-completion-sheet')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('grammar-plan-day-complete')),
        findsOneWidget,
      );
      expect(find.byType(FlipCard), findsNothing);

      await _pumpGrammar(tester);
      expect(
        find.byKey(const Key('grammar-plan-day-complete')),
        findsOneWidget,
      );
      expect(find.byType(FlipCard), findsNothing);
    },
  );

  testWidgets(
    'plan completion practice passes the localized day label in route args',
    (tester) async {
      final curated = GrammarPlanService.curatedRowsForLevel(
        await DataLoader.loadGrammar(),
        'A1',
      );
      final totalDays = GrammarPlanService.totalDays(curated, 1);
      await _storePlans({
        'a1': const GrammarStudyPlan(
          level: 'a1',
          itemsPerDay: 1,
          servedIdsByDate: {},
        ),
      });
      RouteSettings? pushedSettings;
      await _pumpGrammar(tester, const GrammarScreen(), (settings) {
        pushedSettings = settings;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SizedBox.shrink(),
        );
      });

      await tester.tap(find.byType(FlipCard));
      await tester.pump();
      final feed = tester.widget<SoriContentFeed>(find.byType(SoriContentFeed));
      feed.onNext!();
      feed.onNext!();
      await tester.pump(const Duration(milliseconds: 500));
      _tapSheetButton(tester, _l10n.grammarPlanCompletionCta);
      await tester.pump(const Duration(milliseconds: 500));

      expect(pushedSettings?.name, '/grammar_choice_quiz');
      final arguments = pushedSettings?.arguments as Map<String, dynamic>;
      expect(arguments['level'], 'a1');
      expect(arguments['allowedTargetIds'], <String>{curated.first.id});
      expect(arguments['planDayLabel'], 'Day 1 of $totalDays');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'an exhausted plan renders restart before the empty-card return',
    (tester) async {
      final grammar = await DataLoader.loadGrammar();
      final a1 = GrammarPlanService.curatedRowsForLevel(grammar, 'A1');
      final completedDays = GrammarPlanService.totalDays(a1, 3);
      await _storePlans({
        'a1': GrammarStudyPlan(
          level: 'a1',
          itemsPerDay: 3,
          servedIdsByDate: {
            for (var i = 0; i < completedDays; i++)
              '2026-08-${i + 1}': const <String>[],
          },
        ),
        'b1': const GrammarStudyPlan(
          level: 'b1',
          itemsPerDay: 7,
          servedIdsByDate: {
            '2026-08-27': ['grammar_b1_placeholder'],
          },
        ),
      });
      await _pumpGrammar(tester);

      expect(find.byKey(const Key('grammar-plan-finished')), findsOneWidget);
      expect(find.byKey(const Key('grammar-plan-day-header')), findsNothing);
      await tester.tap(find.text('Start over'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.byKey(const Key('grammar-plan-onboarding-sheet')),
        findsOneWidget,
      );
      _tapSheetButton(tester, _l10n.grammarPlanStartCta);
      await tester.pump(const Duration(milliseconds: 500));

      final plans = GrammarPlanService.decodePlans(Storage.grammarPlanRawJson);
      expect(plans['a1']?.servedIdsByDate, isEmpty);
      expect(plans['b1']?.itemsPerDay, 7);
      expect(plans['b1']?.servedIdsByDate['2026-08-27'], [
        'grammar_b1_placeholder',
      ]);
    },
  );

  testWidgets(
    'course practice never shows plan chrome and keeps its filter sheet',
    (tester) async {
      final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
      final link = catalog.contentLinks.firstWhere(
        (item) =>
            item.contentKind == CurriculumContentKind.grammar &&
            item.courseUnitId == 'a1_03_topic_subject_particles' &&
            item.role == ContentLinkRole.assess,
      );
      await _pumpGrammar(
        tester,
        GrammarScreen(courseContext: CoursePracticeContext.fromLink(link)),
      );

      expect(
        find.byKey(const Key('grammar-plan-onboarding-sheet')),
        findsNothing,
      );
      expect(find.byKey(const Key('grammar-plan-day-header')), findsNothing);
      await tester.tap(find.byIcon(Icons.filter_list_rounded));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Filter'), findsOneWidget);
      tester
          .widget<SoriButton>(find.widgetWithText(SoriButton, 'Apply'))
          .onTap!();
      await tester.pump(const Duration(milliseconds: 500));
    },
  );

  testWidgets('dismissing onboarding enables the legacy browse filter flow', (
    tester,
  ) async {
    await _pumpGrammar(tester);
    await tester.tapAt(const Offset(8, 8));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('grammar-filter-row')), findsOneWidget);
    await tester.tap(find.byIcon(Icons.filter_list_rounded));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Filter'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets(
    'load rebuilds and rapid final judgments never stack plan sheets',
    (tester) async {
      await _pumpGrammar(tester);
      for (var i = 0; i < 3; i++) {
        await tester.pump();
      }
      expect(
        find.byKey(const Key('grammar-plan-onboarding-sheet')),
        findsOneWidget,
      );

      _tapSheetButton(tester, _l10n.grammarPlanStartCta);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byType(FlipCard));
      await tester.pump();
      final feed = tester.widget<SoriContentFeed>(find.byType(SoriContentFeed));
      for (var i = 0; i < 5; i++) {
        feed.onNext!();
      }
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.byKey(const Key('grammar-plan-completion-sheet')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'picking a different level in the onboarding sheet plans that level '
    'without touching the global user level (지시서 1.11)',
    (tester) async {
      final curatedB1 = GrammarPlanService.curatedRowsForLevel(
        await DataLoader.loadGrammar(),
        'B1',
      );
      await _pumpGrammar(tester);

      await tester.tap(find.widgetWithText(SoriChip, 'B1'));
      await tester.pump();
      _tapSheetButton(tester, _l10n.grammarPlanStartCta);
      await tester.pump(const Duration(milliseconds: 500));

      final plans = GrammarPlanService.decodePlans(Storage.grammarPlanRawJson);
      expect(plans.containsKey('a1'), isFalse);
      expect(plans['b1']?.itemsPerDay, GrammarPlanService.defaultItemsPerDay);
      expect(plans['b1']?.servedIdsByDate, isEmpty);
      expect(Storage.userLevelCode, 'a1');
      expect(find.byKey(const Key('grammar-plan-day-header')), findsOneWidget);
      expect(find.text(curatedB1[0].pattern), findsWidgets);
    },
  );

  testWidgets(
    'reselecting the currently active, unfinished level keeps its progress '
    '(지시서 1.11)',
    (tester) async {
      await _storePlans({
        'a1': const GrammarStudyPlan(
          level: 'a1',
          itemsPerDay: 5,
          servedIdsByDate: {
            '2026-08-20': ['grammar_a1_placeholder'],
          },
        ),
      });
      await _pumpGrammar(tester);
      expect(
        find.byKey(const Key('grammar-plan-onboarding-sheet')),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('grammar-plan-edit-button')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.byKey(const Key('grammar-plan-onboarding-sheet')),
        findsOneWidget,
      );
      _tapSheetButton(tester, _l10n.grammarPlanStartCta);
      await tester.pump(const Duration(milliseconds: 500));

      final plan = GrammarPlanService.decodePlans(
        Storage.grammarPlanRawJson,
      )['a1'];
      expect(plan?.servedIdsByDate, {
        '2026-08-20': ['grammar_a1_placeholder'],
      });
      expect(Storage.userLevelCode, 'a1');
    },
  );
}

Future<void> _storePlans(Map<String, GrammarStudyPlan> plans) =>
    Storage.setGrammarPlanRawJson(GrammarPlanService.encodePlans(plans));

void _tapSheetButton(WidgetTester tester, String label) =>
    tester.widget<SoriButton>(find.widgetWithText(SoriButton, label)).onTap!();

Future<void> _pumpGrammar(
  WidgetTester tester, [
  Widget child = const GrammarScreen(),
  RouteFactory? onGenerateRoute,
]) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      onGenerateRoute: onGenerateRoute,
      home: child,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}
