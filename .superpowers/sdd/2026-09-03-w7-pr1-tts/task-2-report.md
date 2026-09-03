# Task 2 보고서 — `SoriSpeech.phase` 승격 (인디케이터 3단)

커밋: `57fda129ebfa6cadb3b8d20f7cb2c9ca4415d416`
`feat(sori): SoriSpeech에 idle/resolving/speaking 3단 phase 승격 (지시서 4.3/4.5 / 스윕 tts-02)`

## ① git diff --stat

```
 lib/l10n/app_de.arb                          |  1 +
 lib/l10n/app_en.arb                          |  1 +
 lib/l10n/generated/app_localizations.dart    |  6 ++
 lib/l10n/generated/app_localizations_de.dart |  3 +
 lib/l10n/generated/app_localizations_en.dart |  3 +
 lib/widgets/sori/speakable.dart              | 85 ++++++++++++++++++++--------
 test/sori_speech_dedupe_test.dart            |  7 ++-
 test/speakable_screen_lifecycle_test.dart    | 13 +++--
 test/speakable_semantics_test.dart           | 24 +++++++-
 9 files changed, 110 insertions(+), 33 deletions(-)
```

Edit 범위는 브리프가 지정한 파일 집합과 정확히 일치한다(`speakable.dart` + 두 arb + 생성된 3개 l10n 파일 + 3개 테스트 파일). `docs/superpowers/plans/2026-09-03-w7-pr1-tts.md`는 untracked 상태로 존재하지만 이번 작업 범위 밖이라 손대지 않았다.

## ② RED 로그

`flutter test --no-pub test/speakable_semantics_test.dart test/speakable_screen_lifecycle_test.dart test/sori_speech_dedupe_test.dart` (Step 1 편집 직후, Step 4/5 구현 전):

```
test/speakable_semantics_test.dart:57:16: Error: Member not found: 'phase'.
    SoriSpeech.phase.value = TtsSpeechPhase.speaking;
               ^^^^^
test/speakable_semantics_test.dart:96:16: Error: Member not found: 'phase'.
    SoriSpeech.phase.value = TtsSpeechPhase.speaking;
               ^^^^^
test/speakable_semantics_test.dart:120:45: Error: The getter 'speechIndicatorResolving' isn't defined for the type 'AppL10n'.
    expect(node.getSemanticsData().value, t.speechIndicatorResolving);
                                            ^^^^^^^^^^^^^^^^^^^^^^^^
00:00 +0 -2: loading .../speakable_semantics_test.dart [E]  (컴파일 실패)

test/sori_speech_dedupe_test.dart:51:18: Error: Member not found: 'phase'.
      SoriSpeech.phase.value,
                 ^^^^^
00:00 +0 -2: loading .../sori_speech_dedupe_test.dart [E]  (컴파일 실패)

speakable_screen_lifecycle_test.dart는 컴파일은 통과했으나(당시 아직 TtsService.phase 참조뿐이라 정적 오류는 없음) 런타임 단언에서 실패:
  "화면 dispose 뒤 발화 완료는 UI 예외를 만들지 않는다"
    Expected: exactly one matching candidate
    Actual: _IconWidgetFinder:<Found 0 widgets with icon "IconData(U+0F800)"(hourglass_top_rounded): []>
    이유: "해석이 끝나기 전까지는 resolving 아이콘이어야 한다"
  "발화 실패는 예외를 누출하지 않고 인디케이터를 대기로 되돌린다"
    같은 사유로 hourglass_top_rounded 미검출

결과: 6 passed, 4 failed (2개 파일 로드 자체 실패 포함) — 브리프 예상(“getter 'phase' isn't defined” / “speechIndicatorResolving 미정의”)과 정확히 일치.
```

## ③ GREEN 로그(파일별 카운트)

`flutter test --no-pub --reporter expanded test/speakable_semantics_test.dart test/speakable_screen_lifecycle_test.dart test/sori_speech_dedupe_test.dart` → **전부 GREEN**, 총 19건(모두 PASS):

| 파일 | 테스트 수 |
|---|---|
| `speakable_semantics_test.dart` | 4 (기존 3 + 신규 resolving 케이스 1) |
| `speakable_screen_lifecycle_test.dart` | 8 |
| `sori_speech_dedupe_test.dart` | 7 |
| **합계** | **19 / 19 PASS** |

