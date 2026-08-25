# Personal Hanok Art Direction Lock

- Status: **FINAL SSoT — user-approved continuity contract**
- Version: `2.0.0`
- Locked: `2026-08-23`
- Supersedes: `1.0.0` (2026-08-20)
- Scope: 함양 일두고택 고증 재현 마스터 및 모든 누적 증축 이미지
- Read policy: For routine generation, read **this file + the roster row for the building being added + the immediately preceding approved image only**. Do not reread the long research report or the original 366-line prompt unless this lock is genuinely ambiguous.
- Override policy: A new explicit instruction from Jin may revise this lock. Older prompts, layouts, reports, and V1 conventions may not silently override it.

## 0. What changed from v1.0.0, and why

v1.0.0 §3 required an **original fictional** late-Joseon jongga and forbade reconstructing a named heritage property. v2.0.0 reverses that: the estate is now a **documented reconstruction of one real house**, because the product goal changed to a heritage series (「고택 도장깨기」) with 국가유산청 partnership as an explicit aim. A partnership cannot be built on an invented house.

Three consequences follow, and they are the whole diff:

1. **Fidelity replaces invention.** Every building must trace to a roster row. §3.
2. **Honesty is graded, not assumed.** What we do not know is drawn as not-known, never as a plausible guess. §3.
3. **Two v1 exclusions are resolved rather than papered over.** `rear_garden` and an independent `daecheongmaru` shipped as runtime layers while v1 §5 banned them — the lock and the code disagreed. They are now retired and replaced by buildings this house actually has. §5.

Unchanged from v1.0.0: the camera discipline, the Faceted Minhwa rendering law, the composition budget, the cumulative-generation protocol, and every per-stage hard gate.

## 1. Approved visual anchors

| Role | File | SHA-256 |
|---|---|---|
| Complete-estate composition/style anchor | *pending — 일두고택 마스터 승인 시 기재* | — |
| Empty-estate camera/ground anchor | *pending* | — |
| Current cumulative-state anchor | *pending* | — |

> v1.0.0's anchors (`estate_v2_complete_structure_trial_01.png`, `estate_00_empty_site.png`, `boundary_03_sotdaeulmun.png`) described the retired fictional jongga. They are **not** valid anchors for this lock and must not be used as generation input. They remain on disk as history.
>
> Until the first 일두고택 master is approved, generation runs against candidate references under `assets_unused/한옥후보/`, which are classified `reference_only_user_supplied` by `docs/HANOK_V1_SOURCE_REGISTRY.md` — **fact-check only, `modelInput: forbidden`**. A candidate may inform a written brief; it may never be fed to a model, traced, or recoloured.

## 2. Non-negotiable image contract

