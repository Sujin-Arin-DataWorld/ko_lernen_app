# Task 8 Report — CI 콘텐츠 TTS 완결성 게이트 + stale 삭제 커맨드

## ① Diffstat

```
 .github/scripts/ci_scope.py      | 21 ++++++++++++++++++++-
 .github/scripts/test_ci_scope.py |  8 ++++++++
 .github/workflows/ci.yml         | 35 +++++++++++++++++++++++++++++++++++
 tool/generate_tts.py             | 33 +++++++++++++++++++++++++++++++++
 tool/test_generate_tts.py        | 32 ++++++++++++++++++++++++++++++++
 5 files changed, 128 insertions(+), 1 deletion(-)
```

No Dart files touched (`git status --short` shows only the five files above modified; one pre-existing untracked plan file, `docs/superpowers/plans/2026-09-03-w7-pr1-tts.md`, was not created by this task and left alone).

## ② RED

`test_ci_scope.py` (cwd `.github/scripts`, before implementation):
```
Ran 13 tests in 0.003s
FAILED (failures=1)
FAIL: test_content_shard_change_selects_only_content_gate
  AssertionError: Items in the first set but not the second: 'app'
  Items in the second set but not the first: 'content'
```
(`test_tts_function_change_is_not_conflated_with_content_scope` already passed pre-implementation — `content` scope didn't exist yet, so there was nothing to conflate.)

`tool.test_generate_tts` (worktree root, targeted run of the 2 new tests, before implementation):
```
Ran 2 tests in 0.001s
FAILED (errors=2)
```
Both failed with `AttributeError: module 'tool.test_generate_tts' has no attribute 'TestGenerateTts'` on the first attempt — the actual class is `TtsGeneratorContractTest`, not `TestGenerateTts` as the brief's snippet assumed. Re-run with the correct class name:
```
test_delete_stale_requires_verify_storage ... ok   (argparse "unrecognized arguments" already raises SystemExit != 0)
test_verify_storage_lists_stale_paths_without_deleting ... ERROR
  AttributeError: module 'generate_tts' ... does not have the attribute 'delete_remote_objects'
```
This matches the brief's expected RED shape.

## ③ GREEN (both suites)

`test_ci_scope.py` (cwd `.github/scripts`): **13/13 passed** (11 existing + 2 new).
`tool.test_generate_tts` (worktree root): **32/32 passed** (30 existing + 2 new).
Full CI-equivalent discovery (`python -X utf8 -m unittest discover -s .github/scripts -p "test_*.py"`, all scripts including `select_flutter_tests`): **47/47 passed**.

## ④ YAML validation

`.venv\Scripts\python.exe` (the pinned worktree venv) does not have PyYAML installed, and the task instructions say to install nothing. The system Python resolved via `python3`/`python` in the Bash tool (`C:\Users\vjinn\AppData\Local\Programs\Python\Python313`, not the Windows Store stub) already has PyYAML installed, so used that instead of installing anything:
```python
import yaml
data = yaml.safe_load(open('.github/workflows/ci.yml', encoding='utf-8'))
```
Result: `yaml ok`. Additional structural checks against the parsed object confirmed: `content` output present on the `changes` job, `tts-storage-verify` job present with `needs: changes`, `if: needs.changes.outputs.content == 'true'`, and the 6 expected step names in order (Checkout, Fail with a clear message when the GCS secret is missing, Authenticate to Google Cloud (read-only), Set up Cloud SDK, Set up Python, Verify TTS Storage completeness).

## ⑤ Frozen tests (all unmodified & confirmed GREEN)

- `test_isolated_product_areas_select_only_their_gate` — unmodified, still asserts `functions/tts/` → `tts` only.
- `test_verify_storage_mode_reaches_its_own_read_only_branch` — unmodified; verify-storage alone still performs no writes (`auth`/`synth`/`run` all `assert_not_called()`).
- `test_bare_invocation_is_rejected` — unmodified; bare invocation still rejected by argparse.
- `test_v3_storage_key_matches_flutter_and_function_contract` — unmodified, untouched by this change, passing.
- Task 7's new tests (`test_download_first_line_bundle_*`, and `--download-first-line-bundle` staying in the `modes` group) — unmodified, all passing; `--delete-stale`/`--confirm-delete` were added via separate `parser.add_argument` calls, not `modes.add_argument`, so the mutually-exclusive group is untouched.

`git diff` on both test files shows pure insertions (no line of any existing test was changed), confirmed by inspection.

## ⑥ Unexpected failures

None beyond the expected RED failures in ②. One process note: the brief's RED-test class name (`TestGenerateTts`) doesn't match the file's actual class (`TtsGeneratorContractTest`) — worked around by using the correct name; no code consequence, purely a test-runner invocation detail.

## ⑦ Open questions (≤3)

1. `GCS_TTS_VERIFY_SA_JSON` minimum-privilege scope and registration timing are Jin's call (§9 ruling 5, W9-A) — this task only added the explicit-failure step for when it's absent.
2. `google-github-actions/setup-gcloud@v2` is new to this repo's CI; its real-world validity (action resolves, gcloud installs cleanly on `ubuntu-latest`) can only be confirmed by an actual PR CI run — not exercised here per the no-network-calls constraint.
3. None outstanding beyond the above two, which are explicitly out of this task's scope per the controller's rulings.

## ⑧ Self-review

- **No network calls**: every new/changed test mocks `subprocess.run`, `shutil.which`, `remote_cache_objects`, and `delete_remote_objects` via `patch.object`; no real `gcloud` invocation occurs anywhere in the test suite or in this session's verification commands. `delete_remote_objects()` itself was never executed for real — only asserted `not_called()` in tests.
- **Dry-run default confirmed**: `args.confirm_delete` defaults to `False` (plain `store_true` flag), so `delete_remote_objects` is only invoked when both `--delete-stale` and `--confirm-delete` are passed together; `test_verify_storage_lists_stale_paths_without_deleting` exercises `--delete-stale` alone and asserts `delete.assert_not_called()`.
- **Mutual-exclusion intact**: `--delete-stale`/`--confirm-delete` were added via `parser.add_argument`, not `modes.add_argument` — outside the `required=True` mutually-exclusive `modes` group. `--delete-stale` without `--verify-storage` and `--confirm-delete` without `--delete-stale` both call `parser.error(...)`, which raises `SystemExit` with a non-zero code (verified by `test_delete_stale_requires_verify_storage` and by re-reading the validation block).
- **YAML indentation**: verified structurally via PyYAML `safe_load` (not just a lint) — the parsed dict's `jobs.changes.outputs.content`, `jobs['tts-storage-verify']['if']/['needs']`, and the ordered step-name list all matched expectations, confirming correct indentation and job placement (inserted between `tts-functions-security` and `auth-cleanup-functions-security`).
- **Scope isolation**: `assets/data/other_unrelated_file.json` (not in the corpus list) still resolves to `{'app'}` only; `assets/data/scenarios_a1.json` plus an unrelated `assets/data/other.json` resolves to `{'content', 'app'}` — confirming the new branches only add `content` for the exact listed files/pattern and never suppress the existing fallback for other `assets/data/*` paths. `functions/tts/` still isolates to `tts` only (new dedicated test + unmodified `test_isolated_product_areas_select_only_their_gate`).
- **Exit policy unchanged**: `return 1 if missing else 0` is untouched by the stale-printing/deletion addition — stale objects (printed or deleted) never affect the exit code, only `missing` does.
- No commit was made this run pending explicit "Jin 요청 시에만" per Step 8 of the brief; controller ruling says commit when green, so a commit follows this report (see chat reply for the commit hash).
