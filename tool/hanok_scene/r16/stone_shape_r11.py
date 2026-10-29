"""Bounded, deterministic geometry refinement of the 220 R10 display stones.

Call refine_stones(scene) in the caller's already-open R10 candidate. This module
does not open/save a blend, render, change materials, or modify source objects.
It retains UVs, object names, transforms, and construction_parent. Wall display
meshes freeze R10's original loop triangulation so Blender cannot choose new
diagonals in the source's concave/nonplanar 18-sided polygons after deformation.
V3 allows wall-stone AABBs to change with a shared joint field. Foundation ground,
top bearing bands and all stair/slab/cheek meshes remain fixed. Every nonzero
source triangle is checked after float32 storage; meshes stay closed.
"""

import hashlib
import json
import math
import random
from array import array
from pathlib import Path


VERSION = "r11-shape-3"
ROOT = Path(__file__).resolve().parent
MAX_RECESS = 0.025
JOINT_AMPLITUDE = 0.030
FAMILIES = (("main foundation", 1.016, 3), ("numaru foundation", 0.38, 1),
            ("left terrace", 1.10, 3), ("front apron", 1.10, 3),
            ("stair landing", 1.28, 3), ("numaru front apron", 0.43, 1),
            ("numaru inner apron", 0.43, 1))


def _wall_spec(name):
    return next((s for s in FAMILIES if name.startswith("HS10 " + s[0] + " ")), None)


def _joint_delta(x, y, z, height, rows):
    if rows == 1:
        return 0.0
    weight = _smooth(0.04, 0.12, z) * (1.0 - _smooth(height - 0.12, height - 0.04, z))
    wave = 0.70 * math.sin(0.95 * x + 0.33 * y + 0.55)
    wave += 0.30 * math.sin(1.61 * x - 0.48 * y + 1.0)
    return JOINT_AMPLITUDE * wave * weight


def _joint_warp(name, points):
    spec = _wall_spec(name)
    if spec is None:
        return points
    return [(x, y, z + _joint_delta(x, y, z, spec[1], spec[2])) for x, y, z in points]


def _seed(name):
    return int(hashlib.sha256((VERSION + name).encode()).hexdigest()[:16], 16)


def _smooth(a, b, value):
    t = max(0.0, min(1.0, (value - a) / (b - a)))
    return t * t * (3.0 - 2.0 * t)


def _bounds(points):
    return tuple(min(p[a] for p in points) for a in range(3)), tuple(
        max(p[a] for p in points) for a in range(3)
    )


