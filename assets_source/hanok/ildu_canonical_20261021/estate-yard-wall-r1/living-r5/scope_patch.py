"""Repair only R4's secondary scope feather; no Blender launch or persistence."""

import hashlib
import json
import math


PREFIX = 'Scope R5 | '
FINAL_MIX_LABEL = 'original exterior versus R4 interior'
POSITION_LABEL = 'world XY metres'
INTERNAL_TOLERANCE_M = 1e-6


def patch_scope(original_saved_r4_mat, full_ground_scope_dict):
    """Return a copy with only the final original/R4 Surface Mix Fac replaced.

    Scope is a hard convex-piece union times one global inward feather based on
    actual finite segments of original_scope_polygon. Internal edges do not
    select or clip different feather fields. All R4 BSDF inputs remain intact.
    """
    scope = full_ground_scope_dict
    pieces = [z for z in scope['zones'] if z['type'] in ('scope', 'interior')]
    outer = [tuple(float(v) for v in xy[:2]) for xy in scope['original_scope_polygon']]
    if len(outer) > 3 and outer[0] == outer[-1]:
        outer.pop()
    if not pieces or len(outer) < 3:
        raise ValueError('Require convex scope pieces and original outer boundary')
    feather = float(scope.get('scope_feather', pieces[0].get('feather', .45)))
    if not math.isfinite(feather) or feather <= 0:
        raise ValueError('Global inward feather must be positive finite metres')
    if 'scope_feather' not in scope and any(abs(float(z.get('feather', .45)) - feather) > 1e-9
                                          for z in pieces):
        raise ValueError('Different piece feathers require an explicit global scope_feather')

    prepared = []
    for item in pieces:
        poly = [tuple(float(v) for v in xy[:2]) for xy in item['polygon']]
        if len(poly) > 3 and poly[0] == poly[-1]:
            poly.pop()
        signed_area = sum(a[0] * b[1] - b[0] * a[1]
                          for a, b in zip(poly, poly[1:] + poly[:1]))
        if len(poly) < 3 or not math.isfinite(signed_area) or abs(signed_area) < 1e-8:
            raise ValueError('Invalid scope piece polygon')
        orientation = 1 if signed_area > 0 else -1
        planes = []
        for a, b in zip(poly, poly[1:] + poly[:1]):
            dx, dy = b[0] - a[0], b[1] - a[1]
            length = math.hypot(dx, dy)
            if not math.isfinite(length) or length < 1e-8:
                raise ValueError('Invalid scope piece edge')
            nx, ny = -dy * orientation / length, dx * orientation / length
            plane = (nx, ny, -nx * a[0] - ny * a[1])
            if any(nx * p[0] + ny * p[1] + plane[2] < -1e-7 for p in poly):
                raise ValueError('Scope pieces must be convex')
            planes.append(plane)
        hard_edges = frozenset(int(i) for i in item.get('hard_edges', ()))
        if any(i < 0 or i >= len(planes) for i in hard_edges):
            raise ValueError('Invalid internal decomposition edge index')
        prepared.append((str(item['name']), planes, hard_edges))
    for a, b in zip(outer, outer[1:] + outer[:1]):
        if not all(math.isfinite(v) for v in (*a, *b)) or math.dist(a, b) < 1e-8:
            raise ValueError('Invalid finite outer boundary segment')

    tree_in = original_saved_r4_mat.node_tree
    mixes = [n for n in tree_in.nodes if n.type == 'MIX_SHADER' and n.label == FINAL_MIX_LABEL]
    # R4 retains the R3 exterior graph, which also has a "world XY metres"
    # label. Select the R4 node explicitly instead of matching both labels.
    positions = [n for n in tree_in.nodes if n.name == 'Soil R4 | ' + POSITION_LABEL]
    if len(mixes) != 1 or len(positions) != 1:
        raise ValueError('Expected exactly one saved R4 final Surface Mix and world XY position')
    material = original_saved_r4_mat.copy()
    material.name = 'Living R5 | global outer scope | ' + original_saved_r4_mat.name
    tree = material.node_tree
    final_mix = tree.nodes[mixes[0].name]
    position = tree.nodes[positions[0].name].outputs['Vector']

    def node(kind, name):
        result = tree.nodes.new(kind)
        result.name = PREFIX + name
        result.label = name
        return result

    def connect(value, socket):
        if hasattr(value, 'node'):
            tree.links.new(value, socket)
        else:
            socket.default_value = value

    def scalar(op, a, b, name):
        result = node('ShaderNodeMath', name)
        result.operation = op
        connect(a, result.inputs[0])
        connect(b, result.inputs[1])
        return result.outputs[0]

    def vector(op, a, b, name):
        result = node('ShaderNodeVectorMath', name)
        result.operation = op
        connect(a, result.inputs[0])
        if b is not None:
            connect(b, result.inputs[1])
        return result.outputs['Value' if op in ('DOT_PRODUCT', 'LENGTH') else 'Vector']

    def remap(value, end, name, smooth=False):
        result = node('ShaderNodeMapRange', name)
        result.clamp = True
        result.interpolation_type = 'SMOOTHSTEP' if smooth else 'LINEAR'
        connect(value, result.inputs['Value'])
        result.inputs['From Min'].default_value = 0
        result.inputs['From Max'].default_value = end
        result.inputs['To Min'].default_value = 0
        result.inputs['To Max'].default_value = 1
        return result.outputs[0]

    homogeneous = vector('ADD', position, (0, 0, 1), 'world XY1 for hard scope membership')
    hard_union = 0.0
    for name, planes, internal_edges in prepared:
        minimum, external_minimum = None, None
        for index, plane in enumerate(planes):
            distance = vector('DOT_PRODUCT', homogeneous, plane, '%s edge %d signed metres' % (name, index))
            minimum = distance if minimum is None else scalar(
                'MINIMUM', minimum, distance, '%s edge %d hard minimum' % (name, index))
            if index not in internal_edges:
                external_minimum = distance if external_minimum is None else scalar(
                    'MINIMUM', external_minimum, distance, '%s edge %d external inclusion' % (name, index))
        inside = scalar('GREATER_THAN', minimum, -INTERNAL_TOLERANCE_M, name + ' tolerant internal inclusion')
        if external_minimum is not None:
            outside = scalar('LESS_THAN', external_minimum, 0, name + ' outside actual outer halfplane')
            inside = scalar('MULTIPLY', inside, scalar('SUBTRACT', 1, outside, name + ' exact outer inclusion'),
                            name + ' hard membership without external tolerance leak')
        hard_union = scalar('MAXIMUM', hard_union, inside, name + ' hard scope union')

    nearest = None
    for index, (a, b) in enumerate(zip(outer, outer[1:] + outer[:1])):
        dx, dy = b[0] - a[0], b[1] - a[1]
        length_sq = dx * dx + dy * dy
        tag = 'original outer segment %02d' % index
        relative = vector('SUBTRACT', position, (*a, 0), tag + ' relative point')
        parameter = vector('DOT_PRODUCT', relative, (dx / length_sq, dy / length_sq, 0), tag + ' projection')
        clipped = remap(parameter, 1, tag + ' finite segment clamp')
        scaled = node('ShaderNodeVectorMath', tag + ' closest point offset')
        scaled.operation = 'SCALE'
        scaled.inputs[0].default_value = (dx, dy, 0)
        connect(clipped, scaled.inputs['Scale'])
        residual = vector('SUBTRACT', relative, scaled.outputs['Vector'], tag + ' residual')
        distance = vector('LENGTH', residual, None, tag + ' true finite segment distance')
        nearest = distance if nearest is None else scalar('MINIMUM', nearest, distance, tag + ' global nearest')
    global_feather = remap(nearest, feather, 'one global original-boundary inward feather', smooth=True)
    new_factor = scalar('MULTIPLY', hard_union, global_feather, 'hard union times global original-boundary feather')
    connect(new_factor, final_mix.inputs[0])

    material['scope_repair'] = 'hard convex union multiplied by one global finite outer-segment inward feather'
    material['scope_repair_source_material'] = original_saved_r4_mat.name
    material['scope_repair_source_scope_sha256'] = hashlib.sha256(
        json.dumps(scope, sort_keys=True, ensure_ascii=False, separators=(',', ':')).encode()).hexdigest()
    material['scope_repair_global_feather_m'] = feather
    material['scope_repair_outer_segments'] = len(outer)
    material['scope_repair_preserves_all_interior_bsdf_inputs'] = True
    return material
