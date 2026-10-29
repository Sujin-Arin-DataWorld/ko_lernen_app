import bpy,json,sys
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P));import sarang_reference_colour_r3 as c
bpy.ops.wm.open_mainfile(filepath=str(P/'sarang-stone-masonry-r10/sarang-stone-masonry-r10.blend'))
targets=[Vector(x) for x in [(12.56,-3.635,6.8),(9.17,-5.47,4.95),(15.93,-5.53,4.95)]];out=[]
for o in bpy.context.scene.objects:
 if o.type!='MESH' or o.name.startswith(('HS','Gye')) or not any(s in o.name.lower() for s in ['finial','end ornament','ridge','hip round']):continue
 links=[[] for _ in o.data.vertices]
 for e in o.data.edges:
  a,b=e.vertices;links[a].append(b);links[b].append(a)
 seen=set()
 for v in o.data.vertices:
  if v.index in seen:continue
  seen.add(v.index);stack=[v.index];ids=[]
  while stack:
   j=stack.pop();ids.append(j)
   for k in links[j]:
    if k not in seen:seen.add(k);stack.append(k)
  vs=[o.matrix_world@o.data.vertices[j].co for j in ids];lo=Vector([min(v[i] for v in vs) for i in range(3)]);hi=Vector([max(v[i] for v in vs) for i in range(3)]);center=(lo+hi)/2
  dist=[(center-t).length for t in targets]
  if min(dist)<.55:out.append(dict(name=o.name,indices=ids if len(ids)<150 else ids[:5],vertexCount=len(ids),lo=list(lo),hi=list(hi),center=list(center),distance=dist,rotation=list(o.rotation_euler),materials=[s.material.name if s.material else '' for s in o.material_slots],points=[list(v) for v in vs] if len(vs)<80 else []))
c.p.write(P/'original-finials-r11.json',out)
print(json.dumps([{k:v for k,v in r.items() if k not in ['points','indices']} for r in out],ensure_ascii=False),flush=True)
