# 에셋 생성 프롬프트 — 복붙용 (생성기/외주 전달본)

**작성** 2026-08-03 · **대상** `ko_lernen_app`
**소스 정합** `ASSET_GENERATION_BIBLE.md`(화풍·팔레트) · `ASSET_GAP_R6_CONFIRMED_2026-08-03.md`(목록·우선순위) · `ASSET_PRODUCTION_PLAN_2026-08-03.md`(담당·순서·검수) · `DESIGN_OVERHAUL_PLAN_2026-08-02.md` §5·§6.5·§7.4
**용도** 각 블록을 그대로 이미지/영상 생성기 또는 외주에 전달. 영어 프롬프트 = 생성기 입력용.

---

## 0. 상속 규칙 (모든 프롬프트에 적용)

- ⛔ **호랑이(태고)·까치(조이) 캐릭터 AI 재생성 금지.** 캐릭터가 들어가면 **기존 PNG를 합성**하거나(정지), **기존 PNG를 첫 프레임으로 애니메이트**(영상). 다시 그리지 않는다.
- **캐논 앵커** 호랑이 `mascot/tiger_front.png` · `tiger_right_stand.png` / 까치 `mascot/magpie_wave.png` · `magpie_sing.png` · `magpie_encourage.png`.
- **무문자 원칙(§7.4)** 일러스트에 UI/간판/번호판/역명 등 문자 굽지 않기. 예외 = 한글 학습 낱자.
- **온보딩 라이트 통일(§6.5)** 온보딩 자산은 다크 폐기, 라이트 한지 배경.
- ✅ **만들지 않음** 다크 한옥 12단계.
- **영상 규격 계약(§5.4)** 순백 `#FFFFFF` · 960×960 · 24fps · CRF19 · yuv420p · `+faststart` · **무음** · 전 프레임 픽셀 검수. 근사 흰색 = 불합격(multiply 합성 시 회색판).

### 생성 담당 매트릭스

| 파트 | 담당 | 근거 |
|---|---|---|
| A. 시나리오 배경 7 | 세션/AI 생성 자유 | 인물 0 |
| B. Joy 클립 5 | i2v(기존 PNG 애니) | 재생성 아님 — 기존 프레임 사용 |
| C. 온보딩 — 비캐릭터/오브제 파트 | 세션/AI 생성 자유 | 인물 0 |
| C. 온보딩 — 캐릭터 파트 | 기존 PNG 합성 | 재생성 금지 |
| tiger_sleepy·thinking 등 캐논 정지 재제작 | **Jin 전용** | 캐릭터 redraw |

---

## A. 시나리오 배경 7종

- 경로 `assets/illustrations/scenes/{key}.png` · **1086×1448 (3:4)** · 배경 채움 PNG · 선택 루프 `assets/video/loops/scene_{key}.mp4`.
- 레퍼런스 첨부: `scenes/cafe.png` + `scenes/hotel.png`.
- 각 씬 = **[씬 블록] + [공통 스타일 블록]** 두 개를 이어 붙여 생성.

### A-0. 공통 스타일 블록 (모든 씬 끝에 붙임)

```
Mid-century modernist geometric reduction (Saul Bass, Charley Harper era) crossed
with Korean minhwa folk painting. Confident premium editorial — NOT cute.
NO people, NO figures, NO animals, NO characters. NO text / NO signage lettering
(blank signs and boards only). NO outlines — pure flat angular color planes.
NO gradients within shapes EXCEPT one soft sky/light gradient. Subtle hanji paper
grain over the entire image. Keep the CENTER calm, uncluttered and lower-contrast
(dialogue text overlays there). Overall MUTED / low-key (sits behind chat at ~8%
opacity), warm-dominant with neutral dark anchors, no sepia wash. Silhouette clear
at 100px. Aspect ratio 3:4 vertical, 1086x1448 px, background-filled PNG.
IMPORTANT: match the geometric faceted style, palette, paper-grain texture and mood
of the attached reference backdrops (cafe.png, hotel.png) exactly — same set.
```

### A-1. `home` — 집/캐주얼·전화 → `scenes/home.png` (커버: couple_argument·plans_with_friend·warm_encouragement·complaint_delivery·running_late·postpone_plans·cancel_plans)

