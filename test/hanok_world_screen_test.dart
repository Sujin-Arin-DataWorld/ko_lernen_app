import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/data/personal_hanok_venue_catalog.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/screens/hanok_world_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/personal_hanok_reveal_service.dart';
import 'package:ko_lernen_app/widgets/sori/madang_background.dart';
import 'package:ko_lernen_app/widgets/sori/personal_hanok_map.dart';

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
    final openSelected = find.byKey(
      const ValueKey('hanok-world-open-selected'),
    );
    await tester.ensureVisible(openSelected);
    expect(openSelected, findsOneWidget);
    await tester.tap(openSelected);

    expect(opened, PersonalHanokZone.sarangbang);
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

Widget _host(Widget child) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: child,
  ),
);

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
