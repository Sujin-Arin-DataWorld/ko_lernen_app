# 한옥 V1 A1-06 기둥 세우기 — BBANANA pilot 3안

상태: 호출 전 고정 · 2026-08-17

## 실행 계약

- Provider: BBANANA
- Model: `Nano Banana Pro`
- Mode: image edit
- Resolution: `2K`
- Aspect ratio: `4:3`
- Cost: 4 credits/call, 3 calls, planned total 12 credits
- Base/edit target:
  `assets/illustrations/personal_hanok_v2/map/site_base_light.png`
  (`sha256 5d197bc17feb6ed1797cbbaa1ab96b273a1fabee2e3d12a69728e64c53fd6690`)
- Geometry/style reference:
  `assets/illustrations/personal_hanok_v2/map/structures/sarangchae.png`
  (`sha256 f523e93ff70040cef5066ee93caeb1e2ce54a3b19625bc615ac02c4c336dbff1`)
- The user-supplied screenshots, Vivasam, PDFs, legacy `hanok_stages`, and Gye
  assets are forbidden model inputs.

The base image is the edit target. The Sarangchae image is only a project-owned
geometry, material, palette, and rendering reference. It is not pasted as a
finished building.

## Invariants shared by all three calls

```text
Use case: historical-scene / precise-object-edit
Asset type: cumulative A1 construction state for a Korean-learning app map

PRIMARY REQUEST
Edit the base estate image to show A1 construction state 06: the first timber
columns have been erected for one modest common residential Joseon-era choga
house. This is an unfinished timber frame, not a completed house.

INPUT ROLES
Image 1 is the exact base/edit target. Preserve its 4:3 north-up oblique camera,
1536x1152 composition, top-left light, boundary walls, vegetation, stones,
paths, paper texture, colors, and every building socket outside the primary
house work zone.
Image 2 is a style and geometry reference only. Match its Korean timber scale,
warm walnut material, granite foundation language, faceted painterly finish,
lighting, and oblique perspective. Do not paste its roof, walls, doors, windows,
or completed facade.

PRIMARY HOUSE WORK ZONE
Place the construction only inside canvas rectangle x=160, y=614, width=854,
height=309, with the ground anchor at canvas (587,923). Align it to the same
estate perspective as the reference. Do not alter pixels outside that work zone
except a very small physically necessary contact shadow that remains inside the
zone.

CUMULATIVE CONSTRUCTION STATE
- a low rectangular granite/compacted-earth gidan foundation is already present
- accurately spaced cornerstones support the timber posts
- measured and prepared timber pieces are stacked neatly beside the foundation
- upright warm-walnut columns are newly erected and are the dominant new change
- traditional Korean post-and-lintel proportions and visible mortise preparation
- no workers, tools in motion, cranes, modern machinery, scaffolding, ladders,
  safety tape, or modern materials

VISUAL STYLE
Premium Faceted Minhwa map illustration: detailed geometric painterly facets,
subtle hanji grain, warm cream earth, muted stone gray, warm walnut and deep
walnut timber, restrained natural shadows, crisp readable silhouette at small
size. Match the two project-owned images as one coherent illustrated set.

HARD EXCLUSIONS
No roof of any kind. No rafters, purlins, beams, walls, earth plaster, windows,
doors, ondol room, maru floor, dancheong, signboard, furniture, people, animals,
mascots, text, numbers, labels, progress UI, icons, watermark, border, or black
matte. Do not add another building anywhere else. Do not change the camera,
crop, estate wall, garden, vegetation, pathways, light direction, or season.

OUTPUT INTENT
Opaque RGB 4:3 whole-estate image. The user should immediately recognize that
the house is being built and that this exact step erected columns. Preserve all
invariants aggressively; change only the primary house construction zone.
```

## Variant A — eight-post calm silhouette

Append to the shared prompt:

```text
VARIANT A
Use a calm, highly legible eight-post rectangular frame: four front posts and
four rear posts, evenly spaced, with the two corner posts slightly stronger.
Keep the timber stack compact at the left edge of the foundation. Prioritize a
clean silhouette and exact estate integration.
```

## Variant B — central-bay emphasis

Append to the shared prompt:

```text
VARIANT B
Use ten upright posts with a wider central living bay and narrower side bays,
all still clearly unfinished. Keep prepared timber stacked behind the right
side of the foundation. Prioritize historically plausible rhythm and depth in
the fixed oblique camera.
```

## Variant C — corner-and-inner-post rhythm

Append to the shared prompt:

```text
VARIANT C
Use twelve slender but structurally credible posts: four strong corners plus
paired inner posts that make the future room rhythm readable. Keep the timber
stock low along the rear edge of the foundation. Prioritize the clearest visual
difference from an empty foundation without suggesting beams or a finished
frame.
```

## Acceptance before selecting a pilot

- camera/base outside work zone visually unchanged
- construction is inside the exact socket and touches anchor `(587,923)`
- no roof, beam, wall, finished room, text, UI, character, or watermark
- columns are the unmistakable stage change
- Korean—not Chinese/Japanese—residential timber proportions
- output can be deterministically resized/cropped to 1536×1152 without changing
  composition
- automated dimension/color/matte/OCR/socket tests and human visual review pass
- rejected variants remain QA evidence only and are never bundled
