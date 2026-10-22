"""Surface-only native Blender trial. Real shader relief; no mesh edits or image filters."""
import bpy, hashlib, importlib.util, json, sys, time
from pathlib import Path
from array import array

OUT=Path(__file__).resolve().parent
R1=OUT.parent/'lookdev-sarang-r1'
ART_IMAGES={}
spec=importlib.util.spec_from_file_location('source_tools',R1/'render_lookdev.py')
source=importlib.util.module_from_spec(spec);spec.loader.exec_module(source)
source.OUT=OUT

def write(name,data):
    (OUT/name).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

def attributes(objects):
    result={}
    kinds={'FLOAT':('value',1,'f'),'FLOAT_VECTOR':('vector',3,'f'),'FLOAT2':('vector',2,'f'),
           'INT':('value',1,'i'),'BOOLEAN':('value',1,'b'),'FLOAT_COLOR':('color',4,'f'),
           'BYTE_COLOR':('color',4,'f'),'INT32_2D':('value',2,'i')}
    for ob in objects:
        attrs={}
        for a in ob.data.attributes:
            if a.data_type not in kinds:continue
            prop,n,kind=kinds[a.data_type]
            values=array(kind,[0])*(len(a.data)*n)
            try:a.data.foreach_get(prop,values)
            except (TypeError,RuntimeError):continue
            attrs[a.name]=dict(domain=a.domain,type=a.data_type,sha256=hashlib.sha256(values.tobytes()).hexdigest())
        result[ob.name]=attrs
    return result

def image_state():
    records={}
    for im in bpy.data.images:
        if im.source!='FILE':continue
        records[im.name]=dict(size=list(im.size),colorSpace=im.colorspace_settings.name,alphaMode=im.alpha_mode,
            packed=[hashlib.sha256(p.packed_file.data).hexdigest() for p in im.packed_files],filepath=im.filepath)
    return records

def node(tree,kind,name):
    n=tree.nodes.new(kind);n.name='Handpaint r2 | '+name;n.label=name;return n

def noise(tree,vector,scale,name,detail=2,roughness=.65):
    n=node(tree,'ShaderNodeTexNoise',name)
    n.inputs['Scale'].default_value=scale;n.inputs['Detail'].default_value=detail
    n.inputs['Roughness'].default_value=roughness
    tree.links.new(vector,n.inputs['Vector']);return n.outputs['Fac']

def stretch(tree,vector,factors,name):
    n=node(tree,'ShaderNodeVectorMath',name);n.operation='MULTIPLY'
    n.inputs[1].default_value=factors;tree.links.new(vector,n.inputs[0]);return n.outputs['Vector']

def ramp(tree,signal,stops,name):
    n=node(tree,'ShaderNodeValToRGB',name)
    n.color_ramp.interpolation='EASE'
    for e in list(n.color_ramp.elements)[2:]:n.color_ramp.elements.remove(e)
    for i,(p,c) in enumerate(stops):
        e=n.color_ramp.elements[i] if i<2 else n.color_ramp.elements.new(p)
        e.position=p;e.color=(c,c,c,1) if isinstance(c,(int,float)) else c
    tree.links.new(signal,n.inputs['Fac']);return n.outputs['Color']

def mix(tree,a,b,fac,name,blend='MIX'):
    n=node(tree,'ShaderNodeMixRGB',name);n.blend_type=blend;n.inputs[0].default_value=fac
    for val,slot in [(a,n.inputs[1]),(b,n.inputs[2])]:
        if hasattr(val,'node'):tree.links.new(val,slot)
        else:slot.default_value=val
    return n.outputs[0]

def bump(tree,bsdf,height,distance,strength,name):
    inp=bsdf.inputs['Normal'];prior=inp.links[0].from_socket if inp.is_linked else None
    n=node(tree,'ShaderNodeBump',name)
    n.inputs['Distance'].default_value=distance;n.inputs['Strength'].default_value=strength
    n.inputs['Filter Width'].default_value=.03
    tree.links.new(height,n.inputs['Height'])
    if prior:tree.links.new(prior,n.inputs['Normal'])
    tree.links.new(n.outputs['Normal'],inp)

