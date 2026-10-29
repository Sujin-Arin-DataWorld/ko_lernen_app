import bpy,sys
from pathlib import Path
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P))
import sarang_reference_colour_r3 as c
import grain_individual_r15 as grain
p=c.p;D=P/'sarang-wood-r15';D.mkdir(exist_ok=True)
source=P/'sarang-wood-r14/sarang-wood-r14.blend'
bpy.ops.wm.open_mainfile(filepath=str(source));sc=bpy.context.scene
lock=p.read(P/'sarang/geometry-lock.json');obs=[sc.objects[n] for n in lock['objects']]
before=p.architecture(obs);fixed=c.fixed_scene(sc);sha=p.sha(source)
assert before==p.read(P/'sarang-wood-r14/verification.json')['architecture']
details=grain.apply(sc)
assert p.architecture(obs)==before and c.fixed_scene(sc)==fixed and c.preserve_check()
bpy.context.preferences.filepaths.save_version=0
native=D/'sarang-wood-r15.blend';bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False)
receipt=dict(source=str(source),sourceSha256=sha,native=str(native),nativeSha256=p.sha(native),architecture=before,wood=p.read(P/'sarang-wood-r14/verification.json')['wood'],grain=details,source711DataPreserved=True,render1And2Preserved=True,lightsWorldExposureAndCameraUnchanged=True,userApproved=False,runtimeIntegrated=False,renderComplete=False)
p.write(D/'verification.json',receipt)
sc.render.resolution_x=1200;sc.render.resolution_y=800
receipt['preview']=p.render(sc,D,'preview.png',32)
bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene
assert p.architecture([sc.objects[n] for n in lock['objects']])==before and c.fixed_scene(sc)==fixed
assert p.sha(source)==sha
receipt.update(previewComplete=True,reopenedNativeVerified=True)
p.write(D/'verification.json',receipt);print('R15 PREVIEW AND REOPEN VERIFIED',flush=True)
