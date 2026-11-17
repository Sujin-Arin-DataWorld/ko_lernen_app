import bpy,bmesh,sys,json,math,random,hashlib
from pathlib import Path
from mathutils import Vector,noise
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P));import sarang_reference_colour_r3 as c
p=c.p;f=c.f;D=P/'sarang-stone-masonry-r10';D.mkdir(exist_ok=True)
source=P/'sarang-wrap-r9/sarang-wrap-r9.blend';source_sha=p.sha(source);bpy.ops.wm.open_mainfile(filepath=str(source));sc=bpy.context.scene;fixed=c.fixed_scene(sc)
lock=p.read(P/'sarang/geometry-lock.json');original=[sc.objects[n] for n in lock['objects']];before=p.architecture(original)
collection=bpy.data.collections.new('HS10 individual structural dressed stones');sc.collection.children.link(collection)
srcmat=next(m for m in bpy.data.materials if m.get('guardian6')=='stone');materials=[]
palette=['BBA98F','CDBB9F','B9AD97','CCC0A9','B3AA98','C3B195','D2C5AD','BAA387','C1B8A8','CAB89E']
for i,col in enumerate(palette):
 m=srcmat.copy();m.name=f'HS10 dressed stone mineral family {i:02d}';t=m.node_tree
 body=next(n for n in t.nodes if 'R8 distinct dressed stone bodies' in n.label)
 for e in body.color_ramp.elements:e.color=f.rgb(col)
 for n in t.nodes:
  if 'R7 0.85 metre texture repeat' in n.label:n.inputs[3].default_value=1/1.1
  if 'R8 mineral inclusion separation' in n.label:n.inputs[1].default_value=2.0
  if 'R8 mineral pores' in n.label:n.inputs['Distance'].default_value=.0014;n.inputs['Strength'].default_value=.22
  if 'R8 broad chisel variation' in n.label:n.inputs['Distance'].default_value=.004;n.inputs['Strength'].default_value=.22
  if 'R8 dressed edge light' in n.label:n.inputs['Radius'].default_value=.002
 materials.append(m)
records=[];hidden=[]
def seed(name):return int(hashlib.sha256(name.encode()).hexdigest()[:8],16)
def finish_mesh(name,bm,parent,extent):
 rng=random.Random(seed(name));bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
 # Bevel is geometry: the silhouette, corner cuts and joints survive a clay render.
 bmesh.ops.bevel(bm,geom=list(bm.edges),offset=min(.019,min(extent)*.09)*rng.uniform(.82,1.18),segments=3,affect='EDGES',profile=.55)
 bmesh.ops.subdivide_edges(bm,edges=list(bm.edges),cuts=2,use_grid_fill=True)
 bm.normal_update();offset=Vector((rng.random()*20,rng.random()*20,rng.random()*20))
 for v in bm.verts:
  a=noise.noise_vector(v.co*7.5+offset)[0]*.0015
  v.co+=v.normal*a
 bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
 mesh=bpy.data.meshes.new(name);bm.to_mesh(mesh);bm.free();mesh.update()
 o=bpy.data.objects.new(name,mesh);collection.objects.link(o);o.data.materials.append(materials[rng.randrange(len(materials))]);o['construction_parent']=parent;o['stone_geometry']='solid dressed stone with real bevel, clipped corners and surface relief';o['source_dimensions']=list(extent)
 # Flat broad facets preserve chisel planes; densely bevelled edges provide edge light.
 for poly in mesh.polygons:poly.use_smooth=False
 records.append(dict(name=name,source=parent,vertices=len(mesh.vertices),faces=len(mesh.polygons),dimensions=list(o.dimensions),material=o.data.materials[0].name))
 return o
