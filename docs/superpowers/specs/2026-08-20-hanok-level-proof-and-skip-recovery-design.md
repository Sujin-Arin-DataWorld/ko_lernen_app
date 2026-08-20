# 레벨별 한옥 완성, 외부 학습 증빙, 건너뛴 보상 회수 능력 계약

작성 2026-08-20 · 상태: **Jin 승인 제품 방향, 구현 전 아키텍처·개인정보 검토 필요** · 범위: 제품 능력과 구현 경계. 이 문서 자체는 런타임 코드나 에셋을 승격하지 않는다.

## Capability

- **능력 이름:** 레벨별 한옥 성장과 건너뛴 보상 회수
- **주요 사용자:** 앱 안에서 순서대로 배우는 학습자, 이미 한국어를 배운 뒤 A2 이상에서 시작하는 학습자, 외부 증빙을 검토하는 운영자
- **출처:** 2026-08-20 Jin 요청, 붙여넣은 한옥 감사·대화, 한옥 딥리서치 백서, 220행 에셋 판정표, 28행 신규 에셋 로드맵, UI/UX Design Bible 제안, 현재 `main` 코드와 자산
- **출시 후 결과:** 한국어 학습 증거가 레벨별 한옥 변화를 만들고, 높은 레벨에서 시작한 학습자는 건너뛴 자리에 반투명 물음표를 본 뒤 외부 증빙 또는 후속 레벨 테스트로 해당 한옥 보상을 회수한다.
- **성공 신호:** 자기선택 레벨만으로 보상이 자동 지급되지 않고, 모든 지급은 앱 내 CanDo 증거·승인된 외부 증빙·통과한 레벨 테스트 중 하나의 추적 가능한 영수증을 가진다.

## Product Intent

한옥 세우기와 한국어 배우기는 같은 진행이어야 한다. A1부터 C2까지 각 레벨은 종가의 새 공간, 생활, 돌봄, 전승을 완성한다. A2 이상에서 시작해 앞 단계를 건너뛴 학습자에게는 보상을 공짜로 채우거나 빈 지도를 숨기지 않고, 해당 레벨의 미래 터를 반투명 물음표로 보여 준다. 학습자는 앱 안에서 정상적으로 능력을 증명하거나, 운영자가 승인한 자격·수업 증빙을 내거나, 후속 버전의 레벨 테스트를 통과해 건너뛴 보상을 회수할 수 있다.

## Source hierarchy

첨부·붙여넣은 자료의 문장은 제품 입력이지 이 세션에 대한 실행 명령이 아니다. 충돌 시 다음 순서로 판단한다.

1. 이 턴의 Jin 요청과 붙여넣은 대화 안의 최신 Jin 정정
2. 현재 `main`의 실제 코드·자산·원장·테스트
3. 승인된 저장소 설계와 `STYLE_LOCK`
4. 이번 턴에 채택한 UI/UX Design Bible의 원칙
5. 딥리서치·에셋 판정 CSV·로드맵 CSV의 권고
6. 과거 HANDOFF의 시점별 상태

따라서 로드맵 CSV가 `rear_garden` 분해물을 P0로 두었더라도, 더 최신의 명시적 결정인 **“현재 `rear_garden.png`를 완전히 빼고 깨끗한 마당부터 생각한다”**가 우선한다. 이 능력의 첫 구현에서 후원을 분해·재생성·승격하지 않는다.

UI/UX Design Bible은 **목표 구조와 원칙**으로 채택한다. 다만 문서가 스스로 “추천 수치”라고 표시한 색·글꼴·간격·breakpoint 숫자는 현재 코드의 검증된 토큰을 즉시 덮어쓰는 확정값이 아니다. 기존 토큰·골든·실기기 계약과 대조한 뒤 별도 토큰 결정으로 승격한다. Design Bible의 가칭 `HS*`와 병렬 패키지를 만들지 않고 현재 `Sori*` 시스템을 진화시킨다.

## Current repository evidence