```
A 3:4 vertical editorial illustration of a cozy Korean home living room at dusk — quiet, safe, calm.
LAYER 1 (top ~35%): warm evening light through a window, hanji light #FFFCF2 fading to sky celadon #D8E5DC (the single allowed gradient), a soft persimmon #D8742E glow low at the window horizon.
LAYER 2 (mid): low wooden furniture — a low soban table warm walnut #8E6646 with #5C4028 shadow facets, a floor cushion, a low shelf; a paper lamp casting a warm ochre #DFA951 low-opacity glow; a small potted plant teal #3D9A7F.
LAYER 3 (foreground/floor): warm ondol floor blending stone gray #9A938C and hanji cream #FAF6EC; a folded blanket, a face-down phone and a mug on the low table (objects only, no screen UI). 2 loose dancheong dot groupings (#C24A45, #DFA951, #3D9A7F).
Palette: #FFFCF2 #FAF6EC #D8E5DC #8E6646 #5C4028 #DFA951 #3D9A7F #9A938C #D8742E #C24A45
```

### A-2. `airport` → `scenes/airport.png` (커버: airport_arrival + quest 5)

```
A 3:4 vertical editorial illustration of a spacious Korean airport arrivals hall — orderly, the quiet excitement of arrival.
LAYER 1 (top ~35%): high ceiling with soft indirect light, hanji light #FFFCF2 fading to sky celadon #D8E5DC; a large glass wall with faint faceted airplane silhouettes far outside.
LAYER 2 (mid): a blank information board and pictogram silhouettes (arrow / person symbols, NO letters) in hanok slate #2A3340, tall pillars warm walnut #8E6646.
LAYER 3 (foreground): immigration queue posts and belts (geometric), a rolling suitcase silhouette in slate/walnut, floor stone gray #9A938C, a teal #3D9A7F guidance bar with no text. 2 loose dancheong dot groupings.
Palette: #FFFCF2 #FAF6EC #D8E5DC #2A3340 #1A2028 #8E6646 #9A938C #3D9A7F #DFA951
```

### A-3. `taxi` → `scenes/taxi.png` (커버: taxi_kakao·taxi_street + quests)

```
A 3:4 vertical editorial illustration from the back seat of a taxi moving through the city at dusk — in transit.
LAYER 1 (top ~35%): evening sky, hanji light #FFFCF2 to sky celadon #D8E5DC, a few soft streetlight persimmon #D8742E glows.
LAYER 2 (mid): the car window frame in hanok slate #2A3340, a warm walnut #8E6646 dashboard, a tiny gold #DFA951 meter glow, a rear-view mirror.
LAYER 3 (foreground/through the window): muted city buildings in mountain sage #5C7060 / pale sage #9BB0A0 and slate; persimmon #D8742E tail-light dots in 2 loose groupings; road stone gray #9A938C.
Palette: #FAF6EC #D8E5DC #2A3340 #1A2028 #8E6646 #9A938C #5C7060 #9BB0A0 #D8742E #DFA951
```

### A-4. `convenience` → `scenes/convenience.png` (커버: convenience_store + quests · myeongdong_shopping)

```
A 3:4 vertical editorial illustration of a Korean convenience store interior — bright, calm, retail.
LAYER 1 (top ~35%): warm ceiling light, hanji light #FFFCF2 to hanji cream #FAF6EC, a soft ochre #DFA951 glow.
LAYER 2 (mid): geometric shelving grids with products abstracted as small muted color planes (teal #3D9A7F / red #C24A45 / gold #DFA951 / cream), a counter in warm walnut #8E6646.
LAYER 3 (foreground): the checkout counter and a chilled-drink cabinet in slate #2A3340, blank signage bars (NO letters), warm floor stone gray #9A938C. 2 loose dancheong dot groupings.
Palette: #FFFCF2 #FAF6EC #8E6646 #5C4028 #2A3340 #3D9A7F #C24A45 #DFA951 #9A938C
```

### A-5. `clinic` → `scenes/clinic.png` (커버: pharmacy_headache · doctor_consultation)

```
A 3:4 vertical editorial illustration of a calm Korean pharmacy / clinic consultation space — clean, reassuring.
LAYER 1 (top ~35%): soft clean light, hanji light #FFFCF2 to sky celadon #D8E5DC, still warm-anchored.
LAYER 2 (mid): a medicine-drawer cabinet as a grid of small cream/walnut squares, a geometric cross symbol in teal #3D9A7F (or red #C24A45) with NO letters, a counter.
LAYER 3 (foreground): a consultation desk and chair, a potted plant teal #3D9A7F, floor in stone gray #9A938C and cream. Gentle, reassuring, uncluttered center.
Palette: #FFFCF2 #FAF6EC #D8E5DC #8E6646 #5C4028 #3D9A7F #C24A45 #9A938C #DFA951
```

### A-6. `office` → `scenes/office.png` (커버: business_meeting_intro · job_interview · complaint 일부)

