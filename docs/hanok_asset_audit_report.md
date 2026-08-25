# 한글소리 한옥 에셋 전수 감사와 종가 V2 구현안

**감사 기준일:** 2026-08-19  
**저장소:** `Sujin-Arin-DataWorld/ko_lernen_app`, `main`  
**직접 육안 검수:** 최신 Android 내부테스트 AAB에 실제 번들된 한옥 관련 이미지 112장  
**저장소 분류 검수:** `assets_unused`와 `pending_review`의 후보, 원본, QA, 폐기본 108장  
**총 의사결정 행:** 220장

> 이 보고서의 핵심 결론은 단순하다. **한글소리의 화풍은 버리지 않는다. 지도 구성을 다시 짠다.**

## 1. 최종 판정

현재 한옥이 복잡하고 오래된 게임처럼 보이는 원인은 Faceted Minhwa 재질이 아니다. 실제 번들 이미지는 따뜻한 한지 그레인, 무광 목재, 면분할 기와와 석축이 잘 맞는다. 문제는 다음 네 가지다.

1. `site_base_light.png`에 돌, 풀, 꽃, 나무, 길이 이미 너무 많이 구워져 있어 마당이 비지 않는다.
2. `rear_garden.png` 한 장에 연못 두 개, 다리, 정자, 수목, 괴석, 꽃, 장독대가 함께 들어 있다.
3. 사랑채, 안채, 행랑채, 솟을대문, 사당, 독립 대청이 모두 같은 종류의 보상 실루엣처럼 누적된다.
4. 실내 배경은 외부의 Faceted Minhwa보다 더 사실적이고 단청이 강해 한 세트처럼 보이지 않는다.

따라서 다음을 고정한다.

| 구분 | 최종 결정 |
|---|---|
| 화풍 | **유지.** 한지 질감, 무광, 면분할, 저채도 목재와 기와를 정본으로 잠근다. |
| 사랑채 | **절대 재생성하지 않는다.** 현재 지도의 주인공으로 유지한다. |
| 안채, 행랑채, 솟을대문, 사당 | **재생성하지 않는다.** masterplan에서 위치, 크기, 경계만 다시 잡는다. |
| 대청마루 외관 | **세계지도 건물 목록에서 제거한다.** 사랑대청과 안대청의 내부 venue로 바꾼다. |
| 현재 후원 | **단일 메가 레이어를 퇴역한다.** 화계, 수목, 작은 연못, 정자로 분해한다. |
| 현재 대지 | **재질은 살리고 구성을 다시 합성한다.** 마당 중앙을 비우고 중문과 작업영역 소켓을 만든다. |
| A1 16단계 | **전부 유지한다.** 단, 완성 종가 안에서 시작하지 않도록 sparse A1 base를 별도로 둔다. |
| 실내 3장 | 슬롯 계약은 유지하고 배경은 단계적으로 V2로 교체한다. |
| Gye 자산 | Gye 기능 안에서만 유지한다. 개인 종가에 픽셀 재사용하거나 모델 입력으로 넣지 않는다. |
| 구 `hanok_compound` | 아카이브만. 복원하지 않는다. |

## 2. 왜 현재 완성 장면이 복잡해 보이는가

### 2.1 현재 완성 장면

![현재 전체 종가](01_current_full_estate.png)

후원 레이어가 지도의 뒤쪽 절반을 사실상 점유한다. 장독대까지 후원 안에 들어가 있고, 연못 두 개와 정자가 동시에 영웅 요소로 경쟁한다. 사랑마당과 안마당에는 이미 베이스 식생과 돌이 많아 건물을 빼도 여백이 충분하지 않다.

### 2.2 후원 레이어만 제거한 장면

![후원 제거 비교](02_current_estate_without_rear_garden.png)

후원 한 장을 빼는 것만으로 건물 위계와 마당이 훨씬 선명해진다. 이것은 건물 화풍이 문제가 아니라 **메가 레이어와 고정 배경의 밀도**가 문제라는 직접 증거다. 다만 베이스 자체에도 식생과 돌이 많으므로 여기서 끝내면 안 된다.

## 3. 지금 즉시 지켜야 할 아트 헌법

1. 세계지도는 건물 근접뷰보다 디테일을 30%에서 40% 덜 그린다.
2. 기본 줌에는 지붕, 담, 문, 마당, 큰 수목, 계절만 보인다.
3. 실내 가구는 세계지도에 절대 올리지 않는다.
4. 한 마당의 영웅 요소는 하나다. 정자, 연못, 큰 나무를 동시에 주인공으로 만들지 않는다.
5. 사랑마당과 사당마당은 대부분 비운다.
6. 장독과 우물은 후원이 아니라 안채 뒤와 작업마당에 둔다.
7. 새 건물은 완성본 한 장을 먼저 승인하고, 그 기하를 역분해해 시공 상태를 만든다.
8. 기존 전체 장면을 모델에게 다시 그리게 하지 않는다. 기존 장면 위 투명 RGBA 레이어만 누적한다.
9. 이미지 생성 참조는 스타일 계약이 허용한 정본 한 장만 사용한다.
10. 원장 append, 육안 QA, 카탈로그, pubspec, 렌더러를 분리하지 않는다. 런타임 승격은 한 묶음으로 한다.

## 4. 폐기와 보존의 정확한 경계

### 4.1 실제로 버려야 하는 것

* 세계지도 독립 건물로서의 `daecheongmaru.png`와 그 시공 체인
* 단일 런타임 메가 레이어로서의 `rear_garden.png`와 `rear_garden_s3_final.png`
* `byeoldang_try1_floating_roof...`, `byeoldang_try2_rotated_camera...` 실패본의 재사용 가능성
* 사랑마당 장독 배치 후보 B
* 개인 종가에 대한 Gye 자산 직접 재사용
* V2 생성 참조로서의 `hanok_compound`, `hanok_stages`, 구 수채 대문 장면

### 4.2 파일을 삭제할 필요는 없지만 런타임에서 내려야 하는 것

* 기존 `rear_garden.png`: 원본 보존 후 모듈 분해 재료로만 사용
* `daecheongmaru.png`: 내부 venue 계약이나 회귀 기록으로만 보관
* `anbang_empty.png`, `daecheong_empty.png`, `sarangbang_empty.png`: 슬롯 호환을 위해 임시 유지하되 교체 계획을 고정
* `stage_*_light.png`: 학습경로 헤더가 쓰는 동안만 레거시 UI로 유지

### 4.3 절대로 다시 만들지 말아야 하는 것

* `sarangchae.png`
* `anchae.png`
* `haengrangchae.png`
* `sotdaeulmun.png`
* `sadang.png`
* A1 16개 구조 상태
* production에 이미 승격된 A2 가구 13종

## 5. 지금 필요한 에셋

아래 순서는 생성 순서가 아니라 **제품 선행조건 순서**다. P0가 끝나기 전에는 새 별당이나 서고를 지도에 넣지 않는다.

| priority   | asset                                     | type                        | source_strategy                          | status      | purpose                                                        | implementation_notes                                                                                         |
|:-----------|:------------------------------------------|:----------------------------|:-----------------------------------------|:------------|:---------------------------------------------------------------|:-------------------------------------------------------------------------------------------------------------|
| P0         | site_base_v2_master.png                   | Infrastructure/Map          | 기존 site_base_light 재합성              | 필수        | 마당별 빈 면과 경계 소켓을 가진 새 1536×1152 대지              | 기존 한지·석축 재질 유지. 식생/돌 60~70% 제거. 남쪽 진입, 사랑마당, 중문축, 안마당, 사당영역, 후원영역 고정. |
| P0         | estate_masterplan_v2.json                 | Layout manifest             | 신규 코드/데이터                         | 필수        | 건물 위치·bbox·z·hit zone·yard socket의 단일 정본              | 이미지보다 먼저 승인. 사랑채 위치 이동 같은 임시 collision fix를 이 manifest로 종결.                         |
| P0         | a1_sparse_site_base.webp/png              | A1 base                     | site_base_v2 파생                        | 필수        | A1 1~16 상태가 완성 종가 안에서 시작하지 않게 하는 sparse base | 외곽 담 일부, 앞길, 사랑채 터만 활성. 미래 영역은 막힘/저채도 처리.                                          |
| P0         | rear_garden_hardscape.png                 | Infrastructure              | 기존 rear_garden 분해/재합성             | 필수        | 후원 화계·석축·산책로의 뼈대                                   | 연못·정자·수목·장독을 제거한 투명 RGBA 레이어.                                                               |
| P0         | rear_garden_hero_tree.png                 | Ambience/Landscape          | 기존 수목 또는 sonamu/maehwa 재배치      | 필수        | 후원을 프레이밍하는 영웅 수목 1개                              | 중앙 스티커 금지, 화면 가장자리/정자 뒤에서 일부 잘림 허용.                                                  |
| P0         | jangdok_small_2.png / jangdok_small_3.png | Infrastructure/Life         | 기존 jangdokdae/overlay crop             | 필수        | 안채 뒤·작업마당용 소형 장독                                   | 신규 생성 불필요. Candidate A 좌표.                                                                          |
| P1         | jungmun_ilgakmun.png                      | Infrastructure              | 신규 생성 후 fixed-canvas 합성           | 최우선 신규 | 사랑영역과 안채영역을 분리하는 중문/일각문                     | 완성본 먼저 승인 후 foundation→frame→roof→final 4단계 역분해.                                                |
| P1         | wall_module_front_left/right.png          | Infrastructure              | 신규 또는 기존 담 crop                   | 최우선 신규 | 솟을대문·행랑·중문·사당담을 연결하는 담장 모듈                 | 직선 2, 코너 2, 문 접속 2 정도. 독립 장식이 아니라 경계 생성.                                                |
| P1         | gokgan_service_wing.png                   | Architecture/Infrastructure | haengrangchae 기하 파생 우선             | 최우선 신규 | 곳간·광·창고를 포함한 생활경제 영역                            | 새 독립 화려한 집보다 낮고 단순한 맞배 wing.                                                                 |
| P1         | well_workyard.png                         | Infrastructure/Interactive  | 신규 생성                                | 최우선 신규 | 행랑·작업마당의 중심 언어행동 소켓                             | 물 긷기, 수량, 순서, 위치 퀘스트. 주변 소품은 별도.                                                          |
| P1         | jeongja_simple.png                        | Architecture                | 신규 생성                                | 높음        | 후원 휴식·시·계절 콘텐츠 venue                                 | Gye 정자 직접 재사용 금지. 무단청에 가까운 간결한 정자, 작은 실루엣.                                         |
| P1         | hwagye_stone_kit.png                      | Infrastructure              | 기존 rear_garden/돌담 재합성 + 일부 신규 | 높음        | 후원 깊이를 건물 없이 만드는 계단식 화계·석축                  | 2~4개 모듈, 과한 꽃/연못 없음.                                                                               |
| P1         | workyard_props.png                        | Ambience/Interactive        | 신규 소품 시트 1장                       | 높음        | 빨랫줄, 물동이, 광주리, 장작더미, 짚/도구                      | 동시에 1~2 cluster만 표시. 각각 독립 cutout.                                                                 |
| P1         | sarangbang_empty_v2.png                   | Interior background         | 신규 재제작                              | 높음        | F-A 가구와 같은 재질의 사랑방                                  | 1086×1448, 무광·한지·절제된 목재, 장식띠 제거, 빈 슬롯 유지.                                                 |
| P1         | anbang_empty_v2.png                       | Interior background         | 신규 재제작                              | 높음        | 안방 가구·경대·반닫이용 공간                                   | 무단청, 따뜻한 온돌방, 벽장/창호, 과한 궁중 장식 금지.                                                       |
| P1         | sarang_daecheong_empty_v2.png             | Interior background         | 신규 재제작                              | 높음        | 사랑대청/토론 venue                                            | 열린 마루·기둥·후원 조망. 평상시 비움.                                                                       |
| P1         | an_daecheong_empty_v2.png                 | Interior background         | 신규 재제작 또는 1차 보류                | 중간        | 안채 가족행사 venue                                            | 사랑대청과 기능이 실제로 분리될 때만 별도 제작. 초기에는 하나의 daecheong venue로 시작 가능.                 |
| P2         | small_pond_optional.png                   | Landscape option            | 기존 decoration_pond 조정                | 조건부      | 후원 선택형 작은 연못                                          | 정자·연못 둘 다 hero가 되지 않도록 한쪽만 강조. 화면 10% 미만.                                               |
| P2         | season_spring_maehwa.png                  | Ambience                    | 기존 maehwa 활용                         | 조건부      | 봄 상태                                                        | 한 번에 계절 오버레이 1개.                                                                                   |
| P2         | season_autumn_leaves.png                  | Ambience                    | 신규 생성/프로그램 합성                  | 필수 C1     | 가을·돌봄 이벤트                                               | 낙엽 몇 장과 배수로, 화면 전체 낙엽 금지.                                                                    |
| P2         | season_winter_snow.png                    | Ambience                    | 신규 생성/마스크 합성                    | 필수 C1     | 겨울 상태                                                      | 지붕/담/나무 상부에만 얇은 눈.                                                                               |
| P2         | weather_rain_eaves.png                    | Ambience                    | 신규 또는 셰이더                         | C1          | 비·장마 점검                                                   | 처마 빗물/젖은 마당 중 하나만.                                                                               |
| P2         | maintenance_broken_tile.png               | Maintenance overlay         | 신규 소형 cutout                         | C1          | 기와 보수 퀘스트                                               | 실패 벌점이 아니라 발견→수리 전후 상태.                                                                      |
| P2         | maintenance_torn_changho.png              | Maintenance overlay         | 신규 소형 cutout                         | C1          | 창호지 보수 퀘스트                                             | 건물 전체 재생성 금지, 창호 영역 overlay.                                                                    |
| P2         | maintenance_drain_leaves.png              | Maintenance overlay         | 신규 소형 cutout                         | C1          | 배수 정리 퀘스트                                               | 작업마당/처마 배수 위치에만.                                                                                 |
| P2         | byeoldang_finished.png                    | Architecture                | 기존 pending 후보                        | 검수 후     | 후반 NPC·서사 공간                                             | 새로 생성하지 말고 masterplan 승인 후 후보 검수.                                                             |
| P2         | seogo_finished.png                        | Architecture/Interior       | 기존 pending 후보                        | 검수 후     | C2 문집·문헌 공간                                              | 독립 건물 vs 사랑채 wing 결정 후 승격.                                                                       |
| P2         | pending_props_9                           | Interior furnishing         | 기존 pending 후보                        | 선별 승격   | 백자병·경대·망건통·연상 등                                     | 공간별로 나누고 한 화면 luxury budget 적용.                                                                  |

