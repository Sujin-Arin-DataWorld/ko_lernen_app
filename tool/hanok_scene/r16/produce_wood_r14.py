import bpy,sys,json,time
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P))
import sarang_reference_colour_r3 as c
import wood_individual_r14 as wood
p=c.p;D=P/'sarang-wood-r14';D.mkdir(exist_ok=True)
source=P/'sarang-palette-r13/sarang-palette-r13.blend'
bpy.ops.wm.open_mainfile(filepath=str(source));sc=bpy.context.scene
lock=p.read(P/'sarang/geometry-lock.json');obs=[sc.objects[n] for n in lock['objects']]
before=p.architecture(obs);fixed=c.fixed_scene(sc);sha=p.sha(source)
assert before==p.read(P/'sarang-palette-r13/verification.json')['architecture']
report=wood.apply(sc)
assert before==p.architecture(obs);assert fixed==c.fixed_scene(sc);assert c.preserve_check()
sc.render.resolution_x=1800;sc.render.resolution_y=1200;sc.render.resolution_percentage=100
bpy.context.preferences.filepaths.save_version=0
native=D/'sarang-wood-r14.blend';bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False)
receipt=dict(source=str(source),sourceSha256=sha,native=str(native),nativeSha256=p.sha(native),source711DataPreserved=True,render1And2Preserved=True,architecture=before,lightsWorldExposureAndCameraUnchanged=True,wood=report,userApproved=False,runtimeIntegrated=False,renderComplete=False)
p.write(D/'verification.json',receipt);print('R14 SAVED',report['objects'],report['materials'],flush=True)
sc.render.resolution_x=1200;sc.render.resolution_y=800
receipt['preview']=p.render(sc,D,'preview.png',32);p.write(D/'verification.json',receipt)
bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene
assert before==p.architecture([sc.objects[n] for n in lock['objects']])
assert fixed==c.fixed_scene(sc)
assert p.sha(source)==sha
for row in report['assignments']:
 assert sc.objects[row['object']].material_slots[row['slot']].material.get('hs14_individual_wood')
for row in report['ondolCorrections']:
 m=sc.objects[row['object']].material_slots[row['slot']].material
 assert all(n.inputs['Emission Strength'].default_value==0 for n in p.live(m.node_tree) if n.type=='BSDF_PRINCIPLED')
receipt.update(reopenedNativeVerified=True,previewComplete=True)
p.write(D/'verification.json',receipt)
print('R14 PREVIEW COMPLETE',flush=True)
