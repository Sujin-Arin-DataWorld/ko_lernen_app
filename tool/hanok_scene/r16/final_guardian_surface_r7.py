import bpy,sys,json
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P))
import sarang_reference_colour_r3 as c
p=c.p;f=c.f;D=P/'sarang-fit-r7';v=p.read(D/'verification.json');native=D/v['native']
assert p.sha(native)==v['nativeSha256'];bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene;fixed=c.fixed_scene(sc)
for name in ['HS6 guardian ridge face','HS6 patinated guardian edges']:
 t=bpy.data.materials[name].node_tree
 noise=next(n for n in t.nodes if 'R7 patina flecks' in n.label);noise.inputs['Scale'].default_value=320
 ramp=next(n for n in t.nodes if 'R7 antique clay bronze backing' in n.label)
 for e,col in zip(ramp.color_ramp.elements,['344C49','3D534D','495B50','566457','647060']):e.color=f.rgb(col)
lock=p.read(P/'sarang/geometry-lock.json');assert p.architecture([sc.objects[n] for n in lock['objects']])==v['geometry'];assert c.fixed_scene(sc)==fixed
bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False);v['nativeSha256']=p.sha(native);p.write(D/'verification.json',v)
bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene;cam=sc.camera;orig=cam.matrix_world.copy();ortho=cam.data.ortho_scale
sc.render.resolution_x=1200;sc.render.resolution_y=900;target=Vector((12.56,-3.52,6.87));direction=Vector((.35,-1,.18)).normalized();cam.location=target+direction*3;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=.85;p.write(D/'guardian.json',p.render(sc,D,'guardian.png',48))
cam.matrix_world=orig;cam.data.ortho_scale=ortho;sc.render.resolution_x=1800;sc.render.resolution_y=1200;p.write(D/'render.json',p.render(sc,D,'render.png',64))
assert p.architecture([sc.objects[n] for n in lock['objects']])==v['geometry'];assert c.fixed_scene(sc)==fixed;assert c.preserve_check();assert p.sha(v['source'])==v['sourceSha256']
v['renderComplete']=True;v['reopenedVerified']=True;v['render1And2Preserved']=True;p.write(D/'verification.json',v)
print('R7 FINAL VERIFIED',flush=True)
