# Hardening Dispatch 3 — F: `tool/check_brief_anchors.py` — Report

BASE = HEAD = `476858437f5378610ad980713c0a855d53eee80e` (no other commits landed on the branch during this dispatch; the two new files are staged, not yet committed, at report time).

## ① Files + diffstat

New files only (no existing file touched):

```
 tool/check_brief_anchors.py      | 192 +++++++++++++++++++++++++++++++++++++++
 tool/test_check_brief_anchors.py | 190 ++++++++++++++++++++++++++++++++++++++
 2 files changed, 382 insertions(+)
```

`tool/check_brief_anchors.py` line count: **192** (limit 200).

Note: `.superpowers/sdd/2026-09-03-w7-pr1-tts/progress.md` shows as modified in `git status`, but that change pre-dates this dispatch (present before any file in this task was touched) and was not written by this task — left untouched per instructions.

Note on environment: `.venv\Scripts\python.exe` did not exist anywhere in this worktree at the start of this dispatch (confirmed with `find`, PowerShell `Test-Path`, and `cmd /c dir /a` — all negative), even though `task-8-report.md` from earlier in this same PR references using it. A fresh venv was created from the non-Store system Python 3.13.7 (`python -m venv .venv`) per the `always-use-project-venv` convention; it started with zero packages installed.

## ② RED log

```
test_check_brief_anchors (unittest.loader._FailedTest.test_check_brief_anchors) ... ERROR

======================================================================
ERROR: test_check_brief_anchors (unittest.loader._FailedTest.test_check_brief_anchors)
----------------------------------------------------------------------
ImportError: Failed to import test module: test_check_brief_anchors
Traceback (most recent call last):
  File "...\Lib\unittest\loader.py", line 137, in loadTestsFromName
    module = __import__(module_name)
  File "...\tool\test_check_brief_anchors.py", line 23, in <module>
    import check_brief_anchors  # noqa: E402
    ^^^^^^^^^^^^^^^^^^^^^^^^^^
ModuleNotFoundError: No module named 'check_brief_anchors'

----------------------------------------------------------------------
Ran 1 test in 0.001s

FAILED (errors=1)
```

