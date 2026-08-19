import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/models/quest.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/app_shell.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_catalog_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_gye_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_hanok_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_today_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  for (final size in const <Size>[
    Size(390, 844),
    Size(600, 960),
    Size(720, 1024),
    Size(1280, 900),
  ]) {
    testWidgets('Sori Stage shell has no layout exception at ${size.width}dp', (
      tester,
    ) async {
      _setViewport(tester, size);
      await tester.pumpWidget(_shellApp(textScale: 1));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Profile'), findsOneWidget);
      final profileSize = tester.getSize(find.byTooltip('Profile'));
      expect(profileSize.width, greaterThanOrEqualTo(48));
      expect(profileSize.height, greaterThanOrEqualTo(48));
    });
  }

  testWidgets('390dp shell remains usable at 200 percent text', (tester) async {
    _setViewport(tester, const Size(390, 844));
    await tester.pumpWidget(_shellApp(textScale: 2));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Today'), findsWidgets);
    expect(find.text('Gye'), findsWidgets);
  });

  for (final fixture in <({Locale locale, ThemeData theme, String name})>[
    (locale: const Locale('de'), theme: AppTheme.light, name: 'DE light'),
    (locale: const Locale('en'), theme: AppTheme.dark, name: 'EN dark'),
  ]) {
    testWidgets('${fixture.name} catalog supports reduced motion', (
      tester,
    ) async {
      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        _catalogApp(
          locale: fixture.locale,
          theme: fixture.theme,
          disableAnimations: true,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(SoriStageCatalogScreen), findsOneWidget);
      expect(
        find.byTooltip(
          fixture.locale.languageCode == 'de' ? 'Profil' : 'Profile',
        ),
        findsOneWidget,
      );
    });
  }

  testWidgets('catalog meets tap target, label and contrast guidelines', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _catalogApp(
        locale: const Locale('en'),
        theme: AppTheme.light,
        disableAnimations: true,
      ),
    );
    await tester.pump();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });

  // §C-3b: 1280dp에서 카탈로그 오버플로가 재발하지 않는지 검증.
  // §C-1-4 수리 전에는 soriGridColumns가 클램프 전 전체 폭(1280)을 받아
  // 880px 안에 6열 → 18px 오버플로가 발생했다.
  testWidgets('1280dp catalog does not overflow (regression §C-1-4)', (
    tester,
  ) async {
    _setViewport(tester, const Size(1280, 900));
    await tester.pumpWidget(
      _catalogApp(
        locale: const Locale('en'),
        theme: AppTheme.light,
        disableAnimations: true,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(SoriStageCatalogScreen), findsOneWidget);
  });

  for (final tab in const <SoriStageTab>[
    SoriStageTab.learn,
    SoriStageTab.games,
  ]) {
    for (final size in const <Size>[
      Size(320, 640),
      Size(360, 400),
      Size(390, 844),
      Size(720, 1024),
      Size(1280, 900),
    ]) {
      for (final textScale in const <double>[1, 1.3, 2]) {
        testWidgets(
          '${tab.name} catalog fits ${size.width}x${size.height} at ${textScale}x',
          (tester) async {
            _setViewport(tester, size);
            await tester.pumpWidget(
              _catalogApp(
                locale: const Locale('de'),
                theme: AppTheme.light,
                disableAnimations: true,
                textScale: textScale,
                tab: tab,
              ),
            );
            await tester.pump();

            expect(tester.takeException(), isNull);
            expect(find.byType(SoriStageCatalogScreen), findsOneWidget);
          },
        );
      }
    }
  }

  // Today keeps the current chrome. These cases only lock overflow / text
  // fit on narrow, short, large-type, and wide viewports.
  for (final size in const <Size>[
    Size(320, 640),
    Size(360, 400),
    Size(390, 844),
    Size(1280, 900),
  ]) {
    for (final textScale in const <double>[1, 2]) {
      testWidgets('Today fits ${size.width}x${size.height} at ${textScale}x', (
        tester,
      ) async {
        await _initStorage();
        _setViewport(tester, size);
        await tester.pumpWidget(
          _todayApp(textScale: textScale, locale: const Locale('de')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(tester.takeException(), isNull);
        expect(find.byType(SoriStageTodayScreen), findsOneWidget);
      });
    }
  }

  for (final size in const <Size>[
    Size(320, 640),
    Size(360, 400),
    Size(390, 844),
    Size(1280, 900),
  ]) {
    for (final textScale in const <double>[1, 2]) {
      testWidgets('Hanok fits ${size.width}x${size.height} at ${textScale}x', (
        tester,
      ) async {
        await _initStorage();
        _setViewport(tester, size);
        await tester.pumpWidget(_hanokApp(textScale: textScale));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(tester.takeException(), isNull);
        expect(find.byType(SoriStageHanokScreen), findsOneWidget);
        expect(
          find.byKey(const ValueKey('hanok-shortcut-quests')),
          findsOneWidget,
        );
      });

      testWidgets('Gye fits ${size.width}x${size.height} at ${textScale}x', (
        tester,
      ) async {
        await _initGyeStorage();
        _setViewport(tester, size);
        await tester.pumpWidget(_gyeApp(textScale: textScale));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(find.byType(SoriStageGyeScreen), findsOneWidget);
      });
    }
  }
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _shellApp({required double textScale}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      disableAnimations: true,
      textScaler: TextScaler.linear(textScale),
    ),
    child: child!,
  ),
  home: const AppShell(),
  onGenerateRoute: (_) => MaterialPageRoute<void>(
    builder: (_) => const Scaffold(body: Text('route')),
  ),
);

Widget _catalogApp({
  required Locale locale,
  required ThemeData theme,
  required bool disableAnimations,
  double textScale = 1,
  SoriStageTab tab = SoriStageTab.learn,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: theme,
  locale: locale,
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      disableAnimations: disableAnimations,
      textScaler: TextScaler.linear(textScale),
    ),
    child: child!,
  ),
  home: SoriStageCatalogScreen(tab: tab),
  onGenerateRoute: (_) => MaterialPageRoute<void>(
    builder: (_) => const Scaffold(body: Text('route')),
  ),
);

