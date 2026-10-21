import bpy,json
from pathlib import Path
OUT=Path(__file__).resolve().parent
source=OUT.parent/'ildu-estate-yard-wall-r1.blend'
with bpy.data.libraries.load(str(source),link=False) as (src,dst):
    light_names=list(src.lights);object_names=list(src.objects)
    dst.lights=light_names;dst.worlds=list(src.worlds)
lights=[]
for light in dst.lights:
    r=dict(name=light.name,type=light.type,energy=light.energy)
    for k in ('spread','spot_size','spot_blend','size','size_y','shape','use_shadow','use_custom_distance','cutoff_distance'):
        if hasattr(light,k):r[k]=getattr(light,k)
    if light.use_nodes:
        r['nodes']=[dict(name=n.name,type=n.type) for n in light.node_tree.nodes]
    lights.append(r)
report=dict(lights=lights,worlds=[dict(name=w.name,nodes=[dict(name=n.name,type=n.type) for n in w.node_tree.nodes] if w.use_nodes else []) for w in dst.worlds],
            possible_light_objects=[n for n in object_names if any(k in n.lower() for k in ('light','softbox','key','fill','sun','rim'))])
v=json.loads((OUT/'verification.json').read_text(encoding='utf-8'))
with bpy.data.libraries.load(str(OUT/v['library']),link=False) as (src,dst):dst.materials=list(v['material_signatures'])
mat=dst.materials[0]
report['soil_outputs']=[dict(name=n.name,target=n.target,active=n.is_active_output,inputs={s.name:[l.from_node.name for l in s.links] for s in n.inputs}) for n in mat.node_tree.nodes if n.type=='OUTPUT_MATERIAL']
report['displacement_method']=getattr(mat,'displacement_method',None)
(OUT/'lighting-inventory.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report),flush=True)
