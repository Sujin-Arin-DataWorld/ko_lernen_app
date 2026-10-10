# ABC concept review — 2026-10-10

Six new static candidates: A/B/C in German and English. Built-in image_gen generated each alternative separately, then restored the original poster's character features and created English text variants. The current runtime layout and media remain kept in kept/KEEP.json; 14 source/capture copies were verified byte-for-byte with SHA256.

## Selected direction

The user explicitly selected C on 2026-10-10 by attaching its image and saying that this is the preferred design. C is the visual authority for the next reward-suite mockups. A and B remain alternative exploration records. The reviewers' earlier A/B preferences do not override the user's selection. C's exact movie containment and safe-area adjustments below remain implementation checks.

## What the reviewers actually inspected

All six generated PNGs were viewed directly. At the static concept level, no additional P0/P1 text, actor or CTA overlap was found. German/English copy has no visible language remnants; earned +20, wallet 90 and build cost 40 agree. Button text and arrows are separate. The original headband, patterned vest, sandals and carved club are represented; this is reference-based generated artwork, not byte-identical original movie pixels.

Early candidates changed the character and used a closed lock despite the next building step being available. Those were corrected: costume and club features were restored, locks became readiness checkmarks, and C's unapproved Hanok interior objects were removed. Future house art, construction stages, fabric covers and fixed Sarangchae names are absent.

## Implementation limits and required adjustments

- These are raster compositions shown in 402×874 comparison frames. Native raster sizes and hashes are in CONCEPT_ASSETS.json. Exact logical spacing and native iPhone safe areas are not approved by bitmap inspection.
- Some logo/wallet artwork sits around logical y40–60. The later Flutter layout must reserve top safe area 62 and move this content below it. Bottom safe area 34, primary CTA 56, CTA gap 8 and secondary CTA 48 remain implementation targets.
- C needs about 20dp more room to protect a full 336px movie canvas plus adjacent spacing. Adjust its number area or construction card before implementation.
- Preserve the entire original 960×960 video with contain. The original feet are at about 79% of canvas height; align the contact shadow to the feet rather than the canvas bottom.
- Live earned +0→confirmed20 and wallet70→90 use the actual receipt, cue3.583s, one840ms clock and200ms settle. Generated flying coins are scene illustration, not a proposal to restore coins travelling into the wallet.
- Full video containment across all frames, original RGB, touch targets, semantics, reduced motion, Dynamic Type and device performance require Flutter/runtime checks. Static approval does not establish any of those.

## Skill decisions

Mobile UI and layout/grid skills drove a large acting area, compact related groups and two bottom actions. Design-system and styling skills kept jade/hanji/brass materials, shared light direction and shallow contact depth. User-flow and motion reviewers preserved confirmed-receipt ownership and immediate navigation. UX/a11y reviewers checked language, hierarchy, CTA internals and character overlap, while distinguishing static findings from runtime claims.

Exact inputs are preserved in prompts.json, correction-prompts.json, layout-correction-prompts.json and english-prompts.json. CONCEPT_BRIEF.md records the flow and target geometry. Original generated images remain in the user's generated_images directory.
