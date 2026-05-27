# Hangul Sori — Asset Prompts (Day 2~5)

> **Day 1 (백드롭 5장) 다음으로 만들 모든 자산 통합 프롬프트.**
> Nano Banana 2 / ChatGPT / DALL-E에 그대로 복붙 가능.
>
> **공통 규칙 (필독):**
> - 모든 prompt 끝에 매번 **참조 이미지 2장** 첨부:
>   - 1st anchor: `assets/illustrations/mascot/tiger_idle.png` (호랑이 톤)
>   - 2nd anchor: 카테고리별로 다름 (각 prompt에 명시)
> - 첫 1장 생성 → anchor로 저장 → 나머지는 그 anchor + 카테고리 reference로 톤 일관성 유지
> - 모든 자산은 [HANGUL_SORI_STYLE_GUIDE.md](../HANGUL_SORI_STYLE_GUIDE.md)의 hex 코드만 사용 (Faceted Minhwa)
> - `assets/illustrations/scenes/`의 백드롭(day1)이 이미 완성되어 있으므로, **백드롭과 같은 hanji grain 강도·면 분할 두께·단청 채도를 유지**할 것
>
> **저장 경로 요약:**
> - Day 2 → `assets/illustrations/empty/*.png` · `assets/illustrations/error/*.png`
> - Day 3 → `assets/illustrations/hanok/*.png` (헤더 6장)
> - Day 4 → `assets/illustrations/mascot/*.png` (투명 배경)
> - Day 5 → `docs/store/feature_graphic.png`

---

# Day 2 — 빈/오류 상태 일러스트 5장

> **사양 공통:** 1024 × 1024 정사각, 중앙 단일 모티프, 주변 hanji 여백 풍부.
> 빈/오류 상태는 사용자가 좌절하지 않도록 **정중하고 따뜻한 톤** 유지.
> 참조 첨부: `mascot/tiger_idle.png` + `mascot/magpie_perched.png` + (1장은 hanok/madang(light).png).

## 2.1 `empty/sleeping_tiger_b2.png` — B2 콘텐츠 잠금

> **사용처:** 시나리오 리스트에서 B2 미해금 시 / B2 카드 잠금 화면
> **무드:** "아직 못 깨워" — 격려하는 잠시 휴식

```
A square 1:1 editorial illustration. A Korean tiger (王 character on
forehead) sleeping curled up on a warm walnut hanok wooden floor
(#8E6646), one paw tucked under chin, slow contented breath. A small
magpie wearing a tiny gat hat (갓) perches on the tiger's tail,
looking curious and patient — not waking him.

Mid-century modernist geometric reduction (Saul Bass, Charley Harper era)
crossed with Korean minhwa folk painting iconography. NOT cute, NOT
chibi — the tiger remains dignified even while sleeping. Confident,
contemporary, premium editorial.

Composition:
- Center: sleeping tiger in burnt orange (#E87830) + rust shadow facet
  (#C25420), angular charcoal stripes (#1A1410), tiger cream belly
  (#F4E8D0), closed eyes as gentle curved lines
- On tiger's tail: small magpie black + white body (#1A1410, #F4E8D0),
  gold-amber beak (#DFA951), tiny gat hat with flat oval brim and
  cylindrical crown
- Background: hanji cream (#FAF6EC) dominant with one soft cream-to-ivory
  gradient on upper area, generous negative space all around

ATMOSPHERIC DETAILS:
- 2 plum blossom petals (pale pink #E8B5BC) falling diagonally in upper
  right quadrant — spring season anchor
- NO other animals, NO text, NO clutter

Style discipline (CRITICAL):
- NO outlines on subjects — pure color planes only
- NO smooth gradients within shapes EXCEPT the background sky wash
- Subtle hanji paper grain texture overlay across entire image
- Restricted palette: tiger orange #E87830, rust #C25420, charcoal
  #1A1410, magpie cream #F4E8D0, walnut floor #8E6646, hanji #FAF6EC,
  dancheong gold #DFA951, plum pink #E8B5BC
- High contrast composition with clear silhouette readability at 200px

Aspect ratio: 1:1 square (1024 × 1024 pixels).

ABSOLUTELY AVOID:
- Cute/chibi tiger (must look like a dignified guardian)
- Text, signage, or speech bubbles
- More than 1 magpie
- Sepia wash or monochromatic tone
- Mixed seasons (commit to spring only — plum, not maple)

This is an empty state illustration for "B2 content is being prepared."
Mood should be reassuring patience, not frustration.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. This must look like part of the same illustrated set.
```

---

## 2.2 `empty/celebrate_complete.png` — 단어장 due 완료

> **사용처:** Vocab 화면, 오늘 due 카드 0개 (모두 학습 완료)
> **무드:** 자랑스럽고 따뜻한 축하

```
A square 1:1 editorial illustration. A Korean tiger (王 character on
forehead) standing proud and upright in three-quarter view, magpie
with gat hat perched on the tiger's shoulder with wings raised in
joyful gesture. Above them: a soft burst of dancheong-colored petals
and small geometric stars in the air.

Mid-century modernist geometric reduction + Korean minhwa folk painting.
The tiger holds confident, dignified joy — not goofy. The magpie is
expressive but not cartoonish.

Composition layered front to back:

LAYER 1 — Background
- Hanji cream (#FAF6EC) field with one very soft pale-cream to ivory
  gradient halo behind the figures (single permitted gradient)
- Generous negative space — figures occupy lower 60% of canvas

LAYER 2 — Dancheong burst (sky decoration)
- 8-12 small geometric flat petals scattered in 2 loose clusters in
  upper third, alternating between dancheong red (#C24A45), gold
  (#DFA951), teal (#3D9A7F), plum pink (#E8B5BC)
- Each petal is angular and faceted — NOT realistic flower shapes
- Sizes vary slightly for organic feel, but rotation is geometric

LAYER 3 — Tiger + magpie figures (center)
- Tiger in burnt orange (#E87830) + rust shadow facet (#C25420),
  angular charcoal stripes (#1A1410), tiger cream belly (#F4E8D0).
  Standing 3/4 turn, chest forward, slight upward tilt of chin
- On tiger's right shoulder: magpie black + white (#1A1410, #F4E8D0),
  gold-amber beak (#DFA951), gat hat, both wings raised in V shape,
  body angled slightly back as if cheering

ATMOSPHERIC DETAILS:
- NO ground line — figures float in hanji negative space
- NO text, NO numerals, NO confetti shapes (only the dancheong petals)
- One very small charcoal seal stamp (#A8332E) tucked into bottom right
  corner with 王 character inside — like a Korean artist signature

Style discipline (CRITICAL):
- NO outlines on subjects — pure color planes only
- NO gradients within shapes EXCEPT background halo
- Subtle hanji paper grain texture overlay
- Restricted palette: tiger orange #E87830, rust #C25420, charcoal
  #1A1410, magpie cream #F4E8D0, hanji #FAF6EC, dancheong red #C24A45,
  gold #DFA951, teal #3D9A7F, plum pink #E8B5BC
- High contrast for thumbnail readability

Aspect ratio: 1:1 square (1024 × 1024 pixels).

ABSOLUTELY AVOID:
- Western confetti shapes (no triangles, ribbons, balloons)
- Speech bubbles, exclamation marks, or text
- More than 1 magpie or any other animal
- Trophy, medal, or Western achievement icons
- Cute/chibi proportions

This is the "you finished everything today" celebration screen. Mood:
quiet pride, not loud party.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. This must look like part of the same illustrated set.
```

---

## 2.3 `empty/study_room_waiting.png` — 통계 첫 진입

> **사용처:** Stats 화면, 학습 기록 0개 (앱 처음 깐 직후)
> **무드:** "이제 시작" — 정돈된 책상이 학습자를 기다림. 캐릭터 없음.

