# Hardening wave final review — 445188b3..7adaadb4 (9 commits)

## Verdict: FIX-REQUIRED

Production code (A/B/C/D/E) is clean and mergeable as is. Both Important findings are in the new
Python dev tool (F), zero app impact — a ~10-line fix in `tool/check_brief_anchors.py` closes both.

## Findings

### Important

**I1 — bare filenames outside `lib/test/tool/.github/docs` always report MISSING (exit 1)**
`tool/check_brief_anchors.py:37-55` (`_resolve`), `:33` (`SEARCH_DIRS`)
A path token with no `/` is only looked up under the five `SEARCH_DIRS`, so repo-root files
(`pubspec.yaml`, `AGENTS.md`, `analysis_options.yaml`) and everything under `assets/` are
unresolvable. Reproduced here (canonical venv, `-X utf8`): `task-7-brief.md` gives
`OK 31 / DRIFT 1 / MISSING 8` and all 8 MISSING are false — 6x `pubspec.yaml no such file`,
2x `tts_first_line_manifest.json no such file` (it exists at
`assets/data/tts_first_line_manifest.json`, cf. `lib/services/tts_bundled_manifest.dart:22`).
Matters because the tool's whole contract is exit 1 only on a real brief defect (docstring
`:16-17`, code `:196`); a signal that is red on a correct brief gets ignored within two dispatches
and the T5/T7/T8 lesson that motivated F stays unguarded.
Fix: in `_resolve`, try `root / path_str` before the walk, and add `assets` to `SEARCH_DIRS`.

**I2 — `package:` / `dart:` import lines in brief code blocks parse as repo paths**
`tool/check_brief_anchors.py:28-30` (`PATH_RE`)
`:` is not in the path character class, so `import 'package:flutter/material.dart';` yields the
token `flutter/material.dart`, which has a `/` and resolves as `root/flutter/material.dart` ->
MISSING. Reproduced: `task-5-brief.md` gives `OK 21 / DRIFT 0 / MISSING 15`, of which 12 are
import lines (`flutter/material.dart`, `flutter_test/flutter_test.dart`, `ko_lernen_app/theme.dart`,
`shared_preferences/...`, `../../services/sound_service.dart`). Briefs here routinely paste import
blocks, so this is the dominant false-positive class — larger than I1. Net effect: 4 of the 5 real
briefs I ran exit 1 purely on false positives.
Fix: skip a `PATH_RE` match whose preceding text ends in `package:` or `dart:` (optionally map
`ko_lernen_app/x.dart` -> `lib/x.dart`), and skip tokens starting with `../`.

### Minor

**M1 — `_owner` binds any backticked prose word after a path to that path**
`tool/check_brief_anchors.py:79-81`, `:108-118`. `hardening-3-brief.md:12` says
"(skip `.dart_tool`, `build`, `.git`)" on a line whose nearest preceding path is
`tts_bundled_manifest.dart:195-209`, so the tool prints `MISSING ... build not found`. Conversely an
identifier written before the first path on a line is silently dropped (`_owner` returns `None`).
Fix: bind in either direction, or require an identifier to look like code (`_`, `.`, or case change).

**M2 — the guard's `knownUnstubbedCap` assertion is tautological and never ratchets down**
`test/auto_speech_test_stub_guard_test.dart:112-116`, `:186`. It compares two constants declared 70
lines apart in the same file; the measured `unstubbed` list is never compared to the cap. If an
allowlisted file is fixed, renamed away or deleted, nothing fails and the list rots. Verified by an
independent re-implementation of the scan: 60 offenders, 60 entries, 0 new, 0 stale — latent.
Fix: `expect(unstubbed.length, lessThanOrEqualTo(knownUnstubbedCap))` plus an assertion that every
allowlist entry is still an offender, so fixing one forces list and cap down.

**M3 — the `speakImpl =` marker proves only half of what the docstring claims**
`test/auto_speech_test_stub_guard_test.dart:5-18` (docstring), `:88-90` (marker). The docstring
justifies the guard with the speak/prefetch in-flight-lock trap, but `speakImpl =` alone leaves
`prefetchImpl`/`stopImpl` on the real service (`lib/widgets/sori/speakable.dart:103,110`) and
`SoriSpeech.prefetch` locks `_inFlight[key]` the same way (`speakable.dart:312`). Three live files
pass on that marker with zero `prefetchImpl =`/`stopImpl =`:
`test/review_session_screen_speakable_test.dart`, `test/review_session_screen_test.dart`,
`test/scenario_player_ui_test.dart` (all green today).
Fix: no code change — narrow the docstring, or require `stubSoriSpeech(` for newly added files.

