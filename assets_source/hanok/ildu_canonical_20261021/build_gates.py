"""Fresh native gate construction. No previous blend, meshes or shaders imported.

Dimensions come from drawings 021, 090, 086-088. Undimensioned roof sections
are explicitly classified as interpretation, never certified measurements.
"""
import bpy, bmesh, math, json, hashlib, random, sys, argparse
from pathlib import Path
from mathutils import Vector
from mathutils.geometry import tessellate_polygon
from math import sin, cos, pi

OUT=Path(__file__).resolve().parent
sys.path.insert(0,str(OUT))
RNG=random.Random(20261018)
CONFIG={
 'left':dict(title='사랑채 왼쪽 협문',sheet='2007: 080 / 081 / 082 / 083',w=3.08,d=3.11,axis=2.08,post=.155,
   floor=.355,head=2.835,door=1.790,doorH=2.240,doorT=.025,doorBase=.335,boards=8,
   covers=8,pitch=.273,barge=1.18,eave=2.795,peak=3.84,levels=5,steps=0,
   support=.925,rafters=10,roofRows=9,verifiedElevation=True,roofProfile=[1,.675,.390,.163,0],limeEnds=False,
   rafterEnd=1.445,boardingHalf=1.39,rafterTop=3.075,rafterFall=.325,rafterHeight=.12),
 'right':dict(title='안채 연결 협문',sheet='2007: 089 / 090 / 091 / 092 / 093',w=3.00,d=1.86,
   axis=1.460,post=.180,floor=1.04,head=2.79,door=1.140,doorH=1.680,doorT=.03,
   doorBase=.980,boards=4,covers=7,pitch=.274,barge=1.14,eave=3.015,peak=3.93,
   levels=5,steps=5,support=.6,rafters=7,roofRows=6,verifiedElevation=True,roofProfile=[1,.64,.32,.105,0],limeEnds=True,
   rafterEnd=.83,boardingHalf=1.18,rafterTop=3.125,rafterFall=.175,rafterHeight=.10),
 'shrine':dict(title='사당문',sheet='086 / 087 / 088',w=2.57,d=1.94,axis=1.35,post=.17,
   floor=.2,head=2.0,door=1.02,doorH=1.5,doorT=.03,doorBase=.35,boards=8,
   covers=6,pitch=.27,barge=.82,eave=2.155,peak=3.075,levels=3,steps=1,
   support=.5,rafters=7,roofRows=6,verifiedElevation=True,roofProfile=[1,.69,.405,.176,0],limeEnds=True,
   rafterEnd=.9,rafterHalf=1.0515,boardingHalf=1.089),
}
COL=None;KEY=None;COUNTS={}

def rgba(hexvalue):
    h=hexvalue.lstrip('#'); rgb=[int(h[i:i+2],16)/255 for i in (0,2,4)]
    return tuple(x/12.92 if x<.04045 else ((x+.055)/1.055)**2.4 for x in rgb)+(1,)

def material(name,kind):
    m=bpy.data.materials.new(name);m.use_nodes=True
    n=m.node_tree.nodes;l=m.node_tree.links;n.clear()
    out=n.new('ShaderNodeOutputMaterial');bs=n.new('ShaderNodeBsdfPrincipled');l.new(bs.outputs['BSDF'],out.inputs['Surface'])
    grain=kind in ('wood','red','blue','green')
    tc=n.new('ShaderNodeTexCoord');mp=n.new('ShaderNodeVectorMath');mp.operation='MULTIPLY';l.new(tc.outputs['Generated' if grain else 'Object'],mp.inputs[0])
    mp.inputs[1].default_value=(7,7,.45) if grain else (2.5,2.5,2.5)
    if grain:
        # Bend fibres before stretching them. Straight X bands looked like vinyl.
        warp=n.new('ShaderNodeTexNoise');warp.inputs['Scale'].default_value=3.8;warp.inputs['Detail'].default_value=2.5
        l.new(tc.outputs['Generated'],warp.inputs['Vector'])
        offset=n.new('ShaderNodeVectorMath');offset.operation='SUBTRACT';offset.inputs[1].default_value=(.5,.5,.5);l.new(warp.outputs['Color'],offset.inputs[0])
        amp=n.new('ShaderNodeVectorMath');amp.operation='SCALE';amp.inputs[3].default_value=.13;l.new(offset.outputs[0],amp.inputs[0])
        bent=n.new('ShaderNodeVectorMath');bent.operation='ADD';l.new(tc.outputs['Generated'],bent.inputs[0]);l.new(amp.outputs[0],bent.inputs[1]);l.new(bent.outputs[0],mp.inputs[0])
    seed=n.new('ShaderNodeObjectInfo');off=n.new('ShaderNodeVectorMath');off.operation='SCALE';l.new(seed.outputs['Random'],off.inputs[3]);off.inputs[0].default_value=(11,7,19)
    add=n.new('ShaderNodeVectorMath');add.operation='ADD';l.new(mp.outputs['Vector'],add.inputs[0]);l.new(off.outputs['Vector'],add.inputs[1])
    noise=n.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=3.3;noise.inputs['Detail'].default_value=5;noise.inputs['Roughness'].default_value=.72;l.new(add.outputs['Vector'],noise.inputs['Vector'])
    colors={
      'wood':('#493522','#a28a62'), 'red':('#613b30','#995e49'),
      'blue':('#263b43','#385663'),'green':('#344b3b','#526c4f'),
      'clay':('#272b2c','#555956'),'stone':('#807967','#c3b7a0'),
      'earth':('#9a886c','#c4b28f'),'plaster':('#b6ad97','#dbd2bd'),
      'iron':('#202423','#3d413b'),'ground':('#cbbda3','#dfd0b6')}
    ramp=n.new('ShaderNodeValToRGB');lo,hi=colors[kind]
    ramp.color_ramp.elements[0].position=.12;ramp.color_ramp.elements[0].color=rgba(lo)
    ramp.color_ramp.elements[1].position=.88;ramp.color_ramp.elements[1].color=rgba(hi)
    l.new(noise.outputs['Fac'],ramp.inputs[0]);l.new(ramp.outputs[0],bs.inputs['Base Color'])
    if grain:
        wave=n.new('ShaderNodeTexWave');wave.wave_type='BANDS';wave.bands_direction='X'
        wave.inputs['Scale'].default_value=5.5;wave.inputs['Distortion'].default_value=7.5;wave.inputs['Detail'].default_value=5
        wave.inputs['Detail Scale'].default_value=2.5;l.new(add.outputs['Vector'],wave.inputs['Vector'])
        blend=n.new('ShaderNodeMixRGB');blend.blend_type='MULTIPLY';blend.inputs[0].default_value=.13
        l.new(noise.outputs['Fac'],blend.inputs[1]);l.new(wave.outputs['Fac'],blend.inputs[2]);l.new(blend.outputs[0],ramp.inputs[0])
    detail=n.new('ShaderNodeTexNoise');detail.inputs['Scale'].default_value=33 if grain else 72;detail.inputs['Detail'].default_value=3
    l.new(add.outputs['Vector'],detail.inputs['Vector'])
    bump=n.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.3 if grain else .38
    bump.inputs['Distance'].default_value=.0028 if grain else .003 if kind in ('stone','earth') else .00075
    l.new(detail.outputs['Fac'],bump.inputs['Height']);l.new(bump.outputs['Normal'],bs.inputs['Normal'])
    if grain:
        fibre=n.new('ShaderNodeBump');fibre.inputs['Strength'].default_value=.2;fibre.inputs['Distance'].default_value=.001
        l.new(noise.outputs['Fac'],fibre.inputs['Height']);l.new(bump.outputs['Normal'],fibre.inputs['Normal']);l.new(fibre.outputs['Normal'],bs.inputs['Normal'])
    rough=n.new('ShaderNodeMapRange');rough.inputs['To Min'].default_value=.54 if grain else .69
    rough.inputs['To Max'].default_value=.8 if grain else .91;l.new(noise.outputs['Fac'],rough.inputs['Value']);l.new(rough.outputs['Result'],bs.inputs['Roughness'])
    if kind=='iron':rough.inputs['To Min'].default_value=.40;rough.inputs['To Max'].default_value=.62
    bs.inputs['Metallic'].default_value=.65 if kind=='iron' else 0
    bs.inputs['Specular IOR Level'].default_value=.27 if kind!='iron' else .4
    if grain:
        end_mask=physical_timber_surface(m,kind,bs,ramp,tc,seed)
        heritage_surface(m,kind,bs,ramp,tc,seed,end_mask)
    elif kind=='clay':
        heritage_surface(m,kind,bs,ramp,tc,seed,None)
    elif kind=='stone':
        heritage_stone_surface(m,bs,ramp,tc,seed)
    return m

