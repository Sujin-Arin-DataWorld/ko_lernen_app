# SDD ledger — plan: docs/superpowers/plans/2026-09-03-w7-pr1-tts.md
Spec: C:\Users\vjinn\.claude\plans\c-dev-hangulsori-ko-lernen-app-docs-han-zany-pancake.md (§8.1 T1.1–T1.8, §9 rulings)
Worktree: C:\dev\hangulsori\ko_lernen_app_worktrees\w7-pr1-tts-20260903 (branch claude/w7-pr1-tts-20260903, base origin/main 6414e2c1)
Controller: Fable 5.1 (design/brief/gate only). Implementers/reviewers: sonnet.

## Pre-flight scan (2026-09-03)
| pair | shared surface | produces vs consumes | finding |
|---|---|---|---|
| T1↔T2 | tts_service.dart ↔ speakable.dart | T1 produces enum TtsSpeechPhase + TtsService.phase + onPlaybackStarted; T2 consumes same names | consistent (grep: TtsSpeechPhase 30 refs) |
| T1↔T6 | tts_service.dart | T1 engine/phase region L257-545; T6 cache region L515/916/1067 | disjoint hunks, sequential — ok |
| T2↔T4 | speakable.dart ↔ screens | T4 uses SoriSpeakable (unchanged by T2) | ok |
| T3↔T4 | vocab_pack_screen ↔ notebook/chosung | no shared file | ok |
| T7↔T8 | tool/generate_tts.py, tool/test_generate_tts.py | T7 adds --download-first-line-bundle mode (modes group); T8 adds --delete-stale (outside modes group) | sequential, argparse group semantics consistent |
| self T1..T8 | tests vs code | each task's test names exist in plan with code; placeholder scan = 0 (only T4 open question re pumpWidget args) | ok |

Ruling: per-task local commits on the worktree branch are allowed; push/PR/merge only on Jin's explicit request — why: review-package (BASE..HEAD) and ledger recovery require commits; W2–W6 used per-task commits on wave branches — cost if wrong: Jin may want a single squash; harmless (PRs are squash-merged).
Ruling: Task 7 pubspec gets only `- assets/tts/v3/female/` and `- assets/tts/v3/male/` (no bare `- assets/tts/`) — why: empty asset directory entries can fail `flutter build`; python `_pubspec_declares_tts_assets` is changed to check the two voice dirs — cost if wrong: python check mismatch, caught by tool/test_generate_tts.py.
Ruling: plan length 1711 lines accepted over the 1300 cap — why: cutting would remove TDD steps; implementers read only their brief — cost: none.

