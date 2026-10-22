# R5 — Pablander method, user-authorized implementation

Input: ../lookdev-sarang-r3/sarang-r3-fix-checkpoint.blend
SHA256: 509ffb8a8d714663096c5c7e6d6f0d121a8720f23b281905ebf1cbe328d89c1d

User spec: preserve Hanok hue families, clearer hand brushwork, cared-for materials, geometry/UV/plaques unchanged. Three value fills and independent dark/mid/light paint masks. Compare Numaru, eaves and hero, also 402px width. Save/reopen and verify all 711 meshes. Native review candidate only.

Ruling: reuse the existing artifact checkout, per explicit user instruction against new worktrees. This is a material-art prototype; use native invariance checks and rendered inspection instead of implementation-mirroring unit tests. Keep the review evidence and ledger with the candidate; no unrequested commit, push or canonical promotion.

Ruling: reproduce the layering principle in Blender rather than install Substance/ZBrush or download external packs. Use the already generated neutral brush atlas, with separate tone layers and selected member placements. No source colour averaging, whole-image filter, hue grade or added weathering.

Tasks:
- [x] Preserve baseline and implement layered candidate.
- [x] Save/reopen: geometry, attributes, original packed images, plaques, lighting.
- [x] Render Numaru, eaves, hero, alternate angle (8 paired images).
- [x] Browser comparison at 402px; all 4 pairs decode, controls work, no document overflow, buttons >=48px.
- [x] Independent final review; two Important findings addressed in one correction pass. Desktop check recorded separately in browser-qa.json.

Reference: https://www.pablander.academy/newsletter/a-quick-tip-to-push-hand-painted-textures

Final independent review found two Important issues: generated wood still looked like dense grain, and fixed image revision allowed stale cache. One correction pass: broad neutral-mask-driven three-tone pigment planes (80 percent wood, 45 percent lattice), retained colour signal as tooth, lower repeated fine relief; cache revision r5-final-3. Source architecture remains unchanged; all materials retain their individual profiles.

Correction detail: normalized brush-alpha quantile boundaries were widened for the material paint masks to retain a dominant midtone; each material keeps its own intensity profile. No geometry or lighting changed. The wood/lattice fill/paint values also have final overrides, recorded explicitly in verification.json rather than mislabelled as the initial profiles.

Visual outcome: source hue family and cared-for appearance retained; broad paint passes replace most dense wood grain. At 402px whole-Numaru fit, the effect is restrained. Do not claim a strong Pablander appearance has been proven at that size. Close views and full-size links are provided for the user's style judgment. Candidate approval/canonical promotion/GLB/runtime remain false.
