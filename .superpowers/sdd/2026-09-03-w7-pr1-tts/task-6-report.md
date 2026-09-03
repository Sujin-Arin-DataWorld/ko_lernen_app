# Task 6 리포트 — TTS 로컬 캐시 80MB LRU 상한

## ① diffstat

```
 lib/services/tts_service.dart | 79 +++++++++++++++++++++++++++++++++++++++++++
 test/tts_cache_prune_test.dart | 73 ++++++++++++++++++++++++++++++++++++++++
 2 files changed, 152 insertions(+)
```

커밋: `321abc83` (branch `claude/w7-pr1-tts-20260903`, HEAD였던 `aa30ba57` 위) — 로컬 커밋만, push/PR 없음.

앵커 위치(작업 시점 실측, 브리프 대비 라인 시프트 확인됨):
- `_maxBytes` 상수: L525 (브리프 예상 L515, +10)
- `_cacheAndWrap`: L933-946 (브리프 예상 L904-918, +29)
- `clearCacheStrict` 뒤: L1096 부근에 삽입 (브리프 예상 L1059, +37)

## ② RED 로그

```
flutter test --no-pub test/tts_cache_prune_test.dart --reporter expanded
test/tts_cache_prune_test.dart:37:36: Error: Member not found: 'TtsService.pruneCacheStrict'.
test/tts_cache_prune_test.dart:57:36: Error: Member not found: 'TtsService.pruneCacheStrict'.
test/tts_cache_prune_test.dart:68:18: Error: Member not found: 'TtsService.pruneCacheStrict'.
test/tts_cache_prune_test.dart:71:22: Error: Member not found: 'TtsService.pruneCacheBestEffort'.
00:00 +0 -1: Some tests failed.
```
브리프 예상 컴파일 실패와 일치.

## ③ GREEN 로그

```
flutter test --no-pub test/tts_cache_prune_test.dart --reporter expanded
00:00 +0: 예산 초과 시 오래된 mp3부터 지우고 .part는 절대 지우지 않는다
00:00 +1: 총량이 예산 이하면 아무것도 지우지 않는다
00:00 +2: strict 버전은 디렉터리 조회 실패를 전파하고 best-effort는 삼킨다
00:00 +3: All tests passed!
```
3/3 GREEN.

## ④ analyze

```
flutter analyze --no-pub
Analyzing w7-pr1-tts-20260903...
No issues found! (ran in 77.0s)
```
0 issues.

## ⑤ 인접 가드

`flutter test --no-pub test/account_cleanup_test.dart test/tts_cache_key_test.dart test/tts_bundled_manifest_test.dart test/tts_premium_only_test.dart --reporter expanded`
→ 35개 테스트 전부 PASS(34번째 인덱스까지 +34, "All tests passed!"). 동결 계약 확인:
- `account_cleanup_test.dart` strict/best-effort 4개 테스트 무수정 GREEN.
- `tts_cache_key_test.dart` `storagePath`/`localFileName` 포맷 테스트 무수정 GREEN.
- `tts_bundled_manifest_test.dart`의 "resolver source preserves bundle, disk, Storage, callable order" 테스트 GREEN — `_resolveAudio` 순서 미변경.
- `tts_premium_only_test.dart` 전체(Task 1/2의 `TtsSpeechPhase`/`onPlaybackStarted` 포함) GREEN — 이번 캐시 변경이 재생/phase 로직에 간섭하지 않음.

## ⑥ 예상 밖 가드 실패

없음. 4개 가드 파일 모두 1회차에 전부 통과.

## ⑦ 미해결 의문 (≤3)

1. 브리프의 "파일 하단(`_TtsResolution` 근처)" 지시는 문자 그대로 보면 `_TtsResolution`은 파일 초반(원래 L456 부근)에 있어 위치가 어긋난다. 실제로는 파일 최말단(`TtsService` 클래스 종료 직후, `_reapplySpeechAudioContext` 뒤)에 `_TtsCacheFileStat`를 추가했다 — "파일 하단"이라는 문구를 우선하고 "`_TtsResolution` 근처"는 값 타입을 만드는 스타일 참조로 해석했다. 배치가 의도와 다르면 조정 필요.
2. `_maybePruneCache`의 임계값(쓰기 16회, 5분)은 브리프·컨트롤러 룰링 양쪽에 하드코딩된 리터럴로 명시되어 "명명된 상수 외 리터럴 금지" 셀프리뷰 규칙과 형식상 충돌한다 — 룰링이 리터럴 자체를 지정했으므로 그대로 따랐다. 별도 명명 상수(`_pruneWriteThreshold`, `_pruneMinInterval`)로 승격할지는 추후 스타일 판단.
3. 스로틀 카운터(`_cacheWritesSincePrune`, `_lastPruneAt`)는 정적 상태라 테스트 간 격리가 안 된다 — 이번 태스크의 3개 테스트는 `_cacheAndWrap`을 거치지 않고 `pruneCacheStrict`/`pruneCacheBestEffort`를 직접 호출해 문제가 없었지만, 향후 `_cacheAndWrap` 경로를 도는 테스트가 늘어나면 카운터 리셋 훅이 필요할 수 있다.

## ⑧ 셀프리뷰

