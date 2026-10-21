import bpy,json,sys
from pathlib import Path
from mathutils import Vector
R=Path(__file__).resolve().parent.parent
M=json.loads((R/'construction/contracts/r12-owner-map.json').read_text(encoding='utf-8'))
S=bpy.data.scenes['Hangul Sori | Full Ildu Estate'];bpy.context.window.scene=S
def bounds(objects):
 p=[o.matrix_world@Vector(c) for o in objects for c in o.bound_box]
 return [[min(v[i] for v in p) for i in range(3)],[max(v[i] for v in p) for i in range(3)]] if p else None
res={'sceneObjects':len(S.objects),'sceneVisibleMeshes':sum(o.type=='MESH' and not o.hide_render for o in S.objects),'groups':{}}
for g in M['groups']:
 names=g['sourceObjects'];obs=[bpy.data.objects[n] for n in names if n in bpy.data.objects]
 res['groups'][g['nativeOwner']]={'count':len(obs),'missing':len(names)-len(obs),'bounds':bounds(obs),'examples':[{'name':o.name,'location':list(o.matrix_world.translation),'matrix':[list(v) for v in o.matrix_world]} for o in obs if any(x in o.name.lower() for x in ['column','post','pillar'])][:4]}
for gate in ['left','right','shrine']:
 with bpy.data.libraries.load(str(R/(gate+'-new.blend')),link=False) as (a,b):
  b.objects=[n for n in a.objects if n.startswith(gate+'.')]
 obs=[o for o in b.objects if o and o.type=='MESH'];res[gate]={'count':len(obs),'bounds':bounds(obs),'posts':[{'name':o.name,'location':list(o.matrix_world.translation)} for o in obs if 'column' in o.name or 'post' in o.name][:15]}
 for o in b.objects:
  if o:bpy.data.objects.remove(o,do_unlink=True)
out=Path(__file__).with_name('source-inspection.json');out.write_text(json.dumps(res,ensure_ascii=False,indent=2),encoding='utf-8')
print('INSPECTION',json.dumps(res,ensure_ascii=False),flush=True)

