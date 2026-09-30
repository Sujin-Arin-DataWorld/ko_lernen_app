"""Read-only ownership, source and gloss inventory of building wood and roofs."""
from collections import Counter, defaultdict
from pathlib import Path
import hashlib
import json

import bpy

N = Path(__file__).resolve().parents[2] / 'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
target = N / 'estate-fabric.blend'
bpy.ops.wm.open_mainfile(filepath=str(target))
owners = defaultdict(Counter)
materials = {}
for ob in bpy.context.scene.objects:
    if ob.type != 'MESH':
        continue
    owner = ob.get('construction_building') or ('jung' if 'jung' in ob.name.lower() else 'sarang')
    for polygon in ob.data.polygons:
        mat = ob.data.materials[polygon.material_index]
        if not mat or not any(token in mat.name.lower() for token in
                              ('wood', 'timber', 'walnut', 'pine', 'tile', 'ceramic', 'giwa', 'roof', 'illustrated clay')):
            continue
        owners[owner][mat.name] += 1
        if mat.name in materials:
            continue
        record = {'images': [], 'ramps': {}, 'nodes': []}
        if mat.use_nodes:
            for node in mat.node_tree.nodes:
                record['nodes'].append(node.type)
                if node.type == 'TEX_IMAGE' and node.image:
                    path = Path(bpy.path.abspath(node.image.filepath)).resolve()
                    record['images'].append({'node': node.name, 'image': node.image.name,
                                             'path': str(path), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()
                                             if path.is_file() else None})
                elif node.type == 'VALTORGB':
                    record['ramps'][node.name] = [list(e.color) for e in node.color_ramp.elements]
                elif node.type == 'BSDF_PRINCIPLED':
                    record['baseColor'] = list(node.inputs['Base Color'].default_value)
                    record['colorSource'] = (node.inputs['Base Color'].links[0].from_node.name
                                              if node.inputs['Base Color'].is_linked else None)
                    for socket in ('Roughness', 'Specular IOR Level', 'Metallic'):
                        record[socket] = float(node.inputs[socket].default_value)
                        record[socket + 'Linked'] = node.inputs[socket].is_linked
        materials[mat.name] = record
report = {'sceneSha256': hashlib.sha256(target.read_bytes()).hexdigest(),
          'buildings': {owner: dict(counter.most_common()) for owner, counter in sorted(owners.items())},
          'materials': materials}
(N / 'estate-surface-register.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf8')
print('ESTATE SURFACE REGISTER', json.dumps(report['buildings']), flush=True)
