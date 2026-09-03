# Task 4 리포트 — 무음 표면 3곳 (vocab_notebook_result/studio, chosung_quiz)

## ① diffstat

```
 lib/screens/chosung_quiz_screen.dart          | 52 +++++++++++++++------------
 lib/screens/vocab_notebook_result_screen.dart |  9 ++++-
 lib/screens/vocab_notebook_studio_screen.dart |  9 ++++-
 test/content_audio_policy_guard_test.dart     |  3 ++
 4 files changed, 49 insertions(+), 24 deletions(-)

 신규: test/chosung_quiz_audio_test.dart     (65 lines)
 신규: test/vocab_notebook_audio_test.dart   (107 lines)
```

## ② RED

`flutter test --no-pub test/chosung_quiz_audio_test.dart test/vocab_notebook_audio_test.dart` (구현 전):

- `chosung_quiz_audio_test.dart`: "정답 전(waiting)…" PASS(원래도 `SoriSpeakable` 없음이 참) / "정답을 맞히면…" **FAIL** — `find.byType(SoriSpeakable)` 0개.
- `vocab_notebook_audio_test.dart`: 최초 컴파일 에러(`ExtractedWord` import 누락, `models/custom_pack.dart`가 아니라 `models/book_page.dart`)를 고친 뒤 재실행 → 두 테스트 모두 **FAIL** — `find.byType(SoriSpeakable)` 0개.

## ③ GREEN

구현(import + wrap) 적용 후:
`flutter test --no-pub test/vocab_notebook_audio_test.dart test/chosung_quiz_audio_test.dart` → **4/4 PASS**.

`chosung_quiz_audio_test.dart`의 두 번째 테스트는 `_submit()`이 예약하는
`Future.delayed(700ms, _next)` (정답 시 다음 문항 자동 진행)가 테스트 종료 시
"Timer is still pending" 프레임워크 불변식에 걸려 한 번 실패했다 — 브리프
스니펫에는 없던 후처리라서, 마지막 `expect(spoken, ['사과'])` 뒤에
`await tester.pump(const Duration(milliseconds: 750));`을 추가해 타이머를
흘려보내고 통과시켰다(제품 코드 변경 아님, 테스트 위생).

## ④ analyze

`flutter analyze --no-pub` → **No issues found!** (120.5s)

## ⑤ 인접 가드 2개

`flutter test --no-pub test/vocab_notebook_result_screen_test.dart test/vocab_notebook_studio_screen_test.dart` → **15/15 PASS**(무수정, 기존 `find.text(...)` 단언 안 깨짐).

`content_audio_policy_guard_test.dart`(targetScreens에 3파일 추가 후) →
새 테스트 2건 포함 12/12 PASS(TtsService 0건 화면 검사 통과).

## ⑥ 예상 밖 가드 실패

없음 — 위 ③의 타이머 이슈는 가드가 아니라 신규 테스트 자체의 정리 누락이었고, 테스트 파일 내에서 해결.

## ⑦ 미해결 의문

1. `vocab_notebook_audio_test.dart`의 정확한 `pumpWidget` 인자는 브리프가 열지 못했던 두 기존 테스트 파일(`vocab_notebook_result_screen_test.dart`/`vocab_notebook_studio_screen_test.dart`)에서 직접 확인해 옮겼다 — result 화면은 `MaterialApp(theme: AppTheme.light, locale: de, ..., home: VocabNotebookResultScreen(args: {'text': ...}))`, studio 화면은 `CustomPackService.save(...)` 후 `VocabNotebookStudioScreen(packId: ...)`. 두 화면을 각각 최소 하네스로 새 파일 하나에 합쳤다(브리프가 "두 화면을 띄운 뒤"라 했으므로).
2. `chosung_quiz_audio_test.dart`의 700ms 타이머 흘리기(`await tester.pump(750ms)`)는 브리프 스니펫에 없던 한 줄 추가다 — 순수 테스트 위생이라 화면 로직·프로덕션 계약과는 무관하다고 판단해 임의로 추가했다. 이견 있으면 되돌릴 수 있음.
3. (해당 없음)

## ⑧ 자기 점검

- 중괄호/스위치 화살표 형태 브리프 스니펫과 1:1 일치 확인(diff 대조).
- 하드코딩 문자열 신규 도입 없음(`SoriSpeakable(text: pair.korean/word.korean/word, child: ...)`만 추가).
- 3화면 모두 `TtsService` 리터럴 0건(구현 전/후 grep 확인, import/사용/주석 어디에도 없음) — targetScreens 추가는 이 확인 **이후**에 수행.
- 플립 카드 래핑 없음 — `_State.waiting`(정답 미노출) 분기는 그대로 `Text(...)`만 두어 정답 유출 없음. `vocab_notebook_result/studio`의 단어 행은 플립 카드가 아님(§4 계약과 무충돌, `SoriCard`에 `onTap` 미전달 확인).
- 브리프 목록 밖 파일 수정 없음, `speakable.dart` 무수정.
- 커밋은 Jin 요청 시에만 — 아직 미실행.
