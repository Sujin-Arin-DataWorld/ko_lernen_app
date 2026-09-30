"""Quiet mineral paint follows the volume and fibers of shrine timber.

Generated albedos interpret the canonical illustration and supplied photographs;
they are not scans of the surviving paint. Structural geometry is unchanged.
"""
from pathlib import Path
import bpy, math, random, numpy as np
from northern_timber_sections import groups
from refine_northern_materials import geometry_fingerprint

OUT=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
UV='Painted timber metres'

def painted_material(kind, rebuild=False):
    name='Illustrated mineral paint '+kind+' v1'
    if name in bpy.data.materials and not rebuild:return bpy.data.materials[name]
    mat=bpy.data.materials.get(name) or bpy.data.materials.new(name);mat.use_nodes=True
    nodes=mat.node_tree.nodes;links=mat.node_tree.links;nodes.clear()
    shader=nodes.new('ShaderNodeBsdfPrincipled');shader.inputs['Roughness'].default_value=.90;shader.inputs['Specular IOR Level'].default_value=.17
    output=nodes.new('ShaderNodeOutputMaterial');links.new(shader.outputs[0],output.inputs['Surface'])
    uv=nodes.new('ShaderNodeUVMap');uv.uv_map=UV
    color=nodes.new('ShaderNodeTexImage');color.image=bpy.data.images.load(str(OUT/'materials'/f'hanok-painted-{kind}-v1.png'),check_existing=True);color.extension='REPEAT'
    links.new(uv.outputs['UV'],color.inputs['Vector'])
    # The glTF exporter recognizes the modern RGBA Mix node's constant factor.
    # Legacy MixRGB renders correctly in Blender but silently loses this tint.
    tint=nodes.new('ShaderNodeMix');tint.data_type='RGBA';tint.blend_type='MULTIPLY'
    socket=lambda identifier:next(s for s in tint.inputs if s.identifier==identifier)
    socket('Factor_Float').default_value=1
    socket('B_Color').default_value=(.67,.86,1.0,1) if kind=='red' else (.82,.90,.88,1)
    links.new(color.outputs['Color'],socket('A_Color'))
    links.new(next(s for s in tint.outputs if s.identifier=='Result_Color'),shader.inputs['Base Color'])
    relief=nodes.new('ShaderNodeTexImage');relief.image=bpy.data.images.load(str(OUT/'materials'/f'hanok-painted-{kind}-normal-v1.png'),check_existing=True);relief.image.colorspace_settings.name='Non-Color';relief.extension='REPEAT'
    normal=nodes.new('ShaderNodeNormalMap');normal.uv_map=UV;normal.inputs['Strength'].default_value=.45
    links.new(uv.outputs['UV'],relief.inputs['Vector']);links.new(relief.outputs['Color'],normal.inputs['Color']);links.new(normal.outputs['Normal'],shader.inputs['Normal'])
    mat['surfaceKind']='illustrated_paint_'+kind;mat['physicalTextureMeters']=[.60,1.80]
    mat['linearPigmentTint']=list(socket('B_Color').default_value)
    mat['authority']='Canonical illustration finish and actual shrine/gate photographs; new pigment interpretation, not a historic damage scan'
    return mat

def apply_painted_timber(scene):
    report=[]
    for ob in scene.objects:
        if ob.type!='MESH' or ob.get('construction_building') not in ('sadang','sadangmun') or ob.get('paintedTimberV1'):continue
        if any(k in ob.name for k in ('taegeuk paint','flower','petal','rosette','collar','outline','contour','painted border')):continue
        slots={}
        for i,mat in enumerate(ob.data.materials):
            if mat is None:continue
            kind=mat.get('surfaceKind')
            if kind=='post' or mat.name=='North weathered vermilion':slots[i]='red'
            elif (kind=='beam' and 'floor' not in ob.name) or mat.name=='North aged blue green':slots[i]='green'
        if not slots:continue
        before=geometry_fingerprint(ob);mesh=ob.data;uv=mesh.uv_layers.get(UV) or mesh.uv_layers.new(name=UV)
        remap={}
        for slot,kind in slots.items():remap[slot]=len(mesh.materials);mesh.materials.append(painted_material(kind))
        frames={};owner={};rng=random.Random(ob.name)
        for ci,ids in enumerate(groups(mesh)):
            cloud=np.array([mesh.vertices[i].co[:] for i in ids]);center=cloud.mean(0)
            values,basis=np.linalg.eigh((cloud-center).T@(cloud-center));long=basis[:,2]
            if long[np.argmax(abs(long))]<0:long=-long
            a,b=basis[:,1],basis[:,0];rad=np.linalg.norm(np.column_stack(((cloud-center)@a,(cloud-center)@b)),axis=1)
            cylindrical=len(ids)>12 and np.std(rad)<.002 and np.mean(rad)>.02
            frames[ci]=(center,long,a,b,rng.random(),rng.random(),cylindrical,float(np.mean(rad)))
            for i in ids:owner[i]=ci
        cylindrical_faces=0;faces=0
        for poly in mesh.polygons:
            if poly.material_index not in slots:continue
            center,long,a,b,u0,v0,round_member,radius=frames[owner[poly.vertices[0]]];normal=np.array(poly.normal);cut=abs(normal@long)>.8
            across=a if abs(normal@a)<abs(normal@b) else b
            deltas=[np.array(mesh.vertices[mesh.loops[li].vertex_index].co)-center for li in poly.loop_indices]
            angles=[math.atan2(float(d@b),float(d@a)) for d in deltas]
            if max(angles)-min(angles)>math.pi:angles=[q+math.tau if q<0 else q for q in angles]
            for li,d,angle in zip(poly.loop_indices,deltas,angles):
                if cut:co=(u0+float(d@a)/.60,v0+float(d@b)/1.80)
                elif round_member:co=(u0+angle*radius/.60,v0+float(d@long)/1.80)
                else:co=(u0+float(d@across)/.60,v0+float(d@long)/1.80)
                uv.data[li].uv=co
            cylindrical_faces+=int(round_member and not cut);faces+=1;poly.material_index=remap[poly.material_index]
        mesh.uv_layers.active=uv;uv.active_render=True
        for attr in list(mesh.color_attributes):mesh.color_attributes.remove(attr)
        assert geometry_fingerprint(ob)==before
        ob['paintedTimberV1']=True
        report.append({'object':ob.name,'building':ob['construction_building'],'paint':sorted(set(slots.values())),'components':len(frames),'faces':faces,'cylindricalFaces':cylindrical_faces,'geometryUnchanged':True})
    return report