## 6. 권장 구현 순서

### Phase 0: 동결과 정본화

1. 현재 production 112장과 pending 후보의 SHA, 원장, 카탈로그 상태를 스냅샷으로 고정한다.
2. `a2_furnishing`의 cut/normalized 26장은 production 중복으로 분류하고 다시 승격하지 않는다.
3. 별당, 서고, 신규 소품 9종, 외관 오버레이 5종은 추가 생성하지 않는다.
4. 실패 별당 두 장은 `rejected`를 유지하고 스타일 모델 입력에서 차단한다.

### Phase 1: 종가 masterplan V2

1. 이미지 생성 전에 `estate_masterplan_v2.json`을 만든다.
2. 남쪽 진입부터 솟을대문, 행랑마당, 사랑마당, 중문, 안마당, 후원, 사당영역의 축을 좌표로 고정한다.
3. 현재 40px 사랑채 이동 같은 임시 보정 대신 모든 bbox, z, hit zone을 새 manifest에 넣는다.
4. 대청 외관 zone을 삭제하고 사랑채/안채 내부 진입점으로 바꾼다.

### Phase 2: 대지와 후원 재합성

1. `site_base_v2_master.png`를 먼저 만든다.
2. 현재 대지에서 자잘한 식생과 돌을 60%에서 70% 제거한다.
3. `rear_garden.png`를 화계·석축, 영웅 수목, 작은 연못, 정자, 계절 상태로 분해한다.
4. 장독대는 안채 뒤 candidate A로 옮긴다.
5. 이 단계에서 완성 지도 한 장을 먼저 승인한다.

### Phase 3: 기존 축약 시공 체인 배선

1. 안채 4단계
2. 행랑채 4단계
3. 솟을대문 3단계
4. 사당 3단계
5. 새 중문 4단계

production에 이미 있는 14개 지도 단계가 현재 렌더러에 연결되지 않았으므로, 새 그림보다 먼저 stage renderer와 grant projector를 연결한다.

### Phase 4: 생활 영역과 실내

1. 사랑방: 서안, 문방사우, 연상, 고비, 바둑, 거문고, 보료를 행동 소켓으로 묶는다.
2. 안방: 경대, 반닫이, 자개함 또는 보석함, 침구를 배정한다.
3. 작업마당: 우물, 빨랫줄, 물동이, 광주리, 장작을 배정한다.
4. 서고: 책가도, 백자병, 문집을 배정한다.
5. 같은 방에 고급 장식물을 여러 개 기본 노출하지 않는다.

### Phase 5: 살아 있는 상태와 C레벨 루프

한 번에 한두 개만 바뀐다. 굴뚝 연기, 저녁 등불, 용마루 까치, 봄 매화, 가을 낙엽, 겨울 눈, 깨진 기와, 찢어진 창호, 배수로 낙엽을 조건부 레이어로 둔다.

## 7. 출시 게이트

| 게이트 | 통과 기준 |
|---|---|
| Masterplan | 기본 줌에서 사랑마당, 안마당, 작업마당, 사당마당이 서로 구분된다. |
| 여백 | 사랑마당과 사당마당 중앙 60% 이상이 시각적으로 비어 있다. |
| 실루엣 | 기본 지도에 독립 건축 실루엣은 사랑채, 안채, 행랑·대문, 사당, 후반 별당/정자 정도로 제한한다. |
| 스타일 | 외부 F-C와 실내 F-A/F-D가 한지 무광, 면분할, 저채도 목재로 연결된다. |
| 역사 구조 | 대청이 독립 건물 카드로 표시되지 않고, 중문과 사당담이 공간 위계를 만든다. |
| 밀도 | 한 마당의 생활/장식 cluster는 기본 1개, 최대 2개다. |
| 기술 | fixed canvas, 동일 카메라, 투명 RGBA, 원장, 카탈로그, pubspec, 렌더러가 한 PR에서 통과한다. |
| 회귀 | A1 16단계의 기하와 순서는 변하지 않는다. |

## 8. 이미지별 판정

아래 표는 실제 번들 112장과 저장소 후보·아카이브 108장을 파일 단위로 분류한 것이다. `직접 육안 검수`는 최신 앱 번들에서 픽셀을 확인한 경우다. `육안 QA 필요`는 저장소에 있으나 현재 앱 번들 밖인 신규 후보다.

### 개인 한옥 지도

| 파일 | 역할 | 판정 | 우선 | 평가 | 구현 |
|---|---|---|---:|---|---|
| `assets/illustrations/personal_hanok_v2/map/site_base_light.png` | 대지·담장·마당 베이스 | **재구성** | P0 | 한지·석축·토질 재질과 카메라는 정본에 가깝다. 그러나 식생·돌·오솔길이 이미 전면에 구워져 있어 마당이 비지 않고, 향후 중문·작업마당·사당 경계를 넣을 여백이 없다. | 원본은 보존하고 site_base_v2를 새로 합성한다. 담·기단·마당 면은 살리고 자잘한 초목/돌은 60~70% 제거하며 사랑마당·행랑마당·안마당·작업마당 소켓을 명시한다. |
| `assets/illustrations/personal_hanok_v2/map/landscape/rear_garden.png` | 후원 메가 레이어 | **런타임 퇴역·분해** | P0 | 연못 2개, 다리, 정자, 수목, 괴석, 꽃, 장독대가 한 장에 묶여 후원이 건축보다 더 큰 주인공이 된다. 종갓집보다 판타지 정원 리조트처럼 읽히는 핵심 원인이다. | 단일 레이어 사용을 중단한다. 화계/석축, 영웅 수목, 보조 수목, 작은 연못, 정자, 계절 오버레이로 분해한다. 장독대는 안채 뒤 또는 작업영역으로 이동한다. |
| `assets/illustrations/personal_hanok_v2/map/structures/sarangchae.png` | 사랑채 완성형 | **정본 유지** | P0 | 현재 세트에서 가장 강한 영웅 건축물이다. 처마선, 목재, 창호, 한지 질감이 한글소리의 고급 Faceted Minhwa 감각을 가장 잘 보존한다. | 재생성 금지. masterplan V2에서 위치·축척·z만 조정한다. 사랑대청/누마루 개방감은 내부 진입과 포커스 연출로 보강한다. |
| `assets/illustrations/personal_hanok_v2/map/structures/anchae.png` | 안채 완성형 | **유지·재배치** | P0 | ㄷ/U자 안마당을 형성하는 실루엣이 좋고 사랑채와 같은 재질군이다. 다만 현재는 중문 없이 바로 노출되어 사적 영역의 위계가 약하다. | 재생성하지 않는다. 중문·담장과 함께 뒤쪽 생활권으로 재배치하고, 안마당 중앙은 비운다. |
| `assets/illustrations/personal_hanok_v2/map/structures/haengrangchae.png` | 행랑채 완성형 | **유지·확장 재사용** | P0 | 낮고 긴 서비스 건물로 적절하다. 현재는 사랑채·대문 사이에 눌려 하나의 작은 띠처럼 보인다. | 정본 유지. 위치를 전면 작업영역으로 분리하고 필요하면 동일 기하에서 곳간/광 wing을 파생한다. |
| `assets/illustrations/personal_hanok_v2/map/structures/sotdaeulmun.png` | 솟을대문 완성형 | **정본 유지** | P0 | 크기와 재질은 좋고 입구 위계를 읽힌다. 지금은 주변 담·행랑과의 접속이 약해 독립 아이콘처럼 보인다. | 재생성 금지. 문턱, 좌우 담 접속부, 열린 문 상태를 추가하고 행랑마당 진입축을 정리한다. |
| `assets/illustrations/personal_hanok_v2/map/structures/sadang.png` | 사당 완성형 | **유지·영역 재설계** | P0 | 맞배에 가까운 절제된 작은 채로 쓸 수 있다. 다만 현재 사당담과 일각문이 불완전하고 주변 식생이 많아 의례 영역의 비움이 약하다. | 건물은 유지한다. 별도 사당담·일각문·빈 사당마당을 새 인프라 레이어로 더한다. |
| `assets/illustrations/personal_hanok_v2/map/structures/daecheongmaru.png` | 독립 대청마루 | **세계지도에서 제거·재분류** | P0 | 너무 작아 정자/부스처럼 보이며, 대청을 사랑채·안채와 동급의 독립 건물로 만드는 구조적 오류를 강화한다. | 세계지도 건물 목록에서 뺀다. 사랑대청/안대청 내부 venue의 진입 마커로만 쓰거나, 완전히 새롭고 간결한 정자 자산의 임시 기하 참고로만 보관한다. |

