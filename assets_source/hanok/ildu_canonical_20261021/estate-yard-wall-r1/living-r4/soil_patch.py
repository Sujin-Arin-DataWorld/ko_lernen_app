"""R4 world-scale courtyard substrate, with the original exterior preserved.

Caller supplies validated numeric world-XY polygons, binds the returned copied
material, and owns scene/geometry audits, rendering, and native persistence.
"""

import math


PREFIX = 'Soil R4 | '
MATERIAL = 'Living R4 | place-specific compacted earth'
SOURCE_SHA256 = '586b8a5328e7c0deaeff5f340639708c927ea224a429aca70dc313adadddff68'


def patch_soil(original, scene, zones):
    """Copy a ground material and replace only its supplied interior footprint.

    zones is a list of {name, type, polygon:[[world_x, world_y], ...], ...}.
    Polygons must be convex. The optional `feather` is an inward-only boundary
    transition in metres. `hard_edges` lists internal decomposition edge indices
    that clip the piece without feathering; external edges still feather inward.
    An `interior`/`scope` polygon explicitly limits the replacement; if absent,
    the union of the semantic zone polygons defines the replacement footprint.
    Recognised semantic types: front, central, north, side, tended. Unknown types use
    central statistics. No material binding, object or scene setting is edited.
    """
    if isinstance(zones, dict):
        zones = zones.get('zones', list(zones.values()))
    if not zones or not isinstance(zones, (list, tuple)):
        raise ValueError('Supply nonempty validated numeric world-XY zones')
    definitions = []
    for index, item in enumerate(zones):
        if not isinstance(item, dict):
            raise ValueError('Each zone must be a named polygon dictionary')
        polygon = tuple(tuple(float(c) for c in point[:2]) for point in item['polygon'])
        if len(polygon) > 3 and polygon[0] == polygon[-1]:
            polygon = polygon[:-1]
        if len(polygon) < 3 or not all(math.isfinite(c) for point in polygon for c in point):
            raise ValueError('A zone needs at least three finite XY vertices')
        signed_area = sum(a[0] * b[1] - b[0] * a[1]
                          for a, b in zip(polygon, polygon[1:] + polygon[:1]))
        if abs(signed_area) < 1e-8:
            raise ValueError('Zone polygon has zero signed area')
        orientation = 1 if signed_area > 0 else -1
        planes = []
        for a, b in zip(polygon, polygon[1:] + polygon[:1]):
            dx, dy = b[0] - a[0], b[1] - a[1]
            length = math.hypot(dx, dy)
            if length < 1e-8:
                raise ValueError('Zone polygon has a zero-length edge')
            nx, ny = -dy * orientation / length, dx * orientation / length
            constant = -nx * a[0] - ny * a[1]
            if any(nx * point[0] + ny * point[1] + constant < -1e-7 for point in polygon):
                raise ValueError('Zone polygon must be convex; root must decompose concave scope')
            planes.append((nx, ny, constant))
        hard_edges = frozenset(int(edge) for edge in item.get('hard_edges', ()))
        if any(edge < 0 or edge >= len(polygon) for edge in hard_edges):
            raise ValueError('hard_edges must index valid polygon edges')
        definitions.append(dict(item, name=str(item.get('name', 'zone%d' % index)),
                                type=str(item.get('type', 'central')).lower(), polygon=polygon,
                                planes=tuple(planes), hard_edges=hard_edges))

    material = original.copy()
    material.name = MATERIAL + ' | ' + original.name
    material.use_nodes = True
    tree = material.node_tree
    outputs = [n for n in tree.nodes if n.type == 'OUTPUT_MATERIAL' and n.is_active_output]
    if not outputs or not outputs[0].inputs['Surface'].is_linked:
        raise ValueError('The original material must have a connected active Surface output')
    output = outputs[0]
    original_surface = output.inputs['Surface'].links[0].from_socket

    def node(kind, name):
        item = tree.nodes.new(kind)
        item.name = PREFIX + name
        item.label = name
        return item

    def connect(value, socket):
        if hasattr(value, 'node'):
            tree.links.new(value, socket)
        else:
            socket.default_value = value

    def scalar(operation, a, b, name):
        item = node('ShaderNodeMath', name)
        item.operation = operation
        connect(a, item.inputs[0])
        connect(b, item.inputs[1])
        return item.outputs[0]

    def vector(operation, a, b, name):
        item = node('ShaderNodeVectorMath', name)
        item.operation = operation
        connect(a, item.inputs[0])
        connect(b, item.inputs[1])
        return item.outputs['Value' if operation in ('DISTANCE', 'DOT_PRODUCT') else 'Vector']

    def remap(value, low, high, name, start=0, end=1, smooth=False):
        item = node('ShaderNodeMapRange', name)
        item.clamp = True
        item.interpolation_type = 'SMOOTHSTEP' if smooth else 'LINEAR'
        for socket, value_in in (('Value', value), ('From Min', start), ('From Max', end),
                                 ('To Min', low), ('To Max', high)):
            connect(value_in, item.inputs[socket])
        return item.outputs[0]

    def mix(a, b, factor, name, mode='MIX'):
        item = node('ShaderNodeMixRGB', name)
        item.blend_type = mode
        for value, socket in ((factor, item.inputs[0]), (a, item.inputs[1]), (b, item.inputs[2])):
            connect(value, socket)
        return item.outputs[0]

    def noise(coords, scale, detail, name):
        item = node('ShaderNodeTexNoise', name)
        item.noise_dimensions = '3D'
        connect(coords, item.inputs['Vector'])
        connect(scale, item.inputs['Scale'])
        item.inputs['Detail'].default_value = detail
        item.inputs['Roughness'].default_value = .61
        return item

    geometry = node('ShaderNodeNewGeometry', 'world position with no object dependency')
    p = vector('MULTIPLY', geometry.outputs['Position'], (1, 1, 0), 'world XY metres')
    homogeneous = vector('ADD', p, (0, 0, 1), 'world XY1 for signed plane dot products')

    def polygon_mask(definition):
        """Two nodes/convex edge; internal diagonals clip without feather."""
        name = definition['name']
        hard_edges = definition['hard_edges']
        all_distance, external_distance = None, None
        for index, plane in enumerate(definition['planes']):
            tag = '%s edge %02d' % (name, index)
            distance = vector('DOT_PRODUCT', homogeneous, plane, tag + ' signed metres')
            all_distance = distance if all_distance is None else scalar(
                'MINIMUM', all_distance, distance, tag + ' convex minimum')
            if hard_edges and index not in hard_edges:
                external_distance = distance if external_distance is None else scalar(
                    'MINIMUM', external_distance, distance, tag + ' exposed edge minimum')
        feather = max(.001, float(definition.get('feather', .30)))
        if not hard_edges:
            return remap(all_distance, 0, 1, name + ' finite inward feather',
                         end=feather, smooth=True)
        inside = scalar('GREATER_THAN', all_distance, -1e-6, name + ' hard convex interior')
        if external_distance is None:
            return inside
        edge = remap(external_distance, 0, 1, name + ' external edges inward feather',
                     end=feather, smooth=True)
        return scalar('MULTIPLY', inside, edge, name + ' no internal diagonal fade')

    masks = [(definition, polygon_mask(definition)) for definition in definitions]
    explicit_scope = [(d, mask) for d, mask in masks if d['type'] in ('interior', 'scope')]
    semantics = [(d, mask) for d, mask in masks if d['type'] not in ('interior', 'scope')]
    interior = 0.0
    for definition, mask in explicit_scope or masks:
        interior = scalar('MAXIMUM', interior, mask, definition['name'] + ' scope union')

    # Material construction follows here; semantic parameters remain numeric
    # and no zone can alter original exterior through the final Shader mix.
    bsdf = node('ShaderNodeBsdfPrincipled', 'R4 interior compacted earth')
    bsdf.inputs['Metallic'].default_value = 0
    bsdf.inputs['Specular IOR Level'].default_value = .16

    # A shared continuous substrate crosses all semantic boundaries. Place masks
    # control frequency/density statistics instead of colouring whole parcels.
    envelope_field = noise(p, .26, 1.7, '2 to 5m compaction density envelope')
    drift = noise(p, .51, 2.2, 'irregular substrate domain')
    centred = vector('SUBTRACT', drift.outputs['Color'], (.5, .5, .5), 'centred substrate drift')
    warped = vector('ADD', p, vector('MULTIPLY', centred, (.42, .42, 0), 'limited substrate drift'),
                    'continuous irregular substrate coordinates')

    # Central defaults also cover any scope not assigned an explicit subzone.
    density, powder, compaction, contrast_weight = .62, .18, .50, 1.0
    profiles = {
        'front': (2.25, .40, .13, .84, 1.0),
        'central': (1.45, .62, .18, .50, 1.0),
        'north': (.87, .45, .23, .63, 1.0),
        'side': (1.85, .75, .30, .39, 1.0),
        'tended': (1.45, .28, .10, .90, .20),
    }
    for definition, mask in semantics:
        values = profiles.get(definition['type'], profiles['central'])
        # Semantic boundaries soften over supplied feathers. Their role is to
        # change substrate distribution, with no additive mean colour patch.
        for index, (old, new, label) in enumerate(zip(
                (density, powder, compaction, contrast_weight), values[1:],
                ('aggregate density', 'powder', 'compaction', 'body contrast'))):
            blended = scalar('ADD', scalar('MULTIPLY', old,
                             scalar('SUBTRACT', 1, mask, definition['name'] + ' inverse ' + label),
                             definition['name'] + ' previous ' + label),
                             scalar('MULTIPLY', new, mask, definition['name'] + ' local ' + label),
                             definition['name'] + ' blended ' + label)
            if index == 0:
                density = blended
            elif index == 1:
                powder = blended
            elif index == 2:
                compaction = blended
            else:
                contrast_weight = blended

    second_coords = vector('ADD', warped, (13.79, -8.31, 4.71), 'different phase substrate')
    substrate_fields = {}

    def substrate_field(kind):
        if kind not in substrate_fields:
            frequency = profiles[kind][0]
            medium_a = noise(warped, frequency, 2.4, kind + ' continuous substrate A')
            medium_b = noise(second_coords, frequency * 2.12, 1.8, kind + ' continuous substrate B')
            substrate_fields[kind] = mix(medium_a.outputs['Fac'], medium_b.outputs['Fac'], .36,
                                         kind + ' interleaved substrate, no cell mean colour')
        return substrate_fields[kind]

    substrate = substrate_field('central')
    for definition, mask in semantics:
        kind = definition['type'] if definition['type'] in profiles else 'central'
        if kind == 'tended':
            kind = 'central'  # Reuse the existing field; no additional noise.
        # Blend fixed-frequency fields; modulating frequency itself would squeeze
        # coordinates and create fine bands along semantic zone boundaries.
        substrate = mix(substrate, substrate_field(kind), mask,
                        definition['name'] + ' continuous texture statistics transition')

    # Smooth Voronoi groups only modulate relief/density. No cell colour or edge
    # reaches albedo, so cells cannot become flat coloured stone/map parcels.
    group = node('ShaderNodeTexVoronoi', 'irregular powder aggregate density only')
    group.voronoi_dimensions = '3D'
    group.feature = 'SMOOTH_F1'
    group.distance = 'EUCLIDEAN'
    group.inputs['Scale'].default_value = .83
    group.inputs['Smoothness'].default_value = .68
    connect(warped, group.inputs['Vector'])
    local_density = scalar('MULTIPLY', density,
                           remap(envelope_field.outputs['Fac'], .58, 1.03, '2 to 5m density, no colour wash'),
                           'place and compaction density envelope')
    local_density = scalar('MULTIPLY', local_density,
                           remap(group.outputs['Distance'], .62, 1, 'unoutlined irregular aggregate density',
                                 start=.10, end=.65), 'broken nonuniform substrate density')

    palette = node('ShaderNodeRGB', 'fixed inherited warm grey beige')
    palette.outputs[0].default_value = (.355, .282, .197, 1)
    substrate_tint = remap(substrate, .90, 1.10, 'bounded intermediate dry substrate value',
                           start=.425, end=.575, smooth=True)
    substrate_tint = mix((1, 1, 1, 1), substrate_tint, contrast_weight,
                          'tended body contrast suppression around unchanged pigment multiplier one')
    colour_density = remap(local_density, .60, 1.00, 'actual medium contrast bounded 6 to 10 percent',
                            start=.15, end=.60)
    color = mix(palette.outputs[0], substrate_tint, colour_density,
                'continuous substrate value through variable density', 'MULTIPLY')
    dust = noise(vector('MULTIPLY', warped, (1, 1.35, 0), 'powder domain'), 4.1, 1.7,
                 '0.2 to 0.5m broken powder within substrate')
    dust_tint = remap(dust.outputs['Fac'], .93, 1.075, 'low contrast powder value')
    color = mix(color, dust_tint, powder, 'residual powder within each substrate group', 'MULTIPLY')
    fine = noise(warped, 42, 1.4, 'supporting fine sand; not whole view driver')
    color = mix(color, remap(fine.outputs['Fac'], .88, 1.12, 'fine sand bounded value',
                             start=.25, end=.75), .55,
                'restrained supporting fine sand', 'MULTIPLY')
    connect(color, bsdf.inputs['Base Color'])

    bump = node('ShaderNodeBump', 'shallow compacted substrate normal')
    bump.inputs['Distance'].default_value = .010
    connect(scalar('MULTIPLY', local_density, .36, 'substrate normal density'), bump.inputs['Strength'])
    connect(substrate, bump.inputs['Height'])
    dust_bump = node('ShaderNodeBump', 'powder aggregate surface')
    dust_bump.inputs['Distance'].default_value = .003
    connect(powder, dust_bump.inputs['Strength'])
    connect(dust.outputs['Fac'], dust_bump.inputs['Height'])
    connect(bump.outputs['Normal'], dust_bump.inputs['Normal'])
    fine_bump = node('ShaderNodeBump', 'supporting fine sand normal')
    fine_bump.inputs['Distance'].default_value = .0035
    fine_bump.inputs['Strength'].default_value = .40
    connect(fine.outputs['Fac'], fine_bump.inputs['Height'])
    connect(dust_bump.outputs['Normal'], fine_bump.inputs['Normal'])
    connect(fine_bump.outputs['Normal'], bsdf.inputs['Normal'])
    roughness = scalar('SUBTRACT', .95,
                       scalar('MULTIPLY', compaction, .075, 'compaction matte change'),
                       'dry soil roughness')
    connect(roughness, bsdf.inputs['Roughness'])

    preserve = node('ShaderNodeMixShader', 'original exterior versus R4 interior')
    connect(interior, preserve.inputs[0])
    connect(original_surface, preserve.inputs[1])
    connect(bsdf.outputs['BSDF'], preserve.inputs[2])
    connect(preserve.outputs['Shader'], output.inputs['Surface'])
    material['source_material'] = original.name
    material['source_native_sha256'] = SOURCE_SHA256
    material['candidate'] = 'living-r4; unrendered whole-view substrate candidate'
    material['exterior_policy'] = 'original surface graph retained; mask exact zero outside polygons'
    material['scales'] = '0.3-1.5m continuous substrate; 2-5m density/compaction; fine sand supporting'
    material['numeric_zones'] = str([{k: d[k] for k in ('name', 'type', 'polygon')} for d in definitions])
    return material
