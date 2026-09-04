# T2.4 report — Diktat 한국어 뜻 (지시서 4.13, §9-3 룰링)

커밋: `6c9cb310` (feat(diktat): 완료 후 의미 보기에 한국어 쉬운 풀이(promptKo) 추가 (지시서 4.13))
호스트 파일 결정: 브리프는 `quest_engines_uiux_test.dart` 또는 `diktat_quest_test.dart` 중 "기존 diktat 하네스가 있는 쪽"을 고르라고 했다.
`diktat_quest_test.dart`가 이미 `_host()` 헬퍼 + `DiktatQuest`를 직접 pumpWidget하여 정답/오답
제출 후 리뷰 카드 상태를 검증하는 그룹(`DiktatQuest canonical Korean review`)을 갖고 있어 — 이번
작업(완료 후 의미 보기 토글의 상태 전이)과 정확히 같은 종류의 단위라 이 파일을 선택했다.
`quest_engines_uiux_test.dart`는 7엔진 공통 뷰포트/정답효과/간격 매트릭스 위주라 부적합.

## 사실 재검증 (브리프 앵커 대비 실측)

- `diktat_quest.dart` `_promptDe`/`_promptEn`: 브리프 L319-320 → 실측 **L321-322** (T2.1-T2.3에서 2줄
  밀림). `_meaning()`: 브리프 L377-381 → 실측 **L379-384**. 의미 보기 토글: 브리프 L588-603 → 실측
  **L587-606**(구현 전). `_completed`: L311(불변).
- 리뷰 토글은 구현 전엔 `_completed`와 무관하게 항상 보였고, 열리면 버튼 라벨 자체가
  `_meaning(langCode)`로 바뀌는 방식이었다(별도 텍스트 줄 없음) — 브리프가 요구하는 "완료 후에만
  버튼 노출 + 열면 DE/EN 줄 + KO 줄"과 계약이 달라 의도된 변경으로 구현.
- `validate_content.py`: 브리프 L1732 → 실측 diktat 분기는 **L1732-1743**(`_require_fields`
  호출은 L1733). `promptKo` 키 없음 확인.
- arb: `diktatMeaningKo` 없음 확인(브리프와 일치).

## 구현

- `_promptKo` getter 추가(`diktat_quest.dart:328`): `(widget.data['promptKo'] as String?)?.trim() ?? ''`.
- 의미 보기 토글을 `if (_completed) ...[` 로 감싸 미완료 시 버튼 자체가 트리에서 빠짐(기존엔
  항상 존재) — `key: const ValueKey('diktat-meaning-toggle')` 추가.
- 열림 상태(`_showMeaning`)는 버튼 라벨이 아니라 버튼 아래 별도 `Column`으로 분리:
  기존 DE/EN 텍스트(`_meaning(langCode)`, 라벨 없음, 기존 계약 유지) + `_promptKo.isNotEmpty`일 때만
  `t.diktatMeaningKo` 라벨 텍스트 + `Text(_promptKo, key: ValueKey('diktat-meaning-ko'))`.
- 클래스 상단 data-schema 문서에 `promptKo` 예시·§9-3 설명 추가(동작 변경 없음, 문서만).
- arb `diktatMeaningKo` 추가: de "Auf Koreanisch" / en "In Korean" + `@diktatMeaningKo` description.
  `flutter gen-l10n` 실행 — 생성 diff 20줄(arb 4+4, generated 3개 파일 3+3+6), 그 외 무변경.
- `validate_content.py`: `_validate_diktat_prompt_ko(source, label, data)` 신설, diktat 분기에서
  `_validate_accepted_variants` 다음 호출. 키 없으면 통과(선택 필드) → 있으면 비어있지 않은 문자열
  검사 → `targetKo`와 strip 비교 동일하면 `"promptKo must differ from targetKo"` issue.

## TDD RED/GREEN

1. **arb 스캐폴딩 선행**: `t.diktatMeaningKo` getter 없이는 테스트가 컴파일조차 안 되므로,
   arb 키 + `flutter gen-l10n`을 테스트 작성보다 먼저 실행(동작 변경 없는 순수 코드생성 — RED의
   일부로 취급, "구현"은 아래 위젯/검증기 변경).
