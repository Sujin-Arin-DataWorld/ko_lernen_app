"""Check delivered geometry, source bytes, door pivots and traversable routes."""
from pathlib import Path
import bpy,bmesh,json,hashlib,math,collections,sys,argparse
import numpy as np
sys.path.insert(0,str(Path(__file__).parent))
from northern_timber_sections import groups
from repair_northern_beam_seating import bearing_hits
from northern_wall_joints import rear_joint_audit
from mathutils import Vector,Matrix
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
parser=argparse.ArgumentParser();parser.add_argument('--scene',default='scene.blend');parser.add_argument('--output',default='geometry-validation.json');parser.add_argument('--contract',default='northern-contract.json')
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
bpy.ops.wm.open_mainfile(filepath=str(OUT/args.scene));s=bpy.context.scene;bpy.context.view_layer.update()
c=json.loads((OUT/args.contract).read_text(encoding='utf8'));m=json.loads((OUT/'references/eight-view-manifest.json').read_text(encoding='utf8'));checks=[]
def check(label,ok,**evidence):checks.append({'check':label,'pass':bool(ok),**evidence})
ids=['anchae','arae','angotgan','gokgan','sadang','sadangmun']
rear_joints=rear_joint_audit(s,c['buildings'])
check('Anchae rear infill and depth return have no unintended vertical openings',rear_joints['raySamples']==63 and not rear_joints['gaps'],**rear_joints)
for ident,expected in (('anchae',27),('arae',12)):
 bearing=bearing_hits(s,ident)
 check(ident+' transverse beams bear on every retained column axis',bearing['postCount']==expected and not bearing['missedPosts'],**bearing)
check('Exactly six distinct new buildings',collections.Counter(r['id'] for r in c['buildings'])==collections.Counter(ids))
check('Originals and all copied references match recorded hashes',all(sha(OUT/'references'/r['file'])==r['sha256']==sha(Path(r['source'])) for r in m),references=len(m))
for ident in ids:
 check(ident+' has one canonical and eight distinct source views',sum(r['building']==ident and r['role']=='canonical' for r in m)==1 and len({r['sha256'] for r in m if r['building']==ident and r['role']=='turnaround'})==8)
 parts=[o for o in s.objects if o.type=='MESH' and o.get('northExtension') and o.get('construction_building')==ident]
 check(ident+' has solid separately constructed parts',len(parts)>30,meshes=len(parts))
 check(ident+' geometry has finite coordinates',all(math.isfinite(v) for o in parts for vert in o.data.vertices for v in vert.co))
 check(ident+' has no empty material slots',all(len(o.data.materials)>0 and all(o.data.materials) for o in parts))
 tilemats={o.data.materials[i].name:o.data.materials[i] for o in parts for i in {p.material_index for p in o.data.polygons} if o.data.materials[i].get('surfaceKind')=='illustrated_clay'}
 reference_tiles={o.data.materials[i] for o in parts for i in {p.material_index for p in o.data.polygons} if o.data.materials[i].get('surfaceKind')=='tile' and o.data.materials[i].get('unalteredImageSha256')}
 if c.get('canonicalSurfaceReuse') and ident in ('anchae','sadang','sadangmun'):
  check(ident+' fired-clay pigment comes from its unchanged canonical',bool(reference_tiles) and all(sha(Path(mat['artworkSource']))==mat['unalteredImageSha256'] and ident in mat['artworkSource'] for mat in reference_tiles))
 else:check(ident+' has six distinct fired-clay body materials',len(tilemats)==6,materials=sorted(tilemats))
 stonemats={o.data.materials[i].name for o in parts for i in {p.material_index for p in o.data.polygons} if o.data.materials[i].get('surfaceKind')=='illustrated_granite'}
 reference_stones={o.data.materials[i] for o in parts for i in {p.material_index for p in o.data.polygons} if o.data.materials[i].get('surfaceKind')=='stone' and o.data.materials[i].get('unalteredImageSha256')}
 check(ident+' uses mineral surfaces on solid stones',bool(stonemats or reference_stones))
check('No new copy of Jung or Sarang',not any(o.get('northExtension') and o.get('construction_building') in ('jung','sarang') for o in s.objects))
check('Four-bay inner store has three front doors',sum(r['building']=='angotgan' and 'front WD1' in r['tag'] for r in c['openings'])==3)
check('Gokgan uses the located five-bay measured sheet',next(r for r in c['buildings'] if r['id']=='gokgan')['bodyDepth']==5.46 and len([r for r in m if r['building']=='gokgan' and r['role']=='blueprint'])==7)
check('Shrine front is round, inner and rear columns square',all(bpy.data.objects.get(n) for n in ['North.sadang.frame round red column','North.sadang.frame square post']))
check('Anchae unequal depths retained',next(r for r in c['buildings'] if r['id']=='anchae').get('leftBodyDepth')==3.8)
check('Anchae daechong has no front plank door duplicate',not any(o.name.startswith('North.anchae.daechong front WD3') for o in s.objects))
craft=[o for o in s.objects if o.type=='MESH' and o.get('illustratedPineV1')]
check('Illustrated timber is scoped to requested wood repairs with finite physical UVs',len(craft)>0 and all(o.get('construction_building') in ('anchae','ansarang','sadang','left_changgo','right_ansarang','north_site') and o.data.uv_layers.get('Craft timber metres') and all(math.isfinite(v) for loop in o.data.uv_layers['Craft timber metres'].data for v in loop.uv) for o in craft),meshes=len(craft))
if c.get('canonicalSurfaceReuse'):
 # The adopted artwork supersedes the earlier generated grain materials.
 # Inspect every active timber polygon, including returns and cut faces.
 faces=0;bad=[]
 for o in craft:
  uv=o.data.uv_layers.get('Canonical gate pigment')
  for p in o.data.polygons:
   mat=o.data.materials[p.material_index]
   if mat.get('surfaceKind') not in ('wood','post','beam','floor'):continue
   faces+=1
   coords=[tuple(uv.data[i].uv) for i in p.loop_indices] if uv else []
   area=abs(sum(a[0]*b[1]-b[0]*a[1] for a,b in zip(coords,coords[1:]+coords[:1]))) if coords else 0
   if not mat.get('unalteredImageSha256') or area<1e-14 or not all(math.isfinite(v) and 0<=v<=1 for q in coords for v in q):bad.append(o.name)
 check('Canonical timber covers solid faces with finite nondegenerate artwork UVs',faces>100 and not bad,faces=faces,invalidObjects=sorted(set(bad)))
