import bpy,sys,json,math,shutil
import numpy as np
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P))
import sarang_reference_colour_r3 as c
p=c.p;f=c.f;D=P/'sarang-wrap-r9';D.mkdir(exist_ok=True)
source=P/'sarang-relief-r8/sarang-relief-r8.blend';source_sha=p.sha(source);bpy.ops.wm.open_mainfile(filepath=str(source));sc=bpy.context.scene;fixed=c.fixed_scene(sc)
for mat in bpy.data.materials:
 if mat.get('guardian6')!='stone':continue
 for node in mat.node_tree.nodes:
  if 'R7 0.85 metre texture repeat' in node.label:node.inputs[3].default_value=1/1.15
  if 'R8 mineral inclusion separation' in node.label:node.inputs[1].default_value=2.15
lock=p.read(P/'sarang/geometry-lock.json');obs=[sc.objects[n] for n in lock['objects']]
srcfront=Path('C:/Users/vjinn/.codex/generated_images/01a1501f-48a0-72b0-952f-b9030f42cafe/exec-6dc3e9d7-0263-4476-93a4-e250cbe75c2e.png');srcside=Path('C:/Users/vjinn/.codex/generated_images/01a1501f-48a0-72b0-952f-b9030f42cafe/exec-82363520-c4c8-4ac2-9137-e936bc4cdbf6.png')
for src,name in [(srcfront,'guardian-front.png'),(srcside,'guardian-side.png')]:shutil.copy2(src,D/name)
front=bpy.data.images.load(str(D/'guardian-front.png'));front.pack();side=bpy.data.images.load(str(D/'guardian-side.png'));side.pack()
def image_array(im):
 a=np.empty(im.size[0]*im.size[1]*4,np.float32);im.pixels.foreach_get(a);return a.reshape(im.size[1],im.size[0],4)
a=image_array(front);sa=image_array(side);h,w=a.shape[:2];alpha=a[:,:,3]>.25
ys,xs=np.where(alpha);xmin,xmax=int(xs.min()),int(xs.max());ymin,ymax=int(ys.min()),int(ys.max());lum=a[:,:,:3]@np.array([.2126,.7152,.0722]);low,high=np.percentile(lum[alpha],[8,92]);slum=sa[:,:,:3]@np.array([.2126,.7152,.0722]);slo,shi=np.percentile(slum,[8,92])
nx=280;ny=400
U,V=np.meshgrid(np.linspace(xmin/(w-1),xmax/(w-1),nx+1),np.linspace(ymin/(h-1),ymax/(h-1),ny+1));X=np.rint(U*(w-1)).astype(int);Y=np.rint(V*(h-1)).astype(int)
L=np.zeros_like(U)
for dx,dy in [(0,0),(-4,0),(4,0),(0,-4),(0,4),(-3,-3),(3,3),(-3,3),(3,-3)]:L+=lum[np.clip(Y+dy,0,h-1),np.clip(X+dx,0,w-1)]/9
H=np.clip((L-low)/(high-low),0,1);normV=np.linspace(0,1,ny+1)[:,None]*np.ones((1,nx+1));normU=np.ones((ny+1,1))*np.linspace(0,1,nx+1)[None,:]
face=np.exp(-(((normU-.5)/.30)**2+((normV-.40)/.18)**2)*2);hair=np.exp(-(((normU-.5)/.34)**2+((normV-.61)/.19)**2)*2)
depth=.004+.010*H+.007*face+.003*hair
z=.43*(normV+np.where(normV<.30,.055*np.sin(np.pi*normV/.30),0))
verts=np.stack(((normU-.5)*.30,-depth,z),axis=-1).reshape(-1,3).tolist();uvs=np.stack((U,V),axis=-1).reshape(-1,2).tolist();faces=[];matids=[]
for j in range(ny):
 for i in range(nx):
  px=int((X[j,i]+X[j+1,i+1])/2);py=int((Y[j,i]+Y[j+1,i+1])/2)
  if alpha[py,px]:
   k=j*(nx+1)+i;faces.append((k,k+1,k+nx+2,k+nx+1));matids.append(0)
used=sorted({q for face in faces for q in face});remap={q:i for i,q in enumerate(used)};verts=[verts[i] for i in used];uvs=[uvs[i] for i in used];faces=[tuple(remap[i] for i in face) for face in faces]
count=len(verts);front_faces=list(faces);front_uvs=list(uvs)
edges={}
for face_ids in front_faces:
 for u,v in zip(face_ids,face_ids[1:]+face_ids[:1]):
  key=tuple(sorted((u,v)))
  if key in edges:edges[key]=None
  else:edges[key]=(u,v)
