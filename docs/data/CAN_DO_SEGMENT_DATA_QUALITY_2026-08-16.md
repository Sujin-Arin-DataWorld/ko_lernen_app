# A1–C2 CanDoSegment 데이터 품질·입도 감사

- 감사 기준: `ee8282b9b73962b9c23a03748911cc6aaf32d55c`
- 감사일: 2026-08-16
- 목적: 현재 학습 데이터를 영구 숙달·한옥 보상 단위로 사용해도 되는지 판정
- 판정 grain: 하나의 독립 can-do, 하나의 의미상 구별되는 산출물, 하나의 고유 생산 평가

## 요약

현재 40개 `CourseUnit`은 탐색·선행 조건용 parent umbrella로는 유효하지만 영구
보상 단위로는 신뢰할 수 없다. 방어 가능한 첫 전체 core edition은 86개의
`CanDoSegment`다.

| 레벨 | 최소 | 권장 | 권장안의 근거 |
| --- | ---: | ---: | --- |
| A1 | 16 | 16 | 16개 실제 건축 공정과 기본 can-do |
| A2 | 16 | 16 | 고유 시나리오 15개 + 해요체 전환 1개 |
| B1 | 14 | 18 | 여행·매체·사회행사·생애서술 산출물을 분리 |
| B2 | 14 | 20 | 시나리오·Batch 05 네 주제 외 논증·환경·안전·격식 전환 분리 |
| C1 | 4 | 8 | 네 주제를 진단/판단과 제안/설명으로 각각 분할 |
| C2 | 4 | 8 | 네 주제를 분석과 책임 있는 산출물로 각각 분할 |
| 합계 | **68** | **86** | |

80개 안은 명시적인 MVP로는 가능하지만 B1 두 개와 B2 네 개의 독립 산출물을
supplemental practice로 숨긴다. 따라서 “A1–C2 완전판”의 영구 분모로 사용하지
않는다.

## 데이터와 grain

| 레벨 | CourseUnit | 어휘 / pack | 문법 | Smalltalk | Cloze | Satz | 시나리오 / quest | 현재 생산형 quest |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| A1 | 16 | 211 / 24 | 32 | 64 | 99 | 63 | 15 / 85 | 24 |
| A2 | 8 | 271 / 28 | 41 | 57 | 75 | 38 | 15 / 61 | 8 |
| B1 | 6 | 281 / 26 | 41 | 52 | 79 | 73 | 16 / 53 | 8 |
| B2 | 6 | 329 / 31 | 46 | 80 | 165 | 149 | 12 / 42 | 8 |
| C1 | 2 | 48 / 4 | 8 | 16 | 48 | 48 | 0 / 0 | 0 |
| C2 | 2 | 48 / 4 | 8 | 16 | 48 | 48 | 0 / 0 | 0 |

생산형 quest는 현재 Satz 20개와 Diktat 28개다. 숫자는 48개지만 동일 checkpoint
중복과 can-do 의미 불일치를 제거하면 86 segment에 재사용 가능한 상한은 40개다.

| 설계안 | segment | 기존 생산 문항 최대 인정 | 신규·재작성 하한 |
| --- | ---: | ---: | ---: |
| 최소 68 | 68 | 40 | 28 |
| MVP 80 | 80 | 40 | 40 |
| 권장 86 | 86 | 40 | **46** |

따라서 과거 40-unit 계획의 “19개 신규 생산 평가”는 폐기한다. 46개도 현재 문항의
의미가 모두 정확하다고 가정한 하한이므로 실제 감수 뒤에는 늘 수 있다.

## 무결성 검사

다음 구조 검사는 모두 통과했다.

- unit, vocab, grammar, Smalltalk, Cloze, Satz, scenario ID 중복 0
- vocab pack base, grammar, Smalltalk category, Cloze topic mapping 누락 0
- scenario의 고아 `courseUnitId` 0
- Satz 419개가 모두 유일한 같은 레벨 vocab source와 결합
- checkpoint 40개가 모두 실제 콘텐츠를 참조
- Batch 05 Cloze 144개와 Satz 144개가 vocab 예문·번역과 정확히 일치

단, 감사 시작 시 `content_audit_manifest.json`의 `graph.courseUnits`는 실제 40이
아니라 36으로 남아 있었다. 이 PR에서 실제 curriculum 수와 자동 대조하도록
validator·통합 도구·회귀 검사를 함께 수정한다.

Batch 05의 레벨당 168개 중 Cloze 48개와 Satz 48개, 합계 96개(57.1%)는 어휘
예문에서 파생된 연습이다. join 무결성은 좋지만 독립 능력 수로 세면 중복 과대계상이다.

## 권장 core release

`core_2026_v1`은 레벨별 여섯 immutable edition을 묶는 release track ID이고,
분모 합계는 86으로 고정한다. 아래 이름은 의미 매트릭스이며
영구 segment ID는 원본 평가·rubric과 함께 PR2에서 한 번에 동결한다.

### A1 16

