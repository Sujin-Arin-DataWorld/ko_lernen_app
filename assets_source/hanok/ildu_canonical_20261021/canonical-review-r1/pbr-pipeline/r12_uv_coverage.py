"""Pure read-only R12 UV island coverage audit. No Blender import or UV edits.

Public API: audit_triangle_uvs(normalized_uvs[N,3,2], part_ids[N], texture_size,
source_parts=..., triangle_world_areas=...). Islands share exact UV edges within
the same source part. All-zero-world-area charts remain counted but are exempt
from painted-pixel requirements only when explicit area evidence is supplied.
PCA minor extent and texel-center coverage are chart diagnostics, not a guarantee
of bake quality, mip safety, or a requirement that every tiny triangle be sampled.
"""
from __future__ import annotations

import argparse
from collections import defaultdict
import hashlib
import json
from pathlib import Path

import numpy as np

WORLD_AREA_EPSILON = 1e-12


def triangle_areas(triangle_positions):
    """Compute world area from already transformed (N,3,3) positions, without edits."""
    points = np.asarray(triangle_positions, dtype=np.float64)
    if points.ndim != 3 or points.shape[1:] != (3, 3) or not np.isfinite(points).all():
        raise ValueError('Expected finite triangle world positions with shape (N, 3, 3)')
    areas = .5 * np.linalg.norm(np.cross(points[:, 1] - points[:, 0], points[:, 2] - points[:, 0]), axis=1)
    if not np.isfinite(areas).all():
        raise ValueError('World triangle area overflow')
    return areas


def _size(size):
    if isinstance(size, (int, np.integer)):
        size = (int(size), int(size))
    if len(size) != 2 or any(not isinstance(v, (int, np.integer)) or v <= 0 for v in size):
        raise ValueError('texture_size must be a positive integer or (width, height)')
    return int(size[0]), int(size[1])


def principal_axes(points):
    """Return center, orthonormal major/minor axes, and spans in input units.

    Uses unique UV vertices so triangulation repetition does not weight the axes.
    This is a PCA box, not the minimum-area enclosing rectangle.
    """
    points = np.asarray(points, dtype=np.float64).reshape(-1, 2)
    if not len(points) or not np.isfinite(points).all():
        raise ValueError('Finite nonempty 2D points required')
    points = np.unique(points, axis=0)
    center = points.mean(axis=0)
    relative = points - center
    _, axes = np.linalg.eigh(relative.T @ relative)
    axes = axes[:, ::-1]
    projected = relative @ axes
    spans = np.ptp(projected, axis=0)
    # PCA variance order need not equal bounding-span order for unusual charts.
    if spans[0] < spans[1]:
        axes = axes[:, ::-1]
        spans = spans[::-1]
    return center, axes, spans


def uv_island_indices(triangle_uvs):
    """Connected components of triangles sharing a complete exact UV edge.

    Call per part. Point contact alone is not connectivity. Coincident overlapping
    charts can connect here, so this routine is not an overlap/topology validator.
    """
    triangles = np.asarray(triangle_uvs, dtype=np.float64)
    if triangles.ndim != 3 or triangles.shape[1:] != (3, 2) or not np.isfinite(triangles).all():
        raise ValueError('Expected finite triangle UVs with shape (N, 3, 2)')
    parent = list(range(len(triangles)))
    edges = {}

    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    for i, triangle in enumerate(triangles):
        for j in range(3):
            start, end = tuple(triangle[j]), tuple(triangle[(j + 1) % 3])
            if start == end:
                continue
            edge = (start, end) if start < end else (end, start)
            previous = edges.get(edge)
            if previous is None:
                edges[edge] = i
            else:
                parent[find(i)] = find(previous)
    groups = defaultdict(list)
    for i in range(len(triangles)):
        groups[find(i)].append(i)
    return list(groups.values())


