from pathlib import Path
import bpy,json,hashlib
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
SOURCE=Path('C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-warm-stone-20260923/assets_unused/pending_review/ildu_spatial_preservation_20260922/pair-construction-v26')
OUT=ROOT/'assets_unused/pending_review/hwalju-blueprint-review'
views={'front':((7.2,-28,6.7),(7.2,0,2.9),21),'numaru':((3.5,-15,7),(11,-2.8,2.45),12),'left':((-6,-9,5),(-.4,-.2,2.45),7)}
report=[]
for state,path in [('before',SOURCE/'scene.blend'),('after',OUT/'scene.blend')]:
    bpy.ops.wm.open_mainfile(filepath=str(path));s=bpy.context.scene
    s.render.engine='CYCLES';s.cycles.samples=16;s.cycles.use_denoising=True
    s.render.resolution_x=1120;s.render.resolution_y=800;s.render.resolution_percentage=100
    data=bpy.data.cameras.new('Hwalju matched review');data.type='ORTHO'
    cam=bpy.data.objects.new('CAM.Hwalju review',data);s.collection.objects.link(cam);s.camera=cam
    for view,(pos,target,scale) in views.items():
        cam.location=pos;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();data.ortho_scale=scale
        image=OUT/f'{state}-{view}.png';s.render.filepath=str(image)
        bpy.ops.render.render(write_still=True)
        report.append({'state':state,'view':view,'camera':pos,'target':target,'orthographicScale':scale,'sha256':hashlib.sha256(image.read_bytes()).hexdigest()})
        (OUT/'renders.json').write_text(json.dumps(report,indent=2))
print('SIX MATCHED VIEWS COMPLETE',flush=True)
