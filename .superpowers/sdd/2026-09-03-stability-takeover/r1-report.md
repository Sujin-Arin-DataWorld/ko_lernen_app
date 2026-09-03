# R1 takeover report — data protection / migration failure boundary

Worktree: `C:\dev\hangulsori\ko_lernen_app_worktrees\stability-r1-migration-20260903`
Branch: `codex/stability-r1-migration-20260903` (HEAD before this session: `08b80c6e` = `origin/main`)
Executor: Sonnet (takeover of an interrupted Codex session), 2026-09-03.

## Status before / after cleanup

**Before** (`git status --short`): 12 modified + 13 untracked files under `graphify-out/` (noise from an
unrelated tool run), plus the real R1 deliverable: `lib/services/data_migration_service.dart` (M) and
`test/services/data_migration_failure_test.dart` (??).

Cleanup: `git checkout -- graphify-out` (reverted 12 tracked files) and `git clean -f -- graphify-out`
(deleted 13 untracked AST-cache files under `graphify-out/cache/ast/v0.9.48-s2/`). Nothing outside
`graphify-out/` was touched.

**After**: exactly
```
 M lib/services/data_migration_service.dart
?? test/services/data_migration_failure_test.dart
```

## flutter analyze --no-pub

0 issues ("No issues found!", 67.1s). No analyzer fixes were needed.

## Test counts

- `test/services/data_migration_failure_test.dart` (new R1 file): **71 tests, all passed, 0 failed.**
  The file has 40 static `test(...)` call sites across 7 `group(...)` blocks (confirmed by grep), but
  several sites loop over fixture lists (invalid marker types, fault-injection variants), which the
  Dart test runner expands into 71 runtime test cases at run time. Not a discrepancy — a static vs.
  dynamic test-count difference.
- `git grep -l "DataMigrationService\|data_migration_service" -- test` (tracked + untracked): four files
  — `test/data_migration_test.dart`, `test/e2e/app_flows_e2e_test.dart`,
  `test/startup_maintenance_test.dart`, and the new `test/services/data_migration_failure_test.dart`.
  Run individually for reliable counts:
  - `test/data_migration_test.dart`: 21 tests, all passed.
  - `test/e2e/app_flows_e2e_test.dart`: 12 tests, all passed.
  - `test/startup_maintenance_test.dart`: 3 tests, all passed.
  - Combined total across all four migration-related files: 21 + 12 + 3 + 71 = **107 tests, 0 failed.**

**Observed anomaly (not a regression):** running `data_migration_test.dart` +
`e2e/app_flows_e2e_test.dart` + `startup_maintenance_test.dart` together in one `flutter test`
invocation, with `startup_maintenance_test.dart` listed *last*, reproducibly (twice) dropped its 3
tests from the output entirely — no failure, no skip marker, exit code 0, just absent. Reordering
`startup_maintenance_test.dart` to be listed *first* made it run normally (3/3 pass), and it also
passes cleanly alone or paired with `data_migration_test.dart`. This looks like a pre-existing
`flutter test` multi-file scheduling quirk unrelated to the R1 diff (the file's own code and the
service it imports are unaffected by ordering). Mitigated by verifying every file individually above.

## Full suite

`flutter test --no-pub --reporter failures-only`: **5757 tests total, 15 skipped, 0 failed** (exit
code 0, final line "All other tests passed!"). No baseline from origin/main was available for
comparison, but 0 failures were observed against the current tree with the R1 changes applied.

## git diff --check

Clean (exit 0, no output — no trailing whitespace or conflict markers).

## Behavioural summary of `lib/services/data_migration_service.dart` (+566/-162)

- **Reentrancy**: a synchronous `_running` flag (checked before any `await`) now rejects overlapping
  `run()` calls immediately with `failed:...:alreadyRunning:acquire` instead of racing.
- **Lock scope widened**: `Storage.lockLearningWrites('migration:acquire')` now fires at admission,
  before any read — writes are blocked for the *entire* run, not just after a failure.