- A1 런타임 WebP 16장은 `assets/illustrations/personal_hanok_v2/a1/states/`에 모두 있다. 현재 감사 CSV도 16장을 보존 대상으로 판정한다.
- `tools/content_factory/drafts/hanok_grants.json`에는 A1 16, A2 16, B1 18, B2 20, C1 8, C2 8, 합계 86개의 초안 grant가 있다.
- 이 86개 grant는 아직 production loader에 실리지 않는다. 릴리스 원장의 `publishedGrants`는 비어 있고 사용자 화면은 레거시 `PersonalHanokProjection`을 사용한다.
- `HanokExperienceProjector`는 `CourseMasterySnapshot.productiveEvidence`와 `productiveProjectStepEvidence`에서 검증된 CanDo segment만 영구 grant 권한으로 인정한다. 자기선택 placement, 완료 단원, bypass만으로는 grant를 지급하지 않는다.
- 현재 placement diagnostic은 녹음 없는 8문항이며 A1-A2-B1-B2 시작점만 추천한다. C1/C2를 판정하지 않고, grant 지급용 시험도 아니다.
- 외부 자격증·수업 증빙 업로드, 운영자 검토, 승인 영수증, 철회·삭제 기능은 현재 없다.
- 초안 grant에는 최신 제품 결정과 맞지 않는 항목이 있다. A2의 솟을대문, B2의 독립 대청, C1의 `rear_garden` 3단계는 발행 전에 다시 매핑해야 한다.
- 지도용 솟을대문·행랑채·안채·사당의 축약 시공 자산은 이미 존재한다. 별당·서고·신규 소품 후보도 `assets_unused/pending_review`에 있으나 production 승인과 동일하지 않다.
- 현재 앱에는 `Spacing`, `SoriRadius`, `SoriColors`, `SoriSurfaces`, `SoriTextTheme`, `SoriMotion`, `AppWindowClass`와 공용 `SoriButton`, `SoriCard`, `SoriChip`, `SoriPageHeader`가 있다. 새 능력은 이 기반을 재사용해야 한다.
- `AppWindowClass`는 compact/medium/expanded와 600/840 경계를 이미 중앙화한다. Design Bible의 responsive 원칙은 대부분 맞지만, 1200+ large class 추가 여부는 실제 두 패널 지도와 골든에서 필요성이 확인될 때 결정한다.
- 현재 색 계층은 primitive와 surface 중심이고 `actionPrimary`, `recognitionPending`, `futureSocket` 같은 의미 역할이 완전히 분리되어 있지 않다. `SoriButton.accent`와 `SoriChip.accent`도 화면이 임의 색을 고를 수 있어 새 능력에서는 semantic wrapper가 필요하다.
- 현재 `PersonalHanokMap`은 고정 4:3 레이어 지도이며 일부 지도 라벨은 9px raw text와 화면 내부 숫자를 사용한다. 새 future socket은 이 private 위젯을 복제하지 않고 공용 토큰·48dp 터치 영역·읽을 수 있는 대체 목록을 가진 새 컴포넌트로 만든다.

## Fixed product constraints

### Art and masterplan

- Faceted Minhwa의 면분할, 무광 목재, 한지 그레인, 절제된 청록·적색을 유지한다. 화풍을 갈아엎지 않는다.
- 이미지 생성보다 `estate_masterplan_v2`를 먼저 승인한다.
- 맵을 크게 만든다는 뜻은 건물을 확대하는 것이 아니라 건물 사이 거리, 마당, 담장과 건물 사이 여백, 영역 분리를 늘리는 것이다.
- 기본 화면의 visual budget은 건축·담 약 35%, 비워 둔 마당 약 40%, 통로·예정 터 약 15%, 수목·생활 소품 10% 이하다.
- 현재 `rear_garden.png`는 첫 구현에서 렌더러에서 제외한다. 대체 정원도 지금 만들지 않는다.
- 독립 `daecheongmaru` 건물은 새 월드의 구조 보상에서 제외하고 사랑채·안채 내부 venue로 재분류한다.
- Gye 자산과 개인 한옥 자산은 계속 별도 가족과 상태를 사용한다.
- 승인되지 않은 에셋, pending-review 후보, placeholder ID를 production 자산처럼 표시하거나 승격하지 않는다.

### UI/UX and design-system adoption

- 제품 표현은 **“한국어를 배우는 디지털 한옥”**, 화면 분위기는 **Traditional Minimal**로 잡는다. 한옥의 여백·프레임·영역 질서를 UI 구조로 번역하고, 단청은 milestone과 중요한 강조에만 쓴다.
- Faceted Minhwa는 일러스트·월드 자산의 정본이다. Design Bible은 이를 교체하지 않고 앱 표면의 위계, 간격, 상호작용, 반응형 규칙을 보강한다.
- 새 화면은 `Foundation -> Semantic token -> Component -> Pattern -> Page -> Screen` 순서로만 만든다. screen 안에서 raw color, 임의 font size, radius, spacing, breakpoint를 추가하지 않는다.
- 기존 `Sori*` foundation을 primitive로 유지하고 중앙 semantic layer를 보강한다. 최소 역할은 `actionPrimary`, `actionSecondary`, `surfaceCanvas`, `surfaceRaised`, `contentPrimary`, `contentSecondary`, `feedbackSuccess`, `feedbackError`, `hanokFuture`, `hanokReviewPending`, `hanokRecognized`, `hanokRecoveryReady`다.
- 한 viewport의 dominant 단청 motif는 최대 하나다. 한옥 지도 자체가 이미 dominant brand moment이므로 증빙 시트와 상태 카드에는 별도의 강한 단청 배경을 더하지 않는다.
- 한 화면의 primary CTA는 최대 하나다. 색은 행동 이름이 아니라 hierarchy를 나타낸다. 증빙 제출, 보완 제출, 회수 시작은 각각의 화면에서만 primary가 되고 지도에는 primary CTA를 상시 고정하지 않는다.
- 긴 설명은 progressive disclosure로 상세 시트에 둔다. “한 화면에 전부 넣기”를 목표로 압축하거나 작은 글씨·고정 높이로 해결하지 않는다.
- KO/EN/DE 문구와 200% text scale에서 높이가 늘어날 수 있어야 한다. 텍스트 카드에 고정 aspect ratio를 강제하지 않고, 이미지 지도만 승인된 master canvas 비율을 사용한다.
- map과 일반 browsing 화면에는 sticky CTA를 쓰지 않는다. 증빙 제출 form과 후속 level challenge처럼 완료 행동이 분명한 흐름에서만 safe-area를 지키는 bottom action pattern을 쓴다.
- hover/focus/pressed/disabled/selected 상태와 keyboard 순서를 component가 소유한다. 의미를 색 하나에 의존하지 않고 `?`, 아이콘, 짧은 상태문, semantic label을 함께 쓴다.
- reveal은 fade, gentle slide, progress fill 수준으로 제한하고 `SoriMotion.reduceMotion`에서 즉시 정적 결과로 강등한다.

