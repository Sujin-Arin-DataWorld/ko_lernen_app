# R5 saved review candidate

User-authorized plan implemented in the existing artifact checkout; no new worktree, commit, push or canonical promotion.

Native: sarang-three-value-brush-candidate.blend
SHA256: cab144f08a7836dc0eafc074456104cdbfe21eecd46eadf2c13b882d52efd4c8

Source: ../lookdev-sarang-r3/sarang-r3-fix-checkpoint.blend
SHA256: 509ffb8a8d714663096c5c7e6d6f0d121a8720f23b281905ebf1cbe328d89c1d

Final verification: check_saved.py exited 0; 711 meshes geometry/UV/transforms/attributes/modifiers, plaques, original packed images and lighting equal. 170 used candidate materials contain independent fill/paint layers. All 8 render hashes checked. No new geometry. See verification.json.

Visual implementation: new original generated broader wood colour texture, matching original pigment mean; broad 3-value pigment planes using the existing generated brush atlas; 20% residual wood pigment detail / 55% on lattice; five selected tapered overlapping strokes on the Numaru front bearer and a column. Source colour signal was not mixed into a single uniform average as in R4. No scene lighting baked into the material. No new weathering. Exact generation prompt: PROMPTS.md; asset provenance: textures/PROVENANCE.json.

One independent final review found remaining dense grain and stale image revision. One fix pass remapped wood into broad soft colour plateaus and updated image query revision. Native and browser checks repeated after the fix. Reviewer's visual finding applied to the intermediate render; final visual check was by the implementing agent, not a second independent review.

HTML: index.html?rev=r5-final-4#numaru; four before/after pairs, slider, full-before/full-after, 402px preview. Mobile CSS 402 verified; desktop actual CSS width 1024 (requested device viewport1280). See browser-qa.json. open_in_codex returned queued, not confirmed displayed.

Remaining: user's art-direction approval. At whole-building / 402px whole-Numaru fit the brushwork is restrained; do not claim a strong Pablander appearance was objectively established. Other buildings, GLBs/construction stages, app integration and canonical promotion remain untouched.
