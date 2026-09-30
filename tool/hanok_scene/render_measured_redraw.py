from pathlib import Path
import bpy,sys,json,math,hashlib,argparse
from mathutils import Vector,Matrix
sys.path.insert(0,str(Path(__file__).parent))
from northern_courtyard_photo_repair import OUT
p=argparse.ArgumentParser();p.add_argument('--quick',action='store_true');p.add_argument('--views',default='jar-gate,sadangmun,anchae,ansarang,sadang,anchae-corner,anchae-kitchen,anchae-hall,sadang-joinery');a=p.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
bpy.ops.wm.open_mainfile(filepath=str(OUT/'detail-redraw.blend'));s=bpy.context.scene
c=json.loads((OUT/'detail-redraw-contract.json').read_text(encoding='utf8'));south=json.loads((OUT.parent/'side-connections/connection-contract.json').read_text(encoding='utf8'))
rs={r['id']:r for r in c['buildings']};ar=south['buildings']['ansarang'];rs['ansarang']={**ar,'datum':0};rs['jar-gate']={**c['rearYardGate'],'datum':1.5}
for r in south['gates']:rs[r['id']]={**r,'angle':r.get('orientationRadians',0),'datum':0}
rs['main_gate']={**south['buildings']['main_gate'],'datum':0}
rs['jung']={'center':[0,14.175],'angle':-math.pi/2,'datum':0}
views={
'left-gate-front':('left_changgo',(0,-8,2.40),(0,0,2.40),5.8),
'left-gate-side':('left_changgo',(-8,0,2.45),(0,0,2.45),5.5),
'left-gate-eaves':('left_changgo',(-2.7,-4.2,2.65),(0,0,3.17),4.4),
'right-gate-eaves':('right_ansarang',(2.8,-4.8,2.45),(0,0,2.94),3.6),
'jung-passage':('jung',(.45,-4.8,2.6),(0,1.2,2.85),4.7),
'main-gate-eaves':('main_gate',(-3.4,-6.5,2.35),(0,0,2.65),7.0),
'main-gate-inside':('main_gate',(5.5,10,4.5),(0,0,2),13.2),
'sadang-eaves':('sadang',(3.3,-6,1.8),(0,-1.1,2.6),7.1),
'jar-gate':('jar-gate',(2.8,-4.7,2.6),(0,0,1.23),4.2),
'jar-gate-front':('jar-gate',(0,-5,1.27),(0,0,1.27),3.65),
'jar-gate-back':('jar-gate',(-2.8,4.7,2.5),(0,0,1.23),4.2),
'jar-gate-context':('jar-gate',(2.2,-5.7,1.6),(0,0,1.2),5.2),
'sadangmun':('sadangmun',(3.1,-5.7,2.6),(0,0,1.45),4.9),
'sadangmun-front':('sadangmun',(.3,-6,1.75),(0,0,1.48),4.8),
'sadangmun-hardware':('sadangmun',(.9,-3.2,1.42),(0,0,1.12),1.75),
'sadangmun-context':('sadangmun',(-1.2,-5.2,1.80),(0,.15,1.48),6.6),
'anchae':('anchae',(8,-25,7.5),(0,0,1.85),24.5),
'ansarang':('ansarang',(7,-15,6.5),(0,0,2.45),17.1),
'ansarang-left':('ansarang',(-10,-12,5.0),(0,0,2.05),18.3),
'ansarang-kitchen':('ansarang',(-8.8,1.85,1.72),(-4.12,.38,1.33),4.6),
'sadang':('sadang',(6,-14,5.0),(0,-.1,2.55),11.0),
'sadang-front':('sadang',(0,-16,2.70),(0,0,2.70),10.1),
'sadang-right':('sadang',(16,0,2.70),(0,0,2.70),9.7),
'anchae-corner':('anchae',(12.4,-6.2,2.7),(7.1,-.35,1.50),7.1),
'anchae-kitchen':('anchae',(-6.335,-2.85,1.35),(-6.335,.60,.72),3.1),
'anchae-hall':('anchae',(1.15,-4.8,2.2),(2.1,.2,1.5),4.0),
'sadang-joinery':('sadang',(4.9,-5.5,2.60),(1.15,-1.10,1.72),5.2),
'sadang-porch':('sadang',(3.08,-2.13,1.72),(-2.4,-1.42,2.07),4.2),
'sadang-interior':('sadang',(-.03,-2.0,1.90),(0,.8,1.30),3.9),
}
s.render.engine='CYCLES';s.cycles.samples=12 if a.quick else 24;s.cycles.use_denoising=True
try:
 cp=bpy.context.preferences.addons['cycles'].preferences;cp.compute_device_type='OPTIX';cp.get_devices()
 gpu=[d for d in cp.devices if d.type=='OPTIX']
 if gpu:
  for d in cp.devices:d.use=d in gpu
  s.cycles.device='GPU'
except Exception:pass
s.render.resolution_x=1050 if a.quick else 1440;s.render.resolution_y=760 if a.quick else 1040;s.render.resolution_percentage=100;s.render.film_transparent=False
s.render.image_settings.file_format='PNG';s.view_settings.view_transform='AgX';s.view_settings.exposure=-.30
for ob in s.objects:
 if ob.type=='LIGHT':ob.hide_render=True
s.world.use_nodes=True;s.world.node_tree.nodes.get('Background').inputs['Color'].default_value=(.72,.78,.86,1);s.world.node_tree.nodes.get('Background').inputs['Strength'].default_value=.32
data=bpy.data.cameras.new('Detail redraw review');cam=bpy.data.objects.new('Detail redraw review',data);s.collection.objects.link(cam);s.camera=cam
def lamp(name,energy,size):
 d=bpy.data.lights.new(name,'AREA');d.energy=energy;d.shape='DISK';d.size=size;o=bpy.data.objects.new(name,d);s.collection.objects.link(o);return o
