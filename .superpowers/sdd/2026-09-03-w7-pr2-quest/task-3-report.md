# T2.3 리포트 — SoriGaps 8토큰 배선 (지시서 4.8/4.10)

커밋: `4741408a` (feat) — 브랜치 `claude/w7-pr2-quest-20260903`, HEAD 진입 시 `4382a8e8`.

## Diffstat

```
lib/screens/quest_engines/hoerverstehen_quest.dart |  4 +-
lib/screens/quest_engines/luecken_quest.dart       |  4 +-
lib/screens/quest_engines/particle_pop_quest.dart  |  4 +-
lib/screens/quest_engines/quest_flow.dart          | 12 +--
lib/screens/quest_engines/satz_bauen_quest.dart    | 10 +--
lib/screens/quest_engines/uebersetzen_quest.dart   |  4 +-
test/quest_engines_uiux_test.dart                  | 37 +++++++++
test/sori_gaps_usage_guard_test.dart               | 91 ++++++++++++++++++++++
8 files changed, 147 insertions(+), 19 deletions(-)
```

## RED → GREEN

1. **가드 드라이버** `test/sori_gaps_usage_guard_test.dart` (신규) — `tokens.dart`의
   `SoriGaps` 클래스 본문을 정규식으로 파싱해(`static const double (\w+) =`) 8토큰
   이름을 뽑고, `lib/` 안 `tokens.dart` 밖에서 `SoriGaps.<이름>` 참조가 ≥1인지
   검사한다. 리네임·추가가 있어도 하드코딩 목록이 낡지 않는다.
   - RED(배선 전): `8/8` 미사용 — `optionGap, cardGap, sectionGap,
     questionToOptions, labelToField, chromeToContent, headingToBody,
     paragraphGap`.
   - GREEN(배선 후): 1/1 통과.
2. `test/quest_engines_uiux_test.dart`에 신규 그룹 `SoriGaps.optionGap — 선택형
   퀘스트 4종의 옵션 타일 사이 간격은 12dp` — listening/translation/cloze/particle
   4개 엔진 각각 `answer-0`/`answer-1` 타일의 `getBottomLeft`↔`getTopLeft` y차를
   측정해 `moreOrLessEquals(SoriGaps.optionGap, epsilon: 0.5)`(=12) 단언. 4/4 GREEN.

## analyze

`flutter analyze --no-pub` (전체 프로젝트) → **No issues found!** (83.9s).

## 사이트별 표 — 무엇을 바꿨고 무엇을 의도적으로 남겼나

### (a) 옵션 타일 사이 간격 → `SoriGaps.optionGap` (8→12, 의도된 시각 변경)

| 파일 | 위치 | 이전 | 이후 |
|---|---|---|---|
| hoerverstehen_quest.dart | `for` 루프 안, `SoriAnswerTile` 다음 SizedBox | `Spacing.sm` | `SoriGaps.optionGap` |
| luecken_quest.dart | 〃 | `Spacing.sm` | `SoriGaps.optionGap` |
| uebersetzen_quest.dart | 〃 | `Spacing.sm` | `SoriGaps.optionGap` |
| particle_pop_quest.dart | 〃 | `Spacing.sm` | `SoriGaps.optionGap` |

### (b) 문제→옵션 간격 → `SoriGaps.questionToOptions` (=24, 대부분 무변경)

| 파일 | 위치 | 이전 | 이후 |
|---|---|---|---|
| hoerverstehen_quest.dart | 옵션 루프 직전 SizedBox | `Spacing.lg`(16) | `SoriGaps.questionToOptions`(24) |
| luecken_quest.dart | 〃 | `Spacing.lg`(16) | `SoriGaps.questionToOptions`(24) |
| uebersetzen_quest.dart | 〃 | `Spacing.lg`(16) | `SoriGaps.questionToOptions`(24) |
| particle_pop_quest.dart | TTS 버튼→옵션 루프 SizedBox | 원시 리터럴 `24` | `SoriGaps.questionToOptions`(24, 값 무변경) |

**브리프 결함 1**: 지시서 사실 섹션은 "문제→옵션 Spacing.lg (예: hoerverstehen
~L170)"만 인용해 사이트 목록이 hoerverstehen 1곳만 명시적이었다. 실측 결과
luecken·uebersetzen도 동일 패턴(`Spacing.lg` 직전 SizedBox)이었고, particle_pop은
`Spacing.lg`가 아니라 원시 `24` 리터럴을 쓰고 있었다(hint→sentence는 20, sentence→TTS
버튼은 16, TTS버튼→옵션은 24 — 전부 원시 리터럴). 4개 선택형 엔진(SoriAnswerTile
사용처) 전부에 일관 배선하는 것이 지시서 DO의 "4개 선택형 엔진" 문구와 부합한다고
판단해 particle_pop도 포함했다. particle_pop의 나머지 원시 리터럴(20, 16)은 이번
토큰 배선 범위 밖이라 손대지 않았다 — 20은 그리드 밖(spacing_literal_guard 기존
offender)이지만 T2.3 대상 사이트가 아니다.