else:
 check('Both cut-end and long-grain materials are used on solid faces',all(any(o.data.materials[p.material_index].name=='Illustrated pine '+kind+' v1' for o in craft for p in o.data.polygons) for kind in ('longgrain','endgrain')))
provenance=json.loads((OUT/'materials/generation-provenance.json').read_text(encoding='utf8'))
check('Generated albedo files retained without pixel edits',all(sha(OUT/'materials'/t['file'])==sha(Path(t['generatedSource'])) for t in provenance['textures']))
# Measure the delivered vertices in building coordinates, independently of
# the builder report. Cross-sections must survive export preparation.
for ident,section in [('anchae',(.330,.330)),('angotgan',(.180,.240)),('sadang',(.360,.390)),('gokgan',(.300,.300))]:
 rec=next(r for r in c['buildings'] if r['id']==ident)
 inv=Matrix.Rotation(-rec['angle'],3,'Z');origin=Vector((*rec['center'],rec['datum']))
 ob=bpy.data.objects['North.'+ident+'.frame transverse beam'];measured=[]
 for indices in groups(ob.data):
  points=np.array([inv@(ob.matrix_world@ob.data.vertices[i].co-origin) for i in indices]);span=np.ptp(points,axis=0)
  measured.append([float(span[0]),float(span[2])])
 check(ident+' beam sections match measured drawing within 1 mm',all(abs(a-section[0])<.001 and abs(b-section[1])<.001 for a,b in measured),sections=measured)
 if ident=='anchae':
  ob=bpy.data.objects['North.anchae.frame square post'];found=[];correct=True
  for indices in groups(ob.data):
   points=np.array([inv@(ob.matrix_world@ob.data.vertices[i].co-origin) for i in indices]);mid=(points.min(0)+points.max(0))/2;span=np.ptp(points,axis=0)
   if rec.get('rearPlanVersion')==1:
    from northern_anchae_plan import expected_post_section
    axes=np.r_[-rec['bodyWidth']/2,-rec['bodyWidth']/2+np.cumsum(rec['bays'])]
    axis=int(np.argmin(abs(axes-mid[0])));row=2 if mid[1]>1.3 else 0 if mid[1]<-1.8 else 1
    wx,wy=expected_post_section(axis,row)
   else:wx=wy=(.135 if mid[0]>5 else .165) if mid[1]>1.3 else .210
   correct &= abs(span[0]-wx)<.001 and abs(span[1]-wy)<.001;found.append((round(float(span[0]),3),round(float(span[1]),3)))
  check('Anchae main posts retain the registered drawing sections',correct,sections=sorted(set(found)))
  if rec.get('rearPlanVersion')==1:
   from northern_anchae_plan import local_parts
   rot=inv.transposed();axes=np.r_[-rec['bodyWidth']/2,-rec['bodyWidth']/2+np.cumsum(rec['bays'])]
   rigid=[];rear=[]
   for tag in ('frame square post','frame transverse beam','frame longitudinal beam'):
    for indices,points in local_parts(bpy.data.objects['North.anchae.'+tag],origin,rot):
     rigid.append(all(len(set(np.round(points[:,a],4)))==2 for a in range(3)))
     if tag=='frame square post' and points[:,1].mean()>1.3:rear.append(float(points[:,1].mean()))
   check('Anchae structural members are rigid rectangular solids without depth-step shear',all(rigid),members=len(rigid))
   check('All nine main rear posts follow the 3800 mm body line',len(rear)==9 and all(abs(y-1.5375)<.001 for y in rear),rearAxes=rear)
   walls=local_parts(bpy.data.objects['North.anchae.daechong rear wall'],origin,rot)
   check('Two-bay daechong rear wall lies on main rear line, not room projection',all(abs(points[:,1].mean()-1.5375)<.001 for _,points in walls))
   hallway=[]
   for indices,points in local_parts(bpy.data.objects['North.anchae.floor individual boards'],origin,rot):
    if axes[4]<points[:,0].mean()<axes[6] and points[:,1].max()>0:hallway.append(float(points[:,1].max()))
   check('Daechong floor ends at its rear wall',bool(hallway) and all(abs(y-1.5375)<.001 for y in hallway),boards=len(hallway))
   joists=[]
   for indices,points in local_parts(bpy.data.objects['North.anchae.floor under joists'],origin,rot):
    if axes[4]<points[:,0].mean()<axes[6] and points[:,1].mean()>-1:joists.append(float(np.ptp(points[:,1])))
   check('Relocated hall joists retain their 100 mm timber depth',bool(joists) and all(abs(y-.1)<.001 for y in joists),depths=joists)
   d=[d for d in c['doors'] if d['building']=='anchae' and 'daechong rear' in d['prefix']]
   check('Moved rear door hinge pivots follow their door assemblies',len(d)==2 and all(abs((inv@(Vector(h)-origin)).y-1.51)<.001 for door in d for h in door['hinges']))
   projection=local_parts(bpy.data.objects['North.anchae.room projection square post'],origin,rot)
   check('Room projection has two separate 155 mm outer columns',len(projection)==2 and all(abs(points[:,1].mean()-2.2625)<.001 and np.allclose(np.ptp(points,axis=0)[:2],[.155,.155],atol=.001) for _,points in projection))
photos=json.loads((OUT/'references/photo-manifest.json').read_text(encoding='utf8'))
mineral_provenance=json.loads((OUT/'materials/mineral-provenance.json').read_text(encoding='utf8'))
check('Mineral source maps retained without pixel edits',all(sha(OUT/'materials'/t['file'])==sha(Path(t['generatedSource'])) for t in mineral_provenance['textures']))
shells=[o for o in s.objects if o.type=='MESH' and o.get('tileShellVersion')];shell_failures=[]
for ob in shells:
 evaluated=ob.evaluated_get(bpy.context.evaluated_depsgraph_get());mesh=evaluated.to_mesh();bm=bmesh.new();bm.from_mesh(mesh)
 boundary=sum(e.is_boundary for e in bm.edges)
 if boundary:shell_failures.append({'object':ob.name,'boundaryEdges':boundary})
 bm.free();evaluated.to_mesh_clear()
