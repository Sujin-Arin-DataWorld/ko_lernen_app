# Existing-account progress recovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore backup and learning-save readiness for existing accounts without losing either history or choosing a course starting point silently.

**Architecture:** Keep strict default reconciliation. Add domain-specific legacy-field adapters and a separately confirmed placement merge, then bind preview/confirmation to the existing durable account transition and CAS pipeline. Expose this through the existing pending-operation panel and a C-style sheet.

**Tech Stack:** Flutter 3.44.0, Dart ^3.12.0, existing Firebase/SharedPreferences/account services, existing AppL10n and Sori widgets.

**Spec:** `docs/superpowers/specs/2026-10-30-account-conflict-recovery.md`

## Global Constraints

- Flutter 3.44.0 / Dart ^3.12.0, existing dependencies and catalogs; A1/A2/B1/B2/C1/C2 remain.
- Keep owner/reset/deletion/session/operation/CAS fences, real proof and reward ownership.
- No default remote-wins, no automatic placement repair from 0 XP or empty evidence, no reset/logout shortcut.
- Cloud pronunciation scoring remains disabled; no new paid provider calls or production-data mutations for testing.
- DE/EN, existing C materials, 48dp controls, safe areas, untruncated large text and reduced motion.
- Diagnostics use fixed buckets/enums/counts only, with existing Crashlytics consent.
- Shared worktree: agents edit disjoint files, then freeze all writers before a Flutter/analyze run. Root owns Git/Graphify/releases.

## Review Focus

- An A→B→A account change or same-UID reacquisition must invalidate an old preview (Task 4).
- A reset, new local attempt, changed remote snapshot or new catalog while the sheet is open must require a new preview (Tasks 3–5).
- Different ordered grammar histories and genuinely divergent currency ledgers must remain blocked (Task 2).
- Same-ID/different-body proof and retention overflow must never be hidden by placement selection (Task 3).
- Cancel, double tap, route disposal and 200% text must preserve both data and usable controls (Task 5).

## Task 1: Retain proven independent compatibility repairs

**Files:**
- Modify: `lib/services/account/account_reconciliation.dart`
- Modify: `lib/services/course_mastery_service.dart`
- Test: `test/services/account/account_reconciliation_legacy_fields_test.dart`
- Test: `test/course_mastery_refresh_placement_provenance_test.dart`

**Interfaces:** Existing default `AccountReconciliationMerger` and `CourseMasteryService.refresh()` signatures remain unchanged.

- [x] Reproduce distinct valid calendar dates and reset-empty wrong-count JSON failures.
- [x] Couple current streak with its date; retain best streak; merge only validated per-item wrong counts by maximum.
- [x] Prevent a generic library/learning-goal level from creating dedicated placement when canonical course state is empty.
- [x] Run focused RED/GREEN and analyzer; retain explicit-placement, real legacy-evidence and default placement-conflict tests.
- [ ] Root review, full integration verification and commit together with the coherent follow-up.

## Task 2: Typed field merge and durable local convergence

**Files:**
- Create: `lib/services/account/account_reconciliation_field_policy.dart`
- Modify: `lib/services/account/account_reconciliation.dart` (owner of integration only)
- Modify: `lib/services/cloud_sync.dart`
- Modify: `lib/services/storage_service.dart`
- Test: `test/services/account/account_reconciliation_field_policy_test.dart`
- Test: `test/services/account/account_reconciliation_field_apply_test.dart`

**Interfaces:** `AccountReconciliationFieldPolicy` provides static `String mergeStudyLog(Object? local, Object? remote)`, `String mergeGrammarPlan(Object? local, Object? remote)`, `String? mergeLearnerGoal(Object? local, Object? remote)` and `String mergeWallet(Object? local, Object? remote)`. Each throws `FormatException` for invalid/unsupported/divergent values, mapped to the existing conflict result. Local application uses a reconciliation-specific guarded path; ordinary cloud-restore behavior remains unchanged.

- [ ] Write RED cases for actual shipped string payloads: disjoint/overlapping study dates, reset sentinel, valid local learner goal versus remote goal, grammar ordered-prefix extension and existing wallet dominance/zero baseline.
- [ ] Write rejection cases for malformed schemas, unsupported levels, more than 500 study IDs per date, divergent ordered grammar histories and divergent wallets.
- [ ] Implement pure policies using the existing source parsers/contracts. Device learning-goal/grammar settings are preferences; true learning/served history is retained.
- [ ] Implement guarded local study-history application so a nonempty local date does not silently discard the committed union. Test reset/session drift and repeated apply.
- [ ] Verify typed merge→CAS candidate→local readback equality, no credits/rewards, and unchanged rejection of unknown fields.

## Task 3: Explicit, proof-preserving course merge

**Files:**
- Modify: `lib/services/course_mastery_service.dart`
- Test: `test/course_mastery_confirmed_placement_merge_test.dart`

