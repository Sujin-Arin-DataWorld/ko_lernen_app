"""Isolate the actual saved soil graph on one flat plane, no estate geometry."""
import bpy, json, hashlib
from pathlib import Path
OUT=Path(__file__).resolve().parent
report=json.loads((OUT/'verification.json').read_text(encoding='utf-8'))
library=OUT/report['library']
assert hashlib.sha256(library.read_bytes()).hexdigest()==report['library_sha256']
name=next(iter(report['material_signatures']))
with bpy.data.libraries.load(str(library),link=False) as (src,dst):dst.materials=[name]
mat=dst.materials[0]
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.mesh.primitive_plane_add(size=200)
bpy.context.object.data.materials.append(mat)
scene=bpy.context.scene
bpy.ops.object.camera_add()
scene.camera=bpy.context.object
manifest=json.loads((OUT/'render-manifest.json').read_text(encoding='utf-8'))
camera=next(r['camera'] for r in manifest['renders'] if r['view']=='overview')
scene.camera.location=camera['location'];scene.camera.rotation_euler=camera['rotation']
scene.camera.data.type='ORTHO';scene.camera.data.ortho_scale=camera['ortho_scale']
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=1
scene.cycles.use_denoising=False;scene.render.threads_mode='FIXED';scene.render.threads=4
scene.render.resolution_x=1280;scene.render.resolution_y=960;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='Standard'
tree=mat.node_tree
output=next(n for n in tree.nodes if n.type=='OUTPUT_MATERIAL' and n.is_active_output)
bsdf=next(n for n in tree.nodes if n.label=='R4 interior compacted earth')
contrast=next(n for n in tree.nodes if n.label=='north entry open consolidation blended body contrast')
emit=tree.nodes.new('ShaderNodeEmission');tree.links.new(emit.outputs[0],output.inputs['Surface'])
for label,socket in [('flat-albedo',bsdf.inputs['Base Color'].links[0].from_socket),
                     ('flat-body-contrast',contrast.outputs[0])]:
    tree.links.new(socket,emit.inputs['Color'])
    scene.render.filepath=str(OUT/(label+'.png'))
    bpy.ops.render.render(write_still=True)
    print('DIAGNOSTIC SAVED',label,flush=True)
nodes=[dict(name=n.name,label=n.label,type=n.type,
            interpolation=getattr(n,'interpolation_type',None),clamp=getattr(n,'clamp',None),
            inputs={s.name:list(s.default_value) if hasattr(s.default_value,'__iter__') else s.default_value
                    for s in n.inputs if hasattr(s,'default_value') and not s.is_linked})
       for n in tree.nodes if n.label.startswith('front gate to foundation consolidation')]
(OUT/'flat-material-node-settings.json').write_text(json.dumps(nodes,indent=2),encoding='utf-8')
