"""Rebuild only R10's 207 display wall stones as dressed, closed polyhedra.

No file loading/saving, rendering, material or lighting edits. The 711 source
objects and 13 display stair/slab/cheek objects remain untouched. Each display
wall keeps its object, material slots and construction binding. Its replacement
mesh uses deliberately broad, varied edge planes rather than R10's fragile
nonplanar polygons. Nominal 6mm bedding joints follow the shared R11 field.
"""

import hashlib
import json
import math
import random
import re
from array import array
from pathlib import Path

VERSION = "r12-dressed-polyhedra-1"
ROOT = Path(__file__).resolve().parent
JOINT_AMPLITUDE = 0.030
FAMILIES = (("main foundation", 1.016, 3), ("numaru foundation", .38, 1),
            ("left terrace", 1.10, 3), ("front apron", 1.10, 3),
            ("stair landing", 1.28, 3), ("numaru front apron", .43, 1),
            ("numaru inner apron", .43, 1))


def _wall_spec(name):
    return next((s for s in FAMILIES if name.startswith("HS10 " + s[0] + " ")), None)


def _smooth(a, b, v):
    t = max(0., min(1., (v - a) / (b - a)))
    return t * t * (3. - 2. * t)


def _joint_delta(x, y, z, height, rows):
    if rows == 1:
        return 0.
    weight = _smooth(.04, .12, z) * (1. - _smooth(height - .12, height - .04, z))
    return JOINT_AMPLITUDE * weight * (
        .70 * math.sin(.95 * x + .33 * y + .55)
        + .30 * math.sin(1.61 * x - .48 * y + 1.))


def _read_vectors(data, field="co"):
    values = array("f", [0.]) * (len(data) * 3)
    data.foreach_get(field, values)
    return [tuple(values[i:i + 3]) for i in range(0, len(values), 3)]


def _untouched_state(objects):
    digest = hashlib.sha256()
    for ob in sorted(objects, key=lambda o: o.name):
        digest.update(repr((ob.name, ob.type, ob.data.as_pointer() if ob.data else 0,
                            tuple(tuple(r) for r in ob.matrix_world),
                            ob.parent.name if ob.parent else None,
                            ob.get("construction_parent"), ob.hide_render, ob.hide_get(),
                            tuple(s.material.as_pointer() if s.material else 0
                                  for s in ob.material_slots))).encode())
        if ob.type == "MESH":
            values = array("f", [0.]) * (len(ob.data.vertices) * 3)
            ob.data.vertices.foreach_get("co", values)
            digest.update(values.tobytes())
    return digest.hexdigest()


def _clean_polygon(points):
    import numpy as np
    result = []
    for p in points:
        if not result or np.linalg.norm(p - result[-1]) > 1e-7:
            result.append(p)
    if len(result) > 1 and np.linalg.norm(result[0] - result[-1]) <= 1e-7:
        result.pop()
    changed = True
    while changed and len(result) > 3:
        changed = False
        for i, b in enumerate(result):
            a, c = result[i - 1], result[(i + 1) % len(result)]
            ab, bc = b - a, c - b
            if np.linalg.norm(np.cross(ab, bc)) < 1e-9 * (np.linalg.norm(ab) + np.linalg.norm(bc)):
                result.pop(i)
                changed = True
                break
    return result


def _clip(faces, normal, limit, kind):
    """Clip a convex polyhedron by n dot p <= d; append its outward cap."""
    import numpy as np
    normal = np.asarray(normal, dtype=float)
    length = np.linalg.norm(normal)
    normal, limit = normal / length, limit / length
    result, crossings = [], []
    for polygon, label in faces:
        clipped = []
        for a, b in zip(polygon, polygon[1:] + polygon[:1]):
            da, db = float(np.dot(normal, a) - limit), float(np.dot(normal, b) - limit)
            inside_a, inside_b = da <= 1e-10, db <= 1e-10
            if inside_a:
                clipped.append(a)
            if inside_a != inside_b:
                point = a + (b - a) * (da / (da - db))
                clipped.append(point)
                crossings.append(point)
        clipped = _clean_polygon(clipped)
        if len(clipped) >= 3:
            result.append((clipped, label))
    unique = {}
    for point in crossings:
        unique.setdefault(tuple(round(float(v), 7) for v in point), point)
    cap = list(unique.values())
    if len(cap) >= 3:
        center = np.mean(cap, axis=0)
        axis = np.eye(3)[int(np.argmin(np.abs(normal)))]
        u = np.cross(axis, normal)
        u /= np.linalg.norm(u)
        v = np.cross(normal, u)
        cap.sort(key=lambda p: math.atan2(float(np.dot(p - center, v)),
                                         float(np.dot(p - center, u))))
        cap = _clean_polygon(cap)
        if len(cap) >= 3:
            result.append((cap, kind))
    return result