### Design-system component contract

새 능력은 다음 공용 surface를 먼저 만들고 화면은 조립만 한다. 이름은 구현 시 저장소 관례에 맞춰 `Sori*`를 사용한다.

| Component | 소유하는 상태 | 금지되는 책임 |
|---|---|---|
| `SoriHanokFutureSocket` | futureLocked, evidenceAvailable, reviewPending, recognizedAssetPending, recoveryReady, earned | 권한 계산, receipt 쓰기, 후보 실제 자산 렌더 |
| `SoriHanokLevelSheet` | 레벨·상태 설명, 가능한 경로, 해당 화면의 단일 CTA | claim 승인, CourseMastery 변경 |
| `SoriRecognitionStatusCard` | draft, submitted, needsMoreInfo, approved, rejected, withdrawn, revoked | raw 문서 URL 노출 |
| `SoriEvidenceFormPage` | upload, redaction 안내, progress, retry, submit | 자동 진위 확정, grant 추론 |
| `SoriHanokRecoveryReveal` | receipt에 명시된 grant의 축약 시공, seen 상태 | 보상 권한 생성, 중복 reveal |

`SoriHanokFutureSocket`의 visual state는 다음을 지킨다.

- `futureLocked`: 반투명 Faceted Hanji 면 + 큰 `?` + 레벨 semantic label
- `evidenceAvailable`: 지도 모양은 유지하고 상세 시트에서만 경로를 설명
- `reviewPending`: 지도 모양은 유지하고 상태 카드에 제출일·다음 행동 표시
- `recognizedAssetPending`: `?` 유지 + “권한 확인됨, 그림 준비 중” 텍스트
- `recoveryReady`: `?`와 별도의 짧은 회수 표시를 함께 제공하되 강한 축하 motif는 회수 화면에만 사용
- `earned`: `assetReadiness == runtime`일 때만 실제 approved asset

상태별 색은 위 의미를 보조할 뿐이다. 물음표의 모양, 상태문, screen-reader label, text-only 장소 목록이 항상 같은 의미를 전달해야 한다.

### Learning and reward authority

- 정상 경로의 영구 한옥 보상은 기존처럼 검증된 productive CanDo 증거에서 파생한다.
- 레벨 직접 선택과 기존 8문항 placement 결과는 학습 시작점만 정한다. 보상을 자동 지급하지 않는다.
- 외부 증빙을 앱 안의 `ProductiveMasteryEvidence`로 변환하거나 CanDo 완료를 조작하지 않는다.
- 외부 증빙과 후속 레벨 테스트는 별도의 한옥 보상 회수 영수증을 만든다. 이 영수증은 CourseMastery, SRS, 코스 완료, CanDo 배지를 바꾸지 않는다.
- 실패·거절·만료·철회가 기존에 정상 학습으로 획득한 보상을 회수해서는 안 된다.
- 에셋이 아직 승인되지 않았다면 자격이 있어도 물음표를 실제 그림으로 대체하지 않는다. 권한과 에셋 준비 상태는 별도 축이다.

## Level completion contract

| 레벨 | 한옥 시대 | 사용자에게 보이는 완성 | 현재 에셋 판정 | 발행 전 조치 |
|---|---|---|---|---|
| A1 | 짓다 | 빈 터에서 외담·솟을대문을 세우고 사랑채 16단계를 완성 | 사랑채 16단계와 솟을대문 축약 단계가 존재 | 담장 우선 진행과 기존 16단계의 grant 수를 어떻게 함께 보존할지 결정 필요 |
| A2 | 살다 | 사랑방 가구, 등불·연기 등 한두 생활 흔적으로 사랑채가 살아남 | 일부 production 가구와 pending overlay가 존재 | 현재 A2의 솟을대문 3 grant를 사랑방·생활 보상으로 다시 매핑 |
| B1 | 잇다 | 내담·중문으로 안쪽을 열고 행랑채·작업마당·안채를 연결 | 행랑채·안채 축약 단계 존재, 중문·우물·작업마당은 부족 | 중문과 영역 소켓을 masterplan에 먼저 확정 |
| B2 | 나누다 | 사당, 곳간·광, 장독·우물 생활경제 영역으로 종가의 기능을 분화 | 사당 축약 단계 존재 | 독립 대청 3 grant를 서비스·의례·경계 보상으로 재매핑 |
| C1 | 돌보다 | 계절, 기와·창호·배수·마당 보수로 집을 오래 유지 | 후원 메가 레이어는 퇴역 대상, 관리 overlay는 미제작 | `rear_garden` 3 grant를 소형 관리·계절 변화로 재매핑 |
| C2 | 전하다 | 서고·별당·문집·현판·방문객 해설로 집의 역사를 전승 | 별당·서고 완성 후보는 pending-review | 후보 육안 QA와 masterplan 승인 전에는 물음표 유지 |

