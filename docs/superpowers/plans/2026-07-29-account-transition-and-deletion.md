Exit code: 0
Wall time: 0.3 seconds
Output:
# Safe Account Transition and Server-Owned Deletion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development or superpowers:executing-plans
> to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for
> tracking.

**Goal:** Make anonymous-account replacement and account deletion safe, resumable, auditable, and release-ready on Android and iOS without exposing cloud data or accidentally switching a user into an existing account.

**Architecture:** Introduce one durable account-operation journal and cloud-write session that fences every identity-bound cloud writer. Move destructive and privileged stages into idempotent 2nd-generation Cloud Functions, expose only typed operation status to Flutter, reconcile anonymous collision data before cleanup, and make bookshelf storage generation-based with one active manifest. The app remains German/English; the public deletion page retains German/English/Korean.

**Tech Stack:** Flutter/Dart, Firebase Auth, Cloud Firestore, Cloud Functions for Firebase 2nd generation (Node), Firebase App Check, Flutter Secure Storage, Firebase Storage, Remote Config, RevenueCat, Node built-in test runner, Flutter test.

## Global Constraints

- Never sign the primary app session into a target account after a Google or Apple link collision. A collision is an operation that must be explicitly completed or cancelled; if credential verification is necessary after confirmation, use an isolated temporary FirebaseAuth context and prove the primary source user remains unchanged.
- Only anonymous-to-existing-account replacement is in scope. A durable account switching to a different durable account is blocked with an actionable message; no export/import is inferred.
- The only permitted transition order is prepare, verify target, reconcile, clean source, then activate target.
- No direct client delete of users/{uid}, account_deletions/{uid}, or Firebase Auth users. Firebase Admin-only work happens inside callable functions.
- Every identity-bound asynchronous completion checks its CloudWriteSession uid and epoch before applying results.
- Journal metadata may be stored locally; credentials, proof tokens, and provider reauthentication material must use secure storage and must never appear in logs, analytics, screenshots, or exception text.
- Server actions derive identity only from a verified, non-revoked Firebase ID token; never trust a request-body uid. Connected accounts require a recent auth_time; anonymous accounts require a recent iat plus App Check and UID/request rate limits.
- A timeout, 5xx, disconnected response, accepted-but-unparsed response, or unknown deletion outcome is deletion-in-progress/unknown: retain the journal, freeze writers/push/premium actions, and resume the same operation. Rebinding an old push token is allowed only after a server-confirmed rejection before marker creation.
- Deletion proofs are server-issued 256-bit random values stored only as a hash, with hard expiry, bounded issuance/rotation, one active proof per account, generic public responses, and idempotent proof claim-to-operation creation. A TTL cleanup job is never the authorization expiry check.
- Apple authorization codes are transient request material only. Account deletion is never reported complete until its Apple-revocation state is explicitly terminal; partial external failures stay resumable and disclose only safe status.
- During a transition, RevenueCat must not alias or transfer the source anonymous identity/entitlement. Configure Purchases only after a ready, matching Firebase session and pass that Firebase UID as its custom appUserID; never create an anonymous RevenueCat intermediary with logOut. Premium identity actions remain quiesced until completed source cleanup and then bind only the verified target UID; sandbox entitlement behavior is an external release gate.
- App UI localization is German and English because those are the only supported app locales. Korean remains on the public account-deletion page.
- All new public endpoints are deployed only after staging verification and an explicit operator release action. This implementation must not deploy, push, merge, accept Android SDK licenses, or promise a physical-device result.
- Keep existing user data untouched unless a successful, authorized server operation reaches its specific deletion/reconciliation phase.

## Task 1: Add the durable cloud-write session and transition journal

**Files:**
- Create: lib/services/account/cloud_write_session.dart
- Create: lib/services/account/account_transition_journal.dart
- Create: lib/services/account/transition_secret_store.dart
- Create: test/services/account/cloud_write_session_test.dart
- Create: test/services/account/account_transition_journal_test.dart
- Modify: pubspec.yaml
- Modify: android/app/src/main/AndroidManifest.xml
- Create: android/app/src/main/res/xml/backup_rules.xml
- Create: android/app/src/main/res/xml/data_extraction_rules.xml

