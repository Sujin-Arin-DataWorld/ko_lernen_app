"""Read-only local coordinates for the rear veranda/ground audit."""
from pathlib import Path
import bpy,json,sys
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).parent))
from northern_wall_joints import basis
from northern_anchae_plan import local_parts
OUT=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'scene.blend'))
c=json.loads((OUT/'northern-contract.json').read_text(encoding='utf8'))
origin,rot,axes=basis(c['buildings'])
for tag in ('foundation','foundation.recessed earth mortar','foundation earth top','rear veranda stone foot','room rear','room rear.jamb','room rear.head/sill'):
 ob=bpy.data.objects.get('North.anchae.'+tag)
 if ob is None:continue
 rows=[{'min':p.min(0).round(5).tolist(),'max':p.max(0).round(5).tolist()} for _,p in local_parts(ob,origin,rot)]
 print(tag,json.dumps(rows if len(rows)<20 else {'count':len(rows),'examples':rows[:3]+rows[-3:]}),flush=True)
ground=bpy.data.objects['ConnectionSite.continuous earth'];inv=ground.matrix_world.inverted()
for x in (axes[1],(axes[2]+axes[3])/2,axes[4]):
 for y in (1.54,2.40,2.7375,3.1,3.7):
  p=origin+rot@Vector((x,y,5));hit,point,_,_=ground.ray_cast(inv@p,inv.to_3x3()@Vector((0,0,-1)))
  print('terrain',round(x,3),y,round((ground.matrix_world@point-origin).z,4) if hit else None,flush=True)