```
A square 1:1 editorial illustration. A still life of a Korean scholar's
desk (서안) seen from a gentle high angle, ready for the first lesson.
No people, no animals — just objects, perfectly arranged, waiting.

Mid-century modernist geometric reduction + Korean minhwa folk painting
iconography. The composition feels like a calm "before" moment — quiet
anticipation, not emptiness.

Composition layered front to back:

LAYER 1 — Background
- Hanji cream (#FAF6EC) wall taking upper two thirds
- One soft sky-to-cream gradient on the upper edge (single permitted)
- Warm walnut wood floor (#8E6646 + #5C4028 shadow facet) in lower
  third, edge slightly tilted in subtle 3/4 perspective

LAYER 2 — Low scholar's desk (서안)
- Centered, cherry wood (#7E5A3D) with darker shadow facets (#5C4028)
  on inner edges and underside
- Flat angular plane top, slight 3/4 isometric tilt
- Two short legs visible

LAYER 3 — Desk objects (clustered slightly off-center)
- One open hanji book (책): two flat ivory pages (#F4E8D0), cloth-tied
  spine in dancheong red (#C24A45), pages blank (NO text or marks)
- One calligraphy brush (붓) laid diagonally: cherry-wood handle
  (#7E5A3D), gold collar (#DFA951), sharp triangular black bristle
  (#1A1410) pointing toward upper right
- One inkstone (벼루): flat dark slate rectangle (#2A3340) with circular
  ink pool depression (slightly darker #1A2028)
- One small celadon teacup (#3D9A7F) with thin saucer, darker teal
  shadow facet for volume, placed to the right
- One small square red seal stamp (#A8332E) tucked beside the book with
  cream 王 character inside

ATMOSPHERIC DETAILS:
- 2 loose clusters of dancheong color dots: one near the brush, one
  near the teacup
- One pale moon-shape suggestion in upper background as flat ivory
  (#F4E8D0 at low contrast) — barely visible, like atmosphere
- NO clock, NO calendar, NO modern objects

Style discipline (CRITICAL):
- NO outlines — pure flat color planes
- NO gradients within shapes EXCEPT the background wall wash
- Subtle hanji paper grain overlay
- Restricted palette: hanji #FAF6EC, ivory #F4E8D0, walnut #8E6646,
  cherry #7E5A3D, slate #2A3340, celadon #3D9A7F, dancheong red
  #A8332E + #C24A45, gold #DFA951, charcoal #1A1410
- High silhouette contrast — desk should read clearly at 200px

Aspect ratio: 1:1 square (1024 × 1024 pixels).

ABSOLUTELY AVOID:
- Any text, numerals, characters on book pages or seal except the
  single 王 inside the seal stamp
- Modern objects (laptops, pens, sticky notes, smartphones)
- People, animals, chibi figures
- Multiple seasons or seasonal motifs (this is timeless still life)

This is the empty state for a stats screen — "your journey starts
here." Mood: respectful anticipation, like an empty practice room
before class begins.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. This must look like part of the same illustrated set.
```

---

## 2.4 `error/offline_lantern.png` — 오프라인 다이얼로그

> **사용처:** Settings 동기화 실패 / 오프라인 모드 안내
> **무드:** 잔잔한 위안 — 어둠 속 작은 빛 하나
> **다크 모드 친화:** 라이트/다크 둘 다에서 자연스럽게 — 배경이 어둡고 등이 따뜻

```
A square 1:1 editorial illustration. A single Korean hanji paper
lantern (한지등) hanging in a dark empty courtyard at night, glowing
warmly from within. The image is mostly dark, but the lantern radiates
a soft amber halo. Quiet, comforting solitude.

Mid-century modernist geometric reduction + Korean minhwa folk painting.
Should feel like a moment of pause, not a warning.

Composition:

LAYER 1 — Sky background (upper 70%)
- Deep night navy (#0A2E3A) at top, transitioning softly to slightly
  warmer deeper-navy (#061F28) below — this is the ONE permitted
  gradient
- 4-6 tiny dot-stars scattered subtly in upper area, pale ivory
  (#F4E8D0 at ~40% opacity)
- One muted indigo crescent moon (#1F2E5C) small, upper right

LAYER 2 — Ground hint (lower 20%)
- Dark earth/stone (#15201A) flat plane at bottom edge, slightly
  textured
- One very faint hanok roof silhouette in distant background as flat
  charcoal (#1F2A2E), barely visible against sky

LAYER 3 — Lantern (center, slightly above middle line)
- Rectangular hanji lantern frame: warm walnut wood structure
  (#8E6646) forming a 3x4 grid of small panes
- Hanji panel paper backing inside the grid: glowing warm gold
  (#DFA951) — bright but flat, not photorealistic glow
- A small dancheong red tassel (#C24A45) hanging from the bottom
- The lantern hangs from a single thin charcoal line going up off
  the top of the canvas (rope)
- Around the lantern: ONE soft radial halo of amber (#DFA951 at low
  opacity) fading outward into the navy sky — second permitted
  gradient EXCEPTION, justifiable as the light glow

ATMOSPHERIC DETAILS:
- 2-3 tiny dancheong dot accents (red, gold) drifting subtly near
  the lantern — like fireflies
- NO people, NO animals
- NO text or numerals

Style discipline (CRITICAL):
- NO outlines on subjects
- Permitted gradients (TWO max, justified): sky atmosphere + lantern
  glow halo
- Subtle hanji paper grain across entire image, even in dark areas
- Restricted palette: deep navy #0A2E3A + #061F28, dark earth #15201A,
  dark slate #1F2A2E, walnut #8E6646, hanji glow #DFA951, charcoal
  #1A1410, indigo moon #1F2E5C, pale star #F4E8D0, dancheong red
  #C24A45

Aspect ratio: 1:1 square (1024 × 1024 pixels).

ABSOLUTELY AVOID:
- WiFi icons, no-signal symbols, cloud-strikethrough
- Photorealistic light rays
- Cartoon stars (must be flat dots)
- Sad faces, frowny mascots
- Bright daylight tones

This is the offline / sync-failed empty state. Mood: a quiet promise
that the light is still on — not a problem, just a pause.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. This must look like part of the same illustrated set.
```

---

## 2.5 `error/lost_magpie.png` — 시나리오 로드 실패

> **사용처:** 시나리오 데이터 로드 실패 시 (네트워크/파싱 오류)
> **무드:** "다시 시도하자" — 까치가 길 잃은 모습, 도움 청하는 톤
> 참조 첨부: `mascot/magpie_perched.png` + `hanok/madang(light).png`

```
A square 1:1 editorial illustration. A single Korean magpie wearing
a tiny gat hat (갓) standing alone in an open field, turning its head
sideways as if looking for the path back. Tilted gat hat slightly
askew, head turned with one alert eye visible. Lost but not panicked.

Mid-century modernist geometric reduction + Korean minhwa folk painting.
The magpie should feel slightly comic in its lost expression but
remain elegant — never cute or chibi.

Composition layered front to back:

LAYER 1 — Sky background (upper 60%)
- Hanji cream (#FAF6EC) with one soft cream-to-pale-celadon
  (#D8E5DC) gradient on upper edge (single permitted)
- One small pale plum-pink cloud scroll shape (#E8B5BC at 50%)
  drifting upper left

LAYER 2 — Distant mountains (middle band)
- 3 overlapping mountain silhouettes receding into distance using
  irworobongdo layering: closest peak in mountain teal (#3D9A7F),
  mid in mountain sage (#5C7060), farthest in pale sage (#9BB0A0)
- All as flat angular triangular forms, no detail

LAYER 3 — Grassy field plane (lower 25%)
- A flat sage-green plane (#5C7060 + #9BB0A0 lighter facet) as the
  ground, gently tilted in subtle 3/4 perspective
- 2-3 short stylized grass tufts as small charcoal angular shapes
  (#1A1410), clustered near the magpie's feet

LAYER 4 — Magpie (center foreground)
- Standing on the ground plane, body in 3/4 turn
- Black body (#1A1410) + white-cream belly patch (#F4E8D0)
- Gold-amber beak (#DFA951) slightly open
- Gat hat with flat oval brim and cylindrical crown, tilted slightly
  to one side (the "askew" detail conveys lost-ness)
- One visible alert eye, gold-amber pupil
- Wings folded but slightly raised on one side, as if mid-step
- Cast shadow under magpie as a soft flat oval in darker sage

ATMOSPHERIC DETAILS:
- 2 plum blossom petals drifting in mid-air to the magpie's right
- NO other animals
- NO text, NO question marks, NO arrows

Style discipline (CRITICAL):
- NO outlines on subjects
- NO gradients within shapes EXCEPT the sky background
- Subtle hanji paper grain overlay
- Restricted palette: hanji #FAF6EC, sky celadon #D8E5DC, mountain
  teal #3D9A7F, sage #5C7060, pale sage #9BB0A0, charcoal #1A1410,
  cream #F4E8D0, gold #DFA951, plum pink #E8B5BC
- High silhouette contrast — magpie must read at 200px

Aspect ratio: 1:1 square (1024 × 1024 pixels).

ABSOLUTELY AVOID:
- Tear drops, cry faces, sweat drops (anime tropes)
- Question marks or exclamation marks
- Compass, map, or GPS icons
- Multiple magpies
- Tiger (this is magpie-only)
- Cute/chibi proportions

This is a scenario load failure state. The magpie is the messenger
who couldn't find the message. Mood: gently apologetic, inviting
the user to tap retry.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. This must look like part of the same illustrated set.
```

---

