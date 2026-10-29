import bpy, sys, json
from pathlib import Path
P=Path(__file__).resolve().parent
sys.path.insert(0,str(P))
import produce as p
bpy.ops.wm.open_mainfile(filepath=str(P/'sarang/sarang-hangulsori-r2-refined.blend'))
rows=p.read(P/'sarang/material-inventory.json'); seen=set(); out=[]
for r in rows:
 m=bpy.context.scene.objects[r['object']].material_slots[r['slot']].material
 if (m.name,r['role']) in seen:continue
 seen.add((m.name,r['role']))
 if r['role'] not in ('wood','lattice','endgrain','tile','stone','paper'):continue
 ns=[]
 for n in m.node_tree.nodes:
  if n.type=='TEX_IMAGE':
   ns.append(dict(label=n.label,name=n.name,image=n.image.name if n.image else None,path=n.image.filepath if n.image else None,size=list(n.image.size) if n.image else [],coords=[l.from_node.label for l in n.inputs['Vector'].links]))
 out.append(dict(role=r['role'],object=r['object'],material=m.name,images=ns))
p.write(P/'clean-source-probe.json',out)
print('SOURCE PROBE',len(out),flush=True)
