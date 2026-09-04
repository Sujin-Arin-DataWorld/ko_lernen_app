# 에셋 격차 확정 목록 (R6) — Joy 클립 + 비마스코트

**작성** 2026-08-03 · **대상** `ko_lernen_app` · **선행** `DESIGN_OVERHAUL_PLAN_2026-08-02.md` §5.2("R6에서 우선순위 목록으로 확정")의 그 확정판.
**근거** 코드 소비처 전수 추적(character_clip.dart 역할 함수 + 사용처 grep + scene_asset_resolver.dart + mascot.dart 감정 매핑).

---

## 0. 절대 규칙 (이 문서 전체에 적용)

> ⛔ **호랑이(태고)·까치(조이) 캐릭터 이미지 AI 재생성 무조건 금지.**
> 신규/합성 이미지에 캐릭터가 등장하면 **반드시 아래 기존 에셋 파일을 그대로 배치·합성**한다. 새로 그리지 않는다(온보딩 O-1/O-2의 "별개 렌더 스타일" 드리프트가 바로 이 위반의 결과).
>
> - **캐릭터 캐논 앵커 (2026-08-03 Jin 확정):** 호랑이 = **`mascot/tiger_front.png` + `mascot/tiger_right_stand.png`**(신규 저폴리 정본 — "이 호랑이" 룩이 기준). 까치 = **`mascot/magpie_wave.png` · `magpie_sing.png` · `magpie_encourage.png`** 포즈 참조. 그 외 정지 폴백은 `tiger_neutral`·`magpie_perched` 등(§4 표).
> - 신규 호랑이 클립 재제작(계획 §5.2 bob/thinking)은 **`tiger_front`/`tiger_right_stand`에서 파생** — `tiger_idle` 대신 이 둘이 앵커.
> - 캐릭터 영상 신규분(§2 P0~P4)은 **Jin 캐논 제작 전용** — 세션/AI 생성 대상 아님. 목록은 "목표"이지 "생성 지시"가 아니다.
> - 규격 계약(영상): 순백 #FFFFFF 배경 · 960×960 · 24fps · CRF19 · faststart · **무음** · 전 프레임 픽셀 검수 · multiply 합성이라 **밝은 배경 전용**.

> ✅ **만들지 않는 것 — 다크 한옥 12단계 (`hanok_stages/*_dark`).** 다크모드가 꺼져 있으므로(`themeMode.light` 고정) 순수 낭비. 과거 로그의 "dark 0/12 부채"는 현 스코프에서 **부채 아님**. 제작 금지.

---

## 1. Joy가 실제로 강등되는 지점 (코드 근거 — 확정)

`character_clip.dart`의 역할 함수는 캐릭터별로 클립을 고른다. 까치에 전용 클립이 없으면 idle(perched)·celebrate를 재탕하거나 null → 정지로 떨어진다.

| # | 등장 상황 | 화면(코드) | 호랑이 | Joy 현재 | 심각도 |
|---|---|---|---|---|---|
| J1 | Lernpfad "지금" 노드 | `path_trail.dart:468` | `tiger_walking_front` 전용 바운스 | `magpie_perched` 재탕(정지 대기) | 🔴 최다 노출 |
| J2 | 퀴즈/끝말잇기 "생각 중" | `kkeunmari_screen.dart:438` · `thinkingFor()` | `tiger_thinking` 전용 | `magpie_perched` 재탕 | 🔴 |
| J3 | 캐릭터 선택 무대 인사 | `character_selection_screen.dart:248` | `tiger_roar` 드라마틱 | `magpie_perched` 밋밋 | 🟡 Joy 첫인상 |
| J4 | 신기록/보너스 | `game_reward.dart:166` · `feedbackFor(newBest)` | `tiger_roar` escalation | `magpie_celebrate` 재탕(승급감 없음) | 🟡 |
| J5 | 세션 완료 | `review_session_screen.dart:243` · `sessionCompleteFor()` | `tiger_stretch` 전용 기지개 | `magpie_celebrate` 재탕 | 🟢 |
| J6 | 프로필 초상 다양성 | `profile_screen.dart:281` | 5 포즈 로테이션 | 3 포즈뿐 | 🟢 |
| J7 | "thinking" 정지 폴백 | `mascot.dart:187` | `tiger_thinking` | `magpie_encourage` 의미 재탕 | 🟢 정지층 |

