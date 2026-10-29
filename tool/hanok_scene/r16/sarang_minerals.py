"""Selective mineral planes and pores, preserving all native stone geometry."""
import sys
from pathlib import Path
OUT=Path(__file__).resolve().parent;sys.path.insert(0,str(OUT))
import sarang_calibrated as c
r=c.r;p=r.p
def material(old,role,usage):
 m=c.calibrated(old,role,usage)
 if role!='stone':return m
 t=m.node_tree
 seed=p.craft.illustration.member_value(t)
 mineral=p.r2.ramp(t,seed,[(.0,(.62,.56,.47,1)),(.4,(.84,.79,.69,1)),(1,(1.04,1.02,.98,1))],'HS7 existing stone mineral variation')
 geo=p.r2.node(t,'ShaderNodeNewGeometry','HS7 metric nondirectional mineral coordinates')
 broad=p.r2.node(t,'ShaderNodeTexNoise','HS7 calm irregular mineral planes');broad.inputs['Scale'].default_value=6;broad.inputs['Detail'].default_value=2
 t.links.new(geo.outputs['Position'],broad.inputs['Vector'])
 mineral_noise=p.r2.ramp(t,broad.outputs['Fac'],[(.25,(.66,.63,.58,1)),(.72,(1.06,1.04,1,1))],'HS7 broad warm mineral facets')
 fine=p.r2.node(t,'ShaderNodeTexNoise','HS7 selective stone pores');fine.inputs['Scale'].default_value=42;fine.inputs['Detail'].default_value=1.2;t.links.new(geo.outputs['Position'],fine.inputs['Vector'])
 pore=p.r2.ramp(t,fine.outputs['Fac'],[(.26,(.05,.05,.05,1)),(.38,(.65,.65,.65,1)),(.7,(.75,.75,.75,1))],'HS7 sparse small mineral depressions')
 for bs in [n for n in p.live(t) if n.type=='BSDF_PRINCIPLED']:
  col=p.value(bs.inputs['Base Color']);col=p.r2.mix(t,col,mineral,.65,'HS7 separate original stone bodies','MULTIPLY')
  col=p.r2.mix(t,col,mineral_noise,.40,'HS7 broad mineral planes over original stone maps','MULTIPLY');t.links.new(col,bs.inputs['Base Color'])
  bump=p.r2.node(t,'ShaderNodeBump','HS7 selective pore normal');bump.inputs['Strength'].default_value=.12;bump.inputs['Distance'].default_value=.009
  t.links.new(pore,bump.inputs['Height'])
  if bs.inputs['Normal'].is_linked:t.links.new(bs.inputs['Normal'].links[0].from_socket,bump.inputs['Normal'])
  t.links.new(bump.outputs['Normal'],bs.inputs['Normal'])
 return m
r.DEST=OUT/'sarang-r7';r.DEST.mkdir(exist_ok=True);r.material=material
r.build()
