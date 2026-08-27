import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/guide/guide_hub_screen.dart';
import 'package:ko_lernen_app/features/guide/guide_presentation.dart';
import 'package:ko_lernen_app/features/guide/guide_progress_service.dart';
import 'package:ko_lernen_app/features/guide/guide_runtime.dart';
import 'package:ko_lernen_app/features/guide/today_guide_checklist_card.dart';
import 'package:ko_lernen_app/features/guide/today_guide_section.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/guide_contract.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/pressable.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const hubCopy = GuideHubCopy(
    appBarTitle: 'App guide',
    eyebrow: 'START HERE',
    title: 'Find your way around Hangul Sori',
    description: 'Learn what each area does before you start.',
    completedLabel: 'Completed',
  );

  const checklistCopy = TodayGuideChecklistCopy(
    title: 'Hangul Sori start guide',
    description: 'Choose a topic whenever you need it.',
    progressLabel: '1 of 2 topics completed',
    completedLabel: 'Completed',
    openGuideLabel: 'Open the full guide',
    dismissLabel: 'Dismiss start guide',
  );

  group('GuideHubScreen', () {
    test('localized copy keeps privacy and review availability truthful', () {
      final en = lookupAppL10n(const Locale('en'));
      final de = lookupAppL10n(const Locale('de'));

      expect(en.guideTopicMyBookDescription, contains('on your device'));
      expect(en.guideTopicMyBookDescription, contains('EU analysis service'));
      expect(
        en.guideTopicMyBookDescription,
        contains('does not request camera access'),
      );
      expect(de.guideTopicMyBookDescription, contains('auf deinem Gerät'));
      expect(
        de.guideTopicMyBookDescription,
        contains('Analysedienst in der EU'),
      );
      expect(
        de.guideTopicMyBookDescription,
        contains('fragt nicht nach Kamerazugriff'),
      );
      expect(
        en.guideTopicCardsAndMemoryDescription,
        contains('never starts review'),
      );
      expect(
        en.guideTopicCardsAndMemoryDescription,
        contains('saved words, grammar, sentences, expressions, Hangeul'),
      );
      expect(
        de.guideTopicCardsAndMemoryDescription,
        contains('Wörter, Grammatik, Sätze, Ausdrücke und Hangeul'),
      );
      expect(en.todayGuideDescription, isNot(contains('Three')));
      expect(de.todayGuideDescription, isNot(contains('Drei')));
    });

    testWidgets('shows truthful availability and only activates live topics', (
      tester,
    ) async {
      await _setView(tester, const Size(800, 1800));
      final opened = <GuideTopicId>[];
      final topics = [
        _viewModel(
          topic: GuideTopicId.learn,
          availability: FeatureAvailability.live,
          availabilityLabel: 'Available now',
        ),
        _viewModel(
          topic: GuideTopicId.myBook,
          availability: FeatureAvailability.preview,
          availabilityLabel: 'Preview',
        ),
        _viewModel(
          topic: GuideTopicId.cardsAndMemory,
          availability: FeatureAvailability.comingSoon,
          availabilityLabel: 'Coming soon',
        ),
        _viewModel(
          topic: GuideTopicId.settings,
          availability: FeatureAvailability.unavailable,
          availabilityLabel: 'Unavailable',
        ),
      ];

      await tester.pumpWidget(
        _testApp(
          GuideHubScreen(
            copy: hubCopy,
            topics: topics,
            onDestinationRequested: (topic) => opened.add(topic.id),
          ),
        ),
      );

      expect(find.text('Available now'), findsOneWidget);
      expect(find.text('Preview'), findsWidgets);
      expect(find.text('Coming soon'), findsWidgets);
      expect(find.text('Unavailable'), findsWidgets);
      expect(
        find.byKey(const ValueKey('guide-topic-action-learn')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('guide-topic-action-my-book')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('guide-topic-action-learn')));
      await tester.pump();

      expect(opened, [GuideTopicId.learn]);
    });

    testWidgets('non-live actions require an explicit injected handler', (
      tester,
    ) async {
      final liveOpened = <GuideTopicId>[];
      final nonLiveOpened = <GuideTopicId>[];
      final topic = _viewModel(
        topic: GuideTopicId.myBook,
        availability: FeatureAvailability.preview,
        availabilityLabel: 'Preview',
      );

      await tester.pumpWidget(
        _testApp(
          GuideHubScreen(
            copy: hubCopy,
            topics: [topic],
            onDestinationRequested: (value) => liveOpened.add(value.id),
            onNonLiveTopicRequested: (value) => nonLiveOpened.add(value.id),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('guide-topic-action-my-book')),
      );
      await tester.pump();

      expect(liveOpened, isEmpty);
      expect(nonLiveOpened, [GuideTopicId.myBook]);
    });

    testWidgets('320x640 at 200 percent text remains scrollable', (
      tester,
    ) async {
      await _setCompactView(tester);
      final topics = GuideTopicId.values
          .map(
            (id) => _viewModel(
              topic: id,
              availability: FeatureAvailability.live,
              availabilityLabel: 'Available now',
              description:
                  'A deliberately long localized explanation that wraps onto several lines.',
            ),
          )
          .toList();

      await tester.pumpWidget(
        _testApp(
          GuideHubScreen(
            copy: hubCopy,
            topics: topics,
            onDestinationRequested: (_) {},
          ),
          textScale: 2,
        ),
      );
      expect(tester.takeException(), isNull);

      final lastAction = find.byKey(
        const ValueKey('guide-topic-action-settings'),
      );
      await tester.scrollUntilVisible(lastAction, 500);
      await tester.pumpAndSettle();

      expect(lastAction, findsOneWidget);
      expect(tester.getSize(lastAction).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });

    testWidgets('real German guide fits 320x640 at 200 percent text', (
      tester,
    ) async {
      await _setCompactView(tester);
      final snapshot = GuideProgressSnapshot(
        completedTopicIds: const [],
        isTodayCardDismissed: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child ?? const SizedBox.shrink(),
          ),
          home: Builder(
            builder: (context) {
              final t = AppL10n.of(context);
              return GuideHubScreen(
                copy: guideHubCopy(t),
                topics: guideTopicViewModels(t, snapshot),
                onDestinationRequested: (_) {},
              );
            },
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      final lastAction = find.byKey(
        const ValueKey('guide-topic-action-settings'),
      );
      await tester.scrollUntilVisible(lastAction, 500);
      await tester.pumpAndSettle();
      expect(tester.getSize(lastAction).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });
  });

  group('Guide runtime contracts', () {
    testWidgets('hub route reports one open without marking any topic', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final service = GuideProgressService(
        preferencesLoader: SharedPreferences.getInstance,
      );
      var hubOpens = 0;

      await tester.pumpWidget(
        _localizedTestApp(
          GuideHubRouteScreen(
            progressService: service,
            hubOpenedReporter: () async {
              hubOpens++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump();

      expect(hubOpens, 1);
      expect((await service.load()).openedTopicIds, isEmpty);
    });

    testWidgets(
      'hub opens detail first and the primary destination completes',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final service = GuideProgressService(
          preferencesLoader: SharedPreferences.getInstance,
        );
        await _setView(tester, const Size(800, 2400));

        await tester.pumpWidget(
          _localizedTestApp(
            GuideHubRouteScreen(progressService: service),
            routes: {
              '/study-library': (_) => const Scaffold(
                body: SizedBox(
                  key: ValueKey('study-library-route-destination'),
                ),
              ),
            },
          ),
        );
        await tester.pumpAndSettle();

        final action = find.byKey(
          const ValueKey('guide-topic-action-cards-and-memory'),
        );
        await tester.scrollUntilVisible(action, 400);
        await tester.tap(action);
        await tester.pumpAndSettle();

        var snapshot = await service.load();
        expect(snapshot.isComplete(GuideTopicId.cardsAndMemory), isFalse);
        expect(
          find.byKey(const ValueKey('guide-module-step-1')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('guide-module-action-study-library')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const ValueKey('guide-module-action-study-library')),
        );
        await tester.pumpAndSettle();

        snapshot = await service.load();
        expect(snapshot.isComplete(GuideTopicId.cardsAndMemory), isTrue);
        expect(
          find.byKey(const ValueKey('study-library-route-destination')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'scenario and heritage typed destinations fail closed before consumers exist',
      (tester) async {
        await tester.pumpWidget(
          _testApp(
            const Scaffold(
              body: SizedBox(key: ValueKey('guide-resolver-anchor')),
            ),
          ),
        );
        final context = tester.element(
          find.byKey(const ValueKey('guide-resolver-anchor')),
        );

        final scenarioOpened = await GuideDestinationResolver.open(
          context,
          _resolverTopic(
            const ScenarioBrowseDestination(
              level: LearnerLevel.a1,
              shelfId: 'daily-life',
            ),
          ),
        );
        final heritageOpened = await GuideDestinationResolver.open(
          context,
          _resolverTopic(const HeritageDestination('ildu-gotaek')),
        );

        expect(scenarioOpened, isFalse);
        expect(heritageOpened, isFalse);
      },
    );

    testWidgets('a retained module action cannot bypass a non-live topic', (
      tester,
    ) async {
      await tester.pumpWidget(
        _localizedTestApp(
          const Scaffold(
            body: SizedBox(key: ValueKey('guide-resolver-anchor')),
          ),
          routes: {
            '/study-library': (_) => const Scaffold(
              body: SizedBox(key: ValueKey('study-library-route-destination')),
            ),
          },
        ),
      );
      final context = tester.element(
        find.byKey(const ValueKey('guide-resolver-anchor')),
      );
      const previewTopic = GuideTopicSpec(
        id: GuideTopicId.cardsAndMemory,
        localizationKey: 'guideTopicCardsAndMemory',
        destination: StudyLibraryDestination(StudyLibrarySemanticId.myWords),
        availability: FeatureAvailability.preview,
        requiredConsents: {},
        requiredPermissions: {},
        surfaces: {GuideSurface.guideHub},
        completionMode: GuideCompletionMode.destinationOpened,
        analyticsSurface: GuideAnalyticsSurface.cardsAndMemory,
      );
      final retainedAction =
          GuideModuleCatalog.byTopic[GuideTopicId.cardsAndMemory]!.single;

      final result = await GuideDestinationResolver.resolveAction(
        context,
        topic: previewTopic,
        action: retainedAction,
      );
      await tester.pumpAndSettle();

      expect(result.didOpen, isFalse);
      expect(result.failureReason, GuideRoutingFailureReason.unavailable);
      expect(
        find.byKey(const ValueKey('study-library-route-destination')),
        findsNothing,
      );
    });
  });

  group('TodayGuideChecklistCard', () {
    testWidgets('exposes progress actions without activating non-live topics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var dismissed = 0;
      var openedGuide = 0;
      final openedTopics = <GuideTopicId>[];
      final topics = [
        _viewModel(
          topic: GuideTopicId.learn,
          availability: FeatureAvailability.live,
          availabilityLabel: 'Available now',
          completed: true,
        ),
        _viewModel(
          topic: GuideTopicId.cardsAndMemory,
          availability: FeatureAvailability.comingSoon,
          availabilityLabel: 'Coming soon',
        ),
      ];

      await tester.pumpWidget(
        _testApp(
          Scaffold(
            body: SingleChildScrollView(
              child: TodayGuideChecklistCard(
                copy: checklistCopy,
                topics: topics,
                onOpenGuide: () => openedGuide++,
                onDismiss: () => dismissed++,
                onDestinationRequested: (topic) => openedTopics.add(topic.id),
              ),
            ),
          ),
        ),
      );

      final liveRow = find.byKey(const ValueKey('today-guide-topic-learn'));
      final liveSemantics = tester.getSemantics(liveRow).getSemanticsData();
      expect(liveSemantics.hasAction(ui.SemanticsAction.tap), isTrue);

      await tester.tap(liveRow);
      final nonLiveRow = find.byKey(
        const ValueKey('today-guide-topic-cards-and-memory'),
      );
      expect(
        find.descendant(of: nonLiveRow, matching: find.byType(SoriPressable)),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('today-guide-open-hub')));
      await tester.tap(find.byKey(const ValueKey('today-guide-dismiss')));
      await tester.pump();

      expect(openedTopics, [GuideTopicId.learn]);
      expect(openedGuide, 1);
      expect(dismissed, 1);
      expect(find.text('Completed'), findsOneWidget);
      expect(
        tester
            .getSize(find.byKey(const ValueKey('today-guide-dismiss')))
            .height,
        greaterThanOrEqualTo(48),
      );
      semantics.dispose();
    });

    testWidgets('wraps safely at large text without imposing a fixed height', (
      tester,
    ) async {
      await _setCompactView(tester);

      await tester.pumpWidget(
        _testApp(
          Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: TodayGuideChecklistCard(
                copy: checklistCopy,
                topics: [
                  _viewModel(
                    topic: GuideTopicId.personalizedStart,
                    availability: FeatureAvailability.live,
                    availabilityLabel: 'Available now',
                  ),
                  _viewModel(
                    topic: GuideTopicId.gamesAndRewards,
                    availability: FeatureAvailability.live,
                    availabilityLabel: 'Available now',
                  ),
                ],
                onOpenGuide: () {},
                onDismiss: () {},
                onDestinationRequested: (_) {},
              ),
            ),
          ),
          textScale: 2,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester
            .getSize(find.byKey(const ValueKey('today-guide-open-hub')))
            .height,
        greaterThanOrEqualTo(48),
      );
    });
  });

  group('guide runtime focus continuity', () {
    testWidgets(
      'Today dismiss moves focus past the removed section and announces status',
      (tester) async {
        final semantics = tester.ensureSemantics();
        SharedPreferences.setMockInitialValues({});
        final service = GuideProgressService(
          preferencesLoader: SharedPreferences.getInstance,
        );
        final nextActionFocus = FocusNode(debugLabel: 'after-guide-action');
        addTearDown(() {
          FocusManager.instance.primaryFocus?.unfocus();
          nextActionFocus.dispose();
        });

        await tester.pumpWidget(
          _localizedTestApp(
            Scaffold(
              body: FocusTraversalGroup(
                policy: WidgetOrderTraversalPolicy(),
                child: ListView(
                  children: [
                    TodayGuideChecklistSection(progressService: service),
                    TextButton(
                      key: const ValueKey('after-today-guide-action'),
                      focusNode: nextActionFocus,
                      onPressed: () {},
                      child: const Text('Next Today action'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final dismiss = find.byKey(const ValueKey('today-guide-dismiss'));
        expect(dismiss, findsOneWidget);
        await _focusWithKeyboard(tester, dismiss);
        expect(_primaryFocusIsWithin(tester, dismiss), isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('today-guide-checklist-card')),
          findsNothing,
        );
        expect(nextActionFocus.hasFocus, isTrue);
        final status = find.byKey(
          const ValueKey('today-guide-dismissed-status'),
        );
        final statusData = tester.getSemantics(status).getSemanticsData();
        expect(statusData.flagsCollection.isLiveRegion, isTrue);
        expect(statusData.label, isNotEmpty);
        final snapshot = await service.load();
        expect(snapshot.isTodayCardDismissed, isTrue);
        expect(snapshot.completedTopicIds, isEmpty);
        semantics.dispose();
      },
    );

    testWidgets(
      'Guide restore moves focus to previous action and announces status',
      (tester) async {
        final semantics = tester.ensureSemantics();
        SharedPreferences.setMockInitialValues({
          GuideProgressService.todayCardDismissedKey: true,
          GuideProgressService.completedTopicIdsKey: [
            GuideTopicId.myBook.stableId,
          ],
        });
        final service = GuideProgressService(
          preferencesLoader: SharedPreferences.getInstance,
        );
        addTearDown(() => FocusManager.instance.primaryFocus?.unfocus());
        await _setView(tester, const Size(800, 2400));

        await tester.pumpWidget(
          _localizedTestApp(GuideHubRouteScreen(progressService: service)),
        );
        await tester.pumpAndSettle();

        final restore = find.byKey(const ValueKey('guide-restore-today-card'));
        expect(restore, findsOneWidget);
        await _focusWithKeyboard(tester, restore);
        expect(_primaryFocusIsWithin(tester, restore), isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(restore, findsNothing);
        final previousGuideAction = find.byKey(
          const ValueKey('guide-topic-action-settings'),
        );
        expect(_primaryFocusIsWithin(tester, previousGuideAction), isTrue);
        final status = find.byKey(
          const ValueKey('guide-today-card-restored-status'),
        );
        final statusData = tester.getSemantics(status).getSemanticsData();
        expect(statusData.flagsCollection.isLiveRegion, isTrue);
        expect(statusData.label, isNotEmpty);
        final snapshot = await service.load();
        expect(snapshot.isTodayCardDismissed, isFalse);
        expect(snapshot.isComplete(GuideTopicId.myBook), isTrue);
        semantics.dispose();
      },
    );

    testWidgets(
      'Today dismiss failure stays visible and does not escape the callback',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final preferences = await SharedPreferences.getInstance();
        var preferenceLoads = 0;
        final service = GuideProgressService(
          preferencesLoader: () async {
            if (preferenceLoads++ > 0) {
              throw StateError('dismiss write failed');
            }
            return preferences;
          },
        );

        await tester.pumpWidget(
          _localizedTestApp(
            Scaffold(
              body: ListView(
                children: [
                  TodayGuideChecklistSection(progressService: service),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('today-guide-dismiss')));
        await tester.pump();
        await tester.pump();

        expect(
          find.byKey(const ValueKey('today-guide-checklist-card')),
          findsOneWidget,
        );
        expect(
          find.text(
            'The guide setting could not be saved. Nothing changed; please '
            'try again.',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        expect(
          preferences.getBool(GuideProgressService.todayCardDismissedKey),
          isNull,
        );
      },
    );

    testWidgets(
      'Guide restore failure keeps its action and contains the write error',
      (tester) async {
        await _setView(tester, const Size(800, 2400));
        SharedPreferences.setMockInitialValues({
          GuideProgressService.todayCardDismissedKey: true,
        });
        final preferences = await SharedPreferences.getInstance();
        var preferenceLoads = 0;
        final service = GuideProgressService(
          preferencesLoader: () async {
            if (preferenceLoads++ > 0) {
              throw StateError('restore write failed');
            }
            return preferences;
          },
        );

        await tester.pumpWidget(
          _localizedTestApp(GuideHubRouteScreen(progressService: service)),
        );
        await tester.pumpAndSettle();

        final restore = find.byKey(const ValueKey('guide-restore-today-card'));
        await tester.tap(restore);
        await tester.pump();
        await tester.pump();

        expect(restore, findsOneWidget);
        expect(
          find.text(
            'The guide setting could not be saved. Nothing changed; please '
            'try again.',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        expect(
          preferences.getBool(GuideProgressService.todayCardDismissedKey),
          isTrue,
        );
      },
    );
  });
}

GuideTopicSpec _resolverTopic(GuideDestination destination) => GuideTopicSpec(
  id: GuideTopicId.learn,
  localizationKey: 'guideTopicLearn',
  destination: destination,
  availability: FeatureAvailability.live,
  requiredConsents: const {},
  requiredPermissions: const {},
  surfaces: const {GuideSurface.guideHub},
  completionMode: GuideCompletionMode.destinationOpened,
  analyticsSurface: GuideAnalyticsSurface.learn,
);

GuideTopicViewModel _viewModel({
  required GuideTopicId topic,
  required FeatureAvailability availability,
  required String availabilityLabel,
  String description = 'Topic description',
  bool completed = false,
}) {
  return GuideTopicViewModel(
    spec: GuideTopicSpec(
      id: topic,
      localizationKey: 'guideTopic${topic.name}',
      destination: const SoriStageTabDestination(SoriStageTabTarget.learn),
      availability: availability,
      requiredConsents: const {},
      requiredPermissions: const {},
      surfaces: const {GuideSurface.guideHub, GuideSurface.todayChecklist},
      completionMode: GuideCompletionMode.acknowledged,
      analyticsSurface: GuideAnalyticsSurface.values[topic.index],
    ),
    title: 'Topic ${topic.name}',
    description: description,
    availabilityLabel: availabilityLabel,
    actionLabel: 'Open topic',
    isCompleted: completed,
  );
}

Widget _testApp(Widget home, {double textScale = 1}) {
  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: home,
  );
}

Widget _localizedTestApp(
  Widget home, {
  Map<String, WidgetBuilder> routes = const <String, WidgetBuilder>{},
}) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('en'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    routes: routes,
    home: home,
  );
}

Future<void> _focusWithKeyboard(WidgetTester tester, Finder target) async {
  for (var attempt = 0; attempt < 32; attempt += 1) {
    if (_primaryFocusIsWithin(tester, target)) {
      return;
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  fail('Unable to move keyboard focus to the requested widget.');
}

bool _primaryFocusIsWithin(WidgetTester tester, Finder target) {
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (focusContext == null || target.evaluate().length != 1) {
    return false;
  }
  final targetElement = tester.element(target);
  if (identical(focusContext, targetElement)) {
    return true;
  }
  var isWithin = false;
  focusContext.visitAncestorElements((ancestor) {
    if (identical(ancestor, targetElement)) {
      isWithin = true;
      return false;
    }
    return true;
  });
  return isWithin;
}

Future<void> _setCompactView(WidgetTester tester) async {
  await _setView(tester, const Size(320, 640));
}

Future<void> _setView(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}
