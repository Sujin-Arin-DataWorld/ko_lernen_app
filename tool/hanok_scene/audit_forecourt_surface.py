"""Identify visible near-camera surface artifacts by native scene raycast."""
from pathlib import Path
import bpy,json
from mathutils import Vector
OUT=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/side-connections'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'scene.blend'))
s=bpy.context.scene;bpy.context.view_layer.update();deps=bpy.context.evaluated_depsgraph_get()
pos=Vector((-12,-10,4.5));target=Vector((-18.5,-7,1.5));rot=(target-pos).to_track_quat('-Z','Y');direction=(target-pos).normalized()
for x,y in [(549,624),(551,666),(546,687),(562,676),(550,600),(253,787)]:
 origin=pos+rot@Vector(((x/1260-.5)*7.5,(.5-y/840)*5,0))
 hit,loc,norm,index,obj,matrix=s.ray_cast(deps,origin,direction)
 if hit:
  evaluated=obj.evaluated_get(deps);m=evaluated.data.materials[evaluated.data.polygons[index].material_index]
  print('SURFACE',json.dumps({'pixel':[x,y],'object':obj.name,'face':index,'point':list(loc),'material':m.name,'nodes':[(n.type,n.name) for n in m.node_tree.nodes],'attributes':[a.name for a in obj.data.color_attributes]}),flush=True)
print('TOILET_MESHES',json.dumps([(o.name,[m.name for m in o.data.materials]) for o in s.objects if o.type=='MESH' and o.get('construction_building')=='toilet']),flush=True)
