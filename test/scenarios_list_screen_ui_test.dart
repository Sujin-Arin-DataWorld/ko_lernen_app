import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/guide_contract.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/screens/scenarios_list_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/badge.dart';
import 'package:ko_lernen_app/widgets/sori/hanok_header.dart';
import 'package:ko_lernen_app/widgets/sori/pressable.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

import 'support/scenario_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_tut_scenarios': true,
    });
    await Storage.init();
  });

  testWidgets('approved shelf art and localized metadata stay canonical', (
    tester,
  ) async {
    await _pumpScenarios(
      tester,
      size: const Size(390, 844),
      textScale: 1.3,
      scenarios: const [scenarioAirportArrivalFixture],
    );

    final header = tester.widget<HanokHeader>(find.byType(HanokHeader));
    expect(header.asset, 'assets/illustrations/hanok/madang(light).png');
    expect(header.loopAsset, 'assets/video/loops/hanok_jongga.mp4');
    expect(header.aspectRatio, closeTo(16 / 9, 0.0001));

    await _scrollTo(tester, find.text('5 bis 7 Minuten · +120 XP'));
    expect(find.text('5 bis 7 Minuten · +120 XP'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _pumpScenarios(
      tester,
      size: const Size(390, 844),
      textScale: 1.3,
      locale: const Locale('en'),
      scenarios: const [scenarioAirportArrivalFixture],
    );
    await _scrollTo(tester, find.text('5 to 7 minutes · +120 XP'));
    expect(find.text('5 to 7 minutes · +120 XP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('open scenario card is a labeled button and keeps its route', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpScenarios(
      tester,
      size: const Size(390, 844),
      textScale: 1.3,
      scenarios: const [scenarioAirportArrivalFixture],
    );

    final card = find.bySemanticsLabel(
      'Einreise am Flughafen. 5 bis 7 Minuten · +120 XP',
    );
    await _scrollTo(tester, card);
    expect(card, findsOneWidget);
    final data = tester.getSemantics(card).getSemanticsData();
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
    expect(tester.getSize(card).height, greaterThanOrEqualTo(48));

    await tester.tap(card);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ScenarioPlayerScreen), findsOneWidget);
    semantics.dispose();
  });

  // Mutation caught: removing OpenContainer.onClosed leaves the grid card at
  // 0 stars and the lesson path at A1: 0/1 after the player route closes.
  testWidgets('grid card refreshes progress after the player route closes', (
    tester,
  ) async {
    await _pumpScenarios(
      tester,
      size: const Size(390, 844),
      textScale: 1.0,
      scenarios: const [scenarioAirportArrivalFixture],
    );

    const cardLabel = 'Einreise am Flughafen. 5 bis 7 Minuten · +120 XP';
    _expectScenarioProgress(
      tester,
      cardLabel: cardLabel,
      stars: 0,
      pathProgress: 'A1: 0/1 ★',
    );

    final card = find.bySemanticsLabel(cardLabel);
    await _scrollTo(tester, card);
    await tester.tap(card);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ScenarioPlayerScreen), findsOneWidget);

    await Storage.setScenarioStars(scenarioAirportArrivalFixture.id, 1);
    Navigator.of(tester.element(find.byType(ScenarioPlayerScreen))).pop();
    await tester.pumpAndSettle();

    _expectScenarioProgress(
      tester,
      cardLabel: cardLabel,
      stars: 1,
      pathProgress: 'A1: 1/1 ★',
    );
  });

  // Mutation caught: removing the Navigator.push completion callback leaves
  // the next recommendation path at 0/1 after its player route closes.
  testWidgets(
    'next recommended refreshes progress after the player route closes',
    (tester) async {
      await _pumpScenarios(
        tester,
        size: const Size(390, 844),
        textScale: 1.0,
        scenarios: const [scenarioAirportArrivalFixture],
      );

      const cardLabel = 'Einreise am Flughafen. 5 bis 7 Minuten · +120 XP';
      _expectScenarioProgress(
        tester,
        cardLabel: cardLabel,
        stars: 0,
        pathProgress: 'A1: 0/1 ★',
      );

      final nextRecommended = find.ancestor(
        of: find.text('Als Nächstes'),
        matching: find.byType(SoriPressable),
      );
      await _scrollTo(tester, nextRecommended);
      await tester.tap(nextRecommended);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ScenarioPlayerScreen), findsOneWidget);

      await Storage.setScenarioStars(scenarioAirportArrivalFixture.id, 1);
      Navigator.of(tester.element(find.byType(ScenarioPlayerScreen))).pop();
      await tester.pumpAndSettle();

      _expectScenarioProgress(
        tester,
        cardLabel: cardLabel,
        stars: 1,
        pathProgress: 'A1: 1/1 ★',
      );
    },
  );

  testWidgets('locked scenario is labeled and cannot open the player', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpScenarios(
      tester,
      size: const Size(390, 844),
      textScale: 1.0,
      scenarios: const [scenarioAirportArrivalFixture, _b1Scenario],
      ignoreLevelLock: false,
    );

    const label =
        'Geschäftliches Treffen. 5 bis 7 Minuten · +180 XP. '
        'Erreiche B1, um freizuschalten';
    await _scrollTo(tester, find.text(_b1Scenario.title.de));
    final card = find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.label == label,
      description: 'locked scenario semantics',
    );
    expect(card, findsOneWidget);
    final data = tester.getSemantics(card).getSemanticsData();
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
    expect(tester.getSize(card).height, greaterThanOrEqualTo(48));

    await tester.tap(card);
    await tester.pump();
    expect(find.byType(ScenarioPlayerScreen), findsNothing);
    expect(find.text('Erreiche B1, um freizuschalten'), findsWidgets);
    semantics.dispose();
  });

  test('named-route boundary accepts only ScenarioBrowseDestination', () {
    const destination = ScenarioBrowseDestination(
      level: LearnerLevel.b1,
      shelfId: 'b1_team',
    );

    expect(
      ScenariosListScreen.fromRouteArguments(destination).browseDestination,
      same(destination),
    );
    expect(
      ScenariosListScreen.fromRouteArguments(null).browseDestination,
      isNull,
    );
    expect(
      ScenariosListScreen.fromRouteArguments({
        'level': 'b1',
        'shelfId': 'b1_team',
      }).browseDestination,
      isNull,
    );
    expect(
      ScenariosListScreen.fromRouteArguments('b1_team').browseDestination,
      isNull,
    );
  });

  testWidgets(
    'typed browse shows only the exact shelf without applying course locks or writes',
    (tester) async {
      final preferences = await SharedPreferences.getInstance();
      final before = <String, Object?>{
        for (final key in preferences.getKeys()) key: preferences.get(key),
      };

      await _pumpScenarios(
        tester,
        size: const Size(390, 844),
        textScale: 1.0,
        ignoreLevelLock: false,
        browseDestination: const ScenarioBrowseDestination(
          level: LearnerLevel.b1,
          shelfId: 'b1_team',
        ),
        scenarios: const [_b1Scenario, _b1OtherShelfScenario, _a1Scenario],
      );

      await _scrollTo(tester, find.text(_b1Scenario.title.de));
      expect(find.text(_b1Scenario.title.de), findsOneWidget);
      expect(find.text(_b1OtherShelfScenario.title.de), findsNothing);
      expect(find.text(_a1Scenario.title.de), findsNothing);
      expect(find.text('Erreiche B1, um freizuschalten'), findsNothing);
      expect(find.text('Dein Pfad'), findsNothing);
      expect(Storage.userLevelCode, 'a1');
      expect(Storage.xp, 0);
      expect(Storage.scenarioStars, isEmpty);
      expect(Storage.courseMasteryRawJson, isEmpty);

      final after = <String, Object?>{
        for (final key in preferences.getKeys()) key: preferences.get(key),
      };
      expect(after, before);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('typed browse fails closed for an unknown shelf', (tester) async {
    await _pumpScenarios(
      tester,
      size: const Size(390, 844),
      textScale: 1.0,
      browseDestination: const ScenarioBrowseDestination(
        level: LearnerLevel.b1,
        shelfId: 'b1_not_real',
      ),
      scenarios: const [_b1Scenario],
    );

    expect(find.text('Bald verfügbar'), findsOneWidget);
    expect(find.text('Neue Szenarien folgen bald.'), findsOneWidget);
    expect(find.text(_b1Scenario.title.de), findsNothing);
    expect(find.text('Dein Pfad'), findsNothing);
  });

  testWidgets('typed browse fails closed for a known unstocked shelf', (
    tester,
  ) async {
    await _pumpScenarios(
      tester,
      size: const Size(390, 844),
      textScale: 1.0,
      browseDestination: const ScenarioBrowseDestination(
        level: LearnerLevel.b1,
        shelfId: 'b1_team',
      ),
      scenarios: const [_b1OtherShelfScenario, _a1Scenario],
    );

    expect(find.text('Bald verfügbar'), findsOneWidget);
    expect(find.text('Neue Szenarien folgen bald.'), findsOneWidget);
    expect(find.text(_b1OtherShelfScenario.title.de), findsNothing);
    expect(find.text(_a1Scenario.title.de), findsNothing);
  });

  testWidgets('catalog remains reachable across the required viewport matrix', (
    tester,
  ) async {
    const cases = <({Size size, double scale})>[
      (size: Size(320, 640), scale: 2.0),
      (size: Size(360, 400), scale: 1.0),
      (size: Size(390, 844), scale: 1.3),
      (size: Size(720, 1024), scale: 1.3),
      (size: Size(1280, 900), scale: 1.3),
    ];

    for (final testCase in cases) {
      await _pumpScenarios(
        tester,
        size: testCase.size,
        textScale: testCase.scale,
        scenarios: const [scenarioAirportArrivalFixture, _b1Scenario],
      );
      await _scrollTo(tester, find.text(_b1Scenario.title.de));
      expect(find.text(_b1Scenario.title.de), findsOneWidget);
      expect(find.text('5 bis 7 Minuten · +180 XP'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}

Future<void> _pumpScenarios(
  WidgetTester tester, {
  required Size size,
  required double textScale,
  required List<Scenario> scenarios,
  Locale locale = const Locale('de'),
  bool ignoreLevelLock = true,
  ScenarioBrowseDestination? browseDestination,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        const safeInsets = EdgeInsets.only(top: 44, bottom: 34);
        return MediaQuery(
          data: media.copyWith(
            padding: safeInsets,
            viewPadding: safeInsets,
            textScaler: TextScaler.linear(textScale),
          ),
          child: SoriTypeScale(child: child!),
        );
      },
      home: ScenariosListScreen(
        ignoreLevelLock: ignoreLevelLock,
        loadScenarios: () async => scenarios,
        browseDestination: browseDestination,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  final list = find.byType(ListView).first;
  for (var i = 0; i < 50 && finder.evaluate().isEmpty; i += 1) {
    await tester.drag(list, const Offset(0, -240));
    await tester.pump();
  }
  if (finder.evaluate().isNotEmpty) {
    await tester.ensureVisible(finder.first);
  }
  await tester.pump();
}

void _expectScenarioProgress(
  WidgetTester tester, {
  required String cardLabel,
  required int stars,
  required String pathProgress,
}) {
  final card = find.bySemanticsLabel(cardLabel);
  final cardStars = find.descendant(of: card, matching: find.byType(SoriStars));
  expect(cardStars, findsOneWidget);
  expect(tester.widget<SoriStars>(cardStars).filled, stars);
  expect(find.text(pathProgress), findsOneWidget);
}

const _b1Scenario = Scenario(
  id: 'business_meeting',
  level: LearnerLevel.b1,
  emoji: '💼',
  register: Register.business,
  title: LocalizedText(
    ko: '업무 회의',
    de: 'Geschäftliches Treffen',
    en: 'Business meeting',
  ),
  intro: LocalizedText(ko: '', de: '', en: ''),
  vocab: [],
  grammarIds: [],
  dialog: [],
  quests: [],
  shelf: 'b1_team',
  xpReward: 180,
);

const _b1OtherShelfScenario = Scenario(
  id: 'repair_request',
  level: LearnerLevel.b1,
  emoji: '🔧',
  register: Register.polite,
  title: LocalizedText(
    ko: '수리 요청',
    de: 'Reparatur anfragen',
    en: 'Requesting a repair',
  ),
  intro: LocalizedText(ko: '', de: '', en: ''),
  vocab: [],
  grammarIds: [],
  dialog: [],
  quests: [],
  shelf: 'b1_repair',
);

const _a1Scenario = Scenario(
  id: 'restaurant_order',
  level: LearnerLevel.a1,
  emoji: '🍚',
  register: Register.polite,
  title: LocalizedText(
    ko: '식당 주문',
    de: 'Im Restaurant bestellen',
    en: 'Ordering at a restaurant',
  ),
  intro: LocalizedText(ko: '', de: '', en: ''),
  vocab: [],
  grammarIds: [],
  dialog: [],
  quests: [],
  shelf: 'a1_eat',
);
