"""Compare the retained scalar to actual Cycles emission baking, no R12 edits."""
import json
import sys
from pathlib import Path

import bpy

sys.path.insert(0, str(Path(__file__).parent))
from cycles_object_random import object_random

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 1
scene.cycles.device = 'CPU'
scene.render.bake.margin = 0
results = []
for name in ('R12.RandomProof.A', 'R12.RandomProof.B', 'North.sadangmun.measuredSquareRafter.001', '사당문.기둥'):
    bpy.ops.mesh.primitive_plane_add()
    ob = bpy.context.object
    ob.name = name
    assert ob.name == name
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    source = nt.nodes.new('ShaderNodeObjectInfo')
    em = nt.nodes.new('ShaderNodeEmission')
    output = nt.nodes.new('ShaderNodeOutputMaterial')
    nt.links.new(source.outputs['Random'], em.inputs['Color'])
    nt.links.new(em.outputs[0], output.inputs['Surface'])
    img = bpy.data.images.new(name, width=16, height=16, float_buffer=True)
    img.colorspace_settings.name = 'Non-Color'
    target = nt.nodes.new('ShaderNodeTexImage')
    target.image = img
    nt.nodes.active = target
    ob.data.materials.append(mat)
    bpy.ops.object.bake(type='EMIT')
    measured = img.pixels[(8*16+8)*4]
    expected = object_random(name)
    results.append(dict(name=name, measured=measured, expected=expected, error=abs(measured-expected)))
    assert abs(measured - expected) < 1e-6, results[-1]
    bpy.data.objects.remove(ob, do_unlink=True)
out = Path(sys.argv[sys.argv.index('--')+1])
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps(dict(blender=bpy.app.version_string, passed=True, cases=results), ensure_ascii=False, indent=2), encoding='utf-8')
print('CYCLES_RANDOM_PARITY_PASS', flush=True)