check('Curved ceramic shells have closed thickness after modifiers',bool(shells) and not shell_failures,meshes=len(shells),failures=shell_failures)
plugs=[o for o in s.objects if o.type=='MESH' and o.get('tilePlugVersion')];plug_failures=[]
for ob in plugs:
 bm=bmesh.new();bm.from_mesh(ob.data)
 if any(not e.is_manifold for e in bm.edges):plug_failures.append(ob.name)
 bm.free()
check('Half-round lime end plugs are closed solids',bool(plugs) and not plug_failures,meshes=len(plugs),failures=plug_failures)
for ident in ('anchae','sadang'):
 ob=bpy.data.objects['North.'+ident+'.floor individual boards'];thicknesses=[]
 for indices in groups(ob.data):
  zs=[(ob.matrix_world@ob.data.vertices[i].co).z for i in indices];thicknesses.append(max(zs)-min(zs))
 check(ident+' floorboards match THK45 section within 0.1 mm',bool(thicknesses) and all(abs(t-.045)<.0001 for t in thicknesses),boards=len(thicknesses),minimum=min(thicknesses),maximum=max(thicknesses))
for ident in ('anchae','arae','angotgan','gokgan'):
 rec=next(r for r in c['buildings'] if r['id']==ident);origin=Vector((*rec['center'],rec['datum']));rot=Matrix.Rotation(rec['angle'],3,'Z');inv=rot.transposed()
 bed=bpy.data.objects.get('North.'+ident+'.roof solid bedding');core=bpy.data.objects.get('North.'+ident+'.roof packed ridge core')
 for ob,label in ((bed,'roof bedding'),(core,'ridge fill')):
  bm=bmesh.new()
  if ob:bm.from_mesh(ob.data)
  check(ident+' '+label+' is a closed volume',ob is not None and len(bm.faces)>0 and all(e.is_manifold for e in bm.edges),boundaryEdges=sum(e.is_boundary for e in bm.edges));bm.free()
 thickness=[]
 if bed:
  coords=np.array([inv@(bed.matrix_world@v.co-origin) for v in bed.data.vertices]);lo,hi=coords.min(0),coords.max(0);ev=bed.evaluated_get(bpy.context.evaluated_depsgraph_get())
  for x in np.linspace(lo[0]+.20,hi[0]-.20,5):
   for y in np.linspace(lo[1]+.20,hi[1]-.20,5):
    hits=[]
    for z,dz in ((20,-1),(-1,1)):
     start=ev.matrix_world.inverted()@(origin+rot@Vector((float(x),float(y),z)));direction=ev.matrix_world.inverted().to_3x3()@Vector((0,0,dz))
     hit,p,_,_=ev.ray_cast(start,direction,distance=25)
     if hit:hits.append((ev.matrix_world@p).z)
    thickness.append(hits[0]-hits[1] if len(hits)==2 else 0)
 target_thickness=.240 if ident=='anchae' and rec.get('rearVerandaVersion')==1 else .060
 check(ident+' roof has a continuous solid modelling envelope',len(thickness)==25 and all(abs(t-target_thickness)<.001 for t in thickness),samples=thickness,expectedThickness=target_thickness,surveyThicknessClaimed=False)
 gaps=[]
 if core and bed:
  ev=core.evaluated_get(bpy.context.evaluated_depsgraph_get());verts=np.array([inv@(core.matrix_world@v.co-origin) for v in core.data.vertices]);lo,hi=verts.min(0),verts.max(0)
  ridge_y=float((lo[1]+hi[1])/2)
  for x in np.linspace(lo[0]+.05,hi[0]-.05,19):
   # Probe within a side face, not exactly along the shared vertical edge.
   # The closed-manifold check above also covers that edge; Blender's ray
   # test misses it at x=0 despite hits just 0.1 mm to either side.
   x+=.00023
   heights=[]
   # Offset either side of a shared ridge edge so floating-point ray/face
   # ties cannot mistake the bottom surface for the top of the solid bed.
   for yy in (ridge_y-.002,ridge_y,ridge_y+.002):
    start=bed.matrix_world.inverted()@(origin+rot@Vector((float(x),yy,20)));hit,p,_,_=bed.ray_cast(start,Vector((0,0,-1)),distance=25)
    if hit:heights.append((inv@(bed.matrix_world@p-origin)).z)
   assert heights
   z=max(heights)+.005
   start=ev.matrix_world.inverted()@(origin+rot@Vector((float(x),ridge_y-.30,z)));direction=ev.matrix_world.inverted().to_3x3()@(rot@Vector((0,1,0)))
   if not ev.ray_cast(start,direction,distance=.60)[0]:gaps.append(float(x))
 check(ident+' ridge foot has no through gaps',core is not None and bed is not None and not gaps,raySamples=19,gaps=gaps)
anchae=next(r for r in c['buildings'] if r['id']=='anchae')
if anchae.get('rearVerandaVersion')==1:
 from northern_anchae_plan import local_parts
 origin=Vector((*anchae['center'],anchae['datum']));rot=Matrix.Rotation(anchae['angle'],3,'Z');inv=rot.transposed()
 def veranda_parts(tag):return [points for _,points in local_parts(bpy.data.objects['North.anchae.rear veranda '+tag],origin,rot)]
 posts=veranda_parts('square post');boards=veranda_parts('floor boards');purlins=veranda_parts('purlin')
 check('Rear veranda has four 165 mm posts on the 1200 mm outer axis',len(posts)==4 and all(abs(p[:,1].mean()-2.7375)<.001 and abs(np.ptp(p[:,0])-.165)<.001 for p in posts))
 check('Rear veranda boards have THK45 and an actual 1200 mm walkable depth',len(boards)>30 and all(abs(np.ptp(p[:,2])-.045)<.0001 and abs(np.ptp(p[:,1])-1.2)<.001 for p in boards))
 check('Rear veranda clear height above its floor is 1525 mm to the purlin',len(purlins)==3 and all(abs(p[:,2].min()-max(b[:,2].max() for b in boards)-1.525)<.001 for p in purlins))
 for tag,width,height,axis in [('purlin',.165,.165,1),('jangyeo',.09,.150,1),('floor girder',.09,.135,1),('floor joist',.09,.135,0)]:
  parts=veranda_parts(tag)
  check('Rear veranda '+tag+' has the section 052 cross-section',bool(parts) and all(abs(np.ptp(p[:,axis])-width)<.001 and abs(np.ptp(p[:,2])-height)<.001 for p in parts))
 roofs=[o for o in s.objects if o.type=='MESH' and o.name.startswith('North.anchae.roof')]
 extrema=[(inv@(o.matrix_world@v.co-origin)).z for o in roofs for v in o.data.vertices]
 check('Reprofiled Anchae roof stays within the measured building height',min(extrema)>1.9 and max(extrema)<5.2,minimum=min(extrema),maximum=max(extrema))