def painted_sample(tree,coordinate,category):
    tex=node(tree,'ShaderNodeTexImage','Generated hand painted '+category+' pigment')
    tex.interpolation='Cubic';tex.extension='REPEAT'
    if category=='wood':
        tex.image=ART_IMAGES['wood'];tree.links.new(coordinate,tex.inputs['Vector'])
    else:
        tex.image=ART_IMAGES['atlas']
        fract=node(tree,'ShaderNodeVectorMath','Repeat only inside selected material panel');fract.operation='FRACTION'
        tree.links.new(coordinate,fract.inputs[0])
        scale=stretch(tree,fract.outputs['Vector'],(.46,.46,0),'Keep sample clear of atlas borders')
        offsets=dict(tile=(.02,.52,0),stone=(.52,.52,0),plaster=(.02,.02,0),paper=(.52,.02,0))
        add=node(tree,'ShaderNodeVectorMath','Select '+category+' panel');add.operation='ADD';add.inputs[1].default_value=offsets[category]
        tree.links.new(scale,add.inputs[0]);tree.links.new(add.outputs['Vector'],tex.inputs['Vector'])
    return tex.outputs['Color']

def luminance(tree,color,name):
    n=node(tree,'ShaderNodeRGBToBW',name);tree.links.new(color,n.inputs['Color']);return n.outputs[0]

