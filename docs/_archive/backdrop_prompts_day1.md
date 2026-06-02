# Hangul Sori — 시나리오 백드롭 5장 생성 프롬프트
> **Day 1-2 작업용.** Nano Banana 2 / ChatGPT에 그대로 복붙 가능.
>
> **공통 규칙 (필독):**
> - 생성 시 반드시 참조 이미지 **2장 첨부**: `assets/illustrations/mascot/tiger_idle.png` + `assets/illustrations/hanok/madang(light).png`
> - 가장 먼저 카페(cafe)를 생성하고, 결과가 만족스러우면 그 이미지를 **anchor**로 저장
> - 나머지 4장 생성 시 anchor 이미지 + 기존 참조 1장을 매번 첨부해 톤 일관성 유지
> - 저장 경로: `assets/illustrations/scenes/{name}.png` (1536 × 2048)
> - 8% opacity 백드롭으로 사용되므로 실루엣을 굵고 선명하게

---

## 1. `scenes/cafe.png` — 카페, 여름

```
A vertical 3:4 editorial illustration of a quiet contemporary Korean
café interior. Soft afternoon light, calm summer mood — a learner is
about to order a coffee.

Mid-century modernist geometric reduction (Saul Bass, Charley Harper era)
crossed with Korean minhwa folk painting iconography. NOT cute, NOT
cartoonish — confident, contemporary, premium editorial.

Composition layered front to back:

LAYER 1 — Background wall
- Hanji cream wall (#FAF6EC) with one large vertical celadon teal panel
  (#3D9A7F) on the left third
- Single soft gradient permitted: subtle cream-to-ivory wash on upper
  wall area

LAYER 2 — Mid ground
- Walnut wood counter (#8E6646 primary + #5C4028 shadow facet) running
  horizontally across lower-middle
- Espresso machine on counter as faceted slate-charcoal block
  (#2A3340 + #1A2028 shadow), with single dancheong gold knob accent
  (#DFA951)
- One celadon teacup (#3D9A7F + darker facet) on counter right

LAYER 3 — Foreground
- A small bamboo plant in a hanji-paper pot, lower right corner
- One folded paper menu standing on counter left

ATMOSPHERIC DETAILS:
- 2 loose clusters of dancheong color dots (one near espresso machine,
  one near plant)
- NO people, NO animals
- Generous negative space — wall and floor dominate

Style discipline (CRITICAL):
- NO outlines on subjects — pure color planes only
- NO smooth gradients within shapes EXCEPT the wall sky gradient
- Subtle hanji paper grain texture overlay across entire image
- Restricted palette: hanji cream #FAF6EC, walnut #8E6646, slate #2A3340,
  celadon #3D9A7F, dancheong gold #DFA951
- High contrast composition with clear silhouette readability

Aspect ratio: 3:4 vertical (1536 × 2048 pixels).

ABSOLUTELY AVOID:
- Text or signage
- Western café elements (chalkboards, Edison bulbs)
- Sepia wash
- Multiple seasons

This is editorial illustration for a premium Korean learning app —
serves as a soft 8% opacity backdrop, so design must read at low
opacity. Keep silhouettes bold and high contrast.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. This must look like part of the same illustrated set.
```

---

## 2. `scenes/restaurant.png` — 식당, 가을

```
A vertical 3:4 editorial illustration of a traditional Korean restaurant
interior. Warm late-afternoon light, mellow autumn mood — a learner is
about to order at a hanok-style bunsik restaurant.

Mid-century modernist geometric reduction (Saul Bass, Charley Harper era)
crossed with Korean minhwa folk painting iconography. NOT cute, NOT
cartoonish — confident, contemporary, premium editorial.

Composition layered front to back:

LAYER 1 — Background wall and ceiling
- Hanji cream wall (#FAF6EC) with exposed dark walnut ceiling beam
  (#5C4028) running horizontally at upper third
- On the wall: one abstract vertical scroll — pure black geometric
  plane (#1A1410), no legible characters, purely decorative

LAYER 2 — Mid ground
- Low Korean dining table (juksang, #8E6646 walnut) centered, viewed
  slightly from above
- On the table: four celadon bowls (#3D9A7F + shadow facet #2A6B5E)
  arranged in a loose cluster, two pairs of chopsticks resting on
  a small holder
- Floor: warm ochre floor (#C99A2E muted) with subtle hanji grain

LAYER 3 — Foreground
- One dry autumn maple leaf (#C24A45 red-rust, simple 5-point
  geometric silhouette) resting on the floor, lower left
- One more leaf half-entering from the right edge — implies autumn
  breeze through unseen door

ATMOSPHERIC DETAILS:
- 2 small clusters of dancheong color dots (one near bowl cluster,
  one near the scroll)
- NO people, NO animals
- Generous negative space on wall

Style discipline (CRITICAL):
- NO outlines on subjects — pure color planes only
- NO smooth gradients within shapes EXCEPT the upper wall wash
- Subtle hanji paper grain texture overlay across entire image
- Restricted palette: hanji cream #FAF6EC, walnut #8E6646/#5C4028,
  celadon #3D9A7F, rust leaf #C24A45, dancheong gold #DFA951,
  charcoal #1A1410
- High contrast composition with clear silhouette readability

Aspect ratio: 3:4 vertical (1536 × 2048 pixels).

ABSOLUTELY AVOID:
- Text or menu boards
- Korean food rendered realistically (use geometric color shapes only)
- People or animals
- Sepia wash
- Multiple seasons — autumn only

This is editorial illustration for a premium Korean learning app —
serves as a soft 8% opacity backdrop. Keep silhouettes bold.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. This must look like part of the same illustrated set.
```

