"""Bake a submillimetre painted-fiber relief; retain generated albedo bytes."""
from pathlib import Path
import bpy,json,hashlib
OUT=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/northern-court/materials'
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.samples=1
bpy.ops.mesh.primitive_plane_add(size=.60);plane=bpy.context.object
for vertex in plane.data.vertices:vertex.co.y*=3
report=[]
for kind in ('red','green'):
    source=OUT/f'hanok-painted-{kind}-v1.png';mat=bpy.data.materials.new('Bake painted fibers '+kind);mat.use_nodes=True
    nodes=mat.node_tree.nodes;links=mat.node_tree.links;nodes.clear()
    shader=nodes.new('ShaderNodeBsdfPrincipled');output=nodes.new('ShaderNodeOutputMaterial');links.new(shader.outputs[0],output.inputs['Surface'])
    image=nodes.new('ShaderNodeTexImage');image.image=bpy.data.images.load(str(source));image.extension='REPEAT'
    bump=nodes.new('ShaderNodeBump');bump.inputs['Distance'].default_value=.00055;bump.inputs['Strength'].default_value=.25
    links.new(image.outputs['Color'],bump.inputs['Height']);links.new(bump.outputs['Normal'],shader.inputs['Normal'])
    normal=bpy.data.images.new(kind+' painted timber normal',width=1024,height=1024,alpha=False);normal.colorspace_settings.name='Non-Color'
    target=nodes.new('ShaderNodeTexImage');target.image=normal;nodes.active=target;plane.data.materials.clear();plane.data.materials.append(mat)
    s.render.bake.use_selected_to_active=False;s.render.bake.normal_space='TANGENT';s.render.bake.margin=0
    bpy.ops.object.bake(type='NORMAL');normal.filepath_raw=str(OUT/f'hanok-painted-{kind}-normal-v1.png');normal.file_format='PNG';normal.save()
    report.append({'source':source.name,'sourceSha256':hashlib.sha256(source.read_bytes()).hexdigest(),'normal':Path(normal.filepath_raw).name,'physicalSwatchMeters':[.60,1.80],'bumpDistanceMeters':.00055,'strength':.25})
(OUT/'paint-normal-bake.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print('PAINT NORMALS BAKED',len(report),flush=True)
