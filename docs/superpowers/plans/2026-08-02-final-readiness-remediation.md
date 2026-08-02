# Final Tester Readiness Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the verified feedback branch usable and safe after account deletion, ensure documented internal tester builds actually expose feedback, and close the remaining mobile interaction and outbox-recovery edge cases before integration.

**Architecture:** A feedback lifecycle owner replaces a permanently closed service only after an authoritative deletion has fully completed, local cleanup/checkpoint removal succeeded, and a different valid anonymous UID exists. It never reopens an old service. Small hardening fixes use existing primitives: explicit build defines in authoritative runbooks, opt-in 44px chip targets, and a saturated retry counter.

**Tech Stack:** Flutter/Dart, existing AuthService deletion coordinator/checkpoint, ContentFeedbackService/outbox, widget/service tests, Markdown runbooks.

## Global Constraints

- Work only on `codex/content-feedback-design-2026-07-31`; do not modify `main`, merge, push, fetch, rebase, deploy Firebase, create/sign an AAB, or change credentials.
- User-visible application UI remains German and English only. Do not add Korean UI strings.
- Never reopen a closed feedback service while a deletion/transition journal exists, while prior outbox persistence may survive, or for the deleted/empty UID.
- An old closed service remains closed forever; only a freshly constructed instance may serve a confirmed new identity.
- Preserve all account-bound schema-v2, App Check, auth, rate-limit, idempotency, deletion-barrier, and final-authoritative-clear protections.
- Tester-only build instructions must explicitly enable tester feedback and beta unlock; production instructions must omit the tester-feedback define and explicitly set `BETA_UNLOCK_ALL=false`.
- Every production behavior change needs a deterministic RED then GREEN regression; no release, device install, package build, or backend deployment is authorized in this plan.

---

### Task 1: Replace feedback service only after a completed deletion creates a safe new identity

**Files:**
- Create: `lib/services/content_feedback_lifecycle.dart` (or equivalent focused lifecycle owner)
- Modify: `lib/main.dart`
- Modify: `lib/services/auth_service.dart`
- Modify: `lib/services/content_feedback_service.dart`
- Modify: `lib/screens/settings_screen.dart` only if dependency wiring requires it
- Modify: `test/content_feedback_outbox_test.dart`
- Modify: `test/services/auth_service_test.dart`
- Modify: `test/account_hardening_test.dart` and/or existing deletion checkpoint tests
- Create or modify: focused lifecycle/widget integration test under `test/services/` or `test/widgets/`

**Interfaces:**
- Consumes: a factory for a new `ContentFeedbackService`, its `closeAndDiscard` barrier, current authenticated UID lookup, and authoritative account-deletion checkpoint state.
- Produces: stable `submit`, `resumePending`, and passport read entrypoints that delegate to the current service; `activateAfterCompletedDeletion(deletedUid)` replaces it only after local completion and a new UID is proved safe.

- [ ] **Step 1: Write failing post-deletion lifecycle and passport-gate regressions**

Create deterministic tests that simulate the real operation order, not a manually reopened old service:

```dart
// Old owner service closes and erases; completed deletion yields a different
// anonymous UID. The lifecycle owner creates a new service and a fresh
// feedback submission is accepted with the new owner UID.
expect(oldService.isClosed, isTrue);
expect(newClient.expectedOwnerUids, ['new-anonymous-uid']);

// Same/empty UID or an outstanding deletion/checkpoint never activates a
// replacement service.
expect(await lifecycle.activateAfterCompletedDeletion('old-uid'), isFalse);
```

Add failure/restart cases: remote deletion failure and local-cleanup failure leave the old service closed; a resumed completed deletion recognizes an already-created *different anonymous* UID as recovered, but never accepts a different non-anonymous signed-in account. Add a preexisting closed-service test proving old queued work cannot run after replacement. Add a deletion-gate regression that `readPassportState`, like submit/resume, makes no remote/outbox access while a deletion journal is active.

