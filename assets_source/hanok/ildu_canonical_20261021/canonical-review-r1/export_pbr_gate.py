"""Bake approved native color, normal, roughness, metal and specular into actual 3D."""
import bpy,hashlib,json,sys
from pathlib import Path
OUT=Path(__file__).resolve().parent;ROOT=OUT.parent
sys.path.insert(0,str(OUT/'pbr-pipeline'))
gate=sys.argv[sys.argv.index('--')+1]
if gate=='left':
 from r12_pbr_delivery_fast import export_review,_glb_read,_glb_write
else:
 from r12_pbr_delivery import export_review,_glb_read,_glb_write
key={'left':'left_changgo','right':'right_ansarang','shrine':'sadangmun'}[gate]
native=ROOT/(gate+'-new.blend')
with native.open('rb') as f:expected=hashlib.file_digest(f,'sha256').hexdigest()
assign=json.loads((ROOT/'construction'/f'{gate}-object-stage-map.json').read_text(encoding='utf-8'))['assignments']
source=json.loads((ROOT/'construction/manifest.json').read_text(encoding='utf-8'))
record=next(g for g in source['gates'] if g['gate']==gate)
assert expected==record['sourceNativeSha256']
target=OUT/'pbr'/gate;target.mkdir(parents=True,exist_ok=True)
print('APPROVED NATIVE PBR START',gate,expected,len(assign),flush=True)
manifest=export_review(bpy,target,expected,expected,owners_selection={key:list(assign)},atlas_size=4096,samples=4,bake_margin=4,native_path=native,door_definitions=[])
path=target/(key+'.glb')
blob,doc,payload=_glb_read(path)
bound=set()
for node in doc.get('nodes',[]):
 extra=node.get('extras',{});name=extra.get('sourceObjectName')
 if name in assign and 'mesh' in node:
  extra.update(reviewStage=assign[name],sourceObject=name,reviewOnly=True,approvedNativeSha256=expected)
  node['extras']=extra;bound.add(name)
assert bound==set(assign),(len(bound),len(assign),set(assign)-bound)
assert len(doc.get('materials',[]))>0 and len(doc.get('images',[]))>=4
_glb_write(path,doc,payload)
# Preserve the structural preview as historical evidence; the reviewed viewer will use the new material asset.
dest=OUT/'models'/(key+'-pbr.glb');dest.write_bytes(path.read_bytes())
receipt=dict(gate=gate,key=key,sourceNativeSha256=expected,sourceNativeSaved=False,sourceMaterialsModified=False,sourceGeometryModified=False,partCount=len(bound),materialCount=len(doc['materials']),imageCount=len(doc['images']),model=dest.name,sha256=hashlib.sha256(dest.read_bytes()).hexdigest(),atlasSize=4096,channels=['baseColor','normal','roughnessMetallic','specular'],colorSource='actual source shader bake, no arbitrary recolor',nativeRenderPixelParityClaimed=False,sourcePartsFile=str((target/(key+'-source-parts.json')).relative_to(OUT)))
with native.open('rb') as f:assert hashlib.file_digest(f,'sha256').hexdigest()==expected
(OUT/(gate+'-pbr-export.json')).write_text(json.dumps(receipt,ensure_ascii=False,indent=2),encoding='utf-8')
print('APPROVED NATIVE PBR COMPLETE',json.dumps(receipt),flush=True)

