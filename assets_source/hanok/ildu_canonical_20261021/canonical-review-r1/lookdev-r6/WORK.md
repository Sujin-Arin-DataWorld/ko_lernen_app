# R6 execution ledger — user plan 2026-10-22

Scope: implement the first review gate, Jung joint/post and Sarang numaru/eaves/paper. Geometry, UV, stage attributes, plaques and accepted seam backing fixed. Photo4–6 bright pine, photo3 depth. Original timber detail restored, independent brush mix wood15% lattice8%. Native and matched three-way renders required before human review. Estate-wide expansion and GLB stage conversion explicitly follow this visual gate; R5 authority remains unchanged until then.

Existing workspace retained by user instruction; no new worktree. Publication baseline381f3dbb19b95e1adf98093c262398e1218cce83. Native helper verification reused for geometry/UVs/materials/attributes. No image editing; rendering actual Blender materials.

- [x] Inspect original material donor links and current R5 bindings.
- [x] Restore differentiated material graphs and save/reopen pilot candidates.
- [x] Render matched control/R5/R6 pilot comparisons and examine visuals.
- [ ] Browser QA and independent final review; deliver first gate.

Ruling: user plan's explicit first visual approval gate governs scope; do not promote or expand before that review. Existing artifact checkout has other WIP and is deliberately retained. Archive/reference geometry is never swapped into candidate geometry.

## Live continuation 2026-10-22

The user subsequently approved the visible pine direction repeatedly ("훨씬 좋아졌다") and requested every material and small roof/joinery detail; latest message says keep the plan. First visual-direction gate is now met. Proceed with remaining native variants and stage conversion, retaining R5 authority until explicit promotion. No new worktree, no commit/push/promotion in this R6 task yet.

Pilot refinements:
- Actual source longitudinal/trim atlases restored; 80% broad-plane replacement removed. Wood15%, lattice8% thin independent brush.
- Corrected cap regression using original packed 16-swatch endgrain and existing cap UV/cut masks.
- Initial phase change affected a retained legacy texture, not the final source atlases. Fixed the ACTIVE atlas path with safe per-member in-cell cropping, varying position and scale; original UV bytes unchanged.
- All material families have separate settings in material_profiles.json. Full used-face audit: Jung92,325; Sarang599,487 (24 explicitly retained plaque/backing faces). Must rerun audit after latest native rebuild.
- Roof-gap ray probe identifies the black band as existing roof underside boarding, not missing geometry. Added matched low-angle underside comparison render; no architectural edits.
- Preserved first liked pine checkpoint in checkpoint-first-pine/. Current candidates remain separate from all17 R5 canonical natives.

Ongoing jobs at this checkpoint:
- run_pilots.py session12871: final atlas-phase pilot renders finished or finishing; check logs.
- run_expansion.py session50528: remaining15 native candidates, sequential and resumable; expansion-state.json and per-key logs are authoritative.
- render_eaves_under.py session80259: three matching old/R5/R6 low-angle renders, appends3 entries to Sarang manifest.

Next: finish pilot delivery QA and updated material audit; render remaining native variants; convert every stage model with actual baseColor/roughness/normal and preserve source IDs. Existing exporter needs Random Per Island retention before joined baking; reviewer researching official Cycles algorithm. Native/render/GLB/Flutter claims remain separate. Flutter not in scope.

## User correction 2026-10-23: timber harmony

User identified alternating timber tones in Sarang numaru lower boarding and digitally smooth projecting fascia. Suspended old run_expansion queue; ansarang/anchae/sadang were native-only and NOT visually complete. Retained both pilot natives/renders in checkpoint-pre-unity/.

Actual node diagnosis: lower boards mix legacy maintained-pine and P18 longitudinal/trim atlas. Fascia/rim are legacy-only. Atlas cell means vary strongly; legacy fibre contrast is much weaker. timber_unity.py now calibrates only longitudinal sample means, preserves within-cell relative growth-ring contrast, boosts legacy detail1.6, and leaves cut atlas/geometry/light alone. Initial additive mean subtraction caused dark clipping and was rejected; corrected to multiplicative pigment calibration. Constant-ramp lookup uses half-bin centres and wrapped Repeat coordinates. Final fast preview SHA14fbf86840c3abba365fd2b989407418758f8490822ff0e3d6753fdf5cf71302.

run_unity_delivery.py builds17 candidates with two Blender processes, each4threads. Per-building unity-receipt.json must match exact generator hashes, native SHA, render manifest and complete-material-audit. Intermediate older candidates are stale; do not resume solely from verification.json. unity-state.json is current queue state. unity-review.html shows only completed matching receipts. Finish visual reviews building by building and verify_unity_delivery.py. No canonical promotion, commit, push or Flutter change in this revision. StageGLB work follows these material corrections; original model/stage assets remain unchanged.

## 2026-10-23 illustration-detail steering

User supplied seven illustrated hanok/material references and reaffirmed human-built joinery/tile detail. Bulk unity queue parent 20180/26812 was stopped; active children angotgan/changgo finished independently. Existing saved candidates retained. No new worktree or promotion. Four unity receipts passed (sarang/jung/ansarang/sadang); anchae/arae/gokgan/angotgan used-face auditor has donor suffix .001 vs preserved R5 name mismatch, not yet reconciled. Changgo native/render/audit finished but parent receipt not written. Never report all17 complete.

Current bounded study: craft_detail_study.py on ansarang; output craft-detail-study/ansarang. Keeps original R6 native, geometry/UVs/stages/lights and existing material graphs; separately editable selected dark/light marks and tiny broken material-coloured edge cues. CRAFT_DIRECTION.md reviewed by craft_direction_check: no material unanswered questions. Final native/renders require visual review; stageGLB/Flutter unchanged.

## 2026-10-23 craft research integration

User requested proactive building-specific research including tiles, windows, hanji, garden views and small windows. Added building-craft-research-20261023/REPORT.md and APPLICATION_MATRIX.json: all16 live catalog entries +2 standalone variants mapped;6 existing survey sheets visually read with file hashes. Verified local drawing047 explicitly records perilla-oil finish and single-side paper for specified Jung windows. Kept site evidence separate from generic craft and interpretation. Legacy WB gate lists differ from the3 replacement gates; matrix uses replacement sidecars. Current working HEAD bbe88e7d22bd1893b762609ed5a8990e1e84db5a, existing WIP preserved. No Blender/native/GLB/catalog/image/runtime modifications, no render or canonical promotion in this research turn. Next: apply documented per-member material priorities in order Numaru→Jung windows→Anchae/storage contrast→remaining buildings, retaining geometry/UV/stages/door states/lettering. Do not resume broad old queues from stale WORK entries.
