"""Direct SPEC palette/BRDF study with canonical member grain and topology."""
import bpy,sys
from pathlib import Path
OUT=Path(__file__).resolve().parent;sys.path.insert(0,str(OUT))
import refine_sarang as r
p=r.p
SPEC={
 'wood':dict(colors=['7A3E14','B86B28','D4893B'],rough=.85,spec=.15,sheen=.6,tint='FFCF8B',bevel=.025),
 'lattice':dict(colors=['7A3E14','B86B28','D4893B'],rough=.85,spec=.15,sheen=.6,tint='FFCF8B',bevel=.002),
 'endgrain':dict(colors=['7A3E14','B86B28','D4893B'],rough=.85,spec=.15,sheen=.4,tint='FFCF8B',bevel=.006),
 'tile':dict(colors=['1C2530','2A3746','3D4E61'],rough=.82,spec=.2,sheen=.5,tint='B8D4F0',bevel=.02),
 'tile-end':dict(colors=['C9BFA8','E5DEC9','F5F0E1'],rough=.92,spec=.05,sheen=.8,tint='FFFFFF',bevel=.015),
 'stone':dict(colors=['9E8E78','C2B097','D9CBB5'],rough=.90,spec=.1,sheen=0,tint='FFFFFF',bevel=.035),
 'plaster':dict(colors=['D8CEBE','EAE2D3','F4EFE6'],rough=.95,spec=.05,sheen=.7,tint='FFFFFF',bevel=.008),
}
old_method=r.material
def master(old,role,usage):
 if role not in SPEC:return old_method(old,role,usage)
 m=old.copy();m.name='HS5 '+role+' | '+old.name;m['hs5_spec']='Direct Gemini material palette / original grain retained'
 t=m.node_tree;cfg=SPEC[role];active=p.live(t)
 for n in active:
  if n.type=='BUMP':n.inputs['Strength'].default_value*=.12 if role in ('tile','stone') else .5
 for bs in [n for n in active if n.type=='BSDF_PRINCIPLED']:
  original=p.value(bs.inputs['Base Color'])
  gray=p.r2.node(t,'ShaderNodeRGBToBW','HS5 original material detail luminance');t.links.new(original,gray.inputs[0])
  seed=p.craft.illustration.member_value(t)
  if role in ('wood','lattice','endgrain'):
   # Read the intact longitudinal/end-grain signal. Colour it in the provided
   # SPEC palette without replacing UVs or putting world noise across fibres.
   signal=p.ext.scalar(t,'MULTIPLY',gray.outputs[0],2.1)
   body=p.r2.ramp(t,signal,[(.01,r.rgb(cfg['colors'][0])),(.38,r.rgb(cfg['colors'][1])),(.82,r.rgb(cfg['colors'][2]))],'HS5 SPEC warm timber palette over original grain')
   jitter=p.ext.scalar(t,'ADD',p.ext.scalar(t,'MULTIPLY',seed,.14),.93)
   body=p.r2.mix(t,body,jitter,1,'HS5 subtle stable member value','MULTIPLY')
  else:
   body=p.r2.ramp(t,seed,[(0,r.rgb(cfg['colors'][0])),(.5,r.rgb(cfg['colors'][1])),(1,r.rgb(cfg['colors'][2]))],'HS5 SPEC broad mineral/ceramic palette')
   detail=p.ext.scalar(t,'ADD',p.ext.scalar(t,'MULTIPLY',gray.outputs[0],.16),.92)
   body=p.r2.mix(t,body,detail,1,'HS5 quiet retained original microtexture','MULTIPLY')
  if role in ('wood','lattice','tile','tile-end','stone'):body=r.cavity(t,body,role)
  t.links.new(body,bs.inputs['Base Color'])
  r.setval(t,bs.inputs['Roughness'],cfg['rough']);bs.inputs['Specular IOR Level'].default_value=cfg['spec']
  bs.inputs['Sheen Weight'].default_value=cfg['sheen'];bs.inputs['Sheen Roughness'].default_value=.5;bs.inputs['Sheen Tint'].default_value=r.rgb(cfg['tint'])
  bevel=p.r2.node(t,'ShaderNodeBevel','HS5 SPEC shading bevel, no geometry modifier');bevel.samples=8;bevel.inputs['Radius'].default_value=cfg['bevel']
  if bs.inputs['Normal'].is_linked:t.links.new(bs.inputs['Normal'].links[0].from_socket,bevel.inputs['Normal'])
  t.links.new(bevel.outputs['Normal'],bs.inputs['Normal'])
 return m
r.DEST=OUT/'sarang-r5';r.DEST.mkdir(exist_ok=True)
r.material=master
r.build()
p.write(r.DEST/'applied-spec.json',SPEC)