Future<void> _initStorage() async {
  Storage.resetForTesting();
  SharedPreferences.setMockInitialValues(<String, Object>{
    'kl_user_level': 'a1',
    'kl_tut_home_tour': true,
  });
  await Storage.init();
}

Widget _todayApp({required double textScale, required Locale locale}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
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
    home: SoriStageTodayScreen(
      loadSnapshot: () async => _todayFitSnapshot(),
      now: () => DateTime(2026, 8, 14, 9),
      forceStaticHero: true,
      enableMilestoneCelebrations: false,
    ),
    onGenerateRoute: (_) => MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('route')),
    ),
  );
}

SoriStageProgressionSnapshot _todayFitSnapshot() =>
    SoriStageProgressionSnapshot(
      today: const TodayLearningSnapshot(
        pick: ReviewPick(dueCount: 12),
        destination: TodayLearningDestination(route: '/review'),
        dueCount: 12,
      ),
      hanok: PersonalHanokProjection.from(
        const LevelRatios(a1: 1, a2: .5, b1: 0, b2: 0),
      ),
      quests: const [
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
      stampCount: 4,
      xp: 320,
      streakDays: 6,
      todayReward: const RewardContract(
        activityId: 'srs',
        condition: SoriLocalizedCopy(de: 'Lernen', en: 'Learn'),
        items: [
          RewardContractItem(
            kind: SoriRewardKind.xp,
            label: SoriLocalizedCopy(de: 'Lern-XP', en: 'Learning XP'),
          ),
        ],
      ),
    );

Future<void> _initGyeStorage() async {
  Storage.resetForTesting();
  SharedPreferences.setMockInitialValues(<String, Object>{
    'kl_user_level': 'a1',
    'kl_tut_gye_tab': true,
  });
  await Storage.init();
}

Widget _hanokApp({required double textScale}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: true,
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: SoriStageHanokScreen(
      worldForTesting: const ColoredBox(color: Colors.transparent),
      loadSnapshot: () async => _todayFitSnapshot(),
    ),
    onGenerateRoute: (_) => MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('route')),
    ),
  );
}

Widget _gyeApp({required double textScale}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: true,
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: const SoriStageGyeScreen(),
    onGenerateRoute: (_) => MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('route')),
    ),
  );
}
