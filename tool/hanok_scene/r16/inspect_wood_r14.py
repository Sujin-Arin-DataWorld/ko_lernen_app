import bpy,json,sys
from pathlib import Path
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P))
import sarang_reference_colour_r3 as c
bpy.ops.wm.open_mainfile(filepath=str(P/'sarang-palette-r13/sarang-palette-r13.blend'))
sc=bpy.context.scene; rows=[]; seen=set(); counts={}
for ob in sc.objects:
 if ob.type!='MESH' or ob.hide_render:continue
 for i,s in enumerate(ob.material_slots):
  m=s.material
  if not m or not m.get('hs12_wood_direction'):continue
  role=m.get('referenceColourProfile');counts[role]=counts.get(role,0)+1
  if role in seen:continue
  seen.add(role);t=m.node_tree
  nodes=[]
  for n in c.p.live(t):
   nodes.append(dict(name=n.name,label=n.label,type=n.type,operation=getattr(n,'operation',None),attribute=getattr(n,'attribute_name',None),image=n.image.filepath if n.type=='TEX_IMAGE' and n.image else None,inputs=[dict(name=x.name,value=list(x.default_value) if hasattr(x.default_value,'__len__') else x.default_value,links=[(l.from_node.name,l.from_socket.name) for l in x.links]) for x in n.inputs if hasattr(x,'default_value')],ramp=[(e.position,list(e.color)) for e in n.color_ramp.elements] if n.type=='VALTORGB' else None))
  rows.append(dict(role=role,object=ob.name,material=m.name,nodes=nodes,attributes=[(a.name,a.domain,a.data_type) for a in ob.data.attributes]))
(P/'wood-inspection-r14.json').write_text(json.dumps(dict(counts=counts,examples=rows),indent=2),encoding='utf-8')
print(json.dumps(dict(counts=counts,examples=[dict(role=r['role'],object=r['object'],attributes=r['attributes']) for r in rows]),indent=2))
