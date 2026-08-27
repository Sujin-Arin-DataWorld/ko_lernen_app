import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/onboarding_v2/first_run_coordinator.dart';
import 'package:ko_lernen_app/features/onboarding_v2/onboarding_rollout_service.dart';

void main() {
  test('offline startup keeps the mandatory five-page story', () {
    expect(OnboardingRolloutService.defaultRaw, 'full');
    expect(OnboardingRolloutService.currentMode, OnboardingRolloutMode.full);
  });

  test('remote rollout parser exposes only full or minimal-safe modes', () {
    expect(
      OnboardingRolloutService.parseMode('full'),
      OnboardingRolloutMode.full,
    );
    expect(
      OnboardingRolloutService.parseMode('enabled'),
      OnboardingRolloutMode.full,
    );
    for (final raw in ['minimal', 'off', 'disabled', 'kill']) {
      expect(
        OnboardingRolloutService.parseMode(raw),
        OnboardingRolloutMode.minimalSafe,
        reason: raw,
      );
    }
    for (final raw in ['', 'unexpected', 'enabled-ish']) {
      expect(
        OnboardingRolloutService.parseMode(raw),
        OnboardingRolloutMode.full,
        reason: raw,
      );
    }
  });
}
