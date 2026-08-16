# 콘텐츠 아키텍처 계약

> **상태:** Batch 05 A1–C2 정본 · 2026-08-15
>
> 이 문서는 콘텐츠를 많이 추가하기 전에 지켜야 할 레벨 선택·코스 연결·검수
> 경계를 고정한다. C0는 서로 다른 학습 경험을 하나의 전역 레벨 정책으로
> 바꾸지 않는다.

## 1. 레벨 코드 경계

`Storage`에는 소문자 CEFR 코드(`a1`, `a2`, `b1`, `b2`, `c1`, `c2`)를 저장한다.
JSON 번들과 레벨 선택 UI는 파일별 관례에 따라 대문자(`A1` 등) 또는 소문자를
쓴다. 새 화면이나 로더는 둘을 직접 문자열 비교하지 않고 다음 경계를 거친다.

```dart
final level = learnerLevelForStoredCode(Storage.userLevelCode);
final display = level.display; // A1, A2, B1, B2, C1, C2
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
| **정확 일치** | 선택된 CEFR과 같은 레벨 항목만 기본 덱으로 쓴다. 해당 레벨이 비었으면 화면의 기존 빈/전체 폴백 규칙을 따른다. | `ChosungQuizScreen`, Cloze, Satz, 단어팩은 A1–C2 exact 필터를 쓴다. |
| **가까운 하위 폴백** | 먼저 정확 레벨을 고르고, 없으면 사용자보다 낮은 레벨 중 가장 높은 것을 고른다. 그마저 없을 때만 전체 playable 목록을 쓴다. | C1/C2 전용 데이터가 아직 없는 `ListeningScreen`, Today 시나리오, A1–B2 전용 `SilbenKreuzScreen`. |
| **누적** | `A1..현재 rank`를 함께 사용할 수 있다. 하위 레벨 복습이 학습 경험의 일부다. | C0 `KkeunmariEngine`의 시작·호랑이 응답, `PronunciationStudio`의 문장 목록. 기존 Daily Challenge도 `placementLevelCode` 이하를 캡으로 쓴다. |
| **rank 잠금** | 현재 레벨보다 높은 항목은 노출하되 시작/보상 근거가 될 수 없다. | `ScenariosListScreen`은 높은 CEFR 구역을 잠근다. Sori Stage Today의 `MissionRecommender`도 `scenario.level <= userLevel`일 때만 시나리오 미션을 반환한다. |

### C0의 누적 게임 세부 계약

- 끝말잇기는 시작 단어와 호랑이 응답을 `A1..userLevel` 후보에서 먼저 고른다.
  현재 사용 단어를 뺀 **실시간** 후보로 다음 연결 가능성을 계산한다. 번들 전체의
  `next_count`/`is_dead_end`를 레벨 부분집합의 진실로 재사용하지 않는다.
- 그 부분집합에 살아 있는 체인이 없을 때만 전체 풀로 폴백한다. 이 폴백은 고급 레벨
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

C1/C2 데이터는 `contentLinks`만 늘려서 코스에 연결하지 않는다.
`CurriculumCatalog`은 다음 서로 다른 선언을 합쳐 링크를 만든다.

| 콘텐츠 | 정본 연결 |
| --- | --- |
| vocab | `vocabPackUnitMap`의 pack → unit 매핑 |
| grammar | `grammarRuleMap`의 rule → unit/concept 매핑 |
| smalltalk | `smalltalkCategoryUnitMap`, 평가용으로 검수된 `smalltalkCheckpointPhraseMap` |
| cloze | `clozeTopicUnitMap`의 level/topic → unit 매핑 |
| satz | 같은 레벨의 `vocabKo`가 가리키는 vocab pack을 통해 파생 |
| scenario | 시나리오의 `courseUnitId`, `grammarIds`, concept/context와 unit checkpoint |

`contentLinks`는 명시적 보강 링크다. checkpoint는 `scenario`뿐 아니라 검수된
`grammar` 또는 `smalltalk` 같은 지원 콘텐츠 종류도 쓸 수 있지만, 선언된 unit과
required concept을 정확히 평가하는 immutable edge가 하나여야 한다. 자동 매핑을
대신하는 범용 목록이 아니다. 신규 시나리오는
존재하는 grammar ID·course unit·concept을 참조해야 하고, 신규 Satz는 먼저 같은
레벨 vocab이 병합되어야 한다. 따라서 초안 작성은 병렬로 해도 실제 자산 병합은
어휘 기반 → 필요한 문법 → 시나리오/코스 → 게임 순서를 지킨다.

모든 병합 후에는 `CurriculumCatalog`의 orphan/unknown/ambiguous 검증과
`content_audit_manifest` 수량 검증을 함께 통과해야 한다.

### 고급 레벨의 데이터 부재 센서

Batch 05는 C1/C2 vocab·grammar·smalltalk·Cloze·Satz와 코스 유닛을 제공하지만 전용
scenario와 실벤은 만들지 않았다. Today와 Listening은 가장 가까운 하위 시나리오를,
실벤은 가장 가까운 제공 레벨을 선택한다. 존재하지 않는 C1/C2 데이터를 테스트 fixture로
가짜 생성해 exact 콘텐츠처럼 보이게 하지 않는다. 전용 데이터가 실제 승인·병합되면
exact 선택 회귀 테스트를 추가하고 폴백을 그대로 유지할지 다시 결정한다.

## 6. CourseUnit 아래의 검증 가능한 수행 단위

`CourseUnit`은 경로·선행 조건을 위한 큰 주제 묶음이다. 콘텐츠 수나 난이도가 같은
영구 숙달 단위가 아니며, 그 ID를 한옥 보상이나 생산 능력 도장에 직접 쓰지 않는다.
영구 검증의 최소 단위는 `CanDoSegment`이고 세 책임은 다음처럼 고정한다.

| 계층 | 책임 | 영구 보상 판정 가능 여부 |
| --- | --- | --- |
| `CourseUnit` | 경로, 주제, 선행 조건, 현재 위치 | 불가 |
| 연습 콘텐츠와 `ContentLink` | 학습·복습 routing | 불가 |
| checkpoint | 교체 가능한 평가 수단 | 단독 불가 |
| `CanDoSegment` | 한 가지 can-do, 생산 rubric, 증거 revision | 가능 |
| Hanok grant | 검증된 segment의 시각적 투영 | 판정 권한 없음 |

published segment는 안정적인 ID, 정확한 parent unit과 CEFR, 필수 개념, 양수
`proofRevision`, `allOf` 생산 evidence 정책, immutable release track과 edition을
가져야 한다. `SegmentAssessmentAuthority`는 assessment ID만 확인하지 않고
mission content-link, level, CourseUnit, concept 집합, evidence mode, rubric version,
70% 이상의 minimum score, exact assess edge와 course eligibility를 모두 대조한다.
현재 평가가
바뀌어도 과거 ID는 `ownedAssessmentItemIds`에서 제거하거나 다른 segment에
재할당하지 않는다.
연습 routing은 segment 안의 고정 목록이 아니라 revisioned `ContentClusterDefinition`이
소유한다. 독립 창작 씨앗은 level이 고정된 typed `ContentSeedAuthority`로, 각 파생
참조의 실제 CEFR·`sourceSeedId`·`courseUnitId`는 typed
`ContentReferenceAuthority`로 검증하고, cluster seed 집합과 segment parent에 정확히
귀속되지 않은 파생 항목은 차단한다.
같은 can-do에 어휘·문법·대화·시나리오가 추가되면 cluster revision만
올리고 segment ID, edition, 보상과 분모는 바꾸지 않는다. 같은 construct의 평가를
개선할 때는 `proofRevision`을 올리되 이미 얻은 집을 취소하지 않고 최신 검증 상태를
별도로 보여 준다.

독립적인 새 can-do와 전용 생산 평가가 함께 생긴 경우에만 새 segment를 발행한다.
그 segment는 기존 published release track이나 edition에 삽입하지 않고 같은 CEFR의
새 extension `ReleaseTrackDefinition`과 edition에 속하며, 새 non-draft track의 순서는
기존 non-draft track의 최댓값보다 커야 한다. 첫 core release
`core_2026_v1`은 A1·A2·B1·B2·C1·C2 여섯
고정 edition의 합계 86개이며, 후속 UI는 `코어 86/86`과 `B2 확장 0/4`처럼
edition별 진행을 분리한다. 계속 커지는 catalog 전체 백분율은 사용자 완료율이나
한옥 권한으로 사용하지 않는다. retired segment도 삭제하지 않고 successor 계보와
과거 증거를 보존하며, 여러 번 교체된 경우 successor 체인 전체가 옛 slot의 대체
증거가 될 수 있다. 단, successor는 immutable `constructLineageId`가 같고 역방향
predecessor가 하나뿐인 선형 계보여야 한다. 제품 loader는 published
`core_2026_v1`을 레벨별 `16/16/18/20/8/8`, 총 86개로 fail-closed 검증하며 임의
core policy를 주입하는 우회 loader를 노출하지 않는다.

상황 씨앗 기반 제작에서는 `sourceSeedId`를 typed `ContentSeedAuthority`에 먼저
등록하고 segment나 reward ID로 쓰지 않는다.
같은 씨앗에서 파생된 시나리오·듣기·Satz·발음·Cloze·Smalltalk는 revisioned content
cluster로 묶고, 새 능력인지 여부는 별도 can-do와 생산 평가가 존재하는지로 판정한다.
C1/C2 각각 8개 목표도 CourseUnit 수가 아니라 core segment 수다. 게임별 레코드
충원량과 빈 화면 제거율은 콘텐츠 공급 KPI이며 published 진행 분모가 아니다.

기존 `completedUnitIds`는 새 segment의 생산 증거가 아니다. 재평가는 코스 포인터를
되감지 않고 segment 증거만 추가한다. browse, 단어팩, XP, placement bypass, Gye,
기존 한옥 단계는 segment를 검증할 수 없다. 전체 결정과 거부한 대안은
[`ADR-003`](ADR-003-can-do-segment-authority.md)에 기록한다.
