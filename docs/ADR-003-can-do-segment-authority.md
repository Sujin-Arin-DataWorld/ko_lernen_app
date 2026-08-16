# ADR-003: 검증 가능한 CanDoSegment를 영구 숙달 권한으로 사용한다

- 상태: Accepted
- 결정일: 2026-08-16
- 적용 범위: A1–C2 순차 코스, 재평가, 살아 있는 한옥 보상 투영
- 기준 revision: `ee8282b9b73962b9c23a03748911cc6aaf32d55c`

## 배경

현재 `curriculum_manifest.json`에는 A1 16, A2 8, B1 6, B2 6, C1 2,
C2 2로 총 40개의 `CourseUnit`이 있다. 그러나 이는 같은 크기의 학습 능력 40개가
아니다. 레벨별 원본 콘텐츠와 단원 수는 다음처럼 크게 다르다.

| 레벨 | CourseUnit | 어휘 | 문법 | Smalltalk | 전용 시나리오 |
| --- | ---: | ---: | ---: | ---: | ---: |
| A1 | 16 | 211 | 32 | 64 | 15 |
| A2 | 8 | 271 | 41 | 57 | 15 |
| B1 | 6 | 281 | 41 | 52 | 16 |
| B2 | 6 | 329 | 46 | 80 | 12 |
| C1 | 2 | 48 | 8 | 16 | 0 |
| C2 | 2 | 48 | 8 | 16 | 0 |

PR #27은 B2·C1·C2에 각각 어휘 48, 문법 8, Smalltalk 16, Cloze 48,
Satz 48을 추가했다. Cloze와 Satz는 같은 어휘 예문에서 파생되므로 독립 능력
168개는 아니지만, C1/C2의 콘텐츠를 단원 두 개와 체크포인트 두 개만으로 증명할 수도
없다. 현재 고급 단원 네 개는 선택형 체크포인트 정답 네 번으로 모두 완료될 수 있다.

따라서 `CourseUnit`, 콘텐츠 레코드, 체크포인트 중 어느 것도 그대로 영구 숙달 또는
한옥 보상의 최소 단위로 사용할 수 없다.

## 결정

### 1. 세 가지 책임을 분리한다

- `CourseUnit`: 경로의 큰 주제, 선행 조건, 현재 위치를 소유하는 탐색 단위다.
- `CanDoSegment`: 한 가지 독립적인 실제 수행 능력과 그 생산 증거를 소유하는 숙달
  단위다.
- `HanokGrantDefinition`: 검증된 segment를 한옥의 구조·선택지·장소·분위기·자격
  보상으로 투영한다. 학습 판정 권한은 갖지 않는다.

원본 어휘팩, 문법, Smalltalk, Cloze, Satz와 시나리오는 segment의 연습 재료다.
그 콘텐츠를 보거나 개별 게임을 완료한 사실만으로 segment를 검증하거나 한옥 보상을
지급하지 않는다.

### 2. segment는 독립적인 생산 증거를 요구한다

published segment는 다음을 모두 선언해야 한다.

- 안정적인 `id`, `constructLineageId`, `parentCourseUnitId`, CEFR, 순서,
  다국어 can-do
- level이 고정된 typed `ContentSeedAuthority`, revisioned
  `ContentClusterDefinition`, seed·CourseUnit까지 정확히 귀속된 typed
  `ContentReferenceAuthority`
- 양수 `proofRevision`
- `allOf` 정책으로 결합한 하나 이상의 필수 생산 assessment
- assessment마다 정확한 assess edge, CourseUnit, concept, evidence mode,
  rubric version, 70% 이상의 `minimumScore`
- 해당 segment에 발행된 평가 정체성을 고정하는 immutable
  `ownedAssessmentItemIds`
- 단 하나의 `ReleaseTrackDefinition`과 immutable `TrackEdition`

인정 가능한 생산 모드는 `guidedProduction`, `dictation`,
`connectedProduction`, `openWriting`, `oralProduction`,
`connectedEvidence`다. Cloze·Satz·선택형 recognition은 연습과 피드백에는 쓸 수
있지만 단독 영구 증거가 아니다. 같은 평가를 서로 다른 segment가 중복 소비하지
않는다.

### 3. published release track과 edition은 append-only다

한 번 published가 된 `ReleaseTrackDefinition.editionIds`와
`TrackEdition.segmentIds`의 순서와 구성은 바꾸지 않는다. catalog에는 core track을
정확히 하나만 두며, 새 능력은 기존 core 또는 published extension에 edition을
끼워 넣지 않고 기존 non-draft track의 가장 큰 순서 뒤에 새로운 extension track으로
추가한다. 이 규칙으로 신규 콘텐츠가 생겨도 이미 완성한 여정의 100%와 한옥 보상이
내려가지 않는다.

제품 decoder는 non-draft `core_2026_v1`을 A1 16, A2 16, B1 18,
B2 20, C1 8, C2 8의 정확한 여섯 edition·총 86 slot으로 검증한다. 미완성
canonical core는 draft에서만 허용하며, 임의 core policy를 주입하는 public·test 전용
우회 API를 두지 않는다. 단위 테스트도 같은 86개 정본 계약을 사용한다.

