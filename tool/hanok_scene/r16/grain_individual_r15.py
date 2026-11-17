"""Bounded per-member crops of the existing wood atlas; no mesh/UV edits."""
import bpy
def apply(sc):
 import sarang_reference_colour_r3 as c
 from wood_individual_r14 import node,attach,math
 cache={};rows=[];protected={};details=[]
 def vec(t,op,a,b,label):
  n=node(t,'ShaderNodeVectorMath','R15 '+label);n.operation=op
  attach(t,n.inputs[0],a);attach(t,n.inputs[1],b);return n.outputs['Vector']
 def combine(t,x,y,z,label):
  n=node(t,'ShaderNodeCombineXYZ','R15 '+label)
  for s,v in zip(n.inputs,[x,y,z]):attach(t,s,v)
  return n.outputs[0]
 for ob in sc.objects:
  if ob.type!='MESH' or ob.hide_render:continue
  used={p.material_index for p in ob.data.polygons}
  for i,s in enumerate(ob.material_slots):
   old=s.material
   if i not in used or not old or not old.get('hs14_individual_wood'):continue
   family=old.get('referenceColourProfile')
   if family=='endgrain':continue
   key=old.as_pointer()
   if key not in cache:
    protected[old]=c.p.s.material_state(old)
    m=old.copy();m.name='HS15 individual grain '+family+' | '+old.name;t=m.node_tree
    tex=next(n for n in c.p.live(t) if n.type=='TEX_IMAGE' and n.label=='Craft authored wood detail')
    original=tex.inputs['Vector'].links[0].from_socket
    # Replace the ORIGINAL coordinate's outgoing links, including the quiet
    # broad-grain taps, so a knot has one location throughout the colour path.
    users=list(original.links)
    seed=next(n for n in c.p.live(t) if n.type=='TEX_WHITE_NOISE' and n.label=='Illustration constant pigment per member, not surface noise')
    channels=node(t,'ShaderNodeSeparateXYZ','R15 fixed crop identity')
    t.links.new(seed.outputs['Color'],channels.inputs[0])
    # Keep every address within the existing wood-only atlas quadrant.
    # Different sizes/positions break repeated motifs without surface noise.
    quiet=family in ('railing','frame','lattice','door_panel')
    minx,miny=(.80,.76) if quiet else (.58,.52)
    sx=math(t,'ADD',math(t,'MULTIPLY',channels.outputs['X'],1-minx,'crop width span'),minx,'crop width')
    sy=math(t,'ADD',math(t,'MULTIPLY',channels.outputs['Y'],1-miny,'crop length span'),miny,'crop length')
    ox=math(t,'MULTIPLY',math(t,'SUBTRACT',channels.outputs['Z'],.5,'crop x signed'),math(t,'MULTIPLY',math(t,'SUBTRACT',1.,sx,'crop x margin'),.44,'crop x safe margin'),'crop x offset')
    oy=math(t,'MULTIPLY',math(t,'SUBTRACT',seed.outputs['Value'],.5,'crop y signed'),math(t,'MULTIPLY',math(t,'SUBTRACT',1.,sy,'crop y margin'),.44,'crop y safe margin'),'crop y offset')
    local=vec(t,'SUBTRACT',original,(.25,.75,0),'original wood centre')
    crop=vec(t,'MULTIPLY',local,combine(t,sx,sy,1.,'crop scale'),'vary member grain dimensions')
    crop=vec(t,'ADD',crop,combine(t,ox,oy,0.,'crop offset'),'vary member knot position')
    crop=vec(t,'ADD',crop,(.25,.75,0),'restore wood atlas address')
    for link in users:t.links.new(crop,link.to_socket)
    m['hs15_individual_grain']=True;cache[key]=m
    details.append(dict(material=m.name,role=family,crossGrainScale=[minx,1.],lengthScale=[miny,1.],atlasQuadrant=[.02,.48,.52,.98],originalTexture=tex.image.filepath))
   s.link='OBJECT';s.material=cache[key];rows.append(dict(object=ob.name,slot=i,material=s.material.name))
 assert all(c.p.s.material_state(m)==v for m,v in protected.items())
 return dict(materialCopies=len(cache),objects=len({x['object'] for x in rows}),assignments=rows,settings=details,sourceTextureRetained=True,meshUVDataUnchanged=True,cutFaceAtlasUnchanged=True)
