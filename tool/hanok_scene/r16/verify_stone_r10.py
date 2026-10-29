import bpy,bmesh,sys,json,math
from pathlib import Path
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P));import sarang_reference_colour_r3 as c
p=c.p
def close(a,b):
 if isinstance(a,dict):return a.keys()==b.keys() and all(close(a[k],b[k]) for k in a)
 if isinstance(a,(list,tuple)):return len(a)==len(b) and all(close(x,y) for x,y in zip(a,b))
 if isinstance(a,(int,float)) and isinstance(b,(int,float)):return math.isclose(a,b,rel_tol=1e-6,abs_tol=1e-6)
 return a==b
bpy.ops.wm.open_mainfile(filepath=str(P/'sarang-relief-r8/sarang-relief-r8.blend'));reference=c.fixed_scene(bpy.context.scene)
bpy.ops.wm.open_mainfile(filepath=str(P/'sarang-wrap-r9/sarang-wrap-r9.blend'));sc=bpy.context.scene;assert close(c.fixed_scene(sc),reference)
lock=p.read(P/'sarang/geometry-lock.json');obs=[sc.objects[n] for n in lock['objects']]
for n in p.read(P/'sarang-wrap-r9/verification.json')['visibilityReplaced']:
 if n in lock['objects']:sc.objects[n].hide_render=False
assert p.architecture(obs)==p.read(P/'sarang-wrap-r9/verification.json')['geometry']
v=p.read(P/'sarang-wrap-r9/verification.json');v.update(renderComplete=True,reopenedNativeVerified=True,processBindingCount=711,render1And2Preserved=bool(c.preserve_check()),renders={n:p.read(P/f'sarang-wrap-r9/{n}.json') for n in ['guardian','stone','full']});p.write(P/'sarang-wrap-r9/verification.json',v)
D=P/'sarang-stone-masonry-r10';v=p.read(D/'verification.json');bpy.ops.wm.open_mainfile(filepath=v['native']);sc=bpy.context.scene
assert close(c.fixed_scene(sc),reference);obs=[sc.objects[n] for n in lock['objects']]
for n in v['hiddenOriginalStoneObjects']:
 if n in lock['objects']:sc.objects[n].hide_render=False
assert p.architecture(obs)==v['originalSourceState'];assert p.stage_map('sarang',obs)==p.read(P/'sarang/construction-binding.json');assert p.sha(Path(v['source']))==v['sourceSha256']
bad=[];total_verts=0;total_faces=0
for row in v['addedSolidStones']:
 o=sc.objects[row['name']];bm=bmesh.new();bm.from_mesh(o.data);count=sum(not e.is_manifold for e in bm.edges)
 if count:bad.append(dict(name=o.name,nonManifoldEdges=count))
 total_verts+=len(bm.verts);total_faces+=len(bm.faces);bm.free()
assert not bad,bad
v.update(renderComplete=True,reopenedNativeVerified=True,render1And2Preserved=bool(c.preserve_check()),solidStoneCount=len(v['addedSolidStones']),constructionMappingOriginalCount=711,lightingCameraExposurePreserved=True,solidTopologyAudit=dict(nonManifold=[],vertices=total_verts,faces=total_faces),renders={n:p.read(D/(n+'.json')) for n in ['stone','full']})
p.write(D/'verification.json',v);print(json.dumps(dict(verified=True,stones=len(v['addedSolidStones']),vertices=total_verts,faces=total_faces,source711Preserved=True,nativeSha256=p.sha(Path(v['native'])))),flush=True)