- **`failed` status redefined**: previously meant "a step failed, backup restored, version not
  bumped" (always safely retryable). Now means "safe completion could not be confirmed — recovery may
  be needed, writes stay locked." This is materially more conservative (fail-closed). New
  `DataMigrationFailureCode` (9 values: alreadyRunning, invalidMetadata, invalidBackup, readFailed,
  writeRejected, writeFailed, stepFailed, recoveryFailed, outcomeUnknown) and `DataMigrationPhase` (7
  values: acquire, read, prepare, steps, commit, restore, cleanup) enums carry PII-free diagnostics.
- **`fromVersion` is now `int?`**: null when the starting version can't be trusted.
- **Commit redefined as "native marker == target after reload"**, not "setter returned true". Handles:
  setter returns `false` but marker persisted anyway (still committed, no rollback); setter throws but
  is committed anyway (still committed); reload itself fails (`outcomeUnknown` — nothing is touched,
  all recovery evidence preserved for a future retry/diagnosis).
- **Backup/journal are now validated on every read** (`_Snapshot.parse`/`_Journal.parse`: type, key
  prefix, `from`/`to`/`step` consistency). Malformed or inconsistent recovery data now fails closed
  (`invalidBackup`/`invalidMetadata`) rather than silently proceeding.
- **Restore is all-or-nothing and self-verifying**: every value is validated before the first write;
  after writing, prefs are reloaded and byte/type-compared against the snapshot (`_Snapshot.matches`).
  An apparently-successful restore that doesn't actually verify is itself reported as a failure
  (`recoveryFailed`), with original evidence retained for retry — never silently declared safe.
  never rolls back the already-committed version bump; a stuck cleanup is retried on the next run
  while the user stays on the new schema (`cleanupPending` / `...:cleanup` failure codes), and steps
  are never re-applied.
- **New invariant, directly tested**: injected secrets (email/token) thrown by a step never leak into
  `diagnosticValue` or any other surfaced string.

## Commits

- `d5cc12dd` — `fix(migration): fail-closed migration boundary with backup/journal keys and 40
  failure-path tests (Codex R1 takeover)` — the two R1 files (`lib/services/data_migration_service.dart`,
  `test/services/data_migration_failure_test.dart`), 1681 insertions / 162 deletions.
- (this docs file) — added in a second, separate commit per instructions.

## Unexpected failures

None. `flutter analyze` was 0/0, the new test file and every other migration-touching test file passed
100% individually, and the full suite finished 0 failed / 15 skipped / 5757 total.

## Open questions

1. Is the `flutter test` multi-file ordering anomaly (a trailing test file's tests silently vanishing
   from output when combined with a slow e2e file) already known/tracked, or worth its own bug report
   against the Flutter SDK / this repo's test tooling?
2. `AGENTS.md` §"지금 등록된 단계가 없는 이유" now explicitly says a startup/cloud write-quiescence
   review is required before real production migration steps are registered, since the current lock
   only covers SRS/pack learning writes, not XP, all `kl_` keys, or cloud restore. Should that review
   be scheduled as a follow-up package before any version-2 migration step is actually shipped?
3. No baseline full-suite run against plain `origin/main` (pre-R1) was taken for comparison — only the
   post-R1 tree was verified at 0 failures. If a baseline diff is needed, it would require a second
   `flutter test` run on a clean checkout of `08b80c6e`.

## Fix round 1 (Fable review of commit `d5cc12dd`)

**Verdict addressed:** FIX-REQUIRED (1 Important, 2 Minor).

### Important — stamp-only fast path restored for version bumps without steps

**Problem:** in `_MigrationRun.execute()`, `_Snapshot.capture` + `setString(_backupKey)` and
`_writeJournal()` ran *before* `pending` was computed. A version bump with an empty/non-matching
step registry (e.g. a release that only raises `currentSchemaVersion` with no migration step
registered for that version) still serialized every `kl_` key into a second preference on every
app start, and would `fail-closed` with `invalidBackup` — permanently locking learning writes —
if any `kl_` value had a type the snapshot codec can't represent (a non-finite double, a
`List<Object?>` with a non-string element). The pre-R1 code had a dedicated fast path for exactly
this case ("실행할 단계가 없는 버전 상승 — 도장만 옮긴다"); the R1 rewrite dropped it.

