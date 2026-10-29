import bpy,sys,json
from pathlib import Path
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P));import sarang_reference_colour_r3 as c
p=c.p;bpy.ops.wm.open_mainfile(filepath=str(P/'sarang-wrap-r9/sarang-wrap-r9.blend'))
rows=[]
for m in bpy.data.materials:
 if m.get('guardian6')!='stone':continue
 for bs in [n for n in p.live(m.node_tree) if n.type=='BSDF_PRINCIPLED']:
  values={}
  for k in ['Base Color','Metallic','Roughness','Specular IOR Level','Emission Color','Emission Strength']:
   s=bs.inputs[k];values[k]=dict(value=list(s.default_value) if hasattr(s.default_value,'__iter__') else s.default_value,link=[(l.from_node.name,l.from_socket.name) for l in s.links])
  rows.append(dict(name=m.name,values=values))
print(json.dumps(rows[:3],ensure_ascii=False),flush=True)
