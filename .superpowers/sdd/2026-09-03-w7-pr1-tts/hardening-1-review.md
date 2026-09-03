# Hardening dispatch 1 review — 445188b3..4f3227e4

## Verdict: FIX-REQUIRED

## Findings

**[Important] Guard's "isStubbed" heuristic accepts a no-op safety measure**
File: `test/auto_speech_test_stub_guard_test.dart:169-171`
Issue: `isStubbed = content.contains('stubSoriSpeech(') || content.contains('SoriSpeech.resetForTesting(')`. Per `test/support/sori_speech_stubs.dart:389` (`SoriSpeech.resetForTesting`), a call to `resetForTesting()` alone resets `speakImpl`/`speakSlowImpl`/`prefetchImpl`/`stopImpl` back to the **real** `TtsService.*` delegates (`lib/widgets/sori/speakable.dart:135-138`). A test that calls `resetForTesting()` in `setUp` but never assigns a stub `speakImpl` is exactly the T3 trap this guard exists to prevent (real TtsService → in-flight key lock), yet the guard treats it as "protected."
Why: the guard's stated contract is "protects against unstubbed auto-speech pumpWidget," but the string-match accepts a call that structurally cannot deliver that protection.
Fix: only accept `stubSoriSpeech(` as evidence of stubbing (or additionally require a `speakImpl =` assignment) so that a bare `resetForTesting()` call does not silently pass.
Evidence today: 0 offenders currently (verified via `grep -rl "SoriSpeech.resetForTesting(" test` → 8 files, all 8 also contain `speakImpl =` or `stubSoriSpeech(`), so this is a latent hole, not a live regression.

**[Important] New test file violates repo's hard if/else-brace rule**
File: `test/auto_speech_test_stub_guard_test.dart:68,73,75,79`
Issue: four single-line `if (...) continue;` / `if (...) unstubbed.add(...)` statements without braces, e.g. `if (entity is! File || !entity.path.endsWith('.dart')) continue;` (line 68).
Why: `AGENTS.md:335` — "`if/else` 반드시 중괄호 사용. 한 줄 생략 금지 (실제 오류 발생 이력 있음)" — this is an explicit, documented house rule citing real prior incidents from brace omission, and this dispatch introduces 4 new violations.
Fix: wrap all four bodies in `{ }`.

**[Minor] `stubSoriSpeech()` shares one `Completer` between `speak` and `speakSlow`**
File: `test/support/sori_speech_stubs.dart:30-39`
Issue: when `completeSpeak: false`, `speakImpl` and `speakSlowImpl` both return `pendingCompleter!.future` — the identical `Future` instance. A future test that exercises both hooks on the same stub (e.g. to assert `speak()` resolves independently of `speakSlow()`) would have both calls resolve together on a single `.complete()`.
Why: currently unused (`grep -rn "completeSpeak" test` shows no call site passing `false`), so this is latent, not exploited.
Fix: give `speak` and `speakSlow` independent completers, or document the coupling explicitly if intentional.

No other issues found. `setCacheDirForTesting` is correctly `@visibleForTesting`-only (no `lib/` caller besides the seam itself), `_ensureCacheDir()` re-queries `path_provider` when `_cacheDir == null` (`lib/services/tts_service.dart:1286-1301`), `clearCacheStrict`'s `_cacheDir = null` reset (line ~1177) is consistent with the new setter. `tts_disk_tier_test.dart` uses real `TtsCacheKey.forRequest`/`localFileName`/`bundledAssetPath()` APIs (`lib/services/tts_cache_key.dart:41,62,`), both prod (`tts_service.dart:858-860`) and test (`tts_disk_tier_test.dart:31`) build the cache path with the identical `'${dir.path}/${key.localFileName}'` string interpolation, so `resolved.path == file.path` is a same-string comparison, not an OS path-normalization dependency — safe on both Windows and Linux CI. The 2s/50ms poll correctly pins the *call site* inside `_resolveAudio` (`unawaited(_touchCacheFile(file))` at line 868) rather than calling the exposed `touchCacheFileForTesting` helper directly, which is the right choice per the test's stated purpose. `setLastModified` precision is a non-issue here since the test's stale-vs-fresh deltas are days vs. under a minute. `ci.yml`'s new `if:` block for `tts-storage-verify` is phrase-for-phrase identical in structure to the `build` job's guard (only the `changes.outputs.*` key differs), YAML parses cleanly (`yaml.safe_load` succeeded), and `needs: changes` is retained.