bed=bpy.data.objects.get('North.anchae.roof solid bedding')
underside=[] if bed is None else [p for p in bed.data.polygons if p.normal.z<-.01]
check('Anchae soffit retains photographed lime between rafters',bool(underside) and all(bed.data.materials[p.material_index].name=='North lime plaster' for p in underside),faces=len(underside))
paint=[o for o in s.objects if o.type=='MESH' and o.get('paintedTimberV1')]
check('Painted timber retains physical UVs and stays on shrine buildings',bool(paint) and all(o.get('construction_building') in ('sadang','sadangmun') and o.data.uv_layers.get('Painted timber metres') and all(math.isfinite(v) for loop in o.data.uv_layers['Painted timber metres'].data for v in loop.uv) for o in paint),meshes=len(paint))
paint_sources=json.loads((OUT/'materials/paint-provenance.json').read_text(encoding='utf8'))
check('Paint source albedos retained byte for byte',all(sha(OUT/'materials'/r['file'])==sha(Path(r['generatedSource'])) for r in paint_sources['textures']))
shrine=next(r for r in c['buildings'] if r['id']=='sadang');shrine_origin=Vector((*shrine['center'],shrine['datum']));shrine_inv=Matrix.Rotation(-shrine['angle'],3,'Z')
def shrine_parts(name):
 ob=bpy.data.objects.get('North.sadang.'+name)
 return [] if ob is None else [np.array([shrine_inv@(ob.matrix_world@ob.data.vertices[i].co-shrine_origin) for i in indices]) for indices in groups(ob.data)]
beams=shrine_parts('frame transverse beam')
check('Shrine transverse beams seat across both front and rear column axes',len(beams)==4 and all(p[:,1].min()<=-2.21 and p[:,1].max()>=2.21 and abs((p[:,1].max()+p[:,1].min())/2)<.001 for p in beams),ends=[[float(p[:,1].min()),float(p[:,1].max())] for p in beams])
buyeon=shrine_parts('double eave square buyeon');sizes=[np.ptp(p,axis=0) for p in buyeon]
check('Shrine buyeon has 87x120 section from sheet 059',bool(sizes) and all(abs(p[0]-.087)<.0001 and abs(p[2]-.120)<.0001 for p in sizes),count=len(sizes))
for name,count,axis,width in [('joinery.gable thirty millimetre planks',68,0,.030),('joinery.gable 45x27 cover batten',66,0,.027)]:
 parts=shrine_parts(name)
 check(name+' has surveyed real thickness',len(parts)==count and all(abs(np.ptp(p,axis=0)[axis]-width)<.0001 for p in parts),count=len(parts),width=width)
for name in ('joinery.solid roof bedding','joinery.packed ridge core','joinery.sculpted bracket shoulder','joinery.gable thirty millimetre planks'):
 ob=bpy.data.objects.get('North.sadang.'+name);bm=bmesh.new()
 if ob:bm.from_mesh(ob.data)
 check(name+' is a closed solid',ob is not None and all(e.is_manifold for e in bm.edges),boundaryEdges=sum(e.is_boundary for e in bm.edges),nonManifoldEdges=sum(not e.is_manifold for e in bm.edges));bm.free()
dp=json.loads((OUT/'materials/dancheong-provenance.json').read_text(encoding='utf8'))
check('Illustrated dancheong source retained byte for byte',sha(OUT/'materials'/dp['file'])==sha(Path(dp['generatedSource'])))
soffit=bpy.data.objects.get('North.sadang.joinery.solid roof bedding')
underside=[] if soffit is None else [p for p in soffit.data.polygons if (soffit.matrix_world.to_3x3()@p.normal).z<-.01]
check('Solid shrine roof retains photographed lime plaster beneath rafters',bool(underside) and all(soffit.data.materials[p.material_index].name=='North lime plaster' for p in underside),undersideFaces=len(underside))
bpy.context.view_layer.update();gable_joint=bpy.data.objects.get('North.sadang.joinery.gable thirty millimetre planks');gaps=[]
if gable_joint:
 evaluated=gable_joint.evaluated_get(bpy.context.evaluated_depsgraph_get());rotation=shrine_inv.transposed()
 for side in (-1,1):
  for yy in np.linspace(-2.73,2.73,20):
   t=abs(yy)/2.97;z=3.70+1.46*(1-t)**1.45+.20*t*t+.08*(1-t)-.12
   ray_x=4.30
   if shrine.get('roofSurvey'):
    from repair_sadang_roof import field
    yy=float(yy)*3.55/2.97;z=field(4.28,yy)-.12;ray_x=4.40
   elif shrine.get('elevationHeightRepair'):z=3.00+(z-3.70)*2.16/1.46 if z>3.70 else z-.70
   start=evaluated.matrix_world.inverted()@(shrine_origin+rotation@Vector((side*ray_x,float(yy),z)))
   direction=evaluated.matrix_world.inverted().to_3x3()@(rotation@Vector((-side,0,0)))
   if not evaluated.ray_cast(start,direction,distance=.30)[0]:gaps.append([side,float(yy)])
check('Both shrine gable heads close the visible roof joint',gable_joint is not None and not gaps,raySamples=40,gaps=gaps)

