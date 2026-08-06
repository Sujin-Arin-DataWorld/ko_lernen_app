import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/learn_hub_screen.dart';
import 'package:ko_lernen_app/screens/settings_screen.dart';
import 'package:ko_lernen_app/screens/stats_screen.dart';
import 'package:ko_lernen_app/screens/vocab_packs_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
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
    skip: ready
        ? null
        : '기준 없음 — flutter test --update-goldens test/goldens 로 1회 생성',
    () {
      // 골든은 유지비가 크다. 회귀가 실제로 아팠던 표면만 고정한다:
      // 설정(폼 폭) · 배우기 허브(모듈 카드) · 단어팩(그리드 열 수) · 통계(요약).
      final screens = <String, Widget Function()>{
        'settings': SettingsScreen.new,
        'learn_hub': LearnHubScreen.new,
        'vocab_packs': VocabPacksScreen.new,
        'stats': StatsScreen.new,
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
  home: child,
  onGenerateRoute: (settings) => null,
);
