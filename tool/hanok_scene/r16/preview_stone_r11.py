import bpy,sys
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P));import sarang_reference_colour_r3 as c,stone_shape_r11
p=c.p;D=P/'sarang-sculpt-r11';D.mkdir(exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(P/'sarang-stone-masonry-r10/sarang-stone-masonry-r10.blend'));sc=bpy.context.scene
p.write(D/'stone-shape-preview.json',stone_shape_r11.refine_stones(sc))
cam=sc.camera;direction=(cam.matrix_world.translation-Vector((7,0,3))).normalized();target=Vector((3.9,-.6,1.05));cam.location=target+direction*3;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=5.9;sc.render.resolution_x=1200;sc.render.resolution_y=1000
p.write(D/'stone-preview.json',p.render(sc,D,'stone-preview.png',40))
