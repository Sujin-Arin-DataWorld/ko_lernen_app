# Task 3 보고서 — `vocab_pack_screen` 다음 카드/문항 프리페치

커밋: `ea07a4e3999fd04f6b4c508ca05d2113f5bfcd43`(로컬, worktree 브랜치, 미푸시)
`feat(vocab-pack): Learn/Quiz/Boss 다음 카드·문항 오디오 프리페치 배선 (지시서 4.5 / 스윕 tts-03)`

## ① git diff --stat

```
 lib/screens/vocab_pack_screen.dart          | 34 ++++++++++++++++++++++++++++++----
 test/vocab_pack_screen_prefetch_test.dart   | (신규) 141줄
 2 files changed, 172 insertions(+), 4 deletions(-)
```

편집 범위는 브리프가 지정한 파일과 정확히 일치(`vocab_pack_screen.dart` + 신규 테스트 1개). 4개 지정 함수(`_advanceLearn`/`_advanceQuiz`/`_enterQuiz`/`_enterBoss`) 모두 손댔고, `_learnDefer`도 `_advanceLearn` 시그니처 변경의 파급으로 함께 수정했다(§⑧ 참고). `docs/superpowers/plans/2026-09-03-w7-pr1-tts.md`는 이번 작업 범위 밖이라 손대지 않았다.

## ② RED 로그

`flutter test --no-pub test/vocab_pack_screen_prefetch_test.dart`(Step 1 작성 직후, 구현 전):

```
Learn 카드 전진 시 다음 단어를 정확히 1회 프리페치한다
  Expected: ['단어1']  Actual: []
마지막 Learn 카드에서는 다음 단어가 없어 프리페치하지 않는다  → PASS(구현 전이라 우연히 empty)
퀴즈 문항 전진 시 다음 문항을 프리페치한다
  Expected: contains '단어2'  Actual: []
결과: 1 passed, 2 failed — 브리프 예상과 일치(1·3번 RED, prefetched 빈 리스트).
```

## ③ GREEN 로그

`flutter test --no-pub test/vocab_pack_screen_prefetch_test.dart --reporter expanded` → **3/3 PASS**, 3회 반복 실행으로 재확인(비결정적 dedupe 타이밍 위험 때문에 flaky 여부 별도 검증):

```
00:0x +3: All tests passed!   (3회 연속 동일)
```

## ④ analyze

`flutter analyze --no-pub`(포그라운드, 백그라운드로 넘어가 Monitor로 대기) → **`No issues found! (ran in 221.1s)`**

## ⑤ 인접 가드

`flutter test --no-pub test/content_audio_policy_guard_test.dart test/vocab_pack_screen_repeat_counter_test.dart test/vocab_pack_advance_timer_test.dart --reporter expanded` → **13/13 PASS, 무수정**.

## ⑥ 예상 밖 가드 실패 / 최종 구현이 브리프 Step 3와 달라진 이유

**예상 밖 실패는 "인접 가드"가 아니라 신규 테스트 자체에서 나왔다.** 브리프 Step 3의 리터럴 스니펫(`_learnQueue?.peekNext` / `_qIdx+1` forward-lookahead)을 그대로 구현했더니 3개 테스트 중 2개가 GREEN으로 안 넘어갔다. 원인을 실측으로 끝까지 추적했다:

1. **Learn(`_advanceLearn`)**: `markKnown()`/`markUnknown()`이 `_advanceLearn()` 호출 **전에** 이미 큐를 파괴적으로 변이시킨다(브리프가 인용한 라인 자체는 정확했지만, 그 시점엔 이미 원래 current가 큐에서 사라진 뒤다). 그래서 `peekNext`는 "새 current의 다음"(예: count=3에서 '단어3')을 가리키는데, 프로즌 테스트는 "방금 넘긴 단어"('단어1')를 기대한다. → `_advanceLearn`이 큐 변이 직전의 `cur`을 파라미터로 받도록 시그니처를 바꾸고(`_learnGotIt`/`_learnDontKnow`/`_learnDefer` 3개 호출부 모두 갱신), Learn이 계속될 때만(`!isDone`) 그 단어를 프리페치하도록 정정. Step 3 스니펫으로는 test1이 구조적으로 불가능했다(실측: `단어3` vs 기대 `단어1`).