**Fix:** `pending` is now computed immediately after the `from == target` ("fresh install") block,
before the `prepare` phase. When `pending.isEmpty && recovery == null` (no steps to run, and no
interrupted prior run was restored), the run skips snapshot/backup/journal entirely, leaves
`stepsStarted = false`, and goes straight to `await _commit()` /
`_success(DataMigrationStatus.migrated, cleanupFailure: await _cleanup())` — the same native-marker
commit reconciliation as every other path, just without ever touching unrelated data. When
`recovery != null` (an interrupted earlier run was restored above) or `pending` is non-empty, the
full snapshot/journal/steps path is unchanged. `lib/services/data_migration_service.dart`, function
`_MigrationRun.execute()`.

**Tests added** in `test/services/data_migration_failure_test.dart`, new group *"a version bump
with no registered steps needs no snapshot"*:
- `empty registry stamps the version without ever writing backup or journal, even past a value
  type the snapshot codec cannot represent` — boots with a `kl_` double `NaN` and a `kl_`
  `List<Object?>` containing a non-string element (`2`) alongside the version marker, runs with
  `steps: const {}`, and asserts: status `migrated`, marker == target, `native.operations` never
  contains a `set:` for either `_backup` or `_journal`, neither key exists afterward, and every
  other native value is byte-identical to before the run (nothing touched, nothing failed).
- `the same bump with one registered step still writes backup and journal` — regression guard for
  the untouched full path: same 1→2 bump, default single-step registry, asserts `native.operations`
  *does* contain `set:` for both `_backup` and `_journal` during the run (they're cleaned up by the
  end, so this is checked against the append-only operations log, not final state).

No existing test asserted that a no-step bump writes a backup, so nothing needed updating to the
new contract — `test/data_migration_test.dart`'s `등록된 단계가 없는 버전 상승은 도장만 옮긴다`
only ever asserted `status`/`storedVersion()`/`writesAllowed`, which are unaffected either way.

### Minor notes — comment-only, no behavior change

Both were judged not worth a logic change (risk of the suggested guard silently skipping a needed
cache invalidation on a path that *did* change the version marker outweighed the benefit), so both
were addressed with a one-line explanatory comment only:

1. `_Snapshot.matches` compares `runtimeType`, which can read a stored `2.0` back as an `int` on
   web (dart2js). Added a comment acknowledging web is smoke-only for this service and that this
   gap is accepted rather than widened into a numeric `==` that would blur real type drift too.
2. `Storage.resetCachesAfterExternalWrite()` in `execute()`'s outer `finally` now runs on every
   call, including the upToDate/fresh/no-step-bump no-op paths. Considered guarding with
   `stepsStarted || phase == restore`, but that would also skip invalidation on the `fresh` and new
   no-step-bump paths — both of which *do* change the version marker — which looked like a real
   correctness risk for a purely cosmetic saving. Kept the unconditional call and added a comment
   explaining why ("any exit invalidates" stays one rule instead of a path-dependent one a future
   branch could silently fall outside of).

### Verification after the fix

- `flutter analyze --no-pub`: 0 issues (71.5s).
- `test/services/data_migration_failure_test.dart`: **73 tests, all passed** (71 + 2 new).
- `test/data_migration_test.dart`: 21/21 passed, unchanged.
- `test/e2e/app_flows_e2e_test.dart`: 12/12 passed, unchanged.
- `test/startup_maintenance_test.dart`: 3/3 passed, unchanged.
- Full suite (`flutter test --no-pub --reporter failures-only`): **5759 tests, 15 skipped, 0
  failed** (up from 5757 in the pre-fix run, matching the 2 added tests), exit code 0, "All other
  tests passed!"
- `git diff --check`: clean.

### Commit

- `9afb5110` — `fix(migration): stamp-only fast path for version bumps without steps (Fable review
  of R1)` — `lib/services/data_migration_service.dart` (+34/-5) and
  `test/services/data_migration_failure_test.dart` (+52), 2 files changed, 81 insertions(+), 5
  deletions(-).
