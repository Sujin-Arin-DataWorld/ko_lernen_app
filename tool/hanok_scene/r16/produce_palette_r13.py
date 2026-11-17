"""Reference-sampled per-material colour calibration, preserving all mesh and UV data."""
import bpy,sys,json,math
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P));import sarang_reference_colour_r3 as c
p=c.p;D=P/'sarang-palette-r13';source=P/'sarang-exact-r12/sarang-exact-r12-refined.blend'
samples=p.read(D/'samples.json');bpy.ops.wm.open_mainfile(filepath=str(source));sc=bpy.context.scene
lock=p.read(P/'sarang/geometry-lock.json');obs=[sc.objects[n] for n in lock['objects']]
before=p.architecture(obs);fixed_before=c.fixed_scene(sc);source_sha=p.sha(source)
def lin(x):
 x=x/255;return x/12.92 if x<=.04045 else ((x+.055)/1.055)**2.4
def gains(key):
 row=samples['samples'][key];target=row['target']['displayRGB'][1];current=row['render']['displayRGB'][1]
 if key=='floor':current=[164,74,8]
 return [max(.30,min(1.55,lin(t)/max(lin(s),.008))) if s>=16 else 1. for t,s in zip(target,current)]
mapping={'beam':'frame','rafter':'apron','lattice':'frame','door_panel':'frame','endgrain':'column'}
cache={};assigned=[];changes=[]
for ob in sc.objects:
 if ob.type!='MESH' or ob.hide_render:continue
 for i,slot in enumerate(ob.material_slots):
  old=slot.material
  if old is None or not old.use_nodes:continue
  role=old.get('warmth_role') or old.get('referenceColourProfile')
  if old.get('hs12_stone_material_version'):role='stone'
  if role not in samples['samples'] and role not in mapping:continue
  if role=='ground':continue
  key=mapping.get(role,role);ck=(old.as_pointer(),key)
  if ck not in cache:
   state=p.s.material_state(old);m=old.copy();m.name='HS13 sampled '+str(role)+' | '+old.name
   tree=m.node_tree;factor=gains(key)
   nodes=[n for n in p.live(tree) if n.type=='BSDF_PRINCIPLED']
   for bs in nodes:
    sock=bs.inputs['Base Color'];node=tree.nodes.new('ShaderNodeMixRGB');node.blend_type='MULTIPLY';node.label='HS13 reference sampled '+key;node.inputs[0].default_value=1;node.inputs[2].default_value=(*factor,1)
    if sock.is_linked:tree.links.new(sock.links[0].from_socket,node.inputs[1])
    else:node.inputs[1].default_value=sock.default_value
    tree.links.new(node.outputs[0],sock)
    if key=='paper':
     bs.inputs['Emission Strength'].default_value=4.2
   m['hs13_reference_sha256']=samples['referenceSha256'];m['hs13_sample_family']=key
   assert p.s.material_state(old)==state
   cache[ck]=m;changes.append(dict(source=old.name,material=m.name,role=role,family=key,linearRGBGain=factor,paperEmission=4.2 if key=='paper' else None))
  slot.link='OBJECT';slot.material=cache[ck];assigned.append(dict(object=ob.name,slot=i,role=role))
# Reconnected local lamps are too concentrated at the old power; rebalance just those two.
for name,power in [('HS3 SPEC main warm interior bounce',90.),('HS3 numaru opening bounce',20.)]:
 sc.objects[name].data.energy=power
assert p.architecture(obs)==before;assert c.preserve_check()
fixed=c.fixed_scene(sc)
for k in ['camera','world','ground','view','compositor']:assert fixed[k]==fixed_before[k],k
native=D/'sarang-palette-r13.blend';bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False)
report=dict(reference=samples['reference'],referenceSha256=samples['referenceSha256'],source=str(source),sourceSha256=source_sha,native=str(native),nativeSha256=p.sha(native),source711DataPreserved=True,render1And2Preserved=True,architecture=before,fixedBefore=fixed_before,fixedAfter=fixed,changes=changes,assignments=assigned,materialCopies=len(cache),globalExposureUnchanged=True,renderComplete=False,userApproved=False,runtimeIntegrated=False)
p.write(D/'verification.json',report);print('R13 PALETTE SAVED',flush=True)
sc.render.resolution_x=1200;sc.render.resolution_y=800
preview=p.render(sc,D,'preview.png',32)
bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene
assert p.architecture([sc.objects[n] for n in lock['objects']])==before
assert p.sha(source)==source_sha
report.update(preview=preview,reopenedNativeVerified=True)
p.write(D/'verification.json',report);print('R13 PREVIEW VERIFIED',flush=True)

