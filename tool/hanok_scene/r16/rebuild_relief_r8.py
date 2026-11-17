import bpy,sys,json,math,shutil
import numpy as np
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P))
import sarang_reference_colour_r3 as c
p=c.p;f=c.f;D=P/'sarang-relief-r8';D.mkdir(exist_ok=True)
source=P/'sarang-fit-r7/sarang-fit-r7.blend';source_sha=p.sha(source)
bpy.ops.wm.open_mainfile(filepath=str(source));sc=bpy.context.scene;fixed=c.fixed_scene(sc)
lock=p.read(P/'sarang/geometry-lock.json');obs=[sc.objects[n] for n in lock['objects']];before=p.architecture(obs)
for filename,src in [('guardian-art.png',P/'sarang-guardian-r6/guardian.png'),('stone-material.png',P/'sarang-fit-r7/stone-material.png')]:shutil.copy2(src,D/filename)

# Stone: quiet mineral body per block, local inclusions, broad shallow relief,
# fine pores, and actual short-range join shading are independent controls.
for m in bpy.data.materials:
 if m.get('guardian6')!='stone':continue
 t=m.node_tree;bs=next(n for n in p.live(t) if n.type=='BSDF_PRINCIPLED');tex=next(n for n in t.nodes if n.type=='TEX_IMAGE' and 'R7 authored' in n.label)
 seed=p.craft.illustration.member_value(t)
 body=f.ramp(t,seed,[(0,f.rgb('A89D8A')),(.3,f.rgb('BAAE99')),(.65,f.rgb('CEC0A8')),(1,f.rgb('DDD1BD'))],'R8 distinct dressed stone bodies')
 g=f.gray(t,tex.outputs['Color'],'R8 source mineral density')
 ratio=f.scalar(t,'DIVIDE',g,.70,'R8 calibrated texture body');ratio=f.scalar(t,'POWER',ratio,1.8,'R8 mineral inclusion separation');ratio=f.scalar(t,'MAXIMUM',ratio,.40);ratio=f.scalar(t,'MINIMUM',ratio,1.08)
 col=f.mix(t,body,ratio,1,'R8 original mineral pattern','MULTIPLY')
 ao=f.node(t,'ShaderNodeAmbientOcclusion','R8 short stone joint');ao.inputs['Distance'].default_value=.085;ao.samples=12
 cavity=f.ramp(t,ao.outputs['AO'],[(.05,(.39,.34,.27,1)),(.87,(1,1,1,1))],'R8 warm stone contact')
 t.links.new(f.mix(t,col,cavity,.58,'R8 local stone join','MULTIPLY'),bs.inputs['Base Color'])
 pos=f.node(t,'ShaderNodeNewGeometry','R8 broad dressed stone planes').outputs['Position'];broad=f.noise(t,pos,5.6,1,'R8 shallow dressed surface')
 fine=f.node(t,'ShaderNodeBump','R8 mineral pores');fine.inputs['Distance'].default_value=.003;fine.inputs['Strength'].default_value=.28;t.links.new(g,fine.inputs['Height'])
 large=f.node(t,'ShaderNodeBump','R8 broad chisel variation');large.inputs['Distance'].default_value=.014;large.inputs['Strength'].default_value=.30;t.links.new(broad,large.inputs['Height']);t.links.new(fine.outputs['Normal'],large.inputs['Normal'])
 bevel=f.node(t,'ShaderNodeBevel','R8 dressed edge light');bevel.samples=4;bevel.inputs['Radius'].default_value=.020;t.links.new(large.outputs['Normal'],bevel.inputs['Normal']);t.links.new(bevel.outputs['Normal'],bs.inputs['Normal'])
 rough=f.ramp(t,g,[(.2,(.91,.91,.91,1)),(.8,(.77,.77,.77,1))],'R8 mineral roughness');t.links.new(rough,bs.inputs['Roughness']);bs.inputs['Specular IOR Level'].default_value=.28
 keep=p.live(t)
 for nd in list(t.nodes):
  if nd not in keep:t.nodes.remove(nd)