**M4 — `docs/ADR-002-audio-policy.md:5,392` still names the deleted `TtsService.speaking`**
ADR-002 is live (cited by `test/audio_policy_guard_test.dart:5`, `test/audio_policy_test.dart:8`,
`test/sound_channel_coverage_test.dart:7`) and still calls `TtsService.speaking` the ducking hook;
the real hook is `AudioPolicy.instance.noteSpeechStarted()/noteSpeechEnded()/restoreDuckNow()`
(`lib/services/tts_service.dart:640,659,770`). §6-6 also describes `test/tts_ducking_test.dart`,
which does not exist (pre-existing). Fix: one-line amendment to §5-2/§6-6.

**M5 — disk-tier poll budget has no headroom over the production timeout**
`test/tts_disk_tier_test.dart:74-81` polls 40 x 50 ms = 2 s while `_touchCacheFile` gives up at
`_diskTimeout = 2 s` (`lib/services/tts_service.dart:524`, used at `:990`). On a stalled runner both
expire together, so a slow `setLastModified` fails the test instead of being waited out.
Fix: raise the loop to ~100 iterations; cost is zero in the normal case (exits on iteration 1).

**M6 — ledger commit inconsistent and still pending**
`hardening-3-report.md` is tracked but landed mid-wave inside the code commit 6cb03aeb, while
`hardening-2-report.md` is untracked even though every other `*-report.md` in the directory is
committed; `progress.md` is still modified. Fix: include `hardening-2-report.md` (and this review)
in the final ledger commit with `progress.md`, and keep reports out of code commits.

**M7 — `.venv/` is not in the repo `.gitignore`**
`git check-ignore -v .venv` matches nothing in the repo's own rules; the 217 MB tree
(Pillow/numpy/scipy) is invisible only because `python -m venv` wrote `.venv/.gitignore` containing
`*`. A `virtualenv`/`conda` dir would be committable. Fix: add `.venv/` and `venv/` to `.gitignore`
and delete this worktree's `.venv` — the canonical interpreter is
`C:\Users\vjinn\OneDrive\Desktop\hangulsori\ko_lernen_app\.venv`.

**M8 — concurrent graphify run is dropping untracked artifacts into the worktree (observed live)**
`graphify-out/` is a **tracked** directory with no ignore rule (`git check-ignore graphify-out` -> no
match). During this review `git status` went from clean to 15 untracked
`graphify-out/cache/ast/v0.9.48-s2/*.json` files plus a modified `graphify-out/cache/stat-index.json`.
A `git add -A` for the final ledger commit would sweep all 16 into the PR.
Fix: commit the ledger with explicit paths (`git add .superpowers/... `), and add
`graphify-out/cache/` to `.gitignore`.

## Checked and clean

1. **Production risk — none.** Only `lib/` deltas are `setCacheDirForTesting`
   (`tts_service.dart:963`, `@visibleForTesting`, sole caller `tts_disk_tier_test.dart:26,30`) and
   the bool removal. Surviving statements in `speak()`/`whenComplete`/`stop()` keep their exact
   relative order; the ducking calls (`tts_service.dart:640,659,770`) are untouched and
   `audio_policy.dart` never read `speaking`. Dropping the
   `phase..addListener(_syncSpeakingFromPhase)` cascade is inert — it only wrote the deleted bool,
   nothing calls `hasListeners`/`dispose` on either notifier, and `_onEnginePhaseChanged` is bound
   separately (`speakable.dart:73-77`). `grep -rn "\.speaking\b" lib test tool functions` leaves
   only `TtsSpeechPhase`/`CurriculumLanguageDomain`/`SoriActivityColor*` hits; the rest is docs (M4).
2. **Linux CI robustness.** `resolved.path` is compared to a string built with the same
   interpolation as production (`tts_service.dart:857-859` vs test `:51`) — no separator dependency.
   `tearDown` (`:29-34`) runs on failure and `_touchCacheFile` swallows every error
   (`tts_service.dart:988-994`), so a late touch onto a deleted temp dir cannot raise. Real-manifest
   load under `flutter test` is already proven on CI by `test/tts_bundled_manifest_test.dart:20-28`,
   and `bundledAssetPath()` catches everything (`tts_bundled_manifest.dart:219-227`), so even a
   bundle failure degrades to the `isNull` the test asserts. Guard path normalisation
   (`auto_speech_test_stub_guard_test.dart:77-79`) is a no-op on Linux and handles subdirectories
   (`test/features/study_library/...`); my re-implementation of its scan reproduced exactly the 60
   allowlisted paths. A renamed-but-still-unstubbed file fails loudly under its new name; only the
   stale-entry direction is silent (M2).
