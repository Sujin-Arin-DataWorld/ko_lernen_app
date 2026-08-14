import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_common.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_today_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/character_clip.dart';
import 'package:ko_lernen_app/widgets/sori/home_hero.dart';
import 'package:ko_lernen_app/widgets/sori/stats_top_bar.dart';

/// SoriStage Today 의 **매트 배경 계약** (`home_hero_matte_test.dart` 의 화면판).
///
/// 히어로 클립은 한지색 매트(#FBF5EB)를 미리 합성한 불투명 mp4 다. Today 의
/// 라이트 배경이 정확히 그 값의 평면 단색이 아니면 Android 에서 영상 사각형이
/// 액자처럼 뜬다 (2026-08-12 실기기 실측 — 홈이 네 번 겪은 결함). 이 테스트는
/// Phase 2b(2026-08-14) 히어로 이식이 그 계약을 지키는지 고정한다.
void main() {
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'kl_user_level': 'a1',
      'kl_tut_home_tour': true,
    });
    await Storage.init();
  });

  Future<void> pumpToday(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: SoriStageTodayScreen(
            loadSnapshot: () async => _snapshot(),
            now: () => DateTime(2026, 8, 14, 9),
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

  testWidgets('라이트 배경은 히어로 클립 매트와 같은 평면 단색이다', (tester) async {
    await pumpToday(tester);

    final bg = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('sori-today-bg')),
    );
    expect(bg.color, HomeHeroClips.matte);
    // 토큰 드리프트 가드 — 매트 실측값 자체가 바뀌면 여기서 잡는다.
    expect(bg.color, const Color(0xFFFBF5EB));
  });

  testWidgets('마스코트 히어로와 스탯 톱바가 Today 를 이끈다 (RootHeader 부재)', (tester) async {
    await pumpToday(tester);

    expect(find.byType(SoriCharacterHero), findsOneWidget);
    expect(find.byType(SoriStatsTopBar), findsOneWidget);
    // 2026-08-13 롤백 사유의 수리 증명: 텍스트 RootHeader 는 이 탭에 없다.
    expect(find.byType(SoriStageRootHeader), findsNothing);
    // 프로필 진입은 톱바 아이콘으로 유지 (셸 테스트의 byTooltip 계약).
    expect(find.byTooltip('Profile'), findsOneWidget);
  });

  testWidgets('아침 9시 인사말이 헤더를 대신한다', (tester) async {
    await pumpToday(tester);

    final l10n = await AppL10n.delegate.load(const Locale('en'));
    expect(find.text(l10n.homeHeroGreetingMorning), findsOneWidget);
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
  stampCount: 4,
  xp: 320,
  streakDays: 6,
  todayReward: null,
);