**정지 PNG 층은 손대지 않는다.** 까치 정지 10 / 호랑이 9 — 까치가 오히려 앞선다(`mascot.dart` 감정 매핑에 전부 배선, colored-circle 폴백 0). 격차는 **영상(클립) 층에만** 있다.

---

## 2. 만들 Joy 영상 목록 — 확정 우선순위 (⛔ Jin 캐논 제작 전용, AI 재생성 금지)

각 항목: **상황 → 무엇을 → 왜 → 현재 대체**. 전부 §0 영상 규격 계약 준수. 캐논 앵커 = `magpie_perched/wingup/wingdown` 계열(까치 정본, BIBLE §2).

| 우선 | 파일(제안명) | 상황 | 무엇을(동작) | 왜 | 현재 대체 |
|---|---|---|---|---|---|
| **P0** | `magpie_bob.mp4` | Lernpfad "지금" 노드(J1) · 게임 대기 | 앉은 자세에서 **가벼운 상하 홉 + 꼬리 까딱** 루프 | `tiger_walking_front`과 동등. 가장 자주 보는 화면이 지금 정지라 경로가 죽어 보임 | `magpie_perched`(정지 대기) |
| **P1** | `magpie_thinking.mp4` | 퀴즈·끝말잇기 생각 루프(J2) | **고개 갸웃 + 부리 톡톡** 루프 | `tiger_thinking` 대응. "생각한다"는 몸짓 자체가 없음 | `magpie_perched` 재탕 |
| **P2** | `magpie_flourish.mp4` | 캐릭터 선택 무대(J3) | **날개 활짝 펼침 + 꼬리 부채** 1회 원샷 | `tiger_roar`의 드라마에 대응 = **Joy를 고르는 순간의 첫인상**. 지금은 "Joy는 심심하다" 인상 | `magpie_perched` |
| **P3** | `magpie_soar.mp4` | 신기록·레벨업(J4) | **급상승 비행 + 반짝임** 원샷 | 일반 celebrate보다 한 단계 위 = 승급감 | `magpie_celebrate` 재탕 |
| **P4** | 프로필 포즈 +2 | 프로필 초상(J6) | 착지·깃 다듬기 등 2컷 | 로테이션 3→5, 태고와 동률 | 3컷만 로테이션 |

**참조 포즈 (기존 에셋 — 재생성 대신 이 포즈에서 애니메이트, Jin 확정):**
- P0 `magpie_bob` ← `magpie_encourage` (친근한 직립 대기 자세)
- P1 `magpie_thinking` ← `magpie_sing` + `magpie_encourage` (머리·부리 움직임)
- P2 `magpie_flourish` ← `magpie_wave` (날개 든 포즈 = 활짝 펼침의 기준)
- P3 `magpie_soar` ← `magpie_wave` + `wingup/wingdown` (비행 에너지)
- P4 프로필 +2 ← 위 세 포즈 전부

**보류/불필요:** J5(세션 완료)는 `magpie_celebrate` 재탕이 "완료"로 자연스럽게 읽혀 신규 불요. J7은 정지층이라 불요.

### 2-1. 임시 개선 — 신규 에셋 0 (코드만, Jin 영상 도착 전까지)
- **J1/J2**: `path_trail`·`kkeunmari`의 까치 분기를 정지형 `magpie_perched` 클립 대신 **애니메이션 `Mascot(kind: magpie, animate: true)`**(wingup↔wingdown 날갯짓)로 폴백하면, 새 영상 없이도 "얼어붙은" 인상은 완화된다. → 실기기 시각 확인 후 채택(Jin).

