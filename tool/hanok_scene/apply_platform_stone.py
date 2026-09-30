"""Add shallow irregular stone paving over exposed platform top planes."""
from collections import defaultdict
import math
import random
import bpy
import numpy as np
from mathutils import Vector
from repair_gokgan_clearance import hull
from apply_estate_matte_register import owner_of

UV_NAME='Gye paving pigment metres'


def clip(poly,normal,limit):
    result=[]
    for a,b in zip(poly,np.roll(poly,-1,axis=0)):
        da=float(a@normal-limit);db=float(b@normal-limit)
        if da<=1e-7:result.append(a)
        if (da<0)!=(db<0):result.append(a+(b-a)*da/(da-db))
    return np.asarray(result)


def area(poly):
    return abs(float(np.sum(poly[:,0]*np.roll(poly[:,1],-1)-poly[:,1]*np.roll(poly[:,0],-1)))/2)


def apply_platform_stone(scene):
    assert not scene.get('gyePlatformStoneV1')
    regions=defaultdict(list)
    exact={'Sarang.wing platform','Craft.Sarang platform inner core','Jung.plinth cap',
           'V32.ansarang.foundation recessed core','V28.changgo.foundation.core',
           'V28.toilet.foundation.core','V28.toilet1.foundation.core',
           'PhotoGate.wing earth foundation','PhotoGate.courtyard ochre plinth'}
    for ob in scene.objects:
        if ob.type!='MESH' or ob.hide_render:continue
        if ob.name not in exact and 'foundation earth top' not in ob.name:continue
        owner=owner_of(ob)
        for poly in ob.data.polygons:
            points=np.array([ob.matrix_world@ob.data.vertices[i].co for i in poly.vertices])
            normal=ob.matrix_world.to_3x3()@poly.normal
            if normal.z<.95 or np.ptp(points[:,2])>.001:continue
            outline=hull(points[:,:2])
            if len(outline)<3 or area(outline)<.15:continue
            regions[owner].append({'outline':outline,'z':float(points[:,2].mean()),'source':ob.name})
    # The authored landing stones form the front strip adjacent to the inner core.
    regions['sarang'].append({'outline':np.array([[-.66,-.69],[10.68,-.69],[10.68,.265],[-.66,.265]]),
                             'z':1.1,'source':'Craft.Sarang landing cap family'})
    materials=[]
    for i in range(5):
        mat=bpy.data.materials[f'Pale granite {i}'].copy();mat.name=f'Gye paving warm stone {i}'
        for node in mat.node_tree.nodes:
            if node.type=='UVMAP' and node.uv_map=='Gye stone pigment metres':node.uv_map=UV_NAME
        mat['gyePlatformStoneV1']=True
        materials.append(mat)
    records=[]
    for owner,patches in regions.items():
        chunks=defaultdict(lambda: {'vertices':[],'faces':[],'offsets':[]})
        count=0
        for region_index,region in enumerate(patches):
            outline=region['outline'];low,high=outline.min(0),outline.max(0)
            rng=random.Random(owner+':paving:'+str(region_index));seeds=[]
            for y in np.arange(low[1]-.65,high[1]+.65,.5):
                for x in np.arange(low[0]-.9,high[0]+.9,.72):
                    seeds.append(np.array([x+rng.uniform(-.20,.20),y+rng.uniform(-.14,.14)]))
            for seed in seeds:
                cell=outline.copy()
                for other in seeds:
                    difference=other-seed
                    if not np.any(difference) or np.linalg.norm(difference)>1.8:continue
                    cell=clip(cell,difference,float((other@other-seed@seed)/2))
                    if len(cell)<3:break
                if len(cell)<3 or area(cell)<.012:continue
                center=cell.mean(0);radius=max(np.linalg.norm(cell-center,axis=1));cell=center+(cell-center)*(1-.009/max(radius,.03))
                z=region['z']+.006+rng.uniform(0,.004);thickness=rng.uniform(.009,.014)
                material=rng.randrange(5);chunk=chunks[material];start=len(chunk['vertices']);n=len(cell)
                chunk['vertices'].extend([(float(p[0]),float(p[1]),z) for p in cell])
                chunk['vertices'].extend([(float(p[0]),float(p[1]),z+thickness) for p in cell])
                chunk['faces'].append(tuple(start+n+i for i in range(n)))
                chunk['faces'].extend([(start+i,start+(i+1)%n,start+n+(i+1)%n,start+n+i) for i in range(n)])
                chunk['offsets'].append((start,2*n,rng.random()*8,rng.random()*8,rng.uniform(-math.pi,math.pi)))
                count+=1
        objects=[]
        for material,chunk in chunks.items():
            name=f'GyeCraft.{owner}.irregular paving {material}'
            mesh=bpy.data.meshes.new(name);mesh.from_pydata(chunk['vertices'],[],chunk['faces']);mesh.materials.append(materials[material])
            uv=mesh.uv_layers.new(name=UV_NAME);vertex_uv={}
            for start,length,u,v,angle in chunk['offsets']:
                rotation=np.array([[math.cos(angle),-math.sin(angle)],[math.sin(angle),math.cos(angle)]])
                for i in range(start,start+length):vertex_uv[i]=np.array(chunk['vertices'][i][:2])@rotation/.72+np.array([u,v])
            for loop in mesh.loops:uv.data[loop.index].uv=vertex_uv[loop.vertex_index]
            ob=bpy.data.objects.new(name,mesh);scene.collection.objects.link(ob)
            for key,value in {'construction_building':owner,'construction_first':1,'construction_last':99,
                              'gyePlatformStoneV1':True,'source_object_name':name}.items():ob[key]=value
            bevel=ob.modifiers.new('Small chipped paving corners','BEVEL');bevel.width=.003;bevel.segments=1
            bevel.limit_method='ANGLE';bevel.angle_limit=.5
            objects.append(name)
        records.append({'building':owner,'stones':count,'objects':objects,
                        'sources':sorted({region['source'] for region in patches}),
                        'surfaceAreaSquareMeters':sum(area(region['outline']) for region in patches)})
    assert {record['building'] for record in records}>={'sarang','jung','gokgan','changgo','anchae','ansarang'}
    scene['gyePlatformStoneV1']=True
    return {'buildings':records,'maximumAddedHeightMeters':.024,'courtyardEarthChanged':False,
            'originalFoundationGeometryChanged':False,'runtimePromotion':False}
