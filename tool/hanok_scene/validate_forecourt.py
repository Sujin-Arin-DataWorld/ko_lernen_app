"""Inspect delivered mesh contacts, openings and frozen base, not just config."""
from pathlib import Path
import bpy, ast, json, hashlib, numpy as np, math
from mathutils import Vector, Matrix
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'assets_unused/pending_review/hwalju-blueprint-review/side-connections'
for n in ast.parse((Path(__file__).parent/'validate_connections_native.py').read_text(encoding='utf8')).body:
 if isinstance(n,ast.FunctionDef) and n.name=='fingerprint':exec(compile(ast.Module(body=[n],type_ignores=[]),'fingerprint','exec'))
bpy.ops.wm.open_mainfile(filepath=str(OUT/'ansarang-complete.blend'));bpy.context.view_layer.update()
protected={o.name:fingerprint(o) for o in bpy.context.scene.objects if o.type=='MESH'}
bpy.ops.wm.open_mainfile(filepath=str(OUT/'scene.blend'));s=bpy.context.scene;bpy.context.view_layer.update();dep=bpy.context.evaluated_depsgraph_get()
c=json.loads((OUT/'connection-contract.json').read_text(encoding='utf8'));checks=[]
def check(name,passed,**details):
 checks.append({'check':name,'pass':bool(passed),**details})
def bounds(parts):
 ps=np.array([(o.matrix_world@v.co)[:] for o in parts for v in o.data.vertices]);return ps.min(axis=0),ps.max(axis=0)
def tr(ident,p):
 b=c['buildings'][ident];x,y=b['center'];co=math.cos(b['angle']);si=math.sin(b['angle']);return Vector((x+co*p[0]-si*p[1],y+si*p[0]+co*p[1],p[2]))
terrain=bpy.data.objects['ConnectionSite.continuous earth'].evaluated_get(dep)
def height(x,y):
 hit,p,_,_=terrain.ray_cast(Vector((x,y,30)),Vector((0,0,-1)));assert hit;return float(p.z)
check('All previously checked building, wall and terrain meshes retained',all(fingerprint(bpy.data.objects[n])==v for n,v in protected.items()),count=len(protected))
for ident in ('main_gate','toilet'):
 parts=[o for o in s.objects if o.type=='MESH' and o.get('construction_building')==ident]
 lo,hi=bounds(parts);check(ident+' has solid multi-part architecture',len(parts)>50 and hi[2]-lo[2]>3,meshes=len(parts),bounds=[lo.tolist(),hi.tolist()])
check('Toilet lies inside warehouse-to-gate left enclosure',-23.4<c['buildings']['toilet']['center'][0]<-12 and -10.2<c['buildings']['toilet']['center'][1]<-3.9)
# Test the actual central passage with leaves open, including the new ironwork.
for door in c['doors']:
 if door['building']!='main_gate':continue
 for i,h in enumerate(door['hinges']):
  mat=Matrix.Translation(h)@Matrix.Rotation(math.radians(78)*door['rotationSigns'][i],4,'Z')@Matrix.Translation(-Vector(h))
  for o in s.objects:
   if o.name.startswith(door['prefix']+f'.leaf{i+1}.'):o.matrix_world=mat@o.matrix_world
bpy.context.view_layer.update();dep=bpy.context.evaluated_depsgraph_get()
blocking=[]
for xx in (-.28,0,.28):
 for zz in (.4,1.2,1.85):
  a=tr('main_gate',(xx,-2.3,zz));b=tr('main_gate',(xx,2.3,zz));hit,p,n,i,o,m=s.ray_cast(dep,a,(b-a).normalized(),distance=(b-a).length)
  if hit:blocking.append(o.name)
