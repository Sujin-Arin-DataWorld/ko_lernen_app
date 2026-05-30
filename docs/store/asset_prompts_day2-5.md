# Hangul Sori — Asset Prompts (Day 2~5) — **v2 개선판**

> **Day 1 (백드롭 5장) 다음으로 만들 모든 자산 통합 프롬프트.**
> Nano Banana 2 / ChatGPT / DALL-E에 그대로 복붙 가능.
>
> **2026-05-28 개정 사유:** Day 4 tiger_thinking 등에서 호랑이가 chibi 새끼 고양이처럼 나오고, 까치의 gat 비율이 작아지고, 王 한자가 literal하게 새겨지는 등 기존 mascot/ asset과 캐릭터가 다르게 그려지는 문제 발견. 원인은 (1) bust-up framing 미명시, (2) "王 character" literal 해석, (3) 수염·cheek tuft·eye treatment 누락. v2는 **§0 캐릭터 시트**를 도입해 모든 prompt에서 동일 anchor를 반복 인용한다.
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

# §0 캐릭터 시트 (Character Sheet) — **모든 prompt에 인용 필수**

> 이 섹션은 **§0.4 BLOCK** 그대로 모든 호랑이/까치 등장 prompt에 복붙해야 한다. AI는 짧은 한 줄 설명("dignified Korean tiger") 만으로는 reference와 다른 캐릭터를 그린다. **물리적 디테일을 매번 다시 명시**하는 것이 v2의 핵심.

## §0.1 호랑이 (Korean Tiger) — Character DNA

기존 자산 분석(`mascot/tiger_idle.png` · `tiger_celebrate.png` · `tiger_neutral.png` · `tiger_happy.png` · `tiger_smile.png`)을 기반으로 한 정확한 anatomy + style sheet.

**Build / Proportion (NON-NEGOTIABLE):**
- **Adult guardian build**, NOT chibi, NOT cub, NOT young cat. Head is large and dignified but NOT enlarged in a cartoonish way.
- **Head-to-torso ratio ≈ 1 : 1.5** — the head is large and dignified relative to the body, but the body is clearly that of an adult tiger (broad chest, strong forelegs, full hindquarters and tail visible). Even at full-body framing, the head must remain prominent enough to read its facial detail at thumbnail size.
- **Default framing for Day 4 solo mascot poses is FULL-BODY seated 3/4 turn** (matching `tiger_sad.png` reference: head + chest + front paws + folded hind legs + tail all visible inside the canvas). The full sitting silhouette occupies roughly 70–80 % of canvas height with negative space around all sides.
- The existing bust-up references (`tiger_idle.png`, `tiger_celebrate.png`, `tiger_happy.png`, `tiger_smile.png`, `tiger_neutral.png`) are **head-and-shoulders portraits** used for compact UI contexts; they are NOT the framing target for new Day 4 poses. Match the FULL-BODY framing of `tiger_sad.png` instead.
- In full-body framing, the head occupies **22–28 % of canvas height** and the cheek-to-cheek width at the whisker line is roughly the width of the upper chest.

**Head construction (faceted planes, NO outlines):**
- **Crown / forehead:** burnt orange `#E87830` primary plane with rust-orange `#C25420` shadow facet on the side away from light.
- **Forehead stripe pattern (the "王" suggestion — NEVER the literal Chinese character!):** three short horizontal charcoal `#1A1410` stripes stacked centrally between the eyes, with one short vertical charcoal stripe crossing through them. The vertical stripe is interrupted at the top and bottom by orange — leaving a stylised symbol that *reads* like 王 from a distance but is drawn as four to five discrete angular stripe facets, **not** as a typographic character.
- **Eyes:** sharp **almond-shaped** with a flat **amber-gold** `#DFA951` iris filling the entire eye shape. NO visible round pupil dot, NO white sclera — the gold fills edge to edge. A single thin charcoal `#1A1410` upper eye-line defines the lid (slightly thicker at the inner corner, tapering outward). Below the eye, a tiny rust facet acts as eye-bag. Eyebrow stripes are two short angular charcoal slashes diagonally above each eye.
- **Cheek tufts (THE iconic detail — must not be omitted):** large puffy cream `#F4E8D0` fur masses flaring outward on both sides of the muzzle, shaped as 3–4 stacked angular facet shards. They extend past the cheekbone line and give the head its widened "kite" silhouette.
- **Whisker lines:** 4 thin charcoal `#1A1410` whiskers per side, drawn as sharp angular triangular slivers (NOT smooth curves) radiating outward from the muzzle. Each whisker is one solid sliver, no thickness variation along its length.
- **Muzzle:** small cream `#F4E8D0` triangular shape, with a small downward triangular **muted brown-pink** `#7E4030` nose at the top of the muzzle. Mouth line is a short charcoal angular V below the nose.
- **Ears:** two angular triangle ears at the top of the head, **outer rim charcoal** `#1A1410`, **inner ear cream** `#F4E8D0` with a small dusty-pink `#D8B5B5` inner shadow facet. Ears point upward and outward, never droop unless explicitly drowsy.

**Body (when visible in bust-up):**
- Shoulders broad, slightly tapering toward the chest.
- **Chest cream V:** a strong angular cream `#F4E8D0` V-shape running from the throat down between the front legs, framed on each side by 2–3 angular charcoal `#1A1410` body stripes that point inward toward the V like arrows.
- Side body: burnt orange `#E87830` primary + rust `#C25420` shadow facets where the orange meets shadow. Body stripes are 4–6 angular charcoal shards per visible flank, **angular not curved**, narrowing toward the tips.

**Paws (when visible at bottom of bust-up):**
- Front paws as flat cream-orange angular shapes peeking just at the bottom edge of the canvas. Toe lines drawn as 3 short charcoal slashes. NO claws visible.

**Texture & finish:**
- Subtle hanji paper grain `#FAF6EC` overlay applied only across the tiger's body fill — visible especially on the cream belly. The transparent area stays clean.
- No outlines anywhere on the tiger; planes are defined by color edges only.
- One small subtle rust facet at the corner of each eye for "tear track" suggestion (optional but consistent with reference).

**ABSOLUTE PROHIBITIONS for the tiger (apply to every prompt):**
- ✗ NO literal `王` (Chinese character) drawn as typography on the forehead. Use the stripe pattern described above instead.
- ✗ NO chibi / Cub / Kawaii proportions. The tiger is an adult dignified guardian.
- ✗ NO smooth curved outlines around the body. Planes only.
- ✗ NO round black pupil dots in the eyes. The iris is flat gold filling the entire almond shape.
- ✗ NO smile-cat mouth (no upturned cartoon U mouth). Mouth is a small angular V or closed.
- ✗ NO sparse / missing cheek tufts. The cream cheek tufts are part of the silhouette identity.
- ✗ NO drooping cat ears (unless `tiger_sleepy` specifically calls for it).
- ✗ NO realistic 3D fur rendering. Faceted flat planes only.

## §0.2 까치 (Korean Magpie with 갓) — Character DNA

기존 자산 분석(`mascot/magpie_perched.png` · `magpie_celebrate.png` · `magpie_wingup.png` · `magpie_wingdown.png`).

**Build / Proportion:**
- **Standing magpie ~ 60–70 % of canvas height** in solo poses. Body is upright and slim, not chubby.
- Head sits on a slim neck; from beak tip to tail tip the body forms a slightly back-leaning S-curve.
- **Gat hat is PROMINENT, NOT tiny.** The hat from brim to crown top equals **roughly the height of the head itself** — i.e. when you add hat + head together, the hat occupies the upper ~45 % of that combined silhouette.

**Gat hat (갓) construction:**
- **Brim:** flat oval disc in **solid charcoal** `#1A1410`, perfectly horizontal when the magpie's head is upright. Width of brim is ~1.7× the width of the head. Slight darker facet `#0F0A08` on the underside catch shadow.
- **Crown:** tall cylindrical column in solid charcoal `#1A1410`, height ≈ width × 1.3 (slightly taller than wide). Sides absolutely vertical, top is flat.
- **Gold band:** a thin solid **gold-amber** `#DFA951` horizontal band wrapping the very base of the crown where it meets the brim. ~6–8 % of crown height in thickness. This band is a critical identifier — never omit.
- **Posture of hat:** sits squarely on top of the head, slightly recessed back so the brim shades the upper eye. Tilt only if the prompt explicitly says so (e.g. `magpie_worry` allows 8–12° askew).

**Head & face:**
- **Body / head:** primary plane in deep charcoal `#1A1410`, with a small darker facet `#0F0A08` on the rear-facing side for volume.
- **Beak:** **bright gold-amber** `#DFA951` (NOT yellow, NOT orange — true gold-amber), built from two angular triangular facets — upper beak slightly larger, lower beak smaller — with a thin charcoal `#1A1410` mouth-line splitting them. Beak points forward + slightly down.
- **Eye (one visible in 3/4 turn):** large, almond-shaped, fills the visible eye space. **Gold-amber sclera** `#DFA951` (the WHOLE eye is gold) with a tiny round charcoal `#1A1410` pupil placed off-center (alert direction). A thin charcoal upper eye-line above. NO white sclera.

**Body, wings, tail:**
- **Chest / belly patch:** large bright **tiger cream** `#F4E8D0` patch covering the entire front from throat to belly, with a slightly **dusty-pink** `#D8B5B5` shadow facet on one side for volume. The patch shape is rounded-triangular, not perfectly oval.
- **Wing bar (THE iconic identifier — must not be omitted):** on the shoulder / upper folded wing, a distinct **cream** `#F4E8D0` angular **wing-bar slash** crossing the upper wing — looks like a single faceted parallelogram of cream sitting on the charcoal wing. This is what makes the bird read as a Korean magpie (까치) and not a generic crow.
- **Folded wing details:** charcoal `#1A1410` primary with 2–3 darker `#0F0A08` facet shards indicating feather layers. The wing tip ends in 2–3 sharp angular feather points (NOT rounded).
- **Tail:** long, narrow, angular. Built from 3–4 stacked feather facet shards in alternating charcoal `#1A1410` and slightly lighter `#2A2018` tones. Tail length ≈ body height (long magpie tail is iconic).
- **Legs:** thin charcoal sticks with 3-toed angular feet. NO claws as sharp curves; just simple triangular toe points.

**Texture & finish:**
- Subtle hanji grain on the cream belly and on the brim/crown of the hat.
- No outlines on the magpie; planes only.

**ABSOLUTE PROHIBITIONS for the magpie:**
- ✗ NO tiny hat. The gat is full-sized — roughly equal to the head in stacked height.
- ✗ NO missing cream wing bar. It must be visible on the folded wing.
- ✗ NO white sclera with black pupil. The eye is gold-amber with tiny charcoal pupil.
- ✗ NO orange or yellow beak. The beak is gold-amber `#DFA951`.
- ✗ NO chibi penguin / round Pokémon proportions. The magpie is slim and elegant.
- ✗ NO removing the gold band on the gat hat.
- ✗ NO crow / raven look (short tail). The tail is long and narrow.

## §0.3 공통 면 분할 & finish discipline (every prompt)

- **Faceted Minhwa style** — Saul Bass / Charley Harper geometric reduction × Korean minhwa iconography.
- NO outlines on subjects. Pure flat color planes meeting at angular edges.
- NO smooth gradients within shapes, with the explicit single-gradient exception per image (always the sky/background atmosphere; rarely a second one for a light halo justified in-image).
- Subtle **hanji paper grain** texture overlay across the entire image (or, in transparent-PNG mascot work, across the character body fill only).
- Restricted palette — **only** the HEX values from `HANGUL_SORI_STYLE_GUIDE.md`. No candy colors, no neon, no Western pastels.
- High silhouette contrast — the subject must be readable at 200 px thumbnail size.
- Hard angular facet edges between adjacent color planes, NOT soft airbrushed transitions.

## §0.4 인용 BLOCK — 호랑이/까치 등장 prompt에 그대로 복붙

> **사용법:** 호랑이 또는 까치가 등장하는 모든 prompt 안에 아래 BLOCK을 그대로 삽입한다(필요 시 등장하지 않는 캐릭터 줄은 삭제). AI가 짧은 묘사로 generic하게 그리는 것을 막는 anchor.

