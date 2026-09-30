"""Inspect current gate components in its local architectural axes."""
from pathlib import Path
import bpy,json,math
from mathutils import Matrix,Vector
OUT=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/side-connections'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'scene.blend'));bpy.context.view_layer.update()
c=json.loads((OUT/'connection-contract.json').read_text())['buildings']['main_gate']
inv=(Matrix.Translation((*c['center'],0))@Matrix.Rotation(c['angle'],4,'Z')).inverted();rows=[]
for o in bpy.context.scene.objects:
 if o.type!='MESH' or o.get('construction_building')!='main_gate':continue
 ps=[inv@o.matrix_world@v.co for v in o.data.vertices]
 rows.append({'name':o.name,'min':[round(min(p[i] for p in ps),4) for i in range(3)],'max':[round(max(p[i] for p in ps),4) for i in range(3)],'materials':[m.name for m in o.data.materials],'vertices':len(ps)})
(OUT/'main-gate-component-audit.json').write_text(json.dumps(rows,indent=2),encoding='utf8')
print('GATE_COMPONENTS',len(rows))