def _deform_coordinates(name, points, normals, strength=1.0):
    """Pure numerical kernel; all moves stay inward of the original AABB."""
    rng = random.Random(_seed(name))
    wall = _wall_spec(name)
    lo, hi = _bounds(points)
    dim = tuple(hi[a] - lo[a] for a in range(3))
    if min(dim) <= 0.02:
        raise ValueError(f"Unexpected thin/degenerate R10 stone: {name}")
    center = tuple((lo[a] + hi[a]) * 0.5 for a in range(3))
    # Preserve a small neighbourhood of every original AABB witness, avoiding
    # a single pointed vertex left behind by an otherwise eroded surface.
    anchor_ids = {
        fn(range(len(points)), key=lambda i: points[i][axis])
        for axis in range(3)
        for fn in (min, max)
    }
    anchors = [points[i] for i in sorted(anchor_ids)]
    anchor_radius = min(0.055, min(dim) * 0.16)
    edge_width = rng.uniform(0.045, 0.075)
    edge_depth = rng.uniform(0.012, 0.022)
    broad_depth = rng.uniform(0.004, 0.009)
    face_recess = rng.uniform(0.004, 0.012)
    front_axis, front_sign = (0, -1) if " left course " in name else ((0, 1) if " right course " in name else (1, 1) if " rear course " in name else (1, -1))
    phases = [rng.uniform(-1.0, 1.0) for _ in range(3)]
    # Two large, oblique tool planes per vertical side. Their intersection is
    # piecewise planar; no new high-frequency noise or identical roundover.
    planes = [
        [(rng.uniform(-0.8, 0.8), rng.uniform(-0.65, 0.65),
          rng.uniform(-0.30, 0.05)) for _ in range(2)]
        for _ in range(4)
    ]
    chips = []
    for _ in range(rng.randint(2, 4)):
        axes = rng.choice(((0, 1), (0, 2), (1, 2)))
        free = next(a for a in range(3) if a not in axes)
        chips.append((axes, free, (rng.choice((-1, 1)), rng.choice((-1, 1))),
                      rng.uniform(0.16, 0.84), rng.uniform(0.065, 0.13),
                      rng.uniform(0.015, 0.025)))
    # The joined, measured stair cheeks include sloped bearing edges. Their
    # outline receives a much smaller treatment than individual masonry blocks.
    if "measured solid stair cheeks" in name:
        strength *= 0.30
    result = []
    bearing_count = 0
    for index, (point, normal) in enumerate(zip(points, normals)):
        distances = [min(point[a] - lo[a], hi[a] - point[a]) for a in range(3)]
        q = [(point[a] - center[a]) * 2.0 / dim[a] for a in range(3)]
        if wall and (point[2] <= 0.04 or point[2] >= wall[1] - 0.04):
            result.append(tuple(point))
            bearing_count += 1
            continue
        # Preserve the interior of both bedding planes, including stair treads.
        support = (_smooth(0.020, 0.055, distances[0])
                   * _smooth(0.020, 0.055, distances[1])
                   * (1.0 - _smooth(0.008, 0.035, distances[2])))
        bearing = support == 1.0
        if bearing or index in anchor_ids:
            result.append(tuple(point))
            bearing_count += int(bearing)
            continue
        nearest_anchor = min(math.dist(point, a) for a in anchors)
        preserve = (_smooth(anchor_radius * 0.25, anchor_radius, nearest_anchor)
                    * (1.0 - support))
        recess = [0.0, 0.0, 0.0]
        for axis in range(3):
            other = [a for a in range(3) if a != axis]
            surface = 1.0 - _smooth(0.0, edge_width * 1.7, distances[axis])
            if surface <= 0.0:
                continue
            adjacent = min(distances[a] for a in other)
            edge = 1.0 - _smooth(0.0, edge_width, adjacent)
            tangent = max(other, key=lambda a: dim[a])
            # Low-frequency asymmetric lip width changes along each stone.
            wave = 0.5 + 0.5 * math.sin(q[tangent] * 2.35 + phases[axis] * math.pi)
            lip = edge_depth * edge * (0.32 + 0.68 * wave)
            broad = 0.0
            if axis < 2:
                u = q[1 - axis]
                v = q[2]
                side = axis * 2 + int(q[axis] > 0.0)
                values = [a * u + b * v + c for a, b, c in planes[side]]
                maximum = (sum(values) + math.sqrt((values[0] - values[1]) ** 2
                                                  + 0.015 ** 2)) * 0.5
                broad = broad_depth * _smooth(-0.03, 1.0, maximum)
            recess[axis] = surface * (lip + broad)
            if axis == front_axis and q[axis] * front_sign > 0.0:
                recess[axis] += surface * face_recess
        for axes, free, signs, along, width, depth in chips:
            corner_dist = sum(
                (hi[a] - point[a] if sign > 0 else point[a] - lo[a])
                for a, sign in zip(axes, signs)
            )
            lateral = (point[free] - (lo[free] + dim[free] * along)) / width
            # The wedge has a continuous slope at its boundary, so neighbouring
            # micrometre-height bevel slivers are not split across a hard mask.
            chip = depth * (1.0 - _smooth(0.0, 1.0,
                                         lateral * lateral + (corner_dist / 0.050) ** 2))
            for axis in axes:
                recess[axis] = max(recess[axis], chip)
        moved = []
        for axis in range(3):
            amount = min(MAX_RECESS, recess[axis]) * strength * preserve
            if axis == 2:
                # Large top/bottom polygons interpolate their edge vertices:
                # locking only interior vertices still opens the whole joint.
                # Keep the complete 25mm bedding ring on the shared course
                # surface; local chips may cut its XY outline, not its height.
                amount *= _smooth(0.025, 0.055, distances[2])
            sign = 1.0 if point[axis] >= center[axis] else -1.0
            moved.append(max(lo[axis], min(hi[axis], point[axis] - sign * amount)))
        result.append(tuple(moved))
    if _bounds(result) != (lo, hi):
        raise AssertionError(f"Stone envelope changed: {name}")
    return result, {"seed": _seed(name), "bearingVerticesLocked": bearing_count,
                    "bboxWitnessVerticesLocked": len(anchor_ids),
                    "edgeDepth": edge_depth, "broadDepth": broad_depth,
                    "chipCount": len(chips), "strength": strength,
                    "frontRecess": face_recess, "wallFamily": wall[0] if wall else None}


