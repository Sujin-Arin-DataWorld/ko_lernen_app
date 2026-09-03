# W7 PR1 — Full Verification Report

- Worktree: `C:\dev\hangulsori\ko_lernen_app_worktrees\w7-pr1-tts-20260903`
- Branch: `claude/w7-pr1-tts-20260903`
- Date: 2026-09-03
- Mode: verification-only (no edits, no commits)

## 1. `flutter analyze --no-pub`

Wall time: 120.5 s (tool wall clock) / 116.3 s (analyzer-reported)

```
Analyzing w7-pr1-tts-20260903...
No issues found! (ran in 116.3s)
```

Result: **No issues found.**

## 2. `flutter test --no-pub --reporter failures-only`

Wall time: 455.6 s (~7.6 min)

Final summary line:

```
+5497 ~14: 14 skipped tests.
+5497 ~14: All other tests passed!
```

Counts:
- Passed: 5497
- Failed: 0
- Skipped: 14

This matches the expected baseline (0 failures, exactly 14 skipped — Linux-only goldens + opt-in captures).

### Failure blocks

None. No test failed. All lines in the captured output that mention "failed"/"FAILED"/"error=" are intentional in-test log output from tests that exercise failure-handling/fail-soft code paths (e.g. `DataMigrationResult(failed:...)`, `Storage: ... write failed`, `soriVideoLease: create/prepare FAILED ...`, `klAccount: deletion.failed ...`) — these are expected diagnostic prints from passing tests, not test failures. No `[E]` markers or numbered failure blocks were present anywhere in the output.

Full captured stdout/stderr for this run is preserved at:
`C:\Users\vjinn\AppData\Local\Temp\test_output.txt` (359 lines, `failures-only` reporter, so it prints test start markers only for tests up to and including the first line that logs anything to stdout — normal for this reporter/codebase).

## 3. Re-run of failing test files

Not applicable — zero failures in the full run, so no re-run was performed.

## Summary

| Check | Result |
|---|---|
| `flutter analyze --no-pub` | No issues found (116.3s) |
| `flutter test` passed | 5497 |
| `flutter test` failed | 0 |
| `flutter test` skipped | 14 |
| Flaky vs deterministic | N/A (no failures) |
| Total wall time (analyze + test) | ~576 s (~9.6 min) |
