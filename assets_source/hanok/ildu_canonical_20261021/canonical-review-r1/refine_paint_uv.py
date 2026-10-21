"""Bake thin, planar native paint to continuous UVs; preserve every GLB position/index/normal."""
import bpy,copy,hashlib,json,struct,sys
from pathlib import Path
import numpy as np
OUT=Path(__file__).resolve().parent;ROOT=OUT.parent
sys.path.insert(0,str(OUT/'pbr-pipeline'))
from r12_pbr_delivery import _glb_read,_glb_write,_accessor,_digest,_principled
target=OUT/'pbr/shrine/continuous-paint';target.mkdir(exist_ok=True)
native=ROOT/'shrine-new.blend';native_sha=hashlib.sha256(native.read_bytes()).hexdigest()
path=OUT/'models/sadangmun-pbr.glb';_,doc,payload=_glb_read(path);payload=bytearray(payload)
before_sha=hashlib.sha256(path.read_bytes()).hexdigest()
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=8
scene.render.bake.use_selected_to_active=False;scene.render.bake.margin_type='EXTEND'
records=[]
def append_blob(data):
 global payload
 payload+=b'\0'*((-len(payload))%4);index=len(doc['bufferViews'])
 doc['bufferViews'].append(dict(buffer=0,byteOffset=len(payload),byteLength=len(data)))
 payload+=data;return index
def texture(image):
 view=append_blob(image.read_bytes());idx=len(doc['images']);doc['images'].append(dict(bufferView=view,mimeType='image/png',name=image.stem))
 tid=len(doc['textures']);doc['textures'].append(dict(source=idx,sampler=doc['textures'][0].get('sampler',0)));return tid
