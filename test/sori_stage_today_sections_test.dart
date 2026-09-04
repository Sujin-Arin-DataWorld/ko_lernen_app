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
import 'package:ko_lernen_app/widgets/sori/mascot_preference.dart';

/// **§W-D D3/D7** — Today 퀘스트 행이 fraction 으로 "Fast geschafft"(≥60%)와
/// "Als Nächstes"(<60%) 두 섹션으로 갈리는지, 빈 섹션은 헤더까지 숨는지.
/// **§W-D D2/D7** — 한옥 카드가 더 이상 맨 `'$built / $total'` 을 쓰지 않고
/// [AppL10n.soriStageHanokPieces] 문구를 쓰며, 그 total 이 모델의
/// [PersonalHanokProjection.constructionTotal] 과 일치하는지.
void main() {
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
    required SoriStageProgressionSnapshot snapshot,
    Locale locale = const Locale('en'),
  }) async {
    // 실측: 기본 테스트 뷰포트(800x600)에서는 미션 카드 아래 섹션이
    // SliverList 의 cacheExtent 밖이라 find.text 가 못 찾는다(스크롤 없이).
    // 세로로 넉넉히 키워 전체가 한 프레임에 다 빌드되게 한다.
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: SoriStageTodayScreen(
            loadSnapshot: () async => snapshot,
            now: () => DateTime(2026, 8, 14, 9),
          ),
        ),
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('route')),
        ),
      ),
    );
    await tester.pump();
    // §MOTION-1(J5): reduce-motion 이면 SoriEntrance 가 타이머를 아예
    // 예약하지 않는다 — 더 이상 흘려보낼 것이 없다.
    await tester.pump();
  }

  SoriStageProgressionSnapshot buildSnapshot({
    required List<QuestProgress> quests,
    PersonalHanokProjection? hanok,
  }) => SoriStageProgressionSnapshot(
    today: const TodayLearningSnapshot(
      pick: ReviewPick(dueCount: 12),
      destination: TodayLearningDestination(route: '/review'),
      dueCount: 12,
    ),
    hanok:
        hanok ??
        PersonalHanokProjection.from(
          const LevelRatios(a1: 1, a2: .5, b1: 0, b2: 0),
        ),
    quests: quests,
    pendingBojagiCount: 0,
    stampCount: 4,
    xp: 320,
    streakDays: 6,
    todayReward: null,
  );

  testWidgets('fraction 0.7 행은 Fast geschafft 아래, 0.2 행은 Als Nächstes 아래', (
    tester,
  ) async {
    final t = await AppL10n.delegate.load(const Locale('en'));
    final snapshot = buildSnapshot(
      quests: const [
        // q_jangdokdae target=15 → 11/15 ≈ 0.73 (≥0.6).
        QuestProgress(
          questId: 'q_jangdokdae',
          current: 11,
          target: 15,
          active: true,
          completed: false,
          completedAtIso: null,
        ),
        // q_maehwa target=30 → 6/30 = 0.2 (<0.6).
        QuestProgress(
          questId: 'q_maehwa',
          current: 6,
          target: 30,
          active: true,
          completed: false,
          completedAtIso: null,
        ),
      ],
    );
    await pumpToday(tester, snapshot: snapshot);

    expect(find.text(t.soriStageClosestQuests), findsOneWidget);
    expect(find.text(t.soriStageNextQuests), findsOneWidget);

    final nearlyCompleteHeader = tester.getCenter(
      find.text(t.soriStageClosestQuests),
    );
    final upNextHeader = tester.getCenter(find.text(t.soriStageNextQuests));
    final jarRow = tester.getCenter(find.text('Jar terrace'));
    final plumRow = tester.getCenter(find.text('Plum tree'));

    // "Fast geschafft" 헤더가 Jar terrace(0.73) 행보다 위, "Als Nächstes"
    // 헤더보다도 위에 있다 — 즉 순서가 [Fast geschafft, Jar terrace(0.73),
    // Als Nächstes, Plum tree(0.2)] 다.
    expect(nearlyCompleteHeader.dy, lessThan(jarRow.dy));
    expect(jarRow.dy, lessThan(upNextHeader.dy));
    expect(upNextHeader.dy, lessThan(plumRow.dy));
  });

  testWidgets('빈 섹션은 헤더까지 렌더하지 않는다 (전부 ≥0.6)', (tester) async {
    final t = await AppL10n.delegate.load(const Locale('en'));
    final snapshot = buildSnapshot(
      quests: const [
        QuestProgress(
          questId: 'q_jangdokdae',
          current: 14,
          target: 15,
          active: true,
          completed: false,
          completedAtIso: null,
        ),
      ],
    );
    await pumpToday(tester, snapshot: snapshot);

    expect(find.text(t.soriStageClosestQuests), findsOneWidget);
    expect(find.text(t.soriStageNextQuests), findsNothing);
  });

  testWidgets('빈 섹션은 헤더까지 렌더하지 않는다 (전부 <0.6)', (tester) async {
    final t = await AppL10n.delegate.load(const Locale('en'));
    final snapshot = buildSnapshot(
      quests: const [
        QuestProgress(
          questId: 'q_maehwa',
          current: 3,
          target: 30,
          active: true,
          completed: false,
          completedAtIso: null,
        ),
      ],
    );
    await pumpToday(tester, snapshot: snapshot);

    expect(find.text(t.soriStageClosestQuests), findsNothing);
    expect(find.text(t.soriStageNextQuests), findsOneWidget);
  });

  testWidgets(
    '한옥 카드는 맨 fraction 대신 soriStageHanokPieces 문구를 쓰고 total 은 모델과 일치한다',
    (tester) async {
      final t = await AppL10n.delegate.load(const Locale('de'));
      final hanok = PersonalHanokProjection.from(
        const LevelRatios(a1: 0, a2: 0, b1: 0, b2: 0),
      );
      expect(hanok.unlocked.length, 0);
      expect(
        hanok.constructionTotal,
        PersonalHanokProjection.constructionMilestones.length,
      );

      final snapshot = buildSnapshot(quests: const [], hanok: hanok);
      await pumpToday(tester, snapshot: snapshot, locale: const Locale('de'));

      // 맨 '0 / 7' 텍스트(부재 단위 없는 옛 오버레이 문구)는 어디에도 없다.
      expect(find.text('0 / 7'), findsNothing);
      expect(
        find.text(t.soriStageHanokPieces(0, hanok.constructionTotal)),
        findsOneWidget,
      );
    },
  );
}
