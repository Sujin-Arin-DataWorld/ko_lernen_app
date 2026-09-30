"""Finish the photo reconstruction: bedded masonry, ridge terminals and gable."""
from pathlib import Path
import bpy,ast,json,hashlib,math,random,sys,numpy as np
from mathutils import Matrix,Vector
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'assets_unused/pending_review/hwalju-blueprint-review/side-connections'
ART=Path('C:/dev/hangulsori/ko_lernen_app/assets_unused/pending_review/personal_hanok_v3/hyeopmun_try03_blueprint_colored.png')
sys.path.insert(0,'C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-warm-stone-20260923/tool/hanok_scene');import reconstruction_geometry as g
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
for node in ast.parse((Path(__file__).parent/'refine_canonical_gates.py').read_text(encoding='utf8')).body:
 if isinstance(node,ast.FunctionDef) and node.name in ('new_material','pigment','components','art_uv'):exec(compile(ast.Module(body=[node],type_ignores=[]),'surface','exec'))
bpy.ops.wm.open_mainfile(filepath=str(OUT/'scene.blend'));s=bpy.context.scene
c=json.loads((OUT/'connection-contract.json').read_text());b=c['buildings']['main_gate'];matrix=Matrix.Translation((*b['center'],0))@Matrix.Rotation(b['angle'],4,'Z');inv=matrix.inverted();tr=lambda p:tuple(matrix@Vector(p))
m=bpy.data.materials['Photo gate ochre mortar'];m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.50,.375,.22,1)
for o in s.objects:
 if o.name=='PhotoGate.front irregular fieldstone' and not o.get('closelyBedded'):
  for v in o.data.vertices:
   p=inv@v.co;p.y+=.075;v.co=matrix@p
  o['closelyBedded']=True
tile=bpy.data.objects['PhotoGate.roof ridge end tile'].data.materials[0]
bpy.data.objects.remove(bpy.data.objects['PhotoGate.roof ridge end tile'],do_unlink=True)
g.set_transform(tr)
for x0,x1,ridge in [(-5.55,-.96,4.23),(.96,5.55,4.23),(-1.976,1.976,5.05)]:
 for x in (x0,x1):
  shape=[(-.14,.23),(-.16,.43),(-.115,.56),(0,.65),(.115,.56),(.16,.43),(.14,.23)]
  for yy in (-.045,.045):g.face('PhotoGate.roof rounded ridge terminal',[(x+dx,yy,ridge+dz) for dx,dz in shape],tile)
  for p,q in zip(shape,shape[1:]+shape[:1]):g.face('PhotoGate.roof rounded ridge terminal',[(x+p[0],-.045,ridge+p[1]),(x+p[0],.045,ridge+p[1]),(x+q[0],.045,ridge+q[1]),(x+q[0],-.045,ridge+q[1])],tile)
new=g.flush();g.BATCHES.clear()
for o in new:
 o['construction_building']='main_gate';o['source_object_name']=o.name
 uv=o.data.uv_layers.new(name='Ansarang retained PBR')
 for p in o.data.polygons:
  for li in p.loop_indices:
   v=o.data.vertices[o.data.loops[li].vertex_index].co;uv.data[li].uv=(v.x/.8,v.z/.8)
 attr=o.data.color_attributes.new(name='Craft tonal variation',type='FLOAT_COLOR',domain='CORNER')
 for item in attr.data:item.color=(1,1,1,1)
gable=bpy.data.objects['PhotoWarehouse.gable ochre']
for v in gable.data.vertices:v.co.y=-3.76
g.set_transform(lambda p:p);base_image=bpy.data.images.load(str(ART),check_existing=True);materials={};mapped=[];regions={'beam':[(.303,.332,.708,.353)],'post':[(.244,.328,.282,.680)]}
g.box('PhotoWarehouse.gable cross tie',(-8.6325,-3.795,3.23),(2.76,.13,.15),pigment('beam'))
g.box('PhotoWarehouse.gable king post',(-8.6325,-3.795,3.78),(.11,.13,1.04),pigment('post'))
wood=g.flush();g.BATCHES.clear()
for o in wood:
 art_uv(o,'beam' if 'cross tie' in o.name else 'post');o['construction_building']='changgo';o['source_object_name']=o.name
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'scene.blend'),compress=True)
items=[o for o in s.objects if o.type=='MESH' and (o.get('construction_building') in ('main_gate','toilet','forecourt_wall') or o.name.startswith('PhotoWarehouse.'))]
for o in s.objects:o.select_set(False)
for o in items:o.select_set(True)
bpy.context.view_layer.objects.active=items[0]
bpy.ops.export_scene.gltf(filepath=str(OUT/'crafted-forecourt.glb'),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True,export_extras=True)
(OUT/'photo-gate-finish.json').write_text(json.dumps({'sceneSha256':sha(OUT/'scene.blend'),'forecourtSha256':sha(OUT/'crafted-forecourt.glb'),'changed':['mortar colour and bedding depth','ridge end tile profile','exposed ochre gable and timber ties']}),encoding='utf8')
print('PHOTO FINISH COMPLETE',flush=True)
