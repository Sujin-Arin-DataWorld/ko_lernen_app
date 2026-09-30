"""Map untouched canonical pigments onto solid gates; replace simplified ironwork.

The original image stays byte-identical. UVs select corresponding clean material
regions, never projecting the whole gate photograph onto a flat facade.
"""
from pathlib import Path
import bpy,bmesh,json,math,random,hashlib,re,sys,numpy as np
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'assets_unused/pending_review/hwalju-blueprint-review/side-connections'
OLD=Path('C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-warm-stone-20260923')
SOURCE=OLD/'assets_unused/pending_review/ildu_spatial_preservation_20260922/existing-estate-v36'
ART=Path('C:/dev/hangulsori/ko_lernen_app/assets_unused/pending_review/personal_hanok_v3/hyeopmun_try03_blueprint_colored.png')
sys.path.insert(0,str(OLD/'tool/hanok_scene'));import reconstruction_geometry as g
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(OUT/'structure-base.blend'));s=bpy.context.scene
contract=json.loads((OUT/'connection-contract.json').read_text(encoding='utf8'))
# The warehouse-side photograph puts this wall just below the gate eaves.
# Keep the existing stones at their natural proportions: raise the old courses,
# extend the earth core down to the old footing, and build the missing courses.
wall_raise=.88
left_wall=[o for o in s.objects if o.type=='MESH' and o.get('construction_building')=='left_changgo' and 'wall to sarang' in o.name]
for o in left_wall:
 if 'earth core' in o.name:
  for v in o.data.vertices:
   v.co.z=.02+(v.co.z-.02)*(3.06-.02)/(2.18-.02)
 else:o.location.z+=wall_raise
start=Vector((-2.092,3.802));stop=Vector((-.08,3.802));direction=(stop-start).normalized();normal=Vector((-direction.y,direction.x));length=(stop-start).length
rng=random.Random(92845);stone_mats=[bpy.data.materials[f'Jung warm fieldstone {i}'] for i in range(5)]
g.set_transform(lambda p:(start.x+direction.x*p[0]+normal.x*p[1],start.y+direction.y*p[0]+normal.y*p[1],p[2]))
for side in (-1,1):
 for row in range(4):
  x=0
  while x<length-.01:
   width=min(length-x,rng.uniform(.22,.43))
   g.rock('ConnectionLeft.high wall lower fieldstone',(x+width/2,side*.205,.13+row*.22),(max(.035,width-.012),.10,.218),stone_mats[rng.randrange(5)],rng);x+=width
for x in (0,length):
 for row in range(4):g.rock('ConnectionLeft.high wall lower end',(x,0,.13+row*.22),(.09,.39,.218),stone_mats[rng.randrange(5)],rng)
lower_courses=g.flush();g.BATCHES.clear();g.set_transform(lambda p:p)
for o in lower_courses:
 for k,v in {'source_object_name':o.name,'construction_building':'left_changgo','construction_first':1,'construction_last':99}.items():o[k]=v
contract['leftSarangWall']={'earthTop':3.06,'copingTop':3.284,'footing':.02,'riseFromPrevious':wall_raise,'gateEave':3.38,'construction':'Original stone sizes retained; four lower masonry courses added, core extended to its original footing.','authority':'User warehouse-court photograph: right side of left gate joins Sarang below eaves. Height is a photographic reconstruction, not a surveyed dimension.'}
gates=[o for o in s.objects if o.type=='MESH' and o.get('construction_building') in ('left_changgo','right_ansarang')]
base_image=bpy.data.images.load(str(ART),check_existing=True)
regions={'wood':[(.334,.405,.356,.618),(.389,.406,.414,.619),(.425,.409,.449,.617),(.568,.406,.592,.617),(.604,.406,.631,.619),(.642,.406,.665,.619)],
 'post':[(.244,.328,.282,.68)],'beam':[(.303,.332,.708,.353)],
 'tile':[(.475,.174,.481,.181),(.552,.177,.558,.184),(.431,.174,.437,.181)],
 'stone':[(.192,.728,.286,.756),(.391,.786,.498,.810),(.620,.795,.690,.821)]}
materials={}
def new_material(name):
 m=bpy.data.materials.new(name);m.use_nodes=True;n=m.node_tree.nodes;l=m.node_tree.links;n.clear();bs=n.new('ShaderNodeBsdfPrincipled');bs.name='Principled BSDF';out=n.new('ShaderNodeOutputMaterial');l.new(bs.outputs[0],out.inputs[0]);return m
