"""Replace stage plates with one continuous terrain; preserve building bytes."""
from pathlib import Path
import copy,hashlib,json,struct

ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'assets_unused/pending_review/hwalju-blueprint-review'
OUT=SOURCE/'terrain'
def load(path):
    data=path.read_bytes();magic,version,size=struct.unpack_from('<III',data)
    assert magic==0x46546c67 and version==2 and size==len(data)
    n,t=struct.unpack_from('<II',data,12);assert t==0x4e4f534a
    doc=json.loads(data[20:20+n]);m,t=struct.unpack_from('<II',data,20+n);assert t==0x004e4942
    return doc,data[28+n:28+n+m]
def sha(data):return hashlib.sha256(data).hexdigest()
doc,original=load(SOURCE/'pair-corrected.glb');patch,extra=load(OUT/'corrected-parts.glb')
before=copy.deepcopy(doc)
removed=[i for i,n in enumerate(doc['nodes']) if n.get('extras',{}).get('source_object_name','') in ('Stage.Jung.site','Stage.Sarang.site')]
assert len(removed)==2
for scene in doc['scenes']:scene['nodes']=[i for i in scene['nodes'] if i not in removed]
offset=len(original)
assert offset%4==0
keys=['bufferViews','accessors','images','samplers','textures','materials','meshes','nodes']
base={k:len(doc.get(k,[])) for k in keys}
def remap_texture_infos(value):
    if isinstance(value,dict):
        for key,item in value.items():
            if key.endswith('Texture') and isinstance(item,dict) and 'index' in item:item['index']+=base['textures']
            else:remap_texture_infos(item)
    elif isinstance(value,list):
        for item in value:remap_texture_infos(item)
for key in keys:
    for item in patch.get(key,[]):
        v=copy.deepcopy(item)
        if key=='bufferViews':v['buffer']=0;v['byteOffset']=v.get('byteOffset',0)+offset
        elif key=='accessors':
            if 'bufferView' in v:v['bufferView']+=base['bufferViews']
            assert 'sparse' not in v
        elif key=='images':
            if 'bufferView' in v:v['bufferView']+=base['bufferViews']
        elif key=='textures':
            if 'source' in v:v['source']+=base['images']
            if 'sampler' in v:v['sampler']+=base['samplers']
        elif key=='materials':remap_texture_infos(v)
        elif key=='meshes':
            for p in v['primitives']:
                p['attributes']={a:i+base['accessors'] for a,i in p['attributes'].items()}
                if 'indices' in p:p['indices']+=base['accessors']
                if 'material' in p:p['material']+=base['materials']
        elif key=='nodes':
            if 'mesh' in v:v['mesh']+=base['meshes']
            if 'children' in v:v['children']=[i+base['nodes'] for i in v['children']]
        doc.setdefault(key,[]).append(v)
doc['scenes'][doc.get('scene',0)]['nodes'].extend(i+base['nodes'] for i in patch['scenes'][patch.get('scene',0)]['nodes'])
doc['buffers']=[{'byteLength':len(original)+len(extra)}]
doc['extensionsUsed']=sorted(set(doc.get('extensionsUsed',[])+patch.get('extensionsUsed',[])))
doc['asset']['extras']={'review':'Continuous courtyard from drawings039/042/043; retain prior hwalju correction','sourceGlbSha256':sha((SOURCE/'pair-corrected.glb').read_bytes())}
j=json.dumps(doc,separators=(',',':')).encode();j+=b' '*((-len(j))%4)
binary=original+extra;binary+=b'\0'*((-len(binary))%4)
out=struct.pack('<III',0x46546c67,2,28+len(j)+len(binary))+struct.pack('<II',len(j),0x4e4f534a)+j+struct.pack('<II',len(binary),0x004e4942)+binary
(OUT/'pair-corrected.glb').write_bytes(out)
actual,buffer=load(OUT/'pair-corrected.glb')
assert buffer[:len(original)]==original
assert all(actual['nodes'][i]==n for i,n in enumerate(before['nodes']))
assert all(actual['meshes'][i]==n for i,n in enumerate(before['meshes']))
assert all(actual['materials'][i]==n for i,n in enumerate(before['materials']))
assert all(i not in actual['scenes'][0]['nodes'] for i in removed)
report={'sourceGlbSha256':sha((SOURCE/'pair-corrected.glb').read_bytes()),'glbSha256':sha(out),'bytes':len(out),'retainedOriginalBinaryBytes':len(original),'retainedBinarySha256':sha(original),'originalNodesMeshesMaterialsIdentical':True,'detachedOldGroundNodes':removed,'newObjects':len(patch['nodes']),'geometryDecimated':False,'textureRebaked':False}
(OUT/'delivery-validation.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report))

