"""Illustrated estate palette and softly dressed Sarang stone facing.

This is a review-only art pass. It keeps the approved building envelopes,
hinged doors and existing structural stone in place. New faceted stone is a
    thin facing over the visibly regular south plinths, not a survey claim.
"""
from pathlib import Path
import hashlib
import json
import random

import bpy


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
TARGET = OUT / 'estate-fabric.blend'


def linear_hex(value):
    channels = [int(value[index:index + 2], 16) / 255 for index in (1, 3, 5)]
    return tuple(channel / 12.92 if channel <= .04045 else ((channel + .055) / 1.055) ** 2.4
                 for channel in channels)


def simple_material(name, color):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    nodes.clear()
    shader = nodes.new('ShaderNodeBsdfPrincipled')
    shader.inputs['Roughness'].default_value = .94
    shader.inputs['Specular IOR Level'].default_value = .12
    uv = nodes.new('ShaderNodeUVMap')
    uv.uv_map = 'Dressed stone pigment UV'
    grain = nodes.new('ShaderNodeTexNoise')
    grain.inputs['Scale'].default_value = 8.5
    grain.inputs['Detail'].default_value = 2.3
    grain.inputs['Roughness'].default_value = .62
    grain.inputs['Distortion'].default_value = .12
    ramp = nodes.new('ShaderNodeValToRGB')
    pigment = linear_hex(color)
    ramp.color_ramp.elements[0].position = .2
    ramp.color_ramp.elements[0].color = (*[channel * .79 for channel in pigment], 1)
    ramp.color_ramp.elements[1].position = .8
    ramp.color_ramp.elements[1].color = (*[min(channel * 1.16, 1) for channel in pigment], 1)
    output = nodes.new('ShaderNodeOutputMaterial')
    mat.node_tree.links.new(uv.outputs['UV'], grain.inputs['Vector'])
    mat.node_tree.links.new(grain.outputs['Fac'], ramp.inputs['Fac'])
    mat.node_tree.links.new(ramp.outputs['Color'], shader.inputs['Base Color'])
    mat.node_tree.links.new(shader.outputs['BSDF'], output.inputs['Surface'])
    mat['styleAuthority'] = 'IlDu V3 dressed stone pigment; quiet hand-painted variation'
    return mat


def tint_ramp(mat_name, ramp_name, factors):
    ramp = bpy.data.materials[mat_name].node_tree.nodes[ramp_name].color_ramp
    old = [tuple(element.color) for element in ramp.elements]
    for element in ramp.elements:
        element.color = (*[min(1, element.color[i] * factors[i]) for i in range(3)], element.color[3])
    return {'material': mat_name, 'ramp': ramp_name,
            'old': [[round(value, 4) for value in color] for color in old],
            'new': [[round(value, 4) for value in element.color] for element in ramp.elements]}


def glaze_timber_output(mat_name):
    """Quiet the red cast after the retained artwork and grain are combined."""
    mat = bpy.data.materials[mat_name]
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    shader = next(node for node in nodes if node.type == 'BSDF_PRINCIPLED')
    assert shader.inputs['Base Color'].is_linked
    assert not nodes.get('Gye aged walnut glaze')
    previous = shader.inputs['Base Color'].links[0].from_socket
    glaze = nodes.new('ShaderNodeMixRGB')
    glaze.name = 'Gye aged walnut glaze'
    glaze.blend_type = 'MULTIPLY'
    glaze.inputs['Fac'].default_value = 1.0
    glaze.inputs['Color2'].default_value = (.76, .94, 1.03, 1)
    links.new(previous, glaze.inputs['Color1'])
    links.new(glaze.outputs['Color'], shader.inputs['Base Color'])
    return {'material': mat_name, 'linearRgbMultiplier': [.76, .94, 1.03]}


