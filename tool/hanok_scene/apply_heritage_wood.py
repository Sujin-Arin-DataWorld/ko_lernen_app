"""Replace the legacy facade crops with two distinct painted timber fields."""
from collections import Counter
from pathlib import Path
import hashlib
import random
import bpy
import numpy as np
from northern_timber_sections import groups
from repair_masonry_coping import fingerprint

UV_NAME='Gye heritage timber metres'
REGISTER={'Sarang golden aged timber':('sarang','hanok-sarang-wood-painted-v1.png'),
          'Sarang vertical timber grain':('sarang','hanok-sarang-wood-painted-v1.png'),
          'Jung dark walnut':('jung','hanok-jung-wood-painted-v1.png')}


def apply_heritage_wood(scene, directory):
    assert not scene.get('gyeHeritageWoodV1')
    original={ob.name:fingerprint(ob) for ob in scene.objects if ob.type=='MESH'}
    materials={}
    for name,(owner,filename) in REGISTER.items():
        mat=bpy.data.materials[name]
        path=directory/'materials'/filename
        image=bpy.data.images.load(str(path),check_existing=True)
        nodes,links=mat.node_tree.nodes,mat.node_tree.links
        shader=next(node for node in nodes if node.type=='BSDF_PRINCIPLED')
        old_source=shader.inputs['Base Color'].links[0].from_node.name
        uv=nodes.new('ShaderNodeUVMap');uv.uv_map=UV_NAME
        texture=nodes.new('ShaderNodeTexImage');texture.name='Gye full painted timber field';texture.image=image
        links.new(uv.outputs['UV'],texture.inputs['Vector'])
        links.new(texture.outputs['Color'],shader.inputs['Base Color'])
        # Archived facade crops remain available, but no longer drive the wood.
        mat['gyeHeritageWoodV1']=owner
        materials[name]={'building':owner,'image':filename,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
                         'originalColorSource':old_source}
    mapped=[]
    for ob in scene.objects:
        if ob.type!='MESH':continue
        slots={i for i,mat in enumerate(ob.data.materials) if mat and mat.name in REGISTER}
        if not slots or not any(p.material_index in slots for p in ob.data.polygons):continue
        if ob.data.users>1:ob.data=ob.data.copy()
        mesh=ob.data
        old_active=mesh.uv_layers.active.name if mesh.uv_layers.active else None
        old_render=next((layer.name for layer in mesh.uv_layers if layer.active_render),None)
        uv=mesh.uv_layers.new(name=UV_NAME)
        assert list(mesh.uv_layers).index(uv)<=3,ob.name
        vertex_component={}
        components=[]
        for component,ids in enumerate(groups(mesh)):
            points=np.array([mesh.vertices[i].co[:] for i in ids]);center=points.mean(0)
            _,axes=np.linalg.eigh((points-center).T@(points-center))
            for column in range(3):
                if axes[np.argmax(np.abs(axes[:,column])),column]<0:axes[:,column]*=-1
            rng=random.Random(ob.name+':heritage:'+str(component))
            components.append((center,axes,rng.uniform(.55,.8),rng.uniform(1.45,2.25),np.array([rng.random()*8,rng.random()*8])))
            for vertex in ids:vertex_component[vertex]=component
        for poly in mesh.polygons:
            if poly.material_index not in slots:continue
            center,axes,width,length,offset=components[vertex_component[poly.vertices[0]]]
            normal=np.array(poly.normal[:]);across=axes[:,1] if abs(normal@axes[:,0])>.65 else axes[:,0]
            for loop in poly.loop_indices:
                point=np.array(mesh.vertices[mesh.loops[loop].vertex_index].co[:])-center
                uv.data[loop].uv=(point@across/width+offset[0],point@axes[:,2]/length+offset[1])
        if old_active:mesh.uv_layers.active=mesh.uv_layers[old_active]
        if old_render:mesh.uv_layers[old_render].active_render=True
        ob['gyeHeritageWoodV1']=True
        assert fingerprint(ob,ignore_uv_layers={UV_NAME})==original[ob.name],ob.name
        mapped.append({'object':ob.name,'uvIndex':list(mesh.uv_layers).index(uv),
                       'faces':sum(p.material_index in slots for p in mesh.polygons),'components':len(components),
                       'sourceCoreFingerprint':original[ob.name]})
    scene['gyeHeritageWoodV1']=True
    return {'materials':materials,'mapping':mapped,'sourceImagesUnchanged':True,
            'originalGeometryUvAndSlotsUnchanged':True,'runtimePromotion':False}