오류가 있는 segment는 기록에서 삭제하지 않고 `retired`와
`successorSegmentId`로 계보를 남긴다. 연습 콘텐츠 보강은 cluster revision으로
허용하지만, 한 번 non-draft가 된 같은 segment ID의 `proofRevision`, evidence
policy, assessment requirements, `ownedAssessmentItemIds`는 함께 고정한다. 평가를
개선할 때는 기존 segment를 retired로 두고, 더 큰 `proofRevision`과 새 평가 정체성을
가진 동일 construct의 successor를 더 새로운 **replacement track**에 발행한다.
이미 획득한 옛 segment 증거는 계속 유효하며, 새 학습자는 replacement successor로
옛 edition slot을 채울 수 있다. successor가 다시 교체돼도 체인 전체를 따라 최종
published successor까지 인정한다. replacement edition은 새 can-do나 영구 보상
분모를 추가하지 않는다.
`constructLineageId`가 같은 segment만 successor가 될 수 있고, 한 successor는 단 하나의
predecessor만 가진다. 같은 construct의 non-draft 기록은 하나의 연결된 선형 chain을
이뤄야 하므로 무관한 새 능력 하나가 여러 과거 보상 slot을 대신할 수 없다.

### 3.1 계속 추가되는 콘텐츠는 세 가지로 분류한다

레벨별 데이터는 출시 뒤에도 계속 늘어날 수 있다. 새 레코드의 수가 진행률 분모를
결정하지 않도록 모든 추가분을 아래 순서로 판정한다.

| 추가 유형 | 계약 변경 | 과거 진행률·한옥 |
| --- | --- | --- |
| 같은 can-do의 어휘·문법·대화·게임·시나리오 보강 | 같은 `ContentClusterDefinition.id`의 `revision`과 콘텐츠 참조만 올린다. segment와 edition은 그대로다. | 변하지 않는다. 새 자료는 연습·복습 추천에만 들어간다. |
| 같은 can-do의 평가·rubric 개선 | 기존 segment를 retired로 보존하고, 같은 `constructLineageId`의 새 segment를 더 새로운 replacement track에 발행한다. successor는 더 큰 `proofRevision`과 새 assessment identity를 가진다. | 기존 slot·집·edition 완료는 유지한다. replacement 자체는 새 can-do·영구 보상 분모에 들어가지 않으며 UI는 최신 증거 여부와 재평가만 별도 표시한다. |
| 독립적인 새 can-do와 전용 생산 평가 추가 | 새 segment를 새 **additive per-level edition**에 발행한다. | 기존 edition의 분모와 100%는 고정된다. 새 보상은 별도 확장 여정으로 뒤에 붙는다. |

오탈자·번역·TTS 교정은 능력이나 cluster membership이 바뀌지 않으므로 segment나
edition을 만들지 않는다. raw 콘텐츠 수, pack 수, `CourseUnit` 수가 늘어난 사실만으로
새 segment를 생성하지도 않는다.

첫 core release는 `releaseTrackId=core_2026_v1` 아래 레벨별 여섯 edition으로
나눈다. 예를 들어 A1 edition 16개와 B2 edition 20개는 각각 고정 분모를 가진다.
나중에 B2 can-do 네 개가 추가되면 기존 B2 20개에 삽입하지 않고 별도
`b2_extension_*` edition의 `0/4` 여정으로 공개한다. UI는 `코어 86/86`과
`B2 확장 0/4`를 합쳐 하나의 계속 커지는 백분율로 표시하지 않는다.

현재 catalog 전체를 기준으로 한 커버리지 지표는 별도로 늘어날 수 있다. 그것은
콘텐츠 운영 지표이며 사용자가 완료한 edition 진행률이나 한옥 권한이 아니다.

### 3.2 상황 씨앗 기반 콘텐츠 공급 계획을 흡수한다

별도 감사 커밋 `a990d8a3`이 제안한 B1–C2 상황 씨앗 방식은 콘텐츠 생산
파이프라인으로 사용한다. 하나의 독립 창작 `sourceSeedId`에서 시나리오, 듣기,
Satz, 발음, Cloze, Smalltalk를 파생하되 다음처럼 권한을 분리한다.

- `sourceSeedId`는 level이 고정된 typed `ContentSeedAuthority`로 등록하고,
  파생 modality는 revisioned `ContentClusterDefinition`의 provenance와 연습
  routing으로 묶는다. 각 `ContentReferenceAuthority`는 자신의 `sourceSeedId`와
  `courseUnitId`를 선언하며 cluster seed 집합·segment parent와 정확히 일치해야 한다.
  씨앗은 영구 보상 ID가 아니다.
- C1/C2 각각 8개라는 목표는 우선 8개 `CanDoSegment`와 고유 생산 평가를
  뜻한다. 탐색 UX에 필요하다는 별도 근거가 없으면 `CourseUnit`을 8개로 늘리지 않는다.