# Build a closed, volumetric leaf plaque. All opaque artwork goes to the outer
# edge, and sampled relief plus broad facial volumes are actual vertex depth.
im=bpy.data.images.load(str(D/'guardian-art.png'));im.pack();w,h=im.size
a=np.empty(w*h*4,np.float32);im.pixels.foreach_get(a);a=a.reshape(h,w,4)
luma=a[:,:,:3]@np.array([.2126,.7152,.0722]);opaque=a[:,:,3]>.2
yrows=np.flatnonzero(opaque.any(axis=1));ymin=int(yrows[0]);ymax=int(yrows[-1]);xmin=int(np.where(opaque)[1].min());xmax=int(np.where(opaque)[1].max())
lo,hi=np.percentile(luma[opaque],[10,90])
def sample(u,v):
 x=int(np.clip(u*(w-1),0,w-1));y=int(np.clip(v*(h-1),0,h-1));vals=[]
 for dx,dy in [(0,0),(-3,0),(3,0),(0,-3),(0,3),(-2,-2),(2,2),(-2,2),(2,-2)]:vals.append(luma[np.clip(y+dy,0,h-1),np.clip(x+dx,0,w-1)])
 return float(np.clip((np.mean(vals)-lo)/(hi-lo),0,1))
nx=240;ny=320;verts=[];uvs=[]
for j in range(ny+1):
 py=int(round(ymin+(ymax-ymin)*j/ny));xs=np.flatnonzero(opaque[py]);left,right=int(xs[0]),int(xs[-1])
 for i in range(nx+1):
  px=left+(right-left)*i/nx;u=px/(w-1);v=py/(h-1)
  x=(px-(xmin+xmax)/2)/(xmax-xmin)*.30;z=(py-ymin)/(ymax-ymin)*.43
  face=math.exp(-(((u-.5)/.29)**2+((v-.33)/.20)**2)*2)
  hair=math.exp(-(((u-.5)/.35)**2+((v-.65)/.22)**2)*2)
  depth=.004+.018*sample(u,v)+.014*face+.007*hair
  verts.append((x,-depth,z));uvs.append((u,v))
faces=[];mats=[]
for j in range(ny):
 for i in range(nx):
  k=j*(nx+1)+i;faces.append((k,k+1,k+nx+2,k+nx+1));mats.append(0)
boundary=list(range(nx+1))+[j*(nx+1)+nx for j in range(1,ny+1)]+[ny*(nx+1)+i for i in range(nx-1,-1,-1)]+[j*(nx+1) for j in range(ny-1,0,-1)]
back=[]
for idx in boundary:
 x,y,z=verts[idx];back.append(len(verts));verts.append((x,.040,z));uvs.append(uvs[idx])
for k in range(len(boundary)):
 q=(k+1)%len(boundary);faces.append((boundary[q],boundary[k],back[k],back[q]));mats.append(1)
faces.append(tuple(reversed(back)));mats.append(1)
me=bpy.data.meshes.new('HS8 full guardian relief solid');me.from_pydata(verts,[],faces);me.update();uv=me.uv_layers.new(name='Full guardian surface')
for poly in me.polygons:
 poly.material_index=mats[poly.index];poly.use_smooth=poly.material_index==0
 for li in poly.loop_indices:uv.data[li].uv=uvs[me.loops[li].vertex_index]
