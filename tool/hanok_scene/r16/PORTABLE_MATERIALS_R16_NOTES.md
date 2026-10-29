# Portable R16 material adapter

`portable_materials_r16.apply(scene, buildingKey, masterMaterials)` takes the explicit 17-role material map from `sarang-wood-r16/material-masters.json`. Role keys are authoritative; source masters and their tags are never edited. The returned receipt includes every actual assignment, preserved slot, source material, template, schema and coordinate adaptation. `MappingError.receipt` contains all detected gaps. No slot changes occur until all used slots pass preflight; assignment-stage failures roll back their OBJECT overrides.

Wood keeps the R16 template pigment, knot branch and downstream R15 per-member crop. The old source `Craft authored wood detail` Vector DAG is grafted at the pre-crop ingress. Changgo/toilet/toilet1 use explicit existing original directional image-coordinate branches, bounded to the same wood-only atlas quadrant (X .02-.48, Y .52-.98), or an existing directional UV. Missing directional paths fail visibly; the explicit object-local projection helper uses the actual longest local mesh axis. P18/HS member and cut attributes are adapted in shader copies only. Absent cut masks are explicitly recorded as zero. Nonwood taps adapt to existing original surface UV, surface attributes or original object-coordinate paths. Actual paper-floor copies have zero emission; window paper remains the supplied master.

All changed slots link OBJECT copies, cached by role, old material, source schema and any required projection bounds. Explicit preservation/paint/metal/earth/wax/fibre/backing and lettering are retained. Sadang requires exactly 105 preserved paint slots. Mesh data, names, UVs, attributes, hierarchy, transforms and scene controls are not written.

## Read-only Blender verification, 2026-10-28

Blender 5.2.2 background, two threads; final R16 master SHA-256 `42da8586f04bf89ae7e90c79ea39c0b72bea9a10f86ebc9d29846b2c85466037` verified before loading. All eleven canonical sources completed in-memory transfer with zero mapping errors and unchanged source mesh/schema/hierarchy/transform guards. No native save or render was called.

| Canonical key | Changed slots | Copied materials |
|---|---:|---:|
| sarang | 972 | 235 |
| ansarang | 462 | 126 |
| anchae | 931 | 151 |
| sadang | 113 | 32 |
| jung | 304 | 109 |
| arae | 288 | 99 |
| gokgan | 125 | 64 |
| angotgan | 124 | 61 |
| changgo | 162 | 76 |
| toilet | 108 | 49 |
| toilet1 | 110 | 52 |

Sadang retained all 105 protected paint slots. Changgo used 65 original directional wood-vector copies and one existing directional UV copy; toilet/toilet1 used 40/41 original directional wood-vector copies. The fallback object-local wood projection was not required by these eleven sources. One subsequent correction makes that unused helper choose the longest local axis for columns too. Rendered visual review, native save/reopen, full geometry/binding hashes, approval and runtime integration belong to the calling production driver.

## Actual-render corrections

The first rendered family exposed two coordinate defects that the schema-only transfer probe could not detect. Source HS/P18 longitudinal coordinates are packed 4x4 atlas addresses (confirmed in `lookdev-r6/build_pilot.py`, `wood_phase`); encoding the whole address directly into the Craft wood quadrant shrank each member's grain to a small patch. Non-craft source longitudinal coordinates now decode `FRACT(UV * 4)` before re-encoding; trim atlases use their documented 8x1 grid. Source mesh UVs and attributes stay unchanged.

Anchae's three joined square-post objects were classified as beams, and their source Craft selector mapped atlas Y from local Y, with atlas X from local Z or local X depending on the assembly extents. Their assemblies span many upright posts in Y, so an object-extent choice had made the grain run horizontally across them. Square posts now classify as columns. Only the copied legacy selector, when its direct original SeparateXYZ inputs and upright local Z are verified, maps atlas X from local X+Y and atlas Y from local Z. Existing directional grain UVs are not rotated. Explicit floor girders/joists classify as structural beams before generic floor-name matching.

The exposed maru pink cast was not a wrong material assignment: Ansarang used the actual R16 `floor` master, with live HS12 floor palettes and correct Craft coordinates. Per root art-direction, non-Sarang floor copies alone receive an additional final Base Color linear RGB multiplier `[0.94, 1.20, 1.0]`, recorded as `other-building-exposed-maru-pigment-balance`. No other timber role, light, exposure, or frozen Sarang master changes. Palette A mid is linear RGB `[0.31854677, 0.08650046, 0.01228649]`; existing R16 floor HS13 gain is `[0.86, 1.16, 1.90]` before this additional copy-only balance.

Final focused read-only Blender probe passed with the corrected adapter: Anchae 931 slots (6 column slots, 20 floor slots; 4 copied axis corrections and 15 floor calibrations); Changgo 162 slots (17 packed swatch decodes and 2 floor calibrations); toilet 108 slots (40 packed swatch decodes); toilet1 110 slots (36 packed swatch decodes). Explicit assertions checked square-post column roles, floor-girder/joist beam roles, packed source decoder presence and one final calibration per floor copy. Source mesh/schema/hierarchy/transform guards all passed. No native save or render was called. Corrected module SHA-256: `ff4e4b1e46a1b78cadf8a22fd753b2b5c10a219ae9669f8ea782a307a79670fc`.
