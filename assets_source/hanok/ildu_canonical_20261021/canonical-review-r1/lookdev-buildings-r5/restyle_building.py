"""R5 brush language, adapted to one native building without any mesh edits."""
import bpy, importlib.util, json, sys, time, hashlib, math
from pathlib import Path
from mathutils import Vector

HOME=Path(__file__).resolve().parent
sys.path.insert(0,str(HOME))
from material_rules import category
spec=importlib.util.spec_from_file_location('r5',HOME.parent/'lookdev-sarang-r5/layered_materials.py')
art=importlib.util.module_from_spec(spec);spec.loader.exec_module(art)
r2=art.r2;s=art.s
VERSION='building-r5-2'
WOOD=None
WOOD_MEAN=None

def write(path,value):
    path.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

def scalar(t,op,a,b=None,label=''):
    return art.mathn(t,op,a,b,'Building R5 '+label)

def constant(t,value,label):
    n=r2.node(t,'ShaderNodeRGB',label);n.outputs[0].default_value=value;return n.outputs[0]

def original_color(t,b):
    slot=b.inputs['Base Color']
    return slot.links[0].from_socket if slot.is_linked else constant(t,tuple(slot.default_value),'Unmodified source colour')

def mapping(ob,role):
    available={uv.name for uv in ob.data.uv_layers}
    choices={
      'wood':['Gye cared member grain v52','Gye member grain v25','Gye main gate painted grain','Craft timber metres','Painted timber metres','Reference timber grain'],
      'tile':['Gye cared ceramic metres v52','Gye ceramic metres','Anchae whole roof painting'],
      'stone':['Gye cared stone metres v52','Gye stone metres','Mineral surface metres','Gye stone pigment metres'],
      'plaster':['Gye cared lime metres v52','Gye lime metres','Gye plaster wash metres'],
      'paper':['P12 architectural surface UV','Ansarang retained PBR'],
      'endgrain':['Craft end grain'],
      'paint':['Painted timber metres','Craft timber metres','Shrine frieze pigment'],
    }
    for uv in choices.get('wood' if role=='lattice' else role,[]):
        if uv in available:return ('UV',uv)
    dims=[max(v[i] for v in ob.bound_box)-min(v[i] for v in ob.bound_box) for i in range(3)]
    long=max(range(3),key=lambda i:dims[i]);trans=max((i for i in range(3) if i!=long),key=lambda i:dims[i])
    # Object coordinates stay attached to a door when it is opened.
    return ('OBJECT',long,trans)

def coordinate(t,address,role):
    if address[0]=='UV':
        n=r2.node(t,'ShaderNodeUVMap','Existing original member UV; mesh untouched');n.uv_map=address[1]
        scale=(.85,.55,1) if role in ['wood','lattice'] else (.65,.65,1)
        if address[1] in ['Craft timber metres','Painted timber metres']:scale=(.85,.18,1)
        coord=r2.stretch(t,n.outputs['UV'],scale,'Brush size for this source UV')
    else:
        n=r2.node(t,'ShaderNodeTexCoord','Rigid member coordinates; no UV added')
        sep=r2.node(t,'ShaderNodeSeparateXYZ','Original local member axes');t.links.new(n.outputs['Object'],sep.inputs[0])
        combine=r2.node(t,'ShaderNodeCombineXYZ','Longitudinal strokes on member axis')
        t.links.new(sep.outputs[address[2]],combine.inputs['X']);t.links.new(sep.outputs[address[1]],combine.inputs['Y'])
        coord=r2.stretch(t,combine.outputs[0],(1.7,.24,1) if role in ['wood','lattice','paint'] else (.75,.75,1),'Brush scale in original metres')
    seed=r2.node(t,'ShaderNodeObjectInfo','Stable original object brush phase')
    attr=r2.node(t,'ShaderNodeAttribute','Existing member identity; no mesh attribute added');attr.attribute_name='P18 source member id'
    phase=scalar(t,'ADD',seed.outputs['Random'],attr.outputs['Fac'],'Original member phase')
    noise=r2.node(t,'ShaderNodeTexWhiteNoise','Fixed pigment phase');noise.noise_dimensions='1D';t.links.new(phase,noise.inputs['W'])
    offset=r2.stretch(t,noise.outputs['Color'],(9.3,7.9,0),'Different fixed phase per source member')
    add=r2.node(t,'ShaderNodeVectorMath','Shift texture only');add.operation='ADD';t.links.new(coord,add.inputs[0]);t.links.new(offset,add.inputs[1])
    return add.outputs['Vector']