for node in doc['nodes']:
 name=node.get('extras',{}).get('sourceObject','')
 if '.paint.' not in name:continue
 ob=bpy.data.objects[name];assert ob.type=='MESH' and len(ob.material_slots)==1
 original_digest=_digest(ob);mesh=ob.data;before_uv=[uv.name for uv in mesh.uv_layers]
 material=mesh.materials[0];mat=material.copy();mesh.materials[0]=mat
 coords=np.array([v.co[:] for v in mesh.vertices]);lo=coords[:,[0,2]].min(axis=0);hi=coords[:,[0,2]].max(axis=0)
 uv=mesh.uv_layers.new(name='Continuous native paint');mesh.uv_layers.active=uv
 for loop in mesh.loops:
  x,z=coords[loop.vertex_index,[0,2]];uv.data[loop.index].uv=(.04+.92*(x-lo[0])/(hi[0]-lo[0]),.04+.92*(z-lo[1])/(hi[1]-lo[1]))
 # Original object, coordinates and name remain intact during baking, so procedural inputs are native.
 bpy.ops.object.select_all(action='DESELECT');ob.hide_set(False);ob.select_set(True);bpy.context.view_layer.objects.active=ob
 nt=mat.node_tree;bs=_principled(mat);output=next(n for n in nt.nodes if n.type=='OUTPUT_MATERIAL' and n.is_active_output)
 surface=output.inputs['Surface'].links[0].from_socket
 images={}
 for channel,socket in [('baseColor','Base Color'),('normal',None),('roughness','Roughness'),('metallic','Metallic'),('specular','Specular IOR Level')]:
  image=bpy.data.images.new('Continuous '+channel,width=1024,height=1024,alpha=True,float_buffer=True)
  image.colorspace_settings.name='sRGB' if channel=='baseColor' else 'Non-Color'
  image.generated_color=(.5,.5,1,1) if channel=='normal' else (0,0,0,1)
  targetnode=nt.nodes.new('ShaderNodeTexImage');targetnode.image=image
  for n in nt.nodes:n.select=False
  targetnode.select=True;nt.nodes.active=targetnode
  emit=None
  if socket:
   emit=nt.nodes.new('ShaderNodeEmission');inp=bs.inputs[socket]
   if inp.is_linked:nt.links.new(inp.links[0].from_socket,emit.inputs['Color'])
   else:
    value=inp.default_value;emit.inputs['Color'].default_value=tuple(value) if hasattr(value,'__len__') else (value,value,value,1)
   nt.links.new(emit.outputs[0],output.inputs['Surface'])
  print('CONTINUOUS PAINT BAKE',name,channel,flush=True)
  bpy.ops.object.bake(type='EMIT' if socket else 'NORMAL',normal_space='TANGENT',margin=16)
  if emit:nt.links.new(surface,output.inputs['Surface']);nt.nodes.remove(emit)
  nt.nodes.remove(targetnode);images[channel]=image
 size=1024*1024*4
 rough=np.empty(size,dtype=np.float32);images['roughness'].pixels.foreach_get(rough)
 metal=np.empty_like(rough);images['metallic'].pixels.foreach_get(metal)
 spec=np.empty_like(rough);images['specular'].pixels.foreach_get(spec)
 packed=np.ones_like(rough);packed[1::4]=rough[0::4];packed[2::4]=metal[0::4]
 orm=bpy.data.images.new('Continuous roughnessMetallic',width=1024,height=1024);orm.colorspace_settings.name='Non-Color';orm.pixels.foreach_set(packed);images['roughnessMetallic']=orm
 packed=np.ones_like(rough);packed[3::4]=np.clip(spec[0::4]*2,0,1)
 sp=bpy.data.images.new('Continuous specularRGBA',width=1024,height=1024,alpha=True);sp.colorspace_settings.name='Non-Color';sp.pixels.foreach_set(packed);images['specular']=sp
 maps={}
 for channel in ['baseColor','normal','roughnessMetallic','specular']:
  image=images[channel];image.update();dest=target/(str(len(records))+'-'+channel+'.png');image.filepath_raw=str(dest);image.file_format='PNG';image.save();maps[channel]=texture(dest)
 prims=doc['meshes'][node['mesh']]['primitives'];assert len(prims)==1;prim=prims[0]
 pos=_accessor(doc,payload,prim['attributes']['POSITION']);world=np.array([p[[0,1]] for p in pos])
 # Native paint objects have identity transforms; glTF Y is native Z.
 assert np.allclose(world.min(axis=0),lo,atol=1e-5) and np.allclose(world.max(axis=0),hi,atol=1e-5)
 uvvalues=np.asarray(.04+.92*(world-lo)/(hi-lo),dtype='<f4');uvvalues[:,1]=1-uvvalues[:,1]
 view=append_blob(uvvalues.tobytes());a=len(doc['accessors']);doc['accessors'].append(dict(bufferView=view,componentType=5126,count=len(uvvalues),type='VEC2'))
 prim['attributes']['TEXCOORD_0']=a;prim['attributes'].pop('TANGENT',None)
 newmat=copy.deepcopy(doc['materials'][prim['material']]);newmat['name']='Approved native continuous paint '+str(len(records))
 newmat['pbrMetallicRoughness']['baseColorTexture']={'index':maps['baseColor']}
 newmat['pbrMetallicRoughness']['metallicRoughnessTexture']={'index':maps['roughnessMetallic']}
 newmat['normalTexture']={'index':maps['normal']}
 newmat.setdefault('extensions',{}).setdefault('KHR_materials_specular',{})['specularTexture']={'index':maps['specular']}
 prim['material']=len(doc['materials']);doc['materials'].append(newmat)
 mesh.uv_layers.remove(uv);mesh.materials[0]=material
 assert _digest(ob)==original_digest
 records.append(dict(sourceObject=name,continuousUv=True,size=1024,positionsIndicesNormalsUnchanged=True,sourceObjectRestored=True,files=list(maps)))
assert len(records)==2
doc['buffers'][0]['byteLength']=len(payload);_glb_write(path,doc,bytes(payload))
assert hashlib.sha256(native.read_bytes()).hexdigest()==native_sha
receipt=OUT/'shrine-pbr-export.json';r=json.loads(receipt.read_text(encoding='utf-8'));r.update(sha256=hashlib.sha256(path.read_bytes()).hexdigest(),imageCount=len(doc['images']),materialCount=len(doc['materials']),continuousPaintUvReceipt='paint-uv-verification.json');receipt.write_text(json.dumps(r,ensure_ascii=False,indent=2),encoding='utf-8')
(OUT/'paint-uv-verification.json').write_text(json.dumps(dict(passed=True,originalPbrSha256=before_sha,nativeSha256=native_sha,outputSha256=r['sha256'],reason='Replace fragmented paint UV islands with continuous native planar shader bakes; no geometry changes.',parts=records),ensure_ascii=False,indent=2),encoding='utf-8')
print('CONTINUOUS PAINT COMPLETE',r['sha256'],flush=True)
