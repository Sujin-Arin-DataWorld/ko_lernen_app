# Task 5 Report: Apple account deletion and durable-provider behavior

## Status

Implemented and verified.

## TDD evidence

### RED

Command:

```text
flutter test test/account_hardening_test.dart
```

Expected result before production changes: exit 1. The test failed to compile
because the wished-for production contracts and UI inputs did not yet exist:

```text
Error: Type 'AccountDeletionCoordinator' not found.
Error: Type 'AccountDeletionOperations' not found.
Error: Type 'AuthProviderState' not found.
Error: Type 'AccountDeletionCleanupOperations' not found.
Error: No named parameter with the name 'account'.
Error: Method not found: 'subscriptionManagementUri'.
Error: No named parameter with the name 'accountDeletionWorkflow'.
00:00 +0 -1: Some tests failed.
```

This was the intended missing-behavior failure. No production code had been
changed before this RED run.

### GREEN

Focused command:

```text
flutter test test/account_hardening_test.dart
```

Result:

```text
00:02 +16: All tests passed!
```

The focused suite covers:

- Apple-only and Google-only durable account state.
- Apple-only and deterministic dual-provider labels in Profile.
- Apple-only provider labels in Settings.
- Account-nudge suppression for an Apple-only durable account.
- Apple authorization-code fail-closed behavior.
- Apple revocation before cloud and Firebase-user deletion.
- Dual-linked Google + Apple deletion choosing Apple reauthentication and
  revocation.
- Revocation and cloud-cleanup failures preventing later deletion steps.
- Required local cleanup failure propagating and suppressing success UI.
- App Store and Play Store subscription-management routes.
- The explicit subscription warning and management action in the confirmation
  dialog.

## Files

Created:

- `test/account_hardening_test.dart`
- `.superpowers/sdd/2026-07-29-release-hardening/task-5-report.md`

Modified:

- `lib/services/auth_service.dart`
- `lib/screens/profile_screen.dart`
- `lib/widgets/sori/account_nudge.dart`
- `lib/screens/settings_screen.dart`
- `lib/l10n/app_de.arb`
- `lib/l10n/app_en.arb`
- `lib/l10n/generated/app_localizations.dart`
- `lib/l10n/generated/app_localizations_de.dart`
- `lib/l10n/generated/app_localizations_en.dart`

No dependency, credential, secret, release-plan, or ledger file was changed.

## Implementation

- `AuthProviderState` and `AuthAccountSnapshot` provide immutable,
  production-facing presentation state. Google or Apple makes the account
  durable; dual-linked state has deterministic localized labels.
- Profile, Settings, and the account nudge all consume the same durable-provider
  rule. Optional immutable snapshots make the widgets previewable and testable
  without Firebase initialization.
- `AccountDeletionCoordinator` accepts narrow account operations and continues
  to use Task 2's `PushOwnershipTransitionCoordinator`. Strict old-UID token
  invalidation therefore still happens before the account transition, and
  notification-dependent rebinding behavior is unchanged.
- Any Apple-linked account, including a Google + Apple account, reauthenticates
  with Apple. The reauthentication method returns the Apple authorization code.
  A null, empty, or whitespace-only code fails closed before push invalidation,
  revocation, cloud deletion, or Firebase-user deletion.
- The Firebase production adapter calls
  `FirebaseAuth.revokeTokenWithAuthorizationCode` before cloud and Firebase-user
  deletion. Revocation and required cleanup errors propagate.
- `AccountDeletionWorkflow` sequences remote deletion and all required local
  cleanup behind an injected operations boundary. Settings shows success and
  navigates only after the workflow fully returns; a cleanup failure produces
  the localized failure state instead.
- The account-deletion confirmation explicitly states that deleting the account
  does not cancel an App Store or Play Store subscription. Its management action
  opens `https://apps.apple.com/account/subscriptions` on Apple platforms and
  `https://play.google.com/store/account/subscriptions` on Android through the
  existing `url_launcher` dependency.
- All new user-visible strings are present in German and English, and Flutter
  localization output was regenerated with `flutter gen-l10n`.

## Validation evidence

Task 2 and adjacent focused regression:

```text
flutter test test/account_hardening_test.dart test/profile_screen_test.dart test/push_service_test.dart
00:02 +27: All tests passed!
```

The eight Task 2 push tests remained green, including strict invalidation when
stored notifications are off and suppression of rebinding when notification
preference changes during the transition.

Full static analysis:

```text
flutter analyze
Analyzing ko_lernen_app-release-hardening...
No issues found! (ran in 12.0s)
```

