# Task 5 리포트 — 커스텀팩 타이핑 햅틱 + 마일스톤 levelUp SFX

## ① diffstat

```
 lib/screens/custom_pack_typing_screen.dart  |  3 ++
 lib/services/sound_service.dart             | 14 +++++++
 lib/widgets/sori/milestone_celebration.dart |  4 ++
 test/milestone_feedback_widget_test.dart    | 61 +++++++++++++++++++++++++++++
 test/custom_pack_typing_haptic_test.dart    | 86 +++++++++++++++++++++++++++++++++++++++ (신규)
```
(공개 API: `SoundService`의 기존 5개 메서드 `correct/wrong/combo/levelUp/complete` 시그니처 불변, 볼륨 리터럴 신규 없음.)

## ② RED

`flutter test --no-pub test/custom_pack_typing_haptic_test.dart test/milestone_feedback_widget_test.dart` (구현 전):
- `milestone_feedback_widget_test.dart`: 컴파일 실패 — `Setter not found: 'playImpl'` / `Member not found: 'resetForTesting'` (예상대로).
- `custom_pack_typing_haptic_test.dart`: 두 테스트 모두 `Expected: contains 'HapticFeedbackType.lightImpact'/'mediumImpact', Actual: []` — 예상대로 햅틱 리스트가 비어 실패.

## ③ GREEN

구현 후 재실행, 전부 통과:
```
test/custom_pack_typing_haptic_test.dart: 정답 제출은 lightImpact 햅틱을 낸다 — PASS
test/custom_pack_typing_haptic_test.dart: 오답 제출은 mediumImpact 햅틱을 낸다 — PASS
test/milestone_feedback_widget_test.dart: (기존 3개) — PASS
test/milestone_feedback_widget_test.dart: SoundService.levelUp은 level 마일스톤에서만 불린다 — PASS
```
합계 6/6.

## ④ analyze

`flutter analyze --no-pub` → `No issues found!` (40.0s). (1차 실행에서 브리프 코드 그대로 복제한 로컬 함수명 `_tapAndCollectHaptics`가 `no_leading_underscores_for_local_identifiers` 린트 1건을 냈다 — `tapAndCollectHaptics`로 리네임해 해결. ⑥ 참고.)

## ⑤ 인접 가드

`flutter test --no-pub test/audio_policy_guard_test.dart test/sound_channel_coverage_test.dart --reporter expanded` → 3/3 PASS. `sound_service.dart`에 볼륨 리터럴을 추가하지 않았으므로 래칫 무영향 확인.

## ⑥ 예상 밖 실패 (모두 브리프 코드 그대로 복제 시 발생 — 원인 확인 후 최소 수정)

1. **`custom_pack_typing_haptic_test.dart`의 팩 시딩**: 브리프 코드 블록은 `'kl_custom_packs_v1': packJson`(raw `Map`)을 그대로 `setMockInitialValues`에 넣지만, `CustomPackService._readRaw()`는 `Storage.customPacksRawJson`(String)을 `jsonDecode`한다 — raw Map을 넣으면 `_pack`이 null이 되어 `TextField`를 못 찾고 `enterText`가 "Bad state: No element"로 죽었다. `jsonEncode(packJson)`로 감싸 해결(브리프 본문이 명시한 "flipgate_test의 `kl_custom_packs_v1` 패턴 재사용"과 일치시킴).
2. **같은 테스트의 word 필드 키**: 브리프 코드는 `pos_de/translation_de/translation_en/example_korean/example_de/definition_ko/image_path/saved_to_pack_id`(snake_case)를 쓰지만, `ExtractedWord.fromLocalJson`(=`fromJson`)이 실제로 읽는 키는 camelCase(`posDe/translationDe/translationEn/exampleKorean/exampleDe/definitionKo/imagePath/savedToPackId`)다. snake_case로는 `translationDe/translationEn`이 빈 문자열로 파싱되어 `_pool`이 비고 "필요 단어 수 부족" empty-state가 렌더됨(디버그 프로브로 `TEXTFIELD_COUNT: 0` → `Schule` 텍스트 부재로 확인). camelCase로 교정해 해결.
3. **`milestone_feedback_widget_test.dart`의 신규 테스트, 두 번째 `openMilestone` 탭이 조용히 무효화됨**: 브리프 코드를 그대로 넣었을 때 테스트는 "통과"했지만 `tester.tap`이 `Warning: ... derived an Offset that would not hit test`를 냈다. 디버그 프로브로 `onPressed`에 `print`를 심어 확인한 결과 **두 번째 탭에서 콜백이 아예 호출되지 않았다** — 첫 `openMilestone`이 연 `showSoriSheet` 라우트가 `pumpWidget`을 다시 불러도(같은 위젯 트리 구조라 `NavigatorState`가 재사용됨) 남아 있어 `AbsorbPointer`가 두 번째 버튼 탭을 가로챈 것. 즉 `expect(played, isEmpty)`가 streak 케이스를 실제로 실행하지 않고도 우연히 통과하는 **거짓 양성**이었다. 두 `openMilestone` 호출 사이에 `await tester.pumpWidget(const SizedBox.shrink()); await tester.pump();`(파일 내 기존 "hidden Today" 테스트가 쓰는 동일 관용구)를 넣어 라우트를 완전히 정리 — 재검증 결과 두 번째 `onPressed`가 실제로 호출되고 경고도 사라졌으며, `played`가 진짜로 비어 있음을 확인.

## ⑦ 미해결 의문 (≤3)

1. 브리프 §1의 두 테스트 코드 블록(스텝1)이 위 ⑥-1/⑥-2/⑥-3 세 지점에서 실제 동작과 어긋났다 — 브리프 작성 시점 검증 안 된 스니펫으로 추정. 이번 구현에서 세 곳 모두 최소 수정으로 바로잡았고 의도(햅틱 순서/레벨 전용 게이팅)는 브리프와 동일하게 구현했다.
2. 없음.
3. 없음.

## ⑧ Self-review

- 중괄호: `if(ok){...}else{...}` 양쪽 다 완전한 블록, `if (milestone.type == MilestoneType.level) { SoundService.levelUp(); }`도 블록 형태 — 브리프 그대로.
- 볼륨 리터럴: `sound_service.dart` diff에 숫자 리터럴 없음(`_play` 시임 분기는 `hook(asset)`만 호출, `AudioPolicy` 게이팅 로직 이후 원본 그대로 보존). `audio_policy_guard_test` 그대로 통과.
- 순서: `custom_pack_typing_screen.dart`에서 `HapticFeedback.*Impact()` → `SoundService.correct()/wrong()` 순서로 `custom_pack_quiz_screen.dart:156-165`와 동일.
- level-only 게이팅: `MilestoneType.level`일 때만 `SoundService.levelUp()` 호출, streak/vocab은 무조건 무음 — 신규 테스트가 실제로 두 분기를 모두 실행함을 디버그 프로브로 검증(⑥-3).
- `SoundService` 공개 5메서드(`correct/wrong/combo/levelUp/complete`) 시그니처 불변. 신규 시임 `playImpl`/`resetForTesting`은 `@visibleForTesting`이며 null일 때 프로덕션 경로 바이트 동일(기존 `_play` 로직 이후 그대로).
- `custom_pack_typing_screen.dart`의 `TtsService.speak` 호출은 이번 작업 범위 밖 — 손대지 않음(컨트롤러 룰링).
