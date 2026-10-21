"""Render the combined native without saving or modifying its source file."""
import bpy,json,sys
from pathlib import Path
from mathutils import Vector,Matrix
OUT=Path(__file__).resolve().parent;ROOT=OUT.parent
scene=bpy.data.scenes['Hangul Sori | Full Ildu Estate'];bpy.context.window.scene=scene
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=8;scene.cycles.seed=15;scene.cycles.use_denoising=True
scene.render.threads_mode='FIXED';scene.render.threads=6
scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG'
report=json.loads((OUT/'assembly-verification.json').read_text(encoding='utf-8'))
camData=bpy.data.cameras.new('Canonical combined proof camera');camData.type='ORTHO'
cam=bpy.data.objects.new('Canonical combined proof camera',camData);scene.collection.objects.link(cam);scene.camera=cam
renders=[]
# Keep the existing R5 full framing for the whole-estate verification.
manifest=json.loads((ROOT/'estate-yard-wall-r1/living-r5/render-manifest.json').read_text(encoding='utf-8'))
c=next(x['camera'] for x in manifest['renders'] if x['view']=='full' and x['variant']=='B')
cam.location=c['location'];cam.rotation_euler=c['rotation'];camData.ortho_scale=c['ortho_scale']
scene.render.resolution_x=1280;scene.render.resolution_y=960
scene.render.filepath=str(OUT/'estate-combined.png');bpy.ops.render.render(write_still=True,scene=scene.name)
renders.append('estate-combined.png')
for a in report['assembly']:
 M=Matrix(a['matrix']);center=M.translation.copy()+Vector((0,0,1.5))
 cam.location=M@Vector((5,-9,6));cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();camData.ortho_scale=8
 scene.render.resolution_x=960;scene.render.resolution_y=800
 name=a['gate']+'-in-estate.png';scene.render.filepath=str(OUT/name);bpy.ops.render.render(write_still=True,scene=scene.name);renders.append(name)
(OUT/'combined-render-proof.json').write_text(json.dumps(dict(nativeSha256=report['nativeSha256'],renders=renders,sourceNativeSaved=False,samples=8),indent=2),encoding='utf-8')
print('COMBINED RENDER PROOF COMPLETE',renders,flush=True)