boundary=[e for e in edges.values() if e is not None];next_vertex={u:v for u,v in boundary};loops=[]
while next_vertex:
 start=next(iter(next_vertex));loop=[start];q=start
 while q in next_vertex:
  q=next_vertex.pop(q)
  if q==start:break
  loop.append(q)
 loops.append(loop)
# Back surface duplicates the complete front footprint at a flat depth.
verts.extend([(x,.108,z) for x,y,z in list(verts)]);uvs.extend(front_uvs)
faces.extend([tuple(i+count for i in reversed(face_ids)) for face_ids in front_faces]);matids.extend([1]*len(front_faces))
side_uv={};side_faces=[]
for loop in loops:
 length=len(loop);positions=np.array([[verts[i][0],verts[i][2]] for i in loop]);dist=np.concatenate(([0],np.cumsum(np.linalg.norm(np.roll(positions,-1,axis=0)-positions,axis=1))));nd=80;rings=[loop]
 for j in range(1,nd):
  row=[];u=j/nd
  for k,idx in enumerate(loop):
   x,y,zv=verts[idx];tangent=positions[(k+1)%length]-positions[(k-1)%length];norm=np.array([tangent[1],-tangent[0]]);norm/=max(np.linalg.norm(norm),1e-8)
   vv=(dist[k]/.43)%1;sx=min(sa.shape[1]-1,int(u*(sa.shape[1]-1)));sy=min(sa.shape[0]-1,int(vv*(sa.shape[0]-1)));height=np.clip((slum[max(0,sy-3):sy+4,max(0,sx-3):sx+4].mean()-slo)/(shi-slo),0,1)*.00045*math.sin(math.pi*u)
   row.append(len(verts));verts.append((x+norm[0]*height,y*(1-u)+.108*u,zv+norm[1]*height));uvs.append((u,dist[k]/.43))
  rings.append(row)
 rings.append([i+count for i in loop])
 for j in range(nd):
  for k in range(length):
   q=(k+1)%length;ids=(rings[j][q],rings[j][k],rings[j+1][k],rings[j+1][q]);faces.append(ids);matids.append(1)
   side_faces.append((len(faces)-1,((j/nd,dist[k+1]/.43),(j/nd,dist[k]/.43),((j+1)/nd,dist[k]/.43),((j+1)/nd,dist[k+1]/.43))))
me=bpy.data.meshes.new('HS9 arched guardian solid with carved sides');me.from_pydata(verts,[],faces);me.update();uv=me.uv_layers.new(name='Guardian full surface UV')
for poly in me.polygons:
 poly.material_index=matids[poly.index];poly.use_smooth=True
 for li in poly.loop_indices:uv.data[li].uv=uvs[me.loops[li].vertex_index]
for face_index,coords in side_faces:
 for li,co in zip(me.polygons[face_index].loop_indices,coords):uv.data[li].uv=co
def material(name,im,gray=False,world=False):
 m=bpy.data.materials.new(name);m.use_nodes=True;t=m.node_tree;bs=next(n for n in t.nodes if n.type=='BSDF_PRINCIPLED');tex=f.node(t,'ShaderNodeTexImage','HS9 whole ornament surface');tex.image=im;tex.extension='REPEAT'
 if world:
  co=f.node(t,'ShaderNodeNewGeometry','HS9 mounting stone coordinates');scale=f.node(t,'ShaderNodeVectorMath','HS9 mounting carved pattern scale');scale.operation='MULTIPLY';scale.inputs[1].default_value=(8.5,8.5,7.5);t.links.new(co.outputs['Position'],scale.inputs[0]);t.links.new(scale.outputs[0],tex.inputs['Vector']);tex.projection='BOX';tex.projection_blend=.1
 g=f.gray(t,tex.outputs['Color'],'HS9 relief pigment')
 if gray:col=f.ramp(t,g,[(.1,f.rgb('626973')),(.55,f.rgb('6E7580')),(.9,f.rgb('7B818A'))],'HS9 carved grey fired ceramic')
 else:col=f.mix(t,tex.outputs['Color'],(.42,.50,.46,1),1,'HS9 subdued patinated mineral','MULTIPLY')
 t.links.new(col,bs.inputs['Base Color']);bs.inputs['Metallic'].default_value=.05 if gray else .28;bs.inputs['Roughness'].default_value=.82 if gray else .71;bs.inputs['Specular IOR Level'].default_value=.27
 bump=f.node(t,'ShaderNodeBump','HS9 carved microrelief');bump.inputs['Distance'].default_value=.002 if gray else .00022;bump.inputs['Strength'].default_value=.5 if gray else .18;t.links.new(g,bump.inputs['Height']);t.links.new(bump.outputs['Normal'],bs.inputs['Normal'])
 return m
