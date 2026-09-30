"""Bake very shallow timber relief through Blender's tangent-normal baker.

The generated albedo images stay byte-identical. These new normal textures
describe sub-millimetre fibre relief, never displacement of measured members.
"""
from pathlib import Path
import bpy,json,hashlib
OUT=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/northern-court/materials'
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=1
bpy.ops.mesh.primitive_plane_add(size=2)
plane=bpy.context.object;plane.name='Temporary physical material swatch'
plane.scale=(.6,1.4,1);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
report=[]
for kind in ('longgrain','endgrain'):
    source=OUT/f'hanok-pine-{kind}-v1.png'
    mat=bpy.data.materials.new('Bake '+kind);mat.use_nodes=True;nodes=mat.node_tree.nodes;links=mat.node_tree.links
    nodes.clear();shader=nodes.new('ShaderNodeBsdfPrincipled');output=nodes.new('ShaderNodeOutputMaterial');links.new(shader.outputs['BSDF'],output.inputs['Surface'])
    tex=nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(source));tex.extension='REPEAT'
    links.new(tex.outputs['Color'],shader.inputs['Base Color'])
    bump=nodes.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.24;bump.inputs['Distance'].default_value=.00045
    links.new(tex.outputs['Color'],bump.inputs['Height']);links.new(bump.outputs['Normal'],shader.inputs['Normal'])
    normal=bpy.data.images.new('Pine '+kind+' tangent normal',width=1024,height=1024,alpha=False);normal.colorspace_settings.name='Non-Color'
    target=nodes.new('ShaderNodeTexImage');target.image=normal;nodes.active=target
    plane.data.materials.clear();plane.data.materials.append(mat)
    scene.render.bake.use_selected_to_active=False;scene.render.bake.normal_space='TANGENT';scene.render.bake.margin=0
    bpy.ops.object.bake(type='NORMAL')
    normal.filepath_raw=str(OUT/f'hanok-pine-{kind}-normal-v1.png');normal.file_format='PNG';normal.save()
    report.append({'source':source.name,'sourceSha256':hashlib.sha256(source.read_bytes()).hexdigest(),'normal':Path(normal.filepath_raw).name,'bumpDistanceMeters':.00045,'strength':.24,'physicalSwatchMeters':[1.2,2.8]})
(OUT/'normal-bake.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print('NORMALS BAKED',len(report),flush=True)
