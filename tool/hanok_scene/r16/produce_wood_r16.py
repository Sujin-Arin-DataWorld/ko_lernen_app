import bpy,sys
from pathlib import Path
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P))
import sarang_reference_colour_r3 as c
import wood_balance_r16 as balance
p=c.p;D=P/'sarang-wood-r16';D.mkdir(exist_ok=True)
source=P/'sarang-wood-r15/sarang-wood-r15.blend'
bpy.ops.wm.open_mainfile(filepath=str(source));sc=bpy.context.scene
lock=p.read(P/'sarang/geometry-lock.json');obs=[sc.objects[n] for n in lock['objects']]
before=p.architecture(obs);fixed=c.fixed_scene(sc);sha=p.sha(source)
assert before==p.read(P/'sarang-wood-r15/verification.json')['architecture']
changes=balance.apply(sc)
assert p.architecture(obs)==before and c.fixed_scene(sc)==fixed and c.preserve_check()
# Save exact active representatives for library-based material transfer.
masters={}
for ob in sc.objects:
 if ob.type!='MESH' or ob.hide_render:continue
 for slot in ob.material_slots:
  m=slot.material
  if not m:continue
  role=m.get('hs16_master_role') or m.get('warmth_role') or m.get('referenceColourProfile')
  if m.get('hs12_stone_material_version'):role='stone'
  if role in ('column','beam','floor','gable','apron','lower_board','railing','frame','door_panel','lattice','rafter','endgrain','tile','tile-end','stone','plaster','paper'):
   if role=='paper' and 'ondol' in ob.name:continue
   if role not in masters:masters[role]=m.name
assert len(masters)==17,(len(masters),masters)
native=D/'sarang-wood-r16.blend';bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False)
r=dict(source=str(source),sourceSha256=sha,native=str(native),nativeSha256=p.sha(native),architecture=before,changes=changes,source711DataPreserved=True,render1And2Preserved=True,lightsWorldExposureAndCameraUnchanged=True,userApproved=False,runtimeIntegrated=False,renderComplete=False,masters=masters)
p.write(D/'verification.json',r);p.write(D/'material-masters.json',dict(native=str(native),nativeSha256=r['nativeSha256'],roles=masters))
sc.render.resolution_x=1200;sc.render.resolution_y=800
r['preview']=p.render(sc,D,'preview.png',32)
bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene
assert p.architecture([sc.objects[n] for n in lock['objects']])==before and c.fixed_scene(sc)==fixed
assert p.sha(source)==sha
r.update(previewComplete=True,reopenedNativeVerified=True);p.write(D/'verification.json',r)
print('R16 preview verified',flush=True)
