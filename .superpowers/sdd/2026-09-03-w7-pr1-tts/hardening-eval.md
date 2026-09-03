# Hardening wave evaluation -- 445188b3..7adaadb4

Threshold 0.80 (normalised = accuracy*0.4 + clarity*0.3 + completeness*0.3, /5).

## Score table

| Unit | Label | Accuracy | Clarity | Completeness | Weighted | Pass |
|---|---|---|---|---|---|---|
| U0 | Fable supervision | 4 | 5 | 5 | 0.92 | yes |
| U1 | D1 (A+D+E) as delivered `445188b3..4f3227e4` | 3 | 4 | 4 | 0.72 | **no** |
| U2 | D1 fix round 1 `a6ae93f8` | 5 | 5 | 5 | 1.00 | yes |
| U3 | D2 C (bool removal) `173aff94` | 5 | 5 | 5 | 1.00 | yes |
| U4 | D2 B (phase matrix test) `47685843` | 4 | 5 | 5 | 0.92 | yes |
| U5 | D3 (F tool) as delivered `6cb03aeb` | 3 | 4 | 4 | 0.72 | **no** |
| U6 | D3 fix round 1 `7adaadb4` | 5 | 5 | 5 | 1.00 | yes |

**Overall: 0.90** (mean of 7 units) -- above threshold, but only because both fix rounds fully closed the two failing round-0 units.

## Evidence

**U0 (Fable supervision).** Two self-recorded brief defects, both real and verified: `hardening-2-brief.md:50` asserts `SoriSpeech.speak` "calls stopImpl() once before speakImpl" as if unconditional -- only true on the key-switch branch (`speakable.dart:216-218`); caught downstream by the D2 implementer, not by Fable before dispatch. `hardening-3-brief.md:5` gives a worktree-relative `.venv\Scripts\python.exe`, which did not exist, causing the D3 implementer to build a throwaway 217MB venv before a fix-round correction to the canonical path. All 4 of Fable's verdicts (D1 FIX-REQUIRED, D2 APPROVE, D3 FIX-REQUIRED, D3-fix APPROVE) check out against independent re-reading of every diff in this evaluation. For D3, no separate `hardening-3-review.md` exists -- Fable's own direct code read caught both Important bugs (F1/F2) unassisted.

**U1 (D1 as delivered).** Direct diff read at `test/auto_speech_test_stub_guard_test.dart:76-77` (pre-fix) confirms `isStubbed` accepted `SoriSpeech.resetForTesting(` alone, which restores the *real* TtsService delegates (`speakable.dart:135-138`) -- structurally the exact T3 trap the guard exists to catch. Lines 68/73/75/79 confirmed brace-less, violating `AGENTS.md:335`. `test/support/sori_speech_stubs.dart:30-39` confirmed a shared Completer between speak/speakSlow. No standalone report file exists for D1 (only `hardening-1-review.md`); evidence lives across 4 commit messages.

**U2 (D1 fix).** `git show a6ae93f8` confirms the marker now requires `stubSoriSpeech(` or `speakImpl =`; verified `'speakSlowImpl ='` does not falsely satisfy the `speakImpl =` substring. All 4 brace sites fixed. `speakCompleter`/`speakSlowCompleter` are now independent fields. Independently re-verified against `hardening-2-review.md` Checklist 1a-1d (all OK, allowlist/cap unchanged at 60).

**U3 (bool removal).** `git show 173aff94` matches the brief's FILES list line-for-line: 4 write/definition sites removed from `tts_service.dart`, 3 sites removed from `speakable.dart`, doc comments reworded so no dangling `comment_references` diagnostic is possible. `AudioPolicy` call sites (`tts_service.dart:640,659,770`) untouched. Diffstat 3 files / 15+/24- matches DONE (<=4 files). Reviewer APPROVE.