### 지도 축약 시공

| 파일 | 역할 | 판정 | 우선 | 평가 | 구현 |
|---|---|---|---:|---|---|
| `assets/illustrations/personal_hanok_v2/map/stages/anchae_s1_platform.png` | 지도 시공 단계: 안채 기단 | **유지·배선** | P1 | 완성형과 정렬이 안정적이다. | B1 축약 시공 1단계로 렌더러에 연결한다. |
| `assets/illustrations/personal_hanok_v2/map/stages/anchae_s2_frame.png` | 지도 시공 단계: 안채 골조 | **유지·배선** | P1 | 기단에서 골조로의 변화가 명확하고 카메라가 고정된다. | B1 2단계로 연결한다. |
| `assets/illustrations/personal_hanok_v2/map/stages/anchae_s3_roof.png` | 지도 시공 단계: 안채 지붕 | **유지·배선** | P1 | 골조 위 지붕 누적이 자연스럽다. | pending s4_final과 한 체인으로 연결한다. |
| `assets/illustrations/personal_hanok_v2/map/stages/daecheongmaru_s1_platform.png` | 지도 시공 단계: 대청 기단 | **아카이브** | P1 | 기하 자체는 정렬되지만 독립 대청 건물 방향을 강화한다. | 세계지도 대청 제거와 함께 런타임 체인에서 제외한다. |
| `assets/illustrations/personal_hanok_v2/map/stages/daecheongmaru_s2_frame.png` | 지도 시공 단계: 대청 골조 | **아카이브** | P1 | 동일 이유로 구조적으로 불필요하다. | 제작 원본/회귀 자료로만 보관한다. |
| `assets/illustrations/personal_hanok_v2/map/stages/haengrangchae_s1_foundation.png` | 지도 시공 단계: 행랑채 기단 | **유지·배선** | P1 | 낮고 긴 행랑의 공정 시작이 잘 읽힌다. | B1 시공 체인 1단계. |
| `assets/illustrations/personal_hanok_v2/map/stages/haengrangchae_s2_frame.png` | 지도 시공 단계: 행랑채 골조 | **유지·배선** | P1 | 기하 일관성이 좋다. | B1 시공 체인 2단계. |
| `assets/illustrations/personal_hanok_v2/map/stages/haengrangchae_s3_roof.png` | 지도 시공 단계: 행랑채 지붕 | **유지·배선** | P1 | 지붕 누적이 명확하다. | pending s4_final과 연결. |
| `assets/illustrations/personal_hanok_v2/map/stages/rear_garden_s1_hardscape.png` | 지도 시공 단계: 후원 경질경관 | **교체** | P1 | 현재 거대 연못/정원 메가레이어의 전제에 묶여 있다. | V2 화계·석축 모듈로 대체한다. |
| `assets/illustrations/personal_hanok_v2/map/stages/rear_garden_s2_bridge.png` | 지도 시공 단계: 후원 다리 | **조건부 아카이브** | P1 | 다리가 연못 규모를 키우고 후원을 테마파크처럼 만든다. | 작은 연못을 최종 채택할 때만 축소 변형을 검토한다. |
| `assets/illustrations/personal_hanok_v2/map/stages/sadang_s1_platform.png` | 지도 시공 단계: 사당 기단 | **유지·배선** | P1 | 사당의 위계적 시작점으로 명확하다. | 사당담 기단과 함께 B2 체인 1단계. |
| `assets/illustrations/personal_hanok_v2/map/stages/sadang_s2_frame_roof.png` | 지도 시공 단계: 사당 골조·지붕 | **유지·배선** | P1 | 축약 단계로 적당하다. | pending s3_final과 연결. |
| `assets/illustrations/personal_hanok_v2/map/stages/sotdaeulmun_s1_platform.png` | 지도 시공 단계: 솟을대문 기단 | **유지·배선** | P1 | 문턱과 진입 시작이 잘 읽힌다. | B1 체인 1단계. |
| `assets/illustrations/personal_hanok_v2/map/stages/sotdaeulmun_s2_frame_roof.png` | 지도 시공 단계: 솟을대문 골조·지붕 | **유지·배선** | P1 | 완성 전 상태가 명확하다. | pending s3_final과 연결. |

### A1 16단계

| 파일 | 역할 | 판정 | 우선 | 평가 | 구현 |
|---|---|---|---:|---|---|
| `assets/illustrations/personal_hanok_v2/a1/states/01_site_setout.webp` | A1 터잡기 | **구조 유지·베이스 교체** | P0 | 공정 시작이 명확하지만 이미 완성 담장·식생이 둘러싸여 “맨땅에서 시작”하는 서사가 약하다. | 새 A1 sparse base 위에 동일 상태를 합성한다. |
| `assets/illustrations/personal_hanok_v2/a1/states/02_plan_layout.webp` | A1 설계/배치 | **구조 유지·베이스 교체** | P0 | 배치선이 잘 읽히고 1단계와 카메라가 고정된다. | 동일 기하 유지, 미래 영역은 흐림/잠금 처리. |
| `assets/illustrations/personal_hanok_v2/a1/states/03_foundation_gidan.webp` | A1 기초·기단 | **정본 유지** | P0 | 토대 상승이 분명하다. | 베이스만 교체하고 구조 픽셀은 건드리지 않는다. |
| `assets/illustrations/personal_hanok_v2/a1/states/04_cornerstones_choseok.webp` | A1 초석 | **정본 유지** | P0 | 초석의 위치와 반복이 명확하다. | 그대로 유지. |
| `assets/illustrations/personal_hanok_v2/a1/states/05_timber_preparation.webp` | A1 치목 | **정본 유지** | P0 | 현장에 목재가 등장해 공정 어휘를 행동과 연결하기 좋다. | 그대로 유지, 소품 밀도만 과하지 않게. |
| `assets/illustrations/personal_hanok_v2/a1/states/06_columns.webp` | A1 기둥 | **정본 유지** | P0 | 기둥 수와 위치가 안정적이다. | 그대로 유지. |
| `assets/illustrations/personal_hanok_v2/a1/states/07_beams_changbang.webp` | A1 창방·보 | **정본 유지** | P0 | 수평 구조 누적이 읽힌다. | 그대로 유지. |
| `assets/illustrations/personal_hanok_v2/a1/states/08_purlins_sangnyang.webp` | A1 도리·상량 | **정본 유지** | P0 | 상부 구조의 단계 차이가 명확하다. | 그대로 유지. |
| `assets/illustrations/personal_hanok_v2/a1/states/09_rafters_roof_frame.webp` | A1 서까래·추녀 | **정본 유지** | P0 | 지붕 골조 전환이 가장 교육적으로 좋다. | 그대로 유지. |
| `assets/illustrations/personal_hanok_v2/a1/states/10_roof_base.webp` | A1 개판·보토 | **정본 유지** | P0 | 기와 이전의 지붕 바탕이 구분된다. | 그대로 유지. |
| `assets/illustrations/personal_hanok_v2/a1/states/11_giwa_roof.webp` | A1 기와 | **정본 유지** | P0 | 처마선 완성이 보상으로 강하다. | 그대로 유지. |
| `assets/illustrations/personal_hanok_v2/a1/states/12_wall_frame_sujang.webp` | A1 수장 | **정본 유지** | P0 | 벽 이전 세부 구조가 유지된다. | 그대로 유지. |
| `assets/illustrations/personal_hanok_v2/a1/states/13_earth_walls.webp` | A1 흙벽 | **정본 유지** | P0 | 외관의 생활 가능성이 커지는 변화가 명확하다. | 그대로 유지. |
| `assets/illustrations/personal_hanok_v2/a1/states/14_ondol_maru.webp` | A1 온돌·마루 | **정본 유지** | P0 | 내부 마감 단계가 잘 읽힌다. | 그대로 유지. |
| `assets/illustrations/personal_hanok_v2/a1/states/15_changho_finish.webp` | A1 창호 | **정본 유지** | P0 | 완성 직전의 창호 변화가 분명하다. | 그대로 유지. |
| `assets/illustrations/personal_hanok_v2/a1/states/16_landscape_move_in.webp` | A1 입택·조경 | **유지·조경 절제** | P0 | 완성 보상은 좋지만 주변 조경을 많이 넣으면 A1 종료 시 종가가 이미 완성돼 보일 수 있다. | 사랑마당과 나무 1~2그루, 굴뚝/등잔 등 최소 생활 흔적만 허용한다. |

### 실내 배경

| 파일 | 역할 | 판정 | 우선 | 평가 | 구현 |
|---|---|---|---:|---|---|
| `assets/illustrations/personal_hanok_v2/interiors/anbang_empty.png` | 안방 배경 | **교체** | P1 | 원근과 공간은 실용적이지만 매끈한 3D 질감, 짙은 광택 마루, 녹색 장식띠가 외부 Faceted Minhwa와 끊기며 민가보다 고급 식당/궁중 공간에 가깝다. | 1086×1448 슬롯 계약은 유지하고, 무단청·무광 목재·한지벽·절제된 창호의 Faceted interior V2로 다시 만든다. |
| `assets/illustrations/personal_hanok_v2/interiors/daecheong_empty.png` | 대청 배경 | **교체** | P1 | 천장과 보의 단청이 강해 사대부 살림집보다 궁궐·사찰 분위기다. 지도에서 대청을 독립 건물로 둔 문제와도 연결된다. | 사랑대청/안대청 두 venue 중 하나로 재정의한다. 열린 기둥·우물마루·비워진 마루를 중심으로 무단청에 가깝게 재제작한다. |
| `assets/illustrations/hanok/sarangbang_empty.png` | 사랑방 배경 | **임시 유지·교체 예정** | P1 | 세 실내 중 가장 따뜻하고 단순하지만 여전히 사실적 3D와 녹색 장식띠가 강하다. | 현재 슬롯 편집을 깨지 않도록 임시 유지하고, F-A 가구와 같은 면분할·한지 무광 배경으로 교체한다. |

### 장식·생활 자산

