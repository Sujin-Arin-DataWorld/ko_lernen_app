import 'dart:async';

import 'package:flutter/material.dart';

import '../features/onboarding_v2/first_run_coordinator.dart';
import '../features/onboarding_v2/first_run_runtime.dart';
import '../models/sori_stage_progression.dart';
import '../services/analytics_service.dart';
import '../services/privacy_consent_service.dart';
import 'sori_stage/sori_stage_shell.dart';

/// **AppShell** — Sori Stage 5탭 셸 진입점.
///
/// Phase 4 (2026-08-14): `SoriStageFeatureGate` 제거 — Sori Stage가 유일한 셸.
/// 레거시 `LegacyAppShell`/`HomeScreen` 삭제 완료.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.firstRunCoordinator, this.loadTodaySnapshot});

  /// Test seam. Production uses the shared serialized runtime coordinator.
  final FirstRunCoordinator? firstRunCoordinator;

  /// W10 PR-D(2026-09-06): Today 탭(`SoriStageTodayScreen`)의 스냅샷 로더
  /// 시험용 구멍 — [SoriStageShell.loadTodaySnapshot] 로 그대로 전달.
  /// 프로덕션 기본값(`null`)은 실제 `compute()` 기반 로더를 쓴다.
  final Future<SoriStageProgressionSnapshot> Function()? loadTodaySnapshot;

  /// 앱 재시작 없이 홈 투어를 다시 띄우는 신호.
  /// 설정 "튜토리얼 다시 보기"가 값을 올리면 → 홈 탭으로 전환 후 투어 재생.
  /// (플래그만 리셋하면 [State.initState]가 다시 안 돌아 재시작 전엔 안 보이던 갭 해소.)
  static final ValueNotifier<int> replayHomeTour = ValueNotifier<int>(0);

  /// A one-shot request for the canonical five-tab shell. `-1` means idle.
  static final ValueNotifier<int> requestedStageTab = ValueNotifier<int>(-1);

  static void openStageTab(int index) {
    if (index < 0 || index > 4) {
      throw RangeError.range(index, 0, 4, 'index');
    }
    requestedStageTab.value = index;
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    PrivacyConsentService.analyticsEnabled.addListener(
      _onAnalyticsAvailabilityChanged,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      // The coordinator waits for effective analytics consent, then persists
      // the marker before best-effort dispatch so restarts cannot duplicate
      // completion telemetry or consume the event while collection is barred.
      unawaited(_recordOnboardingArrival());
    });
  }

  @override
  void dispose() {
    PrivacyConsentService.analyticsEnabled.removeListener(
      _onAnalyticsAvailabilityChanged,
    );
    super.dispose();
  }

  void _onAnalyticsAvailabilityChanged() {
    if (!PrivacyConsentService.analyticsEnabled.value) {
      return;
    }
    // The user may opt in after onboarding. Set the bounded level/purpose
    // properties first, then let the durable coordinator deliver the pending
    // completion marker at most once.
    unawaited(Analytics.syncUserProperties());
    unawaited(_recordOnboardingArrival());
  }

  Future<void> _recordOnboardingArrival() async {
    try {
      await (widget.firstRunCoordinator ?? FirstRunRuntime.coordinator)
          .recordAppShellFirstFrame();
    } catch (_) {
      // Existing users without a V2 state and preview/test shells are valid.
      // Analytics must never affect rendering or navigation.
    }
  }

  @override
  Widget build(BuildContext context) => SoriStageShell(
    replayHomeTour: AppShell.replayHomeTour,
    requestedTab: AppShell.requestedStageTab,
    loadTodaySnapshot: widget.loadTodaySnapshot,
  );
}