### diktat_quest.dart — 브리프가 인용한 7개 Spacing.sm 사이트, 전부 미변경

지시서 사실 섹션은 `diktat L228/268/287/509/552/561/583`(앵커 `d120af87` 기준)를
"옵션 간격" 사이트로 인용했다. 앵커 커밋에서 실측하니(현재 파일과 바이트 동일,
T2.1/T2.2가 이 구간을 안 건드림) 7곳 전부 다음 역할이었다:

- 228, 561: 워드뱅크 칩(`tile()` 헬퍼) 내부 `EdgeInsets.symmetric` 패딩 — 칩 자체의
  안쪽 여백, 칩과 칩 사이 간격이 아니다.
- 268: "선택된 토큰" `Container`의 `EdgeInsets.all` 패딩.
- 287: "선택된 토큰" 박스 ↔ "남은 토큰" `Wrap` 사이 SizedBox — 두 **블록** 사이 간격이지
  타일 사이 간격이 아니다.
- 509: 오디오 버튼 2개(보통 속도/느린 속도) 사이 가로 SizedBox.
- 552, 583: 한국어 정답 리뷰 카드 앞/뒤 SizedBox.

diktat는 `SoriAnswerTile`을 전혀 쓰지 않는다(맞춤법 받아쓰기 — 워드뱅크 드래그 UI).
실제 칩-사이 간격은 `Wrap(spacing: Spacing.xs, runSpacing: Spacing.xs, ...)`이
담당하며, 이건 브리프가 인용한 `Spacing.sm` 리터럴이 아니다. 지시서 자체가
"읽어보고 옵션-리스트 간격이 아니면 남기고 사유를 밝혀라"라고 명시했으므로, diktat의
7개 사이트는 **의도적으로 전부 미변경**했다. **브리프 결함 2**로 판단.

### (c) 잔여 6토큰 → `quest_flow.dart` (지시서 4.8/4.10 "카드/라벨→필드/크롬→본문/
제목→본문/문단/섹션")

| 토큰 | 값 | 위치 (클래스 · 역할) | 이전 → 이후 |
|---|---|---|---|
| `chromeToContent` | 16 | `SoriPromptCard` — 스피커 아이콘(장식/크롬) → 텍스트 컬럼 | `Spacing.sm`(8) → 16 |
| `headingToBody` | 8 | `SoriPromptCard` — 문장(제목格) → "다시 듣기" 행(본문) | `Spacing.xs`(4) → 8 |
| `cardGap` | 16 | `SoriAnswerTile` — 인덱스 배지 → 라벨 텍스트 | `Spacing.sm`(8) → 16 |
| `labelToField` | 8 | `ScenarioQuestAction` — 대기 힌트 블록 → 제출 버튼 | `Spacing.sm`(8) → 8(무변경) |
| `paragraphGap` | 12 | `SoriAnswerTray` — 카드 자체 내부 패딩(`EdgeInsets.all`) | `Spacing.md`(12) → 12(무변경) |
| `sectionGap` | 24 | `ScenarioQuestAction` — 결과 메시지 블록 → 계속 버튼 | `Spacing.sm`(8) → 24 |

**신뢰도 노트(≤3 의문 중 1번 참고)**: `quest_flow.dart`는 화면이 아니라 퀘스트
공용 위젯 카탈로그라 "카드 사이"(카드-투-카드 나열)나 "폼 라벨→필드"(실제 TextField
없음)에 딱 맞는 사이트가 원천적으로 없다. `cardGap`은 `SoriAnswerTile`(그 자체가
하나의 "답 카드") 내부 배지→라벨 간격에, `labelToField`는 "힌트 텍스트(라벨격) →
제출 버튼(필드/조작격)" 전이 지점에 붙였다 — 값은 그대로 8이라 시각 변화는 없다.
`paragraphGap`도 마찬가지로 값 무변경. 이 3개는 "정확한 의미"보다 "가장 가까운 근사
+ 무변경"을 택해 리스크를 낮췄다. `cardGap`의 진짜 정본 사이트(카드 목록/피드)는 이
파일 밖에 있을 가능성이 높다 — 필요하면 후속 태스크로 재배치를 제안한다.

### satz_bauen_quest.dart

