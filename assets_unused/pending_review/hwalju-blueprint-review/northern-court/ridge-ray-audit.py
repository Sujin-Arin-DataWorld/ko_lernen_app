import bpy,json,numpy as np
from pathlib import Path
from mathutils import Matrix,Vector
p=Path('assets_unused/pending_review/hwalju-blueprint-review/northern-court')
bpy.ops.wm.open_mainfile(filepath=str(p/'roof-envelope-study.blend'));bpy.context.view_layer.update()
r=next(x for x in json.loads((p/'northern-contract.json').read_text(encoding='utf8'))['buildings'] if x['id']=='gokgan')
a=Vector((*r['center'],r['datum']));rot=Matrix.Rotation(r['angle'],3,'Z');inv=rot.transposed()
bed=bpy.data.objects['North.gokgan.roof solid bedding'];core=bpy.data.objects['North.gokgan.roof packed ridge core']
for xx in (-.001,-.0001,0,.0001,.001):
 heights=[]
 for yy in (-.002,0,.002):
  h,c,n,i=bed.ray_cast(a+rot@Vector((xx,yy,20)),Vector((0,0,-1)),distance=25)
  heights.append((inv@(c-a)).z if h else None)
 zz=max(x for x in heights if x is not None)+.005
 h,c,n,i=core.ray_cast(a+rot@Vector((xx,-.30,zz)),rot@Vector((0,1,0)),distance=.60)
 print({'x':xx,'bed':heights,'probeZ':zz,'hit':h,'coreFace':i})
points=[inv@(v.co-a) for v in core.data.vertices if abs((inv@(v.co-a)).x)<.002]
print('CENTER_CORE', [tuple(p) for p in points])