# Day 3 — 헤더 배너 6장

> **사양 공통:** 1888 × 560 (10:3 와이드), 화면 상단 HanokHeader 슬롯.
> 좌우 대칭이 아닌 **의도된 비대칭** (one side dominant) 권장 — 모바일에서 cropping에 안전.
> 참조 첨부: `assets/illustrations/scenes/cafe.png` (Day 1 anchor) + `hanok/madang(light).png`.

## 3.1 `hanok/scholar_room.png` — Settings 헤더

> **사용처:** SettingsScreen 상단
> **무드:** 한 학자가 잠시 자리를 비운 사랑채. 정돈, 차분, "당신의 설정 공간."

```
A wide 10:3 horizontal editorial illustration of a quiet Korean
hanok scholar's room (사랑채) interior, seen from the front. No
people — just a beautifully arranged study, waiting.

Mid-century modernist geometric reduction + Korean minhwa folk painting.
Premium editorial calm.

Composition layered front to back, wide horizontal frame:

LAYER 1 — Back wall (full width)
- Hanji cream wall (#FAF6EC) covering upper 60%
- One soft cream-to-ivory atmospheric gradient on the wall (single
  permitted gradient)
- A pair of warm walnut wooden ceiling beams (#7E5A3D) running
  horizontally near the top edge, with darker shadow facet (#5C4028)
  on the underside

LAYER 2 — Mid ground (running across)
- LEFT THIRD: a tall hanji-paper book shelf — 4-5 small stacked
  hanji books (책) bound with cloth ties, alternating spines in
  dancheong red (#C24A45), gold (#DFA951), and ivory (#F4E8D0)
- CENTER THIRD: a low scholar's desk (서안) in cherry wood (#7E5A3D),
  with one open hanji book (blank pages), a calligraphy brush laid
  diagonally, a small inkstone (#2A3340), and a tiny red seal stamp
  (#A8332E) with 王 character
- RIGHT THIRD: a paper lattice door (창호지문) in ivory cream
  (#FFFCF2) with walnut frame (#7E5A3D) creating a grid pattern,
  one small plum branch (charcoal #1A1410 stem with 3-4 pale pink
  petals #E8B5BC) silhouetted against it

LAYER 3 — Foreground floor
- Warm walnut floor plane (#8E6646 + #5C4028 shadow facet) covering
  lower 25% in subtle 3/4 perspective

ATMOSPHERIC DETAILS:
- 2 loose clusters of dancheong color dots: one near the books, one
  near the brush
- One small celadon teacup (#3D9A7F) on the desk
- NO people, NO animals
- NO text on book spines or seal except the single 王

Style discipline (CRITICAL):
- NO outlines on subjects
- NO gradients within shapes EXCEPT wall background
- Subtle hanji paper grain across entire image
- Restricted palette: hanji #FAF6EC + #F4E8D0 + #FFFCF2, walnut
  #8E6646, cherry #7E5A3D, walnut shadow #5C4028, dancheong red
  #C24A45 + #A8332E, gold #DFA951, charcoal #1A1410, celadon
  #3D9A7F, slate #2A3340, plum pink #E8B5BC
- Wide composition: read clearly from edge to edge, no element
  exceeds 30% of frame width

Aspect ratio: 10:3 horizontal wide (1888 × 560 pixels).

ABSOLUTELY AVOID:
- Modern objects (laptop, lamp with cord, keyboard)
- Text on book covers or paper
- People or animals
- Symmetrical composition (must feel like a real room, asymmetric)
- Western bookshelf or library aesthetic

This is the Settings screen header — implies "your study, your
controls." Mood: respectful calm.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. This must look like part of the same illustrated set.
```

---

## 3.2 `hanok/achievements.png` — Stats 헤더

> **사용처:** StatsScreen 상단
> **무드:** 성취 인증. 호랑이가 처마 아래에서 늠름하게 정면 응시, 까치가 어깨에 있음.

```
A wide 10:3 horizontal editorial illustration. A Korean tiger
standing in stately front-facing pose under the curved eaves of
a hanok roof, with a small magpie perched on his shoulder. Above
their heads, a dancheong band stretches across the eaves with small
geometric stars or chrysanthemum motifs indicating achievement.
Distant mountain silhouettes behind. The atmosphere is one of
quiet honor.

Mid-century modernist geometric reduction + Korean minhwa folk painting.
Tiger must be dignified guardian energy — not cute, not chibi.

Composition layered front to back, wide horizontal:

LAYER 1 — Sky and distant mountains (upper 55%)
- Hanji cream sky (#FAF6EC) at top with one soft pale-celadon
  (#D8E5DC) gradient on the upper edge (single permitted)
- 3 distant mountain silhouettes spanning the width, irworobongdo
  receding layers: closest in mountain teal (#3D9A7F), mid in sage
  (#5C7060), farthest in pale sage (#9BB0A0)

LAYER 2 — Hanok eaves (upper-middle band, dominant horizontal)
- Curved tile roof (기와지붕) with upturned eave horns (처마끝) on
  both far left and far right
- Dark slate-charcoal primary (#2A3340) with deeper shadow facet
  (#1A2028) on the underside
- Across the eave underside: a dancheong band of alternating
  geometric squares — teal (#3D9A7F) base with small red (#C24A45),
  gold (#DFA951), and ivory (#F4E8D0) squares; inside several squares
  small lotus or chrysanthemum motifs
- Row of small rafter ends (서까래) — warm walnut rectangles
  (#7E5A3D) following the eave curve like dark teeth

LAYER 3 — Tiger + magpie (center, slightly lower-middle)
- Tiger standing 3/4 frontal turn, dominant burnt orange (#E87830)
  + rust shadow facet (#C25420), angular charcoal stripes (#1A1410),
  tiger cream belly (#F4E8D0), 王 character on forehead, sharp
  almond-shaped amber-gold eyes (#DFA951), confident gaze straight
  at viewer
- Small magpie on tiger's right shoulder: black body (#1A1410),
  white belly (#F4E8D0), gold-amber beak (#DFA951), gat hat with
  flat oval brim and cylindrical crown
- Above tiger's head, in the dancheong band area: 3 small flat
  star-petal shapes in dancheong gold (#DFA951) — these are the
  "achievement" markers

LAYER 4 — Ground / stone base (lower 12%)
- Stone gray foundation plane (#8B8478) at the bottom edge of the
  frame

ATMOSPHERIC DETAILS:
- 2 loose clusters of dancheong color dots in the upper sky area
- NO text, NO numbers
- NO trophy, medal, or modern achievement icons

Style discipline (CRITICAL):
- NO outlines on subjects
- NO gradients within shapes EXCEPT sky background
- Subtle hanji paper grain overlay
- Restricted palette: tiger orange #E87830, rust #C25420, charcoal
  #1A1410, cream #F4E8D0, hanji #FAF6EC, sky celadon #D8E5DC,
  mountain teal #3D9A7F, sage #5C7060 + #9BB0A0, slate #2A3340 +
  #1A2028, walnut #7E5A3D, gold #DFA951, dancheong red #C24A45,
  stone gray #8B8478
- Wide composition: tiger is hero, but should not exceed 35% of
  frame width — eaves and mountains share the space

Aspect ratio: 10:3 horizontal wide (1888 × 560 pixels).

ABSOLUTELY AVOID:
- Cute/chibi tiger
- Tiger in profile or running pose (must be frontal, stately)
- Trophies, medals, ribbons, Western awards
- Text or numerals
- Multiple magpies or other animals
- Cartoon stars (must be flat geometric petals)

This is the Stats screen header — implies "your honor wall." Mood:
quiet pride, ceremonial calm.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. This must look like part of the same illustrated set.
```

---

## 3.3 `hanok/study_classroom.png` — Vocab 헤더

> **사용처:** VocabScreen 상단 (현재 study.png 사용 중 → 자동 교체)
> **무드:** 서당(전통 학당) 분위기. 여러 학생이 앉았던 자리. 사람 없음.