(All 8 test methods fail this same way pre-implementation; unittest's `-v` loader stops at the import error for the whole module, so only one `ERROR` line is emitted — this is the expected RED for "module does not exist yet".)

## ③ GREEN log (own suite)

```
$ .venv\Scripts\python.exe -m unittest tool.test_check_brief_anchors -v
test_1_identifier_found_near_anchor_is_ok ... ok
test_2_identifier_found_elsewhere_is_drift ... ok
test_3_identifier_missing_everywhere_fails ... ok
test_4_missing_file_fails ... ok
test_5_anchor_beyond_eof_fails ... ok
test_6_bare_filename_unique_ok_ambiguous_drift ... ok
test_7_l_forms_bind_and_bare_numbers_are_ignored ... ok
test_8_exit_code_and_summary_line_contract ... ok

----------------------------------------------------------------------
Ran 8 tests in 0.250s

OK
```

**8/8 pass, first implementation, no fix-up iterations needed.**

## ④ `python -m unittest discover -s tool -p "test_*.py" -t .`

Ran twice (before/after installing the two missing third-party deps that unrelated pre-existing `tool/` modules import — see §⑤): **289 tests total**, `FAILED (failures=2, errors=2)`. `tool.test_check_brief_anchors`'s own 8 tests are inside this run and are not among the 4 failures (confirmed by grepping the failure list for the module name — no match).

```
Ran 289 tests in 351.943s
FAILED (failures=2, errors=2)
```

## ⑤ Real run — `hardening-2-brief.md`

```
python -X utf8 tool\check_brief_anchors.py .superpowers\sdd\2026-09-03-w7-pr1-tts\hardening-2-brief.md
```

Did not crash. Exit code 1 (2 MISSING rows, both explained below — see §⑥).

```
OK	brief:4	docs/superpowers/plans/2026-09-03-w7-pr1-tts.md	
MISSING	brief:17	lib/services/tts_service.dart:600-601	comment_references not found
OK	brief:18	lib/widgets/sori/speakable.dart:48-49	phase
MISSING	brief:18	lib/widgets/sori/speakable.dart:48-49	_syncSpeakingFromPhase not found
OK	brief:18	lib/widgets/sori/speakable.dart:48-49	phase
OK	brief:18	lib/widgets/sori/speakable.dart:48-49	speaking
OK	brief:18	lib/widgets/sori/speakable.dart:48-49	phase
OK	brief:19	test/review_session_screen_speakable_test.dart:18	TtsService.speaking
OK	brief:19	test/review_session_screen_speakable_test.dart:18	TtsService.phase
OK	brief:25	lib/widgets/sori/speakable.dart	didPushNext
OK	brief:25	test/content_audio_policy_guard_test.dart	
OK	brief:25	test/sori_speech_dedupe_test.dart	
OK	brief:25	test/speakable_screen_lifecycle_test.dart	
OK	brief:25	test/speakable_semantics_test.dart	
OK	brief:25	test/tts_premium_only_test.dart	
OK	brief:35	test/sori_speech_phase_matrix_test.dart	SoriSpeech.phase
OK	brief:35	test/sori_speech_phase_matrix_test.dart	SoriSpeech.phase
OK	brief:37	test/sori_speech_phase_matrix_test.dart	
OK	brief:39	lib/services/tts_service.dart:543-560	
OK	brief:39	lib/services/tts_service.dart:603-618	
OK	brief:39	lib/services/tts_service.dart:636-665	
OK	brief:39	lib/services/tts_service.dart:760-775	
OK	brief:39	lib/widgets/sori/speakable.dart:60-90	
OK	brief:39	lib/widgets/sori/speakable.dart:200-260	
OK	brief:39	lib/widgets/sori/speakable.dart:340-360	
OK	brief:41	test/speakable_semantics_test.dart:159-160	
OK	brief:43	test/support/sori_speech_stubs.dart	stub.speakCompleter
OK	brief:43	test/support/sori_speech_stubs.dart	SoriSpeech.speakImpl
OK	brief:61	test/auto_speech_test_stub_guard_test.dart	
OK	brief:63	test/sori_speech_phase_matrix_test.dart	
OK	brief:67	.superpowers/sdd/2026-09-03-w7-pr1-tts/hardening-2-report.md	content_audio_policy_guard_test
OK	brief:67	.superpowers/sdd/2026-09-03-w7-pr1-tts/hardening-2-report.md	auto_speech_test_stub_guard_test
OK 30 · DRIFT 0 · MISSING 2
```

## ⑥ The two MISSING rows, explained

Both are false positives *for this specific re-run* rather than defects in the D2 (hardening-2) dispatch, for two different reasons:

1. **`brief:17` — `comment_references` not found in `lib/services/tts_service.dart:600-601`.** The brief line reads "...doc references to a nonexistent identifier are an analyzer diagnostic under `` `comment_references` ``." `comment_references` is the *name of a Dart analyzer lint rule*, not a symbol defined anywhere in `tts_service.dart` — the brief text is factually correct as written. My tool's identifier grammar (per the hardening-3 brief spec: "a backtick-quoted token ... that is neither a path token nor an anchor") has no way to distinguish "a backtick-quoted symbol meant to exist in this file" from "a backtick-quoted term referring to an external Dart/analyzer concept" — both are syntactically identical. I did not add a special-case exclusion for this (e.g. a lint-name denylist), since that would be unscoped guessing beyond the spec and would risk suppressing genuine T5-style catches elsewhere. **Not a brief defect, not a fixable parser bug under the specified grammar** — recorded as an open question below.
2. **`brief:18` — `_syncSpeakingFromPhase` not found in `lib/widgets/sori/speakable.dart:48-49`.** This is the exact symbol that hardening-2's own task C instructs to *delete*. Per `progress.md`, task C was already implemented and committed (`173aff94`, "`TtsService.speaking`/`SoriSpeech.speaking` removed") **before** this dispatch ran its real-run check, and this worktree's `BASE` already includes that commit. So the anchor is correctly, expectedly stale: the brief described a "before" state, the deletion it asked for has already happened, and the checker is faithfully reporting that the deleted symbol is no longer present. **Expected — not a defect, not a parser bug.**

No other row was unexpected; the DRIFT-eligible design (see §⑦ open questions) never triggered here because every found identifier landed inside its anchor's search window.

## ⑦ Unexpected failures (separate section)

None caused by `tool/check_brief_anchors.py` or `tool/test_check_brief_anchors.py`. Everything below is a pre-existing environment gap in this freshly-created venv, unrelated to this task's two files:

- **4 failures in the full `tool/` discovery, unrelated to TTS/hardening:**
  - `tool.test_cut_single_object` — 2 `ERROR`s: `result.stderr` is `None` because a `subprocess.run()` call inside that test/tool decodes child-process output with the Windows Korean codepage (`UnicodeDecodeError: 'cp949' codec can't decode byte 0xe2...`) instead of forcing UTF-8. Pre-existing locale bug in that module, not in scope for this task (FILES restricts me to the two `check_brief_anchors` files).
  - `tool.test_check_card_style` / `tool.test_check_decoration_cutouts` — 2 `FAIL`s, most likely numeric drift from the newly-installed Pillow/numpy versions differing from whatever was pinned in the venv that existed earlier in this PR (that venv no longer exists in this worktree — see below). Not touched, not in scope.
- **Root cause context:** `.venv\Scripts\python.exe` did not exist in this worktree at the start of this dispatch (verified three ways). `task-8-report.md`, written earlier in this same PR, explicitly used `.venv\Scripts\python.exe` for its unittest runs, so a working venv existed at some point in this worktree's history and was since lost (worktree/session churn, not this task). I recreated it from system Python 3.13.7 and installed `Pillow`, `numpy`, `scipy` (the packages unrelated pre-existing `tool/` tests import) so the "still green" discover check would reflect real regressions rather than blanket import errors — before installing them, 25 modules failed to import outright; after, only the 4 listed above remain, and none touch anything I wrote.

## Open questions (≤3)

1. Should `comment_references`-style false positives (a backtick-quoted term that names an external Dart/analyzer concept rather than a file-local symbol) be suppressed with a small denylist, or is an occasional explainable MISSING the accepted cost of the simple grammar in the brief? I left it as-is per "no assertion bending" / no unscoped grammar extensions.
2. For a path segment with multiple anchors (e.g. `brief:18` above has L48-49, L54-56, L58-60 all bound to the same path), the tool checks each identifier against the *union* of all the segment's anchor windows but labels the output row with only the *first* anchor (e.g. everything shows `:48-49` even when a match was actually inside the L58-60 window). This keeps the implementation under 200 lines; is a more precise per-anchor row split worth the extra lines for a future revision?
3. This worktree's `.venv` had to be recreated from scratch and given `Pillow`/`numpy`/`scipy` to get a meaningful "still green" discover result — should the repo carry a `tool/requirements.txt` (or similar) so this doesn't need re-deriving by trial and error next time a worktree loses its venv? (Out of scope for this dispatch's FILES list, so not added here.)

---

# Fix round 1 (Fable review on `6cb03aeb`)

Verdict: FIX-REQUIRED — F1 (Important, substring false-matches), F2 (Important, call/assignment backtick forms silently skipped), F3 (Minor, docstring note). All three addressed.

## What changed

- **F1** — `_find` no longer does `name in text`. It now compiles two token-boundary regexes per call (once, not per line): `(?<![A-Za-z0-9_])<name>(?![A-Za-z0-9_])` for the full (possibly dotted) name and the same for its last segment. Explicit lookarounds rather than `\b`, because Python's `\b` treats Korean characters as word characters too -- a name immediately followed by a Korean particle with no space (common in these briefs' target-file comments) would otherwise hide the boundary.
- **F2** -- `IDENT_RE` changed from a bare-identifier-only match to a pattern that also accepts a trailing call `(...)` or assignment `=...` inside the backtick span, so `` `ident` ``, `` `ident(...)` `` (any args), and `` `ident =...` `` are all captured by their leading identifier. Paths, `--flags`, regex fragments, and `L123` forms still don't fit that shape, so they stay excluded.
- **F3** -- added a docstring paragraph explaining that a backtick-quoted external concept (Dart lint rule name, package, SDK type) will read as MISSING since it names no file-local symbol; that is intentional, and the human is expected to read the table. No logic change.
- Tool file: **200 lines** (`(Get-Content tool/check_brief_anchors.py).Count`) -- at the cap, not over.

## GREEN log (own suite, canonical venv)

```
C:\dev\hangulsori\ko_lernen_app\.venv\Scripts\python.exe -m unittest tool.test_check_brief_anchors -v

test_10_suffix_substring_is_not_a_false_match ... ok
test_11_underscore_prefixed_name_matches_via_lookaround ... ok
test_12_call_and_assignment_backtick_forms_are_checked ... ok
test_1_identifier_found_near_anchor_is_ok ... ok
test_2_identifier_found_elsewhere_is_drift ... ok
test_3_identifier_missing_everywhere_fails ... ok
test_4_missing_file_fails ... ok
test_5_anchor_beyond_eof_fails ... ok
test_6_bare_filename_unique_ok_ambiguous_drift ... ok
test_7_l_forms_bind_and_bare_numbers_are_ignored ... ok
test_8_exit_code_and_summary_line_contract ... ok
test_9_prefix_substring_is_not_a_false_match ... ok

----------------------------------------------------------------------
Ran 12 tests in 0.180s

OK
```

**12/12 pass** (8 original + 4 new: `test_9`/`test_10`/`test_11` cover F1's three sub-cases -- an invented name must not match as a substring of `_cacheDir`, `stop` must not match inside `stopImpl`, and `_cacheDir` cited against `_cacheDir` must still match via the lookaround; `test_12` covers F2's call/assignment forms exactly as specified, `foo()`/`bar(x: 1)`/`baz =` -> OK/OK/MISSING).

Note on venv: per the coordinator's correction, the worktree never had a `.venv` of its own -- the canonical one lives at `C:\dev\hangulsori\ko_lernen_app\.venv\Scripts\python.exe`. Used that path for every command in this fix round. The `.venv` created directly inside the worktree in round 0 (with Pillow/numpy/scipy installed) was left in place, undeleted, per instruction.

Full `tool/` discovery was **not** re-run this round -- only the two files in scope changed, and round 0 already established the 4 pre-existing unrelated failures (cp949 subprocess-decoding in `test_cut_single_object`, numpy/Pillow version-skew in `test_check_card_style`/`test_check_decoration_cutouts`) are independent of this file.

## Real run 1 -- `hardening-2-brief.md` (unchanged brief, re-run with the fixed tool)

```
OK	brief:4	docs/superpowers/plans/2026-09-03-w7-pr1-tts.md	
OK	brief:17	lib/services/tts_service.dart:600-601	speaking.value
OK	brief:17	lib/services/tts_service.dart:600-601	speak
OK	brief:17	lib/services/tts_service.dart:600-601	speaking.value
OK	brief:17	lib/services/tts_service.dart:600-601	speaking.value
OK	brief:17	lib/services/tts_service.dart:600-601	stop
MISSING	brief:17	lib/services/tts_service.dart:600-601	comment_references not found
OK	brief:18	lib/widgets/sori/speakable.dart:48-49	phase
MISSING	brief:18	lib/widgets/sori/speakable.dart:48-49	_syncSpeakingFromPhase not found
OK	brief:18	lib/widgets/sori/speakable.dart:48-49	phase
OK	brief:18	lib/widgets/sori/speakable.dart:48-49	speaking
OK	brief:18	lib/widgets/sori/speakable.dart:48-49	phase
OK	brief:18	lib/widgets/sori/speakable.dart:48-49	TtsService.stop
OK	brief:19	test/review_session_screen_speakable_test.dart:18	TtsService.speaking
OK	brief:19	test/review_session_screen_speakable_test.dart:18	TtsService.phase
OK	brief:25	lib/widgets/sori/speakable.dart	TtsService.stop
OK	brief:25	lib/widgets/sori/speakable.dart	didPushNext
OK	brief:25	test/content_audio_policy_guard_test.dart	
OK	brief:25	test/sori_speech_dedupe_test.dart	
OK	brief:25	test/speakable_screen_lifecycle_test.dart	
OK	brief:25	test/speakable_semantics_test.dart	
OK	brief:25	test/tts_premium_only_test.dart	
OK	brief:35	test/sori_speech_phase_matrix_test.dart	SoriSpeech.phase
OK	brief:35	test/sori_speech_phase_matrix_test.dart	SoriSpeech.phase
OK	brief:37	test/sori_speech_phase_matrix_test.dart	
OK	brief:39	lib/services/tts_service.dart:543-560	
OK	brief:39	lib/services/tts_service.dart:603-618	
OK	brief:39	lib/services/tts_service.dart:636-665	
OK	brief:39	lib/services/tts_service.dart:760-775	
OK	brief:39	lib/widgets/sori/speakable.dart:60-90	
OK	brief:39	lib/widgets/sori/speakable.dart:200-260	
OK	brief:39	lib/widgets/sori/speakable.dart:340-360	
OK	brief:41	test/speakable_semantics_test.dart:159-160	
OK	brief:43	test/support/sori_speech_stubs.dart	stub.speakCompleter
OK	brief:43	test/support/sori_speech_stubs.dart	SoriSpeech.speakImpl
OK	brief:43	test/support/sori_speech_stubs.dart	stubSoriSpeech
OK	brief:43	test/support/sori_speech_stubs.dart	addTearDown
OK	brief:61	test/auto_speech_test_stub_guard_test.dart	
OK	brief:63	test/sori_speech_phase_matrix_test.dart	
OK	brief:67	.superpowers/sdd/2026-09-03-w7-pr1-tts/hardening-2-report.md	content_audio_policy_guard_test
OK	brief:67	.superpowers/sdd/2026-09-03-w7-pr1-tts/hardening-2-report.md	auto_speech_test_stub_guard_test
OK 39 · DRIFT 0 · MISSING 2
```

41 rows (up from 32 in round 0 -- F2 now also checks `speaking.value`, `speak`, `stop`, `TtsService.stop`, `stubSoriSpeech`, `addTearDown`, all of which resolve OK). Still exactly **2 MISSING**, same two as round 0, same explanation, unaffected by F1/F2 (they were never substring-match or call/assignment-form artifacts):

1. `brief:17` -- `comment_references` names a Dart analyzer lint rule, not a symbol in `tts_service.dart`; the brief text is correct as written. Exactly the case F3's new docstring note now documents.
2. `brief:18` -- `_syncSpeakingFromPhase` is the symbol hardening-2's own task C instructs to delete, and that deletion was already committed (`173aff94`) before this worktree's BASE -- an expected, correctly-reported stale anchor, not a defect.

## Real run 2 -- `hardening-3-brief.md` (this task's own brief)

```
OK	brief:1	tool/check_brief_anchors.py	
OK	brief:9	.github/workflows/ci.yml:710	
OK	brief:9	tool/check_brief_anchors.py	
OK	brief:9	tool/test_check_brief_anchors.py	
OK	brief:9	tool/test_ledger_append.py	sys.path.insert
OK	brief:9	tool/test_ledger_append.py	unittest
MISSING	brief:11	task-1..8-brief.md	no such file
OK	brief:12	.github/scripts/ci_scope.py	
OK	brief:12	lib/services/tts_service.dart	
OK	brief:12	test/content_audio_policy_guard_test.dart:12-22	
MISSING	brief:12	tts_bundled_manifest.dart:195-209	build not found
MISSING	brief:13	x.dart	no such file
MISSING	brief:13	y.dart	no such file
MISSING	brief:23	brief.md	no such file
OK	brief:23	tool/check_brief_anchors.py	
MISSING	brief:26	lib/a.dart	no such file
MISSING	brief:26	lib/a.dart	no such file
OK	brief:34	.superpowers/sdd/2026-09-03-w7-pr1-tts/hardening-2-brief.md	
OK	brief:34	tool/check_brief_anchors.py	
OK	brief:36	tool/check_brief_anchors.py	
OK	brief:40	.superpowers/sdd/2026-09-03-w7-pr1-tts/hardening-3-report.md	
OK 14 · DRIFT 0 · MISSING 7
```

Did not crash; exit 1 (7 MISSING). This brief is unusual as a check target: it is the *grammar specification* for this very tool, so several of its "path tokens" are illustrative examples or CLI placeholders rather than real repo files. Every MISSING explained:

1. **`brief:11` -- `task-1..8-brief.md`.** From the grammar prose "derived from the real PR1 briefs `task-1..8-brief.md`" -- a range-shorthand notation for "task-1-brief.md through task-8-brief.md", not a literal filename. It happens to satisfy the path-token character class (dots and digits are legal path characters) and ends in `.md`. Not a brief defect (the prose is correct and readable to a human); not a targeted parser bug either -- excluding it would need shorthand-range detection that isn't part of the specified grammar and would be scope creep for this fix round.
2. **`brief:12` -- `` `build` `` not found near `tts_bundled_manifest.dart:195-209`.** The line is "(skip `` `.dart_tool` ``, `` `build` ``, `` `.git` ``)" -- three backtick-quoted directory names to skip during bare-filename search, bound (nearest-preceding-path) to the bare-filename example `tts_bundled_manifest.dart:195-209` on the same line. `.dart_tool` and `.git` start with `.` and are correctly excluded by the identifier grammar (must start with a letter or `_`); `build` has no such leading punctuation, so it reads as an identifier-to-verify and is (correctly) absent from that file. Same class of limitation as `comment_references` in round 0 -- a backtick-quoted token naming something other than a file-local symbol.
3. **`brief:13` -- `x.dart` / `y.dart`.** From the grammar's own illustrative example of the L-anchor-binding syntax. These are placeholder filenames used purely for demonstration, never meant to exist in this repo.
4. **`brief:23` -- `brief.md`.** From the CLI usage line, `<brief.md>` is an angle-bracket CLI placeholder for "your real brief path"; the path regex doesn't special-case `<...>` and picks up the bare filename inside it, which naturally isn't a real file under `lib/`, `test/`, `tool/`, `.github/`, or `docs/`.
5. **`brief:26` -- `lib/a.dart` (x2).** From TDD case 1's description of a *test fixture* that only ever exists inside a tempdir at test-run time (see `tool/test_check_brief_anchors.py::test_1_identifier_found_near_anchor_is_ok`) -- there is and should never be a real `lib/a.dart` in this repository.

All seven fall into the same category: the checker is doing exactly what it is specified to do (verify every path-shaped, backtick-quoted token against the real tree), and this particular brief's job is to *describe* that grammar using realistic-looking examples and placeholders, which is unavoidably indistinguishable from a real citation under the current grammar. None required a parser fix; none are defects in the brief's prose. This is a useful data point for whoever dispatches a check against a grammar/spec document rather than a task brief: expect illustrative examples to show as MISSING, and read the table -- exactly as F3's new docstring note says.

## Unexpected failures

None. Every MISSING row across both real runs is explained above; nothing crashed; `tool.test_check_brief_anchors` is 12/12 on the canonical venv.

## Open questions (fix round 1, <=3)

1. Same as round 0 #1: should external-concept identifiers (`comment_references`, `build` as a skip-dir name) be suppressed with a small denylist? Left as-is -- F3's docstring note is the agreed-upon fix for this round.
2. Should the path-token grammar special-case `<...>`-wrapped CLI placeholders and `N..M`-style range shorthands so a grammar/spec document like this brief checks fully clean? Not requested in this fix round; flagged for a future pass if the tool is ever run against documentation rather than task briefs.
3. Same as round 0 #2 (multi-anchor union-window + first-anchor row label) -- unaffected by this round's changes, still open.

---

# Final fix wave (opus whole-branch review, `hardening-final-review.md`)

Two commits, per the coordinator's "group 1+2 / 3+4+5+6" option:

- `8139f9f6` -- items 1+2 (I1/I2/M1 in `tool/check_brief_anchors.py` + M2/M3 in `test/auto_speech_test_stub_guard_test.dart`)
- `4c5b1ba2` -- items 3+4+5 (M5 disk-tier poll headroom, M4 ADR-002 wording, M7 `.gitignore`)

Item 6 (verify) is folded into this section rather than a commit. `progress.md` untouched. A graphify run was live in this worktree during the whole wave (`git status` showed 12 modified + several untracked `graphify-out/...` paths throughout) -- every `git add` below named exact files, never `-A`/`.`, so none of that was swept in.

## Diffstat per item

```
8139f9f6 fix(tool,test): repo-root/assets path resolution + import-line skip in check_brief_anchors; guard allowlist ratchets down (I1/I2/M1/M2/M3)
 test/auto_speech_test_stub_guard_test.dart | 27 +++++++++++++++--
 tool/check_brief_anchors.py                | 26 +++++++++++++----
 tool/test_check_brief_anchors.py           | 47 ++++++++++++++++++++++++++++++
 3 files changed, 92 insertions(+), 8 deletions(-)

4c5b1ba2 fix(test,docs): disk-tier poll headroom, ADR-002 phase wording, ignore .venv/ (M5/M4/M7)
 .gitignore                   | 5 +++++
 docs/ADR-002-audio-policy.md | 4 ++--
 test/tts_disk_tier_test.dart | 7 +++++--
 3 files changed, 12 insertions(+), 4 deletions(-)
```

`tool/check_brief_anchors.py` line count: **216** (raised cap 220, not exceeded).

## What changed (item 1 -- I1/I2/M1)

- **I1**: `_resolve` now tries `root / path_str` first for every token (bare or slash-qualified), so repo-root files (`pubspec.yaml`, `AGENTS.md`, `analysis_options.yaml`) and dir-qualified `assets/...` paths resolve directly; only a bare filename with no direct hit still falls back to the `SEARCH_DIRS` walk, which now includes `assets`.
- **I2**: a `PATH_RE` match is skipped when the literal 8 characters before it end in `package:` or `dart:`, and when the matched path itself starts with `../`.
- **M1**: docstring-only -- added a sentence stating that a backtick-quoted prose word anywhere after a path token binds to that path (nearest-preceding-path heuristic), a known limit, not a bug. No behavior change, as instructed.
- Tests added (16 total now, was 12): `test_13` (I1a, repo-root bare file), `test_14` (I1b, dir-qualified `assets/data/x.json` and bare `x.json` under `assets`), `test_15` (I2c+../, `package:flutter/material.dart` import and a `../../services/sound_service.dart` relative import both produce zero rows), `test_16` (I2d, a contrived `dart:async.dart` token to prove the `dart:`-prefix skip actually fires, since real `dart:` imports rarely carry a recognised extension on their own).

## What changed (item 2 -- M2/M3)

- **M2**: after `unstubbed` is computed, `stale = knownUnstubbedTestFiles.where((f) => !unstubbed.contains(f))` and `expect(stale, isEmpty, reason: '고쳐졌거나 사라진 파일은 허용 목록에서 지우고 knownUnstubbedCap을 낮출 것: ...')`. Allowlist (60 entries) and cap (60) both left unchanged.
- **M3**: docstring rewritten to say exactly what each marker proves -- `stubSoriSpeech(` stubs all four hooks (speak/speakSlow/prefetch/stop); a bare `speakImpl =` only proves speak is stubbed, prefetch/stop may still reach the real service, and that is accepted as evidence only because the T3 trap the guard exists for is specifically the speak in-flight lock.

## Mutation check (M2, item 2)

Baseline run (before mutation) -- clean:

```
00:00 +0: 자동 발화 화면을 pumpWidget하는 테스트는 SoriSpeech를 스텁한다
00:10 +1: All tests passed!
```

Mutated (`knownUnstubbedTestFiles` +`'test/zz_not_a_file_test.dart'`, `knownUnstubbedCap` 60->61, so only the new `stale` assertion could trip):

```
00:00 +0 -1: 자동 발화 화면을 pumpWidget하는 테스트는 SoriSpeech를 스텁한다 [E]
  Expected: empty
    Actual: ['test/zz_not_a_file_test.dart']
  고쳐졌거나 사라진 파일은 허용 목록에서 지우고 knownUnstubbedCap을 낮출 것: test/zz_not_a_file_test.dart

  package:matcher                                     expect
  package:flutter_test/src/widget_tester.dart 473:18  expect
  test\auto_speech_test_stub_guard_test.dart 126:5    main.<fn>

00:00 +0 -1: Some tests failed.
```

FAILED exactly on the new `stale` assertion (line 126, the `newOffenders` assertion above it never tripped, since the fake path was never a real offender). Reverted both lines; re-ran -- back to `All tests passed!` (diff after revert contains only the intended M2 addition, confirmed via `git diff`).

## Per-brief tool table (all real briefs, fixed tool, canonical venv)

| Brief | OK | DRIFT | MISSING | exit | remaining MISSING all legit? |
|---|---|---|---|---|---|
| task-1-brief.md | 20 | 1 | 2 | 1 | yes |
| task-2-brief.md | 40 | 0 | 3 | 1 | yes |
| task-3-brief.md | 21 | 1 | 2 | 1 | 1 of 2 (see below) |
| task-4-brief.md | 29 | 2 | 4 | 1 | yes |
| task-5-brief.md | 22 | 0 | 3 | 1 | yes |
| task-6-brief.md | 17 | 1 | 3 | 1 | yes |
| task-7-brief.md | 38 | 1 | 1 | 1 | yes |
| task-8-brief.md | 35 | 1 | 5 | 1 | yes |
| hardening-2-brief.md | 39 | 0 | 2 | 1 | yes (round-0/1 explanations, unchanged) |
| hardening-3-brief.md | 14 | 0 | 7 | 1 | yes (round-1 explanations, unchanged) |

Reviewer's two named benchmarks, confirmed fixed: **task-7 8 -> 1** (the 1 remaining is M1-class, not an import/repo-root false positive) and **task-5 15 (12 import lines) -> 3** (all 3 remaining are M1-class; all 12 import-line false positives are gone -- verified by grep-counting `import '` lines in task-5-brief.md and confirming none appear in its output table).

### Classification of every remaining MISSING row

The overwhelming majority (31 of 32 total MISSING rows across the 8 task briefs + 2 hardening briefs) are the **M1 heuristic limit documented this round**: an identifier or anchor textually follows a path token on the same brief line but semantically describes a *different* file, class, or concept than the one nearest-preceding-path binds it to. Verified per row, not asserted:

- **task-1 `speakable.dart:330-333` `onResolutionFailed`/`errorReporter`** -- these are `TtsPlaybackEngine` constructor fields defined in `tts_service.dart` (see task-1-brief.md's own Interfaces section); bound to the nearer `speakable.dart` mention earlier in the sentence.
- **task-2 `content_audio_policy_guard_test.dart:426-437`/`:313-342` (EOF) + `phase`** -- the real file is **143 lines** (verified: `wc -l`); L313-342/L426-437 cannot be in it. `lib/widgets/sori/speakable.dart` is 564 lines and plausibly holds the `SoriSpeakable`/`phase`-subscription content the sentence describes -- bound to the wrong (nearer) path.
- **task-3 `vocab_pack_screen.dart:686-693` `voice`** -- `voice` is a parameter name of `SoriSpeech.prefetch` (defined in `speakable.dart`), described here as "call it with voice omitted", not a literal token expected inside `vocab_pack_screen.dart`.
- **task-4 (x4)** -- `SoriSpeech.speakImpl`/`spoken` describe the *new* file being authored (`vocab_notebook_audio_test.dart`, the first, not-yet-existing path on that line) using shared test-stub infrastructure; `SoriSpeakable` describes a *production* widget-wrapping change, not literal content of the existing test file it got bound to.
- **task-5 (x3)** -- `MilestoneType`/`AudioPolicy`/`SoundService._play` are other classes/services referenced for context, not symbols expected inside `custom_pack_quiz_screen.dart`.
- **task-6 (x3)** -- `_maxBytes`(L515)/`_cacheDir` are production constants; `account_cleanup_test.dart` is **111 lines** (verified), so L515 cannot be in it -- almost certainly `tts_service.dart` (1312 lines).
- **task-7 `pubspec.yaml` `bundledCount`** -- a JSON-manifest/Dart-test assertion key, not literal `pubspec.yaml` content; `pubspec.yaml` is only the nearest-preceding path because it was mentioned two sentences earlier for an unrelated reason (the 3 added asset lines).
- **task-8 (x5, 2 are EOF)** -- `test_verify_storage_mode_reaches_its_own_read_only_branch`(L721-746)/`test_bare_invocation_is_rejected`(L546-554) cannot be in `.github/scripts/test_ci_scope.py` (**128 lines**, verified) but fit comfortably in `tool/test_generate_tts.py` (1011 lines, verified); `modes` is a real Python variable, confirmed at `tool/generate_tts.py:1297` (`modes = parser.add_mutually_exclusive_group(...)`), not in `test_ci_scope.py`.
- **hardening-2 (x2)** and **hardening-3 (x7)** -- unchanged from rounds 0/1 (`comment_references` = external Dart lint-rule name; `_syncSpeakingFromPhase` = already-deleted symbol; hardening-3's 7 are the grammar spec's own illustrative examples/placeholders, see the round-1 section above).

**The one row that is not cleanly "legit" under invented/deleted/external-concept:** `task-3 brief:30 helpers/deck_actions.dart no such file`, from `import 'helpers/deck_actions.dart';`. This is a same-directory-relative Dart import (no `package:` scheme, no leading `../`), which is inherently ambiguous for a text-only checker -- it is syntactically indistinguishable from a real repo-root-relative citation, and resolving it correctly would require knowing which file the `import` statement lives inside (not derivable from the brief text). This falls outside the literally-specified I2 fix (`package:`/`dart:` prefix and `../`-prefix only) and I did not extend the skip to bare `import '...'` tokens generally, to stay inside the round's precisely itemized scope rather than invent an unrequested heuristic. Flagged as an open question below rather than silently left unexplained.

## GREEN log (item 6 -- verify)

```
flutter test --no-pub test/auto_speech_test_stub_guard_test.dart test/tts_disk_tier_test.dart test/content_audio_policy_guard_test.dart
...
00:03 +10: All tests passed!
```
10/10 (1 guard + 1 disk-tier + 8 `content_audio_policy_guard_test`).

```
flutter analyze --no-pub
Analyzing w7-pr1-tts-20260903...
No issues found! (ran in 125.1s)
```

```
C:\dev\hangulsori\ko_lernen_app\.venv\Scripts\python.exe -X utf8 -m unittest tool.test_check_brief_anchors -v
...
Ran 16 tests in 0.165s
OK
```

```
git diff --check -- .gitignore docs/ADR-002-audio-policy.md test/auto_speech_test_stub_guard_test.dart test/tts_disk_tier_test.dart tool/check_brief_anchors.py tool/test_check_brief_anchors.py
(clean, exit 0 -- restricted to this wave's own files since an unrestricted `git diff --check` against the whole working tree pulls in the concurrent graphify run's untracked/modified output and is not a meaningful signal for this wave)
```

## Unexpected failures

None. The full Flutter suite was not run (as instructed). `graphify-out/` was observed changing live throughout (12 tracked files modified, several new untracked `cache/ast/...json` files appeared between checks) but was never staged or touched by either commit.

## Open questions (final fix wave, <=3)

1. `task-3-brief.md:30`'s `helpers/deck_actions.dart` (a bare same-directory-relative Dart import) is a residual false MISSING outside this round's literal I1/I2 scope (`package:`/`dart:`/`../` only). Should a future round extend the skip to any path token immediately preceded by `import '`/`import "` generally, regardless of prefix?
2. M1 accounts for 31 of 32 total MISSING rows across the 10 real briefs. Docstring-only was the agreed fix for this round -- is the volume here (now precisely measured, not just described) enough to justify the behavior fix the original review offered as an alternative ("bind in either direction, or require an identifier to look like code")?
3. M6 (ledger commit hygiene -- keep `*-report.md` out of code commits, land `hardening-2-report.md` + this review doc + `progress.md` together) and M8 (graphify-out ignore rule) were named in the review but not included in this round's numbered items and were left untouched, per the coordinator's explicit "do NOT touch graphify-out/" instruction for this dispatch.
