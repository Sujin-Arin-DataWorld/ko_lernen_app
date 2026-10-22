"""Convert one existing building's exact native parts to stage-preserving PBR."""
import bpy,hashlib,json,struct,sys,time,faulthandler
from pathlib import Path
OUT=Path(__file__).resolve().parent;ROOT=OUT.parent
sys.path.insert(0,str(OUT/'pbr-pipeline'))
from r12_pbr_delivery_fast import export_review,_glb_read,_glb_write
faulthandler.dump_traceback_later(300,repeat=True)
key=sys.argv[sys.argv.index('--')+1]
variant=key.endswith('-standalone');basekey=key.removesuffix('-standalone')
catalog=json.loads((OUT/'catalog.json').read_text(encoding='utf-8'))
row=next(b for b in catalog['buildings'] if b['key']==basekey)
assert not row.get('newGate')
native=(OUT/(row['standaloneNative'] if variant and row.get('standaloneNative') else row['native'])).resolve();expected=row['standaloneNativeSha256'] if variant and row.get('standaloneNative') else row['nativeSha256']
def sha(p):
 with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
assert sha(native)==expected
structural=OUT/row['standaloneModel'] if variant else OUT/'models'/(key+'.glb');_,doc,_=_glb_read(structural)
assign={n['extras']['sourceObject']:n['extras'] for n in doc['nodes'] if 'reviewStage' in n.get('extras',{})}
assert assign and (variant or len(assign)==row['memberCount'])
target=OUT/'building-pbr'/key;target.mkdir(parents=True,exist_ok=True)
receipt=target/'surface-export.json'
if receipt.exists():
 r=json.loads(receipt.read_text(encoding='utf-8'))
 if r['sourceNativeSha256']==expected and sha(target/(key+'.glb'))==r['sha256']:
  print('REUSE VERIFIED COMPLETED',key,flush=True);sys.exit(0)
# A factory scene imports only this building, with its original object materials, data and dependencies.
bpy.ops.wm.read_factory_settings(use_empty=True)
with bpy.data.libraries.load(str(native),link=False) as (src,dst):
 missing=set(assign)-set(src.objects);assert not missing,missing
 dst.objects=list(assign)
for ob in list(bpy.data.objects):
 if ob.name not in bpy.context.scene.objects:bpy.context.scene.collection.objects.link(ob)
bpy.context.view_layer.update()
loaded={ob.name for ob in bpy.context.scene.objects if ob.type=='MESH' and ob.name in assign}
assert loaded==set(assign)
print('EXACT BUILDING APPEND',key,len(loaded),flush=True)
start=time.monotonic()
manifest=export_review(bpy,target,expected,expected,owners_selection={key:list(assign)},atlas_size=4096,samples=4,bake_margin=4,native_path=native,door_definitions=[])
model=target/(key+'.glb');_,result,payload=_glb_read(model)
bound=set()
for node in result['nodes']:
 extras=node.get('extras',{});name=extras.get('sourceObjectName')
 if name in assign and 'mesh' in node:
  extras.update(assign[name]);extras['approvedNativeSha256']=expected;node['extras']=extras;bound.add(name)
assert bound==set(assign)
assert result['materials'] and len(result['images'])>=4
_glb_write(model,result,payload)
assert sha(native)==expected
r=dict(key=key,sourceNative=str(native),sourceNativeSha256=expected,sourceNativeUnchanged=True,sourceMaterials='actual native shader bake',members=len(bound),stageCount=len(row['steps']),model=model.relative_to(OUT).as_posix(),sha256=sha(model),materials=len(result['materials']),images=len(result['images']),atlasSize=4096,seconds=round(time.monotonic()-start,1),geometryPreservedByExporter=True,lightingBaked=False)
receipt.write_text(json.dumps(r,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('BUILDING MATERIAL COMPLETE',json.dumps(r),flush=True)
