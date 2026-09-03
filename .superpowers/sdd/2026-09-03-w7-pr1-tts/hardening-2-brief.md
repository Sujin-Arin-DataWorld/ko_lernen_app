# HARDENING DISPATCH 2 — B (phase transition matrix test) + C (remove zero-consumer `speaking` bools)

Branch `claude/w7-pr1-tts-20260903`, worktree `C:\dev\hangulsori\ko_lernen_app_worktrees\w7-pr1-tts-20260903`.
BASE = the HEAD you find when you start (record it in your report). Plan: `docs/superpowers/plans/2026-09-03-w7-pr1-tts.md`. Ledger dir: `.superpowers/sdd/2026-09-03-w7-pr1-tts/`.

Standing rules (§4 template): TDD with RED log before GREEN; **frozen assertions are never bent to fit the implementation — if a table row cannot pass without changing production behaviour, STOP and report (R2)**; no ratchet/allowlist raise (R3); no files outside FILES (R1); no hardcoded user strings; braces on every if/else; PowerShell syntax, no `&&`; `flutter analyze --no-pub` 0; commit with trailer `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`, identity Codex/codex@local.

Order: do **C first** (it shrinks the surface B must pin), then B.

---

## C — remove the two zero-consumer `speaking` bools

GOAL: delete `TtsService.speaking` and `SoriSpeech.speaking` (`ValueNotifier<bool>`), which have **0 readers** in lib/ and test/ (verified 2026-09-03 by grep: only the definitions, their writes, and one doc comment). `phase` is the single source of truth.

FILES:
- `lib/services/tts_service.dart` — definition L600-601 (`/// 발화 중 여부 — [AudioPolicy] 더킹·UI 표시용 (ADR-002 §5-2).` + `static final ValueNotifier<bool> speaking = ...`), writes at L641 (`speaking.value = true;` in `speak()`), L659 (`speaking.value = false;` in whenComplete), L769 (`speaking.value = false;` in `stop()`), and the docstring at L543 that says `[speaking](레거시 bool)과 별개인 3단 재생 상태` — rewrite that sentence so it no longer references a removed member (doc references to a nonexistent identifier are an analyzer diagnostic under `comment_references`).
- `lib/widgets/sori/speakable.dart` — L48-49 (`/// 화면이 구독하는 발화 상태(레거시 호환) — phase에서 파생된다.` + `static final ValueNotifier<bool> speaking`), the cascade `..addListener(_syncSpeakingFromPhase)` on `phase` (L54-56) and `_syncSpeakingFromPhase` (L58-60) — remove all three; `phase` becomes a plain `ValueNotifier<TtsSpeechPhase>(TtsSpeechPhase.idle)`. Docstring near L490 mentions "전역 `speaking`" — reword to `phase` but **keep the literal `TtsService.stop()` in that docstring** (guard contract below).
- `test/review_session_screen_speakable_test.dart:18` — doc comment mentions `TtsService.speaking` 플래그; reword to `TtsService.phase` (comment only, no assertion change).

INTERFACE: no new API. `TtsService.phase`, `TtsService.activeSpeechText`, `TtsService.markSpeechStarting()`, `SoriSpeech.phase` unchanged.

DO NOT: touch `AudioPolicy.noteSpeechStarted()/noteSpeechEnded()/restoreDuckNow()` calls (they are the ducking path, not the bool); rename `_generation`/`_speakToken`; change `phase` transitions; remove any test.

FROZEN CONTRACTS: `test/content_audio_policy_guard_test.dart` greps `lib/widgets/sori/speakable.dart` for literals (`TtsService.stop()`, `didPushNext`, regex `int\s+_generation`) — must stay GREEN unmodified. `test/tts_premium_only_test.dart`, `test/speakable_semantics_test.dart`, `test/speakable_screen_lifecycle_test.dart`, `test/sori_speech_dedupe_test.dart` GREEN unmodified.

TDD for C (removal task — the RED is the analyzer): 1) grep `-rn "\.speaking\b" lib test` and paste the output in the report (expected: only `TtsSpeechPhase.speaking` and `CurriculumLanguageDomain.speaking` remain after removal) 2) remove 3) `flutter analyze --no-pub` 0 4) run the four frozen test files + the guard.

DONE (C): both members gone, analyze 0, the 5 test files GREEN with counts, `git diff --stat` ≤ 4 files.

---

## B — table-driven phase transition matrix test

GOAL: one new test file `test/sori_speech_phase_matrix_test.dart` that pins the **current** `SoriSpeech.phase` state machine as a table (one row per transition), recording every `SoriSpeech.phase` change through a listener into a `List<TtsSpeechPhase>` and asserting the exact sequence per row. This is a pinning test — production code must not change. Ruling: **voice is NOT part of the promotion identity** (SoriSpeech passes `'auto'` while the engine normalises to a concrete voice); text identity stays.

FILES: new `test/sori_speech_phase_matrix_test.dart` only.

