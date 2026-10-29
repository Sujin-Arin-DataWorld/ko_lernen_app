"""Recut the display saddle against the actual closed R12 cap.

The original mount mesh and the cap are never edited.  This module does not
load an image, render, save a blend, or change the camera.  build_mount returns
one new object; its JSON ``mount_checks`` property contains the measured audit.
"""

import hashlib
import json
import math

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree


SOURCE_NAME = 'Sarang.numaru roof end ornament.pale base'
FACE_NAME = 'Sarang.numaru roof end ornament.original patterned face'
OUTPUT_NAME = 'HS12 native arch-fit guardian saddle'
SEATING_OVERLAP = 0.00020
CONTACT_TOLERANCE = 0.00120
# Explicit acceptance budget for float32 BVH/transforms and sampled surface
# interpolation. This is a declared 10 micrometre budget, not a measured error
# bound, and does not imply that every threshold excess is floating-point noise.
# Keep the nominal tolerance, unrounded distances and nominal verdict separate.
CONTACT_NUMERICAL_ALLOWANCE = 0.000010
VISIBLE_PROFILE_SMOOTHING = 0.0012


def _world_vertices(obj):
    local = np.empty(len(obj.data.vertices) * 3, dtype=np.float64)
    obj.data.vertices.foreach_get('co', local)
    local = local.reshape(-1, 3)
    m = obj.matrix_world
    return np.column_stack([
        local[:, 0] * m[i][0] + local[:, 1] * m[i][1]
        + local[:, 2] * m[i][2] + m[i][3] for i in range(3)
    ])


def _geometry_sha(obj):
    xyz = np.empty(len(obj.data.vertices) * 3, dtype=np.float32)
    idx = np.empty(len(obj.data.loops), dtype=np.int32)
    obj.data.vertices.foreach_get('co', xyz)
    obj.data.loops.foreach_get('vertex_index', idx)
    digest = hashlib.sha256(xyz.tobytes())
    digest.update(idx.tobytes())
    return digest.hexdigest()


def _profile(points):
    """Upper/lower envelopes of the original polygonal cylinder section."""
    ordered = points[np.argsort(points[:, 0])]
    groups = []
    for point in ordered:
        if not groups or point[0] - groups[-1][0][0] > 0.000005:
            groups.append([point])
        else:
            groups[-1].append(point)
    xs = np.array([np.mean([p[0] for p in group]) for group in groups])
    upper = np.array([max(p[2] for p in group) for group in groups])
    lower = np.array([min(p[2] for p in group) for group in groups])
    if len(xs) < 5 or np.any(upper < lower):
        raise ValueError('The original mount is not the expected Y-axis cylinder')
    return xs, upper, lower


class _Surface:
    def __init__(self, obj, depsgraph):
        self.world = obj.matrix_world.copy()
        self.inverse = self.world.inverted()
        self.tree = BVHTree.FromObject(obj, depsgraph, epsilon=0.00000001)

    def vertical(self, x, y, z, upward):
        direction = Vector((0, 0, 1 if upward else -1))
        direction = (self.inverse.to_3x3() @ direction).normalized()
        hit, _normal, _index, _distance = self.tree.ray_cast(
            self.inverse @ Vector((x, y, z)), direction, 3.0
        )
        return None if hit is None else float((self.world @ hit).z)


def _ring(xs, upper, lower, y):
    # One vertex at each extreme prevents zero-width end quads.
    return ([(float(x), float(y), float(z)) for x, z in zip(xs, upper)]
            + [(float(x), float(y), float(z))
               for x, z in zip(xs[-2:0:-1], lower[-2:0:-1])])


def _smooth_profile(xs, zs, radius):
    """Smooth only the exposed lead-in, never the measured bearing surface."""
    step = 0.00025
    grid = np.linspace(xs[0], xs[-1], int(math.ceil((xs[-1] - xs[0]) / step)) + 1)
    half = max(1, int(math.ceil(radius * 3.0 / step)))
    kernel = np.exp(-0.5 * (np.arange(-half, half + 1) * step / radius) ** 2)
    kernel /= kernel.sum()
    sampled = np.interp(grid, xs, zs)
    filtered = np.convolve(np.pad(sampled, half, mode='edge'), kernel, mode='valid')
    return np.interp(xs, grid, filtered)