**Interfaces:** Add `CourseMasteryMergeResult CourseMasteryService.mergeForConfirmedPlacement({required CourseMasterySnapshot local, required CourseMasterySnapshot remote, required String selectedPlacementLevel})` alongside the existing strict `mergeForReconciliation`. The selected normalized placement must equal one of the two validated placements. This method performs no storage/network writes.

- [ ] Write RED for choosing each side while preserving both sides' completion/evidence/checkpoint/Phase/productive/archived proof IDs and bodies.
- [ ] Write RED for bypass staying unearned, duplicate rewards staying zero, valid reachable current-unit selection and interruption-safe deterministic output.
- [ ] Keep default a1↔a2 conflict unchanged; reject forged third levels, invalid snapshots/catalogs, same-ID/different-body proof and unpreservable retention overflow.
- [ ] Reject a lower starting-point choice that makes retained higher-level completions invalid without historical-baseline provenance; preserve all inputs and the existing prerequisite invariant.
- [ ] Implement the explicit merge using existing identity validation and a selected-placement prerequisite/bypass calculation. Never call destructive initialization.
- [ ] Run existing migration, progression, productive and strict synchronization tests with the new tests.

## Task 4: Owned preview, confirmation and resumable consent

**Files:**
- Create: `lib/services/account/account_switch_resolution.dart`
- Modify: `lib/services/account/account_transition_journal.dart`
- Modify: `lib/services/account/account_switch_coordinator.dart`
- Modify: `lib/services/account/account_reconciliation.dart`
- Modify: `lib/services/account/account_ui_operations.dart`
- Modify: `lib/services/auth_service.dart`
- Modify: `lib/services/account/account_failure_diagnostics.dart`
- Test: `test/services/account/account_switch_resolution_test.dart`
- Test: `test/services/account/account_switch_resolution_recovery_test.dart`
- Test: `test/services/account/account_resolution_diagnostics_test.dart`

**Interfaces:**
- `AccountSwitchResolutionSide { device, cloud }`.
- `AccountSwitchResolutionPreview`: `String devicePlacementLevel`, `String cloudPlacementLevel`, `int deviceCompletedUnitCount`, `int cloudCompletedUnitCount`, `bool canChooseDevice`, `bool canChooseCloud` and an owned opaque binding. UI never renders the binding. All constructor fields are required.
- `AccountSwitchResolutionPreviewStatus { ready, blocked, stale, unavailable, resumeRequired }`; `AccountSwitchResolutionPreviewResult` exposes `status` and nullable `preview`.
- `AccountSwitchResolutionOutcome { completed, blocked, stale, unavailable }`.
- Separate optional `AccountUiSwitchResolutionOperations` interface, avoiding new required members on existing link-only fake implementations.
- `Future<AccountSwitchResolutionPreviewResult> previewPendingSwitchResolution()` performs no writes.
- `Future<AccountSwitchResolutionOutcome> confirmPendingSwitchResolution({required AccountSwitchResolutionPreview preview, required AccountSwitchResolutionSide side})` accepts only the exact preview's two choices.
- `Future<AccountSwitchResolutionOutcome> resumePendingSwitchResolution()` resumes only an already-consented operation. A pure preview returns `resumeRequired` for that owned durable state; the UI asks the user to continue the saved choice and offers cancellation. This covers transient failure in a warm process without issuing a new choice or requiring an app restart.
- `AccountUiPendingState.switchResolutionNeeded` is additive; deletion/unknown owner states retain precedence.

- [ ] Write RED for preview zero writes/ready/backup, cancel zero effects, foreign UID/operation/session/reset/catalog/snapshot drift and same-UID reacquisition.
- [ ] Add validated optional journal consent bound to exact input fingerprints, chosen side/placement, candidate fingerprint and existing operation/session identity.
- [ ] Preview each side through the explicit course merger; expose only admissible candidates. No admissible candidate means blocked. Confirmation validates capability-bound admissibility, not caller-supplied enabled flags.
- [ ] Confirm by re-reading/revalidating inside the existing admission lane, then use the existing composite root/pack CAS, local guarded application and completion/activation sequence.
- [ ] Resume only original inputs or the exact same operation's already-committed candidate; prove kill-after-root/pack/local-write resumes exactly once.
- [ ] Add bounded fixed conflict buckets and normalized course/proof summaries. Canary secrets/IDs/text never occur in diagnostics; sink exceptions change no result or write.
- [ ] Keep unresolved unknown/document/proof/currency conflicts blocked; no force-merge flag or ready shortcut.