## Mutation check output

**Guard FAILS with unstubbed probe present** (`test/zz_tmp_unstubbed_probe_test.dart`, pumps `ChosungQuizScreen` without any stub):
```
00:01 +0 -1: 자동 발화 화면을 pumpWidget하는 테스트는 SoriSpeech를 스텁한다 [E]
  Expected: empty
    Actual: ['test/zz_tmp_unstubbed_probe_test.dart']
  SoriSpeech를 스텁하지 않고 자동 발화 화면을 pumpWidget하는 신규 테스트 파일: test/zz_tmp_unstubbed_probe_test.dart — ...
00:01 +0 -1: Some tests failed.
```

**Guard GREEN after probe deleted:**
```
00:00 +0: 자동 발화 화면을 pumpWidget하는 테스트는 SoriSpeech를 스텁한다
00:00 +1: All tests passed!
```
Probe file was created then deleted; `git status --short` in the worktree shows only the pre-existing, unrelated `progress.md` modification — no residue.

## Checklist table

| # | Item | Status | Evidence |
|---|------|--------|----------|
| 1 | Guard correctness (mutation check) | OK | Fails naming probe file; green after deletion (above) |
| 2 | Guard heuristic hole (`resetForTesting()` alone) | ISSUE | 0 live offenders today, but heuristic accepts a non-protective call — see Important finding |
| 3 | Allowlist fidelity (60 entries) | OK | Independent Python reproduction of the guard's scan logic produces the exact same 60-file set (`diff` → identical) |
| 4 | `stubSoriSpeech()` semantics | ISSUE (minor) | reset-then-assign order correct; `addTearDown` in `setUp` valid; `prefetchImpl` signature matches `Future<void> Function(String,String)` exactly; shared completer is a latent coupling (see Minor finding) |
| 5 | `tts_disk_tier_test.dart` | OK | Real API confirmed (`tts_cache_key.dart:41,62,`); path join identical prod/test; call-site correctly pinned via `unawaited(_touchCacheFile(...))`; mtime deltas make precision irrelevant; `_ensureCacheDir` re-queries when null (`tts_service.dart:1286`) |
| 6 | `setCacheDirForTesting` | OK | `@visibleForTesting`; only called from `tts_disk_tier_test.dart`; consistent with `clearCacheStrict`'s `_cacheDir = null` |
| 7 | ci.yml | OK | Identical `if:` phrasing/comment style to `build` job; `yaml.safe_load` parses; `needs: changes` retained |
| 8 | Migrated tests | OK | All old `expect(spoken/prefetched,...)` have `stub.*` equivalents; `vocab_pack_screen_prefetch_test.dart` has no dangling `SoriSpeech`/`speakable.dart` references after import removal; targeted reruns of all 3 migrated files pass (8/8 tests) |
| 9 | Repo rules | ISSUE | No `TtsService` literal added to `lib/screens/*` by this dispatch; `content_audio_policy_guard_test.dart` passes (8/8); no hardcoded user-facing strings; **4 if/else brace-rule violations** in `auto_speech_test_stub_guard_test.dart:68,73,75,79` (AGENTS.md:335) |

## Summary

| Severity | Count | Status |
|----------|-------|--------|
| Critical | 0 | pass |
| Important | 2 | fix required |
| Minor | 1 | note |

Verdict: FIX-REQUIRED — fix the 4 brace-rule violations (mechanical, low-risk) and tighten the guard's `isStubbed` check to require `stubSoriSpeech(` (or an explicit `speakImpl =` assignment) before merge. The Minor shared-completer issue can be addressed opportunistically since it is currently unexercised.
