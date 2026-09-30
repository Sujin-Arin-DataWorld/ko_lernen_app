"""Illustrated pine on solid timber, at physical grain scale with cut ends.

Generated surfaces are explicitly interpretations of the canonical artwork,
not a scan of the historic timber. Surveyed geometry is never changed here.
"""
from pathlib import Path
import bpy,json,hashlib,math,random,sys
import numpy as np
sys.path.insert(0,str(Path(__file__).parent))
from northern_timber_sections import groups

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
MATERIALS=OUT/'materials'
UV_NAME='Craft timber metres'

def pine_material(kind):
    name='Illustrated pine '+kind+' v1'
    if name in bpy.data.materials:return bpy.data.materials[name]
    mat=bpy.data.materials.new(name);mat.use_nodes=True
    nodes=mat.node_tree.nodes;links=mat.node_tree.links;nodes.clear()
    shader=nodes.new('ShaderNodeBsdfPrincipled');shader.inputs['Roughness'].default_value=.86;shader.inputs['Specular IOR Level'].default_value=.20
    output=nodes.new('ShaderNodeOutputMaterial');links.new(shader.outputs['BSDF'],output.inputs['Surface'])
    uv=nodes.new('ShaderNodeUVMap');uv.uv_map=UV_NAME
    albedo=nodes.new('ShaderNodeTexImage');albedo.image=bpy.data.images.load(str(MATERIALS/f'hanok-pine-{kind}-v1.png'),check_existing=True);albedo.extension='REPEAT'
    links.new(uv.outputs['UV'],albedo.inputs['Vector']);links.new(albedo.outputs['Color'],shader.inputs['Base Color'])
    relief=nodes.new('ShaderNodeTexImage');relief.image=bpy.data.images.load(str(MATERIALS/f'hanok-pine-{kind}-normal-v1.png'),check_existing=True);relief.image.colorspace_settings.name='Non-Color';relief.extension='REPEAT'
    normal=nodes.new('ShaderNodeNormalMap');normal.uv_map=UV_NAME;normal.inputs['Strength'].default_value=.5
    links.new(uv.outputs['UV'],relief.inputs['Vector']);links.new(relief.outputs['Color'],normal.inputs['Color']);links.new(normal.outputs['Normal'],shader.inputs['Normal'])
    mat['surfaceAuthority']='Generated illustration surface, referenced to the unchanged Anchae canonical; not a surveyed damage map'
    mat['surfaceKind']='illustrated_'+kind;mat['grainScaleMeters']='width 1.2, length 2.8; end cross-section 0.70'
    return mat

def geometry_fingerprint(ob):
    h=hashlib.sha256();h.update(np.array(ob.matrix_world,dtype=np.float64).tobytes());h.update(np.array([v.co[:] for v in ob.data.vertices],dtype=np.float32).tobytes())
    h.update(str([tuple(poly.vertices) for poly in ob.data.polygons]).encode());return h.hexdigest()

def apply_craft_surfaces(scene,scope=('anchae',)):
    longgrain=pine_material('longgrain');endgrain=pine_material('endgrain');report=[]
    for ob in scene.objects:
        if ob.type!='MESH' or ob.get('construction_building') not in scope or ob.get('illustratedPineV1'):continue
        mesh=ob.data
        wood_slots={i for i,m in enumerate(mesh.materials) if m and m.get('surfaceKind') in ('wood','post','beam','floor')}
        if not wood_slots:continue
        before=geometry_fingerprint(ob);old_count=len(mesh.materials);mesh.materials.append(longgrain);mesh.materials.append(endgrain)
        uv=mesh.uv_layers.get(UV_NAME) or mesh.uv_layers.new(name=UV_NAME)
        rng=random.Random(ob.name);frames={};owner={}
        for ci,indices in enumerate(groups(mesh)):
            cloud=np.array([mesh.vertices[i].co[:] for i in indices]);center=cloud.mean(0)
            values,basis=np.linalg.eigh((cloud-center).T@(cloud-center));long=basis[:,2]
            if long[np.argmax(abs(long))]<0:long=-long
            frames[ci]=(center,long,basis[:,1],basis[:,0],rng.random(),rng.random())
            for i in indices:owner[i]=ci
        cuts=0;long_faces=0
        for poly in mesh.polygons:
            if poly.material_index not in wood_slots:continue
            center,long,a,b,u0,v0=frames[owner[poly.vertices[0]]];normal=np.array(poly.normal)
            cut=abs(normal@long)>.80
            across=a if abs(normal@a)<abs(normal@b) else b
            for li in poly.loop_indices:
                delta=np.array(mesh.vertices[mesh.loops[li].vertex_index].co)-center
                if cut:
                    uu=.50+(delta@a)/.70;vv=.50+(delta@b)/.70
                else:
                    uu=u0+(delta@across)/1.20;vv=v0+(delta@long)/2.80
                uv.data[li].uv=(float(uu),float(vv))
            poly.material_index=old_count+(1 if cut else 0)
            cuts+=int(cut);long_faces+=int(not cut)
        mesh.uv_layers.active=uv;uv.active_render=True
        # Earlier canonical mapping removed donor vertex tint. Keep that
        # neutral behavior so the new albedo is not multiplied by old shades.
        for attr in list(mesh.color_attributes):mesh.color_attributes.remove(attr)
        assert geometry_fingerprint(ob)==before,'Measured geometry changed'
        ob['illustratedPineV1']=True
        report.append({'object':ob.name,'building':ob['construction_building'],'solidComponents':len(frames),'longGrainFaces':long_faces,'cutEndFaces':cuts,'geometryUnchanged':True})
    return report

if __name__=='__main__':
    apply='--apply' in sys.argv
    bpy.ops.wm.open_mainfile(filepath=str(OUT/'scene.blend'));scene=bpy.context.scene
    before={o.name:geometry_fingerprint(o) for o in scene.objects if o.type=='MESH'}
    report=apply_craft_surfaces(scene)
    assert all(geometry_fingerprint(bpy.data.objects[n])==fp for n,fp in before.items())
    name='scene.blend' if apply else 'material-study.blend'
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/name),compress=True)
    manifest={'nativeScene':name,'nativeSha256':hashlib.sha256((OUT/name).read_bytes()).hexdigest(),'geometryObjectsUnchanged':len(before),'surfaces':report,'sourceImagesUnaltered':True,'generatedInterpretation':True}
    (OUT/'material-study.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
    if apply:
        contract=json.loads((OUT/'northern-contract.json').read_text(encoding='utf8'))
        known={r['object']:r for r in contract.get('illustratedTimber',[])}
        known.update({r['object']:r for r in report});contract['illustratedTimber']=list(known.values())
        (OUT/'northern-contract.json').write_text(json.dumps(contract,ensure_ascii=False,indent=2),encoding='utf8')
        for ob in scene.objects:ob.select_set(False)
        obs=[ob for ob in scene.objects if ob.type=='MESH' and ob.get('northExtension')]
        for ob in obs:ob.select_set(True);ob.hide_set(False);ob.hide_render=False
        bpy.context.view_layer.objects.active=obs[0]
        bpy.ops.export_scene.gltf(filepath=str(OUT/'northern.glb'),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True,export_extras=True)
    print('ILLUSTRATED TIMBER',len(report),'meshes;',len(before),'geometry objects unchanged',flush=True)
