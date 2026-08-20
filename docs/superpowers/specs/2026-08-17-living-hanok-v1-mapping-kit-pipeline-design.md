# 살아 있는 한옥 V1 — 학습경로 ↔ 한옥 외관·사랑방 내부 매핑 / 이미지 목록 / "같은 기초 위에 스타일 변화 없이 쌓기" 파이프라인 재검토

작성 2026-08-17 · 상태: **승인됨(2026-08-17, Jin) · v2 적대 리뷰 2축 반영** · 범위: 설계 + 이미지 목록 + 파이프라인 재설계. 이 문서 자체는 코드를 바꾸지 않는다.

> **부분 superseded / A1·조사 이력 전용.** 출처 사용 경계, 건축 사실 조사와 A1
> 결정론적 제작·검수 파이프라인은 계속 유효하다. §4.2–§4.6의 A2–C2 grant 매핑과
> §5의 후속 이미지 목록은
> [`2026-08-20-hanok-level-proof-and-skip-recovery-design.md`](2026-08-20-hanok-level-proof-and-skip-recovery-design.md)가 대체한다.
> 독립 `daecheongmaru`와 `rear_garden`을 V2 구조·생성 입력으로 사용하거나 이 문서의
> 2026-08-17 저장소 상태를 현재 사실로 인용하지 않는다.

---

## 0. 배경 (왜 이 계획인가)

**요청.** Jin: 한옥 짓기 콘텐츠를 대충 만들 생각이 없다. 세 출처(비바샘 테마여행 5, 서울한옥포털 구조, 국가한옥센터 한옥의 시공)를 샅샅이 조사해서 ① 한옥 외관과 사랑방 내부 꾸미기를 현재 구현된 레벨별 학습경로(86 CanDoSegment)에 어떻게 잇는지, ② 만들 이미지 전체 목록, ③ 어떻게 만들지, ④ **같은 기초 바닥 위에 스타일 변화 없이 똑같이 위로 쌓아 올리는 한옥**을 어떻게 만들지 다시 검토.

**지금 상태(실측).**
- A1 16단계 카탈로그·컴포지터·승격 도구는 코드로 고정됨(`lib/data/a1_hanok_construction_catalog.dart`, `tool/compose_hanok_a1_state.py`, `tool/promote_hanok_a1_states.py`). 런타임 `a1/states/`는 없고 QA WebP는 05~10 여섯 장뿐. `generationLedger.records=[]`.
- 05~10 계보는 **폐기 확정**(Codex 06이 앞줄 기둥 7개만, 완성 사랑채는 8기둥 7칸; 07~10에 뒷줄·옆보 없음). BBANANA 뒷줄 재생성 5회 전부 실패(모델이 카메라를 돌리거나 기단을 키움). 누적 20.6 credit 소진, 잔액 900.7.
- 86 grant 초안(`tools/content_factory/drafts/hanok_grants.json`)은 A1만 실제 자산과 연결. A2~C2의 `hanok_reveal_*_v1`은 전부 placeholder, 이미지 0장, l10n 키 0개. 릴리스 원장 `hanok_grants_v1.json` = `publishedGrants: []` → kind/venue/ID 재배정 자유.
- 사랑방(room-v3 자유배치)은 이미 살아 있음: 장식 11종(보자기), 스티커 30, 도장 14. 퀘스트 전용 장식 13종은 마당 전용.
- 완성 사랑채 `personal_hanok_v2/map/structures/sarangchae.png`(1536×1152 RGBA, allowlist, sha `f523e93f…`)와 빈 대지 `site_base_light.png`가 유일한 승인 모델 입력(+QA 합성물).

**출처 사용 경계(변경 없음).** `docs/HANOK_V1_SOURCE_REGISTRY.md`: 세 사이트와 Jin이 붙인 화면은 **사실 색인**으로만 쓴다. 문장 복사·이미지 crop/tracing/재채색·생성 모델 입력 금지. 비바샘은 주제 색인일 뿐, 카드에 쓰는 건축 사실은 hanokdb/서울포털에서 확인된 것만. 모든 문구 KO/DE/EN 독자 작성, 모든 도식은 텍스트 없는 자체 SVG.

---

## 1. 세 출처에서 확인한 사실 (계획의 근거)

원문 덤프: `scratchpad/sources/*_verbatim.md`(세션 한정). 아래는 계획에 쓰는 사실만.

### 1.1 국가한옥센터 `hanokdb.kr/theology/sub_04` (6탭 전문; sub_04_01~05는 404, 내용은 탭에 포함)
- **공사 12단계(의례 포함)**: ①집터잡기(복거·좌향) ②설계 ③기초공사(개기) ④초석놓기(열초) ⑤치목(치목) ⑥조립=기둥→들보·도리→서까래·개판(입주·**상량**) ⑦기와잇기 ⑧수장들이기(벽선) ⑨흙벽치기 ⑩마감(온돌·마루·난간·창호) ⑪주변가꾸기(화계·장독대·담장·대문) ⑫입택(입택).
- **목구조 조립 순서**: 기둥 세우기 → 기둥 상부에 **창방** 짜맞춤 → **주두** → 앞뒤 방향 **보**(대들보→중보·종보, 툇보) → 직각 방향 **도리**(주심·중·**종도리**) → 종도리 올리면 **상량식**. 기둥: 원형/네모, 민흘림/배흘림, 외진주/내진주. 도리: 굴도리/납도리/팔각. 공포: 주두·첨차·살미·소로 / 주심포·다포·익공.
- **지붕**: 추녀(모퉁이 45°, 가장 먼저) → 서까래 → 평고대 고정 → 부연 → 합각. 기와잇기: 산자 엮기 → 흙 → 적심·보토 → 암키와 → 홍두깨흙 → 수키와 → 마루기와(용마루·내림마루·추녀마루). 홑처마/겹처마.
- **온돌**: 아궁이·부뚜막·구들장·고래·두둑·부넘기·바람막이·개자리·굴뚝. **마루**: 우물마루 = 장귀틀·동귀틀 골격 + 청판; 머름착고·머름중방·머름동자·외중방·여모중방.
- **창호·천장**: 호(戶, 출입)/창(窓, 채광·환기); 판문/살문(세살, **꽃살**); 창호는 수장들이기 뒤 **머름**(문갑 높이) 들인 후; 연등천장(대청·누마루) / 의장·우물천장(궁·사찰, 단청).
- **장인**: 대목수(도편수)·소목수·흙벽공·기와공·단청장·석수. 그랭이질, 이음·맞춤.