- [ ] **Step 2: Run the focused tests to verify RED**

Run the lifecycle/auth/checkpoint/outbox selections. Expected failures: global final service cannot serve new owner after deletion, completed-checkpoint recovery rejects an already-created new anonymous user, and passport reads are not deletion-gated.

- [ ] **Step 3: Implement a replacement-only feedback lifecycle owner**

Introduce a small lifecycle owner that retains stable callbacks for `ContentFeedbackControllerScope` but owns the current service instance. Its replacement operation must:

1. require the old service's successful permanent close/final clear;
2. require no durable deletion/transition journal remains;
3. require a non-empty current UID different from the completed deleted UID and, for recovery, prove it is anonymous;
4. construct a fresh service with the normal production dependencies; and
5. atomically switch future entrypoints to it without reopening or draining the old instance.

Wire `main.dart` scopes/callbacks through this owner rather than a process-global final service. Extend the deletion coordinator/AuthService at the existing **post-local-cleanup, post-checkpoint-removal** completion point to call the lifecycle activation callback. During startup resume, keep service closed while a journal exists; after a verified completed deletion and new anonymous UID, invoke the same safe activation.

Do not use `closed = false` or a general reopen method. Preserve failure behavior: if any deletion/local cleanup/activation condition fails, retain journal/closed service and let normal retry/restart recover.

Apply the same deletion gate to passport reads before any remote call.

- [ ] **Step 4: Run focused tests to verify GREEN**

Run the focused lifecycle, auth/checkpoint, settings, and feedback outbox suites. Verify old service never sends after close; new anonymous UID gets a new service and feedback can submit; same/empty/non-anonymous UID cannot activate; completed checkpoint recovery is idempotent; journal-gated passport read makes no calls.

- [ ] **Step 5: Commit the post-deletion lifecycle repair**

```bash
git add lib/services/content_feedback_lifecycle.dart lib/main.dart lib/services/auth_service.dart lib/services/content_feedback_service.dart lib/screens/settings_screen.dart test/content_feedback_outbox_test.dart test/services/auth_service_test.dart test/account_hardening_test.dart test/services/account
git commit -m "fix(feedback): replace service after completed deletion"
```

### Task 2: Make tester runbooks, feedback chip targets, and retry boundary release-ready

**Files:**
- Modify: `BETA_INSTALL_GUIDE.md`
- Modify: `docs/store/closed-testing-checklist-v2.md`
- Modify: `lib/widgets/sori/content_feedback_sheet.dart`
- Modify: `lib/services/content_feedback_outbox.dart`
- Modify: `lib/services/premium_service.dart`
- Modify: `test/content_feedback_widget_test.dart`
- Modify: `test/content_feedback_outbox_test.dart`
- Create or modify: `test/tester_build_release_contract_test.dart`

**Interfaces:**
- Consumes: existing `SoriChip.minInteractiveHeight`, `ENABLE_TESTER_FEEDBACK`, `BETA_UNLOCK_ALL`, outbox retry JSON/validation, and documented Android tester commands.
- Produces: all structured feedback choices have 44px targets at 390px, max valid retry count is recoverable, and source/doc contracts make tester-vs-production defines unambiguous.

- [ ] **Step 1: Write failing runbook, chip, and retry-boundary regressions**

Add focused tests that fail on the current branch:

```dart
// Each documented internal APK/AAB block includes both explicit tester flags;
// production AAB has beta false and no feedback-enable define.
expect(internalCommand, contains('--dart-define=ENABLE_TESTER_FEEDBACK=true'));
expect(internalCommand, contains('--dart-define=BETA_UNLOCK_ALL=true'));
expect(productionCommand, contains('--dart-define=BETA_UNLOCK_ALL=false'));
expect(productionCommand, isNot(contains('ENABLE_TESTER_FEEDBACK=true')));

// At 390x844 every Bug/Content/Signal/Focus structured choice remains within
// viewport, at least 44px high, tappable, and updates selected state.
expect(tester.getSize(chip).height, greaterThanOrEqualTo(44));

// A persisted retryable item at exactly max attempt count resumes without a
// FormatException and remains valid at the saturated count.
expect(item.retry.attemptCount, feedbackOutboxMaxAttemptCount);
```

