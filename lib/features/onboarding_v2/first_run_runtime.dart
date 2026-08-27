import 'package:flutter/foundation.dart';

import '../../services/analytics_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/sori/mascot_preference.dart';
import 'first_run_coordinator.dart';
import 'onboarding_app_adapters.dart';
import 'onboarding_journey_repository.dart';
import 'onboarding_journey_state.dart';
import 'onboarding_rollout_service.dart';

/// Production composition root for the first-run state machine.
///
/// Keeping one coordinator instance serializes rapid taps and overlapping
/// lifecycle callbacks across Splash, onboarding, the gate, and AppShell.
abstract final class FirstRunRuntime {
  static final FirstRunCoordinator coordinator = createCoordinator();

  /// Builds an isolated production-wired coordinator.
  ///
  /// The app normally shares [coordinator]. Whole-app restart tests inject a
  /// fresh instance so asynchronous serialization never crosses test Zones.
  @visibleForTesting
  static FirstRunCoordinator createCoordinator() => FirstRunCoordinator(
    repository: SharedPreferencesOnboardingJourneyRepository(),
    legacyStateReader: const StorageLegacyOnboardingStateReader(),
    commitGateway: StorageOnboardingCommitGateway(
      onCompanionSaved: (_) async => MascotPreference.load(),
    ),
    eventSink: const _AnalyticsOnboardingCompletionEventSink(),
    journeyEventSink: const _AnalyticsOnboardingJourneyEventSink(),
    rolloutModeReader: () => OnboardingRolloutService.currentMode,
  );
}

class _AnalyticsOnboardingJourneyEventSink
    implements OnboardingJourneyEventSink {
  const _AnalyticsOnboardingJourneyEventSink();

  @override
  bool get canRecordOnboardingStarted => Analytics.canCollect;

  @override
  Future<void> recordOnboardingStarted() {
    return Analytics.onboardingStarted(entryPoint: 'fresh_install');
  }

  @override
  Future<void> recordCompanionPreviewFailure(
    OnboardingCompanionPreviewFailure failure,
  ) {
    return Analytics.onboardingCompanionPreviewFailed(failure);
  }
}

class _AnalyticsOnboardingCompletionEventSink
    implements OnboardingCompletionEventSink {
  const _AnalyticsOnboardingCompletionEventSink();

  @override
  bool get canRecordOnboardingCompleted => Analytics.canCollect;

  @override
  Future<void> recordOnboardingCompleted(OnboardingJourneyState state) {
    return Analytics.onboardingCompleted(
      entryLevel: state.levelDraft?.code ?? 'unknown',
      hasPlacement: Storage.dedicatedCoursePlacementLevelCode != null,
      purpose: state.purposeDraft,
    );
  }
}