def _cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2],
            a[0] * b[1] - a[1] * b[0])


def _sub(a, b):
    return tuple(x - y for x, y in zip(a, b))


def _dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def _triangle_normal(points, triangle):
    a, b, c = (points[i] for i in triangle)
    return _cross(_sub(b, a), _sub(c, a))


def _volume(points, triangles):
    # Centering avoids precision loss because the R10 meshes store world-like
    # coordinates in their vertex arrays instead of centering each object.
    lo, hi = _bounds(points)
    center = tuple((a + b) * 0.5 for a, b in zip(lo, hi))
    return sum(_dot(_sub(points[a], center),
                    _cross(_sub(points[b], center), _sub(points[c], center)))
               for a, b, c in triangles) / 6.0


def _read_vectors(data, field):
    values = array("f", [0.0]) * (len(data) * 3)
    data.foreach_get(field, values)
    return [tuple(values[i:i + 3]) for i in range(0, len(values), 3)]


def _safe_coordinates(points, proposed, triangles):
    """Protect source slivers without ever ignoring a nonzero-area triangle.

    R10's tessellated bevels contain almost-collinear triples with heights of a
    few micrometres. A smooth nonlinear field can reverse those triples despite
    leaving the large visible polygon valid. Pin measured fragile triples and
    blend the displacement continuously to zero in their neighbourhood. Then
    check every reference triangle after float32 quantisation, exactly as stored.
    """
    import numpy as np
    from mathutils.kdtree import KDTree

    base = np.asarray(points, dtype=np.float64)
    change = np.asarray(proposed, dtype=np.float64) - base
    tri = np.asarray(triangles, dtype=np.int64)
    a, b, c = (base[tri[:, i]] for i in range(3))
    old_cross = np.cross(b - a, c - a)
    old_squared = np.einsum("ij,ij->i", old_cross, old_cross)
    edge = np.maximum.reduce((np.linalg.norm(b - a, axis=1),
                              np.linalg.norm(c - b, axis=1),
                              np.linalg.norm(a - c, axis=1)))
    altitude = np.divide(np.sqrt(old_squared), edge,
                         out=np.zeros_like(edge), where=edge > 0)
    coordinate_ulp = float(abs(np.spacing(np.float32(np.abs(base).max()))))
    # This is a protection threshold, never an exclusion from validation.
    altitude_guard = max(32.0 * coordinate_ulp, 0.00025)
    protected = set(int(i) for i in tri[altitude <= altitude_guard].ravel())
    nonzero = old_squared > 0.0
    radius = min(0.045, float(np.ptp(base, axis=0).min()) * 0.14)
    iterations = []
    for iteration in range(20):
        if protected:
            tree = KDTree(len(protected))
            for i in sorted(protected):
                tree.insert(tuple(base[i]), i)
            tree.balance()
            weights = np.asarray([_smooth(0.0, radius, tree.find(tuple(p))[2])
                                  for p in base], dtype=np.float64)
        else:
            weights = np.ones(len(base), dtype=np.float64)
        candidate = np.asarray(base + change * weights[:, None], dtype=np.float32)
        # Assign pins from source float32 bytes, not an approximate zero weight.
        if protected:
            ids = np.fromiter(sorted(protected), dtype=np.int64)
            candidate[ids] = base[ids]
        stored = candidate.astype(np.float64)
        a, b, c = (stored[tri[:, i]] for i in range(3))
        new_cross = np.cross(b - a, c - a)
        dot = np.einsum("ij,ij->i", old_cross, new_cross)
        projected_ratio = np.divide(dot, old_squared,
                                    out=np.ones_like(dot), where=nonzero)
        # A positive 25% projected area margin prevents both flips and collapse.
        unsafe = nonzero & (projected_ratio < 0.25)
        # Truly zero-area source triples are frozen, not given arbitrary normals.
        zero_changed = (~nonzero) & np.any(np.any(stored[tri] != base[tri], axis=2), axis=1)
        bad = np.flatnonzero(unsafe | zero_changed)
        iterations.append(dict(iteration=iteration, pinnedVertices=len(protected),
                               unsafeTriangles=int(len(bad)),
                               flippedTriangles=int(np.count_nonzero(nonzero & (dot <= 0))),
                               minimumProjectedAreaRatio=float(projected_ratio[nonzero].min())))
        if not len(bad):
            return stored.tolist(), dict(
                exactDegenerateSourceTriangles=int(np.count_nonzero(~nonzero)),
                fragileSourceTriangles=int(np.count_nonzero(altitude <= altitude_guard)),
                sourceTriangleAreaPercentiles=(np.percentile(np.sqrt(old_squared) * 0.5,
                                                             [0, 1, 50, 100]).tolist()),
                sourceMinimumTriangleAltitude=float(altitude.min()),
                float32CoordinateULP=coordinate_ulp,
                fragileAltitudeGuard=altitude_guard,
                protectedVertices=len(protected), protectionRadius=radius,
                minimumProjectedAreaRatio=float(projected_ratio[nonzero].min()),
                flippedTriangles=0, collapsedNonzeroTriangles=0,
                storedFloat32Verified=True, stabilization=iterations)
        added = set(int(i) for i in tri[bad].ravel()) - protected
        if not added:
            raise ValueError("Pinned source triangles failed exact float32 validation")
        protected.update(added)
    raise ValueError("Stone deformation could not be stabilized without triangle flips")


