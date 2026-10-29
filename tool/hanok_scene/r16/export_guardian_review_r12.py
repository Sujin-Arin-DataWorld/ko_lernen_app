import bpy,sys,json,struct,hashlib,bmesh
from pathlib import Path
P=Path(__file__).resolve().parent;D=P/'sarang-exact-r12';native=D/'sarang-exact-r12.blend';native_sha=hashlib.sha256(native.read_bytes()).hexdigest();bpy.ops.wm.open_mainfile(filepath=str(native))
bpy.ops.object.select_all(action='DESELECT');objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.name in ('HS12 main exact guardian cap','HS12 native arch-fit guardian saddle') and not o.hide_render]
for o in objects:
 o.hide_set(False);o.select_set(True)
 for sl in o.material_slots:
  old=sl.material
  if not old:continue
  mat=old.copy();mat.name=old.name+' review export';sl.material=mat
  tree=mat.node_tree;bs=next(n for n in tree.nodes if n.type=='BSDF_PRINCIPLED');images=[n for n in tree.nodes if n.type=='TEX_IMAGE']
  if images and old.name.startswith('HS12 exact'):
   tree.links.new(images[0].outputs['Color'],bs.inputs['Base Color'])
  elif old.get('referenceColourProfile')=='tile':
   for link in list(bs.inputs['Base Color'].links):tree.links.remove(link)
   bs.inputs['Base Color'].default_value=(.025,.032,.045,1)
   for link in list(bs.inputs['Roughness'].links):tree.links.remove(link)
   bs.inputs['Roughness'].default_value=.76
  for link in list(bs.inputs['Normal'].links):tree.links.remove(link)
 # Review LOD; Blender master retains the full carved resolution.
 if len(o.data.polygons)>100000:
  bpy.context.view_layer.objects.active=o;mod=o.modifiers.new('Review LOD only','DECIMATE');mod.ratio=.45;mod.use_collapse_triangulate=True;bpy.ops.object.modifier_apply(modifier=mod.name)
 # The planar rear must not interpolate the curved perimeter's vertex normals.
 if o.name=='HS12 main exact guardian cap':
  for face in o.data.polygons:
   if face.material_index==2:face.use_smooth=False
  o.data.update()
 else:
  for face in o.data.polygons:face.use_smooth=False
  o.data.update()
out=D/'guardian-review.glb';bpy.ops.export_scene.gltf(filepath=str(out),export_format='GLB',use_selection=True,export_extras=True,export_apply=True,export_yup=True)
data=out.read_bytes();length,typ=struct.unpack_from('<II',data,12);doc=json.loads(data[20:20+length]);rest=data[20+length:]
for m in doc.get('materials',[]):
 pbr=m.get('pbrMetallicRoughness',{})
 if 'baseColorTexture' in pbr:pbr['baseColorFactor']=[.50,.56,.51,1]
encoded=json.dumps(doc,separators=(',',':')).encode();encoded+=b' '*((-len(encoded))%4);out.write_bytes(struct.pack('<III',0x46546c67,2,12+8+len(encoded)+len(rest))+struct.pack('<II',len(encoded),0x4e4f534a)+encoded+rest)
topology=[]
for o in objects:
 bm=bmesh.new();bm.from_mesh(o.data);bad=sum(not e.is_manifold for e in bm.edges);bm.free();assert bad==0,(o.name,bad);topology.append(dict(name=o.name,nonManifoldEdges=bad))
assert hashlib.sha256(native.read_bytes()).hexdigest()==native_sha
report=dict(file=str(out),bytes=out.stat().st_size,sha256=hashlib.sha256(out.read_bytes()).hexdigest(),objects=[dict(name=o.name,polygons=len(o.data.polygons),vertices=len(o.data.vertices)) for o in objects],topology=topology,nativeSha256=native_sha,nativeUnchanged=True,reviewLOD=.45,mountPigment='approximate charcoal PBR; procedural micrograin not baked',runtimeIntegrated=False)
(D/'glb-verification.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print('REVIEW GLB EXPORTED',report,flush=True)