로컬 변수 `sectionGap` → 값 불변, 개명. 지시서가 지정한 이름은 `_compactGap`였으나
실측 결과 `no_leading_underscores_for_local_identifiers`(flutter_lints, info-level)에
걸려 `flutter analyze --no-pub 0` 게이트와 충돌했다(단독 파일 analyze에서
`no_leading_underscores_for_local_identifiers` + `unused_local_variable`
연쇄 확인). **브리프 결함 3**으로 판단해 언더스코어를 뺀 `compactGap`으로 최소
이탈 — 값·용도·`SoriGaps.sectionGap`과의 비충돌은 지시서 의도 그대로다
(`do NOT switch it to SoriGaps.sectionGap` 준수).

## 검증

- `flutter analyze --no-pub` (전체): **0 issues**.
- 지정된 5개 테스트 파일:
  - 개별 실행 전부 GREEN — `sori_gaps_usage_guard_test`(1), `quest_engines_uiux_test`(51),
    `spacing_literal_guard_test`(1), `typography_guard_test`(10),
    `content_audio_policy_guard_test`(8) = **71/71**.
  - 5개를 한 커맨드에 동시에 넘기면(`flutter test --no-pub <5개 경로>`) **러너가
    2개 파일(52개)만 실행하고 나머지 3개 파일을 조용히 건너뛰는 결함을 관찰**했다
    (exit 0, "All tests passed!"로 위장). `--concurrency=1`로 강제하면 71/71 전부
    실행·통과한다. 이건 이번 변경과 무관한 로컬 `flutter test` 샤딩 버그로 보이며,
    다음 구현자도 겪을 수 있어 기록해 둔다 — **다중 파일 검증 시 `--concurrency=1`
    권장**.
- `git diff --check`: 클린(LF/CRLF 경고만, 오류 없음).
- `spacing_literal_guard_test`(ceiling 181) GREEN — 이번 변경은 그리드 밖 리터럴을
  하나도 새로 만들지 않았다(모든 대상 값이 {8,12,16,24} 그리드 안).

## 골든 — CI 재생성 대상 없음

`test/goldens/*.dart`, `test/ildu_sarangchae_construction_pilot_test.dart`,
`test/sori_stage_visual_evidence_test.dart`(`matchesGoldenFile` 쓰는 전체 5개
파일)를 grep했지만 hoerverstehen/luecken/uebersetzen/particle_pop/diktat/
batchim_drop/satz_bauen/quest_flow 어느 위젯도 렌더링하지 않는다. `screen_layout_
golden_test.dart`·`sori_stage_visual_evidence_test.dart`에 나오는 `quests: const
[]`는 홈 화면 "오늘" 미션 진행 카드용 완전히 다른 위젯(빈 리스트로 고정)이라 이번
옵션 간격 변경과 무관하다. **결론: 이번 시각 변경(옵션 간격 8→12 등)을 커버하는
골든이 현재 스위트에 하나도 없다** — CI `regenerate-goldens` 대상 목록은 **없음**.
퀘스트 엔진 골든 커버리지 자체가 없다는 점은 별도 후속 과제로 보고한다(T2.3 범위
밖).

## 예상 밖 가드 실패

없음. `flutter test` 다중 파일 동시 실행 시 3개 파일이 조용히 스킵된 러너 결함은
"가드 실패"는 아니지만(개별/`--concurrency=1` 전부 GREEN) 위 검증 절에 기록했다.

## 열린 질문 (≤3)

1. `quest_flow.dart`의 `cardGap`/`labelToField`/`paragraphGap` 3개는 값이 그대로거나
   (`labelToField`, `paragraphGap`) 근사 위치(`cardGap`)라 시각적으로는 안전하지만,
   "카드 사이"·"폼 라벨→필드" 라는 토큰 이름의 문자 그대로의 의미와는 거리가 있다.
   quest_flow.dart가 화면이 아니라 위젯 카탈로그라 생기는 구조적 제약인데, Fable이
   더 정확한 정본 사이트(다른 화면)로 재배치를 원하는지 확인이 필요하다.
2. diktat 7개 사이트와 particle_pop의 questionToOptions 사이트는 브리프가 인용한
   줄 번호/사이트가 실제 역할과 어긋난 두 갈래 사실 오류였다(위 "브리프 결함 1·2").
   구현자 재량으로 판단해 처리했는데, 이 판단 자체를 승인 대상으로 다뤄줄지 확인
   부탁한다.
3. 퀘스트 엔진 화면들(hoerverstehen/luecken/uebersetzen/particle_pop/diktat/
   satz_bauen)에 골든 테스트가 전혀 없다 — 옵션 간격처럼 순수 시각 변경이 생겨도
   회귀를 잡을 안전망이 없다는 뜻이다. W7 PR2 범위에 골든 신설을 넣을지, 별도
   백로그로 뺄지 결정이 필요하다.