def _untouched_state(objects):
    """Data references plus vertex bytes catch accidental shared-data changes."""
    digest = hashlib.sha256()
    for ob in sorted(objects, key=lambda o: o.name):
        digest.update(repr((ob.name, ob.type, ob.data.as_pointer() if ob.data else 0,
                            tuple(tuple(row) for row in ob.matrix_world),
                            ob.hide_render, ob.hide_get(),
                            tuple(s.material.as_pointer() if s.material else 0
                                  for s in ob.material_slots))).encode())
        if ob.type == "MESH":
            values = array("f", [0.0]) * (len(ob.data.vertices) * 3)
            ob.data.vertices.foreach_get("co", values)
            digest.update(values.tobytes())
    return digest.hexdigest()


def _closed_edges(mesh):
    counts = {}
    for face in mesh.polygons:
        ids = tuple(face.vertices)
        for a, b in zip(ids, ids[1:] + ids[:1]):
            edge = (min(a, b), max(a, b))
            counts[edge] = counts.get(edge, 0) + 1
    return sum(n != 2 for n in counts.values())


def _write_fixed_triangles(replacement, source, coordinates, triangles):
    """Freeze the checked R10 tessellation while retaining corner UV values."""
    allowed = {"sharp_face", "position", ".edge_verts", ".corner_vert", ".corner_edge"}
    allowed.update(layer.name for layer in source.uv_layers)
    unexpected = {a.name for a in source.attributes} - allowed
    if unexpected or source.has_custom_normals:
        raise ValueError(f"Unsupported source mesh attributes: {source.name}: {unexpected}")
    face_settings = [(source.polygons[t.polygon_index].material_index,
                      source.polygons[t.polygon_index].use_smooth)
                     for t in source.loop_triangles]
    uv_values = {
        layer.name: [tuple(layer.data[i].uv) for t in source.loop_triangles for i in t.loops]
        for layer in source.uv_layers
    }
    replacement.clear_geometry()
    replacement.from_pydata(coordinates, [], triangles)
    for polygon, (material_index, smooth) in zip(replacement.polygons, face_settings):
        polygon.material_index = material_index
        polygon.use_smooth = smooth
    for name, values in uv_values.items():
        layer = replacement.uv_layers.get(name) or replacement.uv_layers.new(name=name)
        layer.data.foreach_set("uv", array("f", (v for pair in values for v in pair)))
    replacement.update()
    replacement.calc_loop_triangles()
    if [tuple(t.vertices) for t in replacement.loop_triangles] != triangles:
        raise AssertionError(f"Stored display tessellation changed: {source.name}")
    if tuple(replacement.materials) != tuple(source.materials):
        raise AssertionError(f"Material slots changed: {source.name}")