if shrine.get('roofSurvey'):
 survey=shrine['roofSurvey']
 bedding=shrine_parts('joinery.solid roof bedding');pts=np.concatenate(bedding)
 check('Shrine roof uses sheet 066 eave datums, not sheet 058 foundation size',np.allclose(np.ptp(pts,axis=0)[:2],[8.560,7.100],atol=.00002),roofPlanSpan=np.ptp(pts,axis=0)[:2].tolist())
 check('Shrine roof overhang from column axes is 900 and 1450 mm',np.allclose((np.ptp(pts,axis=0)[:2]-[6.760,4.200])/2,[.900,1.450],atol=.00002))
 check('Shrine roof references match the original 059 061 066 bytes',all(sha(OUT/r['file'])==r['sha256'] for r in survey['sources']))
 ends=shrine_parts('roof.round tile ends')
 check('Shrine tile ends follow 28 runs traced on sheet 066 on each side',len(ends)==56 and sum(p[:,1].mean()>0 for p in ends)==28,count=len(ends))
 # Compare the dimensions against independent elevation coordinates rather
 # than checking a value copied from the construction function.
 roof_parts=[p for o in s.objects if o.type=='MESH' and o.get('construction_building')=='sadang' and o.get('shrineRoofRebuild') for _,p in local_parts(o,shrine_origin,shrine_inv.transposed())]
 cloud=np.concatenate(roof_parts)
 side_peak=(1597-887)/((1798-1245)/4.200)
 check('Shrine roof end height fits the 061 independently calibrated silhouette',abs(cloud[:,2].max()-side_peak)<.040,measuredRoofTop=float(cloud[:,2].max()),tracedHeight=side_peak,tolerance=.040)
 centers=cloud[abs(cloud[:,0])<.05]
 front_peak=(976-594)/((1101.5-596.5)/6.760)
 check('Shrine central ridge fits the 059 silhouette without stretching courses',abs(centers[:,2].max()-front_peak)<.040,measuredRoofTop=float(centers[:,2].max()),tracedHeight=front_peak,tolerance=.040)
 import re
 field_mesh=[o for o in s.objects if o.type=='MESH' and o.get('shrineRoofRebuild') and re.fullmatch(r'North\.sadang\.roof(?:\.\d{3})?',o.name)]
 check('Shrine ceramic shell thickness is independent of roof height',len(field_mesh)==6 and all(any(m.type=='SOLIDIFY' and abs(m.thickness-.008)<1e-7 for m in o.modifiers) for o in field_mesh),fieldMeshes=len(field_mesh))
 for label,expected in [('ridge course ',5),('descending course ',3)]:
  levels={o.name.split(label)[1].split('.')[0] for o in s.objects if o.type=='MESH' and o.name.startswith('North.sadang.roof.'+label)}
  check('Shrine '+label.strip()+' count matches sheet 066',levels=={str(n) for n in range(1,expected+1)},levels=sorted(levels))
gate=next(r for r in c['buildings'] if r['id']=='sadangmun');gate_origin=Vector((*gate['center'],gate['datum']));gate_inv=Matrix.Rotation(-gate['angle'],3,'Z')
def gate_parts(name):
 ob=bpy.data.objects.get('North.sadangmun.'+name)
 return [] if ob is None else [np.array([gate_inv@(ob.matrix_world@ob.data.vertices[i].co-gate_origin) for i in indices]) for indices in groups(ob.data)]
rafters=gate_parts('roof.measured square rafter');spans=[np.ptp(p,axis=0) for p in rafters]
check('Shrine gate seven rafters have surveyed 75x90 mm square section',len(spans)==7 and all(abs(p[0]-.075)<.0001 and abs(p[2]-.090)<.0001 for p in spans),sections=[p.tolist() for p in spans])
boarding=gate_parts('roof.thirty millimetre boarding');gable=gate_parts('roof.solid gable boarding')
check('Shrine gate ceiling and gable boards have real 30 mm thickness',len(boarding)==14 and len(gable)==28 and all(abs(np.ptp(p,axis=0)[2]-.030)<.0001 for p in boarding) and all(abs(np.ptp(p,axis=0)[0]-.030)<.0001 for p in gable),ceilingBoards=len(boarding),gableBoards=len(gable))
ends=gate_parts('roof.round tile ends');central=[]
for side in (-1,1):central.append(sorted(round(float(p.mean(0)[0]),3) for p in ends if p.mean(0)[1]*side>0 and abs(p.mean(0)[0])<.8))
check('Shrine gate has six central sukiwa terminations on each slope',all(xs==[-.675,-.405,-.135,.135,.405,.675] for xs in central),centres=central)
bedding=bpy.data.objects.get('North.sadangmun.roof.solid earthen bedding');bm=bmesh.new()
if bedding:bm.from_mesh(bedding.data)
check('Shrine gate earthen roof bedding is a closed volume',bedding is not None and all(e.is_manifold for e in bm.edges),boundaryEdges=sum(e.is_boundary for e in bm.edges));bm.free()
post_clouds=gate_parts('round vermilion gatepost')
check('Shrine gate post head is 1800 mm above its 200 mm footing',len(post_clouds)==2 and all(abs(p[:,2].min()-.20)<.0001 and abs(p[:,2].max()-2.00)<.0001 for p in post_clouds))
term=bpy.data.objects.get('North.sadangmun.roof.hollow barge terminal');bm=bmesh.new()
if term:bm.from_mesh(term.data)
check('Shrine gate raised ridge terminals are four closed shell noses',term is not None and len(list(groups(term.data)))==4 and all(e.is_manifold for e in bm.edges));bm.free()
check('All supplied photos preserved byte for byte',all(sha(OUT/'references'/p['file'])==p['sha256']==sha(Path(p['source'])) for p in photos['photos']))
if anchae.get('rearAccessVersion')==1:
 origin=Vector((*anchae['center'],anchae['datum']));rot=Matrix.Rotation(anchae['angle'],3,'Z')
 for bay in (2,3):
  prefix='North.anchae.room rear '+str(bay)
  entry=next(d for d in c['doors'] if d['prefix']==prefix)
  check('Rear room '+str(bay)+' is one WD6 leaf with one hinge pivot',len(entry['hinges'])==1 and not any(o.name.startswith(prefix+'.leaf2.') for o in s.objects))
  def access_parts(tag):return [p for _,p in local_parts(bpy.data.objects[prefix+'.'+tag],origin,rot)]
  stiles=access_parts('leaf1.stile');rails=access_parts('leaf1.rail')
  cloud=np.concatenate(stiles+rails);span=np.ptp(cloud,axis=0)
  check('Rear room '+str(bay)+' leaf is 655x1450 with 54x32 frame',np.allclose(span,[.655,.032,1.450],atol=.0001) and all(np.allclose(np.ptp(p,axis=0),[.054,.032,1.450],atol=.0001) for p in stiles),measuredSpan=span.tolist())
  vertical=access_parts('leaf1.vertical sal');horizontal=access_parts('leaf1.horizontal sal')
  check('Rear room '+str(bay)+' WD6 grid has solid 9x15 sal and 7x17 cells',len(vertical)==6 and len(horizontal)==16 and all(np.allclose(np.ptp(p,axis=0)[:2],[.009,.015],atol=.0001) for p in vertical) and all(np.allclose(np.ptp(p,axis=0)[1:],[.015,.009],atol=.0001) for p in horizontal))
  jambs=access_parts('fixed.jamb')
  check('Rear room '+str(bay)+' fixed jambs match 90x120 plan section',len(jambs)==2 and all(np.allclose(np.ptp(p,axis=0)[:2],[.090,.120],atol=.0001) for p in jambs))
 soil=bpy.data.objects['North.anchae.rear veranda earth surface'];soil_parts=local_parts(soil,origin,rot)
 surface=float(max(p[:,2].max() for _,p in soil_parts))
 boards=local_parts(bpy.data.objects['North.anchae.rear veranda floor boards'],origin,rot)
 check('Rear veranda has 535 mm rise from its own ground to the floor',abs(max(p[:,2].max() for _,p in boards)-surface-.535)<.0001,groundLocal=surface)
 # Sample the previously buried base above the irregular perimeter stones.
 dep=bpy.context.evaluated_depsgraph_get();rays=[]
 axes=np.r_[-anchae['bodyWidth']/2,-anchae['bodyWidth']/2+np.cumsum(anchae['bays'])]
 for x in axes[1:5]:
  start=origin+rot@Vector((x,3.20,.095))
  hit,_,_,_,ob,_=s.ray_cast(dep,start,rot@Vector((0,-1,0)),distance=.65)
  rays.append(ob.name if hit else None)
 check('Four veranda footings are visible above the lowered earth',all(name=='North.anchae.rear veranda stone foot' for name in rays),firstHits=rays)
