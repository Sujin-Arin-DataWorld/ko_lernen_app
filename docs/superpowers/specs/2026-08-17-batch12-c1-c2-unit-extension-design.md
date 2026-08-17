# Batch 12 설계 — C1/C2 유닛 확장 (extension 릴리스 트랙)

> **상태:** 접근법 승인(2026-08-17, Jin: "B안 번호 12"), 상세 검토 대기.
> **전제:** review-only 초안까지만 만들고, 병합은 PR3(HanokState v1) 뒤로 미룬다.
> **기준 커밋:** `b7b453a2` (Batch 11 머지 + origin/main `3ed82232` 반영)

## 1. 문제

C1/C2에 `CourseUnit`이 각 2개뿐이다. 시나리오는 같은 레벨 유닛 하나를 `courseUnitId`로
선언하고 `conceptIds`를 그 유닛의 `requiredConceptIds`에서 골라야 하므로, Batch 11의
여섯 카테고리가 C1/C2에서는 2개 유닛에 3+3으로 몰렸다. 소재를 그 유닛 담론으로 올려
해결했지만, 카테고리를 1:1로 펴려면 유닛이 6개씩 필요하다.

## 2. 코드에서 확인한 계약

| 대상 | 확인된 사실 |
| --- | --- |
| `assets/data/can_do_segments.json` | root `schemaVersion / contentClusters / segments / trackEditions / releaseTracks`. 손편집 대상이 아니라 `tools/content_factory/build_can_do_segments.py`가 생성한다(canDo·phrase fingerprint SHA256 하드코딩) |
| `releaseTracks` | 현재 1개: `core_2026_v1`, `kind: "core"`, `order: 1`, `editionIds` 6개(레벨별), `status: "published"` |
| `trackEditions` | 레벨별 1개. `id`, `releaseTrackId`, `level`, `segmentIds[]`, `publishedAt`, `status` |
| segment | `id`, `constructLineageId`, `parentCourseUnitId`, `level`, `order`, `title{}`, `canDo{}`, `requiredConceptIds[]`, `contentClusterIds[]`, `proofRevision`, `evidencePolicy: "allOf"`, `assessmentRequirements[3]`, `ownedAssessmentItemIds[3]`, `releaseTrackId`, `trackEditionId` |
| C1/C2 평가 3종 | `openWriting`, `oralProduction`, `connectedEvidence` / 각 `rubricVersion: 1`, `minimumScore: 0.7`, `missionContentLinkId` 1개 |
| contentCluster | `id`, `level`, `revision`, `sourceSeedIds[]`, `contentReferences[{kind,id}]`. kind는 `vocabPack`·`cloze`·`satz`·`smalltalk`·`project`. 실측(`cluster_c1_evidence_validity_v1`): vocabPack 1, cloze 6, satz 6, smalltalk 2, project 1 |
| `assets/data/can_do_content_authorities.json` | `sourceSeeds` 1,742 / `contentReferences` 1,982 / `coverage` |
| `lib/services/canonical_course_segment_loader.dart` | 하드코딩 숫자 없음. 카탈로그가 선언한 seed/reference 집합과 authorities 파일의 집합이 **정확히 일치**해야 하고 kind별 개수·상속 규칙을 `FormatException`으로 fail-closed 검증 |
| 86 계약 | Dart 코드가 아니라 `test/can_do_segment_asset_test.dart`·`test/canonical_course_segment_loader_test.dart`가 잡는다 |
| ADR-003 | 새 독립 can-do는 기존 edition에 삽입 금지. 같은 CEFR의 **새 extension `ReleaseTrackDefinition`과 edition**에 속하고, 새 non-draft 트랙의 `order`는 기존 non-draft 최댓값보다 커야 한다 |

## 3. 만들 것

### 3.1 새 릴리스 트랙 2개

```
c1_extension_2026_v1   kind: extension   order: 2   edition: edition_ext_c1_v1
c2_extension_2026_v1   kind: extension   order: 3   edition: edition_ext_c2_v1
```

`core_2026_v1`(order 1)의 86개 분모·한옥 보상은 건드리지 않는다. UI는 `코어 86/86`과
`C1 확장 0/4`를 분리해 보여준다(UI 작업은 이 배치 범위 밖).

### 3.2 새 CourseUnit 8개와 카테고리 1:1

C1은 기존 `c1_01`(근거·공공 설명)을 daily, `c1_02`(포용·지속가능)을 friends에 두고 4개를
더한다. C2는 기존 `c2_01`(해석·제도)을 friends, `c2_02`(기술윤리)을 youtube에 두고 4개를 더한다.