- 중괄호: `flutter analyze` 0 issues로 구문 확인 완료(중괄호 불일치는 파싱 단계에서 즉시 에러가 되므로 analyze 통과가 곧 검증).
- 리터럴: 80MB 총 예산은 어디에도 재하드코딩하지 않고 `_maxCacheTotalBytes` 상수 하나만 사용(`budget = maxBytes ?? _maxCacheTotalBytes`). 스로틀 리터럴(16, 5분)은 ⑦-2 참조.
- `.part` 제외: 필터가 `entity.path.endsWith('.mp3')`이므로 `*.mp3.part`는 이 조건을 만족하지 않아 스캔·삭제 후보에서 자동 배제됨 — 테스트로 실측 확인(`tts_v3_female_dddd.mp3.part`가 살아남음).
- strict/best-effort 쌍: `pruneCacheStrict`는 예외를 전파(디렉터리 조회 실패 시 `FileSystemException` 그대로 던짐), `pruneCacheBestEffort`는 `try/catch(_){}`로 전부 삼킴 — `clearCacheStrict`/`clearCache` 패턴과 동형.
- 정적 디렉터리 비의존: `pruneCacheStrict`/`pruneCacheBestEffort`는 `directory` 매개변수만 사용하고, null일 때만 기존 `_strictCacheDirectory()`(캐시된 `_cacheDir` 필드를 재사용하는 기존 헬퍼, `clearCacheStrict`와 동일 폴백)로 위임 — 함수 본문 내부에서 `_cacheDir`를 직접 읽거나 쓰지 않음.

## Fix round 1

**대상:** 컨트롤러 룰링 — Important 결함(부분 스캔 오류가 전체 eviction pass를 무산시킴 + 동시 실행 가드 부재) + ⚠ 파일명 글롭 갭(bare `.mp3` 대신 `tts_v3_` 접두사 계약 미반영).

**변경 (`lib/services/tts_service.dart`):**
1. `pruneCacheStrict` 진입 시 `_pruneInFlight` 플래그 체크 — 이미 진행 중이면 스캔·삭제 없이 즉시 `0` 반환. `try/finally`로 플래그를 세팅·해제(디렉터리 레벨 실패로 조기 리턴해도 finally가 항상 해제).
2. 스캔 루프에서 `entity.uri.pathSegments.last`로 베이스네임을 뽑아 `name.startsWith('tts_v3_') && name.endsWith('.mp3')`로 필터(브리프의 bare `endsWith('.mp3')`를 대체) — `.part`는 여전히 `.mp3`로 끝나지 않아 구조적으로 제외.
3. `entity.stat()`를 항목별 `try/catch`로 감싸 실패 시 그 항목만 스킵(스캔 도중 사라진 파일 대응). `stat.size < 0`(Dart의 notFound sentinel)도 스킵.
4. `entry.file.delete()`도 항목별 `try/catch`로 감싸 실패 시 그 항목만 건너뛰고(freed에 미가산) 나머지 eviction을 계속 진행 — 더 이상 하나의 delete 실패가 전체 pass를 던지지 않는다. 디렉터리 레벨 실패(`dir.list()` 자체가 던지는 경우, 예: 디렉터리 없음)는 여전히 그대로 전파(test 3 계약 유지).
5. 스로틀 리터럴을 `static const int _pruneWriteThreshold = 16;`, `static const Duration _pruneMinInterval = Duration(minutes: 5);`로 승격하고 `_maybePruneCache`가 이를 참조하도록 변경.
6. `@visibleForTesting static void resetPruneStateForTesting()`(in-flight 플래그 + 스로틀 카운터 리셋)과 `@visibleForTesting static void setPruneInFlightForTesting(bool value)`(느린 디렉터리를 흉내내지 않고 in-flight 가드를 결정적으로 검증하기 위한 세터)를 추가 — 룰링이 "테스트가 필요로 하는 것 이상은 공개하지 않는다"고 명시했고, 룰링 자체가 "세터로 플래그를 설정해 가드를 검증하라"고 지시했으므로 세터도 필요분으로 판단.

**변경 (`test/tts_cache_prune_test.dart`):**
- 기존 3개 테스트 무수정.
- `tearDown`에 `TtsService.resetPruneStateForTesting()` 추가(정적 in-flight 플래그가 테스트 간 누수되지 않도록).
- 신규 테스트 4번째: `setPruneInFlightForTesting(true)` 설정 후 `pruneCacheStrict` 호출 → `freed == 0`, 파일 미삭제 확인, 플래그 원복.
- 신규 테스트 5번째(글롭 계약): `tts_v3_` 접두사가 없는 `.mp3`(`other_app_cache.mp3`, 가장 오래된 mtime)와 `tts_v3_` 파일을 함께 두고 `maxBytes: 0`으로 강제 prune → `freed == 500`(tts_v3_ 파일만), `other_app_cache.mp3`는 살아남고 `tts_v3_female_aaaa.mp3`만 삭제됨을 확인. 개별 stat/delete 실패 경로는 파일시스템 레이스를 결정적으로 재현하기 어려워 룰링이 명시한 대로 테스트를 요구하지 않았다(스킵 대상으로 확인).

**재실행 결과:**
- `flutter test --no-pub test/tts_cache_prune_test.dart --reporter expanded` → 5/5 PASS(기존 3 + 신규 2).
- `flutter test --no-pub test/account_cleanup_test.dart test/tts_cache_key_test.dart test/tts_bundled_manifest_test.dart test/tts_premium_only_test.dart --reporter expanded` → 35/35 PASS(동결 계약 "resolver source preserves bundle, disk, Storage, callable order" 포함 무수정 GREEN).
- `flutter analyze --no-pub`(포그라운드) → `No issues found!` (105.6s).

**커밋:** `3addf832` — `fix(tts): 캐시 prune을 항목별 오류 격리·동시 실행 가드·tts_v3 파일명 계약으로 보강 (Task 6 fix round 1)`. 로컬 커밋만, push/PR 없음.

**미해결/우려:** 없음. 룰링 5개 항목 모두 문자 그대로 반영했고 가드 4개 파일 전부 1회차에 통과했다.