```
CHARACTER ANCHOR — match the existing mascot set EXACTLY:

TIGER (Korean guardian tiger 호랑이):
- Adult dignified guardian build, NOT chibi, NOT cub. Full-body seated
  3/4 turn proportions (match tiger_sad.png reference): head + chest +
  visible front paws + folded hind legs + tail. Head-to-torso ratio
  ~ 1:1.5 — head is dignified-large but the body clearly an adult
  tiger, NOT a head-heavy chibi.
- Burnt orange (#E87830) primary fur + rust (#C25420) shadow facets +
  angular charcoal (#1A1410) stripes + tiger cream (#F4E8D0) belly,
  chin, and cheek tufts.
- Forehead stripe pattern that SUGGESTS the character 王 — three short
  horizontal charcoal stripes stacked between the eyes, crossed by
  one short vertical charcoal stripe. Drawn as 4-5 discrete angular
  stripe shards, NEVER as a literal Chinese typographic character.
- Eyes: sharp almond-shaped with a flat amber-gold (#DFA951) iris
  filling the entire eye shape (NO round black pupil dot, NO white
  sclera). Single thin charcoal upper eye-line above each eye.
- Large puffy cream (#F4E8D0) cheek tufts flaring outward on both
  sides of the muzzle — angular faceted shards, prominent in the
  silhouette.
- 4 thin angular charcoal whisker slivers per side radiating from
  the muzzle (sharp triangular slivers, not smooth curves).
- Small muted brown-pink (#7E4030) triangular nose; charcoal V mouth.
- Triangular ears with charcoal outer rim and cream inner with dusty-
  pink (#D8B5B5) shadow facet.
- Chest cream V shape framed by inward-pointing angular stripes.
- Subtle hanji paper grain overlay on the body fill.
- Planes only, NO outlines.

MAGPIE (Korean magpie with gat hat 갓 까치):
- Slim elegant standing build, ~60-70% of canvas in solo poses.
- Charcoal (#1A1410) body with darker (#0F0A08) shadow facets.
- Large bright tiger cream (#F4E8D0) belly patch with dusty-pink
  (#D8B5B5) shadow facet.
- THE iconic CREAM wing-bar slash (#F4E8D0) on the folded upper wing
  — a single angular parallelogram of cream sitting on the charcoal
  wing. MUST be visible.
- Long narrow angular magpie tail (~ body height), built from
  alternating charcoal facet shards.
- Gold-amber (#DFA951) beak built from two angular triangle facets
  split by a thin charcoal mouth line.
- Single visible eye in 3/4 turn: large almond shape filled with
  gold-amber (#DFA951) iris, tiny charcoal (#1A1410) round pupil
  off-centered for alertness. Thin charcoal upper eye-line.
- Gat hat (갓) — PROMINENT, not tiny:
  * Flat oval brim in solid charcoal (#1A1410), width ~1.7x the
    head width, perfectly horizontal.
  * Tall cylindrical crown in solid charcoal, height ≈ width × 1.3.
  * Thin gold-amber (#DFA951) horizontal band wrapping the base of
    the crown — this band is non-negotiable.
  * Sits squarely on top of the head (unless prompt explicitly says
    askew).

STRICT NEGATIVE — applies to both characters:
- NO literal 王 Chinese character drawn as typography anywhere.
- NO chibi / cub / kawaii / Pokémon proportions.
- NO smile-mouth or upturned cartoon U mouth.
- NO tiny gat hat; NO missing gold band on the gat.
- NO missing cream wing bar on the magpie's folded wing.
- NO realistic 3D / watercolor / anime / chibi rendering style.

OUTLINE RULE — READ THIS CAREFULLY (this is the #1 failure mode):
- ZERO outlines anywhere on the character. Not around the body
  silhouette, not around the stripes, not around the cheek tufts,
  not around the muzzle, not around the chest V, not around the
  paws, not around the hat brim, not around the wing bar, not
  around any color plane.
- The image must look like CUT PAPER or STAINED GLASS: adjacent
  color planes meet directly at their color edges with NO drawn
  line of any color between them.
- The ONLY dark elements allowed to read as "lines" are:
  (a) the charcoal stripe SHAPES themselves (which are filled
      shapes, not outlines around something else),
  (b) the thin angular whisker slivers (filled shapes, not outlines),
  (c) a single thin charcoal line tracing only the upper eyelid,
  (d) the thin charcoal mouth-line splitting the magpie's beak.
- If you draw any black/charcoal LINE around the body silhouette,
  around a stripe, around the cheek tuft, around the chest V, around
  the paw, around the hat brim, or around the wing bar — the image
  is UNUSABLE and must be regenerated.
- Reference image (tiger_idle.png / magpie_perched.png): study the
  attached references. In those images there are ZERO outlines
  between any color planes. Match the reference exactly on this
  point. The reference looks like cut paper, not like a coloring
  book illustration.

TIGER EYE RULE — READ THIS CAREFULLY (this is the #2 failure mode):
- The tiger's visible eye is ONE solid gold-amber (#DFA951) almond
  shape filling the entire eye area edge to edge.
- NO round black pupil dot inside the tiger's eye.
- NO white sclera (white area around a pupil) anywhere in the
  tiger's eye.
- NO highlight reflection dot ("anime glint").
- The tiger eye looks like a flat gold coin in an almond shape —
  not like a cartoon cat eye, not like an anime eye, not like a
  Disney-style eye.
- A single thin charcoal line tracing ONLY the upper eyelid is
  allowed (and is part of the reference look).
- If the tiger's eye is drawn as a yellow/gold circle with a black
  dot inside and white around it, the image is UNUSABLE.
- Reference image tiger_idle.png: the tiger's eye in that image
  fills the entire almond with solid gold, no pupil dot, no white
  sclera. Copy that exact eye style.

MAGPIE EYE RULE (the magpie is the EXCEPTION — magpie DOES have a
small pupil, tiger does NOT):
- The magpie's visible eye is a large gold-amber (#DFA951) almond
  filling the eye area, with ONE tiny charcoal (#1A1410) round
  pupil placed off-center for an alert gaze direction.
- NO white sclera around the pupil. The gold-amber fills the entire
  almond shape; the pupil is a single small dot inside that gold.
- Pupil size: roughly 15-20% of the eye's width — small, not a big
  cartoon pupil.

GRADIENT RULE:
- NO smooth gradients within any character shape. Each plane is a
  single flat color. Volume comes from hard-edged plane transitions
  between lighter and shadow facets, not from blurring.
- The single per-image atmospheric sky gradient is permitted ONLY
  in non-mascot scenes (Day 2/3/5 backgrounds), never inside the
  character body fill.
```

> **참고:** 위 BLOCK은 각 prompt 안의 별도 섹션으로 넣되, `Style discipline (CRITICAL)`보다 **위에** 배치하여 AI가 가장 먼저 읽도록 한다.

---

# Day 2 — 빈/오류 상태 일러스트 5장

> **사양 공통:** 1024 × 1024 정사각, 중앙 단일 모티프, 주변 hanji 여백 풍부.
> 빈/오류 상태는 사용자가 좌절하지 않도록 **정중하고 따뜻한 톤** 유지.
> 참조 첨부: `mascot/tiger_idle.png` + `mascot/magpie_perched.png` (호랑이/까치 anchor) + (1장은 `hanok/madang(light).png`).
>
> **v2 변경점:** 호랑이/까치 등장 prompt 4장에 §0.4 CHARACTER ANCHOR BLOCK 삽입. `study_room_waiting`는 캐릭터 없어 anchor 불필요.

## 2.1 `empty/sleeping_tiger_b2.png` — B2 콘텐츠 잠금

> **사용처:** 시나리오 리스트에서 B2 미해금 시 / B2 카드 잠금 화면
> **무드:** "아직 못 깨워" — 격려하는 잠시 휴식
> **포즈:** 측면 누운 자세 (curled up) — 이번엔 bust-up이 아닌 lying full-body 가 정답 (sleeping 표현 때문). 이미 좋은 결과(`empty/sleeping_tiger_b2.png`)가 있으므로 톤 유지.

```
A square 1:1 editorial illustration of a sleeping Korean guardian
tiger curled up on a warm walnut hanok wooden floor. A small magpie
wearing a tall gat hat (갓) perches calmly on the tiger's tail,
patient and curious, not waking him.

Mid-century modernist geometric reduction (Saul Bass, Charley Harper
era) crossed with Korean minhwa folk painting iconography. Adult
dignified guardian energy even while sleeping — NOT chibi, NOT cute.
Premium contemporary editorial.

[INSERT §0.4 CHARACTER ANCHOR BLOCK HERE]

Pose-specific notes for THIS image (sleeping side-curl exception to
default bust-up framing):
- Tiger is lying curled up in profile / 3/4 view, head resting on
  one front paw tucked under the chin. Eyes are closed — drawn as
  two short gentle downward curved charcoal (#1A1410) crescent
  lines (NOT smile-eyes; just closed shut).
- The forehead stripe pattern (the 王 suggestion) is still clearly
  visible on the side of the forehead that faces the viewer.
- Cheek tufts and whiskers visible on the visible side.
- Body fills lower 60% of canvas, curled into a soft round mass with
  the tail wrapping around to the front; the tail tip sticks out and
  the magpie stands on the curl of the tail.
- Magpie is in 3/4 turn, head tilted down looking at the tiger's
  tail. Smaller in scale: hat brim ~ 12% of canvas width.

Composition:
- Background: hanji cream (#FAF6EC) dominant with one soft cream-to-
  ivory (#F4E8D0) gradient on the upper area (single permitted).
- Floor: warm walnut wood (#8E6646) plane occupying the bottom 25%,
  with a darker walnut shadow (#5C4028) line suggesting plank edges.

ATMOSPHERIC DETAILS:
- 2 plum blossom petals (pale pink #E8B5BC) falling diagonally in the
  upper right quadrant — spring season anchor.
- NO other animals, NO text, NO clutter.

Style discipline (CRITICAL):
- NO outlines on subjects — pure color planes only.
- NO smooth gradients within shapes EXCEPT the background sky wash.
- Subtle hanji paper grain texture overlay across entire image.
- Restricted palette: tiger orange #E87830, rust #C25420, charcoal
  #1A1410, magpie cream #F4E8D0, walnut #8E6646 + #5C4028, hanji
  #FAF6EC + #F4E8D0, dancheong gold #DFA951, plum pink #E8B5BC,
  dusty pink #D8B5B5.
- High contrast composition with clear silhouette readability at 200px.

Aspect ratio: 1:1 square (1024 × 1024 pixels).

ABSOLUTELY AVOID:
- Cute / chibi / cub-proportioned tiger.
- Literal Chinese character 王 drawn as text on the forehead.
- Tiny gat hat on the magpie. Missing gold band on the gat.
- Missing cream wing bar on the magpie's folded wing.
- Text, signage, or speech bubbles.
- More than one magpie. Any third animal.
- Sepia wash or monochromatic tone.
- Mixed seasons (commit to spring only — plum, not maple).

This is an empty state illustration for "B2 content is being prepared."
Mood should be reassuring patience, not frustration.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. The tiger MUST read as the same character as in tiger_idle.png
and tiger_celebrate.png — same head proportions, same forehead stripe
pattern, same cheek tufts, same eye style. The magpie MUST read as the
same character as in magpie_perched.png — same prominent gat hat with
gold band, same cream wing bar. This must look like part of the same
illustrated set.
```

---

## 2.2 `empty/celebrate_complete.png` — 단어장 due 완료

> **사용처:** Vocab 화면, 오늘 due 카드 0개 (모두 학습 완료)
> **무드:** 자랑스럽고 따뜻한 축하 — **bust-up portrait** framing 기본 (idle/celebrate reference와 일치)

