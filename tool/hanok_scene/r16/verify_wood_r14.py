import bpy,sys,json,hashlib
from pathlib import Path
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P))
import sarang_reference_colour_r3 as c
p=c.p;version=sys.argv[-1] if sys.argv[-1] in ('r14','r15','r16') else 'r14'
D=P/('sarang-wood-'+version);r=p.read(D/'verification.json')
source=Path(r['source']);native=Path(r['native'])
def snapshot(path):
 bpy.ops.wm.open_mainfile(filepath=str(path));sc=bpy.context.scene
 lock=p.read(P/'sarang/geometry-lock.json');obs=[sc.objects[n] for n in lock['objects']]
 bindings=p.stage_map('sarang',obs)
 nodes={o.name:(o.type,o.parent.name if o.parent else None,[list(row) for row in o.matrix_world]) for o in sc.objects}
 untouched={}
 for o in sc.objects:
  if o.type!='MESH':continue
  for i,s in enumerate(o.material_slots):
   m=s.material
   if not m or m.get('hs12_wood_direction') or 'ondol floor' in o.name:continue
   untouched[(o.name,i)]=p.s.material_state(m)
 return dict(architecture=p.architecture(obs),bindings=bindings,nodes=nodes,untouched=untouched,fixed=c.fixed_scene(sc))
a=snapshot(source);b=snapshot(native)
sc=bpy.context.scene
grain_expected={(row['object'],row['slot']):row['material'] for row in r.get('grain',{}).get('assignments',[])}
for row in r.get('changes',r.get('wood',{})).get('assignments',[]):
 ob=sc.objects[row['object']];mat=ob.material_slots[row['slot']].material
 assert mat.name==grain_expected.get((row['object'],row['slot']),row['material']) and mat.get('hs14_individual_wood')
 attr=ob.data.attributes.get('P18 source member id')
 assert attr is not None and attr.domain=='POINT',ob.name
assert a['architecture']==b['architecture']==r['architecture']
assert a['bindings']==b['bindings']==p.read(P/'sarang/construction-binding.json')
assert a['nodes']==b['nodes']
assert a['untouched']==b['untouched']
assert a['fixed']==b['fixed']
assert p.sha(source)==r['sourceSha256'] and p.sha(native)==r['nativeSha256']
assert c.preserve_check()
for render in r['renders'].values():assert p.sha(D/render['file'])==render['sha256']
r['finalChecks']=dict(source711GeometryUVAttributesAndNormalsPreserved=True,canonicalConstructionBindingsPreserved=True,allObjectNamesParentsAndTransformsPreserved=True,untargetedMaterialsPreserved=True,lightsWorldExposureCameraAndGroundPreserved=True,sourceFileHashPreserved=True,render1And2HashPreserved=True,savedNativeReopened=True,renderHashesVerified=True)
p.write(D/'verification.json',r)
print(json.dumps(r['finalChecks'],indent=2))
