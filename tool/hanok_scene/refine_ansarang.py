"""Surface and small joinery refinement of the measured four-bay Ansarang.

The approved pair and the measured opening/post axes remain unchanged. Original
canonical pixels supply timber/stone pigment; no source image is edited.
"""
from pathlib import Path
import bpy, ast, json, re, random, hashlib, math, sys, numpy as np
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets_unused/pending_review/hwalju-blueprint-review/side-connections'
OLD=Path('C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-warm-stone-20260923')
SOURCE=OLD/'assets_unused/pending_review/ildu_spatial_preservation_20260922/existing-estate-v36'
ART=Path('C:/dev/hangulsori/ko_lernen_app/assets_unused/pending_review/personal_hanok_v3/hyeopmun_try03_blueprint_colored.png')
sys.path.insert(0,str(OLD/'tool/hanok_scene'));import reconstruction_geometry as g
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(OUT/'gate-refined.blend'));s=bpy.context.scene
bpy.context.view_layer.update()
items=[o for o in s.objects if o.type=='MESH' and o.get('construction_building')=='ansarang']
assert len(items)==361
for node in ast.parse((Path(__file__).parent/'refine_canonical_gates.py').read_text(encoding='utf8')).body:
 if isinstance(node,ast.FunctionDef) and node.name in ('new_material','pigment','components','art_uv'):
  exec(compile(ast.Module(body=[node],type_ignores=[]),'shared canonical UV','exec'))
base_image=bpy.data.images.load(str(ART),check_existing=True);materials={};mapped=[]
regions={'wood':[(.334,.405,.356,.618),(.389,.406,.414,.619),(.425,.409,.449,.617),(.568,.406,.592,.617),(.604,.406,.631,.619),(.642,.406,.665,.619)],
 'post':[(.244,.328,.282,.680)],'beam':[(.303,.332,.708,.353)],
 'stone':[(.192,.728,.286,.756),(.391,.786,.498,.810),(.620,.795,.690,.821)]}
mapping=json.loads((SOURCE/'realtime-delivery.json').read_text())['materialMapping'];converted={};tally={};edits=[]
def retain_pbr(o,original):
 name=re.sub(r'\.\d{3}$','',original.name);assert name in mapping,name
 me=o.data;span=np.array(mapping[name]['textureSpanMetres']);uv=me.uv_layers.get('Ansarang retained PBR') or me.uv_layers.new(name='Ansarang retained PBR')
 if me.uv_layers.get('Reference timber grain'):
  for i in range(len(me.loops)):uv.data[i].uv=np.array(me.uv_layers['Reference timber grain'].data[i].uv)/span
 else:
  for p in me.polygons:
   axes=[a for a in range(3) if a!=int(np.argmax(np.abs(p.normal)))]
   for li in p.loop_indices:uv.data[li].uv=np.array(me.vertices[me.loops[li].vertex_index].co)[axes]/span
 me.uv_layers.active=uv;uv.active_render=True
 if name not in converted:
  mat=new_material('Ansarang retained '+name);n=mat.node_tree.nodes;l=mat.node_tree.links;bs=n.get('Principled BSDF');un=n.new('ShaderNodeUVMap');un.uv_map=uv.name;idx=list(mapping).index(name)
  for ch in ('color','normal','roughness'):
   tex=n.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(SOURCE/'textures'/f'{idx:02d}-{ch}.png'),check_existing=True)
   if ch!='color':tex.image.colorspace_settings.name='Non-Color'
   l.new(un.outputs[0],tex.inputs[0])
   if ch=='normal':
    nm=n.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=.7;l.new(tex.outputs[0],nm.inputs['Color']);l.new(nm.outputs[0],bs.inputs['Normal'])
   else:l.new(tex.outputs[0],bs.inputs['Base Color' if ch=='color' else 'Roughness'])
  bs.inputs['Specular IOR Level'].default_value=.22
  if 'iron' in name.lower():bs.inputs['Metallic'].default_value=.7
  converted[name]=mat
 me.materials.clear();me.materials.append(converted[name])
 return name
def component_tints(o,kind):
 me=o.data;groups,find=components(me);rng=random.Random(o.name+'pigment');attr=me.color_attributes.new(name='Craft tonal variation',type='FLOAT_COLOR',domain='CORNER');colors={}
 for root,ids in groups.items():
  v=rng.uniform(.87,1.12) if kind=='ceramic' else rng.uniform(.90,1.05)
  colors[root]=(v*1.02,v,v*.95,1) if kind=='ceramic' else (v,v,v,1)
 for p in me.polygons:
  tint=colors[find(p.vertices[0])]
  for li in p.loop_indices:attr.data[li].color=tint
 me.color_attributes.active_color=attr
 # Match glTF's base-color multiplication in Blender's native render.
 mat=me.materials[0]
 if not mat.get('craftVertexColor'):
  n=mat.node_tree.nodes;l=mat.node_tree.links;bs=n.get('Principled BSDF');link=next((k for k in l if k.to_socket==bs.inputs['Base Color']),None)
  vertex=n.new('ShaderNodeVertexColor');vertex.layer_name=attr.name
  if link:
   src=link.from_socket;l.remove(link);mix=n.new('ShaderNodeMix');mix.data_type='RGBA';mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1;l.new(src,mix.inputs[6]);l.new(vertex.outputs['Color'],mix.inputs[7]);l.new(mix.outputs[2],bs.inputs['Base Color'])
  mat['craftVertexColor']=True