def _build_polyhedron(name, source_bounds, attempt=0):
    import numpy as np
    spec = _wall_spec(name)
    row = int(re.search(r" course (\d+) ", name).group(1))
    bounds = np.array(source_bounds, dtype=float)
    # R10's construction contract: +/-3mm at each course boundary. The old
    # noise-displaced extrema are not the structural bearing heights.
    bounds[0, 2] = row * spec[1] / spec[2] + .003
    bounds[1, 2] = (row + 1) * spec[1] / spec[2] - .003
    if np.any(bounds[0] < source_bounds[0] - .00001) or np.any(bounds[1] > source_bounds[1] + .00001):
        raise ValueError(f"Nominal R10 bearing planes outside source envelope: {name}")
    center, half = bounds.mean(axis=0), np.diff(bounds, axis=0)[0] * .5
    seed = int(hashlib.sha256(f"{VERSION}|{name}|{attempt}".encode()).hexdigest()[:16], 16)
    rng = random.Random(seed)
    faces = []
    # Local box faces, ordered with outward normals.
    for axis in range(3):
        others = [a for a in range(3) if a != axis]
        for sign in (-1, 1):
            points = []
            for s, t in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
                p = np.zeros(3)
                p[axis], p[others[0]], p[others[1]] = sign * half[axis], s * half[others[0]], t * half[others[1]]
                points.append(p)
            normal = np.cross(points[1] - points[0], points[2] - points[0])
            if normal[axis] * sign < 0:
                points.reverse()
            faces.append((points, f"base-{axis}-{sign}"))
    edge_radii = []
    for a, b in ((0, 1), (0, 2), (1, 2)):
        free = next(i for i in range(3) if i not in (a, b))
        for sa in (-1, 1):
            for sb in (-1, 1):
                ra, rb = rng.uniform(.035, .055), rng.uniform(.035, .055)
                ra, rb = min(ra, half[a] * .40), min(rb, half[b] * .40)
                edge_radii.append((ra, rb))
                lean = rng.uniform(-.18, .18)
                for angle in (22.5, 45., 67.5):
                    ca, cb = math.cos(math.radians(angle)), math.sin(math.radians(angle))
                    cut = ca + cb - 1.
                    n = np.zeros(3)
                    n[a], n[b] = sa * ca / ra, sb * cb / rb
                    n[free] = lean * cut / half[free]
                    d = half[a] * ca / ra + half[b] * cb / rb - cut
                    faces = _clip(faces, n, d, "worn-edge")
    corner_sizes = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            for sz in (-1, 1):
                widths = np.array([rng.uniform(.045, .075) for _ in range(3)])
                widths = np.minimum(widths, half * .50)
                n = np.array([sx, sy, sz]) / widths
                d = float(np.sum(half / widths) - rng.uniform(1.05, 1.35))
                faces = _clip(faces, n, d, "corner-chip")
                corner_sizes.append(widths.tolist())
    front_axis, front_sign = ((0, -1) if " left course " in name else
                              (0, 1) if " right course " in name else
                              (1, 1) if " rear course " in name else (1, -1))
    tangent = 1 - front_axis
    front_recess = rng.uniform(.004, .012)
    n = np.zeros(3)
    n[front_axis] = front_sign
    n[tangent], n[2] = rng.uniform(-.018, .018), rng.uniform(-.018, .018)
    faces = _clip(faces, n, half[front_axis] - front_recess, "front-main")
    for sign in (-1, 1):
        n = np.zeros(3)
        n[front_axis] = front_sign
        n[tangent], n[2] = sign * rng.uniform(.045, .075), rng.uniform(-.055, .055)
        faces = _clip(faces, n, half[front_axis] + rng.uniform(.002, .009), "front-tool-plane")
    # The clean convex base has no inherited slivers. Fan triangulation uses
    # each polygon's interior centroid; all shared edge midpoints are reused.
    points, index, triangles, labels = [], {}, [], []

    def vertex(p):
        key = tuple(round(float(v), 7) for v in p)
        if key not in index:
            index[key] = len(points)
            points.append(np.array(p))
        return index[key]

    for polygon, label in faces:
        ids = [vertex(p) for p in polygon]
        middle = vertex(np.mean(polygon, axis=0))
        for a, b in zip(ids, ids[1:] + ids[:1]):
            triangles.append((middle, a, b))
            labels.append(label)
    for _ in range(2):
        mids, refined, next_labels = {}, [], []

        def midpoint(a, b):
            edge = (min(a, b), max(a, b))
            if edge not in mids:
                mids[edge] = len(points)
                points.append((points[a] + points[b]) * .5)
            return mids[edge]

        for (a, b, c), label in zip(triangles, labels):
            ab, bc, ca = midpoint(a, b), midpoint(b, c), midpoint(c, a)
            refined.extend(((a, ab, ca), (ab, b, bc), (ca, bc, c), (ab, bc, ca)))
            next_labels.extend([label] * 4)
        triangles, labels = refined, next_labels
    base = np.asarray(points) + center
    warped = base.copy()
    warped[:, 2] += np.array([_joint_delta(*p, spec[1], spec[2]) for p in base])
    stored = warped.astype(np.float32).astype(float)
    return base, stored, triangles, labels, dict(
        seed=seed, attempt=attempt, edgeRadii=edge_radii, cornerClipSizes=corner_sizes,
        frontRecess=front_recess, polyhedronFaces=len(faces),
        nominalBearingHeights=bounds[:, 2].tolist(), subdivisionLevels=2)