- 선택·배열·빈칸으로 근사한 고급 활동은 practice evidence일 뿐이다. 영구 도장과
  한옥 보상은 typed productive assessment authority를 만족해야 한다.
- seed 수, 게임별 파생 레코드 수, 모든 게임의 빈 화면 제거율은 콘텐츠 공급 KPI다.
  core 86 또는 extension의 사용자 진행 분모가 아니다.
- 신규 seed를 발행할 때 먼저 기존 can-do 보강, 같은 평가 개정, 독립 can-do 중
  하나로 분류한 뒤 각각 cluster revision, replacement successor, 새 extension
  track을 쓴다.

Batch 06 review-only 커밋 `23342c57`의 standalone 68개와 scenario quest 20개는
현재 canonical 86, `ContentClusterDefinition`, assessment authority에 포함하지
않는다. live human review로 승인·승격된 뒤에도 같은 can-do의 practice라면 해당
cluster revision에만 append한다. pronunciation, Cloze, Satz, Smalltalk, scenario는
practice modality이며 자동으로 영구 assessment authority가 되지 않는다. B1 complaint
repair, B2 complaint escalation, C1 evidence limits, C2 technology appeal이라는
provisional scenario intent도 final review 전에는 routing authority가 아니다.

### 4. 구 진도로 새 segment를 자동 검증하지 않는다

기존 `completedUnitIds`와 체크포인트 선택 기록은 그대로 보존하지만 새
`verifiedCanDoSegmentIds`로 backfill하지 않는다. 현재 사용자가 적고 기존 한옥
호환 마이그레이션을 하지 않는다는 제품 결정을 따른다. 완료한 단원은 재평가 경로를
열 수 있으나, 새 생산 평가를 통과해야 segment 도장과 한옥 보상을 얻는다.

단어팩, XP, browse, placement bypass, Gye 진행, 기존 `HanokStage`와 과거 reveal은
새 segment 숙달의 입력이 아니다.

### 5. 첫 core release는 여섯 고정 edition, 합계 86개다

A1의 실제 건축은 16개의 눈에 보이는 공정으로 유지한다. 그러나 전체 segment 수를
레벨마다 16개로 맞추거나 현재 CourseUnit 40개에 맞추지는 않는다. 데이터 품질 감사로
첫 `core_2026_v1` release의 레벨별 edition 분모를 A1 16, A2 16, B1 18,
B2 20, C1 8, C2 8, 합계 **86개**로 결정한다. 80개는 B1/B2의 독립 산출물 여섯 개를 넓은
segment에 숨기므로 전체판이 아니라 명시적 MVP에서만 쓸 수 있다.

86개의 영구 segment ID는 다음 조건을 만족한 원본 평가·rubric과 함께 PR2에서 한
번에 동결한다.

- 모든 기존 연습 클러스터가 의미상 맞는 segment에 연결된다.
- 파생 Cloze/Satz를 독립 능력으로 중복 계산하지 않는다.
- 각 segment에 서로 다른 생산 평가와 rubric이 있다.
- C1/C2의 4단계 프로젝트와 누적 산출물이 실제로 존재한다.
- 한 segment에 과도한 어휘·문법·관계 맥락을 몰아넣지 않는다.

현재 생산형 문항 48개 중 의미와 고유 소유권을 모두 만족하며 재사용할 수 있는 상한은
40개다. 따라서 신규·재작성 생산 평가는 최소 46개이며, 기존 19개 계획은 폐기한다.
정량 근거와 레벨별 매트릭스는
[`CanDoSegment 데이터 품질 감사`](data/CAN_DO_SEGMENT_DATA_QUALITY_2026-08-16.md)에
기록한다.

## 거부한 대안

- **40 CourseUnit = 40 영구 보상:** 단원별 콘텐츠 밀도와 평가 타당도가 지나치게
  다르다.
- **원본 레코드 수 = 보상 수:** 파생 문항 중복 때문에 학습 능력 수를 과장한다.
- **어휘팩 = segment:** 단어 묶음은 실제 can-do나 생산 평가와 일치하지 않는다.
- **시나리오 = segment:** C1/C2 시나리오가 없고, 일부 A/B 시나리오는 단원 밖
  문법을 재사용하거나 여러 능력을 한 장면에 담는다.
- **checkpoint = segment:** 체크포인트는 교체 가능한 평가 수단이지 영구 능력
  정체성이 아니다.
- **별도 한옥 진행 ledger:** CourseMastery와 충돌하는 두 번째 학습 권한이 된다.

## 결과

CourseMastery V3는 segment별 생산 증거와 검증 ID를 정본으로 저장·동기화한다.
한옥 상태는 검증된 segment에서 결정론적으로 파생하고, 보이는 reveal·loadout·돌봄만
별도 저장한다. `core_2026_v1`을 이루는 여섯 edition의 합계 86개 분모는 바꾸지
않는다. 독립 can-do extension만 별도 신규 분모가 되고 proof replacement는 기존
slot의 대체 증거일 뿐 새 한옥 grant를 만들지 않는다. 한옥 grant ID는 해당
segment의 평가와 콘텐츠가 승인되기 전에는 만들지 않는다.