### 2-2. ⛔ 신규 호랑이 클립 2개 — 짝 없이 유입됨 (배선 경고)
`assets/video/character/`에 **`tiger_walk_front.mp4` · `tiger_magpie_play.mp4`**가 있으나 `character_clip.dart` 카탈로그에 **미배선**.
- `tiger_walk_front`를 **kind-분기 역할(예: 홈 정면 걷기)에 넣지 말 것** — 짝 `magpie_*_forward`가 없어 Joy는 또 정지로 떨어진다. 넣으려면 까치 대응 영상이 먼저 있어야 함.
- `tiger_magpie_play`는 **둘 다 등장 → 중립**. 홈/마일스톤 공용으로만(캐릭터 선택 무관 화면) 배선 가능.

---

## 3. 비(非)마스코트 이미지 — 확정 목록

### 3-1. 🔴 시나리오 배경 — 5개로 33개를 돌려막는 중 (최대 빈틈, 신규 생성 대상)
`scenes/`에 5셋(cafe·directions·market·restaurant·hotel)뿐. `SceneAssetResolver`(convention→category 폴백)로 **약 28개 시나리오가 그라데이션 폴백**.

- **캐릭터 없음** = §0 재생성 규칙 무관, **자유 생성 가능**(순수 장소 배경).
- **스타일**: BIBLE "Faceted Minhwa(모던 면 분할 민화)" · **무문자** · 중앙 비움(대사가 위에 얹힘, opacity ~0.08로 은은하게 깔림) · 채도 낮게(저투명도에서 읽히게).
- **배선 2택**: ⓐ `scenes/{scenarioId}.png` 파일명 컨벤션 = **코드 0**(한 시나리오 전용) / ⓑ 새 카테고리 키(여러 시나리오 공유) = `Scenario.backdropKey` 매핑 1줄 추가. 공유 장소는 ⓑ 권장.

**신규 배경 — 잠금 해제되는 시나리오 수 순(정확 매핑):**

| 우선 | 새 카테고리 키 | 커버 시나리오(id) | 장면 프롬프트 핵심 |
|---|---|---|---|
| 1 | `home` (집/캐주얼·전화) | couple_argument · plans_with_friend · warm_encouragement · complaint_delivery · running_late · postpone_plans · cancel_plans | 한지 창·좌식 방 or 소파 한켠, 창밖 저녁빛. 스마트폰 대화 암시(물체만). 인물 0 |
| 2 | `airport` | airport_arrival(+quest 5) | 인천공항 게이트/입국심사 라인, 안내 픽토그램 실루엣(무문자), 캐리어. 인물 0 |
| 3 | `taxi` | taxi_kakao · taxi_street(+quests) | 택시 뒷좌석 시점 or 거리 정차, 계기판·차창 밖 도심 야경. 인물 0 |
| 4 | `convenience` (편의점/상점) | convenience_store(+quests) · myeongdong_shopping | 편의점 계산대·진열대 or 명동 상점 파사드. 상품 실루엣, 간판 무문자. 인물 0 |
| 5 | `clinic` (병원/약국) | pharmacy_headache · doctor_consultation | 약국 카운터 or 진료실, 약 서랍·진료 의자, 십자 심볼(무문자). 인물 0 |
| 6 | `office` (회사/면접) | business_meeting_intro · job_interview · (complaint 일부) | 회의실 긴 테이블·화이트보드(무문자) or 면접 데스크. 인물 0 |
| 7 | `station` (지하철/KTX) | subway_transfer · (KTX 계열) | 지하철 승강장·환승 통로 or KTX 플랫폼, 노선 스트립(무문자). 인물 0 |

> 6~7종 추가 시 배경 커버리지 5 → 11~12. `home` 하나가 캐주얼 7개를 한 번에 해소하므로 **투자 대비 1위**.
> 각 배경에 선택적 앰비언트 루프 `loops/scene_{key}.mp4`(무음, 미세 모션 — 창밖 빛/사람 실루엣 흐름)를 나중에 붙일 수 있음. 포스터 PNG가 먼저, 루프는 후속.