def _project_safe_wall(name, points, proposed, triangles):
    """Keep the shared joint field; minimally correct source sliver orientation.

    Pinning a sliver to its old position would break the shared 30mm joint warp.
    Instead project its stored vertices along the signed-area gradient. Corrections
    are bounded to 3mm, cannot move global bearing bands, and cannot change the z
    of internal bedding-plane vertices. No nonzero triangle is excluded.
    """
    import numpy as np

    base = np.asarray(points, dtype=np.float64)
    target = np.asarray(proposed, dtype=np.float32).astype(np.float64)
    current = target.copy()
    tri = np.asarray(triangles, dtype=np.int64)
    aa, bb, cc = (base[tri[:, i]] for i in range(3))
    old = np.cross(bb - aa, cc - aa)
    area2 = np.linalg.norm(old, axis=1)
    nonzero = area2 > 0.0
    if not np.all(nonzero):
        raise ValueError(f"Unexpected exact-zero source triangle: {name}")
    unit = old / area2[:, None]
    spec = _wall_spec(name)
    lo = base.min(axis=0)
    hi = base.max(axis=0)
    distance = np.minimum(base - lo, hi - base)
    locked = (base[:, 2] <= 0.04) | (base[:, 2] >= spec[1] - 0.04)
    bedding = ((distance[:, 2] <= 0.008) & (distance[:, 0] >= 0.055)
               & (distance[:, 1] >= 0.055))
    freedom = np.ones_like(base)
    freedom[locked] = 0.0
    freedom[bedding, 2] = 0.0
    if np.any(target[locked] != base[locked]):
        raise ValueError(f"Foundation ground/top bearing band moved: {name}")
    history = []
    for iteration in range(100):
        a, b, c = (current[tri[:, i]] for i in range(3))
        cross = np.cross(b - a, c - a)
        ratios = np.einsum("ij,ij->i", cross, unit) / area2
        bad = np.flatnonzero(ratios < 0.25)
        history.append(dict(iteration=iteration, unsafeTriangles=int(len(bad)),
                            flippedTriangles=int(np.count_nonzero(ratios <= 0)),
                            minimumProjectedAreaRatio=float(ratios.min())))
        if not len(bad):
            correction = np.linalg.norm(current - target, axis=1)
            if float(correction.max()) > 0.003:
                raise ValueError(f"Sliver correction exceeded 3mm: {name}")
            if np.any(current[locked] != base[locked]):
                raise AssertionError(f"Locked bearing band changed: {name}")
            if np.any(current[bedding, 2] != target[bedding, 2]):
                raise AssertionError(f"Shared bedding warp changed: {name}")
            lengths = np.maximum.reduce((np.linalg.norm(bb - aa, axis=1),
                                          np.linalg.norm(cc - bb, axis=1),
                                          np.linalg.norm(aa - cc, axis=1)))
            return current.tolist(), dict(
                exactDegenerateSourceTriangles=0, flippedTriangles=0,
                collapsedNonzeroTriangles=0, storedFloat32Verified=True,
                minimumProjectedAreaRatio=float(ratios.min()),
                sourceMinimumTriangleAltitude=float((area2 / lengths).min()),
                sourceMinimumTriangleArea=float(area2.min() * 0.5),
                lockedGroundTopVertices=int(np.count_nonzero(locked)),
                beddingVertices=int(np.count_nonzero(bedding)),
                maximumSliverCorrection=float(correction.max()),
                sharedBeddingZDeviation=0.0, stabilization=history)
        for index in bad[np.argsort(ratios[bad])]:
            ids = tri[index]
            a, b, c = current[ids]
            normal = unit[index]
            projected = float(np.dot(np.cross(b - a, c - a), normal))
            if projected >= area2[index] * 0.25:
                continue
            gradient = np.asarray((np.cross(b - c, normal),
                                   np.cross(c - a, normal),
                                   np.cross(a - b, normal))) * freedom[ids]
            denominator = float(np.einsum("ij,ij->", gradient, gradient))
            if denominator < 1e-24:
                raise ValueError(f"No permitted correction for triangle {index}: {name}")
            step = (area2[index] * 0.65 - projected) / denominator
            current[ids] = np.asarray(current[ids] + step * gradient,
                                      dtype=np.float32).astype(np.float64)
    raise ValueError(f"Wall sliver projection did not converge: {name}")