---

## 3. `scenes/market.png` — 시장, 늦여름

```
A vertical 3:4 editorial illustration of a Korean traditional market
(시장) stall exterior. Bright open-air late-summer light, lively but
calm composition — a learner is about to shop at a produce stand.

Mid-century modernist geometric reduction (Saul Bass, Charley Harper era)
crossed with Korean minhwa folk painting iconography. NOT cute, NOT
cartoonish — confident, contemporary, premium editorial.

Composition layered front to back:

LAYER 1 — Background canopy and sky
- Market canopy across upper half: alternating vertical stripe panels
  in dancheong palette — celadon (#3D9A7F), rust-red (#C24A45), hanji
  cream (#FAF6EC) — each stripe a solid flat geometric shape
- Above canopy: pale celadon sky gradient (the single permitted gradient)

LAYER 2 — Mid ground display table
- Wooden trestle table (#8E6646 walnut + #5C4028 shadow) spanning
  the mid frame
- On the table: three produce silhouettes as bold geometric shapes —
  a persimmon cluster (orange-amber #E87830, 3 spheres), a pale green
  pear (#B5C99A, ellipse), a head of napa cabbage (#3D9A7F + cream
  facets in tight wedge shapes)
- Small hanging weight-scale (#2A3340 slate) suspended from canopy
  edge on the right

LAYER 3 — Foreground
- A wrapped hanji-paper bundle tied with cord, sitting on lower
  platform, left of center
- Single lotus leaf (#3D9A7F flat disc) leaning against the table leg,
  late-summer motif

ATMOSPHERIC DETAILS:
- 2 clusters of dancheong dots scattered near produce
- NO people, NO animals
- Clear open sky and canopy dominate the upper half

Style discipline (CRITICAL):
- NO outlines on subjects — pure color planes only
- NO smooth gradients within shapes EXCEPT the sky
- Subtle hanji paper grain texture overlay across entire image
- Restricted palette: canopy stripes #3D9A7F / #C24A45 / #FAF6EC,
  walnut #8E6646, persimmon #E87830, pear #B5C99A,
  dancheong gold #DFA951
- High contrast composition with clear silhouette readability

Aspect ratio: 3:4 vertical (1536 × 2048 pixels).

ABSOLUTELY AVOID:
- Text on stall or signs
- Plastic or modern packaging
- People or animals
- Sepia wash
- Winter or spring motifs

This is editorial illustration for a premium Korean learning app —
serves as a soft 8% opacity backdrop. Keep silhouettes bold.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. This must look like part of the same illustrated set.
```

---

## 4. `scenes/hotel.png` — 호텔 / 한옥 사랑채, 겨울

```
A vertical 3:4 editorial illustration of a Korean hanok-style hotel
lobby or sarangchae reception corner. Cool, quiet winter atmosphere —
a learner is checking in or asking for directions at the front desk.

Mid-century modernist geometric reduction (Saul Bass, Charley Harper era)
crossed with Korean minhwa folk painting iconography. NOT cute, NOT
cartoonish — confident, contemporary, premium editorial.

Composition layered front to back:

LAYER 1 — Background wall and window
- Hanji cream wall (#FAF6EC); on the right third: a tall rectangular
  lattice window (창호지문) — white hanji panes divided by dark
  charcoal (#1A1410) geometric grid lines
- Through the window: a single bare persimmon branch silhouette
  (#8E6646 walnut, geometric angular) and one hanging persimmon
  fruit (#C99A2E gold) — winter motif

LAYER 2 — Mid ground counter
- Low traditional reception counter (#8E6646 walnut + #5C4028 shadow
  facet) centered horizontally in the mid frame
- On the counter: one small bronze desk bell as a flat trapezoidal
  shape (#DFA951 gold + dark facet), one traditional key with a
  tassel (#1A1410 charcoal body, #C24A45 tassel), one folded
  hanji-paper ledger book (cream + charcoal spine)

LAYER 3 — Foreground
- A small ceramic vase (#3D9A7F celadon, rounded trapezoidal form)
  with one dry winter branch, lower right
- Single traveler's wrapping cloth (보따리 in slate #2A3340) on
  the floor, lower left

ATMOSPHERIC DETAILS:
- 2 small clusters of dancheong dots (near bell, near vase)
- NO people, NO animals
- Soft cool light implying winter overcast

Style discipline (CRITICAL):
- NO outlines on subjects — pure color planes only
- NO smooth gradients within shapes EXCEPT the window sky beyond
- Subtle hanji paper grain texture overlay across entire image
- Restricted palette: hanji cream #FAF6EC, walnut #8E6646,
  charcoal #1A1410, celadon #3D9A7F, gold #DFA951, rust #C24A45
- High contrast composition with clear silhouette readability

Aspect ratio: 3:4 vertical (1536 × 2048 pixels).

ABSOLUTELY AVOID:
- Text or signage
- Modern hotel elements (elevator buttons, plastic cards)
- People or animals
- Sepia wash
- Summer or autumn motifs

This is editorial illustration for a premium Korean learning app —
serves as a soft 8% opacity backdrop. Keep silhouettes bold.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. This must look like part of the same illustrated set.
```

