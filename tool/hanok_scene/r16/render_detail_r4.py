import bpy,sys,json
from pathlib import Path
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P))
import sarang_reference_colour_r3 as c
p=c.p;D=P/'sarang-detail-r4'
v=p.read(D/'verification.json');native=D/v['native'];assert p.sha(native)==v['nativeSha256']
bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene
lock=p.read(P/'sarang/geometry-lock.json');obs=[sc.objects[n] for n in lock['objects']]
assert p.architecture(obs)==v['geometry'];assert p.stage_map('sarang',obs)==p.read(P/'sarang/construction-binding.json')
assert json.loads(json.dumps(c.fixed_scene(sc)))==p.read(P/'sarang-reference-colour-r3/fixed-render-state.json')
sc.render.resolution_x=1800;sc.render.resolution_y=1200
r=p.render(sc,D,'render.png',96);p.write(D/'render.json',r)
assert c.preserve_check();assert p.sha(v['source'])==v['sourceSha256']
v['finalRender']=r;v['earlierVersionsPreservedAfterRender']=True;p.write(D/'verification.json',v)
scope=p.read(P/'CURRENT_SCOPE.json');scope.update(phase='sarang-local-material-review',candidate='sarang-detail-r4',
 authorization='User: reference and v2 tile variation; correct wall, stone and maru/numaru balustrade colours',
 latestVisualReview='Local material candidate 4; user review pending')
p.write(P/'CURRENT_SCOPE.json',scope)
p.write(P/'PROGRESS.json',dict(key='sarang',event='detail_4_render_ready',render=str(D/'render.png'),native=str(native),userApproved=False,runtimeIntegrated=False))
print('DETAIL 4 FINAL RENDER VERIFIED',flush=True)
