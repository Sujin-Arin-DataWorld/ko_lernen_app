"""Reconstruct the raised gate from the user's exterior/interior photographs.

Photographs govern the elevation and construction; the retained site axes only
locate it. Dimensions below are photographic proportions, not surveyed values.
"""
from pathlib import Path
import ast,bpy,json,hashlib,math,random,sys,numpy as np
from mathutils import Matrix,Vector
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'assets_unused/pending_review/hwalju-blueprint-review/side-connections'
OLD=Path('C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-warm-stone-20260923')
ART=Path('C:/dev/hangulsori/ko_lernen_app/assets_unused/pending_review/personal_hanok_v3/hyeopmun_try03_blueprint_colored.png')
sys.path.insert(0,str(OLD/'tool/hanok_scene'));import reconstruction_geometry as g;import reference_detail_geometry as d
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
for file,names in [('refine_canonical_gates.py',('new_material','pigment','components','art_uv')),('refine_ansarang.py',('component_tints',)),('validate_connections_native.py',('fingerprint',))]:
 for node in ast.parse((Path(__file__).parent/file).read_text(encoding='utf8')).body:
  if isinstance(node,ast.FunctionDef) and node.name in names:exec(compile(ast.Module(body=[node],type_ignores=[]),file,'exec'))
bpy.ops.wm.open_mainfile(filepath=str(OUT/'forecourt-before-photo-gate.blend'));s=bpy.context.scene;bpy.context.view_layer.update()
protected={o.name:fingerprint(o) for o in s.objects if o.type=='MESH' and o.get('construction_building')!='main_gate'}
c=json.loads((OUT/'forecourt-before-photo-gate-contract.json').read_text());bc=c['buildings']['main_gate'];cx,cy=bc['center'];a=bc['angle']
matrix=Matrix.Translation((cx,cy,0))@Matrix.Rotation(a,4,'Z');inv=matrix.inverted()
tr=lambda p:tuple(matrix@Vector(p));g.set_transform(tr)
base_image=bpy.data.images.load(str(ART),check_existing=True);materials={};mapped=[]
regions={'wood':[(.334,.405,.356,.618),(.389,.406,.414,.619),(.425,.409,.449,.617),(.568,.406,.592,.617)],'post':[(.244,.328,.282,.680)],'beam':[(.303,.332,.708,.353)],'stone':[(.192,.728,.286,.756),(.391,.786,.498,.810),(.620,.795,.690,.821)]}
wood=pigment('wood');beam=pigment('beam');post=pigment('post');stone=pigment('stone')
def plain(name,col,rough=.90):
 m=new_material(name);b=m.node_tree.nodes.get('Principled BSDF');b.inputs['Base Color'].default_value=(*col,1);b.inputs['Roughness'].default_value=rough;return m
plaster=plain('Photo gate warm lime plaster',(.70,.64,.49));soffit=plain('Photo gate white lime between rafters',(.82,.79,.67));paper=plain('Photo gate warm hanji backing',(.75,.69,.54));earth=plain('Photo gate ochre mortar',(.32,.25,.16));red=plain('Photo gate faded vermilion frames',(.22,.064,.050));iron=plain('Photo gate old iron',(.055,.045,.032),.6)
iron.node_tree.nodes.get('Principled BSDF').inputs['Metallic'].default_value=.55
tiles=[next(m for m in bpy.data.materials if m.name==f'Ansarang retained V33 main_gate source ceramic {i}') for i in range(6)]
tile_end=plain('Photo gate weathered lime tile end',(.53,.50,.42))
removed=[];retained=[]
for o in list(s.objects):
 if o.type!='MESH' or o.get('construction_building')!='main_gate':continue
 removed.append(o.name);bpy.data.objects.remove(o,do_unlink=True)

P='PhotoGate.';rng=random.Random(929028)
# Two real rooms on either side, with exterior windows and courtyard doors.
def panel_with_opening(name,x0,x1,y,z0,z1,opening,depth=.14):
 if opening:
  u,v,lo,hi=opening
  for xx0,xx1,zz0,zz1 in [(x0,u,z0,z1),(v,x1,z0,z1),(u,v,z0,lo),(u,v,hi,z1)]:
   if xx1>xx0 and zz1>zz0:g.box(name,((xx0+xx1)/2,y,(zz0+zz1)/2),(xx1-xx0,depth,zz1-zz0),plaster)
 else:g.box(name,((x0+x1)/2,y,(z0+z1)/2),(x1-x0,depth,z1-z0),plaster)
