"""Member-scale wood variation using existing grain, copied slots and stable seed."""
import bpy

# Linear pigment bounds; changes stay constant over each member, not each pixel.
SETTINGS={
 'column':(.80,1.16,1.60,.96), 'beam':(.84,1.12,1.50,.96),
 'apron':(.80,1.18,1.55,1.0), 'lower_board':(.82,1.16,1.40,.98),
 'floor':(.80,1.15,1.50,.97), 'gable':(.86,1.14,1.25,1.),
 'rafter':(.84,1.15,1.45,1.), 'railing':(.94,1.06,1.45,1.),
 'frame':(.90,1.08,1.60,.96), 'door_panel':(.86,1.10,1.65,.97),
 'lattice':(.94,1.05,1.30,.98), 'endgrain':(.88,1.12,1.15,1.)}

def node(t,kind,label):
 n=t.nodes.new(kind);n.label='HS14 '+label;return n

def attach(t,s,v):
 if hasattr(v,'node'):t.links.new(v,s)
 else:s.default_value=v

def math(t,op,a,b,label):
 n=node(t,'ShaderNodeMath',label);n.operation=op
 attach(t,n.inputs[0],a);attach(t,n.inputs[1],b);return n.outputs[0]

def apply(sc):
 import sarang_reference_colour_r3 as c
 cache={};assignments=[];details=[];originals={}
 for ob in sc.objects:
  if ob.type!='MESH' or ob.hide_render:continue
  used={p.material_index for p in ob.data.polygons}
  for index,slot in enumerate(ob.material_slots):
   old=slot.material
   if index not in used or not old or not old.get('hs12_wood_direction'):continue
   family=old.get('referenceColourProfile')
   if family not in SETTINGS:continue
   key=old.as_pointer()
   if key not in cache:
    originals[old]=c.p.s.material_state(old)
    m=old.copy();m.name='HS14 individual '+family+' | '+old.name;t=m.node_tree
    seed=next(n.outputs['Value'] for n in t.nodes if n.type=='TEX_WHITE_NOISE' and n.label=='Illustration constant pigment per member, not surface noise')
    # The existing hybrid seed contains object random, original member ID and
    # Geometry Random Per Island. Reuse it so joined pieces also differ.
    lo,hi,contrast,body=SETTINGS[family]
    ramps=[n for n in t.nodes if n.type=='VALTORGB' and n.label in ('HS12 '+family+' grain palette A','HS12 '+family+' grain palette B')]
    if family!='endgrain':
     assert len(ramps)==2,(m.name,'missing body ramps')
     old_factor=ramps[0].inputs['Fac'].links[0].from_socket
     centered=math(t,'SUBTRACT',old_factor,.075,'retain grain midpoint '+family)
     stretched=math(t,'ADD',math(t,'MULTIPLY',centered,contrast,'growth contrast '+family),.075,'growth body '+family)
     for ramp in ramps:t.links.new(stretched,ramp.inputs['Fac'])
    # Expand the old A/B interpolation; its previous 0.46-0.54 rail range made
    # the two palettes visually indistinguishable. Final pigment bounds below
    # keep coherent rail assemblies while larger boards have more variation.
    for n in t.nodes:
     if n.type=='MAP_RANGE' and n.label=='HS12 '+family+' bounded member variation' and family not in ('railing','frame','lattice','door_panel','endgrain'):
      n.inputs['To Min'].default_value=0.;n.inputs['To Max'].default_value=1.
    variation=node(t,'ShaderNodeMapRange','constant member pigment '+family)
    variation.inputs['To Min'].default_value=lo;variation.inputs['To Max'].default_value=hi
    t.links.new(seed,variation.inputs['Value'])
    # Closely related honey/walnut pigment hues, driven by the SAME member seed.
    colour=node(t,'ShaderNodeValToRGB','honey to walnut member tint '+family)
    colour.color_ramp.elements[0].color=(.94,1.,1.08,1.)
    colour.color_ramp.elements[1].color=(1.035,1.,.94,1.)
    t.links.new(seed,colour.inputs[0])
    for bs in [n for n in c.p.live(t) if n.type=='BSDF_PRINCIPLED']:
     socket=bs.inputs['Base Color'];src=socket.links[0].from_socket if socket.is_linked else tuple(socket.default_value)
     tint=node(t,'ShaderNodeMixRGB','member hue '+family);tint.blend_type='MULTIPLY';tint.inputs[0].default_value=1.
     attach(t,tint.inputs[1],src);t.links.new(colour.outputs['Color'],tint.inputs[2])
     value=node(t,'ShaderNodeMixRGB','member value '+family);value.blend_type='MULTIPLY';value.inputs[0].default_value=1.
     t.links.new(tint.outputs[0],value.inputs[1]);t.links.new(variation.outputs['Result'],value.inputs[2])
     hsv=node(t,'ShaderNodeHueSaturation','timber pigment balance '+family)
     hsv.inputs['Saturation'].default_value=.97;hsv.inputs['Value'].default_value=body
     t.links.new(value.outputs[0],hsv.inputs['Color']);t.links.new(hsv.outputs[0],socket)
     # Retain the authored roughness, with a bounded member-level offset.
     rough=bs.inputs['Roughness'];source=rough.links[0].from_socket if rough.is_linked else rough.default_value
     shift=math(t,'MULTIPLY',math(t,'SUBTRACT',seed,.5,'roughness centre '+family),.045,'member roughness '+family)
     out=math(t,'ADD',source,shift,'retain original roughness '+family)
     t.links.new(out,rough)
    m['hs14_individual_wood']=True;m['hs14_source_material']=old.name
    cache[key]=m;details.append(dict(material=m.name,role=family,memberLinearValueRange=[lo,hi],grainContrast=contrast,bodyScale=body,seedNode=seed.node.name))
   slot.link='OBJECT';slot.material=cache[key]
   assignments.append(dict(object=ob.name,slot=index,role=family,material=slot.material.name))
 assert all(c.p.s.material_state(m)==s for m,s in originals.items())
 # R13 accidentally included the three paper-finished ondol floors in window
 # emission. Correct only those floor material copies, leaving windows alone.
 floors=[]
 for ob in sc.objects:
  if ob.type!='MESH' or 'ondol floor' not in ob.name:continue
  for index,s in enumerate(ob.material_slots):
   if not s.material or (s.material.get('warmth_role') or s.material.get('referenceColourProfile'))!='paper':continue
   old=s.material;m=old.copy();m.name='HS14 nonemissive ondol | '+old.name
   for n in c.p.live(m.node_tree):
    if n.type=='BSDF_PRINCIPLED':
     for link in list(n.inputs['Emission Strength'].links):m.node_tree.links.remove(link)
     n.inputs['Emission Strength'].default_value=0.
   s.link='OBJECT';s.material=m;floors.append(dict(object=ob.name,slot=index,emission=0.))
 assert len(floors)==3,('expected three nonemissive ondol floors',floors)
 return dict(materials=len(cache),objects=len({a['object'] for a in assignments}),slots=len(assignments),assignments=assignments,settings=details,ondolCorrections=floors,originalMaterialsUnchanged=True,existingGrainUVAndNormalsRetained=True)
