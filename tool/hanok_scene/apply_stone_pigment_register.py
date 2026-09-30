"""Paint building stone surfaces in one mineral family, preserving geometry.

Original artwork, texture coordinates and material slot indices are retained.
Only the two toilet foundations need a material copy because their source is
also used by a long perimeter wall. The copy is explicitly registered.
"""
from pathlib import Path
from collections import Counter
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
IMAGE = N / 'materials/hanok-stone-painted-v2.png'
UV_NAME = 'Gye stone pigment metres'
TOILET_MATERIAL = 'Gye toilet foundation mineral pigment'
PALETTE = {}
for i, color in enumerate(('#938976', '#9C927E', '#A39882', '#877E6B', '#AAA08B', '#978C75')):
    PALETTE[f'Gye hand-chipped warm stone {i}'] = color
for i, color in enumerate(('#9D927C', '#A49984', '#958A75', '#AA9F89', '#9A8F7B')):
    PALETTE[f'Pale granite {i}'] = color
for i, color in enumerate(('#8D8169', '#948970', '#9A8E74', '#8A7F68', '#A0967C')):
    PALETTE[f'Jung warm fieldstone {i}'] = color
for i, color in enumerate(('#887A61', '#8E8067', '#96876B', '#857861', '#9A8D71')):
    PALETTE[f'Jung warm fieldstone {i}.001'] = color
PALETTE.update({
    'Reference anchae stone': '#918671',
    'Reference ansarang stone': '#A69C86',
    'Reference sadang stone': '#A39A84',
    'Reference sadangmun stone': '#988F79',
    'Reference gate stone': '#968A72',
    'Illustrated granite v1 0': '#9C937F',
    'Canonical gate stone pigment.003': '#8F8369',
    TOILET_MATERIAL: '#A29882',
})


def owner_of(ob):
    return ob.get('construction_building') or ('jung' if 'jung' in ob.name.lower() else 'sarang')


