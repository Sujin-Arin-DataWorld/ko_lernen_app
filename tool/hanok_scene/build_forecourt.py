"""Extend the checked Ansarang enclosure to the main gate and toilet.

Site002 is the positional authority; canonical illustrations govern identity.
New outer walls follow manually registered boundary corners, not a guessed
straight bridge to either house. Existing building/enclosure meshes are frozen.
"""
from pathlib import Path
import ast, bpy, json, hashlib, math, random, re, sys, numpy as np
from mathutils import Vector, Matrix
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets_unused/pending_review/hwalju-blueprint-review/side-connections'
OLD=Path('C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-warm-stone-20260923')
SOURCE=OLD/'assets_unused/pending_review/ildu_spatial_preservation_20260922/existing-estate-v36'
ARTROOT=Path('C:/dev/hangulsori/ko_lernen_app/assets_unused/pending_review/personal_hanok_v3')
ART=ARTROOT/'hyeopmun_try03_blueprint_colored.png'
sys.path.insert(0,str(OLD/'tool/hanok_scene'));import reconstruction_geometry as g
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def functions(path,names):
 for node in ast.parse(path.read_text(encoding='utf8')).body:
  if isinstance(node,ast.FunctionDef) and node.name in names:exec(compile(ast.Module(body=[node],type_ignores=[]),str(path),'exec'),globals())
functions(Path(__file__).parent/'validate_connections_native.py',('fingerprint',))
functions(Path(__file__).parent/'refine_canonical_gates.py',('new_material','pigment','components','art_uv'))
functions(Path(__file__).parent/'refine_ansarang.py',('retain_pbr','component_tints'))
bpy.ops.wm.open_mainfile(filepath=str(OUT/'ansarang-complete.blend'));s=bpy.context.scene;bpy.context.view_layer.update()
protected={o.name:fingerprint(o) for o in s.objects if o.type=='MESH'}
contract=json.loads((OUT/'ansarang-complete-contract.json').read_text(encoding='utf8'))
donor=json.loads((SOURCE/'estate.json').read_text(encoding='utf8'))
allowed={'main_gate':12,'toilet':12}
with bpy.data.libraries.load(str(SOURCE/'scene.blend'),link=False) as (src,dst):
 dst.objects=[n for n in src.objects if any('.'+k+'.' in n for k in allowed)]
items=[]
for o in dst.objects:
 if not o or o.type!='MESH':continue
 ident=o.get('construction_building');end=allowed.get(ident)
 if end is None or not o.get('construction_first',1)<=end<=o.get('construction_last',99):continue
 s.collection.objects.link(o);o.hide_set(False);o.hide_render=False;o.data=o.data.copy();items.append(o)
 o['forecourt_source']=str(SOURCE/'scene.blend')
bpy.context.view_layer.update()
base_image=bpy.data.images.load(str(ART),check_existing=True);materials={};mapped=[]
regions={'wood':[(.334,.405,.356,.618),(.389,.406,.414,.619),(.425,.409,.449,.617),(.568,.406,.592,.617),(.604,.406,.631,.619)],'post':[(.244,.328,.282,.680)],'beam':[(.303,.332,.708,.353)],'stone':[(.192,.728,.286,.756),(.391,.786,.498,.810),(.620,.795,.690,.821)]}
mapping=json.loads((SOURCE/'realtime-delivery.json').read_text())['materialMapping'];converted={};tally={}
for o in items:
 original=o.data.materials[0];name=original.name.lower();kind='retained'
 # Plaques already carry corresponding untouched original artwork UVs.
 if '.identity.original' in o.name:continue
 for attr in list(o.data.color_attributes):o.data.color_attributes.remove(attr)
 if any(k in name for k in ('timber','walnut','plank')) and not any(k in name for k in ('hanji','paper')) and 'end grain' not in o.name:
  kind='post' if '.frame.post' in o.name else 'beam' if any(k in o.name for k in ('beam','lintel','fascia','threshold','cross')) else 'wood'
  art_uv(o,kind);component_tints(o,'wood')
 elif any(k in name for k in ('granite','fieldstone')):kind='stone';art_uv(o,kind);component_tints(o,'stone')
 else:
  retain_pbr(o,original)
  if any(k in name for k in ('giwa','ceramic')):kind='ceramic';component_tints(o,kind)
 for mod in o.modifiers:
  if mod.type=='BEVEL':mod.width=min(mod.width,.012 if kind=='stone' else .006);mod.segments=3
 tally[kind]=tally.get(kind,0)+1
for ident in allowed:contract['buildings'][ident]=donor['buildings'][ident]
contract['doors'] += [d for d in donor['doors'] if d['building'] in allowed]
ground=bpy.data.objects['ConnectionSite.continuous earth'];terrain=ground.evaluated_get(bpy.context.evaluated_depsgraph_get())
def height(x,y):
 hit,p,_,_=terrain.ray_cast(Vector((x,y,30)),Vector((0,0,-1)));assert hit;return float(p.z)