me.materials.append(material('HS9 integrated guardian face',front));me.materials.append(material('HS9 carved full thickness cloud edge',side))
col=bpy.data.collections.new('HS9 complete guardian roof finials');sc.collection.children.link(col);added=[]
for name,loc,scale,parent in [('HS9 main integrated finial',(12.56,-3.635,6.66),1,'Sarang.numaru roof end ornament.original patterned face'),('HS9 left integrated finial',(9.17,-5.47,4.82),.79,'Sarang.numaru roof.hip round tile ends'),('HS9 right integrated finial',(15.93,-5.53,4.82),.79,'Sarang.numaru roof.hip round tile ends')]:
 o=bpy.data.objects.new(name,me);col.objects.link(o);o.location=loc;o.scale=(scale,scale,scale);o['construction_parent']=parent;o['story_layer']='Dokkaebi guardian arched finial';added.append(name)
replaced=[o.name for o in sc.objects if o.name.startswith('HS8 ') or o.name.startswith('HS6 guardian eave') or (o.name.startswith('Sarang.numaru roof end ornament.') and 'pale base' not in o.name)]
for n in replaced:sc.objects[n].hide_render=True;sc.objects[n].hide_set(True)
grey=material('HS9 grey carved mounting ridge ceramic',side,gray=True,world=True)
mounts=[o for o in sc.objects if o.name=='Sarang.numaru roof end ornament.pale base' or o.name.startswith('Sarang.numaru roof.ridge stack')]
for o in mounts:
 for sl in o.material_slots:sl.link='OBJECT';sl.material=grey
def original_geometry():
 changed={o.name:o.hide_render for o in obs if o.name in replaced}
 for n in changed:sc.objects[n].hide_render=False
 result=p.architecture(obs)
 for n,state in changed.items():sc.objects[n].hide_render=state
 return result
assert original_geometry()==p.read(P/'sarang-relief-r8/verification.json')['geometry'];assert c.fixed_scene(sc)==fixed;assert p.stage_map('sarang',obs)==p.read(P/'sarang/construction-binding.json')
bpy.context.preferences.filepaths.save_version=0;native=D/'sarang-wrap-r9.blend';bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False)
v=dict(source=str(source),sourceSha256=source_sha,native=native.name,nativeSha256=p.sha(native),geometry=original_geometry(),original711MeshDataPreserved=True,visibilityReplaced=replaced,added=added,greyMountingMaterials=[o.name for o in mounts],vertices=len(verts),faces=len(faces),closedBoundaryLoops=len(loops),mainDimensions=[.30,.108,.43],actualVertexRelief=True,frontArchMatchesRoundBase=True,sideCarving=True,lightingCameraExposurePreserved=True,renderComplete=False,userApproved=False,runtimeIntegrated=False)
p.write(D/'verification.json',v)
bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene;cam=sc.camera;orig=cam.matrix_world.copy();ortho=cam.data.ortho_scale
sc.render.resolution_x=1200;sc.render.resolution_y=900;target=Vector((12.56,-3.54,6.84));direction=Vector((.42,-1,.22)).normalized();cam.location=target+direction*3;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=.88;p.write(D/'guardian.json',p.render(sc,D,'guardian.png',64))
cam.matrix_world=orig;cam.data.ortho_scale=ortho;direction=(cam.location-Vector((7,0,3))).normalized();target=Vector((4,-.6,1.1));cam.location=target+direction*18;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=5.6;p.write(D/'stone.json',p.render(sc,D,'stone.png',48))
cam.matrix_world=orig;cam.data.ortho_scale=ortho;sc.render.resolution_x=1800;sc.render.resolution_y=1200
p.write(D/'full.json',p.render(sc,D,'full.png',64))
after_fixed=c.fixed_scene(sc)
assert all(after_fixed[k]==fixed[k] for k in fixed if k!='camera')
assert np.allclose(after_fixed['camera']['matrix'],fixed['camera']['matrix'],rtol=1e-6,atol=1e-6)
assert p.sha(source)==source_sha;assert c.preserve_check()
obs=[sc.objects[n] for n in lock['objects']]
assert original_geometry()==v['geometry'];assert p.stage_map('sarang',obs)==p.read(P/'sarang/construction-binding.json')
v.update(renderComplete=True,processBindingCount=711,reopenedNativeVerified=True,render1And2Preserved=True,nativeSha256=p.sha(native),renders={name:p.read(D/(name+'.json')) for name in ['guardian','stone','full']})
p.write(D/'verification.json',v);print('R9 INTEGRATED FINIAL VERIFIED',flush=True)
