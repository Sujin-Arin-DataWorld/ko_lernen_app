# Hardening dispatch 2 report — B (phase matrix) + C (remove `speaking` bools), plus dispatch-1 fix round

BASE = `4f3227e479ad3be949544689b2b76aece505c8fc` (fix(test): drop void_checks lint from stubSoriSpeech's prefetchImpl)
HEAD = `47685843` (test(tts): table-driven SoriSpeech phase transition matrix (10 rows))

Commits (in order):
1. `a6ae93f8` — `fix(test): tighten auto-speech stub guard marker, braces, separate speakSlow completer` (Step 0)
2. `173aff94` — `refactor(tts): remove zero-consumer TtsService.speaking / SoriSpeech.speaking bools (phase is the single source)` (Step 1 / brief section C)
3. `47685843` — `test(tts): table-driven SoriSpeech phase transition matrix (10 rows)` (Step 2 / brief section B)

No pushes were made. `.superpowers/sdd/2026-09-03-w7-pr1-tts/progress.md` had a pre-existing uncommitted modification when this session started (Fable's ledger entry describing the hardening wave) — it was left untouched and is not part of any commit above.

---

## Step 0 — dispatch-1 fix round (review verdict FIX-REQUIRED)

Findings addressed, from `.superpowers/sdd/2026-09-03-w7-pr1-tts/hardening-1-review.md`:

- **F1 (Important)** `test/auto_speech_test_stub_guard_test.dart` — `isStubbed` now requires `stubSoriSpeech(` **or** `speakImpl =` (a manual stub assignment). `SoriSpeech.resetForTesting(` alone no longer counts as evidence — it restores the *real* `TtsService.*` delegates (`speakable.dart:129-132`), which is exactly the T3 trap the guard exists to prevent. Verified `'speakSlowImpl ='.contains('speakImpl =')` is `false` (the substring "speak" is followed by "Slow" not "Impl"), so the new marker does not accidentally accept a speakSlow-only stub as evidence. Doc comment (module-level + inline scan comment) and the `newOffenders` failure `reason` text were reworded to match.
- **F2 (Important, R5)** four brace-less `if` bodies (`continue;` ×3, `unstubbed.add(...)` ×1) wrapped in `{ }`.
- **F3 (Minor)** `test/support/sori_speech_stubs.dart` — `speak`/`speakSlow` now use independent completers (`speakCompleter` / new `speakSlowCompleter` field) when `completeSpeak: false`, instead of sharing one `Completer`. No behavior change for the default `completeSpeak: true` path (both still return `Future.value(true)`).

**0-live-offenders check** (per review's instruction to confirm before merging): `grep -rl "SoriSpeech.resetForTesting(" test` → 8 files; all 8 also contain `stubSoriSpeech(` or `speakImpl =`, so the tightened marker adds **zero** new offenders. The guard test itself (which re-derives `newOffenders` at runtime against the same 60-entry allowlist) confirms this by passing.

**Verification:**
- `flutter test --no-pub test/auto_speech_test_stub_guard_test.dart test/chosung_quiz_audio_test.dart test/vocab_notebook_audio_test.dart test/vocab_pack_screen_prefetch_test.dart test/tts_disk_tier_test.dart` → **10 passed, 0 failed** (guard 1, chosung 2, vocab_notebook 2, vocab_pack_prefetch 4, disk_tier 1).
- `flutter analyze --no-pub` → **No issues found.**
- `git status --short` after the change → only `test/auto_speech_test_stub_guard_test.dart` and `test/support/sori_speech_stubs.dart` modified (plus the pre-existing `progress.md`); no `zz_tmp_*` files anywhere under `test/` (the reviewer's probe file was already cleaned up before this session started).

---

## Step 1 — brief section C: remove zero-consumer `speaking` bools

Removed `TtsService.speaking` (`ValueNotifier<bool>`, `lib/services/tts_service.dart`) and `SoriSpeech.speaking` (`lib/widgets/sori/speakable.dart`) — both had 0 readers in `lib/`/`test/`, confirmed before and after:

**Before** (`grep -rn "\.speaking\b" lib test`, excerpt of the removed-member hits):
```
lib/services/tts_service.dart:601:  static final ValueNotifier<bool> speaking = ValueNotifier<bool>(false);
lib/services/tts_service.dart:640:    speaking.value = true;
lib/services/tts_service.dart:658:        speaking.value = false;
lib/services/tts_service.dart:766:    speaking.value = false;
lib/widgets/sori/speakable.dart:49:  static final ValueNotifier<bool> speaking = ValueNotifier<bool>(false);
lib/widgets/sori/speakable.dart:56:        ..addListener(_syncSpeakingFromPhase);
lib/widgets/sori/speakable.dart:59:    speaking.value = phase.value == TtsSpeechPhase.speaking;
test/review_session_screen_speakable_test.dart:18:/// 진입 + 카드 전환(Skip) 자동재생은 `TtsService.speaking` 플래그가 아니라
```
(plus unrelated hits: `TtsSpeechPhase.speaking`, `CurriculumLanguageDomain.speaking`, `SoriActivityColor(s|Role).speaking` across `lib/data/*`, `lib/screens/*`, `lib/widgets/sori/activity_illustration.dart` — none of these reference the removed bools.)

**After** (`grep -rn "\.speaking\b" lib test`): only `TtsSpeechPhase.speaking` (enum member, in `tts_service.dart`, `speakable.dart`, `speakable_semantics_test.dart`, `speakable_screen_lifecycle_test.dart`, `tts_premium_only_test.dart`) and `CurriculumLanguageDomain.speaking` / `SoriActivityColor(s|Role).speaking` (unrelated domains) remain. `grep -rn "TtsService\.speaking\b\|SoriSpeech\.speaking\b" lib test` → **0 matches**.

**Files changed** (`git diff --stat`, 3 files as required — ≤4):
```
 lib/services/tts_service.dart                  | 10 +++-------
 lib/widgets/sori/speakable.dart                | 18 ++++++------------
 test/review_session_screen_speakable_test.dart | 11 ++++++-----
 3 files changed, 15 insertions(+), 24 deletions(-)
```

Detail:
- `tts_service.dart`: removed the `speaking` field + its doc comment; removed the 3 writes (`speak()` start, `speak()`'s `whenComplete`, `stop()`); reworded the `phase` doc comment (was: "[speaking](레거시 bool)과 별개인 3단 재생 상태") so it no longer references a removed identifier (avoids a `comment_references` analyzer hit).
- `speakable.dart`: removed the `speaking` field, the `..addListener(_syncSpeakingFromPhase)` cascade, and `_syncSpeakingFromPhase()`; `phase` is now a plain `ValueNotifier<TtsSpeechPhase>`. Reworded the `ContentSpeechController` docstring ("전역 `speaking` ValueNotifier" → "전역 `phase` ValueNotifier") while keeping the literal `TtsService.stop()` mentions intact (guard contract).
- `review_session_screen_speakable_test.dart:18`: doc-comment-only reword (`TtsService.speaking` → `TtsService.phase`), no assertion touched.

**DO NOT list respected:** `AudioPolicy.noteSpeechStarted()/noteSpeechEnded()/restoreDuckNow()` call sites untouched; `_generation`/`_speakToken` untouched; no `phase` transition logic changed; no test assertions removed or altered (only 1 doc comment).

**Verification (frozen contracts, run together):**
`flutter test --no-pub test/content_audio_policy_guard_test.dart test/tts_premium_only_test.dart test/speakable_semantics_test.dart test/speakable_screen_lifecycle_test.dart test/sori_speech_dedupe_test.dart test/auto_speech_test_stub_guard_test.dart test/review_session_screen_speakable_test.dart` → **46 passed, 0 failed**:
- `content_audio_policy_guard_test.dart`: 8
- `tts_premium_only_test.dart`: 12
- `speakable_semantics_test.dart`: 7
- `speakable_screen_lifecycle_test.dart`: 8
- `sori_speech_dedupe_test.dart`: 7
- `auto_speech_test_stub_guard_test.dart`: 1
- `review_session_screen_speakable_test.dart`: 3

`flutter analyze --no-pub` → **No issues found.**

---

## Step 2 — brief section B: `SoriSpeech.phase` transition matrix (pinning test)

New file: `test/sori_speech_phase_matrix_test.dart` (234 lines, no other files touched — `git diff --stat` for this commit shows exactly 1 file). Table-driven: a `const`/`final` list of 10 `_MatrixCase(name, run)` records, looped into 10 `test()` calls, each starting from a fresh `stubSoriSpeech(completeSpeak: false)` + a `SoriSpeech.phase` listener attached *after* the reset (so the reset-to-idle itself isn't recorded).

**RED evidence:** the first honest run of all 10 rows passed immediately —
```
00:00 +0: 1. idle → speak(A) → resolving
00:00 +1: 2. resolving(A) → engine starts A → speaking
00:00 +2: 3. speaking(A) → speak future completes → idle
00:00 +3: 4. resolving(A) → stop() → idle; late engine signal for A does not promote
00:00 +4: 5. speaking(A) → stop() → idle
00:00 +5: 6. speaking(A) → speak(B) → resolving → engine starts B → speaking
00:00 +6: 7. resolving(A) → unrelated engine start (text Z) → stays resolving
00:00 +7: 8. resolving(A) → speak(A) again while pending → dedupe, still resolving, speakImpl once
00:00 +8: 9. idle → prefetch(A) → stays idle
00:00 +9: 10. resolving(A) → stop() → speak(A) again → resolving with a fresh generation; engine start for A promotes
00:00 +10: All tests passed!
```
**This is GREEN-first pinning** — stated explicitly per the brief's allowance. No table row was edited to force a pass; production code (`lib/`) was not touched by this step.

**Sanity check that the harness isn't vacuous:** before trusting the GREEN-first result, row 2's expected sequence was temporarily mutated to a deliberately wrong value (`[idle, speaking]` instead of `[resolving, speaking]`), rerun, and confirmed to fail with a real `expect()` mismatch (`Actual: [resolving, speaking]`, diff at index 0), then reverted to the original and reconfirmed 10/10 green. This rules out the rows being trivially/vacuously true.

Two rows (4, 5) additionally assert `stub.stops == 1` with an inline comment explaining why: in both rows the only `speak('A')` call in that row has `previousKey == null` (first call), so `_publishSpeak`'s internal key-switch `await stopImpl()` branch never fires — the single explicit `SoriSpeech.stop()` call is the only source of the stop count.

**Verification:**
- `flutter test --no-pub test/sori_speech_phase_matrix_test.dart` → **10 passed, 0 failed**.
- `flutter analyze --no-pub` → **No issues found.**
- `git diff --check --cached -- test/sori_speech_phase_matrix_test.dart` → clean (no whitespace errors).
- Frozen contracts + both guards + matrix, run together: `flutter test --no-pub test/content_audio_policy_guard_test.dart test/tts_premium_only_test.dart test/speakable_semantics_test.dart test/speakable_screen_lifecycle_test.dart test/sori_speech_dedupe_test.dart test/auto_speech_test_stub_guard_test.dart test/sori_speech_phase_matrix_test.dart` → **53 passed, 0 failed** (same per-file counts as Step 1 minus `review_session_screen_speakable_test.dart`, plus the 10-row matrix file).

---

## Final consolidated verification (post all 3 commits)

- `flutter analyze --no-pub` → **No issues found** (ran clean at HEAD `47685843`).
- `flutter test --no-pub test/sori_speech_phase_matrix_test.dart test/auto_speech_test_stub_guard_test.dart test/content_audio_policy_guard_test.dart test/tts_premium_only_test.dart test/speakable_semantics_test.dart test/speakable_screen_lifecycle_test.dart test/sori_speech_dedupe_test.dart test/tts_disk_tier_test.dart` (10+1+8+12+7+8+7+1 = 54 expected) run **5 times**:
  - Run 1 (piped through `tail -15`): reported **1 failure** in `auto_speech_test_stub_guard_test.dart` ("자동 발화 화면을 pumpWidget하는 테스트는 SoriSpeech를 스텁한다"). Full failure detail (Expected/Actual/reason) was **not captured** — the `tail -15` truncation cut it off, and the run's log file was not preserved before rerunning.
  - Runs 2–5 (full output captured to file each time, `--reporter expanded` on one of them, plain compact on the others): **all 4 reported 54 passed, 0 failed**, exit code 0 each time.
- `git status --short` at HEAD: only the pre-existing `progress.md` modification; no stray files.

## Unexpected guard failures

One `auto_speech_test_stub_guard_test.dart` failure was observed in 1 of 5 consecutive runs of the exact same combined command (see above), immediately bracketed by clean runs before and after, and not reproduced in 4 further attempts. Investigation:
- Ruled out `tts_disk_tier_test.dart` writing near `test/`: it writes only to `Directory.systemTemp.createTemp('tts_disk_')` (OS temp dir), never under the repo's `test/` directory, and never writes a `.dart` file — so it cannot be adding a phantom file the guard's `Directory('test').listSync(recursive: true)` would pick up.
- Isolated runs of `auto_speech_test_stub_guard_test.dart` (both alone in Step 0 and combined with the 5 frozen files + review file in Step 1) were always green.
- No table row, allowlist entry, or cap was changed to chase this — per R2/R3, an unreproduced one-off in a test unrelated to this dispatch's own frozen contracts was not treated as grounds to touch the guard further.

This is reported as an open item rather than silently dismissed; treating it as a transient environment/scheduling flake (Windows `flutter test` multi-file concurrency) pending further observation, since 4/5 immediate reruns plus every isolated run were clean and no causal file-system interaction could be found.

## Open questions

1. The unreproduced guard flake above — should CI additionally run `auto_speech_test_stub_guard_test.dart` alone (as Step 0 already does) as a permanent belt-and-suspenders, given it could not be reproduced deliberately?
2. `.superpowers/sdd/2026-09-03-w7-pr1-tts/progress.md` has a pre-existing uncommitted modification (Fable's ledger entry, present before this session started) — left untouched per instructions; flagging so Fable can commit/own it explicitly rather than it sitting uncommitted indefinitely.
3. This report file was written but not committed. Checked: `.superpowers/sdd/.gitignore` contains a blanket `*` pattern, so this whole ledger directory (including this report) is gitignored by default and `git status` doesn't even list it as untracked — consistent with "write only your report files," not commit them. Flagging only in case Fable wants specific report files force-added (`git add -f`) the way `progress.md` evidently was at some point.