def tr_for(ident):
 c=contract['buildings'][ident];cx,cy=c['center'];a=c['angle'];co=math.cos(a);si=math.sin(a)
 return lambda p:(cx+co*p[0]-si*p[1],cy+si*p[0]+co*p[1],p[2])
# Canonical front windows have upright bars, not the donor's invented grid.
removed=[]
for o in list(items):
 if '.outside window horizontal sal' in o.name:
  removed.append(o.name);items.remove(o);bpy.data.objects.remove(o,do_unlink=True)
# Lower wing end masonry repeats the canonical stone base around both returns.
stone=pigment('stone');wood=pigment('wood')
earth=new_material('Forecourt ochre lime mortar');earth.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.31,.224,.13,1)
iron=new_material('Forecourt forged iron');bs=iron.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(.032,.028,.022,1);bs.inputs['Metallic'].default_value=.68;bs.inputs['Roughness'].default_value=.62
tile=next(o.data.materials[0] for o in items if 'roof' in o.name and 'main_gate source ceramic 2' in o.data.materials[0].name)
end=new_material('Forecourt aged lime tile ends');end.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.48,.45,.36,1)
rng=random.Random(9281012)
tr=tr_for('main_gate');g.set_transform(tr)
for x in (-5.1,5.1):
 for row in range(5):
  for j in range(8):g.rock('Forecourt.main_gate.side rubble',(x,j*.33-1.16,.30+row*.208),(.20,.34,.195),stone,rng)
# Solid strap hinges, raised bosses and forged drop rings: hardware is geometry.
for door in contract['doors']:
 if door['building']!='main_gate':continue
 for i in range(2):
  x=(-.18 if i==0 else .18);prefix=door['prefix']+f'.leaf{i+1}.'
  for z in (.43,1.61,2.96):
   g.box(prefix+'crafted hinge strap',((-.59 if i==0 else .59),-1.412,z),(.48,.024,.057),iron)
   for xx in (-.18,0,.18):g.rod(prefix+'crafted hinge rivet',((-.59 if i==0 else .59)+xx,-1.431,z),((-.59 if i==0 else .59)+xx,-1.445,z),.018,iron,12)
  g.box(prefix+'crafted ring escutcheon',(x,-1.423,1.51),(.12,.02,.17),iron)
  g.torus(prefix+'crafted drop ring',(x,-1.466,1.41),.080,.011,iron)
  g.rod(prefix+'crafted ring pin',(x,-1.435,1.52),(x,-1.473,1.52),.02,iron,12)
gate_details=g.flush();g.BATCHES.clear()
for o in gate_details:
 o['construction_building']='main_gate';o['source_object_name']=o.name
 if o.data.materials[0]==stone:art_uv(o,'stone');component_tints(o,'stone')
items.extend(gate_details)
# Three wooden door battens and simple latch match the toilet's approved art.
tr=tr_for('toilet');g.set_transform(tr)
td=next(d for d in contract['doors'] if d['building']=='toilet');prefix=td['prefix']+'.leaf1.'
for z in (.58,1.41,2.10):
 g.box(prefix+'canonical batten',(.31,-1.19,z),(.65,.045,.078),wood)
 for x in (.055,.565):g.rod(prefix+'batten nail',(x,-1.217,z),(x,-1.228,z),.011,iron,10)
g.box(prefix+'wood latch',(.50,-1.24,1.40),(.042,.05,.24),wood)
toilet_details=g.flush();g.BATCHES.clear()
for o in toilet_details:
 o['construction_building']='toilet';o['source_object_name']=o.name
 if o.data.materials[0]==wood:art_uv(o,'wood');component_tints(o,'wood')
