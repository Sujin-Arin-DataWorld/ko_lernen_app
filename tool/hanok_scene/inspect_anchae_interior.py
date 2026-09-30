"""Read-only cutaway and local member bounds; never saves the native scene."""
from pathlib import Path
import bpy,json,sys,argparse,hashlib
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).parent))
from northern_wall_joints import basis
from northern_anchae_plan import local_parts
OUT=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
p=argparse.ArgumentParser();p.add_argument('--scene',default='scene.blend');p.add_argument('--suffix',default='before');args=p.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
bpy.ops.wm.open_mainfile(filepath=str(OUT/args.scene));s=bpy.context.scene
c=json.loads((OUT/'northern-contract.json').read_text(encoding='utf8'));origin,rot,axes=basis(c['buildings'])
rows={}
for tag in ('interior partition','room ondol raised clay','room warm paper floor','floor individual boards','floor under joists'):
 ob=bpy.data.objects.get('North.anchae.'+tag)
 if ob:rows[tag]=[{'min':q.min(0).round(5).tolist(),'max':q.max(0).round(5).tolist()} for _,q in local_parts(ob,origin,rot)]
dep=bpy.context.evaluated_depsgraph_get();rays=[]
for axis,sign in ((4,1),(6,-1)):
 for z in (1.10,1.90):
  start=origin+rot@Vector((axes[axis]+sign*.35,.246,z))
  hit,_,_,_,ob,_=s.ray_cast(dep,start,rot@Vector((-sign,0,0)),distance=.70)
  rays.append({'axis':axis,'height':z,'hit':ob.name if hit else None})
report={'sceneSha256':hashlib.sha256((OUT/args.scene).read_bytes()).hexdigest(),'members':rows,'closedDoorRays':rays}
(OUT/('anchae-interior-'+args.suffix+'.json')).write_text(json.dumps(report,indent=2),encoding='utf8')
print(json.dumps({'partitions':rows['interior partition'],'floor':rows['room warm paper floor'],'rays':rays}),flush=True)
for ob in s.objects:
 if ob.type!='MESH':continue
 ob.hide_render=(ob.get('construction_building')!='anchae' and not ob.name.startswith('ConnectionSite.')) or any(k in ob.name for k in ('roof','rafter','room ceiling','eave','ridge','purlin'))
camera=bpy.data.cameras.new('Interior audit');camera.type='ORTHO';camera.ortho_scale=20
cam=bpy.data.objects.new('CAM interior audit',camera);s.collection.objects.link(cam);s.camera=cam
cam.location=origin+rot@Vector((-.5,-9,12));target=origin+rot@Vector((-.5,0,1.4));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
s.render.engine='CYCLES';s.cycles.samples=12;s.cycles.use_denoising=True;s.render.resolution_x=1440;s.render.resolution_y=960;s.render.resolution_percentage=100;s.render.image_settings.file_format='PNG'
s.render.filepath=str(OUT/('anchae-interior-'+args.suffix+'.png'));bpy.ops.render.render(write_still=True)