### 1.2 hanokdb `sub_02`(종류) · `sub_03`(감상) · `sub_05`(용어사전 PDF, 한자·영문 있음)
- 지붕 재료: 기와집(중상류, **청기와**=고위)/초가(서민, 1~2년 갈이)/너와(산간). 지붕 형태: 맞배(행랑·곳간·사당)/**팔작**(안채·사랑채)/우진각(민가·초가).
- 평면: ㅡ자(남부)/ㄱ자(중부)/ㄷ자(영남 북부 반가)/ㅁ자(안동); 홑집/겹집.
- **채와 마당**: 안채(안방·건넌방·안대청·부엌·곳간, 안마당) / 사랑채(대청·누마루·침방·서고, 사랑마당은 대문과 직결) / 행랑채(대문간·행랑방·곳간·광·마구간) / 사당(안채 동북, 별도 담·문) / 별당.
- **사랑방**: 남자주인 거처·접객·독서·사색·예술. 가구는 유교 영향으로 **간소** — 사방탁자·문갑·책장·문방소품·방석·팔걸이·목침·장·머릿장. 안방: 농·장·반닫이·좌경·반짇고리. 부엌: 찬장·찬탁·뒤주·소반. 붙박이: 벽장·반침·선반. 가사제한: 살림집은 다듬은 돌·공포·단청 금지.
- **정원**: 화계(후면 경사), 담장·문·굴뚝·장독대·연못·석물·화단·석축·계단·다리·산책로·누정; "후원에 독립된 온돌 연통, 담장 장식".
- 용어사전(발췌): 기단·초석·기둥(평주·고주·우주·동자주)·창방·평방·보·대공·장여·도리·처마·서까래·추녀·평고대·개판·박공·적심·보토·연함·기와·용마루·온돌·구들·마루·귀틀·청판·난간·수장재(인방·머름·벽선·문선)·터잡기·지정·달구질·정초·실띄우기·치목(마름질·바심질·가심질·그레질)·결구(맞춤·이음·장부)·입주·수장(외엮기·초벽·재벽·정벌)·단청·기름먹이기 / 연장: 모탕·도행판·대패·끌·다림추·메 / 의례: **개토제·모탕고사·입주식·상량식(상량문)·준공식**. **DE 없음 → 독자 작성.**

### 1.3 서울한옥포털 `infoHanok.do?tab=1·2` (tab 3·4 없음)
- 정의: 기둥·보·한식지붕틀 목구조; 판단 기준 = 한식기와 + 목구조 (+전통미·자연재료).
- 구조 도해 라벨(사실 색인): 용마루·부고·착고·마루적심·종도리·종도리받침장여·뜬창방·대공·평고대·서까래·종보·대들보·단연·중도리·장연·주심도리·장여·상인방·문설주·기둥·중방·하방·머름·벽돌벽·기단·마루널·장귀틀·동귀틀.
- 지방별: 북부 겹집·낮은 지붕(田자: 도장방·정주간·외양간·뒷간), 중부 ㄱ자(안방·대청·건넌방·툇마루), 남부 홑집 ㅡ자(대청 중심).

### 1.4 비바샘 `themeTour_5` (4탭 전문) — **주제 색인만**
한옥 3부(지붕부/벽체부/기단부), 공포 3형, 마루 종류(대청·툇마루·쪽마루·누마루), 창호 명칭 목록(맹장지·불발기·귀자창·귀갑창·띠살창·완자살창·빗살창), 온돌 방고래, 바람길, 서울색 4, 아파트 평면 4형. 이 중 hanokdb/서울포털에서 재확인되지 않은 것(완자살·꽃담 등)은 grant 카드 사실 문장에 쓰지 않는다.

**결론: 현재 A1 16단계 ID는 hanokdb 12공정과 정확히 정합한다.** (01터잡기 02설계 03기초·기단 04초석 05치목 06기둥 07창방·보 08도리·상량 09서까래·추녀 10산자·적심·보토 11지붕잇기 12수장 13흙벽 14온돌·마루 15창호 16주변·입택). 순서·명칭 유지. 11 지붕 재료만 결정 D1.

---

## 2. 재검토 결론 3줄

1. **매핑 원칙 = "6시대 = 6공간층"**: A1 짓다=사랑채 골조·외피(외관 16), **A2 살다=사랑방 내부(가구·문방·수장)**, B1 잇다=대문·행랑채·안채(바깥·가족과 잇기), B2 나누다=대청·사당·후원·마당 구조물·외관 옵션(손님·의례·공동체), C1 돌보다=계절·보수(돌봄 흔적), C2 전하다=사랑방 벽감 서가에 쌓이는 문집·증표. 86개 grant 전부 "눈에 보이는 한 가지 변화"를 갖되 큰 그림은 A1 16장 + 건물별 3~4장뿐이다.
2. **이미지 제작 원칙 = "생성 모델은 그림이 아니라 부품만 그린다"**: 단계 그림을 모델에게 시키면(지금까지 25회) 기하·굵기·카메라·칸수가 매번 흔들린다. 대신 **승인된 완성 사랑채 1장에서 위치·크기·재질을 역분해**하고, 숨은 골조 부품만 모델로 **한 번씩** 만든 뒤, Python 컴포지터가 **manifest 좌표대로 결정론적으로 쌓는다**. 같은 manifest + 같은 인코더 빌드 → 같은 SHA. 스타일 드리프트·뒷줄 누락·칸수 오류가 구조적으로 사라진다.
3. **A1 로드맵**: 16장 중 11·15는 완성본 crop(픽셀 동일), 03·04·06은 crop+결정론 보정, 07~10·12~14는 부품 키트, 01·02·05·16은 소품. 뒷줄은 앞줄 crop을 **원근 벡터**(−k·d·(x−427), −d), d=16(그려진 기단 깊이)로 옮겨 앞기둥 뒤에 깐다. B1·B2 건물은 같은 방법을 3~4단계로 축약 적용한다.

---

## 3. 결정 사항 (기본값 = 이 계획이 전제하는 값. 승인 시 바꾸면 §4·§5가 그대로 따라감)

| # | 결정 | **기본값(권장)** | 대안 | 왜 |
|---|---|---|---|---|
| D1 | A1-11 지붕 재료 | **기와** — `11_choga_roof`→`11_giwa_roof`. **A1-16 = `sarangchae.png` ∪ `sarangchae_props`(굴뚝·아궁이·입택 소품 영구 레이어)** | 초가 유지 → A2 첫 grant가 기와 교체(초가 지붕 sprite 1장 + 11~16 초가 버전) | hanokdb ⑦ 기와잇기; 완성 사랑채(allowlist·기하 정본)가 기와; 사랑채(반가 접객채)에 초가 부적합; 계보 1개. 초가는 B2 designOption 후보로 남김 |
| D2 | 사랑방 개방 시점 | **처음부터 열림(현행 유지, venue grant 없음)** — projector `openedVenues`에 sarangbang을 **기본 포함**하도록 변경(§6.3-7). A2 grant가 가구를 채운다 | A1-16 입택 때 개방 / B1-18(현 초안) | 현 제품 흐름(`/sarangbang` enforceUnlock:false)·room-v3 보존 원칙과 일치. venue grant는 안방(B1-18)·대청(B2-20)만 |
| D3 | A2 16개의 정체 | **사랑방 가구·문방 12(furnishing) + 살림 흔적(외관 ambience) 4** | 현 초안(외관 designOption 12 + ambience 4) | Jin 요청 "사랑방 내부 꾸미기 잇기". 시대명 "살다"와 정합. hanokdb 사랑방 가구 목록이 사실 근거 |
| D4 | 파이프라인 | **부품 키트 + 결정론 컴포지터(§6)** | 단계별 모델 재생성 계속 | 25회 실패 원인이 모두 "모델이 전체를 다시 그림". 크레딧 1/3 |
| D5 | B1/B2 constructionPiece의 실체 | **기존 완성 건물 PNG를 3~4 매크로 단계로 역분해**(대문 3·행랑채 4·안채 4 / 대청 3·사당 3·후원 3) + 마당 구조물 3(우물·석등·담장 장식 구간), **단계는 prerequisite 체인** | 건물당 1장(통째 등장) | 세그먼트마다 "보이는 변화" 유지, 새 그림은 건물당 골조 1장뿐. B1/B2 평가에는 선행조건이 없어 grant 쪽 prerequisite가 필수 |
| D6 | 지식 콘텐츠 깊이 | grant reveal 시트에 KO 용어(한자·로마자)+DE/EN+출처 기반 한 줄 사실 + 의례. `cultural_glossary.json`에 건축 용어 ~24개. 텍스트 없는 SVG 지식카드 6장은 **후순위 트랙** | 최소 캡션만 | Jin: "대충 만들 생각 없다" |
| D7 | 계절(C1) 표시 | **designOption(slot `ambience`, contextPlausible) 4개** — 학습자가 고르며, 미선택 시 실제 달력 월로 자동 | ambience kind(전부 겹침) | `activeLoadout`은 slot당 1개 선택 구조; 봄꽃과 눈이 겹치면 안 됨 |

---

## 4. 학습경로 ↔ 한옥 매핑 (86 grant 전부)

`HanokGrowthEra` build/live/connect/share/care/transmit = A1~C2. kind = constructionPiece(구조) / **furnishing(신설: 사랑방 가구, venueSurface 필수 = 인벤토리 대상 방, designSlot 금지, `openedVenues`에는 넣지 않음)** / designOption(택일 옵션) / venue(방 개방) / ambience(겹칠 수 있는 분위기) / credential(증표).

### 4.1 A1 짓다 (16, constructionPiece, 순차 prerequisite — 변경 없음, 11만 rename)

| step | id | 세그먼트(A1 can-do) | 보이는 변화(소켓 854×309 안) | 부품 출처 | 학습 카드 용어(hanokdb) |
|---|---|---|---|---|---|
| 01 | site_setout | 01 인사·한글 | 말뚝 4 + 실띄우기(기단 발자국 사다리꼴 (18,264)-(834,264)-(800,228)-(52,228)) + 좌향 표식. **transient** | 생성 소품 1세트 | 터잡기·복거·좌향·실띄우기·개토제 |
| 02 | plan_layout | 02 자기소개 | 먹줄 격자(기둥 x 8선 × 3선, 프로그램) + 도행판 소품. **transient** | 프로그램 선 + 생성 소품 1 | 설계·도행판·칸(정칸·협칸·퇴칸) |
| 03 | foundation_gidan | 03 은/는·이/가 | 기단(사다리꼴 윗면 + 2단 면 + 계단) | **crop+결정론 보정**: 완성본 y252~306 crop ∪ 양끝 쐐기(y228~251, x<52/x>800) + 윗면 y228~251(x52~800)을 y252~263 띠 세로 타일로 채움, 하방 그림자·얼룩 제거 | 기초·지정·달구질·기단(장대석기단) |
| 04 | cornerstones_choseok | 04 주문·을/를 | 초석 8(앞, 실측 사다리꼴 폴리곤 crop) + 8(뒤, 원근 벡터 이동·어둡게) | 완성본 폴리곤 crop → 복제 | 초석·정초·열초·그레질 |
| 05 | timber_preparation | 05 시간·숫자 | 원목·각재 더미 + 모탕(기단 윗면 위, **transient**) | 생성 소품 3 | 치목·마름질·바심질·모탕고사·대패·끌 |
| 06 | columns | 06 교통·길 | 앞기둥 8(crop, 실측 x구간 [53–68][161–181][273–291][356–374][478–498][562–580][672–691][784–799], y157~243) + 뒷기둥 8(원근 벡터 복제, 바깥 칸에서만 조금 보임). 주두는 그리지 않음(완성본에 별도 주두 없음) | 완성본 crop + 복제 | 기둥·평주·우주·입주식·다림보기 |
| 07 | beams_changbang | 07 연락처·주소 | 창방·장여 밴드 앞(y145~156 crop)·뒤(벡터 이동) + 보 8(앞머리→뒷머리, 벡터 방향 짧은 부재) + 옆보 2 | 완성본 밴드 crop + 생성 부품 2(보·옆보) | 창방·보(대들보·툇보)·장여·맞춤·이음 |
| 08 | purlins_sangnyang | 08 못 알아들었을 때 | 주심도리(앞·뒤) + 동자주·중도리 2 + 대공·**종도리**(y≈40) + 상량문 천 | 생성 부품 3(도리 타일·대공·상량문) | 도리·대공·**상량식·상량문** |
| 09 | rafters_roof_frame | 09 집·일상 | 서까래 앞면 ≈47줄(종도리→처마) + 추녀 4(끝이 x=1/850까지) + 평고대 + 처마 서까래끝 밴드(y133~144, 비-기와 픽셀만) | 생성 부품 2(서까래·추녀) 타일 + 완성본 밴드 crop | 서까래·추녀·평고대·부연·홑/겹처마 |
| 10 | roof_base | 10 건강·안전 | 기와로 분류된 alpha 영역(처마선 ≤y130~143, x별)을 개판·산자·적심·보토 질감으로 채움(서까래끝 밴드는 노출) | 생성 텍스처 타일 1 + 분류 mask | 산자·개판·적심·보토 |
| 11 | **giwa_roof**(D1) | 11 호칭·관계 | 완성 기와지붕 | **완성본 crop**(alpha 기준 y0~156) — 이후 픽셀 동일 | 기와·암키와·수키와·홍두깨흙·마루기와·용마루 |
| 12 | wall_frame_sujang | 12 일상·부정 | 칸마다 상인방·중방·하방·벽선·머름 틀(칸 폭 83/110/123 세 종) + 뒷벽면 | 완성본 하방 crop(y229~238) + 생성 칸틀 3폭(또는 프로그램 선+질감) | 수장·인방·머름·벽선·문선 |
| 13 | earth_walls | 13 말투 바꾸기 | 칸 벽 부분 심벽 초벽(황토+짚) | 생성 패널 1(3폭) | 흙벽·외엮기·초벽·재벽·정벌 |
| 14 | ondol_maru | 14 결제·배달 | 굴뚝(기단 오른쪽 쐐기 위, 처마 아래 z) + 아궁이(기단 왼쪽 면) + 열린 칸으로 보이는 장판 바닥·가운데 칸 우물마루 → **굴뚝·아궁이는 `sarangchae_props` 영구 레이어** | 생성 부품 4 | 온돌·구들·아궁이·고래·굴뚝·마루·귀틀·청판 |
| 15 | changho_finish | 15 첫 수업·첫 만남 | 칸 창호·회벽 완성(7칸 패널 crop, 기둥 옆 1px 프린지 포함) | **완성본 crop**(y157~228, 칸별) — 이후 픽셀 동일 | 창호·호/창·세살·머름·창호지 |
| 16 | landscape_move_in | 16 첫 90일 캡스톤 | 섬돌 위 신발 한 켤레·처마 등롱·발·기단 쐐기 위 화분 2(소켓 안 propsZone) — 열린 문 없음(15와 픽셀 충돌) | 생성 소품 1세트 → `sarangchae_props` | 입택·준공식·주변가꾸기(화계·장독대·담장·대문은 B1/B2) |

A1-16 합성 = 대지 + `sarangchae.png` + `sarangchae_props` → estate map과 픽셀 연속(테스트: props 끄고 합성한 16의 소켓 내부 RGB == base ⊕ sarangchae.png, 변경 픽셀 0).

### 4.2 A2 살다 (16) — 사랑방 furnishing 12 + 외관 ambience 4 (D3)

furnishing = 획득 grant의 `revealAssetIds`(decoration slug)를 **읽기 시점**에 사랑방 꾸미기 인벤토리에 합집합(§6.3-7). 보자기 11종과 겹치지 않는 선비 가구. slug는 `decoration_` 접두사, `kAvailableDecorations`·`kDecorCategory`·`kDecorScale`·`decorName`(DE/EN 24키) 등록, 퀘스트 보상 풀 제외.

| ord | 세그먼트 | 보상 | 근거 |
|---|---|---|---|
| 1 | 격식체↔해요체 | `decoration_sabangtakja` 사방탁자 | hanokdb 사랑방 가구 |
| 2 | 친구와 약속 | `decoration_bangseok_pair` 방석 2 | 접객 |
| 3 | 생일 축하 | `decoration_soban_tea` 찻상 소반+다기 | 접객 |
| 4 | 지각 | `decoration_hwaro` 화로 | 난방·접객 |
| 5 | 약국 (ambience) | 외관: 굴뚝 연기(props 레이어 굴뚝 좌표에 앵커) | 살림 흔적 |
| 6 | 헬스장 (ambience) | 외관: 처마 등롱 켜짐(props 등롱 좌표) | 살림 흔적 |
| 7 | 아프다고 말하기 | `decoration_boryo_set` 보료·안석·장침 | 주인 자리 |
| 8 | 카페 주문 | `decoration_deungjan` 등잔대 | 조명 |
| 9 | 명동 쇼핑 | `decoration_meoritjang` 머릿장 | 수납 |
| 10 | 카페 공부 (ambience) | 외관: 용마루 위 까치 | 손님·소식 |
| 11 | 지하철 환승 | `decoration_yeonsang` 연상(벼루함) | 문방 |
| 12 | 택시 | `decoration_gobi` 고비 | 문방 |
| 13 | 지하철 길묻기 | `decoration_seoga` 서가(자유배치용; C2 표시의 필수조건 아님) | 서고 |
| 14 | 폰 분실 (ambience) | 외관: 장독대 자리 첫 항아리 2개 | 살림 |
| 15 | KTX 표 | `decoration_byeongpung_small` 2폭 소병풍(글자 없음) | 병풍 |
| 16 | 월세 이체 | `decoration_gyeongsang` 경상 | 문방 |

### 4.3 B1 잇다 (18) — 대문 3 · 행랑채 4 · 안채 4 (prerequisite 체인) + ambience 6 + venue 안방 1

| ord | 세그먼트 | kind | 보상 | prerequisite |
|---|---|---|---|---|
| 1 | 약속 미루기 | constructionPiece | 솟을대문 ① 기단·문설주 기둥 | — |
| 2 | 여행 경험 | ambience | 사랑마당 석등 | — |
| 3 | 회식 1차→2차 | constructionPiece | 솟을대문 ② 지붕 | B1-1 |
| 4 | 매체 인용 전달 | ambience | 대문 앞 소나무 | — |
| 5 | 은행 계좌 | constructionPiece | 솟을대문 ③ 문짝·편액(빈 판) | B1-3 |
| 6 | 회의 역할 조율 | constructionPiece | 행랑채 ① 기단·초석 | — |
| 7 | 출석 회신 | constructionPiece | 행랑채 ② 골조·지붕틀 | B1-6 |
| 8 | 회의 일정 조정 | constructionPiece | 행랑채 ③ 지붕 | B1-7 |
| 9 | 따뜻한 격려 | ambience | 행랑마당 빨랫줄·바구니 | — |
| 10 | 사랑 고백 | ambience | 사랑마당 매화 개화 | — |
| 11 | 초대·응답 | ambience | 대문 열림(문짝 open overlay) | B1-5 |
| 12 | 배달 문제 해결 | constructionPiece | 행랑채 ④ 벽·창 완성 | B1-8 |
| 13 | 누수 신고 | constructionPiece | 안채 ① 기단·초석 | — |
| 14 | 계약 약속 확인 | constructionPiece | 안채 ② 골조·지붕틀 | B1-13 |
| 15 | 난방 켜둔 채 | constructionPiece | 안채 ③ 지붕 | B1-14 |
| 16 | 연인과 다툼 | ambience | 안마당 장독대 채움 | — |
| 17 | 이사 전 열쇠 받기 | constructionPiece | 안채 ④ 벽·창호 완성(입택) | B1-15 |
| 18 | 인생 이야기 | **venue → anbang** | 안방 개방(`interiors/anbang_empty.png`) | B1-17 |

### 4.4 B2 나누다 (20) — constructionPiece 12(대청 3·사당 3·후원 3·마당 구조물 3) + designOption 4(진짜 택일) + credential 3 + venue 대청 1

| ord | 세그먼트 | kind | 보상 | prerequisite |
|---|---|---|---|---|
| 1 | 비즈니스 첫 소개 | constructionPiece | 대청마루 ① 기단·기둥 | — |
| 2 | 높임 변환 | constructionPiece | 대청마루 ② 지붕 | B2-1 |
| 3 | 결정 기준·타협 | constructionPiece | 대청마루 ③ 마루·난간 완성 | B2-2 |
| 4 | 공고문 다듬기 | constructionPiece | 후원 담장 장식 구간(hanokdb "담장 장식") | — |
| 5 | 협업 피드백 | constructionPiece | 사당 ① 기단·기둥·지붕틀 | — |
| 6 | 디지털 출처 판단 | credential | 증표 인장 1 | — |
| 7 | 사회적 근거 논증 | credential | 증표 인장 2 | — |
| 8 | 언어·사회 변화 | designOption(changho, ceremonialImaginative) | 창호 꽃살(hanokdb) 칸 패널 세트 | — |
| 9 | 병원 증상 | constructionPiece | 사당 ② 지붕 | B2-5 |
| 10 | 서명 주체 확인 | constructionPiece(초안 venue→변경) | 사당 ③ 담장·문 | B2-9 |
| 11 | 마감 연장 요청 | constructionPiece | 후원 ① 연못·석축·다리 | — |
| 12 | 환경 트레이드오프 | designOption(courtyard, contextPlausible) | 굴뚝 형태: 기와 굴뚝(기본=흙 연통) | — |
| 13 | 오배송 항의 | constructionPiece | 후원 ② 정자 | B2-11 |
| 14 | 서면 시정 요구 | constructionPiece | 후원 ③ 화계·수목 | B2-13 |
| 15 | 공용 공간 조율 | constructionPiece | 우물(돌우물+두레박) | — |
| 16 | 개인 경계 협상 | constructionPiece | 석등·석조 | — |
| 17 | 가정 안전 규칙 | designOption(wallFinish, commonResidential)(초안 cP→변경) | 사랑채 벽 황토 마감(기본=회벽) | — |
| 18 | 면접 | credential | 증표 인장 3 | — |
| 19 | 문학·문화 감상 | designOption(roofMaterial, ceremonialImaginative) | 청기와(기본=기와) | — |
| 20 | 격식·완곡 재표현 | **venue → daecheongmaru** | 대청 개방(`daecheong_empty.png`) | B2-3 |

### 4.5 C1 돌보다 (8) — credential 4 + designOption(slot ambience) 4 (D7)
1 증거 타당성=인장 / 2 제한된 결론=인장 / 3 위험·불확실=**봄**(후원 매화·잔물결) / 4 위험 정보 수정=**여름**(연꽃·짙은 수목) / 5 접근 장벽=**가을**(국화·단풍) / 6 참여형 개선=인장 / 7 지속가능 수명=**겨울**(눈, 후원·담장 한정) / 8 지역 트레이드오프=인장. `HanokWeatheringTier`(fresh/livedIn/patina) 2 overlay(이끼·낙엽)는 별도 유지.

### 4.6 C2 전하다 (8) — credential 8 = **사랑방 배경의 왼쪽 벽감 선반(고정 좌표, 항상 존재)** 에 문집·족보 8권이 한 권씩 꽂힘 + 도장첩 "증표" 탭.

**증표 표면 원칙.** 15개 credential(B2 3·C1 4·C2 8)은 다른 grant/장식 소유에 기대지 않는다: 도장첩 증표 탭(읽기 시점 합집합, `HanokCredentialMotif` 별도 enum — `DancheongMotif`·`earnedStamps`와 분리) + 사랑방 배경 벽감 선반 credential 레이어(room-v3 아이템 아래, 학습자 배치 불필요).

### 4.7 확장 규칙 — 학습 콘텐츠를 추가해도 이 매핑은 흔들리지 않는다
- 이 표는 `core_2026_v1`의 **CanDoSegment 86개**(영구 분모)에 매핑한 것이지 CourseUnit·단어팩·시나리오·Cloze·Satz 수에 매핑한 것이 아니다. 같은 능력의 새 연습 콘텐츠는 `ContentCluster.revision`만 올리고 grant는 그대로다(ADR-003).
- 평가 교체(retire → 같은 construct의 successor, replacement track)는 같은 slot을 만족하므로 grant 불변(`satisfyingSegmentIdsForEditionSlot`). 이미 published된 grant는 `HanokGrantCatalog.validateEvolutionFrom`이 rewrite/삭제를 거부하고 새 grant는 뒤에 append만 된다.
- **진짜 새 can-do**를 additive extension track에 발행할 때는 grant 카탈로그가 "published additive segment 전부를 grant가 정확히 덮어야 한다"고 검사하므로(`hanok_grant_catalog.dart:84-88`; 생성기도 authored row 없으면 실패) **segment마다 grant 1행을 함께 authoring**한다. 확장 grant의 기본 규칙: kind = ambience 또는 furnishing(작은 sprite 1장, 큰 그림 불필요), prerequisite 없음, A1 16단계·건물 매크로 단계·venue는 core 전용. 즉 콘텐츠 추가 → 매핑 무영향, 능력 추가 → 소품 1장짜리 grant 1행 추가.

**변경 요약(초안 대비).** kind 신설 1(`furnishing`); venue 재배정(B1-18 sarangbang→anbang, B2-10 venue→constructionPiece); A2 12 designOption→furnishing; B2 designOption 4(changho·courtyard·wallFinish·roofMaterial; B2-4/15/16→constructionPiece, B2-17 cP→designOption); C1 ambience 4→designOption(ambience slot); B1/B2 prerequisiteGrantIds 체인 신설; 미사용 slot(roofForm·door·signboard·regionClimate)은 enum 유지. `revealAssetIds`가 실제 자산 ID를 가리키게 됨.

---

## 5. 만들 이미지 전체 목록

공통: Faceted Minhwa(BIBLE §1), 좌상단 광원, 팔레트 §1.3, 텍스트·UI·워터마크·사람 금지. **한지 그레인·그림자는 생성 부품 PNG에 등록 시점에 굽는다(컴포지터 전역 후처리 없음 — 픽셀 동일성 보존).** "생성"=BBANANA(Nano Banana Pro 4cr 2K / Nano Banana 2 3cr) + Recraft Remove BG 0.3cr → true-alpha PNG → 정규화. "crop"=완성 PNG에서 결정론 추출(0cr). 크레딧은 1.5회 시도 가정.

### 5.1 A1 부품 키트 (소켓 854×309, 결과물 16 WebP + 부품 PNG)
| # | 부품 | 출처 | 수량 | 예상 cr |
|---|---|---|---|---|
| K01 | 기단+계단 (crop y252~306 ∪ 쐐기 + 윗면 y228~251 결정론 채움, 얼룩 제거) | crop+보정 | 1 | 0 |
| K02 | 초석 8 (실측 사다리꼴 폴리곤, Jin 확인) | crop | 8 | 0 |
| K03 | 앞기둥 8 (실측 x구간, y157~243; 4·5번은 문선과 분리 폴리곤) | crop | 8 | 0 |
| K04 | 창방/장여 밴드(y145~156), 처마 서까래끝 밴드(y133~144 비-기와), 하방 밴드(y229~238), 지붕(alpha y0~156), 칸 창호 패널 7(y157~228, 프린지 포함) | crop | 11 | 0 |
| K05 | 말뚝+실 1세트, 도행판 1 (먹줄은 프로그램 선) | 생성 | 2 | 8 |
| K06 | 목재 더미 2·모탕 1 | 생성 | 3 | 12 |
| K07 | 보 1, 옆보 1 | 생성 | 2 | 8 |
| K08 | 도리 타일 1, 동자주/대공 1, 상량문 천 1 | 생성 | 3 | 12 |
| K09 | 서까래 1(타일), 추녀 1 (평고대는 프로그램) | 생성 | 2 | 8 |
| K10 | 산자·적심·보토 텍스처 타일(저주파) | 생성 | 1 | 4 |
| K11 | 칸 수장틀 3폭(83/110/123) 또는 프로그램 선+질감 1, 뒷벽면 1, 심벽 초벽 패널 1 | 생성 | 3~5 | 12~20 |
| K12 | 굴뚝, 아궁이, 장판 바닥, 우물마루 바닥 | 생성 | 4 | 16 |
| K13 | 입택 소품(신발·등롱·발·화분) | 생성 | 1세트 | 12 |
| (D1 대안) | 초가 지붕 sprite(완성 지붕 mask) | 생성 | 1 | 4 |
| **소계** | | | 생성 ≈22 | **≈100~110 (cap 200 이내)** |

### 5.2 사랑방 가구(A2 furnishing 12) — 1254px 긴변 RGBA, `assets/illustrations/decorations/` 규격
사방탁자·방석 2·찻상 소반+다기·화로·보료 세트·등잔대·머릿장·연상·고비·서가·2폭 소병풍·경상 = **12장, ≈45cr**. 프롬프트는 BIBLE §3.5 장식 템플릿 + `f63b517` 사랑방 컷아웃 형식(chroma-key, no-outline, hanji). **참조 이미지는 allowlist 편입 뒤에만**(§6.3-4).

### 5.3 외관 overlay(A2 4 + B1 6 + C1 4 계절 + 돌봄 2) — 1536×1152 RGBA(부분 alpha)
굴뚝 연기·처마 등롱 켜짐·용마루 까치·장독 첫 항아리 / 석등·소나무·빨랫줄·매화 개화·대문 열림·장독대 채움 / 봄·여름·가을·겨울(후원 영역 한정) / 이끼·낙엽 = **16장, ≈60cr**. 좌표는 `kPersonalHanokLayers` visualBounds 방식으로 고정, A2-5/6은 `sarangchae_props` 좌표에 앵커.

### 5.4 B1/B2 건물 매크로 단계 — 기존 완성 PNG 역분해 (`tool/derive_estate_building_stages.py`)
| 건물 | 완성 PNG | 단계 | 새 생성 |
|---|---|---|---|
| 솟을대문 | `sotdaeulmun.png` | 기단·문설주 → 지붕 → 문짝·편액 | 골조 1 |
| 행랑채 | `haengrangchae.png` | 기단 → 골조 → 지붕 → 벽·창 | 골조 1 |
| 안채(ㄷ자) | `anchae.png` | 기단 → 골조 → 지붕 → 벽·창호 | 골조 1 |
| 대청마루 | `daecheongmaru.png` | 기단·기둥 → 지붕 → 마루·난간 | 골조 1 |
| 사당 | `sadang.png` | 기단·기둥·지붕틀 → 지붕 → 담장·문 | 골조 1 (+담장·문 분리 crop) |
| 후원 | `rear_garden.png` | 연못·석축·다리 → 정자 → 화계·수목 | 0 (alpha 연결요소/폴리곤 mask 3분할) |
| 마당 구조물 | — | 우물 · 석등·석조 · 담장 장식 구간 | 3 sprite |
골조 5장 × (4+0.3) × 2회 ≈ 45cr + 마당 구조물 3 ≈ 12cr. 방법: `edit_image(base=완성 PNG[allowlist 편입 후], ref=승인된 A1 골조 부품 시트, "같은 카메라·같은 실루엣, 기와·벽·창호 제거, 목재 골조만")` → 게이트: 골조 alpha ⊆ dilate(완성 alpha, 6px), 기둥 발 ⊆ 기단 윗면 밴드, Jin 육안. 실패 시 A1 부품 키트로 프로그램 조립(폴백).

### 5.5 designOption overlay(B2 4): 꽃살 칸 패널 세트(3폭)·기와 굴뚝·황토 벽 패널(3폭)·청기와 지붕(mask) = **4세트 ≈6장, ≈25cr**.

### 5.6 credential(15): `HanokCredentialMotif` 7(B2 3+C1 4, 코드 페인터) + 벽감 선반 문집 sprite 2종 색 변형(C2 8권) = **≈2장, ≈8cr**.

### 5.7 후순위: 지식카드 SVG 6(목구조 분해도·온돌 단면·마루 구조·지붕 단면·창호 종류·평면형 3종) — 사실만 보고 자체 도해, 텍스트 없음, 라벨은 Flutter.

**총계**: 새 생성 ≈ 70장, ≈ 300cr(잔액 900.7). A1 ≈100cr는 provenance `staticMax 200` 안. B1~C2 자산은 ledger `estateStatic` 상한을 따로 둔다(계약 완화 아님, 범위 추가). WebP 예산 검증: base+sarangchae q82 m6 = 280,610B(≥48KB 여유); 기존 QA 276~295KB.

---

## 6. "같은 기초 위에 스타일 변화 없이 쌓기" — 파이프라인 재설계

### 6.1 원리
```
승인 완성 사랑채 sarangchae.png ──derive(재현 가능)──▶ a1_kit_geometry.json(기둥 x구간·밴드·폴리곤·지붕 mask·propsZone·원근 k,d) + crop 부품
                                                     │
BBANANA(부품만, 참조=allowlist) ──Recraft──▶ 생성 부품 PNG(true alpha, 그레인·그림자 굽기, alpha<160 림 제거) ─┐
                                                     ▼                                                        │
  stage_NN.json(부품·좌표·z·tint·transient) + previous-manifest ──▶ compose --kit ──▶ 854×309 layer ──▶ kit 게이트 ──▶ 1536×1152 WebP
  (같은 manifest + 같은 인코더 빌드 ⇒ 같은 SHA)                                                       ▼
                                                                                          Jin 육안 QA → ledger approved(kind=state) → promote(16 원자)
```
- **기하는 오직 완성본에서.** derive가 픽셀 분류(기와/목재/벽/석재/그림자)로 밴드를 계산하고 JSON에 쓴다(§6.2는 실측 요약일 뿐 하드코딩 금지). 기둥 x구간·초석 폴리곤은 derive가 제안, **Jin이 확인**한 값을 JSON에 고정하고 스냅샷 테스트로 잠근다.
- **카메라는 중앙 원근**(기단 윗면 옆모서리가 36행에 ±34px 수렴). 뒷줄 = 앞줄 crop을 벡터 (−k·d·(x−427), −d)로 이동, d = 기둥 발 y244 − 기단 뒷모서리 y228 = **16**(그려진 기단 깊이 = 양식적 선택), k=(52−18)/36/409≈0.0023, 명도 −14%. 바깥 칸에서만 뒷기둥이 ~13px 안쪽으로 조금 보인다. 보·옆보 sprite는 이 벡터 방향으로 그린다.
- **모델은 부품 1개씩만**, 참조는 allowlist(현재 `sarangchae.png`; 추가는 §6.3-4). 결과는 alpha·chroma 검사·크기 정규화·림 제거 후 SHA를 ledger에 `kind=part`로 기록(승인은 Jin 육안 1회/부품). BBANANA `upload_image`는 base64 ≤10MB — 부품 크기면 로컬 업로드 가능(대형 raw는 Jin이 bbanana.ai에서 직접).
- **스타일 통일** = 같은 참조·같은 프롬프트 블록 + 부품 등록 시 동일 후처리(그레인·그림자). 합성 뒤 전역 후처리·모델 다듬기 **없음**.
- **소켓 밖 픽셀 0 변경** 유지. 소품·굴뚝은 `propsZone`(소켓 여백 ∪ 기단 양끝 쐐기 y228~263, x≈20~50 / 805~834) 안에서만; 굴뚝은 지붕 crop 아래 z.

### 6.2 실측(sarangchae.png 소켓 로컬, 리뷰 검증치 — derive가 재계산)
기와 ≤y132(처마선 x별 130~143) · 서까래끝 점 y133~138(47개, y136) · 처마 그림자 y139~144 · 창방/도리 목재 y145~156 · 벽 y157~ · 하방 y229~238 · 그림자 y239~251 · 기단 윗면 y252~263 · 기단 면 y264~292(2단 264~277/278~291) · 계단 y293~306(x349~501) · 추녀 끝 x=1/850(y124~132) · 기단 윗면 옆모서리 (18,264)→(52,228), (834,264)→(800,228) · 앞기둥 8구간 [53–68][161–181][273–291][356–374][478–498][562–580][672–691][784–799] (칸 폭 110.5/111/83/123/83/110.5/110 — 정칸 123, 협칸 83; 4·5번 기둥은 문선과 붙음; 양끝 x=52/800에 녹색 반투명 잔여 201px). WebP: base+sarangchae q82 m6 = 280,610B.

### 6.3 도구·코드 변경(구현 단계에서)
1. **신규 `tool/derive_hanok_a1_kit.py`**: 입력 SHA=allowlist 검사 → 픽셀 분류 → `a1_kit_geometry.json`(pillars[i].xRange/yRange, choseok[i].polygon, bands, roofTileMask, panelBoxes[7], gidanPolygon, propsZone, perspective{k,d}, groundRowExclusive{stage≤02:293, ≥03:307}) + `a1_kit/derived/*.png`(비-런타임). derived 부품은 저장본을 신뢰하지 않고 **compose 시 재도출해 SHA 대조**.
2. **`tool/compose_hanok_a1_state.py` 확장 — kit 모드 규칙(원문)**:
   - `--kit-manifest stage_NN.json --previous-manifest stage_MM.json --previous-layer MM.png`; 레이어는 정확히 854×309, **리사이즈 경로 비활성**.
   - **anchor(kit)**: alpha>8 bbox가 x=427을 포함하고 bottom ≥ geometry.groundRowExclusive(01·02=293, ≥03=307). `requireExclusiveBottom`은 raw 모드 전용으로 유지, provenance에 `socketLayer.kitGroundRows` 추가.
   - **연속성(kit)**: previous_structural_mask = alpha(previous_layer) − dilate(previous-manifest의 transient 부품 mask, 1px); 이 mask 위 recall == 1.0, edge drift ≤2.
   - **포함(전 단계)**: alpha(current) ⊆ dilate(finishedAlpha, 1) ∪ propsZoneMask (finishedAlpha = allowlist sarangchae 소켓 crop alpha>8). 새로 추가된 픽셀도 동일.
   - **계보(kit)**: raw 파일 SHA 검사 대신 (a) derived 부품 = 재도출 SHA == parts.json, (b) generated 부품 = ledger approved `kind=part` outputAsset SHA(`allowed_input_digests` 확장), (c) 합성 레이어 PNG+WebP SHA를 승인 후 `kind=state`로 기록.
   - 나머지 게이트(chroma·socket 밖 0·350KB·decode 오차·RGB WebP 재디코드) 유지. 보고서에 Pillow/libwebp 버전 기록; 결정론 = 같은 manifest + 같은 인코더 빌드, 승격 키는 승인 SHA.
3. **`docs/assets/hanok_a1_kit/`**: `parts.json`(id·file·sha256·source derived|generated·ledgerRecordId·anchor·bakedPostFx) + `stage_01.json … stage_16.json`.
4. **`tool/hanok_v1_asset_contract.py` + `HANOK_V1_ASSET_PROVENANCE.json` + `SOURCE_REGISTRY.md`**: ledger record `kind: part|state|estateLayer`; `estateStatic` 상한 신설; **allowedModelInputs 추가**(SHA·권리 확인 포함): `sotdaeulmun/haengrangchae/anchae/daecheongmaru/sadang.png`, `rear_garden.png`, `decoration_seoan/jagae_mungap/maehwa.png` — **추가 전 이들을 입력으로 생성 호출 금지**. `hanok_v1_asset_provenance_test` 갱신.
5. **`tool/promote_hanok_a1_states.py`**: 불변. D1 시 expectedFiles는 provenance JSON에서(`11_giwa_roof.webp`).
6. **`tool/derive_estate_building_stages.py`**(신규): 완성 PNG → 기단 crop / 골조(생성 입력·게이트) / 지붕 crop / 완성 → `map/structures/<building>_s1..s4.png`(1536×1152 RGBA, ≤350KB) + rear_garden 3분할 + `sarangchae_props.png`.
7. **Flutter**
   - `a1_hanok_construction_catalog.dart` step 11 rename(id·fileName·grantId·revealAssetId) — 접점 7: catalog, `test/a1_hanok_construction_catalog_test.dart:28`, `test/hanok_v1_asset_provenance_test.dart:113`, `build_hanok_grants.py:44`, `drafts/hanok_grants.json`, `PROVENANCE.json:41`, PR3 handoff. `manifestVersion`은 유지.
   - `hanok_growth.dart`: `HanokGrantKind.furnishing`. `hanok_grant_catalog.dart:176`: `needsVenue = kind==venue || kind==furnishing; if (needsVenue != (venue!=null)) throw`; designSlot 금지는 기존 173-175행.
   - **`hanok_experience_projector.dart:69-72`**: `openedVenues = {sarangbang} ∪ {g.venueSurface | g.kind==venue}` (furnishing의 venueSurface는 인벤토리 대상만). `partitionRoomLayouts` 결과 A1 학습자도 사랑방 active. 테스트의 dormant 예시는 anbang으로.
   - `personal_hanok_catalog.dart`: 건물별 단계 레이어(`grantId`), `sarangchae_props`, overlay/option/계절/돌봄 레이어; C1 계절 선택은 `activeLoadout[ambience]` 없으면 달력 월.
   - **소유 합집합(읽기 전용)**: `RoomLayoutService.addItem/load`에 `Set<String> grantOwnedDecor` 파라미터(또는 ownership provider); furnish 화면은 `projection.earnedGrants.where(kind==furnishing && venueSurface==surface).expand(revealAssetIds)`로 계산해 주입. **`Storage.ownedDecor/earnedStamps`에는 쓰지 않는다**(guard 테스트가 hanok_* 파일에서 토큰 금지). credential은 `HanokCredentialMotif`(별도) + 도장첩 증표 탭 + 사랑방 벽감 credential 레이어. PR5b는 순수 함수+테스트, 실배선은 PR6.
   - 장식 등록: 12 slug `kAvailableDecorations`·`kDecorCategory`·`kDecorScale`·`decorName` + `decorName*` DE/EN 24키; 퀘스트 보상 풀 제외; `decoration_slot_test` 갱신.
   - l10n: 키는 밑줄 없는 camelCase(`hanokGrantTitleA101`…`hanokGrantFactC208`; ARB 2125키 중 밑줄 0개), grant id→getter 매핑 함수 1개; DE/EN 완전 대칭, em/en dash 금지, 복수형 규칙 준수(`arb_l10n_guard`·`l10n_parity`). KO 용어는 `cultural_glossary.json`의 `ko` localization(선택적 grant 필드 `glossaryTermId` 추가, 스키마 optional).
   - `cultural_glossary.json` 24 term 추가 → `cultural_glossary_catalog_test` 15→39; 새 가구 slug의 `decorationSlugs` 연결은 PNG가 들어오는 PR5b에서.
8. **테스트**: kit 결정론(SHA), transient/이전 manifest 연속성, 포함 규칙, kit anchor(완성 소켓 crop PASS; 16-props == base⊕sarangchae 0픽셀), geometry 스냅샷(8구간·폭 12~22), catalog rename, grant furnishing 계약(venueSurface 없음→throw, designSlot→throw), projector openedVenues 기본 사랑방·순서 역전 시 상위 단계 보류, 룸 인벤토리 합집합, guard.

### 6.4 왜 이게 "재검토"의 답인가
| 지금까지 실패 원인 | 새 방식에서 |
|---|---|
| 모델이 기둥을 얇게 다시 그림(recall 0.858) | 기둥은 crop 1회, 이후 픽셀 재사용 → 구조 mask recall 1.0 구성상 보장 |
| 뒷줄을 보이려고 기단을 키우거나 카메라 회전 | 뒷줄은 원근 벡터로 프로그램 복제 |
| 7기둥 vs 8기둥 칸수 불일치 | 기둥 x구간은 완성본 실측(비균등 칸도 그대로) |
| 07 상단 y=40 vs 108 비율 붕괴 | 모든 밴드가 derive 분류값 |
| 체커보드/RGB/외부 URL 산출물 | 부품 단위 검사, 실패해도 부품 1개만 재생성(3~4cr) |
| 스타일 드리프트 | 참조 1장·부품 후처리 1종·전역 다듬기 금지 |
| 크레딧 26+ / 6장 | ≈100cr / 16장 + 무한 재합성 0cr |

---

## 7. 학습 콘텐츠 연결(D6)
- grant reveal 시트: 제목(KO 용어+한자·로마자 / DE / EN) + 사실 1줄(§1.1~1.3 근거만, 독자 문장) + 의례 배지(개토제·모탕고사·입주식·상량식·준공식·입택). ARB 키 `hanokGrantTitle{Lv}{NN}` / `hanokGrantFact{Lv}{NN}`(DE/EN), KO는 glossary `ko`.
- glossary 추가 term(안): 기단·초석·기둥·창방·보·도리·상량식·서까래·추녀·기와·온돌·마루·창호·수장·흙벽·사방탁자·보료·서가·병풍·화로·대청·행랑채·사당·화계 (KO/DE/EN meaning≤140·story≤180, sources = hanokdb/서울포털 https URL).
- 지식카드 SVG 6장은 별도 트랙(후순위).

---

## 8. 실행 순서(구현 PR 분할 — 이 계획 승인 뒤)
| PR | 내용 | 산출/게이트 |
|---|---|---|
| PR4b-1 | `derive_hanok_a1_kit.py` + geometry JSON(Jin 확인) + compose kit 모드(anchor·연속성·포함·계보 규칙) + provenance 필드 + 테스트 | 11·15(픽셀 동일)와 03·04·06(crop+보정) 다섯 장이 **0cr**로 단독 게이트 통과(연속성은 PR4b-2에서 전체 재실행) |
| PR4b-2 | 부품 ≈22개 생성(BBANANA, 부품당 Jin 승인·ledger part) → 나머지 11장 합성 → 17장 대조 시트(인접 diff) → ledger state approved → `promote --apply` → pubspec | `check_personal_hanok_assets.py --require-a1-states` PASS |
| PR5a | grant 초안 재생성(D2·D3·D5·D7, prerequisite 체인), enum `furnishing`, catalog:176, projector openedVenues, l10n 86×2+16, glossary 24(테스트 15→39), catalog 11 rename(D1) | grant/projector/guard 테스트 PASS |
| PR5a′ | provenance allowlist 확장(건물 5·후원·장식 3, SHA·권리) + SOURCE_REGISTRY 갱신 | provenance 테스트 PASS — **이 뒤에만 §5.2/§5.4 생성** |
| PR5b | 사랑방 가구 12(등록·decorName·slot 테스트) + 룸 소유 합집합(순수 함수) + `derive_estate_building_stages` + estate 단계·overlay·option·계절 레이어 카탈로그 + credential motif | 자산 검사기 확장 PASS |
| PR6/7 | 기존 계획대로 진입점·cutover(이 계획 밖) | |

---

## 9. 검증(끝나면 이렇게 확인)
1. `python -m pytest tool/test_compose_hanok_a1_state.py tool/test_hanok_v1_asset_contract.py tool/test_promote_hanok_a1_states.py` + 신규 derive/kit 테스트(결정론·anchor·연속성·포함·계보).
2. `python tool/compose_hanok_a1_state.py --kit-manifest docs/assets/hanok_a1_kit/stage_NN.json --previous-manifest … --previous-layer …` 16회 → 보고서: structural recall 1.0 / drift ≤2 / 포함 위반 0 / socket 밖 0 / ≤350KB / 인코더 버전.
3. 대조 시트: 17 상태 4×5 격자 + 인접 diff 히트맵 → Jin 육안 승인(장마다). 16-props == base⊕sarangchae 자동 검사.
4. `python tool/promote_hanok_a1_states.py`(dry) → `--apply` → `python tool/check_personal_hanok_assets.py --require-a1-states`.
5. `flutter test --no-pub test/a1_hanok_construction_*_test.dart test/hanok_grant_catalog_test.dart test/hanok_experience_projector_test.dart test/hanok_v1_source_guard_test.dart test/decoration_slot_test.dart test/cultural_glossary_catalog_test.dart test/arb_l10n_guard_test.dart test/l10n_parity_test.dart` → 전체 `flutter test` · `flutter analyze --no-pub --fatal-infos`.
6. QA 위젯 `A1HanokConstructionMap`을 `ux_preview_app`에서 0→16 스텝 넘기며 실기기 확인(프로덕션 라우트 미연결 유지).
7. 크레딧: ledger 합계 ≤ 상한, `check_credits`로 잔액 대조. SESSION_LOG 최상단 기록.

## 10. 하지 않는 것
- 대지 전체를 모델로 편집(3안 전부 78~80% 픽셀 변경 탈락 전례) / 단계 그림 통째 생성 / 합성 뒤 전역 후처리·모델 다듬기.
- allowlist에 없는 파일(건물 PNG·후원·장식·비바샘·서울포털·hanokdb 이미지·Jin 화면·`hanok_stages/`·`gye/`·`hanok_compound/`)을 모델 입력이나 crop 소스로 쓰기 — 편입(PR5a′) 전 금지.
- `Storage.ownedDecor/earnedStamps`에 grant 결과 쓰기. 릴리스 원장·런타임 pubspec에 승인 전 자산 넣기. 커밋/푸시(Jin 요청 시에만).
