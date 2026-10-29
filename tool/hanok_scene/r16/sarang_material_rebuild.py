"""Clean material construction on frozen Sarang geometry; native Cycles output."""
import bpy, sys, json, math, hashlib
from pathlib import Path
from collections import Counter
import numpy as np
P=Path(__file__).resolve().parent
sys.path.insert(0,str(P))
import produce as p
import refine_sarang as ref
from sarang_wood import profile

D=P/'sarang-material-rebuild-r1'
PALETTES={
 'column':('AE6E32','BE833F','CE9653',1.06,.55),
 'beam':('985B28','B17434','BE8746',.95,.60),
 'gable':('BE8544','CE9654','D6A160',.84,.63),
 'rafter':('AF7437','C28B46','D09B59',.72,.65),
 'endgrain':('BA8B50','D0A566','DEBA82',.64,.72),
 'floor':('A7682D','BB7B36','CD8E46',1.08,.43),
 'railing':('B77C38','C99047','D7A360',.88,.46),
 'apron':('A96F32','C18A45','D09D59',1.18,.60),
 'lower_board':('A66B2E','BE8540','D3A05C',1.30,.62),
 'door_panel':('A26930','B7803D','CB9650',1.05,.57),
 'frame':('995F2B','B37736','C48D48',.82,.53),
 'lattice':('B57C3A','CA9249','D9A75F',.54,.57),
}
MEAN={}

def node(t,kind,label):return p.r2.node(t,kind,'Fresh '+label)
def scalar(t,op,a,b,label=''):return p.ext.scalar(t,op,a,b,'Fresh '+label)
def ramp(t,s,stops,label):return p.r2.ramp(t,s,stops,'Fresh '+label)
def mix(t,a,b,f,label,mode='MIX'):
 n=node(t,'ShaderNodeMixRGB',label);n.blend_type=mode
 attach(t,n.inputs[0],f)
 for sock,value in [(n.inputs[1],a),(n.inputs[2],b)]:
  attach(t,sock,(value,value,value,1) if isinstance(value,(float,int)) else value)
 return n.outputs[0]
def rgb(h):return ref.rgb(h)
def attach(t,sock,val):
 if hasattr(val,'node'):t.links.new(val,sock)
 else:sock.default_value=val
def gray(t,s,label):
 n=node(t,'ShaderNodeRGBToBW',label);t.links.new(s,n.inputs[0]);return n.outputs[0]
def noise(t,co,scale,detail,label):
 n=node(t,'ShaderNodeTexNoise',label);t.links.new(co,n.inputs['Vector']);n.inputs['Scale'].default_value=scale;n.inputs['Detail'].default_value=detail
 return n.outputs['Fac']
def raw(t,label):return next(n for n in t.nodes if n.type=='TEX_IMAGE' and n.label==label)
def image_mean(im,panel=None):
 key=(im.name,panel)
 if key in MEAN:return MEAN[key]
 a=np.empty(len(im.pixels),np.float32);im.pixels.foreach_get(a);w,h=im.size;a=a.reshape(h,w,4)[...,:3]
 if panel:
  x,y={'wood':(0,.5),'endgrain':(.5,.5),'stone':(0,0),'tile':(.5,0)}[panel]
  a=a[int(h*(y+.04)):int(h*(y+.46)),int(w*(x+.04)):int(w*(x+.46))]
 if im.colorspace_settings.name=='sRGB':a=np.where(a<=.04045,a/12.92,((a+.055)/1.055)**2.4)
 ans=float((a@np.array([.2126,.7152,.0722])).mean());MEAN[key]=ans;return ans
def ratio(t,tex,mean,power,label):
 g=gray(t,tex.outputs['Color'],label+' raw luminance')
 z=scalar(t,'DIVIDE',g,max(mean,.001),label+' mean normalisation')
 z=scalar(t,'POWER',z,power,label+' independent grain contrast')
 return scalar(t,'MINIMUM',scalar(t,'MAXIMUM',z,.20),2.0,label+' retained dark and light fibres'),g
def contact(t,col,role):
 ao=node(t,'ShaderNodeAmbientOcclusion','local join contact');ao.samples=8
 ao.inputs['Distance'].default_value={'wood':.08,'lattice':.025,'tile':.07,'stone':.09}.get(role,.04)
 shadow=(.52,.37,.25,1) if role in ('wood','lattice') else (.53,.57,.64,1) if role=='tile' else (.60,.54,.46,1)
 mult=ramp(t,ao.outputs['AO'],[(.05,shadow),(.88,(1,1,1,1))],'short coloured contact')
 return mix(t,col,mult,.34,'contact depth','MULTIPLY')
def normal(t,bs,height,dist,edge,strength=.15):
 bump=node(t,'ShaderNodeBump','material microrelief');bump.inputs['Strength'].default_value=strength;bump.inputs['Distance'].default_value=dist;t.links.new(height,bump.inputs['Height'])
 bevel=node(t,'ShaderNodeBevel','shading edge only');bevel.samples=4;bevel.inputs['Radius'].default_value=edge;t.links.new(bump.outputs['Normal'],bevel.inputs['Normal']);t.links.new(bevel.outputs['Normal'],bs.inputs['Normal'])