- Runtime canvas: `2412 × 2622` — exactly two iPhone 16 Pro screens wide (2 × 1206 @3x) and one screen tall. Jin-approved via the massing mockup, 2026-08-24.
- Viewport: one phone screen (`1206 × 2622`). **Horizontal pan only, zero vertical pan, no zoom ever** (zoom breaks 44dp accessibility targets). First screen (east) = entry + 사랑 domain; one pan west = 안 domain; 후원·사당 strip always visible at the top.
- Entry: 솟을대문 at the bottom of the first screen (신영도 convention). The "대문채 동향" fact is carried by a compass mark, never by rotating the map.
- **Ground is NOT generated.** It is assembled at runtime from one small seamless earth tile (`ImageRepeat.repeat`) plus vector terraces, walls, and gates — a seam cannot exist. Tile prompt: `F-D-ildoo.promptSkeletonGroundTile`.
- **Buildings are generated as individual sprites** (2K, per-building aspect, pure `#00FF00` chroma background), cut to their alpha bbox, and placed by `spriteRect` on the master canvas. Full-canvas scene generation is retired.
- Camera ID: `personal_map_north_up_oblique_v3` — **shallow** frontal elevation, pitch **10–15° only**. Roof pitch planes read broad; the ridge top is barely visible; the 기단 top surface is a thin band, never a lozenge. v1.0.0 said "elevated three-quarter", which was read as a high bird's-eye and flattened every building — the number replaces the adjective.
- Camera: one fixed, north-up camera; no crop, zoom, rotation, tilt, or perspective reset between stages. **The camera never yaws.**
- **Buildings yaw, the camera does not** (`planYaw`, revised 2026-08-24). Each 채 is seated at its surveyed orientation: 사랑채 남동향 → `-20`, 안채 남서향 → `+20` (문화재청 2007 기록화보고서 p38, p39~40), everything else `0`. Only these three values exist. Rotating the *camera* instead would swing the whole site — 담장 would cut the 2412 × 2622 canvas diagonally and the south→north hierarchy axis would go oblique, which is the one thing this estate exists to show. Ridge lines stay horizontal at every yaw: `planYaw` is a plan rotation, not a pitch change.
- **편액 (hanging plaques) are NEVER baked into a sprite** (added 2026-08-24). Generative models hallucinate hanja — try05 produced 愛敬堂 where the house has 文獻世家. Two independent reasons make the runtime layer correct anyway: the plaques are **B2 grants**, so baking them into the A1 사랑채 sprite would leak a B2 reward at A1; and §5 bans generated glyphs outright. Generate the plaque board as an indistinct dark panel; composite the real inscription at runtime from the roster's `plaques[]`.
- `anchorY` is **the ground-contact point nearest the viewer**, not the alpha-bbox bottom — a yawed sprite meets the ground on a diagonal, and the painter's-algorithm ordering depends on this definition.
- Light: soft upper-left illumination; restrained shallow shadows fall toward the lower-right. **Cast-shadow length is proportional to a building's 기단 벌대** — the shadow is a measurement, not decoration.
- Rendering: **Hangul Sori heritage 2.5D game-art system** (full statement: `STYLE_LOCK.json → F-D-ildoo.styleStatement`, Jin 확정 2026-08-23, 자산군별 레지스터 표 확장 2026-08-25). Asset-class registers, never mixed on one asset:
  - **Architecture — stylized hand-painted 2.5D architectural sprite art** (this estate — buildings, gates, walls, ground): believable Korean construction first, precise giwa roof rhythm, warm timber, hanji plaster, stone foundations, selective ink-like linework, matte materials, **restrained painterly facets** — never triangulated geometry. Structure and material before facets.
  - **Camera — elevated three-quarter oblique game view**: for this estate, the shallow 10–15° frontal camera above is the canonical reading of that phrase.
  - **Props/vignette — faceted paper-cut vignette illustration** (decor objects, lesson/UI vignettes — NOT this estate): stronger angular polygonal facets, hanji grain first, compact silhouettes.
  - **Characters — faceted semi-realistic character illustration** (tiger & magpie): facets plus lively, believable expression and anatomy.
  - **Environment — atmospheric faceted painterly environment art** (mountains, sky, distant backdrop).
  - Minhwa-inspired colour and decorative vocabulary without imitating literal minhwa painting. Shared palette across all classes: ink-charcoal giwa, warm walnut, hanji cream, muted deep teal, dark brick red, restrained gold accents. Premium contemporary Korean game art — **not watercolor, not anime, not Pixar, not literal low-poly 3D.**
- Surface: warm compacted earth, subtle aged-hanji grain, restrained value variation, no glossy finish.
- Palette: charcoal-gray matte giwa, weathered natural timber, pale warm earth plaster, muted natural stone, quiet olive edge vegetation.
- Visual hierarchy: **space is the hero**. Architecture is secondary to readable courtyards and breathing room.

> **Why portrait.** The house's organising fact is that the ground rises south → north across four gates. A 4:3 canvas cannot hold that run. The viewport stays 3:4 rather than 9:16 so the 800×1280 landscape tablet in `test/accessibility_guideline_test.dart` still fits and so the estate does not read as a shallow panorama. 3:4 is the exact transpose of the old 4:3, so every `1536` in the toolchain stays `1536`.
>
> **The A1 16-state kit keeps `4:3` `1536 × 1152` permanently.** It is promotion-immutable and hash-locked; it is a different camera with a different job. Two viewport contracts is correct, not a compromise.