def triangle_pixel_centers(triangle_pixels, texture_size):
    """Integer (x,y) texel indices whose centers lie in a UV triangle.

    Includes shared edges; island unions deduplicate them. Coordinates follow
    glTF's top-left UV origin. This models center coverage, not Cycles subpixel
    sampling, dilation, or conservative rasterization.
    """
    width, height = _size(texture_size)
    triangle = np.asarray(triangle_pixels, dtype=np.float64)
    if triangle.shape != (3, 2) or not np.isfinite(triangle).all():
        raise ValueError('Expected one finite triangle in pixel coordinates')
    lo = np.maximum(np.ceil(triangle.min(axis=0) - .5).astype(np.int64), 0)
    hi = np.minimum(np.floor(triangle.max(axis=0) - .5).astype(np.int64), [width - 1, height - 1])
    empty = np.empty((0, 2), dtype=np.int64)
    if (hi < lo).any():
        return empty
    e0, e1 = triangle[1] - triangle[0], triangle[2] - triangle[0]
    determinant = e0[0] * e1[1] - e0[1] * e1[0]
    if abs(determinant) <= 1e-14:
        return empty
    # Work in bounded row strips, avoiding a full-atlas temporary point grid.
    results = []
    for row in range(int(lo[1]), int(hi[1]) + 1, 64):
        xs, ys = np.meshgrid(np.arange(lo[0], hi[0] + 1), np.arange(row, min(row + 64, hi[1] + 1)))
        dx, dy = xs + .5 - triangle[0, 0], ys + .5 - triangle[0, 1]
        a = (dx * e1[1] - dy * e1[0]) / determinant
        b = (e0[0] * dy - e0[1] * dx) / determinant
        inside = (a >= -1e-10) & (b >= -1e-10) & (a + b <= 1 + 1e-10)
        if inside.any():
            results.append(np.column_stack((xs[inside], ys[inside])))
    return np.concatenate(results) if results else empty


