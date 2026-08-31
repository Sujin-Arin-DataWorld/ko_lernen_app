# OnboardingCommitGateway

> 6 nodes · cohesion 0.40

## Key Concepts

- **OnboardingCommitGateway** (5 connections) — `lib/features/onboarding_v2/first_run_coordinator.dart`
- **OnboardingCompanionCommitSnapshotReader** (3 connections) — `lib/features/onboarding_v2/first_run_coordinator.dart`
- **StorageOnboardingCommitGateway** (3 connections) — `lib/features/onboarding_v2/onboarding_app_adapters.dart`
- **_CommitGateway** (3 connections) — `test/features/onboarding_v2/first_run_coordinator_test.dart`
- **_UnusedCommitGateway** (2 connections) — `test/app_shell_onboarding_analytics_retry_test.dart`
- **_CommitGateway** (2 connections) — `test/entry_onboarding_uiux_test.dart`

## Relationships

- [first_run_coordinator.dart](first_run_coordinator.dart.md) (2 shared connections)
- [onboarding_app_adapters.dart](onboarding_app_adapters.dart.md) (1 shared connections)
- [app_shell_onboarding_analytics_retry_test.dart](app_shell_onboarding_analytics_retry_test.dart.md) (1 shared connections)
- [entry_onboarding_uiux_test.dart](entry_onboarding_uiux_test.dart.md) (1 shared connections)
- [first_run_coordinator_test.dart](first_run_coordinator_test.dart.md) (1 shared connections)

## Source Files

- `lib/features/onboarding_v2/first_run_coordinator.dart`
- `lib/features/onboarding_v2/onboarding_app_adapters.dart`
- `test/app_shell_onboarding_analytics_retry_test.dart`
- `test/entry_onboarding_uiux_test.dart`
- `test/features/onboarding_v2/first_run_coordinator_test.dart`

## Audit Trail

- EXTRACTED: 12 (100%)
- INFERRED: 0 (0%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [index](index.md) to navigate.*