key=lamp('Broad daylight',950,7);fill=lamp('Courtyard sky fill',230,6)
basem={o.name:o.matrix_world.copy() for o in s.objects if o.type=='MESH'};basehidden={o.name:o.hide_render for o in s.objects if o.type=='MESH'}
all_doors=c['doors']+south['doors'];records=[]
for view in a.views.split(','):
 ident,eye,target,scale=views[view];r=rs[ident];rot=Matrix.Rotation(r['angle'],3,'Z');origin=Vector((*r['center'],r['datum']));world=lambda p:origin+rot@Vector(p)
 s.view_settings.exposure=.35 if ident=='anchae' else -.30
 for n,m in basem.items():bpy.data.objects[n].matrix_world=m.copy()
 for door in all_doors:
  pre=door['prefix'];allowed=(ident=='jar-gate' and 'rear yard gate.plank door' in pre) or (ident=='sadangmun' and door['building']=='sadangmun') or (ident=='ansarang' and door.get('id')=='ansarang_front3') or (ident=='anchae' and (pre=='North.anchae.kitchen' if view=='anchae-kitchen' else 'daechong rear door' in pre or 'hall room ' in pre))
  allowed=allowed or (ident=='sadang' and door.get('id')=='sadang_center' and view in ('sadang-porch','sadang-interior'))
  allowed=allowed or (ident in ('left_changgo','right_ansarang','main_gate','jung') and door.get('building')==ident and view!='left-gate-front')
  if not allowed or view in ('jar-gate-front','sadangmun-front','sadangmun-hardware','sadangmun-context'):continue
  for i,h in enumerate(door['hinges']):
   theta=math.radians(76 if ident not in ('jar-gate','sadangmun') else (40 if i==0 else 73))*door['rotationSigns'][i]
   hinge=Vector(h);m=Matrix.Translation(hinge)@Matrix.Rotation(theta,4,'Z')@Matrix.Translation(-hinge)
   leaves=door.get('leafGroups',[[j+1] for j in range(len(door['hinges']))])[i]
   for n,base in basem.items():
    if any(n.startswith(pre+f'.leaf{leaf}.') for leaf in leaves):bpy.data.objects[n].matrix_world=m@base
   for f in door.get('folds',[]):
    if f['group']==i:
     fh=Vector(f['hinge']);fold=Matrix.Translation(fh)@Matrix.Rotation(abs(theta)*f['relativeSign'],4,'Z')@Matrix.Translation(-fh)
     for n,base in basem.items():
      if n.startswith(pre+f'.leaf{f["leaf"]}.'):bpy.data.objects[n].matrix_world=m@fold@base
 for ob in s.objects:
  if ob.type!='MESH':continue
  keep=ob.get('construction_building')==ident
  if ident=='jung':keep=keep or 'jung' in ob.name.lower()
  if ident=='jar-gate':keep=ob.name.startswith('North.site.rear yard gate')
  if view=='jar-gate-context':keep=ob.get('construction_building')=='north_site'
  if view=='sadangmun-context':keep=ob.get('construction_building') in ('sadangmun','sadang','north_site','gokgan')
  if view=='sadang-interior' and ob.name.startswith('North.sadang.survey sanctuary '):keep=False
  if ob.name.startswith('ConnectionSite.continuous earth'):keep=True
  ob.hide_render=basehidden[ob.name] or not keep
 data.type='PERSP' if view in ('jung-passage','anchae-kitchen','anchae-hall','sadang-porch','sadang-interior','ansarang-kitchen','sadangmun-context') else 'ORTHO';data.lens=22 if view=='sadang-interior' else 24 if view in ('anchae-kitchen','ansarang-kitchen','sadang-porch') else 28;data.ortho_scale=scale;data.clip_start=.025
 cam.location=world(eye);cam.rotation_euler=(world(target)-cam.location).to_track_quat('-Z','Y').to_euler()
 key.location=world((-4,-6,8));key.rotation_euler=(world((0,0,1.3))-key.location).to_track_quat('-Z','Y').to_euler()
 fill.location=world((5,-1,5));fill.rotation_euler=(world((0,0,1.3))-fill.location).to_track_quat('-Z','Y').to_euler()
 if view in ('anchae-kitchen','anchae-hall','sadang-porch','sadang-interior','ansarang-kitchen'):
  s.view_settings.exposure=.35
  key.location=world((eye[0],eye[1]-.3,2.2));key.data.energy=260;key.data.size=2.5;key.rotation_euler=(world(target)-key.location).to_track_quat('-Z','Y').to_euler()
  if view in ('sadang-interior','sadang-porch','ansarang-kitchen'):key.data.energy=100;s.view_settings.exposure=0
 else:key.data.energy=950;key.data.size=7
 bpy.context.view_layer.update();path=OUT/(view+'-redraw'+('-preview' if a.quick else '')+'.png');s.render.filepath=str(path);bpy.ops.render.render(write_still=True)
 records.append({'view':view,'file':path.name,'sourceSceneSha256':hashlib.sha256((OUT/'detail-redraw.blend').read_bytes()).hexdigest(),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'openedForInspection':True})
 previous=json.loads((OUT/'redraw-renders.json').read_text()) if (OUT/'redraw-renders.json').exists() else []
 known={v['file']:v for v in previous};known[path.name]=records[-1];(OUT/'redraw-renders.json').write_text(json.dumps(list(known.values()),indent=2))
 print('REDRAW RENDERED',view,flush=True)
