import bpy, sys, json, shutil
import numpy as np
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parent; sys.path.insert(0,str(P))
import sarang_reference_colour_r3 as c
p=c.p; f=c.f; D=P/'sarang-fit-r7'; D.mkdir(exist_ok=True)
src=P/'sarang-guardian-r6/sarang-guardian-r6.blend'
sv=p.read(src.parent/'verification.json'); assert p.sha(src)==sv['nativeSha256']
bpy.ops.wm.open_mainfile(filepath=str(src)); sc=bpy.context.scene
lock=p.read(P/'sarang/geometry-lock.json'); obs=[sc.objects[n] for n in lock['objects']]
before=p.architecture(obs); fixed=c.fixed_scene(sc)
preserved={m.name:p.s.material_state(m) for m in bpy.data.materials if m.use_nodes and m.get('guardian6')!='stone' and m.name!='HS6 guardian ridge face'}
texture_src=Path('C:/Users/vjinn/.codex/generated_images/01a1501f-48a0-72b0-952f-b9030f42cafe/exec-944ab39e-de0f-4786-8f64-383ec2f73e3e.png')
shutil.copy2(texture_src,D/'stone-material.png')
im=bpy.data.images.load(str(D/'stone-material.png')); im.pack()
for m in bpy.data.materials:
 if m.get('guardian6')!='stone': continue
 t=m.node_tree; bs=next(n for n in p.live(t) if n.type=='BSDF_PRINCIPLED')
 co=f.node(t,'ShaderNodeNewGeometry','R7 metric stone coordinates').outputs['Position']
 seed=p.craft.illustration.member_value(t)
 scale=f.node(t,'ShaderNodeVectorMath','R7 0.85 metre texture repeat'); scale.operation='SCALE'; t.links.new(co,scale.inputs[0]); scale.inputs[3].default_value=1/.85
 offset=f.node(t,'ShaderNodeCombineXYZ','R7 stable per member offsets')
 for axis,mul in [('X',3.71),('Y',7.93),('Z',11.17)]:t.links.new(f.scalar(t,'MULTIPLY',seed,mul),offset.inputs[axis])
 add=f.node(t,'ShaderNodeVectorMath','R7 varied surface origin');add.operation='ADD';t.links.new(scale.outputs[0],add.inputs[0]);t.links.new(offset.outputs[0],add.inputs[1])
 tex=f.node(t,'ShaderNodeTexImage','R7 authored mineral stone');tex.image=im;tex.projection='BOX';tex.projection_blend=.12;tex.extension='REPEAT';t.links.new(add.outputs[0],tex.inputs['Vector'])
 pigment=f.ramp(t,seed,[(0,(.64,.65,.66,1)),(.5,(.72,.72,.71,1)),(1,(.80,.79,.77,1))],'R7 mild block pigment variation')
 col=f.mix(t,tex.outputs['Color'],pigment,1,'R7 stone only pigment calibration','MULTIPLY');t.links.new(f.contact(t,col,'stone'),bs.inputs['Base Color'])
 height=f.gray(t,tex.outputs['Color'],'R7 mineral pores');f.normal(t,bs,height,.0025,.012,.22)
 for link in list(bs.inputs['Roughness'].links):t.links.remove(link)
 bs.inputs['Roughness'].default_value=.86;bs.inputs['Specular IOR Level'].default_value=.25
 keep=p.live(t)
 for nd in list(t.nodes):
  if nd not in keep:t.nodes.remove(nd)

