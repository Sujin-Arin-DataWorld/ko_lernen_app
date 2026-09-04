import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/gye_tab_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_gye_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_hanok_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_today_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/responsive.dart';
import 'package:ko_lernen_app/widgets/sori/stats_top_bar.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

const _safeInsets = EdgeInsets.only(top: 44, bottom: 34);
const _viewports = <Size>[
  Size(320, 640),
  Size(360, 400),
  Size(390, 844),
  Size(720, 1024),
  Size(1280, 900),
];
const _textScales = <double>[1, 1.3, 1.6, 2];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'kl_user_level': 'a1',
      'kl_streak_days': 7,
      'kl_xp': 320,
      'kl_tut_gye_tab': true,
      'kl_tut_home_tour': true,
    });
    await Storage.init();
  });

  testWidgets(
    'Gye scrolls its own sliver chrome inside SafeArea '
    '(§W-G G5.1 dropped the shared SoriMinHeightScroll contract, mirrors '
    'the Hanok tab below)',
    (tester) async {
      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        _responsiveApp(
          locale: const Locale('en'),
          textScale: 1,
          safeInsets: _safeInsets,
          home: const SoriStageGyeScreen(active: false),
        ),
      );
      await tester.pump();

      // §W-G G5.1: the old fixed-chrome `Column` (`SoriStageSafeViewport` →
      // `SoriMinHeightScroll`) is gone — the tab now scrolls a single
      // `CustomScrollView` inside `SafeArea`, exactly like Hanok already
      // does below.
      expect(find.byType(SoriMinHeightScroll), findsNothing);
      expect(find.byType(SafeArea), findsWidgets);
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Hanok scrolls its own sliver chrome inside SafeArea '
    '(§W-F F1 dropped the shared SoriMinHeightScroll contract)',
    (tester) async {
      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        _responsiveApp(
          locale: const Locale('de'),
          textScale: 1,
          safeInsets: _safeInsets,
          home: const SoriStageHanokScreen(
            active: false,
            // §W-F F1: the tab's own `CustomScrollView` now wraps this in a
            // `SliverToBoxAdapter`, which — unlike the old bounded
            // `Expanded` slot — gives an unbounded height. `SizedBox.expand`
            // (the previous stand-in here) asks to be as big as possible
            // under that constraint and throws; a bounded stand-in, as the
            // shortcut tests already use, is the correct double for a
            // sliver-hosted seam.
            worldForTesting: ColoredBox(color: Colors.transparent),
          ),
        ),
      );
      await tester.pump();

      // The Gye/Today tabs above still measure their fixed chrome height via
      // `SoriMinHeightScroll` inside `SafeArea`. Hanok no longer needs that
      // contract at all: its `CustomScrollView` scrolls within whatever
      // bounded space `SafeArea` gives it directly, so a header/map/place
      // list taller than the viewport scrolls instead of overflowing, with
      // no explicit minimum-height forwarding required.
      expect(find.byType(SoriMinHeightScroll), findsNothing);
      expect(find.byType(SafeArea), findsWidgets);
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final locale in const <Locale>[Locale('de'), Locale('en')]) {
    for (final size in _viewports) {
      testWidgets('Gye CTA is complete at ${size.width}×${size.height} '
          '${locale.languageCode.toUpperCase()} for 100–200% text', (
        tester,
      ) async {
        _setViewport(tester, size);
        final t = await AppL10n.delegate.load(locale);

        for (final textScale in _textScales) {
          await tester.pumpWidget(
            _responsiveApp(
              locale: locale,
              textScale: textScale,
              // §W-G G5.1: `GyeTabScreen(embedded: true)` now returns a
              // sliver group (it no longer carries its own `Scaffold` +
              // `CustomScrollView`, exactly like `HanokWorldScreen(embedded:
              // true)`) — a real caller (`SoriStageGyeScreen`) hosts it
              // inside its own `CustomScrollView`, so this harness does the
              // same instead of using it as a screen root directly.
              home: Scaffold(
                body: CustomScrollView(
                  slivers: [
                    GyeTabScreen(
                      embedded: true,
                      enableCoach: false,
                      loadGyeMetas: () async => const [],
                      onFindOrCreate: () {},
                      onContinueSolo: () {},
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          final cta = find.text(t.gyeFindOrCreate);
          await tester.scrollUntilVisible(
            cta,
            240,
            scrollable: find.byType(Scrollable).first,
          );

          final text = tester.widget<Text>(cta);
          expect(text.data, t.gyeFindOrCreate);
          expect(text.maxLines, isNull);
          expect(text.overflow, isNull);
          expect(find.bySemanticsLabel(t.gyeFindOrCreate), findsOneWidget);
          expect(
            tester.takeException(),
            isNull,
            reason:
                '${locale.languageCode}, ${size.width}×${size.height}, '
                '${textScale}x',
          );
        }
      });
    }
  }

  testWidgets('320dp 200% top status keeps brand and both actions', (
    tester,
  ) async {
    _setViewport(tester, const Size(320, 640));
    final semantics = tester.ensureSemantics();
    var streakTaps = 0;
    var statsTaps = 0;
    await tester.pumpWidget(
      _responsiveApp(
        locale: const Locale('en'),
        textScale: 2,
        home: Scaffold(
          body: SoriStatsTopBar(
            streak: 7,
            level: 4,
            xp: 320,
            onStreakTap: () => streakTaps++,
            onStatsTap: () => statsTaps++,
            onProfileTap: () {},
            profileTooltip: 'Profile',
          ),
        ),
      ),
    );
    await tester.pump();

    final wordmark = tester.widget<Text>(find.text('Hangul Sori'));
    expect(wordmark.maxLines, isNull);
    expect(wordmark.overflow, isNull);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Lv 4'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(RegExp('7 Days')));
    await tester.tap(find.bySemanticsLabel(RegExp('Lv 4 · 320 XP')));
    expect(streakTaps, 1);
    expect(statsTaps, 1);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('320dp 200% Bojagi copy and action are not truncated', (
    tester,
  ) async {
    _setViewport(tester, const Size(320, 640));
    final semantics = tester.ensureSemantics();
    final t = await AppL10n.delegate.load(const Locale('de'));
    await tester.pumpWidget(
      _responsiveApp(
        locale: const Locale('de'),
        textScale: 2,
        home: SoriStageTodayScreen(
          loadSnapshot: () async => _snapshot(),
          forceStaticHero: true,
          enableMilestoneCelebrations: false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final action = find.byKey(const ValueKey('pending-bojagi-action'));
    await tester.scrollUntilVisible(
      action,
      260,
      scrollable: find.byType(Scrollable).first,
    );

    for (final key in const <ValueKey<String>>[
      ValueKey('pending-bojagi-title'),
      ValueKey('pending-bojagi-body'),
      ValueKey('pending-bojagi-action'),
    ]) {
      final text = tester.widget<Text>(find.byKey(key));
      expect(text.maxLines, isNull);
      expect(text.overflow, isNull);
    }
    expect(
      find.bySemanticsLabel(
        [
          t.soriStageBojagiTitle,
          '1',
          t.soriStageBojagiBody,
          t.soriStageOpenBojagi,
        ].join('. '),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets(
    // §NAV-4(J3): _PendingBojagi's outer Semantics must repeat the inner
    // InkWell's onTap, or a screen reader's double-tap does nothing (the
    // ExcludeSemantics child hides the InkWell's own tap action).
    'Bojagi pending semantics node performs the tap and opens the route',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final t = await AppL10n.delegate.load(const Locale('de'));
      await tester.pumpWidget(
        _responsiveApp(
          locale: const Locale('de'),
          textScale: 1,
          home: SoriStageTodayScreen(
            loadSnapshot: () async => _snapshot(),
            forceStaticHero: true,
            enableMilestoneCelebrations: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final label = [
        t.soriStageBojagiTitle,
        '1',
        t.soriStageBojagiBody,
        t.soriStageOpenBojagi,
      ].join('. ');
      final finder = find.bySemanticsLabel(label);
      await tester.scrollUntilVisible(
        finder,
        260,
        scrollable: find.byType(Scrollable).first,
      );

      final data = tester.getSemantics(finder).getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(ui.SemanticsAction.tap), isTrue);

      final nodeId = tester.getSemantics(finder).id;
      // ignore: deprecated_member_use
      tester.binding.pipelineOwner.semanticsOwner!.performAction(
        nodeId,
        ui.SemanticsAction.tap,
      );
      await tester.pumpAndSettle();
      expect(find.text('/bojagi'), findsOneWidget);

      semantics.dispose();
    },
  );

  testWidgets('320dp 200% Hanok shortcuts stack and remain reachable', (
    tester,
  ) async {
    _setViewport(tester, const Size(320, 640));
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _responsiveApp(
        locale: const Locale('de'),
        textScale: 2,
        safeInsets: _safeInsets,
        home: SoriStageHanokScreen(
          loadSnapshot: () async => _snapshot(),
          worldForTesting: const ColoredBox(color: Colors.transparent),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final quests = find.byKey(const ValueKey('hanok-shortcut-quests'));
    final dojang = find.byKey(const ValueKey('hanok-shortcut-dojang'));
    final bojagi = find.byKey(const ValueKey('hanok-shortcut-bojagi'));
    await tester.scrollUntilVisible(
      bojagi,
      220,
      scrollable: find.byType(Scrollable).last,
    );

    expect(
      tester.getTopLeft(dojang).dy,
      greaterThan(tester.getBottomLeft(quests).dy),
    );
    expect(
      tester.getTopLeft(bojagi).dy,
      greaterThan(tester.getBottomLeft(dojang).dy),
    );
    for (final id in const ['quests', 'dojang', 'bojagi']) {
      final text = tester.widget<Text>(
        find.byKey(ValueKey('hanok-shortcut-label-$id')),
      );
      expect(text.maxLines, isNull);
      expect(text.overflow, isNull);
    }
    expect(find.bySemanticsLabel(RegExp('Dojang-Heft, ')), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}

SoriStageProgressionSnapshot _snapshot() => SoriStageProgressionSnapshot(
  today: const TodayLearningSnapshot(
    pick: ReviewPick(dueCount: 12),
    destination: TodayLearningDestination(route: '/review'),
    dueCount: 12,
  ),
  hanok: PersonalHanokProjection.from(
    const LevelRatios(a1: 1, a2: .5, b1: 0, b2: 0),
  ),
  quests: const [],
  pendingBojagiCount: 1,
  stampCount: 0,
  xp: 320,
  streakDays: 7,
  todayReward: null,
);

Widget _responsiveApp({
  required Locale locale,
  required double textScale,
  required Widget home,
  EdgeInsets safeInsets = EdgeInsets.zero,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: locale,
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, child) {
    final mediaQuery = MediaQuery.of(context).copyWith(
      padding: safeInsets,
      viewPadding: safeInsets,
      disableAnimations: true,
      textScaler: TextScaler.linear(textScale),
    );
    return MediaQuery(
      data: mediaQuery,
      child: SoriTypeScale(child: child!),
    );
  },
  home: home,
  onGenerateRoute: (settings) => MaterialPageRoute<void>(
    builder: (_) => Scaffold(body: Text(settings.name ?? 'route')),
  ),
);

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
