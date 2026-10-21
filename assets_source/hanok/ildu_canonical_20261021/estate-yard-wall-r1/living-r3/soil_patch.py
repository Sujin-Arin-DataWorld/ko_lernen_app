"""Living R3 soil material; caller owns binding, audit, save and render.

patch_soil only copies a material. It never edits an object, scene setting,
geometry, UV, transform, or existing material. All shader coordinates are world
metres and all use anchors are numeric, so the material library is standalone.
"""

import math


TARGET = 'GyeGrass.earth.v55.0 | R12 landing occupancy cut'
SOURCE_SHA256 = '586b8a5328e7c0deaeff5f340639708c927ea224a429aca70dc313adadddff68'
MATERIAL = 'Living R3 | tended sandy courtyard'

# Read from R1 compacted-soil-anchors.json. These are existing stone/threshold
# centres, not new paths. Numeric values introduce no object/library dependency.
USE_ANCHORS = (
    (3.55453, -3.43090), (1.86844, -4.51317), (0.19443, -5.60201),
    (-1.48387, -6.68711), (-3.58108, 10.31958), (-3.56225, 8.96367),
    (-3.53711, 7.60842), (-3.51025, 6.25109), (-3.49358, 4.89778),
    (-3.47059, 3.54307), (-3.44798, 2.18874), (-3.42638, 0.83376),
    (-3.39764, -0.52042), (-3.38173, -1.87603), (-3.35761, -3.23070),
    (-3.33762, -4.58549), (-3.31249, -5.93969), (-3.28803, -7.29854),
    (-9.39465, 25.06391), (-10.90182, 24.79953), (2.56508, 24.93549),
    (-18.38030, -8.37742), (22.09164, -10.13030),
)

# Unequal finite entry approach lobes from R2, now changing grain rather than
# darkening/flattening pigment. R1 stone anchors stop before this open approach.
APPROACH_LOBES = (
    (-6.30, -10.90, 1.75, 1.25, .88, 1.0),
    (-5.18, -9.75, 1.70, 1.45, 1.12, .85),
    (-4.36, -8.65, 1.35, 1.10, .48, .65),
)

# Root ray-cast verified these ground positions in detail camera. Two asymmetric
# swept groups have unequal companion lobes, rather than randomly missing view.
# Main centres correspond to image (250,350) and (1080,750) at 1280x960.
SWEPT_LOBES = (
    (-1.153, -8.984, 2.80, 1.55, -.30, 1.0),
    (-.10, -8.55, 1.45, 1.05, .48, .78),
    (-10.497, -8.838, 2.95, 1.65, .62, 1.0),
    (-11.55, -9.18, 1.65, 1.10, -.24, .74),
)


