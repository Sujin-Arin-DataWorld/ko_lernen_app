from pathlib import Path
import bpy,json,hashlib,math,sys,argparse
from mathutils import Vector,Matrix
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'assets_unused/pending_review/hwalju-blueprint-review/side-connections'
p=argparse.ArgumentParser();p.add_argument('--views',default='whole,left-front,left-rear,right-front,right-rear,warehouse,plan,gate-detail,ansarang,open-path');p.add_argument('--before',action='store_true');args=p.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
bpy.ops.wm.open_mainfile(filepath=str(OUT/('structure-base.blend' if args.before else 'scene.blend')));s=bpy.context.scene
bpy.context.view_layer.update()
original_matrices={o.name:o.matrix_world.copy() for o in s.objects if o.type=='MESH'}
original_hidden={o.name:o.hide_render for o in s.objects if o.type=='MESH'}
contract=json.loads((OUT/'connection-contract.json').read_text(encoding='utf8'))
# Match the photographs: left leaves open, right one leaf partly open.
for door in contract['doors']:
    if door['building'] not in ('left_changgo','right_ansarang'):continue
    for i,hinge in enumerate(door['hinges']):
        degrees=78 if door['building']=='left_changgo' else (0 if i==0 else 78)
        angle=math.radians(degrees)*door['rotationSigns'][i]
        transform=Matrix.Translation(hinge)@Matrix.Rotation(angle,4,'Z')@Matrix.Translation(-Vector(hinge))
        for o in s.objects:
            if o.name.startswith(door['prefix']+f'.leaf{i+1}.'):o.matrix_world=transform@o.matrix_world
s.render.engine='CYCLES';s.cycles.samples=20;s.cycles.use_denoising=True;s.render.film_transparent=False
s.render.resolution_x=1260;s.render.resolution_y=840;s.render.resolution_percentage=100
data=bpy.data.cameras.new('Side connection review');data.type='ORTHO'
cam=bpy.data.objects.new('CAM.Side connections',data);s.collection.objects.link(cam);s.camera=cam
views={
 'whole':((-30,-43,35),(9,-3,1.5),60),
 'left-front':((-6,-5,4.1),(-3.2,3.8,2.4),10),
 'left-rear':((-5,12,4.4),(-2.1,3.8,2.4),9.5),
 'left-junction':((-3,10,6),(-5,3.8,1.9),9.5),
 'ansarang-enclosure':((6,-30,27),(22,-10,1.3),32),
 'right-front':((17,-11,4.0),(18.092,.083,1.9),8.5),
 'right-rear':((22,11,5),(18.092,.083,1.9),10),
 'warehouse':((12,3.5,9.5),(-8.634,3.105,2.0),17),
 'plan':((10,-4,55),(10,-4,0),62),
 'gate-detail':((18.2,-3,3.2),(18.092,.083,1.9),6.7),
 'ansarang':((11,-18,7),(24,-9.7,2.2),17),
 'open-path':((11.3,-13.5,1.72),(24,-14.2,1.8),12),
 'numaru-wall':((21,-19,8),(12.7,-5.5,1.7),19),
 'wall-corridor':((18,-18,3.5),(18,.1,1.8),20),
 'ansarang-right':((16,-22,3.7),(23.7,-13.9,1.9),9),
 'ansarang-joinery':((17,-14,2.5),(23.3,-13.7,1.85),5.5),
 'estate':((-39,-51,44),(3,-5,1.5),66),
 'estate-plan':((3,0,70),(3,0,0),85),
 'main-gate-front':((-14,-24,7),(-6.5,-13.18,2.35),15.5),
 'main-gate-inner':((0,-2,6.8),(-6.5,-13.18,2.3),16),
 'main-gate-detail':((-8,-19,3.4),(-6.6,-14.4,2.1),5.5),
 'toilet':((-16,-10,3.5),(-18.5,-7,1.5),6),
 'warehouse-end':((-9.6,-9,3.3),(-8.65,-3.535,2.2),8.5),
 'main-gate-photo-front':((-9.9,-39.0,3.3),(-6.5,-13.18,2.25),14),
 'main-gate-photo-inner':((-5.33,-4.26,3.2),(-6.5,-13.18,2.25),14),
 'main-gate-soffit':((-6.95,-16.6,1.65),(-6.45,-12.8,3.4),5.8),
 'warehouse-to-gate':((-31,-19,20),(-13,-7,1.1),28),
 'ansarang-to-gate':((28,-36,26),(6,-15,1.3),47),
}
report=json.loads((OUT/'renders.json').read_text()) if (OUT/'renders.json').exists() else []
for key in args.views.split(','):
    pos,target,scale=views[key]
    # Reset each view independently: the closed gate portrait must not change
    # later views. The initial scene matrices have already been evaluated.
    for o in s.objects:
        if o.type=='MESH' and o.name in original_matrices:o.matrix_world=original_matrices[o.name].copy()
    if key=='gate-detail':
        # Undo photographic leaf opening for the closed-door material portrait.
        for door in contract['doors']:
            if door['building'] not in ('left_changgo','right_ansarang','main_gate'):continue
            for i,hinge in enumerate(door['hinges']):
                degrees=78 if door['building'] in ('left_changgo','main_gate') else (0 if i==0 else 78)
                if door['building']=='main_gate' and key=='main-gate-detail':degrees=0
                # Closed is exactly the saved closed geometry.
                pass
    else:
        for door in contract['doors']:
            if door['building'] not in ('left_changgo','right_ansarang','main_gate'):continue
            for i,hinge in enumerate(door['hinges']):
                degrees=78 if door['building'] in ('left_changgo','main_gate') else (0 if i==0 else 78)
                if door['building']=='main_gate' and key=='main-gate-detail':degrees=0
                angle=math.radians(degrees)*door['rotationSigns'][i];transform=Matrix.Translation(hinge)@Matrix.Rotation(angle,4,'Z')@Matrix.Translation(-Vector(hinge))
                for o in s.objects:
                    if o.name.startswith(door['prefix']+f'.leaf{i+1}.'):o.matrix_world=transform@o.matrix_world
    for o in s.objects:
        if o.type=='MESH':o.hide_render=original_hidden[o.name] or (key=='warehouse' and o.get('construction_building')!='changgo' and not o.name.startswith('ConnectionSite.'))
    if key.startswith('main-gate'):
        for o in s.objects:
            if o.type=='MESH' and o.get('construction_building') not in ('main_gate','forecourt_wall') and not o.name.startswith('ConnectionSite.'):o.hide_render=True
    if key=='warehouse-end':
        for o in s.objects:
            if o.type=='MESH' and o.get('construction_building') in ('main_gate','toilet'):o.hide_render=True
    data.type='PERSP' if key in ('open-path','main-gate-soffit') else 'ORTHO';data.lens=38
    cam.location=pos;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();data.ortho_scale=scale
    path=OUT/(key+('-before' if args.before else '')+'.png');s.render.filepath=str(path);bpy.ops.render.render(write_still=True)
    report=[r for r in report if r['view']!=key]
    report.append({'view':key,'file':path.name,'camera':pos,'target':target,'scale':scale,'sourceSceneSha256':hashlib.sha256((OUT/('structure-base.blend' if args.before else 'scene.blend')).read_bytes()).hexdigest(),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'warehouseIsolated':key=='warehouse','gateDoorState':'closed' if key=='gate-detail' else 'photograph: left both78deg, right leaf2 78deg'})
    (OUT/'renders.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print('SIDE CONNECTION RENDERS COMPLETE',len(report),flush=True)
