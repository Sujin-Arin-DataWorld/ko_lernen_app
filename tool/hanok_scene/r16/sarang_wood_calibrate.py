"""Keep R8 member palettes, restore grain range without highlight clipping."""
import bpy,sys
from pathlib import Path
OUT=Path(__file__).resolve().parent;sys.path.insert(0,str(OUT))
import produce as p
DEST=OUT/'sarang-r9';DEST.mkdir(exist_ok=True)
v=p.read(OUT/'sarang-r8/verification.json');src=OUT/'sarang-r8'/v['native'];assert p.sha(src)==v['nativeSha256']
bpy.ops.wm.open_mainfile(filepath=str(src));scene=bpy.context.scene
lock=p.read(OUT/'sarang/geometry-lock.json');obs=[scene.objects[n] for n in lock['objects']];assert p.architecture(obs)==v['geometry']
changed=[]
for m in bpy.data.materials:
 if not m.get('hs8_profile'):continue
 for n in m.node_tree.nodes:
  if n.label.endswith('R8 retain original broad and fine grain'):
   assert n.operation=='MULTIPLY';n.inputs[1].default_value=1.0;changed.append(m.name)
assert changed
native=DEST/'sarang-r9.blend';assert not native.exists()
bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False)
bpy.ops.wm.open_mainfile(filepath=str(native));scene=bpy.context.scene;obs=[scene.objects[n] for n in lock['objects']]
assert p.architecture(obs)==v['geometry'];assert p.stage_map('sarang',obs)==p.read(OUT/'sarang/construction-binding.json')
v.update(native=native.name,nativeSha256=p.sha(native),sourceNative=str(src),sourceSha256=v['nativeSha256'],restoredOriginalGrainRange=True)
p.write(DEST/'verification.json',v);p.write(DEST/'wood-profiles.json',p.read(OUT/'sarang-r8/wood-profiles.json'))
scene.render.resolution_x=1200;scene.render.resolution_y=800
p.write(DEST/'preview.json',p.render(scene,DEST,'preview.png',32))
print('R9 WOOD VERIFIED',len(changed),flush=True)