### 3-2. 🟡 빈/오류 상태 — 대부분 "새 이미지 아님", 기존 에셋 배선 (재생성 규칙 정확 적용)
계획 §8.1 표준: 빈=`SoriEmptyState`(조이) · 오류=`app_error`(태고). **두 위젯 모두 이미 마스코트 폴백 슬롯이 있다** → 새 일러스트를 그리는 게 아니라 **기존 마스코트 PNG를 넘겨 배선**한다.

| 상황(화면) | 상태 | 배선할 기존 에셋(재생성 X) | 신규 이미지? | 상태(2026-09-03) |
|---|---|---|---|---|
| 빈 Lerngruppe (§6.4) | 빈 | `mascot/magpie_perched.png` + 기존 `gye/gye_*.png` 합성(=`gye_hanok` 위젯 재사용) | ❌ 위젯 합성 | 미배선(W-G 몫 — `gye_tab_screen.dart`의 `_IntroEmpty`가 대신 courtyard showcase 아트를 씀, magpie 없음) |
| Meine Wörter 빈 | 빈 | `mascot/magpie_wave.png` | ❌ 배선만 | ✅ `custom_pack_edit_screen.dart:435` |
| Knifflige Wörter 없음("Keine Sorgenkinder") | 빈 | `mascot/magpie_celebrate.png` | ❌ 배선만 | ✅ `hard_words_screen.dart:208` |
| 복습 완료("Alles erledigt!") | 빈 | `mascot/magpie_celebrate.png` | ❌ 배선만 | ✅ `review_hub_screen.dart:172` |
| 빈 퀘스트 | 빈 | `mascot/magpie_encourage.png` | ❌ 배선만 | ✅ `quests_screen.dart:247` |
| 오프라인/오류 전반 | 오류 | `mascot/tiger_front.png`(신규 정본·당당한 직립) or `tiger_neutral.png` | ❌ 배선만 | ✅ `app_error.dart:15`(**기본값 배선** — `kTaegoErrorAsset`) |
| 책장 빈 | 빈 | `book/book_empty_shelf.png` (이미 존재·배선됨) | ✅ 이미 있음 | ✅ 그대로 |

> **갱신 2026-09-03(§COPY-5 J15)**: 위 7행 중 5행(Meine Wörter·Knifflige·복습 완료·빈 퀘스트·오프라인/오류)이 배선 완료됐고, 잔여 1행(빈 Lerngruppe)은 W-G 몫으로 남아 있다. "신규 이미지?" 열은 원문 그대로 "새 이미지 필요 없음"을 뜻한다 — ❌가 미완료를 뜻하지 않는다.

> 결론: **빈/오류는 이미지 제작 과제가 아니라 코드 배선 과제.** 새 배경 장식을 원하면 그때만 신규(저우선). 재생성 규칙과 정확히 부합.

### 3-3. 🟡 온보딩 3장 — 캐논 밖 (Jin 제작 대상, 여기선 상태 확인만)
`onboarding/book_scan.png`(그림 속 영어 UI 7건) · `onboarding/tiger_crystal.png`(다크+청색 크리스탈) · "Dein Hanok wächst"의 painterly `loops/hanok_construction.mp4`. **계획 §5.2가 이미 Jin 제작으로 지정** — 캐릭터 포함이라 §0 규칙상 **Jin 캐논 재제작**(AI 재생성 금지). 이 문서 범위 밖, **미해결로 존치 확인**만.

---

## 4. 사용 가능한 기존 캐릭터 에셋 (재생성 대신 이걸 쓴다)