(참고: 기본 `compact` reporter로 비-TTY 파이프에 캡처하면 진행 표시줄 재작성이 중복 텍스트 줄로 남는 렌더링 아티팩트가 있어, 위 카운트는 `--reporter expanded`와 `--reporter json`(testDone 이벤트, `loading` hidden 항목 제외) 이중 확인으로 검증했다.)

## ④ analyze 출력

```
Analyzing w7-pr1-tts-20260903...
No issues found! (ran in 15.2s)
```

(포매팅 반영 후 재실행한 최종본. 최초 실행도 `No issues found!`였다.)

## ⑤ 인접 가드 2개

**가드 A** — `flutter test --no-pub --reporter expanded test/content_audio_policy_guard_test.dart test/review_session_screen_speakable_test.dart`
→ 8 + 3 = **11 / 11 PASS**. `content_audio_policy_guard_test.dart`는 `git diff --stat`에서 완전히 빠짐(무수정 확인).

**가드 B** — `flutter test --no-pub --reporter expanded test/arb_l10n_guard_test.dart test/l10n_parity_test.dart`
→ 8 + 4 = **12 / 12 PASS** (DE/EN 키 완전 대칭 단언 포함, 신규 `speechIndicatorResolving` 키가 양쪽에 있어 통과).

두 가드 모두 조합 실행(7개 파일 동시) 및 개별 실행에서 동일하게 GREEN 재확인했다.

## ⑥ 예상 밖 가드 실패

없음. 다만 작업 중 발견한 도구 특이사항 하나를 기록: `content_audio_policy_guard_test.dart` + `review_session_screen_speakable_test.dart` + `arb_l10n_guard_test.dart` + `l10n_parity_test.dart`를 **4개 한 번에** 넘기면 `review_session_screen_speakable_test.dart` 뒤에 오는 파일이 조용히 실행되지 않고(`All tests passed!`만 찍힘) 넘어가는 현상을 관찰했다 — flutter test의 비-TTY 컴팩트 리포터/파일 스케줄링 쪽 기존 이슈로 보이며, 이번 코드 변경과는 무관하다(review_session 파일을 마지막에 두거나 2개씩 나눠 돌리면 항상 정상 실행됨). 최종 검증은 `--reporter expanded`로 브리프가 지정한 정확한 조합(2+2)으로 재확인했으므로 Done criteria에는 영향 없음.

## ⑦ 미해결 의문 (≤3)

1. 브리프의 Open question 그대로: 인디케이터 알파(0.6)를 배지가 아닌 아이콘 자체(`SoriColors.contentCta.withValues(alpha: iconAlpha)`)에 건 선택이 "hourglass_top_rounded(반투명 0.6)" 의도와 정확히 일치하는지 설계자 확인 필요 — 브리프 Step 5 코드를 그대로 옮겼으므로 구현은 지시서와 100% 일치하지만, 시각 의도 확인은 별도.
2. `speakable_screen_lifecycle_test.dart`에서 `TtsService.phase.value = TtsSpeechPhase.speaking;`을 테스트가 직접 대입하는데, `resetForTesting()`은 `SoriSpeech.phase`만 idle로 되돌리고 `TtsService.phase`는 건드리지 않는다(Task 1 소관). 이번 스위트 안에서는 각 테스트가 stop/complete로 자연스럽게 정리되어 누수가 관측되지 않았지만, 향후 다른 테스트 파일이 `TtsService.phase`를 idle로 리셋하지 않은 채 끝나면 이후 파일에 잔여 상태가 넘어갈 이론적 여지는 있다 — Task 1 쪽 `resetForTesting`/global setUp 정책 확인 대상으로 남겨둠(이번 3개 파일 + 인접 가드 전부 GREEN이므로 즉시 조치는 불필요).
3. 없음(2건만 확인됨).

## ⑧ 자체 검토(self-review)

