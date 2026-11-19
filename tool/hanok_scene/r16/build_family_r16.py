"""Native derivative building production; original architecture and IDs locked."""
import bpy,sys,json
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P))
import produce as p
import portable_materials_r16 as portable
key=sys.argv[-1];inventory=p.read(P/'BUILDING_TRANSFER_INVENTORY_R16.json')
entry=next(x for x in inventory['buildings'] if x['key']==key)
D=P/'family-r16'/key;D.mkdir(parents=True,exist_ok=True)
source=Path(entry['canonicalNative']);assert p.sha(source)==entry['canonicalActualSha256']
bpy.ops.wm.open_mainfile(filepath=str(source));sc=bpy.context.scene
obs=[o for o in sc.objects if o.type=='MESH'];names=[o.name for o in obs]
before=p.architecture(obs);binding=p.stage_map(key,obs)
nodes={o.name:dict(type=o.type,parent=o.parent.name if o.parent else None,matrix=[list(r) for r in o.matrix_world]) for o in obs}
master=p.read(P/'sarang-wood-r16/material-masters.json')
assert p.sha(master['native'])==master['nativeSha256']
requested=list(master['roles'].values())
with bpy.data.libraries.load(master['native'],link=False) as (available,loaded):loaded.materials=requested
masters=dict(zip(master['roles'],loaded.materials))
assert all(masters.values())
try:changes=portable.apply(sc,key,masters)
except portable.MappingError as error:
 p.write(D/'material-error.json',error.receipt);raise
assert p.architecture(obs)==before and p.stage_map(key,obs)==binding
# One common review studio, fit to each original building without remodelling.
# Explicit node types avoid translated default node names in Korean Blender.
pts,lo,hi=p.bounds(obs);centre=(lo+hi)/2;span=max(hi.x-lo.x,hi.y-lo.y)
for ob in list(sc.objects):
 if ob.type=='LIGHT':bpy.data.objects.remove(ob,do_unlink=True)
world=bpy.data.worlds.new('R16 review sky');world.use_nodes=True;sc.world=world
world.node_tree.nodes.clear();bg=world.node_tree.nodes.new('ShaderNodeBackground');out=world.node_tree.nodes.new('ShaderNodeOutputWorld');world.node_tree.links.new(bg.outputs[0],out.inputs[0])
bg.inputs['Color'].default_value=(.806952,.854993,.913099,1);bg.inputs['Strength'].default_value=.75
def light(name,kind,location,power,size,target):
 data=bpy.data.lights.new(name,kind);data.energy=power;data.color=(1,.904661,.745404)
 if kind=='AREA':data.shape='DISK';data.size=size
 if kind=='SUN':data.angle=.244346
 ob=bpy.data.objects.new(name,data);sc.collection.objects.link(ob);ob.location=location;p.point(ob,target)
light('R16 warm upper-left key','SUN',centre+Vector((-10,-12,20)),3.5,0,centre)
light('R16 soft material separation fill','AREA',centre+Vector((span*.25,-span*.7,span*.35)),900*(span/20)**2,span*.7,centre)
bpy.ops.mesh.primitive_plane_add(size=600,location=(centre.x,centre.y,lo.z-.025))
ground=bpy.context.object;ground.name='R16 display ground (non-canonical)';ground['displayOnly']=True
gm=bpy.data.materials.new('R16 neutral warm ground');gm.use_nodes=True
gbs=next(n for n in gm.node_tree.nodes if n.type=='BSDF_PRINCIPLED');gbs.inputs['Base Color'].default_value=(.83,.78,.70,1);gbs.inputs['Roughness'].default_value=.92
ground.data.materials.append(gm)
sc.render.engine='CYCLES';sc.cycles.device='CPU';sc.cycles.use_denoising=True;sc.cycles.max_bounces=6;sc.cycles.diffuse_bounces=4;sc.cycles.glossy_bounces=3;sc.cycles.transparent_max_bounces=8
sc.render.film_transparent=False;sc.render.image_settings.file_format='PNG';sc.render.image_settings.color_mode='RGB';sc.render.use_freestyle=False
sc.view_settings.view_transform='AgX';sc.view_settings.look='AgX - Medium High Contrast';sc.view_settings.exposure=.20
pts,lo,hi=p.bounds(obs);span=max(hi.x-lo.x,hi.y-lo.y)
for ob in sc.objects:
 if ob.type!='LIGHT':continue
 if ob.data.type=='SUN':ob.data.energy=3.5;ob.data.color=(1,.904661,.745404)
 elif 'courtyard bounce' in ob.name:ob.data.energy=900*(span/20)**2;ob.data.color=(1,.904661,.745404)
 elif 'cool roof rim' in ob.name:ob.data.energy=0.
hero=next(x['views']['hero'] for x in p.read(P.parent/'hangulsori-buildings-r1/SOURCE_LOCK.json') if x['key']==key)
direction=(Vector(hero['position'])-Vector(hero['target'])).normalized()
camera=p.fit_camera(sc,obs,(1200,800),direction)
sc.cycles.use_adaptive_sampling=True;sc.cycles.adaptive_threshold=.035;sc.cycles.adaptive_min_samples=8;sc.cycles.seed=217
sc.render.threads_mode='FIXED';sc.render.threads=6;sc.render.use_persistent_data=False
bpy.context.preferences.filepaths.save_version=0
native=D/(key+'.blend')
bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False)
receipt=dict(key=key,name=entry['name'],source=str(source),sourceSha256=entry['canonicalActualSha256'],native=str(native),nativeSha256=p.sha(native),masterNative=master['native'],masterSha256=master['nativeSha256'],architecture=before,objects=names,objectState=nodes,materialTransfer=changes,camera=camera,canonicalProcessBindingsPreserved=True,geometryUVAttributesNormalsPreserved=True,protectedPaintAndLetteringPreserved=True,userApproved=False,runtimeIntegrated=False,renderComplete=False)
p.write(D/'verification.json',receipt);p.write(D/'construction-binding.json',binding)
bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene;obs=[sc.objects[n] for n in names]
assert p.architecture(obs)==before and p.stage_map(key,obs)==binding
for r in changes['assignments']:assert sc.objects[r['object']].material_slots[r['slot']].material.name==r['material']
for r in changes['preserved']:assert sc.objects[r['object']].material_slots[r['slot']].material.name==r['oldMaterial']
receipt['reopenedNativeVerified']=True;p.write(D/'verification.json',receipt)
receipt['full']=p.render(sc,D,'full.png',32);receipt['renderComplete']=True
assert p.sha(source)==entry['canonicalActualSha256'];assert p.sha(native)==receipt['nativeSha256']
p.write(D/'verification.json',receipt);print('FAMILY_R16_VERIFIED',key,before['meshCount'],flush=True)