def mask(t,coord,atlas,role):
    panel='wood' if role in ['wood','lattice','endgrain','paint','fibre'] else 'tile' if role=='tile' else 'stone' if role in ['stone','earth','metal'] else 'plaster'
    offsets={'wood':(.03,.53,0),'tile':(.53,.53,0),'stone':(.03,.03,0),'plaster':(.53,.03,0)}
    f=r2.node(t,'ShaderNodeVectorMath','Repeat within one authored brush panel');f.operation='FRACTION';t.links.new(coord,f.inputs[0])
    sc=r2.stretch(t,f.outputs[0],(.44,.44,0),'Inset from panel border')
    add=r2.node(t,'ShaderNodeVectorMath','Material-specific brush vocabulary');add.operation='ADD';add.inputs[1].default_value=offsets[panel];t.links.new(sc,add.inputs[0])
    tex=r2.node(t,'ShaderNodeTexImage','R5 hand-brush alpha, surface attached');tex.image=atlas;tex.interpolation='Cubic';t.links.new(add.outputs[0],tex.inputs['Vector'])
    return r2.luminance(t,tex.outputs['Color'],'R5 independent paint alpha'),panel

def palette(mat):
    ramps=[n for n in mat.node_tree.nodes if n.type=='VALTORGB']
    shared=[n for n in ramps if n.label.startswith('Shared warm timber palette:')]
    if shared:
        el=shared[0].color_ramp.elements
        return tuple(el[len(el)//2].color),shared[0].label
    for n in ramps:
        cols=[e.color for e in n.color_ramp.elements]
        mid=tuple(sum(c[i] for c in cols)/len(cols) for i in range(4))
        if mid[0]>mid[1]*1.25 and mid[1]>mid[2]*1.25 and mid[0]<.7:
            return mid,n.label or n.name
    return None,'preserved source colour signal; no guessed brown palette'

def copied_surface(mat,role,address,atlas,stats):
    new=mat.copy();new.name='R5 '+role+' | '+mat.name
    new['r5_role']=role;new['r5_extension_version']=VERSION
    new['geometry_changed']=False;new['r5_source_material']=mat.name
    t=new.node_tree;coord=coordinate(t,address,role);gray,panel=mask(t,coord,atlas,role)
    a,b,c,d,e,f=stats[panel]
    dark=r2.ramp(t,gray,[(a,1),(b,0)],'R5 DARK paint mask')
    mid=r2.ramp(t,gray,[(b,0),(c,1),(d,1),(e,0)],'R5 MID paint mask')
    bright=r2.ramp(t,gray,[(e,0),(f,1)],'R5 LIGHT paint mask')
    p,reason=palette(mat) if role in ['wood','lattice'] else (None,'original material pigment retained')
    record=dict(source=mat.name,candidate=new.name,role=role,mapping=list(address),palette=p,paletteAuthority=reason)
    for bsdf in [n for n in list(t.nodes) if n.type=='BSDF_PRINCIPLED']:
        old=original_color(t,bsdf);color=old
        if role in ['wood','lattice'] and p:
            tone=lambda v:tuple(p[i]*v for i in range(3))+(1,)
            planes=r2.ramp(t,gray,[(a,tone(.78)),(b,tone(.78)),(c,tone(1)),(d,tone(1)),(e,tone(1.28)),(f,tone(1.28))],'R5 source-coloured DARK MID LIGHT planes')
            tex=r2.node(t,'ShaderNodeTexImage','Accepted R5 broad hand-brushed timber pigment');tex.image=WOOD;tex.interpolation='Cubic';t.links.new(coord,tex.inputs['Vector'])
            calibrated=r2.mix(t,tex.outputs['Color'],tuple(p[i]/WOOD_MEAN[i] for i in range(3))+(1,),1,'R5 painted tooth in this source timber palette','MULTIPLY')
            painted=r2.mix(t,calibrated,planes,.80,'R5 broad planes and authored brush tooth')
            color=r2.mix(t,old,painted,.80 if role=='wood' else .45,'Broad brush planes; source grain remains')
            # The original cut mapping and growth rings remain on source cut faces.
            attr=r2.node(t,'ShaderNodeAttribute','Existing real cut face mask');attr.attribute_name='P18 real cut face'
            cut=r2.node(t,'ShaderNodeMixRGB','Preserve original endgrain on real cuts');t.links.new(attr.outputs['Fac'],cut.inputs[0]);t.links.new(color,cut.inputs[1]);t.links.new(old,cut.inputs[2]);color=cut.outputs[0]
        strength={'wood':(.91,1.07,.84),'lattice':(.94,1.055,.65),'tile':(.86,1.10,.72),'stone':(.88,1.10,.70),'plaster':(.97,1.03,.5),'paper':(.989,1.012,.3),'paint':(.95,1.045,.60),'endgrain':(.96,1.04,.45),'metal':(.96,1.04,.30),'earth':(.95,1.055,.45),'fibre':(.97,1.03,.4),'wax':(.99,1.01,.25)}[role]
        color=art.pigment(t,color,1,1,'R5 FILL original material colour')
        color=art.pigment(t,color,strength[0],scalar(t,'MULTIPLY',dark,strength[2],'Dark stroke coverage'),'R5 PAINT dark selected strokes')
        color=art.pigment(t,color,1,mid,'R5 PAINT midtone breathing room')
        color=art.pigment(t,color,strength[1],scalar(t,'MULTIPLY',bright,strength[2],'Light stroke coverage'),'R5 PAINT light selected strokes')
        t.links.new(color,bsdf.inputs['Base Color'])
        rough=bsdf.inputs['Roughness'];floor={'wood':.74,'lattice':.75,'tile':.82,'stone':.87,'plaster':.92,'paper':.92,'paint':.77,'endgrain':.82,'metal':.52,'earth':.92,'fibre':.90,'wax':.60}[role]
        if rough.is_linked:t.links.new(scalar(t,'MAXIMUM',rough.links[0].from_socket,floor,'Cared matte surface floor'),rough)
        else:rough.default_value=max(rough.default_value,floor)
        # Shallow pigment relief, never a displacement or a silhouette change.
        distance,strength_b={'wood':(.0014,.20),'lattice':(.0006,.12),'tile':(.0017,.20),'stone':(.0025,.23),'plaster':(.001,.18),'paper':(.0003,.12),'paint':(.0007,.14),'endgrain':(.0006,.12),'metal':(.0007,.12),'earth':(.0014,.14),'fibre':(.0006,.13),'wax':(.0002,.08)}[role]
        r2.bump(t,bsdf,gray,distance,strength_b,'Subtle paint tooth; no added surface noise')
    return new,record

def setup(scene,obs):
    pts=[ob.matrix_world@Vector(p) for ob in obs if not ob.hide_render for p in ob.bound_box]
    lo=Vector(tuple(min(p[i] for p in pts) for i in range(3)));hi=Vector(tuple(max(p[i] for p in pts) for i in range(3)))
    center=(lo+hi)/2;span=max(hi.x-lo.x,hi.y-lo.y,(hi.z-lo.z)*1.5);q=span/20
    scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=24;scene.cycles.seed=217;scene.cycles.use_denoising=True
    scene.render.threads_mode='FIXED';scene.render.threads=8;scene.render.resolution_percentage=100
    scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGB'
    scene.world=bpy.data.worlds.new('R5 matched open daylight');scene.world.use_nodes=True
    t=scene.world.node_tree;bg=t.nodes.get('Background');bg.inputs['Color'].default_value=(.78,.74,.66,1);bg.inputs['Strength'].default_value=.65
    backdrop=t.nodes.new('ShaderNodeBackground');backdrop.inputs['Color'].default_value=(.72,.60,.43,1);backdrop.inputs['Strength'].default_value=5
    rays=t.nodes.new('ShaderNodeLightPath');m=t.nodes.new('ShaderNodeMixShader');t.links.new(rays.outputs['Is Camera Ray'],m.inputs[0]);t.links.new(bg.outputs[0],m.inputs[1]);t.links.new(backdrop.outputs[0],m.inputs[2]);t.links.new(m.outputs[0],t.nodes['World Output'].inputs['Surface'])
    scene.view_settings.view_transform='AgX';scene.view_settings.look='AgX - Medium Low Contrast';scene.view_settings.exposure=0;scene.view_settings.gamma=1
    for name,pos,power,size,col in [('Broad warm daylight',(-12,-10,16),3500,7,(1,.91,.79)),('Open front fill',(6,-11,9),1250,9,(1,.98,.91)),('Soft rear daylight',(1,8,13),1100,8,(.91,.95,1))]:
        light=s.light(scene,name,center+Vector(pos)*q,power*q*q,size*q,col);s.point(light,center)
    data=bpy.data.cameras.new('Matched building review');data.type='ORTHO';data.sensor_fit='HORIZONTAL';cam=bpy.data.objects.new(data.name,data);scene.collection.objects.link(cam);scene.camera=cam
    def fit(position,target,res):
        cam.location=position;s.point(cam,target);bpy.context.view_layer.update();inv=cam.matrix_world.inverted();projected=[inv@p for p in pts]
        w=max(p.x for p in projected)-min(p.x for p in projected);h=max(p.y for p in projected)-min(p.y for p in projected)
        return dict(position=list(position),target=list(target),ortho=max(w,h*res[0]/res[1])*1.12,resolution=res)
    hero=fit(center+Vector((1.2,-1.7,.95))*span,center,(1100,825))
    # Another angle and a closer façade view expose lattice, joins, stone and paint.
    target=center.copy();target.y=lo.y+(hi.y-lo.y)*.12;target.z=lo.z+(hi.z-lo.z)*.38
    detail=dict(position=list(target+Vector((.22,-2,.12))*span),target=list(target),ortho=max(3,span*.32),resolution=(1100,825))
    return dict(hero=hero,detail=detail),dict(bounds=[list(lo),list(hi)],span=span)

def object_properties(obs):
    return {o.name:json.dumps({k:s.serialize(o[k]) for k in o.keys()},sort_keys=True) for o in obs}

def main():
    global WOOD,WOOD_MEAN
    start=time.monotonic();key=sys.argv[sys.argv.index('--')+1]
    source=next(b for b in json.loads((HOME/'source-audit.json').read_text(encoding='utf-8')) if b['key']==key)
    out=HOME/key;out.mkdir(exist_ok=True);s.OUT=out
    native=Path(source['native']);assert s.sha(native)==source['sha256']
    bpy.ops.wm.read_factory_settings(use_empty=True)
    with bpy.data.libraries.load(str(native),link=False) as (src,dst):dst.objects=list(source['names'])
    scene=bpy.context.scene;scene.name=source['name']+' | R5 material review'
    for ob in dst.objects:scene.collection.objects.link(ob)
    bpy.context.view_layer.update();obs=[bpy.data.objects[n] for n in source['names']];assert len(obs)==source['count']
    geometry=s.geometry_state(obs);attrs=r2.attributes(obs);props=object_properties(obs);images=r2.image_state()
    originals={sl.material.name:sl.material for ob in obs for sl in ob.material_slots if sl.material}
    # Some source objects already override the mesh material. Keep the now unused
    # original datablocks in this candidate too, without editing their node graphs.
    for mat in originals.values():mat.use_fake_user=True
    mats={k:s.material_state(m) for k,m in originals.items()}
    views,bounds=setup(scene,obs);lighting=art.study.signature(scene)
    renders=[]
    controls=out/'controls.json'
    cached=json.loads(controls.read_text(encoding='utf-8')) if controls.exists() else {}
    for v in views:
        prior=next((r for r in cached.get('renders',[]) if r['view']==v),None)
        if cached.get('sourceSha256')==source['sha256'] and cached.get('views',{}).get(v)==json.loads(json.dumps(views[v])) and prior and s.sha(out/prior['file'])==prior['sha256']:renders.append(prior)
        else:renders.append(dict(variant='source',view=v,**s.render(scene,scene.camera,'before-'+v+'.png',**views[v])))
    write(controls,dict(sourceSha256=source['sha256'],views=views,renders=renders))
    write(out/'progress.json',dict(stage='controls rendered',key=key))
    atlas=bpy.data.images.load(str(HOME.parent/'lookdev-sarang-r5/textures/material-brush-atlas-r1.png'),check_existing=True);atlas.colorspace_settings.name='Non-Color';atlas.pack();stats=art.gray_image_stats(atlas)
    WOOD=bpy.data.images.load(str(HOME.parent/'lookdev-sarang-r5/textures/wood-colour-planes-r1.png'),check_existing=True);WOOD.pack();WOOD_MEAN=art.study.mean_image(WOOD)
    infos={m['name']:m for m in source['materials']};replacements={};changes=[];coverage={};preserved={}
    for ob in obs:
        for sl in ob.material_slots:
            mat=sl.material
            if not mat:continue
            role=category(infos[mat.name],ob.name);assert role!='unclassified',(ob.name,mat.name)
            coverage.setdefault(role,set()).add(ob.name)
            if role=='preserve':
                preserved.setdefault(ob.name,[]).append(mat.name);continue
            address=mapping(ob,role);cache=(mat.name,role,address)
            if cache not in replacements:
                replacements[cache],record=copied_surface(mat,role,address,atlas,stats);changes.append(record)
            sl.link='OBJECT';sl.material=replacements[cache]
    assert geometry==s.geometry_state(obs);assert attrs==r2.attributes(obs);assert props==object_properties(obs)
    assert mats=={k:s.material_state(m) for k,m in originals.items()}
    path=out/(key+'-r5-brush-candidate.blend');bpy.context.preferences.filepaths.save_version=0
    scene.camera.location=views['hero']['position'];s.point(scene.camera,views['hero']['target']);scene.camera.data.ortho_scale=views['hero']['ortho']
    bpy.ops.wm.save_as_mainfile(filepath=str(path),check_existing=False,compress=True,relative_remap=False)
    bpy.ops.wm.open_mainfile(filepath=str(path));scene=bpy.context.scene;obs=[bpy.data.objects[n] for n in source['names']]
    assert geometry==s.geometry_state(obs);assert attrs==r2.attributes(obs);assert props==object_properties(obs)
    reopened_images={k:v for k,v in r2.image_state().items() if k in images}
    if images!=reopened_images:write(out/'image-state-differences.json',{k:dict(before=v,after=reopened_images.get(k)) for k,v in images.items() if v!=reopened_images.get(k)})
    assert images==reopened_images
    assert mats=={k:s.material_state(bpy.data.materials[k]) for k in mats}
    assert lighting==art.study.signature(scene)
    assert s.sha(native)==source['sha256']
    for n,bindings in preserved.items():assert all(x in [sl.material.name for sl in bpy.data.objects[n].material_slots if sl.material] for x in bindings)
    record=dict(key=key,name=source['name'],version=VERSION,sourceNative=str(native),sourceSha256=source['sha256'],candidateNative=path.name,candidateSha256=s.sha(path),
      passed=True,reopened=True,meshCount=len(obs),geometryUVsTransformsModifiersEqual=True,attributesStagesPropertiesEqual=True,sourceMaterialGraphsEqual=True,sourceImageBytesEqual=True,
      originalPlaquesAndAnonymousPatternsUnchanged=preserved,roles={k:len(v) for k,v in coverage.items()},materials=changes,views=views,bounds=bounds,
      sourceSpecificPalettes=True,newUVs=0,newMeshes=0,objectAttachedUVlessProjection=True,sceneLightBaked=False,lightingUnchangedAfterReopen=True,canonicalPromoted=False,glbConverted=False,appIntegrated=False,
      producerFiles={p.name:s.sha(p) for p in [Path(__file__),HOME/'material_rules.py']})
    write(out/'verification.json',record)
    for v in views:
        renders.append(dict(variant='R5 candidate',view=v,**s.render(scene,scene.camera,'after-'+v+'.png',**views[v])))
        write(out/'render-manifest.json',dict(key=key,complete=len(renders)==4,matchedCameraLights=True,samples=24,renders=renders,seconds=round(time.monotonic()-start,1)))
    write(out/'progress.json',dict(stage='complete',key=key,seconds=round(time.monotonic()-start,1)))
    print('COMPLETE',key,round(time.monotonic()-start,1),flush=True)

if __name__=='__main__':main()