def frame(name,x0,x1,y,z0,z1,t=.045):
 for x in (x0,x1):g.box(name+'.stile',(x,y,(z0+z1)/2),(t,.09,z1-z0+t),wood)
 for z in (z0,z1):g.box(name+'.rail',((x0+x1)/2,y,z),(x1-x0,.09,t),beam)
def rubble(name,x0,x1,y,lo,hi):
 # Irregular, tightly packed fieldstones; the core gives the wall real depth.
 rows=9;rowh=(hi-lo)/rows
 for row in range(rows):
  x=x0
  while x<x1-.01:
   width=min(x1-x,rng.uniform(.21,.48));h=rowh*rng.uniform(.88,1.06);mx=x+width/2;mz=lo+(row+.5)*rowh
   ring=[]
   for k in range(8):
    theta=k*math.tau/8+.11;ring.append((mx+math.cos(theta)*max(.025,width-.013)*.5*rng.uniform(.92,1.07),y-.08,mz+math.sin(theta)*h*.5*rng.uniform(.89,1.10)))
   back=[(xx,y+.065,zz) for xx,_,zz in ring];g.face(name,ring,stone);g.face(name,list(reversed(back)),stone)
   for k in range(8):q=(k+1)%8;g.face(name,[ring[k],back[k],back[q],ring[q]],stone)
   x+=width
for side in (-1,1):
 x0,x1=(-5.1,-1.25) if side<0 else (1.25,5.1);mid=(x0+x1)/2
 g.box(P+'wing earth foundation',(mid,0,.12),(x1-x0,2.7,.24),earth)
 g.planks(P+'wing interior floor',x0,x1,-1.2,.68,.43,[wood],axis='X',thick=.075)
 g.planks(P+'courtyard maru',x0,x1,.68,1.80,.43,[wood],axis='X',thick=.075)
 g.box(P+'courtyard ochre plinth',(mid,.82,.20),(x1-x0,1.10,.32),plaster)
 for x in (x0,mid,x1):
  for y in (-1.325,1.325):
   height=3.83 if abs(x)==1.25 else 2.89
   g.rod(P+'frame weathered post',(x,y,.12),(x,y,height),.125,post,14,r2=.116)
   g.rock(P+'post footstone',(x,y,.08),(.34,.36,.16),stone,rng)
  g.box(P+'courtyard maru bracket',(x,1.5,.27),(.13,.18,.30),wood)
 for y in (-1.325,1.325):g.box(P+'wing head beam',(mid,y,2.82),(x1-x0,.24,.22),beam)
 # Both wing returns form the deep white-sided central passage.
 for x in (x0,x1):
  h=3.66 if abs(x)==1.25 else 2.84
  g.box(P+'wing return plaster',(x,0,(h+.24)/2),(.16,2.65,h-.24),plaster)
  for z in (1.63,2.78):g.box(P+'return horizontal tie',(x,0,z),(.20,2.65,.11),beam)
 for bay,(u,v) in enumerate(((x0,mid),(mid,x1))):
  center=(u+v)/2;y=-1.325
  g.box(P+'outside masonry core',(center,y,.835),(v-u,.33,1.55),earth)
  rubble(P+'front irregular fieldstone',u,v,y-.20,.09,1.60)
  g.box(P+'outside stone sill beam',(center,y-.035,1.66),(v-u,.19,.13),beam)
  panel_with_opening(P+'outside plaster',u,v,y,1.69,2.83,(center-.45,center+.45,1.80,2.28))
  frame(P+f'window{side}_{bay}.frame',center-.44,center+.44,y-.095,1.80,2.28)
  g.box(P+f'window{side}_{bay}.hanji',(center,y+.027,2.04),(.80,.015,.40),paper)
  for xx in np.linspace(center-.386,center+.386,25):g.box(P+f'window{side}_{bay}.fine vertical sal',(xx,y-.028,2.04),(.012,.022,.408),wood)
  for zz in np.linspace(1.845,2.235,7):g.box(P+f'window{side}_{bay}.horizontal sal',(center,y-.053,zz),(.795,.032,.020),wood)
  panel_with_opening(P+'inside plaster',u,v,.72,.34,2.83,(center-.46,center+.46,.46,2.40))
  frame(P+'courtyard door frame',center-.46,center+.46,.81,.46,2.40,.065)
  d.lattice(P+f'courtyard door{side}_{bay}',center-.39,center+.39,.76,.48,2.35,wood,paper,leaves=1,solid=.10,reverse=True)
  # Dividing wall and room ceiling give real volume behind each doorway.
  if bay==0:g.box(P+'room partition',(v,-.20,1.53),(.13,1.9,2.46),plaster)
  g.box(P+'room ceiling',(center,-.22,2.69),(v-u-.10,1.75,.045),soffit)
 # Rough end masonry meets the already checked boundary wall.
 x=-5.1 if side<0 else 5.1
 old=g.TRANSFORM;g.set_transform(lambda p,x=x:tr((x+p[1],p[0],p[2])))
 rubble(P+'return fieldstone',-1.325,1.325,-side*.08,.09,1.60);g.set_transform(old)
 # Continuous inner stone apron below the maru, with two step-height courses.
 for j in range(13):g.rock(P+'courtyard apron stones',(x0+(j+.5)*(x1-x0)/13,1.90,.10),((x1-x0)/13+.02,.45,.19),stone,rng)