items.extend(toilet_details)
g.set_transform(lambda p:p)
mt=tr_for('main_gate');left=mt((-5.1,0,0))[:2];right=mt((5.1,0,0))[:2]
# Registered site002 landmarks: warehouse end, west enclosure foot, southwest
# corner, east road boundary and Ansarang enclosure's southwest corner.
routes=[('warehouse-toilet',[(-7.21,-3.535),(-23.613,-3.535),(-23.618,-10.459),left],2.24),('gate-ansarang',[right,(-1.988,-23.203),(14.82,-21.1)],1.72)]
wall_records=[]
for route,points,top in routes:
 for j,(a,b) in enumerate(zip(points,points[1:])):
  length=math.dist(a,b);angle=math.atan2(b[1]-a[1],b[0]-a[0]);co=math.cos(angle);si=math.sin(angle);nm=f'Forecourt.wall.{route}.{j}'
  g.set_transform(lambda p,a=a,co=co,si=si:(a[0]+co*p[0]-si*p[1],a[1]+si*p[0]+co*p[1],p[2]))
  foot=min(height(a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t) for t in np.linspace(0,1,24))-.10
  # Wall cores overlap at corners by 30mm; no freestanding gap or kink stub.
  g.box(nm+'.core',(length/2,0,(foot+top)/2),(length+.06,.40,top-foot),earth)
  rows=math.ceil((top-foot)/.205);rh=(top-foot)/rows
  for side in (-1,1):
   for row in range(rows):
    x=0
    while x<length-.01:
     w=min(length-x,rng.uniform(.26,.49));g.rock(nm+'.rubble',(x+w/2,side*.216,foot+(row+.5)*rh),(max(.035,w-.014),.10,rh*.90),stone,rng);x+=w
  count=math.ceil(length/.195)
  for i in range(count):
   x=(i+.5)*length/count
   for side in (-1,1):
    for k in range(8):
     aa=-math.pi/2+k*math.pi/8;bb=aa+math.pi/8
     pan=lambda t,y:(x+.101*math.sin(t),side*y,top+.065+.065*(1-y/.31)-.028*math.cos(t))
     g.face(nm+'.pan',[pan(aa,0),pan(bb,0),pan(bb,.31),pan(aa,.31)],tile)
     aa=k*math.pi/8;bb=aa+math.pi/8
     cover=lambda t,y:(x+.099+.043*math.cos(t),side*y,top+.09+.065*(1-y/.32)+.043*math.sin(t))
     g.face(nm+'.cover',[cover(aa,0),cover(bb,0),cover(bb,.32),cover(aa,.32)],tile)
    g.rod(nm+'.tile ends',(x+.099,side*.318,top+.108),(x+.099,side*.338,top+.108),.034,end,16)
   for level in range(3):g.rod(nm+'.ridge',(x-length/count*.5,0,top+.18+level*.043),(x+length/count*.5,0,top+.18+level*.043),.038,tile,12)
  wall_records.append({'id':nm,'start':a,'end':b,'coreWidth':.40,'coreTop':top,'base':foot,'overlap':.03})
walls=g.flush();g.BATCHES.clear();g.set_transform(lambda p:p)
for o in walls:
 o['construction_building']='forecourt_wall';o['source_object_name']=o.name
 if o.data.materials[0]==stone:art_uv(o,'stone');component_tints(o,'stone')
 elif o.data.materials[0]==tile:
  # World-metre UVs matching the retained fired ceramic texture scale.
  me=o.data;uv=me.uv_layers.new(name='Ansarang retained PBR')
  for p in me.polygons:
   axes=[a for a in range(3) if a!=int(np.argmax(np.abs(p.normal)))]
   for li in p.loop_indices:uv.data[li].uv=np.array(me.vertices[me.loops[li].vertex_index].co)[axes]/.8
  component_tints(o,'ceramic')
 for mod in o.modifiers:
  if mod.type=='BEVEL':mod.width=.007;mod.segments=2
items.extend(walls)
for o in items:
 o['construction_first']=1;o['construction_last']=99
 if not o.get('source_object_name'):o['source_object_name']=o.name
contract['forecourt']={'nativeBaseSha256':sha(OUT/'ansarang-complete.blend'),'protectedMeshCount':len(protected),'wallRoutes':wall_records,'sitePlan':'site002.jpg','toiletPlanNumber':12,'mainGatePlanNumber':10,'buildingAuthority':'Site002 locations with canonical proportions; individual main gate/toilet measured elevations were not found. Existing illustrated envelope retained, hidden depth is reconstructed.','wallAuthority':'Manual registration of site002 outer boundary, with new Numaru/Ansarang rectangular wall corrections retained. Corners remain straight segments; wall heights and masonry courses are illustrative reconstruction.','canonicalMainGate':str(ARTROOT/'references/sotdaeulmun/jin_20260914/sotdaeulmun_stone_wall_right_oblique_closed.png'),'canonicalToilet':str(ARTROOT/'화장실.png'),'removedNonCanonicalWindowGrid':removed}
bpy.context.view_layer.update()
assert all(fingerprint(bpy.data.objects[n])==v for n,v in protected.items()),'Protected mesh changed'
(OUT/'connection-contract.json').write_text(json.dumps(contract,ensure_ascii=False,indent=2),encoding='utf8')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'scene.blend'),compress=True)
for o in s.objects:o.select_set(False)
for o in items:o.select_set(True)
bpy.context.view_layer.objects.active=items[0]
bpy.ops.export_scene.gltf(filepath=str(OUT/'crafted-forecourt.glb'),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True,export_extras=True)
report={'nativeSceneSha256':sha(OUT/'scene.blend'),'glbSha256':sha(OUT/'crafted-forecourt.glb'),'meshCount':len(items),'protectedMeshesUnchanged':len(protected),'materialGroups':tally,'mappedSurfaces':len(mapped),'wallRuns':wall_records,'referenceGeometry':'canonical and site002 registration; no surveyed elevation claimed'}
(OUT/'forecourt-build-validation.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print('FORECOURT BUILT',len(items),'protected',len(protected),tally,flush=True)