def patch_soil(original, scene):
    """Return one standalone soil material, leaving every binding unchanged."""
    target = scene.objects.get(TARGET)
    if target is None or not target.material_slots:
        raise ValueError('Expected R1 courtyard soil target/slot 0 is absent')
    if target.material_slots[0].material != original:
        raise ValueError('Pass the material currently bound to target slot 0')

    material = original.copy()
    material.name = MATERIAL
    material.use_nodes = True
    tree = material.node_tree
    tree.nodes.clear()

    def node(kind, name):
        item = tree.nodes.new(kind)
        item.name = 'Soil R3 | ' + name
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
        return item.outputs['Value' if operation == 'DISTANCE' else 'Vector']

    def remap(value, low, high, name, start=0.0, end=1.0, smooth=False):
        item = node('ShaderNodeMapRange', name)
        item.clamp = True
        item.interpolation_type = 'SMOOTHSTEP' if smooth else 'LINEAR'
        for socket, value_in in (
            ('Value', value), ('From Min', start), ('From Max', end),
            ('To Min', low), ('To Max', high),
        ):
            connect(value_in, item.inputs[socket])
        return item.outputs[0]

    def noise(coords, scale, detail, name):
        item = node('ShaderNodeTexNoise', name)
        item.noise_dimensions = '3D'
        item.inputs['Scale'].default_value = scale
        item.inputs['Detail'].default_value = detail
        item.inputs['Roughness'].default_value = .58
        connect(coords, item.inputs['Vector'])
        return item

    def mix(a, b, factor, name, mode='MIX'):
        item = node('ShaderNodeMixRGB', name)
        item.blend_type = mode
        connect(factor, item.inputs[0])
        connect(a, item.inputs[1])
        connect(b, item.inputs[2])
        return item.outputs[0]

    output = node('ShaderNodeOutputMaterial', 'material output')
    bsdf = node('ShaderNodeBsdfPrincipled', 'dry warm mineral sand')
    connect(bsdf.outputs['BSDF'], output.inputs['Surface'])
    bsdf.inputs['Metallic'].default_value = 0
    bsdf.inputs['Specular IOR Level'].default_value = .16

    geometry = node('ShaderNodeNewGeometry', 'world position; no UV or object reference')
    p = vector('MULTIPLY', geometry.outputs['Position'], (1, 1, 0), 'world XY metres')

    def finite_lobes(lobes, name):
        union = 0.0
        for index, (x, y, rx, ry, angle, weight) in enumerate(lobes):
            relative = vector('SUBTRACT', p, (x, y, 0), name + ' %d position' % index)
            squared_axes = []
            for axis, direction in enumerate(((math.cos(angle) / rx, math.sin(angle) / rx, 0),
                                              (-math.sin(angle) / ry, math.cos(angle) / ry, 0))):
                dot = node('ShaderNodeVectorMath', name + ' %d axis %d' % (index, axis))
                dot.operation = 'DOT_PRODUCT'
                connect(relative, dot.inputs[0])
                dot.inputs[1].default_value = direction
                squared_axes.append(scalar('MULTIPLY', dot.outputs['Value'], dot.outputs['Value'],
                                           name + ' %d squared axis %d' % (index, axis)))
            radius = scalar('ADD', squared_axes[0], squared_axes[1], name + ' %d radius' % index)
            lobe = remap(radius, weight, 0, name + ' %d finite soft edge' % index,
                         start=.12, end=1, smooth=True)
            union = scalar('MAXIMUM', union, lobe, name + ' %d asymmetric union' % index)
        return union

    drift = noise(p, .36, 2.1, 'nonperiodic domain drift')
    offset = vector('MULTIPLY', vector('SUBTRACT', drift.outputs['Color'], (.5, .5, .5),
                    'centred drift'), (.25, .25, 0), '12 centimetre domain perturbation')
    warped = vector('ADD', p, offset, 'nonrepeating sand coordinates')

    # Keep the R1 quiet beige/ochre family, but remove its dominant cloudy wash.
    # Both palette ends are linear RGB values sampled from the existing range.
    broad = noise(warped, .10, 1.4, 'restrained inherited broad pigment')
    palette = node('ShaderNodeValToRGB', 'R1 beige soil palette; no orange shift')
    palette.color_ramp.elements[0].color = (.312, .244, .165, 1)
    palette.color_ramp.elements[1].color = (.398, .321, .230, 1)
    connect(broad.outputs['Fac'], palette.inputs['Fac'])
    color = palette.outputs['Color']

    # Finite, differently sized patches around existing stones. The geometry is
    # untouched. These influence grain density and roughness more than value.
    wear = 0.0
    for index, (x, y) in enumerate(USE_ANCHORS):
        distance = vector('DISTANCE', p, (x, y, 0), 'existing stone %02d distance' % index)
        radius = (.83, 1.04, .91, 1.13, .94)[index % 5]
        lobe = remap(distance, 1, 0, 'finite unequal use %02d' % index,
                     start=.16, end=radius, smooth=True)
        wear = scalar('MAXIMUM', wear, lobe, 'existing use union %02d' % index)
    patch_drift = noise(p, 1.8, 1.3, 'irregular local use feather')
    wear = scalar('MULTIPLY', wear,
                  remap(patch_drift.outputs['Fac'], .55, 1, 'broken use intensity'),
                  'tread mask with finite support')
    approach = finite_lobes(APPROACH_LOBES, 'actual doorway approach')
    wear = scalar('MAXIMUM', wear, approach, 'stones plus visible doorway approach')

    # Explicit visible asymmetric patches replace the first-pass random mask,
    # which failed to locate a swept state in the rendered detail view.
    swept = finite_lobes(SWEPT_LOBES, 'verified visible swept ground')
    patch_field = noise(warped, .75, 1.4, 'irregular swept edge strength')
    swept = scalar('MULTIPLY', swept,
                   remap(patch_field.outputs['Fac'], .72, 1, 'swept feather variation'),
                   'visible asymmetric sweep groups')
    swept = scalar('MULTIPLY', swept,
                   scalar('SUBTRACT', 1, scalar('MULTIPLY', wear, .82, 'tread suppresses rake'),
                          'swept surface outside busiest tread'), 'local swept mask')

    # Two oblique directions change slowly across the site. Irregular Noise
    # produces short fragments, rather than a family of parallel ruled lines.
    def directional(angle, name):
        c, s = math.cos(angle), math.sin(angle)
        separate = node('ShaderNodeSeparateXYZ', name + ' world axes')
        connect(warped, separate.inputs[0])
        u = scalar('ADD', scalar('MULTIPLY', separate.outputs['X'], c, name + ' ux'),
                   scalar('MULTIPLY', separate.outputs['Y'], s, name + ' uy'), name + ' u')
        v = scalar('ADD', scalar('MULTIPLY', separate.outputs['X'], -s, name + ' vx'),
                   scalar('MULTIPLY', separate.outputs['Y'], c, name + ' vy'), name + ' v')
        combined = node('ShaderNodeCombineXYZ', name + ' rotated coordinates')
        connect(u, combined.inputs['X'])
        connect(v, combined.inputs['Y'])
        anisotropic = vector('MULTIPLY', combined.outputs[0], (.72, 3.2, 0), name + ' short oblique grain')
        return noise(anisotropic, 2.5, 1.5, name + ' broken 15 to 55cm sweep').outputs['Fac']

    sweep_a = directional(.32, 'sweep direction A')
    sweep_b = directional(1.47, 'sweep direction B')
    orientation = noise(p, .17, 1.0, 'nonperiodic choice of sweep direction')
    swept_height = mix(sweep_a, sweep_b,
                       remap(orientation.outputs['Fac'], 0, 1, 'irregular orientation blend',
                             start=.38, end=.62, smooth=True), 'short changing sweep fragments')
    sweep_tint = remap(swept_height, .82, 1.153, 'readable shallow sweep value', start=.27, end=.73)
    color = mix(color, sweep_tint, swept, 'local swept pigment', 'MULTIPLY')

    # 3–12 cm aggregates carry value as well as normals, so soft illumination
    # and denoising do not have sole control over whether sand can be perceived.
    sand = noise(warped, 14, 2.1, 'visible 3 to 12cm sand aggregate')
    sand_contrast = remap(sand.outputs['Fac'], .84, 1.16, 'mineral sand value', start=.27, end=.74)
    sand_weight = scalar('ADD', .24, scalar('MULTIPLY', swept, .72, 'swept exposed aggregate'),
                         'calm aggregate pigment weight')
    sand_weight = scalar('MULTIPLY', sand_weight,
                         scalar('SUBTRACT', 1, scalar('MULTIPLY', wear, .80, 'consolidated aggregate reduction'),
                                'grain remaining in tread'), 'surface use modulates sand density')
    color = mix(color, sand_contrast, sand_weight, 'visible sand pigment', 'MULTIPLY')

    # Sparse 15–35 cm density groups survive the 477px review better than
    # subpixel grit. This layer is gated to swept patches and has bounded value.
    density = noise(warped, 3.8, 1.8, '15 to 35cm irregular aggregate density')
    density_tint = remap(density.outputs['Fac'], .89, 1.09, 'restrained density bundle value', start=.28, end=.72)
    color = mix(color, density_tint, scalar('MULTIPLY', swept, .70, 'rare readable density groups'),
                'swept aggregate grouping', 'MULTIPLY')
    # Grain and normal density carry tread; its mean pigment is unchanged.

    grit = noise(warped, 135, 1.2, 'restrained 5 to 8mm fine grit')
    grit_tint = remap(grit.outputs['Fac'], .96, 1.035, 'fine grit low contrast')
    grit_weight = scalar('ADD', .035, scalar('MULTIPLY', swept, .27, 'grit in exposed swept sand'),
                         'quiet ground has restrained grit')
    grit_weight = scalar('MULTIPLY', grit_weight,
                         scalar('SUBTRACT', 1, scalar('MULTIPLY', wear, .80, 'tread grit consolidation'),
                                'fine grit remaining in tread'), 'local grit density')
    color = mix(color, grit_tint, grit_weight, 'fine mineral flecks without gravel', 'MULTIPLY')
    connect(color, bsdf.inputs['Base Color'])

    # Three normal scales, no displacement and no silhouette/geometry change.
    relief = node('ShaderNodeBump', 'short swept relief; sub-centimetre')
    relief.inputs['Distance'].default_value = .010
    connect(scalar('MULTIPLY', swept, .38, 'local sweep relief strength'), relief.inputs['Strength'])
    connect(swept_height, relief.inputs['Height'])
    aggregate = node('ShaderNodeBump', 'sand relief 3 to 12cm footprint')
    aggregate.inputs['Distance'].default_value = .007
    sand_relief = scalar('ADD', .20, scalar('MULTIPLY', swept, .54, 'exposed sweep sand relief'),
                         'quiet versus swept sand relief')
    sand_relief = scalar('MULTIPLY', sand_relief,
                         scalar('SUBTRACT', 1, scalar('MULTIPLY', wear, .80, 'tread relief consolidation'),
                                'grain normal remains under tread'), 'three use states sand normal')
    connect(sand_relief, aggregate.inputs['Strength'])
    connect(sand.outputs['Fac'], aggregate.inputs['Height'])
    connect(relief.outputs['Normal'], aggregate.inputs['Normal'])
    fine = node('ShaderNodeBump', 'restrained grit normal')
    fine.inputs['Distance'].default_value = .0009
    connect(grit_weight, fine.inputs['Strength'])
    connect(grit.outputs['Fac'], fine.inputs['Height'])
    connect(aggregate.outputs['Normal'], fine.inputs['Normal'])
    connect(fine.outputs['Normal'], bsdf.inputs['Normal'])

    roughness = remap(sand.outputs['Fac'], .87, .97, 'matte mineral roughness')
    roughness = scalar('SUBTRACT', roughness,
                       scalar('MULTIPLY', wear, .035, 'small consolidated roughness change'),
                       'dry tended sand roughness')
    connect(roughness, bsdf.inputs['Roughness'])

    material.diffuse_color = (.355, .282, .197, 1)
    material['source_material'] = original.name
    material['source_native_sha256'] = SOURCE_SHA256
    material['candidate'] = 'living-r3 revision 2; unrendered visible three-state candidate'
    material['coordinates'] = 'world XY metres; numeric anchors; no object dependencies'
    material['surface_scales'] = '15-55cm broken sweep, 15-35cm density, 3-12cm sand, 5-8mm grit'
    material['changes_geometry_uv_transforms'] = False
    return material