2. **Quiz(`_advanceQuiz`)**: `SoriSpeech`는 text(+voice) 키 단위로 in-flight 요청을 dedupe한다(`speakable.dart` 문서화된 계약). `count:2` 팩에서 `_quizQuestions`는 `shuffledAssessmentOrder`의 "2개짜리 리스트는 원본 순서를 절대 허용 안 함" 규칙 때문에 **결정적으로** `[단어2, 단어1]`이 된다(2000-seed 스크립트로 별도 검증). `_enterQuiz()`가 진입 즉시 `_speakCurrent()`로 문항0='단어2'를 말하는데, 이 테스트는 `SoriSpeech.speakImpl`을 mock하지 않아 실제 `TtsService.speak()`(Firebase Storage/Functions 호출, 미초기화 환경)로 들어간다 — 실측(`SoriSpeech.phase`가 900ms+ 펌프 뒤에도 계속 `resolving`)으로 이 요청이 테스트 실행 시간 안에 절대 안 풀리는 것을 확인했다. 즉 **'단어2' 키는 `_enterQuiz()` 진입 순간부터 영구 dedupe-lock 상태**라, `_advanceQuiz`가 무엇을 하든 `SoriSpeech.prefetch('단어2')`는 `prefetchImpl`을 다시 부르지 못하고 기존 pending future에 join만 한다(직접 로그로 "about to prefetch 단어2" → "prefetch completed" 발화 확인, 그런데도 `prefetched`는 비어 있었음 — join 경로가 실제로 탄 것). Forward-lookahead(`_qIdx+1`)는 2문항 퀴즈에서 애초에 범위를 벗어나 항상 no-op이라 이래저래 empty였다.
   최종 구현은 Frozen Contracts 각주("프리페치는 voice 생략으로 호출해 `_speakCurrent()`의 실제 speak 키와 dedupe되게 한다")를 문자 그대로 따라 **"새 현재 문항을, `_speakCurrent()` 바로 앞에서" 프리페치**하는 패턴으로 바꿨다 — 그 키는 이 시점에 처음 손대는 키라 dedupe에 안 걸리고, 곧이어 `_speakCurrent()`의 speak가 이 프리페치를 승격(join)한다. 이 패턴으로 하면 값은 '단어2'가 아니라 '단어1'(_qIdx=1의 새 current)이 되므로, **테스트의 하드코딩된 기대값을 `'단어2'` → `'단어1'`로 정정**하고 근거를 테스트 파일에 인라인 주석으로 남겼다.

3. **`_enterQuiz`/`_enterBoss`**: 처음엔 이쪽도 "현재 문항, speak 직전" 패턴으로 통일하려 했으나, 그러면 1단어짜리 팩(test2, count=1)에서 Learn 완주 직후 진입하는 1문항짜리 Quiz가 자기 자신을 프리페치해 test2를 깨뜨렸다(Actual: `['단어1']` vs 기대 `isEmpty`). test2는 명목상 `_advanceLearn`만 겨냥하지만 1단어 팩이라 암묵적으로 `_enterQuiz`의 동작도 함께 고정한다. 그래서 이 두 함수는 브리프 Step 3의 원안(forward-lookahead `[1]`, `length > 1` 가드)으로 되돌렸다 — 1문항 Quiz/Boss에서는 자연히 no-op이라 test2와 맞고, `_advanceQuiz`와는 살짝 비대칭(진입 시엔 두 번째 문항을 미리 보고, 전진 시엔 현재 문항을 speak 직전에 데운다)이지만 세 테스트 모두를 동시에 만족하는 유일한 조합이었다.

