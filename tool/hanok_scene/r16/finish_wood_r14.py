"""Reopen native, verify stable member topology/slots, render actual review views."""
import bpy,sys,json,collections
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P))
import sarang_reference_colour_r3 as c
p=c.p;version=sys.argv[-1] if sys.argv[-1] in ('r14','r15','r16') else 'r14'
D=P/('sarang-wood-'+version);native=D/('sarang-wood-'+version+'.blend')
bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene
receipt=p.read(D/'verification.json');lock=p.read(P/'sarang/geometry-lock.json')
assert p.sha(native)==receipt['nativeSha256']
assert p.architecture([sc.objects[n] for n in lock['objects']])==receipt['architecture']
assert c.preserve_check()
fixed=c.fixed_scene(sc);member_rows=[];bad=[]
for ob in sc.objects:
 if ob.type!='MESH' or ob.hide_render:continue
 mats=[s.material for s in ob.material_slots if s.material and s.material.get('hs14_individual_wood')]
 if not mats:continue
 # Original topology, no bmesh writes. Connected components are reviewed as
 # physical-member candidates, preserving the mixed joined/separate structure.
 count=len(ob.data.vertices);parents=list(range(count))
 def find(x):
  while x!=parents[x]:parents[x]=parents[parents[x]];x=parents[x]
  return x
 for e in ob.data.edges:
  a,b=map(find,e.vertices)
  if a!=b:parents[b]=a
 groups=collections.defaultdict(list)
 for v in ob.data.vertices:groups[find(v.index)].append(v.index)
 attr=ob.data.attributes.get('P18 source member id');nonconstant=0
 if attr and attr.domain=='POINT':
  for g in groups.values():
   if len({attr.data[i].value for i in g})>1:nonconstant+=1
 if nonconstant:bad.append(ob.name)
 for m in mats:
  live=p.live(m.node_tree)
  seed=next(n for n in live if n.type=='TEX_WHITE_NOISE' and n.label=='Illustration constant pigment per member, not surface noise')
  todo=[seed];up=set()
  while todo:
   n=todo.pop()
   if n in up:continue
   up.add(n);todo.extend(l.from_node for inp in n.inputs for l in inp.links)
  assert any(n.type=='OBJECT_INFO' for n in up),m.name
  assert any(n.type=='NEW_GEOMETRY' for n in up),m.name
  assert any(n.type=='ATTRIBUTE' and n.attribute_name=='P18 source member id' for n in up),m.name
 member_rows.append(dict(object=ob.name,components=len(groups),memberIdConstantWithinComponents=nonconstant==0,woodSlots=len(mats)))
receipt['memberAudit']=dict(objects=len(member_rows),components=sum(r['components'] for r in member_rows),sourceIdVaryingInsideComponent=bad,seedLineageVerified=True,rows=member_rows)
receipt['renders']={}
sc.render.resolution_x=1800;sc.render.resolution_y=1200
receipt['renders']['full']=p.render(sc,D,'full.png',64);p.write(D/'verification.json',receipt)
direction=Vector((.547418,-.766920,.334913)).normalized()
def camera(target,scale):
 target=Vector(target);sc.camera.location=target+direction*12.
 sc.camera.rotation_euler=(-direction).to_track_quat('-Z','Y').to_euler();sc.camera.data.ortho_scale=scale
 sc.render.resolution_x=1400;sc.render.resolution_y=1200
camera((13.15,-1.5,2.50),5.65)
receipt['renders']['numaru']=p.render(sc,D,'numaru-wood.png',48);p.write(D/'verification.json',receipt)
camera((4.50,.1,2.90),6.0)
receipt['renders']['main']=p.render(sc,D,'main-wood.png',48);p.write(D/'verification.json',receipt)
bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene
assert p.architecture([sc.objects[n] for n in lock['objects']])==receipt['architecture']
assert c.fixed_scene(sc)==fixed
assert p.sha(native)==receipt['nativeSha256']
assert p.sha(Path(receipt['source']))==receipt['sourceSha256']
receipt.update(renderComplete=True,reopenedNativeVerified=True,visualReview='pending independent actual render review')
p.write(D/'verification.json',receipt)
print('R14 FULL AND TWO NATIVE CLOSEUPS VERIFIED',len(member_rows),'wood objects',sum(r['components'] for r in member_rows),'components',len(bad),'mixed original id components',flush=True)