def finish(t,bs,col,rough,spec=.32):
 attach(t,bs.inputs['Base Color'],col);attach(t,bs.inputs['Roughness'],rough)
 bs.inputs['Specular IOR Level'].default_value=spec;bs.inputs['Sheen Weight'].default_value=0;bs.inputs['Metallic'].default_value=0

def material(old,row):
 role=row['role'];key=profile(row) if role in ('wood','lattice','endgrain') else role
 m=old.copy();m.name='HS fresh '+key+' | '+old.name;m['freshMaterialProfile']=key
 t=m.node_tree
 # Reuse only surface-attached source coordinates and ungraded texture pixels.
 # Replacing the surface root bypasses every earlier pigment correction.
 bs=node(t,'ShaderNodeBsdfPrincipled','independent material surface')
 output=next(n for n in t.nodes if n.type=='OUTPUT_MATERIAL' and n.is_active_output)
 t.links.new(bs.outputs['BSDF'],output.inputs['Surface'])
 seed=p.craft.illustration.member_value(t)
 geo=node(t,'ShaderNodeNewGeometry','metric surface coordinates')
 if role in ('wood','lattice','endgrain'):
  a,b,c,power,rough=PALETTES[key]
  base=ramp(t,seed,[(0,rgb(a)),(.5,rgb(b)),(1,rgb(c))],key+' member pigment')
  cuttex=next(n for n in t.nodes if n.type=='TEX_IMAGE' and n.image and ('R6 original illustrated endgrain'==n.label or 'Original hand illustrated cut wood atlas'==n.label))
  rings,ringheight=ratio(t,cuttex,image_mean(cuttex.image),.65,'original end grain')
  cutcolor=mix(t,rgb('C99B59'),rings,1,'end grain pigment','MULTIPLY')
  if role=='endgrain':col=mix(t,base,rings,1,'cut growth','MULTIPLY');height=ringheight
  else:
   tex=raw(t,'Craft authored wood detail')
   growth,height=ratio(t,tex,image_mean(tex.image,'wood'),power,key+' growth')
   col=mix(t,base,growth,1,'pigment with independent original growth','MULTIPLY')
   cut=node(t,'ShaderNodeAttribute','preserved actual cut faces');cut.attribute_name='P18 real cut face'
   col=mix(t,col,cutcolor,cut.outputs['Fac'],'existing end cuts')
   height=mix(t,height,ringheight,cut.outputs['Fac'],'side and cut relief')
  col=contact(t,col,'lattice' if role=='lattice' else 'wood')
  rr=scalar(t,'ADD',rough,scalar(t,'MULTIPLY',height,.075),'grain-scale roughness')
  finish(t,bs,col,rr,.32 if key in ('floor','railing') else .29)
  normal(t,bs,height,.0013 if key in ('lower_board','apron') else .0007,.0018 if role=='lattice' else .0045,.22)
 elif role=='tile':
  tex=raw(t,'Craft authored tile detail');gr,h=ratio(t,tex,image_mean(tex.image,'tile'),.25,'firing surface')
  col=ramp(t,seed,[(0,rgb('293441')),(.5,rgb('34404E')),(1,rgb('424C57'))],'clay body per original island')
  col=mix(t,col,gr,.32,'quiet kiln colour','MULTIPLY');col=contact(t,col,'tile')
  rr=scalar(t,'ADD',.64,scalar(t,'MULTIPLY',seed,.10),'fired clay roughness')
  finish(t,bs,col,rr,.28);normal(t,bs,h,.00035,.0020,.10)
 elif role=='tile-end':
  h=noise(t,geo.outputs['Position'],35,1.2,'clay grain')
  col=ramp(t,seed,[(0,rgb('BFB6A3')),(.6,rgb('D8CDB8')),(1,rgb('E4D9C4'))],'existing cream ends')
  finish(t,bs,contact(t,col,'stone'),.82,.20);normal(t,bs,h,.0003,.002,.1)
 elif role=='stone':
  broad=noise(t,geo.outputs['Position'],5.8,2,'mineral patches');fine=noise(t,geo.outputs['Position'],88,1.5,'fine mineral pores')
  col=ramp(t,seed,[(0,rgb('AEA18D')),(.5,rgb('C8BBA4')),(1,rgb('DED1B9'))],'individual original stone bodies')
  patches=ramp(t,broad,[(.20,(.69,.70,.72,1)),(.55,(1,1,1,1)),(.78,(1.08,1.04,.96,1))],'stone mineral temperature')
  col=mix(t,col,patches,.55,'sparse broad mineral variation','MULTIPLY')
  pores=ramp(t,fine,[(.23,(.16,.16,.16,1)),(.34,(.8,.8,.8,1)),(.43,(1,1,1,1))],'selected small pores')
  col=mix(t,col,pores,.22,'selective pore pigment','MULTIPLY')
  finish(t,bs,contact(t,col,'stone'),.82,.25);normal(t,bs,pores,.0025,.012,.18)
 elif role=='plaster':
  h=noise(t,geo.outputs['Position'],28,2,'quiet lime plaster');col=ramp(t,h,[(.15,rgb('D6CDBD')),(.85,rgb('E9E2D5'))],'plaster low contrast')
  finish(t,bs,col,.90,.18);normal(t,bs,h,.0007,.002,.10)
 elif role=='paper':
  h=noise(t,geo.outputs['Position'],145,1.8,'hanji fibres');col=ramp(t,h,[(.15,rgb('D8CBAE')),(.85,rgb('EEE4CA'))],'paper fibres')
  window='hanji backing' in row['object'].lower() or '.paper' in row['object'].lower() or row['usage']=='window-paper'
  if window:
   ao=node(t,'ShaderNodeAmbientOcclusion','real paper lattice distance');ao.samples=8;ao.inputs['Distance'].default_value=.09
   glow=ramp(t,ao.outputs['AO'],[(0,rgb('C76E29')),(.42,rgb('F2BA64')),(.84,rgb('FFF1C9'))],'local warm paper light')
   t.links.new(glow,bs.inputs['Emission Color']);bs.inputs['Emission Strength'].default_value=1.15
  finish(t,bs,col,.92,.16);normal(t,bs,h,.00012,.001,.08)
 else:return old
 # Discard unreachable old correction nodes in this new material only.
 keep=p.live(t)
 for n in list(t.nodes):
  if n not in keep:t.nodes.remove(n)
 m['sourceMode']='ungraded source textures plus new independent colour and BRDF'
 return m

