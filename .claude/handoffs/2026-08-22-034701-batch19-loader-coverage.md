# Handoff: Batch 19 A1–C2 loader coverage

## Session metadata

- Created: 2026-08-22 03:47:01 Europe/Berlin
- Base: `origin/main` at `caebe3e408d4dcab6502835ae430c5e64feb167d`
- Branch: `codex/batch-live-coverage-20260822`
- Worktree: `C:\dev\hangulsori\ko_lernen_app_worktrees\batch-live-coverage-20260822`
- User authority: commit, push, merge to main, validate, and remove merged worktree/branch

## Completed

- Promoted approved Batch 19 with 345 tracked standard/supplemental records.
- Closed A1–C2 scenario, smalltalk category, cloze, Satzbau, pronunciation, and Silben loader gaps.
- Added exact-level media phrase practice and wired it through route, Discover, and Practice Hub.
- Preserved exact-level daily review so C learners do not receive A1 `안녕하세요`.
- Rebuilt can-do assets without changing the 86 published slots; all raw sources are now routed.
- Repaired the three known base-main CI regressions: immutable ID counts, Batch 18 vocab pack route,
  and `smalltalk_b2_0101` semantic decision coverage.
- Generated and uploaded 633 missing TTS files; verification reports 12,060 expected and 0 missing.

## Verification completed before commit

- Python content, batch, loader, can-do, Unicode, and rejected-phrase checks passed.
- Targeted Flutter content/loader/catalog tests passed.
- `flutter analyze` passed with no issues.
- Full Flutter suite, feature commit/push, clean main integration, exact-head CI, and branch cleanup
  remain the final lifecycle steps.

## Safety and source policy

- PDF material supplied generalized educational signals only; no PDF wording, tables, questions,
  IDs, page references, or unit order entered the app assets.
- The dirty user main checkout was not modified.
- Remote stale TTS cache entries (304) were retained; no destructive storage cleanup was performed.
