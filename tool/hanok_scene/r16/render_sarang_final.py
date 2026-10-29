"""Render and verify only the reviewed Sarang candidate at reference resolution."""
import bpy,sys,json
from pathlib import Path
OUT=Path(__file__).resolve().parent;sys.path.insert(0,str(OUT))
import produce as p
folder=sys.argv[sys.argv.index('--')+1]
assert folder in ('sarang-r4','sarang-r5','sarang-r6','sarang-r7','sarang-r8','sarang-r9','sarang-r10')
dest=OUT/folder;v=p.read(dest/'verification.json');native=dest/v['native'];assert p.sha(native)==v['nativeSha256']
bpy.ops.wm.open_mainfile(filepath=str(native));scene=bpy.context.scene
lock=p.read(OUT/'sarang/geometry-lock.json');obs=[scene.objects[n] for n in lock['objects']]
assert p.architecture(obs)==v['geometry']
assert p.stage_map('sarang',obs)==p.read(OUT/'sarang/construction-binding.json')
scene.render.resolution_x=2528;scene.render.resolution_y=1684;scene.render.resolution_percentage=100
scene.cycles.use_adaptive_sampling=True;scene.cycles.adaptive_threshold=.02;scene.cycles.adaptive_min_samples=16;scene.cycles.samples=128
scene.cycles.use_denoising=True;scene.cycles.denoiser='OPENIMAGEDENOISE'
scene.render.image_settings.color_depth='8'
result=p.render(scene,dest,'complete.png')
assert p.architecture(obs)==v['geometry'];assert p.sha(native)==v['nativeSha256']
ref=Path('C:/Users/vjinn/ELibrary/Downloads/Gemini_Generated_Image_824e6v824e6v824e.jpg')
p.write(dest/'render-manifest.json',dict(complete=True,render=result,maxSamples=128,adaptiveNoiseThreshold=.02,minimumSamples=16,
 reference=dict(path=str(ref),sha256=p.sha(ref)),nativeSha256=p.sha(native),geometryPreserved=True,processBindingsPreserved=711,
 sameCameraAsBefore=True,referenceStyleMatchApproved=False,runtimeIntegrated=False))
print('FINAL SARANG RENDER VERIFIED',flush=True)