def audit_triangle_uvs(triangle_uvs, part_ids, texture_size, source_parts=None, minimum_minor_texels=2.0,
                       triangle_world_areas=None, world_area_epsilon=WORLD_AREA_EPSILON):
    """Return JSON-serializable per-source-part and per-island measurements.

    Input arrays are never changed. Source part rows may include partId,
    sourceObject, and evaluatedEmpty; extra receipt fields are not required.
    Optional triangle_world_areas has one nonnegative finite world area per input
    triangle. Only charts whose every triangle is at or below world_area_epsilon
    are exempt from painted-pixel requirements; no triangle or identity is removed.
    If areas are absent, no chart is exempt. Failure diagnostics are separate
    from approval; no visual success is implied.
    """
    width, height = _size(texture_size)
    uv = np.asarray(triangle_uvs, dtype=np.float64)
    ids = np.asarray(part_ids)
    if uv.ndim != 3 or uv.shape[1:] != (3, 2) or not np.isfinite(uv).all():
        raise ValueError('Expected finite normalized UVs with shape (N, 3, 2)')
    if uv.size and (uv.min() < 0 or uv.max() > 1):
        raise ValueError('Atlas UVs outside [0,1]')
    if ids.shape != (len(uv),) or not np.isfinite(ids).all() or (ids < 0).any() or not np.equal(ids, np.floor(ids)).all():
        raise ValueError('Exactly one nonnegative integer source part ID per triangle required')
    if not np.isfinite(minimum_minor_texels) or minimum_minor_texels < 0:
        raise ValueError('Invalid minor-span threshold')
    if not np.isfinite(world_area_epsilon) or world_area_epsilon < 0:
        raise ValueError('Invalid world-area epsilon')
    world_areas = None
    if triangle_world_areas is not None:
        world_areas = np.asarray(triangle_world_areas, dtype=np.float64)
        if world_areas.shape != (len(uv),) or not np.isfinite(world_areas).all() or (world_areas < 0).any():
            raise ValueError('Exactly one finite nonnegative world area per triangle required')
    ids = ids.astype(np.int64)
    by_id = {}
    for row in source_parts or []:
        pid = row['partId']
        if pid in by_id:
            raise ValueError('Duplicate source part ID')
        by_id[pid] = row
    if source_parts is not None and not set(map(int, ids)) <= set(by_id):
        raise ValueError('Triangle contains foreign source part ID')
    report = {'schemaVersion': 2, 'textureSize': [width, height], 'triangles': len(uv),
              'definition': 'Exact shared-UV-edge islands within each source part; texel centers at x+.5,y+.5.',
              'minimumMinorSpanTexels': float(minimum_minor_texels), 'parts': [],
              'worldAreaProvided': world_areas is not None, 'worldAreaEpsilon': float(world_area_epsilon),
              'worldAreaBasis': 'caller-provided triangle_world_areas' if world_areas is not None else None,
              'worldZeroAreaTriangles': int(np.sum(world_areas <= world_area_epsilon)) if world_areas is not None else None,
              'worldSurfaceTriangles': int(np.sum(world_areas > world_area_epsilon)) if world_areas is not None else None,
              'limitations': ['PCA span is a diagnostic; it does not guarantee coverage of pointed or concave islands.',
                              'Does not validate overlaps, inter-island gaps, bake pixel colors, padding, mipmaps, or native geometry.',
                              'No requirement that every triangulation cell contain its own texel center.',
                              'World-area exemptions are numerical, at the reported epsilon; they do not delete geometry.']}
    for pid in sorted(set(map(int, ids)) | set(by_id)):
        global_indices = np.flatnonzero(ids == pid)
        triangles = uv[global_indices] * np.array([width, height])
        groups = uv_island_indices(triangles)
        rows = []
        for island_id, members in enumerate(groups):
            selected = triangles[members]
            points = selected.reshape(-1, 2)
            center, axes, spans = principal_axes(points)
            e0, e1 = selected[:, 1] - selected[:, 0], selected[:, 2] - selected[:, 0]
            area = abs(e0[:, 0] * e1[:, 1] - e0[:, 1] * e1[:, 0]) * .5
            sampled = [triangle_pixel_centers(triangle, (width, height)) for triangle in selected]
            pixels = np.unique(np.concatenate(sampled), axis=0)
            member_areas = world_areas[global_indices[members]] if world_areas is not None else None
            all_zero_world = bool(np.all(member_areas <= world_area_epsilon)) if member_areas is not None else None
            paint_required = all_zero_world is not True
            rows.append({'islandId': island_id, 'triangleCount': len(members),
                         'triangleIndices': global_indices[members].tolist(),
                         'uvAreaTexels': float(area.sum()), 'pixelCenterCount': len(pixels),
                         'trianglesWithoutPixelCenters': sum(len(v) == 0 for v in sampled),
                         'zeroCenterIsland': len(pixels) == 0,
                         'worldArea': float(member_areas.sum()) if member_areas is not None else None,
                         'worldZeroAreaTriangles': int(np.sum(member_areas <= world_area_epsilon)) if member_areas is not None else None,
                         'allZeroWorldArea': all_zero_world, 'paintedPixelRequirement': paint_required,
                         'paintedPixelExemption': 'all triangle world areas <= epsilon' if not paint_required else None,
                         'zeroCenterFailure': len(pixels) == 0 and paint_required,
                         'principalMajorSpanTexels': float(spans[0]), 'principalMinorSpanTexels': float(spans[1]),
                         'belowMinimumMinorSpan': bool(spans[1] < minimum_minor_texels),
                         'minorSpanFailure': bool(spans[1] < minimum_minor_texels) and paint_required,
                         'principalCenterPixels': center.tolist(), 'principalAxes': axes.tolist(),
                         'bboxPixels': [points.min(axis=0).tolist(), points.max(axis=0).tolist()]})
        identity = by_id.get(pid, {})
        expected_triangles = None
        if 'evaluatedLoopCount' in identity and 'evaluatedFaceCount' in identity:
            expected_triangles = identity['evaluatedLoopCount'] - 2 * identity['evaluatedFaceCount']
            if expected_triangles != len(triangles):
                raise ValueError(f'Source part {pid} triangulation count differs: {len(triangles)} vs {expected_triangles}')
        part_areas = world_areas[global_indices] if world_areas is not None else None
        report['parts'].append({'partId': pid, 'sourceObject': identity.get('sourceObject'),
                                'expectedEmpty': identity.get('evaluatedEmpty'), 'triangleCount': len(triangles),
                                'expectedTriangleCount': expected_triangles,
                                'sourceTriangleCountExact': True if expected_triangles is not None else None,
                                'worldZeroAreaTriangles': int(np.sum(part_areas <= world_area_epsilon)) if part_areas is not None else None,
                                'worldSurfaceTriangles': int(np.sum(part_areas > world_area_epsilon)) if part_areas is not None else None,
                                'islandCount': len(rows), 'zeroCenterIslands': sum(row['zeroCenterIsland'] for row in rows),
                                'excludedAllZeroWorldAreaIslands': sum(row['allZeroWorldArea'] is True for row in rows),
                                'zeroCenterFailureIslands': sum(row['zeroCenterFailure'] for row in rows),
                                'islandsBelowMinimumMinorSpan': sum(row['belowMinimumMinorSpan'] for row in rows),
                                'minorSpanFailureIslands': sum(row['minorSpanFailure'] for row in rows),
                                'islands': rows})
    report['islandCount'] = sum(p['islandCount'] for p in report['parts'])
    report['zeroCenterIslands'] = sum(p['zeroCenterIslands'] for p in report['parts'])
    report['islandsBelowMinimumMinorSpan'] = sum(p['islandsBelowMinimumMinorSpan'] for p in report['parts'])
    report['excludedAllZeroWorldAreaIslands'] = sum(p['excludedAllZeroWorldAreaIslands'] for p in report['parts'])
    report['zeroCenterFailureIslands'] = sum(p['zeroCenterFailureIslands'] for p in report['parts'])
    report['minorSpanFailureIslands'] = sum(p['minorSpanFailureIslands'] for p in report['parts'])
    report['centerCoveragePass'] = report['zeroCenterFailureIslands'] == 0
    report['minorSpanPass'] = report['minorSpanFailureIslands'] == 0
    report['sourceTriangleCountsExact'] = (True if source_parts is not None and
        all(p['sourceTriangleCountExact'] is True for p in report['parts']) else None)
    report['allInputTrianglesRetained'] = sum(p['triangleCount'] for p in report['parts']) == len(uv)
    report['visualApproval'] = False
    return report


