import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/data/personal_hanok_venue_catalog.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/hanok_build_narrative.dart';
import 'package:ko_lernen_app/models/hanok_competence.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/screens/hanok_world_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/personal_hanok_reveal_service.dart';
import 'package:ko_lernen_app/widgets/sori/app_bar.dart';
import 'package:ko_lernen_app/widgets/sori/madang_background.dart';
import 'package:ko_lernen_app/widgets/sori/personal_hanok_map.dart';
import 'package:ko_lernen_app/widgets/sori/progress.dart';
import 'package:ko_lernen_app/widgets/sori/world_map_viewport.dart';

const _narrativeUnit = CourseUnit(
  id: 'a1_01',
  level: 'a1',
  order: 1,
  title: CurriculumText(ko: '인사', de: 'Begrüßung', en: 'Greeting'),
  canDo: CurriculumText(
    ko: '인사할 수 있어요.',
    de: 'Ich kann jemanden begrüßen.',
    en: 'I can greet someone.',
  ),
);

final AppL10n _l10n = lookupAppL10n(const Locale('de'));

void main() {
  test('canonical completed room zones open their own interiors', () {
    expect(hanokRouteForZone(PersonalHanokZone.anchae), '/hanok/anbang');
    expect(
      hanokRouteForZone(PersonalHanokZone.daecheongmaru),
      '/hanok/daecheong',
    );
  });

  test('does not leak the legacy daily challenge from the Huwon', () {
    // Huwon has a venue sheet because it offers the calligraphy sheet and
    // quests. A bare route here would bypass that choice and open the wrong
    // daily surface.
    expect(hanokRouteForZone(PersonalHanokZone.huwon), isNull);
  });

  testWidgets('keeps the legacy courtyard before the estate gate opens', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        HanokWorldScreen(
          loadRatios: () async =>
              const LevelRatios(a1: 1, a2: 1, b1: .24, b2: 1),
          loadProjection: _legacyProjection,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(MadangBackground), findsOneWidget);
    expect(
      find.byKey(const ValueKey('personal-hanok-zone-sarangbang')),
      findsNothing,
    );
  });

  testWidgets('adds the verified can-do to the existing world introduction', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        HanokWorldScreen(
          loadRatios: () async =>
              const LevelRatios(a1: .25, a2: 0, b1: 0, b2: 0),
          loadProjection: _legacyProjection,
          loadNarrative: (projection) async => HanokBuildNarrative.fromSnapshot(
            projection: projection,
            snapshot: const CourseMasterySnapshot(completedUnitIds: ['a1_01']),
            courseUnits: [_narrativeUnit],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(
        'Structure: Laying foundation stones. Verified: I can greet someone.',
      ),
      240,
      scrollable: find.byType(Scrollable).first,
    );

    expect(
      find.text(
        'Structure: Laying foundation stones. Verified: I can greet someone.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('03A opens the current course mission from the next build card', (
    tester,
  ) async {
    String? openedRoute;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        onGenerateRoute: (settings) {
          openedRoute = settings.name;
          return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: SizedBox()),
          );
        },
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: HanokWorldScreen(
            loadRatios: () async =>
                const LevelRatios(a1: .25, a2: 0, b1: 0, b2: 0),
            loadProjection: _legacyProjection,
            revealStore: _MemoryRevealStore.initialized(),
          ),
        ),
      ),
    );
    await tester.pump();

    final nextScene = find.byKey(const ValueKey('hanok-world-next-scene'));
    await tester.scrollUntilVisible(
      nextScene,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(nextScene);
    await tester.pump();
    expect(nextScene, findsOneWidget);
    await tester.tap(nextScene);
    await tester.pump();

    expect(openedRoute, '/course/mission');
  });

  testWidgets('03A shows safe-scene progress toward the current beam', (
    tester,
  ) async {
    final projection = PersonalHanokProjection.from(
      const LevelRatios(a1: .25, a2: 0, b1: 0, b2: 0),
    );
    await tester.pumpWidget(
      _host(
        HanokWorldScreen.preview(
          projection: projection,
          narrative: HanokBuildNarrative(
            projection: projection,
            safeSceneCount: 1,
            safeScenesTowardNextBeam: 1,
            scenesPerBeam: 2,
            plannedBeamCount: 1,
          ),
        ),
      ),
    );

    final progressLabel = find.text('1 of 2 scenarios mastered');
    await tester.dragUntilVisible(
      progressLabel,
      find.byType(ListView).first,
      const Offset(0, -240),
    );

    expect(find.text('Next building step'), findsOneWidget);
    expect(progressLabel, findsOneWidget);
    expect(
      tester.widget<SoriProgressBar>(find.byType(SoriProgressBar)).value,
      .5,
    );
  });

  testWidgets('03A keeps the safe-scene build story usable at 308dp ×1.3', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(308, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final projection = PersonalHanokProjection.from(
      const LevelRatios(a1: .25, a2: 0, b1: 0, b2: 0),
    );

    await tester.pumpWidget(
      _host(
        HanokWorldScreen.preview(
          projection: projection,
          narrative: HanokBuildNarrative(
            projection: projection,
            verifiedUnit: _narrativeUnit,
            safeSceneCount: 1,
            safeScenesTowardNextBeam: 1,
            scenesPerBeam: 2,
            plannedBeamCount: 1,
          ),
        ),
        locale: const Locale('de'),
        textScale: 1.3,
      ),
    );

    expect(find.text('Dein Hof · A1'), findsOneWidget);
    expect(
      find.text('Deine erste Szene ist der Anfang deines Hanok.'),
      findsOneWidget,
    );
    expect(
      find.text('Dein Fundament steht: jemanden begrüßen.'),
      findsOneWidget,
    );
    final map = find.byType(PersonalHanokMap);
    expect(tester.getSize(map).height, greaterThanOrEqualTo(278));
    final progress = find.text('1 von 2 Szenarien sicher gemeistert');
    await tester.dragUntilVisible(
      progress,
      find.byType(ListView).first,
      const Offset(0, -220),
    );
    expect(find.text('Nächster Bauabschnitt'), findsOneWidget);
    expect(progress, findsOneWidget);
    expect(find.text('Nächste Szene ansehen'), findsOneWidget);
    expect(find.text('Mein Haus erkunden'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    expect(tester.takeException(), isNull);
  });

  testWidgets('standalone Hanok chrome stays complete at 320dp and 200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final projection = PersonalHanokProjection.from(
      const LevelRatios(a1: .25, a2: 0, b1: 0, b2: 0),
    );

    await tester.pumpWidget(
      _host(
        HanokWorldScreen.preview(
          projection: projection,
          narrative: HanokBuildNarrative.empty(projection),
        ),
        locale: const Locale('de'),
        textScale: 2,
        safeInsets: const EdgeInsets.only(top: 44, bottom: 34),
      ),
    );
    await tester.pump();

    expect(find.byType(SoriAppBar), findsOneWidget);
    final title = tester.widget<Text>(find.text('Meine Hanok-Welt'));
    expect(title.maxLines, isNotNull);
    expect(title.overflow, TextOverflow.clip);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the estate map from verified course structure alone', (
    tester,
  ) async {
    final projection = _courseGateProjection();
    expect(projection.usesCompoundMap, isTrue);
    expect(projection.isUnlocked(PersonalHanokMilestone.sotdaeulmun), isTrue);
    tester.view.physicalSize = const Size(308, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _host(
        HanokWorldScreen(
          loadRatios: () async => const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
          loadProjection: (_) async => projection,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.scrollUntilVisible(find.byType(WorldMapViewport), 260);

    expect(find.byType(WorldMapViewport), findsOneWidget);
    final map = tester.widget<PersonalHanokMap>(find.byType(PersonalHanokMap));
    expect(map.projection.usesCompoundMap, isTrue);
    expect(
      map.projection.isUnlocked(PersonalHanokMilestone.sarangchae),
      isFalse,
    );
  });

  testWidgets('selects a map place before its detail action opens it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(308, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    PersonalHanokZone? opened;
    await tester.pumpWidget(
      _host(
        HanokWorldScreen(
          loadRatios: () async => const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 1),
          loadProjection: _legacyProjection,
          onOpenZone: (zone) => opened = zone,
        ),
      ),
    );
    await tester.pump();

    final sarangbang = find.byKey(
      const ValueKey('personal-hanok-zone-sarangbang'),
    );
    expect(sarangbang, findsOneWidget);
    expect(tester.getSize(find.byType(PersonalHanokMap)).width, 308);
    final targets = <({PersonalHanokZone zone, Finder finder})>[
      (zone: PersonalHanokZone.sarangbang, finder: sarangbang),
      (
        zone: PersonalHanokZone.daecheongmaru,
        finder: find.byKey(const ValueKey('personal-hanok-zone-daecheongmaru')),
      ),
      (
        zone: PersonalHanokZone.haengrangchae,
        finder: find.byKey(const ValueKey('personal-hanok-zone-haengrangchae')),
      ),
      (
        zone: PersonalHanokZone.anchae,
        finder: find.byKey(const ValueKey('personal-hanok-zone-anchae')),
      ),
      (
        zone: PersonalHanokZone.anchae,
        finder: find.byKey(const ValueKey('personal-hanok-zone-anchae-1')),
      ),
      (
        zone: PersonalHanokZone.huwon,
        finder: find.byKey(const ValueKey('personal-hanok-zone-huwon')),
      ),
      (
        zone: PersonalHanokZone.huwon,
        finder: find.byKey(const ValueKey('personal-hanok-zone-huwon-1')),
      ),
      (
        zone: PersonalHanokZone.sadang,
        finder: find.byKey(const ValueKey('personal-hanok-zone-sadang')),
      ),
    ];
    for (var first = 0; first < targets.length; first++) {
      for (var second = first + 1; second < targets.length; second++) {
        if (targets[first].zone == targets[second].zone) {
          continue;
        }
        expect(
          tester
              .getRect(targets[first].finder)
              .overlaps(tester.getRect(targets[second].finder)),
          isFalse,
          reason: 'screen target $first overlaps $second at 308dp',
        );
      }
    }

    await tester.tap(sarangbang);
    await tester.pump();

    expect(opened, isNull);
    expect(
      find.text(
        'Return to today\'s scene and the expressions you have earned.',
      ),
      findsWidgets,
    );
    final openSelected = find.byKey(
      const ValueKey('hanok-world-open-selected'),
    );
    await tester.ensureVisible(openSelected);
    await tester.pump();
    expect(openSelected, findsOneWidget);
    await tester.tap(openSelected);

    expect(opened, PersonalHanokZone.sarangbang);
  });

  testWidgets('gallery preview renders real 03B widgets without storage load', (
    tester,
  ) async {
    final projection = PersonalHanokProjection.from(
      const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 1),
    );
    await tester.pumpWidget(
      _host(
        HanokWorldScreen.preview(
          projection: projection,
          narrative: HanokBuildNarrative(
            projection: projection,
            receipt: const HanokLearningReceipt(
              nextScenarioId: 'restaurant_scene',
              nextExpressionKo: '안 맵게 해 주세요.',
            ),
          ),
          selectedZone: PersonalHanokZone.sarangbang,
        ),
      ),
    );

    expect(find.byType(WorldMapViewport), findsOneWidget);
    expect(find.text('4 minutes · say “안 맵게 해 주세요.”'), findsOneWidget);
  });

  testWidgets('03B matches the compact German map contract at 308dp ×1.3', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(308, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final projection = PersonalHanokProjection.from(
      const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 1),
    );

    await tester.pumpWidget(
      _host(
        HanokWorldScreen.preview(
          projection: projection,
          narrative: HanokBuildNarrative(
            projection: projection,
            receipt: const HanokLearningReceipt(
              nextScenarioId: 'restaurant_scene',
              nextExpressionKo: '안 맵게 해 주세요.',
            ),
          ),
          selectedZone: PersonalHanokZone.sarangbang,
        ),
        locale: const Locale('de'),
        textScale: 1.3,
      ),
    );

    for (final label in [
      'Heute lernen',
      _l10n.hanokMapPlaceDaecheong,
      'Wörter',
      'Aufgaben',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Deine heutige Szene'), findsOneWidget);
    expect(find.text('4 Minuten · „안 맵게 해 주세요.“ sagen'), findsOneWidget);
    expect(find.text('Dorthin gehen'), findsOneWidget);
    expect(
      find.text(
        'Kehre zu deiner heutigen Szene und den erarbeiteten Ausdrücken zurück.',
      ),
      findsNothing,
    );
    await tester.scrollUntilVisible(
      find.text('Orte als Liste anzeigen'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Orte als Liste anzeigen'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'keeps the Gye road noninteractive and uses the separate shared-courtyard bridge',
    (tester) async {
      String? openedRoute;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          onGenerateRoute: (settings) {
            openedRoute = settings.name;
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: SizedBox()),
            );
          },
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: HanokWorldScreen(
              loadRatios: () async =>
                  const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 1),
              loadProjection: _legacyProjection,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(hanokRouteForZone(PersonalHanokZone.gyeRoad), isNull);
      final bridge = find.byKey(const ValueKey('hanok-world-gye-bridge'));
      await tester.scrollUntilVisible(bridge, 280);
      await tester.ensureVisible(bridge);
      await tester.pumpAndSettle();
      expect(bridge, findsOneWidget);

      await tester.tap(bridge);
      await tester.pumpAndSettle();

      expect(openedRoute, '/gye/hub');
    },
  );

  testWidgets('uses the accessible place list to select before opening', (
    tester,
  ) async {
    PersonalHanokZone? opened;
    await tester.pumpWidget(
      _host(
        HanokWorldScreen(
          loadRatios: () async => const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 1),
          loadProjection: _legacyProjection,
          onOpenZone: (zone) => opened = zone,
        ),
      ),
    );
    await tester.pump();

    final daecheong = find.byKey(
      const ValueKey('hanok-world-place-daecheongmaru'),
    );
    await tester.scrollUntilVisible(daecheong, 280);
    expect(daecheong, findsOneWidget);
    await tester.ensureVisible(daecheong);
    await tester.pump();

    await tester.tap(daecheong);
    await tester.pump();

    expect(opened, isNull);
    await tester.drag(find.byType(ListView), const Offset(0, 1200));
    await tester.pumpAndSettle();
    final openSelected = find.byKey(
      const ValueKey('hanok-world-open-selected'),
    );
    expect(openSelected, findsOneWidget);
    await tester.ensureVisible(openSelected);
    await tester.tap(openSelected);

    expect(opened, PersonalHanokZone.daecheongmaru);
  });

  testWidgets('opens a Huwon context surface before dispatching its action', (
    tester,
  ) async {
    final actions = <PersonalHanokVenueAction>[];
    await tester.pumpWidget(
      _host(
        HanokWorldScreen(
          loadRatios: () async => const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 1),
          loadProjection: _legacyProjection,
          revealStore: _MemoryRevealStore.initialized(
            Set<PersonalHanokMilestone>.from(PersonalHanokMilestone.values),
          ),
          onOpenVenueAction: (action) async => actions.add(action),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final huwon = find.byKey(const ValueKey('hanok-world-place-huwon'));
    // ListView lazily creates the lower accessibility alternatives. First
    // scroll it into the tree, then bring it fully on-screen before a real
    // pointer tap.
    await tester.scrollUntilVisible(huwon, 280);
    await tester.ensureVisible(huwon);
    await tester.pumpAndSettle();
    await tester.tap(huwon);
    await tester.pump();
    // The map viewport is lazily recycled while the place list is in view.
    // Return to its top section before resolving the selected-place action.
    await tester.drag(find.byType(ListView), const Offset(0, 1200));
    await tester.pumpAndSettle();
    final openSelected = find.byKey(
      const ValueKey('hanok-world-open-selected'),
    );
    await tester.ensureVisible(openSelected);
    await tester.tap(openSelected);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('personal-hanok-venue-huwon')),
      findsOneWidget,
    );
    final dailyCharacterAction = find.byKey(
      const ValueKey('personal-hanok-venue-action-openDailyCharacter'),
    );
    await tester.ensureVisible(dailyCharacterAction);
    await tester.tap(dailyCharacterAction);
    await tester.pump();

    expect(actions, [PersonalHanokVenueAction.openDailyCharacter]);
  });

  testWidgets('shows and records a newly unlocked map layer once', (
    tester,
  ) async {
    final revealStore = _MemoryRevealStore.initialized(const {
      PersonalHanokMilestone.sotdaeulmun,
    });
    await tester.pumpWidget(
      _host(
        HanokWorldScreen(
          loadRatios: () async =>
              const LevelRatios(a1: 1, a2: 1, b1: .5, b2: 0),
          loadProjection: _legacyProjection,
          revealStore: revealStore,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('personal-hanok-unlock-reveal')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('personal-hanok-unlock-reveal-continue')),
    );
    await tester.pump();

    expect(revealStore.marked, [PersonalHanokMilestone.haengrangchae]);
  });
}

Widget _host(
  Widget child, {
  Locale locale = const Locale('en'),
  double textScale = 1,
  EdgeInsets safeInsets = EdgeInsets.zero,
}) => MaterialApp(
  locale: locale,
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: MediaQuery(
    data: MediaQueryData(
      disableAnimations: true,
      padding: safeInsets,
      viewPadding: safeInsets,
      textScaler: TextScaler.linear(textScale),
    ),
    child: child,
  ),
);

PersonalHanokProjection _courseGateProjection() => PersonalHanokProjection.from(
  const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
  competence: HanokCompetenceProjection.fromSnapshot(
    snapshot: const CourseMasterySnapshot(
      completedUnitIds: ['a1_01', 'a2_01', 'b1_01'],
    ),
    courseUnits: [
      CourseUnit(
        id: 'a1_01',
        level: 'a1',
        order: 1,
        title: _narrativeUnit.title,
        canDo: _narrativeUnit.canDo,
      ),
      CourseUnit(
        id: 'a2_01',
        level: 'a2',
        order: 1,
        title: _narrativeUnit.title,
        canDo: _narrativeUnit.canDo,
      ),
      CourseUnit(
        id: 'b1_01',
        level: 'b1',
        order: 1,
        title: _narrativeUnit.title,
        canDo: _narrativeUnit.canDo,
      ),
      CourseUnit(
        id: 'b1_02',
        level: 'b1',
        order: 2,
        title: _narrativeUnit.title,
        canDo: _narrativeUnit.canDo,
      ),
      CourseUnit(
        id: 'b1_03',
        level: 'b1',
        order: 3,
        title: _narrativeUnit.title,
        canDo: _narrativeUnit.canDo,
      ),
      CourseUnit(
        id: 'b1_04',
        level: 'b1',
        order: 4,
        title: _narrativeUnit.title,
        canDo: _narrativeUnit.canDo,
      ),
    ],
  ),
);

Future<PersonalHanokProjection> _legacyProjection(LevelRatios ratios) async =>
    PersonalHanokProjection.from(ratios);

class _MemoryRevealStore implements PersonalHanokRevealStore {
  final Set<PersonalHanokMilestone> _seen;
  final bool _initialized;
  final List<PersonalHanokMilestone> marked = <PersonalHanokMilestone>[];

  _MemoryRevealStore.initialized([
    Set<PersonalHanokMilestone> seen = const <PersonalHanokMilestone>{},
  ]) : _seen = Set<PersonalHanokMilestone>.from(seen),
       _initialized = true;

  @override
  Future<PersonalHanokRevealSnapshot> load() async => _initialized
      ? PersonalHanokRevealSnapshot.initialized(Set.unmodifiable(_seen))
      : const PersonalHanokRevealSnapshot.uninitialized();

  @override
  Future<void> initialize(Iterable<PersonalHanokMilestone> milestones) async {
    _seen.addAll(milestones);
  }

  @override
  Future<void> markSeen(PersonalHanokMilestone milestone) async {
    marked.add(milestone);
    _seen.add(milestone);
  }
}
