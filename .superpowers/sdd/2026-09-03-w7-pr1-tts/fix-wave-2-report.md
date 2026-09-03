# W7 PR1 — Fix Wave 2 Report

- Worktree: `C:\dev\hangulsori\ko_lernen_app_worktrees\w7-pr1-tts-20260903`
- Branch: `claude/w7-pr1-tts-20260903`
- Base: `b8ca30c6` (chore(graphify): W7 PR1 TTS·오디오 그래프 갱신)
- Date: 2026-09-03
- Source: Fable direct read of the core diffs (post final-fix-wave), rulings recorded at the end of `progress.md`.

All items below were implemented TDD-where-behavior-changed, each in its own commit.

## F1 (Important) — engine phase same-value reassignment suppressed the resolving→speaking promotion for a second utterance

`lib/services/tts_service.dart`: while utterance A is playing, `TtsService.phase.value == speaking`. A following `SoriSpeech.speak(B)` sets `SoriSpeech.phase = resolving` and calls `TtsService.speak(B)`; the engine's `onPlaybackStarted` callback (`tts_service.dart` construction of `_playbackEngine`, `onPlaybackStarted: (text, voice) { activeSpeechText = text; phase.value = TtsSpeechPhase.speaking; }`) then reassigns `phase.value = speaking` — the *same* value `ValueNotifier` already holds — so `notifyListeners()` never runs and `SoriSpeech._onEnginePhaseChanged` (`lib/widgets/sori/speakable.dart:71-77`, bound as a listener on `TtsService.phase`) never fires. `SoriSpeech.phase` for B stays stuck on `resolving` (hourglass icon) for the whole playback of B.

Fix: added `TtsService.markSpeechStarting()` (`tts_service.dart`, new static method right before `_speakToken`) —

```dart
static void markSpeechStarting() {
  phase.value = TtsSpeechPhase.resolving;
  activeSpeechText = null;
}
```

— and call it from the static `TtsService.speak()` entry point immediately after `final token = ++_speakToken;` (`tts_service.dart`, in `speak()`), before `speaking.value = true` and before handing off to `_playbackEngine.speak(...)`. This guarantees `phase` makes a *real* transition (something→resolving) on every call to `speak()`, so the later engine-driven resolving→speaking transition is always a real value change that notifies listeners.

`speakSlow()` (`tts_service.dart`) is a thin wrapper that calls `speak(text, voice: voice, rateMultiplier: 0.65)` — it funnels through the same entry point, so no separate call site was needed.

### Tests

(a) `test/tts_premium_only_test.dart` — `'markSpeechStarting() 은 phase를 resolving으로 되돌리고 activeSpeechText를 지운다 (F1)'`: sets `TtsService.phase.value = speaking` and `TtsService.activeSpeechText = '학교'`, calls `TtsService.markSpeechStarting()`, asserts `phase.value == resolving` and `activeSpeechText == null`.

(b) `test/speakable_semantics_test.dart` — two tests, RED then GREEN, same test body evolved in place:

- **RED** (commit `915ee1cb`): `'연속 발화 — B가 시작해도 엔진 phase가 이미 speaking이면 같은 값 재대입이라 리스너가 안 불려 B의 승격 신호를 놓친다 (F1)'`. Mocks `SoriSpeech.speakImpl` with per-call `Completer`s and `SoriSpeech.stopImpl` to a no-op (so the real `TtsService.stop()` — which `_publishSpeak` calls when switching speech keys — doesn't itself reset `TtsService.phase` to idle and mask the bug). Drives: `SoriSpeech.speak('A')` → manually set `TtsService.activeSpeechText='A'; TtsService.phase.value=speaking` (asserts `SoriSpeech.phase==speaking`) → `SoriSpeech.speak('B')` (asserts `SoriSpeech.phase==resolving`) → manually set `TtsService.activeSpeechText='B'; TtsService.phase.value=speaking` again (today's engine behavior — no reset in between) → asserted `SoriSpeech.phase==speaking`. Ran before any production change: **failed** — `Expected: speaking, Actual: resolving`, reproducing the bug exactly.
- **GREEN** (commit `607a1834`): same test, renamed to `'연속 발화 — TtsService.markSpeechStarting()이 매 발화마다 phase를 resolving으로 되돌려, 같은 값 재대입으로 승격 신호가 씹히지 않는다 (F1)'`, with `TtsService.markSpeechStarting();` inserted immediately before each `TtsService.activeSpeechText = ...; TtsService.phase.value = speaking;` pair (simulating what the fixed `TtsService.speak()` now does before invoking the engine). Passed.

Frozen: `test/content_audio_policy_guard_test.dart` untouched, ran green throughout; `_generation` not renamed; `ContentSpeechController` docstring untouched.

Commits: `915ee1cb` (RED test), `607a1834` (fix + GREEN test + test (a)).

## F2 (Minor) — cache-hit mtime touch blocked playback start