```
A wide 10:3 horizontal editorial illustration of a traditional Korean
seodang (서당) classroom interior — three low scholar's desks (서안)
arranged in a row across the wide frame, each with a hanji book
and brush, ready for students. No people — just the arrangement,
quietly inviting.

Mid-century modernist geometric reduction + Korean minhwa folk painting.

Composition layered front to back, wide horizontal:

LAYER 1 — Back wall (upper 55%)
- Hanji cream wall (#FAF6EC) with one soft pale ivory atmospheric
  gradient (single permitted) on the upper edge
- One hanging scroll (족자) centered on the wall: thin walnut frame
  (#7E5A3D) at top and bottom, ivory paper field (#F4E8D0), and an
  abstract dark charcoal angular composition inside (#1A1410) —
  NOT actual calligraphy, just geometric ink shapes suggesting a
  brushed character
- A single small red seal stamp shape (#A8332E) in the lower-right
  corner of the scroll

LAYER 2 — Ceiling beam (across the top)
- One warm walnut wood beam (#7E5A3D) running horizontally just
  below the very top, with darker shadow facet (#5C4028) underneath

LAYER 3 — Three scholar's desks (mid-foreground, in a row)
- Three identical low desks (서안) in cherry wood (#7E5A3D) with
  shadow facets (#5C4028) on the inner edges, placed evenly across
  the lower-middle band of the frame
- Each desk has on top: one open hanji book (ivory pages #F4E8D0,
  cloth-tied spine in alternating dancheong colors — leftmost
  red #C24A45, center gold #DFA951, rightmost teal #3D9A7F),
  and one calligraphy brush laid diagonally (cherry wood handle
  #7E5A3D, gold collar #DFA951, sharp triangular black bristle
  #1A1410)
- The desks should not be perfectly aligned — subtle variation in
  angle of brushes for organic feel

LAYER 4 — Floor (lower 25%)
- Warm walnut wooden floor (#8E6646) with darker shadow facet
  (#5C4028) showing the floorboard pattern as 2-3 parallel lines

ATMOSPHERIC DETAILS:
- 2 loose clusters of dancheong color dots near the scroll and near
  the center desk
- One tiny celadon teacup (#3D9A7F) on the right desk
- NO people, NO animals
- NO text on book pages, scroll, or seal

Style discipline (CRITICAL):
- NO outlines
- NO gradients within shapes EXCEPT wall background
- Subtle hanji paper grain across image
- Restricted palette: hanji #FAF6EC + #F4E8D0, walnut #8E6646 +
  #7E5A3D + #5C4028, cherry #7E5A3D, dancheong red #C24A45 +
  #A8332E, gold #DFA951, teal #3D9A7F, charcoal #1A1410
- Wide composition: three desks form a horizontal rhythm

Aspect ratio: 10:3 horizontal wide (1888 × 560 pixels).

ABSOLUTELY AVOID:
- Modern classroom elements (chalkboard, chairs, posters)
- Actual readable Hangul or Hanja text anywhere
- People, students, teacher
- Perfectly symmetric arrangement (must feel organic)
- Western library or schoolroom aesthetic

This is the Vocab screen header — implies "the classroom is open,
choose your seat." Mood: quiet invitation.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. This must look like part of the same illustrated set.
```

---

## 3.4 `hanok/study_scholar.png` — Grammar 헤더

> **사용처:** GrammarScreen 상단
> **무드:** 한 학자의 개인 책상 클로즈업. 깊이 공부하는 자리. 사람 없음.

```
A wide 10:3 horizontal editorial illustration. A close-up overhead-
angled view of a single Korean scholar's desk (서안), seen from a
gentle 30-degree top-down perspective, filling most of the wide
frame. No people — just the open book and tools, captured as if
the scholar just stepped away mid-thought.

Mid-century modernist geometric reduction + Korean minhwa folk painting.
Intimate, focused, premium editorial.

Composition layered front to back, wide horizontal:

LAYER 1 — Background surface (full frame)
- Warm walnut wood desktop (#8E6646 with #5C4028 shadow facet for
  wood grain hint) covering the entire frame as the surface plane
- One very soft pale-cream atmospheric wash (#F4E8D0 at low opacity)
  in upper-left corner suggesting window light (single permitted
  gradient)

LAYER 2 — Open hanji book (LEFT 55% of frame)
- One large open hanji book lying flat: two ivory pages (#F4E8D0)
  spread out, cloth-tied spine in dancheong red (#C24A45) running
  vertically in the center
- Pages are BLANK — no text or markings, just clean ivory planes
- Slight curve at the spine to suggest paper thickness

LAYER 3 — Tools cluster (RIGHT 35% of frame)
- One calligraphy brush (붓) laid diagonally on the desk: cherry wood
  handle (#7E5A3D), gold collar (#DFA951), sharp triangular black
  bristle (#1A1410) pointing toward upper right, tip resting on
  the inkstone
- One inkstone (벼루): flat dark slate rectangle (#2A3340) with a
  circular ink pool depression (slightly darker #1A2028), placed to
  the right of the book
- One ink stick (먹): long hexagonal black stick (#1A1410) with a
  small gold cap (#DFA951), laid beside the inkstone
- One small red seal stamp (#A8332E) with cream 王 character inside,
  placed beside the ink stick
- One small celadon teacup (#3D9A7F) with thin saucer and darker
  shadow facet, placed near the upper-right corner

LAYER 4 — Atmospheric accents
- 2 loose clusters of dancheong dots: one near the brush tip, one
  near the teacup
- One small plum blossom petal (#E8B5BC) drifting onto the book page
- NO people, NO animals

Style discipline (CRITICAL):
- NO outlines on objects
- NO gradients within shapes EXCEPT background wash
- Subtle hanji paper grain across the image, including on book pages
- Restricted palette: walnut #8E6646 + #5C4028, ivory #F4E8D0,
  cherry #7E5A3D, slate #2A3340 + #1A2028, charcoal #1A1410, gold
  #DFA951, dancheong red #C24A45 + #A8332E, celadon #3D9A7F, plum
  pink #E8B5BC
- Wide composition: book dominates left, tools cluster right,
  negative space on top edge

Aspect ratio: 10:3 horizontal wide (1888 × 560 pixels).

ABSOLUTELY AVOID:
- Text on book pages or scroll (only the single 王 inside the seal)
- Modern writing tools (pens, pencils, markers)
- People, hands, animals
- Western desk objects (notebook, ruler, calculator)

This is the Grammar screen header — implies "sit down and study
deeply." Mood: intimate concentration.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. This must look like part of the same illustrated set.
```

---

## 3.5 `hanok/listening_hero.png` — /listening 헤더

> **사용처:** ListeningScreen 상단
> **무드:** 한옥 마루 끝에 풍경(風磬, 바람 종)이 매달려 있고 까치가 귀 기울임.

```
A wide 10:3 horizontal editorial illustration. The edge of a Korean
hanok porch (마루) on the RIGHT third of the frame, with a single
bronze wind chime (풍경) hanging from the eave, slightly swayed by
breeze. On the porch beam beside the chime, a small magpie wearing
a gat hat tilts its head as if listening to the sound. Beyond the
porch on the LEFT two-thirds: distant sage mountains and a soft
celadon sky.

Mid-century modernist geometric reduction + Korean minhwa folk painting.
The image must convey sound visually — through subtle motion lines
and the magpie's listening posture.

Composition layered front to back, wide horizontal:

LAYER 1 — Sky (upper 55%)
- Pale celadon sky (#D8E5DC) at top with one soft cream-to-celadon
  gradient (single permitted)

LAYER 2 — Distant mountains (middle band)
- 3 overlapping silhouettes: closest in mountain teal (#3D9A7F),
  mid in sage (#5C7060), farthest in pale sage (#9BB0A0)
- All flat angular triangles, asymmetric, mostly LEFT half of frame

LAYER 3 — Hanok eave + porch (RIGHT third)
- Curved tile roof eave (기와지붕) coming in from the right edge,
  upturned horn (처마끝), dark slate-charcoal primary (#2A3340)
  with darker shadow facet (#1A2028)
- Below the eave: a dancheong band — teal (#3D9A7F) base with
  alternating red (#C24A45) and gold (#DFA951) small squares
- Warm walnut wooden porch beam (#8E6646 + #5C4028 shadow facet)
  running horizontally as the porch surface, ending mid-frame

LAYER 4 — Wind chime (풍경) (focal point, hanging from eave)
- Bronze bell (#A8732C or similar warm bronze tone derived from
  gold #DFA951 + darker facet) shaped like a small inverted lotus
  bud, hanging from a thin charcoal line attached to the eave
- A fish-shaped pendant (#7E5A3D walnut tone) suspended below the
  bell with a thin tassel
- 2-3 subtle curved motion lines around the chime (very thin
  ivory #F4E8D0 strokes, almost like brush flicks) suggesting
  gentle sway — these are the ONLY line elements in the image

LAYER 5 — Magpie listening (on porch beam, beside chime)
- Small magpie body in 3/4 turn, head tilted upward and to the
  right toward the chime, one alert eye visible
- Black body (#1A1410), white belly (#F4E8D0), gold-amber beak
  (#DFA951), gat hat with flat brim and crown

ATMOSPHERIC DETAILS:
- 2 loose clusters of dancheong dots: one near the dancheong band,
  one in the sky
- NO other animals
- NO text or notation
- NO sound waves drawn as visible rings

Style discipline (CRITICAL):
- NO outlines on subjects (the motion lines are an intentional
  exception — flat brush strokes, not outlines on objects)
- NO gradients within shapes EXCEPT sky
- Subtle hanji paper grain across image
- Restricted palette: sky celadon #D8E5DC, mountain teal #3D9A7F,
  sage #5C7060 + #9BB0A0, slate #2A3340 + #1A2028, walnut #8E6646
  + #7E5A3D + #5C4028, dancheong red #C24A45, gold #DFA951, bronze
  (warm gold variant), charcoal #1A1410, magpie cream #F4E8D0
- Wide composition: porch/chime/magpie cluster on right (35-40%),
  sky and mountains stretch left

Aspect ratio: 10:3 horizontal wide (1888 × 560 pixels).

ABSOLUTELY AVOID:
- Western musical notation, treble clefs, headphones
- Visible sound waves as circles or rings
- Speech bubbles
- Multiple magpies, tigers
- Text

This is the Listening mode header — implies "lean in and hear."
Mood: contemplative, gentle attention.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. This must look like part of the same illustrated set.
```

