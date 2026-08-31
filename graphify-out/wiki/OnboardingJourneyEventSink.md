# OnboardingJourneyEventSink

> 5 nodes · cohesion 0.40

## Key Concepts

- **OnboardingJourneyEventSink** (5 connections) — `lib/features/onboarding_v2/first_run_coordinator.dart`
- **_RecordingJourneyEventSink** (2 connections) — `integration_test/app_flows_test.dart`
- **NoopOnboardingJourneyEventSink** (2 connections) — `lib/features/onboarding_v2/first_run_coordinator.dart`
- **_AnalyticsOnboardingJourneyEventSink** (2 connections) — `lib/features/onboarding_v2/first_run_runtime.dart`
- **_JourneyEventSink** (2 connections) — `test/features/onboarding_v2/first_run_coordinator_test.dart`

## Relationships

- [first_run_coordinator.dart](first_run_coordinator.dart.md) (2 shared connections)
- [entry_onboarding_uiux_test.dart](entry_onboarding_uiux_test.dart.md) (1 shared connections)
- [kkeunmari_screen.dart](kkeunmari_screen.dart.md) (1 shared connections)
- [first_run_coordinator_test.dart](first_run_coordinator_test.dart.md) (1 shared connections)

## Source Files

- `integration_test/app_flows_test.dart`
- `lib/features/onboarding_v2/first_run_coordinator.dart`
- `lib/features/onboarding_v2/first_run_runtime.dart`
- `test/features/onboarding_v2/first_run_coordinator_test.dart`

## Audit Trail

- EXTRACTED: 9 (100%)
- INFERRED: 0 (0%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [index](index.md) to navigate.*