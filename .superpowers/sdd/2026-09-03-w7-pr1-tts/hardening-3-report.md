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
