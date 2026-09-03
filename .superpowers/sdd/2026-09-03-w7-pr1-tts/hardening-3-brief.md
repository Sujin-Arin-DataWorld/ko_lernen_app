# HARDENING DISPATCH 3 — F: `tool/check_brief_anchors.py` (brief anchor checker)

Branch `claude/w7-pr1-tts-20260903`, worktree `C:\dev\hangulsori\ko_lernen_app_worktrees\w7-pr1-tts-20260903`. BASE = HEAD when you start (record it). Ledger dir `.superpowers/sdd/2026-09-03-w7-pr1-tts/`.

Standing rules: TDD (RED log before GREEN); no files outside FILES (R1); no assertion bending (R2); Python via `.venv\Scripts\python.exe` with `PYTHONIOENCODING=utf-8`; PowerShell syntax, no `&&`; commit trailer `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`, identity Codex/codex@local.

GOAL: a read-only CLI Fable runs **before dispatching a brief**: it verifies that every file/line anchor in a brief markdown file exists in the repo and that identifiers quoted in backticks on the same brief line actually appear near the anchored lines. Motivation (plan §4 item 11): PR1 briefs T5/T7/T8 cited a wrong constant name, a wrong JSON key and a wrong scope gate — all brief-authoring errors that a 2-second check would have caught.

FILES: new `tool/check_brief_anchors.py` (≤200 lines, stdlib only), new `tool/test_check_brief_anchors.py`. CI already runs `python -m unittest discover -s tool -p "test_*.py" -t .` (`.github/workflows/ci.yml:710`), so the test is picked up automatically — it must need no network and no repo assets (tempfile fixtures only). Style: mirror `tool/test_ledger_append.py` header (module docstring, `from __future__ import annotations`, `sys.path.insert(0, ...)`, `unittest`).

ANCHOR GRAMMAR (derived from the real PR1 briefs `task-1..8-brief.md` in the ledger dir — read two of them first):
- **Path token**: a relative path ending in one of `.dart .py .yml .yaml .json .arb .md .csv`, optionally wrapped in backticks, e.g. `lib/services/tts_service.dart`, `test/content_audio_policy_guard_test.dart:12-22`, `.github/scripts/ci_scope.py`. A path may be a **bare filename** (`tts_bundled_manifest.dart:195-209`): resolve by searching `lib/`, `test/`, `tool/`, `.github/`, `docs/` recursively (skip `.dart_tool`, `build`, `.git`); exactly one hit → use it; zero → MISSING; more than one → AMBIGUOUS (counted as DRIFT, list the candidates).
- **Line anchor** bound to the nearest preceding path token on the same brief line: `:123`, `:123-139`, `L123`, `L123-139` — the `L` forms may appear later on the same line after the path (e.g. `` `x.dart`(import + L205) ``, `` `y.dart`(`showMilestoneCelebration` L19-30) ``). Bare numbers without `L` or `:` (e.g. "fields 258-282, ctor 264") are **not** anchors — ignore them.
- **Identifier**: a backtick-quoted token on the same brief line matching `[A-Za-z_][A-Za-z0-9_.]*` that is neither a path token nor an anchor, e.g. `_maxBytes`, `clearCacheStrict`, `SoriSpeech.phase`. For dotted tokens, the check passes if either the full token or its last segment (`phase`) is found.

CHECKS (per brief line, per path token):
- File cannot be resolved → `MISSING` (detail: "no such file" / candidates).
- Line anchor beyond EOF → `MISSING` (detail: "EOF at N").
- For each identifier on that line, with an anchor: search the window `[start-W, end+W]` (W = `--window`, default 25) → found → `OK`; found elsewhere in the file only → `DRIFT` (detail: first line where it was found); not found anywhere in the file → `MISSING` (this is the T5-style invented-name case — the most important one).
- Identifiers on a line whose path has **no** anchor: must exist anywhere in the file → `OK` / `MISSING`.
- Path with neither anchor nor identifiers → existence only (`OK`).

OUTPUT: one row per check, tab-separated `STATUS<TAB>brief:<line><TAB>path[:anchor]<TAB>detail`, sorted by brief line then path; a final summary line `OK n · DRIFT n · MISSING n`. Exit code **1 only if any MISSING**; DRIFT/AMBIGUOUS exit 0. CLI: `python tool/check_brief_anchors.py <brief.md> [--root DIR] [--window N]`; `main(argv) -> int` so tests call it without subprocess. Open every file with `encoding="utf-8"` (briefs are Korean); never write anything.

TDD (tests first, RED log attached, then implement):
1. OK — fixture repo with `lib/a.dart` containing `const int kFoo = 1;` at line 3; brief line `` `lib/a.dart:3` sets `kFoo` `` → OK.
2. DRIFT — same identifier at line 80, brief anchors line 3, window 25 → DRIFT with detail line 80.
3. MISSING identifier — brief quotes `kBar` which is nowhere in the file → MISSING, exit 1.
4. MISSING file → MISSING, exit 1.
5. Anchor beyond EOF → MISSING.
6. Bare filename resolves uniquely under `test/` → OK; the same bare name present in both `lib/` and `test/` → DRIFT with "ambiguous" detail, exit 0.
7. `L123-139` and `(import + L205)` forms bind to the preceding path; plain "fields 258-282" numbers are ignored (assert they produce no row).
8. Exit-code semantics via the return value of `main([...])` and the summary line via captured stdout (`contextlib.redirect_stdout`).
Then GREEN, then the **first real run**: `python -X utf8 tool/check_brief_anchors.py .superpowers/sdd/2026-09-03-w7-pr1-tts/hardening-2-brief.md` and paste the full table in the report (DRIFT rows are fine; the run must not crash; any MISSING row must be explained — it is either a real brief defect (report it, do not "fix" the brief) or a parser bug (fix the parser)).

DO NOT: touch any other tool/CI file; add a CI job; use third-party packages; exceed 200 lines in the tool file (`(Get-Content tool/check_brief_anchors.py).Count`).

DONE: `python -m unittest tool.test_check_brief_anchors -v` all pass (count); `python -m unittest discover -s tool -p "test_*.py" -t .` still green (count); line count ≤ 200; real-run table pasted.

REPORT → `.superpowers/sdd/2026-09-03-w7-pr1-tts/hardening-3-report.md`: BASE/HEAD · files + diffstat · RED log · GREEN log with counts · tool discover count · line count · real-run table · unexpected failures (separate section) · ≤3 open questions. Run everything in the foreground.
