"""Lossless GLB part extraction/append; no geometry or texture recompression."""
import copy,json,struct,hashlib
def read(path):
    with path.open('rb') as stream:
        magic,version,size=struct.unpack('<III',stream.read(12));assert (magic,version,size)==(0x46546c67,2,path.stat().st_size)
        n,t=struct.unpack('<II',stream.read(8));assert t==0x4e4f534a
        doc=json.loads(stream.read(n));length,t=struct.unpack('<II',stream.read(8));assert t==0x004e4942
        blob=stream.read(length);assert len(blob)==length
    return doc,blob
def write(path,doc,blob):
    chunks=blob if isinstance(blob,(list,tuple)) else (blob,);length=sum(len(chunk) for chunk in chunks);padding=b'\0'*(-length%4)
    doc['buffers']=[{'byteLength':length}];j=json.dumps(doc,separators=(',',':')).encode();j+=b' '*(-len(j)%4)
    header=struct.pack('<III',0x46546c67,2,28+len(j)+length+len(padding))+struct.pack('<II',len(j),0x4e4f534a)+j+struct.pack('<II',length+len(padding),0x004e4942)
    digest=hashlib.sha256()
    with path.open('wb') as stream:
        for chunk in (header,*chunks,padding):stream.write(chunk);digest.update(chunk)
    return digest.hexdigest()
def texture_refs(value):
    if isinstance(value,dict):
        for key,item in value.items():
            if key.endswith('Texture') and isinstance(item,dict) and 'index' in item:yield item
            else:yield from texture_refs(item)
    elif isinstance(value,list):
        for item in value:yield from texture_refs(item)
def subset(doc,blob,selected):
    ids={'nodes':set(selected)}
    assert all('children' not in doc['nodes'][i] and 'skin' not in doc['nodes'][i] for i in selected)
    ids['meshes']={doc['nodes'][i]['mesh'] for i in selected}
    primitives=[p for i in ids['meshes'] for p in doc['meshes'][i]['primitives']]
    assert all('targets' not in p and 'extensions' not in p for p in primitives)
    ids['accessors']={v for p in primitives for v in list(p['attributes'].values())+([p['indices']] if 'indices' in p else [])}
    ids['materials']={p['material'] for p in primitives if 'material' in p}
    ids['textures']={t['index'] for i in ids['materials'] for t in texture_refs(doc['materials'][i])}
    ids['images']={doc['textures'][i]['source'] for i in ids['textures']}
    ids['samplers']={doc['textures'][i]['sampler'] for i in ids['textures'] if 'sampler' in doc['textures'][i]}
    assert all('sparse' not in doc['accessors'][i] for i in ids['accessors'])
    ids['bufferViews']={doc['accessors'][i]['bufferView'] for i in ids['accessors']}|{doc['images'][i]['bufferView'] for i in ids['images']}
    maps={k:{old:new for new,old in enumerate(sorted(v))} for k,v in ids.items()}
    out={'asset':copy.deepcopy(doc['asset']),'scene':0,'scenes':[{'nodes':list(range(len(selected)))}],'extensionsUsed':doc.get('extensionsUsed',[])};chunks=[];offset=0
    for key,indices in ids.items():
        out[key]=[copy.deepcopy(doc[key][i]) for i in sorted(indices)]
        for v in out[key]:
            if key=='nodes':v['mesh']=maps['meshes'][v['mesh']]
            elif key=='meshes':
                for p in v['primitives']:
                    p['attributes']={k:maps['accessors'][i] for k,i in p['attributes'].items()}
                    if 'indices' in p:p['indices']=maps['accessors'][p['indices']]
                    if 'material' in p:p['material']=maps['materials'][p['material']]
            elif key=='materials':
                for t in texture_refs(v):t['index']=maps['textures'][t['index']]
            elif key=='textures':
                v['source']=maps['images'][v['source']]
                if 'sampler' in v:v['sampler']=maps['samplers'][v['sampler']]
            elif key in ('accessors','images'):v['bufferView']=maps['bufferViews'][v['bufferView']]
            elif key=='bufferViews':
                chunk=blob[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']];chunk+=b'\0'*(-len(chunk)%4)
                v['buffer']=0;v['byteOffset']=offset;chunks.append(chunk);offset+=len(chunk)
    return out,b''.join(chunks)
def append(doc,blob,patch,extra,join=True):
    keys=['bufferViews','accessors','images','samplers','textures','materials','meshes','nodes'];base={k:len(doc.get(k,[])) for k in keys}
    assert len(blob)%4==0
    for key in keys:
        for item in patch.get(key,[]):
            v=copy.deepcopy(item)
            if key=='bufferViews':v['buffer']=0;v['byteOffset']=v.get('byteOffset',0)+len(blob)
            elif key in ('accessors','images'):
                if 'bufferView' in v:v['bufferView']+=base['bufferViews']
            elif key=='textures':
                if 'source' in v:v['source']+=base['images']
                if 'sampler' in v:v['sampler']+=base['samplers']
            elif key=='materials':
                for t in texture_refs(v):t['index']+=base['textures']
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
    doc['extensionsUsed']=sorted(set(doc.get('extensionsUsed',[])+patch.get('extensionsUsed',[])))
    return doc,(blob+extra if join else (blob,extra))
