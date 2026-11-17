"""Role-specific timber palettes with stable object and island pigment variation."""
import bpy,json
from pathlib import Path
P=Path(__file__).resolve().parent

def linear(h):
 values=[int(h.lstrip('#')[i:i+2],16)/255 for i in (0,2,4)]
 return tuple(x/12.92 if x<=.04045 else ((x+.055)/1.055)**2.4 for x in values)+(1,)

def refine_materials(sc):
 import sarang_reference_colour_r3 as c
 spec=json.loads((P/'WOOD_DIRECTION_R12.json').read_text(encoding='utf-8'))
 profiles=spec['profiles'];cache={};assignments=[];reports=[]
 for ob in sc.objects:
  if ob.type!='MESH':continue
  for idx,slot in enumerate(ob.material_slots):
   old=slot.material
   if not old or old.get('referenceColourProfile') not in profiles:continue
   source_key=old['referenceColourProfile'];key=source_key
   if ob.name in spec['mappingExceptionsToReview'][0]['objects']:key='rafter'
   structure=ob.name in spec['mappingExceptionsToReview'][1]['objects']
   cache_key=(old.as_pointer(),key,structure)
   if cache_key not in cache:
    original=c.p.s.material_state(old)
    m=old.copy();m.name='HS12 timber '+key+' | '+old.name
    t=m.node_tree
    seed=next((n.outputs['Value'] for n in t.nodes if n.type=='TEX_WHITE_NOISE' and n.label=='Illustration constant pigment per member, not surface noise'),None)
    assert seed is not None,(old.name,'missing stable island member seed')
    ramps=[]
    for node in list(t.nodes):
     if node.type!='VALTORGB':continue
     if node.label=='Fresh Reference only '+source_key or node.label=='Fresh R4 shared maru and numaru timber':
      family=key
     elif node.label=='Fresh Reference only endgrain':
      family='endgrain'
     else:continue
     config=profiles[family]
     assert len(node.color_ramp.elements)==3,(old.name,node.label)
     old_outputs=list(node.outputs['Color'].links)
     old_input=list(node.inputs['Fac'].links)
     palette_a=config['paletteA'];palette_b=config['paletteB']
     twin=t.nodes.new('ShaderNodeValToRGB');twin.label='HS12 '+family+' grain palette B'
     twin.color_ramp.elements.new(.5)
     for a,b,ha,hb in zip(node.color_ramp.elements,twin.color_ramp.elements,palette_a,palette_b):
      b.position=a.position;a.color=linear(ha);b.color=linear(hb)
      if family=='gable' and structure:
       j=list(node.color_ramp.elements).index(a)
       a.color=tuple(.75*x+.25*y for x,y in zip(linear(ha),linear(profiles['beam']['paletteA'][j])))
       b.color=tuple(.75*x+.25*y for x,y in zip(linear(hb),linear(profiles['beam']['paletteB'][j])))
     twin.color_ramp.interpolation=node.color_ramp.interpolation
     if old_input:t.links.new(old_input[0].from_socket,twin.inputs['Fac'])
     else:twin.inputs['Fac'].default_value=node.inputs['Fac'].default_value
     ranges=config.get('memberMixRange',[0,1])
     if family=='railing':ranges=[.46,.54]
     elif family in ('frame','door_panel'):ranges=[.45,.55]
     elif family=='lattice':ranges=[.47,.53]
     fac=t.nodes.new('ShaderNodeMapRange');fac.label='HS12 '+family+' bounded member variation'
     fac.inputs['From Min'].default_value=0;fac.inputs['From Max'].default_value=1
     fac.inputs['To Min'].default_value=ranges[0];fac.inputs['To Max'].default_value=ranges[1]
     t.links.new(seed,fac.inputs['Value'])
     mix=t.nodes.new('ShaderNodeMixRGB');mix.blend_type='MIX';mix.label='HS12 '+family+' object and island pigment'
     t.links.new(fac.outputs['Result'],mix.inputs[0]);t.links.new(node.outputs['Color'],mix.inputs[1]);t.links.new(twin.outputs['Color'],mix.inputs[2])
     for link in old_outputs:t.links.new(mix.outputs[0],link.to_socket)
     node.label='HS12 '+family+' grain palette A'
     ramps.append(dict(family=family,paletteA=palette_a,paletteB=palette_b,memberMixRange=ranges))
    assert any(r['family']==key for r in ramps),(old.name,key)
    m['hs12_wood_direction']='role palettes plus stable hybrid member pigment; source grain UV and cut rings retained'
    assert c.p.s.material_state(old)==original
    m['referenceColourProfile']=key
    cache[cache_key]=m;reports.append(dict(source=old.name,material=m.name,profile=key,structuralGableVariant=structure,ramps=ramps))
   slot.link='OBJECT';slot.material=cache[cache_key]
   assignments.append(dict(object=ob.name,slot=idx,profile=key,material=slot.material.name))
 return dict(sourceSpec=str(P/'WOOD_DIRECTION_R12.json'),materials=len(cache),assignments=assignments,palettes=reports,originalMaterialsUnchanged=True,geometryUVAndGrainDirectionUnchanged=True,stableHybridMemberVariation=True,globalExposureUnchanged=True)
