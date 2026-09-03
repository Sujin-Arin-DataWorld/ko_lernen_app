# Hardening dispatch 2 review — 4f3227e4..47685843

## Verdict: APPROVE

## Findings

**[Minor] Combined multi-file `flutter test` invocation silently drops/merges duplicate-named tests**
File: n/a (test-runner behavior, Flutter 3.44.8 stable / Dart 3.12.2)
Issue: `flutter test --no-pub <file1> ... <file6>` (checklist item 6 exact command) produces a misleading summary — running all 6 target files together reports "45 passed," but `sori_speech_dedupe_test.dart` 7 tests never appear by name at all (`grep -c "sori_speech_dedupe" <log>` = 0), while `speakable_screen_lifecycle_test.dart` repeated-description test ("화면 dispose 뒤 발화 완료는...") prints 11 duplicate lines instead of its real 1 occurrence. Each file run alone gives a self-consistent, correct count.
Why: not a defect introduced by this dispatch — reproduces on a file pair (dedupe + lifecycle) untouched by this diff. Means checklist item 6 combined command cannot be trusted for pass/fail counts on this SDK.
Fix: none needed for merge; run target files individually (counts below) rather than trusting the combined invocation summary line.

**[Minor] Row 1 "fills only after a microtask turn" framing does not hold for row 1 itself**
File: test/sori_speech_phase_matrix_test.dart:405-410 (the brief own "HOW THE MACHINE WORKS" section makes the same general claim)
Issue: in row 1, `previousKey` is `null` (first call after `resetForTesting()`), so `resolve()` skips the `await stopImpl()` branch (speakable.dart:216) and reaches `return await resolver(text, voice);` (speakable.dart:230) as its first suspension point. The closure call `resolver(text, voice)` is evaluated eagerly before `await` suspends, so `stub.spoken.add('A')` (sori_speech_stubs.dart:46) runs **synchronously** inside the call to `SoriSpeech.speak('A')` — not after a microtask turn.
Why: harmless — `await pumpEventQueue()` (test:408) is a safe no-op wait here, so the assertion still passes. Flagging only because the checklist explicitly asked whether `pumpEventQueue()` is sufficient, and the precise answer is: sufficient but unnecessary for row 1; the general framing is imprecise for this specific row (no key-switch means no stopImpl gate).
Fix: none required; optional one-line comment on row 1 noting the synchronous call would make the file self-documenting.

No Critical or Important issues found. Fix round 1 closure items (marker, braces, completer split, allowlist/cap) all verified correct — see Checklist table. C removal is complete and scoped exactly to the two dead bools plus their doc comments; `AudioPolicy.instance.noteSpeechStarted()/noteSpeechEnded()/restoreDuckNow()` call sites (tts_service.dart:640,659,770) are untouched — no behavior change beyond deleting the bool writes.

## Row-by-row trace

1. OK — speakable.dart:135-153 (speak to _startSpeak to _publishSpeak), :213 (phase=resolving sync), :199/:216 (previousKey==null on first call means no stopImpl gate) so `resolver(text,voice)` runs synchronously inside the `await` expression; stub.spoken filled before `SoriSpeech.speak('A')` returns.
2. OK — speakable.dart:65-71 (`_onEnginePhaseChanged` text+generation match) plus tts_service.dart:613-616 (`markSpeechStarting` resets phase to resolving, activeSpeechText=null), then test sets activeSpeechText='A', phase=speaking so promotion fires. Mirrors speakable_semantics_test.dart:152-166.
3. OK — speakable.dart:239-252 whenComplete: generation still current plus `_activeSpeechKey==key` sets phase to idle on `completer.complete(true)`.
4. OK — speakable.dart:199/:216 previousKey==null means `resolve()` never calls stopImpl; `stop()` (speakable.dart:342-356) unconditionally awaits stopImpl once giving `stub.stops==1`; `stop()` nulls `_activeSpeechText` (:346) so the late engine signal is filtered at the `_activeSpeechText == null return` guard (:67) before any generation check.
5. OK — same previousKey==null reasoning as row 4 (`stub.stops==1` from the explicit `stop()` alone); sequence resolving to speaking to idle per :213/:70/:350.
6. OK — reproduces the F1 fix directly: tts_service.dart:613-616 forces a real resolving to speaking value change on each speak call, so `ValueNotifier` same-value suppression does not swallow B promotion. Mirrors speakable_semantics_test.dart:168-218.
7. OK — speakable.dart:68 text-identity guard (`TtsService.activeSpeechText != _activeSpeechText`) filters the unrelated Z signal. Mirrors speakable_semantics_test.dart:125-150.
8. OK — speakable.dart:138-140 in-flight plus `_playbackFlights` dedupe returns the identical future without re-entering `_publishSpeak`, so speakImpl (and phase=resolving) fires exactly once; `identical(f1,f2)` holds.
9. OK — `prefetch()` (speakable.dart:278-314) never assigns `SoriSpeech.phase` anywhere in its body; `seen` correctly stays empty.
10. OK — `stop()` clears key/text/generation (speakable.dart:342-350); second `speak('A')` is a fresh `_publishSpeak` (previousKey null again, row makes no `stops` assertion); matching engine signal promotes on the new generation.

