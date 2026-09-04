# T2.5 — Silben SoriSpeech 이관 (지시서 2.9 파생)

커밋: `9ad48c9c` refactor(silben): TtsService 직접 호출을 SoriSpeech로 이관 + 오디오 정책 가드 등록

## Diffstat

```
 lib/screens/silben_kreuz_screen.dart      | 5 +++--
 test/content_audio_policy_guard_test.dart | 1 +
 test/silben_grid_clue_sync_test.dart      | 3 +++
 3 files changed, 7 insertions(+), 2 deletions(-)
```

## 앵커 재검증

브리프는 `silben_kreuz_screen.dart:322-333`을 가리켰다. 실측 결과 `TtsService.speak(` 호출은
L330(주변 블록 L326-333)이었다 — T2.1-T2.4로 인한 소폭 라인 이동, 앵커 결함 아님. 호출은
정확히 1건(단어 완성 시 발화), `speakSlow` 사용 없음. `dart:async`는 이미 L1에 import되어
있어 `unawaited` 사용에 추가 import 불필요.

## 순서 및 RED/GREEN 로그

지시된 순서(targetScreens 추가 → RED → 소스 이관 → GREEN)를 그대로 따랐다.

1. **`test/content_audio_policy_guard_test.dart`**: `targetScreens`에
   `'lib/screens/silben_kreuz_screen.dart'` 추가.
   - RED: `학습 화면은 저수준 TtsService를 직접 참조하지 않는다` 실패
     (`Actual: ['lib/screens/silben_kreuz_screen.dart']`).
2. **`test/auto_speech_test_stub_guard_test.dart`** (targetScreens 확장의 부작용 — 예상된 2차 RED):
   `SilbenKreuzScreen`이 `screenClassNames`에 새로 편입되며
   `test/silben_grid_clue_sync_test.dart`가 신규 offender로 즉시 걸림
   (`stubSoriSpeech()`/`speakImpl =` 증거 없이 `pumpWidget(SilbenKreuzScreen(...))`).
   - RED: `자동 발화 화면을 pumpWidget하는 테스트는 SoriSpeech를 스텁한다` 실패.
   - 지시(R3: allowlist/cap 상향 금지, 대신 그 테스트 파일을 `stubSoriSpeech()`로 이관)에 따라
     `test/silben_grid_clue_sync_test.dart`의 `setUp`에 `stubSoriSpeech()` 호출 추가
     (+ `import 'support/sori_speech_stubs.dart';`).
   - GREEN 재확인.
   - 나머지 3개 silben-pumping 테스트(`c0_level_selection_test.dart`,
     `screen_smoke_test.dart`, `standalone_games_uiux_test.dart`,
     `study_activity_responsive_test.dart` — 4개)는 이미
     `knownUnstubbedTestFiles` 동결선에 있어 이번 변경으로 새로 걸리지 않음
     (사전에 allowlist 전수 대조로 확인).
3. **소스 이관** (`lib/screens/silben_kreuz_screen.dart`):
   - import: `../services/tts_service.dart` → `../widgets/sori/speakable.dart`
     (알파벳 정렬 위치 — `widgets/sori/` 그룹 내 `speakable`은 `screen_coach`와
     `spotlight_coach` 사이).
   - 단어 완성 발화: `TtsService.speak(` → `SoriSpeech.speak(`.
   - `dispose()`에 `unawaited(SoriSpeech.stop());` 추가(`_wrongFeedbackTimer?.cancel()` 다음,
     `super.dispose()` 이전).
   - GREEN: `content_audio_policy_guard_test.dart` 8/8 통과.

## 개별 실행 결과

| 파일 | 결과 |
|---|---|
| `test/content_audio_policy_guard_test.dart` | 8/8 GREEN |
| `test/auto_speech_test_stub_guard_test.dart` | 1/1 GREEN |
| `test/silben_grid_clue_sync_test.dart` | 6/6 GREEN |
| `test/silben_puzzle_spoken_test.dart` | 3/3 GREEN |
| `test/silben_puzzle_test.dart` | 3/3 GREEN |

`flutter analyze --no-pub`: **0 issues** (17.7s). `git diff --check`: 클린.

## grep 출력

```
$ git grep -n "TtsService" -- lib/screens/silben_kreuz_screen.dart
(빈 결과, exit 1)

$ git grep -n "TtsService" -- lib/screens/quest_engines/
(빈 결과, exit 1)
```

T2.1/T2.2가 5개 퀘스트 엔진(`hoerverstehen_quest.dart`, `luecken_quest.dart`,
`uebersetzen_quest.dart`, `particle_pop_quest.dart`, `diktat_quest.dart`,
`batchim_drop_quest.dart`)과 `quest_flow.dart`에 남긴 `TtsService` 리터럴 0건을 재확인함
(이번 태스크의 targetScreens 확장 전 전제조건).

## 예상 밖 가드 실패

`auto_speech_test_stub_guard_test.dart`가 targetScreens 확장의 부작용으로 즉시 RED에 걸린 것은
브리프 §"상시 규칙"과 T2.5 지시문이 명시적으로 예견한 경로였으므로 "예상 밖"은 아니다.
그 외 예상 밖 가드 실패 없음.

## 의문 (≤3)

1. 없음 — 브리프 앵커·순서·지시가 실측과 정확히 일치했다.
