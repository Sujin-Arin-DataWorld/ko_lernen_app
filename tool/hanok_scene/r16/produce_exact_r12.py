import bpy,sys,bmesh,json
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P));import sarang_reference_colour_r3 as c,guardian_exact_r12,guardian_sculpt_r11,stone_shape_r12
p=c.p;D=P/'sarang-exact-r12';D.mkdir(exist_ok=True);source=P/'sarang-stone-masonry-r10/sarang-stone-masonry-r10.blend';source_sha=p.sha(source)
bpy.ops.wm.open_mainfile(filepath=str(source));sc=bpy.context.scene;lock=p.read(P/'sarang/geometry-lock.json');original=[sc.objects[n] for n in lock['objects']];before=p.architecture(original);fixed=c.fixed_scene(sc);visibility={o.name:o.hide_render for o in original}
if '--reuse-stones' in sys.argv:
 previous=p.read(D/'verification.json');assert previous['sourceSha256']==source_sha and previous['source711DataPreserved']
 bpy.ops.wm.open_mainfile(filepath=str(D/'sarang-exact-r12.blend'));sc=bpy.context.scene;original=[sc.objects[n] for n in lock['objects']]
 for ob in list(sc.objects):
  if ob.name.startswith('HS12 '):bpy.data.objects.remove(ob,do_unlink=True)
 for ob in original:ob.hide_render=visibility[ob.name]
 assert p.architecture(original)==before
 stone=p.read(D/'stone-shape.json')
else:
 stone=stone_shape_r12.refine_stones(sc)
p.write(D/'stone-shape.json',stone)
if '--stone-material' in sys.argv:
 import stone_material_r12
 stone_material=stone_material_r12.refine_materials(sc);p.write(D/'stone-material.json',stone_material)
warmth=None;wood=None;fixed_before=fixed
if '--warmth' in sys.argv:
 import warmth_material_r12,wood_material_r12
 wood=wood_material_r12.refine_materials(sc);p.write(D/'wood-material.json',wood)
 warmth=warmth_material_r12.apply_warmth(sc);assert warmth['allChecksPassed'];p.write(D/'warmth-material.json',warmth)
 fixed=c.fixed_scene(sc)
guardian=guardian_exact_r12.build(sc);p.write(D/'guardian-shape.json',guardian)
def source_state():
 now={o.name:o.hide_render for o in original}
 for o in original:o.hide_render=visibility[o.name]
 result=p.architecture(original)
 for o in original:o.hide_render=now[o.name]
 return result
assert source_state()==before;assert p.stage_map('sarang',original)==p.read(P/'sarang/construction-binding.json');assert c.fixed_scene(sc)==fixed;assert c.preserve_check()
topology=[]
for o in sc.objects:
 if o.type!='MESH' or not o.name.startswith('HS12 ') or o.hide_render:continue
 bm=bmesh.new();bm.from_mesh(o.data);bad=sum(not e.is_manifold for e in bm.edges);bm.free()
 inherited=o.name.startswith('HS12 ridge finish ')
 if not inherited:assert bad==0,(o.name,bad)
 else:
  source_mesh=sc.objects[o['construction_parent']].data
  assert len(source_mesh.vertices)==len(o.data.vertices) and len(source_mesh.polygons)==len(o.data.polygons)
 topology.append(dict(name=o.name,vertices=len(o.data.vertices),polygons=len(o.data.polygons),nonManifoldEdges=bad,inheritedSourceTopology=inherited))
bpy.context.preferences.filepaths.save_version=0;native=D/'sarang-exact-r12.blend';bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False)
v=dict(source=str(source),sourceSha256=source_sha,native=str(native),nativeSha256=p.sha(native),source711DataPreserved=True,originalState=before,visibilityChanges=[dict(name=o.name,before=visibility[o.name],after=o.hide_render) for o in original if visibility[o.name]!=o.hide_render],stone=stone,guardian=guardian,topology=topology,fixedScene=fixed,fixedSceneBefore=fixed_before,wood=wood,warmth=warmth,render1And2Preserved=True,userApproved=False,runtimeIntegrated=False,renderComplete=False,sourceDesignSha256={k:p.sha(guardian[k]) for k in ['frontSource','sideSource']})
p.write(D/'verification.json',v);print('R12 NATIVE SAVED',flush=True)
cam=sc.camera;old=cam.matrix_world.copy();ortho=cam.data.ortho_scale
def shot(name,target,direction,scale,samples=40,size=1000):
 target=Vector(target);direction=Vector(direction).normalized();cam.location=target+direction*3;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=scale;sc.render.resolution_x=size;sc.render.resolution_y=size;p.write(D/(name+'.json'),p.render(sc,D,name+'.png',samples))
shot('guardian-front',(12.56,-3.49,6.875),(.35,-1,.16),.60)
shot('guardian-side',(12.56,-3.49,6.875),(1,-.24,.13),.60)
shot('guardian-back',(12.56,-3.49,6.875),(.3,1,.12),.60)
clay=guardian_sculpt_r11.make_material('HS12 neutral clay verified','989898',0);sc.view_layers[0].material_override=clay
shot('guardian-clay',(12.56,-3.49,6.875),(.55,-1,.16),.60)
sc.view_layers[0].material_override=None
direction=(old.translation-Vector((7,0,3))).normalized();shot('stone',(3.9,-.6,1.25),direction,5.1,48,1200)
cam.matrix_world=old;cam.data.ortho_scale=ortho;sc.render.resolution_x=1800;sc.render.resolution_y=1200;p.write(D/'full.json',p.render(sc,D,'full.png',64))
bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene;original=[sc.objects[n] for n in lock['objects']];assert c.fixed_scene(sc)==fixed;assert source_state()==before;assert p.sha(source)==source_sha
v.update(renderComplete=True,reopenedNativeVerified=True,renders={k:p.read(D/(k+'.json')) for k in ['guardian-front','guardian-side','guardian-back','guardian-clay','stone','full']});p.write(D/'verification.json',v);print('R12 NATIVE MULTIVIEW VERIFIED',flush=True)
