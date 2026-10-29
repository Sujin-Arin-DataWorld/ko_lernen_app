import bpy,sys,json
from pathlib import Path
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P));import sarang_reference_colour_r3 as c
bpy.ops.wm.open_mainfile(filepath=str(P/'sarang-wrap-r9/sarang-wrap-r9.blend'))
out={}
for o in bpy.context.scene.objects:
 if not (o.name.startswith(('Craft.Sarang dressed','Craft.Numaru dressed','GyeStyle.Sarang irregular stone facing','V25.stair cheek','GyeCraft.sarang.irregular paving'))):continue
 links=[[] for _ in o.data.vertices]
 for e in o.data.edges:
  a,b=e.vertices;links[a].append(b);links[b].append(a)
 seen=set();rows=[]
 for v in o.data.vertices:
  if v.index in seen:continue
  seen.add(v.index);stack=[v.index];ids=[]
  while stack:
   j=stack.pop();ids.append(j)
   for k in links[j]:
    if k not in seen:seen.add(k);stack.append(k)
  co=[o.matrix_world@o.data.vertices[j].co for j in ids]
  rows.append(dict(n=len(ids),lo=[round(min(v[i] for v in co),4) for i in range(3)],hi=[round(max(v[i] for v in co),4) for i in range(3)]))
 out[o.name]=rows
c.p.write(P/'stone-islands-r10.json',out)
for name,rows in out.items():print(name,len(rows),rows[:6],flush=True)
