"""Read-only numeric scope QA. Writes only scope-verification.json.

Run with ordinary Python; does not import Blender or touch scene/material files.
The shader's normalized halfplane/inward-feather equations are evaluated on CPU.
"""

import hashlib
import json
import math
from pathlib import Path


FOLDER = Path(__file__).resolve().parent
EPS = 1e-6
STEP = .25


def pairs(poly):
    return zip(poly, poly[1:] + poly[:1])


def signed_area(poly):
    return sum(a[0] * b[1] - b[0] * a[1] for a, b in pairs(poly)) / 2


def planes(poly):
    orient = 1 if signed_area(poly) > 0 else -1
    result = []
    for a, b in pairs(poly):
        dx, dy = b[0] - a[0], b[1] - a[1]
        length = math.hypot(dx, dy)
        nx, ny = -dy * orient / length, dx * orient / length
        result.append((nx, ny, -nx * a[0] - ny * a[1]))
    return result


def distances(point, equations):
    return [nx * point[0] + ny * point[1] + c for nx, ny, c in equations]


def inside_poly(point, poly):
    x, y = point
    crossings = 0
    for a, b in pairs(poly):
        if (a[1] > y) != (b[1] > y):
            intersection = a[0] + (y - a[1]) * (b[0] - a[0]) / (b[1] - a[1])
            crossings += x < intersection
    return bool(crossings % 2)


def boundary_distance(point, poly):
    x, y = point
    nearest = 1e8
    for a, b in pairs(poly):
        dx, dy = b[0] - a[0], b[1] - a[1]
        t = max(0, min(1, ((x - a[0]) * dx + (y - a[1]) * dy) / (dx * dx + dy * dy)))
        nearest = min(nearest, math.hypot(x - a[0] - t * dx, y - a[1] - t * dy))
    return nearest


def smooth(value):
    value = max(0, min(1, value))
    return value * value * (3 - 2 * value)