def audit_glb(glb_path, parts_path, texture_size, minimum_minor_texels=2.0):
    """Use existing R12 accessor validation; verify sidecar ranges before coverage."""
    from validate_r12_glb import Glb, active_nodes, SOURCE_ID
    glb_path, parts_path = Path(glb_path), Path(parts_path)
    blob, parts_bytes = glb_path.read_bytes(), parts_path.read_bytes()
    glb = Glb(blob)
    sidecar = json.loads(parts_bytes)
    declared = defaultdict(list)
    for part in sidecar['parts']:
        for row in part.get('glbTriangleRanges', []):
            declared[(row['node'], row['mesh'], row['primitive'])].append((row['firstTriangle'], row['endTriangle'], part['partId']))
    uv_rows, id_rows, area_rows, visited = [], [], [], set()
    for node_index, matrix in active_nodes(glb.doc).items():
        node = glb.doc['nodes'][node_index]
        if 'mesh' not in node:
            continue
        for prim_index, primitive in enumerate(glb.doc['meshes'][node['mesh']]['primitives']):
            if primitive.get('mode', 4) != 4:
                raise ValueError('Triangle primitives required')
            indices = glb.array(primitive['indices'])[:, 0].astype(np.int64).reshape(-1, 3)
            attributes = primitive['attributes']
            ids = glb.array(attributes[SOURCE_ID])[:, 0][indices]
            if not np.equal(ids, ids[:, :1]).all():
                raise ValueError('Triangle mixes source part IDs')
            ids = ids[:, 0]
            key = (node_index, node['mesh'], prim_index)
            visited.add(key)
            cursor = 0
            for start, end, pid in sorted(declared.get(key, [])):
                if start != cursor or end <= start or end > len(ids) or not np.equal(ids[start:end], pid).all():
                    raise ValueError('Sidecar range coverage or source identity mismatch')
                cursor = end
            if cursor != len(ids):
                raise ValueError('Sidecar does not cover every triangle')
            uv_rows.append(glb.array(attributes['TEXCOORD_0'])[indices])
            id_rows.append(ids)
            positions = glb.array(attributes['POSITION'])[indices].astype(np.float64)
            positions = positions @ matrix[:3, :3].T + matrix[:3, 3]
            area_rows.append(triangle_areas(positions))
    if not set(declared) <= visited:
        raise ValueError('Sidecar references unused primitive')
    if not uv_rows:
        raise ValueError('No source triangles')
    report = audit_triangle_uvs(np.concatenate(uv_rows), np.concatenate(id_rows), texture_size,
                               sidecar['parts'], minimum_minor_texels, triangle_world_areas=np.concatenate(area_rows))
    report.update(glb=str(glb_path.resolve()), glbSha256=hashlib.sha256(blob).hexdigest(),
                  sourceParts=str(parts_path.resolve()), sourcePartsSha256=hashlib.sha256(parts_bytes).hexdigest(),
                  worldAreaBasis='decoded GLB POSITION and active-scene world transforms; not an independent native-source area audit')
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--glb', required=True)
    parser.add_argument('--parts', required=True)
    parser.add_argument('--size', type=int, required=True)
    parser.add_argument('--minimum-minor-texels', type=float, default=2.)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    report = audit_glb(args.glb, args.parts, args.size, args.minimum_minor_texels)
    # Audit outputs are explicit; never replace an earlier receipt.
    with args.out.open('x', encoding='utf-8') as handle:
        json.dump(report, handle, indent=2)
        handle.write('\n')
    print(json.dumps({key: report[key] for key in ('triangles', 'worldZeroAreaTriangles', 'worldSurfaceTriangles',
          'islandCount', 'zeroCenterIslands', 'excludedAllZeroWorldAreaIslands', 'zeroCenterFailureIslands',
          'islandsBelowMinimumMinorSpan', 'minorSpanFailureIslands', 'centerCoveragePass', 'minorSpanPass',
          'sourceTriangleCountsExact', 'allInputTrianglesRetained', 'visualApproval')}, indent=2))


if __name__ == '__main__':
    main()