def heritage_stone_surface(m,bs,ramp,tc,seed):
    """Quiet dressed stone: broad natural faces, smaller tool marks, no gravel."""
    n=m.node_tree.nodes;l=m.node_tree.links
    path=OUT/'reference-textures'/'gye-fieldstone-brush-v26.png'
    if not path.is_file():raise FileNotFoundError(path)
    image=bpy.data.images.load(str(path),check_existing=True)
    if not image.packed_file:image.pack()
    metric=n.new('ShaderNodeVectorMath');metric.operation='MULTIPLY';metric.inputs[1].default_value=(1.25,1.25,1.25)
    l.new(tc.outputs['Object'],metric.inputs[0])
    offset=n.new('ShaderNodeVectorMath');offset.operation='SCALE';offset.inputs[0].default_value=(7,11,13)
    l.new(seed.outputs['Random'],offset.inputs[3])
    coords=n.new('ShaderNodeVectorMath');coords.operation='ADD'
    l.new(metric.outputs[0],coords.inputs[0]);l.new(offset.outputs[0],coords.inputs[1])
    fieldstone=n.new('ShaderNodeTexImage');fieldstone.image=image;fieldstone.projection='BOX';fieldstone.projection_blend=.35
    l.new(coords.outputs[0],fieldstone.inputs['Vector'])
    broad=n.new('ShaderNodeRGBToBW');l.new(fieldstone.outputs['Color'],broad.inputs[0])
    finer_coords=n.new('ShaderNodeVectorMath');finer_coords.operation='SCALE';finer_coords.inputs[3].default_value=19
    l.new(coords.outputs[0],finer_coords.inputs[0])
    grain=n.new('ShaderNodeTexNoise');grain.inputs['Scale'].default_value=1;grain.inputs['Detail'].default_value=2
    l.new(finer_coords.outputs[0],grain.inputs['Vector'])
    pores_coords=n.new('ShaderNodeVectorMath');pores_coords.operation='SCALE';pores_coords.inputs[3].default_value=4
    l.new(finer_coords.outputs[0],pores_coords.inputs[0])
    pores=n.new('ShaderNodeTexNoise');pores.inputs['Scale'].default_value=1;pores.inputs['Detail'].default_value=2
    l.new(pores_coords.outputs[0],pores.inputs['Vector'])
    broad_gain=n.new('ShaderNodeMapRange');broad_gain.inputs['From Min'].default_value=.17
    broad_gain.inputs['From Max'].default_value=.34;broad_gain.inputs['To Min'].default_value=.82
    broad_gain.inputs['To Max'].default_value=1.18;l.new(broad.outputs[0],broad_gain.inputs['Value'])
    tone=n.new('ShaderNodeMixRGB');tone.blend_type='MULTIPLY';tone.inputs[0].default_value=.50
    l.new(ramp.outputs[0],tone.inputs[1]);l.new(broad_gain.outputs[0],tone.inputs[2])
    grain_gain=n.new('ShaderNodeMapRange');grain_gain.inputs['From Min'].default_value=.28
    grain_gain.inputs['From Max'].default_value=.72;grain_gain.inputs['To Min'].default_value=.88
    grain_gain.inputs['To Max'].default_value=1.12;l.new(grain.outputs['Fac'],grain_gain.inputs['Value'])
    mineral=n.new('ShaderNodeMixRGB');mineral.blend_type='MULTIPLY';mineral.inputs[0].default_value=.30
    l.new(tone.outputs[0],mineral.inputs[1]);l.new(grain_gain.outputs[0],mineral.inputs[2])
    piece=n.new('ShaderNodeMapRange');piece.inputs['To Min'].default_value=.94
    piece.inputs['To Max'].default_value=1.06;l.new(seed.outputs['Random'],piece.inputs['Value'])
    individual=n.new('ShaderNodeMixRGB');individual.blend_type='MULTIPLY';individual.inputs[0].default_value=.65
    l.new(mineral.outputs[0],individual.inputs[1]);l.new(piece.outputs[0],individual.inputs[2]);l.new(individual.outputs[0],bs.inputs['Base Color'])
    old=bs.inputs['Normal'].links[0].from_socket
    broad_height=n.new('ShaderNodeMapRange');broad_height.inputs['From Min'].default_value=.17
    broad_height.inputs['From Max'].default_value=.34;l.new(broad.outputs[0],broad_height.inputs['Value'])
    broad_bump=n.new('ShaderNodeBump');broad_bump.inputs['Strength'].default_value=.20
    broad_bump.inputs['Distance'].default_value=.003;l.new(broad_height.outputs[0],broad_bump.inputs['Height'])
    l.new(old,broad_bump.inputs['Normal'])
    grain_height=n.new('ShaderNodeMapRange');grain_height.inputs['From Min'].default_value=.28
    grain_height.inputs['From Max'].default_value=.72;l.new(grain.outputs['Fac'],grain_height.inputs['Value'])
    grain_bump=n.new('ShaderNodeBump');grain_bump.inputs['Strength'].default_value=.18
    grain_bump.inputs['Distance'].default_value=.0015;l.new(grain_height.outputs[0],grain_bump.inputs['Height'])
    l.new(broad_bump.outputs[0],grain_bump.inputs['Normal'])
    pore_bump=n.new('ShaderNodeBump');pore_bump.inputs['Strength'].default_value=.08
    pore_bump.inputs['Distance'].default_value=.0005;l.new(pores.outputs['Fac'],pore_bump.inputs['Height'])
    l.new(grain_bump.outputs[0],pore_bump.inputs['Normal']);l.new(pore_bump.outputs[0],bs.inputs['Normal'])
    finish=n.new('ShaderNodeMapRange');finish.inputs['From Min'].default_value=.28
    finish.inputs['From Max'].default_value=.72;finish.inputs['To Min'].default_value=.85
    finish.inputs['To Max'].default_value=.70;l.new(grain.outputs['Fac'],finish.inputs['Value'])
    l.new(finish.outputs[0],bs.inputs['Roughness'])
    bs.inputs['Specular IOR Level'].default_value=.17
    m['surfaceRevision']='R6c | calm fieldstone tone, medium dressing, matte pores'

def physical_timber_surface(m,kind,bs,ramp,tc,seed):
    """Metric local grain, broad growth, fibres and real end grain share one palette."""
    n=m.node_tree.nodes;l=m.node_tree.links
    def vector(scale):
        v=n.new('ShaderNodeVectorMath');v.operation='MULTIPLY';v.inputs[1].default_value=scale;l.new(tc.outputs['Object'],v.inputs[0]);return v.outputs[0]
    broad=n.new('ShaderNodeTexNoise');broad.name='Metric broad timber growth';broad.inputs['Scale'].default_value=1.7;broad.inputs['Detail'].default_value=2.5
    l.new(vector((8,8,.40)),broad.inputs['Vector'])
    phase=n.new('ShaderNodeVectorMath');phase.operation='ADD';l.new(vector((520,520,2.5)),phase.inputs[0])
    shift=n.new('ShaderNodeVectorMath');shift.operation='SCALE';shift.inputs[0].default_value=(13,7,3);l.new(seed.outputs['Random'],shift.inputs[3]);l.new(shift.outputs[0],phase.inputs[1])
    fine=n.new('ShaderNodeTexNoise');fine.name='Metric long fibres';fine.inputs['Scale'].default_value=1.5;fine.inputs['Detail'].default_value=2;l.new(phase.outputs[0],fine.inputs['Vector'])
    growth=n.new('ShaderNodeMixRGB');growth.blend_type='MIX';growth.inputs[0].default_value=.20;l.new(broad.outputs['Fac'],growth.inputs[1]);l.new(fine.outputs['Fac'],growth.inputs[2])
    # Volumetric growth rings bend gently down the length, making face grain
    # and end grain parts of the same timber rather than unrelated stripes.
    warp=n.new('ShaderNodeTexNoise');warp.inputs['Scale'].default_value=1.7;warp.inputs['Detail'].default_value=3
    warpShift=n.new('ShaderNodeVectorMath');warpShift.operation='SCALE';warpShift.inputs[0].default_value=(3,7,13);l.new(seed.outputs['Random'],warpShift.inputs[3])
    warpInput=n.new('ShaderNodeVectorMath');warpInput.operation='ADD';l.new(vector((.45,.45,1)),warpInput.inputs[0]);l.new(warpShift.outputs[0],warpInput.inputs[1]);l.new(warpInput.outputs[0],warp.inputs['Vector'])
    centered=n.new('ShaderNodeVectorMath');centered.operation='SUBTRACT';centered.inputs[1].default_value=(.5,.5,.5);l.new(warp.outputs['Color'],centered.inputs[0])
    bend=n.new('ShaderNodeVectorMath');bend.operation='MULTIPLY';bend.inputs[1].default_value=(.085,.07,0);l.new(centered.outputs[0],bend.inputs[0])
    warped=n.new('ShaderNodeVectorMath');warped.operation='ADD';l.new(vector((1,1,0)),warped.inputs[0]);l.new(bend.outputs[0],warped.inputs[1])
    ringcenter=n.new('ShaderNodeVectorMath');ringcenter.operation='ADD';l.new(warped.outputs[0],ringcenter.inputs[0]);ringcenter.inputs[1].default_value=(.065,.028,0)
    radial=n.new('ShaderNodeVectorMath');radial.operation='LENGTH';l.new(ringcenter.outputs[0],radial.inputs[0])
    frequency=n.new('ShaderNodeMath');frequency.operation='MULTIPLY';frequency.inputs[1].default_value=260;l.new(radial.outputs['Value'],frequency.inputs[0])
    rings=n.new('ShaderNodeMath');rings.operation='SINE';l.new(frequency.outputs[0],rings.inputs[0])
    ringrange=n.new('ShaderNodeValToRGB');ringrange.color_ramp.interpolation='EASE'
    ringrange.color_ramp.elements[0].position=.12;ringrange.color_ramp.elements[0].color=(.50,.50,.50,1)
    ringrange.color_ramp.elements[1].position=.68;ringrange.color_ramp.elements[1].color=(.42,.42,.42,1)
    l.new(rings.outputs[0],ringrange.inputs[0])
    geo=n.new('ShaderNodeNewGeometry');tr=n.new('ShaderNodeVectorTransform');tr.vector_type='NORMAL';tr.convert_from='WORLD';tr.convert_to='OBJECT';l.new(geo.outputs['Normal'],tr.inputs[0])
    sep=n.new('ShaderNodeSeparateXYZ');l.new(tr.outputs[0],sep.inputs[0]);ab=n.new('ShaderNodeMath');ab.operation='ABSOLUTE';l.new(sep.outputs['Z'],ab.inputs[0])
    mask=n.new('ShaderNodeMapRange');mask.inputs['From Min'].default_value=.86;mask.inputs['From Max'].default_value=.98;l.new(ab.outputs[0],mask.inputs[0])
    faceRings=n.new('ShaderNodeMixRGB');faceRings.inputs[0].default_value=.06 if kind=='wood' else .025;l.new(growth.outputs[0],faceRings.inputs[1]);l.new(ringrange.outputs[0],faceRings.inputs[2])
    ring_weight=n.new('ShaderNodeMath');ring_weight.operation='MULTIPLY';ring_weight.inputs[1].default_value=.40 if kind=='wood' else .08
    l.new(mask.outputs[0],ring_weight.inputs[0])
    growthmix=n.new('ShaderNodeMixRGB');l.new(ring_weight.outputs[0],growthmix.inputs[0]);l.new(faceRings.outputs[0],growthmix.inputs[1]);l.new(ringrange.outputs[0],growthmix.inputs[2]);l.new(growthmix.outputs[0],ramp.inputs[0])
    bump=n.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.15 if kind=='wood' else .08;bump.inputs['Distance'].default_value=.0008 if kind=='wood' else .00035
    l.new(growthmix.outputs[0],bump.inputs['Height']);l.new(bump.outputs[0],bs.inputs['Normal'])
    pore=n.new('ShaderNodeBump');pore.inputs['Strength'].default_value=.09 if kind=='wood' else .045;pore.inputs['Distance'].default_value=.00017 if kind=='wood' else .00009;l.new(fine.outputs['Fac'],pore.inputs['Height']);l.new(bump.outputs[0],pore.inputs['Normal']);l.new(pore.outputs[0],bs.inputs['Normal'])
    rough=n.new('ShaderNodeMapRange');rough.inputs['To Min'].default_value=.59 if kind=='wood' else .61;rough.inputs['To Max'].default_value=.73 if kind=='wood' else .75;l.new(growth.outputs[0],rough.inputs[0]);l.new(rough.outputs[0],bs.inputs['Roughness'])
    m['grainUnits']='local metres; length Z';m['endGrain']=True
    return mask.outputs[0]

