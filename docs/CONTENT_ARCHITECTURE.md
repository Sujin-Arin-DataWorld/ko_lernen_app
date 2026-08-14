# 콘텐츠 아키텍처 계약

> **상태:** C0 정본 · 2026-08-14
>
> 이 문서는 콘텐츠를 많이 추가하기 전에 지켜야 할 레벨 선택·코스 연결·검수
> 경계를 고정한다. C0는 서로 다른 학습 경험을 하나의 전역 레벨 정책으로
> 바꾸지 않는다.

## 1. 레벨 코드 경계

`Storage`에는 소문자 CEFR 코드(`a1`, `a2`, `b1`, `b2`)를 저장한다.
JSON 번들과 레벨 선택 UI는 파일별 관례에 따라 대문자(`A1` 등) 또는 소문자를
쓴다. 새 화면이나 로더는 둘을 직접 문자열 비교하지 않고 다음 경계를 거친다.

```dart
final level = learnerLevelForStoredCode(Storage.userLevelCode);
final display = level.display; // A1, A2, B1, B2
```

- `LearnerLevel.fromCode`은 대소문자를 허용하는 유일한 파서다.
- `learnerLevelForStoredCode`은 읽기 전용 기본값으로 `A1`을 준다. 값이 없거나
  잘못되었다고 해서 Storage에 `a1`을 쓰지 않는다. 온보딩 진입 판단에서는
  `Storage.userLevelCode == null`을 그대로 사용한다.
- 새 writer는 `LearnerLevel.code` 또는 소문자로 정규화한 값만 저장한다.
  특히 레거시 `setUserLevelCode`는 호출값을 자체 정규화하지 않으므로 호출자가
  이 계약을 지켜야 한다.
- 새 UI에서 `toUpperCase()`를 파서 대용으로 쓰거나 저장값과 대문자 JSON 키를
  직접 비교하는 코드는 추가하지 않는다.

## 2. Storage 키의 소유권

| 키 | 소유하는 상태 | 쓰기 경계 | 읽기 의도 |
| --- | --- | --- | --- |
| `userLevelCode` | 온보딩·계정의 레거시 학습자 레벨. `null`은 아직 레벨을 고르지 않았다는 뜻이다. | 온보딩/프로필과, 명시적 코스 배치의 호환 미러만 쓴다. 탐색 필터는 절대 쓰지 않는다. | 계정 레벨 잠금, C0의 초성·실벤·듣기·끝말잇기·발음 기본값, Today의 시나리오 적합성. |
| `placementLevelCode` | 순차 코스의 진단 또는 직접 시작 레벨. 값이 없으면 getter가 `userLevelCode`로 호환 폴백한다. | 코스 배치/숙달 서비스만 쓴다. 명시적 `setPlacementLevelCode`는 호환을 위해 `userLevelCode`도 미러한다. 실제 코스 배치가 존재하는지 판별할 때는 `dedicatedCoursePlacementLevelCode`를 쓴다. | 코스와 코스 기반 일일 학습의 기준 레벨. |
| `browseLevelCode` | 라이브러리에서 사용자가 고른 탐색 필터. 코스 진행과 독립이다. | 라이브러리 수준 선택만 쓴다. 이 키를 바꿔도 `userLevelCode`나 코스 배치를 바꾸지 않는다. | 단어팩·Cloze·Satz 등 탐색형 라이브러리의 처음 선택된 필터. |

라이브러리의 유효 시작 레벨은 `browseLevelCode ?? placementLevelCode`다.
`placementLevelCode` 자체가 레거시 `userLevelCode`로 폴백할 수 있으므로, 이는
온보딩 완료 사용자를 기존 콘텐츠에서 끊지 않는 호환 경로다. 반대로 코스가
실제로 시작되었다는 증거로 그 폴백을 사용하면 안 된다.

## 3. 선택 의미론: 화면별로 의도적으로 다름

| 의미론 | 계약 | 현재 사용처 |
| --- | --- | --- |
| **정확 일치** | 선택된 CEFR과 같은 레벨 항목만 기본 덱으로 쓴다. 해당 레벨이 비었으면 화면의 기존 빈/전체 폴백 규칙을 따르며, 다른 레벨을 조용히 우선하지 않는다. | C0: `ChosungQuizScreen`과 `SilbenKreuzScreen`은 `userLevelCode → LearnerLevel.display`를 초기 선택값으로 쓰고 각각 vocab `level`/실벤 JSON 레벨 키를 정확히 고른다. 라이브러리: Cloze·Satz는 `browseLevelCode ?? placementLevelCode`로 정확 필터를 시작한다. |
| **가까운 하위 폴백** | 먼저 정확 레벨을 고르고, 없으면 사용자보다 낮은 레벨 중 가장 높은 것을 고른다. 그마저 없을 때만 전체 playable 목록을 쓴다. | C0 `ListeningScreen`: 대사가 있는 시나리오만 대상으로 한다. B2에 B2 대사가 있으면 A1 첫 행이 앞에 있어도 B2를 고른다. |
| **누적** | `A1..현재 rank`를 함께 사용할 수 있다. 하위 레벨 복습이 학습 경험의 일부다. | C0 `KkeunmariEngine`의 시작·호랑이 응답, `PronunciationStudio`의 문장 목록. 기존 Daily Challenge도 `placementLevelCode` 이하를 캡으로 쓴다. |
| **rank 잠금** | 현재 레벨보다 높은 항목은 노출하되 시작/보상 근거가 될 수 없다. | `ScenariosListScreen`은 높은 CEFR 구역을 잠근다. Sori Stage Today의 `MissionRecommender`도 `scenario.level <= userLevel`일 때만 시나리오 미션을 반환한다. |