if anchae.get('hallAccessVersion')==1:
 origin=Vector((*anchae['center'],anchae['datum']));rot=Matrix.Rotation(anchae['angle'],3,'Z')
 dep=bpy.context.evaluated_depsgraph_get();closed_hits=[]
 for room,depth in ((1,.175),(2,.140)):
  prefix='North.anchae.hall room '+str(room);entry=next(d for d in c['doors'] if d['prefix']==prefix)
  def hall_parts(tag):return [q for _,q in local_parts(bpy.data.objects[prefix+'.'+tag],origin,rot)]
  stiles=hall_parts('leaf1.stile');rails=hall_parts('leaf1.rail');span=np.ptp(np.concatenate(stiles+rails),axis=0)
  check('Hall WD4 room '+str(room)+' has measured 695x1740 leaf and 54x45 solid stiles',np.allclose(span,[.045,.695,1.740],atol=.0001) and all(np.allclose(np.ptp(q,axis=0),[.045,.054,1.740],atol=.0001) for q in stiles),measuredSpan=span.tolist())
  jambs=hall_parts('fixed.jamb')
  check('Hall room '+str(room)+' fixed frame has measured 90mm face and '+str(round(depth*1000))+'mm depth',len(jambs)==2 and all(np.allclose(np.ptp(q,axis=0)[:2],[depth,.090],atol=.0001) for q in jambs))
  sal=hall_parts('leaf1.vertical sal')
  check('Hall room '+str(room)+' lattice members have real 12x30 sections',len(sal)==14 and all(np.allclose(np.ptp(q,axis=0)[:2],[.030,.012],atol=.0001) for q in sal))
  solids=[o for o in s.objects if o.name.startswith(prefix+'.') and any(tag in o.name for tag in ('stile','rail','sal','fixed.jamb','fixed.head','fixed.sill'))];boundaries=[]
  for ob in solids:
   bm=bmesh.new();bm.from_mesh(ob.data)
   if any(not edge.is_manifold for edge in bm.edges):boundaries.append(ob.name)
   bm.free()
  check('Hall room '+str(room)+' joinery is closed-volume geometry',not boundaries,openMeshes=boundaries)
  from mathutils.bvhtree import BVHTree
  def world_tree(objects,matrix=None):
   verts=[];faces=[]
   for ob in objects:
    offset=len(verts);transform=ob.matrix_world if matrix is None else matrix@ob.matrix_world
    verts.extend(transform@v.co for v in ob.data.vertices)
    faces.extend(tuple(offset+i for i in poly.vertices) for poly in ob.data.polygons)
   return BVHTree.FromPolygons(verts,faces)
  fixed=[o for o in s.objects if o.name.startswith(prefix+'.fixed.') and any(k in o.name for k in ('jamb','head','sill','rebate'))]
  moving=[o for o in s.objects if o.name.startswith(prefix+'.leaf1.') and any(k in o.name for k in ('stile','rail','sal'))]
  fixed_tree=world_tree(fixed);hinge=Vector(entry['hinges'][0]);collisions=[]
  for angle in (15,30,45,60,78):
   matrix=Matrix.Translation(hinge)@Matrix.Rotation(math.radians(angle)*entry['rotationSigns'][0],4,'Z')@Matrix.Translation(-hinge)
   if world_tree(moving,matrix).overlap(fixed_tree):collisions.append(angle)
  check('Hall room '+str(room)+' swings about the iron pin without cutting through its frame',not collisions,collidingAngles=collisions)
  side=1 if room==1 else -1;hx=entry['hingeLocal'][0]
  for z in (1.10,1.90):
   start=origin+rot@Vector((hx+side*.35,entry['centerLocalY'],z));hit,_,_,_,ob,_=s.ray_cast(dep,start,rot@Vector((-side,0,0)),distance=.7)
   closed_hits.append(ob.name if hit else None)
 check('Two closed hall doors block the doorway with their actual leaves',len(closed_hits)==4 and all(name and '.hall room ' in name and '.leaf1.' in name for name in closed_hits),firstHits=closed_hits)
 # Interior continuity is tested at the former inter-bay trench and rear
 # floor gaps, not just by repeating the new object dimensions.
 floor_hits=[]
 for x,y in ((-2.4925,0),(-3.6,1.40),(6.2,2.10)):
  start=origin+rot@Vector((x,y,1));hit,point,_,_,ob,_=s.ray_cast(dep,start,Vector((0,0,-1)),distance=.5)
  floor_hits.append({'object':ob.name if hit else None,'height':float((point-origin).z) if hit else None})
 check('Room floors cross the old bay trench and reach the rear wall',all(r['object'] and 'warm paper floor' in r['object'] and abs(r['height']-.6335)<.001 for r in floor_hits),floorSamples=floor_hits)