| 파일 | 역할 | 판정 | 우선 | 평가 | 구현 |
|---|---|---|---:|---|---|
| `assets/illustrations/decorations/decoration_baduk.png` | 바둑 | **유지** | P1 | 사랑방 추론·대화 행동 소켓으로 매우 좋다. | 사랑방에만, 사용 장면에서 노출. |
| `assets/illustrations/decorations/decoration_bandaji.png` | 반닫이 | **유지·공간 이동** | P1 | 재질은 좋지만 사랑방 기본 세트에 항상 두면 과밀하다. | 안방·별당·곳간 중 하나에 배정. |
| `assets/illustrations/decorations/decoration_bangseok_pair.png` | 방석 두 장 | **유지** | P1 | 손님 도착/수량·배치 퀘스트에 직접 쓰기 좋다. | 사랑방/대청 이벤트 상태. |
| `assets/illustrations/decorations/decoration_boryo_set.png` | 보료·안석 | **유지** | P1 | 주인 접객 위치를 명확히 만든다. | 사랑방 호스트 소켓 하나. |
| `assets/illustrations/decorations/decoration_byeongpung_small.png` | 소병풍 | **유지·선택형** | P1 | 절제된 배경 선택으로 좋다. | 다른 대형 병풍과 동시 사용 금지. |
| `assets/illustrations/decorations/decoration_chaekgado.png` | 책가도 | **유지·공간 제한** | P1 | 한글소리 고유성이 강하지만 시각 밀도가 높다. | 서고 또는 사랑방 한 벽의 선택형 1점. |
| `assets/illustrations/decorations/decoration_chuseok_moon.png` | 추석 달 | **조건부** | P2 | 역사 지도 자산보다 시즌 UI/하늘 오버레이다. | 추석 이벤트에서만. |
| `assets/illustrations/decorations/decoration_deungjan.png` | 등잔대 | **유지·조건부** | P1 | A2 생활화와 야간 상태에 적합하다. | 저녁/독서 상태 하나만. |
| `assets/illustrations/decorations/decoration_dokkaebi_fire.png` | 도깨비불 | **기본 제외** | P2 | Faceted 스타일은 맞지만 역사적 종가 기본 상태를 판타지화한다. | 별도 설화 이벤트에서만. |
| `assets/illustrations/decorations/decoration_doldam.png` | 돌담 | **유지·모듈화** | P1 | 인프라 에셋으로 유용하다. 현재 길쭉한 컷아웃은 fixed map 축척 조정이 필요하다. | 담장 모듈 세트의 재료로 사용. |
| `assets/illustrations/decorations/decoration_gat_buchae.png` | 갓·부채 | **유지·실내 전용** | P1 | 사랑방 사용자의 흔적을 빠르게 만든다. | 벽/선반/의복 소켓, 세계지도 금지. |
| `assets/illustrations/decorations/decoration_geomungo.png` | 거문고 | **유지** | P1 | 풍류·감정·음악 대화 행동 소켓으로 좋다. | 사랑방 선택형. |
| `assets/illustrations/decorations/decoration_gobi.png` | 고비 | **유지** | P1 | 편지 읽기/보관 행동과 연결된다. | 사랑방 벽 소켓. |
| `assets/illustrations/decorations/decoration_hangeulday_plaque.png` | 한글날 액자 | **이벤트 UI 전용** | P2 | 읽을 수 있는 현대 한글 문구가 고증 공간을 깨뜨린다. | 한글날 이벤트/학습 UI에서만. |
| `assets/illustrations/decorations/decoration_hwaro.png` | 화로 | **유지·겨울 조건** | P1 | 겨울 생활 상태를 강하게 만든다. | 겨울/추운 날만. |
| `assets/illustrations/decorations/decoration_hyangno.png` | 향로 | **유지·특별 조건** | P1 | 항상 두면 장식이 과해지지만 특별 접객·의례에는 좋다. | 이벤트 상태에서만. |
| `assets/illustrations/decorations/decoration_jagae_mungap.png` | 자개 문갑 | **유지·공간 이동** | P1 | 품질은 좋고 화려하지만 사랑방에 다른 장식과 함께 놓으면 부유함이 잡동사니가 된다. | 안방/별당 고급 가구 1점으로 제한. |
| `assets/illustrations/decorations/decoration_jangdokdae.png` | 장독대 6기 | **유지·파생** | P1 | 재질이 좋고 생활경제를 보여주지만 크고 완결된 플랫폼이라 지도에 그대로 놓기 어렵다. | 2기/3기 소형 변형을 파생해 안채 뒤·작업마당에 배치. |
| `assets/illustrations/decorations/decoration_kite.png` | 연 | **조건부** | P2 | 생활 이벤트에는 좋지만 상시 종가 자산은 아니다. | 아이/명절/바람 이벤트에서만. |
| `assets/illustrations/decorations/decoration_kkachi_nest.png` | 까치 둥지 | **조건부 유지** | P1 | 살아 있는 집의 분위기를 만들지만 시각적으로 강하다. | 계절/번식 상태 하나만. |
| `assets/illustrations/decorations/decoration_maehwa.png` | 매화나무 | **유지·프레이밍** | P1 | 아름다운 영웅 수목이다. 독립 스티커처럼 중앙 배치하면 게임맵 느낌이 강해진다. | 후원 화계 또는 화면 가장자리에서 1그루. |
| `assets/illustrations/decorations/decoration_mokchim.png` | 목침 | **유지** | P1 | 소박한 휴식 행동 소켓이다. | 사랑방/별당 실내. |
| `assets/illustrations/decorations/decoration_munbangsau.png` | 문방사우 | **핵심 유지** | P1 | 쓰기 학습을 직접 공간 행동으로 바꾸는 핵심 에셋이다. | 서안과 세트로 사랑방 핵심 소켓. |
| `assets/illustrations/decorations/decoration_pond.png` | 작은 연못 | **조건부 유지** | P1 | 큰 후원 연못보다 적절하지만 연꽃·잉어가 있어 장식성이 강하다. | 후원 선택형 한 개, 화면 10% 미만. |
| `assets/illustrations/decorations/decoration_punggyeong.png` | 풍경 | **조건부 유지** | P1 | 처마 생활감과 소리를 연결할 수 있다. | 누마루/정자/처마 상태, 항상 표시하지 않음. |
| `assets/illustrations/decorations/decoration_pyeonaek.png` | 편액 | **유지·개인화** | P1 | 구조를 건드리지 않고 내 집 정체성을 주는 좋은 표면 선택이다. | 호/현판 이름 커스터마이즈 소켓. |
| `assets/illustrations/decorations/decoration_sabangtakja.png` | 사방탁자 | **핵심 유지** | P1 | 사랑방 전시 소켓으로 정확하고 재질도 정본이다. | 백자·향로·책 중 한두 점만 표시. |
| `assets/illustrations/decorations/decoration_sagunja_guk.png` | 사군자 국화 | **선택형 유지** | P1 | 계절/취향 변형에 좋다. | 사군자 4종 중 1점만. |
| `assets/illustrations/decorations/decoration_sagunja_juk.png` | 사군자 대나무 | **선택형 유지** | P1 | 동일. | 사군자 4종 중 1점만. |
| `assets/illustrations/decorations/decoration_sagunja_maehwa.png` | 사군자 매화 | **선택형 유지** | P1 | 동일. | 사군자 4종 중 1점만. |
| `assets/illustrations/decorations/decoration_sagunja_nan.png` | 사군자 난초 | **선택형 유지** | P1 | 동일. | 사군자 4종 중 1점만. |
| `assets/illustrations/decorations/decoration_seoan.png` | 서안 | **핵심 유지** | P1 | 낮은 책상으로 사랑방 학습 행동의 중심이다. | 문방사우와 결합. |
| `assets/illustrations/decorations/decoration_seokdeung.png` | 석등 | **희귀/기본 제외** | P2 | 완성도는 높지만 기본 종가에 상시 놓으면 사찰·정원 장식 느낌이 강해진다. | 희귀 미관 선택 또는 Gye 전용, 기본 지도 제외. |
| `assets/illustrations/decorations/decoration_seollal_flag.png` | 설날 깃발 | **이벤트 UI 전용** | P2 | 현대 이벤트 표식에 가깝다. | 설날 UI/사진모드에서만. |
| `assets/illustrations/decorations/decoration_soban.png` | 소반 | **유지** | P1 | 차·음식·수량·접객 퀘스트에 좋다. | 사랑방/안방/대청 장면별 공유. |
| `assets/illustrations/decorations/decoration_sonamu.png` | 소나무 | **유지·프레이밍** | P1 | 형태가 강하고 고급스럽지만 중앙 스티커 배치는 피해야 한다. | 담 너머/누마루 바깥/화면 가장자리 프레임으로 1개. |

### 구 한옥/UI

| 파일 | 역할 | 판정 | 우선 | 평가 | 구현 |
|---|---|---|---:|---|---|
| `assets/illustrations/hanok/achievements.png` | 한옥 관련 업적 UI 배너 | **UI 전용 유지** | P3 | 한옥 처마와 마스코트 브랜딩은 좋지만 estate 카메라/재질과 무관하다. | 업적 화면에만 유지, V2 모델 입력 금지. |
| `assets/illustrations/hanok/calligraphy.png` | 한옥 관련 캘리그래피 UI 배너 | **UI 전용 유지** | P3 | 그래픽 배너로는 적합하다. | 학습 UI에만 사용. |
| `assets/illustrations/hanok/gate_door_left.png` | 한옥 관련 인트로 문짝 소스 | **소스 보관** | P3 | 고해상도 문짝 분리본으로 애니메이션 재렌더에는 유용하다. | 지도 건물로 사용하지 않는다. |
| `assets/illustrations/hanok/gate_door_right.png` | 한옥 관련 인트로 문짝 소스 | **소스 보관** | P3 | 좌측과 동일하다. | 지도 건물로 사용하지 않는다. |
| `assets/illustrations/hanok/gate_final.png` | 한옥 관련 구 대문 장면 | **아카이브** | P3 | 세로 수채 장면과 다른 시점이라 V2에 섞을 수 없다. | 인트로/기록용만. |
| `assets/illustrations/hanok/gate_frame.png` | 한옥 관련 구 대문 프레임 | **아카이브** | P3 | 정면 프레임·장식이 강하고 fixed estate 시점과 불일치한다. | V2 참조 금지. |
| `assets/illustrations/hanok/kkeunmari_hero.png` | 한옥 관련 끝말잇기 히어로 | **UI 전용 유지** | P3 | 마스코트 학습 배너로 적합하다. | 게임 UI만. |
| `assets/illustrations/hanok/listening_hero.png` | 한옥 관련 듣기 히어로 | **UI 전용 유지** | P3 | 마스코트/처마 배너로 적합하다. | 듣기 UI만. |
| `assets/illustrations/hanok/madang(light).png` | 한옥 관련 세로 마당 UI 배경 | **UI 전용 유지** | P3 | 여백이 많은 세로 UI 배경이지 종가 지도 마당이 아니다. | 스크린 배경만. |
| `assets/illustrations/hanok/porch.png` | 한옥 관련 처마/까치 배너 | **UI 전용 유지** | P3 | 배너로는 일관되지만 estate 자산이 아니다. | UI만. |
| `assets/illustrations/hanok/study_classroom.png` | 한옥 관련 공부방 배너 | **UI 전용 유지** | P3 | 평면 그래픽 학습 장면으로 적합하다. | 학습 화면만. |
| `assets/illustrations/hanok/study_scholar.png` | 한옥 관련 선비 공부 배너 | **UI 전용 유지** | P3 | 학습 맥락에는 좋다. | 학습 화면만. |
| `assets/illustrations/hanok/taego-joy-duo.png` | 한옥 관련 마스코트 듀오 | **브랜드 전용 유지** | P3 | 브랜드 자산이다. | 한옥 지도 레이어로 사용하지 않는다. |
| `assets/illustrations/hanok/welcome-hero.png` | 한옥 관련 환영 히어로 | **브랜드 전용 유지** | P3 | 캐릭터 선택/환영 포스터에 적합하다. | 지도 참조 금지. |