check('Main gate open leaves provide a traversable central route',not blocking,obstacles=blocking)
for record in c['forecourt']['wallRoutes']:
 o=bpy.data.objects[record['id']+'.core'];a=np.array(record['start']);b=np.array(record['end']);mid=(a+b)/2
 hit,p,n,i,obj,m=s.ray_cast(dep,Vector((mid[0],mid[1],record['coreTop']+1)),Vector((0,0,-1)),distance=2)
 check(record['id']+' has physical masonry and coping',hit and obj.get('construction_building')=='forecourt_wall',firstHit=obj.name if hit else None)
 grades=[height(*(a+(b-a)*t)) for t in np.linspace(0,1,31)]
 check(record['id']+' core is continuously grounded',record['base']<min(grades) and record['coreTop']>max(grades)+1,groundRange=[min(grades),max(grades)])
# Structural connection probes cross the actual gate side posts and warehouse corner.
warehouse_joint=(-10.075,-3.535,1.5) if 'warehousePhotoEnd' in c else (-7.21,-3.535,1.5)
for name,p in [('warehouse',warehouse_joint),('ansarang-wall',(14.82,-21.1,1.2))]:
 close=[]
 for o in s.objects:
  if o.type!='MESH' or not (o.get('construction_building') in ('forecourt_wall','changgo','connection_garden')):continue
  lo,hi=bounds([o])
  if all(lo[i]-.04<=p[i]<=hi[i]+.04 for i in range(3)):close.append(o.name)
 check(name+' connection overlaps real existing construction',any(n.startswith('Forecourt.wall.') for n in close) and any(not n.startswith('Forecourt.wall.') for n in close),parts=close)
wing_half=c.get('photoGateProportionFit',{}).get('bodyWidthAfter',10.2)/2
for side,x in [('left',-wing_half),('right',wing_half)]:
 point=tr('main_gate',(x,0,1.0));r=min(c['forecourt']['wallRoutes'],key=lambda r:min(math.dist(point[:2],r['start']),math.dist(point[:2],r['end'])))
 check('Main gate '+side+' wall ends at wing return',min(math.dist(point[:2],r['start']),math.dist(point[:2],r['end']))<.01)
if 'mainGatePhotographs' in c:
 check('Four exterior windows have the photographed horizontal and fine vertical sal',len([o for o in s.objects if o.name.startswith('PhotoGate.window') and o.name.endswith('.horizontal sal')])==4 and len([o for o in s.objects if o.name.startswith('PhotoGate.window') and o.name.endswith('.fine vertical sal')])==4)
 check('Five separate inscription boards use the attached photograph',len([o for o in s.objects if o.name.startswith('PhotoGate.plaque') and o.name.endswith('.photo inscription')])==5)
 check('Central passage is stone rather than timber planks',any(o.name=='PhotoGate.passage irregular paving' for o in s.objects) and not any('.passage floor' in o.name for o in s.objects))
 check('White lime roof underside has exposed curved rafters',all(bpy.data.objects.get(n) for n in ['PhotoGate.white lime soffit','PhotoGate.exposed curved rafter']))
 if 'warehousePhotoEnd' in c:
  parts=[o for o in s.objects if o.name.startswith('Forecourt.wall.warehouse-toilet.0.')];lo,hi=bounds(parts)
  check('Warehouse gable is not crossed by the courtyard boundary',hi[0]<-10.04 and hi[2]<2.03,maxBounds=hi.tolist())
else:
 check('Main gate canonical upright windows contain no invented horizontal lattice',not any('.outside window horizontal sal' in o.name for o in s.objects))
check('Toilet has three thick door battens',any('canonical batten' in o.name for o in s.objects))
report={'sceneSha256':hashlib.sha256((OUT/'scene.blend').read_bytes()).hexdigest(),'checks':checks,'allPassed':all(x['pass'] for x in checks)}
(OUT/'forecourt-geometry-validation.json').write_text(json.dumps(report,indent=2),encoding='utf8')
for x in checks:print(('PASS ' if x['pass'] else 'FAIL ')+x['check'],flush=True)
assert report['allPassed'],[x for x in checks if not x['pass']]