```
A square 1:1 editorial illustration. A Korean guardian tiger in a
bust-up frontal portrait (head + shoulders + upper chest only — same
framing as tiger_idle.png and tiger_celebrate.png references) with
chin slightly raised in quiet pride. A magpie wearing a tall gat hat
perches on the tiger's right shoulder with both wings raised in a
soft V cheer gesture. Above them, a small cluster of dancheong-colored
petals and tiny geometric stars floats in the air.

Mid-century modernist geometric reduction + Korean minhwa folk painting.
The tiger holds confident, dignified joy — never goofy, never grinning.
The magpie is expressive but elegant.

[INSERT §0.4 CHARACTER ANCHOR BLOCK HERE]

Pose-specific notes for THIS image:
- Framing: BUST-UP portrait. Head + neck + shoulders + upper chest
  occupy lower 60-70% of canvas. Tiger paws are NOT visible (or only
  the very tops peek at the very bottom edge). NO full-body sitting.
- Tiger head is fully frontal with a slight 3/4 turn (~10°), chin
  slightly lifted (~5° upward tilt), eyes looking directly at the
  viewer.
- Mouth is closed in a calm, confident line — NOT smiling, NOT
  open in a roar.
- Magpie sits on the tiger's right shoulder (viewer's left), 3/4
  turn facing the same direction as the tiger but with the head
  tilted slightly upward. BOTH wings lifted in a small V, about
  30-40° from the body — not fully spread, just an excited gesture.
  Beak slightly open.

Composition layered front to back:

LAYER 1 — Background
- Hanji cream (#FAF6EC) field with one very soft pale-cream to
  ivory (#F4E8D0) gradient halo behind the figures — the single
  permitted gradient.
- Generous negative space — figures occupy lower 60-70% of canvas.

LAYER 2 — Dancheong burst (sky decoration, upper third)
- 8-12 small angular faceted petals scattered in 2 loose clusters,
  alternating between dancheong red (#C24A45), gold (#DFA951), teal
  (#3D9A7F), plum pink (#E8B5BC), and a few flat ivory (#F4E8D0)
  shards. NOT realistic floral shapes — angular faceted geometric
  petals.
- Sizes vary slightly for organic feel; orientation rotation is
  geometric.

LAYER 3 — Tiger + magpie figures (center, bust-up)
- See [§0.4 ANCHOR BLOCK] and pose-specific notes above.

ATMOSPHERIC DETAILS:
- NO ground line — figures float in the hanji negative space.
- NO text, NO numerals, NO Western confetti shapes (triangles,
  ribbons, balloons).
- ONE very small square dancheong-red (#A8332E) seal stamp tucked
  into the bottom right corner with a cream 王 character inside —
  this seal is the ONLY place a literal 王 character may appear in
  the image (inside the seal stamp). On the tiger's forehead, use
  the stripe pattern from the anchor block, NEVER a typed character.

Style discipline (CRITICAL):
- NO outlines on subjects — pure color planes only.
- NO gradients within shapes EXCEPT background halo.
- Subtle hanji paper grain overlay across entire image (including on
  the tiger's body fill).
- Restricted palette: tiger orange #E87830, rust #C25420, charcoal
  #1A1410, magpie cream #F4E8D0, dusty pink #D8B5B5, hanji #FAF6EC +
  #F4E8D0, dancheong red #C24A45 + #A8332E, gold #DFA951, teal
  #3D9A7F, plum pink #E8B5BC, muted brown-pink nose #7E4030.
- High contrast for thumbnail readability at 200px.

Aspect ratio: 1:1 square (1024 × 1024 pixels).

ABSOLUTELY AVOID:
- Western confetti shapes (no triangles, ribbons, balloons).
- Speech bubbles, exclamation marks, or text (the only exception is
  the single 王 character inside the small corner seal stamp).
- Literal Chinese character drawn on the tiger's forehead — use the
  stripe pattern instead.
- More than one magpie or any other animal.
- Trophy, medal, or Western achievement icons.
- Cute / chibi / cub tiger proportions.
- Tiger drawn as full-body sitting (this image is BUST-UP only).

This is the "you finished everything today" celebration screen. Mood:
quiet pride, not loud party.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. The tiger MUST read as the same character as tiger_idle.png
and tiger_celebrate.png — same bust-up framing, same head proportions,
same forehead stripe pattern, same cheek tufts and whiskers. The
magpie MUST read as the same character as magpie_celebrate.png. This
must look like part of the same illustrated set.
```

---

## 2.3 `empty/study_room_waiting.png` — 통계 첫 진입

> **사용처:** Stats 화면, 학습 기록 0개 (앱 처음 깐 직후)
> **무드:** "이제 시작" — 정돈된 책상이 학습자를 기다림. **캐릭터 없음** (anchor 불필요).
> **이 prompt는 v1 그대로 유지** (이미 좋은 결과가 나옴).

```
A square 1:1 editorial illustration. A still life of a Korean scholar's
desk (서안) seen from a gentle high angle, ready for the first lesson.
No people, no animals — just objects, perfectly arranged, waiting.

Mid-century modernist geometric reduction + Korean minhwa folk painting
iconography. The composition feels like a calm "before" moment — quiet
anticipation, not emptiness.

Composition layered front to back:

LAYER 1 — Background
- Hanji cream (#FAF6EC) wall taking upper two thirds.
- One soft sky-to-cream gradient on the upper edge (single permitted).
- Warm walnut wood floor (#8E6646 + #5C4028 shadow facet) in lower
  third, edge slightly tilted in subtle 3/4 perspective.

LAYER 2 — Low scholar's desk (서안)
- Centered, cherry wood (#7E5A3D) with darker shadow facets (#5C4028)
  on inner edges and underside.
- Flat angular plane top, slight 3/4 isometric tilt.
- Two short legs visible.

LAYER 3 — Desk objects (clustered slightly off-center)
- One open hanji book (책): two flat ivory pages (#F4E8D0), cloth-tied
  spine in dancheong red (#C24A45), pages blank (NO text or marks).
- One calligraphy brush (붓) laid diagonally: cherry-wood handle
  (#7E5A3D), gold collar (#DFA951), sharp triangular black bristle
  (#1A1410) pointing toward upper right.
- One inkstone (벼루): flat dark slate rectangle (#2A3340) with circular
  ink pool depression (slightly darker #1A2028).
- One small celadon teacup (#3D9A7F) with thin saucer, darker teal
  shadow facet for volume, placed to the right.
- One small square red seal stamp (#A8332E) tucked beside the book with
  cream 王 character inside.

ATMOSPHERIC DETAILS:
- 2 loose clusters of dancheong color dots: one near the brush, one
  near the teacup.
- One pale moon-shape suggestion in upper background as flat ivory
  (#F4E8D0 at low contrast) — barely visible, like atmosphere.
- NO clock, NO calendar, NO modern objects.

Style discipline (CRITICAL):
- NO outlines — pure flat color planes.
- NO gradients within shapes EXCEPT the background wall wash.
- Subtle hanji paper grain overlay.
- Restricted palette: hanji #FAF6EC, ivory #F4E8D0, walnut #8E6646,
  cherry #7E5A3D, slate #2A3340, celadon #3D9A7F, dancheong red
  #A8332E + #C24A45, gold #DFA951, charcoal #1A1410.
- High silhouette contrast — desk should read clearly at 200px.

Aspect ratio: 1:1 square (1024 × 1024 pixels).

ABSOLUTELY AVOID:
- Any text, numerals, characters on book pages or seal except the
  single 王 inside the seal stamp.
- Modern objects (laptops, pens, sticky notes, smartphones).
- People, animals, chibi figures.
- Multiple seasons or seasonal motifs (this is timeless still life).

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
> **캐릭터 없음** — anchor 불필요. v1 그대로 유지.

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
  background gradient.
- 4-6 tiny dot-stars scattered subtly in the upper area, pale ivory
  (#F4E8D0 at ~40% opacity).
- One muted indigo crescent moon (#1F2E5C) small, upper right.

LAYER 2 — Ground hint (lower 20%)
- Dark earth / stone (#15201A) flat plane at bottom edge, slightly
  textured.
- One very faint hanok roof silhouette in distant background as a
  flat dark slate (#1F2A2E), barely visible against sky.

LAYER 3 — Lantern (center, slightly above middle line)
- Rectangular hanji lantern frame: warm walnut wood structure
  (#8E6646) forming a 3×4 grid of small panes.
- Hanji panel paper backing inside the grid: glowing warm gold
  (#DFA951) — bright but flat, not photorealistic glow.
- A small dancheong red tassel (#C24A45) hanging from the bottom.
- The lantern hangs from a single thin charcoal line going up off
  the top of the canvas (rope).
- Around the lantern: ONE soft radial halo of amber (#DFA951 at low
  opacity) fading outward into the navy sky — second permitted
  gradient EXCEPTION, justifiable as the light glow.

ATMOSPHERIC DETAILS:
- 2-3 tiny dancheong dot accents (red, gold) drifting subtly near
  the lantern — like fireflies.
- NO people, NO animals.
- NO text or numerals.

Style discipline (CRITICAL):
- NO outlines on subjects.
- Permitted gradients (TWO max, justified): sky atmosphere + lantern
  glow halo.
- Subtle hanji paper grain across entire image, even in dark areas.
- Restricted palette: deep navy #0A2E3A + #061F28, dark earth #15201A,
  dark slate #1F2A2E, walnut #8E6646, hanji glow #DFA951, charcoal
  #1A1410, indigo moon #1F2E5C, pale star #F4E8D0, dancheong red
  #C24A45.

Aspect ratio: 1:1 square (1024 × 1024 pixels).

ABSOLUTELY AVOID:
- WiFi icons, no-signal symbols, cloud-strikethrough.
- Photorealistic light rays.
- Cartoon stars (must be flat dots).
- Sad faces, frowny mascots.
- Bright daylight tones.

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
a tall gat hat (갓) standing alone in an open field, turning its head
sideways as if looking for the path back. Gat hat tilted slightly
askew, head turned with one alert eye visible. Lost but not panicked.

Mid-century modernist geometric reduction + Korean minhwa folk painting.
The magpie should feel slightly comic in its lost expression but
remain elegant — never cute, never chibi.

[INSERT §0.4 CHARACTER ANCHOR BLOCK HERE]
(For this image, you may omit the TIGER half of the anchor — no
tiger appears. Keep the MAGPIE half intact.)

Pose-specific notes for THIS image:
- Magpie stands on the ground plane in 3/4 turn, body facing slightly
  to the right, head turned sharply to the left (head about 90° from
  body — the "looking back" lost gesture).
- Beak slightly parted (small dark gap visible).
- Gat hat tilted 8-12° askew from vertical — the "lost" detail —
  but the gold band must still be clearly visible. Hat is still
  fully on the head, NOT falling off.
- One alert eye visible (the left eye in this 3/4 turn), gold-amber
  iris with tiny charcoal pupil placed slightly toward the rear, as
  if looking backward.
- Wings folded but one wing slightly raised (~10°) at the shoulder,
  as if mid-step. Cream wing bar clearly visible on the folded wing.
- Magpie occupies ~60% of canvas height, centered in lower 65% of
  the frame.

Composition layered front to back:

LAYER 1 — Sky background (upper 60%)
- Hanji cream (#FAF6EC) with one soft cream-to-pale-celadon (#D8E5DC)
  gradient on the upper edge (single permitted).
- One small pale plum-pink cloud scroll shape (#E8B5BC at 50% opacity)
  drifting in the upper left.

LAYER 2 — Distant mountains (middle band)
- 3 overlapping mountain silhouettes receding into distance using
  irworobongdo layering: closest peak in mountain teal (#3D9A7F),
  mid in mountain sage (#5C7060), farthest in pale sage (#9BB0A0).
- All as flat angular triangular forms, no detail.

LAYER 3 — Grassy field plane (lower 25%)
- A flat sage-green plane (#5C7060 + #9BB0A0 lighter facet) as the
  ground, gently tilted in subtle 3/4 perspective.
- 2-3 short stylized grass tufts as small angular charcoal shapes
  (#1A1410), clustered near the magpie's feet.

LAYER 4 — Magpie (center foreground)
- See [§0.4 ANCHOR BLOCK] (magpie portion) and pose notes above.
- Cast shadow under the magpie as a soft flat oval in darker sage
  (#5C7060).

ATMOSPHERIC DETAILS:
- 2 plum blossom petals drifting in mid-air to the magpie's right.
- NO other animals.
- NO text, NO question marks, NO arrows.

Style discipline (CRITICAL):
- NO outlines on subjects.
- NO gradients within shapes EXCEPT the sky background.
- Subtle hanji paper grain overlay.
- Restricted palette: hanji #FAF6EC, sky celadon #D8E5DC, mountain
  teal #3D9A7F, sage #5C7060, pale sage #9BB0A0, charcoal #1A1410,
  cream #F4E8D0, dusty pink #D8B5B5, gold #DFA951, plum pink #E8B5BC.
- High silhouette contrast — the magpie must read at 200px.

Aspect ratio: 1:1 square (1024 × 1024 pixels).

ABSOLUTELY AVOID:
- Tear drops, cry faces, sweat drops (anime tropes).
- Question marks or exclamation marks.
- Compass, map, or GPS icons.
- Multiple magpies. Any tiger.
- Cute / chibi proportions.
- Tiny gat hat. Missing gold band.
- Missing cream wing bar on the folded wing.

This is a scenario load failure state. The magpie is the messenger
who couldn't find the message. Mood: gently apologetic, inviting
the user to tap retry.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. The magpie MUST read as the same character as in
magpie_perched.png — same prominent tall gat hat with gold band,
same cream wing bar, same gold-amber eye and beak proportions. This
must look like part of the same illustrated set.
```

---

# Day 3 — 헤더 배너 6장

> **사양 공통:** 1888 × 560 (10:3 와이드), 화면 상단 HanokHeader 슬롯.
> 좌우 대칭이 아닌 **의도된 비대칭** (one side dominant) 권장 — 모바일에서 cropping에 안전.
> 참조 첨부: `assets/illustrations/scenes/cafe.png` (Day 1 anchor) + `hanok/madang(light).png`.
>
> **v2 변경점:** 호랑이/까치 등장 prompt (3.2 achievements, 3.5 listening_hero, 3.6 kkeunmari_hero)에 §0.4 CHARACTER ANCHOR BLOCK 삽입.

## 3.1 `hanok/scholar_room.png` — Settings 헤더

> **사용처:** SettingsScreen 상단
> **무드:** 한 학자가 잠시 자리를 비운 사랑채. 정돈, 차분, "당신의 설정 공간."
> **캐릭터 없음** — anchor 불필요. v1 그대로 유지.

