import bpy,sys,json
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P))
import sarang_reference_colour_r3 as c
p=c.p;f=c.f;D=P/'sarang-fit-r7';v=p.read(D/'verification.json');native=D/v['native']
assert p.sha(native)==v['nativeSha256'];bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene
fixed=c.fixed_scene(sc)
for m in bpy.data.materials:
 if m.get('guardian6')!='stone':continue
 t=m.node_tree;tex=next(n for n in t.nodes if n.type=='TEX_IMAGE' and 'R7 authored' in n.label)
 mix=next(n for n in t.nodes if 'R7 stone only pigment calibration' in n.label)
 g=f.gray(t,tex.outputs['Color'],'R7 authored mineral density')
 contrast=f.ramp(t,g,[(.15,(.40,.41,.43,1)),(.35,(.54,.56,.59,1)),(.52,(.78,.79,.81,1)),(.67,(1,1,1,1)),(1,(1,1,1,1))],'R7 local mineral definition')
 col=f.mix(t,tex.outputs['Color'],contrast,1,'R7 mineral pigment contrast','MULTIPLY');t.links.new(col,mix.inputs[1])
def patina(t):
 co=f.node(t,'ShaderNodeNewGeometry','R7 patina coordinates').outputs['Position']
 n=f.noise(t,co,80,3,'R7 patina flecks')
 col=f.ramp(t,n,[(.22,f.rgb('253C3C')),(.45,f.rgb('46574E')),(.57,f.rgb('687064')),(.66,f.rgb('887D62')),(.8,f.rgb('A39373'))],'R7 antique clay bronze backing')
 return col,n
m=bpy.data.materials['HS6 guardian ridge face'];t=m.node_tree
mix=next(n for n in t.nodes if 'Relief pigment inside face' in n.label)
col,n=patina(t);t.links.new(col,mix.inputs[1])
m=bpy.data.materials['HS6 patinated guardian edges'];t=m.node_tree;bs=next(n for n in t.nodes if n.type=='BSDF_PRINCIPLED');col,n=patina(t)
t.links.new(col,bs.inputs['Base Color']);f.normal(t,bs,n,.0006,.003,.15);bs.inputs['Roughness'].default_value=.79;bs.inputs['Metallic'].default_value=.18
lock=p.read(P/'sarang/geometry-lock.json');assert p.architecture([sc.objects[n] for n in lock['objects']])==v['geometry'];assert c.fixed_scene(sc)==fixed
bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False)
v['nativeSha256']=p.sha(native);v['stoneContrast']='Texture-local mineral contrast; no lighting or exposure change';v['guardianBacking']='Patinated surface on existing face and edge; complete artwork contained above cap';p.write(D/'verification.json',v)
bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene;cam=sc.camera;orig=cam.matrix_world.copy();ortho=cam.data.ortho_scale
sc.render.resolution_x=1200;sc.render.resolution_y=900
target=Vector((12.56,-3.52,6.87));direction=Vector((.35,-1,.18)).normalized();cam.location=target+direction*3;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=.85;p.write(D/'guardian.json',p.render(sc,D,'guardian.png',48))
cam.matrix_world=orig;cam.data.ortho_scale=ortho;direction=(cam.location-Vector((7,0,3))).normalized();target=Vector((4,-.6,1.1));cam.location=target+direction*18;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=5.6;p.write(D/'stone.json',p.render(sc,D,'stone.png',48))
cam.matrix_world=orig;cam.data.ortho_scale=ortho;sc.render.resolution_x=1800;sc.render.resolution_y=1200;p.write(D/'render.json',p.render(sc,D,'render.png',64))
assert p.architecture([sc.objects[n] for n in lock['objects']])==v['geometry'];assert c.fixed_scene(sc)==fixed;assert c.preserve_check();assert p.sha(v['source'])==v['sourceSha256']
v['renderComplete']=True;v['reopenedVerified']=True;v['render1And2Preserved']=True;p.write(D/'verification.json',v)
print('R7 COMPLETE AND VERIFIED',flush=True)
