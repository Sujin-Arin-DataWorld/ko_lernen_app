"""Review/apply solid northern roof bedding without altering other geometry."""
from pathlib import Path
import bpy,sys,json,hashlib,shutil
sys.path.insert(0,str(Path(__file__).parent))
from northern_roof_envelope import refine_roof_envelopes,OUT,SCOPE
from northern_mineral_surfaces import apply_mineral_surfaces
from refine_northern_materials import geometry_fingerprint
from northern_wall_joints import close_anchae_wall_joints,WALL_NAMES
apply='--apply' in sys.argv
bpy.ops.wm.open_mainfile(filepath=str(OUT/'scene.blend'));scene=bpy.context.scene
contract=json.loads((OUT/'northern-contract.json').read_text(encoding='utf8'))
protected={o.name:(geometry_fingerprint(o),tuple(m.name for m in o.data.materials)) for o in scene.objects if o.type=='MESH' and o.name not in WALL_NAMES and not (o.get('construction_building') in SCOPE and 'roof continuous bed' in o.name)}
walls=close_anchae_wall_joints(scene,contract['buildings'])
changes=refine_roof_envelopes(scene,contract['buildings']);minerals=apply_mineral_surfaces(scene)
assert all((geometry_fingerprint(bpy.data.objects[n]),tuple(m.name for m in bpy.data.objects[n].data.materials))==fp for n,fp in protected.items())
name='scene.blend' if apply else 'roof-envelope-study.blend'
if apply and not (OUT/'before-roof-envelopes.blend').exists():shutil.copy2(OUT/'scene.blend',OUT/'before-roof-envelopes.blend')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/name),compress=True)
proof={'nativeScene':name,'nativeSha256':hashlib.sha256((OUT/name).read_bytes()).hexdigest(),'unchangedOtherMeshes':len(protected),'roofEnvelopes':changes,'wallJoints':walls,'fullSurveyAccuracyClaimed':False}
(OUT/'roof-envelope-study.json').write_text(json.dumps(proof,ensure_ascii=False,indent=2),encoding='utf8')
if apply:
    if changes:contract['roofEnvelopes']=changes
    if walls:contract['wallJoints']=walls
    keep={r['object']:r for r in contract.get('mineralSurfaces',[]) if r['object'] in bpy.data.objects};keep.update({r['object']:r for r in minerals});contract['mineralSurfaces']=list(keep.values())
    for rec in contract['buildings']:rec['meshes']=sum(o.type=='MESH' and o.get('construction_building')==rec['id'] for o in scene.objects)
    (OUT/'northern-contract.json').write_text(json.dumps(contract,ensure_ascii=False,indent=2),encoding='utf8')
    for ob in scene.objects:ob.select_set(False)
    obs=[o for o in scene.objects if o.type=='MESH' and o.get('northExtension')]
    for ob in obs:ob.select_set(True);ob.hide_set(False);ob.hide_render=False
    bpy.context.view_layer.objects.active=obs[0]
    bpy.ops.export_scene.gltf(filepath=str(OUT/'northern.glb'),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True,export_extras=True)
print('Closed roof envelopes:',len(changes),'records;',len(protected),'other meshes unchanged',flush=True)
