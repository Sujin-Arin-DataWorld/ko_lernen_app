# AI production handoff · English

Attach only the actual reference files needed for this job. A local path or a hash identifies a file; it does not let an external model see it. Do not use a collection of different characters as a single interchangeable face/style reference.

## Job card

```text
Project: Hangul Sori · Ildu Season 1
Job ID / scene / chapter:
Deliverable: [still composition / transparent prop / start-and-end video frames / separate action candidate]
Character ID + attached file:
Building key + process ID/number + standalone/connected variant + attached file:
Estate placement reference, only if needed:
Prop ID + role status + attached file:
Locked starting frame:
Only requested change:
Output size / aspect ratio / duration / transparency:
Separate text / voice / subtitle deliverables:
Missing references:
```

## Copy-ready instructions

```text
Preserve the attached Hangul Sori originals. This job retains existing character identities, building geometry, prop identities and materials. Make only the change named in the job card. Keep original files unchanged and save new outputs as separate derivative candidates.

Each reference governs its own subject. Character files govern that character's face, body, clothing and accessories. Building PNGs/natives govern the selected building and construction stage. The estate reference governs placement. C-direction screens govern material, layering and hierarchy. Do not copy invented text, balances or progress from mockups. Do not mix another character's face/clothes or another building's windows/roof into this scene.

Lock facial shape, eyes/nose/mouth, head/body proportions, hair, skin/fur/feathers, clothing colors/materials, knots, footwear, accessories, and the count, position and direction of each motif. Do not mirror asymmetric details. Change only the requested expression or pose. Do not add hands, wings, horns or props. Unseen surfaces and new contact actions need a verified reference; do not invent them as canon.

Taego is the calm protective white tiger in the attached file: retain individual stripe placement, blue eyes and chest emblem. Joy retains the magpie identity, gat hat, cords and chest motif; exactly two wings. Dokkaebi retains two short horns, headband, outfit and the original wooden club. TalSunbi retains the carved wooden Hahoe mask, gat, robe and folded fan. Sujin and all modern personas keep their own exact source identity. Do not replace the player with a fixed persona face.

Lock each building's plan, proportions, estate coordinates, stone base, column count/spacing, beams/rafters, door/window placement and lattices, roof curves/tiles/eaves/joints, and plaque shape/placement. Do not estimate dimensions from a PNG and redesign the structure. In Blender retain existing object names/counts/hierarchy/origins/transforms/UVs/packed textures. Do not remesh, regenerate textures or change geometry without a specific request. Use the original native for a precise new camera angle. A single PNG cannot establish an unseen side or rear elevation.

Show only the members present at the selected construction stage. Sarangchae and Jungmunganchae have separate standalone and connected roof files; use the designated variant. Side gates, shrine gate and Sotdaeulmun main gate are different assets. Door opening/bolt repair requires verified axes, contact points and start/end action references. Do not use a side-gate native as the main gate.

Retain each source's warm wood, hanji, silk, tile/stone/plaster, brass/gold and teal distinctions, tactile depth and lighting. Do not repaint all buildings with one dancheong pattern or fantasy ornament. F-A freely placed furniture cutouts must not contain a baked floor, room or ground shadow; composition shadows belong to separate scene layers. Preserve per-file transparency and cropping. Do not assume every source is a transparent full-body cutout.

The three-swirl emblem and approved_cloud_spiral UI icon are different files. Locking a file's identity does not establish its Season 1 badge role. Two light pulses do not mean two swirls. Keep guardian roof tiles, cloud badge and ordinary objects distinct. Do not stamp badge motifs, official seals or magical ornaments onto Yeoni's seeds, wick or plain cloth. A letter pouch is not a seed pouch. Longevity stationery is not the first-house note or final story letter.

Retain the same single first '집' note throughout the story and distinguish it from the '이 집' exercise. Korean/German/English instructions, questions, buttons, exact plaque lettering and letter text use the supplied manuscript in separate text/compositing layers. Do not erase or invent lettering in existing originals. Do not bake fake learning progress, rewards or wallet balances into UI art. Nevi_Bar5 uses five image-only icons without new visible labels.

Use only the chapter/process moment named in the job card. Do not show the completed house, first lamp or awakened state before its story event. Do not introduce the completion storm or 30-percent memory during the middle-gate roleplay. Preserve the manuscript's clue, letter and final-greeting reveal order. Artwork/video does not grant learning credit, construction progress or currency.

For video, use locked starting/ending references and only the requested movement. Reject identity drift, changing roof/window geometry or morphing emblems between frames. Avoid continuous motion while the learner reads. Deliver dialogue, sound and subtitles in separate editing layers, plus a silent/still-poster alternative.

Deliver an input filename/SHA-256 list, retained details, actual changes, unresolved references, a comparison under matching conditions or key frames, and layered/editable project files. Never overwrite the originals. Mark missing role/action references SOURCE_PENDING rather than substitute a generic asset. New outputs remain unreviewed derivatives; do not claim canonical approval, app integration, device validation or release completion.
```

## Minimal attachment examples

| Job | References | Unresolved boundary |
|---|---|---|
| TalSunbi reaction | `01_core/character_talsunbi.png` + a selected existing pose | Awakening/new hand action requires its own reviewed action frames |
| Middle-gate roleplay | Dokkaebi + `03_buildings/jung_stage06_identity_only.png` + placement if needed | Stage 06 is a geometry reference, not a confirmed runtime mapping for the narrative midpoint |
| Main-gate epilogue | Dokkaebi + `04_gate/sotdaeulmun_approved_art03.png` | Main-gate bolt/hinge/action references are pending; do not invent rear geometry |
| First book/note | Character + selected existing room/prop references | Exact story-book/note/interior role assignment remains pending |
| App mockup | Relevant subject files + `05_style/hanok_direction_N0020.png` + materials | Use screen as direction; do not crop UI fragments or reproduce its invented text/amounts |

Prompts communicate constraints; they do not guarantee identity or architectural fidelity. Prefer composition from original PNGs and native Blender rendering where structure must remain exact, then compare the output. This document does not execute generation, uploads, purchases or app changes.
