from pathlib import Path
import bpy,json
from mathutils import Vector
root=Path(__file__).resolve().parents[2];out=root/'assets_unused/pending_review/hwalju-blueprint-review/side-connections'
for file in ('structure-base.blend','scene.blend'):
 bpy.ops.wm.open_mainfile(filepath=str(out/file));rows=[]
 for o in bpy.context.scene.objects:
  if o.type=='MESH' and 'right_ansarang' in o.name and any(t in o.name for t in ('.back rail','.boards','.craft ring','.tread1','.iron studs')):
   p=[o.matrix_world@v.co for v in o.data.vertices];rows.append({'name':o.name,'min':[min(v[i] for v in p) for i in range(3)],'max':[max(v[i] for v in p) for i in range(3)],'matrix':[list(r) for r in o.matrix_world]})
 (out/(file+'.axes.json')).write_text(json.dumps(rows,indent=2));print(file,[(r['name'],r['min'][1],r['max'][1]) for r in rows])
