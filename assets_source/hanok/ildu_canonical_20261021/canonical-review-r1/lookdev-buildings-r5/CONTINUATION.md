## Completed checkpoint

Both pipelines exited successfully. All 14 native candidates / 4396 preserved meshes / 56 renders and 15 gallery entries passed. FINAL_REVIEW.md has no blocking introduced defect. BROWSER_QA.json confirms all15 selections /30views /60images and native links, mobile402 and desktop controls. WORK.md tasks are complete. No active render remains. Exact checkout HEAD: bbe88e7d22bd1893b762609ed5a8990e1e84db5a. Candidates remain uncommitted review artifacts; no promotion, GLB/construction runtime or Flutter update. Next dependent decision is user visual review.

# Active R5 building extension — 2026-10-22

User accepted Sarang R5 and requested the same brush material direction for each other building. Do not change architecture, source files, stage data, existing shrine paint/patterns, or the accepted Sarang native. No new worktree. Deliver building-specific native candidates and comparison gallery; no automatic canonical/GLB/Flutter promotion.

Working directory: this folder (`lookdev-buildings-r5`), inside the existing drawing-r4 artifact checkout. Source hashes/names: `source-audit.json` (14 targets). Approval: `STYLE_AUTHORITY.json`. Accepted reference: `../lookdev-sarang-r5/sarang-three-value-brush-candidate.blend`, SHA256 `cab144f08a7836dc0eafc074456104cdbfe21eecd46eadf2c13b882d52efd4c8`.

Implementation: `restyle_building.py` version building-r5-2, `material_rules.py`. Reuse R5 authored brush alpha and timber colour image, adapt each original coloured ramp, retain original colour signal, preserve all original shader graphs and images in each candidate. Gates have no UVs: new strokes use rigid object coordinates. `run_queue.py` processes one building at a time due limited RAM; each produces a compressed packed Blender candidate, four PNGs, verification and render manifests. Save/reopen gates have passed so far. Initial save issues were fixed, documented in WORK.md.

Active processes at this checkpoint:
- Unified exec session 53341: serial remaining building queue. Logs `queue.log`, per-key `*.log`. Currently main_gate completed, left_changgo started; right_ansarang follows.
- Unified exec session 21039: `finish_queue_cameras.py` waits for `QUEUE COMPLETE 12` in queue.log; then runs camera-only corrections for anchae and sadang and `finalize_extension.py`. Check `finish.log` and `*-camera.log`. It launches no Blender until the first queue has fully ended.

Camera corrections are required: anchae was off-centre in the first render; sadang showed its rear instead of sanctuary/painted façade. `refine_review_cameras.py` restores original materials for matched controls and then candidate materials, changes cameras only, saves/reopens and updates receipt hashes. Do not regenerate all materials for this.

Remaining work:
1. Wait for both pipelines, inspect camera corrections and last gates; fix any concrete errors.
2. Run/confirm `finalize_extension.py`: 14 native candidates, 4396 preserved meshes, 56 PNG renders. Builds `gallery-data.json` with 15 entries including approved Sarang.
3. One fresh final reviewer required by executing-plans skill; no per-building implementation agents. Reviewer can inspect receipts/script/material direction and actual images; no edits/new renders.
4. Final browser QA using ECC Chrome DevTools page 6: all 15 selections, both views, all 60 gallery images decode, controls, mobile402 and desktop. So far initial10 entries/20views/40images passed; mobile402 scrollWidth402, visible buttons min48px, range64% and old100/new0/compare50 passed.
5. Mark WORK tasks done, current status/handoff, open comparison link in app, short honest final: native review candidates, not GLB/construction/Flutter updates. No commit/push requested for this extension.

Gallery URL: http://127.0.0.1:8866/surface-redesign-20261018/gate-rebuild/drawing-r4/canonical-review-r1/lookdev-buildings-r5/index.html
Shared server8866 must not be restarted/killed. ECC browser page6 currently mobile402x874x1. Use image content blocks directly; never print screenshot base64.

Final must append one memory citation: MEMORY.md:84-84, note Preserve researched architecture during material changes; empty rollout_ids. Only this memory line was used in this task.