| 레벨 | 새 유닛 ID | 담당 카테고리 | can-do 요지 | concept ID |
| --- | --- | --- | --- | --- |
| C1 | `c1_03_media_evidence_literacy` | youtube | 대중적 주장의 표본·방법 한계를 한정해 설명 | `concept_c1_media_evidence` |
| C1 | `c1_04_play_time_policy` | gaming | 이용시간 자료로 규제안의 효과와 부작용을 함께 검토 | `concept_c1_play_time_policy` |
| C1 | `c1_05_fan_labor_sustainability` | kpop | 무보수 참여 노동의 지속 가능 범위를 설계 | `concept_c1_fan_labor` |
| C1 | `c1_06_intimacy_safety_design` | dating | 안전과 표현 사이에서 신고·차단 절차를 설계 | `concept_c1_intimacy_safety` |
| C2 | `c2_03_automation_redress` | daily | 자동 처리 오류의 구제 경로가 형식에 그치지 않게 요구 | `concept_c2_automation_redress` |
| C2 | `c2_04_sanction_accountability` | gaming | 자동 제재의 전제를 드러내고 이의 절차 조건을 규정 | `concept_c2_sanction_accountability` |
| C2 | `c2_05_relationship_narratives` | dating | 서사가 만드는 관점 편향을 관계와 분리해 분석 | `concept_c2_relationship_narratives` |
| C2 | `c2_06_fandom_discourse_power` | kpop | 집단 언어의 담론 권력을 양보 구문으로 반박 | `concept_c2_fandom_discourse` |

Batch 11의 C1/C2 12편은 이 유닛들이 병합된 뒤 `courseUnitId`를 재배치할 수 있다. 단
Batch 11이 먼저 승인·병합되면 ID·연결은 그대로 두고 **Batch 12에서 `contentLinks`만 추가**한다
(승인된 초안의 재번호·재배치 금지 규칙).

### 3.3 유닛당 산출물과 총계

| 산출물 | 유닛당 | 8유닛 |
| --- | ---: | ---: |
| CourseUnit + concept | 1 + 1 | 8 + 8 |
| CanDoSegment (`proofRevision: 1`, `evidencePolicy: allOf`) | 1 | 8 |
| contentCluster (`revision: 1`) | 1 | 8 |
| vocab pack (11–12개, boss 2–3) | 12 | 96 |
| Cloze / Satz (단어 예문에서 파생) | 4 / 4 | 32 / 32 |
| Smalltalk | 2 | 16 |
| project 영수증 (C1/C2 4단계) | 1 | 8 |
| 생산 평가 항목 + mission 링크 | 3 + 3 | 24 + 24 |
| `sourceSeeds` / `contentReferences` (authorities) | 2 / 19 내외 | 16 / 152 내외 |

C1/C2 어휘는 현재 각 72개다. 96개를 더하면 그 레벨 어휘가 배 이상이 된다. 이 배치의
무게는 코드가 아니라 **C1/C2 수준 문장 240여 개를 쓰는 일**이다.

## 4. 순서

1. **생성기 확장**: `build_can_do_segments.py`에 extension 트랙·edition·8 segment·8 cluster를
   추가하고, `build_productive_assessments.py`에 평가 24개를 추가한다. fingerprint는 생성기가
   계산하도록 두고 손으로 적지 않는다.
2. **콘텐츠 초안**: 유닛별로 단어팩 → 문법 확인 → Cloze/Satz → Smalltalk → project 순서.
   어휘 기반 → 게임 파생 순서를 지킨다(`CONTENT_ARCHITECTURE` §5).
3. **authorities 갱신**: `sourceSeeds`·`contentReferences`를 같은 트랜잭션에서 채운다. Dart
   로더가 집합 불일치를 fail-closed로 잡으므로 부분 갱신은 무조건 실패한다.
4. **검증**: `validate_content.py`, `validate_review_batch.py --manifest`,
   `flutter test test/can_do_segment_asset_test.dart test/canonical_course_segment_loader_test.dart`.
   코어 86은 그대로여야 하고 확장 8은 별도로 세어져야 한다.
5. **승인·병합**: Jin 승인과 PR3 병합 뒤에만 live 자산에 넣는다.

## 5. 금지와 게이트

- 코어 `core_2026_v1`의 segment ID·edition·`proofRevision`·평가 목록을 바꾸지 않는다.
- 새 segment를 기존 edition `segmentIds`에 넣지 않는다.
- `--apply`·TTS·Firebase 쓰기 금지. 승인 전 `assets/data/` 수정 금지.
- PR3(HanokState v1 grant catalog)와 같은 권한 파일을 동시에 수정하지 않는다. 병합 순서는
  PR3 → Batch 12다.
- 새 유닛에 콘텐츠 없이 껍데기만 넣지 않는다. 클러스터가 비면 로더가 거부한다.

## 6. 위험

| 위험 | 대응 |
| --- | --- |
| 분량이 Batch 11의 5–6배 | 유닛 2개 단위(C1 하나 + C2 하나)로 슬라이스해 각 슬라이스가 preview를 통과한 뒤 다음으로 간다 |
| C1/C2 어휘 배증으로 난도 왜곡 | 새 단어는 기존 C1/C2 표제어와 중복 금지, 담론 어휘에 한정하고 팩 단위로 검수 |
| 생성기 fingerprint 하드코딩 | 새 항목은 생성기가 계산하게 하고, 기존 86개 fingerprint는 손대지 않는다 |
| 86 분모 오염 | 확장 트랙 order 2·3, 별도 edition. 테스트에 코어 86과 확장 8을 각각 고정 |
| PR3 충돌 | 초안 단계는 `tools/content_factory/` 안에서만 작업. 병합은 PR3 뒤 |