- **frozen contracts 무수정**: `content_audio_policy_guard_test.dart`는 `git diff --stat`에 전혀 나타나지 않음(완전 무수정). `int _generation`(L478, `ContentSpeechController`)은 이름·타입 그대로. `TtsService.stop()` / `didPushNext` 리터럴은 `ContentSpeechController` 클래스 docstring(L462, L464, L535)에 원문 그대로 남아있음. `RegExp(r'Map<String,\s*Future')` 대상인 `_inFlight`/`_promotionPrefetches` 등 맵 선언부는 건드리지 않음.
- **braces on if/else**: `SoriSpeechIndicator.handleTap`의 `if (phase != TtsSpeechPhase.idle) { ... } else { ... }`는 중괄호 사용. 신규 가드절(`_onEnginePhaseChanged`, `_bindEngineListenerOnce`의 `if (...) return;`)은 기존 파일 전반의 단일문 early-return 관례(중괄호 없음, 예: 기존 `speakSlow`의 `if (existing != null) return existing;`)를 그대로 따름 — `dart format`/`flutter analyze` 통과 확인.
- **no hardcoded strings**: 인디케이터의 신규 텍스트(`speechIndicatorResolving`)는 전부 `AppL10n`(`t.speechIndicatorResolving`)을 경유하며 하드코딩된 문자열 없음.
- **de/en both added**: `app_de.arb`에 `"speechIndicatorResolving": "Wird geladen"`, `app_en.arb`에 `"speechIndicatorResolving": "Loading"` 추가 확인. `flutter gen-l10n`으로 재생성한 `lib/l10n/generated/app_localizations*.dart` 3개 파일 모두 커밋에 포함. 다른 로케일 arb 파일은 프로젝트에 존재하지 않음(de/en만).
- **SoriSpeakable 미변경**: `git diff lib/widgets/sori/speakable.dart`의 훙크 목록을 확인한 결과 모든 변경은 `SoriSpeech`(L45~330 부근)와 `SoriSpeechIndicator`(L392~ 부근) 안에만 있고, `SoriSpeakable` 클래스(L347~378, §4 계약상 phase 비구독 대상)에는 훙크가 전혀 없음 — 여전히 `SoriSpeech.speak(text, voice: voice)`만 호출.
- 추가로 `dart format --set-exit-if-changed`를 돌려 `speakable.dart`/`speakable_semantics_test.dart`의 포맷 편차(주로 브리프 의사코드의 줄바꿈과 실제 dart formatter 출력 차이)를 발견해 `dart format`으로 정리했고, 재포맷 후 `flutter analyze`와 전체 GREEN 테스트를 재확인했다.

## Fix round 1

커밋: `fbe23bd7784418d2ac23c3c1e8a1f63585166a51`
`fix(tts): 재생 시작 콜백에 텍스트 식별자 — 무관한 재생이 인디케이터를 승격시키지 않도록 + resetForTesting에 엔진 phase 리셋 (Task 2 fix round 1)`

### 검토에서 나온 결함 2건

**Finding 1 (Important)** — `SoriSpeech._onEnginePhaseChanged`는 전역 `TtsService.phase`가 `speaking`으로 바뀌고 아무 `SoriSpeech` 키가 활성 상태이기만 하면 무조건 승격시켰다. 화면 어딘가에서 `TtsService.speak()`를 직접 부르는 무관한 재생(예: `review_session_screen.dart:527` 보너스 문구)이 시작돼도, 그때 마침 resolving 상태였던 다른 인디케이터가 잘못 speaking으로 승격됐다.

**Finding 2 (Important)** — `SoriSpeech.resetForTesting()`이 `TtsService.phase`를 리셋하지 않았다. `ValueNotifier`는 같은 값 재대입 시 리스너를 호출하지 않으므로, 어떤 테스트가 `TtsService.phase`를 `speaking`으로 남겨두면 다음 테스트에서 동일 값 재대입이 조용히 무시돼 승격 신호를 놓칠 수 있었다.

### 변경 파일:줄

