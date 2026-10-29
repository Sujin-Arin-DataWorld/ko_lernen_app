"""Sarang-only reference matching. Edits shading/light, never architecture."""
import bpy,sys,math,json,time
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).resolve().parent
sys.path.insert(0,str(OUT))
import produce as p
DEST=OUT/'sarang-r4';DEST.mkdir(exist_ok=True)
def rgb(h):
 c=[int(h[i:i+2],16)/255 for i in (0,2,4)]
 return tuple(v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in c)+(1,)
def setval(t,sock,val):
 for l in list(sock.links):t.links.remove(l)
 sock.default_value=val
def cavity(t,col,role):
 ao=p.r2.node(t,'ShaderNodeAmbientOcclusion','R3 real contact depth');ao.samples=8
 ao.inputs['Distance'].default_value={'wood':.20,'lattice':.07,'stone':.25,'tile':.12,'tile-end':.10}.get(role,.15)
 c=(.56,.44,.34,1) if role in ('wood','lattice') else (.58,.60,.65,1) if role=='tile' else (.63,.58,.51,1)
 mask=p.r2.ramp(t,ao.outputs['AO'],[(.08,c),(.82,(1,1,1,1))],'R3 coloured contact gradient')
 return p.r2.mix(t,col,mask,.30,'R3 contact pigment','MULTIPLY')
def material(old,role,usage):
 m=old.copy();m.name='HS3 '+role+' | '+old.name;m['hs3_reference']='Gemini_Generated_Image_824e6v824e6v824e.jpg'
 t=m.node_tree;active=p.live(t)
 for n in active:
  if n.type=='BUMP':n.inputs['Strength'].default_value*= .18 if role=='stone' else .2 if role=='tile' else .75
 for bs in [n for n in active if n.type=='BSDF_PRINCIPLED']:
  col=p.value(bs.inputs['Base Color'])
  if role in ('wood','lattice','endgrain'):
   col=p.mul(t,col,(1.0,.86,.68),'R3 golden amber pigment through preserved longitudinal grain')
   p.rough(t,bs,.70,.85,1.25);bs.inputs['Specular IOR Level'].default_value=.15
   bs.inputs['Sheen Weight'].default_value=.20;bs.inputs['Sheen Roughness'].default_value=.5;bs.inputs['Sheen Tint'].default_value=rgb('FFCF8B')
  elif role=='tile':
   col=p.mul(t,col,(1.15,1.05,.96),'R3 slate body, less blue and lower value')
   col=p.r2.mix(t,col,rgb('2A3746'),.18,'R3 broad slate mass before small detail')
   setval(t,bs.inputs['Roughness'],.82);bs.inputs['Specular IOR Level'].default_value=.20
   bs.inputs['Sheen Weight'].default_value=.20;bs.inputs['Sheen Roughness'].default_value=.5;bs.inputs['Sheen Tint'].default_value=rgb('B8D4F0')
  elif role=='tile-end':
   col=p.r2.mix(t,col,rgb('E5DEC9'),.75,'R3 warm cream existing ceramic end pieces')
   setval(t,bs.inputs['Roughness'],.92);bs.inputs['Specular IOR Level'].default_value=.05
  elif role=='stone':
   col=p.mul(t,col,(.80,.73,.64),'R3 stone mineral value')
   seed=p.craft.illustration.member_value(t)
   body=p.r2.ramp(t,seed,[(0,rgb('B9AA95')),(.5,rgb('C2B097')),(1,rgb('D9CBB5'))],'R3 existing stone island mineral bodies')
   col=p.r2.mix(t,col,body,.35,'R3 calm broad minerals with original details')
   setval(t,bs.inputs['Roughness'],.90);bs.inputs['Specular IOR Level'].default_value=.10
  elif role=='paper' and usage=='window-paper':
   ao=p.r2.node(t,'ShaderNodeAmbientOcclusion','R3 paper real lattice proximity');ao.samples=16;ao.inputs['Distance'].default_value=.12
   col=p.r2.ramp(t,ao.outputs['AO'],[(.05,rgb('C84312')),(.35,rgb('FF9E22')),(.75,rgb('FFF5C0'))],'R3 SPEC amber to cream transmitted paper')
   t.links.new(col,bs.inputs['Emission Color']);bs.inputs['Emission Strength'].default_value=2.2
   setval(t,bs.inputs['Roughness'],.95)
  if role in ('wood','lattice','stone','tile','tile-end'):col=cavity(t,col,role)
  t.links.new(col,bs.inputs['Base Color'])
  radius={'wood':.01,'lattice':.002,'endgrain':.006,'stone':.025,'tile':.006,'tile-end':.004}.get(role)
  if radius:
   bevel=p.r2.node(t,'ShaderNodeBevel','R3 shading-only edge softness; geometry untouched');bevel.samples=4;bevel.inputs['Radius'].default_value=radius
   if bs.inputs['Normal'].is_linked:t.links.new(bs.inputs['Normal'].links[0].from_socket,bevel.inputs['Normal'])
   t.links.new(bevel.outputs['Normal'],bs.inputs['Normal'])
 return m
