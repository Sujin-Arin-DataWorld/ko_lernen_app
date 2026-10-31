import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/data/canonical_companion_art.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/hanok_competence.dart';
import 'package:ko_lernen_app/models/quest.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_common.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_today_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/c_stage_chrome.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_materials.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/character_clip.dart';
import 'package:ko_lernen_app/widgets/sori/home_hero.dart';
import 'package:ko_lernen_app/widgets/sori/tiger_video.dart';
import 'package:ko_lernen_app/widgets/sori/mascot.dart';
import 'package:ko_lernen_app/widgets/sori/mascot_preference.dart';
import 'package:ko_lernen_app/widgets/sori/reward_thumb.dart';
import 'package:ko_lernen_app/widgets/sori/approved_chrome_assets.dart';
import 'package:ko_lernen_app/widgets/sori/settings_button.dart';
import 'package:ko_lernen_app/widgets/sori/top_chrome.dart';

import 'support/real_fonts.dart';

/// The approved C5 jade material and transparent canonical companion replace
/// the retired video-matte composition; interaction/state contracts remain.
void main() {
  setUpAll(() => loadSoriRealFonts(materialIcons: true));
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'kl_user_level': 'a1',
      'kl_preferred_mascot': 'tiger',
      'kl_tut_home_tour': true,
    });
    await Storage.init();
    MascotPreference.load();
  });

  Future<void> pumpToday(
    WidgetTester tester, {
    SoriStageProgressionSnapshot? snapshot,
    Locale locale = const Locale('en'),
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: TickerMode(
          enabled: false,
          child: MediaQuery(
            data: MediaQueryData(
              disableAnimations: true,
              textScaler: TextScaler.linear(textScale),
            ),
            child: SoriStageTodayScreen(
              loadSnapshot: () async => snapshot ?? _snapshot(),
              now: () => DateTime(2026, 8, 14, 9),
            ),
          ),
        ),
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('route')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> openDetails(WidgetTester tester) async {
    final details = find.byKey(const ValueKey('today-details'));
    expect(details, findsOneWidget);
    await tester.tap(details);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('c-today-board')), findsOneWidget);
  }

  Finder inDetails(Finder target) => find.descendant(
    of: find.byKey(const ValueKey('c-today-board')),
    matching: target,
  );

  testWidgets(
    'Today uses the approved jade material behind its native header',
    (tester) async {
      await pumpToday(tester);

      final bg = find.byKey(const ValueKey('sori-today-bg'));
      expect(tester.widget(bg), isA<CStageBackground>());
      expect(
        find.descendant(
          of: bg,
          matching: find.byWidgetPredicate(
            (widget) => widget is ColoredBox && widget.color == CPalette.jade,
          ),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Today keeps canonical companion, brand, wallet and settings chrome',
    (tester) async {
      await pumpToday(tester);

      expect(
        find.byKey(const ValueKey('today-companion-greeting')),
        findsOneWidget,
      );
      expect(find.text('HANGUL SORI'), findsOneWidget);
      expect(find.byType(SoriWalletBadge), findsOneWidget);
      expect(find.byType(SoriSettingsButton), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ApprovedChromeImage &&
              widget.asset == ApprovedChromeAssets.cloud,
        ),
        findsOneWidget,
      );
      // 2026-08-13 롤백 사유의 수리 증명: 텍스트 RootHeader 는 이 탭에 없다.
      expect(find.byType(SoriStageRootHeader), findsNothing);
      // 프로필 진입은 톱바 아이콘으로 유지 (셸 테스트의 byTooltip 계약).
      expect(find.byTooltip('Profile'), findsOneWidget);
    },
  );

  testWidgets(
    'Today adopts the mature textured portrait without legacy video',
    (tester) async {
      final previous = TigerStageVideo.videoReady;
      TigerStageVideo.videoReady = true;
      addTearDown(() => TigerStageVideo.videoReady = previous);
      await pumpToday(tester);

      expect(find.byType(CharacterClipPlayer), findsNothing);
      final companion = find.byKey(const ValueKey('learning-companion-ground'));
      final portrait = find.descendant(
        of: companion,
        matching: find.byType(Image),
      );
      expect(
        (tester.widget<Image>(portrait).image as AssetImage).assetName,
        CanonicalCompanionArt.baekhoPortrait,
      );
      final ground = tester.getSize(
        find.byKey(const ValueKey('learning-companion-ground')),
      );
        expect(ground, const Size(152, 144));
      expect(tester.widget<Image>(portrait).fit, BoxFit.contain);
    },
  );

  testWidgets('까치 홈 히어로는 정본 PNG에 예전 영상 확대를 적용하지 않는다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: const Scaffold(
          body: SoriCharacterHero(
            greeting: 'Hello',
            bubble: 'Keep going',
            phase: SoriDayPhase.morning,
            kind: MascotKind.magpie,
          ),
        ),
      ),
    );
    await tester.pump();

    final player = tester.widget<CharacterClipPlayer>(
      find.byType(CharacterClipPlayer),
    );
    expect(player.asset, HomeHeroClips.magpieWalkingFront);
    expect(CharacterClips.retiredStillFor(player.asset), isNotNull);
    expect(find.byKey(const ValueKey('home_hero_magpie_scale')), findsNothing);
  });

  testWidgets('아침 9시 인사말이 헤더를 대신한다', (tester) async {
    await pumpToday(tester);

    final l10n = await AppL10n.delegate.load(const Locale('en'));
    expect(find.text(l10n.homeHeroGreetingMorning), findsOneWidget);
  });

  // W-C2: q_jangdokdae's QuestDefinition.name.en changed from
  // 'Jangdokdae (jar terrace)' to 'Jar terrace' (H6 — quest_catalog.dart
  // names now match decorName* ARB values; the SoriTerm secondary line
  // carries the romanization/hangul instead).
  testWidgets('실제 보상 2종과 가장 가까운 퀘스트 썸네일까지 렌더한다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpToday(tester, snapshot: _richSnapshot());
    await openDetails(tester);

    expect(inDetails(find.text('XP')), findsOneWidget);
    expect(inDetails(find.text('Quest')), findsOneWidget);

    await tester.scrollUntilVisible(
      inDetails(find.text('Jar terrace')),
      260,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pump();

    expect(inDetails(find.byType(SoriRewardThumb)), findsOneWidget);
    expect(inDetails(find.text('Jar terrace')), findsOneWidget);
    expect(inDetails(find.text('3 / 15')), findsOneWidget);
    expect(tester.takeException(), isNull);

    // §MOTION-1(J5): reduce-motion (pumpToday sets disableAnimations:
    // true) now schedules 0 timers — SoriEntrance judges reduce-motion
    // once in didChangeDependencies and never schedules a delay Timer,
    // so no settle pump is needed here anymore.
    await tester.pump();
  });

  testWidgets('long German reward wraps at 320dp and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpToday(
      tester,
      snapshot: _longRewardSnapshot(),
      locale: const Locale('de'),
      textScale: 2,
    );
    await openDetails(tester);

    await tester.scrollUntilVisible(
      inDetails(find.text('Verifizierter Hanok-Baufortschritt')),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pump();

    expect(
      inDetails(find.text('Verifizierter Hanok-Baufortschritt')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    // §MOTION-1(J5) — 위 테스트와 같은 이유로 더 이상 필요 없다.
    await tester.pump();
  });
}