def pigment(kind):
 if kind in materials:return materials[kind]
 m=new_material('Canonical gate '+kind+' pigment');n=m.node_tree.nodes;l=m.node_tree.links
 bs=n.get('Principled BSDF');bs.inputs['Roughness'].default_value=.86;bs.inputs['Specular IOR Level'].default_value=.22
 uv=n.new('ShaderNodeUVMap');uv.uv_map='Canonical gate pigment'
 tex=n.new('ShaderNodeTexImage');tex.image=base_image;tex.extension='EXTEND';l.new(uv.outputs[0],tex.inputs[0]);l.new(tex.outputs['Color'],bs.inputs['Base Color'])
 m['artworkSource']=str(ART);m['unalteredImageSha256']=sha(ART);m['surfaceKind']=kind;m.use_backface_culling=False
 materials[kind]=m;return m
def components(me):
 parent=list(range(len(me.vertices)))
 def find(i):
  while parent[i]!=i:parent[i]=parent[parent[i]];i=parent[i]
  return i
 for e in me.edges:
  a,b=map(find,e.vertices);parent[b]=a
 groups={}
 for v in me.vertices:groups.setdefault(find(v.index),[]).append(v.index)
 return groups,find
# Some inherited approach meshes batch several separate stones. Seat each
# connected stone against the evaluated grade, not the batch bounding box.
bpy.context.view_layer.update()
terrain=bpy.data.objects['ConnectionSite.continuous earth'].evaluated_get(bpy.context.evaluated_depsgraph_get())
seated=[]
for o in gates:
 if o.get('construction_building')!='left_changgo' or '.finish.approach' not in o.name:continue
 groups,_=components(o.data)
 for ids in groups.values():
  points=[o.matrix_world@o.data.vertices[i].co for i in ids];center=sum(points,Vector())/len(points)
  hit,location,_,_=terrain.ray_cast(Vector((center.x,center.y,20)),Vector((0,0,-1)))
  assert hit
  dz=location.z+.035-max(p.z for p in points)
  delta=o.matrix_world.to_3x3().inverted()@Vector((0,0,dz))
  for i in ids:o.data.vertices[i].co+=delta
  seated.append({'object':o.name,'ground':float(location.z),'shift':float(dz)})
contract['leftApproachSeating']=seated
mapped=[]
def art_uv(o,kind):
 me=o.data;uv=me.uv_layers.get('Canonical gate pigment') or me.uv_layers.new(name='Canonical gate pigment');groups,find=components(me)
 points=np.array([v.co[:] for v in me.vertices]);rng=random.Random(o.name);frames={}
 for root,ids in groups.items():
  cloud=points[ids];center=cloud.mean(axis=0);values,basis=np.linalg.eigh((cloud-center).T@(cloud-center));long=basis[:,2]
  if long[np.argmax(abs(long))]<0:long=-long
  rect=rng.choice(regions[kind]);frames[root]=(center,long,basis[:,1],basis[:,0],cloud,rect)
 for p in me.polygons:
  center,long,a,b,cloud,rect=frames[find(p.vertices[0])];normal=np.array(p.normal)
  if abs(normal@long)>.8:
   across=a;along=b
  else:along=long;across=a if abs(normal@a)<abs(normal@b) else b
  aa=(cloud-center)@along;bb=(cloud-center)@across
  for li in p.loop_indices:
   co=points[me.loops[li].vertex_index]-center
   u=float(np.clip((co@across-bb.min())/max(np.ptp(bb),1e-6),0,1));v=float(np.clip((co@along-aa.min())/max(np.ptp(aa),1e-6),0,1))
   if kind in ('beam','stone','tile'):u,v=v,u
   x0,y0,x1,y1=rect;uv.data[li].uv=(x0+u*(x1-x0),1-y1+v*(y1-y0))
 me.uv_layers.active=uv;uv.active_render=True
 # Discard donor vertex tint so the canonical pigment is not multiplied twice.
 for attr in list(me.color_attributes):me.color_attributes.remove(attr)
 me.materials.clear();me.materials.append(pigment(kind));mapped.append({'object':o.name,'kind':kind,'components':len(groups)})
for o in gates:
 name=o.name;mat=o.data.materials[0].name.lower()
 if '.door.' in name and any(k in name for k in ('.iron ring','.iron boss')):
  bpy.data.objects.remove(o,do_unlink=True);continue
 if 'walnut' in mat or 'plank' in mat or 'lining timber' in mat:
  kind='post' if '.frame.post' in name else 'beam' if any(k in name for k in ('lintel','threshold','purlin','back rail','fascia')) else 'wood'
  art_uv(o,kind)
 # Retain the baked ceramic surface, as on the adjoining Ansarang roof.
 # Projecting tiny artwork swatches onto disconnected tile quads produced
 # an artificial checker pattern. Real overlapping geometry carries seams.
 elif ('ceramic' in mat or 'giwa' in mat) and 'ends' not in mat:pass
 elif 'fieldstone' in mat or 'granite' in mat:art_uv(o,'stone')

