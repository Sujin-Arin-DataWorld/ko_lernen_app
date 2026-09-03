# Task 1 Report — `TtsPlaybackEngine.onPlaybackStarted`

## ① git diff --stat (commit 028b4723)

```
commit 028b4723b28fb81c51438c42f168088b4dae7d78
    feat(tts): 재생 시작 콜백(onPlaybackStarted)과 3단 phase 엔진 배선 추가 (지시서 4.3/4.5 / 스윕 tts-02)

 lib/services/tts_service.dart   | 14 ++++++++++++
 test/tts_premium_only_test.dart | 49 +++++++++++++++++++++++++++++++++++++++++
 2 files changed, 63 insertions(+)
```

lib diff (excluding tests) is 14 net insertion lines (well under the ≤60줄 budget).

## ② RED log

Command: `flutter test --no-pub test/tts_premium_only_test.dart` (before Step 3 implementation)

```
00:00 +0: loading .../test/tts_premium_only_test.dart
flutter : test/tts_premium_only_test.dart:230:9: Error: No named parameter with the name 'onPlaybackStarted'.
lib/services/tts_service.dart:259:3: Context: Found this candidate, but the arguments don't match.
  TtsPlaybackEngine({
  ^^^^^^^^^^^^^^^^^
        onPlaybackStarted: () => throwingCalls.add(null),
        ^^^^^^^^^^^^^^^^^
test/tts_premium_only_test.dart:241:9: Error: No named parameter with the name 'onPlaybackStarted'.
        onPlaybackStarted: () => startedCalls.add(null),
        ^^^^^^^^^^^^^^^^^
test/tts_premium_only_test.dart:252:9: Error: No named parameter with the name 'onPlaybackStarted'.
        onPlaybackStarted: () => missingCalls.add(null),
        ^^^^^^^^^^^^^^^^^
00:00 +0 -1: loading ... [E]
  Failed to load ...: Compilation failed ...
00:00 +0 -1: Some tests failed.
```

