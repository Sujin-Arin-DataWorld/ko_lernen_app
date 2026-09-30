import bpy,json,sys
from pathlib import Path
from mathutils import Vector,Matrix
p=Path('assets_unused/pending_review/hwalju-blueprint-review/northern-court')
bpy.ops.wm.open_mainfile(filepath=str(p/'scene.blend'))
c=json.loads((p/'northern-contract.json').read_text());r=next(r for r in c['buildings'] if r['id']=='sadang');inv=Matrix.Rotation(-r['angle'],3,'Z');origin=Vector((*r['center'],r['datum']))
for o in bpy.context.scene.objects:
 if o.type=='MESH' and o.get('construction_building')=='sadang' and any(t in o.name for t in ('bracket','roof.','eave','dancheong','beam')):
  pts=[inv@(o.matrix_world@v.co-origin) for v in o.data.vertices];lo=[min(v[k] for v in pts) for k in range(3)];hi=[max(v[k] for v in pts) for k in range(3)];print(o.name, 'bounds', [round(v,3) for v in lo], [round(v,3) for v in hi])
