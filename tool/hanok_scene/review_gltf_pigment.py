"""Preserve native texture-times-constant tint in glTF without baking artwork.

Blender 5.2 exports the texture but drops the MixRGB MULTIPLY constant. Write the
equivalent standard baseColorFactor; mesh buffers and embedded pixels untouched.
"""
import struct,json,hashlib
from pathlib import Path
FACTORS={'Sep29 sadangmun ':[.46,.59,.68,1],'Sep29 sadang ':[.64,.77,.82,1],'Sep29 altar ':[.48,.26,.24,1]}
def preserve_tints(path):
 path=Path(path);blob=path.read_bytes();n=struct.unpack_from('<I',blob,12)[0];doc=json.loads(blob[20:20+n]);binary=blob[20+n:];count=0
 for mat in doc.get('materials',[]):
  for prefix,factor in FACTORS.items():
   if mat.get('name','').startswith(prefix):mat.setdefault('pbrMetallicRoughness',{})['baseColorFactor']=factor;count+=1;break
 if count:
  data=json.dumps(doc,separators=(',',':'),ensure_ascii=False).encode();data+=b' '*((-len(data))%4)
  result=struct.pack('<III',0x46546c67,2,20+len(data)+len(binary))+struct.pack('<II',len(data),0x4e4f534a)+data+binary;path.write_bytes(result)
  assert result[20+len(data):]==binary
 return count
if __name__=='__main__':
 N=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/northern-court';D=Path('C:/dev/hangulsori/sites/ildu-survey-review-20260929/dist/estate');sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
 m=json.loads((N/'redraw-3d-manifest.json').read_text())
 for r in m:
  if r['building'] not in ('sadang','ansarang','sadangmun'):continue
  p=N/'review3d'/r['file'];r['nativePigmentFactors']=preserve_tints(p);r['sha256']=sha(p);r['bytes']=p.stat().st_size
 (N/'redraw-3d-manifest.json').write_text(json.dumps(m,indent=2))
 p=N/'review3d/current-estate.glb';count=preserve_tints(p);r=json.loads((D/'manifest.json').read_text(encoding='utf8'));blob=p.read_bytes();r['chunks']=[];r['bytes']=len(blob);r['glbSha256']=sha(p);r['nativePigmentFactors']=count
 for i,start in enumerate(range(0,len(blob),20*1024**2)):
  piece=D/f'current-estate-{i:02}.bin';piece.write_bytes(blob[start:start+20*1024**2]);r['chunks'].append({'file':piece.name,'bytes':piece.stat().st_size,'sha256':sha(piece)})
 for target in (D/'manifest.json',N/'current-estate-delivery.json'):target.write_text(json.dumps(r,ensure_ascii=False,indent=2),encoding='utf8')
 print('Native pigment factors retained; binary mesh and image buffers unchanged',count)
