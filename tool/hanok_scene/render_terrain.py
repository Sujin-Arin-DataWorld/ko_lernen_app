"""Matched native renders of the actual former browser ground and correction."""
from pathlib import Path
import bpy,json,hashlib
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'assets_unused/pending_review/hwalju-blueprint-review'
OUT=SOURCE/'terrain'
views={'connection':((-48,1,10),(4,4.5,2.3),26),'junction':((-18,-6.56,6),(0,3.7,1.5),10),'gate':((-20,23.2,7.7),(0,12.8,1.9),13)}
report=[]
for state,path in [('before',SOURCE/'scene.blend'),('after',OUT/'scene.blend')]:
    bpy.ops.wm.open_mainfile(filepath=str(path));s=bpy.context.scene
    if state=='before':
        # V26 omitted context terrain on export and the viewer drew these
        # construction stage boxes, plus a flat background at -280mm.
        for o in list(s.objects):
            if o.name.startswith('Terrain.') or o.name in ('Stage.Jung.site','Stage.Sarang.site'):bpy.data.objects.remove(o,do_unlink=True)
        mat=bpy.data.materials.new('Former browser compacted site');mat.diffuse_color=(.45,.38,.27,1);mat.use_nodes=True
        bs=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED');bs.inputs['Base Color'].default_value=(.45,.38,.27,1);bs.inputs['Roughness'].default_value=1
        for name,center,size in [('Stage.Sarang.site',(7.2,.5,-.16),(19,15,.28)),('Stage.Jung.site',(1.1,9.825,.44),(7.5,14.5,.28))]:
            bpy.ops.mesh.primitive_cube_add(size=1,location=center);o=bpy.context.object;o.name=name;o.dimensions=size;o.data.materials.append(mat)
        bpy.ops.mesh.primitive_plane_add(size=100,location=(5,4,-.28));bpy.context.object.data.materials.append(mat)
    s.render.engine='CYCLES';s.cycles.samples=16;s.cycles.use_denoising=True;s.render.film_transparent=False
    s.render.resolution_x=1120;s.render.resolution_y=800;s.render.resolution_percentage=100
    data=bpy.data.cameras.new('Terrain matched review');data.type='ORTHO'
    cam=bpy.data.objects.new('CAM.Terrain review',data);s.collection.objects.link(cam);s.camera=cam
    for view,(pos,target,scale) in views.items():
        cam.location=pos;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();data.ortho_scale=scale
        image=OUT/f'{state}-{view}.png';s.render.filepath=str(image)
        bpy.ops.render.render(write_still=True)
        report.append({'state':state,'view':view,'sceneSha256':hashlib.sha256(path.read_bytes()).hexdigest(),'camera':pos,'target':target,'orthographicScale':scale,'sha256':hashlib.sha256(image.read_bytes()).hexdigest()})
        (OUT/'renders.json').write_text(json.dumps(report,indent=2))
print('SIX MATCHED VIEWS COMPLETE',flush=True)
