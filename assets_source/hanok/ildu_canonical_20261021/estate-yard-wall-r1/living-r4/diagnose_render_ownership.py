"""Actual render-scene ownership proof, cropped to the reported seam."""
import bpy,json
from pathlib import Path
from mathutils import Euler,Vector
OUT=Path(__file__).resolve().parent
scene=bpy.data.scenes['Hangul Sori | Full Ildu Estate']
context_before=bpy.context.scene.name
bpy.context.window.scene=scene
graph=bpy.context.evaluated_depsgraph_get()
manifest=json.loads((OUT/'render-manifest.json').read_text(encoding='utf-8'))
camera=next(r['camera'] for r in manifest['renders'] if r['view']=='overview')
scene.camera.location=camera['location'];scene.camera.rotation_euler=camera['rotation']
scene.camera.data.ortho_scale=camera['ortho_scale']
rotation=Euler(camera['rotation'],'XYZ').to_matrix()
right,up,back=(rotation@Vector(v) for v in ((1,0,0),(0,1,0),(0,0,1)))
pos=Vector(camera['location']); hits=[]
for x,y in [(1100,150),(1100,180),(1100,210),(1000,200),(1000,230),(1000,260),(950,245),(950,275)]:
    origin=pos+right*((x/1280-.5)*camera['ortho_scale'])+up*((.5-y/960)*camera['ortho_scale']*.75)
    hit,loc,norm,face,obj,matrix=scene.ray_cast(graph,origin,-back)
    mat=None
    if hit and obj.type=='MESH':
        evaluated=obj.evaluated_get(graph);idx=evaluated.data.polygons[face].material_index
        mat=obj.material_slots[idx].material.name if obj.material_slots[idx].material else None
    hits.append(dict(pixel=[x,y],object=obj.name if hit else None,material=mat,
                     position=list(loc) if hit else None,normal=list(norm) if hit else None))
report=dict(context_before=context_before,render_scene=scene.name,hits=hits)
(OUT/'actual-render-ownership.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print('ACTUAL RENDER OWNERSHIP',json.dumps(report,ensure_ascii=False),flush=True)
mat=bpy.data.materials.new('DIAGNOSTIC object ownership only');mat.use_nodes=True
tree=mat.node_tree;tree.nodes.clear()
info=tree.nodes.new('ShaderNodeObjectInfo');emit=tree.nodes.new('ShaderNodeEmission');out=tree.nodes.new('ShaderNodeOutputMaterial')
tree.links.new(info.outputs['Color'],emit.inputs['Color']);tree.links.new(emit.outputs[0],out.inputs['Surface'])
for obj in scene.objects:
    obj.color=(1,0,0,1) if obj.name=='GyeGrass.earth.v55.0 | R12 landing occupancy cut' else (0,0,1,1)
for layer in scene.view_layers:layer.material_override=mat
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=1;scene.cycles.use_denoising=False
scene.render.threads_mode='FIXED';scene.render.threads=4
scene.render.resolution_x=1280;scene.render.resolution_y=960;scene.render.resolution_percentage=100
scene.render.use_border=True;scene.render.use_crop_to_border=True
scene.render.border_min_x=775/1280;scene.render.border_max_x=1240/1280
scene.render.border_min_y=1-320/960;scene.render.border_max_y=1-70/960
scene.view_settings.view_transform='Standard';scene.render.image_settings.file_format='PNG'
scene.render.filepath=str(OUT/'actual-render-ownership.png')
bpy.ops.render.render(write_still=True,scene=scene.name)