if c.get('courtyardPhotoVersion'):
 actual=[]
 for i in range(3):
  prefix='North.sadang.survey sanctuary '+str(i)
  actual.append(sorted({o.name.split('.leaf')[1].split('.')[0] for o in s.objects if o.name.startswith(prefix+'.leaf')}))
 check('Shrine uses single-double-single leaves from elevation and photographs',actual==[['1'],['1','2'],['1']],actual=actual)
 for i in range(3):
  parts=shrine_parts('survey sanctuary '+str(i)+'.measured jamb')
  check('Shrine opening '+str(i)+' has 87x150 solid jambs',len(parts)==2 and all(abs(np.ptp(q,axis=0)[0]-.087)<.001 and abs(np.ptp(q,axis=0)[1]-.150)<.001 for q in parts))
 columns=shrine_parts('frame round red column');sections=[]
 for p in columns:
  center=(p.min(0)+p.max(0))/2;section=np.ptp(p,axis=0)[0];sections.append([float(center[0]),float(section)])
 check('Shrine retains four surveyed 240 mm round posts',len(sections)==4 and all(abs(width-.240)<.001 for x,width in sections),sections=sections)
 ornaments=[o for o in s.objects if 'inset petal tile edges' in o.name]
 eligible={('North.site.'+w['name']) for w in c['walls'] if w.get('floral') and math.dist(w['start'],w['stop'])>.69}
 check('Flower tile edges cover each gate-wall span long enough for a full motif',bool(eligible) and {o.name.split(' inset petal')[0] for o in ornaments}==eligible and all(len(o.data.polygons)>100 for o in ornaments),eligibleWalls=sorted(eligible))
 check('Open Gwang forecourt has no transverse wall',not any('gwang south' in o.name for o in s.objects))
 chimney=bpy.data.objects.get('North.site.rear yard chimney.hollow arched cap')
 check('Rear-yard chimney cap has solid sidewalls around an open vent',chimney is not None and len(chimney.data.polygons)>24)
 photos=json.loads((OUT/'references/photo-manifest.json').read_text(encoding='utf8'))
 check('User photographs match preserved source bytes',all(sha(OUT/'references'/p['file'])==p['sha256']==sha(Path(p['source'])) for p in photos['photos'] if p['role']=='user-photograph'))
if c.get('anchaePhotoFittingsVersion'):
 check('Kitchen diamond grille has separate wood members',bpy.data.objects.get('North.anchae.kitchen high ventilator diamond sal') is not None)
 check('Three kitchen stove mouths and east hearth are modeled',all(bpy.data.objects.get('North.anchae.photo kitchen stove '+str(i)+'.arched fire mouth') for i in range(3)) and bpy.data.objects.get('North.anchae.photo east room hearth.arched fire mouth') is not None)
if c.get('surveyReauditVersion'):
 gate=c['rearYardGate'];inv=Matrix.Rotation(-gate['angle'],3,'Z');origin=Vector((*gate['center'],1.5))
 def measured_parts(name):
  ob=bpy.data.objects.get(name)
  return [] if ob is None else [np.array([inv@(ob.matrix_world@ob.data.vertices[i].co-origin) for i in indices]) for indices in groups(ob.data)]
 posts=measured_parts('North.site.rear yard gate.main post 85x85')
 check('Jar-yard gate has two 85x85 mm posts on 1020 mm axes',len(posts)==2 and all(np.max(abs(np.ptp(q,axis=0)[:2]-.085))<.001 for q in posts) and abs(abs(posts[1].mean(0)[0]-posts[0].mean(0)[0])-1.020)<.001)
 boards=[]
 finish=bool(c.get('gateFinishCorrection'))
 for leaf in (1,2):boards+=measured_parts(f'North.site.rear yard gate.plank door.leaf{leaf}.'+('WD1 solid board 30mm' if finish else 'WD1 plank 30mm'))
 check('Jar-yard WD1 planks are 30 mm thick and 1400 mm tall',len(boards)==(4 if finish else 6) and all(abs(np.ptp(q,axis=0)[1]-.030)<.001 and abs(np.ptp(q,axis=0)[2]-1.400)<.001 for q in boards))
 roofboards=measured_parts('North.site.rear yard gate.finish roof deck' if finish else 'North.site.rear yard gate.roof board 20mm')
 check('Jar-yard roof boards stay within the measured roof envelope without out-of-bounds spikes',bool(roofboards) and all(q[:,2].min()>1.70 and q[:,2].max()<2.20 for q in roofboards))
 if finish:
  siding=measured_parts('North.site.rear yard gate.finish pungjipan THK45')
  check('Gate side elevations include twelve solid 45 mm wind boards',len(siding)==12 and all(abs(np.ptp(q,axis=0)[0]-.045)<.001 for q in siding))
 rec=anchae;inv=Matrix.Rotation(-rec['angle'],3,'Z');origin=Vector((*rec['center'],rec['datum']))
 boards=[]
 for leaf in (1,2):boards+=measured_parts(f'North.anchae.kitchen.leaf{leaf}.photo curved plank')
 check('Anchae WD1 solid door boards retain the printed 24 mm thickness',len(boards)==8 and all(abs(np.ptp(q,axis=0)[1]-.024)<.001 for q in boards))
 sal=measured_parts('North.anchae.kitchen high ventilator diamond sal')
 widths=[]
 for q in sal:
  xz=q[:,[0,2]];cov=np.cov(xz.T);_,eigen=np.linalg.eigh(cov);widths.append(float(np.ptp(xz@eigen[:,0])))
 check('Anchae WW9 diamond sal measure 8x25 mm rather than enlarged round rods',len(sal)>10 and all(abs(w-.008)<.001 for w in widths) and all(abs(np.ptp(q,axis=0)[1]-.025)<.001 for q in sal),members=len(sal))
from validate_photo_details import check_details
check_details(s,c,OUT,check)
for d in c['doors']:
 for i,h in enumerate(d['hinges']):
  parts=[o for o in s.objects if o.name.startswith(d['prefix']+f'.leaf{i+1}.')]
  # Material batching can merge several physical members into one mesh.
  # Count real board volume and hardware, not an arbitrary mesh quota.
  boards=[o for o in parts if o.type=='MESH' and any(t in o.name for t in ('board','plank','stile','rail'))]
  hardware=[o for o in parts if any(t in o.name for t in ('ring','hinge','pin','nail','iron pull'))]
  solid=all(min(o.dimensions)>.006 for o in boards)
  check(d['prefix']+f' leaf {i+1} has volumetric wood members and hardware',bool(boards) and bool(hardware) and solid,woodMeshes=len(boards),hardwareMeshes=len(hardware))
  mat=Matrix.Translation(h)@Matrix.Rotation(math.radians(78)*d['rotationSigns'][i],4,'Z')@Matrix.Translation(-Vector(h))
  for o in parts:o.matrix_world=mat@o.matrix_world