### 레거시 성장 배너

| 파일 | 역할 | 판정 | 우선 | 평가 | 구현 |
|---|---|---|---:|---|---|
| `assets/illustrations/hanok_stages/stage_beams_light.png` | 보·서까래 단계 | **레거시 UI 유지** | P3 | 이미 UI 텍스트와 카드가 구워진 장면이라 순수 에셋이 아니다. | 현재 학습경로 헤더가 필요하면 유지하되 F-F로 표시하고 V2 생성 참조·합성 입력에서 배제한다. |
| `assets/illustrations/hanok_stages/stage_dancheong_light.png` | 단청 단계 | **레거시만·향후 폐기 후보** | P3 | 민가 종가의 새 아트 방향과 정면 충돌한다. | 현재 학습경로 헤더가 필요하면 유지하되 F-F로 표시하고 V2 생성 참조·합성 입력에서 배제한다. |
| `assets/illustrations/hanok_stages/stage_empty_light.png` | 빈 터 | **레거시 UI 유지** | P3 | 수직 배너용이며 fixed estate와 다른 지형/카메라다. | 현재 학습경로 헤더가 필요하면 유지하되 F-F로 표시하고 V2 생성 참조·합성 입력에서 배제한다. |
| `assets/illustrations/hanok_stages/stage_foundation_light.png` | 기초 | **레거시 UI 유지** | P3 | 전체 장면 재그림 방식이라 A1 deterministic 체인보다 열등하다. | 현재 학습경로 헤더가 필요하면 유지하되 F-F로 표시하고 V2 생성 참조·합성 입력에서 배제한다. |
| `assets/illustrations/hanok_stages/stage_gate_light.png` | 대문 | **레거시 UI 유지** | P3 | 독립 대문 보상 논리를 강화한다. | 현재 학습경로 헤더가 필요하면 유지하되 F-F로 표시하고 V2 생성 참조·합성 입력에서 배제한다. |
| `assets/illustrations/hanok_stages/stage_jongga_light.png` | 완성 종가 | **레거시 UI 유지** | P3 | 한 화면에 완성 요소가 누적된 구 목표상이다. | 현재 학습경로 헤더가 필요하면 유지하되 F-F로 표시하고 V2 생성 참조·합성 입력에서 배제한다. |
| `assets/illustrations/hanok_stages/stage_pillars_light.png` | 기둥 | **레거시 UI 유지** | P3 | 공정 교육은 가능하나 기하가 A1 체인과 일치하지 않는다. | 현재 학습경로 헤더가 필요하면 유지하되 F-F로 표시하고 V2 생성 참조·합성 입력에서 배제한다. |
| `assets/illustrations/hanok_stages/stage_sidebuilding_light.png` | 곁채 | **레거시 UI 유지** | P3 | 구 수집형 곁채 표현이다. | 현재 학습경로 헤더가 필요하면 유지하되 F-F로 표시하고 V2 생성 참조·합성 입력에서 배제한다. |
| `assets/illustrations/hanok_stages/stage_thatch_light.png` | 초가지붕 | **레거시 UI 유지** | P3 | 현재 기와 종가 성장축과 별도다. | 현재 학습경로 헤더가 필요하면 유지하되 F-F로 표시하고 V2 생성 참조·합성 입력에서 배제한다. |
| `assets/illustrations/hanok_stages/stage_tile_complete_light.png` | 기와 완성 | **레거시 UI 유지** | P3 | fixed canvas 시공 상태로 재사용 불가. | 현재 학습경로 헤더가 필요하면 유지하되 F-F로 표시하고 V2 생성 참조·합성 입력에서 배제한다. |
| `assets/illustrations/hanok_stages/stage_tile_partial_light.png` | 기와 부분 | **레거시 UI 유지** | P3 | 동일. | 현재 학습경로 헤더가 필요하면 유지하되 F-F로 표시하고 V2 생성 참조·합성 입력에서 배제한다. |
| `assets/illustrations/hanok_stages/stage_windows_light.png` | 창호 | **레거시 UI 유지** | P3 | 동일. | 현재 학습경로 헤더가 필요하면 유지하되 F-F로 표시하고 V2 생성 참조·합성 입력에서 배제한다. |

### 계 공동한옥

| 파일 | 역할 | 판정 | 우선 | 평가 | 구현 |
|---|---|---|---:|---|---|
| `assets/illustrations/gye/gye_bridge.png` | 석교 | **Gye 전용 유지** | P3 | 개념적으로 후원 동선을 보여주지만 개인 한옥의 작은 후원에는 규모와 재질이 맞지 않는다. | 직접 재사용/모델 입력 금지. 작은 다리가 정말 필요할 때 기능만 참고. |
| `assets/illustrations/gye/gye_byeoldang.png` | 별당 | **Gye 전용 유지** | P3 | 단일 건물 완성도는 높지만 카메라·단청·축척이 개인 estate와 다르다. | pending 개인 별당 후보를 먼저 검수. |
| `assets/illustrations/gye/gye_garden.png` | 정원 군락 | **Gye 전용 유지** | P3 | 구성은 예쁘지만 완결 스티커 군락이라 지도에 붙이면 콜라주 느낌이 난다. | 영웅 수목+보조 수목 분리 원리만 참고. |
| `assets/illustrations/gye/gye_gate_grand.png` | 대형 대문 | **개인 지도 사용 금지** | P3 | 과장된 단청과 정면 시점이 사대부 종가 V2에 맞지 않는다. | Gye에서만. |
| `assets/illustrations/gye/gye_haenglangchae.png` | 행랑채 | **개인 지도 사용 금지** | P3 | 독립 건물 컷아웃으로는 좋지만 production 행랑과 카메라/재질이 다르다. | Gye에서만. |
| `assets/illustrations/gye/gye_jangmyeongdeung_pair.png` | 장명등 한 쌍 | **개인 기본 지도 제외** | P3 | 사찰·정원 장식성이 강하고 쌍으로 놓으면 테마파크화된다. | Gye 또는 특별 이벤트만. |
| `assets/illustrations/gye/gye_jeongja.png` | 정자 | **개념 참고만** | P3 | 사용자 판타지는 충족하지만 단청과 크기가 과하다. | 개인 estate용 무단청·간결한 정자를 새로 제작. |
| `assets/illustrations/gye/gye_pond_large.png` | 대형 연못 | **개인 지도 사용 금지** | P3 | 화면을 지배하는 대형 연못으로 딥리서치가 경고한 방향과 정확히 충돌한다. | Gye에서만. |
| `assets/illustrations/gye/gye_showcase_courtyard.webp` | 완성 쇼케이스 | **마케팅 전용** | P3 | 한 화면에 건물·연못·장독·동물·정원을 모두 넣은 완성 판타지 이미지다. | 참고/마케팅만, masterplan 정본 금지. |

### 동결 프로토타입

| 파일 | 역할 | 판정 | 우선 | 평가 | 구현 |
|---|---|---|---:|---|---|
| `assets/illustrations/hanok_compound/anchae.png` | 구 compound anchae | **아카이브·복원 금지** | P3 | 현재 production personal_hanok_v2에 대체된 구 프로토타입이며 번들 제외·런타임 참조 0인 F-F 계열이다. 현재 앱 원본과 같은 기준으로 육안 검수할 필요가 없는 폐기 계보다. | git 기록/회귀 참고로만 유지하고 pubspec·카탈로그·생성 참조에 넣지 않는다. |
| `assets/illustrations/hanok_compound/daecheongmaru.png` | 구 compound daecheongmaru | **아카이브·복원 금지** | P3 | 현재 production personal_hanok_v2에 대체된 구 프로토타입이며 번들 제외·런타임 참조 0인 F-F 계열이다. 현재 앱 원본과 같은 기준으로 육안 검수할 필요가 없는 폐기 계보다. | git 기록/회귀 참고로만 유지하고 pubspec·카탈로그·생성 참조에 넣지 않는다. |
| `assets/illustrations/hanok_compound/haengrangchae.png` | 구 compound haengrangchae | **아카이브·복원 금지** | P3 | 현재 production personal_hanok_v2에 대체된 구 프로토타입이며 번들 제외·런타임 참조 0인 F-F 계열이다. 현재 앱 원본과 같은 기준으로 육안 검수할 필요가 없는 폐기 계보다. | git 기록/회귀 참고로만 유지하고 pubspec·카탈로그·생성 참조에 넣지 않는다. |
| `assets/illustrations/hanok_compound/sadang.png` | 구 compound sadang | **아카이브·복원 금지** | P3 | 현재 production personal_hanok_v2에 대체된 구 프로토타입이며 번들 제외·런타임 참조 0인 F-F 계열이다. 현재 앱 원본과 같은 기준으로 육안 검수할 필요가 없는 폐기 계보다. | git 기록/회귀 참고로만 유지하고 pubspec·카탈로그·생성 참조에 넣지 않는다. |
| `assets/illustrations/hanok_compound/sarangchae.png` | 구 compound sarangchae | **아카이브·복원 금지** | P3 | 현재 production personal_hanok_v2에 대체된 구 프로토타입이며 번들 제외·런타임 참조 0인 F-F 계열이다. 현재 앱 원본과 같은 기준으로 육안 검수할 필요가 없는 폐기 계보다. | git 기록/회귀 참고로만 유지하고 pubspec·카탈로그·생성 참조에 넣지 않는다. |
| `assets/illustrations/hanok_compound/site_base.png` | 구 compound site_base | **아카이브·복원 금지** | P3 | 현재 production personal_hanok_v2에 대체된 구 프로토타입이며 번들 제외·런타임 참조 0인 F-F 계열이다. 현재 앱 원본과 같은 기준으로 육안 검수할 필요가 없는 폐기 계보다. | git 기록/회귀 참고로만 유지하고 pubspec·카탈로그·생성 참조에 넣지 않는다. |
| `assets/illustrations/hanok_compound/sotdaeulmun.png` | 구 compound sotdaeulmun | **아카이브·복원 금지** | P3 | 현재 production personal_hanok_v2에 대체된 구 프로토타입이며 번들 제외·런타임 참조 0인 F-F 계열이다. 현재 앱 원본과 같은 기준으로 육안 검수할 필요가 없는 폐기 계보다. | git 기록/회귀 참고로만 유지하고 pubspec·카탈로그·생성 참조에 넣지 않는다. |

### 미사용 한옥 아카이브

| 파일 | 역할 | 판정 | 우선 | 평가 | 구현 |
|---|---|---|---:|---|---|
| `assets_unused/illustrations/hanok/dancheong_frame.png` | 워들 단청 프레임 | **영구 아카이브** | P3 | 입력칸과 겹쳐 의도적으로 제거된 UI 프레임이며 종가 V2와 무관하다. | 현재 위치 유지. V2 모델 입력 금지. |
| `assets_unused/illustrations/hanok/gate.png` | 홈페이지 CTA용 대문 | **웹 전용 보관** | P3 | 앱 런타임 참조 0이며 홈페이지 사본이 역할을 대신한다. | 현재 위치 유지. V2 모델 입력 금지. |
| `assets_unused/illustrations/hanok/gate_entrance.png` | 인트로 영상 키프레임 | **소스 보관** | P3 | 완성 영상 재렌더용 원본이며 지도 자산이 아니다. | 현재 위치 유지. V2 모델 입력 금지. |
| `assets_unused/illustrations/hanok/madang(dark).png` | 다크 마당 배경 | **조건부 보관** | P3 | 앱이 라이트 전용이어서 도달 불가하다. V2 masterplan과는 별도 UI 배경이다. | 현재 위치 유지. V2 모델 입력 금지. |

