# Task 2 Report: Ordered cloud startup and privacy-safe crash/push lifecycle

## Status

Implemented and verified.

## TDD evidence

### RED

Command:

```text
flutter test test/app_startup_coordinator_test.dart test/privacy_consent_service_test.dart test/push_service_test.dart test/premium_identity_binder_test.dart
```

Expected result before production changes: exit 1. The compiler reported the
missing `AppStartupCoordinator`, `PrivacyConsentController` and consent clients,
the instance-based Push lifecycle contracts, `PushOwnershipTransitionCoordinator`,
and `PremiumIdentityBinder`. A test-harness initializer error was corrected and
the privacy test was rerun to confirm its only remaining failures were the
missing production contracts.

### GREEN

Focused command:

```text
flutter test test/app_startup_coordinator_test.dart test/privacy_consent_service_test.dart test/push_service_test.dart test/premium_identity_binder_test.dart
```

Result: exit 0, 14 tests passed.

Full regression command:

```text
flutter test
```

Result: exit 0, 555 tests passed.

Static analysis command:

```text
flutter analyze lib/main.dart lib/services/app_startup_coordinator.dart lib/services/privacy_consent_service.dart lib/services/push_service.dart lib/services/premium_service.dart lib/services/auth_service.dart lib/screens/settings_screen.dart test/app_startup_coordinator_test.dart test/privacy_consent_service_test.dart test/push_service_test.dart test/premium_identity_binder_test.dart
```

Result: exit 0, no issues found. The first analysis pass identified one
redundant `dart:ui` import; it was removed before the clean final run.

Whitespace verification:

```text
git diff --check
```

Result: no whitespace errors.

## Files

Created:

- `lib/services/app_startup_coordinator.dart`
- `test/app_startup_coordinator_test.dart`
- `test/privacy_consent_service_test.dart`
- `test/push_service_test.dart`
- `test/premium_identity_binder_test.dart`
- `.superpowers/sdd/2026-07-29-release-hardening/task-2-report.md`

Modified:

- `lib/main.dart`
- `lib/services/privacy_consent_service.dart`
- `lib/services/push_service.dart`
- `lib/services/premium_service.dart`
- `lib/services/auth_service.dart`
- `lib/screens/settings_screen.dart`

## Design decisions

- `AppStartupCoordinator` accepts production startup functions as dependency
  seams. It awaits Firebase success, then anonymous auth, then RevenueCat, and
  only then optional Push. A false Firebase result prevents all dependent SDK
  access. `main()` launches the coordinator with `unawaited`, so this ordering
  does not delay `runApp()`.
- Crash consent policy lives in `PrivacyConsentController`, behind narrow
  Analytics and Crashlytics clients. Startup with stored consent enables
  collection without deleting legitimately consented queued reports. Startup
  without consent disables collection then deletes queued reports. An explicit
  off-to-on transition deletes reports before enabling, while disabling always
  disables first and deletes second.
- Installed Flutter and platform error handlers consult current consent at
  error time. Without consent they use local Flutter error presentation only
  and never invoke Crashlytics. In debug with consent, local presentation is
  retained in addition to Crashlytics reporting.
- `PushService` is instance-based with narrow messaging, auth, token repository,
  and local-notification adapters. Its production auth adapter reads
  `FirebaseAuth` directly, removing the prior `AuthService` import cycle.
- Push enable is concurrent-call idempotent, becomes ready only after the full
  registration succeeds, and clears the in-flight attempt on failure so the
  next call retries. Permission is requested before FCM auto-init is enabled.
  Token-refresh and foreground-message subscriptions are owned and canceled by
  the service.
- Push disable cancels subscriptions, removes the token from the current UID,
  deletes the device token, and turns off FCM auto-init. Settings keep local
  reminder permission and schedules even when optional FCM registration fails.
- `PushOwnershipTransitionCoordinator` removes the token from the old UID before
  sign-out/account deletion and rebinds the current/new anonymous UID afterward
  when notifications remain enabled. Its `finally` rebind also restores the
  current owner if an auth transition fails partway through.
- Account deletion in Settings resets local notification preference; Push is
  therefore disabled immediately after `Storage.resetAll()` so the freshly
  anonymous token is not retained after the preference becomes off.
- `PremiumIdentityBinder` serializes Firebase user changes and updates
  `boundUid` only after successful RevenueCat `logIn` or `logOut`. A transient
  failure leaves the old binding intact, allowing the same UID event to retry.
