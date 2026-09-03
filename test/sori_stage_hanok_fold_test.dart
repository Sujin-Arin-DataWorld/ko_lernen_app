import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/models/quest.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_hanok_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/collapsing_header.dart';

import 'support/real_fonts.dart';

// §W-F F4: the Hanok tab used to hand the map an `Expanded` share of leftover
// height (`sori_stage_hanok_screen.dart`'s old `Column`), which pushed the
// place list below the fold on anything shorter than
// `kSoriStageMinimumUsableHeight` (640dp). This locks the new sliver
// structure's promise: header, map preview, shortcut row, and the first
// accessible place are all on-screen together at a common phone size, the
// pinned map actually shrinks on scroll, and large text does not throw.
//
// §W-F3 root cause: without a real font loaded, `flutter_test`'s default
// binding renders every glyph as a fixed 1em-wide square ("test font"),
// which inflated the measured header to 253-276dp and made the fold look
// impossibly tight. `loadSoriRealFonts()` (test/support/real_fonts.dart)
// loads the real Paperlogy/MaruBuri faces so this test measures what a
// device actually shows.
//
// Real-font budget at 390×844dp·de (§W-F3, measured via `tester.getRect`,
// with the 1-line soriStageHanokBody copy — title 2 lines, body 1 line):
//   header (eyebrow + 2-line title + 1-line body, top padding 20)  20→149  (129dp)
//   gap (Spacing.xl)                                               149→173 (24dp)
//   map (min(w×3/4,320))                                           173→465.5 (292.5dp)
//   gap(8) + shortcut row (quests tile; §W-J2 wraps the row in
//   `IntrinsicHeight` so it now stretches to match the taller 2-line
//   "Dojang-Heft" tile instead of sitting shorter inside the same row) 465.5→603.5 (138dp)
//   gap(12) + first place card top                                 603.5→615.5 (12dp)
//   -> first place card top = 615.5, fold budget = 764-24 = 740 (124.5dp to spare)

const _compoundRatios = LevelRatios(a1: 1, a2: 1, b1: 1, b2: 1);
const _bottomTabReserve = 80.0;
const _viewportSize = Size(390, 844);

void main() {
  setUpAll(loadSoriRealFonts);

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'kl_user_level': 'a1',
      'kl_tut_home_tour': true,
    });
    await Storage.init();
  });

  Future<void> settle(WidgetTester tester) async {
    // Two independent async chains gate the first real frame: the tab's own
    // `SoriStageProgressionSnapshot` future (feeds the map preview +
    // shortcuts) and `HanokWorldScreen`'s internal load (ratios ->
    // projection -> narrative -> reveal check, each a separate microtask
    // hop). A single `pump()` only resolves the first hop, so poll a few
    // frames instead of guessing one fixed delay.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Widget app({double textScale = 1}) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: SoriStageHanokScreen(
      loadSnapshot: () async => _snapshot(),
      worldLoadRatios: () async => _compoundRatios,
      worldLoadProjection: (ratios) async =>
          PersonalHanokProjection.from(ratios),
    ),
  );

  testWidgets(
    'keeps header, map preview, shortcuts and the first place within the fold at 390x844',
    (tester) async {
      tester.view.physicalSize = _viewportSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(app());
      await settle(tester);

      final fold = _viewportSize.height - _bottomTabReserve;

      // `SoriCollapsingHeader` itself builds a sliver (`SliverLayoutBuilder`),
      // which `tester.getRect` cannot measure directly — its own expanded
      // content layer (a plain `Opacity` box) carries this fixed key.
      expect(find.byType(SoriCollapsingHeader), findsOneWidget);
      final header = find.byKey(
        const ValueKey('sori-collapsing-header-expanded'),
      );
      final map = find.byKey(const ValueKey('hanok-map-header'));
      final shortcut = find.byKey(const ValueKey('hanok-shortcut-quests'));
      final firstPlace = find.byKey(
        const ValueKey('hanok-world-place-sarangbang'),
      );

      expect(header, findsOneWidget);
      expect(map, findsOneWidget);
      expect(shortcut, findsOneWidget);
      expect(
        firstPlace,
        findsOneWidget,
        reason:
            'the first accessible place row should already be built on the '
            'first frame, not require a scroll to reach',
      );

      // §W-F3: header/map/shortcuts must be fully on-screen; the first place
      // card only needs a 24dp peek from its top edge (its title line) — a
      // scroll affordance, not full visibility (§16 "the map is the
      // protagonist" — the map keeps its full-size stage instead of
      // shrinking to fit the whole place card in too). See the real-font
      // budget table above for why 615.5dp of real content still clears
      // this with 124.5dp to spare.
      for (final finder in [header, map, shortcut]) {
        final rect = tester.getRect(finder);
        expect(
          rect.bottom,
          lessThanOrEqualTo(fold),
          reason: '$finder bottom ${rect.bottom} exceeds the fold $fold',
        );
      }
      final firstPlaceRect = tester.getRect(firstPlace);
      expect(
        firstPlaceRect.top,
        lessThanOrEqualTo(fold - 24),
        reason:
            '${firstPlace}top ${firstPlaceRect.top} does not peek 24dp into '
            'the fold $fold',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the map header shrinks and stays pinned after a 600dp scroll', (
    tester,
  ) async {
    tester.view.physicalSize = _viewportSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app());
    await settle(tester);
    await tester.pumpAndSettle();

    final mapKey = find.byKey(const ValueKey('hanok-map-header'));
    expect(mapKey, findsOneWidget);
    final expandedHeight = tester.getRect(mapKey).height;

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    final collapsedRect = tester.getRect(mapKey);
    // 390 crossAxisExtent -> max(390 * 0.25, 88) == 97.5 (§W-F2 §1).
    const expectedCollapsed = 97.5;
    expect(collapsedRect.height, closeTo(expectedCollapsed, 0.5));
    expect(collapsedRect.height, lessThan(expandedHeight));
    // Pinned: still attached directly under the (also pinned) 56dp chrome
    // bar, not scrolled out of view.
    expect(collapsedRect.top, closeTo(kToolbarHeight, 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without exceptions at textScale 1.6', (tester) async {
    tester.view.physicalSize = _viewportSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(app(textScale: 1.6));
    await settle(tester);

    // skipOffstage:false — at 1.6x text scale these can legitimately sit
    // beyond the fold; this test only asserts they exist and nothing threw.
    expect(
      find.byKey(const ValueKey('hanok-map-header'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('hanok-shortcut-quests'), skipOffstage: false),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

SoriStageProgressionSnapshot _snapshot() => SoriStageProgressionSnapshot(
  today: const TodayLearningSnapshot(
    pick: ReviewPick(dueCount: 1),
    destination: TodayLearningDestination(route: '/review'),
    dueCount: 1,
  ),
  hanok: PersonalHanokProjection.from(_compoundRatios),
  quests: [
    QuestProgress(
      questId: 'q_jangdokdae',
      current: 3,
      target: 15,
      active: true,
      completed: false,
      completedAtIso: null,
    ),
  ],
  pendingBojagiCount: 1,
  stampCount: 0,
  xp: 0,
  streakDays: 0,
  todayReward: null,
);
