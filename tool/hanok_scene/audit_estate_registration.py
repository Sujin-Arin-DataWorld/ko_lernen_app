"""Project current native solid footprints onto the untouched survey002 scan."""
from pathlib import Path
import bpy,json,sys,numpy as np
sys.path.insert(0,str(Path(__file__).parent))
from register_site002 import to_pixel
N=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
bpy.ops.wm.open_mainfile(filepath=str(N/'detail-redraw.blend'))
def hull(points):
 p=sorted(set((round(x,2),round(y,2)) for x,y in points))
 def cross(a,b,c):return(b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
 lo=[];hi=[]
 for q in p:
  while len(lo)>1 and cross(lo[-2],lo[-1],q)<=0:lo.pop()
  lo.append(q)
 for q in p[::-1]:
  while len(hi)>1 and cross(hi[-2],hi[-1],q)<=0:hi.pop()
  hi.append(q)
 return lo[:-1]+hi[:-1]
parts={}
for ob in bpy.context.scene.objects:
 if ob.type!='MESH' or ob.hide_render:continue
 bid=ob.get('construction_building')
 if not bid:bid='jung' if 'jung' in ob.name.lower() else 'sarang'
 if bid in ('north_site','context','site','connection_garden','forecourt_wall'):continue
 if not any(k in ob.name.lower() for k in ('roof','rafter','post','column')) or 'wall ' in ob.name.lower():continue
 kind='posts' if any(k in ob.name.lower() for k in ('post.wood','frame square post','gatepost','column')) else 'roof'
 a=[(ob.matrix_world@v.co)[:2] for v in ob.data.vertices]
 parts.setdefault(bid,{}).setdefault(kind,[]).extend(a)
result={bid:{kind:hull(to_pixel(pts)) for kind,pts in sets.items()} for bid,sets in parts.items()}
(N/'estate-plan-projection.json').write_text(json.dumps(result,indent=2))
print('PROJECTED',list(result))