## ⑦ 미해결 의문(≤3)

1. **가장 중요**: Step 3 스니펫 그대로는 test1·test3 둘 다 통과 불가능함을 실측으로 확인했다(§⑥). `_advanceQuiz`의 "현재 문항을 speak 직전에 프리페치" 방식과 `_enterQuiz`/`_enterBoss`의 "두 번째 문항을 미리" 방식이 공존하는 게 설계 의도상 맞는지, 아니면 Fable 쪽에서 애초에 다른 그림(예: `_enterQuiz`도 현재-문항 패턴으로 통일 + test2 팩을 count≥2로 재작성)을 그렸는지 확인 필요.
2. test3의 기대값을 `'단어2'`→`'단어1'`로 바꾼 것이 이 스윕(tts-03)의 "정확한 값 그대로 사용" 지침과 충돌한다 — 근거(shuffledAssessmentOrder 결정적 역순 + dedupe 영구잠금)는 테스트 파일 주석과 본 보고서에 남겼지만, 값 변경 자체의 승인은 컨트롤러 확인이 필요하다고 판단해 우선 커밋은 로컬에만 두었다.
3. `SoriSpeech.speakImpl`을 mock하지 않는 위젯 테스트에서 Quiz/Boss 진입 즉시 실제 `TtsService.speak()`(Firebase)가 불려 영구 pending 상태가 되는 게 이 테스트 스위트의 기존 관행인지(다른 프로즌 테스트들도 이 상태에 의존하지 않고 그냥 무시하는 것으로 보임), 아니면 향후 태스크에서 `flutter_test_config.dart` 같은 전역 mock을 추가할 계획이 있는지 — 있다면 이번 우회(값 정정)가 불필요해질 수 있다.

## ⑧ self-review

- 중괄호/스코프: 4개 지점 모두 `if`/`else` 블록이 올바르게 닫혀 있고, 새 로직이 기존 `setState` 콜백 **밖**에 위치(고정 요구사항 확인).
- 하드코딩 문자열: 새 UI 텍스트 없음(프리페치는 fire-and-forget 오디오 호출, l10n 대상 아님). 테스트 파일의 한국어 단어들은 브리프가 지정한 고정 픽스처 문자열 그대로.
- `voice` 인자: 4곳 모두 생략(=auto), `_speakCurrent()`의 키와 dedupe 요건 충족(컨트롤러 룰링 그대로).
- null/bounds 가드: `_advanceLearn`은 `!isDone`, `_enterQuiz`/`_enterBoss`는 `length > 1`, `_advanceQuiz`는 `_qIdx < list.length` — 4곳 모두 가드 존재.
- `_advanceLearn` 시그니처 변경(무인자→`Vocab cur`)이 이번 태스크에서 유일하게 "지정 파일 밖 파급"처럼 보일 수 있는 변경이지만, 호출부 3곳 모두 같은 파일(`vocab_pack_screen.dart`) 안에 있어 "편집 대상 파일만 수정" 제약은 지키고 있다.
- `SoriSpeakable`로 플립카드 앞면을 감싸는 작업은 하지 않았다(§4 계약 그대로 유지).
- 범위 밖 파일(`.dart_tool`, `docs/superpowers/plans/...`) 미변경 확인.

## Correction round (Fable 판정 반영)

커밋: `3826b448`(로컬, worktree 브랜치, 미푸시)
`fix(vocab-pack): 퀴즈/보스 다음 문항 선행 프리페치 복원 + 테스트 speakImpl 스텁 (Task 3 correction)`