```
A wide 10:3 horizontal editorial illustration of a quiet Korean
hanok scholar's room (사랑채) interior, seen from the front. No
people — just a beautifully arranged study, waiting.

Mid-century modernist geometric reduction + Korean minhwa folk painting.
Premium editorial calm.

Composition layered front to back, wide horizontal frame:

LAYER 1 — Back wall (full width)
- Hanji cream wall (#FAF6EC) covering upper 60%.
- One soft cream-to-ivory atmospheric gradient on the wall (single
  permitted gradient).
- A pair of warm walnut wooden ceiling beams (#7E5A3D) running
  horizontally near the top edge, with darker shadow facet (#5C4028)
  on the underside.

LAYER 2 — Mid ground (running across)
- LEFT THIRD: a tall hanji-paper book shelf — 4-5 small stacked
  hanji books (책) bound with cloth ties, alternating spines in
  dancheong red (#C24A45), gold (#DFA951), and ivory (#F4E8D0).
- CENTER THIRD: a low scholar's desk (서안) in cherry wood (#7E5A3D),
  with one open hanji book (blank pages), a calligraphy brush laid
  diagonally, a small inkstone (#2A3340), and a tiny red seal stamp
  (#A8332E) with 王 character.
- RIGHT THIRD: a paper lattice door (창호지문) in ivory cream
  (#FFFCF2) with walnut frame (#7E5A3D) creating a grid pattern,
  one small plum branch (charcoal #1A1410 stem with 3-4 pale pink
  petals #E8B5BC) silhouetted against it.

LAYER 3 — Foreground floor
- Warm walnut floor plane (#8E6646 + #5C4028 shadow facet) covering
  lower 25% in subtle 3/4 perspective.

ATMOSPHERIC DETAILS:
- 2 loose clusters of dancheong color dots: one near the books, one
  near the brush.
- One small celadon teacup (#3D9A7F) on the desk.
- NO people, NO animals.
- NO text on book spines or seal except the single 王 inside the seal.

Style discipline (CRITICAL):
- NO outlines on subjects.
- NO gradients within shapes EXCEPT wall background.
- Subtle hanji paper grain across entire image.
- Restricted palette: hanji #FAF6EC + #F4E8D0 + #FFFCF2, walnut
  #8E6646 + #7E5A3D + #5C4028, dancheong red #C24A45 + #A8332E,
  gold #DFA951, charcoal #1A1410, celadon #3D9A7F, slate #2A3340,
  plum pink #E8B5BC.
- Wide composition: read clearly edge to edge, no element exceeds
  30% of frame width.

Aspect ratio: 10:3 horizontal wide (1888 × 560 pixels).

ABSOLUTELY AVOID:
- Modern objects (laptop, lamp with cord, keyboard).
- Text on book covers or paper.
- People or animals.
- Symmetrical composition (must feel like a real room, asymmetric).
- Western bookshelf or library aesthetic.

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
> **v2 변경:** 호랑이가 small / chibi로 그려지지 않도록 §0.4 anchor 삽입 + bust-up이 아닌 **upper-body framing** (가슴 위) 명시.

```
A wide 10:3 horizontal editorial illustration. A Korean guardian tiger
standing in a stately upper-body framing under the curved eaves of
a hanok roof, with a small magpie perched on his shoulder. Above
their heads, a dancheong band stretches across the eaves with small
geometric stars indicating achievement. Distant mountain silhouettes
behind. The atmosphere is one of quiet honor.

Mid-century modernist geometric reduction + Korean minhwa folk painting.
Tiger must be dignified adult guardian energy — NOT cute, NOT chibi,
NOT cub-proportioned.

[INSERT §0.4 CHARACTER ANCHOR BLOCK HERE]

Pose-specific notes for THIS image:
- Tiger framing: UPPER-BODY (head + neck + shoulders + upper chest
  fully visible; paws and lower legs cropped at the bottom edge of
  the frame). Tiger occupies roughly the CENTER 35-40% of the frame
  width with the head positioned slightly above the vertical center.
- Tiger head is fully frontal with slight 3/4 turn (~10°), chin
  level, eyes looking directly at the viewer with calm confident
  gaze.
