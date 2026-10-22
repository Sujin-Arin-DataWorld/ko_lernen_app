import bpy,importlib.util,json
from pathlib import Path
from mathutils import Vector
out=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('r1',out.parent/'lookdev-sarang-r1/render_lookdev.py')
r=importlib.util.module_from_spec(spec);spec.loader.exec_module(r);r.OUT=out
bpy.ops.wm.open_mainfile(filepath=str(out.parent/'lookdev-sarang-r2/sarang-handpaint-candidate.blend'))
scene=bpy.context.scene
rows=[]
for ob in scene.objects:
    if 'Craft.Sarang broad apron boards' not in ob.name:continue
    bb=[ob.matrix_world@Vector(v) for v in ob.bound_box]
    rows.append(dict(name=ob.name,min=[min(v[i] for v in bb) for i in range(3)],max=[max(v[i] for v in bb) for i in range(3)],material=[s.material.name for s in ob.material_slots]))
(out/'front-apron-audit.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
print(json.dumps(rows,indent=2))
for ob in scene.objects:
    if ob.type!='MESH':continue
    for sl in ob.material_slots:
        mat=sl.material
        if not mat or not mat.use_nodes:continue
        cached=bpy.data.materials.get('DEBUG ALBEDO | '+mat.name)
        if not cached:
            cached=mat.copy();cached.name='DEBUG ALBEDO | '+mat.name
            t=cached.node_tree;b=next((n for n in t.nodes if n.type=='BSDF_PRINCIPLED'),None)
            if b:
                emit=t.nodes.new('ShaderNodeEmission');emit.inputs['Color'].default_value=b.inputs['Base Color'].default_value
                if b.inputs['Base Color'].is_linked:t.links.new(b.inputs['Base Color'].links[0].from_socket,emit.inputs['Color'])
                output=next(n for n in t.nodes if n.type=='OUTPUT_MATERIAL');t.links.new(emit.outputs[0],output.inputs['Surface'])
        sl.link='OBJECT';sl.material=cached
scene.cycles.samples=1;scene.cycles.use_denoising=False
r.render(scene,scene.camera,'diagnostic-unlit-numaru.png',position=(16,-18,5.3),target=(11.5,-2.8,2.7),ortho=6.0,resolution=(800,700))
print('DIAGNOSTIC ONLY; NATIVE NOT SAVED')
