"""Final material-only pass: grey fired coping and canonical toilet plaster."""
from pathlib import Path
import bpy,ast,hashlib,json,random,numpy as np
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'assets_unused/pending_review/hwalju-blueprint-review/side-connections'
ART=Path('C:/dev/hangulsori/ko_lernen_app/assets_unused/pending_review/personal_hanok_v3/화장실.png')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
for node in ast.parse((Path(__file__).parent/'refine_canonical_gates.py').read_text(encoding='utf8')).body:
 if isinstance(node,ast.FunctionDef) and node.name in ('new_material','pigment','components','art_uv'):exec(compile(ast.Module(body=[node],type_ignores=[]),'canonical surface','exec'))
bpy.ops.wm.open_mainfile(filepath=str(OUT/'scene.blend'));s=bpy.context.scene
items=[o for o in s.objects if o.type=='MESH' and o.get('construction_building') in ('main_gate','toilet','forecourt_wall')]
tile=next(m for m in bpy.data.materials if 'main_gate source ceramic 2' in m.name and m.name.startswith('Ansarang retained'))
changed=[]
for o in items:
 if o.get('construction_building')=='forecourt_wall' and any(o.name.endswith('.'+k) for k in ('pan','cover','ridge')):
  o.data.materials.clear();o.data.materials.append(tile);changed.append(o.name)
base_image=bpy.data.images.load(str(ART),check_existing=True);materials={};mapped=[]
regions={'plaster':[(.377,.451,.433,.697)]}
for o in items:
 if o.get('construction_building')=='toilet' and 'lime plaster' in o.data.materials[0].name.lower():
  o.data=o.data.copy();art_uv(o,'plaster');changed.append(o.name)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'scene.blend'),compress=True)
for o in s.objects:o.select_set(False)
for o in items:o.select_set(True)
bpy.context.view_layer.objects.active=items[0]
bpy.ops.export_scene.gltf(filepath=str(OUT/'crafted-forecourt.glb'),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True,export_extras=True)
report=json.loads((OUT/'forecourt-build-validation.json').read_text());report.update(nativeSceneSha256=sha(OUT/'scene.blend'),glbSha256=sha(OUT/'crafted-forecourt.glb'),finishSurfaceObjects=changed,toiletCanonicalSha256=sha(ART),canonicalImageEdited=False)
(OUT/'forecourt-build-validation.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print('FORECOURT SURFACES FINISHED',len(changed),flush=True)