---

## 3.6 `hanok/kkeunmari_hero.png` — 끝말잇기 헤더

> **사용처:** KkeunmariScreen 상단
> **무드:** 호랑이와 까치가 마루에 마주 앉아 한지 두루마리를 사이에 두고 단어를 잇는 장면.

```
A wide 10:3 horizontal editorial illustration. A Korean tiger sits
on the LEFT side of a wide hanok wooden floor (마루), facing right.
A magpie wearing a gat hat stands on the RIGHT side, facing left.
Between them lies a long unrolled hanji paper scroll, on which a
row of small dancheong-colored dots runs horizontally — this is the
visual metaphor for a word chain. The tiger and magpie are mid-
exchange, dignified, like calligraphers playing a game.

Mid-century modernist geometric reduction + Korean minhwa folk painting.
Tiger remains dignified guardian energy. Magpie stays elegant.

Composition layered front to back, wide horizontal:

LAYER 1 — Background (upper 60%)
- Hanji cream wall (#FAF6EC) at top
- One soft cream-to-ivory atmospheric gradient on the upper edge
  (single permitted)
- Two warm walnut wood beams (#7E5A3D) running horizontally near
  the top, with shadow facet (#5C4028) underneath

LAYER 2 — Mid ground decoration (sky area, sparse)
- 2-3 small dancheong dot accents in the upper sky area
- ONE small plum branch (charcoal stem #1A1410 with 2 pale pink
  petals #E8B5BC) silhouetted in the upper LEFT corner

LAYER 3 — Hanok wooden floor (lower 30%)
- Warm walnut wood plank floor (#8E6646 + #5C4028 shadow facet for
  plank lines, 3-4 parallel horizontal lines visible) covering
  the lower band

LAYER 4 — Unrolled hanji scroll (across the floor, center band)
- A long horizontal hanji paper scroll (ivory #F4E8D0) unrolled
  across the floor between the tiger and magpie, with the two ends
  curling slightly upward at left and right
- On the scroll: a horizontal row of 5-7 small dancheong dots
  alternating in colors — red (#C24A45), gold (#DFA951), teal
  (#3D9A7F), forming a chain visual metaphor
- Each dot is angular and faceted, not perfectly circular
- Connecting the dots: subtle thin charcoal lines (#1A1410) like
  a brushed connector — VERY subtle, almost suggested

LAYER 5 — Tiger (LEFT side, sitting in 3/4 turn facing right)
- Tiger sitting on his haunches, body in 3/4 view, head turned
  toward the magpie/scroll, chin slightly lowered as if focused
- Burnt orange (#E87830) + rust shadow facet (#C25420), angular
  charcoal stripes (#1A1410), tiger cream belly (#F4E8D0), 王
  character on forehead, sharp amber-gold eyes (#DFA951)

LAYER 6 — Magpie (RIGHT side, standing in 3/4 turn facing left)
- Standing tall on the floor edge, body in 3/4 turn facing the
  tiger and scroll, head slightly tilted
- Black body (#1A1410), white belly (#F4E8D0), gold-amber beak
  (#DFA951), gat hat
- Smaller in scale than the tiger (about 30% of tiger's height)

ATMOSPHERIC DETAILS:
- The scroll, tiger, and magpie roughly form a horizontal triangle
  pointing center, with the chain of dots as the visual focal line
- NO text or Hangul on the scroll
- NO other animals
- The mood is playful but respectful — like two old friends

Style discipline (CRITICAL):
- NO outlines on subjects
- NO gradients within shapes EXCEPT background wash
- Subtle hanji paper grain across image
- Restricted palette: hanji #FAF6EC + #F4E8D0, walnut #8E6646 +
  #7E5A3D + #5C4028, tiger orange #E87830 + #C25420, charcoal
  #1A1410, cream #F4E8D0, gold #DFA951, dancheong red #C24A45,
  teal #3D9A7F, plum pink #E8B5BC
- Wide composition: tiger occupies LEFT 30%, magpie RIGHT 15%,
  scroll fills CENTER 50%

Aspect ratio: 10:3 horizontal wide (1888 × 560 pixels).

ABSOLUTELY AVOID:
- Tiger and magpie facing the viewer (must face each other)
- Speech bubbles, thought bubbles, comic effects
- Hangul or any text on scroll
- Multiple tigers, multiple magpies
- Tiger looking aggressive (should look engaged, calm)
- Western board game elements (dice, pieces, cards)

This is the word-chain (끝말잇기) game screen header — implies
"a calligraphy game between friends." Mood: focused play.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. This must look like part of the same illustrated set.
```

---

# Day 4 — 마스코트 추가 포즈 3장

> **사양 공통:** 1024 × 1024 정사각, **투명 배경 (PNG-32)**, 캐릭터 단독.
> 참조 첨부: `mascot/tiger_idle.png` + `mascot/tiger_celebrate.png` (호랑이용) / `mascot/magpie_perched.png` + `mascot/magpie_celebrate.png` (까치용).
> 기존 mascot/ 시리즈와 **사이즈·구도·외곽선·색감 100% 동일**해야 emotion 교차 시 어색하지 않음.

## 4.1 `mascot/tiger_thinking.png` — 호랑이 생각 중

> **사용처:** Chosung 라운드 <50% 정확도 / 시나리오 NPC "minsu" 사고 중

```
A square 1:1 character mascot illustration with TRANSPARENT BACKGROUND.
A Korean tiger seen from the front in 3/4 view, sitting on his
haunches, with his RIGHT front paw raised and resting under his
chin in a thoughtful "hmm" pose. Eyes looking slightly up and to
the side, brow gently furrowed in concentration but not frowning.
Dignified, contemplative — a wise tiger pondering.

Mid-century modernist geometric reduction + Korean minhwa folk painting.
MUST match the exact proportions, scale, line weight, color palette,
and head position of the reference tiger_idle.png and tiger_celebrate.png
so this pose drops into the same mascot rotation seamlessly.

Composition (character only — NO background):
- Tiger body in burnt orange (#E87830) primary plane + rust shadow
  facet (#C25420) on the side of body, belly, and inner legs
- Angular charcoal stripes (#1A1410) on body, head, and tail —
  same pattern density as tiger_idle reference
- Tiger cream (#F4E8D0) belly, inner ears, chin, and around mouth
- 王 character on forehead in solid charcoal (#1A1410), centered,
  same size as in reference
- Sharp almond-shaped amber-gold eyes (#DFA951), looking up-and-
  to-the-right (the contemplative gaze)
- Right front paw raised, pads visible (#F4E8D0), paw tucked
  loosely under the chin — NOT pressed hard, just resting

ATMOSPHERIC DETAILS:
- NO ground line, NO shadow underneath
- NO thought bubble, NO question marks
- NO speech indicators
- Transparent PNG-32 background — alpha channel only behind the
  character

Style discipline (CRITICAL — must match mascot set):
- NO outlines on the tiger — pure flat color planes only
- NO smooth gradients within shapes
- Subtle hanji paper grain texture overlay applied ONLY to the
  character (not the transparent area)
- Restricted palette: tiger orange #E87830, rust #C25420, charcoal
  #1A1410, cream #F4E8D0, gold #DFA951
- Same head-to-body ratio, same canvas occupancy (~80% of frame)
  as tiger_idle.png reference

Aspect ratio: 1:1 square (1024 × 1024 pixels), transparent PNG-32.

ABSOLUTELY AVOID:
- Chibi or cute proportions (must match reference exactly)
- Thought bubble, question mark, exclamation
- Background of any kind (must be transparent)
- Outline strokes
- Eyes looking at viewer (must look up-and-to-side for "thinking")
- Both paws on the ground (right paw must be raised at chin)

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, scale, and proportions of the attached reference
mascot images EXACTLY. This must look like the same tiger in a new
pose — the user should not notice that this is a different image
file, just a different emotion.
```