3. **Guard design.** False negatives are acceptable for a string guard: a test reaching a target
   screen without naming its class (route/factory indirection) is skipped, and the marker is partial
   (M3). The regex over `content_audio_policy_guard_test.dart` fails loudly with a targeted reason if
   that list is reformatted (`:32-38`). Round-1 fixes are all in: marker, four brace sites,
   independent speak/speakSlow completers (`test/support/sori_speech_stubs.dart:40-53`), allowlist
   and cap untouched.
4. **Matrix test.** No row freezes accidental behaviour: `stops == 1` (rows 4/5) follows from the
   `previousKey == null` gate (`speakable.dart:199,216`); `identical(f1, f2)` (row 8) from the
   `_playbackFlights` join (`:138-140`); row 9 from `prefetch()` never assigning `phase`
   (`:278-314`). Crucially `resetForTesting()` also resets the engine notifier (`:127-128`), so rows
   4 and 7 — the only rows setting `TtsService.phase = speaking` without `markSpeechStarting()` —
   still produce a real value change and genuinely exercise the `_activeSpeechText == null` and
   text-identity guards (`:67-68`); without that reset both would be vacuous after row 6 leaves the
   engine at `speaking`. Non-blocking gaps: `speakSlow` (the new completer is still unexercised),
   the resolver-throws-to-idle path (`:231-236`), `stop()` while idle, and pending-prefetch
   promotion (`:144-150`). Pending speak futures left at row end are harmless (completers, no timers).
5. **CI YAML.** `tts-storage-verify`'s `if:` (`ci.yml:627-629`) is structurally identical to the
   `build` job's (`:212-214`). `push` to main and `workflow_dispatch` run whenever
   `content == 'true'`; draft PRs skip; `ready_for_review` is in the PR trigger types (`:28`) so
   promoting a draft re-runs the gate. `content` is still wired (`:693`) and no job declares
   `needs: tts-storage-verify`, so skipping cannot strand a dependent check.
6. **Python tool, apart from I1/I2/M1.** `_find`'s lookarounds correctly reject `cacheDir` in
   `_cacheDir` and `stop` in `stopImpl` (tests 9/10) and rightly avoid `\b` (Korean is a `re` word
   character). Exit codes match spec (ambiguous is DRIFT, exits 0). All I/O is `encoding="utf-8"`;
   the summary middle-dot survived a forced `PYTHONIOENCODING=cp949` run without raising. Path
   handling is `pathlib`-based. Fixtures use `TemporaryDirectory` context managers throughout
   (`tool/test_check_brief_anchors.py:38-51`), leave no residue and need no repo assets, so
   `python -m unittest discover -s tool` (`ci.yml:710`) picks the module up cleanly. 200 lines is
   not a maintainability problem — the density is three documented regexes.
7. **Process residue.** `git status --short` shows only the expected `progress.md` modification; no
   `zz_tmp_*` probe residue. All 9 commits carry the `Co-Authored-By: Claude Fable 5.1` trailer and
   the Codex/codex@local identity.
8. **Missed by the earlier reviews:** I1, I2, M1 (the D3 evaluation ran the tool only on
   `hardening-2-brief.md`, the one brief with neither an import block nor a repo-root citation);
   M2 (review 1 checked allowlist fidelity but not the cap's ratchet semantics); M3-M7.

## Residual risks for Jin's device check

- **Ducking on real hardware.** The `speaking` bool is gone while ADR-002 §5-2 still calls it the
  ducking hook. Only a device proves ambience/BGM still ducks x0.25 and restores on sentence end and
  on mid-sentence interruption — there is no test for the `AudioPolicy` ducking path at all.
- **Indicator states end to end.** The matrix pins the machine with stubbed hooks; only a device
  shows whether hourglass-to-equaliser tracks audible playback start (engine latency, cold first
  utterance, headphone/Bluetooth route changes).
- **Disk-cache mtime in a real app sandbox.** `setLastModified` is exercised on a desktop temp dir;
  on-device filesystems may ignore or coarsen mtime, degrading the LRU prune to arbitrary eviction.
- **CI draft exclusion.** Not provable by reading YAML — check the first draft PR touching `content`
  for "TTS Storage completeness" being skipped, then re-check after "Ready for review".
