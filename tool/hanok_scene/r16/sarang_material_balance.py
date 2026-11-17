"""Local material correction after the first same-light visual comparison."""
import bpy,sys
from pathlib import Path
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P))
import sarang_material_rebuild as f
p=f.p
D=P/'sarang-material-rebuild-r2';D.mkdir(exist_ok=True)
v=p.read(P/'sarang-material-rebuild-r1/verification.json');src=P/'sarang-material-rebuild-r1'/v['native'];assert p.sha(src)==v['nativeSha256']
bpy.ops.wm.open_mainfile(filepath=str(src));sc=bpy.context.scene
lock=p.read(P/'sarang/geometry-lock.json');obs=[sc.objects[n] for n in lock['objects']]
assert p.architecture(obs)==v['geometry']
materials={s.material for o in obs for s in o.material_slots if s.material and s.material.get('freshMaterialProfile')}
for m in materials:
 t=m.node_tree;role=m['freshMaterialProfile']
 if role in f.PALETTES:
  # Keep dark fibres. Only compress values above mean; never add them to member colour.
  for n in list(t.nodes):
   if n.type=='MATH' and n.operation=='MINIMUM' and 'retained dark and light fibres' in n.label:
    source=n.outputs[0];targets=[l.to_socket for l in list(source.links)]
    low=f.scalar(t,'MINIMUM',source,1,'uncompressed dark growth')
    high=f.scalar(t,'MAXIMUM',f.scalar(t,'SUBTRACT',source,1),0,'positive growth')
    soft=f.scalar(t,'ADD',low,f.scalar(t,'MULTIPLY',high,.14),'gentle golden highlight shoulder')
    for target in targets:t.links.new(soft,target)
  if role=='gable':
   for n in t.nodes:
    if n.type=='VALTORGB' and 'member pigment' in n.label:
     for e,h in zip(n.color_ramp.elements,['AF7134','BE833E','CB914A']):e.color=f.rgb(h)
 elif role=='tile':
  for n in t.nodes:
   if n.type=='VALTORGB' and 'clay body per original island' in n.label:
    for e,h in zip(n.color_ramp.elements,['303A47','333E4B','37424E']):e.color=f.rgb(h)
   if n.type=='MATH' and 'fired clay roughness' in n.label:n.inputs[0].default_value=.76
   if n.type=='BEVEL':n.inputs['Radius'].default_value=.0009
   if n.type=='BSDF_PRINCIPLED':n.inputs['Specular IOR Level'].default_value=.19
 elif role=='stone':
  for n in t.nodes:
   if n.type=='VALTORGB' and 'individual original stone bodies' in n.label:
    for e,h in zip(n.color_ramp.elements,['A19179','B9A88D','D2C1A4']):e.color=f.rgb(h)
   if n.type=='MIX_RGB' and 'sparse broad mineral variation' in n.label:n.inputs[0].default_value=.75
   if n.type=='MIX_RGB' and 'selective pore pigment' in n.label:n.inputs[0].default_value=.32
floor=sc.objects['HS2 display ground (non-canonical)'];bs=floor.material_slots[0].material.node_tree.nodes.get('Principled BSDF')
bs.inputs['Emission Strength'].default_value=0
assert p.architecture(obs)==v['geometry'];assert p.stage_map('sarang',obs)==p.read(P/'sarang/construction-binding.json')
native=D/'sarang-material-rebuild.blend';assert not native.exists()
bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False)
bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene
assert p.architecture([sc.objects[n] for n in lock['objects']])==v['geometry']
new=dict(v,native=native.name,nativeSha256=p.sha(native),source=str(src),sourceSha256=v['nativeSha256'],sameLightingAsR7=False,lightChange='Display floor emission 0.65 to 0; other lights, exposure and camera unchanged',changes=['Wood bright growth compressed above mean only','Gable honey pigment locally lowered','Tile island variance and sharp highlights reduced','Stone mineral colour deepened'])
p.write(D/'verification.json',new)
result=p.render(sc,D,'preview.png',48);p.write(D/'preview.json',result)
print('MATERIAL BALANCE PREVIEW COMPLETE',flush=True)