- Native FCM default-off configuration was deliberately not changed here; it
  remains Task 3 as required.

## Self-review

- Re-read every Task 2 checklist item and mapped it to production code plus a
  focused fake-based behavior test.
- Confirmed Push no longer imports `AuthService`.
- Confirmed no `PushService.init` call remains and Premium/Push are reached only
  through the ordered coordinator.
- Confirmed new and changed lifecycle branches use braced `if`/`else` blocks.
- Removed formatter-only churn from unrelated `AuthService` code and stale
  startup comments.
- Confirmed the worktree contains only Task 2 production files, focused tests,
  and this report.

## Concerns and follow-up

- Task 3 must still set the native Firebase Messaging auto-init defaults to off;
  this task only enforces runtime enable/disable behavior after permission.
- The fake-backed tests prove app policy and ordering, but release QA should
  still exercise Android and iOS permission prompts, token deletion/recreation,
  sign-out/account-deletion rebinding, and Crashlytics queued-report behavior on
  real Firebase projects/devices.

## Fix round 1/5

### Findings addressed

- Explicit Crashlytics off-to-on now fails closed: queued-report deletion and
  collection enable must both succeed before consent is persisted true. A
  deletion failure propagates with collection and stored consent still off.
- Crash reporting client methods now retain Firebase's `Future<void>` contract.
  Flutter/platform callbacks attach async handling that presents the original
  error locally when Crashlytics reporting later fails.
- Push enable/disable now use a serialized desired-state lifecycle. A later
  disable changes desired state immediately, every awaited enable boundary
  rechecks it, and lifecycle effects complete in invocation order.
- Auth transition preparation now cancels subscriptions, disables auto-init,
  and deletes the local FCM token before sign-out/account deletion. Failure of
  either safety-critical local operation propagates and blocks the auth
  transition. Firestore cleanup becomes best-effort only after the local token
  is definitively invalid.
- Rebinding after a successful auth transition calls the full Push enable path,
  creating and persisting a token for the new current/anonymous UID.
- Task 3 native manifest configuration remains unchanged.

### RED command and exact terminal tail

Command:

```text
flutter test test/privacy_consent_service_test.dart test/push_service_test.dart
```

Output:

```text
00:00 +10 -5: Some tests failed.

Failing tests:
  C:/Users/vjinn/OneDrive/Desktop/hangulsori/ko_lernen_app-release-hardening/test/privacy_consent_service_test.dart: crash consent asynchronous framework report failures use local presentation
  C:/Users/vjinn/OneDrive/Desktop/hangulsori/ko_lernen_app-release-hardening/test/privacy_consent_service_test.dart: crash consent asynchronous platform report failures use local presentation
  C:/Users/vjinn/OneDrive/Desktop/hangulsori/ko_lernen_app-release-hardening/test/privacy_consent_service_test.dart: crash consent explicit off to on keeps consent off when report deletion fails
  C:/Users/vjinn/OneDrive/Desktop/hangulsori/ko_lernen_app-release-hardening/test/push_service_test.dart: PushService a later disable wins over an in-flight enable
  C:/Users/vjinn/OneDrive/Desktop/hangulsori/ko_lernen_app-release-hardening/test/push_service_test.dart: ownership transition blocks auth when local token invalidation fails
```

### GREEN command and exact terminal tail

Command:

```text
flutter test test/privacy_consent_service_test.dart test/push_service_test.dart
```

Output:

```text
PrivacyConsent: crash report skipped — Bad state: async report failed
PrivacyConsent: crash report skipped — Bad state: async report failed
PushService: enable skipped — Bad state: transient
00:00 +15: All tests passed!
```

### Additional verification

```text
flutter analyze lib/services/privacy_consent_service.dart lib/services/push_service.dart test/privacy_consent_service_test.dart test/push_service_test.dart
Analyzing 4 items...
No issues found! (ran in 3.1s)

flutter test
00:29 +560: All tests passed!

git diff --check
<no output; exit 0>
```

### Fix-round concern

Sign-out/account deletion is intentionally blocked when local FCM auto-init
shutdown or local token deletion cannot be proven, including an offline
`deleteToken()` failure. Proceeding in that state could leave a deliverable
token owned by the old UID. Firestore cleanup failure alone does not block once
the local token is invalid.