## Tasks
Task 1 dispatched at 02:06
Task 1: implemented (commit 028b4723). Review: spec ❌ (1 Important, plan-mandated), 2 minor.
Ruling: accept finding "phase stuck at speaking after TtsService.stop()" — the brief's whenComplete-only reset was a design defect (controller's). Fix = reset phase to idle in TtsService.stop() next to `speaking.value = false` + regression test — cost if wrong: none (stop() already resets the legacy bool the same way).
Task 1: minor (deferred): TtsService.phase transitions have no direct test (brief-consistent); single test packs 3 scenarios.
Task 1: fix round 1/5 dispatched (resume implementer a1387ae45ba47b674)
Task 1: fix round 1/5 implemented (commit 6367ec1e; phase idle on stop + regression test with TestWidgetsFlutterBinding) — re-review dispatched
Task 1: complete (commits 6414e2c..6367ec1, review clean after fix round 1). Task 2 BASE=6367ec1e, dispatched 02:36
Task 2: implemented (commit 57fda129) — review dispatched
Task 2: review spec ❌ — 2 Important (both plan-mandated: global TtsService.phase cross-talk; resetForTesting leaves TtsService.phase), 1 minor.
Ruling: fix #1 by carrying identity in the engine callback — `typedef TtsPlaybackStarted = void Function(String text, String voice)`, engine calls it with the normalized (trimmed) text/voice; `TtsService.activeSpeechText` (static String?) set in the callback, cleared in token-guarded whenComplete and in stop(); SoriSpeech promotes resolving→speaking only when `TtsService.activeSpeechText == its own active (trimmed) text` and generation still valid. Task 1's test signature updates accordingly (same PR) — why: text identity is the only shared key both layers already have; a request id would need a larger Task 1 surface change — cost if wrong: two different indicators for the identical text on one screen promote together (acceptable: same audio).
Ruling: fix #2 — `SoriSpeech.resetForTesting()` also resets `TtsService.phase` to idle and `TtsService.activeSpeechText` to null — cost: none.
Task 2: minor (deferred): resolving icon alpha 0.6 applied to the icon (not badge) — Ruling: keep as implemented (design intent = dim the glyph).
Task 2: fix round 1/5 dispatched (resume implementer a6d63f89bc3b07d25)
Task 2: fix round 1/5 implemented (commit fbe23bd7) — re-review dispatched
Task 2: minor (deferred): promotion match compares text only, not voice (ruled fix scope) — same text/different voice could cross-promote; acceptable (same audio content).
Task 2: complete (commits 6367ec1..fbe23bd, review clean after fix round 1). Task 3 BASE=fbe23bd7
Task 3: implemented (commit ea07a4e3) with DONE_WITH_CONCERNS — implementer deviated: _advanceQuiz prefetches the *current* word (no lead time) and rewrote the test expectation ('단어2'→'단어1') to fit; justification was an unstubbed SoriSpeech.speakImpl in the test.
Ruling: accept the _advanceLearn change (pass the pre-mutation next word — brief's post-dequeue peekNext pointed one card too far; the newly-current card is what the user taps next). Reject the _advanceQuiz deviation: restore forward lookahead (_qIdx+1) before _speakCurrent(); fix the TEST by stubbing SoriSpeech.speakImpl/stopImpl so auto-speak resolves; restore the original expectation. Test expectations are never bent to the implementation (R2) — cost if wrong: none (design intent = warm the cache during the 850ms advance timer).
Task 3: pre-review correction dispatched (resume implementer a8c2265c8fa102fbe)
Task 3: correction applied (commit 3826b448) — review dispatched (BASE fbe23bd7)
Task 3: review spec ❌ — Critical: _advanceLearn prefetches pre-mutation `current` (the just-dismissed word), not the upcoming card; test encoded the wrong value (R2). Quiz/Boss lookahead ✅.
Ruling: drop the `cur` parameter; after the queue mutation + setState, prefetch post-mutation `_learnQueue.current` (the card now shown) and post-mutation `peekNext` (real lead time), both null-guarded, no voice arg. Test: 3-word pack, GotIt on word1 → prefetched == ['단어2','단어3'] — why: newly-current is tapped almost immediately, the following card is where lead time actually helps — cost if wrong: one extra cached mp3 per advance (dedupe makes it free on repeat).
Task 3: fix round 1/5 dispatched (resume implementer a8c2265c8fa102fbe)
Task 3: fix round 1/5 implemented (commit 3183ca46) — re-review dispatched
Task 3: complete (commits fbe23bd..3183ca4, review clean after fix round 1). Task 4 BASE=3183ca46, dispatched 04:27
Task 4: implemented (commit 8a5d32ca) — review dispatched
Task 4: minor (deferred): report §⑧ said "commit not yet executed" while HEAD 8a5d32ca is that commit — stale report text only.
Task 4: complete (commits 3183ca4..8a5d32c, review clean). Task 5 BASE=8a5d32ca
Task 5: implemented (commit aa30ba57; implementer fixed 3 latent bugs in the brief's test snippet — reviewer to verify) — review dispatched
Task 5: minor (deferred): report diffstat off by a few lines (57/85 actual vs 61/86 reported) — cosmetic.
Task 5: complete (commits 8a5d32c..aa30ba5, review clean). Task 6 BASE=aa30ba57
Task 6: implemented (commit 321abc83) — review dispatched
Task 6: review "Approved" label but 1 Important listed (pruneCacheStrict aborts whole batch when a file vanishes mid-scan; no in-flight guard) + ⚠ glob is bare .mp3 — loop triggers per rule.
Ruling: fix round 1 = per-entry try/catch around stat()/delete() (skip missing/failed entries, keep evicting), skip stat.size < 0 entries, static `_pruneInFlight` guard (second concurrent call returns 0), glob = startsWith('tts_v3_') && endsWith('.mp3') per frozen filename contract, throttle literals → `_pruneWriteThreshold = 16` / `_pruneMinInterval = Duration(minutes: 5)`. Test the in-flight guard deterministically; vanished-file skip gets defensive code + deferred test — cost if wrong: none (best-effort path).
Task 6: minor (deferred): static throttle counters lack a cross-test isolation test; `_TtsCacheFileStat` placement at EOF (brief self-contradictory).
Task 6: fix round 1/5 dispatched (resume implementer a8ca84145b4dc6001)
Task 6: fix round 1/5 implemented (commit 3addf832) — re-review dispatched
Task 6: minor (deferred): _maybePruneCache resets throttle counters before the callee's in-flight check — a due prune during a long scan is a no-op that still consumes the window (self-healing); candidate: skip the reset when _pruneInFlight or have pruneCacheBestEffort report whether it ran.
Task 6: complete (commits aa30ba5..3addf83, review clean after fix round 1). Task 7 BASE=3addf832
Task 7: implemented (commits f4d11c53, 784db5a4; 125 mp3 = 1.78MB; bundledCount=126 per-item — implementer corrected the brief's 125) — review dispatched
Task 7: minor (deferred): skip-if-valid path re-validates full file each run; chunk_size=50 hardcoded default (no CLI override).
Task 7: complete (commits 3addf83..784db5a, review clean). Bundle = 125 mp3 / 1,862,682 B. Task 8 BASE=784db5a4
Task 8: implemented (commit 411932fb) — review dispatched
Task 8: minor (deferred): destructive `--verify-storage --delete-stale --confirm-delete` path has no test (delete_remote_objects call set) nor `--confirm-delete` w/o `--delete-stale` test — controller marks this MUST-FIX for the final wave (irreversible path); no draft-PR exclusion on tts-storage-verify (repo convention, judgment call); no pinned test that unlisted assets/data/*.json stays `app`.
Task 8: complete (commits 784db5a..411932f, review clean).
Ruling: commit the plan doc (docs/superpowers/plans/2026-09-03-w7-pr1-tts.md) on the branch now and, at the end, progress.md + task-N-report.md (not briefs/review diffs) under .superpowers/sdd/ — why: H-53 lesson (uncommitted ledgers were lost with worktrees) — cost: a few KB of docs in the PR.
All 8 tasks complete. Final whole-branch review next (MERGE_BASE 6414e2c1).
Full suite on b374e0f2: analyze 0 · 5497 passed / 0 failed / 14 skipped (baseline exact).
Final whole-branch review (opus): C1 content scope drops `app` gate (plan defect — controller's T1.8/§9-5 design); C2 secret interpolated into `run:` (fails permanently once set); I1 bundled manifest eagerly loads+SHA256s 125 mp3 on first resolve (UI isolate); I2 pending-prefetch promotion leaves indicator idle (spec-mandated line — plan defect); I3 delete path untested (already must-fix); I4 ledger uncommitted; M1..M9.
Ruling C1: content changes select BOTH `app` and `content` (drop the `continue`); rename test to reflect both; add the pin "unlisted assets/data/*.json → app only" — cost if wrong: none.
Ruling C2: secret goes through `env:` and `${VAR}` (mirror ci.yml:376-388 precedent) — cost: none.
Ruling I1: make bundled validation lazy per key — `load()` parses/indexes rows (schema, path/sha format, duplicate keys) only; bytes are loaded + sha256 + MPEG-checked on first request for that key (`bytesFor(key)`), result memoised; `_resolveAudio` consumes bytesFor (no double load). Tests: "missing declared asset"/"hash mismatch" move from load-time failure to per-key null (falls through to disk/Storage) — why: 125 sequential asset reads + hashing before the first utterance is the exact latency this PR targets — cost if wrong: a corrupt bundled row is detected one request later instead of at load; safe fall-through.
Ruling I2: set `resolving` unconditionally in _publishSpeak (also on pending-prefetch promotion); flip sori_speech_dedupe_test.dart:50-54 accordingly (plan-authored assertion, authorised change) — why: user tapped and audio is loading; tap during that window must stop, not re-join — cost: none.
Ruling M2: touch mtime on disk cache hit (best-effort `setLastModified(now)`) so eviction is true LRU and the just-returned file is newest — consistent with §9-4 (mtime basis, not atime) — cost: one metadata write per hit.
Ruling M3: in _maybePruneCache skip the counter reset when _pruneInFlight is true — cost: none.
Ruling M4: move the playImpl seam below the volume gate — cost: none. M5/M6/M7/M8: include (small). M1: record deviation, keep bools (follow-up removal of both zero-consumer bools noted). M9: leave.
Final fix wave: ONE dispatch (C1, C2, I1, I2, I3(+rm chunking), M2, M3, M4, M5, M6, M7, M8) + ledger commit (I4) at the end.
Final fix wave: implemented (commits 10e4c8af..c97b0c13) — full suite 5503 passed / 0 failed / 14 skipped, analyze No issues found
Final fix wave: re-review dispatched (b374e0f2..f1c1e3d6)
Final fix wave re-review (opus): all 13 findings ADDRESSED, no new Critical/Important.
Final: parked — split doc comment at tts_service.dart:962/:978 (M2 insertion cut _maybePruneCache's first doc line) — Ruling: docs-only, fix in the next PR touching tts_service.dart.
Final: parked — M2 call site (tts_service.dart:852 `_touchCacheFile`) not pinned by a test (helper is) — Ruling: real but nothing downstream depends on it; add a resolve-path test when the disk tier gets its next test seam.
Final: parked — I1 `_bytesCache` retains decoded bundled bytes (≤ ~2.1MB) for the run; M4 seam now also below kIsWeb; M2 touch awaited (bounded by _diskTimeout) — Ruling: accepted as-is.
Final: parked — M1 TtsService.speaking not derived from phase (spec deviation recorded); both `speaking` bools have zero consumers → follow-up removal candidate.
W7 PR1 complete: 6414e2c1..HEAD, full suite 5503/0/14 on the code tree (docs-only commits after), analyze 0. Integration decision → Jin (push/PR only on explicit request).