현재 16개 CourseUnit의 can-do를 각각 한 segment로 사용한다. 아래 세 개는 현재
checkpoint를 재사용하면 다른 능력을 측정하므로 전용 평가가 반드시 필요하다.

- `a1_05_numbers_time`: 시간·날짜·수량의 듣기·생산
- `a1_12_daily_negation`: 현재·과거·부정 변환 생산
- `a1_13_register_switching`: 합니다체·해요체·반말의 관계별 전환

`a1_02_self_intro_identity`와 `a1_14_payment_delivery`도 현재 산출물이 can-do의
일부만 측정하므로 별도 감수를 통과해야 한다. A1 16개는 한옥의 16개 실제 건축
공정과 1:1로 연결한다.

### A2 16

15개 실제 상황을 합치지 않는다.

```text
plans_with_friend, friend_birthday, running_late,
pharmacy_headache, gym_signup, feeling_sick,
cafe_starbucks_basic, myeongdong_shopping, cafe_study,
subway_transfer, taxi_street, subway_directions, lost_phone,
ktx_ticket, rent_bank_transfer
```

여기에 `haeyo_register_transition`을 새로 만든다. 기존 café checkpoint를 말투 전환과
카페 주문 두 segment가 함께 소비하지 않는다.

### B1 18

```text
plans_with_reasons
travel_experience
relay_social_speech
relay_media_claim
bank_soft_request
team_role_coordination
attendance_and_coverage
schedule_softening
encouragement
intimate_feelings
social_invitation
delivery_resolution
property_damage_report
housing_contract
safety_health_concern
relationship_conflict_repair
move_in_handover
life_course_narrative
```

현재 시나리오 16개만 세면 매체·기술 29개 어휘, 건강·교육·병원 22개 어휘,
여행·교통 Smalltalk와 사회행사·생애 서술 산출물이 다른 장면에 억지로 붙는다.
18개는 이 의미 손실을 막는 최소 권장 분할이다.

### B2 20

```text
formal_meeting_opening
honorific_register_transform
decision_criteria
public_wording_revision
collaborative_feedback
digital_source_judgment
societal_evidence_argument
language_social_change
medical_precision
contract_scope
terms_deferral
environmental_tradeoff
formal_complaint
remedy_and_appeal
shared_space_coordination
personal_boundaries
household_safety_rule
interview_experience
literary_cultural_response
formal_soft_reformulation
```

Batch 05 네 주제는 `collaborative_feedback`, `digital_source_judgment`,
`shared_space_coordination`, `personal_boundaries`로 보존한다. 다만 category 기반
Smalltalk routing 때문에 16개 중 12개가 의미상 다른 CourseUnit으로 향하고,
여러 문법도 예문 주제와 parent가 어긋난다. PR2에서 category 추론 대신 정확한
phrase/grammar ID를 segment에 연결한다.

### C1 8

```text
accessibility_barrier_diagnosis
participatory_access_remedy
evidence_validity
evidence_limits_conclusion
risk_uncertainty
risk_update_correction
sustainable_lifecycle
local_tradeoff_adaptation
```

각 segment는 vocab 6개와 그 문장에서 파생된 Cloze 6개·Satz 6개를 연습으로
사용한다. 네 주제 각각 두 번째 segment가 누적 제안·공공 설명 산출물을 만든다.

### C2 8

```text
procedural_legitimacy
institutional_deliberation
narrative_perspective
interpretation_justification
framing_responsibility
discourse_boundary_power
technology_traceability_appeal
technology_responsibility_rights
```

C2 문법 8개의 현재 예문은 기술·자동화 책임에 치우쳐 있다. 첫 여섯 segment에는
새 문법 규칙을 억지로 추가하기보다 기존 패턴의 제도·서사·담론 맥락 예문과 생산
과제를 먼저 보강한다. 의미상 균형을 위해 C2_01 문법 맥락 2개와 서사 Smalltalk
1개가 최소 추가로 필요하다.

## C1/C2 네 단계 프로젝트

각 고급 주제는 다음 네 단계를 갖는다.

1. 두 개 이상의 자료·목소리를 연결하고 지지·대조·한계를 표시한다.
2. `CARE` 묶음으로 짧은 글쓰기, 구두 요약, 출처 연결 증거를 함께 제출한다.
3. 반례 또는 상대 질문을 받고 자료 연결망을 갱신한다.
4. `TRANSMIT` 묶음으로 수정 글쓰기, 구두 전달, provenance를 함께 제출한다.

2단계와 4단계는 각각 `openWriting + oralProduction + connectedEvidence`를 AND로
통과한다. Cloze·Satz와 선택형 정답은 이 세 gate를 대신하지 않는다.

최소 신규 고급 산출물은 다음과 같다.

- C1/C2 segment 16개와 assessment 선언 16개
- 주제 프로젝트 8개 × 4단계 = 32 step
- open writing 16, oral 16, connected evidence 16 = 48 evidence task
- 연결 자료·목소리 원본 snippet 최소 32개
- C2 문법 맥락 2개, C2 서사 Smalltalk 1개