초기 카메라는 바깥길, 외담, 솟을대문 자리, 사랑마당, 사랑채 터만 본다. 진행에 따라 안채·작업·사당·후반 확장 터를 연다. 전체 종가를 첫 화면부터 축소해 보여 주지 않는다.

## Actors and surfaces

### Actors

- **순차 학습자:** 앱의 mission과 assessment로 CanDo 증거를 쌓는다.
- **높은 레벨 시작 학습자:** 레벨을 직접 선택하거나 placement 추천을 수락했지만 앞 레벨의 보상 증거가 없다.
- **증빙 제출 학습자:** 외부 시험 성적표나 평가가 포함된 수업 수료 증빙을 제출한다.
- **검토 운영자:** issuer, 문서 진위 단서, 성적·레벨, 유효기간, 이름과 계정 일치 범위를 검토하고 영수증을 승인·거절·철회한다.
- **한옥 projector:** 세 종류의 권한을 읽되 서로의 의미를 섞지 않는다.

### User surfaces

- 온보딩/placement 완료 화면: “시작 레벨”과 “아직 받지 않은 한옥 보상”을 분리해 설명
- 한옥 지도: A2-C2 future socket과 건너뛴 level bundle을 반투명 물음표로 표시
- 레벨 터 상세 시트: 정상 학습, 외부 증빙 제출, 후속 레벨 테스트 중 가능한 경로를 안내
- 내 증빙: 제출 상태, 보완 요청, 승인 범위, 원본 삭제 예정일, 철회 상태 표시
- 보상 회수 장면: 승인 뒤 보상을 한꺼번에 덤프하지 않고 레벨별 축약 시공 순서로 재생
- 후속 버전의 레벨 테스트: 아직 구현하지 않되 같은 receipt 계약을 사용

### Operator surfaces

- 검토 대기열, 중복 파일 해시 경고, issuer·시험·native level, 제출자 계정, 보완 요청, 승인 범위, 철회 사유
- 원본 문서 보기 권한은 reviewer custom claim을 가진 계정에만 허용
- 승인 동작은 클라이언트 직접 쓰기가 아니라 서버가 불변 receipt를 발행

## Placeholder UI contract

- 각 레벨은 `estate_masterplan_v2`의 고정 future socket 하나 이상을 가진다.
- production 에셋이 없거나 학습자 권한이 없으면 실제 후보 그림이나 실루엣 대신 공용 `SoriHanokFutureSocket`의 중립적인 Faceted Hanji 면과 `?`를 낮은 불투명도로 그린다.
- 물음표는 지도 장식이며, 접근성 이름은 별도 semantic label로 제공한다. 예: “B1 한옥 영역, 아직 받지 않음, 증빙 또는 학습으로 열 수 있음”.
- 물음표 위에 작은 badge·pill·자물쇠를 여러 개 얹지 않는다. 상태 설명과 CTA는 상세 시트의 읽을 수 있는 본문으로 제공한다.
- 상태가 `reviewPending`이면 상세 시트가 제출 일시와 다음 행동을 보여 주되 지도 자산은 계속 물음표다.
- 상태가 `recognized`여도 runtime asset readiness가 `approved`가 아니면 물음표를 유지하고 “권한 확인됨, 그림 준비 중”으로 설명한다.
- 정상 학습의 부분 증거만 있는 다음 grant는 기존 `nextGrantProgress`의 partial-alpha 건축 표현을 사용한다. 이것을 외부 증빙 검토 상태와 혼동하지 않는다.
- 모든 지도 socket은 최소 48x48 logical hit target을 가지며 keyboard focus ring, pressed state, disabled state를 공용 component 안에서 제공한다.
- compact에서는 지도 다음에 선택한 레벨의 상세 카드를 세로로 둔다. medium/expanded에서는 현재 `WorldMapViewport`처럼 지도와 상세를 2-pane으로 둔다. 분기는 device 이름이 아니라 `windowClassFor(constraints.maxWidth)`로 한다.
- 지도 위 글씨가 12px 미만으로 내려가지 않게 한다. 공간이 부족하면 라벨을 줄이거나 상세 패널로 옮기고, 모든 socket을 text-only 장소 목록에서도 접근할 수 있게 한다.
- 증빙 원본과 상태 설명은 지도 위 overlay로 펼치지 않는다. 지도는 진행 개요, 상세 시트·form은 정보와 행동을 맡는다.

## States and transitions

### Asset readiness

```text
planned -> qaCandidate -> approved -> runtime
             |              |
             v              v
          rejected       retired
```

- `planned`와 `qaCandidate`는 항상 물음표다.
- `approved`만 원장·경로·해시 검증을 통과한 뒤 `runtime`으로 승격할 수 있다.
- `retired`인 `rear_garden`과 독립 대청은 새 보상 projector가 읽지 않는다.

### Normal learning

```text
locked -> attainable -> evidenceInProgress -> earned
```

- `earned`는 현재의 exact CanDo·assessment·concept·rubric·prerequisite 검증을 그대로 요구한다.
- placement로 bypass한 course unit은 정상 경로의 권한이 아니다.

