// 세로 채움 가드 — W10 T-V4(2026-09-05, Jin D-4 "text clusters at the top").
//
// `SoriStandardPage` 등 표준 프레임이 항상 `ListView` 라, 짧은 콘텐츠가 긴
// 뷰포트(태블릿·가로 폰)에서 화면 위쪽에만 뭉치고 아래가 텅 빈다. 이 테스트는
// 앱의 거의 모든 화면(반응형 매트릭스 38개 + 인자·페이크가 필요해 별도 등록한
// 화면 8개)을 두 개의 "긴" 뷰포트에서 렌더해, 실제 콘텐츠가 세로로 합리적인
// 비율을 채우는지(꽉 찬 스크롤 목록·중앙 정렬·또는 상단에서 15% 이상 내려간
// 위치 셋 중 하나)를 고정한다. **allowlist 없음** — 새 화면이 이 규칙을
// 어기면 여기서 바로 잡힌다.
//
// 실측(2026-09-05) 전: 접기 상태의 학습 경로(learning path)·오늘의 발음
// (pronunciation studio)·초성/음절 퍼즐(chosung, wordle, kkeunmari)·단어장
// 결과(vocab notebook result)·커스텀팩 퀴즈/매칭이 이 규칙을 어겨 RED
// 였다(T-V3 로 고쳤다). 재실측은 이 파일이 GREEN 인 상태 자체가 회귀
// 방지 증거다.
//
// W10 PR-D(2026-09-06): 아래 6건도 전부 GREEN 으로 고쳤다 — allowlist·
// 스킵 없이, 각 화면이 이미 갖고 있거나(또는 새로 뚫은) 로더 주입 구멍으로
// 실제 데이터를 즉시 반환하게 해 가드가 진짜 레이아웃을 판정하게 했다.
//   - `scenarios list`: 프로덕션 `ScenarioLoader.load()` 는 `compute()`
//     (isolate)로 파싱해 이 하네스에서 절대 안 돌아온다 — 기존
//     `ScenariosListScreen.loadScenarios` 구멍(다른 화면 테스트와 동일
//     패턴)으로 픽스처를 주입한다(`verticalFillGuardExtraScreens`).
//   - `app shell`/`home`: Today 탭 스냅샷 로더도 같은 부류(내부적으로
//     `compute()`류 의존)라 로딩 스피너에 멈춘다. `home`(`SoriStageTodayScreen
//     .loadSnapshot`)은 기존 구멍을 그대로 쓰고, `app shell`(`AppShell`)은
//     이 구멍이 없어 `AppShell.loadTodaySnapshot` → `SoriStageShell
//     .loadTodaySnapshot` → `SoriStageTodayScreen.loadSnapshot` 로 새로
//     뚫었다(`ListeningScreen.scenariosLoader`와 같은 패턴).
//   - `custom pack quiz`: 격리 실행은 항상 통과했지만 전체 스위트 안에서
//     코치마크(스포트라이트 오버레이) 스케줄링 타이밍에 따라 이따금
//     실패했다 — 레이아웃 결함이 아니라 이 가드와 무관한 코치 UX 잡음이라
//     `setUp`에서 화면별 코치마크를 전부 "이미 봄"으로 시작해 원천
//     차단한다(다른 화면 테스트가 이미 쓰는 `kl_tut_<id>` 패턴).
//   - `practice hub`: 접힌 상태가 진짜로 위쪽에 뭉쳤다(D-4 재현) —
//     `SoriStandardPage(fill: true, fillIntrinsic: false)`(W10 PR-D 파트 A
//     의 `SoriMinHeightScroll.intrinsic` 공용 레시피)로 `ModuleCard` 안의
//     `LayoutBuilder` 와 충돌 없이 채웠다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/card.dart';
import 'package:ko_lernen_app/widgets/sori/illustrated_card.dart';