---

## 4.2 `mascot/tiger_sleepy.png` — 호랑이 졸음

> **사용처:** "오늘 마지막 카드", 푸쉬 알림, "쉴 시간" 안내

```
A square 1:1 character mascot illustration with TRANSPARENT BACKGROUND.
A Korean tiger seen from the front in 3/4 view, same sitting pose as
the reference tiger_idle, but with eyes nearly closed (gentle curved
lines), and the mouth slightly open in a quiet half-yawn (just a
small dark crescent opening). NOT asleep — drowsy, on the edge of
yawning. One ear droops slightly.

Mid-century modernist geometric reduction + Korean minhwa folk painting.
MUST match the proportions and pose of tiger_idle.png reference so
this pose drops into the mascot rotation seamlessly.

Composition (character only — NO background):
- Tiger body in burnt orange (#E87830) primary + rust shadow facet
  (#C25420), angular charcoal stripes (#1A1410), tiger cream
  (#F4E8D0) belly and inner areas — exactly as in reference
- 王 character on forehead in charcoal (#1A1410), same size
- Eyes: gentle curved lines (closed-eye style) in charcoal —
  almost smiling crescents, NO pupil visible
- Mouth: small soft dark crescent (#1A1410) suggesting a half-
  open yawn, NOT showing teeth
- One ear (the left ear from viewer perspective) droops slightly
  more than the other — subtle, only 5-8 degrees of tilt
- Both front paws on ground, same as idle reference

ATMOSPHERIC DETAILS:
- NO Z's, NO sleep symbols
- NO pillow, NO blanket
- NO bubble or speech indicator
- Transparent PNG-32 background
- VERY tiny single charcoal "z" detail near the head — NO, skip
  this. Drowsiness should be conveyed purely by eye and mouth shape

Style discipline (CRITICAL — must match mascot set):
- NO outlines on the tiger
- NO gradients within shapes
- Subtle hanji paper grain on character only
- Restricted palette: same as tiger_idle (tiger orange #E87830,
  rust #C25420, charcoal #1A1410, cream #F4E8D0, gold #DFA951)
- Same scale and canvas occupancy as tiger_idle reference

Aspect ratio: 1:1 square (1024 × 1024 pixels), transparent PNG-32.

ABSOLUTELY AVOID:
- "Z" sleep symbols or speech bubbles
- Lying down pose (this is sitting upright, drowsy)
- Fully closed asleep eyes (use the sleeping_tiger_b2 image instead
  for full sleep — this is the drowsy variant only)
- Cute/chibi proportions
- Background or shadow

This is the "you've worked enough today, rest" prompt. The tiger
is sleepy but still awake and dignified.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, scale, and proportions of the attached reference
mascot images EXACTLY. This must look like the same tiger in a
drowsy variant — same character, different mood.
```

---

## 4.3 `mascot/magpie_worry.png` — 까치 걱정

> **사용처:** 오답 / 동기화 실패 / 끝말잇기 dead_end

```
A square 1:1 character mascot illustration with TRANSPARENT BACKGROUND.
A Korean magpie wearing a gat hat, standing in 3/4 turn (same pose
direction as the reference magpie_perched), but with both wings
slightly raised and lifted away from the body in a small "oops"
gesture. Head tilted slightly downward and to one side, beak slightly
open as if about to say something. Gat hat is tipped slightly askew.
Worried but not panicked — gentle apologetic posture.

Mid-century modernist geometric reduction + Korean minhwa folk painting.
MUST match proportions and pose direction of magpie_perched.png so
this drops into the mascot rotation seamlessly.

Composition (character only — NO background):
- Magpie body in deep charcoal black (#1A1410) for back, head, and
  outer wings
- White-cream belly patch (#F4E8D0) at chest and lower body —
  same shape as in reference magpie_perched
- Gold-amber beak (#DFA951), slightly open (small dark gap visible)
- Gat hat: flat oval brim and cylindrical crown in charcoal
  (#1A1410), with a thin gold band (#DFA951) at the crown base —
  same as reference but tilted slightly askew (8-12 degrees off
  vertical)
- One alert eye visible, gold-amber pupil (#DFA951), looking down-
  and-to-the-side (the worried gaze)
- Both wings lifted slightly away from body — about 15-20 degrees,
  not fully spread. Wings show charcoal feather facets on the
  upper edge

ATMOSPHERIC DETAILS:
- NO ground line, NO shadow
- NO speech bubble, NO sweat drops, NO question marks
- NO tear drops (no anime tropes)
- Transparent PNG-32 background

Style discipline (CRITICAL — must match mascot set):
- NO outlines on the magpie
- NO gradients within shapes
- Subtle hanji paper grain on character only
- Restricted palette: charcoal #1A1410, cream #F4E8D0, gold #DFA951
  (NO other colors — this is the minimal magpie palette)
- Same scale and canvas occupancy as magpie_perched.png reference

Aspect ratio: 1:1 square (1024 × 1024 pixels), transparent PNG-32.

ABSOLUTELY AVOID:
- Tear drops, sweat drops, blue lines (anime worry symbols)
- Speech bubbles or "..." text
- Wings fully spread (must be only slightly lifted, "oh no" pose)
- Falling-off gat hat (must be just tilted, still on head)
- Pose facing fully away from viewer
- Cute/chibi proportions

This is the apologetic magpie — used after an incorrect answer or
a sync failure. Mood: "Oh, sorry — let me try again."

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, scale, and proportions of the attached reference
magpie images EXACTLY. This must look like the same magpie in a
worried variant — same character, different mood.
```

---

# Day 5 — 스토어 자산

## 5.1 `docs/store/feature_graphic.png` — Google Play feature graphic

> **사용처:** Google Play Console feature graphic 슬롯
> **사양:** **1024 × 500 (2:1 가로)**. Play가 이 위에 앱 제목·아이콘을 자동 오버레이하므로 **이미지 자체에 글자 금지**, 좌측 1/3은 비워둠 (negative space).