def heritage_surface(m,kind,bs,ramp,tc,seed,end_mask):
    """Use the estate's packed material samples for restrained grain, not geometry."""
    n=m.node_tree.nodes;l=m.node_tree.links
    def number(operation,a,b=None):
        node=n.new('ShaderNodeMath');node.operation=operation
        for i,value in enumerate((a,b)):
            if value is None:continue
            if isinstance(value,(int,float)):node.inputs[i].default_value=value
            else:l.new(value,node.inputs[i])
        return node.outputs[0]
    def atlas(name,cols,rows,u,v):
        idx=number('FLOOR',number('MULTIPLY',seed.outputs['Random'],cols*rows-.001))
        col=number('MODULO',idx,cols);row=number('FLOOR',number('DIVIDE',idx,cols))
        xy=n.new('ShaderNodeCombineXYZ')
        l.new(number('ADD',number('MULTIPLY',u,1/cols-.006),number('ADD',number('DIVIDE',col,cols),.003)),xy.inputs['X'])
        l.new(number('ADD',number('MULTIPLY',v,1/rows-.006),number('ADD',number('DIVIDE',row,rows),.003)),xy.inputs['Y'])
        path=OUT/'reference-textures'/name
        if not path.is_file():raise FileNotFoundError(path)
        image=bpy.data.images.load(str(path),check_existing=True)
        if not image.packed_file:image.pack()
        tex=n.new('ShaderNodeTexImage');tex.image=image;tex.extension='EXTEND';tex.interpolation='Linear'
        l.new(xy.outputs[0],tex.inputs['Vector'])
        return tex.outputs['Color']
    if kind=='clay':
        path=OUT/'reference-textures'/'gye-clay-matte-v26.png'
        if not path.is_file():raise FileNotFoundError(path)
        image=bpy.data.images.load(str(path),check_existing=True)
        if not image.packed_file:image.pack()
        coords=n.new('ShaderNodeVectorMath');coords.operation='MULTIPLY';coords.inputs[1].default_value=(2.1,2.1,2.1)
        l.new(tc.outputs['Object'],coords.inputs[0])
        tex=n.new('ShaderNodeTexImage');tex.image=image;tex.projection='BOX';tex.projection_blend=.35
        l.new(coords.outputs[0],tex.inputs['Vector']);sample=tex.outputs['Color']
        tint=n.new('ShaderNodeMixRGB');tint.blend_type='MIX';tint.inputs[0].default_value=.44
        l.new(ramp.outputs[0],tint.inputs[1]);l.new(sample,tint.inputs[2])
        gray=n.new('ShaderNodeRGBToBW');l.new(sample,gray.inputs[0])
        # The packed clay sample has a very narrow value range. Expand its
        # middle values gently, then vary each fired ceramic piece a little.
        clay_tones=n.new('ShaderNodeMapRange');clay_tones.name='Clay broad tones';clay_tones.inputs['From Min'].default_value=.09
        clay_tones.inputs['From Max'].default_value=.15
        clay_tones.inputs['To Min'].default_value=.68;clay_tones.inputs['To Max'].default_value=1.32
        l.new(gray.outputs[0],clay_tones.inputs['Value'])
        piece_tones=n.new('ShaderNodeMapRange');piece_tones.inputs['To Min'].default_value=.93
        piece_tones.inputs['To Max'].default_value=1.07;l.new(seed.outputs['Random'],piece_tones.inputs['Value'])
        tonal_value=number('MULTIPLY',clay_tones.outputs['Result'],piece_tones.outputs['Result'])
        colour_depth=n.new('ShaderNodeMixRGB');colour_depth.blend_type='MULTIPLY'
        colour_depth.inputs[0].default_value=1.0
        l.new(tint.outputs[0],colour_depth.inputs[1]);l.new(tonal_value,colour_depth.inputs[2])
        l.new(colour_depth.outputs[0],bs.inputs['Base Color'])
        old=bs.inputs['Normal'].links[0].from_socket
        bump=n.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.14;bump.inputs['Distance'].default_value=.0021
        l.new(gray.outputs[0],bump.inputs['Height']);l.new(old,bump.inputs['Normal']);l.new(bump.outputs[0],bs.inputs['Normal'])
        gen=n.new('ShaderNodeSeparateXYZ');l.new(tc.outputs['Generated'],gen.inputs[0])
        micro=atlas('tile-blue-charcoal-v1.png',4,4,gen.outputs['X'],gen.outputs['Y'])
        micro_gray=n.new('ShaderNodeRGBToBW');micro_gray.name='Clay micro luma';l.new(micro,micro_gray.inputs[0])
        micro_bump=n.new('ShaderNodeBump');micro_bump.name='Clay micro bump';micro_bump.inputs['Strength'].default_value=.13;micro_bump.inputs['Distance'].default_value=.0008
        l.new(micro_gray.outputs[0],micro_bump.inputs['Height']);l.new(bump.outputs[0],micro_bump.inputs['Normal']);l.new(micro_bump.outputs[0],bs.inputs['Normal'])
        rough=n.new('ShaderNodeMapRange');rough.inputs['From Min'].default_value=.09;rough.inputs['From Max'].default_value=.15
        rough.inputs['To Min'].default_value=.62;rough.inputs['To Max'].default_value=.88
        l.new(gray.outputs[0],rough.inputs['Value'])
        micro_rough=n.new('ShaderNodeMapRange');micro_rough.inputs['From Min'].default_value=.03
        micro_rough.inputs['From Max'].default_value=.10
        micro_rough.inputs['To Min'].default_value=-.045;micro_rough.inputs['To Max'].default_value=.045
        l.new(micro_gray.outputs[0],micro_rough.inputs['Value'])
        l.new(number('ADD',rough.outputs[0],micro_rough.outputs[0]),bs.inputs['Roughness'])
        bs.inputs['Specular IOR Level'].default_value=.20
        m['surfaceRevision']='R6 | two-scale native fired clay; tactile matte response'
        return
    gen=n.new('ShaderNodeSeparateXYZ');l.new(tc.outputs['Generated'],gen.inputs[0])
    # Read the complete length of each timber sample on short gate members.
    # The former 4.8 m interval sampled only a narrow, nearly flat strip.
    long_color=atlas('wood-long-members-trim-v1.png',8,1,gen.outputs['X'],gen.outputs['Z'])
    end_color=atlas('wood-endgrain-atlas-v1.png',4,4,gen.outputs['X'],gen.outputs['Y'])
    long_gray=n.new('ShaderNodeRGBToBW');l.new(long_color,long_gray.inputs[0])
    end_gray=n.new('ShaderNodeRGBToBW');l.new(end_color,end_gray.inputs[0])
    sampled=n.new('ShaderNodeMixRGB');sampled.blend_type='MIX'
    l.new(end_mask if kind=='wood' else number('MULTIPLY',end_mask,.40),sampled.inputs[0])
    l.new(long_gray.outputs[0],sampled.inputs[1]);l.new(end_gray.outputs[0],sampled.inputs[2])
    normalised=n.new('ShaderNodeMapRange');normalised.inputs['From Min'].default_value=.04;normalised.inputs['From Max'].default_value=.52
    normalised.inputs['To Min'].default_value=.52 if kind=='wood' else .50
    normalised.inputs['To Max'].default_value=1.48 if kind=='wood' else 1.50;l.new(sampled.outputs[0],normalised.inputs['Value'])
    tint=n.new('ShaderNodeMixRGB');tint.blend_type='MULTIPLY';tint.inputs[0].default_value=.72 if kind=='wood' else .60
    l.new(ramp.outputs[0],tint.inputs[1]);l.new(normalised.outputs[0],tint.inputs[2]);l.new(tint.outputs[0],bs.inputs['Base Color'])
    old=bs.inputs['Normal'].links[0].from_socket
    bump=n.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.15 if kind=='wood' else .18
    bump.inputs['Distance'].default_value=.0011 if kind=='wood' else .0010
    l.new(sampled.outputs[0],bump.inputs['Height']);l.new(old,bump.inputs['Normal']);l.new(bump.outputs[0],bs.inputs['Normal'])
    fibres=n.new('ShaderNodeTexNoise');fibres.inputs['Scale'].default_value=1.0;fibres.inputs['Detail'].default_value=2.0
    fibre_coordinates=n.new('ShaderNodeVectorMath');fibre_coordinates.operation='MULTIPLY';fibre_coordinates.inputs[1].default_value=(28,28,3.8)
    l.new(tc.outputs['Object'],fibre_coordinates.inputs[0]);l.new(fibre_coordinates.outputs[0],fibres.inputs['Vector'])
    fibre_bump=n.new('ShaderNodeBump');fibre_bump.inputs['Strength'].default_value=.09 if kind=='wood' else .08
    fibre_bump.inputs['Distance'].default_value=.00035 if kind=='wood' else .00028
    l.new(fibres.outputs['Fac'],fibre_bump.inputs['Height']);l.new(bump.outputs[0],fibre_bump.inputs['Normal']);l.new(fibre_bump.outputs[0],bs.inputs['Normal'])
    old_rough=bs.inputs['Roughness'].links[0].from_socket
    varied=n.new('ShaderNodeMapRange');varied.inputs['From Min'].default_value=.04;varied.inputs['From Max'].default_value=.52
    varied.inputs['To Min'].default_value=-.055 if kind=='wood' else -.065
    varied.inputs['To Max'].default_value=.055 if kind=='wood' else .065;l.new(sampled.outputs[0],varied.inputs['Value'])
    fibre_rough=n.new('ShaderNodeMapRange');fibre_rough.inputs['From Min'].default_value=.35
    fibre_rough.inputs['From Max'].default_value=.65
    fibre_rough.inputs['To Min'].default_value=-.035 if kind=='wood' else -.025
    fibre_rough.inputs['To Max'].default_value=.035 if kind=='wood' else .025
    l.new(fibres.outputs['Fac'],fibre_rough.inputs['Value'])
    l.new(number('ADD',number('ADD',old_rough,varied.outputs[0]),fibre_rough.outputs[0]),bs.inputs['Roughness'])
    bs.inputs['Specular IOR Level'].default_value=.20 if kind=='wood' else .17
    m['surfaceRevision']='R6 | visible longitudinal fibres and restrained endgrain'