import 'support/responsive_screens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_streak_days': 3,
      'kl_xp': 40,
      // W10 PR-D(2026-09-06): 화면별 코치마크(스포트라이트 오버레이)를 전부
      // "이미 봄"으로 시작한다 — 이 가드는 레이아웃 채움을 재는 것이지 코치
      // 오버레이 UX를 재는 게 아니다(그건 spotlight_coach_test.dart 등
      // 전용 스위트 몫이다). 코치가 열리면 pump 타이밍에 따라 오버레이가
      // 콘텐츠 위에 겹치거나 안 겹치는 게 갈려 `custom pack quiz` 처럼
      // 전체 스위트 안에서만 이따금 실패하는 레이스가 생겼다 — 화면별 세로
      // 채움 판정과 무관한 잡음이라 여기서 원천 차단한다.
      for (final id in Storage.kScreenCoachIds) 'kl_tut_$id': true,
      'kl_tut_book': true,
      'kl_tut_vocab_pack': true,
      'kl_tut_pack_quiz': true,
      'kl_tut_pack_boss': true,
      'kl_tut_home_tour': true,
      'kl_tut_wordbook': true,
    });
    await Storage.init();
    DataLoader.reset();
    ScenarioLoader.reset();
    // 단어장/커스텀팩 가드 화면이 packId 로 조회하는 고정 팩 — 이 화면들만
    // 쓰지만, 매 테스트에서 저렴하게 등록해 둬도 다른 화면에는 무해하다.
    await CustomPackService.save(
      CustomPack.manual(
        id: verticalFillGuardPackId,
        name: 'W10 세로 채움 가드',
        words: verticalFillGuardWords,
      ),
    );
  });

  const viewports = <Size>[Size(430, 932), Size(800, 1280)];

  final surfaces = <String, Widget>{
    ...responsiveScreens(),
    ...verticalFillGuardExtraScreens(),
  };

  for (final viewport in viewports) {
    for (final entry in surfaces.entries) {
      testWidgets(
        '${entry.key} @ ${viewport.width.toInt()}x${viewport.height.toInt()} '
        '세로 채움',
        (tester) async {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(wrapResponsive(entry.value));
          // 무한 반복 애니메이션(SoriPulse 등)이 있을 수 있어 pumpAndSettle
          // 대신 유한 pump 만 쓴다(test/support/sori_stage_pump.dart 와 같은
          // 이유) — responsive_test.dart 가 이미 이 시퀀스로 같은 화면들의
          // 비동기 로드(시나리오·due 카운트 등)를 안정적으로 해소한다.
          await tester.pump();
          // `rootBundle.loadString` 같은 실제 자산 I/O(예: satz arcade의
          // 문장 데이터)는 순수 `pump(Duration)` 만으로는 절대 안 끝난다
          // (FakeAsync 존은 실제 IO를 진행시키지 않는다) — `runAsync` 로
          // 실제 이벤트 루프를 여러 번 돌려 자산 I/O가 끝날 시간을 준다.
          // ⚠️ `pumpWidget` 자체를 runAsync 로 감싸 실제 시간을 더 길게
          // 주는 방식(또는 예산을 크게 늘리는 방식)도 시도했지만, 오디오
          // 관련 실제 타이머가 그 사이에 발화해 mock 되지 않은 플랫폼
          // 채널(MissingPluginException, 예: audioplayers)을 건드리는
          // 새로운 거짓 RED를 만들었다(2026-09-05 실측: home). 그래서 짧은
          // 지연 몇 번으로 예산을 제한한다 — `compute()`(isolate)로
          // 파싱하는 scenarios list 는 이 예산 안에서 못 끝나 RED로
          // 남는다(테스트 환경 한계, UI 결함 아님 — REPORT 참고).
          for (var i = 0; i < 3; i++) {
            await tester.runAsync(() async {
              await Future<void>.delayed(const Duration(milliseconds: 100));
            });
            await tester.pump();
          }
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pump(const Duration(milliseconds: 1200));

          expect(
            tester.takeException(),
            isNull,
            reason: '${entry.key} render exception',
          );

          final bodyRect = _findBodyRect(tester);
          if (bodyRect == null) {
            fail('${entry.key}: Scaffold를 찾지 못했다 — 가드 대상이 아니다.');
          }

          final content = _findContentRect(tester, bodyRect);
          if (content == null) {
            fail(
              '${entry.key} @ ${viewport.width.toInt()}x${viewport.height.toInt()}: '
              'body 안에서 Text/SoriCard/SoriButton/Image/SoriIllustratedCard '
              '를 하나도 못 찾았다.',
            );
          }

          final passLong = content.height >= bodyRect.height * 0.9;
          final passBottom =
              content.bottom >= bodyRect.top + bodyRect.height * 0.55;
          final passCentered =
              content.top >= bodyRect.top + bodyRect.height * 0.15;
          final passed = passLong || passBottom || passCentered;

          final topPct = ((content.top - bodyRect.top) / bodyRect.height * 100)
              .toStringAsFixed(1);
          final bottomPct =
              ((content.bottom - bodyRect.top) / bodyRect.height * 100)
                  .toStringAsFixed(1);

          expect(
            passed,
            isTrue,
            reason:
                '${entry.key} @ ${viewport.width.toInt()}x${viewport.height.toInt()}: '
                '콘텐츠가 위쪽에 뭉쳤다 — top=$topPct% bottom=$bottomPct% '
                '(bodyRect.height=${bodyRect.height.toStringAsFixed(1)}, '
                'content.height=${content.height.toStringAsFixed(1)}). '
                '기준: content.height>=90% 또는 bottom>=55% 또는 top>=15%.',
          );

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        },
      );
    }
  }
}

