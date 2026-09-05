import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/main.dart';
import 'package:ko_lernen_app/features/onboarding_v2/first_run_coordinator.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_app_adapters.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_repository.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_journey_state.dart';
import 'package:ko_lernen_app/screens/app_shell.dart';
import 'package:ko_lernen_app/screens/consent_screen.dart';
import 'package:ko_lernen_app/screens/intro_gate_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_companion_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_setup_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_story_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_journey_screen.dart';
import 'package:ko_lernen_app/screens/splash_screen.dart';
import 'package:ko_lernen_app/services/data_migration_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/tiger_video.dart';

final class _RecordingJourneyEventSink implements OnboardingJourneyEventSink {
  final List<OnboardingCompanionPreviewFailure> previewFailures = [];

  @override
  bool get canRecordOnboardingStarted => false;

  @override
  Future<void> recordOnboardingStarted() async {}

  @override
  Future<void> recordCompanionPreviewFailure(
    OnboardingCompanionPreviewFailure failure,
  ) async {
    previewFailures.add(failure);
  }
}

/// 실기기·에뮬레이터 전용 통합 테스트.
///
/// ⚠️ **CI 에서 돌지 않는다.** GitHub Actions 러너에는 기기가 없다. CI 회귀
/// 그물은 `test/e2e/app_flows_e2e_test.dart`(같은 흐름의 위젯 버전)가 담당하고,
/// 이 파일은 실기기 렌더러와 미디어 플러그인을 포함한 전체 화면 흐름을
/// 확인한다. 단, 테스트 격리를 위해 SharedPreferences mock backend를 쓰므로
/// 실제 디스크 I/O나 OS process-death 복구의 증거로 간주하면 안 된다. 그 두
/// 항목은 전용 QA 빌드의 수동 체크리스트에서 별도로 확인한다.
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
    TigerStageVideo.videoReady = true;
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  tearDown(() {
    TigerStageVideo.videoReady = false;
  });

  FirstRunCoordinator fullV2Coordinator({
    OnboardingJourneyEventSink journeyEventSink =
        const NoopOnboardingJourneyEventSink(),
  }) => FirstRunCoordinator(
    repository: SharedPreferencesOnboardingJourneyRepository(),
    legacyStateReader: const StorageLegacyOnboardingStateReader(),
    commitGateway: StorageOnboardingCommitGateway(),
    journeyEventSink: journeyEventSink,
  );

  Future<void> launch(
    WidgetTester tester, {
    FirstRunCoordinator? firstRunCoordinator,
    Duration splashDuration = const Duration(seconds: 2),
  }) async {
    await tester.pumpWidget(
      KoLernenApp(
        splashDisplayDuration: splashDuration,
        firstRunCoordinator: firstRunCoordinator,
      ),
    );
    await tester.pump();
    await tester.pump(splashDuration + const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 1200));
  }

  Future<void> pumpUntilFound(
    WidgetTester tester,
    Finder finder, {
    int attempts = 60,
  }) async {
    for (var attempt = 0; attempt < attempts; attempt++) {
      if (finder.evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(finder, findsWidgets);
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await pumpUntilFound(tester, finder);
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 250));
  }

  testWidgets('cold start — 신규 사용자가 법적 동의에 도달한다', (tester) async {
    await launch(tester);
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(ConsentScreen), findsOneWidget);
  });

  testWidgets('신규 V2 전체 흐름 — 5장부터 Today까지 도달한다', (tester) async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_consent_accepted': true});
    await Storage.init();
    final journeyEvents = _RecordingJourneyEventSink();
    final coordinator = fullV2Coordinator(journeyEventSink: journeyEvents);

    await launch(
      tester,
      firstRunCoordinator: coordinator,
      splashDuration: Duration.zero,
    );
    await pumpUntilFound(tester, find.byType(OnboardingStoryScreen));
    expect(find.byType(OnboardingV2JourneyScreen), findsOneWidget);

    const storyPageIds = [
      'personalCurriculum',
      'learn',
      'saveAndReview',
      'gamesAndRewards',
      'heritageJourney',
    ];
    for (final pageId in storyPageIds) {
      await pumpUntilFound(tester, find.byKey(ValueKey(pageId)));
      await tapKey(tester, 'onboarding-v2-story-next');
    }

    await pumpUntilFound(tester, find.byType(OnboardingSetupScreen));
    await tapKey(tester, 'onboarding-v2-purpose-lifeTravel');
    await tapKey(tester, 'onboarding-v2-level-A1');
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('onboarding-v2-selected-level')),
    );
    await tapKey(tester, 'onboarding-v2-setup-continue');

    await pumpUntilFound(tester, find.byType(OnboardingCompanionScreen));
    await tapKey(tester, 'onboarding-v2-companion-taego');
    await tapKey(tester, 'onboarding-v2-companion-continue');

    await pumpUntilFound(
      tester,
      find.byType(OnboardingCompanionConfirmationScreen),
    );
    await Future<void>.delayed(const Duration(seconds: 6));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('onboarding-v2-confirmation-start')),
      findsOneWidget,
    );
    await tapKey(tester, 'onboarding-v2-confirmation-start');

    await pumpUntilFound(tester, find.byType(IntroGateScreen));
    await Future<void>.delayed(const Duration(seconds: 10));
    await tester.pump();
    await pumpUntilFound(tester, find.byType(AppShell));

    expect(Storage.hasCompletedOnboarding, isTrue);
    expect(Storage.userLevelCode, 'a1');
    expect(Storage.motivation, 'travel');
    expect(Storage.explicitSelectedCompanion, 'tiger');
    expect(journeyEvents.previewFailures, isEmpty);
  });

  testWidgets('cold start — 기존 사용자가 홈에 도달한다', (tester) async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_consent_accepted': true,
      'kl_onboarding_completed': true,
      'kl_session_count': 5,
    });
    await Storage.init();

    await launch(tester);
    expect(find.byType(AppShell), findsOneWidget);
  });

  testWidgets('격리된 preferences backend에 학습 진도가 남는다', (tester) async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_consent_accepted': true,
      'kl_onboarding_completed': true,
    });
    await Storage.init();
    await launch(tester);

    await Storage.srsReview('사과', gotIt: true);

    // 같은 격리 backend에서 reload 뒤에도 직렬화 결과가 유지되는지만 본다.
    // 실제 디스크·process-death 내구성은 이 테스트의 범위가 아니다.
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    expect(prefs.getString('kl_srs_v1'), contains('사과'));
  });

  testWidgets('마이그레이션이 격리된 backend에 버전을 기록한다', (tester) async {
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
      'kl_consent_accepted': true,
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
  // - 모든 팩 직접 접근·접근 스냅샷 — 실제 Firebase·App Check 필요
  // - TTS 음성·캐릭터 영상 — 실제 오디오/디코더 필요
  // - 권한 6상태 (허용·거부·재요청·다시 묻지 않음·설정에서 회수·사용 중 회수)
}
