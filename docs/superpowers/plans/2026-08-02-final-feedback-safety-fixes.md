# Final Feedback Safety Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the final review's account-boundary, deletion, feedback-queue, reward-idempotency, release-default, and terminal-card regression gaps without changing the intended tester-feedback product behavior.

**Architecture:** Feedback delivery is bound to the outbox item's original Firebase UID and the callable rejects a request whose authenticated UID differs. Account deletion uses the existing authoritative `requestAccountDeletion` operation as the remote barrier before the local feedback service is closed and discarded. Terminal failures leave no permanently blocked hidden outbox records; listening completion coalesces one in-flight reward per session generation; premium unlock defaults safely off unless an internal build explicitly opts in.

**Tech Stack:** Flutter/Dart, Firebase Callable Functions (Node), Firestore emulator tests, Flutter widget/service tests, existing account-operation deletion journal.

## Global Constraints

- Work only in `codex/content-feedback-design-2026-07-31`; do not modify `main`, merge, push, fetch, rebase, deploy Firebase, create/sign an AAB, or change release credentials.
- User-visible app copy remains German and English only. Do not add Korean UI strings.
- Never serialize custom-pack names, extracted/OCR text, answers, raw listening text, raw gestures, or free-text feedback under a different account UID.
- The server must continue to use `request.auth.uid` as the sole storage authority; an expected UID is a mismatch guard, never an authorization grant.
- Preserve existing callable App Check, authentication, rate-limit, idempotency, Firestore-denial, and account-tree deletion protections.
- Preserve opaque content IDs, current feedback types/missions, score behavior, and production loader defaults.
- Every behavior change begins with a deterministic failing regression; do not increase a guard baseline or weaken a test to make it pass.

---

### Task 1: Bind feedback delivery to the original account and establish deletion barrier first

**Files:**
- Modify: `lib/services/content_feedback_client.dart`
- Modify: `lib/services/content_feedback_service.dart`
- Modify: `lib/services/auth_service.dart`
- Modify: `lib/screens/settings_screen.dart`
- Modify: `lib/main.dart` if the existing startup deletion-resume wiring needs the same callback
- Modify: `functions/gye/tester_feedback_runtime.js`
- Modify: `functions/gye/tester_feedback_runtime.test.js`
- Modify: `test/content_feedback_outbox_test.dart`
- Modify: `test/account_hardening_test.dart` and/or existing account-operation service tests
- Modify: `functions/gye/account_operations_runtime.test.js` only if a server-level deletion/feedback ordering case belongs there

**Interfaces:**
- Consumes: an outbox record's existing immutable `ownerUid`, `requestAccountDeletion`'s existing idempotent operation/journal behavior, and the callable's authenticated request UID.
- Produces: a schema-v2 feedback request carrying `expectedOwnerUid`; the callable rejects any missing/v1/mismatched UID before feedback/passport/rate-limit writes. The deletion coordinator invokes a feedback-close callback only after the remote deletion operation is created and written to the local journal, before polling or local account cleanup.

- [ ] **Step 1: Write failing feedback ownership and callable schema regressions**

Add deterministic tests that prove each of the following fails on the pre-fix code:

```dart
// An item created by account A is delivered with A as its expected owner even
// if the live auth lookup changes before the callable resolves.
expect(client.expectedOwnerUids, ['account-a']);

// If the account changes after the callable returns, the old-owner record is
// discarded and is not resumed for the new account.
expect(await outbox.readAll(), isEmpty);
```

```js
// request.auth.uid is still the storage authority. A mismatch is rejected
// before feedback, passport, or rate-limit documents are written.
await assert.rejects(
  handlers.submitTesterFeedback(callableRequest("account-b", {
    ...validPayloadV2,
    expectedOwnerUid: "account-a",
  })),
  { code: "permission-denied" },
);
```

Cover an auth match, a changed account, a forged expected UID, and missing/v1 schema. Assert no writes for every rejection.

- [ ] **Step 2: Run the focused ownership tests to verify RED**

Run the smallest relevant Flutter outbox test selection and the Functions runtime test selection. Record the exact failure caused by the absence of a client expected-owner field / server mismatch validation.