- [ ] Write failing tests that construct CloudWriteSession(uid, epoch, mode), reject a mismatched uid or stale epoch, and verify that a resumed journal never includes secret fields.
- [ ] Run: flutter test test/services/account/cloud_write_session_test.dart test/services/account/account_transition_journal_test.dart
  Expected: compile/test failure because the session and journal types do not exist.
- [ ] Implement CloudWriteMode with ready, quiesced, reconciling, cleanupPending, and blocked; CloudWriteSessionController with acquire, resume, transition, assertCurrent, and clear; AccountTransitionJournal as versioned non-secret JSON; and TransitionSecretStore backed by FlutterSecureStorage.
- [ ] Add cloud_functions, firebase_app_check, and flutter_secure_storage with compatible current Flutter constraints. Set Android backup policy so account-operation storage is not backed up, including explicit backup/data-extraction XML references.
- [ ] Run the two focused tests and flutter analyze. Expected: both tests pass and no analyzer errors in the new files.
- [ ] Commit: feat(account): add durable transition session journal

## Task 2: Fence all cloud writers and identity-bound side effects

**Files:**
- Modify: lib/services/cloud_sync_service.dart
- Modify: lib/services/firestore_progress_service.dart
- Modify: lib/services/pack_progress_service.dart
- Modify: lib/services/bookshelf_service.dart
- Modify: lib/services/custom_pack_service.dart
- Modify: lib/services/media_storage_service.dart
- Modify: lib/services/push_ownership_transition_coordinator.dart
- Modify: lib/services/premium_identity_binder.dart
- Modify: lib/services/gye_service.dart
- Create: test/services/account/cloud_writer_fence_test.dart
- Modify: test/services/push_ownership_transition_coordinator_test.dart
- Modify: test/services/premium_identity_binder_test.dart

- [ ] Write failing tests that start a write for session A, advance to session B, and prove the stale completion cannot write, bind RevenueCat, rebind push ownership, trigger Gye work, or garbage-collect media.
- [ ] Run: flutter test test/services/account/cloud_writer_fence_test.dart test/services/push_ownership_transition_coordinator_test.dart test/services/premium_identity_binder_test.dart
  Expected: stale work is accepted by at least one existing implementation.
- [ ] Add one injected CloudWriteSessionController dependency to each writer/side-effect coordinator. Acquire a snapshot before work, assert it immediately before every write or identity action, and surface a typed stale-session result rather than throwing a raw late exception.
- [ ] Make PushOwnershipTransitionCoordinator quiesce the source before the transition callback and leave an existing binding untouched only on a server-confirmed pre-marker rejection; unknown/accepted/error outcomes must not rebind the old UID and must remain frozen for resume. Configure Premium only after a ready matching Firebase UID is available, use that UID as the custom appUserID, never call logOut during a switch, pause PremiumIdentityBinder while the session is non-ready, forbid source-to-target entitlement aliasing, and make Gye streams/actions epoch-aware.
- [ ] Run the focused tests and existing cloud/pack/bookshelf/custom/media tests. Expected: all pass, and no writer starts during quiesced/reconciling/cleanupPending modes.
- [ ] Commit: feat(account): fence cloud writers during identity transitions

## Task 3: Model server account operations as pure, idempotent state machines

**Files:**
- Create: functions/gye/account_operations.js
- Create: functions/gye/account_operations.test.js
- Modify: functions/gye/package.json

- [ ] Write failing Node tests for allowed and forbidden transitions across prepared, targetVerified, reconciling, sourceCleanupPending, deletionRequested, userTreeDeleting, authDeleted, appleRevocationPending, communityCleanupPending, processorCleanupPending, completed, and blocked.
- [ ] Run: npm test -- --test account_operations.test.js
  Expected: module-not-found failure.
