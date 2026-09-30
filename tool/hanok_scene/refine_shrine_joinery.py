"""Review or apply the photographed shrine joinery without rebuilding the estate."""
from pathlib import Path
import bpy,sys,json,hashlib,shutil
sys.path.insert(0,str(Path(__file__).parent))
from northern_shrine_joinery import refine_shrine_joinery,OUT
from northern_mineral_surfaces import apply_mineral_surfaces
from northern_painted_timber import apply_painted_timber
from refine_northern_materials import geometry_fingerprint
apply='--apply' in sys.argv
bpy.ops.wm.open_mainfile(filepath=str(OUT/'scene.blend'));s=bpy.context.scene
contract=json.loads((OUT/'northern-contract.json').read_text(encoding='utf8'))
protected={o.name:(geometry_fingerprint(o),tuple(m.name if m else '' for m in o.data.materials)) for o in s.objects if o.type=='MESH' and o.get('construction_building')!='sadang'}
changes={'shrineJoinery':refine_shrine_joinery(s,contract['buildings'])}
changes['mineralSurfaces']=apply_mineral_surfaces(s);changes['paintedTimber']=apply_painted_timber(s)
assert all((geometry_fingerprint(bpy.data.objects[n]),tuple(m.name if m else '' for m in bpy.data.objects[n].data.materials))==v for n,v in protected.items())
name='scene.blend' if apply else 'shrine-joinery-study.blend'
if apply and not (OUT/'before-shrine-joinery.blend').exists():shutil.copy2(OUT/'scene.blend',OUT/'before-shrine-joinery.blend')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/name),compress=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
proof={'nativeScene':name,'nativeSha256':sha(OUT/name),'unchangedOtherBuildingMeshes':len(protected),'changes':changes,'fullSurveyAccuracyClaimed':False}
(OUT/'shrine-joinery-study.json').write_text(json.dumps(proof,ensure_ascii=False,indent=2),encoding='utf8')
if apply:
    bpy.context.view_layer.update()
    from mathutils import Vector
    rec=next(r for r in contract['buildings'] if r['id']=='sadang');objects=[o for o in s.objects if o.type=='MESH' and o.get('construction_building')=='sadang']
    pts=[o.matrix_world@Vector(v) for o in objects for v in o.bound_box]
    rec['bounds']={'min':[min(p[k] for p in pts) for k in range(3)],'max':[max(p[k] for p in pts) for k in range(3)]};rec['meshes']=len(objects)
    for key,rows in changes.items():
        known={r.get('object',r.get('building')):r for r in contract.get(key,[]) if not r.get('object') or r['object'] in bpy.data.objects}
        known.update({r.get('object',r.get('building')):r for r in rows});contract[key]=list(known.values())
    (OUT/'northern-contract.json').write_text(json.dumps(contract,ensure_ascii=False,indent=2),encoding='utf8')
    for ob in s.objects:ob.select_set(False)
    obs=[o for o in s.objects if o.type=='MESH' and o.get('northExtension')]
    for ob in obs:ob.select_set(True);ob.hide_set(False);ob.hide_render=False
    bpy.context.view_layer.objects.active=obs[0]
    bpy.ops.export_scene.gltf(filepath=str(OUT/'northern.glb'),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True,export_extras=True)
print('SHRINE JOINERY',name,len(protected),'other meshes preserved',flush=True)
