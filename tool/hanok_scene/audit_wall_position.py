import bpy,json
from mathutils import Vector
from pathlib import Path
p=Path(r'C:\dev\hangulsori\ko_lernen_app_worktrees\hanok-hwalju-20260928\assets_unused\pending_review\hwalju-blueprint-review\side-connections')
bpy.ops.wm.open_mainfile(filepath=str(p/'scene.blend'))
rows=[]
for o in bpy.context.scene.objects:
 if o.type=='MESH' and (any(k in o.name.lower() for k in ['hwalju','numaru','nu-maru','wall to sarang']) or (o.get('construction_building')=='sarang' and any(k in o.name.lower() for k in ['foundation','plinth']))):
  ps=[o.matrix_world@Vector(v) for v in o.bound_box]
  rows.append({'name':o.name,'min':[round(min(v[i] for v in ps),3) for i in range(3)],'max':[round(max(v[i] for v in ps),3) for i in range(3)]})
(p/'wall-position-audit.json').write_text(json.dumps(rows,indent=2))
print(json.dumps(rows))
