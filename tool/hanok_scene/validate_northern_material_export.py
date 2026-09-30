"""Read back the delivered GLB, including actual UV indices and image bytes."""
from pathlib import Path
import json,struct,hashlib
from glb_parts import read
OUT=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
doc,blob=read(OUT/'northern.glb');checks=[]
def accessor(index):
    a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']]
    fmt={5121:'B',5123:'H',5125:'I',5126:'f'}[a['componentType']];width={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']]
    start=v.get('byteOffset',0)+a.get('byteOffset',0);pattern='<'+fmt*width;size=struct.calcsize(pattern);stride=v.get('byteStride',size)
    return [struct.unpack_from(pattern,blob,start+i*stride) for i in range(a['count'])]
for mi,m in enumerate(doc['materials']):
    if not m['name'].startswith(('Illustrated mineral paint ','Illustrated shrine dancheong')):continue
    pbr=m['pbrMetallicRoughness'];prims=[p for mesh in doc['meshes'] for p in mesh['primitives'] if p.get('material')==mi]
    if not prims:continue
    if 'linearPigmentTint' in m.get('extras',{}):
        factor=pbr.get('baseColorFactor',[1,1,1,1]);expected=m['extras']['linearPigmentTint']
        assert all(abs(a-b)<1e-6 for a,b in zip(factor,expected)),m['name']
        assert 'normalTexture' in m,m['name']
    color=pbr['baseColorTexture'];uvkey='TEXCOORD_'+str(color.get('texCoord',0))
    assert all(uvkey in p['attributes'] for p in prims)
    if 'dancheong' in m['name']:
        vs=[]
        for p in prims:
            coords=accessor(p['attributes'][uvkey]);ids=[i[0] for i in accessor(p['indices'])] if 'indices' in p else range(len(coords))
            vs.extend(coords[i][1] for i in ids)
        assert min(vs)>.230 and max(vs)<.770,(min(vs),max(vs))
        im=doc['images'][doc['textures'][color['index']]['source']];bv=doc['bufferViews'][im['bufferView']];start=bv.get('byteOffset',0)
        digest=hashlib.sha256(blob[start:start+bv['byteLength']]).hexdigest()
        assert digest==hashlib.sha256((OUT/'materials/hanok-dancheong-frieze-v1.png').read_bytes()).hexdigest()
    checks.append({'material':m['name'],'primitives':len(prims),'passed':True})
assert any('dancheong' in r['material'] for r in checks)
sha=lambda name:hashlib.sha256((OUT/name).read_bytes()).hexdigest()
proof={'nativeSha256':sha('scene.blend'),'glbSha256':sha('northern.glb'),'checks':checks,'passed':True}
(OUT/'paint-export-validation.json').write_text(json.dumps(proof,ensure_ascii=False,indent=2),encoding='utf8')
print('Exported paint factors, ornament image bytes and used UV coordinates verified:',len(checks),'materials')