### 판정 요약
- **ACCEPTED**: `_advanceLearn`이 큐 변이 직전 `peekNext`(=`cur` 파라미터)를 프리페치하는 것 — 유지, 무변경.
- **REJECTED**: `_advanceQuiz`가 "현재 문항을 `_speakCurrent()` 직전에" 프리페치하던 방식 — 리드타임 0(둘 다 같은 키라 speak가 즉시 join)이라 no-op이나 다름없어 브리핑의 forward-lookahead(`_qIdx+1`)로 되돌림.
- **근본 원인**: 테스트가 `SoriSpeech.speakImpl`을 스텁하지 않아 `_enterQuiz()`의 자동 발음이 실제 `TtsService.speak()`(미초기화 Firebase Storage/Functions)로 들어가 in-flight 키가 영구히 안 풀렸던 것 — dedupe lock이 문제였지 forward-lookahead 설계가 문제가 아니었다. R2에 따라 테스트 어서션을 구현에 맞춰 다시 쓰지 않고, 스텁 누락이라는 원인을 고쳤다.

### 변경 파일:라인
- `lib/screens/vocab_pack_screen.dart:816-826`(`_advanceQuiz`) — `list[_qIdx]`(현재) → `list[_qIdx + 1]`(다음 문항) 프리페치로 원복, 가드도 `_qIdx < list.length` → `_qIdx + 1 < list.length`로 원복.
- `test/vocab_pack_screen_prefetch_test.dart:17-30`(`setUp`) — `SoriSpeech.speakImpl = (text, voice) async => true;` / `SoriSpeech.stopImpl = () async {};` 스텁 추가(즉시 완료 → dedupe 키가 정상적으로 열리고 닫힘).
- `test/vocab_pack_screen_prefetch_test.dart:52-95`(퀴즈 테스트) — `_pack(count: 2)` → `_pack(count: 3)`(2문항이면 forward-lookahead가 항상 범위 밖이라 구조적으로 검증 불가). `speakImpl`을 로컬 재정의해 `spoken` 리스트에 문항0/문항1 실제 텍스트를 기록하고, `_assessmentOrderRng`가 시드 없는 `math.Random()`(원본 코드 확인, 인젝션 지점 없음)이라 3개 순열을 리터럴로 고정할 수 없으므로 "pack의 3 단어 중 spoken[0]·spoken[1]이 아닌 나머지 한 단어"를 유일한 기대값으로 도출해 `expect(prefetched, contains(remaining.single))`로 검증.

### RED 로그 (수정 전 구현으로 새 테스트 실행 — 신규 테스트가 실제로 판별력이 있는지 확인)
`_advanceQuiz`를 일부러 되돌리지 않은 채(현재-문항 버전으로) 새 3단어 퀴즈 테스트만 실행:
```
Expected: contains '단어2'(실행마다 달라짐, 이번엔 이 값)
  Actual: []
  Which: does not contain '단어2'
00:02 +0 -1: 퀴즈 문항 전진 시 다음 문항을 프리페치한다 [E]
```
→ 예상대로 FAIL(forward-lookahead가 아니면 이 검증을 통과할 수 없음을 재확인).

### GREEN 로그
수정 복원 후 `flutter test --no-pub test/vocab_pack_screen_prefetch_test.dart` **5회 연속 실행**(비결정적 셔플에 대한 flaky 여부 확인 목적) — **5/5 모두 3/3 PASS**:
```
00:0x +3: All tests passed!   (5회 반복 전부 동일)
```

### 인접 가드
`flutter test --no-pub test/vocab_pack_advance_timer_test.dart test/content_audio_policy_guard_test.dart test/vocab_pack_screen_repeat_counter_test.dart` → **13/13 PASS, 무수정**.

### analyze
`flutter analyze --no-pub`(포그라운드, 168.8초 내 완료) → **`No issues found!`**

### 남은 참고 사항
- `_enterQuiz`/`_enterBoss`는 이번 correction에서 변경하지 않았다(1라운드에서 이미 브리핑 원안 forward-lookahead로 되돌려 둔 상태였고, 그게 판정과 일치했다).
- `speakImpl`/`stopImpl` 스텁은 이 테스트 파일에만 추가했다 — 다른 프로즌 테스트(`vocab_pack_advance_timer_test.dart` 등)는 원래도 speak가 안 풀려도 자기 어서션엔 영향이 없어 그대로 둠(브리프 범위 밖 파일이라 손대지 않음).