class FacetedStones:
    def __init__(self, name, materials):
        self.name = name
        self.materials = materials
        self.vertices = []
        self.faces = []
        self.indices = []
        self.stones = 0
        self.widths = []

    def face(self, vertices, material):
        self.faces.append(tuple(vertices))
        self.indices.append(material)

    def add_course_stone(self, left, right, bottom, top, front_y, rng):
        width = right - left
        height = top - bottom
        if width < .12 or height < .07:
            return
        bevel = min(.065, width * .13, height * .22)
        middle = (left + right) / 2 + rng.uniform(-.09, .09) * width
        outline = [
            (left + bevel, bottom + rng.uniform(0, .014)),
            (middle, bottom + rng.uniform(-.013, .012)),
            (right - bevel, bottom + rng.uniform(0, .015)),
            (right, bottom + bevel),
            (right - rng.uniform(0, .018), top - bevel),
            (middle + rng.uniform(-.06, .06) * width, top + rng.uniform(-.015, .008)),
            (left + bevel, top - rng.uniform(0, .012)),
            (left + rng.uniform(-.014, .014), top - bevel),
        ]
        y_edge = front_y - rng.uniform(.026, .060)
        start = len(self.vertices)
        self.vertices.extend((x, y_edge + rng.uniform(-.008, .008), max(.006, z)) for x, z in outline)
        back = len(self.vertices)
        self.vertices.extend((x, front_y + .018, max(.006, z)) for x, z in outline)
        main = rng.randrange(len(self.materials))
        # One quiet face per stone: the edge and course variation carry the
        # hand-dressed character, without triangular low-poly highlights.
        self.face(tuple(range(start, start + 8)), main)
        for index in range(8):
            nxt = (index + 1) % 8
            self.face((start + index, back + index, back + nxt, start + nxt),
                      (main + 1) % len(self.materials))
        self.face(tuple(reversed(range(back, back + 8))), (main + 2) % len(self.materials))
        self.stones += 1
        self.widths.append(width)

    def add_run(self, xmin, xmax, front_y, zmin, zmax, courses, seed):
        rng = random.Random(seed)
        weights = [rng.uniform(.82, 1.18) for _ in range(courses)]
        total = sum(weights)
        boundaries = [zmin]
        for weight in weights:
            boundaries.append(boundaries[-1] + (zmax - zmin) * weight / total)
        for row in range(courses):
            bottom = boundaries[row] + (.012 if row else 0)
            top = boundaries[row + 1] - .014
            position = xmin
            while position < xmax - .12:
                remaining = xmax - position
                width = min(remaining, rng.uniform(.36, .86) if courses > 1 else rng.uniform(.44, .92))
                if remaining - width < .16:
                    width = remaining
                gap = rng.uniform(.018, .036)
                self.add_course_stone(position + gap / 2, position + width - gap / 2,
                                      bottom + rng.uniform(-.022, .021),
                                      top + rng.uniform(-.026, .020), front_y, rng)
                position += width

    def add_foot(self, bounds, rng):
        (xmin, xmax), (ymin, ymax), (zmin, zmax) = bounds
        xmin -= .014; xmax += .014; ymin -= .014; ymax += .014
        zmin = max(0, zmin - .006); zmax += .009
        bevel = min(.055, (xmax - xmin) * .14, (ymax - ymin) * .14)
        ring = [(xmin + bevel, ymin), (xmax - bevel, ymin), (xmax, ymin + bevel),
                (xmax, ymax - bevel), (xmax - bevel, ymax), (xmin + bevel, ymax),
                (xmin, ymax - bevel), (xmin, ymin + bevel)]
        start = len(self.vertices)
        self.vertices.extend((x + rng.uniform(-.007, .007), y + rng.uniform(-.007, .007), zmin)
                             for x, y in ring)
        self.vertices.extend((x + rng.uniform(-.014, .014), y + rng.uniform(-.014, .014),
                              zmax + rng.uniform(-.006, .006)) for x, y in ring)
        main = rng.randrange(len(self.materials))
        for index in range(8):
            nxt = (index + 1) % 8
            self.face((start + index, start + nxt, start + 8 + nxt, start + 8 + index),
                      (main + (index % 3 == 0)) % len(self.materials))
        self.face(tuple(range(start + 8, start + 16)), (main + 1) % len(self.materials))
        self.face(tuple(reversed(range(start, start + 8))), (main + 2) % len(self.materials))
        self.stones += 1
        self.widths.append(xmax - xmin)

    def finish(self, scene):
        mesh = bpy.data.meshes.new(self.name)
        mesh.from_pydata(self.vertices, [], self.faces)
        mesh.update()
        for mat in self.materials:
            mesh.materials.append(mat)
        uv = mesh.uv_layers.new(name='Dressed stone pigment UV')
        for polygon, material in zip(mesh.polygons, self.indices):
            polygon.material_index = material
            polygon.use_smooth = False
            for loop_index in polygon.loop_indices:
                point = mesh.vertices[mesh.loops[loop_index].vertex_index].co
                uv.data[loop_index].uv = (point.x * .67 + point.y * .31,
                                          point.z * 1.83 + point.y * .17)
        ob = bpy.data.objects.new(self.name, mesh)
        scene.collection.objects.link(ob)
        ob['construction_building'] = 'sarang'
        ob['construction_first'] = 1
        ob['construction_last'] = 16
        ob['source_object_name'] = ob.name
        ob['styleInterpretation'] = 'Hand-chipped facing over retained surveyed building geometry'
        return ob


