# T2.6 — 대사 카드 책갈피 (지시서 1.24 파생, §9-2 룰링)

커밋: `1db223ce` feat(scenario): 대사 카드에 단어장 책갈피 버튼 추가

## Diffstat

```
 lib/screens/scenario_player_screen.dart | 14 ++++++++
 test/scenario_player_ui_test.dart       | 61 +++++++++++++++++++++++++++++++++
 2 files changed, 75 insertions(+)
```

## 앵커 재검증

브리프는 `_buildDialog`를 ~L1349+, 어휘 행 `AddToWordbookButton(compact: true)`를 L1292-1296으로
가리켰다. 실측: `_buildDialog`는 L1387, 어휘 행 버튼은 L1330-1335 — T2.1-T2.5로 소폭 이동,
앵커 결함 아님. `DialogLine` 모델(`lib/models/scenario.dart:80`)에 `de`/`en` 필드가 직접
있어 브리프 지정대로 `translationDe: line.de, translationEn: line.en`을 그대로 씀.
`AddToWordbookButton` 생성자(`lib/widgets/sori/wordbook_add.dart:200-213`)는
`korean`·`translationDe` required, `translationEn`/`compact` 등은 기본값 있음 —
브리프가 준 4개 파라미터로 충분.

## 설계 결정 — 카드 범위

`_buildDialog`의 대사 줄은 두 분기로 갈린다: 내레이터(`isNarrator`)는 `SoriSpeakable` +
단순 `Text`(카드 아님, `Column`도 없음)이고, 일반 대사는 `SoriCard`의 `child: Column(...)`.
브리프의 "each dialog line **card**'s Column"을 문자 그대로 따라 **SoriCard 분기에만**
버튼을 추가했다 — 내레이터 줄은 애초에 대상 Column이 없다. 버튼은 Column의 마지막
child로 `Align(alignment: Alignment.centerRight, ...)`로 감싸 카드 우측 하단에 배치
(브리프가 지정한 위젯 파라미터 4개는 변경 없음, Align은 레이아웃 배치일 뿐).

## RED/GREEN 로그

**호스트**: `test/scenario_player_ui_test.dart`(기존 `_pumpPreview(stage: ScenarioStage.dialog)`
헬퍼와 `stubSoriSpeech()` 관례를 그대로 재사용 — 지시된 "vocab-row 테스트의 fake 재사용"을
탐색했으나 scenario_player 쪽에는 vocab-row 전용 wordbook 테스트가 없었고(전 코드베이스
검색으로 확인), `AddToWordbookButton`을 실제로 검증하는 기존 테스트들
(`wordbook_bookmark_fill_test.dart` 등)은 진짜 mock/fake 없이 실제 `CustomPackService` +
`SharedPreferences.setMockInitialValues` 조합을 쓴다 — 그 확립된 패턴을 그대로 채택함
(브리프의 "reuse its fake" 문구는 실제로는 없는 fake를 가리킨 사실 오류로 판단, 동등한
검증력의 기존 관례로 대체).

1. **RED** (`대사 카드 책갈피 탭은 quickAdd 1회`, `대사 카드 본문 탭은 여전히 발화를
   1회 추가한다` 두 건 모두, 소스 변경 전): `find.byIcon(Icons.bookmark_add_outlined).first`가
   위젯 트리에 없어 `StateError: Bad state: No element`.
2. **구현**: `_buildDialog` SoriCard 분기 Column 끝에 버튼 추가.
3. **GREEN**: 두 테스트 모두 통과.

### 테스트 (a) — 책갈피 탭

- `_pumpPreview(stage: ScenarioStage.dialog)` 진입 시 T2.1 자동재생이 이미 첫 대사
  (`officer`, `'여권 보여주세요.'`)를 1회 읽음 → `stub.spoken == ['여권 보여주세요.']`로 시작.
- `find.byIcon(Icons.bookmark_add_outlined).first`(첫 대사 카드의 책갈피) 탭.
- `CustomPackService.getById(quickPackId)!.words`에서 `korean == '여권 보여주세요.'`인
  항목이 정확히 1개 — quickAdd 1회 증거.
- `stub.spoken`이 탭 전후로 불변(`['여권 보여주세요.']` 그대로) — 책갈피 탭이 카드
  `onTap`(재생) 아레나로 전파되지 않았다는 직접 증거.

### 테스트 (b) — 카드 본문 탭

- 동일 진입(자동재생 1회 후 `stub.spoken == ['여권 보여주세요.']`).
- `find.bySemanticsLabel(RegExp(r'^Aussprache: 여권 보여주세요\.'))`(카드 본문, 시맨틱
  라벨은 SoriCard 전체에 있음) 탭.
- `stub.spoken == ['여권 보여주세요.', '여권 보여주세요.']` — 탭 1회가 발화를 정확히
  1건 추가함(카드 재생 계약 불변 확인).

## 개별 실행 결과

| 파일 | 결과 |
|---|---|
| `test/scenario_player_ui_test.dart` (전체) | 12/12 GREEN (회귀 없음, 신규 2건 포함) |
| `test/content_audio_policy_guard_test.dart` | 8/8 GREEN |
| `test/auto_speech_test_stub_guard_test.dart` | 1/1 GREEN |
| `test/accessibility_guideline_test.dart` | 55/55 GREEN |

`flutter analyze --no-pub`: **0 issues** (16.9s). `git diff --check`: 클린.

## 예상 밖 가드 실패

없음. `content_audio_policy_guard_test.dart`/`auto_speech_test_stub_guard_test.dart`는
`scenario_player_screen.dart`가 이미 두 가드의 대상·스텁 목록에 있어 이번 변경으로
새로 걸리지 않았다.

`accessibility_guideline_test.dart`는 covers하지만(그리드에 `'scenario player vocabulary'`
항목 존재) 그 항목은 `ScenarioStage.vocab`만 펌핑한다 — 새 북마크 버튼이 사는
`ScenarioStage.dialog`는 그 매트릭스에 없어 이번 변경을 직접 검증하지 않는다. 브리프의
"if it covers the scenario player; else skip" 조건은 "커버함"이므로 그대로 실행했고
55/55 GREEN(회귀 없음)을 확인했지만, dialog 스테이지 커버리지 자체는 이 태스크 범위
밖이라 확장하지 않았다 — 매트릭스 확장이 필요하면 별도 작업으로 제안한다.

## 의문 (≤3)

1. 브리프의 "vocab-row 테스트의 fake 재사용" 지시는 실제로 존재하지 않는 fake를
   가리켰다(코드베이스에 `AddToWordbookButton`을 mock 없이 실제 서비스로 검증하는
   기존 관례만 있음) — 사실 오류로 판단하고 그 확립된 실제-서비스 패턴으로 대체함.
   승인 시 이 판단에 이의가 없는지 확인 요청.
2. `accessibility_guideline_test.dart`의 scenario player 항목이 dialog 스테이지를
   포함하지 않아 새 북마크 버튼의 터치영역/대비/라벨을 그 매트릭스가 직접 검증하지
   않는다 — 매트릭스 확장은 범위 밖으로 보고 넘어갔다(별도 태스크 후보).
