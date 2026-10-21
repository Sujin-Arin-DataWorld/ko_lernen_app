"""CPU-only QA of the secondary R5 scope repair, not the primary light fix.

Reads the local scope and patch code; writes only scope-verification.json.
Does not import Blender, change a source/scene, or render.
"""

import hashlib
import json
import math
from pathlib import Path


FOLDER = Path(__file__).resolve().parent
EPS = 1e-6
STEP = .25
PAIR_OFFSET = .01


def edges(poly):
    return zip(poly, poly[1:] + poly[:1])


def signed_area(poly):
    return sum(a[0] * b[1] - b[0] * a[1] for a, b in edges(poly)) / 2


def planes(poly):
    orient = 1 if signed_area(poly) > 0 else -1
    result = []
    for a, b in edges(poly):
        dx, dy = b[0] - a[0], b[1] - a[1]
        length = math.hypot(dx, dy)
        nx, ny = -dy * orient / length, dx * orient / length
        result.append((nx, ny, -nx * a[0] - ny * a[1]))
    return result


def distances(point, eq):
    return [nx * point[0] + ny * point[1] + c for nx, ny, c in eq]


def inside_polygon(point, poly):
    x, y = point
    crossings = 0
    for a, b in edges(poly):
        if (a[1] > y) != (b[1] > y):
            intersection = a[0] + (y - a[1]) * (b[0] - a[0]) / (b[1] - a[1])
            crossings += x < intersection
    return bool(crossings % 2)


def segment_distance(point, a, b):
    dx, dy = b[0] - a[0], b[1] - a[1]
    t = max(0, min(1, ((point[0] - a[0]) * dx + (point[1] - a[1]) * dy) / (dx * dx + dy * dy)))
    return math.hypot(point[0] - a[0] - t * dx, point[1] - a[1] - t * dy)


def smooth(value):
    value = max(0, min(1, value))
    return value * value * (3 - 2 * value)