- [ ] **Step 3: Implement schema-v2 owner binding without trusting the client**

Change the Dart client interface to require `expectedOwnerUid` for every submit, pass the attempted outbox item's `ownerUid` in both immediate and resume paths, and serialize:

```json
{
  "schemaVersion": 2,
  "expectedOwnerUid": "<immutable-outbox-owner>"
}
```

In the callable, require schema version `2`, validate a bounded non-empty expected UID, compare it to `request.auth.uid`, and reject mismatch with a safe `permission-denied` failure before its transaction. Keep Firestore paths derived only from `request.auth.uid`; do not persist the expected UID. After a successful/failed callable returns, recheck live ownership and discard an attempted record if the account changed rather than retrying it under the next account.

- [ ] **Step 4: Write failing deletion ordering and recovery regressions**

Add a test seam around the existing account deletion coordinator so tests can observe the sequence. Required cases:

```dart
// A remote request failure must leave feedback open and queued.
expect(events, ['reauth', 'request-failed']);
expect(closeCalls, 0);

// Once the idempotent operation is written to the local deletion journal,
// close/discard happens before the first poll.
expect(events, ['request', 'journal', 'close-feedback', 'poll']);

// A close failure keeps the journal and does not begin the poll; a resumed
// operation retries close before polling.
expect(events, ['request', 'journal', 'close-failed']);
```

Keep the existing in-flight submit test and extend it so a deletion operation created before closing is the authoritative server barrier.

- [ ] **Step 5: Implement the existing-operation deletion barrier ordering**

Add an idempotent coordinator callback that closes/discards feedback after `requestAccountDeletion` returns and its operation has been journaled, but before polling. Pass the production `ContentFeedbackService.closeAndDiscard` callback through Settings and startup resume wiring. Remove Settings' earlier pre-request close. If the remote request fails before a barrier exists, do not close feedback. If close fails after the barrier exists, retain the deletion journal, do not poll/claim success, and retry the close callback first when the operation resumes.

Do not create a second deletion-marker collection: the existing server account operation is the authoritative barrier and already blocks feedback transactions. Preserve the existing worker's user-tree cleanup; add an emulator regression that a feedback/passport/rate-limit document made before the operation is removed by the account tree deletion.

- [ ] **Step 6: Run focused ownership, deletion, and Function regressions to verify GREEN**

Run the affected Flutter outbox/account tests and Functions runtime/deletion tests. Verify a v2 matching owner remains idempotent, mismatches make no writes, failure-before-barrier leaves feedback usable, and close-after-barrier precedes poll.

- [ ] **Step 7: Commit the account-boundary repair**

```bash
git add lib/services/content_feedback_client.dart lib/services/content_feedback_service.dart lib/services/auth_service.dart lib/screens/settings_screen.dart lib/main.dart functions/gye/tester_feedback_runtime.js functions/gye/tester_feedback_runtime.test.js test/content_feedback_outbox_test.dart test/account_hardening_test.dart functions/gye/account_operations_runtime.test.js
git commit -m "fix(feedback): bind delivery to account deletion barrier"
```

### Task 2: Prevent terminal failures from exhausting feedback and strengthen shared terminal-card privacy coverage

**Files:**
- Modify: `lib/services/content_feedback_service.dart`
- Modify: `lib/services/content_feedback_outbox.dart` only if a small cleanup helper is needed
- Modify: `test/content_feedback_outbox_test.dart`
- Modify: `test/shared_game_feedback_route_test.dart`

**Interfaces:**
- Consumes: persisted `pending`/legacy `blocked` outbox records and current non-retryable `ContentFeedbackClientFailure` semantics.
- Produces: terminal failures are reported to the UI but do not leave a non-resumable record consuming capacity; legacy blocked records are removed safely. Every shared real terminal route renders a `ContentFeedbackCard` when an enabled `ContentFeedbackControllerScope` is present.

- [ ] **Step 1: Write failing terminal-failure and terminal-card tests**

Add regressions for the real terminal behavior:

