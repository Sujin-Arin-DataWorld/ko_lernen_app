import bpy,sys,json
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P))
import produce as p
bpy.ops.wm.open_mainfile(filepath=str(P/'sarang-surface-r5/sarang-surface-r5.blend'))
rows=p.read(P/'sarang/material-inventory.json');names=set(n for n in p.read(P/'sarang/geometry-lock.json')['objects'] if any(s in n for s in ('finial','ornament','low cap')))
out=[]
for n in sorted(names):
 o=bpy.context.scene.objects[n];pts=[o.matrix_world@Vector(q) for q in o.bound_box]
 out.append(dict(name=n,min=[min(v[i] for v in pts) for i in range(3)],max=[max(v[i] for v in pts) for i in range(3)],matrix=[list(v) for v in o.matrix_world],materials=[s.material.name if s.material else '' for s in o.material_slots]))
p.write(P/'guardian-probe-r6.json',out)
print('PROBE',len(out))
