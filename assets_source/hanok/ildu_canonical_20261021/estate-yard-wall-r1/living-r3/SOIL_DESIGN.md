# Living R3 courtyard soil — 2026-10-21

Current code is **revision 2**, awaiting a new render. The first R3 render was
inspected and rejected for uniform carpet-like grain and unlocatable use states.
Root owns integration, geometry/binding
audits, rendering and visual acceptance. No native source or existing material
was modified by this module. No render, save, commit or push is performed here.

## Diagnosis and decision

I inspected the actual `entry-pilot-r2/detail-B.png` and `overview-B.png`, the
visibility diagnosis, `build_surfaces.py:ground`, `repair_soil.py`, and the R2
patch. `material_patch.py` is the portable export/reconstruction script, not the
soil authoring function. The R2 images read as broad blurred clay pigment;
their weak relief and local compaction cannot communicate maintained sand.

The newly explicit sand/roughness request replaces the previous excessive
smoothing. Preserve the warm beige soil family and let grain density, shallow
relief and broken sweep direction tell the use story. No orange/terracotta
increase, gravel carpet, continuous dark road, tile, repeating wave or regular
rake stripe is used.

## Revision 2 after actual first-render review

I directly inspected `living-r3/detail-B.png` and read `VISUAL_REVIEW.md`.
The first version improved sandy roughness but spread similar fine grain across
nearly every visible surface. Random swept masks did not reliably intersect
visible ground; the existing stone anchors also omitted the open door approach.

Revision 2 uses the following explicitly locatable states. Positions below are
world XY values verified by root against the actual detail image:

| State | Actual location | Changed treatment |
| --- | --- | --- |
| Swept exposed sand A | pixel (250,350), world (-1.153,-8.984) | broad asymmetric finite group, short oblique value fragments and stronger sand relief |
| Swept exposed sand B | pixel (1080,750), world (-10.497,-8.838) | different direction and unequal companion lobe, no repeated patch stamp |
| Trodden approach | R2's three unequal lobes centred near (-6.30,-10.90), (-5.18,-9.75), (-4.36,-8.65) | grain and normal density reduced by up to 80%; mean pigment unchanged |
| Quiet ground | outside these swept/tread masks | sand color weight .12 and aggregate bump strength .09, substantially quieter than first-pass .58/.62 |

The swept mask has finite support and deliberately lies on visible ground.
Low-frequency Noise only softens its irregular strength; it no longer decides
whether a swept state exists. No broad color wash, dark road or additional
fine-grit increase is used to identify the states. Swept sand raises color weight
toward 1 and aggregate normal strength toward .78; actual feathering lowers
their local maxima. Tread retains very low grain rather than wet sheen.

## Implemented material hierarchy

| Scale | Shader treatment | Intended reading |
| --- | --- | --- |
| Site scale | restrained inherited warm pigment | quiet maintained whole |
| About 65% quiet ground, design target | finite visible swept groups surrounded by strongly quieter ground | architecture keeps priority |
| 15–55cm | two nonperiodic oblique Noise fields; short fragments only | locally swept loose sand |
| 15–35cm | sparse aggregate-density value modulation inside swept patches | irregular texture groups surviving small review size |
| 3–12cm | world-coordinate sand Noise in both value and chained bump | sand is visible under diffuse light |
| 5–8mm | restrained value/bump | fine grit without salt-and-pepper gravel |
| Existing stone and doorway approaches | unequal finite masks from numeric stone centres plus three doorway lobes | locally consolidated tread at unchanged mean pigment; grain still remains |

The quiet-ground percentage is a design target, **not yet measured rendered
coverage**. Shader Noise frequencies describe approximate visual footprints,
not fabricated physical individual grain diameters. The cm layers are aggregate
groups; actual fine grit stays in the millimetre layer. Density and swept
fragments supply medium-scale evidence when the fine sand averages out.

Roughness remains dry and matte (roughly .84–.97). Sand relief uses 7mm Bump
distance with strength .018–.78 depending on state; these are shader parameters, not actual mesh
height. The swept normal is local, and no displacement is connected.

## Integration contract

```python
from soil_patch import patch_soil
obj = scene.objects['GyeGrass.earth.v55.0 | R12 landing occupancy cut']
new_material = patch_soil(obj.material_slots[0].material, scene)
# Caller audits then binds only this target slot using its existing safe policy.
```

`patch_soil(original, scene)` validates the target/slot, copies `original`, builds
the new node tree, and returns the material. It leaves bindings unchanged.
All 23 stone anchors are numeric values read from R1's existing
`compacted-soil-anchors.json`; doorway/sweep lobes are also numeric. No object,
image, UV map, external node group,
driver, Geometry Nodes attribute or texture-file dependency is introduced.
Geometry Position is in world space and flattened to XY for continuous metre
coordinates. All non-target materials, geometry and transforms remain caller
owned. Expected R1 source SHA:
`586b8a5328e7c0deaeff5f340639708c927ea224a429aca70dc313adadddff68`.

## Review gates for root

Compare the original and candidate under identical cameras, lighting, samples,
seed and color management. Inspect a single candidate image before A/B blinking.

1. At 1280px: visible mineral sand and occasional short sweep fragments;
   shadowed surfaces must retain grain without looking like coarse gravel.
2. At 477px: uneven 4–12px bundles should communicate tended sand. Increasing
   fine grit alone is not an acceptable repair if those bundles disappear.
3. Most ground should remain calm; sweeps must not become long parallel stripes,
   threshold halos, or a new dark route. Tread differs mainly in grain density.
4. Preserve R1 beige family. No broad road, excessive orange, glitter or wet sheen.
5. Exact source SHA, target slot, all other material bindings, geometry/UV/
   transform equality, and exported library reconstruction remain separate
   integrity gates. Passing them does not establish visual acceptance.

The art director specifically requested 15–35cm sparse density groups if tiny
grain cannot survive reduction; this is implemented in addition to the sand.

## Sources and validation status

Primary Blender manual pages were requested on 2026-10-21 for Geometry Position,
Noise and Bump, but the web fetch returned 402 and supplied no readable content:
[Geometry](https://docs.blender.org/manual/en/latest/render/shader_nodes/input/geometry.html),
[Noise](https://docs.blender.org/manual/en/latest/render/shader_nodes/textures/noise.html),
[Bump](https://docs.blender.org/manual/en/latest/render/shader_nodes/vector/bump.html).
Current source scripts supply the established node/socket API precedent.
Python `ast.parse` syntax validation passed on 2026-10-21 after revision 2 (one public
`patch_soil` function). Blender node construction, library portability and visual
outcomes still need root's actual run.