# Roof underside: white lime spans between long round rafters, with real beams.
for roofidx,(x0,x1,eave,ridge) in enumerate([(-5.55,-.96,3.16,4.23),(.96,5.55,3.16,4.23),(-1.976,1.976,4.02,5.05)]):
 field=g.roof(P+f'roof{roofidx}',(x0,x1,-1.905,1.905),eave,ridge,wood,tiles,tile_end,columns=round((x1-x0)/.195),turn=.14,ridge_turn=.11)
 # Layered curved verge caps and rising ridge end tiles follow the same roof.
 for xx in (x0,x1):
  for sign in (-1,1):
   for j in range(18):
    ya=sign*j/18*1.905;yb=sign*(j+1)/18*1.905
    for layer in range(3):g.rod(P+'roof curved verge caps',(xx,ya,field(xx,ya)+.075+layer*.055),(xx,yb,field(xx,yb)+.075+layer*.055),.055,tiles[(j+layer)%6],10)
  outline=[(-.15,ridge+.24),(-.14,ridge+.49),(-.085,ridge+.61),(0,ridge+.66),(.085,ridge+.61),(.14,ridge+.49),(.15,ridge+.24)]
  for dx in (-.035,.035):g.face(P+'roof ridge end tile',[(xx+dx,yy,zz) for yy,zz in outline],tiles[2])
  for p,q in zip(outline,outline[1:]+outline[:1]):g.face(P+'roof ridge end tile',[(xx-.035,*p),(xx+.035,*p),(xx+.035,*q),(xx-.035,*q)],tiles[2])
 def zroof(y):
  u=abs(y)/1.905
  return ridge-(ridge-eave)*(1-(1-u)**1.55)-.17
 for sign in (-1,1):
  ys=[sign*t for t in np.linspace(0,1.905,14)]
  for ya,yb in zip(ys,ys[1:]):
   g.face(P+'white lime soffit',[(x0,ya,zroof(ya)),(x1,ya,zroof(ya)),(x1,yb,zroof(yb)),(x0,yb,zroof(yb))],soffit)
  for xx in np.linspace(x0+.12,x1-.12,max(8,round((x1-x0)/.26))):
   for ya,yb in zip(ys,ys[1:]):g.rod(P+'exposed curved rafter',(xx,ya,zroof(ya)-.044),(xx,yb,zroof(yb)-.044),.047,wood,10)
 for yy in (-1.28,1.28):g.box(P+'roof supporting purlin',((x0+x1)/2,yy,zroof(yy)-.18),(x1-x0,.18,.21),beam)

# Front lintel stands ahead of the lower door/plaques, leaving a deep passage.
for y,z in [(-1.325,3.70),(1.325,3.70)]:g.box(P+'portal upper transverse beam',(0,y,z),(2.78,.28,.26),beam)
for x in (-1.25,1.25):g.box(P+'portal cross beam',(x,0,3.70),(.25,2.92,.24),beam)
door_y=.65;door_lo=.13;door_hi=2.78;half=1.10
for x in (-1.155,1.155):g.box(P+'entry jamb',(x,door_y,1.455),(.11,.19,2.76),post)
g.box(P+'entry low lintel',(0,door_y,2.85),(2.42,.20,.16),beam)
prefix=P+'entry'
for leaf in (0,1):
 x0,x1=(-1.10,-.018) if leaf==0 else (.018,1.10);pre=prefix+f'.leaf{leaf+1}.'
 for j in range(6):
  width=(x1-x0)/6;xx=x0+(j+.5)*width
  g.box(pre+'aged plank',(xx,door_y,(door_lo+door_hi)/2),(width-.0035,.072,door_hi-door_lo),wood)
 for z in (.46,1.38,2.48):
  g.box(pre+'inside wooden batten',((x0+x1)/2,door_y+.072,z),(x1-x0-.035,.077,.115),beam)
  for xx in (x0+.12,x1-.12):g.rod(pre+'batten nail',(xx,door_y+.112,z),(xx,door_y+.128,z),.012,iron,10)
 for z in (.44,2.49):
  xx=x0+.10 if leaf==0 else x1-.10;g.box(pre+'hinge strap',(xx,door_y-.044,z),(.18,.022,.038),iron)
 g.torus(pre+'small iron pull',((-.22 if leaf==0 else .22),door_y-.060,1.29),.063,.009,iron)