```dart
// Permission-denied is terminal: result is failed, but the durable queue is
// empty and a later new feedback submission can be accepted.
expect(result.status, ContentFeedbackSubmitStatus.failed);
expect(await outbox.readAll(), isEmpty);

// Legacy blocked records are cleaned during resume/admission and cannot make
// a 20-item queue permanently full.
expect(await service.resumePending(), isA<ContentFeedbackResumeResult>());
expect(await outbox.readAll(), isEmpty);
```

In the shared-game terminal test wrapper, install an enabled controller scope with an inert submitter, then assert exactly one real `ContentFeedbackCard` after each real game end. For the long custom pack fixture, assert every serialized string lacks the pack name, Korean extracted word, and translations as substrings, not merely whole-value equality.

- [ ] **Step 2: Run focused tests to verify RED**

Run the outbox and shared-game terminal files. Expected failures: non-retryable records remain `blocked`/consume capacity, shared routes lack a rendered card under the test wrapper, and the stricter substring assertion is not present.

- [ ] **Step 3: Implement terminal failure discard and bounded legacy cleanup**

For a non-retryable delivery failure, remove the attempted durable record instead of saving it as permanently blocked; still return the existing failed result for UI messaging. If a removal write fails, keep the prior durable pending record rather than silently losing it. During ownership cleanup/resume/admission, remove legacy `blocked` records so old installs recover capacity. Retain parsing compatibility for `blocked` data; do not make a terminal failure retry indefinitely.

Add only test-scope wiring for `ContentFeedbackControllerScope`; do not alter shared-game production completion behavior.

- [ ] **Step 4: Run focused tests to verify GREEN**

Run the outbox and shared game route suites. Assert that retryable failures remain pending, non-retryable failures do not occupy capacity, old blocked records are reclaimed, all seven terminal routes render their visible feedback card under an enabled scope, and custom fixture text is absent from every wire string.

- [ ] **Step 5: Commit the feedback queue and route-coverage repair**

```bash
git add lib/services/content_feedback_service.dart lib/services/content_feedback_outbox.dart test/content_feedback_outbox_test.dart test/shared_game_feedback_route_test.dart
git commit -m "fix(feedback): reclaim terminal outbox failures"
```

### Task 3: Make listening completion rewards idempotent per session generation

**Files:**
- Modify: `lib/models/feedback_completion.dart`
- Modify: `lib/screens/listening_screen.dart` only if the model-level coalescing requires existing UI state to observe completion
- Modify: `test/dedicated_feedback_completion_test.dart`
- Modify: `test/dedicated_feedback_route_test.dart` if a real double-tap completion regression belongs at the screen boundary

**Interfaces:**
- Consumes: `ListeningFeedbackCompletionState.finish` and `reset` lifecycle.
- Produces: repeated `finish` calls for one current listening generation return the same in-flight/completed result and invoke reward persistence exactly once; `reset()` creates a new independent generation.

- [ ] **Step 1: Write failing concurrent-finish regressions**

Use a `Completer`-controlled persistence callback to make two calls overlap:

```dart
final first = state.finish(persistXp: persist);
final second = state.finish(persistXp: persist);
expect(persistCalls, 1);
completer.complete();
expect(await first, same(await second));
```

Add a reset case proving a stale completion cannot clear or reuse the next generation's in-flight result. If the real button remains enabled during async completion, drive its rapid double tap and assert XP persistence exactly once.

- [ ] **Step 2: Run focused tests to verify RED**

Run the dedicated feedback completion test selection. Expected failure: the pre-fix state calls persistence twice for concurrent completion.

- [ ] **Step 3: Implement generation-safe Future coalescing**

Store the current generation's in-flight `Future<FeedbackCompletion?>` in `ListeningFeedbackCompletionState`. On a second finish in the same generation, return that future rather than creating/persisting again. On reset, advance/invalidate the generation and permit a new future. Only clear an in-flight field if the completing future still belongs to its generation; do not let an old future erase new-session state. Preserve existing feedback slot idempotency, haptics, mounted checks, and score values.

- [ ] **Step 4: Run focused tests to verify GREEN**

Run the dedicated completion and listening route tests. Verify exactly one XP persistence and one feedback allocation per session, then a clean reset/new round can persist once again.

- [ ] **Step 5: Commit the listening reward repair**