## 3. Subject and evidence obligations

This estate is **함양 일두고택** (국가민속문화유산, 지정 1984-01-14, 경남 함양군 지곡면 개평길 50-13) — not a fictional jongga, and not a composite of several houses.

1. **Roster discipline.** Every building, gate, and site element must correspond to a row in `docs/data/heritage_houses/ildu_gotaek.json`. Do not invent a building. Do not add a building because the composition feels empty — emptiness is the composition (§4).
2. **Every row carries an evidence grade** — `measured` (실측 근거) / `documented` (문헌 근거) / `typological` (유형 추정) / `unresolved` (미상).
3. **The grade determines how it is drawn.** This is enforced in code, not left to judgement:

   | grade | render mode | drawn as |
   |---|---|---|
   | `measured` | `solid` | full material rendering |
   | `documented` | `reconstructed` | reduced saturation, persistent grade chip |
   | `typological` | `schematic` | line/hatched footprint only — **no material detail, no signboard, no bay count** |
   | `unresolved` | `vacantPlot` | marked empty plot with a `?`. **Never a silhouette** |

4. **No text reuse, no image reuse.** Source sentences, drawings, and photographs are never copied, traced, or recoloured. Confirm a fact, close the source, then author independently — the neutral-brief rule in `docs/HANOK_V1_SOURCE_REGISTRY.md`.
5. **No implied endorsement.** No 국가유산청 logo, seal, certification, or sponsorship wording anywhere in the app. `출처: 국가유산청 국가유산포털` as attribution is permitted and expected.
6. **Disputed facts stay disputed.** Where sources disagree (정려 편액 4 vs 5, 동 수 10 vs 12 vs 17), the roster records every claim with its source. Generation follows the roster's `renderClaimId`; it never silently picks a winner.

## 4. Composition budget

- Architecture and walls: `≤35%` of the complete-estate canvas.
- Intentionally empty courtyards: `≥40%`.
- Paths, thresholds, and reserved future space: approximately `15%`.
- Vegetation and life props combined: `≤10%`.
- Outer 사랑마당: `≥60%` one connected unobstructed earth plane.
- 안마당: `≥60%` empty.
- Vegetation: edge-only, no more than two restrained clusters.
- **Courtyard width narrows toward the entry** (前窄後寬): the entry band reads roughly half the width of the 안 band. See the roster's `groundBand` table.

## 5. Absolute exclusions

**Released from v1.0.0:**

- **석가산** — permitted, but as **exactly one 삼봉형(three-peak) rock arrangement** in the 사랑마당, which is a documented feature of this house. All other ornamental rockwork remains forbidden.

**Retired — the subject does not have them:**

- `rear_garden` as a structure, layer, milestone, or reward. Replaced by 석가산.
- An independent `daecheongmaru` **building**. 대청 is a part of the 안채, not a building. The freed slot is **중문간채**.
- `서고` as a building.

**Never add or revive:**

- **단청 on any building.** 조선 살림집 가사제한. In v1 this was a taste rule; here it is a **고증 rule**, machine-checked by the `dancheongMax` gate in the `F-D-ildoo` style family. A generation model will violate this silently — one earlier candidate produced a red-dancheong two-storey gate tower — so it is gated, not trusted.
- ponds, bridges, pavilions, ornamental streams, flower gardens, stone lanterns, or central courtyard trees;
- rigid palace symmetry, monumental axes, palace-scale gates;
- watercolor wash, anime, Pixar-style rendering, **literal low-poly 3D triangulation**, photorealism, soft painterly blur, glossy 3D, or cartoon styling;
- people, animals, vehicles, tools left as decoration, text, labels, arrows, UI, logos, watermarks, or modern objects;
- a silhouette, placeholder, or "plausible" massing inside an `unresolved` plot.

## 6. Locked spatial grammar

Sourced from the roster's `spatialPrinciples[]`. This is a 남부 개방형 estate and must never drift toward the closed 경북 ㅁ자 뜰집.

