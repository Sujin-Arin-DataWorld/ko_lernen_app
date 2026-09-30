"""Retain legacy building metadata and native palette in the web delivery only.

Legacy procedural shader colour ramps are unsupported by glTF. Use their authored
midpoint palette for the overview. Native shader graphs, model, and image bytes
remain unchanged; detailed procedural surface grain remains in Blender renders.
"""
from pathlib import Path
import bpy,json,struct,hashlib,collections
N=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
D=Path('C:/dev/hangulsori/sites/ildu-survey-review-20260929/dist/estate')
bpy.ops.wm.open_mainfile(filepath=str(N/('estate-fabric.blend' if (N/'estate-fabric.blend').exists() else 'detail-redraw.blend')))
p=N/'review3d/current-estate.glb';blob=p.read_bytes();size=struct.unpack_from('<I',blob,12)[0];doc=json.loads(blob[20:20+size]);binary=blob[20+size:]
updated=[]
for m in doc['materials']:
 pbr=m.get('pbrMetallicRoughness',{});native=bpy.data.materials.get(m['name'])
 if 'baseColorTexture' in pbr or 'baseColorFactor' in pbr or not native or not native.use_nodes:continue
 ramps=[n for n in native.node_tree.nodes if n.type=='VALTORGB']
 if not ramps:continue
 pbr['baseColorFactor']=[float(v) for v in ramps[0].color_ramp.evaluate(.5)]
 bsdf=next((n for n in native.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
 if bsdf:pbr['roughnessFactor']=float(bsdf.inputs['Roughness'].default_value)
 m.setdefault('extras',{})['web_palette']='Native colour ramp midpoint; procedural micrograin retained in Blender renders'
 updated.append(m['name'])
for n in doc['nodes']:
 if 'mesh' not in n:continue
 e=n.setdefault('extras',{});e.setdefault('source_object_name',n['name'])
 if 'construction_building' not in e:
  # All untagged legacy objects are the established Sarang/Jung pair. Source
  # naming explicitly marks Jung; the remaining legacy prefixes are Sarang.
  e['construction_building']='jung' if 'jung' in n['name'].lower() else 'sarang'
data=json.dumps(doc,separators=(',',':'),ensure_ascii=False).encode();data+=b' '*((-len(data))%4)
result=struct.pack('<III',0x46546c67,2,20+len(data)+len(binary))+struct.pack('<II',len(data),0x4e4f534a)+data+binary
assert result[20+len(data):]==binary
p.write_bytes(result);sha=lambda b:hashlib.sha256(b).hexdigest()
r=json.loads((D/'manifest.json').read_text(encoding='utf8'));r.update(bytes=len(result),glbSha256=sha(result),chunks=[])
for i,start in enumerate(range(0,len(result),20*1024**2)):
 piece=result[start:start+20*1024**2];f=D/f'current-estate-{i:02}.bin';f.write_bytes(piece);r['chunks'].append({'file':f.name,'bytes':len(piece),'sha256':sha(piece)})
r['meshCounts']=dict(collections.Counter(n['extras']['construction_building'] for n in doc['nodes'] if 'mesh'in n))
r['webMaterialNote']='Legacy procedural materials use native palette midpoint; complete procedural micrograin is available in native scene and renders.'
r['deliveryPaletteFix']={'materials':updated,'geometryAndImagesUnchanged':True}
for f in (D/'manifest.json',N/'current-estate-delivery.json'):f.write_text(json.dumps(r,ensure_ascii=False,indent=2),encoding='utf8')
print('PALETTE AND BUILDING METADATA',len(updated),r['meshCounts'],flush=True)
