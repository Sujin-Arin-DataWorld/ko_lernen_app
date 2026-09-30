from pathlib import Path
import bpy,json,hashlib,numpy as np
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2];REVIEW=ROOT/'assets_unused/pending_review/hwalju-blueprint-review';OUT=REVIEW/'side-connections'
def fingerprint(o):
 h=hashlib.sha256()
 for v in o.data.vertices:h.update(np.asarray(v.co,dtype=np.float32).tobytes())
 for p in o.data.polygons:h.update(np.asarray(p.vertices,dtype=np.int32).tobytes())
 h.update(str([list(r) for r in o.matrix_world]).encode());h.update(str(sorted((k,str(o[k])) for k in o.keys())).encode());h.update(str([m.name for m in o.data.materials]).encode());return h.hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(REVIEW/'terrain/scene.blend'))
protected={o.name:fingerprint(o) for o in bpy.context.scene.objects if o.type=='MESH' and o.name!='TerrainFix.continuous rising courtyard'}
bpy.ops.wm.open_mainfile(filepath=str(OUT/'scene.blend'));s=bpy.context.scene
assert len(protected)==940
assert all(fingerprint(bpy.data.objects[n])==v for n,v in protected.items())
ground=bpy.data.objects['ConnectionSite.continuous earth'];dep=bpy.context.evaluated_depsgraph_get();terrain=ground.evaluated_get(dep)
def height(x,y):
 hit,pos,_,_=terrain.ray_cast(Vector((x,y,30)),Vector((0,0,-1)));assert hit;return float(pos.z)
contract=json.loads((OUT/'connection-contract.json').read_text(encoding='utf8'))
checks=[]
def check(label,ok,**details):
 checks.append({'check':label,'pass':bool(ok),**details});assert ok,(label,details)
check('940 approved native building meshes unchanged',True)
entry_x,entry_y=contract['openForecourtConnection']['openingCenter']
samples=[(x,height(x,entry_y)) for x in np.linspace(11.3,20.5,120)]
check('Open path ground has no cliff',max(abs(b[1]-a[1]) for a,b in zip(samples,samples[1:]))<.025,maxRisePerSample=max(abs(b[1]-a[1]) for a,b in zip(samples,samples[1:])))
check('Forecourt connection has no gate',contract['openForecourtConnection']['gateOnRoute']==False)
check('Open path clear width 2.8m',abs(contract['openForecourtConnection']['openingWidth']-2.8)<1e-6)
check('Right gate stair low side faces Sarang forecourt',height(18.092,-2)<.02 and height(18.092,1.2)>.70,heights=[height(18.092,-2),height(18.092,1.2)])
check('Ansarang foundation datum matches ground',abs(height(24.4459,-9.7831)-contract['buildings']['ansarang']['ground'])<.005)
# Collision test across eye and walking heights, ignoring intentional low stone lip.
hits=[]
for x in np.linspace(11.3,20.3,48):
 for z in (.3,1.0,1.7):
  hit,pos,norm,index,obj,matrix=s.ray_cast(dep,Vector((float(x),entry_y,z)),Vector((1,0,0)),distance=.25)
  if hit:hits.append(obj.name)
check('Open route unobstructed at walking and eye heights',not hits,hits=hits)
check('Entry faces right fourth bay rather than centre',-15.2432<entry_y<-12.5131,entryY=entry_y,buildingCentreY=-9.7831032106)
hit,pos,norm,index,obj,matrix=s.ray_cast(dep,Vector((entry_x+.05,entry_y,1.7)),Vector((1,0,0)),distance=15)
check('Eye line through opening reaches rightmost four-leaf joinery',hit and 'front joinery3' in obj.name,firstVisibleObject=obj.name if hit else None)
def bounds(parts):
 points=[o.matrix_world@v.co for o in parts for v in o.data.vertices]
 return [min(v[i] for v in points) for i in range(3)],[max(v[i] for v in points) for i in range(3)]
wall=[o for o in s.objects if o.type=='MESH' and o.name.startswith('ConnectionGarden.wall1.')]
lo,hi=bounds(wall)
check('Garden wall starts at marked OUTER Numaru front corner',14.3<lo[0]<14.7 and 14.9<hi[0]<15.3 and -4.15<hi[1]<-4.0,bounds=[lo,hi])
wallcore=bpy.data.objects['ConnectionGarden.wall1.ochre core'];lo,hi=bounds([wallcore])
check('Garden wall is straight on outer corner axis',abs((lo[0]+hi[0])/2-14.82)<.002 and abs(hi[0]-lo[0]-.37)<.002,bounds=[lo,hi])
corner=bpy.data.objects['Craft.Numaru continuous post 14.545'];a,b=bounds([corner])
check('Garden masonry touches Numaru outer corner timber',lo[0]<b[0] and hi[0]>a[0] and hi[1]>a[1] and lo[1]<b[1],wall=[lo,hi],post=[a,b])
core=bpy.data.objects['V27.left_changgo.wall to sarang.earth core'];lo,hi=bounds([core])
check('Left gate to Sarang wall rises without lifting footing',abs(hi[2]-3.06)<.005 and abs(lo[2]-.02)<.005,bounds=[lo,hi])
lower=[o for o in s.objects if o.name.startswith('ConnectionLeft.high wall lower')];lo,hi=bounds(lower)
check('Raised left wall has real lower masonry courses',len(lower)>0 and lo[2]<.05 and hi[2]>.89,bounds=[lo,hi])
coping=bpy.data.objects['V27.left_changgo.wall to sarang.coping.ridge'];lo,hi=bounds([coping])
check('High coping joins just below left gate eaves',3.25<hi[2]<3.38,top=hi[2],gateEave=3.38)
for gate in contract['gates']:
 ident=gate['id'];cx,cy=gate['center'];half=gate['post']/2;axis=gate['postAxis']/2
 left_token='wall to warehouse' if ident=='left_changgo' else 'wall to sarang'
 right_token='wall to sarang' if ident=='left_changgo' else 'wall to ansarang'
 for side,token in ((-1,left_token),(1,right_token)):
  wall=bpy.data.objects[f'V27.{ident}.{token}.earth core'];lo,hi=bounds([wall])
  joint=hi[0] if side<0 else lo[0];postedge=cx+side*(axis+half);overlap=(joint-postedge)*(-side)
  check(f'{ident} {token} straight and joined to gate post',abs((lo[1]+hi[1])/2-cy)<.002 and abs(hi[1]-lo[1]-.4)<.004 and 0<=overlap<.05,bounds=[lo,hi],overlap=overlap)
