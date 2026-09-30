from pathlib import Path
import bpy,json
from mathutils import Vector
OUT=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/side-connections'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'scene.blend'));bpy.context.view_layer.update()
found=[]
for o in bpy.context.scene.objects:
 if o.type!='MESH':continue
 p=[o.matrix_world@Vector(v) for v in o.bound_box];lo=[min(v[i] for v in p) for i in range(3)];hi=[max(v[i] for v in p) for i in range(3)]
 if lo[0]<19 and hi[0]>16 and lo[1]<1 and hi[1]>-3 and lo[2]<1.8:
  found.append({'name':o.name,'building':o.get('construction_building'),'low':lo,'high':hi,'materials':[m.name for m in o.data.materials]})
(OUT/'low-surface-diagnostic.json').write_text(json.dumps(found,indent=2))
print(json.dumps(found),flush=True)
pos=Vector((17.3,-6,3.2));target=Vector((18.092,.083,2.1));q=(target-pos).to_track_quat('-Z','Y');dep=bpy.context.evaluated_depsgraph_get()
for px,py in [(540,686),(555,684),(528,668)]:
 origin=pos+q@Vector(((px/1260-.5)*6.7,(.5-py/840)*6.7/1.5,0));direction=q@Vector((0,0,-1))
 hit,p,n,idx,o,m=bpy.context.scene.ray_cast(dep,origin,direction)
 print('PIXEL HIT',px,py,hit,o.name if o else None,list(p),dict(o.items()) if o else None,flush=True)