def build():
 v=p.read(OUT/'sarang/verification.json');src=OUT/'sarang'/v['native'];assert p.sha(src)==v['nativeSha256']
 bpy.ops.wm.open_mainfile(filepath=str(src));scene=bpy.context.scene;lock=p.read(OUT/'sarang/geometry-lock.json');obs=[scene.objects[n] for n in lock['objects']]
 before=p.architecture(obs);assert before==v['geometry'];rows=p.read(OUT/'sarang/material-inventory.json');cache={};protected={}
 for r in rows:
  ob=scene.objects[r['object']];sl=ob.material_slots[r['slot']]
  if r['preserved']:protected[(ob.name,r['slot'])]=p.s.material_state(sl.material);continue
  # Open/lifted window leaves remain window paper even when horizontal.
  usage='window-paper' if r['role']=='paper' and ('hanji backing' in ob.name.lower() or '.paper' in ob.name.lower()) else r['usage']
  k=(sl.material.name,r['role'],usage)
  if k not in cache:cache[k]=material(sl.material,r['role'],usage)
  sl.link='OBJECT';sl.material=cache[k]
  r['hs3Material']=sl.material.name;r['usage']=usage
 for ob in list(scene.objects):
  if ob.type=='LIGHT':bpy.data.objects.remove(ob,do_unlink=True)
 pts,lo,hi=p.bounds(obs);center=(lo+hi)/2
 world=scene.world;bg=world.node_tree.nodes.get('Background');bg.inputs['Color'].default_value=rgb('E8EEF5');bg.inputs['Strength'].default_value=.75
 def light(name,typ,position,power,color,target,size=1.5):
  d=bpy.data.lights.new(name,typ);d.energy=power;d.color=rgb(color)[:3]
  if typ=='SUN':d.angle=math.radians(14)
  else:d.shape='DISK';d.size=size
  o=bpy.data.objects.new(name,d);scene.collection.objects.link(o);o.location=position;p.point(o,target)
  return dict(name=name,position=list(o.location),target=list(target),power=power,color=color)
 lights=[light('HS3 SPEC warm upper-left key','SUN',center+Vector((-12,-16,20)),3.5,'FFF4E0',center)]
 lights.append(light('HS3 soft material separation fill','AREA',center+Vector((2,-9,5)),900,'FFF4E0',center,8))
 for name,floorname in [('main','Sarang.main two-bay ondol floor'),('numaru','Sarang.wing front room ondol floor')]:
  floor=scene.objects[floorname];_,a,b=p.bounds([floor]);c=(a+b)/2;pos=Vector((c.x,c.y+.25,b.z+1.05))
  lights.append(light('HS3 SPEC '+name+' warm interior bounce','AREA',pos,150,'FF8C1A',Vector((c.x,a.y-2,b.z+.5)),1.5))
  if name=='numaru':
   # A low warm reflected-light contribution at the opening, aimed into the
   # existing veranda; no luminous planes or architectural geometry added.
   lights.append(light('HS3 numaru opening bounce','AREA',Vector((c.x,a.y-.15,b.z+1.2)),65,'FFB34F',Vector((c.x,a.y-2,b.z+.15)),1.0))
 floor=scene.objects['HS2 display ground (non-canonical)'];m=floor.material_slots[0].material.copy();floor.material_slots[0].material=m
 bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=rgb('F3EFEA');bs.inputs['Emission Color'].default_value=rgb('F3E4D2');bs.inputs['Emission Strength'].default_value=.65
 scene.view_settings.view_transform='AgX';scene.view_settings.look='AgX - Medium High Contrast';scene.view_settings.exposure=.2;scene.view_settings.gamma=1
 assert p.architecture(obs)==before
 assert protected=={(n,i):p.s.material_state(scene.objects[n].material_slots[i].material) for n,i in protected}
 native=DEST/(DEST.name+'.blend');assert not native.exists()
 bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False)
 bpy.ops.wm.open_mainfile(filepath=str(native));scene=bpy.context.scene;assert p.architecture([scene.objects[n] for n in lock['objects']])==before
 p.write(DEST/'verification.json',dict(passed=True,reopened=True,native=native.name,nativeSha256=p.sha(native),geometry=before,sourceNative=str(src),sourceSha256=v['nativeSha256'],sameCamera=True,lights=lights,originalGeometryUVNormalsAndProcessBindingUnchanged=True,userApproved=False,runtimeIntegrated=False))
 p.write(DEST/'material-inventory.json',rows)
 scene.render.resolution_x=1200;scene.render.resolution_y=800
 result=p.render(scene,DEST,'preview.png',32);p.write(DEST/'preview.json',result)
 assert p.sha(src)==v['nativeSha256']
 print(DEST.name+' PREVIEW COMPLETE',flush=True)
if __name__=='__main__':build()
