import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/hanok_competence.dart';
import 'package:ko_lernen_app/models/home_navigation_art.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/app_shell.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_shell.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_today_screen.dart';
import 'package:ko_lernen_app/services/learning_journey.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/adaptive_navigation.dart';
import 'package:ko_lernen_app/widgets/sori/mascot_preference.dart';

import 'support/real_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadSoriRealFonts);
  setUp(() async {
    LearningJourneyObserver.shared.cancel();
    Storage.resetForTesting();
    AppShell.requestedStageTab.value = -1;
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_tut_home_tour': true,
      'kl_tut_gye_tab': true,
      'kl_preferred_mascot': 'tiger',
    });
    await Storage.init();
    MascotPreference.load();
  });

  test('all approved home artwork keeps its source bytes and transparency', () {
    final manifest =
        jsonDecode(
              File(
                'docs/assets/NATIVE_HOME_NAV_ART_20261004.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final files = manifest['files'] as List;
    expect(files.map((entry) => entry['asset']).toSet(), {
      HomeNavigationArt.today,
      HomeNavigationArt.learn,
      HomeNavigationArt.games,
      HomeNavigationArt.hanok,
      HomeNavigationArt.gye,
      HomeNavigationArt.settings,
      HomeNavigationArt.treasureChest,
    });
    for (final entry in files) {
      final bytes = File(entry['asset'] as String).readAsBytesSync();
      expect(
        sha256.convert(bytes).toString(),
        entry['sha256'],
        reason: entry['asset'] as String,
      );
      final decoded = image.decodePng(bytes)!;
      expect(decoded.numChannels, 4);
      expect(decoded.any((pixel) => pixel.a == 0), isTrue);
    }
  });

  for (final width in [390.0, 800.0]) {
    testWidgets('the actual ${width}dp shell uses artwork for all five roots', (
      tester,
    ) async {
      _viewport(tester, Size(width, 1000));
      final replay = ValueNotifier(0);
      addTearDown(replay.dispose);
      await tester.pumpWidget(
        _app(
          const Locale('en'),
          SoriStageShell(
            replayHomeTour: replay,
            loadTodaySnapshot: () async => _snapshot(0),
          ),
        ),
      );
      await tester.pump();
      final nav = find.byType(SoriAdaptiveNavigation);
      final expected = [
        HomeNavigationArt.today,
        HomeNavigationArt.learn,
        HomeNavigationArt.games,
        HomeNavigationArt.hanok,
        HomeNavigationArt.gye,
      ];
      for (final asset in expected) {
        final art = find.descendant(of: nav, matching: _asset(asset));
        expect(art, findsWidgets, reason: asset);
        for (final widget in tester.widgetList<Image>(art)) {
          expect(widget.fit, BoxFit.contain);
          expect(widget.color, isNull);
          expect(widget.matchTextDirection, isFalse);
          expect(widget.excludeFromSemantics, isTrue);
        }
      }
      expect(
        find.descendant(of: nav, matching: find.byType(Icon)),
        findsNothing,
      );
      for (final index in [2, 1, 0]) {
        final root = expected[index];
        await tester.tap(
          find.descendant(of: nav, matching: _asset(root)).first,
        );
        await tester.pump();
        expect(tester.widget<SoriAdaptiveNavigation>(nav).selectedIndex, index);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  for (final locale in [const Locale('de'), const Locale('en')]) {
    testWidgets('${locale.languageCode} treasure chest keeps count and route '
        'at 320dp/200%', (tester) async {
      _viewport(tester, const Size(320, 640));
      final semantics = tester.ensureSemantics();
      try {
        final t = await AppL10n.delegate.load(locale);
        await tester.pumpWidget(
          _app(
            locale,
            SoriStageTodayScreen(
              loadSnapshot: () async => _snapshot(2),
              forceStaticHero: true,
              enableMilestoneCelebrations: false,
            ),
            textScale: 2,
          ),
        );
        await tester.pump();
        await tester.pump();
        final action = find.byKey(const ValueKey('pending-bojagi-action'));
        await tester.scrollUntilVisible(
          action,
          240,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        await Scrollable.ensureVisible(tester.element(action), alignment: .5);
        await tester.pump();
        expect(tester.getRect(action).bottom, lessThanOrEqualTo(640));
        expect(find.text('${t.soriStageBojagiTitle} · 2'), findsOneWidget);
        expect(find.text(t.soriStageBojagiBody), findsOneWidget);
        expect(_asset(HomeNavigationArt.treasureChest), findsOneWidget);
        final label = [
          t.soriStageBojagiTitle,
          '2',
          t.soriStageBojagiBody,
          t.soriStageOpenBojagi,
        ].join('. ');
        expect(find.bySemanticsLabel(label), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(action);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('/bojagi'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        semantics.dispose();
      }
    });
  }
}

Finder _asset(String asset) => find.byWidgetPredicate((widget) {
  if (widget is! Image) {
    return false;
  }
  final provider = widget.image is ResizeImage
      ? (widget.image as ResizeImage).imageProvider
      : widget.image;
  return provider is AssetImage && provider.assetName == asset;
});

SoriStageProgressionSnapshot _snapshot(int pending) =>
    SoriStageProgressionSnapshot(
      today: const TodayLearningSnapshot(
        pick: ReviewPick(dueCount: 12),
        destination: TodayLearningDestination(route: '/review'),
        dueCount: 12,
      ),
      hanokCompetence: const HanokCompetenceProjection.empty(),
      quests: const [],
      pendingBojagiCount: pending,
      stampCount: 0,
      xp: 320,
      streakDays: 7,
      todayReward: null,
    );

Widget _app(Locale locale, Widget home, {double textScale = 1}) => MaterialApp(
  theme: AppTheme.light,
  locale: locale,
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      disableAnimations: true,
      textScaler: TextScaler.linear(textScale),
    ),
    child: child!,
  ),
  onGenerateRoute: (settings) => MaterialPageRoute<void>(
    builder: (_) => Scaffold(body: Text(settings.name ?? 'route')),
  ),
  home: home,
);

void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
