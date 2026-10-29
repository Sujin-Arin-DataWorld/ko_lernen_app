import bpy,json
from pathlib import Path
P=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(P/'sarang-exact-r12/sarang-exact-r12.blend'))
items=[]
for m in bpy.data.materials:
 if m.users==0 or not m.use_nodes:continue
 key=m.get('referenceColourProfile')
 if key not in ('column','beam','gable','rafter','floor','railing','apron','lower_board','door_panel','frame','lattice','endgrain'):continue
 nodes=[]
 for n in m.node_tree.nodes:
  row=dict(name=n.name,label=n.label,type=n.type)
  if n.type=='VALTORGB':row['elements']=[(e.position,list(e.color)) for e in n.color_ramp.elements]
  if n.type=='TEX_IMAGE':row.update(image=n.image.filepath if n.image else None)
  if n.type=='MATH':row.update(operation=n.operation,values=[s.default_value for s in n.inputs])
  nodes.append(row)
 items.append(dict(name=m.name,profile=key,users=m.users,props={k:m[k] for k in m.keys()},nodes=nodes,links=[(l.from_node.name,l.from_socket.name,l.to_node.name,l.to_socket.name) for l in m.node_tree.links]))
(P/'wood-current-r12.json').write_text(json.dumps(items,ensure_ascii=False,indent=2,default=str),encoding='utf-8')
print([(i['name'],i['profile'],i['users']) for i in items],flush=True)
