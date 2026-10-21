# Living R4 — whole-view compacted courtyard earth, 2026-10-21

Status: unrendered candidate. Root supplies exact inspected numeric scope and
semantic polygons, binds materials, audits geometry/UV/transforms, and renders.
This module does not run Blender, save native files, bind slots or alter a scene.

## Actual image diagnosis

I directly inspected `living-r3/full-B.png` and `overview-B.png`. The full image
shows a large nearly uniform beige ground plane; the two entrance-area broom
patches do not explain the open central/northern grounds. Fine sandy relief
helps close views but cannot drive the full-estate composition.

At the recorded 91.34m full-view orthographic width, 3–12cm features span roughly
0.4–1.7 pixels at 1280px and 0.16–0.63px at 477px, before projection and sampling
effects. The 0.3–1.5m intermediate substrate instead spans about 4–21px at 1280,
and 1.6–7.8px at 477. These are scale estimates, not rendered visibility claims.

The approved garden beds remain untouched: the source binding inventory places
`Estate.garden.arae.unplanted beds` and `Estate.garden.changgo.unplanted beds` on
a separate garden material. Root's current scope audit must confirm bindings;
historical inventories are not permission to change garden material.

## Implemented hierarchy

| Layer | Role | Guard against artificial appearance |
| --- | --- | --- |
| Continuous 0.3–1.5m substrate | irregular dry earth and powder aggregates readable in full view | two spatial phases/scales interleave; no single mean-colour Voronoi parcel |
| 2–5m envelope | changes density and consolidation | no direct large additive colour clouds |
| Front / central / north / side | different frequency, powder density and consolidation | actual semantic polygons; feathered texture-statistics transitions |
| Substrate grouping | irregular local density within the continuous texture | SmoothF1 Voronoi distance only gates density; no black edges or cell-colour output |
| Supporting 2–3cm fine sand aggregates | readable shallow granular surface | bounded value contribution; no black flecks, cell colour or coarse gravel |

The fixed warm grey-beige pigment follows R3's family. Before the first full
render, root approved a numeric correction to prevent the intermediate texture
from being multiplied back down to roughly 1% contrast. Continuous substrate
uses a smoothstep remap from Fac .425–.575 to value .90–1.10. Its colour mixing
weight remaps raw local density .15–.60 into .60–1.00. The intermediate layer
therefore has a hard maximum excursion of **6–10%**, depending on local density;
at Fac .45/.55 it reaches about 5.1–8.5%. This bounds that layer only; fine powder,
lighting, colour management and the outside blend still affect final pixels.
Actual Fac distribution, rendered mean and perceptual visibility remain unmeasured.
**An exact rendered mean or perceived colour match is not claimed.**
No new broad colour envelope accompanies this correction. There is no palette orange shift,
gravel carpet, dark route, dry-paddy crack outline or new geometry.

## Bounded fine-grain correction after actual detail render

The designer and root directly inspected the resulting `living-r4/detail-B.png`.
Broad compacted-earth organisation remained, but the surface read as blurry
cloud/velvet rather than rough sandy soil. The existing 42/m Noise field had
only .98–1.02 value range mixed at .35 (maximum about ±0.7% albedo), with
.0007 Bump distance and .13 strength. This contribution was too weak to provide
visible grain in that actual render.

Only that existing fine layer is strengthened: its Fac .25–.75 maps into value
.88–1.12, mixed at .55 for a maximum ±6.6% multiplier excursion. Bump distance
is .0035 and strength .40. Their 1.4mm product is a shader-strength comparison,
not measured mesh relief or actual displacement. The 42/m frequency remains,
representing approximate 2–3cm aggregates rather than individual sand grains.
The composition, polygons, tended statistics, broader substrate, fixed palette
and garden materials are unchanged. No new texture field, black specks,
Voronoi-cell colour or large gravel layer is introduced. This correction is
awaiting root's new identical-camera full/overview/detail verification.

R3's two broom masks are absent from the new interior graph. The original R3
graph remains reachable outside the exact supplied interior footprint. First
acceptance prioritizes the full view; any new sparse short sweep accent should
be added only when actual semantic coordinates and whole-view evidence support
it, rather than recreating the old two isolated patches.

## Semantic statistics

These profiles change substrate distribution, not a parcel's whole mean colour:

| Type | Base frequency / m | Aggregate density | Powder | Consolidation |
| --- | ---: | ---: | ---: | ---: |
| front | 2.25 | .40 | .13 | .84 |
| central | 1.45 | .62 | .18 | .50 |
| north | .87 | .45 | .23 | .63 |
| side | 1.85 | .75 | .30 | .39 |

Frequencies are Noise parameters rather than exact periodic wavelengths. Each
profile has two fixed-frequency continuous fields, blended across zone masks.
Modulating frequency by a world-position mask was deliberately avoided: that
would compress coordinates into fine bands at semantic boundaries.

## Interface and exterior preservation

```python
new_material = patch_soil(original_material, scene, [
    {'name': 'estate interior', 'type': 'scope', 'polygon': [[x, y], ...],
     'feather': 0.30},
    {'name': 'open central yard', 'type': 'central', 'polygon': [[x, y], ...],
     'feather': 2.0},
])
```

`zones` is a list of named polygon dictionaries. A wrapper dictionary with a
`zones` list is also accepted. `interior`/`scope` polygons define the final
replacement footprint. Without an explicit scope, semantic polygons define the
replacement union. Overlapping semantic profiles blend in supplied list order.

The first arbitrary-polygon graph allocated about 34 GB of private memory on a
16 GB host. Root interrupted that process; the full frame and receipt had in
fact just saved (165.85 seconds for the frame). It is retained under
`first-visible-trial/`, with its library under `failed-complex-mask/`.
The final helper accepts convex polygons and uses normalized signed halfplanes,
approximately two nodes per edge. `simplify_scope.py` decomposes the original
concave footprint into nine convex pieces with identical total area. Internal
edges use `hard_edges` inclusion with no feather; exposed edges fade inward.
The union avoids diagonal seams. Outside the footprint the mask is zero, apart
from a numeric inclusion tolerance of one micrometre on internal halfplanes.
The material copies all
original nodes and keeps the original Surface source as one side of a final
Mix Shader. Original Volume/Displacement output connections are untouched.
Root must supply correct scope; no shader mask can infer historical courtyard
boundaries from a camera image.

No target-object/material equality assertion exists: multiple validated ground
materials can use this function. No object node, UV map, external image, driver,
new mesh or scene reference is introduced. All zone data becomes numeric shader
constants. `scene` remains part of the agreed caller interface and is not mutated.

## Root's acceptance sequence

1. Compare full-view A=current R3 and B=R4 with identical camera, lighting,
   samples, seed and colour management, first at 1280px and then at 477px.
2. In B alone, central/northern/approach earth should have different aggregate
   density and consolidation. No isolated broom patch should carry this claim.
3. Reject broad brown clouds, evenly coloured stone/map cells, dark cracks,
   repeated stamps, field-like furrows, universal grit or a perimeter dirt band.
4. Architecture retains priority. Whole-view material acceptance precedes close
   inspection of supporting fine grain.
5. Verify unchanged garden materials and geometry/UV/transforms, original graph
   and exterior preservation, plus library reconstruction. These integrity
   checks do not establish visual success.

## Validation

Only source edits and static Python syntax inspection are performed by this
designer. Blender node construction, exact scope/interior handling, exported
library reconstruction, the actual exterior comparison and all rendered visual
claims remain root's verification work.

Final rendered texture review, 2026-10-21: I directly compared the archived
`second-visible-consolidated/detail-B.png` with the current `detail-B.png` at
1280px, then inspected the current `full-B.png` reduced in memory to 477px.
The current detail has a visible fine granular surface over the previously
blurred/velvety earth, including the quiet open approach; it reads as sandy
mineral aggregate rather than large gravel, black-and-white speckle or outlined
Voronoi stones. The grey-beige family, architectural priority, broad compacted
circulation areas and rougher residual areas remain visually consistent with
the preceding composition. At 477px individual grains naturally merge into the
surface finish; the full view communicates the larger maintained/rough density
distribution rather than identifiable grains. Larger mottled groups remain
visible in residual peripheral/northern ground, so complete naturalness of
those groups remains an art-direction/user judgement. This is a rendered
candidate texture improvement, not user approval, historical material proof,
Flutter integration or device validation. This review added no source edit,
new render or saved image derivative.