```
A 3:4 vertical editorial illustration of a professional Korean meeting / interview room — composed, formal.
LAYER 1 (top ~35%): a daylight window with faint city outside, hanji light #FFFCF2 to sky celadon #D8E5DC.
LAYER 2 (mid): a long meeting table in warm walnut #8E6646 (shadow #5C4028), chairs, a BLANK whiteboard (cream panel, slate #2A3340 frame), a geometric wall clock with no numbers.
LAYER 3 (foreground): the near table edge, a closed laptop silhouette (no screen UI), a mug, a notebook. 1 minimal dancheong dot grouping.
Palette: #FAF6EC #FFFCF2 #D8E5DC #8E6646 #5C4028 #2A3340 #9A938C #3D9A7F #DFA951
```

### A-7. `station` → `scenes/station.png` (커버: subway_transfer · KTX 계열)

```
A 3:4 vertical editorial illustration of a Korean subway / KTX platform — the moment of waiting, a train arriving.
LAYER 1 (top ~35%): station ceiling light strips, hanji light #FFFCF2 to sky celadon #D8E5DC.
LAYER 2 (mid): platform pillars in hanok slate #2A3340, a wall route strip as colored segments (teal/gold/red bars, NO letters), platform screen doors as a geometric grid.
LAYER 3 (foreground): platform floor stone gray #9A938C, a walnut bench, an arriving train nose as a faceted slate silhouette with persimmon #D8742E window glow, directional arrow shapes.
Palette: #FAF6EC #D8E5DC #2A3340 #1A2028 #8E6646 #9A938C #3D9A7F #DFA951 #C24A45 #D8742E
```

---

## B. Joy 클립 P0~P4 (이미지→영상, 기존 PNG를 첫 프레임으로 = 재생성 아님)

- 경로 `assets/video/character/magpie_*.mp4`. 각 클립 = **[공통 클립 블록] + [모션 한 줄]** + 지정 첨부 PNG.
- **납품 전 필수:** `python3 tool/clip_normalize.py <in> <out> <w> <h> [--pingpong]` → 960²/24fps/CRF19/faststart/무음. 그다음 `tool/check_clip_matte.py --check`(배경 순백 100%) 게이트 통과 후 배선. 루프(bob·thinking) 이음새 >2배면 `--pingpong`.

### B-0. 공통 클립 블록

```
Image-to-video. Use the ATTACHED image as the first frame and the EXACT character —
do NOT redraw, re-style, recolor, or morph the magpie; keep its faceted look, gat,
proportions and colors identical. Pure white #FFFFFF background must stay pure white
for the entire clip (no gray haze, no shadow spill, no vignette). Camera locked — no
zoom, no pan; the bird stays centered. Gentle, natural avian motion only. Silent — NO
audio track. 1:1 square, 24fps.
```

| 클립 | 루프 | 첨부(첫 프레임) | 모션 |
|---|---|---|---|
| **P0 `magpie_bob.mp4`** | loop ~2s | `mascot/magpie_encourage.png` | `the perched magpie gently bobs — a small vertical body hop with a slight tail flick and an occasional single blink. Subtle, seamless LOOP.` |
| **P1 `magpie_thinking.mp4`** | loop ~2.5s | `mascot/magpie_sing.png` (or encourage) | `the magpie tilts its head slowly side to side and gives one or two small beak taps as if pondering; feathers settle. Loopable "thinking" idle.` |
| **P2 `magpie_flourish.mp4`** | one-shot ~1.5s | `mascot/magpie_wave.png` | `the magpie spreads both wings wide open and fans its long tail in a single proud display, then settles. One-time celebratory reveal, NOT looping.` |
| **P3 `magpie_soar.mp4`** | one-shot ~1.5s | `mascot/magpie_wave.png` (+wingup/down 참고) | `the magpie beats its wings and lifts upward in a quick joyful ascent with a light shimmer of dancheong sparkle. One-time big-win, NOT looping.` |
| **P4 프로필 +2** | loop ~2s each | `mascot/magpie_perched.png` / `magpie_choose` | `quiet portrait idle variants — a soft settle, a slow preen of the chest feathers, a calm look-around. Two different gentle micro-idles.` |

---

## C. 온보딩 자산 (§5.2 · 라이트 한지 · 무문자)

### C-1. book_scan → `onboarding/book_scan.png` (세로 941×1672)

스캔 장면 = 프롬프트 / 캐릭터 = 기존 PNG 합성.