```bash
git add lib/models/feedback_completion.dart lib/screens/listening_screen.dart test/dedicated_feedback_completion_test.dart test/dedicated_feedback_route_test.dart
git commit -m "fix(listening): coalesce concurrent completion rewards"
```

### Task 4: Make release entitlement safe by default while retaining explicit internal beta unlock

**Files:**
- Modify: `lib/services/premium_service.dart`
- Modify: `BETA_INSTALL_GUIDE.md`
- Create or modify: `test/premium_release_default_test.dart`

**Interfaces:**
- Consumes: `bool.fromEnvironment('BETA_UNLOCK_ALL', ...)` and existing internal beta build instructions.
- Produces: premium is locked by default in a build with no define; an internal beta remains explicitly unlockable with `--dart-define=BETA_UNLOCK_ALL=true`.

- [ ] **Step 1: Write a failing release-default source contract test**

Add a focused source contract test that reads `premium_service.dart` and requires the exact safe default:

```dart
expect(
  source,
  contains("bool.fromEnvironment('BETA_UNLOCK_ALL', defaultValue: false)"),
);
```

This must fail on the current `defaultValue: true`; do not mutate a runtime environment or weaken entitlement tests to simulate the result.

- [ ] **Step 2: Run the source contract test to verify RED**

Run `flutter test --no-pub test/premium_release_default_test.dart` and record the expected failure.

- [ ] **Step 3: Implement safe default and explicit beta documentation**

Change only the environment default in `PremiumService.betaUnlockAll` to `false`. Keep the existing explicit environment key. Update the Android internal beta build command in `BETA_INSTALL_GUIDE.md` to include `--dart-define=BETA_UNLOCK_ALL=true` so internal testers retain the intended unlocked experience. Do not change purchase/restore logic or user-visible strings.

- [ ] **Step 4: Run release/default tests to verify GREEN**

Run the new source contract test and existing premium tests. Verify source default is false and documentation shows explicit beta opt-in.

- [ ] **Step 5: Commit the release-default repair**

```bash
git add lib/services/premium_service.dart BETA_INSTALL_GUIDE.md test/premium_release_default_test.dart
git commit -m "fix(premium): default beta unlock off"
```

### Task 5: Verify final safety repair without external release actions

**Files:**
- Modify: `.superpowers/sdd` report artifacts only (ignored)

- [ ] **Step 1: Run generated-localization and all focused safety suites**

Run:

```bash
flutter gen-l10n
flutter test --no-pub test/content_feedback_outbox_test.dart test/shared_game_feedback_route_test.dart test/dedicated_feedback_completion_test.dart test/dedicated_feedback_route_test.dart test/premium_release_default_test.dart
npm.cmd --prefix functions/gye test -- tester_feedback_runtime.test.js account_operations_runtime.test.js deletion_adapters.test.js
```

If the repository has a different documented filtered Node test invocation, use it only when it runs those exact tests and record it.

- [ ] **Step 2: Run full Flutter, Functions, static, and formatting checks**

Run:

```bash
flutter test --no-pub
flutter analyze --no-pub
npm.cmd --prefix functions/gye test
git diff --check
```

Run the existing Firestore emulator rules suite if its local documented environment is available; otherwise record the exact environmental reason and do not claim it passed.

- [ ] **Step 3: Verify boundaries**

Confirm all current ARB changes remain only `lib/l10n/app_de.arb` and `lib/l10n/app_en.arb` against merge base `10ae1c2`. Confirm no deployment, signed AAB, remote push, merge, fetch, rebase, or credential change occurred.

- [ ] **Step 4: Commit only a needed verification correction**

If no verification source correction is needed, create no empty commit. Record exact commands, exit codes, counts, and any unavailable external emulator check in the task report.

## Self-Review

- Task 1 covers the account-switch TOCTOU and deletion-in-flight remote storage path with the existing server operation as the only deletion barrier.
- Task 2 prevents terminal error state from permanently locking feedback and closes the final shared-route privacy/card coverage gaps.
- Task 3 prevents duplicate listening XP under rapid taps without blocking a fresh session after reset.
- Task 4 makes absent build defines release-safe while preserving explicit internal beta access.
- Task 5 validates Flutter and Functions paths without pretending an external deployment or package was made.