### C0의 누적 게임 세부 계약

- 끝말잇기는 시작 단어와 호랑이 응답을 `A1..userLevel` 후보에서 먼저 고른다.
  현재 사용 단어를 뺀 **실시간** 후보로 다음 연결 가능성을 계산한다. 번들 전체의
  `next_count`/`is_dead_end`를 레벨 부분집합의 진실로 재사용하지 않는다.
- 그 부분집합에 살아 있는 체인이 없을 때만 전체 풀로 폴백한다. 이 폴백은 B1/B2
  풀이 아직 희소해서 게임을 시작하지 못하는 문제를 막기 위한 것이며, 부분집합이
  가능할 때 더 높은 단어를 섞을 근거가 아니다.
- 사용자가 입력한 사전 단어의 전체 풀 검증은 기존 계약 그대로다. C0 스코프는
  호랑이가 생성하는 단어와 시작 단어의 난도 선택이지, 사용자 입력 사전을
  레벨별로 봉쇄하는 변경이 아니다.
- 발음 스튜디오는 현재 레벨 이하의 승인 문장을 모두 노출한다. 번들 로드가
  실패하거나 누적 목록이 비면 임의의 하드코딩 문장으로 폴백하지 않고 TTS/녹음
  동작을 막은 뒤 재시도를 제공한다.

## 4. 전역 통일 금지

정확 일치·누적·rank 잠금은 버그가 아니라 서로 다른 교육 목적이다. C0 이후에도
다음 변경은 금지한다.

- 모든 게임을 `userLevelCode` 하나의 exact 필터로 바꾸기
- 라이브러리의 `browseLevelCode`를 코스/Today/게임의 난이도 변경 신호로 쓰기
- 시나리오 잠금을 누적 게임의 폴백처럼 취급하기
- 데이터 부족을 이유로 저장된 사용자 레벨을 낮추거나 다른 키에 덮어쓰기

새 화면은 구현 전 이 표의 네 정책 중 하나를 선택하고, 입력 레벨·비어 있는
대상·폴백 결과를 단위 또는 위젯 테스트로 고정한다. 특별한 이유가 없으면
연습 라이브러리는 exact, 복습형 경험은 cumulative, 진입 제한은 rank-lock을 쓴다.

## 5. 후속 콘텐츠 병합의 그래프 계약

C1 이후 데이터는 `contentLinks`만 늘려서 코스에 연결하지 않는다.
`CurriculumCatalog`은 다음 서로 다른 선언을 합쳐 링크를 만든다.

| 콘텐츠 | 정본 연결 |
| --- | --- |
| vocab | `vocabPackUnitMap`의 pack → unit 매핑 |
| grammar | `grammarRuleMap`의 rule → unit/concept 매핑 |
| smalltalk | `smalltalkCategoryUnitMap`, 평가용으로 검수된 `smalltalkCheckpointPhraseMap` |
| cloze | `clozeTopicUnitMap`의 level/topic → unit 매핑 |
| satz | 같은 레벨의 `vocabKo`가 가리키는 vocab pack을 통해 파생 |
| scenario | 시나리오의 `courseUnitId`, `grammarIds`, concept/context와 unit checkpoint |

`contentLinks`는 명시적 보강 링크다. 현재의 명시적 항목은 시나리오 평가
checkpoint이며, 자동 매핑을 대신하는 범용 목록이 아니다. 신규 시나리오는
존재하는 grammar ID·course unit·concept을 참조해야 하고, 신규 Satz는 먼저 같은
레벨 vocab이 병합되어야 한다. 따라서 초안 작성은 병렬로 해도 실제 자산 병합은
어휘 기반 → 필요한 문법 → 시나리오/코스 → 게임 순서를 지킨다.

모든 병합 후에는 `CurriculumCatalog`의 orphan/unknown/ambiguous 검증과
`content_audit_manifest` 수량 검증을 함께 통과해야 한다.

### C1 Today 추천 수용 센서 (C0에서 예약)

C1이 실제 B1/B2 시나리오를 병합할 때에는 별도 서비스·위젯 센서를 추가한다.
최소 증거는 **B1 사용자 + 미완료로 병합된 B1 시나리오**에서 `TodayLearningSnapshot`이
그 시나리오의 유효한 destination을 만들고 Sori Stage Today가 그 추천을 표시한다는
것이다. C0는 존재하지 않는 시나리오나 코스 연결을 테스트 데이터에 섞어 이 조건을
가짜로 통과시키지 않는다. 이 센서는 실제 C1 레코드·course unit·grammar 참조가 모두
검수·병합된 뒤에만 작성한다.