def block(name,lo,hi,parent):
 rng=random.Random(seed(name));lo=Vector(lo);hi=Vector(hi);center=(lo+hi)/2;dim=hi-lo
 bm=bmesh.new();bmesh.ops.create_cube(bm,size=1)
 for v in bm.verts:v.co=Vector((v.co.x*dim.x,v.co.y*dim.y,v.co.z*dim.z))+center
 # Clip selected corners into small broken facets before softening edges.
 for k in range(2):
  signs=Vector((rng.choice([-1,1]),rng.choice([-1,1]),rng.choice([-1,1])));corner=Vector([hi[i] if signs[i]>0 else lo[i] for i in range(3)]);normal=signs.normalized();cut=min(dim)*rng.uniform(.035,.075)
  r=bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.000001,plane_co=corner-normal*cut,plane_no=normal,clear_outer=True,clear_inner=False)
  edges=[e for e in bm.edges if e.is_boundary]
  if edges:bmesh.ops.holes_fill(bm,edges=edges,sides=0)
 return finish_mesh(name,bm,parent,dim)
def hide(o):
 if o.name not in hidden:hidden.append(o.name)
 o.hide_render=True;o.hide_set(True)
def span(label,a,b,y0,y1,z0,z1,row,parent,axis=0):
 rng=random.Random(seed(label));length=b-a;average=.77;count=max(1,round(length/average));weights=[rng.uniform(.82,1.18) for _ in range(count)]
 if row%2 and count>2:weights[0]*=.60;weights[-1]*=1.35
 total=sum(weights);pos=a
 for i,w in enumerate(weights):
  end=pos+length*w/total;gap=.005
  lo=[pos+gap,y0,z0+.003];hi=[end-gap,y1,z1-.003]
  if axis:lo=[y0,pos+gap,z0+.003];hi=[y1,end-gap,z1-.003]
  block(f'HS10 {label} block {i:02d}',lo,hi,parent);pos=end
def perimeter(label,x0,x1,y0,y1,z1,rows,parent):
 depth=.32
 for row in range(rows):
  z0=z1*row/rows;zt=z1*(row+1)/rows
  span(f'{label} front course {row}',x0,x1,y0,y0+depth,z0,zt,row,parent)
  span(f'{label} rear course {row}',x0,x1,y1-depth,y1,z0,zt,row,parent)
  span(f'{label} left course {row}',y0+depth,y1-depth,x0,x0+depth,z0,zt,row,parent,1)
  span(f'{label} right course {row}',y0+depth,y1-depth,x1-depth,x1,z0,zt,row,parent,1)
for o in list(sc.objects):
 if o.name.startswith(('Craft.Sarang dressed foundation','Craft.Numaru dressed foundation','GyeStyle.Sarang irregular stone facing','V25.landing masonry','V25.stair tread','V25.upper entry slab')) or (o.name.startswith('HwaljuFix.') and 'masonry' in o.name):hide(o)
perimeter('main foundation',-.66,10.68,-.70,5.675,1.016,3,'Craft.Sarang dressed foundation')
perimeter('numaru foundation',10.035,15.12,-4.53,5.67,.38,1,'Craft.Numaru dressed foundation')
for label,rect,height,rows,parent in [
 ('left terrace',(-1.31,-.61,-1.28,.30),1.10,3,'HwaljuFix.left terrace masonry 0-0'),
 ('front apron',(-.61,1.81,-1.28,-.69),1.10,3,'HwaljuFix.left front apron masonry 0-0'),
 ('stair landing',(1.81,6.06,-1.29,-.57),1.28,3,'V25.landing masonry 0-0'),
 ('numaru front apron',(10.32,14.76,-5.16,-4.51),.43,1,'HwaljuFix.numaru front apron masonry 0-0'),
 ('numaru inner apron',(9.34,10.32,-5.16,-4.18),.43,1,'HwaljuFix.numaru inner apron masonry 0-0')]:
  x0,x1,y0,y1=rect
  for row in range(rows):span(f'{label} course {row}',x0,x1,y0,y1,row*height/rows,(row+1)*height/rows,row,parent)