# Five independent raised red signboards, with untouched lettering from photo2.
refs=OUT/'photo-gate-references';refs.mkdir(exist_ok=True)
photo_ids=['546c595d-2c35-45b6-a94b-4fccf5e1ec56','51a79fef-4e00-49de-80f7-2d162fcb56ab','c2c482a4-3e7a-4733-b8c1-b56a4d157940','918e3846-bc7b-4819-96eb-a02d8d51d79b','9c044430-8c30-4617-b98b-7058fa4964d2','37f86c93-cfec-4f18-9e1e-96f902e525c2','5be9b615-ed7c-4bd6-8e42-dc3e86ae674d','f78aacb4-f8b7-48b6-afb8-e1cdd155181e','826370a0-3466-4e2a-9db1-5a70393571dd','e85cb5f4-f12d-430c-9c04-9c1a29ffbbf5','0e023408-b471-4199-9b89-5a195d738279']
reference_records=[]
for i,key in enumerate(photo_ids,1):
 src=Path('C:/Users/vjinn/AppData/Local/Temp')/f'codex-clipboard-{key}.png';dst=refs/f'{i:02d}.png';dst.write_bytes(src.read_bytes());reference_records.append({'file':str(dst.relative_to(OUT)),'sha256':sha(src)})
photo=refs/'02.png';planes=[]
specs=[(-.59,.59,3.64,3.92,[(266,113),(470,106),(474,137),(264,142)]),(-1.12,-.035,3.30,3.61,[(160,167),(352,158),(353,211),(151,221)]),(.035,1.12,3.30,3.61,[(373,160),(581,157),(602,215),(374,214)]),(-1.12,-.035,2.95,3.26,[(151,229),(351,224),(353,280),(141,273)]),(.035,1.12,2.95,3.26,[(377,229),(601,230),(609,278),(379,278)])]
for i,(x0,x1,z0,z1,pixels) in enumerate(specs):
 y=door_y-.025;g.box(P+f'plaque{i}.solid board',((x0+x1)/2,y,(z0+z1)/2),(x1-x0+.065,.065,z1-z0+.05),red)
 for x in (x0-.025,x1+.025):g.box(P+'plaque red frame',(x,y-.045,(z0+z1)/2),(.040,.050,z1-z0+.08),red)
 for z in (z0-.024,z1+.024):g.box(P+'plaque red frame',((x0+x1)/2,y-.045,z),(x1-x0+.08,.05,.04),red)
 ob=g.source_quad(P+f'plaque{i}.photo inscription',[(x0,y-.066,z0),(x1,y-.066,z0),(x1,y-.066,z1),(x0,y-.066,z1)],photo,[pixels[3],pixels[2],pixels[1],pixels[0]],red);planes.append(ob)
for x in (-1.18,1.18):g.box(P+'plaque upright',(x,door_y,3.38),(.075,.13,1.04),red)
# White tablets sit on the front columns; lettering is sampled without editing.
for side,pixels in [(-1,[(326,220),(355,219),(342,326),(316,323)]),(1,[(923,235),(948,239),(952,342),(923,337)])]:
 x=side*1.25;y=-1.463;z0,z1=2.25,2.88
 g.box(P+'white tablet backing',(x,y+.009,(z0+z1)/2),(.20,.045,z1-z0),soffit)
 ob=g.source_quad(P+f'white tablet{side}',[(x-.10,y-.015,z0),(x+.10,y-.015,z0),(x+.10,y-.015,z1),(x-.10,y-.015,z1)],refs/'10.png',[pixels[3],pixels[2],pixels[1],pixels[0]],soffit);planes.append(ob)