## Mutation check output

Guard FAILS with the reset-only probe (test/zz_tmp_reset_only_probe_test.dart, calls only SoriSpeech.resetForTesting(), no speakImpl assignment or stubSoriSpeech(), pumps ChosungQuizScreen):
```
00:00 +0 -1: 자동 발화 화면을 pumpWidget하는 테스트는 SoriSpeech를 스텁한다 [E]
  Expected: empty
    Actual: [test/zz_tmp_reset_only_probe_test.dart]
  SoriSpeech를 스텁하지 않고 자동 발화 화면을 pumpWidget하는 신규 테스트 파일: test/zz_tmp_reset_only_probe_test.dart — ...
00:00 +0 -1: Some tests failed.
```
Guard GREEN after probe deleted:
```
00:00 +0: 자동 발화 화면을 pumpWidget하는 테스트는 SoriSpeech를 스텁한다
00:00 +1: All tests passed!
```
git status --short after deletion shows only the pre-existing progress.md modification — no zz_tmp_* residue.

## Checklist table (1-6)

| # | Item | Status | Evidence |
|---|------|--------|----------|
| 1a | Marker tightened, mutation check | OK | Reset-only probe fails naming itself; green after deletion (above) |
| 1b | Four brace sites | OK | grep for brace-less if in both test files returns 0 matches; all 4 sites now use braces |
| 1c | speakSlow completer independent | OK | sori_speech_stubs.dart:40-53 — pendingSpeakCompleter/pendingSpeakSlowCompleter are distinct Completer<bool>() instances; each hook (speakImpl/speakSlowImpl) only awaits its own completer future |
| 1d | Allowlist/cap unchanged | OK | git diff 4f3227e4..47685843 for test/auto_speech_test_stub_guard_test.dart shows no knownUnstubbed array lines touched (28 ins/12 del, all in the marker-logic function); list has exactly 60 entries, knownUnstubbedCap = 60 unchanged |
| 2 | C removal completeness | OK | grep -rn for the speaking property in lib and test shows only TtsSpeechPhase.speaking, CurriculumLanguageDomain.speaking, and the unrelated SoriActivityColorRole/SoriActivityColors.speaking (a color-role enum untouched by this dispatch) remain; no lib or test doc comment still references the removed identifiers (only historical docs/ADR-002, docs/HANDOFF, and this dispatch own plan doc do — out of scope, non-Dart-comment, no analyzer impact); speakable.dart still has TtsService.stop() (lines 482,484), didPushNext (line 533), int _generation (line 498); content_audio_policy_guard_test.dart 8/8 green; AudioPolicy.instance.* call sites unchanged (tts_service.dart:640,659,770) |
| 3 | Matrix test row-by-row | OK | See Row-by-row trace — all 10 rows follow from the code as written; no leaked Timers (Completers only, not Timer-based) and resetForTesting() (speakable.dart:114-133) clears in-flight maps and bumps generation before the next row runs, so a still-pending prior-row Future whenComplete callback (if it ever fired) would fail the generation check anyway |
| 4 | Test quality | INFO | Not tautological. Rows 2, 6, 7 intentionally overlap speakable_semantics_test.dart:125-218 (the brief itself cites these as the origin pattern — acceptable, noted here explicitly). Non-blocking coverage suggestions: no row exercises speakSlow() phase transitions (the new speakSlowCompleter split is unexercised by this file — still latent per hardening-1 original Minor); no row exercises stop() when idle; no row exercises the failed-resolution-to-idle path in this table (covered elsewhere, e.g. speakable_screen_lifecycle_test.dart failure test) |
| 5 | Analyzer | OK | flutter analyze --no-pub reports No issues found! (0 issues, 18.9s); no discarded_futures/unawaited_futures lints configured in analysis_options.yaml, so none to report |
| 6 | Targeted test run | OK (see note) | Combined 6-file command is unreliable on this SDK (see Minor finding). Individual counts, all green: sori_speech_phase_matrix_test.dart 10/10, auto_speech_test_stub_guard_test.dart 1/1, tts_premium_only_test.dart 12/12, speakable_semantics_test.dart 7/7, speakable_screen_lifecycle_test.dart 8/8, sori_speech_dedupe_test.dart 7/7 |

## Summary

| Severity | Count | Status |
|----------|-------|--------|
| Critical | 0 | pass |
| Important | 0 | pass |
| Minor | 2 | note |

Verdict: APPROVE — fix round 1 is fully closed (marker, braces, completer split, allowlist/cap all verified), C removal is complete and correctly scoped, and all 10 matrix rows trace cleanly against the current production code. The two Minor notes (combined-invocation test-runner quirk; a slightly imprecise microtask-turn framing for row 1) are informational and do not block merge.
