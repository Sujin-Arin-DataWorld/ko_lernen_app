import bpy,sys,json
from pathlib import Path
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P));import sarang_reference_colour_r3 as c
bpy.ops.wm.open_mainfile(filepath=str(P/'sarang-wood-r15/sarang-wood-r15.blend'))
names=['Continuity.numaru corner posts']
names += [o.name for o in bpy.context.scene.objects if o.name.startswith('Enclosure.numaru lower') and 'vertical board' in o.name][:3]
rows=[]
for name in names:
 o=bpy.context.scene.objects[name];row=dict(object=name,dimensions=list(o.dimensions),uv={})
 for uv in o.data.uv_layers:
  values=[tuple(x.uv) for x in uv.data];row['uv'][uv.name]=[(min(x[i] for x in values),max(x[i] for x in values)) for i in (0,1)]
 for attr in o.data.attributes:
  if attr.name in ('P18 surface UV','P18 long timber UV'):
   a=[tuple(x.vector) for x in attr.data];row[attr.name]=[(min(x[i] for x in a),max(x[i] for x in a)) for i in (0,1)]
 m=next(s.material for s in o.material_slots if s.material and s.material.get('hs14_individual_wood'))
 n=next(n for n in m.node_tree.nodes if n.label=='Craft wood panel');todo=[n];seen=set();dump=[]
 while todo:
  n=todo.pop()
  if n in seen:continue
  seen.add(n)
  dump.append(dict(label=n.label,type=n.type,operation=getattr(n,'operation',None),uv=getattr(n,'uv_map',None),attr=getattr(n,'attribute_name',None),inputs=[dict(name=s.name,value=list(s.default_value) if hasattr(s.default_value,'__len__') else s.default_value,links=[(l.from_node.label,l.from_socket.name) for l in s.links]) for s in n.inputs if hasattr(s,'default_value')]))
  todo.extend(l.from_node for s in n.inputs for l in s.links)
 row['coordinateNodes']=dump;rows.append(row)
(P/'grain-coordinates-r16.json').write_text(json.dumps(rows,indent=2));print(json.dumps([{k:v for k,v in r.items() if k!='coordinateNodes'} for r in rows],indent=2))