def build():
 D.mkdir(exist_ok=True)
 v=p.read(P/'sarang-r7/verification.json');src=P/'sarang-r7'/v['native'];assert p.sha(src)==v['nativeSha256']
 bpy.ops.wm.open_mainfile(filepath=str(src));sc=bpy.context.scene
 lock=p.read(P/'sarang/geometry-lock.json');obs=[sc.objects[n] for n in lock['objects']]
 before=p.architecture(obs);assert before==v['geometry'];binding=p.stage_map('sarang',obs);assert binding==p.read(P/'sarang/construction-binding.json')
 protected={};cache={};report=[]
 for row in p.read(P/'sarang/material-inventory.json'):
  ob=sc.objects[row['object']];slot=ob.material_slots[row['slot']]
  if row['preserved'] or 'joint backings' in ob.name.lower() or row['role'] not in ('wood','lattice','endgrain','tile','tile-end','stone','plaster','paper'):
   protected[(ob.name,row['slot'])]=p.s.material_state(slot.material);continue
  key=profile(row) if row['role'] in ('wood','lattice','endgrain') else row['role']
  ck=(slot.material.name,key,row['usage'])
  if ck not in cache:
   cache[ck]=material(slot.material,row)
   if len(cache)%30==0:print('MATERIALS',len(cache),row['object'],flush=True)
  slot.link='OBJECT';slot.material=cache[ck];report.append(dict(object=ob.name,slot=row['slot'],profile=key,material=slot.material.name))
 assert p.architecture(obs)==before
 assert protected=={(n,i):p.s.material_state(sc.objects[n].material_slots[i].material) for n,i in protected}
 sc.render.resolution_x=1200;sc.render.resolution_y=800;sc.render.resolution_percentage=100
 sc.cycles.use_adaptive_sampling=True;sc.cycles.adaptive_threshold=.035;sc.cycles.adaptive_min_samples=8;sc.cycles.use_denoising=True
 sc.render.threads_mode='FIXED';sc.render.threads=12
 native=D/'sarang-material-rebuild.blend';assert not native.exists()
 bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(native),compress=True,relative_remap=False)
 bpy.ops.wm.open_mainfile(filepath=str(native));sc=bpy.context.scene;obs=[sc.objects[n] for n in lock['objects']]
 assert p.architecture(obs)==before;assert p.stage_map('sarang',obs)==binding
 p.write(D/'verification.json',dict(passed=True,reopened=True,native=native.name,nativeSha256=p.sha(native),geometry=before,source=str(src),sourceSha256=v['nativeSha256'],canonicalSource=lock['source'],sameCamera=True,sameLightingAsR7=True,processBindingCount=len(binding),protectedMaterialsUnchanged=True,userApproved=False,runtimeIntegrated=False))
 p.write(D/'material-profiles.json',dict(palettes=PALETTES,assignments=report,counts=dict(Counter(r['profile'] for r in report)),sourceMeans={str(k):v for k,v in MEAN.items()}))
 result=p.render(sc,D,'preview.png',48);p.write(D/'preview.json',result)
 print('FRESH MATERIAL PREVIEW COMPLETE',flush=True)

if __name__=='__main__':build()
