"""Sarang R8: member-specific light timber. Geometry and lighting stay fixed."""
import bpy,sys,hashlib
from pathlib import Path
from collections import Counter
OUT=Path(__file__).resolve().parent;sys.path.insert(0,str(OUT))
import refine_sarang as r
p=r.p
DEST=OUT/'sarang-r8'
# All colours describe pigment, not baked directional lighting.
PROFILES={
 'column': ('99602E','C69351','E7BB7C',.71,.18),
 'beam': ('965B2A','BB8446','DDAE6C',.77,.14),
 'gable': ('B38243','D8AC68','EECF94',.77,.15),
 'rafter': ('A57335','CEA05B','E7C584',.78,.15),
 'endgrain': ('B48B4A','DEC180','F0DBAC',.84,.12),
 'floor': ('A46B33','CF9C59','E5BB7E',.60,.24),
 'railing': ('A77339','D2A461','EBC78A',.63,.22),
 'apron': ('AB7B43','CDA266','E6C38C',.78,.16),
 'lower_board': ('A6743C','C79656','E1B777',.81,.14),
 'door_panel': ('A26F37','BF8D4C','DBAF70',.76,.17),
 'frame': ('8F5729','B68142','D5A35F',.70,.18),
 'lattice': ('B07D3E','D1A25E','E6C283',.71,.17),
}
def profile(row):
 n=row['object'].lower();role=row['role']
 if role=='endgrain' or 'end grain' in n:return 'endgrain'
 if 'gable' in n:return 'gable'
 if any(s in n for s in ('railing','v25.no4','return rails','no5 plain rail','no5 stile')):return 'railing'
 if n.startswith('enclosure.numaru lower'):return 'lower_board'
 if any(s in n for s in ('apron','left horizontal boarding','left boarding continuous')):return 'apron'
 if role=='lattice':return 'lattice'
 if 'recessed lower board' in n or row['usage']=='board-door':return 'door_panel'
 if row['usage']=='floor-plank' or any(s in n for s in ('connector maru','gallery floor','wing room subfloor','entrance maru','maru extension','maru front extension','maru side extension','maru clipped corner','maru return end board')):return 'floor'
 if 'rafter' in n or 'underside' in n or 'bedding board' in n:return 'rafter'
 if any(s in n for s in ('continuous post','corner posts','post.wood','hwaljufix')):return 'column'
 if any(s in n for s in ('.leaf','head/sill','jamb','wall frame','horizontal frame','door threshold')):return 'frame'
 return 'beam'

def timber(old,key,role):
 m=old.copy();m.name='HS8 '+key+' | '+old.name
 m['hs8_profile']=key;m['hs8_source']='member palettes; original grain and stable island variation'
 t=m.node_tree
 # The input of this earlier multiply is the ungraded R2 original wood,
 # including the original UV texture, grain direction, knots and member IDs.
 source=next(n for n in t.nodes if n.label=='R3 golden amber pigment through preserved longitudinal grain')
 original=p.value(source.inputs[1])
 bw=p.r2.node(t,'ShaderNodeRGBToBW','R8 original directional grain luminance');t.links.new(original,bw.inputs[0])
 seed=p.craft.illustration.member_value(t)
 spread=.24 if key in ('floor','lower_board','apron') else .16
 shift=p.ext.scalar(t,'SUBTRACT',seed,.5,'R8 member-centred variation')
 shift=p.ext.scalar(t,'MULTIPLY',shift,spread*2,'R8 restrained per-board value range')
 grain=p.ext.scalar(t,'MULTIPLY',bw.outputs[0],2.1,'R8 retain original broad and fine grain')
 grain=p.ext.scalar(t,'ADD',grain,shift,'R8 individual board plus grain')
 dark,mid,light,rough,spec=PROFILES[key]
 col=p.r2.ramp(t,grain,[(.00,r.rgb(dark)),(.43,r.rgb(mid)),(.94,r.rgb(light))],'R8 '+key+' light natural timber pigment')
 # Small pigment-temperature shifts are constant on a member, not pixel noise.
 warmth=p.r2.ramp(t,seed,[(0,(.98,1.025,1.08,1)),(.5,(1,1,1,1)),(1,(1.025,.985,.94,1))],'R8 member honey to sand pigment variation')
 col=p.r2.mix(t,col,warmth,.75,'R8 individual timber colour temperature','MULTIPLY')
 col=r.cavity(t,col,'lattice' if role=='lattice' else 'wood')
 for bs in [n for n in p.live(t) if n.type=='BSDF_PRINCIPLED']:
  t.links.new(col,bs.inputs['Base Color'])
  # A touched rail/floor reflects differently to a sawn board or end cut.
  rr=p.ext.scalar(t,'MULTIPLY',bw.outputs[0],.10,'R8 grain-scale finish variation')
  rr=p.ext.scalar(t,'ADD',rr,rough-.025,'R8 '+key+' finish')
  t.links.new(rr,bs.inputs['Roughness']);bs.inputs['Specular IOR Level'].default_value=spec
  bs.inputs['Sheen Weight'].default_value=.08;bs.inputs['Sheen Tint'].default_value=r.rgb('E9C994')
 return m

