// 낮은 높이(가로로 든 폰 · 분할 화면) 반응형 회귀 + 상태 변형 매트릭스.
//
// **왜 `responsive_test.dart` 와 파일이 갈렸나.** 축이 다르다 — 저쪽은 폭
// (308–1280dp), 여기는 높이와 상태 변형이다. 원본 파일은 이미 386 케이스라
// 여기까지 합치면 한 파일이 읽기 어려워진다. 성능·러너 제약 때문이 **아니다**.
//
// ⚠️ 처음엔 "한 파일에 무거운 pump 를 많이 쌓으면 러너가 hang 한다"고 봤지만
// **틀린 진단이었다.** 진짜 원인은 pump 횟수와 무관한 `rootBundle` 의 Future
// 캐시 오염이었다 — 상태 변형 그룹 `setUp` 의 `rootBundle.clear()` 주석에 전말을
// 적어 뒀다. 그걸 고치자 154 케이스가 16초에 끝난다(직전엔 10분 타임아웃).
// 따라서 "파일당 pump 상한" 같은 규칙은 두지 않는다 — 근거가 없다.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/screens/grammar_screen.dart';
import 'package:ko_lernen_app/screens/smalltalk_screen.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';
import 'package:ko_lernen_app/services/smalltalk_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

import 'support/responsive_screens.dart';

/// 상태 변형이 도는 뷰포트 — 낮은 높이 4종 + 폰/태블릿 기준 2종.
const _variantViewports = <Size>[
  ..._shortViewports,
  Size(360, 900), // 세로 폰 기준선
  Size(800, 1280), // 세로 태블릿 기준선
];

