"""Move the requested rear boundary as one connected wall and coping network."""
from pathlib import Path
import json
import bpy
import numpy as np
from mathutils import Vector
from northern_timber_sections import groups
from repair_masonry_coping import fingerprint


def hull(points):
    points=sorted(set(tuple(p) for p in points))
    def cross(a,b,c):return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
    lower=[];upper=[]
    for p in points:
        while len(lower)>1 and cross(lower[-2],lower[-1],p)<=0:lower.pop()
        lower.append(p)
    for p in reversed(points):
        while len(upper)>1 and cross(upper[-2],upper[-1],p)<=0:upper.pop()
        upper.append(p)
    return np.array(lower[:-1]+upper[:-1])


def polygon_distance(a,b):
    def inside(p,polygon):
        d=np.roll(polygon,-1,axis=0)-polygon;r=p-polygon
        return bool(np.all(d[:,0]*r[:,1]-d[:,1]*r[:,0]>=-1e-7))
    def to_segment(p,u,v):
        d=v-u;t=np.clip(np.dot(p-u,d)/np.dot(d,d),0,1)
        return float(np.linalg.norm(p-u-t*d))
    if any(inside(p,b) for p in a) or any(inside(p,a) for p in b):return 0.
    for u,v in zip(a,np.roll(a,-1,axis=0)):
        for p,q in zip(b,np.roll(b,-1,axis=0)):
            d=v-u;e=q-p;den=d[0]*e[1]-d[1]*e[0]
            if abs(den)<1e-9:continue
            r=p-u;t=(r[0]*e[1]-r[1]*e[0])/den;s=(r[0]*d[1]-r[1]*d[0])/den
            if 0<=t<=1 and 0<=s<=1:return 0.
    return min(to_segment(p,u,v) for pset,poly in ((a,b),(b,a)) for p in pset
               for u,v in zip(poly,np.roll(poly,-1,axis=0)))


def footprint(ob):
    return hull([(ob.matrix_world@vertex.co)[:2] for vertex in ob.data.vertices])


def repair_gokgan_clearance(scene,directory):
    assert not scene.get('gokganRearClearanceV1')
    network=json.loads((directory/'gokgan-clearance-source-network.json').read_text(encoding='utf8'))
    cores={row['name']:row for row in network['cores']}
    A=[30.1,2.40];B=[30.5,15.78];C=[30.5,18.90]
    endpoints={
        'North.site.gwang east.earth core':(None,A),
        'North.site.gwang north.earth core':(A,B),
        'Estate.fabric.gwang byeoldang join.earth core':(A,None),
        'Estate.fabric.shrine gwang join.earth core':(B,C),
        'North.site.shrine gate right earth core':(None,C),
        'North.site.shrine rear.earth core':(C,None),
    }
    before={ob.name:fingerprint(ob) for ob in scene.objects if ob.type=='MESH'}
    building=bpy.data.objects['North.gokgan.foundation.recessed earth mortar']
    outline=footprint(building)
    records=[];routes=[];seen=set()
    for name,(new_start,new_stop) in endpoints.items():
        row=cores[name];a,b=np.array(row['start']),np.array(row['stop'])
        A2=np.array(new_start or a);B2=np.array(new_stop or b)
        delta=b-a;length=np.linalg.norm(delta);direction=delta/length;normal=np.array([-direction[1],direction[0]])
        new_direction=(B2-A2)/np.linalg.norm(B2-A2);new_normal=np.array([-new_direction[1],new_direction[0]])
        prefix=name[:-len('.earth core')] if name.endswith('.earth core') else name[:-len(' earth core')]
        selected=[ob for ob in scene.objects if ob.type=='MESH' and ob.name.startswith(prefix) and
                                    (ob.name[len(prefix):len(prefix)+1] in ('.',' '))]
        assert selected,prefix
        assert not (seen & {ob.name for ob in selected}),prefix
        seen.update(ob.name for ob in selected)
        old_gap=polygon_distance(outline,footprint(bpy.data.objects[name]))
        for ob in selected:
            if ob.data.users>1:ob.data=ob.data.copy()
            inverse=ob.matrix_world.inverted()
            # Keep flower insets rigid while spacing their component centres along the new run.
            rigid='inset petal' in ob.name or 'inset central' in ob.name
            for ids in groups(ob.data) if rigid else [range(len(ob.data.vertices))]:
                center=np.mean([ob.matrix_world@ob.data.vertices[i].co for i in ids],axis=0) if rigid else None
                for index in ids:
                    vertex=ob.data.vertices[index];point=np.array(ob.matrix_world@vertex.co)
                    reference=center if rigid else point
                    relative=reference[:2]-a;t=relative@direction/length;s=relative@normal
                    xy=A2+(B2-A2)*t+new_normal*s
                    if rigid:
                        local=point[:2]-center[:2]
                        xy+=new_direction*(local@direction)+new_normal*(local@normal)
                    vertex.co=inverse@Vector((float(xy[0]),float(xy[1]),float(point[2])))
            ob.data.update();ob['gokganRearClearanceV1']=True
            records.append({'object':ob.name,'beforeFingerprint':before[ob.name],'afterFingerprint':fingerprint(ob)})
        gap=polygon_distance(outline,footprint(bpy.data.objects[name]))
        routes.append({'core':name,'group':prefix,'oldStart':a.tolist(),'oldStop':b.tolist(),
                       'newStart':A2.tolist(),'newStop':B2.tolist(),'oldClearanceMeters':old_gap,'clearanceMeters':gap})
    moved={row['object'] for row in records}
    assert all(fingerprint(bpy.data.objects[name])==expected for name,expected in before.items() if name not in moved)
    long=next(row for row in routes if row['core']=='North.site.gwang north.earth core')
    assert long['clearanceMeters']>.95,long
    assert all(row['clearanceMeters']>.20 for row in routes),routes
    scene['gokganRearClearanceV1']=True
    return {'movedObjects':records,'routes':routes,'buildingFootprint':outline.tolist(),
            'buildingMoved':False,'requestedRearClearanceMeters':.95,'otherOriginalObjectsUnchanged':True,
            'runtimePromotion':False}
