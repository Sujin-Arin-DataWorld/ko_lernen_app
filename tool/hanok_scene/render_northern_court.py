from pathlib import Path
import bpy,json,math,sys,argparse,hashlib
from mathutils import Vector,Matrix
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
p=argparse.ArgumentParser();p.add_argument('--views',default='north,anchae,arae,angotgan,gokgan,sadang,sadangmun,jars,plan');p.add_argument('--quick',action='store_true');p.add_argument('--scene',default='scene.blend');p.add_argument('--contract',default='northern-contract.json');p.add_argument('--suffix',default='');args=p.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
bpy.ops.wm.open_mainfile(filepath=str(OUT/args.scene));s=bpy.context.scene;bpy.context.view_layer.update()
contract=json.loads((OUT/args.contract).read_text(encoding='utf8'));sourcehash=hashlib.sha256((OUT/args.scene).read_bytes()).hexdigest()
s.render.engine='CYCLES';s.cycles.samples=12 if args.quick else 28;s.cycles.use_denoising=True;s.render.resolution_x=960 if args.quick else 1440;s.render.resolution_y=640 if args.quick else 960;s.render.resolution_percentage=100
s.render.film_transparent=False;s.render.image_settings.file_format='PNG'
data=bpy.data.cameras.new('Northern review');data.type='ORTHO';cam=bpy.data.objects.new('CAM Northern review',data);s.collection.objects.link(cam);s.camera=cam
views={'north':((-24,-9,34),(11,17,2),53),'plan':((10,8,85),(10,8,0),78),'anchae':((-5,6,10),(10.945,20.012,3.1),25),'arae':((11,16,7),(2.855,28.004,3.0),12.5),'angotgan':((9,10,9),(-4.447,21.683,3.2),14),'gokgan':((10,-1,9),(24.909,10.510,3.6),16),'sadang':((12,13,9),(24.311,22.429,4.2),12),'sadangmun':((16,11,4.1),(19.859,16.853,2.9),4.4),'jars':((12,19,12),(15.8,26.8,2.0),12),'route':((18,3.6,3.4),(19,17,3),18),'court':((-1,13,8),(5,23,2.5),30)}
views['sadangmun']=((16,11,4.7),(19.859,16.853,2.9),6.0)
views['anchae-detail']=((1.5,12,5.0),(10.945,17.7,3.7),10.2)
views['anchae-veranda']=((18.6,27.5,4.6),(13.15,24.0,2.7),10.7)
views['anchae-access']=((16.9,25.8,3.15),(12.55,22.5,2.80),6.0)
views['anchae-hall']=((10.095,16.612,3.40),(11.191,19.9245,3.05),3.0)
views['anchae-hall-open']=views['anchae-hall']
views['sadang-detail']=((15.0,19.5,4.4),(24.311,22.429,4.0),9.6)
views['sadang-brackets']=((19.6,22.6,4.2),(22.211,23.659,4.72),3.1)
views['rear-gates']=((18.8,8.7,3.8),(18.8,16.7,2.7),8.0)
views['flower-wall']=((20.8,15.2,3.5),(24,16.7,2.35),5.7)
views['anchae-corner']=((5.5,5.0,4.1),(9.3,10.2,2.6),7.5)
views['anchae-kitchen']=((7.345,26.347,3.05),(11.245,26.347,2.30),4.5)
views['anchae-hearth']=((6.445,13.687,2.65),(8.865,13.687,1.85),3.7)
for key,value in list(views.items()):
 ident=key.split('-')[0];rec=next((r for r in contract['buildings'] if r['id']==ident),None)
 if rec and rec.get('placementTransform'):
  mat=Matrix(rec['placementTransform']);views[key]=(tuple(mat@Vector(value[0])),tuple(mat@Vector(value[1])),value[2])
if contract.get('rearYardGate'):
 gate=contract['rearYardGate'];mat=Matrix.Rotation(gate['angle'],3,'Z');o=Vector((*gate['center'],1.5))
 views['jar-gate']=(tuple(o+mat@Vector((2.8,-4.8,2.8))),tuple(o+mat@Vector((0,0,1.25))),3.55)
