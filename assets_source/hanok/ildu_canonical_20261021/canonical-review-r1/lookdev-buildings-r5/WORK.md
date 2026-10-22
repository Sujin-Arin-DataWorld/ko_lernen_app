# Building-specific R5 brush extension

User accepted Sarang R5 and requested the other buildings in the same direction, adapted to each building. Source authority is STYLE_AUTHORITY.json. Existing artifact checkout; no new worktree.

Scope: 14 other building/gate keys from current catalog (11 R12 buildings including the main gate, plus the three rebuilt gates). Sarang R5 is the accepted reference. Courtyard/walls are not buildings in this extension. Source geometry, UV layers, transforms, object attributes, stages and painted patterns/plaques are preserved.

Approach: sequential per-building native extraction, materials copied and adapted from each original colour signal; three-value hand-brush rhythm from R5. Vermilion/green/painted patterns must not be replaced with brown wood. Gates lack UVs; use stable material projection without adding UV layers. No new generated textures required. Reuse original generated R5 assets as brush vocabulary.

Storage/memory: starting free disk 5.32GB, available RAM 4.83GB. Never render the entire estate at once; one building process at a time, self-contained compressed native per building and durable per-building receipts for resume. Do not run old bulk PBR/GLB scripts.

Tasks:
- [x] Source/material classification, exact source hashes/member lists.
- [x] Adapt each of 14 keys; preserve building-specific colour/pigment.
- [x] Save/reopen and render before/after hero + another view per key.
- [x] Browser gallery, all building selections, mobile/desktop, final review.

No automatic canonical promotion, runtime integration or source overwrites. New variants require visual review; prior structure/colour approval does not imply approval of every new stroke.

## Implementation decisions and verification

- Reused the accepted R5 alpha atlas and broad timber pigment image. Each timber material derives its palette from its own original coloured ramp; no global Sarang brown or warm screen filter.
- Timber wrapper names are not material identity. Classification also checks actual image names; mixed side/endgrain atlases do not turn whole members into endgrain, and illustrated clay is clay.
- Source images keep their exact paths and packed bytes (`relative_remap=False`); original shader datablocks are kept with fake users in the candidate so Blender does not discard their unused copies on save.
- The first extraction was not accepted as complete when preservation assertions failed. The save/reopen gates exposed path remapping and Blender purging unused materials; both save issues were corrected before any completion claim.
- First visual check found the timber expression weaker than the accepted Sarang reference. Added the same R5 authored timber tooth, calibrated to each original palette, and changed the second camera to a real closer façade view.
- Verification is the meaningful gate for this art prototype: exact mesh/UV/matrix/modifier and attribute/stage/property hashes, original material graph and image-byte preservation, reopen, matched controls and actual visual inspection. No implementation-mirroring unit tests.
- No external resource packs installed, additional image generation, canonical replacement, GLB bake or Flutter changes.

## Completed

- `VERIFICATION_SUMMARY.json`: 14 native candidates, 4,396 preserved meshes, 56 actual PNG renders; source hashes unchanged; accepted Sarang R5 native unchanged. Every candidate saved and reopened successfully.
- `refine_review_cameras.py` corrected the off-centre anchae review and the rear-facing sadang review. It restored original/candidate material bindings for matched controls, updated cameras only, and repeated preservation checks. Both native hashes/receipts were refreshed.
- `FINAL_REVIEW.md`: one fresh independent reviewer examined all building outputs at least once and recomputed source/candidate/producer/render/gallery hashes; no blocking introduced material defect found. User aesthetic approval remains separate.
- `BROWSER_QA.json`: ECC browser actual mobile402x874; all15 selections,30 views,60 decoded gallery images,15 available native downloads/verification links, old100/new0/compare50/range63%, visible controls48px. Desktop requested1280x960 yielded actual CSS1024x768 under connector zoom; measured controls fit, and app-width toggle is402px. This is HTML QA, not native app/device QA.
- Deliverable: `index.html`, `gallery-data.json`, per-building packed native candidates and receipts. No new worktree, Git commit/push, canonical promotion, GLB/construction viewer export or Flutter update was performed for this extension.
