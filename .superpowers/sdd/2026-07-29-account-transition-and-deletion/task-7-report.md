# Task 7 report: App Check and typed server account operations

## Status

Implemented and locally verified.

The Flutter client now activates App Check before protected Firebase-backed
startup work, restores a durable cloud-write fence only after obtaining the
live Firebase Auth UID, and uses typed callable DTOs for server-owned account
deletion. The client no longer creates deletion markers, deletes the Firestore
user root, calls `User.delete()`, or revokes Apple authorization directly.

No Firebase configuration was deployed. No Functions, Firestore rules, public
pages, UI routing, localization, sync reconciliation, plan, or progress ledger
was changed.

## Files

### Created

- `lib/services/account/account_operation_client.dart`
  - Typed account-operation kind, phase, blocked-reason, result, request, and
    failure models.
  - Injectable transport boundary with the production
    `FirebaseFunctions.instanceFor(region: 'europe-west3')` adapter.
  - Strict callable response validation and fixed safe error mapping.
  - Bounded retry only for idempotent `getAccountOperation` reads.
  - Non-retrying deletion request and Apple revocation completion calls.
- `lib/services/account/firebase_app_check_initializer.dart`
  - Debug providers only for debug builds.
  - Android Play Integrity for non-debug builds.
  - Apple App Attest with DeviceCheck fallback for non-debug builds.
- `test/services/account/account_operation_client_test.dart`
  - Provider-selection, region, DTO, safe-failure, malformed-response,
    status-only retry, Apple completion, and value equality/hash coverage.
- `test/services/app_startup_coordinator_test.dart`
  - App Check ordering, live-UID restoration, non-ready operation resumption,
    and fail-closed startup coverage.
- `test/services/auth_service_test.dart`
  - Server request/status polling, transient Apple-code handling, direct-delete
    interface removal, and unknown-outcome persistence/fencing/resume coverage.

### Modified

- `lib/main.dart`
  - Wires App Check into startup before Remote Config, RevenueCat, push, and
    pending account-operation resumption.
  - Uses fixed cloud-startup log text rather than raw Firebase error strings.
- `lib/services/app_startup_coordinator.dart`
  - Orders Firebase, App Check, auth, live-UID journal restoration, and protected
    startup work.
  - Resumes a restored non-ready operation and skips unrelated side effects.
- `lib/services/auth_service.dart`
  - Replaces client-owned destructive deletion with request/status/Apple
    completion callables.
  - Adds a non-secret, versioned SharedPreferences deletion journal.
  - Persists the quiesced/blocked/cleanup-pending cloud-write session and exact
    operation ID.
  - Removes client marker creation, user-root deletion, `User.delete()`, and
    client Apple revocation.
  - Keeps backup-only field/subcollection deletion separate.
- `test/app_startup_coordinator_test.dart`
  - Updates the existing startup regression suite for App Check and live-UID
    session restoration ordering.
- `test/account_hardening_test.dart`
  - Marks eleven obsolete client-owned deletion cases as superseded by the new
    positive typed server-operation tests.
  - Keeps local privacy cleanup and subscription-management coverage active.
- `test/gye_hardening_test.dart`
  - Removes obsolete assertions for client marker creation and root deletion;
    retains backup-only cleanup coverage.

## RED

Initial focused command:

```text
flutter test test/services/account/account_operation_client_test.dart test/services/app_startup_coordinator_test.dart test/services/auth_service_test.dart
```

Observed exit 1 after 50.3 seconds. Expected failures showed:

- missing `account_operation_client.dart`
- missing `firebase_app_check_initializer.dart`
- no `initializeAppCheck` or live-UID session-restoration startup boundary
- `AccountDeletionOperations` still required direct cloud-data deletion,
  Firebase user deletion, and client Apple revocation

Self-review regression RED:

```text
flutter test test/services/account/account_operation_client_test.dart --plain-name "transport call equality has an order-independent hash"
```

Observed exit 1 because equal calls with differently ordered maps produced
different hash codes.

## GREEN

- Focused Task 7 suite: 13/13 passed before the self-review regression addition.
- Equality/hash regression: 1/1 passed after the deterministic hash fix.
- Relevant account/push/session suites: 56 passed; obsolete direct-deletion
  cases were skipped.
- Full Flutter suite before the final verification gate: 813 passed, 11
  obsolete legacy cases skipped, exit 0.
- `flutter analyze`: no issues found.

Final verification after all changes:

- Focused Task 7 suite: 14/14 passed, exit 0 in 7.7 seconds.
- Full Flutter suite: 814 passed, 11 obsolete legacy cases skipped, exit 0 in
  52 seconds.
- `flutter analyze`: no issues found, exit 0 in 18.3 seconds.
- `dart format --set-exit-if-changed` across all 11 changed Dart files:
  0 files changed, exit 0.

## Commit

Requested commit subject:

```text
feat(account): use App Check and server deletion operations
```

The resulting commit hash is reported in the Task 7 handoff because a commit
cannot contain its own final hash.

## Self-review

- Confirmed App Check activation precedes pending-operation status reads and all
  other protected Firebase-backed startup steps.
