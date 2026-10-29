import bpy,sys,json
from pathlib import Path
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P))
import sarang_reference_colour_r3 as c
p=c.p;D=P/'sarang-surface-r5';v=p.read(D/'verification.json');native=D/v['native']
assert p.sha(native)==v['nativeSha256'];bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene
lock=p.read(P/'sarang/geometry-lock.json');lighting=c.fixed_scene(sc)
for m in bpy.data.materials:
 if m.get('surface5')!='stone':continue
 t=m.node_tree
 for n in t.nodes:
  if n.type=='BUMP' and n.label=='Fresh material microrelief':n.inputs['Distance'].default_value=.0025;n.inputs['Strength'].default_value=.20
  if n.type=='VALTORGB' and 'R5 separated iron mineral flecks' in n.label:
   for e,pos in zip(n.color_ramp.elements,[.24,.32,.42,.70]):e.position=pos
  if n.type=='MIX_RGB' and 'R5 readable sparse freckles' in n.label:n.inputs[0].default_value=.56
assert p.architecture([sc.objects[n] for n in lock['objects']])==v['geometry'];assert c.fixed_scene(sc)==lighting
bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False)
v['nativeSha256']=p.sha(native);v['previewRefinement']='Reduce evenly distributed roughness; retain mineral clouds, sparse pores and restored wall';p.write(D/'verification.json',v)
exec(compile((P/'render_surface_r5.py').read_text(encoding='utf-8'),str(P/'render_surface_r5.py'),'exec'))
