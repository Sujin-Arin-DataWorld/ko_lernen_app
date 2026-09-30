"""Read-only inventory of building stone and its original texture authority."""
from pathlib import Path
from collections import Counter, defaultdict
import hashlib
import json

import bpy

N = Path(__file__).resolve().parents[2] / 'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
SOURCE = N / 'estate-fabric.blend'
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
owners = defaultdict(Counter)
materials = {}
for ob in bpy.context.scene.objects:
    if ob.type != 'MESH':
        continue
    owner = ob.get('construction_building')
    if not owner:
        owner = 'jung' if 'jung' in ob.name.lower() else 'sarang'
    for polygon in ob.data.polygons:
        mat = ob.data.materials[polygon.material_index]
        if not mat or not any(word in mat.name.lower() for word in ('stone', 'granite')):
            continue
        owners[owner][mat.name] += 1
        if mat.name in materials:
            continue
        images = []
        if mat.use_nodes:
            for node in mat.node_tree.nodes:
                if node.type == 'TEX_IMAGE' and node.image:
                    path = Path(bpy.path.abspath(node.image.filepath)).resolve()
                    images.append({'path': str(path), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()
                                   if path.is_file() else None})
        materials[mat.name] = {'images': images}
report = {'sceneSha256': hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
          'owners': {owner: dict(items.most_common()) for owner, items in sorted(owners.items())},
          'materials': materials}
(N / 'estate-stone-register.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf8')
print('ESTATE STONE REGISTER', json.dumps(report['owners']), flush=True)