- Confirmed release provider selection is Play Integrity on Android and App
  Attest with DeviceCheck fallback on Apple; debug providers are selected only
  when `kDebugMode` is true.
- Confirmed startup passes the UID read from live Firebase Auth into
  `CloudWriteSessionController.resume(expectedUid: ...)`; it is never sourced
  from journal metadata.
- Confirmed a restored non-ready session resumes the existing operation and
  suppresses premium/push/other startup side effects.
- Confirmed only status reads retry and are capped at three transport attempts.
- Confirmed request and Apple completion calls never retry automatically.
- Confirmed DTO parsing rejects unknown kinds/phases, negative versions,
  inconsistent blocked reasons, and non-map responses.
- Confirmed raw callable messages/details are not rendered or logged.
- Confirmed the Apple authorization code is passed only to the transient server
  completion callable and is absent from journal JSON.
- Confirmed an unknown status outcome persists the operation ID, transitions the
  write session to blocked, and restart polls that ID without requesting a new
  deletion.
- Confirmed the production Flutter source contains no direct Firebase Auth user
  deletion, client Apple token revocation, deletion-marker creation, or
  Firestore user-root deletion.
- Confirmed backup-only field deletion remains intentionally separate from
  account deletion.

## Concerns and external gates

- No real App Check debug token, Play Integrity verdict, App Attest verdict, or
  DeviceCheck fallback was obtained or logged. Signed Android and Apple device
  verification remains a release gate.
- The current initializer intentionally has no web reCAPTCHA provider. Web
  protected cloud startup therefore remains fail-closed until a separately
  reviewed web App Check configuration is supplied.
- No live/emulator callable integration was run. Callable IAM, App Check
  enforcement, auth-token freshness after provider reauthentication, server
  worker progress, and status reads after server-side Auth deletion remain
  deployment-stage gates.
- If the initial non-idempotent deletion request reaches the server but its
  response is lost before an operation ID is received, the client durably
  freezes and does not issue a new deletion request. The current server API has
  no read-by-request-key recovery callable, so resolving that particular
  response-loss state requires future server support or an operator-assisted
  recovery path.
- Eleven old tests that asserted the removed client-owned destructive sequence
  remain explicitly skipped for historical visibility. Their replacement
  coverage is in the new positive server-operation tests.

---

## Review fix round 1/5: deletion coordinator contracts

This section supersedes the initial report's statements about eleven skipped
legacy deletion tests. That skipped group and its obsolete direct-deletion
fakes have now been removed. The replacement server-operation coverage is
active, and the full Flutter suite contains no `skip:` declarations.

### Findings resolved

- The deletion coordinator now requires
  `PushOwnershipTransitionCoordinator.run` to return
  `CloudWriteResult.completed`. Missing, mismatched, stale, and otherwise
  non-completed session outcomes fail with a safe typed blocked result before
  local cleanup can report success.
- A successful accepted ownership transition returns `completed` while the
  session remains durably frozen in `cleanupPending`.
- Missing Apple authorization, dual-linked provider selection, recent-auth
  prerequisites, typed pre-request failures, server-blocked operations,
  post-server identity recovery, and recovery-failure cleanup behavior all
  have active server-contract tests.
- Raw Firebase reauthentication and push-removal failures are converted at the
  coordinator boundary to safe `AccountOperationFailure` values. Known recent
  login, authentication, permission, network, and unavailable codes retain a
  safe typed meaning; raw provider messages are never copied to display text.
- Status and Apple-completion responses must match the requested operation ID
  before they can replace or be written into the journal.
- Resume requires the current cloud-write session to exactly equal the journal
  session by UID, epoch, and mode before polling or transitioning. Missing and
  unrelated sessions are rejected without polling, journaling, or mutation.
- After server-confirmed deletion, the production adapter signs out linked
  Google state when applicable, signs out Firebase Auth, and retries anonymous
  identity creation once. Recovery failures retain the established safe
  post-deletion cleanup contract.

### RED evidence

The focused regression command initially failed as expected:

```text
flutter test test/services/auth_service_test.dart test/services/push_ownership_transition_coordinator_test.dart
```

Observed failures proved that missing and mismatched ready sessions returned
success, and that accepted ownership transitions returned `blocked` instead of
an unambiguous successful result.

### GREEN and final verification

- Relevant account/transition/cleanup suite: 41/41 passed.
- Full Flutter suite: 831/831 passed, zero skipped, exit 0.
- `flutter analyze`: no issues found, exit 0.
- `dart format --set-exit-if-changed` across the five fix-round Dart files:
  0 files changed, exit 0.
- `git diff --check`: clean; only Git's informational LF-to-CRLF worktree
  warnings were emitted.
- Repository-wide `rg -n "skip:" test`: no matches.

### Fix-round files

- `lib/services/auth_service.dart`
- `lib/services/push_service.dart`
- `test/services/auth_service_test.dart`
- `test/services/push_ownership_transition_coordinator_test.dart`
- `test/account_hardening_test.dart`

### Remaining external gates

The initial report's device App Check and live callable integration gates remain
unchanged. No Functions, Firestore rules, Firebase configuration, deployment,
UI localization, or public-page work was performed in this fix round.

### Fix-round commit

Requested subject:

```text
fix(account): harden deletion coordinator contracts
```
