from pathlib import Path
import sys,json,bpy,numpy as np
from mathutils import Matrix,Vector
OUT=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'detail-redraw.blend'))
c=json.loads((OUT/'detail-redraw-contract.json').read_text(encoding='utf8'));r=next(r for r in c['buildings'] if r['id']=='sadang');o=Vector((*r['center'],r['datum']));inv=Matrix.Rotation(-r['angle'],3,'Z')
for ob in bpy.context.scene.objects:
 if ob.type=='MESH' and ob.get('construction_building')=='sadang':
  p=np.array([inv@(ob.matrix_world@v.co-o) for v in ob.data.vertices]);lo=p.min(0);hi=p.max(0)
  if hi[2]>2.8:print(ob.name, 'lo',lo.round(3).tolist(),'hi',hi.round(3).tolist(),'verts',len(p),flush=True)
