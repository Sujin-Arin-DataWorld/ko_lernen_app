# Hard diagonal seam — code diagnosis, 2026-10-21

Status: investigation, not visual approval. No shader, scope, geometry, binding,
lighting or render was changed. This file is the only saved addition.

## Latest evidence — supersedes the earlier normal hypothesis

Root's completed `seam-probe-normals.json` supplies 24 actual paired ground hits:
same ground object/material, scope=1, flat Z and upward geometric/face/corner
normals on both sides. Ground elevation, split normals and a different visible
ground face material are therefore excluded as the reported seam's explanation.
The screenshot match is now located on overview with scale .79, origin
(783.544,86.076), score .9899; there is no need to keep guessing its location.

I directly inspected `flat-albedo.png` from the actual saved R4 library. It has
continuous BaseColor and body contrast without the scissors boundary. That
diagnostic routes the R4 BaseColor into emission, so it excludes an albedo/tended
value jump but bypasses BSDF normal/roughness, the final original/R4 Surface Mix,
the original scene lighting and any original-scene postprocessing differences.

I also inspected the completed `actual-render-ownership.png` and its JSON. The
ground across the reported region is continuous red; the blue architecture and
stepping stones do not form the reported floor cut. A camera-visible opaque
overlay/instance changing which object is rendered is not supported by this
test. The emission override removes ordinary shadow/BSDF response and replaces
per-material Volume paths, so illumination and, if actually present, volumes or
postprocessing still require separation.

Current ranked hypotheses are: (1) an existing direct/indirect illumination or
cast-shadow boundary, made more obvious by rough soil; (2) the lit response of
the actual Bump/Roughness path; (3) denoising/compositor treatment of an existing
lighting feature. A volume hypothesis should only remain active if the actual
world/object nodes contain a connected Volume shader. Do not keep unsupported
fog explanations when an inventory can rule them out. The straight tonal edge
already visible in baseline A favours an existing lighting feature over a new
denoiser-created line, but this is still an inference, not a confirmed cause.

The next small root-owned isolation is an identical-camera/crop constant diffuse
ground material, fixed colour/upward normal/no bump, no denoising or compositor,
with the actual estate geometry and lights retained. A remaining line identifies
lighting/shadow rather than substrate values; its absence points back toward
the actual BSDF or postprocessing path. Direct and indirect diffuse evidence can
then identify which illumination component carries it. This designer did not
run that render or start another Blender process.

The separate numeric scope corner defect documented below remains real, but
scope=1 across the correctly located seam rules it out for this reported line.

## Observed evidence

I directly inspected the user's clipboard screenshot, current `overview-B.png`
and baseline `overview-A.png`. The current image has an obvious straight
smooth/rough boundary near the main Sarang stairs. Baseline A also has a straight
diagonal tonal boundary in this vicinity; R4 makes the difference in surface
reading more visible. That does not establish whether the same underlying
boundary is caused by terrain normals/elevation, illumination, a shader mask or
different visible surfaces. It is not acceptable as natural maintained earth.

## A genuine scope-mask discontinuity exists, separately from its attribution

The current convex helper does:

1. Hard membership using **all** signed halfplanes of a convex piece.
2. Feather using only that piece's external halfplane distances.
3. Multiply membership by feather, then MAX-union the pieces.

Excluding internal diagonals from feather avoids a fade on an isolated internal
edge midpoint, but does not guarantee continuity along the entire edge. An
external *infinite line* can remain close to a point whose projection lies past
the corresponding actual boundary segment. Neighbouring pieces can then have
different external feather values. Their hard membership switches which value
is available at the internal diagonal, producing a step in the union.

Additional read-only numeric testing sampled each of the eight internal edges
at 99 positions, offset 1cm to both sides. Pairs within .46m of the actual outer
boundary were excluded. Among 754 eligible pairs, four had a nonunit mask on
one side. The maximum jump was **0.0863709**, at midpoint
**(-12.068, -11.777)**, with side masks **0.9136291 / 1.0**. This proves a
localized code limitation even though the earlier 0.25m grid and eight edge
midpoints passed membership and midpoint tests. The previous strict grid found
one smaller .995328 mask value, which was honestly recorded as a failed strict
test; it did not bound the peak discontinuity between grid samples.

That worst location is near the front outer approach. It is **not automatically
the same location as the reported Sarang-stair seam**. Root must compare actual
world positions before attributing the screenshot to this defect.

