"""Give flat plaster a quiet painted pigment wash, preserving original UVs."""
from pathlib import Path
import hashlib
import json
import math
import random
import sys

import bpy
import numpy as np

sys.path.insert(0, str(Path(__file__).parent))
from apply_gye_estate_style import linear_hex
from northern_timber_sections import groups
from repair_masonry_coping import fingerprint

N = Path(__file__).resolve().parents[2] / 'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
TARGET = N / 'estate-fabric.blend'
IMAGE = N / 'materials/hanok-cream-plaster-painted-v1.png'
UV_NAME = 'Gye plaster wash metres'
TARGETS = {
    'North lime plaster': '#D6C7A7',
    'North earthen plaster': '#9B7A52',
    'Photo gate warm lime plaster': '#CFBD99',
}
OWNER_SCALE = {'anchae': 1.9, 'sadang': 2.2, 'sadangmun': 1.45,
               'arae': 1.6, 'angotgan': 1.8, 'gokgan': 2.0,
               'ansarang': 1.75, 'main_gate': 1.55}


def apply_plaster_wash_register(scene):
    assert not scene.get('gyePlasterWashV1'), 'Plaster wash already applied'
    image = bpy.data.images.load(str(IMAGE), check_existing=True)
    # Loaded byte-image pixels retain their sRGB encoding. Normalize the linear
    # changing the generated image bytes or the retained canonical artwork.
    pixels = np.empty(len(image.pixels), dtype=np.float32)
    image.pixels.foreach_get(pixels)
    rgb = pixels.reshape((-1, 4))[:, :3]
    mean = np.where(rgb <= .04045, rgb / 12.92, ((rgb + .055) / 1.055) ** 2.4).mean(axis=0)
    before = {ob.name: fingerprint(ob) for ob in scene.objects if ob.type == 'MESH'}
    records = {}
    for name, color in TARGETS.items():
        material = bpy.data.materials[name]
        nodes, links = material.node_tree.nodes, material.node_tree.links
        shader = next(node for node in nodes if node.type == 'BSDF_PRINCIPLED')
        assert not shader.inputs['Base Color'].is_linked, name
        original = list(shader.inputs['Base Color'].default_value)
        uv = nodes.new('ShaderNodeUVMap')
        uv.uv_map = UV_NAME
        texture = nodes.new('ShaderNodeTexImage')
        texture.name = 'Gye hand-worked cream pigment'
        texture.image = image
        texture.extension = 'REPEAT'
        links.new(uv.outputs['UV'], texture.inputs['Vector'])
        glaze = nodes.new('ShaderNodeMixRGB')
        glaze.name = 'Gye plaster register glaze'
        glaze.blend_type = 'MULTIPLY'
        glaze.inputs['Fac'].default_value = 1
        factor = np.asarray(linear_hex(color)) / mean
        glaze.inputs['Color2'].default_value = (*map(float, factor), 1)
        links.new(texture.outputs['Color'], glaze.inputs['Color1'])
        links.new(glaze.outputs['Color'], shader.inputs['Base Color'])
        shader.inputs['Roughness'].default_value = .96
        shader.inputs['Specular IOR Level'].default_value = .14
        material['gyePlasterTextureV1'] = True
        records[name] = {'oldLinearColor': original, 'pigmentMean': color,
                         'linearMultiplier': list(map(float, factor)), 'roughness': .96,
                         'faces': 0, 'objects': []}
    frames = []
    for ob in scene.objects:
        if ob.type != 'MESH':
            continue
        slots = {i: mat.name for i, mat in enumerate(ob.data.materials)
                 if mat and mat.name in TARGETS}
        if not slots or not any(p.material_index in slots for p in ob.data.polygons):
            continue
        mesh = ob.data
        assert not mesh.uv_layers.get(UV_NAME), ob.name
        uv = mesh.uv_layers.new(name=UV_NAME)
        owner = ob.get('construction_building', 'site')
        rng = random.Random('gye-plaster/' + owner + '/' + ob.name)
        component_frames, owners = {}, {}
        for ci, indices in enumerate(groups(mesh)):
            center = np.mean([mesh.vertices[i].co[:] for i in indices], axis=0)
            component_frames[ci] = (center, rng.random(), rng.random(),
                                    OWNER_SCALE.get(owner, 1.7) * rng.uniform(.84, 1.17),
                                    rng.uniform(-.18, .18))
            for i in indices:
                owners[i] = ci
        counts = {}
        for poly in mesh.polygons:
            if poly.material_index not in slots:
                continue
            material_name = slots[poly.material_index]
            counts[material_name] = counts.get(material_name, 0) + 1
            center, u0, v0, scale, angle = component_frames[owners[poly.vertices[0]]]
            axes = [a for a in range(3) if a != int(np.argmax(np.abs(poly.normal)))]
            for li in poly.loop_indices:
                delta = np.asarray(mesh.vertices[mesh.loops[li].vertex_index].co) - center
                u, v = delta[axes] / scale
                uv.data[li].uv = (u0 + u * math.cos(angle) - v * math.sin(angle),
                                  v0 + u * math.sin(angle) + v * math.cos(angle))
        uv.active_render = True
        for name, count in counts.items():
            records[name]['faces'] += count
            records[name]['objects'].append(ob.name)
        ob['gyePlasterWashV1'] = True
        frames.append({'object': ob.name, 'building': owner,
                       'components': len(component_frames), 'physicalWidthMeters': OWNER_SCALE.get(owner, 1.7)})
    assert all(fingerprint(bpy.data.objects[name], ignore_uv_layers={UV_NAME}) == value
               for name, value in before.items()), 'Plaster wash altered retained surfaces'
    assert all(record['faces'] > 100 for record in records.values()), records
    scene['gyePlasterWashV1'] = True
    return {'image': IMAGE.name, 'imageSha256': hashlib.sha256(IMAGE.read_bytes()).hexdigest(),
            'materials': records, 'mapping': frames, 'additionalUvLayer': UV_NAME,
            'originalGeometryMaterialsAndUvUnchanged': True,
            'canonicalImageBytesChanged': False, 'runtimePromotion': False}


