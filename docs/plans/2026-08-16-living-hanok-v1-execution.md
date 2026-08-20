# 살아 있는 한옥 V1 — 확장 가능한 실행 기준

상태: 실행 중
기준일: 2026-08-16
제품 범위: 코드·규칙·자산·테스트의 `main` 병합까지. Firebase 프로덕션 배포와
스토어 제출은 별도 승인 사항이다.

> **부분 승계.** 이 문서의 86개 core `CanDoSegment`, exact productive evidence,
> additive content evolution 계약은 계속 유효하다. 외부 증빙 receipt, 건너뛴 보상
> 회수, 새 레벨별 시각 매핑과 V2 masterplan은
> [`2026-08-20-hanok-level-proof-and-skip-recovery-design.md`](../superpowers/specs/2026-08-20-hanok-level-proof-and-skip-recovery-design.md)가 확장·대체한다.
> 이 문서에서 recognition이 정상 한옥 권한이 아니라는 말은 CourseMastery와 기존
> productive grant 경로에 적용되며, 별도 receipt 기반 recovery를 금지한다는 뜻이 아니다.

## 1. 처음 계획에서 바뀐 핵심

처음의 `40 CourseUnit = 40 영구 보상` 계약은 폐기한다. 현재 CourseUnit은
`A1 16 / A2 8 / B1 6 / B2 6 / C1 2 / C2 2`로 콘텐츠 밀도가 크게 다르고,
Batch 05만 해도 B2·C1·C2에 각 168개의 활동을 더했다. CourseUnit은 탐색과
선행 조건을 담당하는 umbrella로 유지하고 영구 능력·보상 권한은 더 작은
`CanDoSegment`가 담당한다.

첫 core edition은 다음 86개다.

| 레벨 | core segment | 한옥 시대 |
|---|---:|---|
| A1 | 16 | 짓다 |
| A2 | 16 | 살다 |
| B1 | 18 | 잇다 |
| B2 | 20 | 나누다 |
| C1 | 8 | 돌보다 |
| C2 | 8 | 전하다 |
| 합계 | **86** | |

A1 16개는 각각 한 번의 실제 건축 변화와 대응한다. 나머지는 구조물,
생활·디자인 선택지, 장소, 분위기, 관리 기록, 자격 증표로 나뉜다. 따라서 86개가
모두 별도 대형 이미지 한 장을 요구하지 않는다.

C1/C2는 각 레벨의 네 주제를 네 단계 프로젝트로 만든다. 총 8개 프로젝트와
32개 단계이며, 관찰·비교 → CARE 산출물 → 반례·수정 → TRANSMIT 산출물 순서를
런타임과 비원문 증거로 모두 강제한다.

## 2. 권한과 확장 구조

```text
CourseUnit (40, 탐색·선행 조건)
  └─ CanDoSegment (core 86, 영구 능력·보상 identity)
       ├─ ProductiveAssessment (exact assess, allOf, 70% 이상)
       └─ ContentCluster (revisioned 연습 묶음)
            └─ ContentSeedAuthority (출처·CourseUnit provenance)
```

- 같은 능력을 연습하는 새 어휘·문법·대화·시나리오·Cloze·Satz는
  `ContentCluster.revision`만 올린다. 집, 분모, 과거 증거는 변하지 않는다.
- 독립적인 새 can-do와 고유 생산 평가가 생기면 기존 core에 끼워 넣지 않고,
  뒤쪽의 additive extension track에 발행한다.
- 기존 평가를 개선할 때 같은 published segment의 rubric을 바꾸지 않는다.
  기존 segment를 retire하고 같은 construct의 successor를 분모 0인 replacement
  track에 발행한다.
- recognition, Cloze, Satz, 발음 따라 읽기, XP, 단어팩, browse, bypass, Gye는
  영구 능력이나 개인 한옥 보상 권한이 아니다.