1. **안채 영역(서)과 사랑채 영역(동)이 동서축에 병렬로 놓인다.** Two parallel bars at different heights — not one nested courtyard.
2. Entry is a single 솟을대문 at the south, integrated into the 문간채 as its raised central bay.
3. From the gate, one route runs straight west to the 일각문; the other runs obliquely north-east into the 사랑마당. **The two never merge again.**
4. 일각문 → 중문 is a two-stage threshold into the 안 영역. Never a straight palace axis.
5. The 안채 is 一자형 and south-facing, with 부속채 attached on its service side.
6. The 사당 occupies a **separately walled enclosure at the highest rear ground**.
7. The estate rises through six ground bands south → north; 기단 height rises on top of that. **사랑채 is the visual high point (band 2 + 4벌대); 사당 is the topographic high point (band 5).**

## 7. Sprite-generation protocol

1. **One building per generation**, standalone, on pure `#00FF00` chroma, at 2K, per-building aspect. Full-canvas cumulative generation is retired with the code-assembled ground.
2. Style reference: exactly **one** allowlisted project sprite (e.g. `assets/illustrations/personal_hanok_v2/map/structures/sarangchae.png` — it is in `allowedModelInputs`). The reference carries **style, camera, palette, and lighting only — never plan shape or proportions**; state that in the prompt. Candidate photos and the 신영도 remain `modelInput: forbidden`.
3. Geometry comes from the roster row: plan form, front bays, podium courses, roof form, orientation. **If a roster field is null, omit that sentence from the prompt** — never specify an unsourced form.
4. Every sprite's placement must agree with the roster's `groundBand`, `podiumBeoldae`, and the terrace table in `F-D-ildoo.camera.groundBands`.
5. Produce one candidate per building. If a hard gate fails, regenerate that same building before continuing.
6. Save only to `assets_unused/pending_review/personal_hanok_v3/` until Jin gives separate promotion authority.
7. Do not modify runtime assets, `pubspec.yaml`, catalogs, grants, Firebase, or provenance ledgers; do not commit, push, or open a PR without separate authorization.

## 8. Per-stage hard gates

Reject the image if any of these occurs:

- camera, crop, wall, gate, light, palette, grain, or existing vegetation drifts;
- a building appears that has no roster row, or an `unresolved` plot is filled;
- a `typological` row is drawn with material detail, a signboard, or countable bays;
- **any dancheong appears on any building** (`dancheongMax` gate);
- the 솟을대문 separates from the 문간채, or becomes palace-scale;
- the 안/사랑 parallel axis collapses into a single enclosed courtyard;
- a courtyard stops reading as the largest clear empty plane, or 前窄後寬 inverts;
- 기단 height or cast-shadow length contradicts the roster's `podiumBeoldae`;
- construction from a later stage appears early;
- props, vegetation, decoration, or paths are invented;
- the architecture register drifts toward watercolor, anime, Pixar-style rendering, literal low-poly triangulation, photorealism, soft blur, or glossy 3D — or toward the props register's hard polygonal faceting;
- the image contains text, people, animals, modern objects, or watermarking.

## 9. Validation and reporting

For every stage:

- inspect the full image, a `25%` preview (`576 × 1024`), and a `100 px`-wide thumbnail;
- confirm stage-to-stage cumulative readability at 100 px;
- confirm `2304 × 4096`, RGB, embedded sRGB ICC at generation and `1152 × 2048` after downsample, and record SHA-256 for both;
- run the `F-D-ildoo` style conformance check, including `dancheongMax`;
- report the sole input image, exact saved path, dimensions/mode/profile/hash, visual hard-gate result, roster rows touched, and changed files.

## 10. Design-guide carryover

Hanok order, hierarchy, restraint, and breathing room are the brand system. Hanji is the field. **Dancheong is not an accent on this house at all** — it is forbidden by the subject's own sumptuary law. Do not solve weak composition by adding colour or ornament; solve it with the ground, the shadow, and the empty courtyard.