def surface_copy(mat,category,uv_fallback=False):
    new=mat.copy();new.name='HANDPAINT r2 '+category+' | '+mat.name.replace('LOOKDEV CANDIDATE r1 | ','')
    t=new.node_tree
    geom=node(t,'ShaderNodeNewGeometry','World-position anchored texture, stable across stages')
    pos=geom.outputs['Position']
    member=node(t,'ShaderNodeAttribute','Preserved original source member ID');member.attribute_name='P18 source member id'
    per_member=node(t,'ShaderNodeTexWhiteNoise','Stable member pigment load');per_member.noise_dimensions='1D'
    t.links.new(member.outputs['Fac'],per_member.inputs['W'])
    uv_maps=[n.uv_map for n in t.nodes if n.type=='UVMAP' and n.uv_map]
    original_uv=node(t,'ShaderNodeTexCoord' if uv_fallback else 'ShaderNodeUVMap','Object coordinates for UV-less source' if uv_fallback else 'Preserve original material UV mapping')
    if not uv_fallback:original_uv.uv_map=uv_maps[0] if uv_maps else ''
    add=node(t,'ShaderNodeVectorMath','Stable material sampling phase per member');add.operation='ADD'
    t.links.new(original_uv.outputs['Object' if uv_fallback else 'UV'],add.inputs[0]);t.links.new(per_member.outputs['Color'],add.inputs[1])
    mapped=stretch(t,add.outputs['Vector'],(.8,.8,1),'Material scale in source UV')
    for b in [n for n in list(t.nodes) if n.type=='BSDF_PRINCIPLED']:
        base=b.inputs['Base Color'];old=base.links[0].from_socket if base.is_linked else tuple(base.default_value)
        b.inputs['Specular IOR Level'].default_value=.26
        b.inputs['Coat Weight'].default_value=0
        if category in ['wood','lattice']:
            # Existing source member UV has V along the timber, including horizontal beams.
            uv=node(t,'ShaderNodeUVMap','Preserved longitudinal member UV')
            uv.uv_map='Gye cared member grain v52'
            offset=stretch(t,per_member.outputs['Color'],(13,9,0),'Distinct fixed brush phase per source member')
            add=node(t,'ShaderNodeVectorMath','Shift shader sample only, leave mesh UV unchanged');add.operation='ADD'
            t.links.new(uv.outputs['UV'],add.inputs[0]);t.links.new(offset,add.inputs[1]);coord=add.outputs['Vector']
            broad=noise(t,stretch(t,coord,(22,1.8,1),'Broad brush direction'),1,'Pigment loading over long strokes',2)
            bristles=noise(t,stretch(t,coord,(125,5,1),'Broken bristle direction'),1,'Broken parallel brush bristles',2.5)
            pores=noise(t,stretch(t,coord,(420,15,1),'Fine grain direction'),1,'Fine open timber pores',2)
            # A new painted color signal replaces most repeated photographic knots.
            art=painted_sample(t,stretch(t,coord,(3.4,.9,1) if category=='lattice' else (1.3,1.2,1),'Hand painted timber physical scale'),'wood')
            grade=node(t,'ShaderNodeHueSaturation','Warm maintained chestnut pigment, restrained orange')
            grade.inputs['Saturation'].default_value=.82;grade.inputs['Value'].default_value=.90
            t.links.new(art,grade.inputs['Color']);pigment=grade.outputs['Color']
            dry=ramp(t,bristles,[(.33,.68),(.5,1),(.68,1.28)],'Broken dry brush gaps')
            color=mix(t,old,pigment,.84,'Painted texture leads; source grain remains subordinate')
            color=mix(t,color,dry,.12,'Subordinate narrow brush variation','MULTIPLY')
            tone=ramp(t,per_member.outputs['Value'],[(0,.84),(1,1.14)],'Individual maintained timber tone')
            color=mix(t,color,tone,1,'Stable subtle member tone','MULTIPLY')
            cut_uv=node(t,'ShaderNodeAttribute','Preserved cut face atlas UV');cut_uv.attribute_name='P18 cut UV'
            cut_mask=node(t,'ShaderNodeAttribute','Only actual source cut faces');cut_mask.attribute_name='P18 real cut face'
            cut_image=node(t,'ShaderNodeTexImage','Original hand illustrated cut wood atlas');cut_image.image=ART_IMAGES['endgrain']
            t.links.new(cut_uv.outputs['Vector'],cut_image.inputs['Vector'])
            masked=node(t,'ShaderNodeMixRGB','Distinct end grain on real cuts, longitudinal grain on side')
            t.links.new(cut_mask.outputs['Fac'],masked.inputs[0]);t.links.new(color,masked.inputs[1]);t.links.new(cut_image.outputs['Color'],masked.inputs[2])
            color=masked.outputs[0]
            b.inputs['Roughness'].default_value=.8
            rough=ramp(t,bristles,[(.2,.67),(.78,.94)],'Stain and dry fibres scatter light differently')
            t.links.new(rough,b.inputs['Roughness'])
            bump(t,b,bristles,.0045,.58,'Shallow brush ridges and planed fibres')
            bump(t,b,pores,.0018,.42,'Fine directional open pores')
            bump(t,b,luminance(t,art,'Painted timber texture relief'),.0038,.52,'Relief tied to painted wood grain')
        elif category=='endgrain':
            # Dedicated cap meshes only have Craft end grain UV, not the side-grain UV.
            end_uv=node(t,'ShaderNodeUVMap','Use actual cap UV, avoid missing side UV');end_uv.uv_map='Craft end grain'
            per_island=geom.outputs['Random Per Island']
            slots=node(t,'ShaderNodeMath','One of sixteen original painted growth rings');slots.operation='MULTIPLY';slots.inputs[1].default_value=15.999
            t.links.new(per_island,slots.inputs[0])
            integer=node(t,'ShaderNodeMath','Stable ring swatch integer');integer.operation='FLOOR';t.links.new(slots.outputs[0],integer.inputs[0])
            col=node(t,'ShaderNodeMath','Ring atlas column');col.operation='MODULO';col.inputs[1].default_value=4;t.links.new(integer.outputs[0],col.inputs[0])
            row=node(t,'ShaderNodeMath','Ring atlas row');row.operation='DIVIDE';row.inputs[1].default_value=4;t.links.new(integer.outputs[0],row.inputs[0])
            floor=node(t,'ShaderNodeMath','Ring atlas row integer');floor.operation='FLOOR';t.links.new(row.outputs[0],floor.inputs[0])
            cell=node(t,'ShaderNodeCombineXYZ','Growth ring swatch address');t.links.new(col.outputs[0],cell.inputs['X']);t.links.new(floor.outputs[0],cell.inputs['Y'])
            quarter=stretch(t,cell.outputs[0],(.25,.25,0),'Original sixteen swatch atlas spacing')
            local=stretch(t,end_uv.outputs['UV'],(.21,.21,0),'Use entire cap surface within one swatch')
            add=node(t,'ShaderNodeVectorMath','Combine original cap UV and swatch address');add.operation='ADD';t.links.new(local,add.inputs[0]);t.links.new(quarter,add.inputs[1])
            margin=node(t,'ShaderNodeVectorMath','Inset ring sample from atlas seams');margin.operation='ADD';margin.inputs[1].default_value=(.02,.02,0);t.links.new(add.outputs[0],margin.inputs[0])
            art=node(t,'ShaderNodeTexImage','Existing illustrated growth ring texture');art.image=ART_IMAGES['endgrain'];art.interpolation='Cubic';t.links.new(margin.outputs[0],art.inputs['Vector'])
            grade=node(t,'ShaderNodeHueSaturation','Maintained end wood, no orange discs');grade.inputs['Saturation'].default_value=.82;grade.inputs['Value'].default_value=.9;t.links.new(art.outputs['Color'],grade.inputs['Color']);color=grade.outputs['Color']
            b.inputs['Roughness'].default_value=.88
            bump(t,b,luminance(t,art.outputs['Color'],'Fine growth ring tooth'),.0016,.36,'Shallow hand painted cut face relief')
        elif category=='stone':
            body=noise(t,pos,5.0,'Broad mineral body, not gravel',2)
            chisel=noise(t,pos,34,'Broken small chisel and crystal faces',2.3)
            fine=noise(t,pos,180,'Stone grain pinholes',2)
            glaze=ramp(t,body,[(.28,.67),(.48,1),(.72,1.29)],'Low chroma stone wash')
            dry=ramp(t,chisel,[(.2,.85),(.8,1.1)],'Dry mineral flecks')
            color=mix(t,mix(t,old,glaze,.72,'Broad mineral washes','MULTIPLY'),dry,.45,'Mineral flecks stay subordinate','MULTIPLY')
            art=painted_sample(t,mapped,'stone')
            color=mix(t,color,art,.60,'Hand painted broad stone body')
            tone=ramp(t,per_member.outputs['Value'],[(0,(.85,.83,.79,1)),(1,(1.16,1.12,1.04,1))],'Different gray beige washes on each stone')
            color=mix(t,color,tone,1,'Stone block pigment variation','MULTIPLY')
            rough=ramp(t,chisel,[(.15,.79),(.8,.97)],'Stone grain roughness')
            t.links.new(rough,b.inputs['Roughness'])
            bump(t,b,chisel,.009,.55,'Shallow stone tooling, no displaced silhouette')
            bump(t,b,fine,.0015,.30,'Fine mineral grain')
            bump(t,b,luminance(t,art,'Painted mineral tooth'),.004,.36,'Painted stone tooling relief')
        elif category=='tile':
            wash=noise(t,pos,6.5,'Uneven fired clay and brush pigment',2)
            dry=noise(t,stretch(t,pos,(1.8,1,1),'Dry clay stroke direction'),45,'Dry clay powder grains',2)
            glaze=ramp(t,wash,[(.28,.74),(.48,1.20),(.74,1.75)],'Charcoal clay tonal body')
            dust=ramp(t,dry,[(.28,.78),(.7,1.25)],'Fine pale powder catches daylight')
            color=mix(t,mix(t,old,glaze,1,'Keep source tiles with fired variation','MULTIPLY'),dust,.60,'Dry clay pigment on the tile body','MULTIPLY')
            art=painted_sample(t,mapped,'tile')
            color=mix(t,color,art,.68,'Hand brushed charcoal clay pigment')
            tone=ramp(t,per_member.outputs['Value'],[(0,.82),(1,1.18)],'Restrained charcoal variation between tiles')
            color=mix(t,color,tone,1,'Individual fired tile color','MULTIPLY')
            rough=ramp(t,dry,[(.2,.77),(.8,.98)],'Powdered clay roughness')
            t.links.new(rough,b.inputs['Roughness'])
            bump(t,b,wash,.0028,.26,'Hand worked fired clay body')
            bump(t,b,dry,.0018,.48,'Powdery clay surface')
            bump(t,b,luminance(t,art,'Painted clay dry brush relief'),.0028,.45,'Rough hand brushed fired clay')
        elif category=='plaster':
            wash=noise(t,pos,4,'Broad limewash passes',2)
            fine=noise(t,stretch(t,pos,(1,1,1.7),'Lime brush orientation'),75,'Lime and paper fine tooth',2)
            glaze=ramp(t,wash,[(.2,.86),(.8,1.08)],'Restrained overlapping lime washes')
            art=painted_sample(t,mapped,'plaster')
            color=mix(t,mix(t,old,glaze,.70,'Visible lime brush body','MULTIPLY'),art,.72,'Hand applied limewash pigment')
            rough=ramp(t,fine,[(.1,.88),(.9,.99)],'Dry lime roughness');t.links.new(rough,b.inputs['Roughness'])
            bump(t,b,fine,.002,.35,'Fine brushed lime relief')
            bump(t,b,luminance(t,art,'Limewash stroke height'),.002,.40,'Visible lime brush passes')
        elif category=='paper':
            art=painted_sample(t,mapped,'paper');color=mix(t,old,art,.65,'Painted hanji fibre pigment')
            b.inputs['Roughness'].default_value=.94
            bump(t,b,luminance(t,art,'Hanji fine pulp fibres'),.0005,.22,'Fine paper fibre tooth')
        elif category=='pigment':
            # Existing finial decoration remains legible; only restrained surface response changes.
            fine=noise(t,pos,140,'Fine pigment granulation on original decorative pattern',2)
            tint=ramp(t,fine,[(.2,.90),(.8,1.07)],'Restrained original pigment variation')
            color=mix(t,old,tint,.22,'Keep original decorative pigment and pattern','MULTIPLY')
            b.inputs['Roughness'].default_value=.88
            bump(t,b,fine,.0006,.20,'Dry pigment tooth on finial')
        else:continue
        t.links.new(color,base)
    new['candidate_status']='unapproved native surface trial'
    new['geometry_changed']=False
    return new

