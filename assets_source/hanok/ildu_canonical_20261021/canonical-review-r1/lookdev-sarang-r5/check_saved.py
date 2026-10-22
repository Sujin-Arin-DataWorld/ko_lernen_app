"""Fresh disk verification of the final native, independently of its render process."""
import bpy,importlib.util,json,hashlib
from pathlib import Path
p=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('impl',p/'layered_materials.py');impl=importlib.util.module_from_spec(spec);spec.loader.exec_module(impl)
fix=impl.fix;r2=impl.r2;s=impl.s
bpy.ops.wm.open_mainfile(filepath=str(impl.NATIVE))
objs=[o for o in bpy.context.scene.objects if o.type=='MESH'];names=[o.name for o in objs]
geometry=s.geometry_state(objs);attrs=r2.attributes(objs);images=r2.image_state();plaques=fix.plaque_state();lighting=impl.study.signature(bpy.context.scene)
native=p/'sarang-three-value-brush-candidate.blend';bpy.ops.wm.open_mainfile(filepath=str(native));scene=bpy.context.scene
actual=[o for o in scene.objects if o.type=='MESH'];assert len(actual)==len(names)==711
assert geometry==s.geometry_state(actual);assert attrs==r2.attributes(actual);assert plaques==fix.plaque_state();assert lighting==impl.study.signature(scene)
assert images=={k:v for k,v in r2.image_state().items() if k in images}
assert s.sha(impl.NATIVE)==impl.EXPECTED
mats={sl.material.name:sl.material for o in actual if o.name not in s.PLAQUES for sl in o.material_slots if sl.material}
layers=['R5 FILL dark base','R5 FILL dominant midtone','R5 FILL restrained light','R5 PAINT dark strokes','R5 PAINT mid strokes','R5 PAINT light strokes']
for mat in mats.values():
 labels={n.label for n in mat.node_tree.nodes};assert set(layers)<=labels,mat.name
 if mat.get('r5_role') in ['wood','lattice']:
  assert 'R5 broad DARK MID LIGHT pigment planes' in labels,mat.name
  assert not any(n.label.startswith('R4 quiet intervals') for n in mat.node_tree.nodes)
manifest=json.loads((p/'render-manifest.json').read_text(encoding='utf-8'));assert manifest['complete'] and len(manifest['renders'])==8
for item in manifest['renders']:assert s.sha(p/item['file'])==item['sha256'],item['file']
record=json.loads((p/'verification.json').read_text(encoding='utf-8'))
if 'profiles' in record:record['baseProfiles']=record.pop('profiles')
record['effectiveWoodAndLatticeProfile']=dict(base=.99,mid=1.,light=1.025,darkPaint=.91,midPaint=1.,lightPaint=1.07)
record['freshFinalReopenVerified']=True;record['allRenderedImageHashesVerified']=True
record['candidateSha256']=s.sha(native)
(p/'verification.json').write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(dict(passed=True,meshCount=len(actual),materials=len(mats),sixLayersPerMaterial=True,sourceGeometryUvsAttributesPlaquesLightingEqual=True,renderedImages=8,candidateSha256=s.sha(native))))
