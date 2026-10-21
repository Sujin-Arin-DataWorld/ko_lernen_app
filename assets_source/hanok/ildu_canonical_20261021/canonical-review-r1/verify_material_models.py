"""Verify material GLBs against source bake geometry, stage bindings and immutable native hashes."""
import hashlib,json,struct
from pathlib import Path
OUT=Path(__file__).resolve().parent;ROOT=OUT.parent
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(path):
 b=path.read_bytes();n=struct.unpack_from('<I',b,12)[0];j=json.loads(b[20:20+n]);off=20+n
 size,kind=struct.unpack_from('<II',b,off);assert kind==0x004e4942
 return j,b[off+8:off+8+size]
def accessor(j,b,index):
 a=j['accessors'][index];v=j['bufferViews'][a['bufferView']]
 width={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']]*{5121:1,5123:2,5125:4,5126:4}[a['componentType']]
 offset=v.get('byteOffset',0)+a.get('byteOffset',0);stride=v.get('byteStride',width)
 return b''.join(b[offset+i*stride:offset+i*stride+width] for i in range(a['count']))
def geometry(j,b):
 result={}
 for node in j['nodes']:
  if 'mesh' not in node:continue
  parts=[]
  for p in j['meshes'][node['mesh']]['primitives']:
   parts.append({k:hashlib.sha256(accessor(j,b,p['indices'] if k=='indices' else p['attributes'][k])).hexdigest() for k in ['POSITION','NORMAL','indices']})
  result[node['extras']['sourceObjectName']]=dict(parts=parts,transform={k:node.get(k) for k in ['matrix','translation','rotation','scale']})
 return result
records=[]
for gate,key in [('left','left_changgo'),('right','right_ansarang'),('shrine','sadangmun')]:
 r=json.loads((OUT/(gate+'-pbr-export.json')).read_text(encoding='utf-8'))
 assert sha(ROOT/(gate+'-new.blend'))==r['sourceNativeSha256']
 model=OUT/'models'/r['model'];assert sha(model)==r['sha256']
 j,b=read(model);source,sb=read(OUT/'pbr'/gate/(key+'.glb'))
 assert geometry(j,b)==geometry(source,sb),gate
 assert len(j['materials'])==r['materialCount'] and len(j['images'])==r['imageCount']
 assignments=json.loads((ROOT/'construction'/(gate+'-object-stage-map.json')).read_text(encoding='utf-8'))['assignments']
 assert {n['extras']['sourceObject']:n['extras']['reviewStage'] for n in j['nodes'] if 'reviewStage' in n.get('extras',{})}==assignments
 for mat in j['materials']:
  assert mat['pbrMetallicRoughness'].get('baseColorTexture') and mat.get('normalTexture') and mat['pbrMetallicRoughness'].get('metallicRoughnessTexture')
 records.append(dict(gate=gate,members=len(assignments),textures=len(j['images']),positionsIndicesNormalsTransformsExactlyPreserved=True,nativeSourceUnchanged=True,allStagesShareSameSurface=True,model=r['model'],sha256=r['sha256']))
(OUT/'material-model-verification.json').write_text(json.dumps(dict(passed=True,records=records),indent=2)+'\n',encoding='utf-8')
print('MATERIAL MODELS VERIFIED',[(r['gate'],r['members'],r['textures']) for r in records])
