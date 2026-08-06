import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/personal_room.dart';
import 'package:ko_lernen_app/screens/app_shell.dart';
import 'package:ko_lernen_app/screens/home_screen.dart';
import 'package:ko_lernen_app/screens/hanok_world_screen.dart';
import 'package:ko_lernen_app/screens/learn_hub_screen.dart';
import 'package:ko_lernen_app/screens/practice_hub_screen.dart';
import 'package:ko_lernen_app/screens/personal_room_furnish_screen.dart';
import 'package:ko_lernen_app/screens/sarangbang_furnish_screen.dart';
import 'package:ko_lernen_app/screens/sarangbang_screen.dart';
import 'package:ko_lernen_app/screens/wordbook_hub_screen.dart';
import 'package:ko_lernen_app/screens/scenarios_list_screen.dart';
import 'package:ko_lernen_app/screens/settings_screen.dart';
import 'package:ko_lernen_app/screens/stats_screen.dart';
import 'package:ko_lernen_app/screens/vocab_packs_screen.dart';
import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/screens/grammar_screen.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/smalltalk_loader.dart';
import 'package:ko_lernen_app/screens/hangul_screen.dart';
import 'package:ko_lernen_app/screens/wordle_screen.dart';
import 'package:ko_lernen_app/screens/kkeunmari_screen.dart';
import 'package:ko_lernen_app/screens/dojangcheop_screen.dart';
import 'package:ko_lernen_app/screens/listening_screen.dart';
import 'package:ko_lernen_app/screens/hard_words_screen.dart';
import 'package:ko_lernen_app/screens/legacy_vocab_screen.dart';
import 'package:ko_lernen_app/screens/consent_screen.dart';
import 'package:ko_lernen_app/screens/paywall_screen.dart';
import 'package:ko_lernen_app/screens/chosung_quiz_screen.dart';
import 'package:ko_lernen_app/screens/cloze_game_screen.dart';
import 'package:ko_lernen_app/screens/speed_match_screen.dart';
import 'package:ko_lernen_app/screens/daily_challenge_screen.dart';
import 'package:ko_lernen_app/screens/satz_arcade_screen.dart';
import 'package:ko_lernen_app/screens/learning_path_screen.dart';
import 'package:ko_lernen_app/screens/gye_tab_screen.dart';
import 'package:ko_lernen_app/screens/quests_screen.dart';
import 'package:ko_lernen_app/screens/smalltalk_screen.dart';
import 'package:ko_lernen_app/screens/review_session_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/responsive.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── 1. 순수 함수: 클램프 padding 수학 ──────────────────────────────────
  group('soriClampPadding', () {
    test('폭 ≤ maxWidth → base 그대로 (extra 0, 폰 무변화)', () {
      final p = soriClampPadding(
        360,
        maxWidth: 480,
        base: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      );
      expect(p.left, 16);
      expect(p.right, 16);
      expect(p.top, 4); // 상하 보존
      expect(p.bottom, 24);
    });

    test('정확히 maxWidth → extra 0', () {
      final p = soriClampPadding(
        480,
        maxWidth: 480,
        base: const EdgeInsets.symmetric(horizontal: 16),
      );
      expect(p.left, 16);
      expect(p.right, 16);
    });

    test('넓은 폭 → 잉여폭을 좌우로 균등 분배', () {
      final p = soriClampPadding(
        1200,
        maxWidth: 480,
        base: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      );
      expect(p.left, 16 + 360); // (1200 - 480) / 2 = 360
      expect(p.right, 16 + 360);
      expect(p.top, 8);
      expect(p.bottom, 24);
    });

    test('기본값: content breakpoint(480) + Spacing.lg base', () {
      final p = soriClampPadding(SoriBreakpoints.content);
      expect(p.left, Spacing.lg);
      expect(p.right, Spacing.lg);
    });

    test('grid breakpoint(600) override', () {
      final p = soriClampPadding(
        SoriBreakpoints.grid + 200,
        maxWidth: SoriBreakpoints.grid,
        base: const EdgeInsets.symmetric(horizontal: 12),
      );
      expect(p.left, 12 + 100); // 200 / 2
      expect(p.right, 12 + 100);
    });
  });

  // ── 2. SoriContentClamp 위젯: LayoutBuilder 폭 와이어링 ────────────────
  group('SoriContentClamp', () {
    testWidgets('가용 폭에 따라 padding 클램프', (tester) async {
      tester.view.physicalSize = const Size(1000, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late EdgeInsets captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoriContentClamp(
              base: const EdgeInsets.symmetric(horizontal: 16),
              builder: (_, p) {
                captured = p;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );

      expect(captured.left, 16 + 180); // (1000 - 640) / 2 = 180
      expect(captured.right, 16 + 180);
    });
  });

  // ── 2b. soriGridColumns: 반응형 grid 컬럼 수 ──────────────────────────
  group('soriGridColumns', () {
    test('폰 360px → min 보존 (회귀 0)', () {
      expect(soriGridColumns(360, target: 110, min: 3, max: 6), 3);
    });
    test('태블릿 768px → 확장', () {
      expect(soriGridColumns(768, target: 110, min: 3, max: 6), greaterThan(3));
    });
    test('아주 넓은 폭 → max 상한 클램프', () {
      expect(soriGridColumns(3000, target: 110, min: 3, max: 6), 6);
    });
    test('좁은 폭도 min 밑으로 안 내려감', () {
      expect(soriGridColumns(200, target: 150, min: 2, max: 6), 2);
    });
  });

  // ── 2c. SoriCenterClamp: 비스크롤 중앙 클램프 위젯 ────────────────────
  group('SoriCenterClamp', () {
    testWidgets('넓은 폭 → maxWidth(480)로 제한', (tester) async {
      tester.view.physicalSize = const Size(1000, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoriCenterClamp(
              child: const SizedBox.expand(
                child: ColoredBox(key: Key('c'), color: Color(0xFF000000)),
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const Key('c'))).width, 480);
    });

    testWidgets('폰 폭(360) → 그대로 통과 (회귀 0)', (tester) async {
      tester.view.physicalSize = const Size(360, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoriCenterClamp(
              child: const SizedBox.expand(
                child: ColoredBox(key: Key('c'), color: Color(0xFF000000)),
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const Key('c'))).width, 360);
    });
  });

  // ── 3. 화면 렌더: 다중 폭에서 오버플로 0 ───────────────────────────────
  group('반응형 화면 다중 폭 렌더', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'kl_user_level': 'a1',
        'kl_streak_days': 3,
        'kl_xp': 40,
      });
      await Storage.init();
      DataLoader.reset();
      ScenarioLoader.reset();
    });

    final screens = <String, Widget>{
      'app shell': const AppShell(),
      'home': const HomeScreen(),
      'personal hanok world': const HanokWorldScreen(),
      'learn hub': const LearnHubScreen(),
      'practice hub': const PracticeHubScreen(),
      'sarangbang study': const SarangbangStudyScreen(),
      'sarangbang furnish': const SarangbangFurnishScreen(),
      'anbang furnish': const PersonalRoomFurnishScreen(
        surface: PersonalRoomSurface.anbang,
      ),
      'daecheong furnish': const PersonalRoomFurnishScreen(
        surface: PersonalRoomSurface.daecheongmaru,
      ),
      'wordbook hub': const WordbookHubScreen(),
      'scenarios list': const ScenariosListScreen(),
      'settings': const SettingsScreen(),
      'stats': const StatsScreen(),
      'vocab packs': const VocabPacksScreen(),
      // 반응형 전파 + 핫스팟 동적화 화면 (무인자만)
      'grammar': const GrammarScreen(),
      'hangul': const HangulScreen(),
      'wordle': const WordleScreen(),
      'kkeunmari': const KkeunmariScreen(),
      'dojangcheop': const DojangcheopScreen(),
      'listening': const ListeningScreen(),
      'hard words': const HardWordsScreen(),
      'legacy vocab': const LegacyVocabScreen(),
      'consent': const ConsentScreen(),
      'paywall': const PaywallScreen(),
      'chosung': const ChosungQuizScreen(),
      'cloze': const ClozeGameScreen(),
      'speed match': const SpeedMatchScreen(),
      'daily challenge': const DailyChallengeScreen(),
      'satz arcade': const SatzArcadeScreen(),
      'learning path': const LearningPathScreen(),
      // D5 신규 커버 (D4에서 변경된 미커버 화면, 무인자만).
      'gye tab': const GyeTabScreen(),
      'quests': const QuestsScreen(),
      'smalltalk': const SmalltalkScreen(),
      'review': const ReviewSessionScreen(),
    };

    for (final width in <double>[308, 360, 600, 720, 800, 1280]) {
      for (final entry in screens.entries) {
        testWidgets('${entry.key} @ ${width.toInt()}px 오버플로 없음', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(_wrap(entry.value));
          await tester.pump(); // 첫 프레임 (로딩 상태)
          // 비동기 로드(시나리오·due 카운트) 해소 → Today 카드 등 실데이터 상태 렌더.
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pump(const Duration(milliseconds: 1200));

          expect(tester.takeException(), isNull);

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        });
      }
    }

    // 접근성 큰 글씨(시스템 텍스트 스케일 1.3×) — 좁은 폰에서 오버플로 0.
    // WCAG 1.4.4 / Jin 실기기 "잘림" 계열 회귀 방어.
    for (final size in <Size>[const Size(800, 1280), const Size(1280, 800)]) {
      for (final entry in screens.entries) {
        testWidgets(
          '${entry.key} @ ${size.width.toInt()}x${size.height.toInt()} tablet has no exceptions',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);

            await tester.pumpWidget(_wrap(entry.value));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 100));
            await tester.pump(const Duration(milliseconds: 1200));

            expect(tester.takeException(), isNull);

            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
          },
        );
      }
    }

    // ── 낮은 높이: 가로 폰 · 분할 화면 ────────────────────────────────
    // 이 위의 매트릭스는 **폭**만 308–1280dp 로 훑고 높이는 900/1280/800 뿐이라,
    // 가로로 든 폰이나 분할 화면처럼 **세로가 짧은** 상태를 어느 테스트도 보지
    // 않았다. 실제로 그 구멍에서 오버플로가 살아 있었다(2026-08-06).
    //
    // 짧은 높이가 특히 위험한 이유: 화면 상단 헤더와 하단 액션 블록은 대개
    // **고정 높이**라 뷰포트가 짧아져도 줄지 않는다. 가운데를 `Expanded` 로
    // 준 화면은 그 가운데가 0까지 줄어도 고정 블록의 합이 뷰포트를 넘으면
    // 그대로 넘친다.
    for (final size in <Size>[
      const Size(360, 400), // 세로 분할 화면 (좁고 짧음)
      const Size(800, 360), // 가로 폰
      const Size(800, 600), // 작은 가로 / flutter 기본 뷰포트
      const Size(1280, 500), // 가로 태블릿 분할
    ]) {
      for (final entry in screens.entries) {
        testWidgets(
          '${entry.key} @ ${size.width.toInt()}x${size.height.toInt()} 낮은 높이 오버플로 없음',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);

            await tester.pumpWidget(_wrap(entry.value));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 100));
            await tester.pump(const Duration(milliseconds: 1200));

            expect(tester.takeException(), isNull);

            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
          },
        );
      }
    }

    for (final size in <Size>[
      const Size(360, 900),
      const Size(800, 900),
      const Size(1280, 800),
    ]) {
      final width = size.width;
      for (final entry in screens.entries) {
        testWidgets('${entry.key} @ ${width.toInt()}px ×1.3 글씨 오버플로 없음', (
          tester,
        ) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(_wrap(entry.value, textScale: 1.3));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pump(const Duration(milliseconds: 1200));

          expect(tester.takeException(), isNull);

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        });
      }
    }
  });

  // ── 상태 변형: 같은 화면, 인자에 따라 달라지는 렌더 구조 ─────────────────
  //
  // 위 매트릭스의 `screens` 맵은 **무인자 생성자만** 담는다. 그래서 같은
  // Screen 이라도 인자로 레이아웃이 달라지는 변형(코스 모드·팩 인자)은 어떤
  // 폭·높이에서도 검사되지 않았다. 실제로 `GrammarScreen(courseContext: …)`
  // 는 800×600 에서 넘치는데 무인자 `GrammarScreen()` 은 같은 폭에서 멀쩡하다.
  //
  // 기준은 "생성자에 인자가 있느냐" 가 아니라 **"그 인자가 렌더 구조를
  // 바꾸느냐"** 다. 코스 모드는 체크포인트 헤더와 다른 액션 바를 얹고,
  // 팩 화면은 학습 카드·스테이지 바를 얹는다 — 둘 다 구조가 달라진다.
  group('상태 변형 반응형 (인자가 렌더 구조를 바꾸는 화면)', () {
    setUp(() async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        'kl_user_level': 'a1',
        'kl_streak_days': 3,
        'kl_xp': 40,
        // 코스 화면의 첫 실행 코치마크가 레이아웃을 덮지 않게 한다.
        'kl_tut_grammar': true,
        'kl_tut_smalltalk': true,
      });
      await Storage.init();
      DataLoader.reset();
      ScenarioLoader.reset();
      SmalltalkLoader.reset();
      CurriculumCatalog.reset();
    });

    /// 코스 미션이 연 학습 화면의 문맥. 카탈로그 로드가 필요해 화면 생성이
    /// 비동기다 — 그래서 이 그룹은 `screens` 맵이 아니라 빌더를 쓴다.
    Future<CoursePracticeContext> courseContext(
      WidgetTester tester, {
      required CurriculumContentKind kind,
      required String unitId,
    }) async {
      final catalog = (await tester.runAsync(CurriculumCatalog.load))!;
      final link = catalog.contentLinks.firstWhere(
        (item) =>
            item.contentKind == kind &&
            item.courseUnitId == unitId &&
            item.role == ContentLinkRole.assess,
      );
      return CoursePracticeContext.fromLink(link);
    }

    final variants = <String, Future<Widget> Function(WidgetTester)>{
      'grammar (course mode)': (tester) async => GrammarScreen(
        courseContext: await courseContext(
          tester,
          kind: CurriculumContentKind.grammar,
          unitId: 'a1_03_topic_subject_particles',
        ),
      ),
      'smalltalk (course mode)': (tester) async => SmalltalkScreen(
        courseContext: await courseContext(
          tester,
          kind: CurriculumContentKind.smalltalk,
          unitId: 'a2_02_plans_proposals',
        ),
      ),
      // pack 인자로 열리는 학습 화면 — 무인자가 아니라 매트릭스에 없었다.
      'vocab pack (pack arg)': (tester) async =>
          const VocabPackScreen(packId: 'a1_greetings_1'),
    };

    // 낮은 높이 4조건 + 폰/태블릿 기준 2조건.
    for (final size in <Size>[
      const Size(360, 400),
      const Size(800, 360),
      const Size(800, 600),
      const Size(1280, 500),
      const Size(360, 900),
      const Size(800, 1280),
    ]) {
      for (final entry in variants.entries) {
        testWidgets(
          '${entry.key} @ ${size.width.toInt()}x${size.height.toInt()} 오버플로 없음',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);

            final screen = await entry.value(tester);
            await tester.pumpWidget(_wrap(screen));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 100));
            await tester.pump(const Duration(milliseconds: 1200));

            expect(tester.takeException(), isNull);

            // 코스 화면은 TTS·진입 애니메이션 타이머를 들고 있어 명시적 해제가
            // 필요하다(다음 테스트로 새지 않게).
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump(const Duration(seconds: 1));
          },
        );
      }
    }
  });
}

Widget _wrap(Widget child, {double textScale = 1.0}) {
  return MaterialApp(
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
}
