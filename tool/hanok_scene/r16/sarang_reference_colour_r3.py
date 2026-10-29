"""Render 3: reset pigment, use reference samples, freeze render-2 illumination."""
import bpy, sys, json, hashlib
from pathlib import Path
from collections import Counter
P=Path(__file__).resolve().parent
sys.path.insert(0,str(P))
import sarang_material_rebuild as f
p=f.p
D=P/'sarang-reference-colour-r3'
S=p.read(P/'reference-sampled-colours.json')
PALETTE={k:v['displayColors'] for k,v in S['samples'].items()}

def matrix(ob):return [list(row) for row in ob.matrix_world]
def fixed_scene(sc):
 cam=sc.camera
 lights=[]
 for ob in sorted(sc.objects,key=lambda o:o.name):
  if ob.type!='LIGHT':continue
  d=ob.data
  lights.append(dict(name=ob.name,matrix=matrix(ob),type=d.type,color=list(d.color),energy=d.energy,
   size=getattr(d,'size',None),size_y=getattr(d,'size_y',None),angle=getattr(d,'angle',None),
   radius=getattr(d,'shadow_soft_size',None),nodes=p.s.material_state(d) if d.use_nodes else None))
 ground=sc.objects['HS2 display ground (non-canonical)']
 return dict(camera=dict(name=cam.name,matrix=matrix(cam),type=cam.data.type,lens=cam.data.lens,
  ortho_scale=cam.data.ortho_scale,shift_x=cam.data.shift_x,shift_y=cam.data.shift_y),
  lights=lights,world=p.s.material_state(sc.world),ground=p.s.material_state(ground.material_slots[0].material),
  view=dict(transform=sc.view_settings.view_transform,look=sc.view_settings.look,exposure=sc.view_settings.exposure,
   gamma=sc.view_settings.gamma,use_curve_mapping=sc.view_settings.use_curve_mapping),
  compositor=bool(sc.use_nodes))

def colour(t,fac,key,positions=(0,.5,1)):
 return f.ramp(t,fac,[(a,f.rgb(h)) for a,h in zip(positions,PALETTE[key])],'Reference only '+key)

def raw_gray(t,label):
 tex=f.raw(t,label)
 return f.gray(t,tex.outputs['Color'],'Reference detail mask only')

