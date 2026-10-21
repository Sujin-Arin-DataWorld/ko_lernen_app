"""Measure native missing named-UV behavior before preserving it in the bake."""
import json
import sys
from pathlib import Path
import bpy

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.mesh.primitive_plane_add()
ob = bpy.context.object
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 1
scene.render.bake.margin = 0
mat = bpy.data.materials.new('UV fallback proof')
mat.use_nodes = True
ob.data.materials.append(mat)
nt = mat.node_tree
nt.nodes.clear()
uv = nt.nodes.new('ShaderNodeUVMap')
em = nt.nodes.new('ShaderNodeEmission')
output = nt.nodes.new('ShaderNodeOutputMaterial')
nt.links.new(uv.outputs['UV'], em.inputs['Color'])
nt.links.new(em.outputs[0], output.inputs['Surface'])
img = bpy.data.images.new('UV result', width=16, height=16, float_buffer=True)
img.colorspace_settings.name = 'Non-Color'
target = nt.nodes.new('ShaderNodeTexImage')
target.image = img
nt.nodes.active = target
results = {}
for name in ('UVMap', 'Missing native UV'):
    uv.uv_map = name
    bpy.ops.object.bake(type='EMIT')
    results[name] = list(img.pixels[(8*16+8)*4:(8*16+8)*4+3])
assert max(abs(x) for x in results['Missing native UV']) < 1e-6, results
assert results['UVMap'][0] > .45, results
normal = nt.nodes.new('ShaderNodeNormalMap')
normal.inputs['Color'].default_value = (1, .5, 1, 1)
nt.links.new(normal.outputs['Normal'], em.inputs['Color'])
ob.data.uv_layers.new(name='Explicit zero UV')
for loop in ob.data.uv_layers['Explicit zero UV'].data:
    loop.uv = (0, 0)
ob.data.uv_layers.active = ob.data.uv_layers['UVMap']
ob.data.uv_layers['UVMap'].active_render = True
for name in ('Missing native UV', 'Explicit zero UV', 'UVMap'):
    normal.uv_map = name
    bpy.ops.object.bake(type='EMIT')
    results['normal '+name] = list(img.pixels[(8*16+8)*4:(8*16+8)*4+3])
assert results['normal Missing native UV'] == [0.0, 0.0, 1.0], results
assert results['normal Explicit zero UV'][0] > .7, results
path = Path(sys.argv[sys.argv.index('--')+1])
path.write_text(json.dumps(dict(blender=bpy.app.version_string, passed=True, cases=results),indent=2),encoding='utf-8')
print('MISSING_UV_ZERO_PARITY_PASS', flush=True)