def _validate_geometry(base, stored, triangles, source_bounds, spec):
    import numpy as np
    tri = np.asarray(triangles, dtype=np.int64)
    old_cross = np.cross(base[tri[:, 1]] - base[tri[:, 0]], base[tri[:, 2]] - base[tri[:, 0]])
    new_cross = np.cross(stored[tri[:, 1]] - stored[tri[:, 0]], stored[tri[:, 2]] - stored[tri[:, 0]])
    squared = np.einsum("ij,ij->i", old_cross, old_cross)
    dots = np.einsum("ij,ij->i", old_cross, new_cross)
    if np.any(squared <= 0) or np.any(dots <= 0):
        raise ValueError("New polyhedron has a collapsed or flipped triangle")
    ratio = dots / squared
    if float(ratio.min()) < .20:
        raise ValueError("Insufficient projected triangle area margin")
    counts = {}
    for a, b, c in triangles:
        for u, v in ((a, b), (b, c), (c, a)):
            edge = (min(u, v), max(u, v))
            counts[edge] = counts.get(edge, 0) + 1
    if any(n != 2 for n in counts.values()):
        raise ValueError("New polyhedron is not a closed manifold")
    center = stored.mean(axis=0)
    p = stored - center
    volume = float(np.einsum("ij,ij->", p[tri[:, 0]],
                             np.cross(p[tri[:, 1]], p[tri[:, 2]])) / 6.)
    if volume <= 0:
        raise ValueError("New polyhedron has nonpositive signed volume")
    if np.any(stored[:, :2] < source_bounds[0, :2] - 2e-6) or np.any(stored[:, :2] > source_bounds[1, :2] + 2e-6):
        raise ValueError("Stone escaped its original XY silhouette envelope")
    if stored[:, 2].min() < -.000002 or stored[:, 2].max() > spec[1] + .000002:
        raise ValueError("Stone escaped the foundation ground/top envelope")
    return dict(vertices=len(stored), triangles=len(triangles), closedBoundaryEdges=0,
                triangleFlips=0, collapsedTriangles=0, signedVolume=volume,
                minimumTriangleArea=float(np.linalg.norm(new_cross, axis=1).min() * .5),
                minimumProjectedAreaRatio=float(ratio.min()),
                maximumSharedWarp=float(np.abs(stored[:, 2] - base[:, 2]).max()),
                xyWithinSourceEnvelope=True, zWithinFoundationEnvelope=True)


