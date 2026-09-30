"""Bake legacy wood's existing shader into web textures, without new artwork.

Blender's UV vector graph crops canonical artwork to a wood pigment patch. glTF
ignores that graph and incorrectly paints the entire facade over each member.
Baking the native colour shader fixes the web export; source images stay intact.
"""
from pathlib import Path
import bpy,json,struct,hashlib,sys
sys.path.insert(0,str(Path(__file__).parent))
from apply_estate_matte_register import timber_needs_bake
N=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
D=Path('C:/dev/hangulsori/sites/ildu-survey-review-20260929/dist/estate')
bpy.ops.wm.open_mainfile(filepath=str(N/('estate-fabric.blend' if (N/'estate-fabric.blend').exists() else 'detail-redraw.blend')))
p=N/'review3d/current-estate.glb';blob=p.read_bytes();size=struct.unpack_from('<I',blob,12)[0];doc=json.loads(blob[20:20+size]);payload=blob[28+size:];original_payload=payload
scene=bpy.data.scenes.new('Web material baking only');bpy.context.window.scene=scene;scene.render.engine='CYCLES';scene.cycles.samples=1;scene.cycles.device='CPU'
scene.render.bake.margin=0;scene.render.image_settings.file_format='PNG'
bpy.ops.mesh.primitive_plane_add(size=2);plane=bpy.context.object
folder=N/'review3d/web-materials';folder.mkdir(exist_ok=True);baked=[]
roof_palette={'Reference anchae tile','Reference sadang roof ceramic corrected','Reference ansarang tile','Reference sadangmun tile'}
for m in doc['materials']:
 if 'plaque' in m['name'].lower() or 'finial' in m['name'].lower():continue
 native=bpy.data.materials.get(m['name'])
 if not native or not native.use_nodes:continue
 bsdf=next((n for n in native.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
 if native.get('gyeMatteSurfaceV1') and bsdf:
  pbr=m.setdefault('pbrMetallicRoughness',{})
  pbr['roughnessFactor']=float(bsdf.inputs['Roughness'].default_value)
  pbr['metallicFactor']=0
  # Do not let the old gloss image modulate the new uniform matte finish.
  pbr.pop('metallicRoughnessTexture',None)
  m.setdefault('extras',{})['gyeMatteSurfaceV1']=native['gyeMatteSurfaceV1']
 if native.get('gyeHeritageWoodV1'):
  # The new illustrated timber is a direct image/UV pair, already exported at source resolution.
  assert not timber_needs_bake(native)
  m.setdefault('extras',{})['gyeHeritageWoodV1']=native['gyeHeritageWoodV1']
  continue
 texs=[n for n in native.node_tree.nodes if n.type=='TEX_IMAGE' and n.image]
 if not ((native.get('gyeMatteSurfaceV1')=='wood' and timber_needs_bake(native)) or native.get('gyeWalnutPigmentV1') or native.get('gyeStoneTextureV2') or native.get('gyePlasterTextureV1') or m['name'] in roof_palette or m['name'].startswith('Gye hand-chipped warm stone') or
         any(n.image.name.startswith(('master-sarangchae','art-jungmunganchae')) for n in texs)):continue
 bsdf=next((n for n in native.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
 if not bsdf or not bsdf.inputs['Base Color'].is_linked:continue
 mat=native.copy();nodes=mat.node_tree.nodes;links=mat.node_tree.links
 for nd in nodes:
  if nd.type=='UVMAP':
   key=nd.uv_map or 'UVMap'
   if not plane.data.uv_layers.get(key):plane.data.uv_layers.new(name=key)
   layer=plane.data.uv_layers[key]
   for poly in plane.data.polygons:
    for li in poly.loop_indices:
     co=plane.data.vertices[plane.data.loops[li].vertex_index].co;layer.data[li].uv=((co.x+1)/2,(co.y+1)/2)
 plane.data.materials.clear();plane.data.materials.append(mat)
 bs=next(n for n in nodes if n.type=='BSDF_PRINCIPLED');out=next(n for n in nodes if n.type=='OUTPUT_MATERIAL')
 source=bs.inputs['Base Color'].links[0].from_socket;emit=nodes.new('ShaderNodeEmission');links.new(source,emit.inputs['Color']);links.new(emit.outputs[0],out.inputs['Surface'])
 resolution=1024 if native.get('gyeWalnutPigmentV1') or m['name'] in roof_palette or native.get('gyePlasterTextureV1') or native.get('gyeStoneTextureV2') else 512
 img=bpy.data.images.new('Web bake '+m['name'],width=resolution,height=resolution,alpha=False);img.colorspace_settings.name='sRGB'
 target=nodes.new('ShaderNodeTexImage');target.image=img;nodes.active=target;target.select=True
 bpy.ops.object.bake(type='EMIT');f=folder/(hashlib.sha256(m['name'].encode()).hexdigest()[:16]+'.png');img.filepath_raw=str(f);img.file_format='PNG';img.save()
 raw=f.read_bytes();start=len(payload);payload+=raw;payload+=b'\0'*((-len(payload))%4)
 vi=len(doc['bufferViews']);doc['bufferViews'].append({'buffer':0,'byteOffset':start,'byteLength':len(raw)})
 ii=len(doc['images']);doc['images'].append({'name':'Native shader bake '+m['name'],'bufferView':vi,'mimeType':'image/png'})
 ti=len(doc['textures']);doc['textures'].append({'source':ii,'sampler':0})
 pbr=m.setdefault('pbrMetallicRoughness',{})
 # The retained canonical roofs use a non-default UV set. Preserve that
 # texture coordinate when replacing the image with a baked colour layer.
 source_texture=dict(pbr.get('baseColorTexture',{}))
 source_texture['index']=ti
 pbr['baseColorTexture']=source_texture
 pbr['baseColorFactor']=[1,1,1,1]
 pbr['roughnessFactor']=float(bsdf.inputs['Roughness'].default_value) if native.get('gyeMatteSurfaceV1') or m['name'] in roof_palette or native.get('gyePlasterTextureV1') or native.get('gyeStoneTextureV2') else .78
 m.pop('normalTexture',None);m.setdefault('extras',{})['webMaterial']=f'Native colour shader baked to {resolution}px; source images unchanged'
 baked.append(m['name']);print('BAKED',m['name'],len(raw),flush=True)
assert payload[:len(original_payload)]==original_payload
doc['buffers'][0]['byteLength']=len(payload)
data=json.dumps(doc,separators=(',',':'),ensure_ascii=False).encode();data+=b' '*((-len(data))%4)
result=struct.pack('<III',0x46546c67,2,28+len(data)+len(payload))+struct.pack('<II',len(data),0x4e4f534a)+data+struct.pack('<II',len(payload),0x004e4942)+payload;p.write_bytes(result)
sha=lambda b:hashlib.sha256(b).hexdigest();r=json.loads((D/'manifest.json').read_text(encoding='utf8'));r.update(bytes=len(result),glbSha256=sha(result),chunks=[])
for i,start in enumerate(range(0,len(result),20*1024**2)):
 piece=result[start:start+20*1024**2];f=D/f'current-estate-{i:02}.bin';f.write_bytes(piece);r['chunks'].append({'file':f.name,'bytes':len(piece),'sha256':sha(piece)})
r['legacyWoodShaderBakes']={'materials':baked,'resolution':512,'roofResolution':1024,
                            'sourceImagesAndGeometryUnchanged':True}
for f in (D/'manifest.json',N/'current-estate-delivery.json'):f.write_text(json.dumps(r,ensure_ascii=False,indent=2),encoding='utf8')
print('LEGACY WOOD COMPLETE',len(baked),flush=True)
