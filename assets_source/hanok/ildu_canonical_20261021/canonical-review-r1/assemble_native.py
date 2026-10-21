"""Create a new full-estate canonical scene; leave every source file untouched."""
import bpy,hashlib,importlib.util,json,math,sys
from pathlib import Path
from mathutils import Vector,Matrix
OUT=Path(__file__).resolve().parent;ROOT=OUT.parent;BASE=ROOT/'estate-yard-wall-r1';R5=BASE/'living-r5'
sys.path.insert(0,str(BASE))
from audit_source import state
def sha(p):
 with Path(p).open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def write(n,d):(OUT/n).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('RECONSTRUCT R5 from preserved libraries',flush=True)
spec=importlib.util.spec_from_file_location('canonical_r5',R5/'run.py');r5=importlib.util.module_from_spec(spec);spec.loader.exec_module(r5)
prior=r5.reconstruct_r4();r5report=r5.apply_saved(prior)
source_scene=bpy.data.scenes['Hangul Sori | Full Ildu Estate'];bpy.context.window.scene=source_scene
bpy.context.view_layer.update()
before=state();print('R5 RECONSTRUCTED',len(before),flush=True)
owners=json.loads((ROOT/'construction/contracts/r12-owner-map.json').read_text(encoding='utf-8'))
groups={g['nativeOwner']:g['sourceObjects'] for g in owners['groups']}
def wall_context(n):
 return n.startswith('ConnectionLeft.') or '.wall' in n.lower() or n.startswith('GyeCraft.wall')
replace_keys={'left':'left_changgo','right':'right_ansarang','shrine':'sadangmun'}
removed={key:[n for n in groups[key] if not wall_context(n)] for key in replace_keys.values()}
all_removed={n for ns in removed.values() for n in ns}
# New scene owns its own collection, sharing unchanged existing object/data blocks.
source_scene.name='R12 preserved legacy full scene'
scene=source_scene.copy();scene.name='Hangul Sori | Full Ildu Estate'
for c in list(scene.collection.children):scene.collection.children.unlink(c)
for o in list(scene.collection.objects):scene.collection.objects.unlink(o)
for o in source_scene.objects:
 if o.name not in all_removed:scene.collection.objects.link(o)
bpy.context.window.scene=scene
assembly=[];new_objects=[]
for gate,key in replace_keys.items():
 mapping=json.loads((ROOT/'construction'/f'{gate}-object-stage-map.json').read_text(encoding='utf-8'))['assignments']
 native=ROOT/(gate+'-new.blend')
 expected=json.loads((OUT/(gate+'-export.json')).read_text())['sourceNativeSha256'];assert sha(native)==expected
 # Locate the existing portal by its two authored post bodies, not by adjoining walls.
 oldname={'left':'V27.left_changgo.frame.post','right':'V27.right_ansarang.frame.post','shrine':'North.sadangmun.round vermilion gatepost'}[gate]
 old=bpy.data.objects[oldname]
 points=[old.matrix_world@v.co for v in old.data.vertices]
 center=Vector(tuple((min(v[i] for v in points)+max(v[i] for v in points))*.5 for i in range(3)))
 yaw=math.atan2(old.matrix_world[1][0],old.matrix_world[0][0])
 ground={'left':.6,'right':0.,'shrine':1.5}[gate]
 M=Matrix.Translation((center.x,center.y,ground))@Matrix.Rotation(yaw,4,'Z')
 with bpy.data.libraries.load(str(native),link=False) as (a,b):b.objects=list(mapping)
 loaded=[o for o in b.objects if o];assert len(loaded)==len(mapping)
 for o in loaded:
  name=o.name;scene.collection.objects.link(o)
  o.matrix_world=M@o.matrix_world;o['canonical_gate']=gate;o['sourceObject']=name;o['reviewStage']=mapping[name]
  new_objects.append(o)
 bpy.context.view_layer.update()
 assembly.append(dict(gate=gate,key=key,sourceNativeSha256=expected,objectCount=len(loaded),removedLegacyCount=len(removed[key]),preservedWallCount=len(groups[key])-len(removed[key]),matrix=[list(row) for row in M],scale=[1,1,1],placementBasis='existing authored portal centre and existing site datum, rigid placement only; join review required'))
 print('ASSEMBLED',gate,len(loaded),flush=True)
after=state()
differences={n:{k:dict(before=v[k],after=after[n].get(k)) for k in v if v[k]!=after[n].get(k)} for n,v in before.items() if after[n]!=v}
write('assembly-source-differences.json',differences)
assert not differences,'An original object geometry/UV/transform/render state changed; see assembly-source-differences.json'
for key in replace_keys.values():assert not set(removed[key])&set(scene.objects.keys())
for o in new_objects:
 assert all(abs(s-1)<1e-5 for s in o.matrix_world.to_scale())
scene['canonical_designation']='User requested canonical source on 2026-10-21'
scene['immutable_architecture']='Preserve all exterior, detail and structure; style/material/color only'
bpy.ops.file.pack_all()
path=OUT/'ildu-estate-r5-three-gates-canonical.blend'
bpy.ops.wm.save_as_mainfile(filepath=str(path),compress=True)
report=dict(passed=True,native=path.name,nativeSha256=sha(path),source=BASE.joinpath('ildu-estate-yard-wall-r1.blend').as_posix(),sourceSha256=sha(BASE/'ildu-estate-yard-wall-r1.blend'),r5LibrarySha256=r5report['library_sha256'],sourceObjectsPreserved=len(before),allOriginalGeometryUvTransformsEqual=True,newGateMembers=len(new_objects),activeScene=scene.name,activeSceneObjects=len(scene.objects),activeSceneMeshCount=sum(o.type=='MESH' for o in scene.objects),oldGatesExcludedFromActiveScene=True,assembly=assembly,oldObjectsRetainedInLegacyScene=True,sourceFilesOverwritten=False,appIntegrated=False,assemblyVisualReview='pending',placementIsSurveyRecertification=False)
write('assembly-verification.json',report)
print('CANONICAL ASSEMBLY SAVED',path,flush=True)

