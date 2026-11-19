import bpy,sys,json
from pathlib import Path
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P));import produce as p
bpy.ops.wm.open_mainfile(filepath=str(P/'sarang-r9/sarang-r9.blend'))
o=bpy.context.scene.objects['Craft.Sarang broad apron boards'];m=next(s.material for s in o.material_slots if s.material and s.material.get('hs8_profile'))
rows=[]
for n in p.live(m.node_tree):
 if n.type not in ('MIX_RGB','VALTORGB','RGBTOBW','MATH','TEX_IMAGE','BRIGHTCONTRAST','HUE_SAT'):continue
 vals=[]
 for i in n.inputs:
  if i.is_linked:vals.append([i.name,'<-',i.links[0].from_node.label,i.links[0].from_socket.name])
  elif hasattr(i,'default_value'):
   v=i.default_value
   try:v=list(v)
   except TypeError:pass
   vals.append([i.name,v])
 rows.append(dict(label=n.label,type=n.type,inputs=vals,ramp=[(e.position,list(e.color)) for e in n.color_ramp.elements] if n.type=='VALTORGB' else None))
p.write(P/'wood-node-probe.json',rows)
print('PROBE',m.name,len(rows),flush=True)