- `CourseMastery.completedUnitIds - bypassedPrerequisiteUnitIds`는 완료 단원의
  재평가 자격만 제공한다. 집과 “실제로 말하고 쓸 수 있음” 도장은 exact productive
  evidence로 검증된 `CanDoSegment`에서만 함께 파생한다. 따라서 기존 CourseUnit
  완료자도 신뢰 가능한 생산 증거가 없으면 새 한옥은 빈 터에서 시작하며, 재평가를
  통과할 때 해당 영구 보상만 정확히 한 번 얻는다.

## 3. Batch 06과 이후 콘텐츠 레인

브랜치 `codex/content-games-batch06-20260816`, 커밋 `23342c57`의 현재 범위는
standalone 68개와 시나리오 quest 20개다. 사람 검수는 0/68이고 TTS·Firebase·live
승격은 하지 않았다. 이 항목은 canonical 86, 생산 평가 권한, 한옥 보상 분모에
들어가지 않는다.

`23342c57`까지의 네 review-only 커밋은 현재 원격 `main`에 통합됐다. 병합과
learner-facing 승격은 서로 다른 작업이며, 통합됐다는 사실은 콘텐츠 승인을 뜻하지
않는다.

1. draft·review 원장·PDF 감사·validator·rollback 도구는 review-only로 유지한다.
2. KO 자연스러움, 관계 말투, DE/EN 의미 등가, 정답·오답, CEFR, segment 적합성,
   clean-room 권리를 사람이 검수한다.
3. `approved=true`, `live=true`, exact `canDoSegmentId`,
   `assessmentAuthority=false`를 모두 만족한 항목만 live로 승격한다.
4. 기존 능력의 연습이면 cluster revision으로 편입한다. 진짜 새 능력이면 별도
   extension proposal과 생산 평가를 만든다.
5. TTS는 live 승격 뒤 생성한다. review-only draft에는 만들지 않는다.

현재 확인된 후속 작업량은 standalone 164개와 quest 70개다. C1/C2 시나리오 14개,
고급 smalltalk 75개, B1/B2 Cloze 29개, B1/B2 Satz 14개, B1–C2 발음 32개를
포함한다. C1/C2 음절 퍼즐은 데이터 40개와 레벨 선택 UI를 함께 만들고, 미디어
표현은 호출 경로와 권리·개인정보 정책을 먼저 만든 뒤 콘텐츠를 작성한다.

이 콘텐츠 레인은 한옥 PR3 이후와 병렬 진행할 수 있다. human review 지연 때문에
A1 실제 건축이나 HanokState 구현을 막지 않는다.

## 4. 생산 평가와 개인정보

core 86개는 실행 가능한 평가 118개에 exact join한다. A1–B2의 독자 작성 과제
70개와 C1/C2의 source·prompt는 결정론적 계약과 테스트 fixture로 먼저 고정하되,
Jin의 per-ID 콘텐츠 승인을 뜻하지 않는다. 승인 원장이 통합되기 전 learner copy는
`tools/content_factory/drafts/productive_assessments.json`에만 두며 Flutter의
`assets/data/`에 넣지 않는다. production 재평가 route는 catalog loader를 호출하기
전에 fail closed하여 prompt와 source를 표시하지 않는다. 승인 뒤 C1/C2
16개 segment마다 open writing, oral production, connected evidence 세 축을 모두
요구한다.

- 원문 답안, 녹음, 인식문, source note는 CourseMastery·Firestore·analytics에
  저장하지 않는다.
- 영구 기록에는 정의 fingerprint, 평가기 버전, 비원문 결과 fingerprint, 점수,
  rubric, concept, source·slot coverage와 prerequisite evidence ID만 남긴다.
- 이 fingerprint는 손상·구버전·정의 불일치를 찾는 catalog integrity 장치다.
  learner-owned sync JSON에 대한 암호학적 부정행위 방지나 원격 시험 인증으로
  표현하지 않는다.
- 기존 10초 Azure read-aloud는 발음 연습일 뿐이며 oral-production 도장을 만들 수
  없다.
- 장시간 말하기는 별도 PR2b에서 45–120초 자유 발화, 별도 동의, 연속 STT,
  의미 슬롯·자료 언급·담화 표지, 발음·정확도·유창성 기준을 모두 검증한다.
  이 authority가 설치되기 전 재평가 화면은 말하기를 명시적으로 unavailable로
  표시하고 fail closed한다.

