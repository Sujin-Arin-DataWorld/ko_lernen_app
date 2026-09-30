"""Read-only inventory of timber materials by IlDu building in the candidate."""
from collections import Counter, defaultdict
from pathlib import Path
import json

import bpy


ROOT = Path(__file__).resolve().parents[2]
N = ROOT / 'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
bpy.ops.wm.open_mainfile(filepath=str(N / 'estate-fabric.blend'))

owners = defaultdict(Counter)
material_images = {}
for ob in bpy.context.scene.objects:
    if ob.type != 'MESH':
        continue
    building = ob.get('construction_building')
    if not building:
        continue
    for polygon in ob.data.polygons:
        if polygon.material_index >= len(ob.data.materials):
            continue
        mat = ob.data.materials[polygon.material_index]
        if not mat:
            continue
        name = mat.name
        if not any(token in name.lower() for token in
                   ('wood', 'timber', 'pine', 'walnut', 'plank', 'beam', 'board')):
            continue
        owners[building][name] += 1
        if name not in material_images:
            material_images[name] = sorted({
                str(Path(node.image.filepath).resolve())
                for node in mat.node_tree.nodes
                if node.type == 'TEX_IMAGE' and node.image and node.image.filepath
            }) if mat.use_nodes else []

report = {
    building: [{'material': name, 'faces': faces, 'images': material_images[name]}
               for name, faces in counter.most_common(15)]
    for building, counter in sorted(owners.items())
}
path = N / 'estate-wood-register.json'
path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf8')
print('ESTATE WOOD REGISTER', len(report), path, flush=True)
