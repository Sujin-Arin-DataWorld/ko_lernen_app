"""Vary shallow hand-planed timber arrises, retaining the source core meshes.

Only structural timber/boarding receives a reversible weighted bevel. Door
leaves, hinges, plaques, mineral surfaces and authored source UVs are protected.
The small evaluated surface change is registered separately from core geometry.
"""
from collections import Counter, defaultdict
from pathlib import Path
import hashlib
import json
import math
import random
import re
import sys

import bmesh
import bpy
import numpy as np

sys.path.insert(0, str(Path(__file__).parent))
from repair_masonry_coping import fingerprint
from northern_timber_sections import groups
from apply_estate_matte_register import owner_of, surface_role

N = Path(__file__).resolve().parents[2] / 'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
TARGET = N / 'estate-fabric.blend'
D = Path('C:/dev/hangulsori/sites/ildu-survey-review-20260929/dist')
WEIGHT = 'Gye timber edge weights'
SCOPE = {'sarang', 'jung', 'anchae', 'ansarang', 'sadang', 'sadangmun', 'arae',
         'angotgan', 'gokgan', 'changgo', 'main_gate', 'toilet', 'toilet1'}
EXCLUDED = re.compile(r'leaf\d|lattice|hinge|nail|peg|sal\b|stile|rail|threshold|plaque|sign|letter', re.I)
MEMBER = re.compile(r'post|column|beam|purlin|plank|board|deck', re.I)


def timber_material(material):
    if not material or surface_role(material.name) == 'roof':
        return False
    name = material.name.lower()
    if any(word in name for word in ('stone', 'granite', 'plaster', 'lime', 'earth',
                                     'mortar', 'iron', 'brass', 'hanji', 'glass')):
        return False
    return (surface_role(name) == 'wood' or material.get('surfaceKind') in ('wood', 'post', 'beam', 'floor') or
            any(word in name for word in ('post pigment', ' post', ' floor', 'paint', 'dancheong')))


def eligible(ob):
    if ob.type != 'MESH' or ob.hide_render or owner_of(ob) not in SCOPE:
        return False
    owner = owner_of(ob)
    stage = 16 if owner == 'sarang' else 12
    if owner in ('sarang', 'jung') and not ob.get('construction_first', 0) <= stage <= ob.get('construction_last', 99):
        return False
    if not MEMBER.search(ob.name) or EXCLUDED.search(ob.name):
        return False
    used = {poly.material_index for poly in ob.data.polygons}
    return bool(used) and all(timber_material(ob.data.materials[i]) for i in used)


def evaluated_summary(ob, depsgraph):
    evaluated = ob.evaluated_get(depsgraph)
    mesh = evaluated.to_mesh()
    try:
        mesh.calc_loop_triangles()
        points = np.array([ob.matrix_world @ vertex.co for vertex in mesh.vertices])
        return {'min': points.min(0).tolist(), 'max': points.max(0).tolist(),
                'vertices': len(mesh.vertices), 'triangles': len(mesh.loop_triangles)}
    finally:
        evaluated.to_mesh_clear()


def modifier_record(modifier):
    return {key: getattr(modifier, key) for key in ('name', 'width', 'segments', 'profile',
            'limit_method', 'edge_weight', 'use_clamp_overlap', 'harden_normals')}


