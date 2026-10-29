"""Bible-driven native materials and light; canonical geometry is immutable."""
import bpy, sys, json, hashlib, math, time, struct, copy
from pathlib import Path
from collections import Counter
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
import numpy as np
OUT=Path(__file__).resolve().parent; DESIGN=OUT.parent; R6=DESIGN.parent; CAN=R6.parent; ROOT=CAN.parent
sys.path.insert(0,str(R6/'building-craft-application-r1'))
import apply_craft as craft
s,r2,ext=craft.s,craft.r2,craft.ext
def read(p):return json.loads(Path(p).read_text(encoding='utf-8'))
def write(p,d):Path(p).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def sha(p):
 with open(p,'rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def log(key,event,**kw):
 d=dict(key=key,event=event,**kw);print(json.dumps(d,ensure_ascii=False),flush=True);write(OUT/'PROGRESS.json',d)
def architecture(obs):
 state=dict(geometry=s.geometry_state(obs),attributes=r2.attributes(obs),properties=ext.object_properties(obs))
 h=hashlib.sha256();nh=hashlib.sha256()
 for o in sorted(obs,key=lambda x:x.name):
  a=np.empty(len(o.data.corner_normals)*3,dtype=np.float32);o.data.corner_normals.foreach_get('vector',a);nh.update(o.name.encode());nh.update(a.tobytes())
  b=np.empty(len(o.data.polygons),dtype=np.bool_);o.data.polygons.foreach_get('use_smooth',b);nh.update(b.tobytes())
 h.update(json.dumps(state,sort_keys=True,ensure_ascii=False).encode())
 return dict(stateSha256=h.hexdigest(),normalsSha256=nh.hexdigest(),meshCount=len(obs))
def live(t):
 todo=[n for n in t.nodes if n.type=='OUTPUT_MATERIAL' and n.is_active_output];seen=set()
 while todo:
  n=todo.pop()
  if n in seen:continue
  seen.add(n);todo.extend(l.from_node for sock in n.inputs for l in sock.links)
 return seen
def value(sock):return sock.links[0].from_socket if sock.is_linked else sock.default_value
def mul(t,col,v,label):return r2.mix(t,col,tuple(v)+(1,),1,label,'MULTIPLY')
def rough(t,bs,lo,hi,fac):
 v=ext.scalar(t,'MULTIPLY',value(bs.inputs['Roughness']),fac)
 t.links.new(ext.scalar(t,'MINIMUM',ext.scalar(t,'MAXIMUM',v,lo),hi),bs.inputs['Roughness'])
def style_material(old,role,use):
 m=old.copy();m.name='HS2 '+role+' | '+old.name
 m['hangulsori_style']='Bible 1.1 / production r2';m['hs2_role']=role;m['hs2_source']=old.name
 t=m.node_tree
 for n in live(t):
  if n.type=='BUMP':n.inputs['Strength'].default_value*= {'tile':.06,'wood':.40,'lattice':.3,'stone':.45,'plaster':.3,'paper':.4}.get(role,1)
 for bs in [n for n in live(t) if n.type=='BSDF_PRINCIPLED']:
  col=value(bs.inputs['Base Color'])
  if role in ('wood','lattice','endgrain'):
   col=mul(t,col,(1.05,.70,.36),'HS2 amber timber through original grain')
   rough(t,bs,.34 if use in ('floor-plank','hand-contact','oiled-joinery-D047') else .43,.62,.70)
   bs.inputs['Specular IOR Level'].default_value=.34
  elif role=='tile':
   col=mul(t,col,(.44,.53,.69),'HS2 cool charcoal ceramic original firing variation')
   col=r2.mix(t,col,(.028,.040,.060,1),.52,'HS2 quiet ceramic body under original firing colour')
   rough(t,bs,.64,.78,.86);bs.inputs['Specular IOR Level'].default_value=.22
  elif role=='tile-end':
   col=r2.mix(t,col,(.72,.665,.535,1),.88,'HS2 existing clay end faces warm lime finish')
   rough(t,bs,.78,.91,.98);bs.inputs['Specular IOR Level'].default_value=.2
  elif role=='stone':
   col=mul(t,col,(1.35,1.23,1.04),'HS2 warm mineral body with original facets')
   rough(t,bs,.73,.91,.97);bs.inputs['Specular IOR Level'].default_value=.24
  elif role=='paper':
   col=mul(t,col,(1.03,.86,.58),'HS2 warm ivory paper with original fibre')
   if use=='window-paper':
    ao=r2.node(t,'ShaderNodeAmbientOcclusion','HS2 real lattice proximity, warm paper depth');ao.inputs['Distance'].default_value=.12;ao.samples=8
    glow=r2.ramp(t,ao.outputs['AO'],[(0,(.55,.12,.015,1)),(.4,(1,.46,.09,1)),(.85,(1,.84,.52,1))],'HS2 warm light through actual lattice')
    t.links.new(glow,bs.inputs['Emission Color']);bs.inputs['Emission Strength'].default_value=1.1
   else:bs.inputs['Emission Strength'].default_value=0
   rough(t,bs,.83,.95,1)
  elif role=='plaster':
   col=mul(t,col,(1.03,1.00,.94),'HS2 neutral ivory fibre and lime')
   rough(t,bs,.83,.95,1)
  elif role=='earth':
   col=mul(t,col,(1.13,1.06,.94),'HS2 restrained ochre clay')
  elif role=='metal':
   rough(t,bs,.32,.65,.9)
  t.links.new(col,bs.inputs['Base Color'])
 return m
def material_rows(row,obs):
 src=ROOT/row['native']['path'];p=src.parent/'material-inventory.json'
 arr=read(p) if p.exists() else []
 lookup={(r.get('object'),r.get('slot')):r for r in arr if 'object' in r and 'slot' in r}
 result=[]
 for ob in obs:
  counts=Counter(p.material_index for p in ob.data.polygons)
  for i,slot in enumerate(ob.material_slots):
   if not counts[i]:continue
   m=slot.material;r=lookup.get((ob.name,i),{})
   role=r.get('role') or m.get('craft_role') or m.get('r6_role') or m.get('r5_role')
   if not role:role=ext.category(dict(name=m.name,images=[dict(image=n.image.name if n.image else '') for n in m.node_tree.nodes if n.type=='TEX_IMAGE']),ob.name)
   preserve=craft.b.plaque(ob) or role in ('paint','pigment','preserve','backing')
   if role=='tile' and 'round tile ends' in ob.name.lower():role='tile-end'
   use=craft.usage(row['key'],ob,role)
   if role=='paper':use='window-paper' if ob.dimensions.z>.3 and min(ob.dimensions.x,ob.dimensions.y)<ob.dimensions.z*.2 else 'paper-floor'
   result.append(dict(object=ob.name,slot=i,faces=counts[i],role=role,usage=use,preserved=preserve))
 return result
def point(o,target):o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler()
def bounds(obs):
 pts=[o.matrix_world@Vector(c) for o in obs for c in o.bound_box]
 return pts,Vector([min(p[i] for p in pts) for i in range(3)]),Vector([max(p[i] for p in pts) for i in range(3)])
def rig(scene,obs):
 pts,lo,hi=bounds(obs);center=(lo+hi)/2;span=max(hi.x-lo.x,hi.y-lo.y)
 for ob in list(scene.objects):
  if ob.type=='LIGHT':bpy.data.objects.remove(ob,do_unlink=True)
 world=bpy.data.worlds.new('HS2 cool open sky');world.use_nodes=True;scene.world=world
 bg=world.node_tree.nodes['Background'];bg.inputs['Color'].default_value=(.63,.72,.86,1);bg.inputs['Strength'].default_value=.55
 def light(name,typ,loc,power,size,col,target):
  d=bpy.data.lights.new(name,typ);d.energy=power;d.color=col
  if typ=='AREA':d.shape='DISK';d.size=size
  if typ=='SUN':d.angle=.25
  o=bpy.data.objects.new(name,d);scene.collection.objects.link(o);o.location=loc;point(o,target);return o
 light('HS2 broad warm sun','SUN',center+Vector((-10,-12,20)),3.2,0,(1,.91,.79),center)
 light('HS2 low soft courtyard bounce','AREA',center+Vector((span*.25,-span*.7,span*.35)),span**2*9.0,span*.7,(1,.90,.79),Vector((center.x,center.y,lo.z+.65)))
 light('HS2 cool roof rim','AREA',center+Vector((span*.3,span*.45,span*.6)),span**2*5,span*.65,(.65,.78,1),center)
 bpy.ops.mesh.primitive_plane_add(size=600,location=(center.x,center.y,lo.z-.025))
 floor=bpy.context.object;floor.name='HS2 display ground (non-canonical)';floor['displayOnly']=True
 mat=bpy.data.materials.new('HS2 warm parchment ground');mat.use_nodes=True
 bs=mat.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(.83,.78,.70,1);bs.inputs['Roughness'].default_value=.92
 bs.inputs['Emission Color'].default_value=(.85,.77,.64,1);bs.inputs['Emission Strength'].default_value=.23
 floor.data.materials.append(mat)
 scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=48;scene.cycles.use_denoising=True;scene.cycles.seed=217
 scene.cycles.max_bounces=6;scene.cycles.diffuse_bounces=4;scene.cycles.glossy_bounces=3;scene.cycles.transparent_max_bounces=8
 scene.render.threads_mode='FIXED';scene.render.threads=10;scene.render.use_persistent_data=True;scene.render.use_freestyle=False
 scene.render.film_transparent=False;scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGB'
 scene.view_settings.view_transform='AgX';scene.view_settings.look='AgX - Medium High Contrast';scene.view_settings.exposure=.35
 return floor
def fit_camera(scene,obs,res=(1800,1200),direction=None,margin=.065):
 pts,lo,hi=bounds(obs);center=(lo+hi)/2
 if direction is None:direction=Vector((.57,-.76,.34)).normalized()
 cam=scene.camera
 if cam is None:
  data=bpy.data.cameras.new('HS2 full building camera');cam=bpy.data.objects.new(data.name,data);scene.collection.objects.link(cam);scene.camera=cam
 cam.data.type='ORTHO';cam.data.sensor_fit='HORIZONTAL';cam.data.dof.use_dof=False;cam.data.clip_end=1000
 cam.location=center+direction*100;point(cam,center);bpy.context.view_layer.update()
 inv=cam.matrix_world.inverted();mins=[];maxs=[]
 for ob in obs:
  # Empty canonical mesh objects remain in the lock and process binding, but
  # contribute no points to the camera framing calculation.
  if not ob.data.vertices:continue
  coords=np.empty(len(ob.data.vertices)*3,dtype=np.float32);ob.data.vertices.foreach_get('co',coords);coords=coords.reshape(-1,3)
  mat=np.array(inv@ob.matrix_world);local=coords@mat[:3,:3].T+mat[:3,3];mins.append(local.min(axis=0));maxs.append(local.max(axis=0))
 lows=np.min(mins,axis=0);highs=np.max(maxs,axis=0);xmin,xmax=float(lows[0]),float(highs[0]);ymin,ymax=float(lows[1]),float(highs[1])
 cam.location+=cam.rotation_euler.to_matrix()@Vector(((xmin+xmax)/2,(ymin+ymax)/2,0))
 aspect=res[0]/res[1];cam.data.ortho_scale=max(xmax-xmin,(ymax-ymin)*aspect)/(1-2*margin)
 scene.render.resolution_x,scene.render.resolution_y=res;scene.render.resolution_percentage=100;bpy.context.view_layer.update()
 sx=cam.data.ortho_scale;sy=sx/aspect;box=[.5-(xmax-xmin)/2/sx,.5-(ymax-ymin)/2/sy,.5+(xmax-xmin)/2/sx,.5+(ymax-ymin)/2/sy]
 assert box[0]>=margin-.001 and box[1]>=margin-.001 and box[2]<=1-margin+.001 and box[3]<=1-margin+.001,box
 return dict(position=list(cam.location),rotation=list(cam.rotation_euler),ortho=cam.data.ortho_scale,resolution=list(res),architectureNdcBounds=box,minimumMargin=margin)
def render(scene,dest,name,samples=None):
 if samples:scene.cycles.samples=samples
 scene.render.filepath=str(dest/name);start=time.monotonic();bpy.ops.render.render(write_still=True)
 return dict(file=name,sha256=sha(dest/name),seconds=round(time.monotonic()-start,2),samples=scene.cycles.samples,resolution=[scene.render.resolution_x,scene.render.resolution_y])
def stage_map(key,obs):
 f=(CAN/'models'/f'{key}.glb').open('rb');f.read(12);n,typ=struct.unpack('<II',f.read(8));j=json.loads(f.read(n));f.close()
 mapping={n['extras']['sourceObject']:n['extras'] for n in j['nodes'] if 'reviewStage' in n.get('extras',{})}
 for ob in obs:
  if ob.name not in mapping:
   assert ob.get('reviewStage') is not None,(key,ob.name)
   mapping[ob.name]=dict(sourceObject=ob.name,reviewStage=ob['reviewStage'],processId=ob.get('processId'),assignmentStatus='native_explicit')
 assert set(mapping)=={o.name for o in obs}
 return mapping
def build(key,preview=False):
 row=next(x for x in read(ROOT/'canonical-11-20261023/CANONICAL_MANIFEST.json')['buildings'] if x['key']==key)
 dest=OUT/key;dest.mkdir(exist_ok=True);src=ROOT/row['native']['path'];assert sha(src)==row['native']['sha256']
 log(key,'open canonical source');bpy.ops.wm.open_mainfile(filepath=str(src));scene=bpy.context.scene;obs=[o for o in scene.objects if o.type=='MESH'];names=[o.name for o in obs]
 before=architecture(obs);rows=material_rows(row,obs);mapping=stage_map(key,obs)
 cache={};protected={}
 for r in rows:
  ob=scene.objects[r['object']];sl=ob.material_slots[r['slot']];old=sl.material
  if r['preserved']:protected[(ob.name,r['slot'])]=s.material_state(old);continue
  ck=(old.name,r['role'],r['usage'])
  if ck not in cache:cache[ck]=style_material(old,r['role'],r['usage'])
  sl.link='OBJECT';sl.material=cache[ck];r['material']=sl.material.name
 assert architecture(obs)==before
 floor=rig(scene,obs)
 reference_view=next(r['views']['hero'] for r in read(DESIGN/'hangulsori-buildings-r1/SOURCE_LOCK.json') if r['key']==key)
 direction=Vector(reference_view['position'])-Vector(reference_view['target']);direction.z=0;direction.normalize();direction.z=.358
 camera=fit_camera(scene,obs,(1000,667) if preview else (1800,1200),direction.normalized())
 write(dest/'geometry-lock.json',dict(source=row['native'],**before,objects=names));write(dest/'material-inventory.json',rows);write(dest/'construction-binding.json',mapping)
 native=dest/(key+'-hangulsori-r2-refined.blend')
 if not preview:
  assert not native.exists(),'Production native already exists'
  bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False)
  bpy.ops.wm.open_mainfile(filepath=str(native));scene=bpy.context.scene;obs=[scene.objects[n] for n in names]
  assert architecture(obs)==before
  assert protected=={(n,i):s.material_state(scene.objects[n].material_slots[i].material) for n,i in protected}
  write(dest/'verification.json',dict(passed=True,reopened=True,native=native.name,nativeSha256=sha(native),source=row['native'],geometry=before,bibleSha256=sha(DESIGN/'ART_DIRECTION_BIBLE.md'),protectedPaintAndLetteringUnchanged=True,camera=camera,userApproved=False,runtimeIntegrated=False))
 log(key,'render complete building')
 result=render(scene,dest,'preview.png' if preview else 'complete.png',20 if preview else 64)
 write(dest/'render-manifest.json',dict(complete=True,camera=camera,renders=[result],geometryPreserved=True))
 assert sha(src)==row['native']['sha256'];log(key,'preview rendered' if preview else 'building complete',render=result)