## 5. 구현·병합 순서

| 단계 | 결과 | 상태/의존성 |
|---|---|---|
| PR0 | room-v3/e66 선통합 | 완료(PR #29) |
| PR1 | segment·track·권리·카메라 불변 계약 | 완료(PR #30) |
| PR2 | 86 catalog, 118 draft 평가, CourseMastery V3, 4단계 project evidence, 승인 전 asset 격리·fail-closed 재평가 route | 완료(PR #31, merge `90613738`) |
| PR2b | 진짜 unscripted oral authority와 consent/privacy/backend tests | PR2 뒤 |
| Content lane A | Batch 06 review-only 도구 통합 | 완료(`23342c57` 포함 main) |
| Content lane B | Batch 06 사람 검수와 선택적 cluster 승격 | PR2 뒤 병렬·한옥 비차단 |
| PR3 | productive CourseMastery-only HanokState, 86 grant catalog, cutover, room-v3 dormant 복원 | 실행 중; 사용자 기본 경로 비노출 |
| PR4 | A1 0–16 누적 자산·renderer·reveal·thumbnail QA | PR3 뒤 |
| PR5 | A2–C2 디자인·장소·프로젝트·7/14일 돌봄 | PR3·PR4 뒤 |
| PR6 | Today·학습 경로·미션·영수증·개인 한옥·승인된 재평가 최초 진입점 연결 | PR5 및 콘텐츠 승인 뒤 |

PR3의 86개 grant 정의는 승인 전 설계 검증용 draft다. 따라서
`tools/content_factory/drafts/hanok_grants.json`에서만 생성·검증하며 Flutter
`assets/data`와 production `rootBundle` loader에는 포함하지 않는다. 사람 검수와
assessment 승인이 끝난 row만 append-only release ledger에 추가하고, 그 승인 변경과
runtime catalog 노출을 같은 원자적 PR에서 수행한다.
| PR7 | 원자적 cutover와 legacy 한옥 삭제, Gye 경계 분리 | PR6 뒤 |
| PR8 | 전체 성능·접근성·오프라인·동기화·기기 QA | 마지막 |

각 PR은 최신 원격 main에서 만든 독립 worktree를 사용한다. 명시적 파일만 stage하고,
SESSION_LOG 최상단 기록, push, PR, 해당 원격 SHA의 exact-head CI, main 병합과
worktree 정리까지 완료한다. 로컬 `main`의 선행 커밋이나 dirty 변경은 기준으로 쓰지
않는다.

## 6. 완료 판정

최종 완료는 다음 열 가지가 모두 충족된 exact `main` SHA가 있을 때뿐이다.

1. core 86과 모든 extension/replacement 계약에 중복·누락이 없다.
2. A1 빈 터 포함 17상태와 16번의 식별 가능한 건축 변화가 있다.
3. 실패·browse·bypass·단어팩·XP·Gye로 개인 한옥 보상이 생기지 않는다.
4. 과거 legacy 집 상태와 무관하게 같은 CourseMastery는 같은 새 한옥을 만든다.
5. 모든 segment가 70%·필수 생산·exact assess 계약을 만족한다.
6. 여섯 성장 시대와 C1/C2 8개 프로젝트·32단계가 도달 가능하다.
7. 자유설계, room-v3 복원, 돌봄·휴가·알림 중복 방지가 작동한다.
8. 자산 크기·색공간·OCR·socket·thumbnail hash·memory·reduced motion을 통과한다.
9. 제3자 화면·PDF 원문·raw answer가 번들·모델 입력·analytics에 들어가지 않는다.
10. analyze, 전체 Flutter test, web release, rules/emulator, diff check,
    exact-head CI와 반응형·실기기 QA를 모두 통과한다.

이미지·영상 생성은 PR4의 정적 자산 계약이 코드로 고정되고 pilot 합성 QA를 통과한
뒤에만 시작한다. 현재 단계에서는 BBANANA/Seedance 크레딧을 사용하지 않는다.