- `lib/services/tts_service.dart`
  - L42: `typedef TtsPlaybackStarted = void Function(String text, String voice);` 신규(기존 `TtsErrorReporter` 타입 옆).
  - L286: `final TtsPlaybackStarted? onPlaybackStarted;` (기존 `VoidCallback?`에서 변경).
  - L394: `onPlaybackStarted?.call(trimmed, normalizedVoice);` — 엔진이 이미 정규화해 둔 `trimmed`/`normalizedVoice` 로컬 변수 사용.
  - L540: `static String? activeSpeechText;` 신규(`phase` 옆).
  - L563-566: 정적 엔진 배선 `onPlaybackStarted: (text, voice) { activeSpeechText = text; phase.value = TtsSpeechPhase.speaking; }`.
  - L633: `speak()`의 토큰 가드 `whenComplete` 안에 `activeSpeechText = null;` 추가(`phase.value = idle` 옆).
  - L743: `stop()` 안 `phase.value = idle` 옆에 `activeSpeechText = null;` 추가.
- `test/tts_premium_only_test.dart`
  - L225-259: 세 콜백을 2-인자 시그니처(`(text, voice) => calls.add(text)`)로 변경, `throwingCalls`/`startedCalls`/`missingCalls` 타입을 `<void>[]` → `<String>[]`로 변경. 성공 케이스는 `expect(startedCalls, ['x'])`로 trim된 텍스트 수신을 단언(테스트명도 "…텍스트와 함께 불린다"로 갱신).
  - L261-290: stop() 회귀 테스트에 `TtsService.activeSpeechText = '학교';` 준비 + `expect(TtsService.activeSpeechText, isNull)`을 동기 직후·await 이후 양쪽에 추가.
- `lib/widgets/sori/speakable.dart`
  - L77-82: `static String? _activeSpeechText;` / `static int _activeSpeechGeneration = 0;` 신규 필드(`_activeSpeechKey` 옆).
  - L61-75: `_onEnginePhaseChanged`를 텍스트+세대 대조로 교체 — `TtsService.phase.value == speaking && _activeSpeechText != null && TtsService.activeSpeechText == _activeSpeechText && _activeSpeechGeneration == _speechGeneration`일 때만 승격.
  - L112-124: `resetForTesting()`에 `_activeSpeechText = null;`, `TtsService.phase.value = TtsSpeechPhase.idle;`, `TtsService.activeSpeechText = null;` 추가.
  - `_publishSpeak` 발행부: `_activeSpeechText = text.trim();` / `_activeSpeechGeneration = generation;`를 `_activeSpeechKey = key;` 바로 뒤에 추가(엔진이 최종적으로 통보할 `trimmed` 텍스트와 정확히 같은 값을 미리 기록).
  - `_publishSpeak`의 `whenComplete` 클리어 분기, `stop()`: `_activeSpeechKey = null;` 옆에 `_activeSpeechText = null;` 추가.
- `test/speakable_semantics_test.dart`
  - 파일 끝에 신규 테스트 2건 추가: "무관한 엔진 재생은 resolving 인디케이터를 승격시키지 않는다" (`TtsService.activeSpeechText = 'B'`로 불일치 재현 → `SoriSpeech.phase.value == resolving` 유지 확인), "일치하는 엔진 재생은 speaking으로 승격한다" (`activeSpeechText = 'A'` 일치 → `speaking` 확인).
- `test/speakable_screen_lifecycle_test.dart` (계획에 없던 필수 추가 수정 — 아래 "예상 밖" 참고)
  - L136-139: `'화면 dispose 뒤 발화 완료는...'` 테스트에서 `TtsService.phase.value = TtsSpeechPhase.speaking;` 직전에 `TtsService.activeSpeechText = '학교';`를 추가해, host()가 렌더링한 텍스트('학교')와 일치하는 진짜 엔진 신호를 재현하도록 갱신.

### 커버 테스트 + 명령 + 출력

**1) `flutter test --no-pub --reporter expanded test/tts_premium_only_test.dart`** (기대: 11/11)
```
00:00 +11: All tests passed!
```
11/11 PASS — 텍스트 인자 전달·trim 확인·stop() 후 `activeSpeechText` null 확인 모두 포함.

**2) 세 Task 2 테스트 파일** (`speakable_semantics_test.dart` / `speakable_screen_lifecycle_test.dart` / `sori_speech_dedupe_test.dart`, 기대: 19 + 2 신규 = 21)
```
00:03 +21: All tests passed!
```
21/21 PASS.

