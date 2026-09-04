import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/card.dart';
import 'package:ko_lernen_app/widgets/sori/level_chip.dart';
import 'package:ko_lernen_app/widgets/sori/hanok_tokens.dart';
import 'package:ko_lernen_app/widgets/sori/mission_hero_card.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

/// 디자인 컴포넌트 골든 — R0 기준 스크린샷 세트의 자동화 대체
/// (2026-08-04 감사 #6). 표면 v2 문법(그림자·selectable·액센트 바)과
/// 미션 히어로 상태가 픽셀 단위로 고정된다.
///
/// ⚠️ **기준선은 Linux(CI) 정본이다.** `matchesGoldenFile` 의 기본
/// `LocalFileComparator` 는 허용오차 0이라 OS·Flutter 패치 버전이 다르면
/// 서브픽셀 AA 차이만으로 깨진다. 실제로 Windows 에서 만든 기준선이
/// ubuntu + `flutter-version: 3.44.0` 핀인 CI 와 어긋나 main 이 빨간불이었다
/// (2026-08-06). Ahem 폰트는 **글리프 기하**만 결정론적으로 만들 뿐,
/// BoxShadow blur·그라데이션 디더링·둥근 모서리 커버리지까지 고정하지 않는다.
///
/// **기준 생성 — 로컬에서 `--update-goldens` 를 돌리지 말 것.**
/// CI 와 같은 환경에서만 만든다:
///   1. Actions → CI → "Run workflow" (workflow_dispatch)
///   2. `Regenerate goldens (manual)` 잡의 `goldens-linux-3-44-0` 아티팩트 다운로드
///   3. `test/goldens/baselines/` 에 덮어쓰고 커밋
/// 그 결과 이 3개 테스트는 **로컬(Windows/macOS)에서는 실패하는 게 정상**이다.
/// 판단이 필요하면 CI 실패 시 올라오는 `golden-failures` 아티팩트의
/// `_testImage`/`_isolatedDiff` 를 보고 진짜 회귀인지 확인할 것.
///
/// 기준이 없으면 스위트는 skip 된다(빨간 게이트 방지).
Widget _wrap(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('de'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: Scaffold(
    backgroundColor: SoriColors.lightBg,
    body: Center(
      child: SizedBox(
        width: 360,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  ),
);

void main() {
  final baselines = Directory('test/goldens/baselines');
  final ready =
      autoUpdateGoldenFiles ||
      (baselines.existsSync() && baselines.listSync().isNotEmpty);
  // 기준선은 Linux(CI) 정본이라(위 주석) Windows/macOS 로컬에선 서브픽셀 AA
  // 차이만으로 항상 깨진다 → 로컬 빨간불(3건)을 없애려 비-Linux 에선 skip 하고,
  // 픽셀 검증은 CI(Linux)에서만 한다. `--update-goldens` 시엔 플랫폼 무관 실행.
  final String? goldenSkip = !ready
      ? '기준 없음 — CI 워크플로(Regenerate goldens)로 1회 생성'
      : (!autoUpdateGoldenFiles && !Platform.isLinux)
      ? 'golden 기준선은 Linux(CI) 정본 — 로컬(Windows/macOS)에선 skip'
      : null;

  group('디자인 컴포넌트 골든 (표면 v2 기준선)', skip: goldenSkip, () {
    testWidgets('SoriCard 표면 v2 4상태', (tester) async {
      tester.view.physicalSize = const Size(400, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _wrap(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SoriCard(child: Text('기본 — 무테두리 + low 그림자')),
              SizedBox(height: 12),
              SoriCard(selectable: true, child: Text('선택형 — 테두리')),
              SizedBox(height: 12),
              SoriCard(
                selectable: true,
                selected: true,
                child: Text('선택됨 — primary 2px'),
              ),
              SizedBox(height: 12),
              SoriCard(
                accent: SoriColors.tiger,
                tinted: true,
                child: Text('액센트 — 좌측 4px 바'),
              ),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await expectLater(
        find.byType(Column).first,
        matchesGoldenFile('baselines/sori_card_v2.png'),
      );
    });

    testWidgets('SoriLevelChip 사계 + 챕터 0', (tester) async {
      tester.view.physicalSize = const Size(400, 200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      // 실제 표면은 LevelFilterBar 가로 스크롤; 픽스처는 줄바꿈 허용 —
      // Linux 폰트 메트릭에서 328dp Row가 1px 넘침(2026-09-04).
      await tester.pumpWidget(
        _wrap(
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.xs,
            children: const [
              SoriLevelChip(code: 'A1'),
              SoriLevelChip(code: 'A2'),
              SoriLevelChip(code: 'B1'),
              SoriLevelChip(code: 'B2'),
              SoriLevelChip(code: 'C1'),
              SoriLevelChip(code: 'C2'),
              SoriLevelChip(code: '0', color: HanokColors.hanjiInk),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await expectLater(
        find.byType(Wrap).first,
        matchesGoldenFile('baselines/level_chips.png'),
      );
    });

    testWidgets('MissionHeroCard 스켈레톤·allDone', (tester) async {
      tester.view.physicalSize = const Size(400, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _wrap(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MissionHeroCard(loading: true, content: null),
              const SizedBox(height: 12),
              MissionHeroCard(
                loading: false,
                content: null,
                onAnotherRound: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await expectLater(
        find.byType(Column).first,
        matchesGoldenFile('baselines/mission_hero_states.png'),
      );
    });
  });
}
