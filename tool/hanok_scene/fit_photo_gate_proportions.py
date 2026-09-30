"""Lower the photo gate after the user's height/width proportion correction."""
from pathlib import Path
import bpy,json,hashlib,math,numpy as np
from mathutils import Matrix,Vector
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets_unused/pending_review/hwalju-blueprint-review/side-connections'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'south-photo-20260928.blend'))
s=bpy.context.scene;c=json.loads((OUT/'south-photo-20260928.json').read_text())
bc=c['buildings']['main_gate'];cx,cy=bc['center'];a=bc['angle']
M=Matrix.Translation((cx,cy,0))@Matrix.Rotation(a,4,'Z');I=M.inverted()
oldz=[-.1,0,.43,2.78,3.16,4.23,5.7]
newz=[-.1,0,.40,2.30,2.61,3.38,4.43]
def fitted(p):
 q=I@Vector(p);q.x*=.93;q.z=float(np.interp(q.z,oldz,newz));return M@q
for o in s.objects:
 if o.type=='MESH' and o.get('construction_building')=='main_gate':
  inv=o.matrix_world.inverted();o.data=o.data.copy()
  for v in o.data.vertices:v.co=inv@fitted(o.matrix_world@v.co)
for d in c['doors']:
 if d['building']=='main_gate':
  d['hinges']=[list(fitted(p)) for p in d['hinges']];d['width']*=.93;d['height']=2.30-float(np.interp(.13,oldz,newz))
# Move only the adjoining wall endpoint into the revised end post. Keep its
# other corner fixed; the long courtyard boundary must not drift with the gate.
gate_end_delta={}
for side in (-1,1):
 old=M@Vector((side*5.1,0,0));new=fitted(old);gate_end_delta[side]=new-old
for o in s.objects:
 if o.type!='MESH' or o.get('construction_building')!='forecourt_wall':continue
 o.data=o.data.copy();inv=o.matrix_world.inverted()
 for v in o.data.vertices:
  p=o.matrix_world@v.co;q=I@p
  # The terminal 1.6m joins the wing return; falloff retains tile/wall continuity.
  side=1 if q.x>0 else -1;distance=abs(abs(q.x)-5.1)
  if distance<1.6 and abs(q.y)<1.7:
   p+=gate_end_delta[side]*(1-distance/1.6);v.co=inv@p
bc.update(width=9.486,wallTop=2.47,eave=2.61,ridge=3.38)
for route in c['forecourt']['wallRoutes']:
 for key in ('start','end'):
  q=I@Vector((*route[key],0))
  if abs(abs(q.x)-5.1)<.01 and abs(q.y)<.01:route[key]=list(fitted((*route[key],0)))[:2]
c['mainGatePhotographs'].update(centralClearWidth=2.2*.93,doorClearHeight=2.30-float(np.interp(.13,oldz,newz)),masonryTop=float(np.interp(1.60,oldz,newz)))
c['photoGateProportionFit']={'reference':'photo-gate-references/12.png','policy':'photographic front and courtyard elevations; source art supplies material character only','userCorrection':'height too long; width slightly too long','heightBefore':5.70,'heightAfter':4.43,'bodyWidthBefore':10.20,'bodyWidthAfter':9.486,'doorHead':2.30,'depthRetained':2.65,'surveyedDimensions':False}
(OUT/'connection-contract.json').write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf8')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'scene.blend'),compress=True)
items=[o for o in s.objects if o.type=='MESH' and (o.get('construction_building') in ('main_gate','toilet','forecourt_wall') or o.name.startswith('PhotoWarehouse.'))]
for o in s.objects:o.select_set(False)
for o in items:o.select_set(True)
bpy.context.view_layer.objects.active=items[0]
bpy.ops.export_scene.gltf(filepath=str(OUT/'crafted-forecourt.glb'),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True,export_extras=True)
stats={}
for o in s.objects:
 if o.type!='MESH':continue
 k=o.get('construction_building',o.get('building','other'));p=np.array([o.matrix_world@Vector(v) for v in o.bound_box])
 if k not in stats:stats[k]={'lo':p.min(0).tolist(),'hi':p.max(0).tolist(),'count':0}
 else:stats[k]['lo']=np.minimum(stats[k]['lo'],p.min(0)).tolist();stats[k]['hi']=np.maximum(stats[k]['hi'],p.max(0)).tolist()
 stats[k]['count']+=1
(OUT/'proportion-fit-audit.json').write_text(json.dumps({'fit':c['photoGateProportionFit'],'sceneSha256':hashlib.sha256((OUT/'scene.blend').read_bytes()).hexdigest(),'buildingBounds':stats},indent=2),encoding='utf8')
print('PHOTO PROPORTIONS FITTED',json.dumps(stats),flush=True)
