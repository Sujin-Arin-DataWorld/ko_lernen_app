"""R10: preserve full RGB grain contrast with explicit per-use pigment gains."""
import bpy,sys
from pathlib import Path
OUT=Path(__file__).resolve().parent;sys.path.insert(0,str(OUT));import refine_sarang as r
p=r.p;DEST=OUT/'sarang-r10';DEST.mkdir(exist_ok=True)
GAINS={
 'column':(1.20,1.04,.87), 'beam':(1.02,.90,.75),
 'gable':(1.26,1.23,1.10),'rafter':(1.18,1.12,.97),
 'endgrain':(1.35,1.42,1.40),'floor':(1.05,.94,.79),
 'railing':(1.25,1.16,1.01),'apron':(1.15,1.13,1.04),
 'lower_board':(1.17,1.10,.94),'door_panel':(1.08,.98,.84),
 'frame':(.99,.86,.72),'lattice':(1.20,1.18,1.08)}
v=p.read(OUT/'sarang-r9/verification.json');src=OUT/'sarang-r9'/v['native'];assert p.sha(src)==v['nativeSha256']
bpy.ops.wm.open_mainfile(filepath=str(src));scene=bpy.context.scene
lock=p.read(OUT/'sarang/geometry-lock.json');obs=[scene.objects[n] for n in lock['objects']];assert p.architecture(obs)==v['geometry']
for m in bpy.data.materials:
 key=m.get('hs8_profile')
 if not key:continue
 t=m.node_tree;source=next(n for n in t.nodes if n.label=='R8 original directional grain luminance')
 original=p.value(source.inputs['Color'])
 col=p.mul(t,original,GAINS[key],'R10 '+key+' RGB pigment preserving original grain contrast')
 seed=p.craft.illustration.member_value(t)
 spread=.14 if key in ('lower_board','floor','apron') else .09
 factor=p.r2.ramp(t,seed,[(0,(1-spread,)*3+(1,)),(1,(1+spread,)*3+(1,))],'R10 individual piece lightness')
 col=p.r2.mix(t,col,factor,1,'R10 original detail plus member value','MULTIPLY')
 temperature=next(n for n in t.nodes if n.label=='R8 member honey to sand pigment variation')
 col=p.r2.mix(t,col,temperature.outputs['Color'],.65,'R10 individual honey and sand colour','MULTIPLY')
 col=r.cavity(t,col,'lattice' if key=='lattice' else 'wood')
 for bs in [n for n in p.live(t) if n.type=='BSDF_PRINCIPLED']:t.links.new(col,bs.inputs['Base Color'])
 m['hs10_gain']=GAINS[key]
native=DEST/'sarang-r10.blend';assert not native.exists()
bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False)
bpy.ops.wm.open_mainfile(filepath=str(native));scene=bpy.context.scene;obs=[scene.objects[n] for n in lock['objects']]
assert p.architecture(obs)==v['geometry'];assert p.stage_map('sarang',obs)==p.read(OUT/'sarang/construction-binding.json')
v.update(native=native.name,nativeSha256=p.sha(native),sourceNative=str(src),sourceSha256=v['nativeSha256'],fullRGBGrainContrastPreserved=True)
p.write(DEST/'verification.json',v)
profiles=p.read(OUT/'sarang-r9/wood-profiles.json');profiles['actualPigmentGains']=GAINS;profiles['paletteTriples']='R8 exploration, replaced by RGB grain preserving per-profile gains in R10'
p.write(DEST/'wood-profiles.json',profiles)
scene.render.resolution_x=1200;scene.render.resolution_y=800
p.write(DEST/'preview.json',p.render(scene,DEST,'preview.png',32));print('R10 WOOD VERIFIED',flush=True)
