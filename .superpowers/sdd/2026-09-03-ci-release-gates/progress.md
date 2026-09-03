# Progress — CI release gates (2026-09-03)

Worktree: `C:\dev\hangulsori\ko_lernen_app_worktrees\ci-release-gates-20260903`
Branch: `claude/ci-release-gates-20260903` (from `origin/main`, base commit `d120af87`, PR #259 squash-merge)

## START CONDITION
- `git fetch origin main` on canonical repo: OK, first try (no retry needed).
- `origin/main:tool/release_integrity.py` and `origin/main:tool/android_release_evidence.py` both present (`git cat-file -e`): OK.
- Worktree created via `git worktree add -b claude/ci-release-gates-20260903 <path> origin/main`.

## W1 — SHA-pin all workflows + workflow-integrity job (commit 1)

1. Manifest additions: resolved via read-only `gh api`:
   - `gh api repos/google-github-actions/auth/git/ref/tags/v2 -q .object` → `{"sha":"c200f3691d83b41bf9bbd8638997a462592937ed","type":"commit",...}` (already a commit object, no dereference needed).
   - `gh api repos/google-github-actions/setup-gcloud/git/ref/tags/v2 -q .object` → `{"sha":"e427ad8a34f8676edf47cf7d7925499adf3eb74f","type":"commit",...}` (already a commit object).
   - Added both to `tool/release_toolchain.json` under `actions`; `binaries` block untouched.
   - `python tool/release_integrity.py manifest` → `{"schemaVersion": 1, "verified": true}` OK.
2. Rewrote every `uses:` in `ci.yml`, `play_closed.yml`, `playwright.yml` to `owner/repo@<sha> # <version>` using a throwaway script (`$TEMP/pin_actions.py`, not committed) driven purely off the manifest. Result: `ci.yml` 38 lines changed, `play_closed.yml` 6 lines changed, `playwright.yml` 0 changed (already correctly pinned by #257, verified identical to manifest values). `git diff` confirmed via grep that no non-`uses:` line changed in either file.
   - **Fact correction vs brief**: `playwright.yml` actually has 5 `uses:` lines (not 3 as the brief's fact sheet said) — reported, not silently substituted.
3. Added job `workflow-integrity` ("Workflow action pins") to `ci.yml`, no `needs`, `runs-on: ubuntu-latest`, `timeout-minutes: 5`: pinned checkout, pinned setup-python 3.12, `pip install pyyaml==6.0.2`, `python tool/release_integrity.py manifest`, `python tool/release_integrity.py actions <3 workflow files>`.
   - Investigated the `changes` job ("Select required checks", ~L82-181): it only computes boolean scope outputs (`app`, `website`, `book`, `gye`, `pronunciation`, `tts`, `auth_cleanup`, `ios`, `content`, `flutter_test_mode`, `flutter_tests`) consumed via `needs.changes.outputs.*` in other jobs' `if:`. There is no explicit list of required job names and no `needs:` fan-in job anywhere in `ci.yml`, and no in-repo file registers required-status-check names (`grep -rln "required.*check|requiredContexts|required_status_checks"` under `.github/` matched nothing but `ci.yml`'s own comment). Branch-protection required-checks lists live in GitHub repo settings, outside this repo's tracked files — out of scope for this package. Per the brief's fallback ("if it only computes scopes, do nothing more"): did nothing further. Jin will need to add "Workflow action pins" as a required status check in GitHub branch protection settings if desired.
4. Added `tool/test_release_integrity.py::test_repository_workflows_are_fully_pinned`: runs the real `verify_workflow` against the real manifest and the three real workflow files, asserts the checked count equals the count of lines matching `^\s*(?:-\s*)?uses:\s` in each file. No `skipUnless` — a missing PyYAML makes the test error/fail, not skip.
5. Verification:
   - `tool.test_release_integrity -v` (throwaway venv, PyYAML 6.0.2): **28 tests, OK** (27 pre-existing + 1 new).
   - `python tool/release_integrity.py actions .github/workflows/ci.yml .github/workflows/play_closed.yml .github/workflows/playwright.yml` → `{"actionsChecked": 51}` (49 after the pin rewrite alone, +2 for the two new pinned `uses:` in the `workflow-integrity` job itself).
   - YAML-parsed all three workflow files with `yaml.safe_load`: OK.
   - `python -m unittest discover -s .github/scripts -p "test_*.py"`: **initially 2 FAILURES** (see "Unexpected failures" below) — fixed, now 64/64 OK.

### Unexpected failure (fixed, documented)
`.github/scripts/test_play_internal_workflow.py` hardcoded the literal bare tag `r0adkll/upload-google-play@v1.1.5` in two assertions (`test_release_is_signed_reproducible_and_targets_internal_only`, `test_ci_never_deploys_ios_or_closed_testing`). This module runs on every PR/push via the `changes` job's "Verify CI and release contracts" step, so SHA-pinning would have turned that step red on the very next CI run. Applied the minimal fix: both assertions now match the SHA-pinned form via regex (`r0adkll/upload-google-play@[0-9a-f]{40} # v1\.1\.5` and `^r0adkll/upload-google-play@[0-9a-f]{40}$`) instead of the bare tag string. Same protections preserved (exactly one Play upload action, internal track only, no iOS/closed-testing deploy) — only the literal-string match was updated to tolerate the new pinned reference shape. No other `.github/scripts/*.py` file referenced a bare action tag (grepped for all 8 pinned action names + `@v` — no other hits).

## W1 addendum (items 6-7)
6. `asset-gates` job `timeout-minutes` raised 10 → 20.
7. Split the single "Run tool/ unit tests" step into:
   - "Run tool/ release-integrity tests" (`timeout-minutes: 5`): `python -m unittest tool.test_release_integrity tool.test_android_release_evidence tool.test_android_release_tools_config -v`
   - "Run tool/ unit tests (image pipeline and the rest)": unchanged `python -m unittest discover -s tool -p "test_*.py" -t .` (re-runs step A's modules too, per brief's "acceptable, prefer simplicity").
   - **Note**: step A references `tool.test_android_release_tools_config`, which does not exist until W2 item 4 (this commit, commit 1, therefore leaves `ci.yml` referencing a module that is only created in commit 2). This is what the brief specifies verbatim ("W1 items 1-7" listed before "W2 items 1-4"); flagging so Jin is aware commit 1 in isolation would fail that CI step until commit 2 lands on the same branch. Verified at the end of this session (after W2) that the full split step actually runs and passes.

Commit 1 message: `ci(security): SHA-pin all workflow actions and verify them with release_integrity.py on every run`

## W2 — symbol-evidence gate in play_closed.yml (commit 2)

Read `tool/android_release_evidence.py` in full (module docstring, `_validate_tool`,
`upload_symbols`, `main()`'s argparse) before designing anything.

1. New `tool/android_release_tools.json` (no secrets, all real except sha256):
   - `bundletool.version` "1.18.3" / `.url` (real GitHub release asset URL) — resolved via read-only `gh api repos/google/bundletool/releases/latest` (no download).
   - `firebase-tools.version` "15.29.0" — resolved via read-only `curl https://registry.npmjs.org/firebase-tools/latest` (metadata only, confirmed `"bin":{"firebase":"lib/bin/firebase.js"}` matches the tool's expected path).
   - `java.version` "17.0.20.1+1" (current Temurin 17 LTS build, resolved via read-only `https://api.adoptium.net/v3/assets/latest/17/hotspot?image_type=jdk`) — this exact build string should be re-checked at harvest time since Temurin patches roll forward.
   - `node.version` "24.20.0" (current Active LTS "Krypton", resolved via read-only `https://nodejs.org/dist/index.json`).
   - All four `sha256` fields are the literal placeholder `<fill from harvest step>` — none can be computed offline without downloading (prohibited for this session).
   - `docs/runbooks/android-symbol-evidence.md` (57 lines, within the 60-line budget): what the gate does, the 3 secrets/variables to create, the harvest procedure, and rollback (set `ANDROID_SYMBOL_EVIDENCE_GATE` back to `false`).
2. `play_closed.yml`, inserted between "Record bundle identity" and "Preserve AAB and Dart symbols":
   - "Symbol evidence gate status" (always-on, no `if`) — prints gate state; if disabled, prints `sha256sum` of whatever `java`/`node` binaries are already on `PATH` from existing setup steps. Downloads nothing.
   - "Read pinned release-toolchain versions" (gated, `id: toolchain`) — reads `tool/android_release_tools.json` with a Python heredoc (stdlib `json`, no `jq` needed) and emits one `GITHUB_OUTPUT` line per field (`bundletool_version`, `bundletool_url`, `bundletool_sha256`, `firebase_tools_version`, `firebase_tools_sha256`, `java_version`, `java_sha256`, `node_version`, `node_sha256`).
   - "Pin release-toolchain Java" / "... Node" (gated) — `actions/setup-java`/`actions/setup-node` (both pinned via the W1 manifest) using the exact versions from step `toolchain`'s outputs.
   - "Download and verify bundletool" (gated, `id: bundletool`) — downloads the pinned jar to `$RUNNER_TEMP` and `sha256sum -c`s it against the manifest value.
   - "Install and verify firebase-tools" (gated, `id: firebase-tools`) — `npm install --no-save --prefix $RUNNER_TEMP/firebase-tools-scratch` (no global install) and verifies `lib/bin/firebase.js`'s hash.
   - "Write release-evidence tools manifest" (gated, `id: tools-json`) — resolves the absolute `java`/`node` paths via `command -v` and writes the exact `{"bundletool": {"argv": [...], "sha256": {...}}, "firebase": {...}}` shape `android_release_evidence.py --tools-json` expects.
   - "Materialise Firebase credentials" (gated) — writes `secrets.FIREBASE_SYMBOLS_SA_JSON` to `$RUNNER_TEMP/firebase-sa.json` under `umask 077`; fails with `::error::` if the secret is empty; also fails with `::error::` if an ambient `FIREBASE_TOKEN` is set. **Deliberately does not export `GOOGLE_APPLICATION_CREDENTIALS` job-wide via `$GITHUB_ENV`** (see "Design deviation" below).
   - "Upload and verify Crashlytics symbol evidence" (gated, `id: symbol-evidence`) — builds one `common_args` array (aab, symbols dir, google-services.json, receipt path, tools-json, git-sha, run-id, run-attempt, version-code, firebase-app-id, expected-aab-sha256 parsed from the `.sha256` file written by "Record bundle identity") and runs `upload` then `verify` with the identical args. Only the tool's own JSON stdout/stderr is printed.
   - "Archive symbol evidence" (gated, `id: archive-evidence`) + "Preserve symbol evidence artifact" (gated `upload-artifact`, pinned) — archives to `$RUNNER_TEMP/symbol-evidence` and uploads as `android-symbol-evidence-v<version-code>-<sha>`, `retention-days: 90`.
   - Every gated step/`uses:` carries `if: vars.ANDROID_SYMBOL_EVIDENCE_GATE == 'true'`; the Play upload step is unmodified and unconditional as before, and now sits strictly after these steps in job order, so any non-zero exit here fails the job before the upload runs.
3. Verified `android/app/google-services.json` contains `"package_name": "com.sujinarin.ko_lernen_app"` (grep, 3 occurrences) — matches `mobilesdk_app_id` cross-check the tool performs. No app id committed; it comes from `vars.FIREBASE_ANDROID_APP_ID` at runtime.
4. Tests:
   - `tool/test_android_release_evidence.py`: confirmed **zero diff** (`git diff --stat` empty) — untouched as required.
   - Added `tool/test_android_release_tools_config.py` (stdlib only, no network): schema keys, `SEMVER`/`JAVA_VERSION` regexes on every version string, bundletool URL host+path-prefix, and every `sha256` field is either 64-hex or the literal placeholder (with a dedicated test that placeholders can appear **only** in `sha256`, nowhere else) — **6/6 tests pass**.
   - YAML-parsed `play_closed.yml` with `yaml.safe_load`: OK.
   - `python tool/release_integrity.py actions .github/workflows/play_closed.yml` → `{"actionsChecked": 9}` (was 6 after W1's rewrite; +3 for the two new pinned `setup-java`/`setup-node` calls and the new pinned `upload-artifact` call in this gate).
   - Combined `.github/workflows/*.yml` actions check after both commits: `{"actionsChecked": 54}`.
   - Full W1 `test_release_integrity.py` suite re-run after the W2 edits: still 28/28 OK (its `test_repository_workflows_are_fully_pinned` covers `play_closed.yml`'s new lines too).
   - `python -m unittest tool.test_release_integrity tool.test_android_release_evidence tool.test_android_release_tools_config -v` (the exact command the new ci.yml split step runs): **78/78 tests, OK**, wall time 181s in this session (vs. profile's 63-67s for just R4 — see "Timing note" below); fits the 5-minute step timeout with margin.
   - Did not install pillow/numpy/scipy locally to re-run the full unrelated `tool/` `discover` (step B); not requested by the brief for W2, and step B's command itself is unchanged from before this package.
   - Ran `bash -n` against every embedded shell script in `play_closed.yml` (16 steps, including all 8 new ones) after correcting a false-positive from my own checker (Windows text-mode stdin re-inserts CRLF; fixed by writing to a file with explicit `newline="\n"` and invoking `bash -n <file>`): all OK.
   - Independently simulated the exact `--tools-json` JSON shape the "Write release-evidence tools manifest" step produces against the real `_validate_tool`/`ToolCommand` construction in `tool/android_release_evidence.py` (fixture executables + matching sha256, run outside the repo): validator accepts the well-formed manifest and correctly rejects a tampered jar with `tool_mismatch`. Confirms the schema this PR authors is accepted by the real tool without needing a live GitHub runner.

### Design deviation from the literal brief wording (flagged, not a gap)
Brief 2b says "export `GOOGLE_APPLICATION_CREDENTIALS`"; I scoped it to a per-step `env:` on only the two steps that call `android_release_evidence.py` ("Upload and verify..." and "Archive symbol evidence") instead of exporting it job-wide via `$GITHUB_ENV` from "Materialise Firebase credentials". Job-wide export would have left `GOOGLE_APPLICATION_CREDENTIALS` set in the process environment of the later "Upload to Google Play Closed Testing" step too, which is explicitly off-limits ("DO NOT change the Play upload step itself") — that step already authenticates via `serviceAccountJsonPlainText` and should not have an ambient ADC env var alongside it, even though the action likely prioritizes its explicit input. Same secret, same two consuming steps, strictly narrower blast radius.

### Timing note
`tool.test_android_release_evidence` alone took 216s in this session (isolated run) and 181s as part of the combined 78-test command — both far above the 63-67s in `tool-test-profile.md`, but this machine/session is visibly under more load than the profiling run (this whole session ran under a cost/scope-tracking hook throughout). Both numbers still fit inside the 5-minute (300s) step-A timeout with real margin. No R4 test logic was touched, per the brief's explicit instruction.

### Note: intentional cross-commit reference (from the brief, not my choice)
Per the task's literal ordering ("W1 items 1-7, then W2 items 1-4"), W1's `ci.yml` addendum (item 7, commit 1) references `tool.test_android_release_tools_config`, which is only created in W2 (item 4, commit 2). Commit 1 in isolation therefore has a `ci.yml` step that would fail to import that module until commit 2 lands on the same branch/PR. Verified after finishing W2 that the combined final state runs cleanly (see the 78/78 run above).

Commit 2 message: `ci(release): variable-gated Crashlytics symbol-evidence gate before Play upload (R4), harvest step, runbook`