def _point_to_ring_error(points, ring):
    polygon = np.asarray(ring)[:, (0, 2)]
    a = polygon
    d = np.roll(polygon, -1, axis=0) - a
    den = np.maximum((d * d).sum(axis=1), 1e-20)
    errors = []
    for point in points:
        q = point[[0, 2]]
        t = np.clip(((q - a) * d).sum(axis=1) / den, 0, 1)
        errors.append(float(np.sqrt(((q - a - t[:, None] * d) ** 2).sum(axis=1)).min()))
    return max(errors, default=0.0)


def build_mount(sc, cap, gray_material):
    """Return a closed display mount with source/geometry/contact checks.

    The complete lower envelope and rear section remain in place.  The front upper
    surface follows vertical intersections with the actual R12 cap, including
    its modelled lower arch.  Restoration to the original rear section starts
    only behind the cap.  The 0.2 mm seat overlap avoids a light leak without
    covering the face.  Only the exposed upper front is rolled back to the cap
    plane; its lead-in is smoothed instead of extruding alpha-pixel steps for
    76 mm in front of the cap. No source or cap mesh is modified.
    """
    if cap.type != 'MESH' or cap.name != 'HS12 main exact guardian cap':
        raise ValueError('Pass the actual HS12 main exact guardian cap mesh')
    if bpy.data.objects.get(OUTPUT_NAME) is not None:
        raise RuntimeError('A fitted saddle already exists; inspect it before rebuilding')
    source = sc.objects.get(SOURCE_NAME)
    if source is None or source.type != 'MESH':
        raise ValueError('The preserved original pale base is required')
    if gray_material is None:
        raise ValueError('A gray fired-ceramic material is required')

    bpy.context.view_layer.update()
    source_sha = _geometry_sha(source)
    cap_sha = _geometry_sha(cap)
    native = _world_vertices(source)
    cap_points = _world_vertices(cap)
    lo, hi = native.min(axis=0), native.max(axis=0)
    cap_lo, cap_hi = cap_points.min(axis=0), cap_points.max(axis=0)
    del cap_points
    front_y, rear_y = float(lo[1]), float(hi[1])
    front_section = native[np.abs(native[:, 1] - front_y) < 0.00001]
    rear_section = native[np.abs(native[:, 1] - rear_y) < 0.00001]
    native_x, native_upper, native_lower = _profile(front_section)
    if len(rear_section) < 8:
        raise ValueError('Unable to identify the unchanged rear cylinder section')

    source_face = sc.objects.get(FACE_NAME)
    source_front = (float(np.median(_world_vertices(source_face)[:, 1]))
                    if source_face else float(cap_hi[1] - 0.108))
    cap_back = float(cap_hi[1])
    if not (front_y < source_front < cap_back < rear_y):
        raise ValueError('Unexpected cap/mount depth relationship; no automatic relocation')
    # Dense sampling of the existing alpha-derived lower arch, not a new oval.
    count = int(math.ceil((native_x[-1] - native_x[0]) / 0.00050)) + 1
    regular_xs = np.linspace(native_x[0], native_x[-1], count)
    # Avoid micron-wide strips where a regular sample almost coincides with a
    # source polygon corner.  Keep the original section vertices exactly.
    regular_xs = [x for x in regular_xs if np.min(np.abs(native_x - x)) > 0.00001]
    xs = np.sort(np.r_[regular_xs, native_x])
    upper_native = np.interp(xs, native_x, native_upper)
    lower = np.interp(xs, native_x, native_lower)
    inside_front = source_front + 0.00060
    inside_back = cap_back - 0.00060
    restore_start = cap_back + min(0.002, (rear_y - cap_back) * 0.1)
    contact_rows_count = int(math.ceil((inside_back - inside_front) / 0.0008)) + 1
    ys = np.unique(np.r_[np.linspace(front_y, inside_front, 13),
                         np.linspace(inside_front, inside_back, contact_rows_count),
                         np.linspace(inside_back, rear_y, 17), cap_back, restore_start])
    depsgraph = bpy.context.evaluated_depsgraph_get()
    cap_surface = _Surface(cap, depsgraph)
    ray_start = float(min(lo[2], cap_lo[2]) - 0.05)
    misses = 0
    cache = {}
    roll_start_z = float((lo[2] + hi[2]) * 0.5)
    roll_end_z = float(cap_lo[2])
    if roll_end_z <= roll_start_z + 0.01:
        raise ValueError('Insufficient height for an upper-front-only saddle roll')
    visible_front_y = source_front + 0.00010

    def front_roll_y(y, z):
        """Preserve every lower-envelope point and roll back only the upper front."""
        if y >= inside_front or z <= roll_start_z:
            return float(y)
        t = float(np.clip((z - roll_start_z) / (roll_end_z - roll_start_z), 0, 1))
        height_weight = t * t * (3 - 2 * t)
        # Linear depth mapping remains monotonic: even at full retraction the
        # last front strip retains positive thickness before the bearing region.
        lead_weight = float((inside_front - y) / (inside_front - front_y))
        return float(y + (visible_front_y - front_y) * height_weight * lead_weight)

    def arch_at(y):
        nonlocal misses
        query_y = float(np.clip(y, inside_front, inside_back))
        key = round(query_y, 9)
        if key not in cache:
            sampled = []
            for x, upper in zip(xs, upper_native):
                # A ray exactly on an alpha-grid edge can skip a shared
                # underside triangle. Three tiny lateral probes remove that
                # seam ambiguity while conservatively keeping the lowest hit.
                hits = [cap_surface.vertical(float(x + dx), query_y, ray_start, True)
                        for dx in (-0.00002, 0.0, 0.00002)]
                hits = [z for z in hits if z is not None]
                if not hits:
                    misses += 1
                    z = float(upper) + 0.01
                else:
                    z = min(hits)
                sampled.append(z)
            cache[key] = np.asarray(sampled)
        return cache[key]

    vertices = []
    cross_sections = []
    for y in ys:
        arch = arch_at(y)
        cut = np.maximum(upper_native - arch - SEATING_OVERLAP, 0.0)
        if y <= restore_start:
            weight = 1.0
        else:
            t = float((y - restore_start) / (rear_y - restore_start))
            weight = 1.0 - t * t * (3.0 - 2.0 * t)
        upper = upper_native - cut * weight
        if y < inside_front:
            # The exposed lead-in has no reason to copy pixel-scale teeth.
            # Taper the filtered profile to zero before the actual contact area.
            t = float((inside_front - y) / (inside_front - front_y))
            blend = t * t * (3 - 2 * t)
            filtered = _smooth_profile(xs, upper, VISIBLE_PROFILE_SMOOTHING)
            upper = upper * (1 - blend) + np.minimum(filtered, upper_native) * blend
        if np.any(upper < lower - 1e-7):
            raise ValueError('The requested arch cut would pierce the original lower mount')
        section = [(x, front_roll_y(y0, z), z)
                   for x, y0, z in _ring(xs, upper, lower, y)]
        cross_sections.append(section)
        vertices.extend(section)

    width = len(cross_sections[0])
    faces = []
    for j in range(len(ys) - 1):
        a, b = j * width, (j + 1) * width
        for k in range(width):
            q = (k + 1) % width
            faces.append((a + k, a + q, b + q, b + k))
    faces.append(tuple((len(ys) - 1) * width + k for k in range(width)))
    # The front end is now curved in Y/Z. A nonplanar n-gon would create long
    # diagonal facets; tessellate its interior as a regular ruled surface.
    nx = len(xs)
    front_top = np.asarray(cross_sections[0][:nx])[:, 2]
    front_rows = []
    for row in range(65):
        t = row / 64.0
        ids = []
        for i, x in enumerate(xs):
            if i == 0 or i == nx - 1:
                idx = i
            elif row == 0:
                idx = width - i
            elif row == 64:
                idx = i
            else:
                z = float(lower[i] * (1 - t) + front_top[i] * t)
                idx = len(vertices)
                vertices.append((float(x), front_roll_y(front_y, z), z))
            ids.append(idx)
        front_rows.append(ids)
    for a, b in zip(front_rows[:-1], front_rows[1:]):
        for i in range(nx - 1):
            face = list(dict.fromkeys((a[i], a[i + 1], b[i + 1], b[i])))
            if len(face) >= 3:
                faces.append(tuple(face))
    mesh = bpy.data.meshes.new(OUTPUT_NAME + ' closed native recut')
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    bm = bmesh.new()
    try:
        bm.from_mesh(mesh)
        bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
        if bm.calc_volume(signed=True) < 0:
            bmesh.ops.reverse_faces(bm, faces=list(bm.faces))
        nonmanifold = sum(not e.is_manifold for e in bm.edges)
        loose = sum(not v.link_faces for v in bm.verts)
        volume = float(bm.calc_volume(signed=True))
        if nonmanifold or loose or volume <= 0:
            raise ValueError('Saddle closure check failed: %s' % (nonmanifold, loose, volume))
        # Concave end sections are explicitly triangulated for portable export.
        bmesh.ops.triangulate(bm, faces=[f for f in bm.faces if len(f.verts) > 4])
        nonmanifold = sum(not e.is_manifold for e in bm.edges)
        loose = sum(not v.link_faces for v in bm.verts)
        if nonmanifold or loose:
            raise ValueError('Triangulated saddle is not a closed mesh')
        bm.to_mesh(mesh)
    except Exception:
        bpy.data.meshes.remove(mesh)
        raise
    finally:
        bm.free()

    mount = bpy.data.objects.new(OUTPUT_NAME, mesh)
    collection = cap.users_collection[0] if cap.users_collection else sc.collection
    collection.objects.link(mount)
    mesh.materials.append(gray_material)
    # The cap and fitted saddle move together; world geometry stays put now.
    mount.parent = cap
    mount.matrix_parent_inverse = cap.matrix_world.inverted()
    mount.matrix_world = Matrix.Identity(4)
    for polygon in mesh.polygons:
        # Smooth the real curved front, including its edge triangles. Keep the
        # unchanged rear closure planar; previous triangle-flat shading caused
        # facets on the front end after a geometric roll.
        polygon.use_smooth = not all(
            abs(mesh.vertices[i].co.y - rear_y) < 0.00001 for i in polygon.vertices
        )
    mount['construction_parent'] = SOURCE_NAME
    mount['support_for'] = cap.name
    mount['source_mesh_sha256'] = source_sha
    mount['source_preserved_hidden'] = True
    mount['no_image_geometry'] = True
    bpy.context.view_layer.update()

    # Independent ray intersections against the finished meshes, at positions
    # between construction samples rather than only at the fitted vertices.
    mounted_surface = _Surface(mount, bpy.context.evaluated_depsgraph_get())
    checks = []
    contact_rows = []
    misses_check = 0
    sample_xs = xs[:-1] * 0.629 + xs[1:] * 0.371
    contact_ys = ys[(ys >= inside_front) & (ys <= inside_back)]
    y_indices = np.linspace(1, len(contact_ys) - 3, 7).astype(int)
    test_ys = [contact_ys[i] * 0.387 + contact_ys[i + 1] * 0.613 for i in y_indices]
    for y in test_ys:
        for x in sample_xs[::3]:
            underside = cap_surface.vertical(float(x), float(y), ray_start, True)
            original_top = float(np.interp(x, native_x, native_upper))
            if underside is None or original_top < underside - 0.0001:
                continue  # Native cylinder did not support this part of the cap.
            # Keep diagnostic rays off coincident tessellation seams.  A ray
            # exactly on a row edge can miss the top and report the bottom of
            # an otherwise closed saddle. Compare paired 10-micron probes and
            # retain their median, not an expected/analytic roof value.
            pairs = []
            for dx, dy in [(0, 0), (0.000007, 0.000011), (-0.000011, 0.000007)]:
                below = cap_surface.vertical(float(x + dx), float(y + dy), ray_start, True)
                above = mounted_surface.vertical(float(x + dx), float(y + dy), hi[2] + 0.10, False)
                if below is not None and above is not None:
                    pairs.append((float(above - below), float(below), float(above)))
            if not pairs:
                misses_check += 1
            else:
                delta, below, above = sorted(pairs)[len(pairs) // 2]
                checks.append(delta)
                contact_rows.append([float(x), float(y), below, above, delta])
    max_overlap = max([0.0] + checks)
    max_gap = max([0.0] + [-x for x in checks])
    rear_error = _point_to_ring_error(rear_section, cross_sections[-1])
    source_preserved = _geometry_sha(source) == source_sha
    cap_preserved = _geometry_sha(cap) == cap_sha
    contact_samples_ok = len(checks) >= 100 and not misses_check
    contact_nominal_ok = (contact_samples_ok and max_overlap <= CONTACT_TOLERANCE
                          and max_gap <= CONTACT_TOLERANCE)
    effective_contact_limit = CONTACT_TOLERANCE + CONTACT_NUMERICAL_ALLOWANCE
    allowance_used = max(0.0, max_overlap - CONTACT_TOLERANCE,
                         max_gap - CONTACT_TOLERANCE)
    contact_ok = (contact_samples_ok and max_overlap <= effective_contact_limit
                  and max_gap <= effective_contact_limit)
    contact_decision = ('pass_nominal' if contact_nominal_ok else
                        'pass_with_declared_numerical_allowance' if contact_ok else 'fail')
    report = {
        'name': mount.name, 'parentObject': cap.name,
        'constructionParent': SOURCE_NAME, 'sourceGeometryUnchanged': source_preserved,
        'capGeometryUnchanged': cap_preserved, 'closedMesh': not nonmanifold and not loose,
        'nonManifoldEdges': nonmanifold, 'looseVertices': loose,
        'volumeCubicMetres': volume, 'vertices': len(mesh.vertices), 'faces': len(mesh.polygons),
        'sourceFrontY': front_y, 'sourceRearY': rear_y,
        'nativeCapFrontY': source_front, 'capBackY': cap_back,
        'rearRestorationStartsY': restore_start,
        'rearSectionMaxErrorMetres': rear_error,
        'lowerSectionPreserved': True, 'uniformScaleApplied': False,
        'frontUpperRollFromY': front_y, 'frontUpperRollToY': visible_front_y,
        'frontRollStartsZ': roll_start_z, 'frontRollEndsZ': roll_end_z,
        'exposedProfileSmoothingMetres': VISIBLE_PROFILE_SMOOTHING,
        'frontEndRuledSurfaceRows': 65,
        'archSource': 'vertical intersections with actual closed HS12 cap mesh',
        'seatingOverlapMetres': SEATING_OVERLAP,
        'profileProbeRadiusMetres': 0.00002, 'contactSamplingStepYMetres': 0.0008,
        'contactComparison': 'median of three paired independent mesh rays within 14 micrometres',
        'profileRayMisses': misses, 'independentContactSamples': len(checks),
        'contactRayMisses': misses_check, 'maxContactOverlapMetres': max_overlap,
        'maxContactGapMetres': max_gap, 'contactToleranceMetres': CONTACT_TOLERANCE,
        'contactNumericalAllowanceMetres': CONTACT_NUMERICAL_ALLOWANCE,
        'contactEffectiveLimitMetres': effective_contact_limit,
        'contactNumericalAllowanceUsedMetres': allowance_used,
        'contactNominalPassed': contact_nominal_ok,
        'contactNominalOverlapExcessMetres': max(0.0, max_overlap - CONTACT_TOLERANCE),
        'contactNominalGapExcessMetres': max(0.0, max_gap - CONTACT_TOLERANCE),
        'contactDecision': contact_decision,
        'contactAllowanceBasis': ('Declared 10 micrometre acceptance budget for float32 '
                                 'BVH/transforms and surface sampling/interpolation; '
                                 'not a measured bound or a geometric correction'),
        'largestContactDifferences': sorted(contact_rows, key=lambda row: abs(row[-1]), reverse=True)[:12],
        'contactPassed': contact_ok,
        'allGeometryChecksPassed': (contact_ok and source_preserved and cap_preserved
                                    and rear_error <= 0.00001),
        'needsVisualReview': 'Rolled upper front and smoothed exposed lead-in; no render performed',
    }
    mount['mount_checks'] = json.dumps(report, ensure_ascii=False)
    mount['closed_mesh'] = bool(report['closedMesh'])
    mount['contact_passed'] = bool(contact_ok)
    if report['allGeometryChecksPassed']:
        source.hide_render = True
        source.hide_set(True)
        placeholder = sc.objects.get('HS12 seated guardian saddle')
        if placeholder is not None and placeholder != mount:
            placeholder.hide_render = True
            placeholder.hide_set(True)
    elif not source_preserved or not cap_preserved:
        raise AssertionError('Source/cap changed while creating the display saddle')
    else:
        mount.hide_render = True
        mount.hide_set(True)
    return mount


def get_checks(mount):
    """Read the JSON-compatible closure and contact receipt for the caller."""
    return json.loads(mount['mount_checks'])