| 캐릭터 | 정지 PNG (`assets/illustrations/mascot/`) | 영상 (`assets/video/character/`) |
|---|---|---|
| 태고(호랑이) | **front** · **right_stand** (⭐신규 캐논 앵커) · idle · blink · celebrate · neutral · sad · sleepy · smile · surprised · thinking (11) | rise · roar · celebrate_hifive · rest · sitting2 · bob · stretch · thinking · choose · greet_pawflash · walk_front* · magpie_play* (12) |
| 조이(까치) | perched · wingup · wingdown · celebrate · worry · dance · encourage · sing · sleep · wave (10) | flight · celebrate · worry · perched · choose · greet_chirp (6) |

`*` = 카탈로그 미배선(§2-2). 이 표의 파일만 사용, **표 밖의 캐릭터를 새로 그리지 않는다.**

---

## 5. 실행 요약 (우선순위 통합)

1. **[신규 생성 가능·자유] 시나리오 배경 `home` 1장** — 캐주얼 7개 한 번에 해소. 그 다음 `airport`·`taxi`·`convenience`·`clinic`·`office`·`station`.
2. **[코드 배선·이미지 0] 빈/오류 상태** — 기존 마스코트 PNG를 `SoriEmptyState`/`app_error`에 배선(§3-2 표).
3. **[Jin 캐논 제작·AI 금지] Joy 영상 P0 `magpie_bob` → P1 `magpie_thinking` → P2 `magpie_flourish`** — 임시로 애니메이션 Mascot 폴백(§2-1)로 완화 가능.
4. **[하지 않음] 다크 한옥 12단계, 캐릭터 재생성.**

---

## 부록 A — 시나리오 배경 상세 프롬프트 (BIBLE 준거, 캐릭터 없음 → 생성 자유)

> 출처 규칙: `docs/ASSET_GENERATION_BIBLE.md` §1(Style DNA·팔레트·템플릿·마감문장). 아래는 그 §1.5 템플릿을 씬 백드롭용으로 특화한 것.

### A-0. 공통 규격 (7종 전부 동일)

- **규격**: 3:4 세로 **1086×1448 px** (기존 5씬 `cafe/hotel/…`와 픽셀 동일). PNG-24 배경 채움(알파 불필요 — 백드롭이라 뒤가 안 비침).
- **경로**: `assets/illustrations/scenes/{key}.png` · 선택 앰비언트 루프 `assets/video/loops/scene_{key}.mp4`(무음, 후속).
- **배선**: 새 key는 `Scenario.backdropKey` 매핑 1줄 추가(여러 시나리오 공유) **또는** `scenes/{scenarioId}.png` 파일명 컨벤션(코드 0, 단일 시나리오).
- ⛔ **인물·호랑이·까치 등 캐릭터 0. 글자/간판 텍스트 0(무문자).** 순수 장소.
- **대사가 중앙에 얹힌다 → 중앙부는 비우고 저대비.** 전체를 **muted**하게(opacity ~0.08로 깔려서 너무 쨍하면 안 됨).
- 레퍼런스 첨부: 기존 `scenes/cafe.png` + `scenes/hotel.png`(동일 세트 결 유지).

### A-1. 공통 스타일 블록 (모든 씬 프롬프트 끝에 그대로 붙임)

```
Mid-century modernist geometric reduction (Saul Bass, Charley Harper era)
crossed with Korean minhwa folk painting. Confident, premium editorial — NOT
cute, NOT cartoonish.
NO people, NO animals, NO tiger, NO magpie, NO characters of any kind.
NO lettering or signage text (blank signs / blank boards only).
NO outlines on shapes — pure flat angular color planes only.
NO gradients within shapes EXCEPT one soft light/sky gradient.
Subtle hanji paper grain texture overlay across the entire image.
Keep the CENTER calm, uncluttered and slightly lower-contrast (dialogue text
overlays there). Overall MUTED / low-key tones — this sits behind chat at ~8%
opacity, so avoid punchy saturation. Warm-dominant with neutral dark anchors,
avoid sepia wash. Clear silhouette readability at 100px.
Restricted palette (hex): [PER-SCENE LIST BELOW]
Aspect ratio: 3:4 vertical (1086x1448 px). Background-filled PNG.

IMPORTANT: match the geometric faceted style, color palette, paper-grain texture
and overall mood of the attached reference images (cafe.png, hotel.png) exactly.
This must look like part of the same illustrated backdrop set.
```

