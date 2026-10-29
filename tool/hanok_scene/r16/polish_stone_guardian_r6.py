import bpy,sys,json
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P))
import sarang_reference_colour_r3 as c
p=c.p;f=c.f;D=P/'sarang-guardian-r6';v=p.read(D/'verification.json');native=D/v['native']
assert p.sha(native)==v['nativeSha256'];bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene
for m in bpy.data.materials:
 if m.get('guardian6')!='stone':continue
 t=m.node_tree;bs=next(n for n in p.live(t) if n.type=='BSDF_PRINCIPLED');co=f.node(t,'ShaderNodeNewGeometry','Final stone coordinates').outputs['Position'];seed=p.craft.illustration.member_value(t)
 base=f.ramp(t,seed,[(0,f.rgb('9C8D76')),(.5,f.rgb('B5A38B')),(1,f.rgb('CBBAA2'))],'Final stone warm mineral body')
 n=f.noise(t,co,9.5,2.8,'Final irregular mineral field')
 stains=f.ramp(t,n,[(.29,(.29,.24,.18,1)),(.415,(.53,.47,.37,1)),(.455,(.68,.62,.53,1)),(.478,(1,1,1,1)),(.72,(1.05,1.03,1,1))],'Final sharp broken mineral boundaries')
 col=f.mix(t,base,stains,.68,'Final mineral body integration','MULTIPLY')
 fine=f.noise(t,co,62,2,'Final small dispersed mineral pores')
 dots=f.ramp(t,fine,[(.26,(.20,.17,.13,1)),(.33,(.56,.50,.42,1)),(.39,(1,1,1,1))],'Final sparse pore boundaries')
 col=f.mix(t,col,dots,.38,'Final isolated pore pigment','MULTIPLY');t.links.new(f.contact(t,col,'stone'),bs.inputs['Base Color'])
 relief=f.mix(t,n,dots,.4,'Final stone grain relief');f.normal(t,bs,relief,.0045,.016,.26)
 keep=p.live(t)
 for nd in list(t.nodes):
  if nd not in keep:t.nodes.remove(nd)
lock=p.read(P/'sarang/geometry-lock.json');assert p.architecture([sc.objects[n] for n in lock['objects']])==v['geometry']
assert json.loads(json.dumps(c.fixed_scene(sc)))==p.read(P/'sarang-reference-colour-r3/fixed-render-state.json')
bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False)
v['nativeSha256']=p.sha(native);v['stoneRefinement']='Warm body with thresholded broken mineral patches, sparse pores; no lighting changes';p.write(D/'verification.json',v)
bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene
assert p.architecture([sc.objects[n] for n in lock['objects']])==v['geometry']
cam=sc.camera;orig=cam.matrix_world.copy();ortho=cam.data.ortho_scale;direction=(cam.location-Vector((7,0,3))).normalized();target=Vector((4,-.6,1.1))
cam.location=target+direction*18;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=5.6
sc.render.resolution_x=1200;sc.render.resolution_y=900;p.write(D/'stone-detail.json',p.render(sc,D,'stone-detail.png',48))
cam.matrix_world=orig;cam.data.ortho_scale=ortho;sc.render.resolution_x=1800;sc.render.resolution_y=1200;p.write(D/'render.json',p.render(sc,D,'render.png',64))
assert p.sha(v['source'])==v['sourceSha256'];assert c.preserve_check();v['renderComplete']=True;p.write(D/'verification.json',v)
print('STONE CONTACT AND GUARDIAN FINAL VERIFIED',flush=True)