(중간 경과: 최초 재실행에서 `speakable_screen_lifecycle_test.dart`의 "화면 dispose 뒤…" 테스트가 hourglass_top_rounded만 계속 보여 실패했다 — Fix round 1 이전에는 `TtsService.phase.value = TtsSpeechPhase.speaking;` 단독 대입만으로 승격됐지만, finding 1 수정 후에는 `TtsService.activeSpeechText`가 우리 요청 텍스트('학교')와 일치해야 승격되므로 그 대입이 빠진 이 테스트가 정확히 새 계약대로 "승격 안 됨"을 보여준 것 — 버그가 아니라 테스트가 실제 엔진 신호를 덜 정확하게 흉내 내고 있었을 뿐이다. 위 표의 마지막 수정으로 해결.)

**3) `flutter test --no-pub --reporter expanded test/content_audio_policy_guard_test.dart test/review_session_screen_speakable_test.dart`**
```
00:15 +11: All tests passed!
```
11/11 PASS(무수정 `content_audio_policy_guard_test.dart` 포함).

**4) `flutter analyze --no-pub`** (foreground)
```
Analyzing w7-pr1-tts-20260903...
No issues found! (ran in 210.3s)
```

### git diff --stat (Fix round 1만)

```
 lib/services/tts_service.dart             | 20 +++++++++++---
 lib/widgets/sori/speakable.dart           | 32 ++++++++++++++++++++---
 test/speakable_screen_lifecycle_test.dart |  4 +++
 test/speakable_semantics_test.dart        | 43 +++++++++++++++++++++++++++++++
 test/tts_premium_only_test.dart           | 35 ++++++++++++++++++-------
 5 files changed, 118 insertions(+), 16 deletions(-)
```

### 예상 밖 가드 실패

`speakable_screen_lifecycle_test.dart`의 "화면 dispose 뒤 발화 완료는…" 테스트가 finding 1 수정 직후 실패했다(위 ②에서 설명). 원인은 이 테스트 자체가 "엔진이 승격 신호를 보낸다"를 `TtsService.phase.value = speaking` 대입만으로 흉내 냈는데, finding 1 수정이 정확히 그 지점("텍스트가 실제로 일치하는가")을 엄격하게 만들었기 때문이다. 브리프/컨트롤러 지시 목록에는 없던 파일이지만, RE-RUN 기준("19+2=21 전부 GREEN")을 만족시키기 위해 `TtsService.activeSpeechText = '학교';` 한 줄을 그 테스트에 추가해 실제 엔진 신호를 정확히 재현하도록 고쳤다 — frozen contracts(`content_audio_policy_guard_test.dart`, `_generation`, docstring, `SoriSpeakable`)는 전혀 건드리지 않았다.

### 자체 검토

- **frozen contracts**: `content_audio_policy_guard_test.dart`는 `git diff --stat`에 여전히 나타나지 않음(무수정). `int _generation`(L505, `ContentSpeechController`)은 이름·위치 그대로. `lib/widgets/sori/speakable.dart`의 diff 훙크 6개는 전부 `SoriSpeech` 클래스 안(L60~354 부근)이고 `SoriSpeakable`/`ContentSpeechController` 쪽 훙크는 0개.
- **braces on if/else**: 이번 라운드에서 추가한 분기는 전부 기존 파일 관례대로 단일문 early-return(`if (...) return;`, 중괄호 없음)이거나 이미 중괄호가 있던 블록(`onPlaybackStarted: (text, voice) { ... }`)이다. `dart format`/`flutter analyze` 통과로 스타일 준수 확인.
- **no hardcoded strings**: 이번 변경은 로직/식별자 대조 코드이며 사용자 노출 문자열을 추가하지 않았다(신규 arb 키 없음).
- **de/en 해당 없음**: 이번 라운드는 텍스트/문구 변경이 없어 arb 갱신 대상 아님.
- 추가로 `dart format --set-exit-if-changed`로 이번 라운드가 건드린 5개 파일 모두 재확인 — 최초 편집 스크립트가 남긴 줄바꿈 편차를 `dart format`으로 정리한 뒤 전체 테스트·analyze를 재실행해 그린을 재확인했다.
