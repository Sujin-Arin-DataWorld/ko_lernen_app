# R5 secondary scope repair — 2026-10-21

This patch repairs the independently proven R4 scope corner discontinuity.
Root has separately confirmed the user's visible stair-area scissors line came
from a low vertical area light intersecting the floor; root owns that lighting
repair. The scope patch does not paint over or claim to fix that lighting cause.

## Interface and exact scope

```python
new_material = patch_scope(original_saved_r4_mat, full_ground_scope_dict)
```

The material is copied. Only the Fac input of the saved R4 final
`original exterior versus R4 interior` Mix Shader is rewired. All interior BSDF
colour, Noise, semantic/tended statistics, roughness, normal/bump connections and
external R3 Surface branch are retained. No material binding, geometry, UV,
transform, garden/field material, camera or light is modified. The code neither
imports Blender nor launches a process, renders, saves native files or exports.

## Why the old helper could jump

Each convex piece selected its own external infinite-halfplane feather and
clipped it with hard membership. Adjacent pieces could therefore choose
different feather values across their internal diagonal, especially near
re-entrant outer corners. Dense 1cm paired testing found a maximum scope jump
of .0863709 near (-12.068,-11.777), despite matching union area and successful
midpoint tests. That defect is separate from the confirmed area-light artefact.

## New single feather field

```text
hard_scope = MAX(hard inclusion of each convex scope piece)
outer_distance = MIN(distance to each actual finite original outer segment)
new_Fac = hard_scope * smoothstep(0, 0.45m, outer_distance)
```

The global feather width comes from `scope_feather`, or the equal `feather`
values of the supplied scope pieces. Unequal values without an explicit global
width are rejected. Semantic polygons do not enter this new footprint mask.

The true finite-segment distance clamps the projected parameter to [0,1] before
measuring point-to-segment residual length. It is not distance to an infinite
line. Thus there is only one common boundary-distance value on both sides of
every internal diagonal. Internal hard membership uses a 1µm tolerance to avoid
floating-point cracks. External halfplanes use strict outside exclusion before
the union so this tolerance does not introduce a nonzero exterior feather leak.
`hard_edges` identifies internal decomposition edges for that inclusion policy;
it no longer controls any per-piece feather. Root's validated 9 convex pieces
and original 18 outer edges remain numeric shader constants.

## Verification ownership

Static Python syntax is checked by this designer. Root should verify actual
node construction and exported material reconstruction, compare every preserved
BSDF connection/signature, and repeat dense paired-edge and outside-zero tests.
The former worst corner must have a single continuous feather across the
diagonal; unlike the previous helper, its value may legitimately be below one
only according to its actual outer-boundary distance. Root owns final lighting
and material renders and native safety evidence. No visual acceptance or user
approval is asserted here.