### External recognition

```text
draft -> submitted -> reviewPending -> approved -> recoveryReady -> recovered
                     |        |
                     |        +-> expired / revoked
                     +-> needsMoreInfo -> submitted
                     +-> rejected
draft / submitted / rejected -> withdrawn
```

- 승인 receipt는 `coveredGrantIds`를 명시적으로 고정한다. “B1 이상이면 문자열 비교로 앞 레벨 전체” 같은 런타임 추론을 하지 않는다.
- `recoveryReady`는 보상을 받을 자격이고 `recovered`는 학습자가 축약 시공 회수를 완료한 상태다.
- 같은 grant를 나중에 정상 학습으로 증명해도 중복 reveal·중복 소유를 만들지 않는다.

### Future level challenge

```text
unavailable -> eligible -> inProgress -> passed -> recoveryReady
                                |
                                +-> failed -> eligible
```

- 테스트 실패는 집을 손상시키거나 기존 보상을 잃게 하지 않는다.
- `passed`는 외부 증빙과 같은 회수 영수증 인터페이스를 사용하지만 issuer는 `hangulsori_level_challenge_vN`이다.

## Interface contract

### Inputs

- `CourseMasterySnapshot`의 trusted productive evidence
- 승인된 `HanokGrantCatalog`
- `HanokAssetReadinessCatalog`
- 서버가 발행한 `HanokLevelRecognitionReceipt`
- 후속 버전의 `HanokLevelChallengeReceipt`
- learner의 `recoveredGrantIds`와 reveal seen 상태

### Projection output

grant마다 다음을 계산한다.

```text
assetReadiness: planned | qaCandidate | approved | runtime | retired
authority: none | productiveEvidence | externalRecognition | levelChallenge
display: questionMark | partialConstruction | recoveryReady | earnedAsset
```

`authority`가 있어도 `assetReadiness != runtime`이면 `earnedAsset`을 출력하지 않는다. `assetReadiness == runtime`이어도 `authority == none`이면 실제 자산을 소유한 것으로 표시하지 않는다.

### Side effects

- 제출 시 원본을 private Storage에 올리고 claim 문서를 만든다.
- 승인 시 서버가 중복 불가능한 receipt와 명시적 `coveredGrantIds`를 쓴다.
- 회수 완료 시 learner presentation state에 `recoveredGrantIds`와 seen reveal만 기록한다.
- 어떤 경로도 `ProductiveMasteryEvidence`, `completedUnitIds`, SRS, XP를 합성해서는 안 된다.

### Failure and recovery

- 네트워크 실패 시 민감 파일을 무기한 로컬 큐에 남기지 않는다. 업로드 성공 전에는 제출 완료로 표시하지 않는다.
- 같은 사용자·파일 SHA·시험 식별자의 중복 제출은 기존 claim으로 idempotent하게 연결한다.
- 승인과 철회는 receipt ID 및 정책 버전으로 감사 가능해야 한다.
- raw document가 삭제되어도 승인 receipt의 최소 메타데이터·해시·정책 버전으로 지급 근거를 설명할 수 있어야 한다.
- 구버전 클라이언트가 새 receipt를 모르면 CourseMastery나 기존 한옥 상태를 덮어쓰지 않고 무시한다.

## Data implications

### `HanokAssetReadinessCatalog`

```text
manifestVersion
level
socketId
assetIds[]
readiness
approvedLedgerIds[]
```

### `HanokLevelRecognitionClaim`

```text
claimId
ownerUid
claimedLevel
evidenceType: proficiencyCertificate | assessedCourseCompletion | attendanceOnly
issuerCode
credentialNativeLevel
credentialNumberSuffix?  // 전체 번호 저장은 기본 금지
issuedAt?
expiresAt?
fileSha256
storageObjectId
status
privacyNoticeVersion
createdAt / updatedAt
```

### `HanokLevelRecognitionReceipt`

```text
receiptId
ownerUid
claimId
recognizedLevel
coveredGrantIds[]
mappingPolicyVersion
reviewerUid
decisionAt
sourceFileSha256
state: active | revoked | expired
reasonCode
```

### `HanokRecoveryState`

기존 `HanokState`와 합칠지는 아키텍처 검토에서 결정하되, CourseMastery와는 분리한다.

```text
receiptIds[]
recoveredGrantIds[]
seenRecoveryRevealIds[]
```

## Evidence acceptance policy

- 후보 issuer allowlist에는 공식 한국어 숙달도 시험처럼 issuer·성적·레벨·유효기간을 검증할 수 있는 체계만 넣는다. TOPIK과 세종한국어평가(SKA/iSKA)는 검토 후보이지 이 문서만으로 자동 CEFR 등가를 선언하지 않는다.
- 시험 고유 등급과 CEFR는 별도 값으로 보존한다. 매핑은 `mappingPolicyVersion`이 있는 수동 승인표를 사용한다.
- **단순 수업 참여증은 실력 증명이 아니다.** `attendanceOnly` 하나만으로 직접 recovery receipt를 발행하지 않고, 보완 자료를 요청하거나 후속 레벨 테스트의 `eligible` 상태만 연다.
- 평가 결과와 레벨이 명시된 수료증은 `assessedCourseCompletion`으로 별도 검토할 수 있다.
- 이름이 다른 경우 자동 거절하지 않고 개명·로마자 표기 차이를 보완할 수 있게 하되, 신분증 업로드를 기본 요구하지 않는다.

