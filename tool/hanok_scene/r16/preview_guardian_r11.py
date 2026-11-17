import bpy,sys
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P));import sarang_reference_colour_r3 as c;import guardian_sculpt_r11 as g
p=c.p;D=P/'sarang-sculpt-r11';D.mkdir(exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(P/'sarang-stone-masonry-r10/sarang-stone-masonry-r10.blend'));sc=bpy.context.scene;report=g.build_guardians(sc,p.read(P/'original-finials-r11.json'));p.write(D/'guardian-shape-preview.json',report)
cam=sc.camera;target=Vector((12.56,-3.49,6.875));direction=Vector((.35,-1,.16)).normalized();cam.location=target+direction*3;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=.60;sc.render.resolution_x=800;sc.render.resolution_y=800
p.write(D/'guardian-front-preview.json',p.render(sc,D,'guardian-front-preview.png',24))
sc.view_layers[0].material_override=g.make_material('HS11 clay preview','989898',0);direction=Vector((.65,-1,.16)).normalized();cam.location=target+direction*3;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();p.write(D/'guardian-clay-preview.json',p.render(sc,D,'guardian-clay-preview.png',24))
print('GUARDIAN PREVIEW READY',flush=True)