### 검토대기 A2 가구

| 파일 | 역할 | 판정 | 우선 | 평가 | 구현 |
|---|---|---|---:|---|---|
| `assets_unused/pending_review/a2_furnishing/cut/decoration_baduk.png` | A2 가구 cut baduk | **중복 아카이브** | P3 | production decorations의 decoration_baduk.png가 이미 번들되어 있어 런타임 후보로 다시 승격하면 중복·카탈로그 충돌이 난다. | cut/normalized/model_inputs/QA를 제작 기록으로만 보관한다. production 파일을 정본으로 삼는다. |
| `assets_unused/pending_review/a2_furnishing/normalized/decoration_baduk.png` | A2 가구 normalized baduk | **중복 아카이브** | P3 | 동일 자산의 정규화 중간 산출물이다. 사용자 보상 자산으로 별도 취급하지 않는다. | 제작 파이프라인 기록으로만 유지. |
| `assets_unused/pending_review/a2_furnishing/cut/decoration_bandaji.png` | A2 가구 cut bandaji | **중복 아카이브** | P3 | production decorations의 decoration_bandaji.png가 이미 번들되어 있어 런타임 후보로 다시 승격하면 중복·카탈로그 충돌이 난다. | cut/normalized/model_inputs/QA를 제작 기록으로만 보관한다. production 파일을 정본으로 삼는다. |
| `assets_unused/pending_review/a2_furnishing/normalized/decoration_bandaji.png` | A2 가구 normalized bandaji | **중복 아카이브** | P3 | 동일 자산의 정규화 중간 산출물이다. 사용자 보상 자산으로 별도 취급하지 않는다. | 제작 파이프라인 기록으로만 유지. |
| `assets_unused/pending_review/a2_furnishing/cut/decoration_bangseok_pair.png` | A2 가구 cut bangseok_pair | **중복 아카이브** | P3 | production decorations의 decoration_bangseok_pair.png가 이미 번들되어 있어 런타임 후보로 다시 승격하면 중복·카탈로그 충돌이 난다. | cut/normalized/model_inputs/QA를 제작 기록으로만 보관한다. production 파일을 정본으로 삼는다. |
| `assets_unused/pending_review/a2_furnishing/normalized/decoration_bangseok_pair.png` | A2 가구 normalized bangseok_pair | **중복 아카이브** | P3 | 동일 자산의 정규화 중간 산출물이다. 사용자 보상 자산으로 별도 취급하지 않는다. | 제작 파이프라인 기록으로만 유지. |
| `assets_unused/pending_review/a2_furnishing/cut/decoration_boryo_set.png` | A2 가구 cut boryo_set | **중복 아카이브** | P3 | production decorations의 decoration_boryo_set.png가 이미 번들되어 있어 런타임 후보로 다시 승격하면 중복·카탈로그 충돌이 난다. | cut/normalized/model_inputs/QA를 제작 기록으로만 보관한다. production 파일을 정본으로 삼는다. |
| `assets_unused/pending_review/a2_furnishing/normalized/decoration_boryo_set.png` | A2 가구 normalized boryo_set | **중복 아카이브** | P3 | 동일 자산의 정규화 중간 산출물이다. 사용자 보상 자산으로 별도 취급하지 않는다. | 제작 파이프라인 기록으로만 유지. |
| `assets_unused/pending_review/a2_furnishing/cut/decoration_byeongpung_small.png` | A2 가구 cut byeongpung_small | **중복 아카이브** | P3 | production decorations의 decoration_byeongpung_small.png가 이미 번들되어 있어 런타임 후보로 다시 승격하면 중복·카탈로그 충돌이 난다. | cut/normalized/model_inputs/QA를 제작 기록으로만 보관한다. production 파일을 정본으로 삼는다. |
| `assets_unused/pending_review/a2_furnishing/normalized/decoration_byeongpung_small.png` | A2 가구 normalized byeongpung_small | **중복 아카이브** | P3 | 동일 자산의 정규화 중간 산출물이다. 사용자 보상 자산으로 별도 취급하지 않는다. | 제작 파이프라인 기록으로만 유지. |
| `assets_unused/pending_review/a2_furnishing/cut/decoration_deungjan.png` | A2 가구 cut deungjan | **중복 아카이브** | P3 | production decorations의 decoration_deungjan.png가 이미 번들되어 있어 런타임 후보로 다시 승격하면 중복·카탈로그 충돌이 난다. | cut/normalized/model_inputs/QA를 제작 기록으로만 보관한다. production 파일을 정본으로 삼는다. |
| `assets_unused/pending_review/a2_furnishing/normalized/decoration_deungjan.png` | A2 가구 normalized deungjan | **중복 아카이브** | P3 | 동일 자산의 정규화 중간 산출물이다. 사용자 보상 자산으로 별도 취급하지 않는다. | 제작 파이프라인 기록으로만 유지. |
| `assets_unused/pending_review/a2_furnishing/cut/decoration_geomungo.png` | A2 가구 cut geomungo | **중복 아카이브** | P3 | production decorations의 decoration_geomungo.png가 이미 번들되어 있어 런타임 후보로 다시 승격하면 중복·카탈로그 충돌이 난다. | cut/normalized/model_inputs/QA를 제작 기록으로만 보관한다. production 파일을 정본으로 삼는다. |
| `assets_unused/pending_review/a2_furnishing/normalized/decoration_geomungo.png` | A2 가구 normalized geomungo | **중복 아카이브** | P3 | 동일 자산의 정규화 중간 산출물이다. 사용자 보상 자산으로 별도 취급하지 않는다. | 제작 파이프라인 기록으로만 유지. |
| `assets_unused/pending_review/a2_furnishing/cut/decoration_gobi.png` | A2 가구 cut gobi | **중복 아카이브** | P3 | production decorations의 decoration_gobi.png가 이미 번들되어 있어 런타임 후보로 다시 승격하면 중복·카탈로그 충돌이 난다. | cut/normalized/model_inputs/QA를 제작 기록으로만 보관한다. production 파일을 정본으로 삼는다. |
| `assets_unused/pending_review/a2_furnishing/normalized/decoration_gobi.png` | A2 가구 normalized gobi | **중복 아카이브** | P3 | 동일 자산의 정규화 중간 산출물이다. 사용자 보상 자산으로 별도 취급하지 않는다. | 제작 파이프라인 기록으로만 유지. |
| `assets_unused/pending_review/a2_furnishing/cut/decoration_hwaro.png` | A2 가구 cut hwaro | **중복 아카이브** | P3 | production decorations의 decoration_hwaro.png가 이미 번들되어 있어 런타임 후보로 다시 승격하면 중복·카탈로그 충돌이 난다. | cut/normalized/model_inputs/QA를 제작 기록으로만 보관한다. production 파일을 정본으로 삼는다. |
| `assets_unused/pending_review/a2_furnishing/normalized/decoration_hwaro.png` | A2 가구 normalized hwaro | **중복 아카이브** | P3 | 동일 자산의 정규화 중간 산출물이다. 사용자 보상 자산으로 별도 취급하지 않는다. | 제작 파이프라인 기록으로만 유지. |
| `assets_unused/pending_review/a2_furnishing/cut/decoration_hyangno.png` | A2 가구 cut hyangno | **중복 아카이브** | P3 | production decorations의 decoration_hyangno.png가 이미 번들되어 있어 런타임 후보로 다시 승격하면 중복·카탈로그 충돌이 난다. | cut/normalized/model_inputs/QA를 제작 기록으로만 보관한다. production 파일을 정본으로 삼는다. |
| `assets_unused/pending_review/a2_furnishing/normalized/decoration_hyangno.png` | A2 가구 normalized hyangno | **중복 아카이브** | P3 | 동일 자산의 정규화 중간 산출물이다. 사용자 보상 자산으로 별도 취급하지 않는다. | 제작 파이프라인 기록으로만 유지. |
| `assets_unused/pending_review/a2_furnishing/cut/decoration_mokchim.png` | A2 가구 cut mokchim | **중복 아카이브** | P3 | production decorations의 decoration_mokchim.png가 이미 번들되어 있어 런타임 후보로 다시 승격하면 중복·카탈로그 충돌이 난다. | cut/normalized/model_inputs/QA를 제작 기록으로만 보관한다. production 파일을 정본으로 삼는다. |
| `assets_unused/pending_review/a2_furnishing/normalized/decoration_mokchim.png` | A2 가구 normalized mokchim | **중복 아카이브** | P3 | 동일 자산의 정규화 중간 산출물이다. 사용자 보상 자산으로 별도 취급하지 않는다. | 제작 파이프라인 기록으로만 유지. |
| `assets_unused/pending_review/a2_furnishing/cut/decoration_sabangtakja.png` | A2 가구 cut sabangtakja | **중복 아카이브** | P3 | production decorations의 decoration_sabangtakja.png가 이미 번들되어 있어 런타임 후보로 다시 승격하면 중복·카탈로그 충돌이 난다. | cut/normalized/model_inputs/QA를 제작 기록으로만 보관한다. production 파일을 정본으로 삼는다. |
| `assets_unused/pending_review/a2_furnishing/normalized/decoration_sabangtakja.png` | A2 가구 normalized sabangtakja | **중복 아카이브** | P3 | 동일 자산의 정규화 중간 산출물이다. 사용자 보상 자산으로 별도 취급하지 않는다. | 제작 파이프라인 기록으로만 유지. |
| `assets_unused/pending_review/a2_furnishing/cut/decoration_soban_v2.png` | A2 가구 cut soban_v2 | **중복 아카이브** | P3 | production decorations의 decoration_soban.png가 이미 번들되어 있어 런타임 후보로 다시 승격하면 중복·카탈로그 충돌이 난다. | cut/normalized/model_inputs/QA를 제작 기록으로만 보관한다. production 파일을 정본으로 삼는다. |
| `assets_unused/pending_review/a2_furnishing/normalized/decoration_soban_v2.png` | A2 가구 normalized soban_v2 | **중복 아카이브** | P3 | 동일 자산의 정규화 중간 산출물이다. 사용자 보상 자산으로 별도 취급하지 않는다. | 제작 파이프라인 기록으로만 유지. |
| `assets_unused/pending_review/a2_furnishing/model_inputs/a2_style_ref_sheet_v1.png` | 스타일 참조 시트 | **정본 참조 유지** | P3 | F-A 생성 재현을 위한 참조 시트다. 런타임 에셋이 아니다. | STYLE_LOCK의 F-A 입력으로만 사용하고 앱 번들에는 넣지 않는다. |
| `assets_unused/pending_review/a2_furnishing/model_inputs/a2_style_ref_sheet_v1_400.webp` | 스타일 참조 시트 | **정본 참조 유지** | P3 | F-A 생성 재현을 위한 참조 시트다. 런타임 에셋이 아니다. | STYLE_LOCK의 F-A 입력으로만 사용하고 앱 번들에는 넣지 않는다. |

### 검토대기 신규 소품