def construction(key):
 dest=OUT/key;v=read(dest/'verification.json');native=dest/v['native'];assert sha(native)==v['nativeSha256']
 bpy.ops.wm.open_mainfile(filepath=str(native));scene=bpy.context.scene;lock=read(dest/'geometry-lock.json');obs=[scene.objects[n] for n in lock['objects']]
 original=architecture(obs);assert original==v['geometry'];mapping=read(dest/'construction-binding.json')
 steps=next(b['steps'] for b in read(CAN/'catalog.json')['buildings'] if b['key']==key)
 original_hidden={o.name:o.hide_render for o in obs};dest_stage=dest/'construction';dest_stage.mkdir(exist_ok=True)
 scene.render.resolution_x=1200;scene.render.resolution_y=800;scene.cycles.samples=24
 manifest=dict(key=key,complete=False,nativeSha256=v['nativeSha256'],sameCameraAsComplete=True,materialsUnchanged=True,stages=[],policy='Existing source stage assignments, cumulative visible members; no new geometry invented for empty stages.')
 cache={}
 for st in steps:
  n=st['sequence'];visible=[o.name for o in obs if mapping[o.name]['reviewStage']<=n and not original_hidden[o.name]]
  sig=hashlib.sha256('\n'.join(sorted(visible)).encode()).hexdigest()
  for o in obs:o.hide_render=o.name not in visible
  bpy.context.view_layer.update()
  row=dict(id=st['id'],sequence=n,label=st['label'],description=st.get('description',''),newMembers=sum(mapping[o.name]['reviewStage']==n for o in obs),visibleMembers=len(visible),visibleSetSha256=sig,isFinal=st['isFinal'])
  if st['isFinal']:
   assert len(visible)==sum(not v for v in original_hidden.values())
   row.update(file='complete.png',sha256=sha(dest/'complete.png'),reuse='complete render')
  elif sig in cache:row.update(cache[sig],reuse='same source geometry state')
  else:
   log(key,'render construction',sequence=n,label=st['label'],visible=len(visible))
   result=render(scene,dest_stage,f'{n:02d}.png',24);result['file']='construction/'+result['file'];row.update(result);cache[sig]=result
  manifest['stages'].append(row);write(dest/'construction.json',manifest)
 for o in obs:o.hide_render=original_hidden[o.name]
 assert architecture(obs)==original;assert sha(native)==v['nativeSha256']
 manifest['complete']=True;manifest['geometryStateRestored']=True;write(dest/'construction.json',manifest);log(key,'construction complete',stageCount=len(steps))
if __name__=='__main__':
 args=sys.argv[sys.argv.index('--')+1:]
 if '--construction' in args:construction(args[0])
 else:build(args[0],'--preview' in args)