### A-2. 씬별 레이어 스펙 (우선순위 순 — A-1 스타일 블록과 조합해 사용)

**① `home` — 집/캐주얼·전화** (커버: couple_argument · plans_with_friend · warm_encouragement · complaint_delivery · running_late · postpone_plans · cancel_plans) — **투자 1위(7개 해소)**
> MOOD: 저녁 무렵 한국 집, 아늑하고 안전한 정적.
> - LAYER 1 (상단 ~35%): 창으로 드는 따뜻한 저녁빛. hanji light `#FFFCF2` → sky celadon `#D8E5DC`(허용된 단일 그라데이션). 창 하단 지평선에 은은한 persimmon `#D8742E` glow.
> - LAYER 2 (중경): 낮은 목가구 — 소반/좌탁 warm walnut `#8E6646`(그림자 `#5C4028`), 방석, 낮은 선반. 한지 등 warm ochre `#DFA951` 저투명 glow. 작은 화분 teal `#3D9A7F`.
> - LAYER 3 (전경/바닥): 온돌 바닥 stone gray `#9A938C`+hanji cream `#FAF6EC`. 개켠 담요, 좌탁 위 엎어둔 스마트폰(물체만, UI 없음)과 머그. 단청 점 2군집(`#C24A45`,`#DFA951`,`#3D9A7F`).
> - PALETTE: `#FFFCF2 #FAF6EC #D8E5DC #8E6646 #5C4028 #DFA951 #3D9A7F #9A938C #D8742E #C24A45`

**② `airport` — 공항 도착/입국** (커버: airport_arrival + quest 5)
> MOOD: 넓고 질서정연한 도착장, 여행의 설렘.
> - LAYER 1: 높은 천장 간접광. hanji light `#FFFCF2` → celadon `#D8E5DC`.
> - LAYER 2: 안내 전광판·픽토그램은 **무문자 실루엣**(화살표·사람 심볼 형태만) slate `#2A3340`, 큰 기둥, 유리벽 너머 비행기 실루엣 옅게.
> - LAYER 3: 입국심사 줄 기둥·벨트(기하), 캐리어 실루엣 walnut/slate, 바닥 stone gray `#9A938C`. teal `#3D9A7F` 안내 바(글자 없음). 단청 점 2군집.
> - PALETTE: `#FFFCF2 #FAF6EC #D8E5DC #2A3340 #1A2028 #8E6646 #9A938C #3D9A7F #DFA951`

**③ `taxi` — 택시/거리** (커버: taxi_kakao · taxi_street + quests)
> MOOD: 도심을 지나는 택시 뒷좌석 시점, 이동 중.
> - LAYER 1: 해질녘 하늘. hanji light → celadon, 가로등 persimmon `#D8742E` glow 몇 점.
> - LAYER 2: 차창 프레임 slate `#2A3340`, 대시보드 warm walnut, 미터기 gold `#DFA951` 미세 glow, 룸미러.
> - LAYER 3: 창밖 도심 건물 muted slate/sage(`#5C7060`/`#9BB0A0`), 후미등 persimmon `#D8742E` 점을 2군집, 도로 stone gray `#9A938C`.
> - PALETTE: `#FAF6EC #D8E5DC #2A3340 #1A2028 #8E6646 #9A938C #5C7060 #9BB0A0 #D8742E #DFA951`

