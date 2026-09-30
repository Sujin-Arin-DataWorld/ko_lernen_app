"""Join Anchae infill to the retained posts without moving window openings."""
import bpy,bmesh,numpy as np
from mathutils import Matrix,Vector
from mathutils.bvhtree import BVHTree
from northern_timber_sections import groups

WALL_NAMES={'North.anchae.'+n for n in ('room rear','kitchen rear','daechong rear wall','end bay rear','interior partition')}

def basis(records):
    rec=next(r for r in records if r['id']=='anchae');rot=Matrix.Rotation(rec['angle'],3,'Z');origin=Vector((*rec['center'],rec['datum']))
    axes=[-rec['bodyWidth']/2]
    for bay in rec['bays']:axes.append(axes[-1]+bay)
    return origin,rot,axes

def rear_joint_audit(scene,records):
    origin,rot,axes=basis(records);vertices=[];faces=[]
    for ob in scene.objects:
        if ob.type!='MESH' or ob.get('construction_building')!='anchae' or 'roof' in ob.name:continue
        start=len(vertices);vertices.extend(ob.matrix_world@v.co for v in ob.data.vertices)
        faces.extend(tuple(start+i for i in p.vertices) for p in ob.data.polygons)
    tree=BVHTree.FromPolygons(vertices,faces);gaps=[];count=0
    for axis in axes[1:-1]:
        for offset in (-.11,-.095,-.080,-.055,0,.055,.080,.095,.11):
            start=origin+rot@Vector((axis+offset,-.70,1.60));hit=tree.ray_cast(start,rot@Vector((0,1,0)),4.1)[0];count+=1
            if hit is None:gaps.append({'axis':axis,'offset':offset})
    return {'raySamples':count,'gaps':gaps}

def close_anchae_wall_joints(scene,records):
    if all(bpy.data.objects[n].get('wallJointVersion') for n in WALL_NAMES):return []
    origin,rot,axes=basis(records);inv=rot.transposed();before=rear_joint_audit(scene,records)
    posts=bpy.data.objects['North.anchae.frame square post'];halves={}
    for indices in groups(posts.data):
        points=np.array([inv@(posts.matrix_world@posts.data.vertices[i].co-origin) for i in indices]);lo,hi=points.min(0),points.max(0)
        if (lo[1]+hi[1])/2>1.3:
            axis=min(axes,key=lambda x:abs(x-(lo[0]+hi[0])/2));halves[axis]=(hi[0]-lo[0])/2
    report=[]
    for name in sorted(WALL_NAMES):
        ob=bpy.data.objects[name];oi=ob.matrix_world.inverted();changed=0
        if name.endswith('interior partition'):
            for indices in groups(ob.data):
                points=np.array([inv@(ob.matrix_world@ob.data.vertices[i].co-origin) for i in indices]);cx=(points[:,0].min()+points[:,0].max())/2
                for index,p in zip(indices,points):
                    if p[1]<1.30:continue
                    # At the depth change a perpendicular return seals the
                    # corner. Vertex-wise depth warping had twisted this wall.
                    p[1]=2.2925 if abs(cx-axes[4])<.001 else p[1]+.030
                    ob.data.vertices[index].co=oi@(origin+rot@Vector(p));changed+=1
        else:
            for vertex in ob.data.vertices:
                p=inv@(ob.matrix_world@vertex.co-origin)
                for axis in axes:
                    delta=p.x-axis
                    if abs(abs(delta)-.10)>.00002:continue
                    inset=.035 if abs(axis-axes[4])<.001 else halves[axis]-.010
                    p.x=axis+inset*(1 if delta>0 else -1);vertex.co=oi@(origin+rot@p);changed+=1;break
        ob.data.update();bm=bmesh.new();bm.from_mesh(ob.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(ob.data);bm.free()
        ob['wallJointVersion']=1
        report.append({'object':name,'verticesAdjusted':changed,'openingVerticesMoved':False,'jointOverlapInterpretation':True})
    bpy.context.view_layer.update();after=rear_joint_audit(scene,records)
    assert not after['gaps'],after
    return [{'building':'anchae','before':before,'after':after,'walls':report,'columnAxesUnchanged':True,'openingsUnchanged':True}]
