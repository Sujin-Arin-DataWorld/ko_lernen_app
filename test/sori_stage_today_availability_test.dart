import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/models/quest.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_today_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/home_hero.dart';

/// The Stage shell must keep [TodayLearningSnapshot]'s availability contract:
/// a partial recommendation is never displayed or recorded as a fresh Today
/// mission. Saved review is the only optional learning action in that state.
void main() {
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'kl_user_level': 'a1',
      'kl_tut_home_tour': true,
    });
    await Storage.init();
  });

  testWidgets('ready snapshot keeps the normal Stage mission and reward', (
    tester,
  ) async {
    final t = await AppL10n.delegate.load(const Locale('en'));

    await _pumpToday(tester, loadSnapshot: () async => _readySnapshot());
    await tester.scrollUntilVisible(
      find.widgetWithText(SoriButton, t.soriStageMissionStart),
      300,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('sori-today-unavailable-mission')),
      findsNothing,
    );
    expect(
      find.widgetWithText(SoriButton, t.soriStageMissionStart),
      findsOneWidget,
    );
    expect(find.text('${t.soriStagePossibleReward}:'), findsOneWidget);
    expect(find.text('XP'), findsOneWidget);
  });

  testWidgets('purpose never changes the Today companion message', (
    tester,
  ) async {
    final t = await AppL10n.delegate.load(const Locale('en'));
    await Storage.setStreakDays(1);
    await Storage.setXp(40);

    await Storage.setMotivation('travel');
    await _pumpToday(tester, loadSnapshot: () async => _readySnapshot());
    final travelBubble = tester
        .widget<SoriCharacterHero>(find.byType(SoriCharacterHero))
        .bubble;

    await tester.pumpWidget(const SizedBox.shrink());
    await Storage.setMotivation('kdrama');
    await _pumpToday(tester, loadSnapshot: () async => _readySnapshot());
    final contentBubble = tester
        .widget<SoriCharacterHero>(find.byType(SoriCharacterHero))
        .bubble;

    expect(travelBubble, t.homeTigerBubbleResume);
    expect(contentBubble, travelBubble);
  });

  testWidgets('ready snapshot still allows an explicitly replayed home tour', (
    tester,
  ) async {
    final t = await AppL10n.delegate.load(const Locale('en'));
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final replayHomeTour = ValueNotifier<int>(0);
    addTearDown(replayHomeTour.dispose);
    var homeTourStarts = 0;

    await _pumpToday(
      tester,
      loadSnapshot: () async => _readySnapshot(),
      replayHomeTour: replayHomeTour,
      onHomeTourStarted: () => homeTourStarts++,
    );
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(SoriButton, t.soriStageMissionStart),
      findsOneWidget,
    );
    expect(
      tester
          .widget<SoriStageTodayScreen>(find.byType(SoriStageTodayScreen))
          .replayHomeTour,
      same(replayHomeTour),
    );

    replayHomeTour.value++;
    await tester.pumpAndSettle();

    expect(homeTourStarts, 1);
  });

  testWidgets(
    'unavailable snapshot replaces the fresh mission with safe review and retry',
    (tester) async {
      final t = await AppL10n.delegate.load(const Locale('en'));
      String? openedRoute;
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpToday(
        tester,
        loadSnapshot: () async => _unavailableSnapshot(
          reason: TodayLearningUnavailableReason.localData,
          dueCount: 12,
          pendingBojagiCount: 1,
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
        ),
        onGenerateRoute: (settings) {
          openedRoute = settings.name;
          return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Review route')),
          );
        },
      );

      expect(
        find.byKey(const ValueKey('sori-today-unavailable-mission')),
        findsOneWidget,
      );
      expect(find.text(t.homeLocalUnavailableEyebrow), findsOneWidget);
      expect(find.text(t.homeLocalUnavailableTitle), findsOneWidget);
      expect(find.text(t.homeUnavailableCta), findsOneWidget);
      expect(find.text(t.soriStageMissionAction), findsNothing);
      expect(find.text('${t.soriStagePossibleReward}:'), findsNothing);
      expect(find.text('XP'), findsNothing);
      expect(find.textContaining(t.soriStageBojagiTitle), findsNothing);
      expect(find.text(t.soriStageHanokNow), findsNothing);
      expect(find.text(t.soriStageClosestQuests), findsNothing);

      await tester.tap(find.byKey(const ValueKey('sori-today-saved-review')));
      await tester.pump();

      expect(openedRoute, '/review');
    },
  );

  testWidgets(
    'offline snapshot exposes retry only and returns to ready Today',
    (tester) async {
      final t = await AppL10n.delegate.load(const Locale('en'));
      var loads = 0;

      await _pumpToday(
        tester,
        loadSnapshot: () async {
          loads++;
          return loads == 1
              ? _unavailableSnapshot(
                  reason: TodayLearningUnavailableReason.offline,
                )
              : _readySnapshot();
        },
      );

      // §W-A2 재조사(실측): 토큰 확대로 이 화면 위쪽 "가이드 허브" 섹션이
      // 커져, 오프라인 카드("Connection paused")가 스크롤 없이는 화면 밖에
      // 있었다(scrollUntilVisible 로 실측 확인: 스크롤 전 allText 에 없다가
      // 스크롤 후 나타남). 실제로 스크롤해 도달 가능한 요소이므로 여기서
      // 명시적으로 스크롤한다.
      await tester.scrollUntilVisible(
        find.text(t.homeUnavailableEyebrow),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(t.homeUnavailableEyebrow), findsOneWidget);
      expect(find.text(t.homeUnavailableCta), findsNothing);
      expect(find.text(t.soriStageMissionAction), findsNothing);
      expect(
        find.widgetWithText(SoriButton, t.homeUnavailableRetry),
        findsOneWidget,
      );

      final retryButton = find.byKey(
        const ValueKey('sori-today-unavailable-retry'),
      );
      await tester.ensureVisible(retryButton);
      await tester.pump();
      await tester.tap(retryButton, warnIfMissed: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(loads, 2);
      expect(find.text(t.homeUnavailableEyebrow), findsNothing);
      final missionStart = find.widgetWithText(
        SoriButton,
        t.soriStageMissionStart,
      );
      if (missionStart.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          missionStart,
          -200,
          scrollable: find.byType(Scrollable).first,
        );
      }
      expect(missionStart, findsOneWidget);
    },
  );

  testWidgets(
    'unavailable snapshot suppresses automatic and replayed home tours',
    (tester) async {
      await Storage.resetTutorials();
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final replayHomeTour = ValueNotifier<int>(0);
      addTearDown(replayHomeTour.dispose);
      var homeTourStarts = 0;

      await _pumpToday(
        tester,
        loadSnapshot: () async => _unavailableSnapshot(
          reason: TodayLearningUnavailableReason.remoteService,
        ),
        replayHomeTour: replayHomeTour,
        onHomeTourStarted: () => homeTourStarts++,
      );

      expect(Storage.tutHomeTourSeen, isFalse);
      expect(homeTourStarts, 0);

      replayHomeTour.value++;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(homeTourStarts, 0);
    },
  );

  testWidgets(
    'unavailable snapshot never records or queues an earned milestone',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'kl_user_level': 'a1',
        'kl_tut_home_tour': true,
        'kl_streak_days': 3,
        'kl_xp': 400,
        'kl_hanok_stages_seen_v1': <String>['empty'],
      });
      Storage.resetForTesting();
      await Storage.init();

      await _pumpToday(
        tester,
        loadSnapshot: () async => _unavailableSnapshot(
          reason: TodayLearningUnavailableReason.remoteService,
        ),
        enableMilestoneCelebrations: true,
      );
      await tester.pump(const Duration(seconds: 1));

      expect(Storage.celebratedMilestones, isEmpty);
      expect(Storage.pendingBoxes, isEmpty);
    },
  );
}