Fresh full regression after the final focused test was added:

```text
flutter test
00:25 +578: All tests passed!
```

Whitespace:

```text
git diff --check
```

Result: exit 0 with no whitespace errors. Git emitted only normal Windows
line-ending conversion warnings.

## Self-review

- Re-read every Task 5 checklist item and mapped it to implementation plus a
  focused behavior test.
- Confirmed Apple takes priority whenever `apple.com` is linked, so a
  dual-linked account cannot bypass Apple token revocation through the Google
  branch.
- Confirmed missing authorization code, Apple revocation failure, cloud cleanup
  failure, and local cleanup failure all prevent the success state.
- Confirmed the actual Firebase adapter invokes
  `revokeTokenWithAuthorizationCode`; the test seam is an account-operations
  interface used by production coordination, not a test-only method.
- Confirmed the existing Task 2 push coordinator was reused without weakening
  old-token invalidation or notification-consent behavior.
- Confirmed German Unicode strings render correctly from UTF-8 source and that
  all new localization keys exist in both ARB files and generated outputs.
- Confirmed `url_launcher` was already a declared dependency and no package
  change was necessary.
- Confirmed only Task 5 implementation, tests, generated localization, and this
  report are present in the working tree.

## Concerns and follow-up

- Firebase/Apple token revocation and store deep links require physical-device
  QA with real sandbox accounts. The injected tests prove app ordering,
  fail-closed policy, routes, and presentation without requiring credentials.
- Account deletion does not and cannot cancel a store subscription; users are
  routed to the appropriate store management page before deletion.

## Review remediation

The review follow-up was implemented as a separate strict TDD cycle. Ordinary
push, image, TTS, and storage cleanup remains best effort; the account-deletion
path now uses explicit strict variants.

### Remediation RED

Command:

```text
flutter test test/account_cleanup_test.dart test/account_hardening_test.dart test/push_service_test.dart
```

Expected result before remediation production changes: exit 1. Compilation
failed on the requested contracts, including:

```text
Member not found: 'WordImageService.deleteAllStrict'
Member not found: 'TtsService.clearCacheStrict'
Member not found: 'Storage.resetAllStrict'
The method 'disableStrict' isn't defined for the type 'PushService'
Type 'AccountDeletionRecoveryException' not found
Type 'AccountDeletionFailure' not found
Method not found: 'AccountDeletionCleanupAdapter'
Method not found: 'SubscriptionManagementLauncher'
No named parameter with the name 'subscriptionManager'
```

No remediation production code had been changed before this RED run.

### Remediation implementation

- Added strict account-deletion cleanup variants for push ownership, app-owned
  preferences, word images, and the TTS cache. Each independent cleanup is
  attempted and failures are aggregated. The existing ordinary methods retain
  best-effort behavior.
- The production deletion adapter now exclusively invokes those strict
  variants. The workflow stops local destruction for pre-delete remote errors,
  but after irreversible Firebase-user deletion it still attempts storage,
  push, image, TTS, and in-memory cleanup before returning one aggregate error.
- Added a typed post-delete recovery failure. Google sign-out runs only for a
  linked Google provider, anonymous recovery still runs after sign-out failure,
  and a failed anonymous creation is retried once without retrying deletion of
  the already-removed Firebase user.
- Preserved Task 2's strict old-token invalidation. Push rebinding now fails on
  a missing UID, while unsupported messaging and ordinary permission denial
  remain non-errors.
- Subscription management now returns no route for web, Windows, Linux, or
  Fuchsia. The production launcher receives `kIsWeb`, and injected launcher
  failure is surfaced through the existing localized Settings error state.
- Added the recent-login retry test proving that a fresh Apple authorization
  code is obtained and revoked before the retry deletion.

### Remediation focused GREEN

```text
flutter test test/account_cleanup_test.dart test/account_hardening_test.dart test/push_service_test.dart
00:03 +43: All tests passed!
```

The focused suite includes real coordinator-plus-workflow integration coverage:
a pre-delete cloud failure performs no destructive local cleanup, while a
post-delete recovery failure performs every local privacy cleanup and reports
failure. It also covers strict failure aggregation, false preference-removal
results, missing-UID rebinding, and denied-permission non-error behavior.

### Remediation validation

```text
flutter analyze
Analyzing ko_lernen_app-release-hardening...
No issues found! (ran in 9.9s)
```

Fresh full regression:

```text
flutter test
00:28 +597: All tests passed!
```

Whitespace verification:

```text
git diff --check
```

Result: exit 0 with only normal Windows line-ending conversion warnings.