```
A wide 2:1 horizontal editorial banner illustration for the Google
Play Store feature graphic slot. A Korean hanok gateway (솟을대문)
stands slightly open on the RIGHT side of the frame, revealing a
warm hanji-cream interior glow. A dignified Korean tiger sits inside
the gateway looking out at the viewer, with a small magpie perched
on the gate's eave above him. The LEFT third of the frame is open
hanji cream sky with mountain silhouettes — left intentionally
spacious so the Play Store can overlay app title and icon there.

Mid-century modernist geometric reduction + Korean minhwa folk painting.
Premium magazine cover quality.

Composition layered front to back, wide 2:1 horizontal:

LAYER 1 — Sky and distant mountains (LEFT two thirds + upper area)
- Hanji cream sky (#FAF6EC) dominating LEFT half with one soft
  cream-to-pale-celadon (#D8E5DC) gradient (single permitted)
- 3 distant mountain silhouettes spanning LEFT and CENTER:
  closest in mountain teal (#3D9A7F), mid in sage (#5C7060),
  farthest in pale sage (#9BB0A0) — receding irworobongdo style
- LEFT THIRD is intentionally minimal — sky and ONE distant
  mountain peak only, leaving 30-35% of the frame as breathable
  negative space for Play's auto-overlaid title/icon

LAYER 2 — Hanok gate (CENTER-RIGHT, slightly open)
- A solssalmun (솟을대문) hanok gateway: tiered curved tile roof
  (#2A3340 with #1A2028 shadow facet), upturned eave horns on
  both sides
- Dancheong band under the eaves with alternating teal (#3D9A7F),
  red (#C24A45), gold (#DFA951), ivory (#F4E8D0) squares
- Two warm walnut wooden pillars (#7E5A3D + #5C4028 shadow facet)
  framing the doorway
- Two red dancheong door panels (#C24A45) slightly OPEN inward,
  with brass-gold doorknobs (#DFA951) visible
- Through the open doorway: a warm amber halo of welcoming light
  (#DFA951 at low opacity gradient — second permitted gradient,
  justified as the welcoming glow)

LAYER 3 — Tiger inside the gateway (focal point)
- A Korean tiger sitting upright in 3/4 frontal turn, framed by
  the open doorway behind him
- Burnt orange (#E87830) + rust shadow facet (#C25420), angular
  charcoal stripes (#1A1410), tiger cream belly (#F4E8D0), 王
  character on forehead, sharp amber-gold eyes looking at viewer
- Tiger size is sub-dominant to the gate frame — viewer reads
  "hanok gateway with tiger inside," not "tiger first"

LAYER 4 — Magpie on the eave (small accent)
- Small magpie wearing a gat hat perched on the LEFT side of the
  hanok eave, head turned toward viewer
- Black body (#1A1410), white belly (#F4E8D0), gold-amber beak
  (#DFA951)

LAYER 5 — Stone base / threshold (lower edge)
- Stone gray foundation (#8B8478) and a step or two leading up
  to the gateway, taking the lowermost 10-12% of the frame

ATMOSPHERIC DETAILS:
- 2 loose clusters of dancheong color dots: one near the eave's
  dancheong band, one in the LEFT mountain area
- One small plum branch (charcoal stem #1A1410 with 2 pale pink
  petals #E8B5BC) in the upper-LEFT corner — spring season anchor
- NO text, NO logos, NO titles ANYWHERE in the image
- LEFT 30-35% of frame must be clean negative space (sky and one
  mountain only)

Style discipline (CRITICAL):
- NO outlines on subjects
- Permitted gradients (TWO, both justified): sky atmosphere +
  doorway welcoming glow
- Subtle hanji paper grain overlay across image
- Restricted palette: hanji #FAF6EC, sky celadon #D8E5DC, mountain
  teal #3D9A7F, sage #5C7060 + #9BB0A0, slate #2A3340 + #1A2028,
  walnut #7E5A3D + #5C4028, dancheong red #C24A45, gold #DFA951,
  ivory #F4E8D0, tiger orange #E87830, rust #C25420, charcoal
  #1A1410, plum pink #E8B5BC, stone gray #8B8478
- High silhouette contrast for thumbnail readability at 200px
  wide (Play search results)

Aspect ratio: 2:1 horizontal (1024 × 500 pixels exactly).

ABSOLUTELY AVOID:
- ANY text, app name, tagline, or numerals
- Logo overlay (Play adds this automatically)
- Fully closed gateway (gate must be ajar, inviting entry)
- Fully open gateway (must be slightly open, suggesting "come in")
- Multiple tigers, multiple magpies
- Modern objects, smartphones, Western design elements
- Centered symmetrical composition (must be asymmetric: gate on
  right, breathing room on left)
- Sepia or monochromatic wash

This is the Google Play feature graphic — must instantly communicate
"premium Korean learning app with hanok aesthetic" at small thumbnail
size, while leaving the LEFT third clean for Play's automatic title
overlay.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. This must look like the most polished piece of the same
illustrated set — the cover image.
```

---

# Day 6 (옵션) — Wordle 단청 frame

## 6.1 `hanok/dancheong_frame.png` — Wordle 게임판 frame

> **사용처:** WordleScreen 게임판 외곽 BoxDecoration
> **사양:** 1024 × 1024 정사각, **가운데 영역 투명** (게임판 내용이 보이도록)
> **선택 작업** — 현재 코드는 BoxBorder + 4코너 dot로 fallback이 동작 중, PNG 들어오면 시각 강화

```
A square 1:1 decorative frame illustration. A Korean dancheong (단청)
ornamental border running around the four edges of a square canvas,
with the entire center area COMPLETELY TRANSPARENT (alpha = 0). The
frame should look like a slice of the dancheong band found under a
hanok eave, but bent into a closed rectangular border.

Mid-century modernist geometric reduction + Korean minhwa folk painting.
Symmetric, decorative, repeating pattern.

Composition (frame only — center is transparent):

FRAME STRUCTURE (border width ~120px from edge):
- Outer edge (touching canvas border): solid charcoal (#1A1410)
  line, ~6px thick
- Main band: dancheong teal (#3D9A7F) base, ~80px wide, running
  continuously around all four edges
- Inside the teal band: alternating geometric squares (~40px each)
  in dancheong red (#C24A45), gold (#DFA951), and ivory (#F4E8D0),
  evenly spaced around the border
- Inside each colored square: a tiny stylized flat lotus or
  chrysanthemum motif (4-petal angular shape, cream or contrasting
  color)
- Inner edge of the band: solid charcoal (#1A1410) line, ~4px thick
- Four corners: a slightly larger square (~50px) with a special
  motif — a small angular flame or 王 character — same in all 4
  corners for symmetric anchor

CENTER (CRITICAL):
- The inner area inside the border (approximately 800×800 region
  in the center) MUST BE FULLY TRANSPARENT — alpha channel = 0
- NO color, NO white background, NO gradient — pure transparency
  so the Wordle grid below shows through

ATMOSPHERIC DETAILS:
- No animals, no text, no other figures
- Subtle hanji paper grain ONLY on the frame areas (not on the
  transparent center)
- Pattern repeats consistently around all 4 edges

Style discipline (CRITICAL):
- NO outlines other than the structural charcoal edges
- NO smooth gradients
- Subtle hanji paper grain on frame
- Restricted palette: dancheong teal #3D9A7F, red #C24A45, gold
  #DFA951, ivory #F4E8D0, charcoal #1A1410

Aspect ratio: 1:1 square (1024 × 1024 pixels), transparent center.

ABSOLUTELY AVOID:
- Any content in the center (must be fully transparent)
- White or cream background fill in center (transparent only!)
- Asymmetric frame (must be 4-way symmetric)
- Asian pattern stereotypes (no dragons, no fans, no Chinese knots)
- Outlines around the colored squares

This is a decorative frame that will overlay a Wordle game grid.
The colored band wraps the grid in dancheong ornament; the center
must be transparent so the grid is visible inside.

IMPORTANT: match the geometric faceted style and color palette of
the attached reference images. The center MUST be fully transparent
(alpha 0) — verify with a checkered transparency view before
exporting.
```

---

# 자산 우선순위 추천 (Day 2-5 작업 순서)

| 순위 | 자산 | 이유 |
|---|---|---|
| 🔴 1 | Day 2 (빈/오류 5장) | `SoriEmptyState` 코드 완비 + 사용자 충돌 가능성. 5장 한 세트로 작업 |
| 🔴 2 | Day 4 (마스코트 3장) | 신규 화면 (Chosung mascot pop, 끝말잇기 thinking) 즉시 활용 |
| 🟡 3 | Day 3 (헤더 6장) | HanokHeader 자동 교체, 시각 강도 ⭐⭐ → ⭐⭐⭐로 |
| 🟡 4 | Day 5 (feature graphic) | 출시 제출 직전에만 필요 |
| 🟢 5 | Day 6 (frame, 옵션) | 현재 fallback 동작, v1.0.1 이월 가능 |

---

# Intro Gate 자산 (별도 작업 — gate.png 스타일과 100% 일치 필요)

> Jin이 직접 만드신 `assets/illustrations/hanok/gate.png`의 스타일·색감·디테일과 **완전히 일치**하는 분리 자산이 필요합니다. 현재 사용 중인 `gate_frame.png`, `gate_door_left.png`, `gate_door_right.png`는 평평한 색만으로 만들어진 낮은 퀄리티이므로 교체 권장.
>
> **3장 모두 동일 anchor: `assets/illustrations/hanok/gate.png` 첨부 필수.**

## Intro.1 `gate_frame.png` (교체) — 솟을대문 frame (가운데 도어 영역 투명)