- [ ] **Step 2: Run focused tests to verify RED**

Run the new runbook contract, feedback widget, and outbox boundary tests. Expected failures: commands omit defines, chips use intrinsic small height, and max count increments past validation ceiling.

- [ ] **Step 3: Implement minimal release/readiness hardening**

Update both authoritative internal tester commands to include exactly:

```text
--dart-define=ENABLE_TESTER_FEEDBACK=true --dart-define=BETA_UNLOCK_ALL=true
```

Place a clearly labeled production AAB command adjacent to them with `--dart-define=BETA_UNLOCK_ALL=false` and no feedback-enable define. Preserve other commands/documentation.

Pass `minInteractiveHeight: 44` to each structured feedback-sheet choice chip only; do not globally resize unrelated chips. Declare a shared `feedbackOutboxMaxAttemptCount` constant, use it in validation, and saturate `recordAttempt()` at that value so a valid persisted max item cannot wedge resume. Keep it pending/retryable; do not discard user feedback merely because it reached the counter cap. Replace the obsolete/corrupted premium comment with a concise accurate statement that absence of the define leaves normal entitlement gating on.

- [ ] **Step 4: Run focused tests to verify GREEN**

Run source/doc contract, feedback-sheet 390px interaction, outbox boundary, and existing premium tests. Verify all internal command blocks are usable, production remains safe, all structured choices remain visible/tappable, and saturated retry resumes without exception.

- [ ] **Step 5: Commit the final readiness hardening**

```bash
git add BETA_INSTALL_GUIDE.md docs/store/closed-testing-checklist-v2.md lib/widgets/sori/content_feedback_sheet.dart lib/services/content_feedback_outbox.dart lib/services/premium_service.dart test/content_feedback_widget_test.dart test/content_feedback_outbox_test.dart test/tester_build_release_contract_test.dart
git commit -m "fix(tester): harden feedback readiness defaults"
```

### Task 3: Verify final readiness without packaging or deployment

**Files:**
- Modify: `.superpowers/sdd` report artifacts only (ignored)

- [ ] **Step 1: Run focused lifecycle and readiness suites**

Run:

```bash
flutter gen-l10n
flutter test --no-pub test/content_feedback_outbox_test.dart test/content_feedback_widget_test.dart test/services/auth_service_test.dart test/account_hardening_test.dart test/tester_build_release_contract_test.dart
```

- [ ] **Step 2: Run full validation**

Run:

```bash
flutter test --no-pub --reporter compact
flutter analyze --no-pub
npm.cmd --prefix functions/gye test
git diff --check
```

Run the documented Firestore emulator rules suite with the local Android Studio JBR only for that command if Java is otherwise unavailable; record exact outcome. Do not persist environment changes.

- [ ] **Step 3: Verify integration boundaries**

Confirm current ARB changes versus `10ae1c2` remain exactly `lib/l10n/app_de.arb` and `lib/l10n/app_en.arb`. Confirm tracker build documentation contains internal and production commands as specified. Confirm no deployment, package, signing, remote push, merge, fetch, rebase, or credential action occurred.

- [ ] **Step 4: Commit only a needed verification correction**

If no source correction is needed, create no empty commit. Record exact commands, exit codes, test counts, and any unavailable external check.

## Self-Review

- Task 1 closes the post-deletion permanent feedback shutdown without weakening permanent close/barrier safety, and it covers deletion-gated passport reads and completed-checkpoint recovery.
- Task 2 makes tester instructions executable, feedback choices accessible on Android widths, retry max recoverable, and premium documentation truthful.
- Task 3 revalidates app, Functions, rules, localization, and release boundaries without implying an external rollout.
