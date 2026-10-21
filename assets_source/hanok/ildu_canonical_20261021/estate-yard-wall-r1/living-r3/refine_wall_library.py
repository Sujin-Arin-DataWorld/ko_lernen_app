"""Bounded wall visibility adjustment in an empty Blender session.

No scene/geometry is loaded or modified. Input is the verified material library.
Soil, lime/earth walls, fine grit and contact nodes remain byte-signature equal.
"""
import json
import sys
from pathlib import Path

import bpy

OUT = Path(__file__).resolve().parent
sys.path.insert(0, str(OUT))
sys.path.insert(0, str(OUT.parent))
from run import sha, write
from material_patch import signature

record = json.loads((OUT / 'verification.json').read_text(encoding='utf-8'))
source = OUT / record['library']
assert sha(source) == record['library_sha256']
names = tuple(record['material_signatures'])
with bpy.data.libraries.load(str(source), link=False) as (src, dst):
    dst.materials = list(names)
loaded = dict(zip(names, dst.materials))
changed = []
for name, mat in loaded.items():
    assert mat.name == name
    assert signature(mat) == record['material_signatures'][name]
    if mat.get('living_r3_role') != 'stone':
        continue
    tree = mat.node_tree
    value = tree.nodes['LR3 wall | existing pigment; bounded broad value']
    value.inputs['From Min'].default_value = .28
    value.inputs['From Max'].default_value = .72
    value.inputs['To Min'].default_value = .84
    value.inputs['To Max'].default_value = 1.12
    cluster = tree.nodes['LR3 wall | sparse rough face clusters'].outputs['Result']
    distance = tree.nodes.new('ShaderNodeMapRange')
    distance.name = 'LR3 wall | 10 to 14mm only in rough clusters'
    distance.label = '10 to 14mm only in rough clusters'
    distance.clamp = True
    distance.inputs['To Min'].default_value = .010
    distance.inputs['To Max'].default_value = .014
    tree.links.new(cluster, distance.inputs['Value'])
    broad_bump = tree.nodes['LR3 wall | shallow rough mineral planes; no displacement']
    tree.links.new(distance.outputs['Result'], broad_bump.inputs['Distance'])
    changed.append(name)
assert changed
signatures = {name: signature(mat) for name, mat in loaded.items()}
assert all(signatures[n] == s for n, s in record['material_signatures'].items() if n not in changed)
output = OUT / 'living-yard-wall-r3-refined.blend'
bpy.data.libraries.write(str(output), set(loaded.values()), fake_user=True, compress=True)
with bpy.data.libraries.load(str(output), link=False) as (src, dst):
    inventory = {k: len(getattr(src, k)) for k in ('materials', 'images', 'objects', 'meshes')}
    keys = tuple(src.materials)
    dst.materials = list(keys)
for name, mat in zip(keys, dst.materials):
    assert signature(mat) == signatures[name]
assert inventory['objects'] == inventory['meshes'] == 0
record.update(library=output.name, library_sha256=sha(output), library_datablocks=inventory,
              material_signatures=signatures,
              wall_visibility_refinement={'materials': changed, 'input_library_sha256': sha(source),
                  'broad_value': {'input': [.28, .72], 'output': [.84, 1.12]},
                  'bump_distance': '10-14mm controlled by existing sparse rough cluster',
                  'unchanged_shader_signatures': 'soil, mortar and earthwall',
                  'source_geometry_recheck': 'Required by run.py apply before rendering; see reconstruction-verification.json'})
write('verification.json', record)
print('WALL LIBRARY REFINED', len(changed), 'materials', record['library_sha256'], flush=True)