def run():
    source = FOLDER / 'ground-scope.json'
    data = json.loads(source.read_text(encoding='utf-8'))
    outer = data['original_scope_polygon']
    pieces = [z for z in data['zones'] if z['type'] in ('scope', 'interior')]
    semantics = [z for z in data['zones'] if z['type'] not in ('scope', 'interior')]
    prepared = [(z, planes(z['polygon'])) for z in pieces]
    max_feather = max(z['feather'] for z in pieces)

    def union_mask(point):
        values = []
        for zone, equations in prepared:
            ds = distances(point, equations)
            hard = set(zone.get('hard_edges', []))
            if not hard:
                values.append(smooth(min(ds) / zone['feather']))
            elif min(ds) <= -EPS:
                values.append(0)
            else:
                exposed = [value for index, value in enumerate(ds) if index not in hard]
                values.append(smooth(min(exposed) / zone['feather']) if exposed else 1)
        return max(values)

    xmin, xmax = min(p[0] for p in outer) - 1, max(p[0] for p in outer) + 1
    ymin, ymax = min(p[1] for p in outer) - 1, max(p[1] for p in outer) + 1
    tested = skipped = inside_count = outside_count = 0
    mismatch_count = deficit_count = leak_count = 0
    mismatches, deficits, leaks = [], [], []
    for iy in range(math.ceil((ymax - ymin) / STEP) + 1):
        for ix in range(math.ceil((xmax - xmin) / STEP) + 1):
            point = (xmin + ix * STEP, ymin + iy * STEP)
            distance = boundary_distance(point, outer)
            if distance <= EPS:
                skipped += 1
                continue
            tested += 1
            original_inside = inside_poly(point, outer)
            convex_inside = any(min(distances(point, eq)) >= -EPS for _, eq in prepared)
            inside_count += original_inside
            outside_count += not original_inside
            if original_inside != convex_inside:
                mismatch_count += 1
                if len(mismatches) < 30:
                    mismatches.append({'point': point, 'original': original_inside, 'union': convex_inside})
            if original_inside and distance > max_feather + EPS:
                mask = union_mask(point)
                if mask < 1 - 1e-7:
                    deficit_count += 1
                    if len(deficits) < 30:
                        deficits.append({'point': point, 'boundary_distance': distance, 'mask': mask})
            elif not original_inside:
                mask = union_mask(point)
                if mask > 1e-7:
                    leak_count += 1
                    if len(leaks) < 30:
                        leaks.append({'point': point, 'mask': mask})

    edges = {}
    for zone, _ in prepared:
        polygon = zone['polygon']
        for index in zone.get('hard_edges', []):
            a, b = polygon[index], polygon[(index + 1) % len(polygon)]
            key = tuple(sorted((tuple(a), tuple(b))))
            edges.setdefault(key, []).append({'piece': zone['name'], 'edge': index})
    midpoint_checks = []
    for (a, b), owners in edges.items():
        point = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
        distance = boundary_distance(point, outer)
        mask = union_mask(point)
        eligible = distance > max_feather + EPS
        midpoint_checks.append({'edge': [a, b], 'owners': owners, 'point': point,
                                'outer_boundary_distance': distance, 'union_mask': mask,
                                'eligible_distance_gt_feather': eligible,
                                'passed': mask >= 1 - 1e-7 if eligible else None})
    convexity = []
    for zone in data['zones']:
        eq = planes(zone['polygon'])
        minimum = min(min(distances(point, eq)) for point in zone['polygon'])
        convexity.append({'piece': zone['name'], 'type': zone['type'],
                          'minimum_vertex_halfplane_distance': minimum, 'passed': minimum >= -EPS})

    # Derived from helper construction, not Blender's optimized runtime graph.
    old_polys = [outer] + [z['polygon'] for z in semantics]
    old_nodes = sum(sum(17 if abs(b[1] - a[1]) > 1e-10 else 7 for a, b in pairs(poly)) + 3
                    for poly in old_polys)
    new_nodes = 0
    for zone in data['zones']:
        edge_count = len(zone['polygon'])
        hard = set(zone.get('hard_edges', []))
        exposed = edge_count - len(hard)
        count = edge_count + edge_count - 1
        count += 1 if not hard else ((exposed - 1) + 3 if exposed else 1)
        new_nodes += count
    area_original = abs(signed_area(outer))
    area_pieces = sum(abs(signed_area(z['polygon'])) for z in pieces)
    paired = all(len(owners) == 2 for owners in edges.values())
    required_pass = (not mismatch_count and not leak_count and paired
                     and all(item['passed'] for item in convexity)
                     and all(item['passed'] is not False for item in midpoint_checks)
                     and abs(area_original - area_pieces) < 1e-6)
    report = {
        'kind': 'read-only numeric scope QA; not Blender/render evidence',
        'scope_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
        'scope_piece_count': len(pieces), 'semantic_zone_count': len(semantics),
        'tended_zone_count': sum(z['type'] == 'tended' for z in semantics),
        'tolerance_m': EPS,
        'grid': {'step_m': STEP, 'tested': tested, 'boundary_points_skipped': skipped,
                 'inside_samples': inside_count, 'outside_samples': outside_count,
                 'classification_mismatch_count': mismatch_count,
                 'classification_mismatch_samples': mismatches,
                 'interior_far_from_boundary_mask_deficit_count': deficit_count,
                 'interior_far_from_boundary_mask_deficit_samples': deficits,
                 'outside_mask_leak_count': leak_count, 'outside_mask_leak_samples': leaks},
        'areas': {'original': area_original, 'sum_convex_pieces': area_pieces,
                  'absolute_difference': abs(area_original - area_pieces)},
        'convexity': convexity,
        'internal_edges': {'unique_count': len(edges), 'all_edges_paired': paired,
                           'midpoint_checks': midpoint_checks},
        'nodecount_theory': {'old_original_concave_scope_plus_same_semantics': old_nodes,
                             'new_nine_convex_pieces_plus_same_semantics': new_nodes,
                             'reduction_percent': 100 * (1 - new_nodes / old_nodes),
                             'excludes': 'scope union, shared coordinates, original material, substrate and texture graphs; no runtime memory claim'},
        'required_checks_passed': required_pass,
        'passed': required_pass and not deficit_count,
        'additional_strict_grid_check_note': (
            'Preserve strict deficits: convex infinite-edge line distance can be smaller than '
            'segment distance near a corner. Required midpoint and exterior checks are separate '
            'from the strict all-interior-grid mask=1 criterion.'),
    }
    output = FOLDER / 'scope-verification.json'
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps({'required_checks_passed': required_pass, 'strict_passed': report['passed'],
                      'scope_sha256': report['scope_sha256'], 'tended_zone_count': report['tended_zone_count'],
                      'tested': tested, 'mismatches': mismatch_count, 'strict_deficits': deficit_count,
                      'leaks': leak_count, 'nodecount_theory': report['nodecount_theory'],
                      'saved': str(output)}, ensure_ascii=False))


if __name__ == '__main__':
    run()