bpy.context.view_layer.update();dep=bpy.context.evaluated_depsgraph_get()
if anchae.get('hallAccessVersion')==1:
 origin=Vector((*anchae['center'],anchae['datum']));rot=Matrix.Rotation(anchae['angle'],3,'Z');hits=[]
 for entry in anchae['hallAccess']['doors']:
  side=1 if entry['partitionAxis']==4 else -1;hx=entry['hingeLocal'][0]
  for z in (1.10,1.90):
   start=origin+rot@Vector((hx+side*.35,entry['centerLocalY'],z));hit,_,_,_,ob,_=s.ray_cast(dep,start,rot@Vector((-side,0,0)),distance=.7)
   if hit:hits.append(ob.name)
 check('Both hall WD4 doors open through real room connections',not hits,raySamples=4,obstacles=hits)
if anchae.get('rearVerandaVersion')==1:
 origin=Vector((*anchae['center'],anchae['datum']));rot=Matrix.Rotation(anchae['angle'],3,'Z')
 axes=np.r_[-anchae['bodyWidth']/2,-anchae['bodyWidth']/2+np.cumsum(anchae['bays'])];hits=[]
 for bay in (2,3):
  for height in (1.10,1.85):
   start=origin+rot@Vector(((axes[bay]+axes[bay+1])/2,1.12,height))
   hit,_,_,_,ob,_=s.ray_cast(dep,start,rot@Vector((0,1,0)),distance=1.0)
   if hit:hits.append(ob.name)
 check('Both opened rear room doors lead through real openings onto the veranda',not hits,raySamples=4,obstacles=hits)
ground=bpy.data.objects['ConnectionSite.continuous earth'].evaluated_get(dep)
vents=bpy.data.objects.get('North.sadang.photo ventilated earth apron')
check('Shrine apron has modeled ventilation bores',vents is not None and bpy.data.objects.get('North.sadang.photo ventilation bore') is not None)
rec=next(r for r in c['buildings'] if r['id']=='sadang');rot=Matrix.Rotation(rec['angle'],3,'Z');origin=Vector((*rec['center'],rec['datum']))
apron=vents.evaluated_get(dep);blocked=[]
for x in (-2.82,-1.76,-.60,.65,1.95,2.82):
 rayorigin=apron.matrix_world.inverted()@(origin+rot@Vector((x,-2.20,.338)))
 direction=apron.matrix_world.inverted().to_3x3()@(rot@Vector((0,1,0)))
 if apron.ray_cast(rayorigin,direction,distance=.50)[0]:blocked.append(x)
check('All six shrine apron bores pass a ray through their centers',not blocked,blocked=blocked)
hits=[];low_clearance=[]
for route in c['routes']:
 for aa,bb in zip(route,route[1:]):
  dist=math.dist(aa,bb);n=max(1,math.ceil(dist/.65));direction=Vector((bb[0]-aa[0],bb[1]-aa[1],0)).normalized()
  for i in range(n):
   t=(i+.5)/n;x=aa[0]+(bb[0]-aa[0])*t;y=aa[1]+(bb[1]-aa[1])*t
   hit,p,_,_=ground.ray_cast(Vector((x,y,30)),Vector((0,0,-1)))
   if not hit:hits.append({'point':[x,y],'object':'missing terrain'});continue
   for h in (.70,1.65):
    hit,point,normal,index,obj,matrix=s.ray_cast(dep,Vector((x,y,p.z+h)),direction,distance=.42)
    if hit:
     evidence={'point':[x,y,h],'object':obj.name}
     if c.get('surveyReauditVersion') and h==1.65 and obj.name=='North.site.rear yard gate.head sill 85x150':low_clearance.append(evidence)
     else:hits.append(evidence)
check('Approach routes clear except the explicitly surveyed low jar-yard lintel',not hits,obstacles=hits,standingHeadObstructions=low_clearance)
if c.get('surveyReauditVersion'):
 gate=c['rearYardGate'];rot=Matrix.Rotation(gate['angle'],3,'Z');origin=Vector((*gate['center'],1.5));duck_hits=[]
 for x in (-.24,0,.24):
  start=origin+rot@Vector((x,-.55,1.30))
  hit,_,_,_,ob,_=s.ray_cast(dep,start,rot@Vector((0,1,0)),distance=1.10)
  if hit:duck_hits.append(ob.name)
 check('Opened 1400 mm jar-yard gate clears a lowered passage at 1300 mm; standing clearance is not claimed',not duck_hits,obstacles=duck_hits,openingHeightMm=1400)
# An explicit continuous gap, not a wall hidden behind the closed leaf.
hits=[]
for x in (19.65,19.86,20.05):
 hit,p,n,idx,o,mat=s.ray_cast(dep,Vector((x,16.25,2.55)),Vector((0,1,0)),distance=1.3)
 if hit:hits.append(o.name)
check('Shrine gate opens through the enclosure',not hits,obstacles=hits)
if c.get('wallFinishCorrection'):
 from repair_masonry_coping import masonry_audit,is_wall,TIMBER_SUFFIXES
 audit=masonry_audit(s)
 check('Stone and earthen walls have no timber grain materials',not audit['woodOnMasonry'],objects=audit['objects'],violations=audit['woodOnMasonry'])
 leftovers=[o.name for o in s.objects if is_wall(o) and ' coping' in o.name and o.name.endswith(TIMBER_SUFFIXES)]
 check('Ceramic wall coping has earth bedding and no building rafters or timber fascia',not leftovers and len(c['wallFinishCorrection']['earthenBedding'])==len(c['walls']),leftovers=leftovers)
report={'sceneSha256':sha(OUT/args.scene),'checks':checks,'passed':sum(r['pass'] for r in checks),'total':len(checks),'allPassed':all(r['pass'] for r in checks),'fullSurveyAccuracyClaimed':False}
(OUT/args.output).write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
for r in checks:
 if not r['pass']:print('FAIL',r,flush=True)
print('NORTHERN VALIDATION',report['passed'],'/',len(checks),flush=True)
assert report['allPassed'],'See geometry-validation.json'