**U4 (phase matrix).** All 10 rows verified against `hardening-2-review.md`'s independent line-by-line trace. Rows 4/5 correctly compute `stub.stops==1` by tracing that `previousKey==null` skips the key-switch `stopImpl` branch -- the implementer worked around the brief's own imprecise row-5 premise (see U0) rather than copying it blindly, and documented the reasoning inline. One Minor, attributable to this file: the "fills only after a microtask turn" framing doesn't strictly hold for row 1 (synchronous call), harmless but never corrected in a later commit. GREEN-first pinning explicitly stated; non-vacuity independently demonstrated via a deliberate row-2 mutation.

**U5 (F tool as delivered).** `tool/check_brief_anchors.py:54` (`_find`, pre-fix) confirmed via `git show 6cb03aeb` to use plain substring containment (`name in text or last in text`) -- an invented `cacheDir` would false-match inside a real `_cacheDir`, and an invented `stop` inside a real `stopImpl`, defeating the tool's stated primary purpose ("the invented-name case", `hardening-3-brief.md:19`). `IDENT_RE` at line 28 confirmed to skip any backtick token with a trailing call or `=` suffix, undercounting checks. Both are Important-severity and were found by Fable's own direct code read (no second reviewer). The relative-venv brief defect (U0) left a 217MB duplicate venv in the worktree, still undeleted after the fix round.

**U6 (D3 fix).** `git show 7adaadb4` confirms both fixes exactly as claimed: token-boundary lookaround regex (correctly avoiding `\b` because Korean is a `re` word character), and `IDENT_RE` extended to capture call/assignment backtick forms. `wc -l` on the fixed file returns exactly 200 (at cap, not over). 12/12 own tests including 4 new regression cases targeting F1/F2 directly. Two independent real-run verifications (against `hardening-2-brief.md` and self-referentially against `hardening-3-brief.md`) with every MISSING row explained and none attributable to the fixed bugs.

## Optimize actions (units below 0.80)

**U1** (fixed in U2, listed for completeness of the round-0 record):
1. `test/auto_speech_test_stub_guard_test.dart:76-77` -- require `stubSoriSpeech(` or `speakImpl =`; reject `SoriSpeech.resetForTesting(` alone.
2. `test/auto_speech_test_stub_guard_test.dart:68,73,75,79` -- brace all 4 single-line if bodies.
3. `test/support/sori_speech_stubs.dart:30-39` -- independent Completers for speak/speakSlow.

**U5** (fixed in U6, listed for completeness of the round-0 record):
1. `tool/check_brief_anchors.py:54` (`_find`) -- token-boundary lookaround regex instead of substring `in`.
2. `tool/check_brief_anchors.py:28` (`IDENT_RE`) -- capture leading identifier of call/assignment backtick forms.
3. `tool/check_brief_anchors.py` docstring -- document external-concept MISSING-by-design behavior.

## Improvements (units >= 0.80, <=1 each)

- **U0**: trace control-flow claims used in count assertions before writing them into a brief (the row-5 `stopImpl` premise, U0 evidence).
- **U2**: none -- fully closed.
- **U3**: none -- fully closed.
- **U4**: `test/sori_speech_phase_matrix_test.dart` row 1 -- add a one-line comment noting the synchronous call, per reviewer Minor #2.
- **U6**: none -- fully closed.

## Trajectory

Both hardening pairs improved from round 0 to their fix round, and both did so in a single pass (no second FIX-REQUIRED verdict was needed):
- **D1**: U1 0.72 -> U2 1.00. Two Important defects (guard heuristic hole, 4 brace violations) plus one Minor (shared completer), all verified closed with zero new offenders.
- **D3**: U5 0.72 -> U6 1.00. Two Important defects (substring false-match, skipped call/assignment identifier forms) that struck at the tool's own core purpose, fixed with 4 new regression tests and two independent real-run brief checks.

## Critical issues (axes <= 2)

None. The lowest individual-dimension scores are 3 (U1 accuracy, U5 accuracy), both above the critical floor and both closed by the immediately following fix commit.
