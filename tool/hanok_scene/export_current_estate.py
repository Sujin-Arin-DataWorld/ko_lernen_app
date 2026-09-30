"""Whole-estate review from the exact current candidate, without repositioning."""
from pathlib import Path
import bpy,json,hashlib,sys,collections
sys.path.insert(0,str(Path(__file__).parent))
from review_gltf_pigment import preserve_tints
ROOT=Path(__file__).resolve().parents[2];N=ROOT/'assets_unused/pending_review/hwalju-blueprint-review/northern-court';D=Path('C:/dev/hangulsori/sites/ildu-survey-review-20260929/dist/estate');D.mkdir(exist_ok=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
candidate=N/'estate-fabric.blend'
source=candidate if candidate.exists() else N/'detail-redraw.blend'
bpy.ops.wm.open_mainfile(filepath=str(source));s=bpy.context.scene
selected=[]
for o in s.objects:
 o.select_set(False)
 if o.type!='MESH' or o.hide_render or o.get('construction_building')=='context':continue
 bid=o.get('construction_building','site')
 if bid in ('sarang','jung'):
  stage=16 if bid=='sarang' else 12
  if not o.get('construction_first',0)<=stage<=o.get('construction_last',99):continue
 o.hide_set(False);o.select_set(True);selected.append(o)
bpy.context.view_layer.objects.active=selected[0]
out=N/'review3d/current-estate.glb'
bpy.ops.export_scene.gltf(filepath=str(out),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True,export_extras=True,export_draco_mesh_compression_enable=True,export_draco_mesh_compression_level=6,export_draco_position_quantization=18,export_draco_normal_quantization=12,export_draco_texcoord_quantization=16)
preserve_tints(out)
blob=out.read_bytes();chunks=[];size=20*1024**2
for i,start in enumerate(range(0,len(blob),size)):
 p=D/f'current-estate-{i:02}.bin';p.write_bytes(blob[start:start+size]);chunks.append({'file':p.name,'bytes':p.stat().st_size,'sha256':sha(p)})
contract=json.loads((N/'detail-redraw-contract.json').read_text(encoding='utf8'));south=json.loads((N.parent/'side-connections/connection-contract.json').read_text(encoding='utf8'))
fabric=json.loads((N/'estate-fabric-contract.json').read_text(encoding='utf8')) if candidate.exists() else None
report={'sceneSha256':sha(source),'sceneFile':source.name,'glbSha256':sha(out),'bytes':len(blob),'chunks':chunks,'meshCounts':dict(collections.Counter(o.get('construction_building','site') for o in selected)),'buildings':contract['buildings']+([fabric['toilet1']] if fabric else []),'ansarang':south['buildings']['ansarang'],'walls':contract['walls']+(fabric['wallRoutes'] if fabric else []),'doors':contract['doors']+south['doors'],'layout':'Original shared world coordinates; #11 small canonical-style candidate and 002 wall routes added separately','precision':'18-bit Draco positions; approved originals unchanged'}
(D/'manifest.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8');(N/'current-estate-delivery.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
print('CURRENT ESTATE EXPORTED',len(blob),len(selected),report['meshCounts'],flush=True)
import runpy
runpy.run_path(str(Path(__file__).with_name('repair_estate_delivery.py')),run_name='__main__')
runpy.run_path(str(Path(__file__).with_name('bake_estate_legacy_palette.py')),run_name='__main__')