# Jittered Voronoi flagstones avoid a tiled rectangular carpet in the passage.
seeds=[Vector((-1.33+j*.64+rng.uniform(-.20,.20),-3.10+row*.52+rng.uniform(-.19,.19))) for row in range(10) for j in range(5)]
for seed in seeds:
 poly=[Vector(p) for p in [(-1.78,-3.40),(1.78,-3.40),(1.10,1.95),(-1.10,1.95)]]
 for other in seeds:
  if other==seed:continue
  normal=other-seed;bound=(other.length_squared-seed.length_squared)/2;result=[]
  for aa,bb in zip(poly,poly[1:]+poly[:1]):
   da=aa.dot(normal)-bound;db=bb.dot(normal)-bound
   if da<=0:result.append(aa)
   if (da<=0)!=(db<=0):result.append(aa+(bb-aa)*(da/(da-db)))
  poly=result
  if not poly:break
 if len(poly)>2:
  center=sum(poly,Vector((0,0)))/len(poly);poly=[tuple(center+(p-center)*.96) for p in poly]
  g.prism(P+'passage irregular paving',poly,-.04,.045+rng.uniform(0,.018),stone)
for j in range(3):g.rock(P+'entry threshold stone',(-.73+j*.73,door_y+.18,.065),(.76,.28,.13),stone,rng)

new=g.flush();g.BATCHES.clear()
for o in new:
 m=o.data.materials[0];kind=next((k for k in ('wood','beam','post','stone') if m==materials.get(k)),None)
 if kind:art_uv(o,kind);component_tints(o,'stone' if kind=='stone' else 'wood')
 elif m in tiles:
  uv=o.data.uv_layers.new(name='Ansarang retained PBR')
  for p in o.data.polygons:
   axes=[a for a in range(3) if a!=int(np.argmax(np.abs(p.normal)))]
   for li in p.loop_indices:uv.data[li].uv=np.array(o.data.vertices[o.data.loops[li].vertex_index].co)[axes]/.8
  component_tints(o,'ceramic')
 for mod in o.modifiers:
  if mod.type=='BEVEL':mod.width=.004;mod.segments=2
for o in new+planes+retained:
 o['construction_building']='main_gate';o['source_object_name']=o.name;o['construction_first']=1;o['construction_last']=99
 o['photo_authority']='User 2026-09-28 photos 1,2,4,5,6,7; photo3 divergent facade not blended into this elevation'
bpy.context.view_layer.update()
assert all(fingerprint(bpy.data.objects[n])==v for n,v in protected.items()),'Non-gate mesh changed'
for door in c['doors']:
 if door['building']=='main_gate':door.update(prefix=prefix,hinges=[tr((-half,door_y,door_lo)),tr((half,door_y,door_lo))],rotationSigns=[-1,1])
c['mainGatePhotographs']={'references':reference_records,'baselineSceneSha256':sha(OUT/'forecourt-before-photo-gate.blend'),'protectedNonGateMeshes':len(protected),'centralClearWidth':2.2,'doorClearHeight':2.65,'doorPlaneY':door_y,'masonryTop':1.60,'fivePlaques':5,'photo3Note':'Facade in photo3 differs from the repeated four exterior windows in photos1,4,5. Not mixed into this reconstruction.','authority':'Elevations reconstructed from user photos, not measured drawings. Original illustration only supplies timber and stone surface language.','reconstructedDetails':['Stone sizes and joints','Hidden room partitions','Exact metric heights and roof curvature']}
c['forecourt']['buildingAuthority']='Gate rebuilt from user photographs1,2,4,5,6,7; canonical surface style only. Toilet follows approved art and site002. Heights are photographic reconstruction.'
(OUT/'connection-contract.json').write_text(json.dumps(c,indent=2),encoding='utf8')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'scene.blend'),compress=True)
items=[o for o in s.objects if o.type=='MESH' and o.get('construction_building') in ('main_gate','toilet','forecourt_wall')]
for o in s.objects:o.select_set(False)
for o in items:o.select_set(True)
bpy.context.view_layer.objects.active=items[0]
bpy.ops.export_scene.gltf(filepath=str(OUT/'crafted-forecourt.glb'),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True,export_extras=True)
report={'nativeSceneSha256':sha(OUT/'scene.blend'),'forecourtSha256':sha(OUT/'crafted-forecourt.glb'),'protectedNonGateMeshes':len(protected),'removedGateObjects':removed,'newGateObjects':len(new)+len(planes),'retainedRetiledRoofObjects':len(retained),'references':reference_records,'canonicalImagesEdited':False,'surveyedElevationClaimed':False}
(OUT/'photo-gate-build-validation.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print('PHOTO GATE REBUILT',len(new)+len(planes),len(retained),'PROTECTED',len(protected),flush=True)
