"""Separate actual ground illumination, cast shadows and the saved soil BSDF."""
import bpy,json
from pathlib import Path
OUT=Path(__file__).resolve().parent
scene=bpy.data.scenes['Hangul Sori | Full Ildu Estate'];bpy.context.window.scene=scene
lights=[dict(name=o.name,kind=o.data.type,location=list(o.location),rotation=list(o.rotation_euler),
             energy=o.data.energy,hide_render=o.hide_render,angle=getattr(o.data,'angle',None),
             size=getattr(o.data,'size',None)) for o in scene.objects if o.type=='LIGHT']
volumes=[]
for o in scene.objects:
    for s in o.material_slots:
        if not s.material or not s.material.use_nodes:continue
        if any(n.type=='OUTPUT_MATERIAL' and n.is_active_output and n.inputs['Volume'].is_linked for n in s.material.node_tree.nodes):
            volumes.append(dict(object=o.name,material=s.material.name))
compositor=getattr(scene,'compositing_node_group',None) or getattr(scene,'node_tree',None)
meta=dict(lights=lights,volume_objects=volumes,use_nodes=scene.use_nodes,
          compositor=[dict(name=n.name,type=n.type) for n in compositor.nodes] if compositor else [],
          compositor_api=[k for k in dir(scene) if 'compos' in k or 'node' in k],
          layers=[dict(name=l.name,use=l.use,override=l.material_override.name if l.material_override else None) for l in scene.view_layers])
(OUT/'actual-lighting-scene.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2),encoding='utf-8')
print('SCENE LIGHTING',json.dumps(meta,ensure_ascii=False),flush=True)
manifest=json.loads((OUT/'render-manifest.json').read_text(encoding='utf-8'));camera=next(r['camera'] for r in manifest['renders'] if r['view']=='overview')
scene.camera.location=camera['location'];scene.camera.rotation_euler=camera['rotation'];scene.camera.data.ortho_scale=camera['ortho_scale']
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=8;scene.cycles.use_denoising=False
scene.render.use_persistent_data=True;scene.render.threads_mode='FIXED';scene.render.threads=8
scene.render.resolution_x=1280;scene.render.resolution_y=960;scene.render.resolution_percentage=100
scene.render.use_border=True;scene.render.use_crop_to_border=True
scene.render.border_min_x=775/1280;scene.render.border_max_x=1240/1280
scene.render.border_min_y=1-320/960;scene.render.border_max_y=1-70/960
scene.render.use_compositing=False;scene.render.use_sequencer=False;scene.render.image_settings.file_format='PNG'
ground=bpy.data.objects['GyeGrass.earth.v55.0 | R12 landing occupancy cut']
original=ground.material_slots[0].material
mat=bpy.data.materials.new('DIAGNOSTIC flat diffuse no bump');mat.use_nodes=True;mat.node_tree.nodes.clear()
d=mat.node_tree.nodes.new('ShaderNodeBsdfDiffuse');d.inputs['Color'].default_value=(.355,.282,.197,1);d.inputs['Normal'].default_value=(0,0,1)
out=mat.node_tree.nodes.new('ShaderNodeOutputMaterial');mat.node_tree.links.new(d.outputs[0],out.inputs['Surface'])
ground.material_slots[0].link='OBJECT';ground.material_slots[0].material=mat
def render(label):
    scene.render.filepath=str(OUT/(label+'.png'));bpy.ops.render.render(write_still=True,scene=scene.name);print('SAVED',label,flush=True)
render('lighting-constant-with-shadows')
shadow={o.name:o.visible_shadow for o in scene.objects}
for o in scene.objects:o.visible_shadow=False
render('lighting-constant-no-shadows')
for o in scene.objects:o.visible_shadow=shadow[o.name]
v=json.loads((OUT/'verification.json').read_text(encoding='utf-8'))
with bpy.data.libraries.load(str(OUT/v['library']),link=False) as (src,dst):dst.materials=list(v['material_signatures'])
soil=dst.materials[0];ground.material_slots[0].material=soil
render('lighting-r4-no-postprocess')