def reset_colour(old,key):
 m=old.copy();m.name='HS reference 3 '+key+' | '+old.name
 t=m.node_tree
 bs=next(n for n in p.live(t) if n.type=='BSDF_PRINCIPLED')
 # Clear the pigment input before rebuilding. No earlier graded RGB is used.
 for link in list(bs.inputs['Base Color'].links):t.links.remove(link)
 bs.inputs['Base Color'].default_value=(.18,.18,.18,1)
 seed=p.craft.illustration.member_value(t)
 geo=f.node(t,'ShaderNodeNewGeometry','Reference metric position')
 if key in f.PALETTES:
  if key=='endgrain':
   tex=next(n for n in t.nodes if n.type=='TEX_IMAGE' and n.image and 'endgrain' in n.label)
   g=f.gray(t,tex.outputs['Color'],'Reference end-cut mask only')
  else:g=raw_gray(t,'Craft authored wood detail')
  # The original image is used only as a scalar grain mask. Its old hue and
  # highlight multipliers cannot reach Base Color. Colours are bounded samples.
  member=f.scalar(t,'MULTIPLY',f.scalar(t,'SUBTRACT',seed,.5),.034,'Reference member offset')
  g=f.scalar(t,'ADD',g,member,'Reference grain and member mask')
  col=colour(t,g,key,(.012,.075,.255))
  if key!='endgrain':
   cut=f.node(t,'ShaderNodeAttribute','Reference actual end-cut mask');cut.attribute_name='P18 real cut face'
   cuttex=next((n for n in t.nodes if n.type=='TEX_IMAGE' and n.image and ('R6 original illustrated endgrain'==n.label or 'Original hand illustrated cut wood atlas'==n.label)),None)
   if cuttex:
    rings=f.gray(t,cuttex.outputs['Color'],'Reference preserved cut rings')
    cutcol=colour(t,rings,'endgrain',(.015,.075,.28))
    col=f.mix(t,col,cutcol,cut.outputs['Fac'],'Reference real cut pigment')
 elif key=='tile':
  # Keep broad charcoal bodies. Sampled brightest pixels are curvature light,
  # so base pigment uses the dark-to-mid section of the sampled ramp.
  fac=f.scalar(t,'ADD',.10,f.scalar(t,'MULTIPLY',seed,.24),'Reference fired body variation')
  col=colour(t,fac,'tile')
 elif key=='tile-end':col=colour(t,seed,key)
 elif key=='stone':
  mineral=f.noise(t,geo.outputs['Position'],7.0,2,'Reference stone minerals')
  fac=f.scalar(t,'ADD',f.scalar(t,'MULTIPLY',seed,.38),f.scalar(t,'MULTIPLY',mineral,.42),'Reference mineral and block variation')
  col=colour(t,fac,key)
 elif key=='plaster':
  h=f.noise(t,geo.outputs['Position'],28,2,'Reference plaster variation');col=colour(t,h,key)
 elif key=='paper':
  h=f.noise(t,geo.outputs['Position'],145,1.8,'Reference paper fibre colour');col=colour(t,h,key)
  if bs.inputs['Emission Strength'].default_value>0:
   for link in list(bs.inputs['Emission Color'].links):t.links.remove(link)
   bs.inputs['Emission Color'].default_value=f.rgb(PALETTE[key][1])
 else:raise ValueError(key)
 t.links.new(col,bs.inputs['Base Color'])
 keep=p.live(t)
 for n in list(t.nodes):
  if n not in keep:t.nodes.remove(n)
 m['referenceColourProfile']=key;m['referenceColourSha256']=S['sha256']
 m['referenceColourPolicy']='Old pigment disconnected; sampled RGB in bounded ramps; scalar source detail only'
 return m

def preserve_check():
 manifest=p.read(P/'RENDER_1_2_PRESERVATION.json')
 for folder,files in manifest['files'].items():
  for item in files:
   path=P/folder/item['file']
   assert path.stat().st_size==item['bytes'] and p.sha(path)==item['sha256'],str(path)
 return True