### Concrete mask repair if the reported seam crosses a scope discontinuity

Separate footprint membership and outer-boundary feather:

```text
hard_scope = MAX(convex_piece_hard_membership_i)
distance = MIN(distance_to_actual_segment_j for original outer boundary edges)
scope = hard_scope * SMOOTHSTEP(0, feather, distance)
```

There is one global outer feather field, not one field per decomposition piece.
Internal diagonals cannot select different feather values. Exact segment
distance is needed; global MIN of infinite signed lines is not correct for a
concave footprint. The existing optimized halfplanes can continue to supply
hard membership. The global segment field for the 18 actual outer edges adds
roughly seven nodes per segment once; it does not require the old full ray
crossing/segment graph for every semantic polygon. This changes shading only,
preserves exact outside-zero behaviour and does not move geometry or UVs.

Before any render, test both sides of dense samples on every internal edge,
including positions near re-entrant outer corners. Membership equality and
eight midpoints are insufficient continuity checks.

## What the current root ray probes do and do not establish

I read the completed `seam-probe.json`; I did not run Blender. Its 20 samples
all hit the same source `GyeGrass.earth.v55.0 | R12 landing occupancy cut` and
source yard material, with scope=1 and interior piece 3=1. At those locations
the tended mask changes continuously, including .133083, .030738 and .000477.
These samples do not show a semantic hard cutoff.

However, all 20 samples are on the same side of the piece-3/piece-4 diagonal.
Fitting the existing ground hit XY to pixels gave a maximum fit error of about
.0026px. The internal edge [(-23.6,-3.5), (29.5,.1)] projects approximately to:

| Overview pixel X | Edge pixel Y |
| ---: | ---: |
| 820 | 236.17 |
| 900 | 196.38 |
| 1000 | 146.63 |
| 1100 | 96.89 |

The current samples at these X values begin below those rows. Root should check
whether this projected line matches the user's actual cut, then probe ±5px or
±10px across the *observed* line rather than treating all scope=1 hits on one
side as evidence against a mask seam. This projection is a flat-ground estimate;
elevated ground needs actual ray hits.

## Other causal branches and their concrete next checks

**Terrain/shading normal or elevation discontinuity:** plausible because a
straight tonal boundary is already visible in baseline A. At true paired seam
hits, record Z, evaluated polygon index/material index, geometric normal and
interpolated shading normal. Same object name/material and scalar scope=1 do not
prove these are equal. If a triangulation/split-normal artefact is confirmed and
geometry must remain frozen, a bounded shading-only normal correction on the
confirmed affected earth region is possible: supply a continuous reference
normal to the first Bump Normal input, then preserve the same bump chain. Do not
flatten intentional surveyed slopes across the whole estate. A real geometric
height discontinuity cannot honestly be declared fixed by reducing albedo grain.

**Different evaluated surfaces/materials or coordinate mismatch:** query the
actual reconstructed R4 render depsgraph, not only source R1. Source probes can
miss modifiers, different visible slot assignments or overlapping surfaces in
the candidate. If confirmed, repair the exact validated soil binding/coordinate
contract; avoid hiding it with a new painted wedge. The code uses Geometry
Position flattened to world XY, so object Generated coordinates are not intended
to control this material.

**Existing cast-shadow boundary:** compare direct-light/shadow evidence if both
paired normals and all R4 material/mask values are continuous. Shader colour
blurring is not a causal correction for a physical hard shadow. Lighting changes
would require a distinct agreed scope because the current material task preserves
the original lights. No light change is proposed for automatic execution here.

**Semantic/tended mask:** these masks have no `hard_edges` and use a clamped
SMOOTHSTEP of minimum signed distance, so their values are continuous. MIN can
change derivative along an equidistant line, but not jump in value. Steep
albedo remapping can amplify a gradient, but should not create a mathematically
discontinuous scissors cut by itself. Inspect actual exported graph values if
paired R4 pixels contradict the source equations.

## Current conclusion

There is a verified scope-helper corner discontinuity, and a visible staircase
seam that has not yet been causally matched to it. The earlier images should not
be reapproved. Use root's actual paired evaluated hits to choose the repair;
apply the global outer-segment feather repair if the seam is in the scope mask,
or correct the confirmed terrain-normal/material source if scope and semantic
values are continuous across the actual cut. No source edit or rerender was
performed during this diagnosis.