if __name__ == '__main__':
    bpy.ops.wm.open_mainfile(filepath=str(TARGET))
    contract_path = N / 'estate-fabric-contract.json'
    contract = json.loads(contract_path.read_text(encoding='utf8'))
    if '--refresh-colors' in sys.argv:
        report = contract['gyePlasterWash']
        image = bpy.data.images.load(str(IMAGE), check_existing=True)
        pixels = np.empty(len(image.pixels), dtype=np.float32)
        image.pixels.foreach_get(pixels)
        rgb = pixels.reshape((-1, 4))[:, :3]
        mean = np.where(rgb <= .04045, rgb / 12.92, ((rgb + .055) / 1.055) ** 2.4).mean(axis=0)
        for name, record in report['materials'].items():
            glaze = bpy.data.materials[name].node_tree.nodes['Gye plaster register glaze']
            assert all(abs(glaze.inputs['Color2'].default_value[i] - v) < .001
                       for i, v in enumerate(record['linearMultiplier']))
            factors = np.asarray(linear_hex(record['pigmentMean'])) / mean
            glaze.inputs['Color2'].default_value = (*map(float, factors), 1)
            record['linearMultiplier'] = list(map(float, factors))
    else:
        report = apply_plaster_wash_register(bpy.context.scene)
    bpy.ops.wm.save_as_mainfile(filepath=str(TARGET), compress=True)
    contract['gyePlasterWash'] = report
    contract['candidateSceneSha256'] = hashlib.sha256(TARGET.read_bytes()).hexdigest()
    contract_path.write_text(json.dumps(contract, ensure_ascii=False, indent=2), encoding='utf8')
    print('PLASTER WASH REGISTER', len(report['mapping']),
          {name: record['faces'] for name, record in report['materials'].items()}, flush=True)