- [ ] Implement pure transition validation, operation record normalization, monotonic attempt counters, retry classification, proof hard-expiry/claim rules, Apple partial-failure state, and an operationResult shape that never returns secrets.
- [ ] Add tests for duplicate requests, out-of-order retries, stale operation version rejection, target/source uid equality rejection, same-proof response-loss resume, Auth user-not-found terminal handling, and safe terminal states.
- [ ] Run: npm test -- --test account_operations.test.js
  Expected: all state-machine tests pass.
- [ ] Commit: feat(functions): add idempotent account-operation state machine

## Task 4: Add protected callable operation repository and authorization boundary

**Files:**
- Modify: functions/gye/index.js
- Create: functions/gye/account_operations_runtime.js
- Create: functions/gye/account_operations_runtime.test.js
- Modify: functions/gye/package.json

- [ ] Write failing runtime tests for prepareAnonymousReplacement, attachReplacementTarget, commitReplacementReconciliation, startSourceCleanup, requestAccountDeletion, and getAccountOperation. Test unauthenticated, request-body uid mismatch, revoked token, stale connected-account auth_time, stale anonymous iat, missing App Check, stale version, and duplicate-call paths.
- [ ] Run: npm test -- --test account_operations_runtime.test.js
  Expected: callable exports do not exist.
- [ ] Implement 2nd-generation callable functions in europe-west3 with enforceAppCheck true and consumeAppCheckToken true. Verify the Authorization-header token with checkRevoked, derive the caller UID only from that token, enforce a 300-second auth_time for connected accounts or a 300-second iat for anonymous accounts, enforce operation-version matching, and persist/reuse operation records through a transaction-safe repository.
- [ ] Make replacement callables advance only the pure state machine and return safe operation results. requestAccountDeletion may create/reuse a deletionRequested operation but must not delete any user data in this task; all runtime logs and errors use safe codes only.
- [ ] Run: npm test. Expected: all existing and runtime-operation tests pass.
- [ ] Commit: feat(functions): add protected account operation callables

## Task 5: Add deletion proof, server worker, and restrictive rules

**Files:**
- Modify: functions/gye/index.js
- Modify: functions/gye/account_operations_runtime.js
- Modify: functions/gye/account_operations_runtime.test.js
- Modify: functions/gye/package.json
- Modify: firestore.rules
- Modify: firebase.json

- [ ] Write failing runtime tests for issueDeletionProof, requestDeletionByProof, completeAppleRevocation, proof replay/expiry/response loss, generic public response, server-worker lease renewal, Auth user-not-found, and legacy client tombstone isolation.
- [ ] Run: npm test -- --test account_operations_runtime.test.js
  Expected: new proof/worker behavior is absent or fails its safety assertions.
- [ ] Issue 256-bit proofs server-side, persist only a keyed hash/expiry/issuance metadata, and atomically claim or reuse an opaque operation ID in a Firestore transaction. Add a minimal public HTTP requestDeletionByProof endpoint that consumes no raw proof after validation, returns the same generic response for invalid/expired/used/deleted cases, applies bounded request limits, and records only safe metadata.
- [ ] Run destructive user-tree cleanup outside transactions through a lease-based, paged server worker. Treat Auth user-not-found as terminal success; keep server-created markers distinct from abandoned client tombstones; complete Apple revocation only through a transient safe-code path; preserve existing Gye/user-deletion cleanup behind server operation phases so a root delete cannot bypass community/processor status.
- [ ] Remove client rule permission to create account_deletions or delete a user root; allow clients only the narrowly needed operation status reads for their own uid. Add deployment configuration only for the new first-party endpoint, without deploying it.
- [ ] Run: npm test and firebase firestore:rules:compile --project demo-project-id if the CLI permits an offline compile. Expected: all Node tests pass; if project validation requires credentials, record the exact authenticated command as an external gate.
- [ ] Commit: feat(functions): add server-owned deletion proof and worker

## Task 6: Initialize App Check and replace client-side deletion with typed callable clients

