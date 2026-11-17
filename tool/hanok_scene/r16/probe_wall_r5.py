import bpy,sys,json
from pathlib import Path
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P))
import produce as p
bpy.ops.wm.open_mainfile(filepath=str(P/'sarang/sarang-hangulsori-r2-refined.blend'))
rows=p.read(P/'sarang/material-inventory.json');out=[];seen=set()
for r in rows:
 if r['role']!='plaster':continue
 m=bpy.context.scene.objects[r['object']].material_slots[r['slot']].material
 if m.name in seen:continue
 seen.add(m.name)
 out.append(dict(object=r['object'],material=m.name,nodes=[dict(name=n.name,label=n.label,type=n.type,image=n.image.name if n.type=='TEX_IMAGE' and n.image else None,path=n.image.filepath if n.type=='TEX_IMAGE' and n.image else None,inputs=[dict(name=s.name,source=[(l.from_node.label,l.from_socket.name) for l in s.links]) for s in n.inputs if s.is_linked]) for n in p.live(m.node_tree)]))
p.write(P/'wall-source-r5.json',out)
print('WALL MATERIALS',len(out),flush=True)