def apply_timber_arris(scene):
    assert not scene.get('gyeTimberArrisV1'), 'Timber arris already applied'
    before = {ob.name: fingerprint(ob) for ob in scene.objects if ob.type == 'MESH'}
    records = []
    anchors = defaultdict(list)
    candidates = [ob for ob in scene.objects if eligible(ob)]
    depsgraph = bpy.context.evaluated_depsgraph_get()
    for ob in candidates:
        bevels = [mod for mod in ob.modifiers if mod.type == 'BEVEL']
        if len(bevels) > 1:
            continue
        old_evaluated = evaluated_summary(ob, depsgraph)
        component_indices = list(groups(ob.data))
        component_of = {}
        components = []
        scales = [ob.matrix_world.to_scale()[i] for i in range(3)]
        scale = max(min(abs(value) for value in scales), 1e-6)
        for index, ids in enumerate(component_indices):
            points = np.array([ob.data.vertices[i].co[:] for i in ids])
            center = points.mean(0)
            _, basis = np.linalg.eigh((points - center).T @ (points - center))
            extent = np.ptp((points - center) @ basis, axis=0)
            section = max(float(min(extent[:2])), 0)
            width = min(.016 / scale, section * .075)
            rng = random.Random(ob.name + ':' + str(index))
            width *= rng.uniform(.82, 1)
            components.append({'width': width, 'seed': rng.randrange(2**31)})
            for vertex in ids:
                component_of[vertex] = index
            if re.search(r'post|column', ob.name, re.I) and 'roof' not in ob.name.lower():
                world = np.array([ob.matrix_world @ ob.data.vertices[i].co for i in ids])
                low, high = world.min(0), world.max(0)
                if high[2] - low[2] > .7:
                    point = (low + high) / 2
                    point[2] = low[2] + .58 * (high[2] - low[2])
                    anchors[owner_of(ob)].append({'point': point.tolist(), 'object': ob.name,
                                                  'frontRank': float(point @ np.array([-.65, -.95, 0]))})
        maximum = max((row['width'] for row in components), default=0)
        if maximum < .0002:
            continue
        bm = bmesh.new()
        bm.from_mesh(ob.data)
        bm.edges.ensure_lookup_table()
        weights = np.zeros(len(ob.data.edges), dtype=np.float32)
        for edge in bm.edges:
            if len(edge.link_faces) != 2 or not edge.is_convex or edge.calc_face_angle() < math.radians(38):
                continue
            component = components[component_of[edge.verts[0].index]]
            rng = random.Random(component['seed'] + edge.index * 7919)
            weights[edge.index] = component['width'] / maximum * rng.uniform(.48, 1)
        bm.free()
        if np.count_nonzero(weights) < 6:
            continue
        if ob.data.users > 1:
            ob.data = ob.data.copy()
        assert not ob.data.attributes.get(WEIGHT), ob.name
        attribute = ob.data.attributes.new(WEIGHT, 'FLOAT', 'EDGE')
        attribute.data.foreach_set('value', weights)
        modifier = bevels[0] if bevels else ob.modifiers.new('Gye hand-planed timber arris', 'BEVEL')
        original = modifier_record(modifier) if bevels else None
        modifier.limit_method = 'WEIGHT'
        modifier.edge_weight = WEIGHT
        modifier.width = maximum
        modifier.segments = 2
        modifier.profile = .55
        modifier.use_clamp_overlap = True
        modifier.harden_normals = False
        ob['gyeTimberArrisV1'] = True
        ob.data.update()
        records.append({'object': ob.name, 'building': owner_of(ob), 'modifier': modifier.name,
                        'originalModifier': original, 'afterModifier': modifier_record(modifier),
                        'weightedEdges': int(np.count_nonzero(weights)), 'weightSha256': hashlib.sha256(weights.tobytes()).hexdigest(),
                        'coreFingerprint': before[ob.name], 'beforeEvaluated': old_evaluated,
                        'maximumLocalWidth': maximum, 'components': len(components)})
    bpy.context.view_layer.update()
    depsgraph = bpy.context.evaluated_depsgraph_get()
    for row in records:
        ob = bpy.data.objects[row['object']]
        after = evaluated_summary(ob, depsgraph)
        row['afterEvaluated'] = after
        row['boundsDeviationMeters'] = max(abs(a - b) for key in ('min', 'max')
                                           for a, b in zip(after[key], row['beforeEvaluated'][key]))
        assert row['boundsDeviationMeters'] <= .0301, row
    assert {row['building'] for row in records} == SCOPE, {row['building'] for row in records}
    assert all(fingerprint(bpy.data.objects[name]) == expected for name, expected in before.items())
    cameras = {owner: {key: value for key, value in max(rows, key=lambda row: row['frontRank']).items()
                       if key != 'frontRank'} for owner, rows in anchors.items()}
    scene['gyeTimberArrisV1'] = True
    return {'members': records, 'countsByBuilding': dict(Counter(row['building'] for row in records)),
            'detailAnchors': cameras, 'coreGeometryUvSlotsChanged': False,
            'doorLeavesHingesAndPlaquesChanged': False, 'maximumWorldWidthMeters': .016,
            'limits': 'Cosmetic hand-planed corner interpretation; source sections and axes retained',
            'runtimePromotion': False}


def write_detail_cameras(report):
    (D / 'timber-detail-cameras.json').write_text(json.dumps({'anchors': report['detailAnchors'],
        'coordinates': 'Retained source building world axes; Blender XYZ'}, ensure_ascii=False, indent=2), encoding='utf8')


if __name__ == '__main__':
    bpy.ops.wm.open_mainfile(filepath=str(TARGET))
    path = N / 'estate-fabric-contract.json'
    contract = json.loads(path.read_text(encoding='utf8'))
    source_sha = hashlib.sha256(TARGET.read_bytes()).hexdigest()
    report = apply_timber_arris(bpy.context.scene)
    report['sourceSceneSha256'] = source_sha
    bpy.ops.wm.save_as_mainfile(filepath=str(TARGET), compress=True)
    contract['gyeTimberArris'] = report
    contract['candidateSceneSha256'] = hashlib.sha256(TARGET.read_bytes()).hexdigest()
    path.write_text(json.dumps(contract, ensure_ascii=False, indent=2), encoding='utf8')
    write_detail_cameras(report)
    print('HAND-PLANED TIMBER', report['countsByBuilding'], flush=True)
