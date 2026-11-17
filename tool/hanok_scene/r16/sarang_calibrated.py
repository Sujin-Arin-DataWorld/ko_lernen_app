"""Reference-calibrated result after the direct SPEC material comparison."""
import sys
from pathlib import Path
OUT=Path(__file__).resolve().parent;sys.path.insert(0,str(OUT))
import refine_sarang as r
original=r.material
def calibrated(old,role,usage):
 m=original(old,role,usage);t=m.node_tree
 for n in t.nodes:
  if n.label=='R3 golden amber pigment through preserved longitudinal grain':n.inputs[2].default_value=(.90,.76,.53,1)
  if n.label=='R3 slate body, less blue and lower value':n.inputs[2].default_value=(1.15,.90,.76,1)
 for bs in [n for n in r.p.live(t) if n.type=='BSDF_PRINCIPLED']:
  if role in ('wood','lattice','endgrain'):bs.inputs['Sheen Weight'].default_value=.10
  if role=='tile':bs.inputs['Sheen Weight'].default_value=.10
 m['hs6_calibration']='Retain source detail; match warm timber and neutral charcoal; avoid excessive sheen from literal SPEC.'
 return m
if __name__=='__main__':
 r.DEST=OUT/'sarang-r6';r.DEST.mkdir(exist_ok=True);r.material=calibrated
 r.build()