Future<void> _pumpToday(
  WidgetTester tester, {
  required Future<SoriStageProgressionSnapshot> Function() loadSnapshot,
  RouteFactory? onGenerateRoute,
  ValueListenable<int>? replayHomeTour,
  VoidCallback? onHomeTourStarted,
  bool? enableMilestoneCelebrations,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      onGenerateRoute: onGenerateRoute,
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: SoriStageTodayScreen(
          loadSnapshot: loadSnapshot,
          replayHomeTour: replayHomeTour,
          now: () => DateTime(2026, 8, 14, 9),
          onHomeTourStarted: onHomeTourStarted,
          enableMilestoneCelebrations: enableMilestoneCelebrations,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

SoriStageProgressionSnapshot _readySnapshot() => _snapshot(
  const TodayLearningSnapshot(
    pick: ReviewPick(dueCount: 12),
    destination: TodayLearningDestination(route: '/review'),
    dueCount: 12,
  ),
);

SoriStageProgressionSnapshot _unavailableSnapshot({
  required TodayLearningUnavailableReason reason,
  int dueCount = 0,
  int pendingBojagiCount = 0,
  List<QuestProgress> quests = const [],
}) => _snapshot(
  TodayLearningSnapshot(
    pick: ReviewPick(dueCount: dueCount),
    destination: const TodayLearningDestination(route: '/review'),
    dueCount: dueCount,
    availability: TodayLearningAvailability.unavailable,
    unavailableReason: reason,
    unavailableSources: const {TodayLearningSource.course},
  ),
  pendingBojagiCount: pendingBojagiCount,
  quests: quests,
);

SoriStageProgressionSnapshot _snapshot(
  TodayLearningSnapshot today, {
  int pendingBojagiCount = 0,
  List<QuestProgress> quests = const [],
}) => SoriStageProgressionSnapshot(
  today: today,
  hanok: PersonalHanokProjection.from(
    const LevelRatios(a1: 1, a2: .5, b1: 0, b2: 0),
  ),
  quests: quests,
  pendingBojagiCount: pendingBojagiCount,
  stampCount: 4,
  xp: 320,
  streakDays: 6,
  todayReward: const RewardContract(
    activityId: 'srs',
    condition: SoriLocalizedCopy(de: 'Lernen', en: 'Learn'),
    items: [
      RewardContractItem(
        kind: SoriRewardKind.xp,
        label: SoriLocalizedCopy(
          key: SoriCopyKey.rewardXp,
          de: 'Lern-XP',
          en: 'XP',
        ),
      ),
    ],
  ),
);