| 파일 | 역할 | 판정 | 우선 | 평가 | 구현 |
|---|---|---|---:|---|---|
| `assets_unused/pending_review/asset_recipe/decoration_baekja_byeong/decoration_baekja_byeong_cut.png` | 백자병 | **검수 후 조건부 승격** | P2 | 사랑방 사방탁자/서고의 단일 진열품으로 적합한 후보. 파일은 현재 앱 번들 밖이므로 픽셀 수준 최종 승인은 별도 육안 QA가 필요하다. | 사랑방/서고. 한 화면에 도자기 1점만. STYLE_LOCK F-A, alpha, 색상, 그림자, 크기 검사를 통과한 뒤 원장 append→카탈로그→번들 순서로 승격. |
| `assets_unused/pending_review/asset_recipe/decoration_baekja_byeong/decoration_baekja_byeong_raw.png` | 백자병 raw | **소스 보관** | P3 | 생성 원본으로 런타임 사용 대상이 아니다. | cut 승인 여부와 무관하게 provenance용으로만 유지. |
| `assets_unused/pending_review/asset_recipe/decoration_boseokham/decoration_boseokham_cut.png` | 보석함 | **검수 후 선택 승격** | P2 | 안방·별당의 고급 수납 후보이나 자개함과 역할이 겹친다. 파일은 현재 앱 번들 밖이므로 픽셀 수준 최종 승인은 별도 육안 QA가 필요하다. | jagaeham과 둘 중 하나만 채택. STYLE_LOCK F-A, alpha, 색상, 그림자, 크기 검사를 통과한 뒤 원장 append→카탈로그→번들 순서로 승격. |
| `assets_unused/pending_review/asset_recipe/decoration_boseokham/decoration_boseokham_raw.png` | 보석함 raw | **소스 보관** | P3 | 생성 원본으로 런타임 사용 대상이 아니다. | cut 승인 여부와 무관하게 provenance용으로만 유지. |
| `assets_unused/pending_review/asset_recipe/decoration_gyeongdae/decoration_gyeongdae_cut.png` | 경대 | **검수 후 우선 승격** | P1 | 안방 기능을 명확히 만드는 현재 부족 자산이다. 파일은 현재 앱 번들 밖이므로 픽셀 수준 최종 승인은 별도 육안 QA가 필요하다. | 안방 전용. STYLE_LOCK F-A, alpha, 색상, 그림자, 크기 검사를 통과한 뒤 원장 append→카탈로그→번들 순서로 승격. |
| `assets_unused/pending_review/asset_recipe/decoration_gyeongdae/decoration_gyeongdae_raw.png` | 경대 raw | **소스 보관** | P3 | 생성 원본으로 런타임 사용 대상이 아니다. | cut 승인 여부와 무관하게 provenance용으로만 유지. |
| `assets_unused/pending_review/asset_recipe/decoration_jagaeham/decoration_jagaeham_cut.png` | 자개함 | **검수 후 선택 승격** | P2 | 안방·별당의 고급 표면 선택에 맞는다. 파일은 현재 앱 번들 밖이므로 픽셀 수준 최종 승인은 별도 육안 QA가 필요하다. | boseokham과 동시 기본 노출 금지. STYLE_LOCK F-A, alpha, 색상, 그림자, 크기 검사를 통과한 뒤 원장 append→카탈로그→번들 순서로 승격. |
| `assets_unused/pending_review/asset_recipe/decoration_jagaeham/decoration_jagaeham_raw.png` | 자개함 raw | **소스 보관** | P3 | 생성 원본으로 런타임 사용 대상이 아니다. | cut 승인 여부와 무관하게 provenance용으로만 유지. |
| `assets_unused/pending_review/asset_recipe/decoration_jangmokbi/decoration_jangmokbi_cut.png` | 장목비 | **낮은 우선순위·보류** | P1 | 단독 보상으로는 서사적 힘이 약하고 공간 소속이 모호하다. 파일은 현재 앱 번들 밖이므로 픽셀 수준 최종 승인은 별도 육안 QA가 필요하다. | 몸단장/하인 작업 퀘스트가 생길 때만. STYLE_LOCK F-A, alpha, 색상, 그림자, 크기 검사를 통과한 뒤 원장 append→카탈로그→번들 순서로 승격. |
| `assets_unused/pending_review/asset_recipe/decoration_jangmokbi/decoration_jangmokbi_raw.png` | 장목비 raw | **소스 보관** | P3 | 생성 원본으로 런타임 사용 대상이 아니다. | cut 승인 여부와 무관하게 provenance용으로만 유지. |
| `assets_unused/pending_review/asset_recipe/decoration_manggeontong/decoration_manggeontong_cut.png` | 망건통 | **검수 후 승격** | P2 | 사랑방 남성 복식·생활 흔적을 만들기 좋다. 파일은 현재 앱 번들 밖이므로 픽셀 수준 최종 승인은 별도 육안 QA가 필요하다. | 사랑방 선반/사방탁자. STYLE_LOCK F-A, alpha, 색상, 그림자, 크기 검사를 통과한 뒤 원장 append→카탈로그→번들 순서로 승격. |
| `assets_unused/pending_review/asset_recipe/decoration_manggeontong/decoration_manggeontong_raw.png` | 망건통 raw | **소스 보관** | P3 | 생성 원본으로 런타임 사용 대상이 아니다. | cut 승인 여부와 무관하게 provenance용으로만 유지. |
| `assets_unused/pending_review/asset_recipe/decoration_mukpodo_byeongpung/decoration_mukpodo_byeongpung_cut.png` | 묵포도 병풍 | **검수 후 선택 승격** | P2 | 사랑방·별당의 고급 병풍 선택으로 좋지만 다른 병풍과 동시에 쓰면 과밀하다. 파일은 현재 앱 번들 밖이므로 픽셀 수준 최종 승인은 별도 육안 QA가 필요하다. | 병풍 슬롯 1개 선택형. STYLE_LOCK F-A, alpha, 색상, 그림자, 크기 검사를 통과한 뒤 원장 append→카탈로그→번들 순서로 승격. |
| `assets_unused/pending_review/asset_recipe/decoration_mukpodo_byeongpung/decoration_mukpodo_byeongpung_raw.png` | 묵포도 병풍 raw | **소스 보관** | P3 | 생성 원본으로 런타임 사용 대상이 아니다. | cut 승인 여부와 무관하게 provenance용으로만 유지. |
| `assets_unused/pending_review/asset_recipe/decoration_yakjang/decoration_yakjang_cut.png` | 약장 | **맥락 확정 후 승격** | P2 | 일반 사랑방 장식보다 의료·생활 서사가 필요하다. 파일은 현재 앱 번들 밖이므로 픽셀 수준 최종 승인은 별도 육안 QA가 필요하다. | 별당/서비스/약방 퀘스트가 생긴 뒤. STYLE_LOCK F-A, alpha, 색상, 그림자, 크기 검사를 통과한 뒤 원장 append→카탈로그→번들 순서로 승격. |
| `assets_unused/pending_review/asset_recipe/decoration_yakjang/decoration_yakjang_raw.png` | 약장 raw | **소스 보관** | P3 | 생성 원본으로 런타임 사용 대상이 아니다. | cut 승인 여부와 무관하게 provenance용으로만 유지. |
| `assets_unused/pending_review/asset_recipe/decoration_yeonsang/decoration_yeonsang_cut.png` | 연상 | **검수 후 우선 승격** | P1 | 문방사우·서안과 연결되는 핵심 학문 행동 자산이다. 파일은 현재 앱 번들 밖이므로 픽셀 수준 최종 승인은 별도 육안 QA가 필요하다. | 사랑방 핵심 소켓. STYLE_LOCK F-A, alpha, 색상, 그림자, 크기 검사를 통과한 뒤 원장 append→카탈로그→번들 순서로 승격. |
| `assets_unused/pending_review/asset_recipe/decoration_yeonsang/decoration_yeonsang_raw.png` | 연상 raw | **소스 보관** | P3 | 생성 원본으로 런타임 사용 대상이 아니다. | cut 승인 여부와 무관하게 provenance용으로만 유지. |

### 검토대기 외관 오버레이

| 파일 | 역할 | 판정 | 우선 | 평가 | 구현 |
|---|---|---|---:|---|---|
| `assets_unused/pending_review/estate_overlays/cut/a2_chimney_smoke.png` | 굴뚝 연기 | **승격 권장** | P1 | 큰 실루엣을 바꾸지 않고 집이 살아 있음을 보여주는 좋은 ambience다. | 추운 날/아침 조건에서 하나만 표시. |
| `assets_unused/pending_review/estate_overlays/cut/a2_jangdok_big.png` | 큰 장독 | **보류** | P1 | 기존 장독대와 중복되며 지도 기본 줌에서는 과대할 가능성이 있다. | small과 실측 비교 후 필요 없으면 폐기. |
| `assets_unused/pending_review/estate_overlays/cut/a2_jangdok_small.png` | 작은 장독 | **승격 권장** | P1 | 첫 장독 생활 흔적으로 적절하다. | 안채 뒤/작업마당 candidate A에 배치. |
| `assets_unused/pending_review/estate_overlays/cut/a2_lantern_lit.png` | 켜진 등롱 | **승격 권장** | P1 | 야간 생활감을 최소 오브젝트로 만든다. | 사랑채 1개 또는 대문 1개, 동시 다수 금지. |
| `assets_unused/pending_review/estate_overlays/cut/a2_ridge_magpie.png` | 용마루 까치 | **승격 권장** | P1 | 한글소리 마스코트 세계관과 살아 있는 종가를 연결한다. | 조건부 1마리, 상시 여러 마리 금지. |
| `assets_unused/pending_review/estate_overlays/raw/exterior_props_sheet_v1.png` | 외관 소품 원본 시트 | **소스 보관** | P3 | 컷아웃 전 생성 시트로 런타임 대상이 아니다. | provenance/재컷용만. |
| `assets_unused/pending_review/estate_overlays/raw/exterior_props_sheet_v2.png` | 외관 소품 원본 시트 | **소스 보관** | P3 | 컷아웃 전 생성 시트로 런타임 대상이 아니다. | provenance/재컷용만. |

### 검토대기 오버레이 QA

| 파일 | 역할 | 판정 | 우선 | 평가 | 구현 |
|---|---|---|---:|---|---|
| `assets_unused/pending_review/estate_overlays/qa/jangdok_candidate_A_anchae_courtyard.png` | 장독 배치 QA | **채택 방향** | P1 | 장독의 역사적·시각적 소속이 안채 뒤/인접 영역에 맞는다. | A안을 기준으로 좌표 고정. B안은 rejected 폴더로 이동. |
| `assets_unused/pending_review/estate_overlays/qa/jangdok_candidate_A_anchae_courtyard_layer_only.png` | 장독 배치 QA | **채택 방향** | P1 | A안의 투명 레이어 버전. | A안을 기준으로 좌표 고정. B안은 rejected 폴더로 이동. |
| `assets_unused/pending_review/estate_overlays/qa/jangdok_candidate_B_sarangmadang.png` | 장독 배치 QA | **기각 방향** | P1 | 사랑마당을 비워야 하는 masterplan과 충돌한다. | A안을 기준으로 좌표 고정. B안은 rejected 폴더로 이동. |
| `assets_unused/pending_review/estate_overlays/qa/jangdok_candidate_B_sarangmadang_layer_only.png` | 장독 배치 QA | **기각 방향** | P1 | B안의 투명 레이어 버전. | A안을 기준으로 좌표 고정. B안은 rejected 폴더로 이동. |