def main():
    start=time.monotonic()
    native=R1/'sarang-lookdev-candidate.blend'
    assert source.sha(source.NATIVE)==source.EXPECTED
    bpy.ops.wm.open_mainfile(filepath=str(native))
    scene=bpy.context.scene
    objects=[o for o in scene.objects if o.type=='MESH']
    assert len(objects)==710
    before=source.geometry_state(objects);attrs=attributes(objects);images_before=image_state()
    plaque_before={n:dict(materials=[source.material_state(s.material) for s in bpy.data.objects[n].material_slots],uv=before[n]['uv']) for n in source.PLAQUES}
    mats={s.material.name:s.material for o in objects for s in o.material_slots if s.material}
    signatures={k:source.material_state(v) for k,v in mats.items()}
    # Identical light rig for both variants; more directional daylight reveals surface relief.
    scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.65
    for name,energy,size in [('Broad warm daylight',3500,7),('Open front fill',1250,9),('Soft rear daylight',1100,8)]:
        scene.objects[name].data.energy=energy;scene.objects[name].data.size=size
    scene.cycles.samples=40;scene.cycles.use_denoising=True;scene.cycles.seed=217
    scene.render.threads=8
    scene.view_settings.look='AgX - Medium Low Contrast'
    camera=scene.camera
    views={
      'hero':dict(position=(29.4,-30.2,15.45),target=(7.4,1.8,2.85),ortho=22,resolution=(1400,1050)),
      'front':dict(position=(6.4,-22,3.5),target=(6.4,0,3.35),ortho=12.8,resolution=(1400,840)),
      'wood':dict(position=(18,-15,5.0),target=(12.5,-3.0,2.3),ortho=3.2,resolution=(1100,900)),
      'stone':dict(position=(6.5,-8.5,4.8),target=(4.0,-1.9,.63),ortho=3.6,resolution=(1100,900)),
      'tile':dict(position=(17,-12,13),target=(13,-1.9,4.3),ortho=4.5,resolution=(1100,900)),
      'eaves':dict(position=(13.5,-12,3.7),target=(12.5,-4.5,3.9),ortho=2.8,resolution=(1300,650)),
      'wall':dict(position=(23,1,4.3),target=(14.6,1.6,2.8),ortho=3.1,resolution=(1100,900))}
    if '--hero-only' in sys.argv:views={k:v for k,v in views.items() if k in ['hero','wood']}
    if '--draft' in sys.argv:
        scene.cycles.samples=24
        for v in views.values():v['resolution']=tuple(int(x*.7) for x in v['resolution'])
    renders=[]
    cache=json.loads((OUT/'controls-cache.json').read_text()) if '--reuse-controls' in sys.argv else {}
    for name,view in views.items():
        entry=cache.get(name)
        if entry and entry['resolution']==list(view['resolution']) and source.sha(OUT/entry['file'])==entry['sha256']:
            renders.append(dict(variant='r1 previous candidate, matched lighting',view=name,**entry))
        else:
            renders.append(dict(variant='r1 previous candidate, matched lighting',view=name,**source.render(scene,camera,'before-'+name+'.png',**view)))
    for key,filename in [('wood','handpainted-pine-r1.png'),('atlas','handpainted-mineral-paper-atlas-r1.png')]:
        image=bpy.data.images.load(str(OUT/'textures'/filename),check_existing=True);image.pack();ART_IMAGES[key]=image
    ART_IMAGES['endgrain']=bpy.data.images['wood-endgrain-atlas-v1.png']
    replacements={};changes=[];coverage={};untreated=[];mapping_audit=[]
    for ob in objects:
        if ob.name in source.PLAQUES:continue
        for slot in ob.material_slots:
            mat=slot.material;category=source.role(mat) if mat else None
            if mat and 'finial pigment' in mat.name.lower():category='pigment'
            if mat and 'Craft rafter end grain' in mat.name:category='endgrain'
            elif category=='wood' and any(k in ob.name.lower() for k in ['vertical sal','horizontal sal','horizontal band','lattice','rebated bead','lower moulding','rear paper rail','inner bevel bead']):category='lattice'
            if category not in ['wood','stone','tile','plaster','paper','pigment','endgrain','lattice']:
                untreated.append(dict(object=ob.name,material=mat.name if mat else None));continue
            coverage.setdefault(category,set()).add(ob.name)
            uv_fallback=not bool(ob.data.uv_layers)
            if category in ['wood','lattice']:assert 'Gye cared member grain v52' in ob.data.uv_layers,ob.name
            if category=='endgrain':assert 'Craft end grain' in ob.data.uv_layers,ob.name
            mapping_audit.append(dict(object=ob.name,category=category,sourceUvs=[v.name for v in ob.data.uv_layers],mapping='local object coordinates' if uv_fallback else 'preserved source UV',material=mat.name))
            replacement_key=(mat.name,category,uv_fallback)
            if replacement_key not in replacements:
                new=surface_copy(mat,category,uv_fallback);replacements[replacement_key]=new
                changes.append(dict(original=mat.name,candidate=new.name,category=category))
            slot.link='OBJECT';slot.material=replacements[replacement_key]
    assert not untreated, untreated
    write('material-coverage.json',dict(objects=len(objects),intentionallyPreservedPlaques=sorted(source.PLAQUES),unclassifiedSlots=untreated,
        categories={k:dict(count=len(v),objects=sorted(v)) for k,v in coverage.items()},allNonPlaqueSurfaceSlotsTreated=True))
    write('surface-mapping-audit.json',mapping_audit)
    bpy.context.view_layer.update()
    assert before==source.geometry_state(objects)
    assert attrs==attributes(objects)
    assert images_before=={k:v for k,v in image_state().items() if k in images_before}
    assert signatures=={k:source.material_state(v) for k,v in mats.items()}
    assert plaque_before=={n:dict(materials=[source.material_state(s.material) for s in bpy.data.objects[n].material_slots],uv=source.geometry_state([bpy.data.objects[n]])[n]['uv']) for n in source.PLAQUES}
    for name,view in views.items():
        renders.append(dict(variant='r2 surface candidate, unapproved',view=name,**source.render(scene,camera,'after-'+name+'.png',**view)))
    write('geometry-before.json',before);write('attributes-before.json',attrs)
    write('source-images-before.json',images_before)
    write('material-changes.json',changes)
    camera.location=views['hero']['position'];source.point(camera,views['hero']['target']);camera.data.ortho_scale=22
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'sarang-handpaint-candidate.blend'),check_existing=False)
    assert source.sha(source.NATIVE)==source.EXPECTED
    output=OUT/'sarang-handpaint-candidate.blend'
    # Fresh disk reopen, not only the pre-save in-memory comparison.
    bpy.ops.wm.open_mainfile(filepath=str(output))
    saved=[o for o in bpy.context.scene.objects if o.type=='MESH']
    assert before==source.geometry_state(saved)
    assert attrs==attributes(saved)
    assert images_before=={k:v for k,v in image_state().items() if k in images_before}
    assert plaque_before=={n:dict(materials=[source.material_state(s.material) for s in bpy.data.objects[n].material_slots],uv=source.geometry_state([bpy.data.objects[n]])[n]['uv']) for n in source.PLAQUES}
    write('verification.json',dict(passed=True,exactSourceMeshes=710,geometryUvsTransformsModifiersEqual=True,allRecordedMeshAttributesEqual=True,
        sourceMaterialsUnchanged=True,plaquesMaterialsImagesUvsUnchanged=True,savedNativeReopened=True,sourceNativeSha256=source.EXPECTED,
        sourceNativeUnchanged=True,candidateSha256=source.sha(output),candidateApproved=False,appIntegrated=False,glbConverted=False,
        surfaceOnly=True,noGeometryDisplacement=True,sourceImagePackedBytesEqual=True,changedMaterials=len(changes)))
    write('render-manifest.json',dict(renders=renders,samples=bpy.context.scene.cycles.samples,matchedLightsAndCameras=True,candidateApproved=False,seconds=round(time.monotonic()-start,1),
        previousNativeSha256=source.sha(native),candidateNativeSha256=source.sha(output),nativeFile=output.name))
    print('HANDPAINTED CANDIDATE SAVED AND REOPENED',time.monotonic()-start,flush=True)

if __name__=='__main__':main()
