import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/home_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';

/// 홈 레이아웃 골든 — 폰 1열 / 태블릿 2열 두 상태를 픽셀로 고정한다.
///
/// `home_layout_test.dart` 는 **관계**(같은 행인가·문턱을 넘었나)를 보고,
/// 이쪽은 그 결과의 **모양**을 본다. 둘 다 있어야 "테스트는 초록인데 화면은
/// 이상한" 경우가 걸린다.
///
/// ⚠️ **기준선은 Linux(CI) 정본이다.** `design_components_golden_test.dart` 의
/// 머리말과 같은 규칙이 그대로 적용된다 — 로컬에서 `--update-goldens` 로
/// 만들지 말 것. OS·Flutter 패치 차이의 서브픽셀 AA 만으로 CI 가 빨간불이 된다
/// (2026-08-06 실제 사고).
///
/// **기준 생성**: Actions → CI → "Run workflow" → `Regenerate goldens (manual)`
/// 잡의 `goldens-linux-3-44-0` 아티팩트를 `test/goldens/baselines/` 에 커밋.
///
/// 기준 파일이 아직 없으면 각 테스트는 **skip** 된다 — 새 골든을 추가했다는
/// 이유만으로 CI 가 빨개지지 않게(기존 기준선 유무로 뭉뚱그려 판단하면 이
/// 파일의 기준이 없는데도 ready 로 잡힌다).
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'kl_user_level': 'a1'});
    await Storage.init();
  });

  _goldenTest(
    name: '폰 세로 — 1열',
    size: const Size(360, 800),
    baseline: 'home_compact_360x800.png',
  );

  _goldenTest(
    name: '태블릿 가로 — 2열',
    size: const Size(1280, 800),
    baseline: 'home_expanded_1280x800.png',
  );
}

void _goldenTest({
  required String name,
  required Size size,
  required String baseline,
}) {
  final file = File('test/goldens/baselines/$baseline');
  final ready = autoUpdateGoldenFiles || file.existsSync();

  // 기준이 없으면 skip — CI 의 "Regenerate goldens (manual)" 로 $baseline 생성.
  testWidgets(
    '홈 골든 — $name',
    skip: !ready,
    (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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
              // 인사말이 시각에 따라 바뀌므로 골든은 **텍스트가 아니라 배치**를
              // 본다고 가정하면 안 된다. 픽셀이 달라지는 건 사실이라, 이
              // 골든은 인사말 영역까지 포함해 하루 중 시각에 의존한다 —
              // CI 는 UTC 고정이라 재현되지만, 로컬 재생성은 금지다(위 주석).
              textScaler: const TextScaler.linear(1.0),
            ),
            child: HomeScreen(
              loadTodaySnapshot: () async => TodayLearningSnapshot(
                pick: const ReviewPick(dueCount: 12),
                dueCount: 12,
              ),
              loadHanokRatios: () async =>
                  const LevelRatios(a1: 1, a2: 0.5, b1: 0, b2: 0),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('baselines/$baseline'),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );
}