# Treads retain the measured rise/run, and are split into real solid stones.
for i in range(1,6):
 o=sc.objects[f'V25.stair tread {i}'];pts=[o.matrix_world@Vector(v) for v in o.bound_box];lo=[min(v[j] for v in pts) for j in range(3)];hi=[max(v[j] for v in pts) for j in range(3)];mid=(lo[0]+hi[0])/2+(.06 if i%2 else -.04)
 for j,(a,b) in enumerate([(lo[0],mid-.004),(mid+.004,hi[0])]):block(f'HS10 stair {i} stone {j}',(a,lo[1],.003),(b,hi[1],hi[2]),o.name)
for i in range(2):
 o=sc.objects[f'V25.upper entry slab {i}'];pts=[o.matrix_world@Vector(v) for v in o.bound_box];lo=[min(v[j] for v in pts) for j in range(3)];hi=[max(v[j] for v in pts) for j in range(3)];block(f'HS10 upper entry solid {i}',lo,hi,o.name)
# Reuse measured wedge outline, but give its edge cuts real depth.
o=sc.objects['V25.stair cheek'];bm=bmesh.new();bm.from_mesh(o.data)
for v in bm.verts:v.co=o.matrix_world@v.co
finish_mesh('HS10 measured solid stair cheeks',bm,o.name,o.dimensions);hide(o)
vis={o.name:o.hide_render for o in original}
def verify_original():
 # Compare original data with the source visibility state, including R9 replacement.
 for n in hidden:
  if n in lock['objects']:sc.objects[n].hide_render=False
 result=p.architecture(original)
 for n,state in vis.items():sc.objects[n].hide_render=state
 assert result==before,(result,before)
 assert p.stage_map('sarang',original)==p.read(P/'sarang/construction-binding.json')
 return result
verify_original();assert c.fixed_scene(sc)==fixed;assert c.preserve_check()
bpy.context.preferences.filepaths.save_version=0;native=D/'sarang-stone-masonry-r10.blend';bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False)
v=dict(source=str(source),sourceSha256=source_sha,native=str(native),nativeSha256=p.sha(native),originalDataPreserved=True,originalSourceState=before,hiddenOriginalStoneObjects=hidden,addedSolidStones=records,lightingExposurePreserved=True,renderComplete=False,userApproved=False,runtimeIntegrated=False,geometryAuthorization='User requested real stone foundation instead of imitation; dimensions and stair rise/run retained in new visual layer')
p.write(D/'verification.json',v)
cam=sc.camera;orig=cam.matrix_world.copy();ortho=cam.data.ortho_scale;sc.render.resolution_x=1400;sc.render.resolution_y=1000
direction=(cam.location-Vector((7,0,3))).normalized();target=Vector((3.9,-.6,1.05));cam.location=target+direction*18;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=5.9
p.write(D/'stone.json',p.render(sc,D,'stone.png',64))
cam.matrix_world=orig;cam.data.ortho_scale=ortho;sc.render.resolution_x=1800;sc.render.resolution_y=1200
p.write(D/'full.json',p.render(sc,D,'full.png',64))
# Matrix restoration can change the last decimal through Euler decomposition.
after_fixed=c.fixed_scene(sc)
assert all(after_fixed[k]==fixed[k] for k in fixed if k!='camera')
assert all(math.isclose(x,y,abs_tol=1e-6,rel_tol=1e-6) for a,b in zip(after_fixed['camera']['matrix'],fixed['camera']['matrix']) for x,y in zip(a,b))
verify_original()
v.update(renderComplete=True,render1And2Preserved=bool(c.preserve_check()),solidStoneCount=len(records),constructionMappingOriginalCount=711,renders={k:p.read(D/(k+'.json')) for k in ['stone','full']});p.write(D/'verification.json',v)
assert p.sha(source)==source_sha;print('R10 SOLID STONE FOUNDATION COMPLETE',flush=True)