Expected per brief: "FAIL(컴파일) — `The named parameter 'onPlaybackStarted' isn't defined.`(2곳)". Actual: 3 occurrences (three `onPlaybackStarted:` usages in the new test — throwing/starting/missing engines), same root cause (constructor didn't declare the parameter yet). Compile failure as expected, confirming the test exercises code that doesn't exist yet.

Note: before this run, `.dart_tool/` was entirely absent in this worktree (never had `flutter pub get` run), so the very first `flutter test` invocation failed with a `package:flutter_test` resolution error rather than the RED compile error. Per the brief's stated exception ("Do not run `flutter pub get` unless the tests fail to resolve packages"), ran `flutter pub get` once, then re-ran and got the expected RED above.

## ③ GREEN log

Command: `flutter test --no-pub test/tts_premium_only_test.dart` (after Step 3 implementation)

```
00:00 +0: loading .../test/tts_premium_only_test.dart
00:00 +0: OS 음성 티어를 되살릴 수 없다
00:00 +1: 재생 플랫폼은 오디오 페이로드만 받는다
00:00 +2: 로컬 캐시 읽기 실패는 TimeoutException 외의 예외도 잡아 Storage 로 넘어간다 (finding 1a)
00:00 +3: 프리미엄이 없으면 — 무음이되 조용하지 않다 해결 실패는 재생을 시작하지 않고 사유를 남긴다
00:00 +4: 프리미엄이 없으면 — 무음이되 조용하지 않다 차단된 합성의 사유가 그대로 전달된다
00:00 +5: 프리미엄이 없으면 — 무음이되 조용하지 않다 TtsSynthesisBlocked 가 아닌 해석 실패도 사유가 보고된다 (finding 1b)
00:00 +6: 프리미엄이 없으면 — 무음이되 조용하지 않다 재생 단계 실패(해석은 성공)는 errorReporter 만 타고 onResolutionFailed 는 안 탄다 (post-review)
00:00 +7: 프리미엄이 없으면 — 무음이되 조용하지 않다 해석 실패는 errorReporter 와 onResolutionFailed 를 둘 다 태운다 (post-review)
00:00 +8: 재생 시작 콜백(onPlaybackStarted) — post-review T1.1 해석 성공 + startAudio 성공에서만 정확히 1회 불린다
00:00 +9: TtsAudio 는 경로 또는 바이트 중 하나만 갖는다
00:00 +10: All tests passed!
EXITCODE=0
```

10/10 GREEN — 9 pre-existing tests (unmodified, still pass) + 1 new test (T1.1).

## ④ flutter analyze --no-pub

```
Analyzing w7-pr1-tts-20260903...
No issues found! (ran in 185.5s)
```

Exit code 0.

## ⑤ 인접 가드 (`test/content_audio_policy_guard_test.dart`)

Command: `flutter test --no-pub test/content_audio_policy_guard_test.dart`

```
00:00 +0: loading .../test/content_audio_policy_guard_test.dart
00:00 +0: (setUpAll)
00:00 +0: ContentSpeechController 는 soriRouteObserver 를 구독한다
00:00 +1: 전환 시 TtsService.stop() 을 호출한다 (didPushNext/deactivate)
00:00 +2: 진입/전환 자동재생은 인위 지연 없이 다음 event turn에 시작한다
00:00 +3: speak/prefetch 는 세대 토큰 + 공유 in-flight 맵을 쓴다
00:00 +4: 하트 판정은 onDoubleTap 전용이고 인디케이터는 별도로 포인터를 소비한다
00:00 +5: 학습 화면은 저수준 TtsService를 직접 참조하지 않는다
00:00 +6: quest, cloze, scenario 비플립 콘텐츠는 탭 재생 래퍼를 쓴다
00:00 +7: first-line bundle tier is manifest-only and declares no fake audio dir
00:00 +8: (tearDownAll)
00:00 +8: All tests passed!
EXITCODE=0
```

8/8 PASS, file untouched (this task never edits `lib/widgets/sori/speakable.dart`).

## ⑥ 예상 밖 가드/테스트 실패

없음.

## ⑦ 미해결 의문 (brief 원문)

- `TtsService.phase`가 `resolving`을 스스로 쓰지 않는다(엔진은 idle/speaking 2단만 오간다) — 그래도 T1.1/T1.2가 같은 3단 enum 하나를 공유하도록 스펙이 지시해 이 설계를 그대로 따랐다.

## ⑧ Self-review notes

- Completeness: all 5 anchor points from the brief (enum, constructor/field, call site, static `phase` + engine wiring, `whenComplete` idle reset) landed verbatim; diffs matched the brief's code blocks exactly, byte-for-byte at the touched lines.
- YAGNI: no extra state, no unused enum members exercised, no speculative API surface — `resolving` is intentionally never set by this engine (per the brief's own open question); Task 2 owns that.
- Frozen contracts: `onResolutionFailed`/`errorReporter` signatures and call sites are byte-for-byte unchanged (only a `git diff` context line moved, no semantic edit). `test/content_audio_policy_guard_test.dart` and `lib/widgets/sori/speakable.dart` were not touched.
- No hardcoded strings introduced (the two new comments/docs are Korean prose comments, not user-facing or logic strings).
- Braces: the one new call site (`onPlaybackStarted?.call();`) is a single statement, not an if/else — no braces question there; no other conditional was added or modified.
- Scope: only `lib/services/tts_service.dart` and `test/tts_premium_only_test.dart` were modified, as instructed. The untracked `docs/superpowers/plans/2026-09-03-w7-pr1-tts.md` file already present in the worktree was left untouched and unstaged.
- Environment note: `.dart_tool/` was missing from this worktree at task start (never had `pub get` run); ran `flutter pub get` once per the brief's stated exception before the RED run could even compile-fail correctly.

## Fix round 1

**Finding addressed (Important):** `TtsService.stop()` reset `speaking.value = false` but not `phase` — because `stop()` bumps `_speakToken`, the in-flight `speak()`'s `whenComplete` guard (`if (token == _speakToken)`) becomes false, so `phase` stayed stuck at `TtsSpeechPhase.speaking` after any explicit stop during playback (routine `ContentSpeechController` didPushNext/deactivate → `TtsService.stop()` path).

### What changed

- `lib/services/tts_service.dart:732` — added `phase.value = TtsSpeechPhase.idle;` immediately next to `speaking.value = false;` inside `TtsService.stop()` (same statement ordering/guard-free placement as the bool it mirrors — `stop()` is not `async`, so this line executes synchronously the instant `stop()` is called, before the returned `_playbackEngine.stop()` future is even awaited).
- `test/tts_premium_only_test.dart:260-278` — new regression test inside the `'재생 시작 콜백(onPlaybackStarted)'` group: `'stop() 은 phase 를 idle 로 되돌린다 (카드 전환 정지 시 speaking 고착 방지, fix round 1)'`. All 10 pre-existing tests in the file are byte-for-byte unmodified (diff is a pure addition after the last existing test in the group).

### Regression test — two attempts before the working one (both tried, both reported per the escape-valve/ follow-up instruction)

1. **`await engine.speak(...)` fully awaited, no binding init** → `flutter test --no-pub test/tts_premium_only_test.dart` **hung and timed out** at 30s. Root cause: `TtsService._player` is a `static final AudioPlayer _player = AudioPlayer();` (the `audioplayers` package). First access (inside `TtsService._stopPlatforms()`, reached via `TtsService.stop()` → `TtsPlaybackEngine.stop()` → `_serialize(platform.stop)`) constructs a real `AudioPlayer`, whose internal `GlobalAudioScope` calls `EventChannel.receiveBroadcastStream().listen()` and then `MethodChannel.invokeMethod(...)`, both of which need `ServicesBinding.instance` — absent in a bare `test()` (no `TestWidgetsFlutterBinding.ensureInitialized()`). The resulting `FlutterError` ("Binding has not yet been initialized") did **not** reject the awaited `Future` (it fired from an orphaned/unawaited internal stream-listen callback inside the `audioplayers` package, reported via the test zone's uncaught-error handler with "asynchronous gap" markers) — so no `try/catch` around the `await` could catch it, and the test just hung until `package:test`'s own 30s per-test timeout fired.
2. **Called `TtsService.stop()` without awaiting the returned future, `.catchError` on it** → still failed, but quickly (no hang): confirmed the theory above — the actual `FlutterError` is not a rejection of the future returned by `TtsService.stop()`/`_playbackEngine.stop()` at all (that future's chain already has its own internal best-effort `try/catch` in `_stopPlatforms()`/`TtsPlaybackEngine.stop()` and would have swallowed a normal rejection); it is a separate, orphaned zone-level uncaught error from inside `audioplayers`' `AudioPlayer()` construction, which `package:test` still attributed to this test even though its synchronous body had already returned.
3. **Working version** (committed): added `TestWidgetsFlutterBinding.ensureInitialized();` as the first line of the test body — this is the standard, documented Flutter-test API for exactly this situation (not a mock of `TtsService`/`TtsPlaybackEngine`/`AudioPlayer` behavior — it only supplies the real `ServicesBinding`/`TestDefaultBinaryMessengerBinding` that `audioplayers`' platform-channel calls need). With the binding present, the channel calls fail as ordinary `MissingPluginException`s (no native plugin registered in `flutter test`), which the app's own existing best-effort `try/catch` in `_stopPlatforms()`/`TtsPlaybackEngine.stop()` swallows exactly as designed. Scoped to only this one test — the other 9 tests in the file never touch a platform channel, so they are unaffected (verified: they still pass, and `flutter analyze` and the guard test are also unaffected).

### Covering tests + commands + output

`flutter test --no-pub test/tts_premium_only_test.dart` (run twice to confirm no flakiness):
```
...
00:00 +8: 재생 시작 콜백(onPlaybackStarted) — post-review T1.1 해석 성공 + startAudio 성공에서만 정확히 1회 불린다
00:00 +9: 재생 시작 콜백(onPlaybackStarted) — post-review T1.1 stop() 은 phase 를 idle 로 되돌린다 (카드 전환 정지 시 speaking 고착 방지, fix round 1)
00:00 +10: TtsAudio 는 경로 또는 바이트 중 하나만 갖는다
00:00 +11: All tests passed!
```
11/11 GREEN (10 original + 1 new), both runs, no hang.

`flutter test --no-pub test/content_audio_policy_guard_test.dart`:
```
00:00 +8: (tearDownAll)
00:00 +8: All tests passed!
```
8/8 GREEN, unmodified.

### flutter analyze --no-pub (foreground)

```
Analyzing w7-pr1-tts-20260903...
No issues found! (ran in 218.7s)
```

### Commit

`6367ec1e` — `fix(tts): stop()이 phase를 idle로 되돌리도록 — 카드 전환 정지 시 speaking 고착 방지 (Task 1 fix round 1)` — 2 files changed, 22 insertions(+).

### Concerns / open notes

- The 3-attempt trail above is included for traceability; only attempt 3 (committed) actually runs in CI.
- `TestWidgetsFlutterBinding.ensureInitialized()` is idempotent and scoped to this one test file's process — it does not change any of the other 9 tests' behavior (confirmed by their still-passing output), but it is a small addition beyond the single `expect`/`await` line originally sketched in the fix instructions; flagging it explicitly in case the controller wants a different pattern for future platform-channel-touching tests in this file.