def mesh(name,verts,faces,mat,bevel=0,smooth=False):
    name=KEY+'.'+name;me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update()
    bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free()
    ob=bpy.data.objects.new(name,me);COL.objects.link(ob);me.materials.append(mat)
    for p in me.polygons:p.use_smooth=smooth
    ob['source']='new construction from drawing';ob['owner']=KEY
    if bevel:
        mod=ob.modifiers.new('small real arris','BEVEL');mod.width=bevel;mod.segments=2
    COUNTS[KEY]=COUNTS.get(KEY,0)+1
    return ob

def box(name,center,size,mat,bevel=.003):
    x,y,z=(v/2 for v in size)
    vs=[(a*x,b*y,c*z) for a,b,c in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
    fs=[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
    ob=mesh(name,vs,fs,mat,bevel);ob.location=center;return ob

def beam(name,a,b,w,d,mat,bevel=.003):
    a=Vector(a);b=Vector(b);ob=box(name,(a+b)/2,(w,d,(b-a).length),mat,bevel)
    ob.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return ob

def horizontal_timber(name,a,b,width,height,mat,bevel=.003):
    """A horizontal timber with explicit world-vertical section height."""
    a=Vector(a);b=Vector(b);assert abs(a.z-b.z)<1e-6
    ob=beam(name,a,b,width,height,mat,bevel)
    ob['sectionWidth_mm']=width*1000;ob['verticalSection_mm']=height*1000
    # For Z tracking with Y up, local Y is the world vertical for both X/Y runs.
    return ob

def longitudinal_grain(ob,axis):
    """Rebase a custom mesh so its Generated Z follows the timber's long axis."""
    q=Vector(axis).to_track_quat('Z','Y');inv=q.inverted()
    for v in ob.data.vertices:v.co=inv@v.co
    ob.rotation_euler=q.to_euler()

def roof_surface(c,x,y):
    B=c['barge'];xmax=c['w']/2;t=min(1,abs(y)/(c['d']/2))
    wingDrop=.10 if KEY=='shrine' else .18
    edge=.06*(abs(x)/B)**4 if abs(x)<=B else .06-wingDrop*((abs(x)-B)/(xmax-B))
    # Per-gate elevation guides. Interpolation remains explicitly traced, not a printed dimension.
    guide=c['roofProfile'];s=t*4;k=min(3,int(s));u=s-k
    # Monotone smooth tangent interpolation avoids visible polygon kinks.
    slopes=[guide[1]-guide[0]]+[(guide[i+1]-guide[i-1])/2 for i in range(1,4)]+[guide[4]-guide[3]]
    z=(2*u**3-3*u*u+1)*guide[k]+(u**3-2*u*u+u)*slopes[k]+(-2*u**3+3*u*u)*guide[k+1]+(u**3-u*u)*slopes[k+1]
    return c['eave']+(c['peak']-.255-c['eave'])*z+edge

def roof_corner_y(c,x,y):
    """Trace the rounded fan at the four tile-wing corners, keeping overall spans."""
    shoulder=c['barge'];rim=c['w']/2
    t=max(0,min(1,(abs(x)-shoulder)/(rim-shoulder)))
    smooth=t*t*(3-2*t)
    corner={'left':.18,'right':.16,'shrine':.19}[KEY]
    return y*(1-corner*smooth/(c['d']/2))

def deck_top(c):
    if KEY!='shrine':return c['rafterTop']+.025
    # 087 separates 30 mm boarding from 75 x 90 square rafters.
    return dori_bottom(c)+.15+.09+.03

def dori_bottom(c):
    # 087: post head includes the 150 mm dori zone. 090 elevation: dori bears above post head.
    return c['head']-.03 if KEY=='right' else c['head']-.15

def rafter_lift(c,x,y):
    tail=c.get('rafterEnd',c['d']/2-.035);start=min(c['support']+.055,tail-.10)
    u=max(0,min(1,(abs(y)-start)/(tail-start)));u=u*u*(3-2*u)
    return max(0,roof_surface(c,x,c['d']/2)-.035-deck_top(c))*u

def shaped_rafter(c,x,index,material):
    end=c.get('rafterEnd',c['d']/2-.035)
    ys=sorted(set([-end+i*2*end/24 for i in range(25)]+[-c['support'],0,c['support']]))
    verts=[];roundwood=KEY=='left';n=32 if roundwood else 8
    for y in ys:
        lift=rafter_lift(c,x,y);ztop=deck_top(c)-.03+lift
        if roundwood:
            verts.extend((x+.045*cos(2*pi*j/n),y,ztop-.045+.045*sin(2*pi*j/n)) for j in range(n))
        else:
            cham=.006 if abs(y)>end-.055 else .0015
            section=[(-.0375,0),(.0375,0),(.0375,-.09+cham),(.0375-cham,-.09),(-.0375+cham,-.09),(-.0375,-.09+cham),(-.0375,-.045),(-.0375,-.005)]
            verts.extend((x+xx,y,ztop+zz) for xx,zz in section)
    faces=[tuple(range(n-1,-1,-1)),tuple(range(len(verts)-n,len(verts)))]
    for k in range(len(ys)-1):faces.extend((k*n+j,k*n+(j+1)%n,(k+1)*n+(j+1)%n,(k+1)*n+j) for j in range(n))
    name='roof.round rafter ' if roundwood else 'roof.square rafter '
    ob=mesh(name+str(index),verts,faces,material,.0008,roundwood)
    if roundwood:
        ob.data.polygons[0].use_smooth=False;ob.data.polygons[1].use_smooth=False
    longitudinal_grain(ob,(0,1,0));ob['sectionEvidence']='left round ends from photo; diameter interpretation' if roundwood else '75x90 body section; 087'
    return ob

def soften_timber_tail(ob):
    length=max(v.co.z for v in ob.data.vertices)-min(v.co.z for v in ob.data.vertices)
    for v in ob.data.vertices:
        if v.co.y<0:v.co.z-=math.copysign(min(.018,length*.025),v.co.z)
    ob['endTreatment']='small lower arris scarf; outline preserved'

def cylinder(name,a,b,r,mat,segments=32):
    a=Vector(a);b=Vector(b);height=(b-a).length
    v=[(r*cos(2*pi*i/segments),r*sin(2*pi*i/segments),z) for z in (0,height) for i in range(segments)]
    f=[tuple(range(segments-1,-1,-1)),tuple(range(segments,2*segments))]
    f += [(i,(i+1)%segments,(i+1)%segments+segments,i+segments) for i in range(segments)]
    ob=mesh(name,v,f,mat,.001,True);ob.location=a;ob.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return ob

def shell(name,grid,mat,thick=.012,bevel=.001):
    nr=len(grid);nc=len(grid[0]);v=[p for row in grid for p in row];v += [(x,y,z-thick) for x,y,z in v];N=nr*nc
    f=[]
    for j in range(nr-1):
        for i in range(nc-1):
            a=j*nc+i;b=a+1;c=b+nc;d=a+nc
            f += [(a,b,c,d),(a+N,d+N,c+N,b+N)]
    edges=[]
    edges += [(i,i+1) for i in range(nc-1)]
    edges += [(j*nc+nc-1,(j+1)*nc+nc-1) for j in range(nr-1)]
    edges += [((nr-1)*nc+i,(nr-1)*nc+i-1) for i in range(nc-1,0,-1)]
    edges += [(j*nc,(j-1)*nc) for j in range(nr-1,0,-1)]
    f += [(a,a+N,b+N,b) for a,b in edges]
    ob=mesh(name,v,f,mat,bevel,True)
    for p in ob.data.polygons:p.use_smooth=p.index<2*(nr-1)*(nc-1)
    return ob

def profile_solid(name,points,x0,x1,mat):
    n=len(points);v=[(x,y,z) for x in (x0,x1) for y,z in points]
    f=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh(name,v,f,mat,.002)

def path_tube(name,points,r,mat,segments=12):
    v=[];f=[]
    for i,p in enumerate(points):
        p=Vector(p);t=Vector(points[min(i+1,len(points)-1)])-Vector(points[max(0,i-1)])
        q=t.to_track_quat('Z','Y')
        v.extend(tuple(p+q@Vector((r*cos(j*2*pi/segments),r*sin(j*2*pi/segments),0))) for j in range(segments))
    for i in range(len(points)-1):
        for j in range(segments):f.append((i*segments+j,i*segments+(j+1)%segments,(i+1)*segments+(j+1)%segments,(i+1)*segments+j))
    f += [tuple(range(segments-1,-1,-1)),tuple((len(points)-1)*segments+j for j in range(segments))]
    return mesh(name,v,f,mat,0,True)

def nail(name,x,y,z,r=.011):
    # Low dome, not a black sphere glued halfway through the door.
    seg=16;rings=5;v=[(x,y-.009,z)]
    for k in range(1,rings+1):
        a=k*pi/2/rings
        v.extend((x+r*sin(a)*cos(j*2*pi/seg),y-.009*cos(a),z+r*sin(a)*sin(j*2*pi/seg)) for j in range(seg))
    f=[(0,1+j,1+(j+1)%seg) for j in range(seg)]
    for k in range(rings-1):
        for j in range(seg):a=1+k*seg+j;b=1+k*seg+(j+1)%seg;f.append((a,b,b+seg,a+seg))
    f.append(tuple(range(len(v)-1,len(v)-1-seg,-1)))
    return mesh(name,v,f,M['iron'],0,True)

def hardware(c):
    y=-c['doorT']/2-.003;zc=c['doorBase']+c['doorH']*.49
    for sx in (-1,1):
        x=sx*.075
        # Flat lobed escutcheon with a separate moving ring and hinge eye.
        outline=[]
        for j in range(32):
            t=2*pi*j/32;r=.044*(1+.10*cos(6*t));outline.append((x+r*cos(t),y,zc+.028+r*1.35*sin(t)))
        v=outline+[(a,b+.006,d) for a,b,d in outline];n=len(outline)
        mesh('iron.escutcheon',v,[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)],M['iron'],.002)
        ring=[(x+.046*cos(t),y-.023,zc-.025+.052*sin(t)) for t in [2*pi*j/48 for j in range(49)]]
        path_tube('iron.ring',ring,.006,M['iron'])
        cylinder('iron.eye',(x,y-.005,zc+.035),(x,y-.036,zc+.035),.009,M['iron'],20)
        nail('iron.plate pin',x,y-.007,zc+.071,.006)
    rows=[.08,.92] if KEY!='right' else [.08,.48,.92]
    for j in range(c['boards']):
        cx=-c['door']/2+(j+.5)*c['door']/c['boards']
        for rz in rows:
            for off in ((0,) if KEY=='shrine' else (-.043,.043)):
                nail('iron.board nail',cx+off,y, c['doorBase']+c['doorH']*rz,.0085)

def taegeuk(c):
    cx=0;cz=c['doorBase']+c['doorH']*.57;r=c['door']*.43;y=-c['doorT']/2-.0008
    # The symbol is flush paint on the same plank surface. Preserve door seams.
    boardw=c['door']/c['boards']
    outline=[Vector((r*cos(pi/2-pi*j/96),0,r*sin(pi/2-pi*j/96))) for j in range(97)]
    outline += [Vector((r/2*cos(-pi/2-pi*j/64),0,-r/2+r/2*sin(-pi/2-pi*j/64))) for j in range(1,65)]
    outline += [Vector((r/2*cos(-pi/2+pi*j/64),0,r/2+r/2*sin(-pi/2+pi*j/64))) for j in range(1,64)]
    def clip(poly,bound,greater):
        result=[]
        for a,b in zip(poly,poly[1:]+poly[:1]):
            ia=a.x>=bound if greater else a.x<=bound;ib=b.x>=bound if greater else b.x<=bound
            if ia:result.append(a)
            if ia!=ib:result.append(a+(b-a)*((bound-a.x)/(b.x-a.x)))
        return result
    def paint_shape(polyline,material,depth,name):
        v=[];f=[]
        for tri in tessellate_polygon([polyline]):
            tri=[polyline[index] if isinstance(index,int) else index for index in tri]
            for j in range(c['boards']):
                a=-c['door']/2+j*boardw+.0006;b=a+boardw-.0012
                poly=clip(clip(list(tri),a,True),b,False)
                if len(poly)<3:continue
                q=len(v);v.extend((p.x,depth,cz+p.z) for p in poly);f.append(tuple(q+k for k in range(len(poly))))
        return mesh(name,v,f,material)
    # Photo: a distinguishable full red disk, blue below with the upper-right lobe.
    # The previous vertical blue crescent used the door colour as an invisible red half.
    red=M['red'].copy();red.name='Fresh | red disk paint'
    ramp=next(n for n in red.node_tree.nodes if n.bl_idname=='ShaderNodeValToRGB')
    ramp.color_ramp.elements[0].color=rgba('#84513e');ramp.color_ramp.elements[1].color=rgba('#b6815f')
    circle=[Vector((r*cos(2*pi*i/128),0,r*sin(2*pi*i/128))) for i in range(128)]
    paint_shape(circle,red,y+.0003,'paint.taegeuk red disk on boards')
    outline=[Vector((-p.z,0,-p.x)) for p in outline]
    paint_shape(outline,M['blue'],y,'paint.taegeuk blue on boards')

def stone(name,center,size):
    ob=box(name,center,size,M['stone'],min(.018,min(size)*.08))
    su=ob.modifiers.new('stone face tessellation','SUBSURF');su.subdivision_type='SIMPLE';su.levels=3;su.render_levels=3
    tex=bpy.data.textures.get('stone chisel') or bpy.data.textures.new('stone chisel','CLOUDS');tex.noise_scale=.065;tex.noise_depth=2
    di=ob.modifiers.new('low chisel relief','DISPLACE');di.texture=tex;di.strength=.009;di.mid_level=.5
    return ob

def fieldstone(name,center,size,seed):
    """A dressed walking face with uneven perimeter, not inflated rounded boxes."""
    rng=random.Random(seed);w,d,h=size;cx,cy,cz=center
    cut=[rng.uniform(.08,.19) for _ in range(4)]
    outline=[(-.5+cut[0],-.5),(.5-cut[1],-.5),(.5,-.5+cut[1]),(.5,.5-cut[2]),(.5-cut[2],.5),(-.5+cut[3],.5),(-.5,.5-cut[3]),(-.5,-.5+cut[0])]
    vs=[]
    for z in (-h/2,h/2):
        for x,y in outline:
            vs.append((cx+x*w,cy+y*d+rng.uniform(-.009,.009),cz+z+(rng.uniform(-.003,.003) if z>0 else 0)))
    fs=[tuple(range(7,-1,-1)),tuple(range(8,16))]+[(i,(i+1)%8,(i+1)%8+8,i+8) for i in range(8)]
    ob=mesh(name,vs,fs,M['stone'],.007)
    su=ob.modifiers.new('broad dressed face relief','SUBSURF');su.subdivision_type='SIMPLE';su.levels=3;su.render_levels=3
    tex=bpy.data.textures.get('fieldstone broad relief') or bpy.data.textures.new('fieldstone broad relief','CLOUDS');tex.noise_scale=.18;tex.noise_depth=1
    di=ob.modifiers.new('shallow uneven dressing','DISPLACE');di.texture=tex;di.strength=.006;di.mid_level=.5
    ob['surfaceRole']='irregular dressed walking stone';return ob

def foundation(c):
    if KEY!='shrine':
        import measured_assemblies
        return measured_assemblies.foundation(sys.modules[__name__],c)
    if KEY=='shrine':
        for sx in (-1,1):stone('foundation.shinbangseok', (sx*c['axis']/2,0,.10),(.305,1.48,.20))
        stone('foundation.threshold', (0,0,.103),(1.12,.28,.206))
        return
    # Set the top landing at the bottom of the long post footings.
    landing=c['floor']-.14;rise=landing/c['steps'];tread=.32 if KEY=='right' else .27
    core_sections=[]
    for level in range(c['steps']):
        width=c['axis']+.55+(c['steps']-1-level)*.10
        y=-.85-(c['steps']-1-level)*tread
        top=(level+1)*rise;back=.88
        start=y-tread/2+.045
        if core_sections:
            old=core_sections[-1];core_sections.append((start-.002,old[1],old[2]))
        core_sections.append((start,width-.18,top-.07))
        nr=3 if level%2==0 else 4;rng=random.Random(5300+level+(100 if KEY=='left' else 0))
        weights=[rng.uniform(.75,1.3) for _ in range(nr)];total=sum(weights);xx=-width/2
        for j,weight in enumerate(weights):
            ww=width*weight/total
            fieldstone('foundation.step %d block %d'%(level+1,j+1),(xx+ww/2,y,top-rise*.52),(ww-.009,tread+.045,rise*1.04),5000+level*10+j)
            xx+=ww
    # One closed stepped core. Separate nested boxes had coplanar rear faces.
    core_sections.append((.88,core_sections[-1][1],core_sections[-1][2]))
    vs=[(x,y,z) for y,w,h in core_sections for x,z in [(-w/2,0),(w/2,0),(w/2,h),(-w/2,h)]]
    fs=[(3,2,1,0),tuple(range(len(vs)-4,len(vs)))]
    for j in range(len(core_sections)-1):
        fs.extend((j*4+k,j*4+(k+1)%4,(j+1)*4+(k+1)%4,(j+1)*4+k) for k in range(4))
    mesh('foundation.compacted backing',vs,fs,M['earth'],.006)
    # Modelled landing and soil carry the rear portions of both footings.
    fieldstone('foundation.rear landing',(0,.10,landing-.045),(c['axis']+.55,1.64,.09),891)
    for sx in (-1,1):stone('foundation.post footing',(sx*c['axis']/2,0,c['floor']-.07),(.31,1.40,.14))

def timber(c):
    if KEY!='shrine':
        import measured_assemblies
        return measured_assemblies.timber(sys.modules[__name__],c)
    wood=M['red'] if KEY=='shrine' else M['wood'];under=M['green'] if KEY=='shrine' else wood
    base=c['floor'];head=c['head'];p=c['post'];ax=c['axis']/2
    for sx in (-1,1):
        if KEY=='shrine':cylinder('timber.round main post',(sx*ax,0,base),(sx*ax,0,head),p/2,wood,48)
        else:beam('timber.main post',(sx*ax,0,base),(sx*ax,0,head),p,p,wood,.005)
        for sy in (-1,1):
            if KEY=='left':
                beam('timber.side brace',(sx*(ax+.22),sy*.65,base),(sx*ax,0,head*.58),.068,.075,wood)
            else:beam('timber.fore aft support',(sx*ax,sy*c['support'],base),(sx*ax,sy*c['support'],c['head']-.08 if KEY=='shrine' else dori_bottom(c)),.07,.08,wood)
        # Front and rear dori supported at the side members.
        if KEY=='shrine':
            ob=horizontal_timber('timber.dori',(sx*ax,-.9,c['head']-.075),(sx*ax,.9,c['head']-.075),.082,.15,under);soften_timber_tail(ob)
            ob['drawing']='087 longitudinal section: 82x150; 086 ceiling plan, Y direction'
        else:
            ob=horizontal_timber('timber.side changbang',(sx*ax,-c['support']-.08,dori_bottom(c)-.0525),(sx*ax,c['support']+.08,dori_bottom(c)-.0525),.072,.105,under);soften_timber_tail(ob)
    if KEY=='shrine':
        horizontal_timber('timber.central changbang',(-ax,0,c['head']-.15-.0525),(ax,0,c['head']-.15-.0525),.072,.105,under)
        for yy in (-.5,.5):
            ob=horizontal_timber('timber.cross bearing 70x80',(-1.089,yy,c['head']-.04),(1.089,yy,c['head']-.04),.07,.08,under)
            ob['drawing']='086 ceiling plan / 087 70x80 longitudinal section'
    else:
        for yy in (-c['support'],0,c['support']):
            ob=horizontal_timber('timber.dori',(-ax-.4,yy,dori_bottom(c)+.075),(ax+.4,yy,dori_bottom(c)+.075),.082,.15,under);soften_timber_tail(ob)
    horizontal_timber('timber.upper door jamb',(-ax,0,c['doorBase']+c['doorH']+.045),(ax,0,c['doorBase']+c['doorH']+.045),.072,.09,wood)
    horizontal_timber('timber.sill',(-ax,0,base+.075),(ax,0,base+.075),.072,.15,wood)
    for sx in (-1,1):
        beam('timber.side door jamb',(sx*(c['door']/2+.036),0,c['doorBase']-.035),(sx*(c['door']/2+.036),0,c['doorBase']+c['doorH']+.035),.072,.09,wood)
    bw=c['door']/c['boards']
    for j in range(c['boards']):
        x=-c['door']/2+(j+.5)*bw;gap=.004 if j==c['boards']//2 else .0015
        ob=box('door.board %02d'%(j+1),(x,0,c['doorBase']+c['doorH']/2),(bw-gap,c['doorT'],c['doorH']),wood,.00065)
        ob['drawingThickness']=c['doorT'];ob['drawingHeight']=c['doorH']
        if j!=c['boards']//2 and j>0:
            box('door.rebated plank joint',(x-bw/2,.003,c['doorBase']+c['doorH']/2),(.012,c['doorT']*.65,c['doorH']-.002),wood,.0004)
    for sx in (-1,1):
        for k,z in enumerate((c['doorBase']+.14,c['doorBase']+c['doorH']*.5,c['doorBase']+c['doorH']-.14)):
            thick,hei=(.034,.054) if k==1 else (.065,.095)
            if KEY=='left':thick,hei=(.045,.060) if k==1 else (.090,.075)
            horizontal_timber('door.rear rail', (sx*c['door']/4-c['door']/4+.02,c['doorT']/2+thick/2,z),(sx*c['door']/4+c['door']/4-.02,c['doorT']/2+thick/2,z),thick,hei,wood,.0015)
        for z in (c['doorBase']-.015,c['doorBase']+c['doorH']+.015):
            cylinder('door.wood pivot',(sx*(c['door']/2-.05),0,z-.035),(sx*(c['door']/2-.05),0,z+.035),.019,wood)
        if KEY=='shrine':
            # 086: outer height 1600 = 40 above + 1500 panel + 60 below.
            for role,zz,hh in [('lower',c['doorBase']-.0175,.085),('upper',c['doorBase']+c['doorH']-.015,.110)]:
                ob=box('door.pivot housing '+role,(sx*(c['door']/2-.105),.052,zz),(.210,.073,hh),wood,.0015)
                ob['drawing']='086 '+('73x85x210' if role=='lower' else '73x110x210')
    ob=box('door.sliding wooden bolt',(.075,.09,c['doorBase']+c['doorH']*.5),(.52,.027,.054),wood,.002)
    ob['drawing']='086/088 asymmetric bolt length and placement traced, section27x54'
    for xx in (-.16,.16):
        ob=box('door.bolt keeper',(xx,.09,c['doorBase']+c['doorH']*.5),(.060,.07,.350),wood,.003)
        ob['drawing']='086/088 outline traced against1500 panel; not a printed350 dimension'
    for j in range(c['rafters']):
        x=(-1+2*j/(c['rafters']-1))*c.get('rafterHalf',c['barge']-.07)
        if KEY=='shrine':x=[-1.0515,-.675,-.3375,0,.3375,.675,1.0515][j]
        ob=shaped_rafter(c,x,j,under)
        ob['section_mm']='round 90 interpreted' if KEY=='left' else '75x90';ob['drawingEvidence']='left eaves photograph' if KEY=='left' else '087; other gates assembly interpretation'
    boardLength=1.8 if KEY=='shrine' else c['d']-.16
    nboards=math.ceil(boardLength/.19);bw=boardLength/nboards
    for j in range(nboards):
        yy=-boardLength/2+(j+.5)*bw
        bh=c.get('boardingHalf',c['barge']+.045)
        xs=[-bh+i*2*bh/24 for i in range(25)]
        grid=[[(x,y,deck_top(c)+rafter_lift(c,x,y)) for x in xs] for y in (yy-(bw-.002)/2,yy+(bw-.002)/2)]
        ob=shell('roof.boarding THK30 plank %02d'%j,grid,wood,.03,.0006);longitudinal_grain(ob,(1,0,0))
        ob['thickness_mm']=30;ob['individualBoard']=True
    if KEY=='left':
        centers=[(-1+2*j/(c['rafters']-1))*(c['barge']-.07) for j in range(c['rafters'])]
        for sy in (-1,1):
            yy=sy*(c['d']/2-.125)
            for j,(a,b) in enumerate(zip(centers[:-1],centers[1:])):
                grid=[[(x,y,deck_top(c)-.032+rafter_lift(c,x,y)) for x in [a+.041+(b-a-.082)*i/12 for i in range(13)]] for y in (yy-.025,yy+.025)]
                ob=shell('roof.recessed lime infill %s %s'%(sy,j),grid,M['plaster'],.061,.002)
                ob['evidence']='left front and rear photographs; spacing inferred'
    hardware(c)
    if KEY=='shrine':
        for sx in (-1,1):
            for z in (c['doorBase']+.035,c['doorBase']+c['doorH']-.035):
                ob=box('iron.corner strap',(sx*(c['door']/2-.075),-c['doorT']/2-.003,z),(.145,.006,.018),M['iron'],.002)
                ob['drawing']='086 front door corner ironwork; outline traced'
        taegeuk(c)

def roof(c):
    if KEY!='shrine':
        import measured_assemblies
        measured_assemblies.roof_underlay(sys.modules[__name__],c)
        ceramic_roof(c)
        return
    W=c['w'];D=c['d'];B=c['barge'];rows=c['roofRows'];step=D/2/rows
    # Surface datum from elevation; ridge courses occupy the remaining height.
    crest=c['peak']-.255;ev=c['eave'];xmax=W/2
    def zbase(x,y):return roof_surface(c,x,y)
    # Fill is internal. The former full-height closure was an exposed beige fascia.
    earth=[]
    for j in range(41):
        yy=-D/2+.16+j*(D-.32)/40
        earth.append([(xx,yy,zbase(xx,yy)-.055) for xx in [-B+.04+i*(2*B-.08)/40 for i in range(41)]])
    core=shell('roof.compacted earth surface',earth,M['earth'],.08,.002)
    half=len(core.data.vertices)//2
    for v in core.data.vertices[half:]:
        xx,yy,zz=v.co;edge=max(0,min(1,(abs(xx)-(B-.10))/(xmax-B+.10)))
        v.co.z=min(zz+.04,deck_top(c)*(1-edge)+(zbase(xx,yy)-.095)*edge)
    core['eaveSetback_mm']=160;core['sideSetback_mm']=(xmax-B+.04)*1000
    wood=M['red'] if KEY=='shrine' else M['wood']
    under=M['green'] if KEY=='shrine' else wood
    # 30 mm gable lining contains the earthen packing. Horizontal board courses
    # expose their joints rather than showing the packing as a flat beige face.
    def clipz(poly,level,keepAbove):
        result=[]
        for a,b in zip(poly,poly[1:]+poly[:1]):
            ina=a[1]>=level if keepAbove else a[1]<=level
            inb=b[1]>=level if keepAbove else b[1]<=level
            if ina:result.append(a)
            if ina!=inb:
                t=(level-a[1])/(b[1]-a[1]);result.append((a[0]+t*(b[0]-a[0]),level))
        return result
    for sx in (-1,1):
        xx=sx*(B-.019);ys=[-D/2+.15+j*(D-.30)/40 for j in range(41)]
        outline=[(y,zbase(xx,y)-.052) for y in ys]+[(ys[-1],deck_top(c)-.005),(ys[0],deck_top(c)-.005)]
        for j in range(math.ceil((c['peak']-deck_top(c))/.14)):
            bottom=deck_top(c)-.006+j*.14;top=bottom+.1385
            polygon=clipz(clipz(outline,bottom,True),top,False)
            if len(polygon)>2:
                ob=profile_solid('roof.gable lining THK30 %s %s'%(sx,j),polygon,xx-.015,xx+.015,wood);longitudinal_grain(ob,(0,1,0))
                ob['evidence']='087 gable THK30; horizontal course joints interpreted'
    # Separate timber lining and supporting ribs under the side roof wings.
    # The earthen packing is internal, never an exposed beige diagonal face.
    strips=math.ceil((D-.10)/.18);stripWidth=(D-.10)/strips
    for sx in (-1,1):
        xs=[sx*(B-.025+(xmax-B+.005)*i/8) for i in range(9)]
        for j in range(strips):
            yy=-D/2+.05+(j+.5)*stripWidth
            grid=[[(x,roof_corner_y(c,x,y),zbase(x,roof_corner_y(c,x,y))-.05) for x in xs] for y in (yy-(stripWidth-.002)/2,yy+(stripWidth-.002)/2)]
            ob=shell('roof.wing boarding THK30 %s %s'%(sx,j),grid,wood,.03,.0008);longitudinal_grain(ob,(1,0,0))
            ob['evidence']='timber-lined side return; assembly interpretation'
        for sy in (-1,0,1):
            yy=sy*c['support'];grid=[]
            for y in (yy-.0375,yy+.0375):grid.append([(x,y,zbase(x,y)-.081) for x in xs])
            ob=shell('roof.wing support rib %s %s'%(sx,sy),grid,under,.075,.002);longitudinal_grain(ob,(1,0,0))
            ob['evidence']='side return support; assembly interpretation'
    # Only a thin tile-setting bed reaches the timber edge. The deep fill stays back.
    for sy in (-1,1):
        grid=[]
        for j in range(5):
            yy=sy*(D/2-.18+.168*j/4)
            grid.append([(xx,yy,zbase(xx,yy)+.003) for xx in [-B-.035+i*(2*B+.07)/40 for i in range(41)]])
        ob=shell('roof.eave thin tile bedding',grid,M['eaveBed'],.038,0)
        ob['thickness_mm']=38;ob['materialRole']='internal bedding closes the tile/boarding seam'
    # A 30mm horizontal boarding nose, rather than a deep vertical fascia.
    for sy in (-1,1):
        xs=[-B-.035+i*(2*B+.07)/40 for i in range(41)]
        grid=[[(x,y,deck_top(c)+rafter_lift(c,x,y)) for x in xs] for y in (sy*(D/2-.079),sy*(D/2-.025))]
        ob=shell('roof.eave timber edge',grid,M['eaveEdge'],.03,.001);longitudinal_grain(ob,(1,0,0))
        ob['materialRole']='30mm horizontal boarding nose; visible rafter head below'
    # Barge boards follow the side elevation, with an open underside below.
    for sx in (-1,1):
        xx=sx*(xmax-.015)
        for sy in (-1,1):
            ys=[roof_corner_y(c,xx,sy*j*D/2/28) for j in range(29)]
            upper=[(y,zbase(xx,y)-.05) for y in ys]
            # 088 side: a straight lower arris, not a second sagging roof curve.
            lower=[(y,(zbase(xx,0)-.255)*(1-abs(y)/(D/2))+(zbase(xx,sy*D/2)-.255)*(abs(y)/(D/2))) for y in reversed(ys)]
            lowerForward=list(reversed(lower));middle=[(u[0],(u[1]+v[1])*.5) for u,v in zip(upper,lowerForward)]
            for part,topline,bottomline in [(0,upper,[(y,z+.0008) for y,z in middle]),(1,[(y,z-.0008) for y,z in middle],lowerForward)]:
                ob=profile_solid('roof.diagonal barge board plank '+str(part),topline+list(reversed(bottomline)),xx-.015,xx+.015,wood)
                longitudinal_grain(ob,(0,sy*D/2,ev-crest));ob['jointEvidence']='board joint interpretation within original 30mm barge outline'
    ceramic_roof(c)

def ceramic_roof(c):
    W=c['w'];D=c['d'];B=c['barge'];rows=c['roofRows'];step=D/2/rows
    crest=c['peak']-.255;ev=c['eave'];xmax=W/2
    def zbase(x,y):return roof_surface(c,x,y)
    # Main pan lanes, their overlapped ends are actual 12mm ceramic edges.
    centers=[(j-(c['covers']-1)/2)*c['pitch'] for j in range(c['covers'])]
    lanes=[-B]+centers+[B]
    for side in (-1,1):
        for row in range(rows):
            y0=row*step;y1=min(D/2,y0+step+.055)
            overlap=.004
            for lane,(a,b) in enumerate(zip(lanes[:-1],lanes[1:])):
                grid=[]
                for j in range(7):
                    y=side*(y0+(y1-y0)*j/6)
                    grid.append([(a+(b-a)*i/10,y,zbase(a+(b-a)*i/10,y)+.022*(2*i/10-1)**2+overlap+.020*j/6) for i in range(11)])
                ob=shell('roof.pan.s%d.r%d.l%d'%(side,row,lane),grid,M['clay']);ob['ceramicRole']='pan'
            for lane,x in enumerate(centers):
                grid=[];radius=.071
                for j in range(7):
                    y=side*(y0+(y1-y0)*j/6)
                    # Taper: downstream tile mouth slightly wider.
                    rr=radius*(.92+.08*j/6)
                    grid.append([(x-rr*cos(pi*i/16),y,zbase(x-rr*cos(pi*i/16),y)+.025+.057*sin(pi*i/16)+overlap+.020*j/6) for i in range(17)])
                ob=shell('roof.cover.s%d.r%d.l%d'%(side,row,lane),grid,M['clay']);ob['ceramicRole']='cover'
                if row==rows-1:
                    points=[(x-radius*cos(pi*i/24),side*(D/2-.0045),zbase(x-radius*cos(pi*i/24),side*D/2)+.046+.057*sin(pi*i/24)+overlap) for i in range(25)]
                    path_tube('roof.cover lip',points,.0045,M['clay'])
                    if c['limeEnds']:
                        # Photo evidence: recessed half-moon lime closures, never spherical white caps.
                        cap=[(x-.058*cos(pi*i/32),side*(D/2-.010),zbase(x,side*D/2)+.048+.044*sin(pi*i/32)) for i in range(33)]
                        vv=cap+[(a,b-side*.018,d) for a,b,d in cap];nn=len(cap)
                        ob=mesh('roof.lime half moon closure',vv,[tuple(range(nn-1,-1,-1)),tuple(range(nn,2*nn))]+[(i,(i+1)%nn,(i+1)%nn+nn,i+nn) for i in range(nn)],M['plaster'],.001)
                        ob['sourceDetail']='photo-right-front / sadangmun-front-sep29; lime within mouth'
    # Short transverse tile fields at each gable, supported by the roof body.
    for sx in (-1,1):
        wingrows=max(4,round(D/.25))
        for j in range(wingrows):
            yc=-D/2+(j+.5)*D/wingrows
            for cover in (False,True):
                grid=[]
                for k in range(8):
                    xx=sx*(B+(xmax-B)*k/7)
                    hw=.064 if cover else D/wingrows*.52
                    row=[]
                    for i in range(15):
                        yy=roof_corner_y(c,xx,max(-D/2,min(D/2,yc-hw+2*hw*i/14)))
                        zz=zbase(xx,yy)+(.033+.052*sin(pi*i/14) if cover else .02*(2*i/14-1)**2)
                        row.append((xx,yy,zz))
                    grid.append(row)
                shell('roof.wing '+('cover' if cover else 'pan'),grid,M['clay'])
    # Three layers of laid ridge tiles under a distinct top cap.
    for sx in (-1,1):
        x=sx*B
        for side in (-1,1):
            for level in range(3):
                width=.14-level*.012
                grid=[]
                for j in range(35):
                    y=side*(.05+(D/2-.07)*j/34)
                    grid.append([(x-width+i*width/2,y,zbase(x,y)+.025+level*.028+.008*(1-(i/2-1)**2)) for i in range(5)])
                shell('roof.barge course %d'%level,grid,M['clay'],.0285,0)
            for row in range(rows):
                y0=.04+row*(D/2-.06)/rows;y1=min(D/2-.01,y0+(D/2-.06)/rows+.03)
                grid=[]
                for j in range(7):
                    y=side*(y0+(y1-y0)*j/6)
                    radius=.084+.006*j/6
                    grid.append([(x-radius*cos(pi*i/18),y,zbase(x,y)+.104+.067*sin(pi*i/18)+(rows-row)*.003) for i in range(19)])
                shell('roof.barge cap tile',grid,M['clay'],.014,0)
            y=side*(D/2-.012);zz=zbase(x,y)+.105
            cap=[(x-.086*cos(pi*i/32),y,zz+.064*sin(pi*i/32)) for i in range(33)]
            vv=cap+[(a,b-side*.012,d) for a,b,d in cap];nn=len(cap)
            mesh('roof.barge end face',vv,[tuple(range(nn-1,-1,-1)),tuple(range(nn,2*nn))]+[(i,(i+1)%nn,(i+1)%nn+nn,i+nn) for i in range(nn)],M['clay'],.001)
            for rr in (.032,.055):
                path_tube('roof.barge end relief',[(x-rr*cos(pi*i/20),y+side*.001,zz+.003+rr*.70*sin(pi*i/20)) for i in range(21)],.0022,M['clay'],8)
    # Segmented main ridge; five courses on 090, three on 086-088.
    reach=B+.1;segment=.26;nseg=math.ceil(2*reach/segment)
    # The laid ridge courses bear on a closed tile bed, not an unsupported black slit.
    grid=[]
    for j in range(41):
        x=-reach+2*reach*j/40
        grid.append([(x,y,crest+.008+.065*(abs(x)/reach)**4) for y in (-.12,0,.12)])
    ob=shell('roof.ridge bedding',grid,M['clay'],.08,.001)
    for v in ob.data.vertices[len(ob.data.vertices)//2:]:v.co.z=zbase(v.co.x,v.co.y)+.004
    for level in range(c['levels']):
        half=.12-level*.007
        for j in range(nseg+1):
            # Butt joints with staggered courses: overlapping coplanar side faces
            # previously produced black rectangles, unrelated to the drawing.
            a=max(-reach,-reach+2*reach*(j-.5*(level%2))/nseg)+.0003
            b=min(reach,-reach+2*reach*(j+1-.5*(level%2))/nseg)-.0003
            if b<=a:continue
            grid=[]
            for k in range(8):
                x=a+(b-a)*k/7;z=crest+.032+level*.028+.065*(abs(x)/reach)**4
                grid.append([(x,-half+i*half/3,z+.012*(1-(i/3-1)**2)) for i in range(7)])
            shell('roof.main ridge course %d'%level,grid,M['clay'],.0285,0)
    capbase=crest+.032+c['levels']*.028
    for j in range(nseg):
        a=-reach+2*reach*j/nseg+.0003;b=-reach+2*reach*(j+1)/nseg-.0003
        grid=[]
        for k in range(7):
            x=a+(b-a)*k/6;z=capbase+.065*(abs(x)/reach)**4
            grid.append([(x,-.073*cos(pi*i/18),z+.06*sin(pi*i/18)) for i in range(19)])
        shell('roof.main ridge cap',grid,M['clay'],.013,0)
    # Restrained thin end finials, profile read from the drawing.
    for sx in (-1,1):
        xx=sx*(reach-.02);points=[(-.105,capbase+.055),(-.09,c['peak']-.025),(0,c['peak']),(.09,c['peak']-.025),(.105,capbase+.055)]
        profile_solid('roof.ridge end finial',points,xx-.015,xx+.015,M['clay'])

def set_camera(sc,view,c):
    target=Vector((0,-.04,c['peak']*.48))
    if view=='hero':direction=Vector((1.15,-2.2,1.05));scale=max(c['peak'],c['w'])*1.32
    elif view=='front':direction=Vector((0,-1,0));scale=c['peak']*1.15
    elif view=='side':direction=Vector((1,0,0));scale=c['peak']*1.15
    elif view=='back':direction=Vector((0,1,0));scale=c['peak']*1.15
    elif view=='eaves':
        comparison_height=c['eave']
        target=Vector((0,-c['d']/2+.10,comparison_height+.09));direction=Vector((.3,-3,-.15));scale=c['w']*1.12
    elif view=='door':
        target=Vector((0,0,c['doorBase']+c['doorH']*.5));direction=Vector((.12,-3,.12));scale=max(c['doorH'],c['door'])*1.12
    elif view=='stone':
        target=Vector((0,-.70,c['floor']*.50));direction=Vector((.8,-2,1.0));scale=c['axis']+1.05
    elif view=='underside':
        target=Vector((0,-.10,deck_top(c)-.11));direction=Vector((1.05,-3,-.95));scale=c['w']*1.08
    elif view=='arrival':direction=Vector((.8,-3,.28));scale=max(c['peak'],c['w'])*1.24
    else:direction=Vector((0,0,1));scale=max(c['w'],c['d'])*1.15;target=Vector((0,0,1.5))
    direction.normalize()
    if view in ('hero','front','side','back','plan','arrival'):
        # Fit actual gate geometry, including the 1850mm approach of 092.
        # A roof-only bounding box cut the bottom stair off the side/plan views.
        q=(-direction).to_track_quat('-Z','Y');right=q@Vector((1,0,0));up=q@Vector((0,1,0))
        points=[o.matrix_world@Vector(p) for o in sc.objects if o.type=='MESH' and o.get('owner')==KEY and not o.get('studio') for p in o.bound_box]
        if points:
            xx=[p.dot(right) for p in points];zz=[p.dot(up) for p in points]
            target+=right*((min(xx)+max(xx))/2-target.dot(right))+up*((min(zz)+max(zz))/2-target.dot(up))
            scale=max(max(xx)-min(xx),max(zz)-min(zz))*1.14
    cam=sc.camera;cam.location=target+direction*20;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=scale

def studio(sc,c):
    global COL,KEY
    col=bpy.data.collections.new('Studio.'+KEY);sc.collection.children.link(col);saved=COL;COL=col
    ground=box('studio.ground',(0,0,-.055),(200,200,.1),M['ground'],0);ground['studio']=True
    cam=bpy.data.objects.new('Camera.'+KEY,bpy.data.cameras.new('Camera.'+KEY));col.objects.link(cam);sc.camera=cam;cam.data.type='ORTHO';cam.data.lens=55
    for name,loc,power,size,color in [('key',(-3.5,-4,6.8),850,3.5,(1,.87,.72)),('fill',(4,-2,4),180,4,(.82,.90,1)),('rim',(0,4,5.5),400,3,(1,.94,.82))]:
        li=bpy.data.lights.new(name+'.'+KEY,'AREA');li.energy=power;li.shape='DISK';li.size=size;li.color=color
        ob=bpy.data.objects.new(li.name,li);col.objects.link(ob);ob.location=loc;ob.rotation_euler=(Vector((0,0,1.5))-ob.location).to_track_quat('-Z','Y').to_euler()
    sc.world=bpy.data.worlds.new('Warm neutral.'+KEY);sc.world.use_nodes=True;bg=sc.world.node_tree.nodes.get('Background');bg.inputs[0].default_value=(.55,.60,.65,1);bg.inputs[1].default_value=.35
    sc.render.engine='CYCLES';sc.cycles.samples=48;sc.cycles.use_denoising=True;sc.cycles.max_bounces=6
    sc.render.resolution_x=1400;sc.render.resolution_y=1400;sc.render.resolution_percentage=100
    sc.render.image_settings.file_format='PNG';sc.render.image_settings.color_mode='RGBA'
    sc.view_settings.view_transform='AgX';sc.view_settings.look='AgX - Medium High Contrast';sc.view_settings.exposure=0
    set_camera(sc,'hero',c);COL=saved
    try:
        prefs=bpy.context.preferences.addons['cycles'].preferences;prefs.compute_device_type='OPTIX';prefs.get_devices()
        gpu=False
        for d in prefs.devices:d.use=d.type=='OPTIX';gpu=gpu or d.use
        if gpu:sc.cycles.device='GPU'
    except Exception:pass

def run():
    global COL,KEY,M
    manifest=json.loads((OUT/'manifest.json').read_text(encoding='utf-8')) if (OUT/'manifest.json').exists() else {'nativeFiles':[],'renders':[]}
    manifest.update(status='new-native-build-in-progress',legacyMeshesImported=0,legacyMaterialsImported=0,sourceBlend=None,fullDrawingMatchClaimed=False,configuration=CONFIG,
                    geometryDesignApprovedByUser=True,surfaceApprovedByUser=False,surfaceRevision='R6c full-length timber grain and calm dressed stone',
                    surfaceSourceReceipt='reference-textures/source-receipt.json',geometryBaselineCommit='bbe88e7')
    args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
    parser=argparse.ArgumentParser();parser.add_argument('gates',nargs='*');parser.add_argument('--views',default='hero,front,side,back,plan,eaves');parser.add_argument('--draft',action='store_true')
    opts=parser.parse_args(args);selected=opts.gates or list(CONFIG);views=opts.views.split(',')
    for key in selected:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        M={k:material('Fresh | '+k,k) for k in ['wood','red','blue','green','clay','stone','earth','plaster','iron','ground']}
        if key=='shrine':
            for kind,lo,hi in [('red','#542d2a','#80443a'),('green','#2d4036','#47654f'),('plaster','#888378','#aaa598')]:
                painted_ramp=next(n for n in M[kind].node_tree.nodes if n.type=='VALTORGB')
                painted_ramp.color_ramp.elements[0].color=rgba(lo)
                painted_ramp.color_ramp.elements[1].color=rgba(hi)
                M[kind]['shrinePalette']='R6 | sadang parent lacquer family'
            clay_nodes=M['clay'].node_tree.nodes;clay_links=M['clay'].node_tree.links
            clay_bs=next(n for n in clay_nodes if n.type=='BSDF_PRINCIPLED')
            clay_color=clay_bs.inputs['Base Color'].links[0].from_socket
            clay_nodes['Clay broad tones'].inputs['To Min'].default_value=.34
            clay_nodes['Clay broad tones'].inputs['To Max'].default_value=1.66
            clay_nodes['Clay micro bump'].inputs['Strength'].default_value=.15
            clay_nodes['Clay micro bump'].inputs['Distance'].default_value=.0009
            # Use continuous native clay color. The tile atlas can reveal its
            # grid when used as color, so it contributes only bump/roughness.
            clay_tint=clay_nodes.new('ShaderNodeMixRGB');clay_tint.blend_type='MULTIPLY'
            clay_tint.inputs[0].default_value=.80;clay_tint.inputs[2].default_value=(.48,.54,.62,1)
            clay_links.new(clay_color,clay_tint.inputs[1]);clay_links.new(clay_tint.outputs[0],clay_bs.inputs['Base Color'])
            M['clay']['shrinePalette']='R6b | sadang parent charcoal tile with seamless ceramic tones'
        M['eaveBed']=M['earth'].copy();M['eaveBed'].name='Fresh | eave bedding'
        bed_ramp=next(n for n in M['eaveBed'].node_tree.nodes if n.type=='VALTORGB')
        bed_ramp.color_ramp.elements[0].color=rgba('#383735')
        bed_ramp.color_ramp.elements[1].color=rgba('#595650')
        M['eaveBed']['surfaceRevision']='R6 | dark compacted earthen bedding at ceramic seam'
        M['eaveEdge']=M['wood'].copy();M['eaveEdge'].name='Fresh | eave timber edge'
        edge_nodes=M['eaveEdge'].node_tree.nodes;edge_links=M['eaveEdge'].node_tree.links
        edge_bs=next(n for n in edge_nodes if n.type=='BSDF_PRINCIPLED')
        edge_color=edge_bs.inputs['Base Color'].links[0].from_socket
        edge_tint=edge_nodes.new('ShaderNodeMixRGB');edge_tint.blend_type='MULTIPLY'
        edge_tint.inputs[0].default_value=.24;edge_tint.inputs[2].default_value=(.55,.52,.48,1)
        edge_links.new(edge_color,edge_tint.inputs[1]);edge_links.new(edge_tint.outputs[0],edge_bs.inputs['Base Color'])
        M['eaveEdge']['surfaceRevision']='R6 | shaded timber board nose at ceramic seam'
        if key=='shrine':M['eaveEdge']=M['red']
        KEY=key;c=CONFIG[key]
        sc=bpy.data.scenes.new(c['title']+' | New drawing construction');bpy.context.window.scene=sc
        COL=bpy.data.collections.new('Drawing built.'+key);sc.collection.children.link(COL)
        print('Building from empty scene:',key,flush=True)
        foundation(c);timber(c);roof(c);studio(sc,c)
        sc['drawingSource']=c['sheet'];sc['legacyMeshCount']=0;sc['elevationSourceAvailable']=c['verifiedElevation'];sc['fullDrawingMatchClaimed']=False
        sc['eavesRevision']='R4: recovered complete 2007 drawings; separate measured assemblies'
        sc['surfaceRevision']='R6c: timber grain and dressed stone; shrine palette aligned; native mesh unchanged'
        if key=='shrine':sc['taegeukRevision']='photo-facing red disk, lower blue and upper-right lobe'
        bpy.context.view_layer.update()
        set_camera(sc,'hero',c)
        path=OUT/(key+'-new.blend');bpy.ops.wm.save_as_mainfile(filepath=str(path),compress=True)
        manifest['nativeFiles']=[v for v in manifest['nativeFiles'] if v['gate']!=key]
        manifest['nativeFiles'].append({'gate':key,'path':str(path),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
        for view in views:
            set_camera(sc,view,c)
            transparent=view!='hero';sc.render.film_transparent=transparent
            for ob in sc.objects:
                if ob.get('studio'):ob.hide_render=transparent
            sc.render.filepath=str(OUT/(key+'-'+view+'.png'))
            if view in ('front','side','back','plan'):sc.cycles.samples=24;sc.render.resolution_x=1000;sc.render.resolution_y=1000
            elif view in ('eaves','underside'):sc.cycles.samples=48;sc.render.resolution_x=1600;sc.render.resolution_y=1000 if view=='underside' else 900
            else:sc.cycles.samples=48;sc.render.resolution_x=1400;sc.render.resolution_y=1400
            if opts.draft:sc.cycles.samples=12;sc.render.resolution_percentage=65
            (OUT/'render-state.json').write_text(json.dumps(dict(gate=key,view=view,status='rendering')))
            bpy.ops.render.render(write_still=True,scene=sc.name)
            manifest['renders']=[v for v in manifest['renders'] if (v['gate'],v['view'])!=(key,view)]
            manifest['renders'].append({'gate':key,'view':view,'file':sc.render.filepath,'camera':list(sc.camera.location),'orthoScale':sc.camera.data.ortho_scale,'nativeSha256':hashlib.sha256(path.read_bytes()).hexdigest(),'draft':opts.draft})
            (OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
        set_camera(sc,'hero',c)
    counts=manifest.get('objectCounts',{});counts.update(COUNTS)
    manifest.update(status='new-build-rendered-needs-surface-review',objectCounts=counts)
    (OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
    (OUT/'render-state.json').write_text(json.dumps(dict(status='completed',renders=len(manifest['renders']))),encoding='utf-8')
    print('FRESH BUILD FINISHED',COUNTS,flush=True)

if __name__=='__main__':run()
