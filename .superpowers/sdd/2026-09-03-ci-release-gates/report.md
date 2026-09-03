# Report — CI release gates (2026-09-03)

Worktree: `C:\dev\hangulsori\ko_lernen_app_worktrees\ci-release-gates-20260903`
Branch: `claude/ci-release-gates-20260903` (from `origin/main`, base `d120af87`, PR #259 squash-merge)
Not pushed. Two commits, as instructed:

1. `2de9fe71` -- `ci(security): SHA-pin all workflow actions and verify them with release_integrity.py on every run`
2. `bcb5fce7` -- `ci(release): variable-gated Crashlytics symbol-evidence gate before Play upload (R4), harvest step, runbook`

## START CONDITION

`git fetch origin main` on the canonical repo succeeded on the first try. Both
`origin/main:tool/release_integrity.py` and `origin/main:tool/android_release_evidence.py`
verified present via `git cat-file -e` before creating the worktree -- no
retry needed.

## W1 -- manifest additions (with gh outputs)

```
gh api repos/google-github-actions/auth/git/ref/tags/v2 -q .object
  -> {"sha":"c200f3691d83b41bf9bbd8638997a462592937ed","type":"commit", ...}
gh api repos/google-github-actions/setup-gcloud/git/ref/tags/v2 -q .object
  -> {"sha":"e427ad8a34f8676edf47cf7d7925499adf3eb74f","type":"commit", ...}
```
Both `.object` entries were already `type: commit`, so no dereference step
was needed. Added both to `tool/release_toolchain.json` under `actions`;
`binaries` block untouched. `python tool/release_integrity.py manifest` ->
`{"schemaVersion": 1, "verified": true}`.

## `uses:` rewrite stat

| File | Lines rewritten | Notes |
|---|---|---|
| `ci.yml` | 38 | matches brief's fact sheet |
| `play_closed.yml` | 6 | matches brief's fact sheet |
| `playwright.yml` | 0 | already correctly pinned by #257; **actual count is 5 `uses:` lines, not 3** as the brief's fact sheet stated -- verified against the real file, reported rather than silently corrected |

Rewrite done with a throwaway script (`$TEMP/pin_actions.py`, not committed),
driven only by manifest values. `git diff` confirmed (via grep) that no line
other than a `uses:` line changed in either file.

## `actions` command output (progression)

| Point in the work | `actionsChecked` |
|---|---|
| After the pin rewrite, before adding `workflow-integrity` | 49 |
| After adding `workflow-integrity` job (2 new pinned `uses:` in `ci.yml`) | 51 |
| `play_closed.yml` alone, after W2's 3 new pinned `uses:` (setup-java, setup-node, upload-artifact) | 9 |
| All three workflow files, final state (end of W2) | **54** |

The brief guessed `{"actionsChecked": 47}` as a possibility; the true final
total across all three files is **54** (49 W1-only, +2 for `workflow-integrity`'s
own pinned steps, +3 for W2's gate steps in `play_closed.yml`).

## Test counts

| Suite | Count | Result |
|---|---|---|
| `tool.test_release_integrity` (throwaway venv, PyYAML 6.0.2) | 28 (27 pre-existing + 1 new) | OK |
| `.github/scripts` discover | 64 | OK (2 pre-existing tests initially broke, see below -- fixed, count unchanged) |
| `tool.test_android_release_tools_config` (new) | 6 | OK |
| `tool.test_android_release_evidence` | 44 | OK, zero diff from `origin/main` |
| Combined `tool.test_release_integrity tool.test_android_release_evidence tool.test_android_release_tools_config` (exact command the new ci.yml step A runs) | 78 | OK |

## Secrets/variables Jin must create, and the harvest procedure

Full detail in `docs/runbooks/android-symbol-evidence.md` (57 lines). Summary:

- **`ANDROID_SYMBOL_EVIDENCE_GATE`** -- repository **variable**. `true` enables
  the gate; anything else (including unset) keeps today's release path
  unchanged. Rollback = set back to `false`, no code revert needed.
- **`FIREBASE_ANDROID_APP_ID`** -- repository **variable**. The
  `mobilesdk_app_id` for `com.sujinarin.ko_lernen_app` (verified present in
  `android/app/google-services.json`, 3 occurrences of the package name; no
  app id is committed anywhere).
- **`FIREBASE_SYMBOLS_SA_JSON`** -- repository **secret**. A service-account
  key authorized only for `firebase crashlytics:symbols:upload`; do not reuse
  the Play upload service account.
- **Harvest**: `tool/android_release_tools.json` already carries real,
  verified `version`/`url` values for all four tools (resolved via read-only
  GitHub/npm/Adoptium/nodejs.org metadata lookups -- no downloads performed).
  Every `sha256` field is the literal placeholder `"<fill from harvest step>"`.
  With the gate variable unset, a `play_closed.yml` run's always-on "Symbol
  evidence gate status" step prints the sha256 of whatever `java`/`node`
  binaries are already on the runner (no download). The bundletool jar's and
  `firebase-tools`'s `lib/bin/firebase.js` sha256 must come from each
  package's own published checksum/integrity metadata, not a download you
  trust on first use. Fill all four `sha256` fields, commit, and
  `tool/test_android_release_tools_config.py` will confirm the schema before
  the gate can ever run for real.

## Unexpected failures

1. **Fixed, in commit 1**: `.github/scripts/test_play_internal_workflow.py`
   hardcoded the literal bare tag `r0adkll/upload-google-play@v1.1.5` in two
   assertions. SHA-pinning changed that literal to
   `@<40-hex> # v1.1.5`, which broke both tests -- and this module runs on
   every PR/push via the `changes` job's "Verify CI and release contracts"
   step, so it would have turned every future CI run red. Applied the
   minimal fix: both assertions now match the pinned form via regex,
   preserving the exact same protections (exactly one Play-upload action,
   internal track only, no iOS/closed-testing deploy). No other file under
   `.github/scripts/` referenced a bare action tag.
2. **Not a failure, a timing observation**: `tool.test_android_release_evidence`
   took 216s standalone / 181s as part of the combined 78-test run in this
   session, well above `tool-test-profile.md`'s 63-67s. This session ran
   under a cost/scope-tracking hook the whole time and this machine was
   visibly more loaded than the profiling run. Both numbers still fit inside
   the 5-minute step-A timeout with real margin; no R4 test logic was
   touched.
3. **My own tooling, not the workflow**: an ad-hoc `bash -n` syntax-checker
   script I wrote first reported false-positive syntax errors on both new
   and pre-existing steps alike, caused by Python's text-mode stdin
   round-tripping `\n` back to `\r\n` on Windows before handing it to
   Cygwin bash. Fixed by writing each script to a file with explicit
   `newline="\n"` and invoking `bash -n <file>` directly; all 16 shell steps
   in `play_closed.yml` (including all 8 new ones) then passed cleanly.

## Design deviation flagged for review (not improvised -- narrower than requested)

Brief 2b says "export `GOOGLE_APPLICATION_CREDENTIALS`". I scoped it to a
per-step `env:` on only the two steps that actually invoke
`android_release_evidence.py` ("Upload and verify Crashlytics symbol
evidence" and "Archive symbol evidence") instead of exporting it job-wide via
`$GITHUB_ENV` from "Materialise Firebase credentials". A job-wide export
would have left that env var set in the process environment of the later,
explicitly off-limits "Upload to Google Play Closed Testing" step too. Same
secret, same two consumers, strictly narrower blast radius -- flagging in
case Jin wants the literal job-wide export instead.

## Cross-commit note (from the brief's own ordering, not my choice)

Per the task's literal instruction ("W1 items 1-7, then W2 items 1-4"), W1's
`ci.yml` addendum (item 7, commit 1) references
`tool.test_android_release_tools_config`, a module only created in W2 (item
4, commit 2). Commit 1 in isolation therefore has a CI step that would fail
to import that module until commit 2 lands on the same branch. Verified
after finishing W2 that the combined final state runs cleanly (78/78, see
above).

## Open questions (<=3)

1. `java.version` "17.0.20.1+1" was resolved from Adoptium's public API as
   the current Temurin 17 LTS build; Temurin ships patches on its own
   schedule, so this should be re-checked (not blindly trusted) at harvest
   time against whatever `actions/setup-java` actually resolves for
   `distribution: temurin`.
2. `node.version` "24.20.0" is the current Active LTS ("Krypton"); is a
   dedicated Node install (via `actions/setup-node`) the right choice for
   running `firebase-tools`, or would Jin prefer pinning to whatever Node
   version the Flutter/Firebase toolchain already standardizes on elsewhere
   in this repo?
3. Confirm the `GOOGLE_APPLICATION_CREDENTIALS` scoping choice above (narrower
   than the brief's literal "export" wording) is acceptable, or say if the
   job-wide `$GITHUB_ENV` export was actually intended.
