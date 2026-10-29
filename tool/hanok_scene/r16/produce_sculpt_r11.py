import bpy,sys,json,bmesh,math
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P));import sarang_reference_colour_r3 as c
import stone_shape_r11,guardian_sculpt_r11
p=c.p;D=P/'sarang-sculpt-r11';D.mkdir(exist_ok=True);source=P/'sarang-stone-masonry-r10/sarang-stone-masonry-r10.blend';source_sha=p.sha(source)
bpy.ops.wm.open_mainfile(filepath=str(source));sc=bpy.context.scene;lock=p.read(P/'sarang/geometry-lock.json');original=[sc.objects[n] for n in lock['objects']];before=p.architecture(original);fixed=c.fixed_scene(sc)
stone=stone_shape_r11.refine_stones(sc);p.write(D/'stone-shape.json',stone)
guardian=guardian_sculpt_r11.build_guardians(sc,p.read(P/'original-finials-r11.json'));p.write(D/'guardian-shape.json',guardian)
assert p.architecture(original)==before;assert p.stage_map('sarang',original)==p.read(P/'sarang/construction-binding.json');assert c.fixed_scene(sc)==fixed;assert c.preserve_check()
topology=[]
for row in guardian:
 o=sc.objects[row['name']];bm=bmesh.new();bm.from_mesh(o.data);bad=sum(not e.is_manifold for e in bm.edges);bm.free();assert bad==0,(o.name,bad);topology.append(dict(name=o.name,nonManifoldEdges=bad))
bpy.context.preferences.filepaths.save_version=0;native=D/'sarang-sculpt-r11.blend';bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False)
v=dict(source=str(source),sourceSha256=source_sha,native=str(native),nativeSha256=p.sha(native),source711DataPreserved=True,originalState=before,stone=stone,guardians=guardian,topology=topology,fixedScene=fixed,render1And2Preserved=True,userApproved=False,runtimeIntegrated=False,renderComplete=False)
p.write(D/'verification.json',v)
cam=sc.camera;old=cam.matrix_world.copy();ortho=cam.data.ortho_scale
def shot(name,target,direction,scale,samples=32,size=800):
 target=Vector(target);direction=Vector(direction).normalized();cam.location=target+direction*3;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=scale;sc.render.resolution_x=size;sc.render.resolution_y=size;p.write(D/(name+'.json'),p.render(sc,D,name+'.png',samples))
shot('guardian-front',(12.56,-3.49,6.875),(.35,-1,.16),.60)
shot('guardian-side',(12.56,-3.49,6.875),(1,-.32,.12),.60)
shot('guardian-back',(12.56,-3.49,6.875),(.3,1,.12),.60)
shot('round-cap',(9.195,-5.3875,4.865),(.32,-1,.15),.26)
clay=guardian_sculpt_r11.make_material('HS11 neutral clay audit','989898',0);sc.view_layers[0].material_override=clay
shot('guardian-clay',(12.56,-3.49,6.875),(.65,-1,.16),.60)
sc.view_layers[0].material_override=None
direction=(old.translation-Vector((7,0,3))).normalized();shot('stone',(3.9,-.6,1.05),direction,5.9,48,1200)
cam.matrix_world=old;cam.data.ortho_scale=ortho;sc.render.resolution_x=1800;sc.render.resolution_y=1200;p.write(D/'full.json',p.render(sc,D,'full.png',64))
bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene;assert c.fixed_scene(sc)==fixed;assert p.architecture([sc.objects[n] for n in lock['objects']])==before;assert p.sha(source)==source_sha
v.update(renderComplete=True,reopenedNativeVerified=True,renders={k:p.read(D/(k+'.json')) for k in ['guardian-front','guardian-side','guardian-back','round-cap','guardian-clay','stone','full']});p.write(D/'verification.json',v);print('R11 MULTI VIEW NATIVE VERIFIED',flush=True)