iron=new_material('Craft forged iron');bs=iron.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(.042,.038,.029,1);bs.inputs['Metallic'].default_value=.65;bs.inputs['Roughness'].default_value=.60
for gate in contract['gates']:
 ident=gate['id'];cx,cy=gate['center'];angle=0;c=math.cos(angle);sn=math.sin(angle)
 g.set_transform(lambda p,c=c,sn=sn,cx=cx,cy=cy:(cx+c*p[0]-sn*p[1],cy+sn*p[0]+c*p[1],p[2]))
 z=gate['doorBottom']+gate['doorHeight']*.48;radius=.071 if ident=='left_changgo' else .061
 for leaf,sign in ((1,-1),(2,1)):
  x=sign*(radius+.027);prefix=f'V27.{ident}.door.leaf{leaf}.craft'
  # Scalloped forged escutcheon, with solid edge, raised border and pin.
  poly=[]
  for i in range(32):
   t=math.tau*i/32;r=1+.12*math.cos(8*t);poly.append((x+math.cos(t)*.047*r,-.027,z+radius*.92+math.sin(t)*.065*r))
  g.face(prefix+' escutcheon',poly,iron);g.face(prefix+' escutcheon',[(a,b+.008,c) for a,b,c in reversed(poly)],iron)
  for a,b in zip(poly,poly[1:]+poly[:1]):
   g.face(prefix+' escutcheon',[a,b,(b[0],b[1]+.008,b[2]),(a[0],a[1]+.008,a[2])],iron)
   g.rod(prefix+' forged edge',a,b,.0017,iron,6)
  g.rod(prefix+' hinge boss',(x,-.027,z+radius),(x,-.053,z+radius),.015,iron,16)
  # Smooth torus, rather than a necklace of disconnected hexagonal rods.
  for i in range(48):
   a=math.tau*i/48;b=math.tau*(i+1)/48
   for j in range(10):
    q=math.tau*j/10;r=math.tau*(j+1)/10
    def pt(t,p):return (x+(radius+.0085*math.cos(p))*math.cos(t),-.061+.0085*math.sin(p),z+(radius+.0085*math.cos(p))*math.sin(t))
    g.face(prefix+' ring',[pt(a,q),pt(b,q),pt(b,r),pt(a,r)],iron)
  for dz in (-.035,.065):g.rod(prefix+' rivet',(x,-.03,z+radius+dz),(x,-.034,z+radius+dz),.004,iron,10)
new=g.flush();g.BATCHES.clear();g.set_transform(lambda p:p)
for o in new:
 for mod in list(o.modifiers):o.modifiers.remove(mod)
 for p in o.data.polygons:p.use_smooth=(' ring' in o.name or 'boss' in o.name)
 ident='left_changgo' if 'left_changgo' in o.name else 'right_ansarang'
 for k,v in {'source_object_name':o.name,'construction_building':ident,'construction_first':4,'construction_last':99,'canonical_detail':True}.items():o[k]=v