def _support_check(pending):
    """Measure the rendered triangle surfaces, not only AABBs or field formulae."""
    import numpy as np
    from mathutils import Vector
    from mathutils.bvhtree import BVHTree
    groups, meshes, bounds = {}, {}, {}
    for ob, source, replacement in pending:
        match = re.match(r"(.*) course (\d+) block ", ob.name)
        groups.setdefault(match[1], {}).setdefault(int(match[2]), []).append(ob.name)
        meshes[ob.name] = BVHTree.FromPolygons([v.co for v in replacement.vertices],
                                              [tuple(p.vertices) for p in replacement.polygons],
                                              all_triangles=True)
        points = np.asarray(_read_vectors(source.vertices))
        bounds[ob.name] = np.array([points.min(axis=0), points.max(axis=0)])
    gaps, missing, pairs = [], [], 0
    for rows in groups.values():
        for row, lower_names in rows.items():
            for lower in lower_names:
                for upper in rows.get(row + 1, []):
                    lo = np.maximum(bounds[lower][0, :2], bounds[upper][0, :2]) + .075
                    hi = np.minimum(bounds[lower][1, :2], bounds[upper][1, :2]) - .075
                    if np.any(hi <= lo):
                        continue
                    pairs += 1
                    for u in (.1, .3, .5, .7, .9):
                        for v in (.2, .5, .8):
                            x, y = lo + (hi - lo) * np.array([u, v])
                            a = meshes[lower].ray_cast(Vector((x, y, 3)), Vector((0, 0, -1)))[0]
                            b = meshes[upper].ray_cast(Vector((x, y, -1)), Vector((0, 0, 1)))[0]
                            if a is None or b is None:
                                missing.append((lower, upper, x, y))
                            else:
                                gaps.append(float(b.z - a.z))
    if missing or not gaps or min(gaps) <= 0 or max(gaps) > .015:
        raise ValueError(f"Native support gap check failed: missing={len(missing)}, range={min(gaps, default=0), max(gaps, default=0)}")
    return dict(adjacentRowPairs=pairs, raySamples=len(gaps), missingSupportSamples=0,
                minimumGap=min(gaps), maximumGap=max(gaps),
                method="15 BVH vertical-ray samples per adjacent pair, 75mm edge inset",
                passed=True)


