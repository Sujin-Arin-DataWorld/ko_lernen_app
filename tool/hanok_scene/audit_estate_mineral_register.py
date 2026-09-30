"""Read-only ownership and shader inventory of estate plaster and stone."""
from collections import Counter, defaultdict
from pathlib import Path
import json

import bpy


N = Path(__file__).resolve().parents[2] / 'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
bpy.ops.wm.open_mainfile(filepath=str(N / 'estate-fabric.blend'))
owners = defaultdict(Counter)
materials = {}
for ob in bpy.context.scene.objects:
    if ob.type != 'MESH' or not ob.get('construction_building'):
        continue
    for polygon in ob.data.polygons:
        mat = ob.data.materials[polygon.material_index]
        if not mat or not any(token in mat.name.lower() for token in
                              ('plaster', 'lime', 'earth', 'granite', 'stone', 'mortar', 'tile', 'ceramic', 'giwa', 'roof')):
            continue
        owners[ob.get('construction_building')][mat.name] += 1
        if mat.name in materials:
            continue
        record = {'images': [], 'ramps': {}, 'nodes': []}
        if mat.use_nodes:
            for node in mat.node_tree.nodes:
                record['nodes'].append(node.type)
                if node.type == 'TEX_IMAGE' and node.image:
                    record['images'].append(str(Path(bpy.path.abspath(node.image.filepath)).resolve()))
                elif node.type == 'VALTORGB':
                    record['ramps'][node.name] = [list(e.color) for e in node.color_ramp.elements]
                elif node.type == 'BSDF_PRINCIPLED':
                    record['baseColor'] = list(node.inputs['Base Color'].default_value)
                    record['colorSource'] = (node.inputs['Base Color'].links[0].from_node.name
                                              if node.inputs['Base Color'].is_linked else None)
                    record['roughness'] = float(node.inputs['Roughness'].default_value)
        materials[mat.name] = record
report = {'buildings': {owner: dict(counter.most_common()) for owner, counter in sorted(owners.items())},
          'materials': materials}
(N / 'estate-mineral-register.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf8')
print('ESTATE MINERAL REGISTER', json.dumps(report['buildings']), flush=True)