rec=next(r for r in contract['buildings'] if r['id']=='anchae');mat=Matrix.Rotation(rec['angle'],3,'Z');o=Vector((*rec['center'],rec['datum']))
cx=-rec['bodyWidth']/2+rec['bays'][0]+rec['bays'][1]/2
views['anchae-kitchen-door']=(tuple(o+mat@Vector((cx+1,-5.8,2.0))),tuple(o+mat@Vector((cx,-2.3,1.7))),3.6)
records=json.loads((OUT/'renders.json').read_text()) if (OUT/'renders.json').exists() else []
basehidden={o.name:o.hide_render for o in s.objects if o.type=='MESH'}
base_matrices={o.name:o.matrix_world.copy() for o in s.objects if o.name.startswith('North.anchae.') and '.leaf' in o.name}
# A broad inspection fill makes the recessed member sides readable. It is
# only a review lamp and is never saved to scene.blend or exported to GLB.
fill_data=bpy.data.lights.new('Interior inspection fill','AREA');fill_data.energy=110;fill_data.shape='DISK';fill_data.size=2.5
fill=bpy.data.objects.new('Interior inspection fill',fill_data);s.collection.objects.link(fill);fill.location=(9.85,17.7,4.0)
fill.rotation_euler=(Vector((11.191,19.9245,3.05))-fill.location).to_track_quat('-Z','Y').to_euler()
for key in args.views.split(','):
 fill.hide_render=not (key.startswith('anchae-hall') or key=='anchae-kitchen')
 if key=='anchae-kitchen':
  fill.location=(9.0,25.3,3.4);fill.rotation_euler=(Vector((11.2,25.6,2.3))-fill.location).to_track_quat('-Z','Y').to_euler()
 for name,matrix in base_matrices.items():bpy.data.objects[name].matrix_world=matrix.copy()
 if key=='anchae-hall-open':
  for door in contract['doors']:
   if not door['prefix'].startswith('North.anchae.hall room '):continue
   hinge=Vector(door['hinges'][0]);m=Matrix.Translation(hinge)@Matrix.Rotation(math.radians(78)*door['rotationSigns'][0],4,'Z')@Matrix.Translation(-hinge)
   for name,matrix in base_matrices.items():
    if name.startswith(door['prefix']+'.'):bpy.data.objects[name].matrix_world=m@matrix
 if key=='anchae-kitchen':
  for door in contract['doors']:
   if door['prefix']!='North.anchae.kitchen':continue
   for i,h in enumerate(door['hinges']):
    hinge=Vector(h);m=Matrix.Translation(hinge)@Matrix.Rotation(math.radians(82)*door['rotationSigns'][i],4,'Z')@Matrix.Translation(-hinge)
    for name,matrix in base_matrices.items():
     if name.startswith(door['prefix']+f'.leaf{i+1}.'):bpy.data.objects[name].matrix_world=m@matrix
 bpy.context.view_layer.update()
 ident=key.split('-')[0]
 if key in views:pos,target,scale=views[key]
 else:
  rec=next(r for r in contract['buildings'] if r['id']==ident);cx,cy=rec['center'];a=rec['angle'];r=max(rec['bodyWidth']*.85,8);f=1 if key.endswith('rear') else -1;target=(cx,cy,rec['datum']+2)
  pos=(cx-f*r*math.sin(a),cy+f*r*math.cos(a),rec['datum']+4.0);scale=max(rec['bodyWidth']+4.2,rec['bodyDepth']+5)
 for o in s.objects:
  if o.type!='MESH':continue
  isolate=ident in [r['id'] for r in contract['buildings']]
  o.hide_render=basehidden[o.name] or (isolate and o.get('construction_building')!=ident and not o.name.startswith('ConnectionSite.'))
  if key=='jar-gate':
   isolate=True;o.hide_render=basehidden[o.name] or not(o.name.startswith('North.site.rear yard gate') or o.name.startswith('ConnectionSite.continuous earth'))
 data.type='PERSP' if key in ('route','rear-gates','flower-wall','anchae-kitchen','anchae-hearth') or key.startswith('anchae-hall') else 'ORTHO';data.lens=38;data.clip_start=.05;data.ortho_scale=scale;cam.location=pos;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler()
 path=OUT/(key+args.suffix+'.png');s.render.filepath=str(path);bpy.ops.render.render(write_still=True)
 records=[r for r in records if r['view']!=key+args.suffix];records.append({'view':key+args.suffix,'camera':pos,'target':target,'scale':scale,'file':path.name,'sourceSceneSha256':sourcehash,'isolated':isolate,'inspectionFill':key.startswith('anchae-hall'),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
 (OUT/'renders.json').write_text(json.dumps(records,indent=2),encoding='utf8');print('RENDERED',key,flush=True)
