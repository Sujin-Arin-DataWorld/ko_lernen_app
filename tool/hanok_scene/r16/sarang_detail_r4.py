"""Local wall, stone, tile and balustrade refinement of preserved render 3."""
import bpy,sys,json
from pathlib import Path
P=Path(__file__).resolve().parent;sys.path.insert(0,str(P))
import sarang_reference_colour_r3 as c
f=c.f;p=c.p;D=P/'sarang-detail-r4'
def palette(t,fac,colors,label):return f.ramp(t,fac,[(i/(len(colors)-1),f.rgb(v)) for i,v in enumerate(colors)],'R4 '+label)
def rail(row):
 n=row['object'].lower()
 return any(s in n for s in ('railing','v25.no4','no5 plain rail','numaru return rails')) or ('numaru lower' in n and 'closing rail' in n)
def material(old,kind):
 m=old.copy();m.name='HS detail4 '+kind+' | '+old.name;t=m.node_tree
 bs=next(n for n in p.live(t) if n.type=='BSDF_PRINCIPLED')
 seed=p.craft.illustration.member_value(t);geo=f.node(t,'ShaderNodeNewGeometry','R4 metric coordinates')
 if kind=='tile':
  # v2 retained clay variation and non-glossy firing. Restore full per-island
  # colour range instead of r3's compressed .10-.34 ramp interval.
  col=palette(t,seed,['252D38','303846','3C424C','4A4C50'],'individual cool charcoal and warm kiln tiles')
  tex=f.raw(t,'Craft authored tile detail');g=f.gray(t,tex.outputs['Color'],'R4 existing kiln grain')
  fine=palette(t,g,['8D8F91','B8B9B9','EEEEEE'],'quiet firing variation')
  col=f.mix(t,col,fine,.10,'R4 original clay texture','MULTIPLY')
  f.attach(t,bs.inputs['Roughness'],f.scalar(t,'ADD',.70,f.scalar(t,'MULTIPLY',seed,.12)))
  bs.inputs['Specular IOR Level'].default_value=.18
 elif kind=='stone':
  broad=f.noise(t,geo.outputs['Position'],9,2,'R4 stone mineral clouds')
  fine=f.noise(t,geo.outputs['Position'],110,2,'R4 small stone pores')
  col=palette(t,seed,['AD9F8B','BDAE97','CBBBA3','D6C7AF'],'stone bodies in related mineral tones')
  tint=f.ramp(t,broad,[(.18,(.82,.80,.77,1)),(.55,(1,1,1,1)),(.82,(1.04,1.03,1.01,1))],'R4 quiet mineral wash')
  col=f.mix(t,col,tint,.42,'R4 restrained stone mottling','MULTIPLY')
  pits=f.ramp(t,fine,[(.24,(.48,.42,.35,1)),(.33,(.73,.68,.60,1)),(.43,(1,1,1,1))],'R4 sparse mineral pinpoints')
  col=f.mix(t,col,pits,.38,'R4 small natural pores','MULTIPLY')
  col=f.contact(t,col,'stone')
  f.normal(t,bs,fine,.00065,.009,.12);f.attach(t,bs.inputs['Roughness'],.79)
 elif kind=='plaster':
  h=f.noise(t,geo.outputs['Position'],33,2,'R4 fine lime wall')
  col=palette(t,h,['C4B9A5','CFC5B3','D8CFBE'],'warm ivory wall surface')
  f.normal(t,bs,h,.00025,.002,.10)
 elif kind=='paper':
  h=f.noise(t,geo.outputs['Position'],140,2,'R4 quiet paper fibres')
  col=palette(t,h,['D8C6A4','E5D6B9','EEDFC3'],'ivory paper')
  if bs.inputs['Emission Strength'].default_value>0:
   for link in list(bs.inputs['Emission Color'].links):t.links.remove(link)
   bs.inputs['Emission Color'].default_value=f.rgb('FFE0A4')
 elif kind=='rail':
  tex=next((n for n in t.nodes if n.type=='TEX_IMAGE' and n.label=='Craft authored wood detail'),None)
  g=f.gray(t,tex.outputs['Color'],'R4 original rail growth') if tex else seed
  jitter=f.scalar(t,'MULTIPLY',f.scalar(t,'SUBTRACT',seed,.5),.018)
  g=f.scalar(t,'ADD',g,jitter)
  col=f.ramp(t,g,[(.012,f.rgb('63320F')),(.075,f.rgb('9F5420')),(.255,f.rgb('BE7732'))],'R4 shared maru and numaru timber')
  col=f.contact(t,col,'wood')
  f.attach(t,bs.inputs['Roughness'],.56);bs.inputs['Specular IOR Level'].default_value=.28
 else:raise ValueError(kind)
 t.links.new(col,bs.inputs['Base Color'])
 keep=p.live(t)
 for n in list(t.nodes):
  if n not in keep:t.nodes.remove(n)
 m['detail4']=kind
 return m
def main():
 D.mkdir(exist_ok=True)
 v=p.read(P/'sarang-reference-colour-r3/verification.json');src=P/'sarang-reference-colour-r3'/v['native'];assert p.sha(src)==v['nativeSha256']
 bpy.ops.wm.open_mainfile(filepath=str(src));sc=bpy.context.scene
 lock=p.read(P/'sarang/geometry-lock.json');obs=[sc.objects[n] for n in lock['objects']]
 before=p.architecture(obs);assert before==v['geometry'];lighting=c.fixed_scene(sc)
 cache={};report=[];unchanged={}
 for row in p.read(P/'sarang/material-inventory.json'):
  ob=sc.objects[row['object']];sl=ob.material_slots[row['slot']]
  kind='rail' if rail(row) and row['role'] in ('wood','lattice') else row['role']
  if row['preserved'] or kind not in ('rail','tile','stone','plaster','paper'):
   unchanged[(ob.name,row['slot'])]=p.s.material_state(sl.material);continue
  key=(sl.material.name,kind)
  if key not in cache:cache[key]=material(sl.material,kind)
  sl.link='OBJECT';sl.material=cache[key];report.append(dict(object=ob.name,slot=row['slot'],kind=kind))
 assert p.architecture(obs)==before;assert c.fixed_scene(sc)==lighting
 assert unchanged=={k:p.s.material_state(sc.objects[k[0]].material_slots[k[1]].material) for k in unchanged}
 assert p.stage_map('sarang',obs)==p.read(P/'sarang/construction-binding.json')
 sc.render.resolution_x=1800;sc.render.resolution_y=1200;sc.cycles.samples=96
 bpy.context.preferences.filepaths.save_version=0
 native=D/'sarang-detail-r4.blend';assert not native.exists()
 bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False)
 bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene
 assert p.architecture([sc.objects[n] for n in lock['objects']])==before;assert c.fixed_scene(sc)==lighting
 p.write(D/'verification.json',dict(geometry=before,reopened=True,fixedCameraLightingExposure=True,otherMaterialsUnchanged=True,processBindingCount=711,
  source=str(src),sourceSha256=v['nativeSha256'],native=native.name,nativeSha256=p.sha(native),render1And2Preserved=c.preserve_check(),changes=report,userApproved=False,runtimeIntegrated=False))
 sc.render.resolution_x=1200;sc.render.resolution_y=800
 p.write(D/'preview.json',p.render(sc,D,'preview.png',48))
 assert p.sha(src)==v['nativeSha256'];assert c.preserve_check()
 print('DETAIL R4 PREVIEW VERIFIED',flush=True)
if __name__=='__main__':main()