def connected_bounds(ob):
    mesh = ob.data
    parent = list(range(len(mesh.vertices)))

    def find(value):
        while parent[value] != value:
            parent[value] = parent[parent[value]]
            value = parent[value]
        return value

    for edge in mesh.edges:
        a, b = edge.vertices
        parent[find(a)] = find(b)
    groups = {}
    for index, vertex in enumerate(mesh.vertices):
        groups.setdefault(find(index), []).append(ob.matrix_world @ vertex.co)
    for points in groups.values():
        yield tuple((min(point[axis] for point in points), max(point[axis] for point in points))
                    for axis in range(3))


def apply_estate_style(scene):
    assert not scene.get('gyeEstateStyleV1'), 'Gye style already applied'
    palette = {
        'tile': '#393B35', 'wood': '#80532D', 'plaster': '#D6C7A7',
        'stone': ['#807663', '#918671', '#A69B83', '#726A58', '#B0A48B', '#8B806A'],
    }
    ramps = []
    for name in ('Sarang golden aged timber', 'Sarang vertical timber grain'):
        ramps.append(tint_ramp(name, '색상 램프', (.60, .75, .89)))
    glazes = [glaze_timber_output(name) for name in
              ('Sarang golden aged timber', 'Sarang vertical timber grain')]
    ramps.append(tint_ramp('Jung dark walnut', '색상 램프', (1.35, 1.22, 1.10)))
    for index in range(6):
        sarang = f'Charcoal grey giwa {index}'
        jung = f'Jung dark weathered giwa {index}'
        if sarang in bpy.data.materials:
            ramps.append(tint_ramp(sarang, '색상 램프', (1.00, 1.00, .80)))
        if jung in bpy.data.materials:
            ramps.append(tint_ramp(jung, 'Color Ramp', (1.12, 1.08, .87)))
    for index in range(5):
        ramps.append(tint_ramp(f'Pale granite {index}', '색상 램프', (.91, .86, .77)))
    materials = [simple_material(f'Gye hand-chipped warm stone {index}', color)
                 for index, color in enumerate(palette['stone'])]
    courses = FacetedStones('GyeStyle.Sarang irregular stone facing', materials)
    runs = [
        (-.64, 10.70, -.704, .025, .985, 3, 'sarang-front'),
        (-1.30, 1.81, -1.286, .025, 1.064, 3, 'sarang-left-apron'),
        (1.81, 6.05, -1.300, .025, 1.278, 4, 'sarang-steps-landing'),
        (9.34, 14.75, -5.166, .02, .398, 1, 'numaru-front'),
        (11.99, 14.45, -1.229, .835, 1.438, 2, 'wing-front'),
    ]
    for run in runs:
        courses.add_run(*run)
    # The straight, pale beoldae and stair risers were still reading as newly
    # cut strips beside the irregular foundation. Keep their original cores.
    courses.add_run(-.64, 10.70, -.704, 1.006, 1.096, 1, 'sarang-cap')
    for number in range(1, 6):
        tread = scene.objects[f'V25.stair tread {number}']
        bounds = list(connected_bounds(tread))
        assert len(bounds) == 1, f'Unexpected stair mesh: {tread.name}'
        (xmin, xmax), (ymin, _), (_, zmax) = bounds[0]
        bottom = (number - 1) * .213 + .008
        courses.add_run(xmin + .015, xmax - .015, ymin - .008,
                        bottom, zmax - .012, 1, f'sarang-stair-{number}')
    course_ob = courses.finish(scene)
    feet = FacetedStones('GyeStyle.Sarang hand-cut post feet', materials)
    rng = random.Random(20260930)
    source_feet = [ob for ob in scene.objects if ob.type == 'MESH' and
                   (ob.name.startswith(('Sarang.', 'HwaljuFix.')) and ob.name.endswith('.stone foot'))]
    for ob in source_feet:
        for bounds in connected_bounds(ob):
            feet.add_foot(bounds, rng)
    foot_ob = feet.finish(scene)
    report = {
        'palette': palette, 'woodAndRoofRampChanges': ramps, 'finalTimberGlazes': glazes,
        'stoneCourses': courses.stones, 'stoneFeet': feet.stones,
        'stoneWidthRangeMeters': [round(min(courses.widths), 3), round(max(courses.widths), 3)],
        'newMeshes': [course_ob.name, foot_ob.name], 'sourceFeet': [ob.name for ob in source_feet],
        'buildingEnvelopeChanged': False, 'hingedDoorMeshesChanged': False,
        'sourceArtworkBytesChanged': False,
        'visualAuthority': 'Approved IlDu V3 building art, F-D-ildoo architecture register, user feedback on regular Sarang stone',
        'limits': 'Candidate material and dressed-stone pass; whole-estate visual review remains open',
    }
    scene['gyeEstateStyleV1'] = True
    return report


