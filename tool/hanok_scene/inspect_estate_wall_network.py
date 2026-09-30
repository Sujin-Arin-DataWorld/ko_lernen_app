"""Read the actual wall axes and surfaces for the estate connection audit."""
import bpy
import json
import sys
from pathlib import Path
import numpy as np
sys.path.insert(0, str(Path(__file__).parent))
from complete_estate_fabric import TARGET, OUT, ground, to_pixel

bpy.ops.wm.open_mainfile(filepath=str(TARGET))
records = []
for ob in bpy.context.scene.objects:
    if ob.type != 'MESH':
        continue
    name = ob.name.lower()
    if 'wall' not in name and ob.get('construction_building') != 'north_site':
        continue
    points = np.asarray([ob.matrix_world @ v.co for v in ob.data.vertices])
    core = ('core' in name and 'wall' in name) or ('earth core' in name)
    entry = {'name': ob.name, 'building': ob.get('construction_building'),
             'materials': [ob.data.materials[i].name for i in sorted({p.material_index for p in ob.data.polygons})],
             'min': points.min(0).tolist(), 'max': points.max(0).tolist()}
    if core:
        xy = points[:, :2]; centre = xy.mean(0)
        _, eig = np.linalg.eigh(np.cov((xy - centre).T)); axis = eig[:, -1]
        along = (xy - centre) @ axis
        endpoints = [centre + axis * along.min(), centre + axis * along.max()]
        entry['pixelEndpoints'] = to_pixel(endpoints).round(2).tolist()
        entry['heightOverGround'] = round(float(points[:, 2].max() - ground(*centre)), 3)
    records.append(entry)
(OUT / 'wall-network-inspection.json').write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding='utf8')
print(json.dumps([r for r in records if 'pixelEndpoints' in r], ensure_ascii=False), flush=True)