## 위험과 자동화

| 위험 | 심각도 | 조치 |
| --- | --- | --- |
| CourseUnit 완료를 영구 보상으로 사용 | High | segment 증거 없이는 grant 금지 |
| 파생 Cloze/Satz를 독립 능력으로 계산 | High | source vocab join으로 중복 제거 |
| 같은 checkpoint를 두 segment가 소비 | High | assessment ID 전역 단일 소유 검사 |
| category 기반 B2 Smalltalk 오배치 | High | exact phrase reference로 교체 |
| C1/C2 선택형 4회로 고급 완료 | High | 3축 생산 증거 AND gate |
| 미래 콘텐츠가 과거 100%를 낮춤 | High | edition segmentIds append 금지 |
| audit graph count 재누락 | Medium | curriculum 실제 수 자동 대조 |

## 적용 결정

- `CourseUnit`은 reward key가 아니다.
- raw 콘텐츠 레코드 수는 segment 수가 아니다.
- 80개는 전체 core edition이 아니다.
- `core_2026_v1` release는 레벨별 여섯 고정 edition, 합계 86 segment를 갖는다.
- 기존 CourseUnit 완료는 새 segment로 자동 승격하지 않는다.
- 한옥은 향후 `verifiedCanDoSegmentIds - bypassedSegmentIds`에서만 파생한다.
- 다음 edition은 기존 86개 분모를 수정하지 않고 별도 extension으로 추가한다.

## 지속적인 레벨별 콘텐츠 추가 계약

콘텐츠 생산량은 edition 분모와 분리한다.

1. 기존 can-do를 더 연습하는 어휘·문법·Smalltalk·Cloze·Satz·시나리오는 같은
   `ContentClusterDefinition`의 revision을 올린다. 기존 segment와 보상은 그대로다.
2. 동일한 can-do의 평가가 개선되면 `proofRevision`과 assessment/rubric version을
   올린다. 기존 집은 유지하고 최신 검증 여부만 별도 상태로 제공한다.
3. 독립 can-do와 고유 생산 평가가 추가될 때만 새 segment를 만들고 해당 레벨의 새
   additive edition에 넣는다. 예: `코어 B2 20/20`, `B2 확장 1 0/4`.
4. 현재 catalog 커버리지는 운영 지표로 따로 계산할 수 있지만, 과거 edition 100%나
   한옥 완성도를 다시 낮추는 전역 분모는 만들지 않는다.

따라서 앞으로 한 레벨에 레코드 500개가 추가되어도 그것만으로 500개 보상이 생기지
않으며, 반대로 검증 가능한 새로운 생활 수행 능력이 생기면 기존 집을 훼손하지 않고
새 건축·생활·돌봄 여정으로 계속 확장할 수 있다.

## `a990d8a3` 콘텐츠 충원 감사와의 관계

`origin/agent/reference-gap-audit-20260816`의 `a990d8a3`는 B1–C2에 독립
상황 씨앗을 먼저 8개씩 만들고, 같은 씨앗에서 시나리오·듣기·Satz·발음·Cloze·
Smalltalk를 함께 파생하는 공급 계획을 기록한다. 이 방향은 다음처럼 흡수한다.

- `sourceSeedId`는 level이 고정된 typed `ContentSeedAuthority`로 등록하며,
  `ContentClusterDefinition`의 append-only provenance다. 각 파생 콘텐츠 authority의
  seed와 CourseUnit은 cluster seed 집합·segment parent에 정확히 일치해야 한다.
- B1–C2 32개 첫 씨앗과 후속 C1/C2 16개 씨앗은 콘텐츠 공급량이지 보상 수가 아니다.
- “C1/C2 CourseUnit 각 8개”는 “C1/C2 core CanDoSegment 각 8개”로 정정한다.
- 기존 엔진으로 만든 선택·배열·빈칸 근사 활동은 연습만 담당하고 생산 숙달을
  판정하지 않는다.
- 씨앗이 기존 can-do를 보강하면 cluster revision, 같은 평가를 개선하면
  proof revision, 독립 can-do와 고유 평가를 만들면 새 extension track으로 분류한다.
- published core는 제품 기본 loader에서 `core_2026_v1`의 여섯 레벨 edition과
  `16/16/18/20/8/8=86`을 정확히 검증하며, successor는 동일
  `constructLineageId`의 단일 predecessor 선형 계보만 허용한다.
- 제품과 테스트가 같은 canonical core policy를 사용하며 public test seam은 두지 않는다.
  새 non-draft extension track은 기존 non-draft 최댓값보다 뒤에만 추가한다.

해당 커밋은 현재 `main`에 없는 문서형 백로그이며 앱 코드·데이터·테스트를 바꾸지
않는다. 따라서 그대로 병합하지 않고 위 권한 경계로 정정한 뒤 PR2 이후의 콘텐츠
제작 입력으로 사용한다.