def apply_stone_pigment_register(scene):
    assert not scene.get('gyeStonePigmentV2'), 'Stone pigment already applied'
    before = {ob.name: fingerprint(ob) for ob in scene.objects if ob.type == 'MESH'}
    aliases = {TOILET_MATERIAL: 'Canonical gate stone pigment.002'}
    source_toilet = bpy.data.materials[aliases[TOILET_MATERIAL]]
    toilet = source_toilet.copy()
    toilet.name = TOILET_MATERIAL
    scoped_copies = []
    for ob in scene.objects:
        if ob.type != 'MESH' or owner_of(ob) not in ('toilet', 'toilet1'):
            continue
        if source_toilet not in list(ob.data.materials):
            continue
        if ob.data.users > 1:
            ob.data = ob.data.copy()
        for i, material in enumerate(ob.data.materials):
            if material == source_toilet:
                ob.data.materials[i] = toilet
                scoped_copies.append({'object': ob.name, 'slot': i, 'source': source_toilet.name,
                                      'candidate': toilet.name})
    assert scoped_copies, 'Expected toilet stone surfaces missing'
    image = bpy.data.images.load(str(IMAGE), check_existing=True)
    pixels = np.empty(len(image.pixels), dtype=np.float32)
    image.pixels.foreach_get(pixels)
    rgb = pixels.reshape((-1, 4))[:, :3]
    mean = np.where(rgb <= .04045, rgb / 12.92, ((rgb + .055) / 1.055) ** 2.4).mean(0)
    records = {}
    original_images = {}
    for name, color in PALETTE.items():
        material = bpy.data.materials[name]
        nodes, links = material.node_tree.nodes, material.node_tree.links
        shader = next(node for node in nodes if node.type == 'BSDF_PRINCIPLED')
        for node in nodes:
            if node.type == 'TEX_IMAGE' and node.image:
                path = Path(bpy.path.abspath(node.image.filepath)).resolve()
                if path.is_file():
                    original_images[str(path)] = hashlib.sha256(path.read_bytes()).hexdigest()
            elif node.type == 'BUMP':
                node.inputs['Strength'].default_value = min(float(node.inputs['Strength'].default_value), .12)
            elif node.type == 'NORMAL_MAP':
                node.inputs['Strength'].default_value = min(float(node.inputs['Strength'].default_value), .16)
        old_source = (shader.inputs['Base Color'].links[0].from_node.name
                      if shader.inputs['Base Color'].is_linked else None)
        assert not nodes.get('Gye mineral pigment glaze'), name
        uv = nodes.new('ShaderNodeUVMap')
        uv.uv_map = UV_NAME
        texture = nodes.new('ShaderNodeTexImage')
        texture.name = 'Gye broad mineral paint'
        texture.image = image
        texture.extension = 'REPEAT'
        links.new(uv.outputs['UV'], texture.inputs['Vector'])
        glaze = nodes.new('ShaderNodeMixRGB')
        glaze.name = 'Gye mineral pigment glaze'
        glaze.blend_type = 'MULTIPLY'
        glaze.inputs['Fac'].default_value = 1
        factors = np.asarray(linear_hex(color)) / mean
        glaze.inputs['Color2'].default_value = (*map(float, factors), 1)
        links.new(texture.outputs['Color'], glaze.inputs['Color1'])
        links.new(glaze.outputs['Color'], shader.inputs['Base Color'])
        for link in list(shader.inputs['Roughness'].links):
            links.remove(link)
        shader.inputs['Roughness'].default_value = .96
        shader.inputs['Specular IOR Level'].default_value = .12
        material['gyeStoneTextureV2'] = True
        records[name] = {'pigmentMean': color, 'linearMultiplier': list(map(float, factors)),
                         'originalColorSourceNode': old_source, 'faces': 0, 'owners': {}, 'objects': []}
    mapping = []
    for ob in scene.objects:
        if ob.type != 'MESH':
            continue
        slots = {i: material.name for i, material in enumerate(ob.data.materials)
                 if material and material.name in PALETTE}
        if not slots or not any(p.material_index in slots for p in ob.data.polygons):
            continue
        if ob.data.users > 1:
            ob.data = ob.data.copy()
        mesh = ob.data
        assert not mesh.uv_layers.get(UV_NAME), ob.name
        old_active = mesh.uv_layers.active.name if mesh.uv_layers.active else None
        old_render = next((layer.name for layer in mesh.uv_layers if layer.active_render), None)
        uv = mesh.uv_layers.new(name=UV_NAME)
        assert list(mesh.uv_layers).index(uv) <= 3, f'Web review UV limit exceeded: {ob.name}'
        if old_active:
            mesh.uv_layers.active = mesh.uv_layers[old_active]
        if old_render:
            mesh.uv_layers[old_render].active_render = True
        owner = owner_of(ob)
        rng = random.Random('gye-stone/' + owner + '/' + ob.name)
        points = np.array([ob.matrix_world @ vertex.co for vertex in mesh.vertices])
        component_frames, vertex_owners = {}, {}
        for ci, indices in enumerate(groups(mesh)):
            center = points[indices].mean(0)
            width = (.74 if owner in ('sarang', 'ansarang', 'sadang') else .64) * rng.uniform(.84, 1.20)
            component_frames[ci] = (center, rng.random(), rng.random(), width,
                                    rng.uniform(-math.pi, math.pi))
            for i in indices:
                vertex_owners[i] = ci
        counts = Counter()
        normal_matrix = np.array(ob.matrix_world.to_3x3().inverted().transposed())
        for polygon in mesh.polygons:
            if polygon.material_index not in slots:
                continue
            name = slots[polygon.material_index]
            counts[name] += 1
            center, u0, v0, width, angle = component_frames[vertex_owners[polygon.vertices[0]]]
            normal = normal_matrix @ np.asarray(polygon.normal)
            axes = [axis for axis in range(3) if axis != int(np.argmax(np.abs(normal)))]
            cosine, sine = math.cos(angle), math.sin(angle)
            for li in polygon.loop_indices:
                delta = points[mesh.loops[li].vertex_index] - center
                u, v = delta[axes] / width
                uv.data[li].uv = (u0 + u * cosine - v * sine, v0 + u * sine + v * cosine)
        for name, count in counts.items():
            record = records[name]
            record['faces'] += count
            record['owners'][owner] = record['owners'].get(owner, 0) + count
            record['objects'].append(ob.name)
        ob['gyeStonePigmentV2'] = True
        mapping.append({'object': ob.name, 'building': owner, 'components': len(component_frames),
                        'uvSet': list(mesh.uv_layers).index(uv), 'preservedActiveUv': old_render})
    assert all(fingerprint(bpy.data.objects[name], ignore_uv_layers={UV_NAME},
                           material_name_aliases=aliases) == value for name, value in before.items()), \
        'Stone pigment changed retained shape or source surface mapping'
    assert all(hashlib.sha256(Path(path).read_bytes()).hexdigest() == digest
               for path, digest in original_images.items()), 'Source artwork image changed'
    assert all(record['faces'] for record in records.values()), 'Unused stone target in register'
    scene['gyeStonePigmentV2'] = True
    return {'sourceSceneSha256': hashlib.sha256(TARGET.read_bytes()).hexdigest(),
            'image': IMAGE.name, 'imageSha256': hashlib.sha256(IMAGE.read_bytes()).hexdigest(),
            'materials': records, 'mapping': mapping, 'additionalUvLayer': UV_NAME,
            'slotMaterialAliases': aliases, 'scopedMaterialCopies': scoped_copies,
            'originalImages': original_images,
            'stoneSizesStairHeightsAndOriginalUvChanged': False, 'runtimePromotion': False}


if __name__ == '__main__':
    bpy.ops.wm.open_mainfile(filepath=str(TARGET))
    contract_path = N / 'estate-fabric-contract.json'
    contract = json.loads(contract_path.read_text(encoding='utf8'))
    report = apply_stone_pigment_register(bpy.context.scene)
    bpy.ops.wm.save_as_mainfile(filepath=str(TARGET), compress=True)
    contract['gyeStonePigment'] = report
    contract['candidateSceneSha256'] = hashlib.sha256(TARGET.read_bytes()).hexdigest()
    contract_path.write_text(json.dumps(contract, ensure_ascii=False, indent=2), encoding='utf8')
    print('STONE PIGMENT REGISTER', len(report['materials']), len(report['mapping']),
          sorted({row['building'] for row in report['mapping']}), flush=True)
