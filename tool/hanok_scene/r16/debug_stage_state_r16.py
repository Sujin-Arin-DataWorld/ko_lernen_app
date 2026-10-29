import bpy,sys,json
from pathlib import Path
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P));import produce as p
names=p.read(P/'sarang/geometry-lock.json')['objects'];sel=p.read(P/'family-r16/sarang/stage-selection.json')
def snap(path):
 bpy.ops.wm.open_mainfile(filepath=str(path));sc=bpy.context.scene
 for name,state in sel['baseline'].items():
  sc.objects[name].hide_render=state['hideRender'];sc.objects[name].hide_viewport=state['hideViewport']
 bpy.context.view_layer.update()
 obs=[sc.objects[n] for n in names]
 return dict(geometry=p.s.geometry_state(obs),attrs=p.r2.attributes(obs),props=p.ext.object_properties(obs),hash=p.architecture(obs))
a=snap(P/'sarang-wood-r16/sarang-wood-r16.blend');b=snap(P/'family-r16/sarang/stage.blend')
diff={}
for part in ('geometry','attrs','props'):
 if a[part]!=b[part]:
  if isinstance(a[part],dict):
   diff[part]=[]
   for name,aa in a[part].items():
    bb=b[part].get(name)
    if aa==bb:continue
    values=[(k,aa[k],bb.get(k)) for k in aa if aa[k]!=bb.get(k)] if isinstance(aa,dict) else [aa,bb]
    diff[part].append((name,values))
  else:diff[part]=(str(a[part])[:500],str(b[part])[:500])
print('HASHES',a['hash'],b['hash']);print(json.dumps(diff,indent=2)[:9000]);p.write(P/'stage-state-diff-r16.json',diff)
