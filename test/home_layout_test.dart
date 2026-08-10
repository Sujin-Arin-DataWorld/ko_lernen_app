import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/hanok_build_narrative.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/screens/home_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/character_clip.dart';
import 'package:ko_lernen_app/widgets/sori/mission_hero_card.dart';
import 'package:ko_lernen_app/widgets/sori/personal_hanok_map.dart';
import 'package:ko_lernen_app/widgets/sori/hanok_build_narrative_line.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

/// 2026-08-07 태블릿 홈 — **폰 레이아웃을 가운데 세워 둔 것**이 문제였다.
///
/// 실측(변경 전): 콘텐츠 컬럼이 640dp 에서 완전히 멈춰 1280dp 화면의 **52.5%**
/// 가 빈 여백이고, 폭이 아무리 늘어도 세로 스크롤은 ~1540dp 로 고정이었다.
/// 한옥 블록 하나가 559dp(미션 카드의 2.9배)로 홈에서 가장 큰 요소였다.
///
/// 그래서 expanded 에서 2열로 간다. 이 파일이 고정하는 것은 **전환 기준**이다 —
/// 화면 폭이 아니라 실제 콘텐츠 영역 폭. 홈은 `AppShell` 안에서 NavigationRail
/// 오른쪽에 놓이므로 둘은 같지 않다.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'kl_user_level': 'a1'});
    await Storage.init();
  });

  group('2열 전환 기준', () {
    test('breakpoint 는 한옥 행의 실제 요구에서 나온다 (임의의 화면폭 숫자가 아니다)', () {
      // 가장 넓은 요구를 갖는 행이 한옥이다: 지도 상한 + 간격 + 진행률 열.
      // 히어로+미션 행은 이 폭이면 각 열 (744-24)/2 = 360dp 라 폰 컬럼(328dp)
      // 보다 넓으므로 자동으로 충족된다 — 그래서 한옥이 기준을 정한다.
      expect(
        kHomeTwoColumnMinWidth,
        kHanokPreviewMaxWidth + kHomeColumnGap + kHomeSideColumnMinWidth,
      );
      expect(kHomeTwoColumnMinWidth, 744);

      // 2열 컬럼 상한은 "한 열이 폰 컬럼 상한을 넘지 않는다"에서 나온다.
      expect(
        kHomeTwoColumnContentMaxWidth,
        SoriBreakpoints.content * 2 + kHomeColumnGap,
      );
    });

    // 이게 화면 폭 하드코딩과 LayoutBuilder 기준의 결정적 차이다. 800dp 태블릿은
    // 레일 없이는 2열이 들어가지만, `AppShell` 처럼 레일(96dp)이 붙으면 홈에
    // 남는 폭이 704dp → 콘텐츠 672dp 로 744dp 문턱 아래다. 화면 폭으로
    // 분기했다면 두 경우가 같은 결과를 냈을 것이다.
    testWidgets('800dp — 레일이 없으면 2열', (tester) async {
      await _pumpHome(tester, size: const Size(800, 1280));
      expect(_isTwoColumn(tester), isTrue, reason: '콘텐츠 768dp');
    });

    testWidgets('800dp — 레일이 폭을 먹으면 같은 화면 폭에서도 1열', (tester) async {
      await _pumpHome(tester, size: const Size(800, 1280), railWidth: 96);
      expect(_isTwoColumn(tester), isFalse, reason: '콘텐츠 672dp');
    });

    // 콘텐츠 폭 = 화면폭 − 좌우 clamp padding(각 Spacing.lg).
    testWidgets('문턱 바로 아래는 1열', (tester) async {
      const double justUnder = kHomeTwoColumnMinWidth + Spacing.lg * 2 - 1;
      await _pumpHome(tester, size: const Size(justUnder, 900));
      expect(_isTwoColumn(tester), isFalse, reason: '${justUnder}dp');
    });

    testWidgets('문턱 바로 위는 2열', (tester) async {
      const double justOver = kHomeTwoColumnMinWidth + Spacing.lg * 2;
      await _pumpHome(tester, size: const Size(justOver, 900));
      expect(_isTwoColumn(tester), isTrue, reason: '${justOver}dp');
    });
  });

  group('compact/medium — 기존 1열 유지', () {
    for (final size in <Size>[Size(360, 800), Size(360, 400)]) {
      for (final scale in <double>[1.0, 1.3]) {
        testWidgets(
          '${size.width.toInt()}x${size.height.toInt()} @$scale 는 1열이다',
          (tester) async {
            await _pumpHome(tester, size: size, textScale: scale);
            expect(_isTwoColumn(tester), isFalse);

            // 히어로가 미션 **위**에 있고 옆이 아니다.
            final hero = tester.getRect(find.byType(MissionHeroCard));
            final hanok = tester.getRect(_hanokFinder);
            expect(hero.bottom, lessThanOrEqualTo(hanok.top + 0.01));
          },
        );
      }
    }

    testWidgets('레일이 붙은 800dp 태블릿(medium)도 1열이다', (tester) async {
      await _pumpHome(tester, size: const Size(800, 1280), railWidth: 96);
      expect(_isTwoColumn(tester), isFalse);
    });
  });

  group('expanded — 2열 배치', () {
    testWidgets('히어로와 미션이 같은 행에 나란히 놓인다', (tester) async {
      await _pumpHome(tester, size: const Size(1280, 800));

      final mission = tester.getRect(find.byType(MissionHeroCard));
      // 인사말은 시각(아침/오후/저녁)에 따라 문구가 바뀌므로 앵커로 못 쓴다.
      // 캐릭터 밴드는 라이트 테마에서 항상 이 위젯이다.
      final heroBand = tester.getRect(find.byType(CharacterClipPlayer));

      // 가로로 분리 — 히어로 열이 미션 카드 왼쪽에 있다.
      expect(
        heroBand.right,
        lessThanOrEqualTo(mission.left + 0.01),
        reason: '히어로 열이 미션 카드 왼쪽에 있어야 한다',
      );
      // 세로로 겹침 — 같은 행이다(위아래로 쌓인 게 아니다).
      final overlap =
          (mission.bottom < heroBand.bottom
              ? mission.bottom
              : heroBand.bottom) -
          (mission.top > heroBand.top ? mission.top : heroBand.top);
      expect(overlap, greaterThan(0), reason: '같은 행이면 세로 구간이 겹친다');
    });

    testWidgets('한옥은 지도 | 능력 설명 2열로 바뀐다', (tester) async {
      await _pumpHome(tester, size: const Size(1280, 800));

      final map = tester.getRect(find.byType(PersonalHanokMap));
      final narrative = tester.getRect(find.byType(HanokBuildNarrativeLine));

      expect(
        narrative.left,
        greaterThanOrEqualTo(map.right),
        reason: '능력 설명이 지도 오른쪽',
      );
      final overlap =
          (map.bottom < narrative.bottom ? map.bottom : narrative.bottom) -
          (map.top > narrative.top ? map.top : narrative.top);
      expect(overlap, greaterThan(0), reason: '지도와 능력 설명이 같은 행');

      // 지도는 여전히 상한을 넘지 않는다 — 2열이라고 그림을 키우지 않는다.
      expect(map.width, lessThanOrEqualTo(kHanokPreviewMaxWidth + 0.01));
    });

    testWidgets('1열에서는 능력 설명이 지도 아래에 그대로 남는다 (회귀 방향)', (tester) async {
      await _pumpHome(tester, size: const Size(360, 800));

      final map = tester.getRect(find.byType(PersonalHanokMap));
      final narrative = tester.getRect(find.byType(HanokBuildNarrativeLine));
      expect(narrative.top, greaterThanOrEqualTo(map.bottom - 0.01));
    });

    testWidgets('태블릿에서 좌우 빈 공간이 화면의 절반을 먹지 않는다', (tester) async {
      // 변경 전 실측: 1280dp 에서 콘텐츠 608dp, 한쪽 여백 336dp (= 52.5% 낭비).
      await _pumpHome(tester, size: const Size(1280, 800));

      final hanok = tester.getRect(_hanokFinder);
      final unused = 1280 - hanok.width;
      expect(
        unused / 1280,
        lessThan(0.30),
        reason: '미사용 폭 ${unused.toStringAsFixed(0)}dp — 변경 전은 672dp(52.5%)였다',
      );
    });
  });

  group('짧은/좁은 뷰포트에서 오버플로 0', () {
    // 지시된 3종 + 대조군. 공용 responsive 매트릭스와 별개로 홈만 직접 본다.
    for (final size in <Size>[
      Size(360, 400),
      Size(800, 360),
      Size(1280, 500),
      Size(360, 800),
      Size(1280, 800),
    ]) {
      for (final scale in <double>[1.0, 1.3]) {
        final label = '${size.width.toInt()}x${size.height.toInt()} @$scale';
        testWidgets('$label — 예외 없음', (tester) async {
          await _pumpHome(tester, size: size, textScale: scale);
          expect(tester.takeException(), isNull, reason: label);
        });

        testWidgets('$label — 레일 있는 경우도 예외 없음', (tester) async {
          await _pumpHome(
            tester,
            size: size,
            textScale: scale,
            railWidth: size.width >= SoriBreakpoints.navigationRail ? 96 : 0,
          );
          expect(tester.takeException(), isNull, reason: '$label +rail');
        });
      }
    }
  });

  group('접근성', () {
    for (final size in <Size>[Size(360, 800), Size(1280, 800)]) {
      final label = '${size.width.toInt()}x${size.height.toInt()}';
      testWidgets('$label — 탭 타깃이 최소 크기를 만족한다', (tester) async {
        final handle = tester.ensureSemantics();
        await _pumpHome(tester, size: size);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        handle.dispose();
      });

      testWidgets('$label — 본문 대비가 기준을 만족한다', (tester) async {
        final handle = tester.ensureSemantics();
        await _pumpHome(tester, size: size);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  });
}

final _hanokFinder = find.byKey(const ValueKey('home-hanok-preview'));

/// 미션 카드가 한옥 카드보다 좁으면 행을 나눠 쓴 것 = 2열.
bool _isTwoColumn(WidgetTester tester) {
  final mission = tester.getSize(find.byType(MissionHeroCard)).width;
  final hanok = tester.getSize(_hanokFinder).width;
  return mission < hanok - 1;
}

/// [railWidth] 는 `AppShell` 의 NavigationRail 을 흉내 낸다 — 홈에 실제로
/// 남는 폭이 화면 폭과 다르다는 조건을 재현하기 위한 것이다.
Future<void> _pumpHome(
  WidgetTester tester, {
  required Size size,
  double textScale = 1.0,
  double railWidth = 0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final home = HomeScreen(
    loadTodaySnapshot: () async => TodayLearningSnapshot(
      pick: const ReviewPick(dueCount: 12),
      dueCount: 12,
    ),
    loadHanokRatios: () async =>
        const LevelRatios(a1: 1, a2: 0.5, b1: 0, b2: 0),
    loadHanokProjection: (ratios) async => PersonalHanokProjection.from(ratios),
    loadHanokNarrative: (projection) async =>
        HanokBuildNarrative.empty(projection),
  );

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: SizedBox()),
      ),
      home: MediaQuery(
        data: MediaQueryData(
          disableAnimations: true,
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: railWidth > 0
            ? Row(
                children: [
                  SizedBox(width: railWidth, height: size.height),
                  Expanded(child: home),
                ],
              )
            : home,
      ),
    ),
  );
  await tester.pump();
  // `SoriEntrance` 의 진입 지연은 최대 300ms 다(오늘의 글자 카드). 그보다 짧게
  // 펌프하면 타이머가 살아 있는 채로 트리가 사라져 "Pending timer" 로 터진다.
  await tester.pump(const Duration(milliseconds: 400));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
