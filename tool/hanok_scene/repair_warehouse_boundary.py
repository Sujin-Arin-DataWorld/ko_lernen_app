"""Reveal the warehouse end: photo11 locates the low wall at its outer corner."""
from pathlib import Path
import bpy,bmesh,ast,hashlib,json,sys,numpy as np
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'assets_unused/pending_review/hwalju-blueprint-review/side-connections'
sys.path.insert(0,'C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-warm-stone-20260923/tool/hanok_scene');import reconstruction_geometry as g
bpy.ops.wm.open_mainfile(filepath=str(OUT/'scene.blend'));s=bpy.context.scene
c=json.loads((OUT/'connection-contract.json').read_text());wall='Forecourt.wall.warehouse-toilet.';cut_x=-10.055;top=1.72;changed=[]
for o in list(s.objects):
 if not o.name.startswith(wall):continue
 o.data=o.data.copy();bm=bmesh.new();bm.from_mesh(o.data)
 # All these boundary mesh coordinates are world baked by the wall builder.
 if o.name.startswith(wall+'0.'):
  res=bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.000001,plane_co=(cut_x,0,0),plane_no=(1,0,0),clear_outer=True,clear_inner=False)
  cut=[e for e in res['geom_cut'] if isinstance(e,bmesh.types.BMEdge) and e.is_boundary]
  if cut:bmesh.ops.holes_fill(bm,edges=cut,sides=0)
 if o.name.endswith(('.core','.rubble')):
  res=bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.000001,plane_co=(0,0,top),plane_no=(0,0,1),clear_outer=True,clear_inner=False)
  cut=[e for e in res['geom_cut'] if isinstance(e,bmesh.types.BMEdge) and e.is_boundary]
  if cut:bmesh.ops.holes_fill(bm,edges=cut,sides=0)
 else:
  for v in bm.verts:v.co.z-=.52
 bm.to_mesh(o.data);bm.free();o.data.update();changed.append(o.name)
for r in c['forecourt']['wallRoutes']:
 if r['id'].startswith(wall):
  r['coreTop']=top
  if r['id']==wall+'0':r['start']=[cut_x,-3.535]
# The photograph shows a plastered end, not a plank-faced wall. Add the real
# outer render coat while retaining the existing timber frame behind it.
def mat(name,color):
 m=bpy.data.materials.new(name);m.use_nodes=True;b=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED');b.inputs['Base Color'].default_value=(*color,1);b.inputs['Roughness'].default_value=.95;return m
lime=mat('Warehouse photographed warm lime end',(.62,.55,.38));ochre=mat('Warehouse photographed ochre end',(.40,.215,.088))
g.set_transform(lambda p:p);left,right=-10.01,-7.255;y=-3.594
# Thick plaster infill with a softly irregular change of earth/lime finish.
g.box('PhotoWarehouse.end ochre infill',((left+right)/2,y,1.985),(right-left,.055,2.35),ochre)
profile=[(left,.735),(right,.735),(right,1.79),(right-.35,1.86),((left+right)/2,1.91),(left+.30,1.86),(left,1.81)]
front=[(x,y-.033,z) for x,z in profile];back=[(x,y+.014,z) for x,z in profile]
g.face('PhotoWarehouse.end lime plaster',list(reversed(front)),lime);g.face('PhotoWarehouse.end lime plaster',back,lime)
for i in range(len(front)):j=(i+1)%len(front);g.face('PhotoWarehouse.end lime plaster',[front[i],front[j],back[j],back[i]],lime)
g.face('PhotoWarehouse.gable ochre',[(left,y,3.16),(right,y,3.16),((left+right)/2,y,4.34)],ochre)
new=g.flush();g.BATCHES.clear()
for o in new:o['construction_building']='changgo';o['source_object_name']=o.name;o['construction_first']=1;o['construction_last']=99
c['warehousePhotoEnd']={'reference':'photo-gate-references/11.png','wallStart':[cut_x,-3.535],'wallCoreTop':top,'clearEndWidth':2.88,'addedSurfaceObjects':[o.name for o in new],'retainedOriginalWarehouseMeshes':True,'authority':'User photo11: low wall terminates at outside gable corner, ochre above lime render, visible timber frame.'}
(OUT/'connection-contract.json').write_text(json.dumps(c,indent=2),encoding='utf8')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'scene.blend'),compress=True)
items=[o for o in s.objects if o.type=='MESH' and (o.get('construction_building') in ('main_gate','toilet','forecourt_wall') or o.name.startswith('PhotoWarehouse.'))]
for o in s.objects:o.select_set(False)
for o in items:o.select_set(True)
bpy.context.view_layer.objects.active=items[0]
bpy.ops.export_scene.gltf(filepath=str(OUT/'crafted-forecourt.glb'),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True,export_extras=True)
report={'sceneSha256':hashlib.sha256((OUT/'scene.blend').read_bytes()).hexdigest(),'forecourtSha256':hashlib.sha256((OUT/'crafted-forecourt.glb').read_bytes()).hexdigest(),'trimmedAndLoweredMeshes':changed,'addedPlasterObjects':[o.name for o in new],'wallStart':[cut_x,-3.535]}
(OUT/'warehouse-photo-repair.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print('WAREHOUSE CORNER REPAIRED',len(changed),flush=True)
