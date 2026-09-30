from pathlib import Path
import bpy,json,sys
from mathutils import Vector
OUT=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'scene.blend'));s=bpy.context.scene;bpy.context.view_layer.update()
r={}
for ident in ('sarang','jung','north_site'):
 obs=[o for o in s.objects if o.type=='MESH' and o.get('construction_building')==ident]
 if ident=='north_site':print('landscape objects',[o.name for o in obs]);continue
 active=[o for o in obs if o.get('construction_first',0)<=(12 if ident=='jung' else 16)<=o.get('construction_last',99)]
 v=[o.matrix_world@Vector(p) for o in active for p in o.bound_box]
 r[ident]={'meshes':len(obs),'active':len(active),'min':[min(p[k] for p in v) for k in range(3)],'max':[max(p[k] for p in v) for k in range(3)]} if v else None
print('SOUTH',json.dumps(r),flush=True)
ground=bpy.data.objects['ConnectionSite.continuous earth'];inv=ground.matrix_world.inverted()
for x,y in ((10,34),(2,34),(-4,30),(16,34),(0,35),(10,38)):
 hit,p,_,_=ground.ray_cast(inv@Vector((x,y,20)),inv.to_3x3()@Vector((0,0,-1)))
 print('ground',x,y,tuple(ground.matrix_world@p) if hit else None,flush=True)