/// 세로가 짧은 뷰포트. 실제로 존재하는 상태만 넣는다.
///
/// 앞의 4종은 이 브랜치가 넣은 것이고, 뒤의 2종은 PR #6 이 `responsive_test`
/// 에 넣었던 것을 여기로 합친 것이다 — 짧은 높이 커버리지는 한 파일에 모은다.
const _shortViewports = <Size>[
  Size(360, 400), // 세로 분할 화면 (좁고 짧음)
  Size(800, 360), // 가로 폰
  Size(800, 600), // 작은 가로 창 / flutter 기본 뷰포트
  Size(1280, 500), // 가로 태블릿 분할
  Size(740, 360), // 폰 가로모드 (PR #6)
  Size(640, 480), // 좁고 짧은 분할화면 (PR #6)
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── 낮은 높이: 가로 폰 · 분할 화면 ──────────────────────────────────────
  // `responsive_test.dart` 의 매트릭스는 **폭**만 308–1280dp 로 훑고 높이는
  // 900/1280/800 뿐이라, 가로로 든 폰이나 분할 화면처럼 **세로가 짧은** 상태를
  // 어느 테스트도 보지 않았다. 실제로 그 구멍에서 오버플로가 살아 있었다.
  //
  // 짧은 높이가 특히 위험한 이유: 화면 상단 헤더와 하단 액션 블록은 대개
  // **고정 높이**라 뷰포트가 짧아져도 줄지 않는다. 가운데를 `Expanded` 로 준
  // 화면은 그 가운데가 0까지 줄어도 고정 블록의 합이 뷰포트를 넘으면 넘친다.
  group('낮은 높이 반응형 (가로 폰 · 분할 화면)', () {
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

    final screens = responsiveScreens();

    for (final size in _shortViewports) {
      for (final entry in screens.entries) {
        testWidgets(
          '${entry.key} @ ${size.width.toInt()}x${size.height.toInt()} 낮은 높이 오버플로 없음',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);

            await tester.pumpWidget(wrapResponsive(entry.value));
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
  });

  // 짧은 뷰포트 × 시스템 글자 1.3배 — 둘이 겹치는 최악 조합.
  // (PR #6 이 `responsive_test` 에 넣었던 검사를 여기로 옮겼다.)
  group('낮은 높이 × 글자 1.3배', () {
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

    final screens = responsiveScreens();

    for (final entry in screens.entries) {
      testWidgets('${entry.key} @ 800x600 ×1.3 글씨 오버플로 없음', (tester) async {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(wrapResponsive(entry.value, textScale: 1.3));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 1200));

        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      });
    }
  });

  // ── 상태 변형: 같은 화면, 인자에 따라 달라지는 렌더 구조 ─────────────────
  //
  // 위 매트릭스의 화면 목록은 **무인자 생성자만** 담는다. 그래서 같은 Screen
  // 이라도 인자로 레이아웃이 달라지는 변형(코스 모드·팩 인자)은 어떤 폭·높이
  // 에서도 검사되지 않았다. 실제로 `GrammarScreen(courseContext: …)` 는
  // 800×600 에서 넘쳤는데 무인자 `GrammarScreen()` 은 같은 폭에서 멀쩡했다.
  //
  // 기준은 "생성자에 인자가 있느냐" 가 아니라 **"그 인자가 렌더 구조를
  // 바꾸느냐"** 다. 코스 모드는 체크포인트 헤더와 다른 액션 바를 얹고, 팩
  // 화면은 학습 카드·스테이지 바를 얹는다 — 둘 다 구조가 달라진다.
  group('상태 변형 반응형 (인자가 렌더 구조를 바꾸는 화면)', () {
    setUp(() async {
      // ⚠️ 이게 없으면 이 그룹이 **영원히 멈춘다**(2026-08-07 실측: 10분 타임아웃
      // → 다음 테스트는 "Reentrant call to runAsync() denied").
      //
      // `rootBundle` 은 `CachingAssetBundle` 이라 **키마다 Future 자체를**
      // 캐시한다. 위 낮은 높이 그룹이 `cloze`·`satz arcade`·`learning path`
      // 같은 화면을 pump 하면 그 화면들이 fake-async 존 안에서
      // `rootBundle.loadString(...)` 을 걸고, 테스트가 끝날 때 그 Future 는
      // **미완료 상태로 캐시에 남는다**. 그 다음 `tester.runAsync` 로 같은 키를
      // 불러도 죽은 Future 를 돌려받아 `CurriculumCatalog.load()` 가 끝나지 않는다.
      //
      // 캐시를 비우면 `runAsync` 안에서 실제 로드가 새로 일어난다.
      rootBundle.clear();
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
    /// 비동기다 — 그래서 이 그룹은 화면 맵이 아니라 빌더를 쓴다.
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

    // 변형마다 뷰포트 목록을 따로 들고 있지만 지금은 전부 [_variantViewports]
    // 다 — hang 의 진짜 원인을 잡은 뒤로 조합을 줄일 이유가 없어졌다. 목록을
    // 변형별로 남겨 둔 건, 특정 변형만 뷰포트를 넓히거나 좁힐 때 다른 변형을
    // 건드리지 않게 하기 위해서다.
    //
    // `grammar (course mode) @ 800×600` 은 CI 가 실제로 잡았던 회귀 지점이다
    // — 어떤 축소를 하더라도 **이 조합은 빼지 않는다**.
    final variants =
        <
          ({
            String name,
            List<Size> viewports,
            Future<Widget> Function(WidgetTester) build,
          })
        >[
          (
            name: 'grammar (course mode)',
            viewports: _variantViewports,
            build: (tester) async => GrammarScreen(
              courseContext: await courseContext(
                tester,
                kind: CurriculumContentKind.grammar,
                unitId: 'a1_03_topic_subject_particles',
              ),
            ),
          ),
          (
            name: 'smalltalk (course mode)',
            viewports: _variantViewports,
            build: (tester) async => SmalltalkScreen(
              courseContext: await courseContext(
                tester,
                kind: CurriculumContentKind.smalltalk,
                unitId: 'a2_02_plans_proposals',
              ),
            ),
          ),
          // pack 인자로 열리는 학습 화면 — 무인자가 아니라 매트릭스에 없었다.
          (
            name: 'vocab pack (pack arg)',
            viewports: _variantViewports,
            build: (tester) async =>
                const VocabPackScreen(packId: 'a1_greetings_1'),
          ),
        ];

    for (final variant in variants) {
      for (final size in variant.viewports) {
        testWidgets(
          '${variant.name} @ ${size.width.toInt()}x${size.height.toInt()} 오버플로 없음',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);

            final screen = await variant.build(tester);
            await tester.pumpWidget(wrapResponsive(screen));
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