SoriStageProgressionSnapshot _snapshot() => SoriStageProgressionSnapshot(
  today: const TodayLearningSnapshot(
    pick: ReviewPick(dueCount: 12),
    destination: TodayLearningDestination(route: '/review'),
    dueCount: 12,
  ),
  hanokCompetence: const HanokCompetenceProjection.empty(),
  quests: const [],
  pendingBojagiCount: 1,
  stampCount: 4,
  xp: 320,
  streakDays: 6,
  todayReward: null,
);

SoriStageProgressionSnapshot _richSnapshot() => SoriStageProgressionSnapshot(
  today: const TodayLearningSnapshot(
    pick: ReviewPick(dueCount: 12),
    destination: TodayLearningDestination(route: '/review'),
    dueCount: 12,
  ),
  hanokCompetence: const HanokCompetenceProjection.empty(),
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
  pendingBojagiCount: 0,
  stampCount: 4,
  xp: 320,
  streakDays: 6,
  todayReward: const RewardContract(
    activityId: 'srs',
    condition: SoriLocalizedCopy(de: 'Lernen', en: 'Learn'),
    items: [
      RewardContractItem(
        kind: SoriRewardKind.xp,
        amount: 15,
        label: SoriLocalizedCopy(
          key: SoriCopyKey.rewardXp,
          de: 'Lern-XP',
          en: 'XP',
        ),
      ),
      RewardContractItem(
        kind: SoriRewardKind.questProgress,
        label: SoriLocalizedCopy(
          key: SoriCopyKey.rewardQuest,
          de: 'Quest',
          en: 'Quest',
        ),
      ),
    ],
  ),
);

SoriStageProgressionSnapshot _longRewardSnapshot() =>
    SoriStageProgressionSnapshot(
      today: const TodayLearningSnapshot(
        pick: ReviewPick(dueCount: 12),
        destination: TodayLearningDestination(route: '/review'),
        dueCount: 12,
      ),
      hanokCompetence: const HanokCompetenceProjection.empty(),
      quests: const [],
      pendingBojagiCount: 0,
      stampCount: 4,
      xp: 320,
      streakDays: 6,
      todayReward: const RewardContract(
        activityId: 'srs',
        condition: SoriLocalizedCopy(de: 'Lernen', en: 'Learn'),
        items: [
          RewardContractItem(
            kind: SoriRewardKind.hanokProgress,
            label: SoriLocalizedCopy(
              de: 'Verifizierter Hanok-Baufortschritt',
              en: 'Verified Hanok construction progress',
            ),
          ),
        ],
      ),
    );