def main():
 D.mkdir(exist_ok=True)
 assert preserve_check();assert p.sha(S['reference'])==S['sha256']
 v=p.read(P/'sarang-material-rebuild-r2/verification.json');src=P/'sarang-material-rebuild-r2'/v['native']
 assert p.sha(src)==v['nativeSha256']
 bpy.ops.wm.open_mainfile(filepath=str(src));sc=bpy.context.scene
 lock=p.read(P/'sarang/geometry-lock.json');obs=[sc.objects[n] for n in lock['objects']]
 before=p.architecture(obs);assert before==v['geometry'];scene_before=fixed_scene(sc)
 binding=p.stage_map('sarang',obs);assert binding==p.read(P/'sarang/construction-binding.json')
 cache={};rows=[];protected={}
 for row in p.read(P/'sarang/material-inventory.json'):
  ob=sc.objects[row['object']];sl=ob.material_slots[row['slot']];old=sl.material
  if row['preserved'] or 'joint backings' in ob.name.lower() or row['role'] not in ('wood','lattice','endgrain','tile','tile-end','stone','plaster','paper'):
   protected[(ob.name,row['slot'])]=p.s.material_state(old);continue
  key=f.profile(row) if row['role'] in ('wood','lattice','endgrain') else row['role']
  ck=(old.name,key)
  if ck not in cache:cache[ck]=reset_colour(old,key)
  sl.link='OBJECT';sl.material=cache[ck]
  rows.append(dict(object=ob.name,slot=row['slot'],profile=key,material=sl.material.name))
  if len(rows)%100==0:print('REFERENCE COLOUR SLOTS',len(rows),flush=True)
 assert p.architecture(obs)==before
 assert fixed_scene(sc)==scene_before
 assert protected=={k:p.s.material_state(sc.objects[k[0]].material_slots[k[1]].material) for k in protected}
 sc.render.resolution_x=1800;sc.render.resolution_y=1200;sc.render.resolution_percentage=100
 sc.cycles.samples=96;sc.cycles.adaptive_threshold=.02;sc.cycles.adaptive_min_samples=16
 native=D/'sarang-reference-colour.blend';assert not native.exists()
 bpy.context.preferences.filepaths.save_version=0
 bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False)
 bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene;obs=[sc.objects[n] for n in lock['objects']]
 assert p.architecture(obs)==before;assert p.stage_map('sarang',obs)==binding
 assert fixed_scene(sc)==scene_before
 p.write(D/'fixed-render-state.json',scene_before)
 p.write(D/'colours.json',dict(reference=S,palettes=PALETTE,assignments=rows,counts=dict(Counter(r['profile'] for r in rows))))
 p.write(D/'verification.json',dict(passed=True,reopened=True,geometry=before,processBindingCount=len(binding),
  sameCameraLightsWorldGroundExposureAndToneMappingAsRender2=True,render1And2Preserved=preserve_check(),
  protectedMaterialsUnchanged=True,native=native.name,nativeSha256=p.sha(native),source=str(src),sourceSha256=v['nativeSha256'],
  changes='Base colour rebuilt from reference samples; paper emission hue only. No exposure or light strength changes.',
  userApproved=False,runtimeIntegrated=False))
 # First inspect a small native render; the saved file already holds final settings.
 sc.render.resolution_x=1200;sc.render.resolution_y=800
 result=p.render(sc,D,'preview.png',48);p.write(D/'preview.json',result)
 assert preserve_check()
 print('RENDER 3 COMPLETE; RENDER 1 AND 2 IDENTICAL',flush=True)

def resume_saved():
 native=D/'sarang-reference-colour.blend'
 v=p.read(P/'sarang-material-rebuild-r2/verification.json')
 src=P/'sarang-material-rebuild-r2'/v['native']
 assert p.sha(src)==v['nativeSha256'];assert preserve_check()
 bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene
 lock=p.read(P/'sarang/geometry-lock.json');obs=[sc.objects[n] for n in lock['objects']]
 assert p.architecture(obs)==v['geometry']
 binding=p.stage_map('sarang',obs);assert binding==p.read(P/'sarang/construction-binding.json')
 # JSON normalises tuple-valued links into lists.
 assert json.loads(json.dumps(fixed_scene(sc)))==p.read(D/'fixed-render-state.json')
 rows=[]
 for row in p.read(P/'sarang/material-inventory.json'):
  m=sc.objects[row['object']].material_slots[row['slot']].material
  if m.get('referenceColourProfile'):
   rows.append(dict(object=row['object'],slot=row['slot'],profile=m['referenceColourProfile'],material=m.name))
 p.write(D/'colours.json',dict(reference=S,palettes=PALETTE,assignments=rows,counts=dict(Counter(r['profile'] for r in rows))))
 p.write(D/'verification.json',dict(passed=True,reopened=True,geometry=v['geometry'],processBindingCount=len(binding),
  sameCameraLightsWorldGroundExposureAndToneMappingAsRender2=True,render1And2Preserved=preserve_check(),
  protectedMaterialsUnchanged=True,native=native.name,nativeSha256=p.sha(native),source=str(src),sourceSha256=v['nativeSha256'],
  changes='Base colour rebuilt from reference samples; paper emission hue only. No exposure or light strength changes.',
  userApproved=False,runtimeIntegrated=False))
 sc.render.resolution_x=1200;sc.render.resolution_y=800
 result=p.render(sc,D,'preview.png',48);p.write(D/'preview.json',result)
 assert preserve_check();print('RENDER 3 COMPLETE; RENDER 1 AND 2 IDENTICAL',flush=True)

if __name__=='__main__':
 if '--resume' in sys.argv:resume_saved()
 else:main()