HOW THE MACHINE WORKS (read the code, do not trust this summary blindly — `lib/widgets/sori/speakable.dart` L60-90, L200-260, L340-360; `lib/services/tts_service.dart` L543-560, L603-618, L636-665, L760-775):
- `SoriSpeech.speak(text)` sets `_activeSpeechText = text.trim()` and `phase = resolving` **synchronously before its first await** (then `await stopImpl()` then `speakImpl(...)`). So `stub.spoken` fills only after a microtask turn — use `await pumpEventQueue()` (flutter_test) before asserting on `stub.spoken`.
- Promotion resolving→speaking happens only in `SoriSpeech._onEnginePhaseChanged` when `TtsService.phase.value == speaking` **and** `TtsService.activeSpeechText == _activeSpeechText` **and** the generation snapshot matches. In tests the engine is simulated exactly as `test/speakable_semantics_test.dart:159-160,193-203` does: `TtsService.markSpeechStarting(); TtsService.activeSpeechText = 'A'; TtsService.phase.value = TtsSpeechPhase.speaking;`.
- The speak future's `whenComplete` resets to idle only if the generation is still current. `SoriSpeech.stop()` bumps the generation, sets idle, calls `stopImpl`.
- Use `stubSoriSpeech(completeSpeak: false)` from `test/support/sori_speech_stubs.dart` to hold the speak future pending (`stub.speakCompleter`). Its completer is **shared** between calls; for rows that need A and B pending independently, override `SoriSpeech.speakImpl` after `stubSoriSpeech()` with your own per-call completer map (allowed — the helper is a default, and `addTearDown(SoriSpeech.resetForTesting)` is already registered by it).

THE TABLE (each row = one `test()` generated from a `const`/final list of case records; name each row exactly as below):
1. `idle → speak(A) → resolving` — sequence `[resolving]`; `stub.spoken == ['A']` after pumpEventQueue.
2. `resolving(A) → engine starts A → speaking` — `[resolving, speaking]`.
3. `speaking(A) → speak future completes → idle` — complete the completer with true → `[resolving, speaking, idle]`.
4. `resolving(A) → stop() → idle; late engine signal for A does not promote` — `[resolving, idle]`, then simulate engine start for A → sequence unchanged (still ends in idle), `stub.stops` as the code dictates (see row 5 note).
5. `speaking(A) → stop() → idle` — `[resolving, speaking, idle]`. (Careful: `SoriSpeech.speak` itself calls `stopImpl()` once before `speakImpl` — read `_startSpeak` and count accordingly; put the exact expected `stops` in the row from what the code does, and explain the number in a comment.)
6. `speaking(A) → speak(B) → resolving → engine starts B → speaking` — `[resolving, speaking, resolving, speaking]` (this is the F1 same-value-suppression regression from PR1; the `markSpeechStarting()` simulation step is what makes the last promotion a real value change).
7. `resolving(A) → unrelated engine start (text Z) → stays resolving` — `[resolving]`.
8. `resolving(A) → speak(A) again while pending → dedupe, still resolving, speakImpl once` — `[resolving]`, `stub.spoken == ['A']`.
9. `idle → prefetch(A) → stays idle` — `[]`, `stub.prefetched == ['A']`.
10. `resolving(A) → stop() → speak(A) again → resolving with a fresh generation; engine start for A promotes` — `[resolving, idle, resolving, speaking]`.

Implementation notes: record the sequence with `SoriSpeech.phase.addListener(() => seen.add(SoriSpeech.phase.value))` registered **after** `stubSoriSpeech()` (which resets phase to idle) and removed in `addTearDown`. Rows are plain `test()` (no widget pumping). If any row's observed sequence differs from the table, do **not** edit the table to match — stop, keep the RED log, and report the observed sequence with the code line that produces it (R2). RED evidence for a pinning test = the first honest run; if all 10 rows pass on that first run, say so explicitly and attach the log (GREEN-first is acceptable for pinning tests only when the report states it).

DO NOT: modify `lib/`; modify existing tests; add `voice` to any identity check; use `Future.delayed` with real time (use `pumpEventQueue()`/completers).

FROZEN CONTRACTS: same five test files as C; `test/auto_speech_test_stub_guard_test.dart` GREEN (your new file does not pump widgets, so it is out of that guard's scope — confirm by running it).

DONE (B): `flutter test --no-pub test/sori_speech_phase_matrix_test.dart` → 10 passed; analyze 0; `git diff --check` clean.

---

REPORT (write to `.superpowers/sdd/2026-09-03-w7-pr1-tts/hardening-2-report.md` and return it): BASE/HEAD SHAs · files + diffstat · C grep output before/after · RED evidence (or the explicit "GREEN-first pinning" statement) · GREEN logs with counts for: matrix test, the five frozen files, `content_audio_policy_guard_test`, `auto_speech_test_stub_guard_test` · analyze output · unexpected guard failures (separate section, even if none) · ≤3 open questions. Run tests in the foreground (do not wait on background notifications).