## Security and privacy

- 외부 문서는 이름, 생년월일, 수험번호 등을 포함할 수 있으므로 일반 학습 데이터보다 강한 private boundary를 사용한다.
- 제출 전에 불필요한 생년월일·주소·사진·전체 수험번호를 가리는 안내와 crop/redaction 도구를 제공한다.
- 원본 URL을 Firestore 공개 문서나 analytics에 넣지 않는다. analytics에는 claim 상태와 익명 reason code만 보낸다.
- owner는 자기 claim 상태만 읽고, raw document는 명시적 재확인 때만 본다. reviewer는 custom claim과 감사 로그를 요구한다.
- 원본은 결정과 이의제기에 필요한 짧은 기간만 보존하고 자동 삭제한다. 정확한 보존 기간은 개인정보 검토에서 확정한다.
- 계정 삭제는 원본·claim·receipt·recovery state의 삭제 또는 법적 보존 예외 처리를 함께 정의해야 한다.
- Firebase Storage·Firestore rules, callable authorization, App Check, reviewer 권한, 삭제 재시도와 orphan cleanup을 구현 전에 별도 보안 검토한다.

이 경계는 GDPR Article 5의 목적 제한, 데이터 최소화, 저장 제한 원칙을 제품 요구로 반영한다. 법률 자문을 대체하지 않는다.

## Non-goals

- 이 단계에서 새 한옥 이미지를 생성하지 않는다.
- `rear_garden` 분해, 정자·연못 제작, 별당·서고·pending 소품 승격을 하지 않는다.
- 현재 8문항 placement diagnostic을 보상 시험으로 재사용하지 않는다.
- OCR이나 생성형 AI로 자격증 진위를 자동 확정하지 않는다.
- 외부 증빙으로 CourseMastery, CanDo, SRS, XP, 코스 완료율을 올리지 않는다.
- Gye 공동 한옥의 성장·소유·기부 규칙을 바꾸지 않는다.
- C2 이후 장인 루프와 계절 앨범을 이 첫 능력에 포함하지 않는다.

## Open questions

구현을 시작하기 전에 다음 결정을 기록해야 한다.

1. **담장 우선과 A1 16 grant 보존:** 권장안은 기존 16개를 재작성하지 않고 `외담 기단 -> 외담 완성 -> 솟을대문` 3개를 앞에 두는 additive A1 boundary prologue다. 새 평가·grant 3개를 만들지, 첫 A1 mission의 비권한적 guided prologue로 둘지 아키텍처 검토가 필요하다.
2. **외부 증빙의 회수 범위:** 인정 B1이 A1-A2만 회수하게 할지, B1까지 회수하게 할지 제품 결정이 필요하다. 권장안은 `coveredGrantIds`를 reviewer가 정책표로 명시하고 현재 레벨의 핵심 구조는 앱 안 학습 또는 레벨 테스트로 남기는 것이다.
3. **Issuer allowlist와 레벨 매핑:** TOPIK, SKA/iSKA, 대학·세종학당 수료증을 어떤 조건으로 인정할지 운영 정책이 필요하다.
4. **검토 운영자:** 초기 reviewer를 Jin 한 명으로 둘지, Firebase admin 웹 화면을 만들지 결정해야 한다.
5. **원본 보존 기간과 이의제기:** 개인정보 검토 후 일수를 확정해야 한다.
6. **물음표의 레벨 단위:** 레벨당 대표 future socket 하나인지, 해당 레벨의 여러 건축 socket인지 `estate_masterplan_v2`에서 결정해야 한다. 권장안은 기본 줌의 밀도를 지키기 위해 레벨당 대표 1개, 포커스 진입 후 세부 socket이다.

## Phased implementation plan

각 단계는 독립 승인·회귀 지점을 가진다. 앞 단계가 완료되지 않으면 민감 업로드나 새 이미지 제작으로 넘어가지 않는다.

### Phase 0 — 결정 동결과 masterplan

**산출물**

- `estate_masterplan_v2`: 빈 터, 외담 기단, 외담 완성, 솟을대문, 사랑채 16단계, 내담·중문, 안채와 후반 영역의 고정 socket·카메라 reveal 순서
- 86개 draft grant의 새 level/structure mapping 표. A2 솟을대문, B2 독립 대청, C1 rear garden을 제거·재매핑
- 위 Open questions 1-6의 결정 기록
- issuer allowlist 초안, native level-to-grant 정책표, 원본 보존·삭제·이의제기 정책
- Design Bible 원칙과 기존 `Sori*` 값의 차이표. 이번 기능에 필요한 semantic token만 먼저 확정

**완료 게이트**

- 새 이미지 없이 와이어프레임·socket 좌표·상태표를 Jin이 승인
- Gye, CourseMastery, SRS와의 비의존 경계를 아키텍처 리뷰가 승인
- 개인정보·Firebase Security Rules 위협 모델이 검토됨

### Phase 1 — Design-system foundation slice

**구현 범위**

