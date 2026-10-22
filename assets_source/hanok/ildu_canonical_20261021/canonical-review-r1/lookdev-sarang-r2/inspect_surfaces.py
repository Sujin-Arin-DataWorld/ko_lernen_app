import bpy, json
from pathlib import Path
out = Path(__file__).resolve().parent
src = out.parent / 'lookdev-sarang-r1/sarang-lookdev-candidate.blend'
bpy.ops.wm.open_mainfile(filepath=str(src))
records = []
for category in ['wood', 'stone', 'tile', 'plaster']:
    matches = []
    for ob in bpy.context.scene.objects:
        if ob.type != 'MESH': continue
        for slot in ob.material_slots:
            mat = slot.material
            if not mat: continue
            name = mat.name.lower()
            hit = dict(wood=any(k in name for k in ['pine', '.wood.']), stone=any(k in name for k in ['.stone.', 'limestone', 'fieldstone']), tile=any(k in name for k in ['.tile.', 'charcoal clay']), plaster='plaster' in name)[category]
            if hit: matches.append((ob,mat))
    unique={}
    for ob,mat in matches:
        if mat.name in unique: continue
        unique[mat.name]=dict(object=ob.name, dimensions=list(ob.dimensions), location=list(ob.location), rotation=list(ob.rotation_euler), scale=list(ob.scale), material=mat.name,
            nodes=[dict(name=n.name,type=n.bl_idname,scale=n.inputs['Scale'].default_value if 'Scale' in n.inputs and isinstance(n.inputs['Scale'].default_value,(float,int)) else None,
                        vector=list(n.inputs['Scale'].default_value) if n.type=='MAPPING' else None,
                        image=n.image.name if n.type=='TEX_IMAGE' and n.image else None) for n in mat.node_tree.nodes],
            links=[(l.from_node.name,l.from_socket.name,l.to_node.name,l.to_socket.name) for l in mat.node_tree.links])
        if len(unique)>=3: break
    records.append(dict(category=category,total=len(matches),examples=list(unique.values())))
(out/'source-surface-graphs.json').write_text(json.dumps(records,indent=2),encoding='utf-8')
print(json.dumps(records,indent=2))
