import bpy,sys,json
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P));import sarang_reference_colour_r3 as c
bpy.ops.wm.open_mainfile(filepath=str(P/'sarang-wrap-r9/sarang-wrap-r9.blend'))
rows=[]
for o in bpy.context.scene.objects:
 if o.type!='MESH' or o.hide_render or not any(s.material and s.material.get('guardian6')=='stone' for s in o.material_slots):continue
 coords=[o.matrix_world@Vector(v) for v in o.bound_box]
 rows.append(dict(name=o.name,lo=[min(v[i] for v in coords) for i in range(3)],hi=[max(v[i] for v in coords) for i in range(3)],vertices=len(o.data.vertices),polygons=len(o.data.polygons),modifiers=[(m.name,m.type) for m in o.modifiers],attributes=[(a.name,a.domain,a.data_type) for a in o.data.attributes]))
c.p.write(P/'stone-structure-r10.json',rows)
print(json.dumps(rows,ensure_ascii=False),flush=True)