**Files:**
- Create: lib/services/account/account_operation_client.dart
- Create: lib/services/account/firebase_app_check_initializer.dart
- Modify: lib/main.dart
- Modify: lib/services/app_startup_coordinator.dart
- Modify: lib/services/auth_service.dart
- Modify: test/services/account/account_operation_client_test.dart
- Modify: test/services/app_startup_coordinator_test.dart
- Modify: test/services/auth_service_test.dart

- [ ] Write failing tests that require App Check initialization before a protected callable, map callable errors to typed AccountOperationFailure values, and prove AccountDeletionCoordinator no longer invokes direct FirebaseAuth.delete or direct Firestore data deletion.
- [ ] Run: flutter test test/services/account/account_operation_client_test.dart test/services/app_startup_coordinator_test.dart test/services/auth_service_test.dart
  Expected: tests expose direct client deletion and missing initialization.
- [ ] Implement FirebaseAppCheck activation with Android debug in debug builds and Play Integrity in release builds; Apple debug in debug builds and App Attest with DeviceCheck fallback in release builds. Restore the CloudWriteSession only after deriving expectedUid from live FirebaseAuth state, then initialize protected Firebase-backed startup work.
- [ ] Implement AccountOperationClient using FirebaseFunctions.instanceFor(region: europe-west3), typed request/response DTOs, bounded retry only for idempotent reads, and safe error text. Replace AccountDeletionCoordinator's direct deletion path with request/status/polling, retain provider reauthentication only as a prerequisite signal, and map unknown server outcomes to journal-resume/frozen state rather than retrying a fresh deletion.
- [ ] Run the focused Flutter tests, flutter analyze, and dart format --set-exit-if-changed on changed Dart files. Expected: all pass and all changed Dart files are formatted.
- [ ] Commit: feat(account): use App Check and server deletion operations

## Task 7: Add typed remote reads and deterministic reconciliation

**Files:**
- Create: lib/services/account/cloud_read_result.dart
- Create: lib/services/account/account_reconciliation.dart
- Modify: lib/services/cloud_sync_service.dart
- Modify: lib/services/firestore_progress_service.dart
- Modify: lib/services/pack_progress_service.dart
- Modify: lib/services/custom_pack_service.dart
- Create: test/services/account/account_reconciliation_test.dart
- Modify: test/services/cloud_sync_service_test.dart
- Modify: test/services/firestore_progress_service_test.dart
- Modify: test/services/pack_progress_service_test.dart

- [ ] Write failing tests for CloudReadResult.present, absent, unavailable, invalid, and tooLarge; merge tests for local-only, remote-only, same-version, divergent-version, malformed remote, unavailable remote, and retry after an interrupted reconcile.
- [ ] Run: flutter test test/services/account/account_reconciliation_test.dart test/services/cloud_sync_service_test.dart test/services/firestore_progress_service_test.dart test/services/pack_progress_service_test.dart
  Expected: current code collapses failures to empty/null or overwrites data.
- [ ] Implement typed read adapters with size validation and a deterministic merge policy. Preserve divergent SRS-card histories and divergent custom-pack IDs as typed blocking conflicts rather than overwriting either side; persist reconciliation checkpoints in the non-secret journal, use transaction/CAS where a document revision is available, and never treat unavailable/invalid data as absent.
- [ ] Require a current reconciling CloudWriteSession for migration writes and use the journal's operation id as the idempotency identity where supported.
- [ ] Run the focused tests and the full relevant service test group. Expected: no data overwrite in divergent or offline cases.
- [ ] Commit: feat(sync): reconcile remote account data deterministically

## Task 8: Migrate bookshelf sync to immutable generations and guard media cleanup

**Files:**
- Modify: lib/services/bookshelf_service.dart
- Modify: lib/services/media_storage_service.dart
- Modify: lib/services/cloud_sync_service.dart
- Create: lib/services/account/bookshelf_generation_manifest.dart
- Create: test/services/account/bookshelf_generation_manifest_test.dart
- Modify: test/services/bookshelf_service_test.dart
- Modify: test/services/media_storage_service_test.dart