def refine_stones(sc) -> dict:
    import bpy
    import numpy as np
    expected = json.loads((ROOT / "sarang-stone-masonry-r10/verification.json").read_text(encoding="utf-8"))["addedSolidStones"]
    expected_names = {r["name"] for r in expected}
    source_names = set(json.loads((ROOT / "sarang/geometry-lock.json").read_text(encoding="utf-8"))["objects"])
    objects = sorted((o for o in sc.objects if o.name.startswith("HS10 ")), key=lambda o: o.name)
    if len(objects) != 220 or {o.name for o in objects} != expected_names or expected_names & source_names:
        raise ValueError("Expected exactly the 220 R10 display stones, separate from original711")
    if any(o.get("hs11_shape_version") or o.get("hs12_shape_version") for o in objects):
        raise ValueError("Open fresh R10 before the R12 display rebuild")
    if any(o.type != "MESH" or not o.get("construction_parent") or o.modifiers or o.data.shape_keys for o in objects):
        raise ValueError("Unexpected display object, binding, modifier or shape key")
    for ob in objects:
        if any(abs(ob.matrix_world[i][j] - float(i == j)) > 1e-7 for i in range(4) for j in range(4)):
            raise ValueError(f"World-aligned R10 coordinates required: {ob.name}")
    untouched = [o for o in sc.objects if o.name not in expected_names or _wall_spec(o.name) is None]
    before = _untouched_state(untouched)
    pending, reports = [], []
    try:
        for ob in objects:
            spec = _wall_spec(ob.name)
            if spec is None:
                continue
            old = ob.data
            points = np.asarray(_read_vectors(old.vertices))
            bounds = np.array([points.min(axis=0), points.max(axis=0)])
            accepted, errors = None, []
            for attempt in range(5):
                try:
                    base, stored, triangles, labels, settings = _build_polyhedron(ob.name, bounds, attempt)
                    metrics = _validate_geometry(base, stored, triangles, bounds, spec)
                    accepted = base, stored, triangles, labels, settings, metrics
                    break
                except ValueError as error:
                    errors.append(str(error))
            if accepted is None:
                raise ValueError(f"Could not construct safe dressed stone {ob.name}: {errors}")
            base, stored, triangles, labels, settings, metrics = accepted
            replacement = old.copy()
            pending.append((ob, old, replacement))
            replacement.name = old.name + " R12 dressed polyhedron"
            old_uv_names = [layer.name for layer in old.uv_layers]
            replacement.clear_geometry()
            replacement.from_pydata(stored.tolist(), [], triangles)
            # The R10 display stones have one material and no UV layers. Keep
            # every material slot; existing UVs, if present, receive a dominant
            # face-plane projection in world metres because topology is new.
            material_index = max(set(p.material_index for p in old.polygons),
                                 key=lambda x: sum(p.area for p in old.polygons if p.material_index == x))
            for face in replacement.polygons:
                face.material_index = material_index
                face.use_smooth = False
            for name in old_uv_names:
                layer = replacement.uv_layers.get(name) or replacement.uv_layers.new(name=name)
                for face in replacement.polygons:
                    axis = int(np.argmax(np.abs(face.normal)))
                    uv_axes = [a for a in range(3) if a != axis]
                    for loop in face.loop_indices:
                        p = replacement.vertices[replacement.loops[loop].vertex_index].co
                        layer.data[loop].uv = (p[uv_axes[0]], p[uv_axes[1]])
            replacement.update()
            replacement.calc_loop_triangles()
            actual = np.asarray(_read_vectors(replacement.vertices))
            if not np.array_equal(actual, stored):
                raise AssertionError(f"Stored float32 mismatch: {ob.name}")
            if [tuple(t.vertices) for t in replacement.loop_triangles] != triangles:
                raise AssertionError(f"Rendered tessellation changed: {ob.name}")
            if tuple(replacement.materials) != tuple(old.materials):
                raise AssertionError(f"Material slots changed: {ob.name}")
            reports.append(dict(name=ob.name, sourceMesh=old.name, replacementMesh=replacement.name,
                                sourceBounds=bounds.tolist(), newBounds=[stored.min(axis=0).tolist(), stored.max(axis=0).tolist()],
                                regeneratedUVLayers=old_uv_names, **settings, **metrics))
        support = _support_check(pending)
        if _untouched_state(untouched) != before:
            raise AssertionError("Original711, non-HS10 or stair/slab state changed")
        for ob, old, replacement in pending:
            ob.data = replacement
            ob["hs12_shape_version"] = VERSION
        if _untouched_state(untouched) != before:
            raise AssertionError("Protected scene state changed during commit")
    except Exception:
        for ob, old, replacement in pending:
            if ob.data == replacement:
                ob.data = old
            if "hs12_shape_version" in ob:
                del ob["hs12_shape_version"]
            if replacement.users == 0:
                bpy.data.meshes.remove(replacement)
        raise
    return dict(version=VERSION, stoneCount=220, rebuiltWallCount=len(reports),
                unchangedStairSlabCount=220 - len(reports), stones=reports,
                original711Untouched=True, sourceDisplayMeshesUntouched=True,
                namesTransformsMaterialSlotsBindingsPreserved=True,
                outsideSourceXYEnvelope=0, outsideFoundationZEnvelope=0,
                triangleFlips=0, openBoundaryEdges=0, positiveVolumes=True,
                supportCheck=support, maximumSharedJointWarp=JOINT_AMPLITUDE,
                savedBlend=False, rendered=False)
