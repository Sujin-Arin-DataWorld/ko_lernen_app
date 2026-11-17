import bpy,sys
from pathlib import Path
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P))
import sarang_reference_colour_r3 as c
f=c.f;p=c.p;D=P/'sarang-detail-r4';v=p.read(D/'verification.json');native=D/v['native']
assert p.sha(native)==v['nativeSha256'];bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene
lock=p.read(P/'sarang/geometry-lock.json');obs=[sc.objects[n] for n in lock['objects']];light=c.fixed_scene(sc)
for m in {s.material for o in obs for s in o.material_slots if s.material and s.material.get('detail4')=='stone'}:
 t=m.node_tree
 for n in t.nodes:
  if n.type=='VALTORGB' and 'stone bodies in related mineral tones' in n.label:
   for e,h in zip(n.color_ramp.elements,['97866F','B4A087','C7B59A','D8C7AD']):e.color=f.rgb(h)
  if n.type=='VALTORGB' and 'quiet mineral wash' in n.label:n.color_ramp.elements[0].color=(.64,.59,.51,1)
  if n.type=='MIX_RGB' and 'restrained stone mottling' in n.label:n.inputs[0].default_value=.68
  if n.type=='BEVEL':n.inputs['Radius'].default_value=.014
 bs=next(n for n in p.live(t) if n.type=='BSDF_PRINCIPLED');base=bs.inputs['Base Color'].links[0].from_socket
 geo=f.node(t,'ShaderNodeNewGeometry','R4 pit coordinates');vor=f.node(t,'ShaderNodeTexVoronoi','R4 mineral pores');vor.inputs['Scale'].default_value=72;t.links.new(geo.outputs['Position'],vor.inputs['Vector'])
 pits=f.ramp(t,vor.outputs['Distance'],[(.05,(.34,.27,.20,1)),(.13,(.65,.59,.49,1)),(.20,(1,1,1,1))],'R4 sparse pore colour')
 col=f.mix(t,base,pits,.72,'R4 mineral stipple','MULTIPLY');t.links.new(col,bs.inputs['Base Color'])
assert c.fixed_scene(sc)==light;assert p.architecture(obs)==v['geometry']
bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False)
v['nativeSha256']=p.sha(native);v['stoneRefinement']='Restrained mineral variation and sparse fine pores';p.write(D/'verification.json',v)
exec(compile((P/'render_detail_r4.py').read_text(encoding='utf-8'),str(P/'render_detail_r4.py'),'exec'))