### 검토대기 지도·시공

| 파일 | 역할 | 판정 | 우선 | 평가 | 구현 |
|---|---|---|---:|---|---|
| `assets_unused/pending_review/estate_stages/anchae/anchae_frame_aligned.png` | 안채 정렬 골조 | **소스 유지** | P2 | 골조 정렬용 중간 산출물. | 런타임은 s2_frame 사용, 정렬 회귀용만. |
| `assets_unused/pending_review/estate_stages/anchae/anchae_s1_platform.png` | 안채 기단 후보 | **중복 정본화** | P1 | production s1과 동일 체인 후보. | 해시/픽셀 비교 후 한 파일만 남긴다. |
| `assets_unused/pending_review/estate_stages/anchae/anchae_s2_frame.png` | 안채 골조 후보 | **중복 정본화** | P1 | production s2와 동일 체인 후보. | 한 파일만 정본. |
| `assets_unused/pending_review/estate_stages/anchae/anchae_s3_roof.png` | 안채 지붕 후보 | **중복 정본화** | P1 | production s3와 동일 체인 후보. | 한 파일만 정본. |
| `assets_unused/pending_review/estate_stages/anchae/anchae_s4_final.png` | 안채 최종 단계 | **승격 권장** | P1 | 현재 production 체인에 빠진 최종 상태다. | renderer 배선과 같은 커밋으로 승격. |
| `assets_unused/pending_review/estate_stages/byeoldang/cut/byeoldang_finished.png` | 별당 완성 후보 | **육안 QA 후 보류/승격** | P2 | 이미 만들어진 최종 후보이므로 재생성 금지. | masterplan V2 위치·축척을 먼저 고정한 뒤 스타일/카메라/겹침 검수. |
| `assets_unused/pending_review/estate_stages/byeoldang/raw/byeoldang_finished_raw.jpg` | 별당 raw | **소스 보관** | P3 | 생성 원본. | provenance만. |
| `assets_unused/pending_review/estate_stages/byeoldang/rejected/byeoldang_try1_floating_roof_gvi_pu1lcj.png` | 별당 실패 1 | **영구 기각** | P3 | floating roof 결함이 파일명에 명시된 실패본. | rejected 유지, 모델 입력 금지. |
| `assets_unused/pending_review/estate_stages/byeoldang/rejected/byeoldang_try2_rotated_camera_4638a3ae.png` | 별당 실패 2 | **영구 기각** | P3 | 카메라 회전 결함이 명시된 실패본. | rejected 유지, 모델 입력 금지. |
| `assets_unused/pending_review/estate_stages/daecheongmaru/daecheongmaru_s1_platform.png` | 독립 대청 기단 후보 | **아카이브** | P3 | 세계지도 대청 제거 방향과 충돌. | 런타임 미승격. |
| `assets_unused/pending_review/estate_stages/daecheongmaru/daecheongmaru_s2_frame.png` | 독립 대청 골조 후보 | **아카이브** | P3 | 동일. | 런타임 미승격. |
| `assets_unused/pending_review/estate_stages/daecheongmaru/daecheongmaru_s3_final.png` | 독립 대청 완성 후보 | **아카이브/정자 참고 금지에 가깝게** | P3 | 현재 작은 독립 대청 실루엣을 완성하는 자산이지만 masterplan에서는 불필요. | 내부 venue로 분류하고 지도 체인은 닫는다. |
| `assets_unused/pending_review/estate_stages/haengrangchae/haengrangchae_frame_aligned.png` | 행랑 정렬 골조 | **소스 유지** | P2 | 정렬 중간 산출물. | 회귀용만. |
| `assets_unused/pending_review/estate_stages/haengrangchae/haengrangchae_s1_foundation.png` | 행랑 기단 후보 | **중복 정본화** | P1 | production s1과 동일 체인. | 해시 비교 후 정본 1개. |
| `assets_unused/pending_review/estate_stages/haengrangchae/haengrangchae_s2_frame.png` | 행랑 골조 후보 | **중복 정본화** | P1 | production s2와 동일 체인. | 정본 1개. |
| `assets_unused/pending_review/estate_stages/haengrangchae/haengrangchae_s3_roof.png` | 행랑 지붕 후보 | **중복 정본화** | P1 | production s3와 동일 체인. | 정본 1개. |
| `assets_unused/pending_review/estate_stages/haengrangchae/haengrangchae_s4_final.png` | 행랑 최종 단계 | **승격 권장** | P1 | 현재 체인에 빠진 완성 상태다. | renderer 배선과 함께 승격. |
| `assets_unused/pending_review/estate_stages/rear_garden/rear_garden_s1_hardscape.png` | 후원 경질경관 후보 | **교체** | P1 | 거대 정원 전제의 중간 단계. | V2 화계/석축 모듈로 대체. |
| `assets_unused/pending_review/estate_stages/rear_garden/rear_garden_s2_bridge.png` | 후원 다리 후보 | **조건부 아카이브** | P2 | 큰 연못을 요구한다. | 작은 연못 설계 확정 전 미승격. |
| `assets_unused/pending_review/estate_stages/rear_garden/rear_garden_s3_final.png` | 후원 최종 후보 | **런타임 퇴역** | P0 | 현재 과밀 rear_garden 메가 레이어의 최종 상태다. | 분해 후 새 모듈로 대체. |
| `assets_unused/pending_review/estate_stages/sadang/sadang_frame_aligned.png` | 사당 정렬 골조 | **소스 유지** | P2 | 정렬 중간 산출물. | 회귀용만. |
| `assets_unused/pending_review/estate_stages/sadang/sadang_s1_platform.png` | 사당 기단 후보 | **중복 정본화** | P1 | production s1과 동일 체인. | 정본 1개. |
| `assets_unused/pending_review/estate_stages/sadang/sadang_s2_frame_roof.png` | 사당 골조 후보 | **중복 정본화** | P1 | production s2와 동일 체인. | 정본 1개. |
| `assets_unused/pending_review/estate_stages/sadang/sadang_s3_final.png` | 사당 최종 단계 | **승격 권장** | P1 | 현재 체인에 빠진 완성 상태다. | 사당담/일각문과 함께 배선. |
| `assets_unused/pending_review/estate_stages/seogo/cut/seogo_finished.png` | 서고 완성 후보 | **육안 QA 후 보류/승격** | P2 | 이미 생성 완료된 후보라 재생성하면 안 된다. | 독립 서고가 필요한지 사랑채 wing으로 통합할지 masterplan 확정 후 검수. |
| `assets_unused/pending_review/estate_stages/seogo/raw/seogo_finished_raw.png` | 서고 raw | **소스 보관** | P3 | 생성 원본. | provenance만. |
| `assets_unused/pending_review/estate_stages/sotdaeulmun/sotdaeulmun_frame_aligned.png` | 대문 정렬 골조 | **소스 유지** | P2 | 정렬 중간 산출물. | 회귀용만. |
| `assets_unused/pending_review/estate_stages/sotdaeulmun/sotdaeulmun_s1_platform.png` | 대문 기단 후보 | **중복 정본화** | P1 | production s1과 동일 체인. | 정본 1개. |
| `assets_unused/pending_review/estate_stages/sotdaeulmun/sotdaeulmun_s2_frame_roof.png` | 대문 골조 후보 | **중복 정본화** | P1 | production s2와 동일 체인. | 정본 1개. |
| `assets_unused/pending_review/estate_stages/sotdaeulmun/sotdaeulmun_s3_final.png` | 대문 최종 단계 | **승격 권장** | P1 | 현재 체인에 빠진 완성 상태다. | 문 열림 상태/담 접속과 함께 배선. |
| `assets_unused/pending_review/estate_stages/anchae/raw/anchae_edit_base.jpg` | 건축 편집 원본 | **소스 보관** | P3 | 완성 에셋 역분해/정렬을 재현하기 위한 원본이다. | 런타임·pubspec 제외, provenance만. |
| `assets_unused/pending_review/estate_stages/anchae/raw/anchae_frame_raw.png` | 건축 편집 원본 | **소스 보관** | P3 | 완성 에셋 역분해/정렬을 재현하기 위한 원본이다. | 런타임·pubspec 제외, provenance만. |
| `assets_unused/pending_review/estate_stages/haengrangchae/raw/haengrangchae_edit_base.jpg` | 건축 편집 원본 | **소스 보관** | P3 | 완성 에셋 역분해/정렬을 재현하기 위한 원본이다. | 런타임·pubspec 제외, provenance만. |
| `assets_unused/pending_review/estate_stages/haengrangchae/raw/haengrangchae_frame_raw.png` | 건축 편집 원본 | **소스 보관** | P3 | 완성 에셋 역분해/정렬을 재현하기 위한 원본이다. | 런타임·pubspec 제외, provenance만. |
| `assets_unused/pending_review/estate_stages/sadang/raw/sadang_edit_base.jpg` | 건축 편집 원본 | **소스 보관** | P3 | 완성 에셋 역분해/정렬을 재현하기 위한 원본이다. | 런타임·pubspec 제외, provenance만. |
| `assets_unused/pending_review/estate_stages/sadang/raw/sadang_frame_raw.png` | 건축 편집 원본 | **소스 보관** | P3 | 완성 에셋 역분해/정렬을 재현하기 위한 원본이다. | 런타임·pubspec 제외, provenance만. |
| `assets_unused/pending_review/estate_stages/sotdaeulmun/raw/sotdaeulmun_edit_base.jpg` | 건축 편집 원본 | **소스 보관** | P3 | 완성 에셋 역분해/정렬을 재현하기 위한 원본이다. | 런타임·pubspec 제외, provenance만. |
| `assets_unused/pending_review/estate_stages/sotdaeulmun/raw/sotdaeulmun_frame_raw.png` | 건축 편집 원본 | **소스 보관** | P3 | 완성 에셋 역분해/정렬을 재현하기 위한 원본이다. | 런타임·pubspec 제외, provenance만. |

### 검토대기 QA

| 파일 | 역할 | 판정 | 우선 | 평가 | 구현 |
|---|---|---|---:|---|---|
| `assets_unused/pending_review/reference_full_estate.png` | 완성형 대조 이미지 | **QA 전용** | P3 | 런타임이 아니라 사람이 레이어 합성을 비교하는 참조 이미지다. | “완성 예시 보기” 기능이 생기기 전에는 번들 금지. |
| `assets_unused/pending_review/estate_scale_study/estate_scale_mockup_2026-08-19.png` | 축척 목업 | **QA 전용** | P1 | masterplan과 건물 축척을 판단하기 위한 목업이다. | 새 배치 승인 회의 자료로만 사용, 런타임 금지. |

## 9. 최종 한 줄 결정

**한글소리 종가 V2는 새 건물을 계속 얹는 작업이 아니다. 현재 사랑채와 A1 기술을 중심으로, 대지의 여백·문·담·마당·동선을 다시 조직하고, 생활 소품을 방과 조건 속으로 내려보내는 작업이다.**

가장 먼저 만들 것은 별당도 서고도 아니다. `estate_masterplan_v2.json`, `site_base_v2_master.png`, `jungmun_ilgakmun.png`, 담장 모듈, 우물, 간결한 정자다.