import bpy,json
from pathlib import Path
from mathutils import Vector
p=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(p/'sarang-palette-brush-study.blend'))
items=[]
for o in bpy.context.scene.objects:
 if o.type!='MESH':continue
 vs=[o.matrix_world@Vector(v) for v in o.bound_box]
 lo=[min(v[i] for v in vs) for i in range(3)];hi=[max(v[i] for v in vs) for i in range(3)]
 if hi[0]<10 or lo[0]>16 or lo[1]>0 or hi[1]<-5 or hi[2]<1.2 or lo[2]>3.9:continue
 if any(k in o.name.lower() for k in ['post','column','beam','numaru','rail','fascia','apron','board']):
  items.append(dict(name=o.name,min=lo,max=hi))
(p/'member-bounds.json').write_text(json.dumps(items,indent=2),encoding='utf-8')
print(json.dumps(items,indent=2))
