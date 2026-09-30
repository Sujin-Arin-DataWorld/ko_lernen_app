"""Preserve the painted-timber pigment multiplier in the review GLB."""
from pathlib import Path
import bpy,sys,json,hashlib,struct
sys.path.insert(0,str(Path(__file__).parent))
from northern_painted_timber import painted_material,OUT
from refine_northern_materials import geometry_fingerprint

bpy.ops.wm.open_mainfile(filepath=str(OUT/'scene.blend'))
s=bpy.context.scene
before={o.name:geometry_fingerprint(o) for o in s.objects if o.type=='MESH'}
for kind in ('red','green'):painted_material(kind,rebuild=True)
assert all(geometry_fingerprint(bpy.data.objects[n])==v for n,v in before.items())
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'scene.blend'),compress=True)
for ob in s.objects:ob.select_set(False)
obs=[o for o in s.objects if o.type=='MESH' and o.get('northExtension')]
for ob in obs:ob.select_set(True);ob.hide_set(False);ob.hide_render=False
bpy.context.view_layer.objects.active=obs[0]
bpy.ops.export_scene.gltf(filepath=str(OUT/'northern.glb'),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True,export_extras=True)

with (OUT/'northern.glb').open('rb') as stream:
    stream.seek(12);size,kind=struct.unpack('<II',stream.read(8))
    assert kind==0x4e4f534a
    doc=json.loads(stream.read(size))
checks=[]
for kind in ('red','green'):
    mat=painted_material(kind);expected=list(mat['linearPigmentTint'])
    variants=[(i,m) for i,m in enumerate(doc['materials']) if m['name']==mat.name or m['name'].startswith(mat.name+'.')]
    assert variants,mat.name
    for i,m in variants:
        pbr=m['pbrMetallicRoughness'];actual=pbr.get('baseColorFactor',[1,1,1,1])
        assert all(abs(a-b)<1e-6 for a,b in zip(actual,expected)),(m['name'],actual,expected)
        assert 'baseColorTexture' in pbr and 'normalTexture' in m
        uv=pbr['baseColorTexture'].get('texCoord',0);normaluv=m['normalTexture'].get('texCoord',0)
        prims=[p for mesh in doc['meshes'] for p in mesh['primitives'] if p.get('material')==i]
        assert prims and all(f'TEXCOORD_{uv}' in p['attributes'] and f'TEXCOORD_{normaluv}' in p['attributes'] for p in prims)
        checks.append({'material':m['name'],'baseColorFactor':actual,'primitives':len(prims),'colorAndNormalUVPresent':True})
sha=lambda name:hashlib.file_digest((OUT/name).open('rb'),'sha256').hexdigest()
proof={'nativeSha256':sha('scene.blend'),'glbSha256':sha('northern.glb'),'unchangedGeometryObjects':len(before),'checks':checks,'passed':True}
(OUT/'paint-export-validation.json').write_text(json.dumps(proof,ensure_ascii=False,indent=2),encoding='utf8')
print('PAINT EXPORT VERIFIED',json.dumps(proof),flush=True)
