"""Apply bounded review corrections to saved R12 without rebuilding geometry."""
import bpy,sys,json
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P))
import sarang_reference_colour_r3 as c
p=c.p;D=P/'sarang-exact-r12';source=D/'sarang-exact-r12.blend';source_sha=p.sha(source)
bpy.ops.wm.open_mainfile(filepath=str(source));sc=bpy.context.scene
lock=p.read(P/'sarang/geometry-lock.json');original=[sc.objects[n] for n in lock['objects']]
before=p.architecture(original);fixed_before=c.fixed_scene(sc)
import wood_review_refine_r12,stone_review_refine_r12,interior_warmth_refine_r12
receipts={}
for name,module in [('wood',wood_review_refine_r12),('stone',stone_review_refine_r12),('interior',interior_warmth_refine_r12)]:
 receipts[name]=module.apply(sc);p.write(D/(name+'-review-refinement.json'),receipts[name])
 assert p.architecture(original)==before,(name,'original architecture changed')
assert c.preserve_check()
fixed=c.fixed_scene(sc)
for key in ['camera','world','ground','view','compositor']:assert fixed[key]==fixed_before[key],key
native=D/'sarang-exact-r12-refined.blend'
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False)
v=dict(source=str(source),sourceSha256=source_sha,native=str(native),nativeSha256=p.sha(native),
 original711ArchitecturePreserved=True,originalArchitecture=before,render1And2Preserved=True,
 fixedSceneBefore=fixed_before,fixedScene=fixed,refinements=receipts,
 userApproved=False,runtimeIntegrated=False,renderComplete=False)
p.write(D/'refined-verification.json',v);print('REFINED NATIVE SAVED',flush=True)
cam=sc.camera;old=cam.matrix_world.copy();scale=cam.data.ortho_scale
target=Vector((3.9,-.6,1.25));direction=(old.translation-Vector((7,0,3))).normalized()
cam.location=target+direction*10;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=5.1
sc.render.resolution_x=1200;sc.render.resolution_y=1200
stone=p.render(sc,D,'stone-refined.png',48)
cam.matrix_world=old;cam.data.ortho_scale=scale;sc.render.resolution_x=1800;sc.render.resolution_y=1200
full=p.render(sc,D,'full-refined.png',64)
bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene
assert p.architecture([sc.objects[n] for n in lock['objects']])==before
assert c.fixed_scene(sc)==fixed
assert p.sha(source)==source_sha
v.update(renderComplete=True,reopenedNativeVerified=True,renders=dict(stone=stone,full=full))
p.write(D/'refined-verification.json',v);print('REFINED NATIVE AND RENDERS VERIFIED',flush=True)

