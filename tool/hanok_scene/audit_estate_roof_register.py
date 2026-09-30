"""Read-only native roof material, owner and vertex-colour inventory."""
from pathlib import Path
from collections import defaultdict, Counter
import json
import bpy
import numpy as np

N = Path(__file__).resolve().parents[2] / 'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
bpy.ops.wm.open_mainfile(filepath=str(N / 'estate-fabric.blend'))
owners = defaultdict(Counter)
anchae_colors = []
for ob in bpy.context.scene.objects:
    if ob.type != 'MESH':
        continue
    owner = ob.get('construction_building')
    if not owner:
        owner = 'jung' if 'jung' in ob.name.lower() else 'sarang'
    for polygon in ob.data.polygons:
        mat = ob.data.materials[polygon.material_index]
        if mat and (any(t in mat.name.lower() for t in ('giwa', 'ceramic', 'clay v1', ' tile')) or
                    any(t in ob.name.lower() for t in ('giwa', 'roof pan', 'roof cover'))):
            owners[owner][mat.name] += 1
    if owner == 'anchae' and any(mat and mat.name == 'Reference anchae tile' for mat in ob.data.materials):
        attrs = []
        for attr in ob.data.color_attributes:
            values = np.empty(len(attr.data) * 4, dtype=np.float32)
            attr.data.foreach_get('color', values)
            values = values.reshape((-1, 4))
            attrs.append({'name': attr.name, 'active': attr == ob.data.color_attributes.active_color,
                          'min': values.min(0).tolist(), 'max': values.max(0).tolist(),
                          'mean': values.mean(0).tolist()})
        anchae_colors.append({'object': ob.name, 'colorAttributes': attrs,
                              'uvLayers': [uv.name for uv in ob.data.uv_layers]})
report = {'owners': {owner: dict(items.most_common()) for owner, items in sorted(owners.items())},
          'anchaeColorAttributes': anchae_colors}
(N / 'estate-roof-register.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf8')
print('ESTATE ROOF REGISTER', json.dumps(report), flush=True)