- [ ] Write failing tests that restore only the active manifest, ignore an incomplete new generation, survive an interrupted manifest flip, and prohibit media garbage collection until reconciliation is complete.
- [ ] Run: flutter test test/services/account/bookshelf_generation_manifest_test.dart test/services/bookshelf_service_test.dart test/services/media_storage_service_test.dart
  Expected: current per-document and parent JSON paths can conflict and media cleanup can run too early.
- [ ] Implement immutable generation writes under users/{uid}/sync_generations/{generationId}/bookshelf/{bookId}, then atomically update one active-manifest record after all generation writes succeed. Retain legacy data read support until a completed migration is confirmed.
- [ ] Stop using CloudSync.bookshelf_json as a competing canonical writer. Require session currentness plus a completed reconciliation checkpoint before destructive media cleanup.
- [ ] Run focused tests and existing bookshelf/cloud tests. Expected: manifest failure preserves the prior visible generation.
- [ ] Commit: feat(sync): make bookshelf migration generation-safe

## Task 9: Implement anonymous collision coordination without accidental login

**Files:**
- Create: lib/services/account/account_transition_coordinator.dart
- Modify: lib/services/auth_service.dart
- Modify: test/services/auth_service_test.dart
- Create: test/services/account/account_transition_coordinator_test.dart

- [ ] Write failing tests that a Google/Apple credential collision returns ExistingAccountLinkConflict, does not change FirebaseAuth.currentUser, that confirmed target verification with a freshly acquired credential also preserves the primary source user, and that a resumable anonymous transition starts only after explicit confirmation.
- [ ] Run: flutter test test/services/auth_service_test.dart test/services/account/account_transition_coordinator_test.dart
  Expected: existing link methods sign in to the target account after collision.
- [ ] Replace auto-sign-in collision catches with a typed conflict result containing only safe provider/operation metadata. Implement AccountTransitionCoordinator phases: prepare, target verification in an isolated temporary FirebaseAuth context, account reconciliation, source cleanup, then target activation.
- [ ] Make coordinator resume after app restart from the journal only when its source UID matches live auth; block durable-to-durable transition; expose cancel only before source cleanup begins; discard provider credentials after each use; and keep current user/session unchanged after failed target verification or reconciliation.
- [ ] Run focused tests and flutter test test/services. Expected: no test observes target activation before cleanup success.
- [ ] Commit: feat(auth): coordinate anonymous account replacement safely

## Task 10: Route all account UI through safe operations and localize user-facing states

**Files:**
- Modify: lib/screens/settings_screen.dart
- Modify: lib/screens/profile_screen.dart
- Modify: lib/widgets/account_nudge.dart
- Modify: lib/screens/gye_screen.dart
- Modify: lib/l10n/app_en.arb
- Modify: lib/l10n/app_de.arb
- Modify: lib/l10n/app_localizations.dart
- Modify: lib/l10n/app_localizations_en.dart
- Modify: lib/l10n/app_localizations_de.dart
- Create: test/widgets/account_transition_ui_test.dart
- Modify: test/widgets/settings_screen_test.dart
- Modify: test/widgets/profile_screen_test.dart

- [ ] Write failing widget tests that invoke account linking/deletion from every entry point, show confirmation before prepare, show recoverable status/polling errors, and never expose a raw Firebase error or proof token.
- [ ] Run: flutter test test/widgets/account_transition_ui_test.dart test/widgets/settings_screen_test.dart test/widgets/profile_screen_test.dart
  Expected: at least one route invokes AuthService directly or displays raw error text.
- [ ] Route settings, profile, nudge, and Gye account actions through AccountTransitionCoordinator/AccountOperationClient. Add complete English/German strings for explain, confirm, in-progress, resume, blocked durable account, retry, and support escalation states.
- [ ] Regenerate localizations using the repository's existing Flutter localization workflow; do not add a partial Korean app locale.
- [ ] Run focused widget tests, flutter analyze, and full flutter test. Expected: all user-facing flows use typed state and localized messages.
- [ ] Commit: feat(ui): present resumable safe account operations