- 기존 `SoriColors/SoriSurfaces` 위에 필요한 semantic role을 중앙화하고 screen raw 값 금지
- `SoriHanokFutureSocket`, `SoriHanokLevelSheet`, `SoriRecognitionStatusCard`의 상태 API와 component tests
- `WorldMapViewport`가 `AppWindowClass`를 사용하도록 수렴하고 compact/medium/expanded 배치를 고정
- DE/EN ARB 쌍과 KO 학습 문자열 정책을 보존

**완료 게이트**

- 320, 360, 390, 430, 600, 768, 840, 1024, 1280 폭의 대표 골든
- KO/EN/DE, text scale 100/130/160/200에서 잘림 없이 기능 완료
- 48dp target, 4.5:1 body contrast, 3:1 meaningful non-text contrast, keyboard focus, screen reader, reduced motion 검증
- 기존 personal Hanok 골든과 Sori component 골든의 의도하지 않은 변화 0

### Phase 2 — 순수 domain projector

**구현 범위**

- `HanokAssetReadinessCatalog`, recognition/challenge receipt, recovery state의 pure Dart model
- `assetReadiness x authority -> display` projector
- 기존 `HanokExperienceProjector`의 productive evidence 경로를 입력으로 재사용하되 변경하지 않음
- feature flag 뒤에서 draft catalog를 새 매핑으로 읽는 adapter

**완료 게이트**

- 자기선택·placement·unit completion·bypass만으로 grant 0
- receipt의 `coveredGrantIds` 외 grant 0
- runtime asset과 authority가 모두 있을 때만 actual asset
- duplicate, revoked, expired, offline replay, old client의 fail-closed 단위 테스트

### Phase 3 — 읽기 전용 future socket

**구현 범위**

- 실제 계정 업로드 없이 A2-C2 대표 socket을 feature flag로 표시
- 정상 학습 부분 진행, 건너뜀, review mock, recognized-asset-pending, recovery-ready 상태를 fixture로 시각 검증
- 지도 선택 -> level sheet -> 기존 학습 경로까지 연결
- text-only 장소 목록에서 동일 상태·행동 제공

**완료 게이트**

- runtime 미승인 후보 이미지가 bundle path로 새지 않음
- rear garden·독립 대청·Gye layer가 새 projector와 화면에서 0건
- 작은 화면, 태블릿 2-pane, 키보드, screen reader, reduced motion 검증
- Jin이 물음표의 크기·투명도·맵 여백·카메라 reveal을 실기기에서 승인

### Parallel asset lane — masterplan 이후에만

**순서**

1. production assets를 새 master canvas에 재배치해 건물 간 거리와 빈 마당을 검증
2. pending-review 별당·서고·소품을 개별 육안 QA하고 승인 또는 거절
3. 레벨별 missing asset만 Faceted Minhwa/무광 목재/한지 그레인 계약으로 제작
4. ledger, hash, provenance, transparent-edge, fixed-canvas 검증 후 `runtime` 승격

사용자 권한 구현과 에셋 제작은 병렬일 수 있지만, 어느 쪽도 다른 쪽의 부족을 숨기지 않는다. 에셋만 준비되면 여전히 `?`, 권한만 준비되면 “그림 준비 중”이다.

### Phase 4 — 외부 증빙 backend와 운영 검토

**구현 범위**

- linked account 전제의 private upload, redaction 안내, claim 상태, retry/idempotency
- reviewer custom claim, private document access, immutable decision audit, explicit receipt issuance
- owner deletion, retention cleanup, orphan cleanup, account deletion cascade
- 최소 운영 화면: 대기열, 보완 요청, 승인 범위, 거절·철회. 자동 CEFR 판정은 없음

**완료 게이트**

- Storage/Firestore/callable rules의 소유자·reviewer·App Check 테스트
- URL·PII analytics 유출 0, 로그 redaction, 중복 파일·재시도·권한 강등 테스트
- attendance-only가 직접 receipt를 만들 수 없음
- 개인정보 고지와 보존 기간을 Jin이 승인

### Phase 5 — 회수 reveal과 정합성

**구현 범위**

- approved receipt -> `recoveryReady` -> 사용자가 시작하는 레벨별 축약 시공 reveal
- recovered/seen presentation state 동기화와 중복 방지
- 정상 학습으로 나중에 같은 grant를 얻는 경로와 합집합 처리

**완료 게이트**

- 한 grant당 소유·reveal 1회
- 실패·철회가 정상 학습 자산을 제거하지 않음
- reduce motion에서는 애니메이션 없이 동일 최종 상태
- CourseMastery, SRS, XP 직렬화 before/after byte-equivalent 확인

### Phase 6 — 후속 level challenge

현재 8문항 placement와 분리된 assessed challenge를 별도 설계한다. 녹음·쓰기 등 productive evidence, 시험 보안, 재응시 정책, 접근성을 먼저 정의한 뒤 같은 explicit `coveredGrantIds` receipt 인터페이스에 연결한다. 이 단계 전에는 UI에 “곧 제공” 이상의 시험 약속을 넣지 않는다.

## Handoff

