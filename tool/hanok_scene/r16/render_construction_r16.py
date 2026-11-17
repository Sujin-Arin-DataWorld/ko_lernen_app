"""Same native shader bindings at every cumulative curriculum review cut."""
import bpy,sys,json,hashlib,shutil
from pathlib import Path
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P))
import produce as p
import construction_stages_r16 as stages
key=sys.argv[-1];D=P/'family-r16'/key;D.mkdir(parents=True,exist_ok=True);images=D/'stages';images.mkdir(exist_ok=True)
if key=='sarang':
 source=P/'sarang-wood-r16/sarang-wood-r16.blend';verification=p.read(P/'sarang-wood-r16/verification.json')
 names=p.read(P/'sarang/geometry-lock.json')['objects'];binding=p.read(P/'sarang/construction-binding.json')
else:
 verification=p.read(D/'verification.json');source=Path(verification['native']);names=verification['objects'];binding=p.read(D/'construction-binding.json')
source_sha=p.sha(source);assert source_sha==verification['nativeSha256']
bpy.ops.wm.open_mainfile(filepath=str(source));sc=bpy.context.scene;obs=[sc.objects[n] for n in names]
before=p.architecture(obs);assert before==verification['architecture'];assert p.stage_map(key,obs)==binding
def signature():
 rows=[(ob.name,i,s.material.name if s.material else None) for ob in sc.objects if ob.type=='MESH' for i,s in enumerate(ob.material_slots)]
 return hashlib.sha256(json.dumps(sorted(rows)).encode()).hexdigest()
material_hash=signature();selection=stages.stage_sets(sc,key,obs,binding)
p.write(D/'stage-selection.json',selection)
managed=[ob for ob in sc.objects if ob.type=='MESH' and not ob.get('displayOnly') and 'display ground' not in ob.name.lower()]
# Save a separate native timeline. The full native and original selectors remain
# intact, while users can rotate any stage in Blender by changing its frame.
sc.frame_start=1;sc.frame_end=len(selection['steps'])
for row in selection['steps']:
 sc.frame_set(row['sequence'])
 stages.set_stage(sc,selection,row['sequence'])
 for ob in managed:
  ob.keyframe_insert(data_path='hide_render',frame=row['sequence'])
  ob.hide_viewport=ob.hide_render
  ob.keyframe_insert(data_path='hide_viewport',frame=row['sequence'])
stages.restore(sc,selection)
sc.frame_set(sc.frame_end)
timeline=D/'stage.blend';bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(timeline),compress=True,relative_remap=False)
bpy.ops.wm.open_mainfile(filepath=str(timeline));sc=bpy.context.scene
managed=[sc.objects[name] for name in selection['baseline']]
stages.restore(sc,selection)
assert p.architecture([sc.objects[n] for n in names])==before
assert p.stage_map(key,[sc.objects[n] for n in names])==binding
assert signature()==material_hash
manifest=dict(key=key,source=str(source),sourceSha256=source_sha,native=str(timeline),nativeSha256=p.sha(timeline),architecture=before,materialBindingSha256=material_hash,selection='stage-selection.json',stageCount=len(selection['steps']),steps=[],renderComplete=False,userApproved=False,runtimeIntegrated=False)
previous={};old_path=D/'stage-renders.json';old=p.read(old_path) if old_path.exists() else {}
old_rows={r['sequence']:r for r in old.get('steps',[])} if old.get('sourceSha256')==source_sha else {}
sc.render.resolution_x=800;sc.render.resolution_y=533;sc.render.resolution_percentage=100
sc.render.threads_mode='FIXED';sc.render.threads=6;sc.render.use_persistent_data=False
sc.cycles.use_adaptive_sampling=True;sc.cycles.adaptive_threshold=.045;sc.cycles.adaptive_min_samples=8
camera=dict(position=list(sc.camera.location),rotation=list(sc.camera.rotation_euler),ortho=sc.camera.data.ortho_scale,resolution=[800,533])
for row in selection['steps']:
 sequence=row['sequence'];sc.frame_set(sequence)
 expected=set(row['visibleObjects']);actual={o.name for o in managed if not o.hide_render}
 assert actual==expected,(key,sequence,'timeline visibility mismatch',sorted(actual^expected)[:8])
 assert signature()==material_hash
 filename=f'{sequence:02d}.png';dest=images/filename
 visible_hash=hashlib.sha256(json.dumps(sorted(actual)).encode()).hexdigest()
 out=dict(sequence=sequence,processId=row['processId'],label=row['label'],isFinal=row.get('isFinal',sequence==sc.frame_end),visibleMembers=len(actual),visibleSetSha256=visible_hash,materialBindingSha256=material_hash,camera=camera,file='stages/'+filename)
 if sequence in old_rows and old_rows[sequence].get('visibleSetSha256')==visible_hash and old_rows[sequence].get('materialBindingSha256')==material_hash and old_rows[sequence].get('camera')==camera and dest.exists() and p.sha(dest)==old_rows[sequence]['sha256']:
  out.update(sha256=p.sha(dest),reusedVerifiedRender=True)
 elif visible_hash in previous:
  shutil.copy2(previous[visible_hash],dest);out.update(sha256=p.sha(dest),reuseReason='same preserved cumulative geometry; existing curriculum step retained')
 else:
  result=p.render(sc,images,filename,16);out.update(sha256=result['sha256'],seconds=result['seconds'],samples=16)
 previous[visible_hash]=dest;manifest['steps'].append(out);p.write(old_path,manifest)
 print('STAGE_R16',key,sequence,len(actual),flush=True)
sc.frame_set(sc.frame_end);stages.restore(sc,selection)
assert signature()==material_hash and p.architecture([sc.objects[n] for n in names])==before
assert p.sha(source)==source_sha and p.sha(timeline)==manifest['nativeSha256']
manifest.update(renderComplete=True,reopenedNativeVerified=True,allStageMaterialsIdenticalToSavedNative=True,allStageVisibilityVerified=True,sourceFilePreserved=True)
p.write(old_path,manifest);print('ALL_STAGES_R16_VERIFIED',key,len(manifest['steps']),flush=True)