**Review rulings:**
- Committed reconciliation restores the validated app date/current-streak pair exactly under the existing source/session/reset guards. Ordinary restore keeps its current same-date merge policy. A crash after the date write must not prevent the candidate's lower current streak from converging.
- Account merging keeps the conservative mixed-pace rejection and never silently changes the learner's pace. A separately reproduced live defect in ordinary pace changes is included below: pure selection uses actual served IDs and the displayed day estimate uses actual history, without a stored-plan migration or reward change.
- A write-attempt latch belongs to the whole operation and is persisted before remote writes, including strict reconciliation without placement consent. Only provably new operations begin with `false`; existing `true` or missing legacy state is never downgraded. Explicit resume may retire stale consent only when durable `false`, unchanged ownership/journals, and read-only commit evidence all permit it. Retirement preserves both journals, operation identity, custom-pack bases, data and reconciling mode, then returns stale for a fresh user-initiated preview. Preview/startup never retires consent; attempted, unknown or partial commits remain exact-resume/blocked. Absence of a receipt alone is insufficient.

## Task 5: User-initiated recovery sheet and Settings flow

**Files:**
- Create: `lib/widgets/sori/account_progress_recovery_sheet.dart`
- Modify: `lib/widgets/sori/account_operation_ui.dart`
- Modify: `lib/screens/settings_screen.dart`
- Modify: `lib/l10n/app_de.arb`, `lib/l10n/app_en.arb` and generated localizations
- Test: `test/widgets/account_progress_recovery_sheet_test.dart`
- Test: `test/widgets/account_progress_recovery_flow_test.dart`

**Interfaces:** UI consumes Task 4's optional operations interface and immutable preview; it returns a selected `AccountSwitchResolutionSide` or cancellation, then passes the original preview to confirmation. Use existing `showSoriSheet`; retain actual text scaling with no 1.3 cap.

- [ ] Write RED for a real pending-switch panel/backup action opening preview, no preselection, disabled confirm, explicit side, cancel/back, double tap and stale result.
- [ ] Add localized neutral device/cloud choices with actual CEFR and completed-unit counts; show no internal IDs/keys. The sheet explains that saved learning remains and only the course starting point is chosen.
- [ ] Disable an inadmissible side with a readable explanation. One admissible side still requires explicit selection; no admissible side cannot be confirmed.
- [ ] Keep failure/retry visible and restore focus on dismissal. Preview or cancellation never triggers backup; successful readiness permits the normal fenced backup path.
- [ ] Verify default/deletion panels and account linking remain unchanged; recovery never invokes reset/logout/placement initialization.
- [ ] Render and inspect 320/390dp DE/EN at 100%/200%, a wide window and reduced motion; verify 48dp targets, semantics, no overlaps and reachable actions.

## Task 5b: Confirmed grammar pace and recovery consumer regressions

**Files:** `lib/services/grammar_plan_service.dart`, the two day-total calls in `lib/screens/grammar_screen.dart`, `lib/screens/profile_screen.dart`, and the shared pending-operation completion callback. Existing and new grammar/profile tests retain actual content IDs and native mock storage.

- [x] Reproduce ordinary 3-to-10 skipping and 10-to-3 replay, repeated/removed/inserted IDs, and incorrect day totals. These are independent of account merging and belong to the authorized live P0-P3 scope.
- [x] Reproduce Profile statistics remaining stale and the account nudge remaining open after successful recovery; cancellation preserves stored data.
- [ ] Select the next unserved rows in existing CSV order, preserving the caller's current-day completion and quiz guards. Keep plan schema, real IDs, evaluation and reward ownership unchanged.
- [ ] Calculate total plan days from actual completed dates plus the remaining unserved rows at the selected pace. Preserve the legacy static estimate API for callers that do not have a plan.
- [ ] Pass refreshed scalar values into Profile statistics and invoke the existing completion callback only when no recovery-specific callback is supplied.
- [ ] Re-run grammar, account, Profile, nudge, Settings and source-contract regressions before the assembled candidate. Do not represent pure/widget tests as native-device verification.

## Task 6: Integration and one assembled follow-up testing candidate

**Files:** Existing CI/release mechanisms; source manifest and receipts outside the worktree.

- [ ] Freeze writers; run relevant account/course/storage/UI regression groups, analyzer and final whole-app checks. Independently review ownership, proof retention and real rendered UI.
- [ ] Refresh free AST Graphify outputs only, review selected files, commit/push, create PR and verify exact-head automatic CI. Merge only when required checks pass, then verify exact merged-main CI.
- [ ] Build the assembled follow-up for the same Android package and iOS app 6798293722; keep public/testing availability, notifications and native verification distinct.
- [ ] On the existing Play installation, open recovery preview, let the user choose the actual course starting point, and verify backup time advances. Verify one learning save, restart persistence and exactly-once outcomes.
- [ ] Verify disabled scoring/local recording/replay, actual canonical characters, offline/failure/retry and accessibility. Do not mark any unrun platform/flow complete.
- [ ] Record remaining Google/Apple review, physical QA or unsupported data gates and safe worktree cleanup status. No claim that all P0–P3 are resolved without this evidence.
