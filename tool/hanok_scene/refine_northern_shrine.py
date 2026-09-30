"""Review then apply shrine paint and the gate-specific surveyed roof structure."""
from pathlib import Path
import bpy,sys,json,hashlib,shutil
sys.path.insert(0,str(Path(__file__).parent))
from refine_northern_materials import geometry_fingerprint
from northern_shrine_gate_roof import refine_shrine_gate_roof
from northern_painted_timber import apply_painted_timber
from northern_tile_ends import refine_tile_end_profiles,give_tile_shells_depth
from northern_mineral_surfaces import apply_mineral_surfaces
OUT=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
apply='--apply' in sys.argv
bpy.ops.wm.open_mainfile(filepath=str(OUT/'scene.blend'));s=bpy.context.scene
contract=json.loads((OUT/'northern-contract.json').read_text(encoding='utf8'))
protected={o.name:geometry_fingerprint(o) for o in s.objects if o.type=='MESH' and o.get('construction_building')!='sadangmun'}
south={o.name:tuple(m.name if m else '' for m in o.data.materials) for o in s.objects if o.type=='MESH' and not o.get('northExtension')}
changes={}
changes['shrineGateCraft']=refine_shrine_gate_roof(s,contract['buildings'])
changes['tileEndProfiles']=refine_tile_end_profiles(s);changes['tileShells']=give_tile_shells_depth(s)
changes['mineralSurfaces']=apply_mineral_surfaces(s);changes['paintedTimber']=apply_painted_timber(s)
assert all(geometry_fingerprint(bpy.data.objects[name])==value for name,value in protected.items())
assert all(tuple(m.name if m else '' for m in bpy.data.objects[name].data.materials)==value for name,value in south.items())
name='scene.blend' if apply else 'shrine-craft-study.blend'
if apply and not (OUT/'before-shrine-craft.blend').exists():shutil.copy2(OUT/'scene.blend',OUT/'before-shrine-craft.blend')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/name),compress=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
proof={'nativeScene':name,'nativeSha256':sha(OUT/name),'protectedGeometryObjects':len(protected),'protectedSouthMaterialObjects':len(south),'changes':changes,'fullSurveyAccuracyClaimed':False}
(OUT/'shrine-craft-study.json').write_text(json.dumps(proof,ensure_ascii=False,indent=2),encoding='utf8')
if apply:
    bpy.context.view_layer.update()
    rec=next(r for r in contract['buildings'] if r['id']=='sadangmun')
    objects=[o for o in s.objects if o.type=='MESH' and o.get('construction_building')=='sadangmun']
    from mathutils import Vector
    points=[o.matrix_world@Vector(v) for o in objects for v in o.bound_box]
    rec['bounds']={'min':[min(p[k] for p in points) for k in range(3)],'max':[max(p[k] for p in points) for k in range(3)]};rec['meshes']=len(objects)
    for key,rows in changes.items():
        known={r.get('object',r.get('building')):r for r in contract.get(key,[]) if not r.get('object') or r['object'] in bpy.data.objects}
        known.update({r.get('object',r.get('building')):r for r in rows});contract[key]=list(known.values())
    (OUT/'northern-contract.json').write_text(json.dumps(contract,ensure_ascii=False,indent=2),encoding='utf8')
    for ob in s.objects:ob.select_set(False)
    obs=[o for o in s.objects if o.type=='MESH' and o.get('northExtension')]
    for ob in obs:ob.select_set(True);ob.hide_set(False);ob.hide_render=False
    bpy.context.view_layer.objects.active=obs[0]
    bpy.ops.export_scene.gltf(filepath=str(OUT/'northern.glb'),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True,export_extras=True)
print('SHRINE CRAFT',json.dumps({k:len(v) for k,v in changes.items()}),'protected geometry',len(protected),flush=True)
