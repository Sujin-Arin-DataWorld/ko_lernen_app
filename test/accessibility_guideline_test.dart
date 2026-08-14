import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/consent_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_level_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_start_screen.dart';
import 'package:ko_lernen_app/screens/practice_hub_screen.dart';
import 'package:ko_lernen_app/screens/settings_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_today_screen.dart';
import 'package:ko_lernen_app/screens/stats_screen.dart';
import 'package:ko_lernen_app/screens/vocab_packs_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';

/// Flutter 공식 접근성 가이드라인 자동 검사.
///
/// 수동 검사만으로는 부족하다 — 화면이 늘어나면 사람이 전수로 볼 수 없고,
/// 회귀는 조용히 들어온다. 여기서 기계가 볼 수 있는 네 가지를 고정한다:
///
/// - [androidTapTargetGuideline] — 최소 48×48 터치 영역
/// - [iOSTapTargetGuideline] — 최소 44×44 터치 영역
/// - [textContrastGuideline] — WCAG AA 텍스트 대비
/// - [labeledTapTargetGuideline] — 누를 수 있는 것에 라벨이 있는지(TalkBack/VoiceOver)
///
/// ⚠️ 이 테스트가 **실기기 검사를 대체하지 않는다.** TalkBack·VoiceOver 낭독
/// 순서, 초점 이동, 색상 반전, Reduce Motion 은 여전히 사람이 봐야 한다
/// (`docs/store/RELEASE_QA_CHECKLIST.md` §5).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_streak_days': 3,
      'kl_xp': 40,
    });
    await Storage.init();
    DataLoader.reset();
    ScenarioLoader.reset();
  });

  /// 진입 빈도가 높고 상호작용이 밀집한 화면들.
  final screens = <String, Widget Function()>{
    'settings': SettingsScreen.new,
    'practice hub': PracticeHubScreen.new,
    'vocab packs': VocabPacksScreen.new,
    'stats': StatsScreen.new,
    'consent': ConsentScreen.new,
    // §G (2026-08-14): 온보딩 진입 2화면 — 설문 옵션·레벨 사다리가 터치 밀집.
    'onboarding start': OnboardingStartScreen.new,
    'onboarding level': OnboardingLevelScreen.new,
    // §D (2026-08-14): 기본 셸의 첫 화면 — 미션 스테이지·보자기·한옥 진행이
    // 상호작용 밀집 구간이라 매트릭스에 상주시킨다. 픽스처 주입으로
    // Storage/실시간 시각에 묶이지 않는다.
    'sori today': () => SoriStageTodayScreen(
      loadSnapshot: () async => _todaySnapshot(),
      now: () => DateTime(2026, 8, 14, 9),
    ),
  };

  Future<SemanticsHandle> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    Size size = const Size(360, 800),
    double textScale = 1.0,
  }) async {
    final handle = tester.ensureSemantics();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(screen, textScale: textScale));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 1200));
    return handle;
  }

  group('터치 영역 크기', () {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} — Android 48dp / iOS 44dp', (tester) async {
        final handle = await pumpScreen(tester, entry.value());
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        handle.dispose();
      });
    }
  });

  group('텍스트 대비 (WCAG AA)', () {
    for (final entry in screens.entries) {
      testWidgets(entry.key, (tester) async {
        final handle = await pumpScreen(tester, entry.value());
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  });

  group('스크린리더 라벨', () {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} — 누를 수 있는 요소에 라벨이 있다', (tester) async {
        final handle = await pumpScreen(tester, entry.value());
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  });

  group('시스템 글자 확대 1.3배에서도 터치 영역이 유지된다', () {
    // 글자가 커지면서 버튼이 밀려 잘리거나, 고정 height 때문에 텍스트만 커지고
    // 터치 영역은 그대로인 경우를 잡는다.
    for (final entry in screens.entries) {
      testWidgets(entry.key, (tester) async {
        final handle = await pumpScreen(tester, entry.value(), textScale: 1.3);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        handle.dispose();
      });
    }
  });

  group('태블릿 폭에서도 같은 기준을 만족한다', () {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} @ 800×1280', (tester) async {
        final handle = await pumpScreen(
          tester,
          entry.value(),
          size: const Size(800, 1280),
        );
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  });
}

Widget _wrap(Widget child, {double textScale = 1.0}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('de'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: textScale == 1.0
      ? child
      : MediaQuery.withClampedTextScaling(
          minScaleFactor: textScale,
          maxScaleFactor: textScale,
          child: child,
        ),
  onGenerateRoute: (settings) => null,
);

/// sori today 픽스처 — 미션 스테이지(보상행 포함)·보자기 배너·한옥 진행이
/// 모두 그려지는 상태 (sori_stage_today_matte_test.dart 미러).
SoriStageProgressionSnapshot _todaySnapshot() => SoriStageProgressionSnapshot(
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
