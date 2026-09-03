import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/chaekgado_shelf.dart';
import 'package:ko_lernen_app/features/guide/guide_progress_service.dart';
import 'package:ko_lernen_app/features/guide/guide_runtime.dart';
import 'package:ko_lernen_app/features/guide/guide_topic_detail_screen.dart';
import 'package:ko_lernen_app/features/guide/today_guide_section.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/guide_contract.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/motion/transitions.dart';
import 'package:ko_lernen_app/services/analytics_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all six localized modules expose 1-3 steps and typed actions', () {
    for (final locale in const [Locale('en'), Locale('de')]) {
      final t = lookupAppL10n(locale);
      for (final topic in GuideTopicCatalog.all) {
        final module = guideTopicModuleViewModel(t, topic);
        expect(
          module.steps.length,
          inInclusiveRange(1, 3),
          reason: '${locale.languageCode}:${topic.id.stableId}',
        );
        expect(
          module.steps.every((step) => step.body.trim().isNotEmpty),
          isTrue,
        );
        expect(module.actions, isNotEmpty);
        for (final action in module.actions) {
          expect(
            action.spec.destination,
            anyOf(
              isA<SoriStageTabDestination>(),
              isA<SettingsSectionDestination>(),
              isA<HangulTargetDestination>(),
              isA<ScenarioBrowseDestination>(),
              isA<StudyLibraryDestination>(),
              isA<HeritageDestination>(),
            ),
          );
        }
      }
    }
  });

  testWidgets(
    'rendering a detail module is passive and actions remain explicit',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1800);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });
      final requested = <GuideModuleActionId>[];
      await tester.pumpWidget(
        _localizedApp(
          Builder(
            builder: (context) => GuideTopicDetailScreen(
              module: guideTopicModuleViewModel(
                AppL10n.of(context),
                GuideTopicCatalog.all.singleWhere(
                  (topic) => topic.id == GuideTopicId.myBook,
                ),
              ),
              onActionRequested: (action) => requested.add(action.spec.id),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(requested, isEmpty);
      expect(
        find.byKey(const ValueKey('guide-module-passive-notice-my-book')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('guide-module-action-capture-textbook')),
      );
      await tester.pump();
      expect(requested, [GuideModuleActionId.captureTextbook]);
    },
  );

  testWidgets('rendering a detail route does not mark its topic opened', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final service = GuideProgressService(
      preferencesLoader: SharedPreferences.getInstance,
    );
    final topic = GuideTopicCatalog.all.singleWhere(
      (value) => value.id == GuideTopicId.settings,
    );

    await tester.pumpWidget(
      _localizedApp(
        GuideTopicDetailRouteScreen(
          topic: topic,
          progressService: service,
          entrySurface: GuideEntryAnalyticsSurface.guideHub,
        ),
      ),
    );
    await tester.pump();

    final snapshot = await service.load();
    expect(snapshot.hasOpened(GuideTopicId.settings), isFalse);
    expect(snapshot.isComplete(GuideTopicId.settings), isFalse);
  });

  testWidgets('explicit topic activation records first open then reopen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final service = GuideProgressService(
      preferencesLoader: SharedPreferences.getInstance,
    );
    final openStates = <GuideTopicOpenState>[];
    final topic = GuideTopicCatalog.all.singleWhere(
      (value) => value.id == GuideTopicId.settings,
    );
    late BuildContext launcherContext;

    await tester.pumpWidget(
      _localizedApp(
        Builder(
          builder: (context) {
            launcherContext = context;
            return const Scaffold(
              body: SizedBox(key: ValueKey('guide-launcher')),
            );
          },
        ),
      ),
    );

    Future<void> openTopic() => openGuideTopicModule(
      launcherContext,
      topic: topic,
      progressService: service,
      entrySurface: GuideEntryAnalyticsSurface.guideHub,
      openedReporter:
          ({required topic, required entrySurface, required openState}) async {
            openStates.add(openState);
          },
    );

    final firstNavigation = openTopic();
    await tester.pumpAndSettle();
    expect(openStates, [GuideTopicOpenState.firstOpen]);
    expect((await service.load()).hasOpened(GuideTopicId.settings), isTrue);
    // §NAV-2(J4): openGuideTopicModule moved off SoriTransitions.fadeScale
    // onto SoriTransitions.page — platform-native transition, no
    // route-local reduceMotion override.
    expect(
      ModalRoute.of(
        tester.element(find.byKey(const ValueKey('guide-module-step-1'))),
      ),
      isA<SoriPageRoute<dynamic>>(),
    );

    Navigator.of(
      tester.element(find.byKey(const ValueKey('guide-module-step-1'))),
    ).pop();
    await tester.pumpAndSettle();
    await firstNavigation;

    final secondNavigation = openTopic();
    await tester.pumpAndSettle();
    expect(openStates, [
      GuideTopicOpenState.firstOpen,
      GuideTopicOpenState.reopen,
    ]);

    Navigator.of(
      tester.element(find.byKey(const ValueKey('guide-module-step-1'))),
    ).pop();
    await tester.pumpAndSettle();
    await secondNavigation;
  });

  testWidgets('Today topic activation opens detail without completing it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final service = GuideProgressService(
      preferencesLoader: SharedPreferences.getInstance,
    );
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1800);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(
      _localizedApp(
        Scaffold(
          body: SingleChildScrollView(
            child: TodayGuideChecklistSection(progressService: service),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('today-guide-topic-personalized-start')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('guide-module-step-1')), findsOneWidget);
    expect(
      (await service.load()).isComplete(GuideTopicId.personalizedStart),
      isFalse,
    );
  });

  testWidgets('detail disposal reports one bounded close event', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final reports = <String>[];
    final topic = GuideTopicCatalog.all.singleWhere(
      (value) => value.id == GuideTopicId.learn,
    );

    await tester.pumpWidget(
      _localizedApp(
        GuideTopicDetailRouteScreen(
          topic: topic,
          progressService: GuideProgressService(
            preferencesLoader: SharedPreferences.getInstance,
          ),
          entrySurface: GuideEntryAnalyticsSurface.todayChecklist,
          closedReporter: ({required topic, required entrySurface}) async {
            reports.add('${topic.name}:${entrySurface.name}');
          },
        ),
      ),
    );
    await tester.pump();
    expect(reports, isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(reports, ['learn:todayChecklist']);
  });

  testWidgets('secondary action does not complete; primary destination does', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final service = GuideProgressService(
      preferencesLoader: SharedPreferences.getInstance,
    );
    final topic = GuideTopicCatalog.all.singleWhere(
      (value) => value.id == GuideTopicId.personalizedStart,
    );

    await tester.pumpWidget(
      _localizedApp(
        GuideTopicDetailRouteScreen(
          topic: topic,
          progressService: service,
          entrySurface: GuideEntryAnalyticsSurface.guideHub,
        ),
        routes: {
          '/settings': (_) => const Scaffold(
            body: SizedBox(key: ValueKey('settings-destination')),
          ),
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('guide-module-action-browse-level')),
      400,
    );
    await tester.tap(
      find.byKey(const ValueKey('guide-module-action-browse-level')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-destination')), findsOneWidget);
    expect(
      (await service.load()).isComplete(GuideTopicId.personalizedStart),
      isFalse,
    );

    Navigator.of(
      tester.element(find.byKey(const ValueKey('settings-destination'))),
    ).pop();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('guide-module-action-course-start')),
      -400,
    );
    await tester.tap(
      find.byKey(const ValueKey('guide-module-action-course-start')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-destination')), findsOneWidget);
    expect(
      (await service.load()).isComplete(GuideTopicId.personalizedStart),
      isTrue,
    );
  });

  testWidgets('consent rejection logs a bounded failure and rolls back', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final service = GuideProgressService(
      preferencesLoader: SharedPreferences.getInstance,
    );
    final failures = <String>[];
    final topic = GuideTopicCatalog.all.singleWhere(
      (value) => value.id == GuideTopicId.myBook,
    );

    await tester.pumpWidget(
      _localizedApp(
        GuideTopicDetailRouteScreen(
          topic: topic,
          progressService: service,
          entrySurface: GuideEntryAnalyticsSurface.todayChecklist,
          routingFailureReporter:
              ({
                required topic,
                required entrySurface,
                required action,
                required reason,
              }) async {
                failures.add(
                  '${topic.name}:${entrySurface.name}:${action.name}:${reason.name}',
                );
              },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('guide-module-action-capture-textbook')),
      400,
    );
    await tester.tap(
      find.byKey(const ValueKey('guide-module-action-capture-textbook')),
    );
    await tester.pumpAndSettle();

    expect(failures, ['myBook:todayChecklist:captureTextbook:consent']);
    expect((await service.load()).isComplete(GuideTopicId.myBook), isFalse);
  });

  testWidgets('caught navigation logs a bounded failure and rolls back', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final service = GuideProgressService(
      preferencesLoader: SharedPreferences.getInstance,
    );
    final failures = <String>[];
    final topic = GuideTopicCatalog.all.singleWhere(
      (value) => value.id == GuideTopicId.learn,
    );

    await tester.pumpWidget(
      _localizedApp(
        GuideTopicDetailRouteScreen(
          topic: topic,
          progressService: service,
          entrySurface: GuideEntryAnalyticsSurface.guideHub,
          scenarioBrowseLevelReader: () => LearnerLevel.a1,
          loadScenarios: (_) async => const [],
          routingFailureReporter:
              ({
                required topic,
                required entrySurface,
                required action,
                required reason,
              }) async {
                failures.add(
                  '${topic.name}:${entrySurface.name}:${action.name}:${reason.name}',
                );
              },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('guide-module-action-hangul-overview')),
      400,
    );
    await tester.tap(
      find.byKey(const ValueKey('guide-module-action-hangul-overview')),
    );
    await tester.pumpAndSettle();

    expect(failures, ['learn:guideHub:hangulOverview:navigation']);
    expect((await service.load()).isComplete(GuideTopicId.learn), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Learn detail shows loaded browse-level counts and routes an exact secondary shelf',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = GuideProgressService(
        preferencesLoader: SharedPreferences.getInstance,
      );
      final loadedLevels = <LearnerLevel>[];
      Object? routedArguments;
      final topic = GuideTopicCatalog.all.singleWhere(
        (value) => value.id == GuideTopicId.learn,
      );

      await tester.pumpWidget(
        _localizedApp(
          GuideTopicDetailRouteScreen(
            topic: topic,
            progressService: service,
            entrySurface: GuideEntryAnalyticsSurface.guideHub,
            scenarioBrowseLevelReader: () => LearnerLevel.b1,
            loadScenarios: (level) async {
              loadedLevels.add(level);
              return [
                _scenario(id: 'team-1', level: level, shelf: 'b1_team'),
                _scenario(id: 'refund', level: level, shelf: 'b1_refund'),
                _scenario(id: 'team-2', level: level, shelf: 'b1_team'),
              ];
            },
          ),
          routes: {
            '/scenarios': (context) {
              routedArguments = ModalRoute.settingsOf(context)?.arguments;
              return const Scaffold(
                body: SizedBox(key: ValueKey('scenario-category-route')),
              );
            },
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('guide-scenario-categories-summary')),
        500,
      );
      await tester.pumpAndSettle();

      expect(loadedLevels, [LearnerLevel.b1]);
      expect(routedArguments, isNull);
      expect(
        find.byKey(const ValueKey('guide-scenario-categories-summary')),
        findsOneWidget,
      );
      expect(find.text('Level B1, 3 scenarios'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('guide-scenario-category-b1_team')),
        findsOneWidget,
      );
      expect(find.textContaining('2 scenarios'), findsOneWidget);
      expect((await service.load()).isComplete(GuideTopicId.learn), isFalse);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('guide-scenario-category-b1_team')),
        500,
      );
      await tester.tap(
        find.byKey(const ValueKey('guide-scenario-category-b1_team')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('scenario-category-route')),
        findsOneWidget,
      );
      expect(routedArguments, isA<ScenarioBrowseDestination>());
      final destination = routedArguments! as ScenarioBrowseDestination;
      expect(destination.level, LearnerLevel.b1);
      expect(destination.shelfId, 'b1_team');
      expect((await service.load()).isComplete(GuideTopicId.learn), isFalse);
    },
  );

  testWidgets(
    'caught scenario navigation reports one category bucket without completion',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = GuideProgressService(
        preferencesLoader: SharedPreferences.getInstance,
      );
      final failures = <String>[];
      final topic = GuideTopicCatalog.all.singleWhere(
        (value) => value.id == GuideTopicId.learn,
      );

      await tester.pumpWidget(
        _localizedApp(
          GuideTopicDetailRouteScreen(
            topic: topic,
            progressService: service,
            entrySurface: GuideEntryAnalyticsSurface.guideHub,
            scenarioBrowseLevelReader: () => LearnerLevel.b1,
            loadScenarios: (level) async => [
              _scenario(id: 'team-1', level: level, shelf: 'b1_team'),
            ],
            routingFailureReporter:
                ({
                  required topic,
                  required entrySurface,
                  required action,
                  required reason,
                }) async {
                  failures.add(
                    '${topic.name}:${entrySurface.name}:${action.name}:${reason.name}',
                  );
                },
          ),
          onGenerateRoute: (settings) {
            if (settings.name == '/scenarios') {
              throw StateError('sensitive route failure detail');
            }
            return null;
          },
        ),
      );
      await tester.pumpAndSettle();

      final category = find.byKey(
        const ValueKey('guide-scenario-category-b1_team'),
      );
      await tester.scrollUntilVisible(category, 400);
      await tester.ensureVisible(category);
      await tester.pumpAndSettle();
      await tester.tap(category);
      await tester.pumpAndSettle();

      expect(failures, ['learn:guideHub:scenarioCategory:navigation']);
      expect((await service.load()).isComplete(GuideTopicId.learn), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Learn category loader failure exposes no guessed count or shelf',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final service = GuideProgressService(
        preferencesLoader: SharedPreferences.getInstance,
      );
      final topic = GuideTopicCatalog.all.singleWhere(
        (value) => value.id == GuideTopicId.learn,
      );

      await tester.pumpWidget(
        _localizedApp(
          GuideTopicDetailRouteScreen(
            topic: topic,
            progressService: service,
            entrySurface: GuideEntryAnalyticsSurface.guideHub,
            scenarioBrowseLevelReader: () => LearnerLevel.a2,
            loadScenarios: (_) async => throw StateError('missing shard'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('guide-scenario-categories-failed')),
        500,
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('guide-scenario-categories-failed')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('guide-scenario-categories-summary')),
        findsNothing,
      );
      expect(_scenarioCategoryButtons(), findsNothing);
      expect((await service.load()).isComplete(GuideTopicId.learn), isFalse);
    },
  );

  testWidgets('Learn zero-stock result exposes no fabricated zero count', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final service = GuideProgressService(
      preferencesLoader: SharedPreferences.getInstance,
    );
    final topic = GuideTopicCatalog.all.singleWhere(
      (value) => value.id == GuideTopicId.learn,
    );

    await tester.pumpWidget(
      _localizedApp(
        GuideTopicDetailRouteScreen(
          topic: topic,
          progressService: service,
          entrySurface: GuideEntryAnalyticsSurface.guideHub,
          scenarioBrowseLevelReader: () => LearnerLevel.c1,
          loadScenarios: (_) async => const [],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('guide-scenario-categories-empty')),
      500,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('guide-scenario-categories-empty')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('guide-scenario-categories-summary')),
      findsNothing,
    );
    expect(_scenarioCategoryButtons(), findsNothing);
    expect((await service.load()).isComplete(GuideTopicId.learn), isFalse);
  });

  testWidgets('German Learn categories stay scroll-safe at 320x640 and 200%', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    SharedPreferences.setMockInitialValues({});
    final service = GuideProgressService(
      preferencesLoader: SharedPreferences.getInstance,
    );
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
    final topic = GuideTopicCatalog.all.singleWhere(
      (value) => value.id == GuideTopicId.learn,
    );
    final slots = kChaekgadoSlots[LearnerLevel.c2]!;

    await tester.pumpWidget(
      _localizedApp(
        GuideTopicDetailRouteScreen(
          topic: topic,
          progressService: service,
          entrySurface: GuideEntryAnalyticsSurface.guideHub,
          scenarioBrowseLevelReader: () => LearnerLevel.c2,
          loadScenarios: (level) async => [
            for (final slot in slots)
              _scenario(
                id: slot.imageKey,
                level: level,
                shelf: chaekgadoShelfId(level, slot.slug),
              ),
          ],
        ),
        locale: const Locale('de'),
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();

    final lastCategory = find.byKey(
      const ValueKey('guide-scenario-category-c2_fandom'),
    );
    await tester.scrollUntilVisible(lastCategory, 600);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(tester.getSize(lastCategory).height, greaterThanOrEqualTo(48));
    final semanticsData = tester.getSemantics(lastCategory).getSemanticsData();
    expect(semanticsData.hasAction(ui.SemanticsAction.tap), isTrue);
    expect(semanticsData.label, contains('1 Szenario'));
    expect((await service.load()).isComplete(GuideTopicId.learn), isFalse);
    semantics.dispose();
  });

  testWidgets('German settings module is scroll-safe at 320x640 and 200%', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
    final requested = <GuideModuleActionId>[];

    await tester.pumpWidget(
      _localizedApp(
        Builder(
          builder: (context) => GuideTopicDetailScreen(
            module: guideTopicModuleViewModel(
              AppL10n.of(context),
              GuideTopicCatalog.all.singleWhere(
                (topic) => topic.id == GuideTopicId.settings,
              ),
            ),
            onActionRequested: (action) => requested.add(action.spec.id),
          ),
        ),
        locale: const Locale('de'),
        textScale: 2,
      ),
    );
    await tester.pump();

    final lastAction = find.byKey(
      const ValueKey('guide-module-action-guide-settings'),
    );
    await tester.scrollUntilVisible(lastAction, 500);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(tester.getSize(lastAction).height, greaterThanOrEqualTo(48));
    final semanticsData = tester.getSemantics(lastAction).getSemanticsData();
    expect(semanticsData.hasAction(ui.SemanticsAction.tap), isTrue);
    expect(semanticsData.label, contains('App-Anleitung'));
    semantics.dispose();
  });
}

Finder _scenarioCategoryButtons() => find.byWidgetPredicate((widget) {
  final key = widget.key;
  return key is ValueKey<String> &&
      key.value.startsWith('guide-scenario-category-');
});

Scenario _scenario({
  required String id,
  required LearnerLevel level,
  required String shelf,
}) => Scenario(
  id: id,
  level: level,
  emoji: '📖',
  register: Register.polite,
  title: LocalizedText(ko: id, de: id, en: id),
  intro: const LocalizedText(ko: '', de: '', en: ''),
  vocab: const [],
  grammarIds: const [],
  dialog: const [],
  quests: const [],
  shelf: shelf,
);

Widget _localizedApp(
  Widget home, {
  Locale locale = const Locale('en'),
  double textScale = 1,
  Map<String, WidgetBuilder> routes = const {},
  RouteFactory? onGenerateRoute,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: locale,
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    routes: routes,
    onGenerateRoute: onGenerateRoute,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: true,
      ),
      child: child ?? const SizedBox.shrink(),
    ),
    home: home,
  );
}