```
A vertical editorial illustration (light hanji) of a hand holding a smartphone that
scans an open Korean book on a warm wooden desk. Faceted Minhwa, mid-century geometric,
premium editorial, NOT cute.
The phone screen shows ONLY a blank scan frame with a few large plain Hangul letter
glyphs (e.g. ㅎ ㅏ ㄴ) as learning material — NO interface words, NO buttons, NO English,
NO lettering anywhere on screen or scene.
LAYER 1 (bg): hanji light #FFFCF2 → cream #FAF6EC (single soft gradient), warm.
LAYER 2: an open book with faceted cream pages #F4E8D0 on a walnut desk #8E6646 (#5C4028 shadow).
LAYER 3 (foreground): a hand + smartphone (slate #2A3340 body) framing the blank scan area,
a soft gold #DFA951 scan-glow line.
NO outlines, subtle hanji grain, muted, NO faces beyond the hand, NO animals.
Palette: #FFFCF2 #FAF6EC #F4E8D0 #8E6646 #5C4028 #2A3340 #DFA951 #9A938C
```
→ 완성 후 기존 `mascot/tiger_front.png`(소형)·`magpie_perched.png`를 여백에 합성. **캐릭터 다시 그리지 말 것.**

### C-2. Dein Hanok wächst (안 A, 캐릭터 없음) → `onboarding/hanok_growing.png` (세로) + 선택 루프

```
A vertical editorial illustration of a Korean hanok courtyard joyfully under construction /
growing. Faceted Minhwa, light hanji, celebratory calm. NOT cute.
LAYER 1 (sky, top 35%): hanji cream #FAF6EC → sky celadon #D8E5DC (single allowed gradient).
LAYER 2 (mid): distant irworobongdo peaks — #9A938C / #9BB0A0 / #5C7060, flat angular silhouettes.
LAYER 3 (foreground): a rising hanok — granite foundation #8B8478, walnut timber frame #8E6646,
a partial curved black-tile roof slate #2A3340 with upturned Korean eaves, a dancheong beam band
(teal #3D9A7F base + red #C24A45 / gold #DFA951 squares).
NO people, NO animals, NO text. 2 loose dancheong dot groupings. NO crane. NO Chinese pagoda roof.
NO outlines, hanji grain, one sky gradient only.
Palette: #FAF6EC #D8E5DC #8B8478 #8E6646 #2A3340 #3D9A7F #C24A45 #DFA951 #9A938C
```
→ (선택) 영상 리메이크: 같은 장면 느린 상량 모션, **960²·24fps·CRF19·+faststart·무음**(§5.4). painterly `loops/hanok_construction.mp4` 대체.

### C-3. tiger_crystal 리메이크 → "스트릭 실드" 부적 (Q4: 부적·단청 황 오브제)

오브제 = 프롬프트(투명 PNG) / 호랑이 = 기존 PNG 합성.

```
A transparent PNG of a Korean protective talisman (부적) reimagined as a faceted dancheong
charm — a vertical amulet / shield form in dancheong GOLD #DFA951 with #C99935 shadow facets,
small red #C24A45 and teal #3D9A7F accents, and a subtle warm protective glow.
Faceted Minhwa, NO outlines, subtle hanji grain, self-shadow at base only, transparent background.
This is a "streak shield" metaphor — solid, reassuring, Korean. NO tiger, NO animal, NO letters.
Aspect 1:1 (1254x1254). Full RGBA transparency.
```
→ 슬라이드(`onboarding/tiger_crystal.png` 대체): 라이트 한지 배경 + 위 부적 + 기존 `mascot/tiger_front.png`를 수호하듯 곁에 배치. **호랑이 재생성 X.** (다크+청색 크리스탈 버전 폐기 → §6.5 라이트 통일.)

### C-4. tiger_sleepy · tiger_thinking (정지 PNG, §5.2 #4)

화풍 이질 → **캐논 재제작 = Jin 전용**. AI 프롬프트 재생성 불가라 제외. 캐논 앵커 `tiger_front`/`tiger_right_stand`에서 Jin 파생.

---

## D. 납품·검수 체크 (BIBLE §6·§8, PRODUCTION_PLAN §5)

1. **팔레트** — 각 블록의 hex만. 캔디/네온 금지.
2. **화풍** — 무윤곽 · 면내 그라데이션 0(하늘/빛 1개 예외) · 한지 그레인 · 여백 · 강조 2군집.
3. **무문자** — 간판·화면·번호판·역명 텍스트 0(한글 학습 낱자만 예외).
4. **배경(씬)** — 8% opacity 뒤에서 중앙 텍스트 가독. 3~5장 변주 → 1장 선택.
5. **투명 오브제(부적 등)** — 진짜 RGBA, 흰 사각/체크무늬/드롭섀도 사각 0.
6. **영상(클립)** — `clip_normalize.py` 변환 + `check_clip_matte.py` 게이트(순백 100%) 통과 후 배선. 규격 계약(§0) 준수.
7. **마스코트 합성** — 캐릭터는 반드시 기존 PNG 배치(재생성 0). 역할맵(§5.3): 승리/초대=조이, 오류/수호=태고.
8. **하지 않음** — 다크 한옥 12단계 · 캐릭터 AI 재생성 · `tiger_walking_front` kind-분기 배선.
