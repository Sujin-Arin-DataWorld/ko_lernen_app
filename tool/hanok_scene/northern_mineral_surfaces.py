"""Mineral pigment on the existing solid stones and overlapping curved tiles.

Albedo fields are generated interpretations of the canonical illustration.
The measured geometry, accepted southern scene and original artwork stay intact.
"""
from pathlib import Path
import bpy,json,hashlib,random,sys
import numpy as np
sys.path.insert(0,str(Path(__file__).parent))
from northern_timber_sections import groups
from refine_northern_materials import geometry_fingerprint
from northern_tile_ends import refine_tile_end_profiles,give_tile_shells_depth

OUT=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
MATERIALS=OUT/'materials'
UV_NAME='Mineral surface metres'
COLOR_NAME='Mineral component tint'

def mineral_material(kind,variant=0):
    name='Illustrated '+kind+' v1 '+str(variant)
    if name in bpy.data.materials:return bpy.data.materials[name]
    mat=bpy.data.materials.new(name);mat.use_nodes=True
    nodes=mat.node_tree.nodes;links=mat.node_tree.links;nodes.clear()
    shader=nodes.new('ShaderNodeBsdfPrincipled');shader.inputs['Roughness'].default_value=.90 if kind=='granite' else .84
    shader.inputs['Specular IOR Level'].default_value=.20
    output=nodes.new('ShaderNodeOutputMaterial');links.new(shader.outputs['BSDF'],output.inputs['Surface'])
    uv=nodes.new('ShaderNodeUVMap');uv.uv_map=UV_NAME
    color=nodes.new('ShaderNodeTexImage');color.image=bpy.data.images.load(str(MATERIALS/f'hanok-{kind}-v1.png'),check_existing=True);color.extension='REPEAT'
    links.new(uv.outputs['UV'],color.inputs['Vector'])
    tint=nodes.new('ShaderNodeVertexColor');tint.layer_name=COLOR_NAME
    mix=nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1
    links.new(color.outputs['Color'],mix.inputs[1]);links.new(tint.outputs['Color'],mix.inputs[2]);links.new(mix.outputs['Color'],shader.inputs['Base Color'])
    relief=nodes.new('ShaderNodeTexImage');relief.image=bpy.data.images.load(str(MATERIALS/f'hanok-{kind}-normal-v1.png'),check_existing=True);relief.image.colorspace_settings.name='Non-Color';relief.extension='REPEAT'
    normal=nodes.new('ShaderNodeNormalMap');normal.uv_map=UV_NAME;normal.inputs['Strength'].default_value=.55
    links.new(uv.outputs['UV'],relief.inputs['Vector']);links.new(relief.outputs['Color'],normal.inputs['Color']);links.new(normal.outputs['Normal'],shader.inputs['Normal'])
    mat['surfaceKind']='illustrated_'+kind;mat['surfaceAuthority']='Canonical illustration and field-photo material character, not a historic damage scan';mat['physicalTextureWidthMeters']=.70
    return mat

def apply_mineral_surfaces(scene):
    report=[]
    for ob in scene.objects:
        if ob.type!='MESH' or not ob.get('northExtension') or ob.get('mineralSurfaceVersion',0)>=1:continue
        mesh=ob.data;slots={}
        for i,mat in enumerate(mesh.materials):
            if mat and mat.get('surfaceKind')=='stone':slots[i]=('granite',0)
            elif mat and 'source ceramic ' in mat.name and mat.name[-1].isdigit():slots[i]=('clay',int(mat.name[-1]))
        if not slots:continue
        fingerprint=geometry_fingerprint(ob)
        remap={}
        for i,(kind,variant) in slots.items():remap[i]=len(mesh.materials);mesh.materials.append(mineral_material(kind,variant))
        uv=mesh.uv_layers.get(UV_NAME) or mesh.uv_layers.new(name=UV_NAME)
        for attr in list(mesh.color_attributes):mesh.color_attributes.remove(attr)
        tint=mesh.color_attributes.new(name=COLOR_NAME,type='FLOAT_COLOR',domain='CORNER');mesh.color_attributes.active_color=tint
        frames={};owners={};rng=random.Random(ob.name)
        for ci,indices in enumerate(groups(mesh)):
            center=np.mean([mesh.vertices[i].co[:] for i in indices],axis=0)
            frames[ci]=(center,rng.random(),rng.random(),rng.uniform(.91,1.06))
            for i in indices:owners[i]=ci
        faces=0
        for poly in mesh.polygons:
            if poly.material_index not in slots:continue
            kind,variant=slots[poly.material_index];new_index=remap[poly.material_index]
            center,u0,v0,tone=frames[owners[poly.vertices[0]]]
            axes=[a for a in range(3) if a!=int(np.argmax(abs(np.array(poly.normal))))]
            # A slight cool-grey ceramic bias; stone retains a warm mineral tint.
            rgb=np.array((.97,1,1.035) if kind=='clay' else (.94,.955,.97))*tone
            if kind=='clay':rgb*=.94+variant*.022
            for li in poly.loop_indices:
                delta=np.array(mesh.vertices[mesh.loops[li].vertex_index].co)-center
                uv.data[li].uv=(float(u0+delta[axes[0]]/.70),float(v0+delta[axes[1]]/.70))
                tint.data[li].color=(*map(float,rgb),1)
            poly.material_index=new_index;faces+=1
        mesh.uv_layers.active=uv;uv.active_render=True
        assert geometry_fingerprint(ob)==fingerprint,'Mineral surface changed geometry'
        ob['mineralSurfaceVersion']=1
        report.append({'object':ob.name,'building':ob.get('construction_building'),'kinds':sorted({v[0] for v in slots.values()}),'components':len(frames),'faces':faces,'geometryUnchanged':True})
    return report

if __name__=='__main__':
    apply='--apply' in sys.argv
    bpy.ops.wm.open_mainfile(filepath=str(OUT/'scene.blend'));scene=bpy.context.scene
    plugs=refine_tile_end_profiles(scene)
    shells=give_tile_shells_depth(scene)
    before={o.name:geometry_fingerprint(o) for o in scene.objects if o.type=='MESH'}
    report=apply_mineral_surfaces(scene)
    assert all(geometry_fingerprint(bpy.data.objects[n])==fp for n,fp in before.items())
    name='scene.blend' if apply else 'mineral-study.blend'
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/name),compress=True)
    manifest={'nativeScene':name,'nativeSha256':hashlib.sha256((OUT/name).read_bytes()).hexdigest(),'geometryObjectsUnchangedBySurfacePass':len(before),'tileEndProfiles':plugs,'tileShells':shells,'surfaces':report,'sourceImagesUnaltered':True,'generatedInterpretation':True}
    (OUT/'mineral-study.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
    if apply:
        contract=json.loads((OUT/'northern-contract.json').read_text(encoding='utf8'));contract['mineralSurfaces']=report
        contract['tileEndProfiles']=plugs
        contract['tileShells']=shells
        (OUT/'northern-contract.json').write_text(json.dumps(contract,ensure_ascii=False,indent=2),encoding='utf8')
        for ob in scene.objects:ob.select_set(False)
        obs=[ob for ob in scene.objects if ob.type=='MESH' and ob.get('northExtension')]
        for ob in obs:ob.select_set(True);ob.hide_set(False);ob.hide_render=False
        bpy.context.view_layer.objects.active=obs[0]
        bpy.ops.export_scene.gltf(filepath=str(OUT/'northern.glb'),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True,export_extras=True)
    print('MINERAL SURFACES',len(report),'meshes;',len(before),'geometry objects unchanged',flush=True)