- **직접 구현 준비:** 아직 아님
- **먼저 필요한 것:** Phase 0의 `estate_masterplan_v2`, 위 1-6 결정, semantic token delta, 개인정보·Firebase Security Rules 검토
- **첫 구현 순서:** Design-system component slice -> pure projector -> 읽기 전용 future socket. 민감 업로드보다 먼저 fail-closed projection과 UI를 검증한다.
- **그 다음:** linked account claim·review·receipt backend -> 승인 receipt 기반 회수 장면
- **후속:** 별도 assessed level challenge를 같은 receipt 인터페이스로 추가
- **다음 ECC lane:** 아키텍처 검토 후 `project-flow-ops`, 각 slice는 TDD와 verification loop 적용

## Verification contract

- 자기선택 placement만으로 어떤 grant도 earned가 되지 않는다.
- trusted productive evidence는 기존 결과와 동일한 grant를 낸다.
- external receipt는 명시된 `coveredGrantIds`만 `recoveryReady`로 만들고 CourseMastery JSON을 바꾸지 않는다.
- attendance-only claim은 직접 receipt를 만들지 않는다.
- `assetReadiness != runtime`이면 어떤 권한에서도 실제 자산 경로를 출력하지 않는다.
- revoked·expired receipt는 아직 회수하지 않은 보상을 막되 정상 학습 보상은 유지한다.
- 같은 grant를 외부 회수 뒤 정상 학습해도 reveal과 소유가 하나다.
- `rear_garden`과 독립 대청은 새 projector 출력에 없다.
- Gye state와 개인 한옥 receipt 사이에 read/write 의존성이 없다.
- 계정 삭제·원본 retention cleanup·업로드 중단의 orphan 경로를 테스트한다.
- 320dp, 390dp, 태블릿, 130%·200% 텍스트에서 물음표 semantic label과 상세 CTA가 접근 가능하다.
- compact/medium/expanded 전환이 `windowClassFor` 한 곳에서 결정되고 화면별 임의 breakpoint가 없다.
- future/review/recognized/recovery 상태는 색을 제거해도 `?`, 아이콘, 문구, semantic label로 구분된다.
- 한 화면에 primary CTA가 하나를 넘지 않고, 지도 화면에 sticky CTA가 생기지 않는다.
- 새 Hanok surface에 raw hex, raw font size, raw radius, raw spacing, device-name layout branch가 없다.
- KO/EN/DE와 100/130/160/200% text scale에서 제출·상태확인·회수 흐름을 완료할 수 있다.

## Reviewed external source artifacts

아래 원본은 active repository 문서가 아니며 이 계획에 복사하지 않는다. 파일명, 검토 당시 수정 시각, 행·레코드 수와 SHA-256으로 사용한 입력을 식별한다. CSV count는 header를 제외한 data row 수다.

| Source artifact | Count | Last modified (Europe/Berlin) | SHA-256 |
|---|---:|---|---|
| `pasted-text.txt` | 1,003 lines | 2026-08-20 13:34:48 +02:00 | `ffd8b370bb0571d21d8ec82a35abb41a7b3fe9711a181195bc42ba5a0f0e293e` |
| `딥리서치-한옥과한글소리.md` | 1,027 lines | 2026-08-20 13:36:46 +02:00 | `2b856bf6fff68aeebb56fb2809ff1a6fba75cca944d71a9b9ff419fc52cb4116` |
| `hanok_asset_inventory_decisions.csv` | 220 rows | 2026-08-20 13:37:50 +02:00 | `6c4bf507b6a6ee07ef62d60d1a8f5441ba9da784b6131fd88739c5621c3798b3` |
| `hanok_required_assets_roadmap.csv` | 28 rows | 2026-08-20 08:53:05 +02:00 | `094b79ffc69fcae0885a86092da28be96d7790e2f0d40cd2ba2ac7dda8aa6aa5` |
| `UIUX_Audit_DesignBible_Idea.md` | 2,153 lines | 2026-08-20 11:41:05 +02:00 | `5a7ccde48add72d236b393bb6e589d7cb23d80e3dc4fd1daa05a2fbbef08c2ec` |

`pasted-text.txt`는 로그인이 필요한 private ChatGPT 링크 대신 사용한 전체 대화 입력이다. 원본의 장기 보존·삭제는 repository 밖의 사용자 보관 정책이며 구현자가 이 로컬 파일을 요구해서는 안 된다.

## References

- `docs/plans/2026-08-16-living-hanok-v1-execution.md`
- `docs/superpowers/specs/2026-08-17-living-hanok-v1-mapping-kit-pipeline-design.md`
- `tools/content_factory/drafts/hanok_grants.json`
- `lib/services/hanok_experience_projector.dart`
- `lib/services/productive_assessment_service.dart`
- `lib/services/placement_diagnostic.dart`
- `lib/data/personal_hanok_estate_stage_catalog.dart`
- `docs/assets/STYLE_LOCK.json`
- `docs/HANGUL_SORI_DESIGN_TOKENS.md`
- `lib/widgets/sori/tokens.dart`
- `lib/widgets/sori/window_class.dart`
- `lib/widgets/sori/world_map_viewport.dart`
- GDPR Article 5: https://eur-lex.europa.eu/eli/reg/2016/679/oj
- TOPIK official site: https://www.topik.go.kr/
- King Sejong Institute Foundation, SKA/iSKA: https://www.ksif.or.kr/