`lib/services/tts_service.dart` `_resolveAudio`, local-cache disk-hit branch (was ~L852): `await _touchCacheFile(file);` → `unawaited(_touchCacheFile(file));`. `dart:async` was already imported (line 1), so no import change needed. The touch is a best-effort mtime bump feeding the LRU prune heuristic (§9-4) — its own failures are already swallowed inside `_touchCacheFile`, so there was no reason to make every cache hit wait (bounded by `_diskTimeout`, up to 2s) for a disk write before starting playback.

No behavior test needed beyond the existing `test/tts_cache_prune_test.dart` coverage of `_touchCacheFile` itself (via `touchCacheFileForTesting`), which calls the helper directly and is unaffected by how its caller awaits it — ran green.

Commit: `b78951a4`.

## F3 (Minor) — split doc comments repaired

`lib/services/tts_service.dart`: the full-scan-cost premise sentence (`/// 매 쓰기마다 전체 스캔하면 캐시가 커질수록 재생 지연에 영향을 준다 —`) had drifted onto `_touchCacheFile`'s doc comment, where it doesn't apply (that function only bumps one file's mtime — it never scans). The sentence actually describes `_maybePruneCache`, the function that scans the whole cache directory and exists specifically to throttle that cost (16-writes/5-min gate, §9 룰링 4). Moved the sentence back to the start of `_maybePruneCache`'s doc, ahead of the existing "쓰기 16회 또는 마지막 prune 후 5분..." sentence; `_touchCacheFile`'s doc now describes only the mtime touch.

Docs-only change, no test.

Commit: `ca616501`.

## F4 (Minor) — `--verify-storage` printed one STALE line per stale object even without `--delete-stale`

`tool/generate_tts.py`, `--verify-storage` branch (~L1533-1539): `for path in unexpected: print(f"STALE\t{path}")` ran unconditionally. A bare `--verify-storage` run (the CI completeness gate, `.github/workflows/ci.yml` job `tts-storage-verify`) already has thousands of already-stale objects from prior voice migrations, so this turned a routine gate run into thousands of lines of CI log noise even though the one-line `Storage verify — expected N, remote N, missing N, stale N` summary already carries the count. Gated the per-path listing on `args.delete_stale`, so it now only appears as a dry-run preview of what `--delete-stale` would remove (the destructive `--confirm-delete` path is unaffected — still requires `--delete-stale` and only executes on its own separate `if`).

### Tests (`tool/test_generate_tts.py`)

- Added `test_verify_storage_without_delete_stale_does_not_list_stale_paths`: bare `--verify-storage` with one expected object and one stale object present in `remote_cache_objects` — asserts zero `STALE\t`-prefixed `print()` calls, and asserts the summary line reads exactly `Storage verify — expected 1, remote 2, missing 0, stale 1`.
- `test_verify_storage_lists_stale_paths_without_deleting` (frozen, unchanged) already invoked `generate_tts.main(["--verify-storage", "--delete-stale"])` — no `--confirm-delete` — so it continues to exercise and pass the dry-run listing path unmodified.

Full `tool.test_generate_tts` module: 36/36 passed (`python -X utf8 -m unittest tool.test_generate_tts -v`, run via the project venv).

Commit: `e72ff572`.

## F5 (Minor) — CI job requested a pip cache with nothing to key it on

`.github/workflows/ci.yml`, job `tts-storage-verify`, step "Set up Python" (`actions/setup-python@v5`): removed `cache: pip`. That job never runs `pip install` — `tool/generate_tts.py --verify-storage` only needs the stdlib plus the `gcloud` CLI already set up by the preceding step — so there is no `requirements*.txt`/`pyproject.toml` for `cache: pip` to hash, and the option fails the step outright when it can't find one to key the cache on.

Validated by parsing: `yaml.safe_load` (PyYAML, via system `python -X utf8` — the project venv lacks PyYAML) on the whole `ci.yml` succeeded (13 jobs parsed), and the `tts-storage-verify` job's "Set up Python" step's `with:` now shows only `{'python-version': '3.12'}`. `.github/scripts/test_ci_scope.py` (14/14) also passed — it doesn't reference this job's config, but was run as a sanity check per the task's "python suites" instruction.

Commit: `48c4bf35`.

## Verification run (after all five fixes)

- `flutter test --no-pub test/tts_premium_only_test.dart test/speakable_semantics_test.dart test/sori_speech_dedupe_test.dart test/speakable_screen_lifecycle_test.dart test/content_audio_policy_guard_test.dart test/tts_cache_prune_test.dart --reporter expanded` → 50/50 passed.
- `python -X utf8 -m unittest tool.test_generate_tts -v` → 36/36 passed.
- `.github/scripts/test_ci_scope.py` → 14/14 passed.
- `flutter analyze --no-pub` (foreground) → No issues found! (101.2s).
- `flutter test --no-pub --reporter failures-only` (foreground, full suite) → 5505 passed, 0 failed, 14 skipped.
- `graphify update .` → ran clean, `graphify-out/` committed separately (`ab24b349`).

Commits, in order: `915ee1cb` (F1 RED) → `607a1834` (F1 fix/GREEN) → `b78951a4` (F2) → `ca616501` (F3) → `e72ff572` (F4) → `48c4bf35` (F5) → `ab24b349` (graphify).
