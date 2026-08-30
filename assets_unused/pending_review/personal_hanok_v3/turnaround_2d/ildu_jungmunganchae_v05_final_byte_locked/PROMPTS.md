# V05 prompt record

Mode: built-in `image_gen`

Use case: `precise-object-edit`

## Shared immutable lock

- Reference image 1 is the immutable master and sole visual identity authority.
- Preserve its exact building: proportions, single straight body, single matbae roof and ridge, timber, plaster, stones, stairs, giwa, lighting, linework, and muted hand-painted game-asset style.
- Rotate only the camera. Do not redesign, simplify, replace, mirror, or add architecture.
- Front physical left-to-right is immutable: closed vertical-plank double door with two ring handles; paired vertical-lattice window (`04 WD`, about 1080×1020); small low horizontal lattice window (`01 WW`, about 900×580); open maru bay at the right.
- Never turn the left door into an open passage. Never swap the two windows. The second window is only slightly wider than the third but clearly much taller; never turn it into the unrelated 2005-wide four-panel opening.
- Rear straight-view order is locked to the rear elevation: closed vertical-board bay without ring handles; small narrow vertical lattice window; large tall paired lattice assembly; one open structural/maru bay only at the extreme right.
- Physical right gable is the plain plaster end already visible in the master, with no side opening. Physical left gable uses the elevation's plaster upper field and lower vertical timber boarding, with no door or window.
- Keep exactly one long ridge and one roof. No L-shape, annex, second ridge, second roof volume, courtyard wing, or detached object.
- References 2+ are archival geometry checks only and do not override the master image's facade or art style.
- Isolated object, transparent background, no ground plane, scenery, vegetation, people, text, labels, frame, watermark, or checkerboard.

## Direction plan

`00_front_source_exact.png` is the byte-identical reference and is not one of the generated directions.

Every generated direction uses the same orthographic-style camera distance. The optical axis is tilted 28 degrees away from straight vertical downward, equivalent to an elevation of 62 degrees above the horizontal ground plane, and aimed at the building center.

For diagonal views, the near roof plane and the opposite roof plane must both be readable while sharing one and only one central ridge. A far eave must never be interpreted as a second ridge.

1. `00_front_000.png`: front azimuth 0°.
2. `01_front_right_045.png`: front-right azimuth 45°.
3. `02_right_090.png`: physical right azimuth 90°.
4. `03_rear_right_135.png`: rear-right azimuth 135°.
5. `04_rear_180.png`: rear azimuth 180°.
6. `05_rear_left_225.png`: rear-left azimuth 225°.
7. `06_left_270.png`: physical left azimuth 270°.
8. `07_front_left_315.png`: front-left azimuth 315°.