def run():
    source = FOLDER / 'ground-scope.json'
    data = json.loads(source.read_text(encoding='utf-8'))
    outer = data['original_scope_polygon']
    pieces = [z for z in data['zones'] if z['type'] in ('scope', 'interior')]
    prepared = [(z, planes(z['polygon']), set(z.get('hard_edges', []))) for z in pieces]
    feather = float(data.get('scope_feather', pieces[0].get('feather', .45)))

    def boundary_distance(point):
        return min(segment_distance(point, a, b) for a, b in edges(outer))

    def hard_union(point):
        for zone, eq, hard in prepared:
            ds = distances(point, eq)
            if min(ds) <= -EPS:
                continue
            external = [value for index, value in enumerate(ds) if index not in hard]
            if external and min(external) < 0:
                continue
            return True
        return False

    def new_mask(point, distance=None):
        if not hard_union(point):
            return 0.0
        return smooth((boundary_distance(point) if distance is None else distance) / feather)

    def old_mask(point):
        values = []
        for zone, eq, hard in prepared:
            ds = distances(point, eq)
            if not hard:
                values.append(smooth(min(ds) / zone['feather']))
            elif min(ds) <= -EPS:
                values.append(0)
            else:
                external = [value for index, value in enumerate(ds) if index not in hard]
                values.append(smooth(min(external) / zone['feather']) if external else 1)
        return max(values)

    unique_edges = {}
    for zone, _, hard in prepared:
        poly = zone['polygon']
        for index in hard:
            a, b = poly[index], poly[(index + 1) % len(poly)]
            key = tuple(sorted((tuple(a), tuple(b))))
            unique_edges.setdefault(key, []).append({'piece': zone['name'], 'edge': index})
    paired_checks = old_nonunit_count = new_nonunit_count = 0
    old_max_jump = new_max_jump = 0
    old_bad_pairs = []
    for (a, b), owners in unique_edges.items():
        dx, dy = b[0] - a[0], b[1] - a[1]
        length = math.hypot(dx, dy)
        nx, ny = -dy / length, dx / length
        for index in range(1, 100):
            t = index / 100
            midpoint = (a[0] + dx * t, a[1] + dy * t)
            if boundary_distance(midpoint) <= feather + PAIR_OFFSET:
                continue
            left = (midpoint[0] + nx * PAIR_OFFSET, midpoint[1] + ny * PAIR_OFFSET)
            right = (midpoint[0] - nx * PAIR_OFFSET, midpoint[1] - ny * PAIR_OFFSET)
            old_values = [old_mask(left), old_mask(right)]
            new_values = [new_mask(left), new_mask(right)]
            paired_checks += 1
            old_max_jump = max(old_max_jump, abs(old_values[0] - old_values[1]))
            new_max_jump = max(new_max_jump, abs(new_values[0] - new_values[1]))
            if min(old_values) < 1 - 1e-7:
                old_nonunit_count += 1
                old_bad_pairs.append({'midpoint': midpoint, 'sample_points': [left, right],
                                      'outer_distance': boundary_distance(midpoint),
                                      'old_masks': old_values, 'new_masks': new_values,
                                      'new_passed': min(new_values) >= 1 - 1e-7})
            if min(new_values) < 1 - 1e-7:
                new_nonunit_count += 1

    xmin, xmax = min(p[0] for p in outer) - 1, max(p[0] for p in outer) + 1
    ymin, ymax = min(p[1] for p in outer) - 1, max(p[1] for p in outer) + 1
    tested = skipped = mismatches = leaks = deficits = 0
    examples = []
    for iy in range(math.ceil((ymax - ymin) / STEP) + 1):
        for ix in range(math.ceil((xmax - xmin) / STEP) + 1):
            point = (xmin + ix * STEP, ymin + iy * STEP)
            distance = boundary_distance(point)
            if distance <= EPS:
                skipped += 1
                continue
            tested += 1
            original_inside = inside_polygon(point, outer)
            inclusion = hard_union(point)
            value = new_mask(point, distance)
            mismatch = original_inside != inclusion
            leak = not original_inside and value > 1e-12
            deficit = original_inside and distance > feather + EPS and value < 1 - 1e-7
            mismatches += mismatch
            leaks += leak
            deficits += deficit
            if (mismatch or leak or deficit) and len(examples) < 30:
                examples.append({'point': point, 'inside': original_inside,
                                 'hard_union': inclusion, 'mask': value, 'distance': distance})
    all_paired = all(len(owners) == 2 for owners in unique_edges.values())
    area_difference = abs(abs(signed_area(outer)) - sum(abs(signed_area(z['polygon'])) for z in pieces))
    passed = (paired_checks == 754 and old_nonunit_count == 4 and new_nonunit_count == 0
              and new_max_jump < 1e-7 and mismatches == leaks == deficits == 0
              and all_paired and area_difference < 1e-6)
    report = {
        'kind': 'CPU-only secondary scope repair QA; not primary lighting-cause or native-render evidence',
        'scope_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
        'scope_patch_sha256': hashlib.sha256((FOLDER / 'scope_patch.py').read_bytes()).hexdigest(),
        'global_outer_segment_count': len(outer), 'convex_piece_count': len(pieces),
        'global_feather_m': feather, 'internal_inclusion_tolerance_m': EPS,
        'areas': {'original': abs(signed_area(outer)), 'difference_from_sum_pieces': area_difference},
        'internal_edges': {'unique_count': len(unique_edges), 'all_paired': all_paired,
                           'sample_positions_per_edge': 99, 'pair_offset_m': PAIR_OFFSET,
                           'eligible_pair_count': paired_checks, 'old_nonunit_pair_count': old_nonunit_count,
                           'new_nonunit_pair_count': new_nonunit_count,
                           'old_maximum_pair_jump': old_max_jump, 'new_maximum_pair_jump': new_max_jump,
                           'old_four_bad_pairs_rechecked': old_bad_pairs},
        'grid': {'step_m': STEP, 'tested': tested, 'boundary_points_skipped': skipped,
                 'classification_mismatch_count': mismatches, 'outside_leak_count': leaks,
                 'deep_interior_nonunit_count': deficits, 'failure_examples': examples},
        'passed': passed,
        'limitation': 'Numerical equations mirror scope_patch.py; actual Blender node construction, float behaviour, exported library and final lighting proof remain root verification.'
    }
    output = FOLDER / 'scope-verification.json'
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps({'passed': passed, 'scope_sha256': report['scope_sha256'],
                      'eligible_pairs': paired_checks, 'old_bad_pairs': old_nonunit_count,
                      'new_bad_pairs': new_nonunit_count, 'old_max_jump': old_max_jump,
                      'new_max_jump': new_max_jump, 'grid_points': tested,
                      'mismatches': mismatches, 'outside_leaks': leaks, 'deep_deficits': deficits,
                      'saved': str(output)}, ensure_ascii=False))


if __name__ == '__main__':
    run()