/// Scaffold의 `body` 위젯 하나(AppBar/SafeArea 위 크롬 제외)의 화면 좌표
/// Rect. `body` 위젯 인스턴스로 직접 [find.byWidget] 해서 AppBar 안의
/// 텍스트·버튼이 섞여 들어오지 않게 한다.
Rect? _findBodyRect(WidgetTester tester) {
  final scaffolds = find.byType(Scaffold);
  if (scaffolds.evaluate().isEmpty) {
    return null;
  }
  final scaffoldFinder = scaffolds.first;
  final scaffold = tester.widget<Scaffold>(scaffoldFinder);
  final body = scaffold.body;
  if (body != null) {
    final bodyFinder = find.byWidget(body);
    if (bodyFinder.evaluate().isNotEmpty) {
      return tester.getRect(bodyFinder);
    }
  }
  return tester.getRect(scaffoldFinder);
}

/// [bodyRect]의 세로 구간과 겹치는 Text/SoriCard/SoriButton/Image/
/// SoriIllustratedCard 전부의 합집합 Rect. AppBar·bottomNavigationBar 처럼
/// body 세로 구간 밖에 있는 크롬은 자연히 걸러진다(겹치지 않으므로).
Rect? _findContentRect(WidgetTester tester, Rect bodyRect) {
  Rect? union;
  for (final type in const [
    Text,
    SoriCard,
    SoriButton,
    Image,
    SoriIllustratedCard,
  ]) {
    for (final element in find.byType(type).evaluate()) {
      final renderObject = element.renderObject;
      if (renderObject is! RenderBox || !renderObject.hasSize) {
        continue;
      }
      final size = renderObject.size;
      if (size.width <= 0 || size.height <= 0) {
        continue;
      }
      final Offset topLeft;
      try {
        topLeft = renderObject.localToGlobal(Offset.zero);
      } catch (_) {
        continue; // 아직 트리에 attach되지 않은 렌더 오브젝트 보호.
      }
      final rect = topLeft & size;
      if (rect.bottom <= bodyRect.top || rect.top >= bodyRect.bottom) {
        continue; // body 세로 구간 밖(AppBar·bottomNavigationBar 등).
      }
      union = union == null ? rect : union.expandToInclude(rect);
    }
  }
  return union;
}
