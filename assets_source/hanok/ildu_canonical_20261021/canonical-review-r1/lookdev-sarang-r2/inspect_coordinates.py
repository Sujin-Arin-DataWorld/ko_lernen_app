import bpy,json
from pathlib import Path
from mathutils import Vector
out=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(out.parent/'lookdev-sarang-r1/sarang-lookdev-candidate.blend'))
obs=[o for o in bpy.context.scene.objects if o.type=='MESH']
rows=[]
for ob in obs:
    if not any(k in ob.name.lower() for k in ['column','post','stair','main roof','plaque','front wall','numaru front','balustrade','front lower']):continue
    bb=[ob.matrix_world@Vector(v) for v in ob.bound_box]
    rows.append(dict(name=ob.name,center=list(sum(bb,Vector())/8),dimensions=list(ob.dimensions),uvs=[u.name for u in ob.data.uv_layers],attributes=[a.name for a in ob.data.attributes]))
(out/'coordinate-audit.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
for r in rows:
    print(r['name'],r['center'],r['dimensions'])
ob=bpy.data.objects['Continuity.numaru corner posts']
for mat in {s.material for s in ob.material_slots if s.material}:
    if 'tone 3' not in mat.name:continue
    print('MAT',mat.name)
    for n in mat.node_tree.nodes:
        if n.type=='ATTRIBUTE':print(n.name,n.attribute_name)
        if n.type=='UVMAP':print(n.name,n.uv_map)
        if n.type=='BUMP':print('bump',[(i.name,i.default_value) for i in n.inputs if not i.is_linked and hasattr(i,'default_value')])
    for a in ob.data.attributes:
        print('ATTR',a.name,a.domain,a.data_type,len(a.data),str(a.data[0]) if a.data else '')
