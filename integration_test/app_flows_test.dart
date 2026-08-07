import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/main.dart';
import 'package:ko_lernen_app/screens/app_shell.dart';
import 'package:ko_lernen_app/screens/quick_onboarding_screen.dart';
import 'package:ko_lernen_app/screens/splash_screen.dart';
import 'package:ko_lernen_app/services/data_migration_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

/// 실기기·에뮬레이터 전용 통합 테스트.
///
/// ⚠️ **CI 에서 돌지 않는다.** GitHub Actions 러너에는 기기가 없다. CI 회귀
/// 그물은 `test/e2e/app_flows_e2e_test.dart`(같은 흐름의 위젯 버전)가 담당하고,
/// 이 파일은 위젯 테스트가 **원리적으로 볼 수 없는 것**을 본다:
/// 실제 플랫폼 채널, 실제 SharedPreferences 디스크 I/O, 실제 프로세스 재시작
/// 직후의 상태, 실제 렌더러 성능.
///
/// ## 실행법
///
/// ```bash
/// # Android 실기기/에뮬레이터
/// flutter test integration_test/app_flows_test.dart -d <device-id>
///
/// # iOS 시뮬레이터
/// flutter test integration_test/app_flows_test.dart -d <simulator-id>
///
/// # 릴리스에 가까운 조건에서 (권장 — debug 전용 문제를 걷어낸다)
/// flutter test integration_test/app_flows_test.dart -d <device-id> --profile
/// ```
///
/// 세 화면 크기에서 각각 한 번씩 돌린다 (`docs/store/RELEASE_QA_CHECKLIST.md`
/// §20 기기 매트릭스): compact phone · medium tablet · expanded tablet.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    DataMigrationService.resetForTesting();
    Storage.unlockLearningWrites();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  Future<void> launch(WidgetTester tester) async {
    await tester.pumpWidget(const KoLernenApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 1200));
  }

  testWidgets('cold start — 신규 사용자가 온보딩에 도달한다', (tester) async {
    await launch(tester);
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(QuickOnboardingScreen), findsOneWidget);
  });

  testWidgets('cold start — 기존 사용자가 홈에 도달한다', (tester) async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_onboarding_completed': true,
      'kl_session_count': 5,
    });
    await Storage.init();

    await launch(tester);
    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets('실제 저장소에 학습 진도가 남는다', (tester) async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_onboarding_completed': true});
    await Storage.init();
    await launch(tester);

    await Storage.srsReview('사과', gotIt: true);

    // 플랫폼 채널을 실제로 거쳐 다시 읽는다 — 위젯 테스트의 mock 으로는
    // 검증할 수 없는 구간이다.
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    expect(prefs.getString('kl_srs_v1'), contains('사과'));
  });

  testWidgets('마이그레이션이 실제 저장소에서 도장을 찍는다', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final result = await DataMigrationService.run(preferences: prefs);

    expect(result.writesAllowed, isTrue);
    await prefs.reload();
    expect(
      prefs.getInt(DataMigrationService.versionPreferenceKey),
      isNotNull,
      reason: '스키마 도장이 디스크에 남지 않으면 다음 실행이 baseline 을 다시 추정한다',
    );
  });

  testWidgets('회전해도 앱이 살아 있다', (tester) async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_onboarding_completed': true,
      'kl_session_count': 5,
    });
    await Storage.init();
    await launch(tester);
    expect(find.byType(AppShell), findsOneWidget);

    // 세로 → 가로. 실기기에서는 실제 렌더러가 다시 레이아웃한다.
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(AppShell), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // ⚠️ 아래는 **사람이 함께 봐야 하는** 항목이라 자동 단언을 걸지 않는다.
  // 이 러너로 화면을 띄운 뒤 체크리스트로 확인한다
  // (`docs/store/RELEASE_QA_CHECKLIST.md`):
  // - Google 연동 / 계정 삭제 / 전체 초기화 — 실제 Firebase·App Check 필요
  // - 결제·구독 복원 — 실제 Play Billing / StoreKit 필요
  // - TTS 음성·캐릭터 영상 — 실제 오디오/디코더 필요
  // - 권한 6상태 (허용·거부·재요청·다시 묻지 않음·설정에서 회수·사용 중 회수)
}