- Mouth closed in a calm line.
- Magpie on the tiger's right shoulder (viewer's left), 3/4 turn
  facing forward, head slightly tilted. Wings folded. Hat brim
  ~ 6-8% of frame width (proportionally smaller than tiger but
  still clearly prominent on the magpie's head).
- The 3 small dancheong-gold (#DFA951) flat star-petal achievement
  markers float above the tiger's head, in the dancheong band area.

Composition layered front to back, wide horizontal:

LAYER 1 — Sky and distant mountains (upper 55%)
- Hanji cream sky (#FAF6EC) at top with one soft pale-celadon
  (#D8E5DC) gradient on the upper edge (single permitted).
- 3 distant mountain silhouettes spanning the width, irworobongdo
  receding layers: closest in mountain teal (#3D9A7F), mid in sage
  (#5C7060), farthest in pale sage (#9BB0A0).

LAYER 2 — Hanok eaves (upper-middle band, dominant horizontal)
- Curved tile roof (기와지붕) with upturned eave horns (처마끝) on
  both far left and far right.
- Dark slate-charcoal primary (#2A3340) with deeper shadow facet
  (#1A2028) on the underside.
- Across the eave underside: a dancheong band of alternating
  geometric squares — teal (#3D9A7F) base with small red (#C24A45),
  gold (#DFA951), and ivory (#F4E8D0) squares; inside several squares
  small lotus or chrysanthemum motifs.
- Row of small rafter ends (서까래) — warm walnut rectangles
  (#7E5A3D) following the eave curve like dark teeth.

LAYER 3 — Tiger + magpie (center, upper-body framing)
- See [§0.4 ANCHOR BLOCK] and pose notes above.

LAYER 4 — Ground / stone base (lower 12%)
- Stone gray foundation plane (#8B8478) at the bottom edge of the
  frame.

ATMOSPHERIC DETAILS:
- 2 loose clusters of dancheong color dots in the upper sky area.
- NO text, NO numbers.
- NO trophy, medal, or modern achievement icons.

Style discipline (CRITICAL):
- NO outlines on subjects.
- NO gradients within shapes EXCEPT sky background.
- Subtle hanji paper grain overlay.
- Restricted palette: tiger orange #E87830, rust #C25420, charcoal
  #1A1410, cream #F4E8D0, hanji #FAF6EC, sky celadon #D8E5DC,
  mountain teal #3D9A7F, sage #5C7060 + #9BB0A0, slate #2A3340 +
  #1A2028, walnut #7E5A3D, gold #DFA951, dancheong red #C24A45,
  stone gray #8B8478, muted brown-pink nose #7E4030.
- Wide composition: tiger is hero, but should not exceed 35% of
  frame width — eaves and mountains share the space.

Aspect ratio: 10:3 horizontal wide (1888 × 560 pixels).

ABSOLUTELY AVOID:
- Cute / chibi / cub tiger.
- Tiger drawn small with full body visible inside the frame (this
  is upper-body framing, paws cropped at bottom).
- Literal Chinese character 王 drawn as typography on the forehead.
- Tiger in profile or running pose (must be near-frontal, stately).
- Trophies, medals, ribbons, Western awards.
- Text or numerals.
- Multiple magpies or other animals.
- Cartoon stars (must be flat geometric petals).
- Tiny gat hat. Missing gold band. Missing cream wing bar.

This is the Stats screen header — implies "your honor wall." Mood:
quiet pride, ceremonial calm.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. The tiger MUST read as the same character as in
tiger_idle.png and tiger_celebrate.png — same head proportions,
same stripe pattern, same cheek tufts, same eyes. The magpie MUST
read as the same character as in magpie_perched.png. This must
look like part of the same illustrated set.
```

---

## 3.3 `hanok/study_classroom.png` — Vocab 헤더

> **사용처:** VocabScreen 상단 (현재 study.png 사용 중 → 자동 교체)
> **무드:** 서당(전통 학당) 분위기. 여러 학생이 앉았던 자리. **사람 없음.**
> **캐릭터 없음** — anchor 불필요. v1 그대로 유지.

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
  gradient (single permitted) on the upper edge.
- One hanging scroll (족자) centered on the wall: thin walnut frame
  (#7E5A3D) at top and bottom, ivory paper field (#F4E8D0), and an
  abstract dark charcoal angular composition inside (#1A1410) —
  NOT actual calligraphy, just geometric ink shapes suggesting a
  brushed character.
- A single small red seal stamp shape (#A8332E) in the lower-right
  corner of the scroll.

LAYER 2 — Ceiling beam (across the top)
- One warm walnut wood beam (#7E5A3D) running horizontally just
  below the very top, with darker shadow facet (#5C4028) underneath.

LAYER 3 — Three scholar's desks (mid-foreground, in a row)
- Three identical low desks (서안) in cherry wood (#7E5A3D) with
  shadow facets (#5C4028) on the inner edges, placed evenly across
  the lower-middle band of the frame.
- Each desk has on top: one open hanji book (ivory pages #F4E8D0,
  cloth-tied spine in alternating dancheong colors — leftmost
  red #C24A45, center gold #DFA951, rightmost teal #3D9A7F),
  and one calligraphy brush laid diagonally (cherry wood handle
  #7E5A3D, gold collar #DFA951, sharp triangular black bristle
  #1A1410).
- The desks should not be perfectly aligned — subtle variation in
  angle of brushes for organic feel.

LAYER 4 — Floor (lower 25%)
- Warm walnut wooden floor (#8E6646) with darker shadow facet
  (#5C4028) showing the floorboard pattern as 2-3 parallel lines.

ATMOSPHERIC DETAILS:
- 2 loose clusters of dancheong color dots near the scroll and near
  the center desk.
- One tiny celadon teacup (#3D9A7F) on the right desk.
- NO people, NO animals.
- NO text on book pages, scroll, or seal.

Style discipline (CRITICAL):
- NO outlines.
- NO gradients within shapes EXCEPT wall background.
- Subtle hanji paper grain across image.
- Restricted palette: hanji #FAF6EC + #F4E8D0, walnut #8E6646 +
  #7E5A3D + #5C4028, cherry #7E5A3D, dancheong red #C24A45 +
  #A8332E, gold #DFA951, teal #3D9A7F, charcoal #1A1410.
- Wide composition: three desks form a horizontal rhythm.

Aspect ratio: 10:3 horizontal wide (1888 × 560 pixels).

ABSOLUTELY AVOID:
- Modern classroom elements (chalkboard, chairs, posters).
- Actual readable Hangul or Hanja text anywhere.
- People, students, teacher.
- Perfectly symmetric arrangement (must feel organic).
- Western library or schoolroom aesthetic.

This is the Vocab screen header — implies "the classroom is open,
choose your seat." Mood: quiet invitation.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. This must look like part of the same illustrated set.
```

---

## 3.4 `hanok/study_scholar.png` — Grammar 헤더

> **사용처:** GrammarScreen 상단
> **무드:** 한 학자의 개인 책상 클로즈업. 깊이 공부하는 자리. **사람 없음.**
> **캐릭터 없음** — anchor 불필요. v1 그대로 유지.

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
  wood grain hint) covering the entire frame as the surface plane.
- One very soft pale-cream atmospheric wash (#F4E8D0 at low opacity)
  in the upper-left corner suggesting window light (single permitted
  gradient).

LAYER 2 — Open hanji book (LEFT 55% of frame)
- One large open hanji book lying flat: two ivory pages (#F4E8D0)
  spread out, cloth-tied spine in dancheong red (#C24A45) running
  vertically in the center.
- Pages are BLANK — no text or markings, just clean ivory planes.
- Slight curve at the spine to suggest paper thickness.

LAYER 3 — Tools cluster (RIGHT 35% of frame)
- One calligraphy brush (붓) laid diagonally on the desk: cherry wood
  handle (#7E5A3D), gold collar (#DFA951), sharp triangular black
  bristle (#1A1410) pointing toward upper right, tip resting on the
  inkstone.
- One inkstone (벼루): flat dark slate rectangle (#2A3340) with a
  circular ink pool depression (slightly darker #1A2028), placed to
  the right of the book.
- One ink stick (먹): long hexagonal black stick (#1A1410) with a
  small gold cap (#DFA951), laid beside the inkstone.
- One small red seal stamp (#A8332E) with cream 王 character inside,
  placed beside the ink stick.
- One small celadon teacup (#3D9A7F) with thin saucer and darker
  shadow facet, placed near the upper-right corner.

LAYER 4 — Atmospheric accents
- 2 loose clusters of dancheong dots: one near the brush tip, one
  near the teacup.
- One small plum blossom petal (#E8B5BC) drifting onto the book page.
- NO people, NO animals.

Style discipline (CRITICAL):
- NO outlines on objects.
- NO gradients within shapes EXCEPT background wash.
- Subtle hanji paper grain across the image, including on book pages.
- Restricted palette: walnut #8E6646 + #5C4028, ivory #F4E8D0,
  cherry #7E5A3D, slate #2A3340 + #1A2028, charcoal #1A1410, gold
  #DFA951, dancheong red #C24A45 + #A8332E, celadon #3D9A7F, plum
  pink #E8B5BC.
- Wide composition: book dominates left, tools cluster right,
  negative space on top edge.

Aspect ratio: 10:3 horizontal wide (1888 × 560 pixels).

ABSOLUTELY AVOID:
- Text on book pages or scroll (only the single 王 inside the seal).
- Modern writing tools (pens, pencils, markers).
- People, hands, animals.
- Western desk objects (notebook, ruler, calculator).

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
> **v2 변경:** 까치 anchor 삽입 + 까치가 헤더 안에서 작게 보이지만 hat 비율은 유지.

```
A wide 10:3 horizontal editorial illustration. The edge of a Korean
hanok porch (마루) on the RIGHT third of the frame, with a single
bronze wind chime (풍경) hanging from the eave, slightly swayed by
breeze. On the porch beam beside the chime, a small magpie wearing
a tall gat hat tilts its head as if listening to the sound. Beyond
the porch on the LEFT two-thirds: distant sage mountains and a soft
celadon sky.

Mid-century modernist geometric reduction + Korean minhwa folk painting.
The image must convey sound visually — through subtle motion lines
and the magpie's listening posture.

[INSERT §0.4 CHARACTER ANCHOR BLOCK HERE]
(For this image, you may omit the TIGER half of the anchor — no
tiger appears. Keep the MAGPIE half intact. Even though the magpie
appears small inside this wide frame, ALL magpie character details
— prominent gat with gold band, cream wing bar, gold-amber beak and
eye — must be present and readable.)

Pose-specific notes for THIS image:
- Magpie body in 3/4 turn facing slightly to the left (toward the
  chime), head tilted up and to the right toward the bell.
- Magpie occupies ~ 10-12% of frame width, placed on the porch
  beam just to the LEFT of the wind chime. Even at this small
  size, the gat hat (with gold band), the cream wing bar, and the
  gold-amber beak must all be clearly drawn — do not simplify away
  these identifying details.

Composition layered front to back, wide horizontal:

LAYER 1 — Sky (upper 55%)
- Pale celadon sky (#D8E5DC) at top with one soft cream-to-celadon
  gradient (single permitted).

LAYER 2 — Distant mountains (middle band)
- 3 overlapping silhouettes: closest in mountain teal (#3D9A7F),
  mid in sage (#5C7060), farthest in pale sage (#9BB0A0).
- All flat angular triangles, asymmetric, mostly LEFT half of frame.

LAYER 3 — Hanok eave + porch (RIGHT third)
- Curved tile roof eave (기와지붕) coming in from the right edge,
  upturned horn (처마끝), dark slate-charcoal primary (#2A3340)
  with darker shadow facet (#1A2028).
- Below the eave: a dancheong band — teal (#3D9A7F) base with
  alternating red (#C24A45) and gold (#DFA951) small squares.
- Warm walnut wooden porch beam (#8E6646 + #5C4028 shadow facet)
  running horizontally as the porch surface, ending mid-frame.

LAYER 4 — Wind chime (풍경) (focal point, hanging from eave)
- Bronze bell shaped like a small inverted lotus bud in warm
  bronze tone (#A8732C — derived from gold #DFA951 + a darker
  rust facet), hanging from a thin charcoal line attached to the
  eave.
- A fish-shaped pendant in walnut tone (#7E5A3D) suspended below
  the bell with a thin tassel.
- 2-3 subtle curved motion lines around the chime (very thin
  ivory #F4E8D0 strokes, almost like brush flicks) suggesting
  gentle sway — these are the ONLY line elements in the image.

LAYER 5 — Magpie listening (on porch beam, beside chime)
- See [§0.4 ANCHOR BLOCK] (magpie portion) and pose notes above.

ATMOSPHERIC DETAILS:
- 2 loose clusters of dancheong dots: one near the dancheong band,
  one in the sky.
- NO other animals.
- NO text or notation.
- NO sound waves drawn as visible rings.

Style discipline (CRITICAL):
- NO outlines on subjects (the motion lines around the chime are
  an intentional exception — flat brush strokes, not outlines on
  objects).
- NO gradients within shapes EXCEPT sky.
- Subtle hanji paper grain across image.
- Restricted palette: sky celadon #D8E5DC, mountain teal #3D9A7F,
  sage #5C7060 + #9BB0A0, slate #2A3340 + #1A2028, walnut #8E6646
  + #7E5A3D + #5C4028, dancheong red #C24A45, gold #DFA951, bronze
  #A8732C, charcoal #1A1410, magpie cream #F4E8D0.
- Wide composition: porch/chime/magpie cluster on right (35-40%),
  sky and mountains stretch left.

Aspect ratio: 10:3 horizontal wide (1888 × 560 pixels).

ABSOLUTELY AVOID:
- Western musical notation, treble clefs, headphones.
- Visible sound waves as circles or rings.
- Speech bubbles.
- Multiple magpies, tigers.
- Tiny / missing gat hat. Missing gold band on the gat.
- Missing cream wing bar on the magpie's folded wing.
- Yellow or orange beak (must be gold-amber).
- Text.

This is the Listening mode header — implies "lean in and hear."
Mood: contemplative, gentle attention.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. The magpie — even though small inside this wide frame —
MUST read as the same character as in magpie_perched.png. This
must look like part of the same illustrated set.
```

---

## 3.6 `hanok/kkeunmari_hero.png` — 끝말잇기 헤더

> **사용처:** KkeunmariScreen 상단
> **무드:** 호랑이와 까치가 마루에 마주 앉아 한지 두루마리를 사이에 두고 단어를 잇는 장면.
> **v2 변경:** 두 캐릭터가 작아 보일 수밖에 없는 wide 헤더이지만, anchor를 명시해 캐릭터 식별성을 잃지 않도록.

```
A wide 10:3 horizontal editorial illustration. A Korean guardian
tiger sits on the LEFT side of a wide hanok wooden floor (마루),
facing right. A magpie wearing a tall gat hat stands on the RIGHT
side, facing left. Between them lies a long unrolled hanji paper
scroll, on which a row of small dancheong-colored dots runs
horizontally — this is the visual metaphor for a word chain. The
tiger and magpie are mid-exchange, dignified, like two calligraphers
playing a game.

Mid-century modernist geometric reduction + Korean minhwa folk painting.
Tiger remains adult dignified guardian energy. Magpie stays elegant.

[INSERT §0.4 CHARACTER ANCHOR BLOCK HERE]

Pose-specific notes for THIS image:
- TIGER framing exception: this image shows the tiger in FULL-BODY
  seated 3/4 turn (similar to tiger_sad.png reference, but with
  upright posture and calm engaged expression). Tiger occupies LEFT
  ~25-30% of frame width. Front paws planted on the floor, hind
  legs folded under, tail curled behind. Head turned slightly to
  the right toward the scroll and magpie. Mouth closed, eyes calm
  and engaged. Despite the full-body framing, the head MUST still
  retain its iconic proportions — large head with prominent cheek
  tufts, forehead stripe pattern, almond gold eyes.
- MAGPIE: standing 3/4 turn facing left (toward the tiger), about
  20-25% of the tiger's height. Wings folded. Hat with gold band
  clearly visible. Cream wing bar visible on folded wing.
- SCROLL: ivory hanji paper (#F4E8D0) unrolled across the floor
  between them, occupying the CENTER ~50% of frame width.

Composition layered front to back, wide horizontal:

LAYER 1 — Background (upper 60%)
- Hanji cream wall (#FAF6EC) at top.
- One soft cream-to-ivory atmospheric gradient on the upper edge
  (single permitted).
- Two warm walnut wood beams (#7E5A3D) running horizontally near
  the top, with shadow facet (#5C4028) underneath.

LAYER 2 — Mid ground decoration (sky area, sparse)
- 2-3 small dancheong dot accents in the upper sky area.
- ONE small plum branch (charcoal stem #1A1410 with 2 pale pink
  petals #E8B5BC) silhouetted in the upper LEFT corner.

LAYER 3 — Hanok wooden floor (lower 30%)
- Warm walnut wood plank floor (#8E6646 + #5C4028 shadow facet for
  plank lines, 3-4 parallel horizontal lines visible) covering the
  lower band.

LAYER 4 — Unrolled hanji scroll (across the floor, center band)
- A long horizontal hanji paper scroll (ivory #F4E8D0) unrolled
  across the floor between the tiger and magpie, with the two ends
  curling slightly upward at left and right.
- On the scroll: a horizontal row of 5-7 small dancheong dots
  alternating in colors — red (#C24A45), gold (#DFA951), teal
  (#3D9A7F), forming a chain visual metaphor.
- Each dot is angular and faceted, not perfectly circular.
- Connecting the dots: subtle thin charcoal lines (#1A1410) like
  a brushed connector — VERY subtle, almost suggested.

LAYER 5 — Tiger (LEFT, full-body seated 3/4 turn facing right)
- See [§0.4 ANCHOR BLOCK] and pose notes above.

LAYER 6 — Magpie (RIGHT, standing 3/4 turn facing left)
- See [§0.4 ANCHOR BLOCK] and pose notes above.

ATMOSPHERIC DETAILS:
- The scroll, tiger, and magpie roughly form a horizontal triangle
  pointing toward the center, with the chain of dots as the visual
  focal line.
- NO text or Hangul on the scroll.
- NO other animals.
- The mood is playful but respectful — like two old friends.

Style discipline (CRITICAL):
- NO outlines on subjects.
- NO gradients within shapes EXCEPT background wash.
- Subtle hanji paper grain across image.
- Restricted palette: hanji #FAF6EC + #F4E8D0, walnut #8E6646 +
  #7E5A3D + #5C4028, tiger orange #E87830 + #C25420, charcoal
  #1A1410, cream #F4E8D0, dusty pink #D8B5B5, gold #DFA951,
  dancheong red #C24A45, teal #3D9A7F, plum pink #E8B5BC, muted
  brown-pink nose #7E4030.
- Wide composition: tiger LEFT 25-30%, magpie RIGHT 12-15%, scroll
  CENTER 50%.

Aspect ratio: 10:3 horizontal wide (1888 × 560 pixels).

ABSOLUTELY AVOID:
- Cute / chibi / cub tiger. Tiger with overly small head relative
  to its body — even in full body, the head must remain large and
  dignified (head:torso ratio approximately 1:1.5).
- Literal Chinese character 王 typography on the tiger's forehead.
- Tiny gat hat. Missing gold band on the gat. Missing cream wing
  bar on the magpie's folded wing.
- Tiger and magpie facing the viewer (must face each other across
  the scroll).
- Speech bubbles, thought bubbles, comic effects.
- Hangul or any text on scroll.
- Multiple tigers, multiple magpies.
- Tiger looking aggressive (should look engaged, calm).
- Western board game elements (dice, pieces, cards).

This is the word-chain (끝말잇기) game screen header — implies
"a calligraphy game between friends." Mood: focused play.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. Both characters MUST read as the same characters as in the
existing mascot/ assets — even though the framing shows them in
full body inside a wide scene, the head proportions, stripe pattern,
cheek tufts, hat with gold band, and cream wing bar must all be
recognizable. This must look like part of the same illustrated set.
```

---

# Day 4 — 마스코트 추가 포즈 3장 (**v2.1 — FULL-BODY 재개정**)

> **사양 공통:** 1024 × 1024 정사각, **투명 배경 (PNG-32)**, 캐릭터 단독.
> 참조 첨부 (호랑이): **`mascot/tiger_sad.png` (1st anchor — full-body 어른 호랑이 자세)** + `mascot/tiger_idle.png` (얼굴 디테일 anchor) + `mascot/tiger_celebrate.png` (얼굴 디테일 anchor).
> 참조 첨부 (까치): `mascot/magpie_perched.png` + `mascot/magpie_celebrate.png`.
> 기존 mascot/ 시리즈와 **얼굴 디테일·색감·면 분할 100% 동일** + **full-body 자세는 `tiger_sad.png`와 동일**해야 함.
>
> **v2.1 핵심 변경 (2026-05-28 사용자 피드백 반영):**
> 1. **Day 4 마스코트 solo 포즈를 모두 FULL-BODY로 변경.** 기존 v2의 bust-up portrait 방향성 폐기. 이유: `tiger_sad.png`/`magpie_celebrate.png`가 이미 full-body라 set 안에 precedent 있음 + dignified guardian energy가 full-body에서 훨씬 잘 살아남 + 호랑이가 작아져도 thumbnail에서 호랑이로 충분히 읽힘.
> 2. **1st reference를 `tiger_sad.png`로 교체.** 어른 호랑이 sitting full-body 자세의 가장 명확한 anchor.
> 3. §0.4 CHARACTER ANCHOR BLOCK 전체 삽입 (v2와 동일).
> 4. "王 character on forehead" → "stripe pattern that SUGGESTS 王, never literal Chinese character" 로 교정 (v2와 동일).
> 5. 강화된 OUTLINE RULE + TIGER EYE RULE + MAGPIE EYE RULE (v2.1 §0.4에 이미 반영).

## 4.1 `mascot/tiger_thinking.png` — 호랑이 생각 중

> **사용처:** Chosung 라운드 <50% 정확도 / 시나리오 NPC "minsu" 사고 중
> **포즈 (v2.1):** **FULL-BODY seated 3/4 turn** (tiger_sad.png 자세 기준) + 한 앞발이 가슴 앞으로 들려 턱 아래에 가볍게 닿는 사색 포즈. 머리 디테일은 tiger_idle.png/tiger_celebrate.png와 동일 (얼굴 면 분할, cheek tufts, gold-amber eyes, stripe 패턴).

```
A square 1:1 character mascot illustration with TRANSPARENT BACKGROUND.
A Korean guardian tiger sitting in a full-body 3/4 turn pose (matching
exactly the body proportions and sitting posture of the tiger_sad.png
reference: head + chest + visible front paws + folded hind legs + tail
all inside the canvas), but with the RIGHT front paw raised across
the chest, the back of the paw resting loosely just under the chin —
a thoughtful "hmm" gesture. Eyes looking slightly UP and to the SIDE
(toward the upper right of the frame), brow gently furrowed in
contemplation but NOT frowning. Dignified, contemplative — a wise
adult guardian pondering.

Mid-century modernist geometric reduction + Korean minhwa folk painting.
MUST match the EXACT body proportions, sitting posture, hind-leg
fold, and tail position of tiger_sad.png reference. MUST match the
EXACT head construction (cheek tufts, whisker slivers, stripe
pattern, eye style, nose shape, ear shape) of tiger_idle.png and
tiger_celebrate.png references so this pose drops into the same
mascot rotation seamlessly.

[INSERT §0.4 CHARACTER ANCHOR BLOCK HERE]
(Use the TIGER portion only — no magpie in this image.)

Pose-specific notes for THIS image (CRITICAL — read carefully):

FRAMING (FULL-BODY — this is v2.1 change from v2's bust-up):
- FULL-BODY seated 3/4 turn. The entire tiger fits inside the canvas
  with negative space around all sides — head visible at top, tail
  curling out near the lower edge, neither cropped.
- Tiger silhouette occupies ~ 70-80% of canvas height, centered
  horizontally, with feet/tail base resting at roughly 90% canvas
  height (small empty space below for visual breathing room — but
  NO drawn ground line, NO drawn shadow).
- Match the body posture, hind-leg fold, and tail curve of
  tiger_sad.png reference EXACTLY.

POSE:
- Body in 3/4 turn — body facing slightly to the right of viewer (so
  the viewer sees more of the tiger's right side), hindquarters
  folded under, tail curling around to the right side and ending
  with the tip visible.
- LEFT front paw (viewer's right side of frame) planted on the
  ground, supporting weight.
- RIGHT front paw (viewer's left side of frame) RAISED across the
  chest, paw pads visible in tiger cream (#F4E8D0), back of the paw
  loosely touching just under the chin. Paw is angular and faceted,
  showing 3 short charcoal toe slashes. The paw rests there gently,
  does NOT press hard.
- Head turned ~ 10-15° upward and to the LEFT (viewer's right), with
  the gaze of the eyes shifted UP and to the upper RIGHT corner of
  the canvas — the classic "looking up while thinking" eye position.
- Brow facets slightly drawn together (the two charcoal eyebrow
  slashes angle inward toward the center forehead a touch more than
  in tiger_idle), giving a subtle furrow — but the rest of the face
  stays calm. NOT a frown, NOT a glare.
- Mouth closed in a soft neutral angular V (no smile, no open mouth).
- Cheek tufts and whiskers fully visible on both sides of the muzzle
  — same density and shape as in tiger_idle.png reference.

Composition (character only — NO background):
- See [§0.4 ANCHOR BLOCK] (tiger portion).

ATMOSPHERIC DETAILS:
- NO ground line, NO drawn shadow underneath (the figure floats in
  transparent space — the implied ground is just where the planted
  paw rests).
- NO thought bubble, NO question marks, NO speech indicators.
- Transparent PNG-32 background — alpha channel only behind the
  character.

Style discipline (CRITICAL — must match mascot set):
- (See OUTLINE RULE and TIGER EYE RULE in §0.4 anchor block — these
  are the #1 and #2 failure modes; read them again before drawing.)
- NO smooth gradients within shapes.
- Subtle hanji paper grain texture overlay applied ONLY to the
  character body fill.
- Restricted palette: tiger orange #E87830, rust #C25420, charcoal
  #1A1410, cream #F4E8D0, dusty pink #D8B5B5, gold #DFA951, muted
  brown-pink nose #7E4030.

Aspect ratio: 1:1 square (1024 × 1024 pixels), transparent PNG-32.

ABSOLUTELY AVOID:
- ✗ Bust-up portrait framing (head + shoulders only). This is FULL-
  BODY — the entire seated tiger must fit inside the canvas including
  hind legs and tail.
- ✗ Chibi, cub, kawaii, or young-cat proportions. Head-to-torso ratio
  must be approximately 1:1.5 — head dignified-large but body clearly
  that of an adult tiger.
- ✗ Literal Chinese character 王 drawn as typography on the forehead.
  Use the stripe pattern from the anchor block instead.
- ✗ Black outlines anywhere on the tiger — around the body, stripes,
  cheek tufts, chest V, paws, or any plane edge. Reference look:
  tiger_sad.png has zero outlines between any color planes.
- ✗ Eyes drawn as gold/yellow circles with a round black pupil inside
  white sclera. The tiger eye is solid gold-amber filling the entire
  almond shape, no pupil dot, no white sclera (see TIGER EYE RULE in
  §0.4).
- ✗ Missing or sparse cheek tufts. The cream cheek tufts are part
  of the silhouette identity and must be prominent.
- ✗ Smile mouth or open mouth. Mouth is a small angular closed V.
- ✗ Thought bubble, question mark, exclamation, glow effects.
- ✗ Background of any kind. Must be fully transparent PNG-32.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, scale, head construction (cheek tufts, whisker
arrangement, chest V, stripe pattern, gold-amber eyes), body
posture (sitting 3/4 turn, hindquarters folded, tail curling), and
NO-outline / NO-pupil style of the attached reference mascot images
EXACTLY. This must look like the same adult tiger as in
tiger_sad.png + tiger_idle.png + tiger_celebrate.png, just in a
new "thinking" pose with one raised paw under the chin and an
upward-sideways gaze. The user must not notice this is a different
image file — it should feel like the same character expressing a
different emotion.
```

---

## 4.2 `mascot/tiger_sleepy.png` — 호랑이 졸음

> **사용처:** "오늘 마지막 카드", 푸쉬 알림, "쉴 시간" 안내
> **포즈 (v2.1):** **FULL-BODY seated 3/4 turn** (tiger_sad.png 자세 기준), 단 표정만 sleepy — 눈은 거의 감기고 입은 살짝 벌어진 half-yawn, 한쪽 귀만 살짝 처짐. 누운 자세 X (그건 sleeping_tiger_b2가 담당).

```
A square 1:1 character mascot illustration with TRANSPARENT BACKGROUND.
A Korean guardian tiger sitting in a full-body 3/4 turn pose (matching
exactly the body proportions and sitting posture of the tiger_sad.png
reference: head + chest + visible front paws planted on ground +
folded hind legs + tail all inside the canvas), but with the eyes
nearly closed — drawn as two gentle downward-curving charcoal crescent
lines, almost smiling shut — and the mouth slightly parted in a quiet
half-yawn (just a small dark angular crescent opening, NO teeth, NO
tongue). The LEFT ear (from viewer perspective) droops slightly more
than the other, tilting ~ 8° outward and downward. The tiger is NOT
asleep, NOT lying down — sitting upright, drowsy, on the edge of
yawning.

Mid-century modernist geometric reduction + Korean minhwa folk painting.
MUST match the EXACT body proportions, sitting posture, hind-leg
fold, and tail position of tiger_sad.png reference. MUST match the
EXACT head construction (cheek tufts, whisker slivers, stripe
pattern, nose shape, ear shape) of tiger_idle.png so this pose drops
into the mascot rotation seamlessly.

[INSERT §0.4 CHARACTER ANCHOR BLOCK HERE]
(Use the TIGER portion only.)

Pose-specific notes for THIS image:

FRAMING (FULL-BODY):
- FULL-BODY seated 3/4 turn, identical body posture and canvas
  occupancy as tiger_sad.png reference — head visible at top, both
  front paws planted, hind legs folded under, tail curling out to
  one side.
- Tiger silhouette ~ 70-80% of canvas height, centered. NO ground
  line, NO drawn shadow.

EXPRESSION (the only difference from tiger_sad / tiger_idle):
- Eyes: drawn as two charcoal (#1A1410) downward-curving crescent
  lines, like gentle smile-shaped closed eyelids. NO almond gold
  iris showing, NO pupil — just the curved closed-eye line on each
  side. The crescents are subtle, not exaggerated comic.
- Mouth: small dark angular crescent (#1A1410) at the center of the
  muzzle, slightly parted — this is the half-yawn. Width ~ 30% of
  the muzzle width. NO visible teeth, NO tongue, NO Western "O" shape.
- Left ear (viewer's perspective): tilts ~ 8° outward and downward
  from the head crown. Subtle droop. The other ear stays upright.
- Body posture is calm and relaxed — shoulders slightly slumped, but
  back is still upright. NOT slouching forward.

EVERYTHING ELSE matches the references EXACTLY:
- Forehead stripe pattern (the 王 suggestion — 4-5 angular stripes,
  never literal Chinese typography).
- Cheek tufts and whiskers.
- Chest cream V.
- Body stripes and shadow facets.
- Hind-leg fold and tail curl matching tiger_sad.png.

ATMOSPHERIC DETAILS:
- NO Z's, NO sleep symbols, NO speech bubbles, NO halos.
- NO pillow, NO blanket.
- Transparent PNG-32 background. Drowsiness is conveyed PURELY by
  the eye crescents, the half-yawn mouth, the slight ear droop, and
  the relaxed shoulder line.

Style discipline (CRITICAL — must match mascot set):
- (See OUTLINE RULE and TIGER EYE RULE in §0.4 anchor block —
  although the eyes are closed here so the gold-iris rule doesn't
  apply, the no-outline rule is still in full force.)
- NO smooth gradients within shapes.
- Subtle hanji paper grain on character body fill only.
- Restricted palette: same as tiger_idle and tiger_sad (tiger orange
  #E87830, rust #C25420, charcoal #1A1410, cream #F4E8D0, dusty
  pink #D8B5B5, gold #DFA951, muted brown-pink nose #7E4030).

Aspect ratio: 1:1 square (1024 × 1024 pixels), transparent PNG-32.

ABSOLUTELY AVOID:
- ✗ Lying down / curled up sleeping pose (that's the
  sleeping_tiger_b2 asset — this is the drowsy-while-SITTING variant).
- ✗ Bust-up portrait framing. This is FULL-BODY seated.
- ✗ Z sleep symbols, speech bubbles, halos around the head.
- ✗ Chibi / cub / kawaii proportions.
- ✗ Literal Chinese character 王 typography on the forehead.
- ✗ Both ears drooping the same. Only the LEFT ear droops slightly.
- ✗ Black outlines anywhere on the tiger (see OUTLINE RULE in §0.4).
- ✗ Background or drawn shadow underneath.
- ✗ Fully cartoon U-shaped smile mouth.
- ✗ Wide open mouth showing teeth.

This is the "you've worked enough today, rest" prompt. The tiger
is drowsy but still upright, awake, and dignified.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, scale, head construction (cheek tufts, whisker
arrangement, chest V, stripe pattern), body posture (sitting 3/4
turn, hindquarters folded, tail curling — matching tiger_sad.png),
and NO-outline style of the attached reference mascot images
EXACTLY. This must look like the SAME adult tiger as in
tiger_sad.png + tiger_idle.png — just with a drowsy expression
(closed-eye crescents, half-yawn mouth, slightly drooping left ear).
Everything except those three small expression changes must be
identical to the references.
```

---

## 4.3 `mascot/magpie_worry.png` — 까치 걱정

> **사용처:** 오답 / 동기화 실패 / 끝말잇기 dead_end
> **포즈 정정 (v2):** magpie_perched와 동일 framing + 양 날개를 살짝 들어올리고 갓이 약간 askew, 부리 살짝 벌림.

```
A square 1:1 character mascot illustration with TRANSPARENT BACKGROUND.
A Korean magpie wearing a tall gat hat, standing in 3/4 turn (same
pose direction and canvas occupancy as the reference magpie_perched.png),
but with both wings slightly raised and lifted away from the body in
a small "oops" gesture (about 15-20° away from the body, NOT fully
spread). Head tilted slightly downward and to one side, beak slightly
parted as if about to apologize. Gat hat is tipped slightly askew
(8-12° off vertical) but still fully on the head, gold band still
clearly visible. Worried but not panicked — gentle apologetic posture.

Mid-century modernist geometric reduction + Korean minhwa folk painting.
MUST match the proportions, canvas occupancy, head construction,
hat scale, and color palette of magpie_perched.png reference so this
pose drops into the mascot rotation seamlessly.

[INSERT §0.4 CHARACTER ANCHOR BLOCK HERE]
(Use the MAGPIE portion only — no tiger in this image.)

Pose-specific notes for THIS image:

FRAMING:
- Same canvas occupancy as magpie_perched.png — magpie occupies ~
  60-70% of canvas height, standing upright, body in 3/4 turn facing
  the viewer's left.
- Feet planted on the lower edge of the visible area (but NO ground
  line — feet just stop at where the ground would be, transparent
  below).

EXPRESSION:
- Head tilted slightly downward (~ 10°) and to the side (viewer's
  right), giving the "downcast worried" gesture.
- Beak slightly parted — a small dark angular gap visible between
  the upper and lower beak.
- One visible eye (the right eye in this 3/4 turn): same gold-amber
  iris filling the almond shape, tiny charcoal pupil placed slightly
  toward the lower edge of the eye (looking down).
- Gat hat tilted 8-12° askew from vertical — but STILL FULLY ON
  the head. The gold band must remain clearly visible at the base
  of the crown. Hat does NOT fall off.

WINGS:
- Both wings lifted ~ 15-20° outward from the body — NOT fully
  spread, just a small "oh no" gesture. The wings stay close to the
  body, just opened a small amount.
- Each wing shows the cream wing bar clearly (the iconic identifier).
- 2-3 darker charcoal facet shards visible on the wing surface
  showing the feather layering.

EVERYTHING ELSE matches magpie_perched.png EXACTLY:
- Body charcoal primary + darker facet shadows.
- Cream belly patch shape + dusty-pink shadow facet.
- Long narrow magpie tail with stacked charcoal feather shards.
- Hat proportions (brim 1.7× head width, crown height ≈ width × 1.3,
  gold band at base).
- Gold-amber beak with thin charcoal mouth-line split.
- Thin charcoal legs with 3-toe angular feet.

ATMOSPHERIC DETAILS:
- NO ground line, NO shadow.
- NO speech bubble, NO sweat drops, NO question marks.
- NO tear drops (NO anime worry tropes).
- Transparent PNG-32 background.

Style discipline (CRITICAL — must match mascot set):
- NO outlines on the magpie.
- NO gradients within shapes.
- Subtle hanji paper grain on character body fill only (cream belly,
  hat brim, etc.).
- Restricted palette: charcoal #1A1410 + darker #0F0A08, cream
  #F4E8D0, dusty pink #D8B5B5, gold #DFA951 (NO other colors —
  this is the minimal magpie palette).
- Same scale and canvas occupancy as magpie_perched.png reference.

Aspect ratio: 1:1 square (1024 × 1024 pixels), transparent PNG-32.

ABSOLUTELY AVOID:
- ✗ Tear drops, sweat drops, blue lines (anime worry symbols).
- ✗ Speech bubbles, "..." text, exclamation marks.
- ✗ Wings fully spread (must be only slightly lifted, "oh no" pose
  about 15-20° from the body).
- ✗ Hat falling off (must be just tilted, still on head, gold band
  still visible).
- ✗ Tiny / missing gat hat. Crown without gold band.
- ✗ Missing cream wing bar on the lifted wings.
- ✗ Pose facing fully away from viewer.
- ✗ Chibi / penguin / Pokémon proportions.
- ✗ White sclera with round black pupil (the eye is gold-amber
  iris with tiny charcoal pupil).
- ✗ Yellow or orange beak (must be gold-amber #DFA951).
- ✗ Background or shadow underneath.

This is the apologetic magpie — used after an incorrect answer or
a sync failure. Mood: "Oh, sorry — let me try again."

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, scale, head construction, hat proportions, cream
wing bar, and proportions of the attached reference magpie images
EXACTLY. This must look like the SAME magpie as in magpie_perched.png
— just with a worried expression: tilted hat (still on head), slightly
lifted wings, parted beak, downcast eye. Everything except the wing
position, head tilt, beak gap, and hat askew angle must be identical
to magpie_perched.png.
```

---

# Day 5 — 스토어 자산

## 5.1 `docs/store/feature_graphic.png` — Google Play feature graphic

> **사용처:** Google Play Console feature graphic 슬롯
> **사양:** **1024 × 500 (2:1 가로)**. Play가 이 위에 앱 제목·아이콘을 자동 오버레이하므로 **이미지 자체에 글자 금지**, 좌측 1/3은 비워둠 (negative space).
> **v2 변경:** 호랑이/까치 anchor 삽입 + 호랑이가 게이트 내부에 작게 들어가지만 캐릭터 식별성을 유지하도록 안내.

```
A wide 2:1 horizontal editorial banner illustration for the Google
Play Store feature graphic slot. A Korean hanok gateway (솟을대문)
stands slightly open on the RIGHT side of the frame, revealing a
warm hanji-cream interior glow. A dignified Korean guardian tiger
sits inside the gateway looking out at the viewer, with a small
magpie perched on the gate's eave above him. The LEFT third of the
frame is open hanji-cream sky with mountain silhouettes — left
intentionally spacious so the Play Store can overlay app title and
icon there.

Mid-century modernist geometric reduction + Korean minhwa folk painting.
Premium magazine cover quality.

[INSERT §0.4 CHARACTER ANCHOR BLOCK HERE]

Pose-specific notes for THIS image:
- TIGER framing: full-body seated frontal-facing inside the gate
  opening. Despite the relatively small scale (tiger occupies ~ 25%
  of frame width and ~ 50% of frame height), the head MUST retain
  iconic proportions — large dignified head with prominent cheek
  tufts, forehead stripe pattern (NOT literal 王), almond gold eyes,
  closed mouth in calm line. Head-to-torso ratio ~ 1:1.5.
- MAGPIE: small but with all identifying details intact — tall gat
  hat with gold band, cream wing bar on folded wing, gold-amber beak,
  one visible gold-amber eye. Perched on the LEFT side of the hanok
  eave above the gate, head turned toward viewer.

Composition layered front to back, wide 2:1 horizontal:

LAYER 1 — Sky and distant mountains (LEFT two thirds + upper area)
- Hanji cream sky (#FAF6EC) dominating LEFT half with one soft
  cream-to-pale-celadon (#D8E5DC) gradient (single permitted).
- 3 distant mountain silhouettes spanning LEFT and CENTER: closest
  in mountain teal (#3D9A7F), mid in sage (#5C7060), farthest in
  pale sage (#9BB0A0) — receding irworobongdo style.
- LEFT THIRD is intentionally minimal — sky and ONE distant mountain
  peak only, leaving 30-35% of the frame as breathable negative
  space for Play's auto-overlaid title/icon.

LAYER 2 — Hanok gate (CENTER-RIGHT, slightly open)
- A solssalmun (솟을대문) hanok gateway: tiered curved tile roof
  (#2A3340 with #1A2028 shadow facet), upturned eave horns on
  both sides.
- Dancheong band under the eaves with alternating teal (#3D9A7F),
  red (#C24A45), gold (#DFA951), ivory (#F4E8D0) squares.
- Two warm walnut wooden pillars (#7E5A3D + #5C4028 shadow facet)
  framing the doorway.
- Two red dancheong door panels (#C24A45) slightly OPEN inward,
  with brass-gold doorknobs (#DFA951) visible.
- Through the open doorway: a warm amber halo of welcoming light
  (#DFA951 at low opacity gradient — second permitted gradient,
  justified as the welcoming glow).

LAYER 3 — Tiger inside the gateway (focal point)
- See [§0.4 ANCHOR BLOCK] (tiger portion) and pose notes above.
- Tiger size is sub-dominant to the gate frame — viewer reads
  "hanok gateway with tiger inside," not "tiger first" — but the
  tiger must still be recognizable at 200 px thumbnail.

LAYER 4 — Magpie on the eave (small accent)
- See [§0.4 ANCHOR BLOCK] (magpie portion) and pose notes above.

LAYER 5 — Stone base / threshold (lower edge)
- Stone gray foundation (#8B8478) and a step or two leading up
  to the gateway, taking the lowermost 10-12% of the frame.

ATMOSPHERIC DETAILS:
- 2 loose clusters of dancheong color dots: one near the eave's
  dancheong band, one in the LEFT mountain area.
- One small plum branch (charcoal stem #1A1410 with 2 pale pink
  petals #E8B5BC) in the upper-LEFT corner — spring season anchor.
- NO text, NO logos, NO titles ANYWHERE in the image.
- LEFT 30-35% of frame must be clean negative space (sky and one
  mountain only).

Style discipline (CRITICAL):
- NO outlines on subjects.
- Permitted gradients (TWO, both justified): sky atmosphere +
  doorway welcoming glow.
- Subtle hanji paper grain overlay across image.
- Restricted palette: hanji #FAF6EC, sky celadon #D8E5DC, mountain
  teal #3D9A7F, sage #5C7060 + #9BB0A0, slate #2A3340 + #1A2028,
  walnut #7E5A3D + #5C4028, dancheong red #C24A45, gold #DFA951,
  ivory #F4E8D0, tiger orange #E87830, rust #C25420, charcoal
  #1A1410, dusty pink #D8B5B5, plum pink #E8B5BC, stone gray
  #8B8478, muted brown-pink nose #7E4030.
- High silhouette contrast for thumbnail readability at 200 px
  wide (Play search results).

Aspect ratio: 2:1 horizontal (1024 × 500 pixels exactly).

ABSOLUTELY AVOID:
- ANY text, app name, tagline, or numerals.
- Logo overlay (Play adds this automatically).
- Fully closed gateway (gate must be ajar, inviting entry).
- Fully open gateway (must be slightly open, suggesting "come in").
- Multiple tigers, multiple magpies.
- Modern objects, smartphones, Western design elements.
- Centered symmetrical composition (must be asymmetric: gate on
  right, breathing room on left).
- Sepia or monochromatic wash.
- Chibi / cub / kawaii tiger.
- Literal Chinese character 王 drawn on the tiger's forehead.
- Tiny gat hat on the magpie. Missing gold band on the gat. Missing
  cream wing bar on the magpie's folded wing.

This is the Google Play feature graphic — must instantly communicate
"premium Korean learning app with hanok aesthetic" at small thumbnail
size, while leaving the LEFT third clean for Play's automatic title
overlay.

IMPORTANT: match the geometric faceted style, color palette, paper
grain texture, and overall mood of the attached reference images
exactly. The tiger MUST read as the same character as in
tiger_idle.png and tiger_celebrate.png (same head construction,
cheek tufts, stripe pattern). The magpie MUST read as the same
character as in magpie_perched.png (same prominent gat with gold
band, cream wing bar). This must look like the most polished piece
of the same illustrated set — the cover image.
```

---

# Day 6 (옵션) — Wordle 단청 frame

## 6.1 `hanok/dancheong_frame.png` — Wordle 게임판 frame

> **사용처:** WordleScreen 게임판 외곽 BoxDecoration
> **사양:** 1024 × 1024 정사각, **가운데 영역 투명** (게임판 내용이 보이도록)
> **선택 작업** — 현재 코드는 BoxBorder + 4코너 dot로 fallback이 동작 중, PNG 들어오면 시각 강화. **캐릭터 없음** — anchor 불필요.

```
A square 1:1 decorative frame illustration. A Korean dancheong (단청)
ornamental border running around the four edges of a square canvas,
with the entire center area COMPLETELY TRANSPARENT (alpha = 0). The
frame should look like a slice of the dancheong band found under a
hanok eave, but bent into a closed rectangular border.

Mid-century modernist geometric reduction + Korean minhwa folk painting.
Symmetric, decorative, repeating pattern.

Composition (frame only — center is transparent):

FRAME STRUCTURE (border width ~ 120 px from edge):
- Outer edge (touching canvas border): solid charcoal (#1A1410)
  line, ~ 6 px thick.
- Main band: dancheong teal (#3D9A7F) base, ~ 80 px wide, running
  continuously around all four edges.
- Inside the teal band: alternating geometric squares (~ 40 px each)
  in dancheong red (#C24A45), gold (#DFA951), and ivory (#F4E8D0),
  evenly spaced around the border.
- Inside each colored square: a tiny stylized flat lotus or
  chrysanthemum motif (4-petal angular shape, cream or contrasting
  color).
- Inner edge of the band: solid charcoal (#1A1410) line, ~ 4 px thick.
- Four corners: a slightly larger square (~ 50 px) with a special
  motif — a small angular flame or a stylized 王 stripe pattern
  (NOT typographic) — same in all 4 corners for symmetric anchor.

CENTER (CRITICAL):
- The inner area inside the border (approximately 800 × 800 region
  in the center) MUST BE FULLY TRANSPARENT — alpha channel = 0.
- NO color, NO white background, NO gradient — pure transparency
  so the Wordle grid below shows through.

ATMOSPHERIC DETAILS:
- No animals, no text, no other figures.
- Subtle hanji paper grain ONLY on the frame areas (not on the
  transparent center).
- Pattern repeats consistently around all 4 edges.

Style discipline (CRITICAL):
- NO outlines other than the structural charcoal edges.
- NO smooth gradients.
- Subtle hanji paper grain on frame.
- Restricted palette: dancheong teal #3D9A7F, red #C24A45, gold
  #DFA951, ivory #F4E8D0, charcoal #1A1410.

Aspect ratio: 1:1 square (1024 × 1024 pixels), transparent center.

ABSOLUTELY AVOID:
- Any content in the center (must be fully transparent).
- White or cream background fill in center (transparent only!).
- Asymmetric frame (must be 4-way symmetric).
- Asian pattern stereotypes (no dragons, no fans, no Chinese knots).
- Outlines around the colored squares.
- Literal Chinese typography 王 as text — use the stripe pattern.

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
| 🔴 1 | **Day 4 (마스코트 3장) — v2 최우선 재작업** | v1 출력이 chibi/full-body로 나옴. v2 prompt로 재생성 필수 |
| 🔴 2 | Day 3.2 / 3.5 / 3.6 (호랑이/까치 등장 헤더 3장) — v2 재작업 | 같은 캐릭터 식별성 이슈 잠재 — v2 anchor로 재생성 권장 |
| 🟡 3 | Day 2 (빈/오류 5장) | 이미 좋은 결과 있음. 다시 만들 필요는 낮음 |
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

Composition layered front to back, 1080 × 1920 canvas:

LAYER 1 — Sky background
- Hanji cream (#FAF6EC) sky with one soft cream-to-ivory gradient.
- One small muted indigo crescent moon (#1F2E5C) in upper right
  (matches reference gate.png exactly).

LAYER 2 — Distant mountain silhouettes
- Two angular green mountain silhouettes (mountain teal #3D9A7F
  + sage #5C7060) on left and right sides of the lower frame —
  exactly as in reference gate.png.

LAYER 3 — Hanok roof and eaves (upper third)
- Tiered curved tile roof (기와지붕) in dark slate-charcoal
  (#2A3340) with deeper shadow facet (#1A2028) on the underside
  curve.
- Upturned eave horns (처마끝) on both far left and far right.
- Small dark roof ridge cap (망와) at the apex.
- Match exactly the roof curvature, tile pattern, and proportion
  shown in reference gate.png.

LAYER 4 — Dancheong band (under the eaves)
- Horizontal teal band (#3D9A7F) running across the full width
  below the roof.
- Inside the band: alternating geometric squares (~ equal spacing)
  in red (#C24A45), gold (#DFA951), ivory (#F4E8D0).
- Match the exact square count, color sequence, and motif inside
  each square as shown in reference gate.png.

LAYER 5 — Wooden pillars and frame structure
- Two warm walnut wood pillars (#7E5A3D with darker shadow facet
  #5C4028 on the inner edge) running vertically from the dancheong
  band down to the stone base, framing the doorway.
- A horizontal walnut lintel between the pillars at the top of the
  doorway.

LAYER 6 — Stone base and steps
- Stone gray foundation (#8B8478) at the bottom, with one or two
  visible steps leading up to the gateway threshold.
- Match reference gate.png exactly.

CENTRAL TRANSPARENT AREA (CRITICAL):
- The rectangular area where the double red doors would normally
  be (approximately x=195 to x=885, y=615 to y=1615 in 1080 × 1920
  space, matching the registration in HanokGateArt) MUST BE FULLY
  TRANSPARENT (alpha = 0).
- NO red color, NO door dots, NO doorknobs in this central area.
- Through this transparent rectangle, the door panels (separate
  assets) will be rotated open in the app.

ATMOSPHERIC DETAILS:
- A tiny single magpie shape silhouette perched on the roof apex
  (match reference gate.png exactly) — optional, only if it stays
  perfectly consistent.
- 2-3 small dancheong dot accents around the gateway, matching
  the loose cluster pattern of reference.

Style discipline (CRITICAL):
- NO outlines on subjects.
- Match reference gate.png exactly: stroke weight, plane facets,
  hanji grain density, color saturation.
- Restricted palette: SAME as reference gate.png — do not introduce
  any new color.

Aspect ratio: 9:16 vertical (1080 × 1920 pixels), with transparent
central door area as specified.

ABSOLUTELY AVOID:
- Red color anywhere in the central door area (must be transparent).
- Different style or color saturation from reference gate.png.
- New decorative elements not present in reference.
- Outline strokes.
- Modern elements.

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
  roughly 1:2.9 aspect ratio).
- The RIGHT edge of the panel (the inner edge that meets the other
  door) should be where the hinge axis would be in the open
  position — but the asset itself is drawn as the CLOSED panel
  (the rotation happens in code).

Composition (panel only — TRANSPARENT background):

PANEL BODY:
- Solid dancheong red (#C24A45) main panel surface, with subtle
  rust shadow facet (#A8332E) along ONE vertical edge (the right
  edge — the inner edge that meets the other door) for slight
  3D depth.
- A darker rust outline along all four panel edges in #7E2A22
  (~ 6 px), suggesting the wooden door frame.

PANEL DETAILS (match reference gate.png exactly):
- Vertical wood plank lines: 2-3 thin vertical charcoal lines
  (#7E2A22, thin 3-4 px) running top to bottom, dividing the panel
  into 3 vertical plank sections.
- Decorative gold-amber metal studs (#DFA951): rows of small
  circles (~ 24 px diameter) arranged in a grid pattern, 4 rows ×
  3 columns, evenly spaced down the panel — these are the
  traditional hanok door rivets.
- One large gold-amber door knocker handle (#DFA951): a circular
  ring (~ 80 px diameter) attached to the panel near the inner
  edge (right side) at vertical mid-height, with a small backing
  plate.

ATMOSPHERIC DETAILS:
- NO background (fully transparent).
- NO shadow underneath.
- Subtle hanji paper grain ONLY on the red panel surface, not on
  the transparent area.
- NO text or characters on the panel.

Style discipline (CRITICAL — must match reference gate.png):
- Match the red dancheong color, stud pattern, and knocker style
  of the reference gate.png exactly.
- NO outlines except the structural panel-frame edge.
- NO smooth gradients.
- Restricted palette: dancheong red #C24A45 + #A8332E + #7E2A22,
  gold #DFA951.

Aspect ratio: approximately 1:2.9 vertical rectangle (345 × 1000
or proportional), transparent PNG-32.

ABSOLUTELY AVOID:
- Background of any color (must be fully transparent).
- Door frame, hinges, or surrounding architecture (those are in
  the gate_frame.png — this is the door panel ONLY).
- Different style than reference gate.png.
- Outline strokes on stud circles.
- Both door panels in one image (this is LEFT panel only).

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
  inner edge meeting the other door).
- Darker rust outline along all four panel edges in #7E2A22
  (~ 6 px).

PANEL DETAILS:
- Same 2-3 vertical plank lines as the left panel, mirrored.
- Same 4 × 3 grid of gold-amber metal studs (#DFA951).
- One large gold-amber door knocker ring (~ 80 px diameter,
  #DFA951) attached near the inner edge (LEFT side this time)
  at vertical mid-height.

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
- [x] `assets/illustrations/empty/sleeping_tiger_b2.png` (v1 OK, 유지 가능)
- [x] `assets/illustrations/empty/celebrate_complete.png` (v1 OK, 유지 가능)
- [x] `assets/illustrations/empty/studyroom_waiting.png` (v1 OK, 유지)
- [x] `assets/illustrations/error/offline_lantern.png` (v1 OK, 유지)
- [x] `assets/illustrations/error/lost_magpie.png` (v1 OK, 유지)

## Day 3 — 헤더 배너 (6장)
- [x] `assets/illustrations/hanok/scholar_room.png` (Settings, 캐릭터 없음 OK)
- [ ] `assets/illustrations/hanok/achievements.png` (Stats) — v2로 재생성 권장
- [x] `assets/illustrations/hanok/study_classroom.png` (Vocab, 캐릭터 없음 OK)
- [x] `assets/illustrations/hanok/study_scholar.png` (Grammar, 캐릭터 없음 OK)
- [ ] `assets/illustrations/hanok/listening_hero.png` (/listening) — v2로 재생성 권장
- [ ] `assets/illustrations/hanok/kkeunmari_hero.png` (끝말잇기) — v2로 재생성 권장

## Day 4 — 마스코트 (3장) — **v2 최우선 재생성**
- [ ] `assets/illustrations/mascot/tiger_thinking.png` ⚠️ v1 출력은 chibi/full-body — v2 재생성 필수
- [ ] `assets/illustrations/mascot/tiger_sleepy.png`
- [ ] `assets/illustrations/mascot/magpie_worry.png`

## Day 5 — 스토어 (1장)
- [ ] `docs/store/feature_graphic.png` (1024 × 500)

## Intro Gate (3장, gate.png 스타일 일치)
- [ ] `assets/illustrations/hanok/gate_frame.png` (교체 — 가운데 투명)
- [ ] `assets/illustrations/hanok/gate_door_left.png` (교체 — 단독 panel)
- [ ] `assets/illustrations/hanok/gate_door_right.png` (교체 — mirror)

## Day 6 옵션 (1장)
- [ ] `assets/illustrations/hanok/dancheong_frame.png` (Wordle frame)

---

# 부록 A — v1 → v2 변경 요약 (디버그 메모)

## A.1 진단: 왜 day 4부터 망가졌나

`mascot/tiger_thinking.png` (v1 결과) 와 reference (`tiger_idle.png`, `tiger_celebrate.png`, `tiger_neutral.png`) 를 직접 비교한 결과:

| 항목 | reference (idle/celebrate/neutral) | v1 tiger_thinking (실패) | 원인 |
|---|---|---|---|
| Framing | BUST-UP (어깨까지, 머리 dominant) | FULL-BODY 작은 사이즈 | prompt가 "sitting on his haunches" 라고 함 → AI가 full body로 해석 |
| 머리 비율 | 캔버스 height의 40-50% | 캔버스 height의 ~20% | full body로 그리면서 머리가 축소됨 |
| 이마 stripe | 4-5개 angular charcoal facet (王 모양 암시) | 한자 王 또는 단순 stripe | prompt에 "王 character on forehead" → 한자 typography로 그려짐 |
| Cheek tuft | 매우 prominent, puffy cream facet | 거의 없음 | prompt가 cheek tuft를 명시 안 함 |
| 수염 | 4개 angular sliver per side | 누락 또는 매우 약함 | prompt에 whisker 디테일 없음 |
| Eye | 전체 gold-amber 채운 almond | round black pupil + white sclera | prompt가 "amber-gold eyes" 만 함 — pupil 금지 미명시 |
| 캐릭터 식별성 | 어른 dignified guardian | 작은 새끼 / chibi 고양이 | 위 모든 누락 누적 효과 |

## A.2 v2 처방 (이 문서에 적용된 변경)

1. **§0 캐릭터 시트 신설.** anatomy + style discipline을 1회 정의.
2. **§0.4 CHARACTER ANCHOR BLOCK.** 호랑이/까치 등장하는 모든 prompt 안에 그대로 복붙.
3. **Framing 명시.** 마스코트 solo 포즈는 모두 "BUST-UP portrait, paws cropped at bottom" 명시. "sitting on his haunches" 표현 제거.
4. **"王 character" → "stripe pattern that SUGGESTS 王, never literal Chinese typography"** 로 모든 prompt에서 정정.
5. **Cheek tufts / whiskers / chest V / eye style**를 매 prompt마다 다시 명시 (anchor block에 포함).
6. **Magpie hat 비율 "tiny" → "prominent / tall / 1.7× head width"** 로 강화 + gold band 필수 명시.
7. **Magpie wing bar 명시.** 모든 까치 prompt에서 "cream wing bar on folded wing (the iconic identifier)" 필수.
8. **Eye pupil 명확화.** "no round black pupil in white sclera; the iris fills the entire almond shape in gold-amber" 매번 명시.
9. **Adult proportions 강조.** "NOT chibi, NOT cub, NOT kawaii" 를 모든 prompt의 ABSOLUTE PROHIBITIONS 섹션에 포함.
10. **마지막 줄 IMPORTANT.** "The tiger MUST read as the same character as in tiger_idle.png" 같은 직접 reference 명시를 매 prompt 끝에 추가.

## A.3 사용 권장 순서

1. 먼저 §0 캐릭터 시트를 읽고 캐릭터 anchor를 머릿속에 정착.
2. 각 prompt 안의 `[INSERT §0.4 CHARACTER ANCHOR BLOCK HERE]` 위치에 §0.4 BLOCK을 그대로 복붙.
3. AI tool (Nano Banana 2 / DALL-E / ChatGPT image) 에 prompt + reference image 2장 첨부.
4. 첫 생성 결과를 reference와 직접 비교:
   - 머리 비율?
   - Cheek tufts 있나?
   - 수염 있나?
   - 이마에 한자 王 typography가 있나? (있으면 실패 — stripe pattern으로 다시)
   - 눈에 black pupil + white sclera 가 있나? (있으면 실패 — gold-amber 전체 채움으로 다시)
   - Gat hat에 gold band 있나?
   - Cream wing bar 있나?
5. 위 항목 중 하나라도 어긋나면 "Regenerate with these corrections:" 로 prompt를 보강.