if __name__ == '__main__':
    bpy.ops.wm.open_mainfile(filepath=str(TARGET))
    contract_path = OUT / 'estate-fabric-contract.json'
    contract = json.loads(contract_path.read_text(encoding='utf8'))
    if '--refresh' in __import__('sys').argv:
        previous = contract['gyeStylePass']
        for record in previous.get('finalTimberGlazes', []):
            mat = bpy.data.materials[record['material']]
            nodes, links = mat.node_tree.nodes, mat.node_tree.links
            glaze = nodes['Gye aged walnut glaze']
            shader = next(node for node in nodes if node.type == 'BSDF_PRINCIPLED')
            source = glaze.inputs['Color1'].links[0].from_socket
            links.new(source, shader.inputs['Base Color'])
            nodes.remove(glaze)
        for record in previous['woodAndRoofRampChanges']:
            ramp = bpy.data.materials[record['material']].node_tree.nodes[record['ramp']].color_ramp
            assert len(ramp.elements) == len(record['new'])
            for element, expected, original in zip(ramp.elements, record['new'], record['old']):
                assert max(abs(element.color[i] - expected[i]) for i in range(4)) < .001
                element.color = original
        expected = set(previous['newMeshes'])
        assert expected == {'GyeStyle.Sarang irregular stone facing', 'GyeStyle.Sarang hand-cut post feet'}
        for name in expected:
            bpy.data.objects.remove(bpy.data.objects[name], do_unlink=True)
        del bpy.context.scene['gyeEstateStyleV1']
    report = apply_estate_style(bpy.context.scene)
    bpy.ops.wm.save_as_mainfile(filepath=str(TARGET), compress=True)
    contract['gyeStylePass'] = report
    contract['candidateSceneSha256'] = hashlib.sha256(TARGET.read_bytes()).hexdigest()
    contract_path.write_text(json.dumps(contract, ensure_ascii=False, indent=2), encoding='utf8')
    print('GYE ESTATE STYLE', report['stoneCourses'], report['stoneFeet'], flush=True)