# Latest marked image resolves the anchor: OUTER front corner of the Numaru
# plinth, inside the outer hwalju. The previous left-corner reading was wrong.
# This wall stays straight and its end meets the corner timber/stone footing.
def garden_x(y):return 14.82
wall_runs=[((garden_x(-4.10),-4.10),(garden_x(-12.8),-12.8)),((garden_x(-15.6),-15.6),(garden_x(-21.1),-21.1))]
opening_x=garden_x(-14.2)
earthmat=new_material('Craft garden ochre joints')
earthmat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.33,.225,.12,1)
earthmat.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=1
stonemat=bpy.data.materials.new('Craft garden fieldstone');tilemat=bpy.data.materials['Charcoal grey giwa 2']
endmat=new_material('Craft garden pale tile noses');endmat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.58,.50,.36,1)
endmat.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.88
rng=random.Random(2814)
# Independent courtyard enclosure, NOT a wall ending in the house. Site002
# original pixels (1476,850),(1907,885),(1888,1150) register to approx
# (28.787,.407),(29.512,-21.093),(16.281,-21.596). Use the user's straight
# rectangular enclosure and retain the marked Numaru anchor and open walk.
enclosure_runs=[((23.25,.083),(29.5,.083)),((29.5,.083),(29.5,-21.1)),((29.5,-21.1),(14.82,-21.1))]
wall_sections=[(a,b,1.22) for a,b in wall_runs]+[(a,b,2.24) for a,b in enclosure_runs]
for wi,(start,stop,top) in enumerate(wall_sections):
 length=math.dist(start,stop);angle=math.atan2(stop[1]-start[1],stop[0]-start[0]);c=math.cos(angle);sn=math.sin(angle)
 g.set_transform(lambda p,c=c,sn=sn,a=start:(a[0]+c*p[0]-sn*p[1],a[1]+sn*p[0]+c*p[1],p[2]))
 base=.005;nm=f'ConnectionGarden.wall{wi+1}';rows=round(top/.195);row_height=top/rows
 g.box(nm+'.ochre core',(length/2,0,(base+top)/2),(length,.37,top-base),earthmat)
 for side in (-1,1):
  for row in range(rows):
   x=0
   while x<length-.01:
    width=min(length-x,rng.uniform(.24,.48));h=.16*rng.uniform(.8,1.08)
    g.rock(nm+'.fieldstone',(x+width/2,side*.20,row_height*(row+.5)),(width-.015,.09,h),stonemat,rng);x+=width
 # Alternating concave pans, convex covers, overhanging ends and three ridges.
 count=round(length/.195)
 for i in range(count):
  x=(i+.5)*length/count
  for side in (-1,1):
   for k in range(8):
    a=-math.pi/2+k*math.pi/8;b=-math.pi/2+(k+1)*math.pi/8
    def pan(t,y):return (x+.101*math.sin(t),side*y,top+.065+.065*(1-y/.31)-.028*math.cos(t))
    g.face(nm+'.pan',[pan(a,0),pan(b,0),pan(b,.31),pan(a,.31)],tilemat)
   for j in range(8):
    a=j*math.pi/8;b=(j+1)*math.pi/8
    def cover(t,y):return(x+.099+.043*math.cos(t),side*y,top+.09+.065*(1-y/.32)+.043*math.sin(t))
    g.face(nm+'.cover',[cover(a,0),cover(b,0),cover(b,.32),cover(a,.32)],tilemat)
   g.rod(nm+'.tile noses',(x+.099,side*.318,top+.108),(x+.099,side*.338,top+.108),.034,endmat,16)
  for level in range(3):g.rod(nm+'.layered ridge',(x-length/count*.49,0,top+.18+level*.043),(x+length/count*.49,0,top+.18+level*.043),.038,tilemat,12)
 for end in (0,length):
  for row in range(rows):g.rock(nm+'.end stones',(end,0,row_height*(row+.5)),(.08,.38,.18),stonemat,rng)
  for level in range(3):g.rod(nm+'.turned end cap',(end,-.28,top+.06+level*.038),(end,0,top+.17+level*.038),.026,tilemat,12);g.rod(nm+'.turned end cap',(end,0,top+.17+level*.038),(end,.28,top+.06+level*.038),.026,tilemat,12)
g.set_transform(lambda p:p)
# A low irregular stone lip and bordering stones, with no posts or gate leaf.
for i in range(7):
 y=-13.0-i*.40;g.rock('ConnectionGarden.open path stone lip',(garden_x(y),y,.04),(.34,.41,.10),stonemat,rng)
for y in (-12.95,-15.45):
 for i in range(7):
  x=opening_x+.45+i*.43;z=.015+.12*max(0,min(1,(x-19)/2))
  g.rock('ConnectionGarden.path edging',(x,y,z+.05),(.44,.18,.12),stonemat,rng)
garden=g.flush();g.BATCHES.clear()
for o in garden:
 for m in o.modifiers:m.width=.005;m.segments=2
 for k,v in {'source_object_name':o.name,'construction_building':'connection_garden','construction_first':1,'construction_last':99}.items():o[k]=v
 if o.data.materials[0]==stonemat:art_uv(o,'stone')