2. `test/diktat_quest_test.dart`에 신규 그룹 `DiktatQuest meaning toggle (지시서 4.13, §9-3, T2.4)`
   5건 추가, `setUp(() { stubSoriSpeech(); })`를 파일 top-level에 추가(diktat는 `initState`에서
   자동재생 — 상시 규칙).
   - RED 1회차: `flutter test --no-pub test/diktat_quest_test.dart` → 24/29 GREEN, **4건 FAIL**
     (전부 `diktat-meaning-toggle` 키를 못 찾음 — 구현 전이라 정상). "완료 전 토글 없음" 케이스는
     구현 전에도 통과(키 자체가 없어 vacuous) — 의도된 관찰, 아래 GREEN에서 게이팅 로직으로 재검증됨.
   - 구현(위 섹션) 적용 후 재실행: 27/29 GREEN, 1건 FAIL — `find.descendant(of: byKey(koLineKey),
     matching: find.text(promptKo))`가 0건(키를 가진 위젯 자신은 자신의 descendant가 아님 — 테스트
     버그, 구현 결함 아님). `tester.widget<Text>(find.byKey(koLineKey)).data == promptKo`로 수정.
   - 최종: `flutter test --no-pub test/diktat_quest_test.dart` → **32/32 GREEN**.
3. `tools/content_factory/test_validate_content.py`에
   `test_dictation_prompt_ko_is_optional_but_must_differ_from_target` 추가(promptKo 없음/유효/
   targetKo와 동일/공백 4케이스). RED: 단독 실행 → `AssertionError: False is not true`
   (targetKo와 동일해도 issue 없음 — 검증기 미구현). 구현 후 모듈 전체
   (`python -m unittest tools.content_factory.test_validate_content`) → **15/15 OK**
   (`test_current_repository_content_passes` 포함 — 실제 콘텐츠에 회귀 없음).

## 검증 (개별 실행, 지시대로 병렬 아님)

- `flutter test --no-pub test/diktat_quest_test.dart` → 32/32 GREEN.
- `flutter test --no-pub test/quest_engines_uiux_test.dart` → 32/32 GREEN(회귀 없음).
- `flutter test --no-pub test/content_audio_policy_guard_test.dart` → 9/9 GREEN.
- `flutter test --no-pub test/arb_l10n_guard_test.dart` → 9/9 GREEN(DE/EN 대칭·복수형·dash 포함).
- `flutter test --no-pub test/arb_orphan_key_guard_test.dart` → 1/1 GREEN(신규 키는 `diktat_quest.dart`
  에서 `t.diktatMeaningKo`로 참조되어 고아 아님 — 래칫 319 불변, 상향 없음).
- `flutter test --no-pub test/auto_speech_test_stub_guard_test.dart` → 1/1 GREEN(추가 안전 확인 —
  브리프 목록엔 없지만 diktat 위젯 테스트를 건드렸으므로 자체 판단으로 실행).
- `flutter analyze --no-pub` → **0 이슈**(20.2s).
- `python -m unittest tools.content_factory.test_validate_content` → **15/15 OK**.
- `git diff --check` → 클린(공백 오류 0).

예상 밖 가드 실패: 없음.

## Diffstat

```
lib/l10n/app_de.arb                            |   4 +
lib/l10n/app_en.arb                            |   4 +
lib/l10n/generated/app_localizations.dart      |   6 ++
lib/l10n/generated/app_localizations_de.dart   |   3 +
lib/l10n/generated/app_localizations_en.dart   |   3 +
lib/screens/quest_engines/diktat_quest.dart    |  79 ++++++++++----
test/diktat_quest_test.dart                    | 138 ++++++++++++++++++++++++-
tools/content_factory/test_validate_content.py |  60 +++++++++++
tools/content_factory/validate_content.py      |  20 ++++
9 files changed, 297 insertions(+), 20 deletions(-)
```

## 의문 (≤3)

1. §9-3 룰링은 "완료 후에만 노출"만 명시하고 KO 줄의 정확한 시각 배치(라벨 위/값 아래 2줄 vs.
   한 줄 결합)를 규정하지 않아, DE/EN 줄과 동일한 무라벨 스타일에 KO만 라벨(`diktatMeaningKo`)을
   붙이는 비대칭 레이아웃이 됐다 — PR4 크롬 정리 때 재검토 여지.
2. `promptKo`가 실제 콘텐츠(assets/data 시나리오)에 아직 하나도 없어(W9-C 백필 대기) 위젯 테스트는
   전부 인라인 픽스처로만 검증했다 — 실제 시드 데이터 통합 시 첫 실사용 사례가 될 것.
3. `_validate_diktat_prompt_ko`의 "다르다" 판정은 `strip()` 비교만 한다(문장부호/띄어쓰기 차이는
   서로 다른 문장으로 간주) — `acceptedVariants`처럼 자모 근접도까지 볼지는 §9-3에 명시가 없어
   최소 계약으로 구현.