def main():
 DEST.mkdir(exist_ok=True)
 v=p.read(OUT/'sarang-r7/verification.json');src=OUT/'sarang-r7'/v['native'];assert p.sha(src)==v['nativeSha256']
 bpy.ops.wm.open_mainfile(filepath=str(src));scene=bpy.context.scene
 lock=p.read(OUT/'sarang/geometry-lock.json');obs=[scene.objects[n] for n in lock['objects']]
 before=p.architecture(obs);assert before==v['geometry']
 stages=p.stage_map('sarang',obs);assert stages==p.read(OUT/'sarang/construction-binding.json')
 rows=p.read(OUT/'sarang/material-inventory.json');cache={};report=[];untouched={}
 for row in rows:
  ob=scene.objects[row['object']];slot=ob.material_slots[row['slot']]
  if row['preserved'] or row['role'] not in ('wood','lattice','endgrain'):
   untouched[(ob.name,row['slot'])]=p.s.material_state(slot.material);continue
  key=profile(row);ck=(slot.material.name,key)
  if ck not in cache:cache[ck]=timber(slot.material,key,row['role'])
  slot.link='OBJECT';slot.material=cache[ck]
  report.append(dict(object=ob.name,slot=row['slot'],profile=key,material=slot.material.name,palette=PROFILES[key][:3]))
 assert before==p.architecture(obs)
 assert untouched=={k:p.s.material_state(scene.objects[k[0]].material_slots[k[1]].material) for k in untouched}
 native=DEST/'sarang-r8.blend';assert not native.exists()
 bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False)
 bpy.ops.wm.open_mainfile(filepath=str(native));scene=bpy.context.scene;obs=[scene.objects[n] for n in lock['objects']]
 assert p.architecture(obs)==before;assert p.stage_map('sarang',obs)==stages
 p.write(DEST/'verification.json',dict(passed=True,reopened=True,native=native.name,nativeSha256=p.sha(native),geometry=before,
  sourceNative=str(src),sourceSha256=v['nativeSha256'],sameCamera=True,sameLighting=True,onlyWoodEdited=True,
  originalGeometryUVNormalsAndProcessBindingUnchanged=True,userApproved=False,runtimeIntegrated=False))
 p.write(DEST/'wood-profiles.json',dict(profiles=PROFILES,assignments=report,slotCounts=dict(Counter(x['profile'] for x in report))))
 scene.render.resolution_x=1200;scene.render.resolution_y=800
 result=p.render(scene,DEST,'preview.png',32);p.write(DEST/'preview.json',result)
 assert p.sha(src)==v['nativeSha256']
 print('R8 WOOD VERIFIED',dict(Counter(x['profile'] for x in report)),flush=True)
if __name__=='__main__':main()
