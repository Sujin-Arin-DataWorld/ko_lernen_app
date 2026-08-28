import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/settings_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_today_screen.dart';
import 'package:ko_lernen_app/screens/vocab_packs_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';
import 'package:ko_lernen_app/widgets/sori/window_class.dart';

/// 폰·태블릿·가로 화면 배치 골든.
///
/// `test/responsive_test.dart` 는 "예외가 안 난다 / 오버플로가 없다"만 본다.
/// 그건 **레이아웃이 조용히 망가지는 것**은 못 잡는다 — 카드가 화면 끝까지
/// 늘어나거나, 태블릿에서 컬럼이 폰 폭에 갇히거나, 가로에서 여백이 무너지는
/// 종류. 픽셀로 고정해야 잡힌다.
///
/// 3폭은 [AppWindowClass] 세 분류를 하나씩 대표한다:
/// - compact 360×800 — 일반 휴대폰
/// - medium 800×1280 — 작은 태블릿·폴더블 세로
/// - expanded 1280×800 — 태블릿 가로
///
/// ⚠️ **기준선은 Linux(CI) 정본이다.** `matchesGoldenFile` 의 기본
/// `LocalFileComparator` 는 허용오차 0이라 OS·Flutter 패치 버전이 다르면
/// 서브픽셀 AA 차이만으로 깨진다. 반드시 CI 와 같은 환경
/// (ubuntu + `.github/workflows/ci.yml` 의 `flutter-version` 핀)에서 만든다:
///   1. Actions → CI → "Run workflow" (workflow_dispatch)
///   2. `Regenerate goldens (manual)` 잡의 아티팩트 다운로드
///   3. `test/goldens/baselines/` 에 덮어쓰고 커밋
/// 기준이 없으면 스위트는 skip 된다(빨간 게이트 방지).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final baselines = Directory('test/goldens/baselines');
  final ready =
      autoUpdateGoldenFiles ||
      (baselines.existsSync() && baselines.listSync().isNotEmpty);

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

  group(
    '화면 배치 골든 (compact · medium · expanded)',
    // 기준선은 위 주석대로 Linux(CI) 정본이다. Windows/macOS 로컬에서는 서브
    // 픽셀 AA 차이만으로 반드시 깨지므로 픽셀 검증은 CI 에서만 한다.
    //
    // 예전 가드는 기준선 **유무**만 봤다. 기준선이 커밋된 뒤로는 Windows 에서도
    // 실행돼 로컬 `flutter test` 가 상시 빨간불이 됐고(2026-08-12 실측: 이 파일
    // 9건 + home_layout 2건 = 11건), 진짜 실패가 그 사이에 묻혔다.
    // design_components_golden_test.dart 는 이미 이 가드를 갖고 있었다.
    skip: !ready
        ? '기준 없음 — flutter test --update-goldens test/goldens 로 1회 생성'
        : (!autoUpdateGoldenFiles && !Platform.isLinux)
        ? 'golden 기준선은 Linux(CI) 정본 — 로컬(Windows/macOS)에선 skip'
        : null,
    () {
      // 골든은 유지비가 크다. 회귀가 실제로 아팠던 표면만 고정한다:
      // 설정(폼 폭) · 배우기 허브(모듈 카드) · 단어팩(그리드 열 수).
      //
      // ⚠️ `stats` 는 **의도적으로 뺐다.** `_StreakWeekHeatmap` 이
      // `DateTime.now().weekday` 로 "오늘" 칸에 금색 테두리를 그린다
      // (`stats_screen.dart` 의 `isToday`). 즉 렌더 결과가 **실행 요일마다
      // 달라져** 기준선을 만든 그 요일에만 통과한다 — 실측(2026-08-07):
      // 목요일에 만든 medium·expanded 기준선이 금요일에 깨졌고, 같은 날
      // 재생성한 compact 만 통과했다. 기준선을 다시 만들어도 다음 날 또 깨진다.
      //
      // 픽셀 고정이 필요하면 먼저 `_StreakWeekHeatmap` 에 시계 seam 을 주고
      // (예: `package:clock` 의 `clock.now()` + 테스트에서 `withClock`)
      // 그다음에 되살릴 것. 그때까지 통계 화면의 레이아웃 회귀는
      // `responsive_test`(폭 6종 × 글자 1.3배) ·
      // `responsive_short_height_test`(낮은 높이 6종) ·
      // `accessibility_guideline_test`(터치영역·대비·라벨)가 덮는다.
      final screens = <String, Widget Function()>{
        'settings': SettingsScreen.new,
        'vocab_packs': VocabPacksScreen.new,
        // §P3 (2026-08-14): Today 미션 카드 v2·한옥 배너·퀘스트 카드의 배치
        // 골든. 결정적 렌더를 위해 now/loadSnapshot 시임 주입 (1차 핸드오프
        // §3-4 픽스처 원칙 — sori_stage_today_matte_test 와 같은 스냅샷).
        'sori_today': () => SoriStageTodayScreen(
          loadSnapshot: () async => _todaySnapshot(),
          now: () => DateTime(2026, 8, 14, 9),
          forceStaticHero: true,
        ),
      };

      final viewports = <String, Size>{
        'compact': const Size(360, 800),
        'medium': const Size(800, 1280),
        'expanded': const Size(1280, 800),
      };

      for (final viewport in viewports.entries) {
        for (final screen in screens.entries) {
          testWidgets('${screen.key} @ ${viewport.key}', (tester) async {
            // 분류가 의도한 값인지 먼저 확인한다 — 뷰포트를 잘못 잡은 채
            // 픽셀만 비교하면 "태블릿 골든"이 실은 폰 골든일 수 있다.
            expect(
              windowClassFor(viewport.value.width),
              AppWindowClass.values.byName(viewport.key),
            );

            tester.view.physicalSize = viewport.value;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);

            await tester.pumpWidget(_wrap(screen.value()));
            await tester.pump();
            if (screen.key == 'vocab_packs') {
              await tester.runAsync(() async {
                final context = tester.element(find.byType(VocabPacksScreen));
                await precacheImage(
                  const AssetImage(
                    'assets/illustrations/hanok/study_classroom.png',
                  ),
                  context,
                );
              });
              await tester.pump();
              final context = tester.element(find.byType(VocabPacksScreen));
              // The hero preload above runs outside fake async. Pack artwork
              // can otherwise win or lose that same decode race, so compact
              // and medium capture a different subset of visible images.
              // Await every mounted Image provider before taking the golden.
              final imageProviders = tester
                  .widgetList<Image>(
                    find.descendant(
                      of: find.byType(VocabPacksScreen),
                      matching: find.byType(Image),
                    ),
                  )
                  .map((image) => image.image)
                  .toList(growable: false);
              expect(imageProviders, isNotEmpty);
              await tester.runAsync(() async {
                await Future.wait([
                  for (final provider in imageProviders)
                    precacheImage(
                      provider,
                      context,
                      // Pack artwork is optional by SoriIllustratedCard's
                      // contract. Let its errorBuilder settle on the fallback
                      // while still awaiting every bundled image decode.
                      onError: (_, _) {},
                    ),
                ]);
              });
              await tester.pump();
            }
            if (screen.key == 'sori_today') {
              await tester.runAsync(() async {
                final context = tester.element(
                  find.byType(SoriStageTodayScreen),
                );
                await Future.wait([
                  precacheImage(
                    const AssetImage(
                      'assets/illustrations/activities/srs.webp',
                    ),
                    context,
                  ),
                  precacheImage(
                    const AssetImage(
                      'assets/illustrations/mascot/tiger_front.png',
                    ),
                    context,
                  ),
                ]);
              });
              await tester.pump();
            }
            await tester.pump(const Duration(milliseconds: 100));
            await tester.pump(const Duration(milliseconds: 1200));

            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(
                'baselines/screen_${screen.key}_${viewport.key}.png',
              ),
            );

            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
          });
        }
      }
    },
  );
}

Widget _wrap(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('de'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  // Production installs this in MaterialApp.builder (`lib/main.dart`).
  // Without it, tablet goldens lock in "no comfort scaler" after #96.
  builder: (context, app) => SoriTypeScale(child: app!),
  home: child,
  onGenerateRoute: (settings) => null,
);

/// sori_today 골든 픽스처 — 미션 스테이지 일러스트·보자기·한옥 배너의
/// 결정적 레이아웃. 보상행과 퀘스트 진행 카드의 rich-state 계약은
/// `sori_stage_today_matte_test.dart`가 별도 픽스처로 검증한다.
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
