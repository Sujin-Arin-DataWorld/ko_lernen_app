from pathlib import Path
import bpy,json,sys
from mathutils import Vector,Matrix
sys.path.insert(0,str(Path(__file__).parent))
from northern_courtyard_photo_repair import OUT
from northern_anchae_plan import local_parts
bpy.ops.wm.open_mainfile(filepath=str(OUT/'spatial-detail-study.blend'))
c=json.loads((OUT/'spatial-detail-contract.json').read_text(encoding='utf8'))
r=next(r for r in c['buildings'] if r['id']=='anchae');o=Vector((*r['center'],r['datum']));rot=Matrix.Rotation(r['angle'],3,'Z')
rows=[]
for ob in bpy.context.scene.objects:
 if ob.type!='MESH':continue
 ident=ob.get('construction_building')
 if ident=='ansarang' and not any(k in ob.name for k in ('roof','foundation','petal','end grain','fissure','fine splits')):
  q=[ob.matrix_world@Vector(p) for p in ob.bound_box]
  rows.append({'name':ob.name,'materials':[m.name for m in ob.data.materials if m],'min':[min(v[i] for v in q) for i in range(3)],'max':[max(v[i] for v in q) for i in range(3)]})
 if ident=='anchae' and any(k in ob.name for k in ('kitchen front','room ondol','room warm','floor individual','open corner','end bay','right room','kitchen high','interior partition')):
  rows.append({'name':ob.name,'parts':[{'min':q.min(0).tolist(),'max':q.max(0).tolist()} for ids,q in local_parts(ob,o,rot)]})
(OUT/'redraw-inspection.json').write_text(json.dumps(rows,indent=2),encoding='utf8')
print('INSPECTED',len(rows))
