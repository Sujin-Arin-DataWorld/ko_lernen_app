"""Role-specific amber/brown balance and selective existing knot definition."""
import bpy
from wood_individual_r14 import node,math,attach
GAINS={
 'column':(.97,1.06,1.30),'beam':(.96,1.08,1.32),
 'floor':(.86,1.16,1.90),'gable':(.94,1.12,1.55),
 'apron':(.96,1.10,1.42),'lower_board':(.96,1.10,1.42),
 'railing':(.98,1.07,1.20),'frame':(.97,1.08,1.32),
 'door_panel':(.96,1.10,1.36),'lattice':(.98,1.06,1.24),
 'rafter':(.97,1.08,1.32),'endgrain':(.97,1.08,1.30)}

def apply(sc):
 import sarang_reference_colour_r3 as c
 cache={};rows=[];protected={}
 for ob in sc.objects:
  if ob.type!='MESH' or ob.hide_render:continue
  used={p.material_index for p in ob.data.polygons}
  for i,sl in enumerate(ob.material_slots):
   old=sl.material
   if i not in used or not old or not old.get('hs14_individual_wood'):continue
   family=old.get('referenceColourProfile')
   if family not in GAINS:continue
   if old.as_pointer() not in cache:
    protected[old]=c.p.s.material_state(old)
    m=old.copy();m.name='HS16 '+family+' master | '+old.name;t=m.node_tree
    gain=GAINS[family]
    for n in t.nodes:
     if n.type=='MIX_RGB' and n.label.startswith('HS13 reference sampled '):
      rgb=n.inputs[2].default_value
      n.inputs[2].default_value=tuple(rgb[j]*gain[j] for j in range(3))+(1,)
     if family in ('column','beam','lower_board','apron','gable'):
      if n.label=='HS14 crop width':n.inputs[1].default_value=.45
      elif n.label=='HS14 crop width span':n.inputs[1].default_value=.55
      elif n.label=='HS14 crop length':n.inputs[1].default_value=.70
      elif n.label=='HS14 crop length span':n.inputs[1].default_value=.30
    if family in ('column','beam','lower_board','apron','gable'):
     tex=next(n for n in c.p.live(t) if n.type=='TEX_IMAGE' and n.label=='Craft authored wood detail')
     gray=node(t,'ShaderNodeRGBToBW','HS16 existing knot and surrounding growth')
     t.links.new(tex.outputs['Color'],gray.inputs[0])
     seed=next(n.outputs['Value'] for n in t.nodes if n.type=='TEX_WHITE_NOISE' and n.label=='Illustration constant pigment per member, not surface noise')
     rare=math(t,'GREATER_THAN',seed,.76,'HS16 sparse member growth accents')
     tail=math(t,'MAXIMUM',math(t,'SUBTRACT',.055,gray.outputs[0],'HS16 original dark knot tail'),0.,'HS16 existing dark growth only')
     tail=math(t,'MINIMUM',math(t,'MULTIPLY',tail,8.,'HS16 bounded existing knot depth'),.23,'HS16 maximum knot accent')
     factor=math(t,'SUBTRACT',1.,math(t,'MULTIPLY',tail,rare,'HS16 sparse knot strength'),'HS16 retain natural growth body')
     for bs in [n for n in c.p.live(t) if n.type=='BSDF_PRINCIPLED']:
      socket=bs.inputs['Base Color'];source=socket.links[0].from_socket
      mul=node(t,'ShaderNodeMixRGB','HS16 original knot definition');mul.blend_type='MULTIPLY';mul.inputs[0].default_value=1.
      t.links.new(source,mul.inputs[1]);t.links.new(factor,mul.inputs[2]);t.links.new(mul.outputs[0],socket)
    m['hs16_master_role']=family;m['hs16_colour_balance']=gain;m['hs16_existing_knots_only']=True
    cache[old.as_pointer()]=m
   sl.link='OBJECT';sl.material=cache[old.as_pointer()]
   rows.append(dict(object=ob.name,slot=i,role=family,material=sl.material.name))
 assert all(c.p.s.material_state(m)==s for m,s in protected.items())
 return dict(objects=len({r['object'] for r in rows}),materials=len(cache),assignments=rows,roleLinearGains=GAINS,existingKnotAccentMaximum=.23,sparseAccentMemberThreshold=.76,onlySourceAuthoredGrowthUsed=True)