contract['openForecourtConnection']={'gateOnRoute':False,'openingWidth':2.8,'entryBay':'right fourth bay and end post','openingCenter':[opening_x,-14.2],'route':[[11.3,-14.2,0],[opening_x,-14.2,0],[20.5,-14.2,.10]],'gardenWallRuns':wall_runs,'previousGardenWallX':17.1,'numaruFrontFoundationY':-4.539,'wallStartY':-4.10,'geometryAuthority':'Latest user marked screenshot is authoritative: attach at the OUTER front Numaru plinth corner inside the outer hwalju, not the inner/left corner. The wall is straight. The EBS still governs the rightmost-bay sightline through the doorless opening. Heights remain photo reconstruction.'}
contract.pop('rightWallReturn',None)
contract['ansarangCourtyardEnclosure']={'joinsAnsarangBuilding':False,'shape':'independent rectangular courtyard with separate stepped gate and doorless opening','outerAxes':{'west':14.82,'east':29.5,'north':.083,'south':-21.1},'newOuterRuns':enclosure_runs,'preservedOpenRouteY':-14.2,'source':'site002.jpg','manualPixelLandmarks':[[1476,850],[1907,885],[1888,1150]],'registeredLandmarks':[[28.787,.407],[29.512,-21.093],[16.281,-21.596]],'authority':'Latest user correction explicitly requires an enclosing square courtyard rather than a wall joined to Ansarang. The original site002 boundary places the rear/east boundary beyond the building; axes are orthogonalized from manual registration, not surveyed dimensions.'}
(OUT/'connection-contract.json').write_text(json.dumps(contract,ensure_ascii=False,indent=2),encoding='utf8')

# Source PBR for small remaining parts, with a unique material per selected set.
mapping=json.loads((SOURCE/'realtime-delivery.json').read_text())['materialMapping'];converted={}
gates=[o for o in s.objects if o.type=='MESH' and o.get('construction_building') in ('left_changgo','right_ansarang','connection_garden')]
for o in gates:
 m=o.data.materials[0]
 if m in materials.values() or m in (iron,earthmat,endmat):continue
 name=re.sub(r'\.\d{3}$','',m.name)
 if name.startswith('Charcoal grey giwa '):name=name.replace('Charcoal grey giwa ','Jung dark weathered giwa ')
 if name not in mapping:raise ValueError(name)
 span=np.array(mapping[name]['textureSpanMetres']);me=o.data;uv=me.uv_layers.get('Gate realtime') or me.uv_layers.new(name='Gate realtime')
 if me.uv_layers.get('Reference timber grain'):
  for i in range(len(me.loops)):uv.data[i].uv=np.array(me.uv_layers['Reference timber grain'].data[i].uv)/span
 else:
  for p in me.polygons:
   axes=[a for a in range(3) if a!=int(np.argmax(np.abs(p.normal)))]
   for li in p.loop_indices:uv.data[li].uv=np.array(me.vertices[me.loops[li].vertex_index].co)[axes]/span
 if name not in converted:
  mat=m.copy();mat.name='Gate retained '+name;n=mat.node_tree.nodes;l=mat.node_tree.links;n.clear();bs=n.new('ShaderNodeBsdfPrincipled');out=n.new('ShaderNodeOutputMaterial');l.new(bs.outputs[0],out.inputs[0]);un=n.new('ShaderNodeUVMap');un.uv_map=uv.name;idx=list(mapping).index(name)
  for ch in ('color','normal','roughness'):
   tex=n.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(SOURCE/'textures'/f'{idx:02d}-{ch}.png'),check_existing=True)
   if ch!='color':tex.image.colorspace_settings.name='Non-Color'
   l.new(un.outputs[0],tex.inputs[0])
   if ch=='normal':
    nm=n.new('ShaderNodeNormalMap');l.new(tex.outputs[0],nm.inputs['Color']);l.new(nm.outputs[0],bs.inputs['Normal'])
   else:l.new(tex.outputs[0],bs.inputs['Base Color' if ch=='color' else 'Roughness'])
  converted[name]=mat
 me.materials.clear();me.materials.append(converted[name])
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'scene.blend'),compress=True)
import shutil
shutil.copyfile(OUT/'scene.blend',OUT/'gate-refined.blend')
for o in s.objects:o.select_set(False)
for o in gates:o.hide_set(False);o.hide_render=False;o.select_set(True)
bpy.context.view_layer.objects.active=gates[0]
bpy.ops.export_scene.gltf(filepath=str(OUT/'crafted-gates.glb'),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True,export_extras=True)
report={'canonicalImage':str(ART),'canonicalSha256':sha(ART),'sourceImageEdited':False,'uvRegionsNormalized':regions,'mappedSurfaces':mapped,'newIronworkMeshes':len(new),'gateMeshes':len(gates),'sceneSha256':sha(OUT/'scene.blend'),'gateGlbSha256':sha(OUT/'crafted-gates.glb'),'openingPostAndRoofDimensionsChanged':False}
(OUT/'canonical-detail-validation.json').write_text(json.dumps(report,indent=2),encoding='utf8');print('CANONICAL GATES COMPLETE',len(gates),len(mapped),len(new),flush=True)