```
A vertical 9:16 illustration of a Korean sotdaemun hanok gateway,
EXCEPT the central door area (the red double-door region) is FULLY
TRANSPARENT — alpha = 0 — leaving only the roof, eaves, dancheong
band, pillars, stone base, and surrounding background.

Match the EXACT style, color palette, line work, and detail level
of the reference gate.png attachment. This is the same gateway,
but with the door panels removed (because they will be animated
separately in code).

Composition layered front to back, 1080×1920 canvas:

LAYER 1 — Sky background
- Hanji cream (#FAF6EC) sky with one soft cream-to-ivory gradient
- One small muted indigo crescent moon (#1F2E5C) in upper right
  (matches reference gate.png exactly)

LAYER 2 — Distant mountain silhouettes
- Two angular green mountain silhouettes (mountain teal #3D9A7F
  + sage #5C7060) on left and right sides of the lower frame —
  exactly as in reference gate.png

LAYER 3 — Hanok roof and eaves (upper third)
- Tiered curved tile roof (기와지붕) in dark slate-charcoal (#2A3340)
  with deeper shadow facet (#1A2028) on the underside curve
- Upturned eave horns (처마끝) on both far left and far right
- Small dark roof ridge cap (망와) at the apex
- Match exactly the roof curvature, tile pattern, and proportion
  shown in reference gate.png

LAYER 4 — Dancheong band (under the eaves)
- Horizontal teal band (#3D9A7F) running across the full width
  below the roof
- Inside the band: alternating geometric squares (~equal spacing)
  in red (#C24A45), gold (#DFA951), ivory (#F4E8D0)
- Match the exact square count, color sequence, and motif inside
  each square as shown in reference gate.png

LAYER 5 — Wooden pillars and frame structure
- Two warm walnut wood pillars (#7E5A3D with darker shadow facet
  #5C4028 on the inner edge) running vertically from the dancheong
  band down to the stone base, framing the doorway
- A horizontal walnut lintel between the pillars at the top of the
  doorway

LAYER 6 — Stone base and steps
- Stone gray foundation (#8B8478) at the bottom, with one or two
  visible steps leading up to the gateway threshold
- Match reference gate.png exactly

CENTRAL TRANSPARENT AREA (CRITICAL):
- The rectangular area where the double red doors would normally be
  (approximately x=195 to x=885, y=615 to y=1615 in 1080×1920 space,
  matching the registration in HanokGateArt) MUST BE FULLY TRANSPARENT
  (alpha = 0)
- NO red color, NO door dots, NO doorknobs in this central area
- Through this transparent rectangle, the door panels (separate
  assets) will be rotated open in the app

ATMOSPHERIC DETAILS:
- A tiny single magpie shape silhouette perched on the roof apex
  (match reference gate.png exactly) — optional, only if it stays
  perfectly consistent
- 2-3 small dancheong dot accents around the gateway, matching
  the loose cluster pattern of reference

Style discipline (CRITICAL):
- NO outlines on subjects
- Match reference gate.png exactly: stroke weight, plane facets,
  hanji grain density, color saturation
- Restricted palette: SAME as reference gate.png — do not introduce
  any new color

Aspect ratio: 9:16 vertical (1080 × 1920 pixels), with transparent
central door area as specified.

ABSOLUTELY AVOID:
- Red color anywhere in the central door area (must be transparent)
- Different style or color saturation from reference gate.png
- New decorative elements not present in reference
- Outline strokes
- Modern elements

IMPORTANT: this asset MUST be visually 100% consistent with the
attached gate.png reference, except for the missing central door
area (which is intentionally transparent). The two door panels will
be supplied as separate assets that rotate into this transparent
window during the intro animation.
```

## Intro.2 `gate_door_left.png` — 좌측 문짝 단독 panel

```
A vertical illustration of a SINGLE LEFT door panel from a Korean
sotdaemun hanok gateway, isolated on a TRANSPARENT BACKGROUND.

This is the LEFT door panel from the reference gate.png — extracted
as a single standalone panel. Match the exact style, color, and
detail of the door shown in the reference.

Sizing context:
- The panel should fit a rectangular shape with proportions
  approximately 345 wide × 1000 tall (a tall narrow rectangle,
  roughly 1:2.9 aspect ratio)
- The RIGHT edge of the panel (the inner edge that meets the other
  door) should be where the hinge axis would be in the open
  position — but the asset itself is drawn as the CLOSED panel
  (the rotation happens in code)

Composition (panel only — TRANSPARENT background):

PANEL BODY:
- Solid dancheong red (#C24A45) main panel surface, with subtle
  rust shadow facet (#A8332E) along ONE vertical edge (the right
  edge — the inner edge that meets the other door) for slight
  3D depth
- A darker rust outline along all four panel edges in #7E2A22
  (~6px), suggesting the wooden door frame

PANEL DETAILS (match reference gate.png exactly):
- Vertical wood plank lines: 2-3 thin vertical charcoal lines
  (#7E2A22, thin 3-4px) running top to bottom, dividing the panel
  into 3 vertical plank sections
- Decorative gold-amber metal studs (#DFA951): rows of small
  circles (~24px diameter) arranged in a grid pattern, 4 rows ×
  3 columns, evenly spaced down the panel — these are the
  traditional hanok door rivets
- One large gold-amber door knocker handle (#DFA951): a circular
  ring (~80px diameter) attached to the panel near the inner edge
  (right side) at vertical mid-height, with a small backing plate

ATMOSPHERIC DETAILS:
- NO background (fully transparent)
- NO shadow underneath
- Subtle hanji paper grain ONLY on the red panel surface, not on
  the transparent area
- NO text or characters on the panel

Style discipline (CRITICAL — must match reference gate.png):
- Match the red dancheong color, stud pattern, and knocker style
  of the reference gate.png exactly
- NO outlines except the structural panel-frame edge
- NO smooth gradients
- Restricted palette: dancheong red #C24A45 + #A8332E + #7E2A22,
  gold #DFA951

Aspect ratio: approximately 1:2.9 vertical rectangle (345 × 1000
or proportional), transparent PNG-32.

ABSOLUTELY AVOID:
- Background of any color (must be fully transparent)
- Door frame, hinges, or surrounding architecture (those are in
  the gate_frame.png — this is the door panel ONLY)
- Different style than reference gate.png
- Outline strokes on stud circles
- Both door panels in one image (this is LEFT panel only)

IMPORTANT: this is one half of an animated door pair. The companion
right panel will be the mirror image. When closed (placed beside
each other in the gate_frame.png central transparent window), they
must visually align perfectly with the door area shown in the
reference gate.png.
```

## Intro.3 `gate_door_right.png` — 우측 문짝 (좌측 mirror)

```
A vertical illustration of a SINGLE RIGHT door panel from a Korean
sotdaemun hanok gateway, isolated on a TRANSPARENT BACKGROUND.

This is the MIRROR image of gate_door_left.png — the right half of
the double door. All specifications are identical to the left
panel EXCEPT the shadow facet, plank line offset, and door knocker
position are mirrored to the LEFT edge (the inner edge meeting the
left door).

Composition (panel only — TRANSPARENT background):

PANEL BODY:
- Solid dancheong red (#C24A45) main panel surface, with subtle
  rust shadow facet (#A8332E) along the LEFT vertical edge (the
  inner edge meeting the other door)
- Darker rust outline along all four panel edges in #7E2A22 (~6px)

PANEL DETAILS:
- Same 2-3 vertical plank lines as the left panel, mirrored
- Same 4×3 grid of gold-amber metal studs (#DFA951)
- One large gold-amber door knocker ring (~80px diameter, #DFA951)
  attached near the inner edge (LEFT side this time) at vertical
  mid-height

All other style discipline, palette, and avoidance rules are
identical to gate_door_left.png.

Aspect ratio: approximately 1:2.9 vertical rectangle (345 × 1000
or proportional), transparent PNG-32.

IMPORTANT: this is the mirror companion of gate_door_left.png.
When placed side by side, they must form a perfectly aligned
closed double door, identical to the door area visible in the
reference gate.png. Generate this as the exact horizontal mirror
of the left panel.
```

---

# 자산 작업 진행 체크리스트

생성한 PNG는 정해진 경로에 drop만 하면 `pubspec.yaml`의 폴더 등록 + `errorBuilder` fallback 로직으로 즉시 적용됩니다 (코드 수정 불필요).

## Day 2 — 빈/오류 (5장)
- [ ] `assets/illustrations/empty/sleeping_tiger_b2.png`
- [ ] `assets/illustrations/empty/celebrate_complete.png`
- [ ] `assets/illustrations/empty/study_room_waiting.png`
- [ ] `assets/illustrations/error/offline_lantern.png`
- [ ] `assets/illustrations/error/lost_magpie.png`

## Day 3 — 헤더 배너 (6장)
- [ ] `assets/illustrations/hanok/scholar_room.png` (Settings)
- [ ] `assets/illustrations/hanok/achievements.png` (Stats)
- [ ] `assets/illustrations/hanok/study_classroom.png` (Vocab)
- [ ] `assets/illustrations/hanok/study_scholar.png` (Grammar)
- [ ] `assets/illustrations/hanok/listening_hero.png` (/listening)
- [ ] `assets/illustrations/hanok/kkeunmari_hero.png` (끝말잇기)

## Day 4 — 마스코트 (3장)
- [ ] `assets/illustrations/mascot/tiger_thinking.png`
- [ ] `assets/illustrations/mascot/tiger_sleepy.png`
- [ ] `assets/illustrations/mascot/magpie_worry.png`

## Day 5 — 스토어 (1장)
- [ ] `docs/store/feature_graphic.png` (1024×500)

## Intro Gate (3장, gate.png 스타일 일치)
- [ ] `assets/illustrations/hanok/gate_frame.png` (교체 — 가운데 투명)
- [ ] `assets/illustrations/hanok/gate_door_left.png` (교체 — 단독 panel)
- [ ] `assets/illustrations/hanok/gate_door_right.png` (교체 — mirror)

## Day 6 옵션 (1장)
- [ ] `assets/illustrations/hanok/dancheong_frame.png` (Wordle frame)