enclosure=contract['ansarangCourtyardEnclosure'];ax=enclosure['outerAxes']
check('Ansarang remains freestanding within rectangular courtyard',not enclosure['joinsAnsarangBuilding'] and 'rightWallReturn' not in contract)
for wi in (3,4,5):
 o=bpy.data.objects[f'ConnectionGarden.wall{wi}.ochre core'];lo,hi=bounds([o])
 check(f'Outer enclosure wall{wi} stays outside Ansarang footprint',hi[1]<-17 or lo[1]>-.12 or lo[0]>29,bounds=[lo,hi])
for label,point,direction in [('north',(24,.083,1.0),(0,1,0)),('east',(29.5,-10,1.0),(1,0,0)),('south',(24,-21.1,1.0),(0,-1,0)),('west',(14.82,-10,1.0),(-1,0,0))]:
 hit,pos,norm,index,obj,matrix=s.ray_cast(dep,Vector(point)-Vector(direction),Vector(direction),distance=2)
 check('Courtyard perimeter present on '+label,hit and ('ConnectionGarden.wall' in obj.name or 'wall to ansarang' in obj.name),object=obj.name if hit else None)
# The side elevation must have an open passage around it. This is the exact
# line obstructed by the removed, unsupported building-attached return.
hit,pos,norm,index,obj,matrix=s.ray_cast(dep,Vector((22.35,-3.7,1.5)),Vector((1,0,0)),distance=5)
check('No invented wall blocks Ansarang left-side passage',not hit,hitObject=obj.name if hit else None)
# Audit individual stepping-stone components because a batched bounding box
# can conceal floating stones when the approach grade changes beneath them.
seating=[]
for o in s.objects:
 if o.type!='MESH' or o.get('construction_building')!='left_changgo' or '.finish.approach' not in o.name:continue
 parent=list(range(len(o.data.vertices)))
 def root(i):
  while parent[i]!=i:parent[i]=parent[parent[i]];i=parent[i]
  return i
 for e in o.data.edges:
  a,b=map(root,e.vertices);parent[b]=a
 groups={}
 for v in o.data.vertices:groups.setdefault(root(v.index),[]).append(o.matrix_world@v.co)
 for ps in groups.values():
  center=sum(ps,Vector())/len(ps);z=height(center.x,center.y);top=max(v.z for v in ps);bottom=min(v.z for v in ps)
  seating.append({'name':o.name,'topAboveGrade':top-z,'bottomAboveGrade':bottom-z})
check('Each left approach stone is embedded in local grade',len(seating)>0 and all(abs(v['topAboveGrade']-.035)<.006 and v['bottomAboveGrade']<0 for v in seating),stones=seating)
treads=[o for o in s.objects if o.name.startswith('V27.right_ansarang.foundation.tread1')]
check('Actual first gate tread is on south approach',max((o.matrix_world@v.co).y for o in treads for v in o.data.vertices)<0)
for gate in contract['gates']:
 ident=gate['id'];cx,cy=gate['center'];doorparts=[o for o in s.objects if o.name.startswith(f'V27.{ident}.door.') and '.boards' in o.name]
 coords=[o.matrix_world@v.co for o in doorparts for v in o.data.vertices]
 width=max(p.x for p in coords)-min(p.x for p in coords);heightv=max(p.z for p in coords)-min(p.z for p in coords)
 check(ident+' original door dimensions retained',abs(width-gate['doorWidth'])<.02 and abs(heightv-gate['doorHeight'])<.005,width=width,height=heightv)
 check(ident+' paired crafted iron rings',len([o for o in s.objects if f'{ident}.door.' in o.name and '.craft ring' in o.name])==2)
report={'sceneSha256':hashlib.sha256((OUT/'scene.blend').read_bytes()).hexdigest(),'protectedMeshes':len(protected),'checks':checks,'allPassed':all(c['pass'] for c in checks)}
(OUT/'geometry-validation.json').write_text(json.dumps(report,indent=2));print('NATIVE CONNECTION VALIDATION',len(checks),'PASS',flush=True)