## Fix round 1 (Fable FIX-REQUIRED on 4741408a, 2026-09-04)

**판정**: 열린 질문 1번(quest_flow.dart의 cardGap/labelToField/paragraphGap 사이트가
토큰명 의미와 거리가 있다)이 정확했고, 지시서의 "잔여 6토큰을 quest_flow.dart 어딘가에
배선하라"는 지시 자체가 결함이었다고 Fable이 판정했다. 아래 4가지를 수정했다.

### 1. quest_flow.dart 6곳 전부 원복

`git diff 4382a8e8 -- lib/screens/quest_engines/quest_flow.dart` 로 원복 확인 —
T2.3 이전 baseline과 바이트 동일:

| 위치 | 되돌린 값 |
|---|---|
| `SoriAnswerTray` 카드 패딩 | `SoriGaps.paragraphGap` → `Spacing.md` |
| `SoriPromptCard` 아이콘→텍스트 | `SoriGaps.chromeToContent` → `Spacing.sm` |
| `SoriPromptCard` 문장→재생행 | `SoriGaps.headingToBody` → `Spacing.xs` |
| `SoriAnswerTile` 배지→라벨 | `SoriGaps.cardGap` → `Spacing.sm` |
| `ScenarioQuestAction` 힌트→제출버튼 | `SoriGaps.labelToField` → `Spacing.sm` |
| `ScenarioQuestAction` 결과→계속버튼 | `SoriGaps.sectionGap` → `Spacing.sm` |

유지: 4개 선택형 엔진(hoerverstehen/luecken/uebersetzen/particle_pop)의
`optionGap`/`questionToOptions` 배선, `satz_bauen_quest.dart`의 `compactGap`
개명, `quest_engines_uiux_test.dart`의 12dp 지오메트리 단언 4개.

### 2. SoriGaps 가드 재설계

`test/sori_gaps_usage_guard_test.dart`를 두 테스트로 재작성:

- `optionGap`/`questionToOptions`: **필수** — tokens.dart 밖 lib/에 참조 없으면
  즉시 실패(지시서 4.8/4.10의 실제 배선 대상).
- 나머지 6토큰: `test/auto_speech_test_stub_guard_test.dart`의
  `knownUnstubbedTestFiles`/`knownUnstubbedCap` 패턴을 그대로 미러링한
  `knownUnadoptedGaps`(6개, 알파벳순) + `knownUnadoptedCap`(=6) down-only
  래칫. 두 단언: (a) 허용 목록 밖에서 새 미채택 토큰이 생기면 실패,
  (b) 허용 목록의 토큰이 실제로 채택되면(더 이상 미사용이 아니면) 실패 —
  목록에서 지우고 캡을 낮춰야 통과한다. Doc comment에 자연 채택처 명시:
  W7 PR4 크롬(chromeToContent, cardGap), W8 폼(labelToField), 표준 페이지
  (sectionGap/paragraphGap/headingToBody) — 의미가 맞는 곳에서만 채택, 가드
  통과 목적의 임의 배선 금지를 재차 명시.

### 3. 검증

- 5개 파일 개별 실행(다중 파일 러너 결함 회피) 전부 GREEN:
  `sori_gaps_usage_guard_test`(2), `quest_engines_uiux_test`(32),
  `spacing_literal_guard_test`(1), `quest_explicit_flow_test`(31),
  `scenario_player_ui_test`(10) = **76/76**.
- `flutter analyze --no-pub` 전체: **0 issues**.
- `git diff --check`: 클린.
- **뮤테이션 체크**: 4개 선택형 엔진 전부에서 `SoriGaps.optionGap` 참조를
  일시 제거(lib/ 전체 참조 0으로 만듦) → 가드 FAIL 확인
  (`optionGap 는 지시서 4.8/4.10의 필수 배선 토큰인데 ... 참조가 없다`) →
  4개 파일을 커밋된 상태로 복원, 가드 재실행 GREEN 재확인. 단일 엔진
  1곳만 제거하는 뮤테이션은(요청 문구 그대로 해석하면) 나머지 3곳이 여전히
  참조를 남겨 가드가 실패하지 않는다 — 이건 "lib/ 전체에서 ≥1 참조"라는
  가드 설계 자체의 정상 동작이라 판단해 전체 제거로 뮤테이션을 강화했다.

### 커밋

`0f474698` — `fix(quest): quest_flow의 의미 불일치 토큰 치환 6곳 되돌림 +
SoriGaps 가드를 필수 2토큰·미채택 래칫으로 재설계 (Fable 리뷰)`.