for o in items:
 original=o.data.materials[0];name=original.name.lower();kind='retained';o.data=o.data.copy()
 for attr in list(o.data.color_attributes):o.data.color_attributes.remove(attr)
 if any(k in name for k in ('timber','walnut','plank')) and not any(k in name for k in ('hanji','paper')) and 'end grain' not in o.name:
  kind='post' if '.frame.post' in o.name else 'wood'
  if any(k in o.name for k in ('cross beam','long beam','fascia','barge','lintel')):kind='beam'
  art_uv(o,kind);component_tints(o,'wood')
  for mod in o.modifiers:
   if mod.type=='BEVEL':mod.width=min(mod.width,.0035 if 'joinery' in o.name else .006);mod.segments=3
 elif any(k in name for k in ('granite','fieldstone')):
  kind='stone';art_uv(o,kind);component_tints(o,'stone')
  if any(k in o.name for k in ('dressed edge','dressed return','stepping stone')):
   rng=random.Random(o.name+'weathered edge')
   for v in o.data.vertices:v.co+=Vector((rng.uniform(-.010,.010),rng.uniform(-.010,.010),rng.uniform(-.005,.005)))
   for mod in o.modifiers:
    if mod.type=='BEVEL':mod.width=.013;mod.segments=3
   edits.append({'object':o.name,'edgeVariationMetres':.010,'heightVariationMetres':.005})
 else:
  retain_pbr(o,original)
  if any(k in name for k in ('ceramic','giwa')):kind='ceramic';component_tints(o,kind)
 tally[kind]=tally.get(kind,0)+1
 o['surface_refinement']='canonical timber/stone and varied fired tile; measured opening axes retained'

# Flush timber pegs at beam seats, subtle longitudinal age splits on exposed
# posts, and individual endgrain rings on existing rafter ends. These are
# surface craft details, not invented structural bays or altered silhouettes.
dark=new_material('Ansarang aged timber fissures');dark.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.055,.032,.014,1);dark.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.95
peg=new_material('Ansarang endgrain pegs');peg.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.19,.105,.045,1);peg.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.86
cx,cy=24.4459092788,-9.7831032106
g.set_transform(lambda p:(cx+p[1],cy-p[0],p[2]))
rng=random.Random(55048)
for x in [-5.46,-2.73,0,2.73,5.46]:
 for z in (1.20,2.94):g.rod('CraftAnsarang.frame timber pegs',(x,-2.265,z),(x,-2.273,z),.013,peg,16)
 for j in range(3):
  xx=x+rng.uniform(-.065,.065);zz=rng.uniform(1.22,2.45);length=rng.uniform(.16,.46)
  pts=[(xx+rng.uniform(-.002,.002),-2.272,zz+k*length/5) for k in range(6)]
  for a,b in zip(pts,pts[1:]):g.rod('CraftAnsarang.post fine splits',a,b,rng.uniform(.0008,.0015),dark,5)
new=g.flush();g.BATCHES.clear();g.set_transform(lambda p:p)
for o in new:
 for mod in list(o.modifiers):o.modifiers.remove(mod)
 o['construction_building']='ansarang';o['construction_first']=1;o['construction_last']=99;o['source_object_name']=o.name;o['detailAuthority']='Illustrative timber aging; not measured historical damage'
items.extend(new)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'scene.blend'),compress=True)
for o in s.objects:o.select_set(False)
for o in items:o.hide_set(False);o.hide_render=False;o.select_set(True)
bpy.context.view_layer.objects.active=items[0]
bpy.ops.export_scene.gltf(filepath=str(OUT/'crafted-ansarang.glb'),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True,export_extras=True)
report={'baseComponents':361,'craftedComponents':len(items),'materialGroups':tally,'mapped':mapped,'smallGeometryChanges':edits,'sourcePigmentSha256':sha(ART),'canonicalImageEdited':False,'measuredOpeningsAndRoofAxesChanged':False,'sceneSha256':sha(OUT/'scene.blend'),'craftedGlbSha256':sha(OUT/'crafted-ansarang.glb'),'historicalDamageMeasured':False}
(OUT/'ansarang-detail-validation.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print('ANSARANG DETAIL COMPLETE',tally,len(items),flush=True)
