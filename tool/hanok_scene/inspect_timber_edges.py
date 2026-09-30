"""Read-only member topology and existing arris inventory for the art pass."""
from collections import Counter, defaultdict
from pathlib import Path
import json
import re
import sys

import bpy

sys.path.insert(0, str(Path(__file__).parent))
from apply_estate_matte_register import owner_of, surface_role

N = Path(__file__).resolve().parents[2] / 'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
bpy.ops.wm.open_mainfile(filepath=str(N / 'estate-fabric.blend'))
records = defaultdict(list)
for ob in bpy.context.scene.objects:
    if ob.type != 'MESH' or ob.hide_render:
        continue
    owner = owner_of(ob)
    if owner not in {'sarang', 'jung', 'anchae', 'ansarang', 'sadang', 'sadangmun', 'arae', 'angotgan', 'gokgan', 'changgo', 'main_gate', 'toilet', 'toilet1'}:
        continue
    stage = 16 if owner == 'sarang' else 12
    if owner in ('sarang', 'jung') and not ob.get('construction_first', 0) <= stage <= ob.get('construction_last', 99):
        continue
    if not re.search(r'post|column|beam|purlin|plank|board|deck', ob.name, re.I):
        continue
    if re.search(r'leaf\d|lattice|hinge|nail|peg|sal\b|stile|rail|threshold', ob.name, re.I):
        continue
    used = {p.material_index for p in ob.data.polygons}
    if not used or any(not ob.data.materials[i] or surface_role(ob.data.materials[i].name) != 'wood' for i in used):
        continue
    records[owner].append({'object': ob.name, 'vertices': len(ob.data.vertices), 'faces': len(ob.data.polygons),
                           'scale': list(ob.scale), 'size': list(ob.dimensions), 'dataUsers': ob.data.users,
                           'modifiers': [{'name': m.name, 'type': m.type,
                                          'width': m.width if m.type == 'BEVEL' else None,
                                          'segments': m.segments if m.type == 'BEVEL' else None,
                                          'limit': m.limit_method if m.type == 'BEVEL' else None}
                                         for m in ob.modifiers]})
props = bpy.types.BevelModifier.bl_rna.properties
api = {p.identifier: str(p.default) for p in props if 'weight' in p.identifier}
report = {'api': api, 'members': dict(records)}
(N / 'timber-edge-register.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf8')
for owner, items in records.items():
    print(owner, len(items), sorted((r['vertices'], r['object'], r['modifiers']) for r in items)[:6], flush=True)
print('BEVEL API', api, flush=True)
