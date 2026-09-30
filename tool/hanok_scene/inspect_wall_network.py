"""Read-only wall inventory for the active estate review scene."""
from collections import Counter
from pathlib import Path
import json

import bpy
import numpy as np

root = Path(__file__).resolve().parents[2]
out = root / 'assets_unused/pending_review/hwalju-blueprint-review/northern-court/wall-network-inventory.json'


def group(name):
    for marker in ('.earth core', '.core', '.rubble', '.uneven fieldstone',
                   '.irregular stone', '.tile coping', '.pan', '.cover',
                   '.tile ends', '.ridge', '.earthen tile bedding'):
        if marker in name:
            return name.split(marker)[0]
    return name.split(' ', 1)[0]


groups = {}
cores = []
for ob in bpy.context.scene.objects:
    if ob.type != 'MESH' or not ('wall' in ob.name.lower() or
                                ob.get('construction_building') in ('estate_wall', 'north_site')):
        continue
    key = group(ob.name)
    rec = groups.setdefault(key, {'objects': 0, 'materials': Counter(), 'buildings': Counter()})
    rec['objects'] += 1
    rec['buildings'][ob.get('construction_building', '')] += 1
    rec['materials'].update(m.name for m in ob.data.materials if m)
    if 'core' not in ob.name.lower():
        continue
    points = np.array([(ob.matrix_world @ v.co)[:] for v in ob.data.vertices])
    xy = points[:, :2]
    centre = xy.mean(axis=0)
    _, basis = np.linalg.eigh((xy - centre).T @ (xy - centre))
    axis = basis[:, -1]
    if axis[0] < 0 or abs(axis[0]) < .001 and axis[1] < 0:
        axis = -axis
    projection = (xy - centre) @ axis
    cores.append({'name': ob.name, 'group': key, 'building': ob.get('construction_building', ''),
                  'start': (centre + projection.min() * axis).round(4).tolist(),
                  'stop': (centre + projection.max() * axis).round(4).tolist(),
                  'zMin': round(float(points[:, 2].min()), 4),
                  'zMax': round(float(points[:, 2].max()), 4),
                  'materials': [m.name for m in ob.data.materials if m]})

report = {'scene': bpy.data.filepath, 'cores': sorted(cores, key=lambda x: x['name']),
          'groups': {k: {'objects': v['objects'], 'materials': dict(v['materials']),
                         'buildings': dict(v['buildings'])} for k, v in sorted(groups.items())}}
out.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf8')
print('WALL NETWORK INVENTORY', len(cores), len(groups), out, flush=True)
