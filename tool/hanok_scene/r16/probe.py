import bpy, json, sys, hashlib
from pathlib import Path
from collections import Counter
OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[3]
MANIFEST=ROOT/'canonical-11-20261023/CANONICAL_MANIFEST.json'
m=json.loads(MANIFEST.read_text(encoding='utf-8'))
src=ROOT/m['buildings'][0]['native']['path']
bpy.ops.wm.open_mainfile(filepath=str(src))
s=bpy.context.scene
obs=[o for o in s.objects if o.type=='MESH']
def val(v):
 try:return v.to_list()
 except:pass
 try:return v.to_dict()
 except:pass
 return str(v) if not isinstance(v,(str,int,float,bool,list,dict)) else v
data={'root':str(ROOT),'source':str(src),'objectCount':len(obs),'objects':[{'name':o.name,'props':{k:val(o[k]) for k in o.keys()},'bounds':list(o.dimensions),'location':list(o.location),'rotation':list(o.rotation_euler)} for o in obs[:15]],'stages':dict(Counter(str(o.get('reviewStage')) for o in obs)),'propertyKeys':dict(Counter(k for o in obs for k in o.keys())),'lights':[{'name':o.name,'type':o.data.type,'energy':o.data.energy,'color':list(o.data.color),'location':list(o.location),'size':getattr(o.data,'size',0)} for o in s.objects if o.type=='LIGHT'],'world':{'name':s.world.name,'nodes':[(n.type,n.name) for n in s.world.node_tree.nodes]},'materials':[]}
seen=set()
for ob in obs:
 for slot in ob.material_slots:
  mat=slot.material
  if not mat or mat.name in seen:continue
  seen.add(mat.name)
  role=mat.get('craft_role',mat.get('r6_role',''))
  if any(x['role']==role for x in data['materials']):continue
  data['materials'].append({'name':mat.name,'role':role,'props':{k:val(mat[k]) for k in mat.keys()},'nodes':[{'name':n.name,'label':n.label,'type':n.type,'operation':getattr(n,'operation',None),'inputs':{sock.name:(('link:'+sock.links[0].from_node.label+':'+sock.links[0].from_socket.name) if sock.is_linked else val(getattr(sock,'default_value',None))) for sock in n.inputs}} for n in mat.node_tree.nodes if n.type in ('BSDF_PRINCIPLED','BUMP','TEX_IMAGE','MIX_RGB')]})
pref=bpy.context.preferences.addons['cycles'].preferences
data['gpu']={}
for backend in ['OPTIX','CUDA','HIP']:
 try:
  pref.compute_device_type=backend;pref.get_devices();data['gpu'][backend]=[(d.name,d.type) for d in pref.devices]
 except Exception as e:data['gpu'][backend]=str(e)
(OUT/'probe.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
print('PROBE',len(obs),data['stages'],data['gpu'],flush=True)