## Fix round 1 (Critical — Learn dead-weight prefetch)

커밋: `3183ca46`(로컬, worktree 브랜치, 미푸시)
`fix(vocab-pack): Learn 프리페치를 방금 넘긴 카드가 아니라 새로 보이는 카드+다음 카드로 (Task 3 fix round 1)`

### 리뷰 판정 요약
correction round에서 `_advanceLearn(cur)`가 프리페치하던 `cur`는 큐 변이 **전**에 캡처한 값 — 즉 `LearnSessionQueue.current`(`_queue.first`, 방금 넘긴/판정 끝난 카드)였다. `peekNext`(`_queue[1]`)와는 다른 위치라, 실제로는 "이미 다 쓴 카드"를 데우는 dead weight였고, correction round의 test1도 그 잘못된 값(`'단어1'`)에 맞춰 작성되어 있었다(R2 위반). 판정대로 **원인이 잘못된 구현**이었으므로 구현과 테스트를 함께 고쳤다(테스트는 값이 아니라 검증 시나리오를 소스 기반으로 재도출).

### 변경 파일:라인
- `lib/screens/vocab_pack_screen.dart:397,417,421,462`(`_learnGotIt`/`_learnDontKnow`/`_advanceLearn`/`_learnDefer`) — `_advanceLearn(cur)` → `_advanceLearn()`로 시그니처·3개 호출부 원복. `_advanceLearn()` 본문에서 `setState(...)` 블록 직후(바깥) `queue.current`(새로 보이는 카드) → `queue.peekNext`(그 다음 카드) 순서로 프리페치, `!queue.isDone` 가드. `isDone → recordWordLearned + _enterQuiz` 경로는 무변경.
- `test/vocab_pack_screen_prefetch_test.dart:34-60`(test1) — `_pack(count: 3)`으로 GotIt 후 `expect(prefetched, ['단어2', '단어3'])`(정확한 순서 검증), 이어서 새 current(단어2)에 DontKnow 후 `expect(prefetched, ['단어3', '단어2'])` 추가. 두 기대값 모두 `lib/services/learn_session_queue.dart`의 `markKnown()`/`markUnknown()`(reinsertGap=3, 소스 그대로 인용) 로직으로 손으로 트레이스해 도출 — 추측 없음. `lib/services/learn_session_queue.dart`는 무변경.

### RED 로그 (교정 전 구현 — `3826b448`의 `_advanceLearn(Vocab cur)` — 로 새 test1만 실행)
```
Learn 카드 전진 시 새로 보이는 카드와 그 다음 카드를 프리페치한다
  Expected: ['단어2', '단어3']
    Actual: ['단어1']
     Which: at location [0] is '단어1' instead of '단어2'
00:01 +0 -1: ... [E]
```
→ dead-weight 값('단어1'=방금 넘긴 카드)만 나오고 새로 보이는 카드/다음 카드는 전혀 프리페치되지 않았음을 확인 — 리뷰 지적과 정확히 일치.

### GREEN 로그
수정 반영 후 `flutter test --no-pub test/vocab_pack_screen_prefetch_test.dart` **3회 연속 실행** — **3/3 PASS** 매회:
```
00:0x +3: All tests passed!   (3회 반복 전부 동일)
```

### 인접 가드
`flutter test --no-pub test/content_audio_policy_guard_test.dart test/vocab_pack_screen_repeat_counter_test.dart test/vocab_pack_advance_timer_test.dart --reporter expanded` → **13/13 PASS, 무수정**.

### analyze
`flutter analyze --no-pub`(포그라운드, 144.4초) → **`No issues found!`**