---

## 5. `scenes/directions.png` — 길찾기, 봄

```
A vertical 3:4 editorial illustration of a Korean outdoor crossroads
scene. Clear spring morning light — a learner is asking for directions
on a quiet street near a traditional hanok district.

Mid-century modernist geometric reduction (Saul Bass, Charley Harper era)
crossed with Korean minhwa folk painting iconography. NOT cute, NOT
cartoonish — confident, contemporary, premium editorial.

Composition layered front to back:

LAYER 1 — Background sky and distant mountain
- Upper third: pale celadon sky (#A8D5C4, gradient to hanji cream —
  the single permitted gradient)
- Mid-distant: one simplified mountain silhouette (irworobongdo style)
  — three overlapping geometric triangular peaks in muted slate
  (#3A4A48 darkest peak, #5A6E6A mid, #7A9090 lightest)
- On the horizon line: one hanok tiled-roof silhouette (#1A1410
  charcoal, purely geometric — curved eave as a single arc shape)

LAYER 2 — Mid ground road and signpost
- A stone-paved road diverging into two paths (a Y-junction viewed
  from slight elevation) — stones in hanji cream #FAF6EC with
  charcoal #1A1410 thin mortar lines between
- At the junction: one traditional wooden signpost (#8E6646 walnut)
  with two rectangular arm planks — NO text, purely abstract shapes

LAYER 3 — Foreground
- Lower right: one plum blossom branch (매화) as flat geometric
  shapes — dark charcoal branch (#1A1410), three 5-petal blossoms
  (#FAF6EC white petals, #DFA951 gold center dots)
- Lower left: a simple bicycle silhouette (#2A3340 slate, geometric
  frame + two circles for wheels) leaning against the signpost base

ATMOSPHERIC DETAILS:
- 3 falling plum blossom petals (#FAF6EC) scattered around the
  junction — spring motif
- 1 cluster of dancheong dots near the signpost
- NO people, NO animals

Style discipline (CRITICAL):
- NO outlines on subjects — pure color planes only
- NO smooth gradients within shapes EXCEPT the sky
- Subtle hanji paper grain texture overlay across entire image
- Restricted palette: sky celadon #A8D5C4, mountain slate #3A4A48,
  road cream #FAF6EC, walnut #8E6646, charcoal #1A1410,
  blossom gold #DFA951
- High contrast composition with clear silhouette readability

Aspect ratio: 3:4 vertical (1536 × 2048 pixels).

ABSOLUTELY AVOID:
- Text on signpost or road
- Realistic perspective (no vanishing point receding road)
- People or animals
- Sepia wash
- Autumn or winter motifs

This is editorial illustration for a premium Korean learning app —
serves as a soft 8% opacity backdrop. Keep silhouettes bold.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. This must look like part of the same illustrated set.
```

---

## 생성 순서 & 앵커 전략

1. **카페(cafe) 먼저** — 가장 실내 단순, 프롬프트 가장 상세. 이 장이 tone setter.
2. 결과 확인 — 면 분할·하지 그레인·팔레트 3요소 모두 맞으면 anchor 확정.
3. **나머지 4장은 무조건 anchor 첨부** — anchor + `tiger_idle.png` 2장을 참조 이미지로.
4. 한 세션에서 5장 모두 완성하는 게 가장 톤이 일관됨. 세션 끊기면 anchor로 재시작.

## 완성 후 체크리스트 (장당)

- [ ] 텍스트 0개 (글자 없는지 확대 확인)
- [ ] 사람·동물 0개
- [ ] 단청 색 군집 2곳 (흩뿌리기 금지)
- [ ] 실루엣이 굵고 선명 (Figma/Preview에서 8% opacity 레이어 올려 확인)
- [ ] 파일명 정확: `cafe.png`, `restaurant.png`, `market.png`, `hotel.png`, `directions.png`
- [ ] 저장 경로: `assets/illustrations/scenes/`
