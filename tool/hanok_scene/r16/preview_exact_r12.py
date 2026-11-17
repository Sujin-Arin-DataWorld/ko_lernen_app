import bpy,sys
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P));import sarang_reference_colour_r3 as c,guardian_exact_r12,guardian_sculpt_r11
p=c.p;D=P/'sarang-exact-r12';D.mkdir(exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(P/'sarang-stone-masonry-r10/sarang-stone-masonry-r10.blend'));sc=bpy.context.scene
p.write(D/'guardian-shape-preview.json',guardian_exact_r12.build(sc))
cam=sc.camera;target=Vector((12.56,-3.49,6.875));direction=Vector((.35,-1,.16)).normalized();cam.location=target+direction*3;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=.60;sc.render.resolution_x=800;sc.render.resolution_y=800
p.write(D/'guardian-front-preview.json',p.render(sc,D,'guardian-front-preview.png',32))
clay=guardian_sculpt_r11.make_material('HS12 neutral clay audit','989898',0);sc.view_layers[0].material_override=clay
p.write(D/'guardian-clay-preview.json',p.render(sc,D,'guardian-clay-preview.png',32))