**④ `convenience` — 편의점/상점** (커버: convenience_store + quests · myeongdong_shopping)
> MOOD: 밝고 활기차되 차분한 소매점 실내.
> - LAYER 1: 따뜻한 천장광. hanji light `#FFFCF2` → cream `#FAF6EC`, ochre glow.
> - LAYER 2: 진열 선반 기하 grid, 상품 상자를 **작은 단청톤 색면**(muted teal/red/gold/cream)으로 추상화, 카운터 walnut `#8E6646`.
> - LAYER 3: 계산대·냉장 진열장 slate, 간판 바 **무문자**, 바닥 warm stone `#9A938C`. 단청 점 2군집.
> - PALETTE: `#FFFCF2 #FAF6EC #8E6646 #5C4028 #2A3340 #3D9A7F #C24A45 #DFA951 #9A938C`

**⑤ `clinic` — 병원/약국** (커버: pharmacy_headache · doctor_consultation)
> MOOD: 차분하고 안심되는 청결한 진료/약국 공간.
> - LAYER 1: 부드러운 청결광. hanji light `#FFFCF2` → celadon `#D8E5DC`(cool하지만 warm anchor 유지).
> - LAYER 2: 약 서랍장(작은 cream/walnut 사각 grid), 십자 심볼을 **기하 색면**(teal `#3D9A7F` 또는 red `#C24A45`, 글자 없음), 카운터.
> - LAYER 3: 진료 데스크·의자, 화분 teal `#3D9A7F`, 바닥 stone/cream. 전체 gentle·reassuring.
> - PALETTE: `#FFFCF2 #FAF6EC #D8E5DC #8E6646 #5C4028 #3D9A7F #C24A45 #9A938C #DFA951`

**⑥ `office` — 회사/면접** (커버: business_meeting_intro · job_interview · complaint 일부)
> MOOD: 프로페셔널하고 정중한 회의/면접 공간.
> - LAYER 1: 채광창, 밖 도심 옅게. hanji light → celadon.
> - LAYER 2: 긴 회의 테이블 warm walnut `#8E6646`(그림자 `#5C4028`), 의자들, **무문자 화이트보드**(cream 면 + slate 프레임), 기하 벽시계(숫자 없음).
> - LAYER 3: 전경 테이블 모서리, 닫힌 노트북 실루엣(UI 없음), 머그, 노트. 단청 점 최소 1군집.
> - PALETTE: `#FAF6EC #FFFCF2 #D8E5DC #8E6646 #5C4028 #2A3340 #9A938C #3D9A7F #DFA951`

**⑦ `station` — 지하철/KTX** (커버: subway_transfer · KTX 계열)
> MOOD: 이동·대기의 순간, 도착하는 열차.
> - LAYER 1: 역사 천장 광 스트립. hanji light → celadon.
> - LAYER 2: 승강장 기둥 slate `#2A3340`, 벽 노선 스트립을 **색 세그먼트 바**(teal/gold/red, 글자 없음), 스크린도어 기하 grid.
> - LAYER 3: 승강장 바닥 stone gray `#9A938C`, 벤치 walnut, 진입하는 열차 앞머리 faceted 실루엣 slate + 창 persimmon `#D8742E` glow, 방향 화살표 형태.
> - PALETTE: `#FAF6EC #D8E5DC #2A3340 #1A2028 #8E6646 #9A938C #3D9A7F #DFA951 #C24A45 #D8742E`

### A-3. 사용법

1. **A-1 스타일 블록**을 복사 → 맨 위에 `A [3:4] editorial illustration of [해당 씬 MOOD].` 한 줄 + **A-2 해당 씬의 LAYER 1/2/3** 붙이고, `[PER-SCENE LIST]`에 그 씬 PALETTE 채움.
2. 3~5장 변주 생성 → 1장 선택(BIBLE §0-5). 8% opacity로 깔았을 때 중앙 텍스트 가독성 최우선.
3. `home`부터. 그 다음 `airport` → `taxi` → `convenience` → `clinic` → `office` → `station`.
4. 앰비언트 루프(mp4)는 포스터 확정 후 후속 — 창밖 빛/사람 실루엣 미세 흐름, 무음, 규격 계약(§0 계승).