def refine_stones(sc) -> dict:
    """Atomically replace only validated HS10 visual meshes; never save/render."""
    import bpy

    expected = json.loads((ROOT / "sarang-stone-masonry-r10/verification.json")
                          .read_text(encoding="utf-8"))["addedSolidStones"]
    source_names = set(json.loads((ROOT / "sarang/geometry-lock.json")
                                  .read_text(encoding="utf-8"))["objects"])
    objects = sorted((o for o in sc.objects if o.name.startswith("HS10 ")),
                     key=lambda o: o.name)
    expected_names = {r["name"] for r in expected}
    if len(objects) != 220 or {o.name for o in objects} != expected_names:
        raise ValueError("Expected the exact 220 R10 visual stone objects")
    if source_names.intersection(expected_names):
        raise ValueError("A visual stone unexpectedly belongs to original711")
    if any(o.type != "MESH" or not o.get("construction_parent") for o in objects):
        raise ValueError("Invalid R10 visual stone or missing construction binding")
    if any(o.get("hs11_shape_version") for o in objects):
        raise ValueError("R11 already applied; reopen the R10 source before running")
    for ob in objects:
        if any(abs(ob.matrix_world[i][j] - float(i == j)) > 1e-7
               for i in range(4) for j in range(4)):
            raise ValueError(f"R10 world-aligned coordinates required: {ob.name}")
        if ob.data.shape_keys is not None or ob.modifiers:
            raise ValueError(f"Unexpected shape keys/modifiers: {ob.name}")
    untouched = [o for o in sc.objects if o.name not in expected_names]
    original_state = _untouched_state(untouched)
    pending = []
    reports = []
    try:
        for ob in objects:
            mesh = ob.data
            points = _read_vectors(mesh.vertices, "co")
            normals = _read_vectors(mesh.vertices, "normal")
            mesh.calc_loop_triangles()
            triangles = [tuple(t.vertices) for t in mesh.loop_triangles]
            old_volume = _volume(points, triangles)
            if abs(old_volume) < 1e-8:
                raise ValueError(f"Invalid source stone volume: {ob.name}")
            if _closed_edges(mesh):
                raise ValueError(f"Source stone is not closed: {ob.name}")
            spec = _wall_spec(ob.name)
            if spec is None:
                reports.append(dict(name=ob.name, sourceMesh=mesh.name,
                                    replacementMesh=mesh.name, unchangedStairOrSlab=True,
                                    solidVolumeRatio=1.0, bboxPreserved=True,
                                    maximumVertexMove=0.0, movedVertices=0,
                                    vertices=len(points), faces=len(mesh.polygons),
                                    closedBoundaryEdges=0,
                                    triangleSafety=dict(flippedTriangles=0,
                                                        minimumProjectedAreaRatio=1.0,
                                                        storedFloat32Verified=True)))
                continue
            accepted = None
            for strength in (1.0, 0.75, 0.50):
                local, settings = _deform_coordinates(ob.name, points, normals, strength)
                # Stabilise the stronger local dressing before adding the shared
                # course warp. Pins attenuate only local erosion; every pin still
                # follows the same joint field as its neighbouring blocks.
                local, local_safety = _safe_coordinates(points, local, triangles)
                proposed = _joint_warp(ob.name, local)
                candidate, safety = _project_safe_wall(ob.name, points, proposed, triangles)
                safety["localDressingSafety"] = local_safety
                new_volume = _volume(candidate, triangles)
                ratio = new_volume / old_volume
                if 0.86 <= ratio <= 1.14:
                    accepted = candidate, settings, ratio, safety
                    break
            if accepted is None:
                raise ValueError(f"Could not safely refine stone: {ob.name}")
            candidate, settings, ratio, safety = accepted
            replacement = mesh.copy()
            pending.append((ob, mesh, replacement))
            replacement.name = mesh.name + " R11 coherent dressed masonry"
            _write_fixed_triangles(replacement, mesh, candidate, triangles)
            actual = _read_vectors(replacement.vertices, "co")
            if actual != [tuple(v) for v in candidate]:
                raise AssertionError(f"Stored float32 differs from validated data: {ob.name}")
            if _closed_edges(replacement):
                raise AssertionError(f"Replacement stone is not closed: {ob.name}")
            movement = [math.dist(a, b) for a, b in zip(actual, points)]
            before_bbox, after_bbox = _bounds(points), _bounds(actual)
            joint_moves = [abs(_joint_delta(*point, spec[1], spec[2])) for point in points]
            reports.append(dict(name=ob.name, sourceMesh=mesh.name,
                                replacementMesh=replacement.name, **settings,
                                solidVolumeRatio=ratio, bboxPreserved=before_bbox == after_bbox,
                                bboxBefore=before_bbox, bboxAfter=after_bbox,
                                maximumJointWarp=max(joint_moves),
                                closedBoundaryEdges=0,
                                maximumVertexMove=max(movement),
                                movedVertices=sum(x > 1e-7 for x in movement),
                                vertices=len(points), faces=len(replacement.polygons),
                                sourceFaces=len(mesh.polygons),
                                originalLoopTriangulationFrozen=True,
                                triangleSafety=safety))
        if _untouched_state(untouched) != original_state:
            raise AssertionError("Non-HS10 scene data changed during preparation")
        for ob, original, replacement in pending:
            ob.data = replacement
            ob["hs11_shape_version"] = VERSION
        if _untouched_state(untouched) != original_state:
            raise AssertionError("Non-HS10 scene data changed during commit")
    except Exception:
        for ob, original, replacement in pending:
            if ob.data == replacement:
                ob.data = original
            if "hs11_shape_version" in ob:
                del ob["hs11_shape_version"]
            if replacement.users == 0:
                bpy.data.meshes.remove(replacement)
        raise
    return dict(version=VERSION, stoneCount=len(reports), stones=reports,
                seedMode="sha256 version plus stable object name",
                original711Untouched=True, nonHS10StatePreserved=True,
                namesTransformsUVsMaterialsBindingsPreserved=True,
                sourceOriginalTopologyPreserved=True,
                displayWallTopology="R10 original loop triangles frozen; no added vertices",
                wallStoneCount=len(pending), unchangedStairSlabCount=len(reports) - len(pending),
                bboxPreserved=False, wallBboxChangesRecorded=True,
                maximumInwardAxisRecess=MAX_RECESS,
                maximumSharedJointWarp=JOINT_AMPLITUDE,
                sharedWarpMinimumVerticalDerivativeBound=1.0 - JOINT_AMPLITUDE * 1.5 / 0.08,
                foundationGroundTopBandsPreserved=True, closedMeshesVerified=True,
                minimumSolidVolumeRatio=min(r["solidVolumeRatio"] for r in reports),
                maxVertexMove=max(r["maximumVertexMove"] for r in reports),
                rendererRun=False, savedBlend=False)