## Task 11: Publish a safe proof-consumption page and correct release documentation

**Files:**
- Create: docs/account-deletion-page.js
- Create: docs/account-deletion-page.test.js
- Modify: docs/account-deletion.html
- Modify: docs/privacy-policy.html
- Modify: docs/data-disclosure.html
- Create: docs/release-readiness.md

- [ ] Write failing Node tests that pass a fragment proof into consumeDeletionProof, verify history.replaceState removes it before network use, assert no proof appears in a rendered error, and assert generic success for expired/used proofs.
- [ ] Run: node --test docs/account-deletion-page.test.js
  Expected: module-not-found failure.
- [ ] Implement account-deletion-page.js as a small testable browser module. It reads the fragment once, immediately replaces the URL without it, POSTs only to the configured first-party endpoint, renders generic status, and has no analytics, third-party scripts, external form submission, proof query parameter, or raw error interpolation.
- [ ] Update account-deletion.html in English/German/Korean to explain app request and email/form fallback accurately. Correct privacy/disclosure statements to distinguish current deployed behavior from the required server release gate; add a release-readiness checklist for Cache-Control no-store, Referrer-Policy no-referrer, strict CSP, HTTPS/HSTS, exact CORS allowlist, request-size limits, endpoint rate limits, App Check, Firebase configuration, privacy URLs, Apple/Google console evidence, log redaction, and manual proof-page testing.
- [ ] Run node --test docs/account-deletion-page.test.js and scan docs for live secrets, proof query parameters, third-party script URLs, and unsupported "current release" claims. Expected: tests pass and scan has no findings.
- [ ] Commit: docs: add secure deletion proof page and release gates

## Task 12: Verify the complete branch, perform independent review, and prepare handoff

**Files:**
- Modify if required by verified defects only: files identified by test/review evidence
- Create: docs/release-verification-2026-07-29.md

- [ ] Run the full Flutter suite: flutter test --reporter compact.
- [ ] Run static checks: flutter analyze, dart format --set-exit-if-changed on changed Dart files, npm test in functions/gye, node --test docs/account-deletion-page.test.js, git diff --check, and a focused rg scan for secrets/unsafe direct deletion/collision auto-login.
- [ ] Run Android environment diagnostics without changing SDK state: flutter doctor -v, flutter devices, adb devices, and flutter build appbundle --debug or the repository's non-release equivalent only if Android toolchain licenses/dependencies already permit it.
- [ ] Have a fresh reviewer inspect the branch for invariant violations, missing writer fences, rules regressions, localization omissions, and external deployment assumptions. Fix only evidence-backed findings using a test-first follow-up task.
- [ ] Write docs/release-verification-2026-07-29.md with exact commands, outcomes, unverified external gates, device/USB status, production deployment gates, and tester checklist. Include verified least-privilege service-account/IAM, Auth anonymous-auto-cleanup, function-trigger/index, proof-log redaction, Apple partial-revoke, and RevenueCat sandbox gates. Do not claim that Android USB, Play Integrity, App Attest, Firebase deployment, Play Console, or App Store submission has been verified unless actual evidence exists.
- [ ] Commit: docs: record account operation release verification

## Plan Self-Review

- [ ] Coverage: account collision, deletion, App Check, cloud writes, push, RevenueCat, Gye, progress, custom content, bookshelf, media, Firestore rules, public proof handling, and release evidence are each assigned to a task.
- [ ] Ordering: all writers are fenced before reconciliation, and reconciliation completes before source cleanup/target activation.
- [ ] External boundaries: Firebase configuration, Admin permissions, App Check providers, Apple revocation, CORS/CSP, Android SDK/device, and store-console actions are recorded as explicit gates rather than assumed complete.
- [ ] Type consistency: operation state, session state, remote-read state, callable result, and UI state are represented as typed interfaces rather than nullable maps/strings.
- [ ] Placeholder scan: the implementation contains no unimplemented-marker comments for safety-critical behavior.