mat=bpy.data.materials.new('HS8 sculpted guardian patinated surface');mat.use_nodes=True;t=mat.node_tree;bs=next(n for n in t.nodes if n.type=='BSDF_PRINCIPLED')
tex=f.node(t,'ShaderNodeTexImage','R8 full face edge to edge');tex.image=im;tex.extension='EXTEND'
t.links.new(f.mix(t,tex.outputs['Color'],(.42,.55,.52,1),1,'R8 local pigment only','MULTIPLY'),bs.inputs['Base Color']);bs.inputs['Metallic'].default_value=.32;bs.inputs['Roughness'].default_value=.67;bs.inputs['Specular IOR Level'].default_value=.3
g=f.gray(t,tex.outputs['Color'],'R8 relief micro patina');bump=f.node(t,'ShaderNodeBump','R8 patina micrograin');bump.inputs['Distance'].default_value=.00035;bump.inputs['Strength'].default_value=.18;t.links.new(g,bump.inputs['Height']);t.links.new(bump.outputs['Normal'],bs.inputs['Normal'])
side=bpy.data.materials['HS6 patinated guardian edges'].copy();side.name='HS8 relief solid fired edge';me.materials.append(mat);me.materials.append(side)
collection=bpy.data.collections.new('HS8 Guardian full volumetric replacement');sc.collection.children.link(collection)
added=[]
for name,loc,scale,parent in [('HS8 main full guardian',(12.56,-3.645,6.66),1,'Sarang.numaru roof end ornament.original patterned face'),('HS8 left full guardian',(9.17,-5.47,4.82),.79,'Sarang.numaru roof.hip round tile ends'),('HS8 right full guardian',(15.93,-5.53,4.82),.79,'Sarang.numaru roof.hip round tile ends')]:
 o=bpy.data.objects.new(name,me);collection.objects.link(o);o.location=loc;o.scale=(scale,scale,scale);o['construction_parent']=parent;o['story_layer']='User requested full Dokkaebi finial relief';added.append(o.name)
replaced=['Sarang.numaru roof end ornament.original patterned face','Sarang.numaru roof end ornament.finial edge','HS6 guardian eave seal 0','HS6 guardian eave seal 1']
old_visibility={n:sc.objects[n].hide_render for n in replaced}
assert p.architecture(obs)==before
for n in replaced:sc.objects[n].hide_render=True;sc.objects[n].hide_set(True)
def check_geometry():
 current={n:sc.objects[n].hide_render for n in replaced}
 for n,hide in old_visibility.items():sc.objects[n].hide_render=hide
 result=p.architecture(obs)
 for n,hide in current.items():sc.objects[n].hide_render=hide
 assert result==before
 return result
assert c.fixed_scene(sc)==fixed;check_geometry();assert p.stage_map('sarang',obs)==p.read(P/'sarang/construction-binding.json')
bpy.context.preferences.filepaths.save_version=0
native=D/'sarang-relief-r8.blend';assert not native.exists();bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False)
report=dict(source=str(source),sourceSha256=source_sha,native=native.name,nativeSha256=p.sha(native),geometry=before,original711MeshDataPreserved=True,visibilityReplacement=replaced,added=added,reliefVertices=len(verts),reliefFaces=len(faces),mainWidth=.30,mainHeight=.43,frontBaseY=-3.645,fullImageToMeshBoundary=True,reliefDepthMethod='Image-guided sampled shallow relief plus broad face and hair volumes; not independently sculpted semantic topology',lightingCameraExposurePreserved=True,processBindingCount=711,renderComplete=False,userApproved=False,runtimeIntegrated=False)
p.write(D/'verification.json',report)
bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene;cam=sc.camera;orig=cam.matrix_world.copy();ortho=cam.data.ortho_scale
sc.render.resolution_x=1200;sc.render.resolution_y=900;target=Vector((12.56,-3.59,6.87));direction=Vector((.35,-1,.18)).normalized();cam.location=target+direction*3;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=.85;p.write(D/'guardian.json',p.render(sc,D,'guardian.png',48))
cam.matrix_world=orig;cam.data.ortho_scale=ortho;direction=(cam.location-Vector((7,0,3))).normalized();target=Vector((4,-.6,1.1));cam.location=target+direction*18;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=5.6;p.write(D/'stone.json',p.render(sc,D,'stone.png',48))
assert p.sha(source)==source_sha;assert c.preserve_check();print('R8 NATIVE RELIEF AND STONE DETAILS READY',flush=True)
