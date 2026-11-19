import bpy,sys,json
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P))
import sarang_reference_colour_r3 as c
p=c.p;f=c.f;D=P/'sarang-guardian-r6';v=p.read(D/'verification.json');native=D/v['native']
assert p.sha(native)==v['nativeSha256'];bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene
for m in bpy.data.materials:
 if m.get('guardian6')!='stone':continue
 t=m.node_tree;co=next(n for n in t.nodes if n.label=='Fresh R6 mineral metric').outputs['Position']
 warp=f.node(t,'ShaderNodeTexNoise','R6 irregular inclusion edges');t.links.new(co,warp.inputs['Vector']);warp.inputs['Scale'].default_value=19;warp.inputs['Detail'].default_value=1.5
 off=f.node(t,'ShaderNodeVectorMath','R6 small inclusion warp');off.operation='SCALE';t.links.new(warp.outputs['Color'],off.inputs[0]);off.inputs['Scale'].default_value=.045
 add=f.node(t,'ShaderNodeVectorMath','R6 scattered stone inclusions');add.operation='ADD';t.links.new(co,add.inputs[0]);t.links.new(off.outputs[0],add.inputs[1])
 vor=f.node(t,'ShaderNodeTexVoronoi','R6 separate weathered mineral islands');t.links.new(add.outputs[0],vor.inputs['Vector']);vor.inputs['Scale'].default_value=3.8
 ramp=next(n for n in t.nodes if 'R6 visible irregular ochre patches' in n.label)
 t.links.new(vor.outputs['Distance'],ramp.inputs[0])
 for e,pos,color in zip(ramp.color_ramp.elements,[.08,.19,.28,.35,.64],['8F795C','B09A78','CCB99A','D9CCB4','DED3BF']):e.position=pos;e.color=f.rgb(color)
 for n in t.nodes:
  if n.type=='MIX_RGB' and 'R6 local pit pigment' in n.label:n.inputs[0].default_value=.28
  if n.type=='MIX_RGB' and 'R6 actual mineral pigment layers' in n.label:n.inputs[0].default_value=.52
for m in bpy.data.materials:
 if m.name not in ('HS6 guardian ridge face','HS6 corner guardian faces'):continue
 t=m.node_tree;bs=next(n for n in t.nodes if n.type=='BSDF_PRINCIPLED');oldcol=bs.inputs['Base Color'].links[0].from_socket
 toned=f.mix(t,oldcol,(.42,.57,.53,1),1,'R6 subdued aged guardian pigment','MULTIPLY');t.links.new(toned,bs.inputs['Base Color'])
 bs.inputs['Metallic'].default_value=.12;bs.inputs['Roughness'].default_value=.78;bs.inputs['Specular IOR Level'].default_value=.22
lock=p.read(P/'sarang/geometry-lock.json');obs=[sc.objects[n] for n in lock['objects']]
assert p.architecture(obs)==v['geometry'];assert p.stage_map('sarang',obs)==p.read(P/'sarang/construction-binding.json')
assert json.loads(json.dumps(c.fixed_scene(sc)))==p.read(P/'sarang-reference-colour-r3/fixed-render-state.json')
bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False)
v['nativeSha256']=p.sha(native);p.write(D/'verification.json',v)
bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene
assert p.architecture([sc.objects[n] for n in lock['objects']])==v['geometry']
sc.render.resolution_x=1800;sc.render.resolution_y=1200
p.write(D/'render.json',p.render(sc,D,'render.png',96))
# Real native detail renders with the same lighting; camera changes only for review.
cam=sc.camera;orig=cam.matrix_world.copy();ortho=cam.data.ortho_scale;direction=(cam.location-Vector((7,0,3))).normalized()
for name,target,scale in [('stone-detail.png',(4,-.6,1.1),5.6),('guardian-detail.png',(12.56,-3.52,6.87),.85)]:
 target=Vector(target)
 if name.startswith('guardian'):direction=Vector((.35,-1,.18)).normalized()
 cam.location=target+direction*18;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=scale
 sc.render.resolution_x=1200;sc.render.resolution_y=900;p.write(D/(name.replace('.png','.json')),p.render(sc,D,name,64))
cam.matrix_world=orig;cam.data.ortho_scale=ortho
assert p.sha(v['source'])==v['sourceSha256'];assert c.preserve_check()
v['reopened']=True;v['originalFilesPreserved']=True;v['renderComplete']=True;p.write(D/'verification.json',v)
p.write(P/'PROGRESS.json',dict(key='sarang',event='guardian_6_render_ready',render=str(D/'render.png'),native=str(native),userApproved=False,runtimeIntegrated=False))
print('GUARDIAN R6 FINAL AND DETAILS VERIFIED',flush=True)