# Fit the complete opaque artwork silhouette inside the actual face above the cap.
o=sc.objects[sv['ornamentTarget']];m=bpy.data.materials['HS6 guardian ridge face'];t=m.node_tree
tex=next(n for n in t.nodes if n.type=='TEX_IMAGE');art=tex.image;w,h=art.size
pixels=np.empty(w*h*4,np.float32);art.pixels.foreach_get(pixels);alpha=pixels.reshape(h,w,4)[:,:,3]
points=[]
for y in range(0,h,5):
 xs=np.flatnonzero(alpha[y]>.02)
 if len(xs):
  for x in [xs[0],(xs[0]+xs[-1])//2,xs[-1]]:points.append((x/(w-1)-.5,y/(h-1)))
points=np.array(points)
o.data.calc_loop_triangles();tris=[]
for tri in o.data.loop_triangles:
 xyz=[o.matrix_world@o.data.vertices[i].co for i in tri.vertices]
 tris.append(np.array([[q.x,q.z] for q in xyz]))
def contains(q):
 inside=np.zeros(len(q),bool)
 for tri in tris:
  signs=[]
  for a,b in zip(tri,np.roll(tri,-1,axis=0)):
   signs.append((b[0]-a[0])*(q[:,1]-a[1])-(b[1]-a[1])*(q[:,0]-a[0]))
  s=np.array(signs);inside|=np.all(s>=-1e-9,axis=0)|np.all(s<=1e-9,axis=0)
 return bool(np.all(inside))
bottom=6.775;cx=12.56;aspect=w/h;low=.05;high=.32
for _ in range(30):
 height=(low+high)/2;q=points*np.array([height*aspect,height])+np.array([cx,bottom])
 if contains(q):low=height
 else:high=height
height=low*.965;width=height*aspect
lo=(cx-width/2,0,bottom);hi=(cx+width/2,0,bottom+height)
geo=f.node(t,'ShaderNodeNewGeometry','R7 guardian fitted world position')
sub=f.node(t,'ShaderNodeVectorMath','R7 visible face bottom');sub.operation='SUBTRACT';t.links.new(geo.outputs['Position'],sub.inputs[0]);sub.inputs[1].default_value=lo
sep=f.node(t,'ShaderNodeSeparateXYZ','R7 visible face axes');t.links.new(sub.outputs[0],sep.inputs[0])
uv=f.node(t,'ShaderNodeCombineXYZ','R7 full artwork contain mapping')
t.links.new(f.scalar(t,'DIVIDE',sep.outputs['X'],width),uv.inputs['X']);t.links.new(f.scalar(t,'DIVIDE',sep.outputs['Z'],height),uv.inputs['Y']);t.links.new(uv.outputs[0],tex.inputs['Vector']);tex.extension='CLIP'
keep=p.live(t)
for nd in list(t.nodes):
 if nd not in keep:t.nodes.remove(nd)
assert contains(points*np.array([width,height])+np.array([cx,bottom]))
assert p.architecture(obs)==before==sv['geometry']
assert c.fixed_scene(sc)==fixed
assert all(p.s.material_state(bpy.data.materials[n])==state for n,state in preserved.items())
assert p.stage_map('sarang',obs)==p.read(P/'sarang/construction-binding.json')
bpy.context.preferences.filepaths.save_version=0
native=D/'sarang-fit-r7.blend';assert not native.exists();bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False)
v=dict(source=str(src),sourceSha256=p.sha(src),native=native.name,nativeSha256=p.sha(native),geometry=before,original711Preserved=True,processBindingCount=711,lightingCameraExposurePreserved=True,otherMaterialsPreserved=True,contactRepair=sv['contact'],guardianFit=dict(width=width,height=height,bottom=bottom,top=bottom+height,aspectPreserved=True,sampledSilhouetteContained=True,clearanceAboveCap=.03),stoneTextureSource=str(texture_src),stoneTextureSha256=p.sha(texture_src),renderComplete=False,userApproved=False,runtimeIntegrated=False)
p.write(D/'verification.json',v)
bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene
assert p.architecture([sc.objects[n] for n in lock['objects']])==before
cam=sc.camera;orig=cam.matrix_world.copy();ortho=cam.data.ortho_scale
direction=(cam.location-Vector((7,0,3))).normalized();target=Vector((4,-.6,1.1))
cam.location=target+direction*18;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=5.6
sc.render.resolution_x=1200;sc.render.resolution_y=900;p.write(D/'stone.json',p.render(sc,D,'stone.png',48))
target=Vector((12.56,-3.52,6.87));direction=Vector((.35,-1,.18)).normalized();cam.location=target+direction*3;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=.85
p.write(D/'guardian.json',p.render(sc,D,'guardian.png',48))
cam.matrix_world=orig;cam.data.ortho_scale=ortho
assert p.sha(src)==v['sourceSha256'];assert c.preserve_check()
print('R7 DETAILS READY',json.dumps(v['guardianFit']),flush=True)
