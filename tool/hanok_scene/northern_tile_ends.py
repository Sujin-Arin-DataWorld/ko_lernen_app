"""Lime plugs fit beneath the curved sukiwa instead of forming white cylinders.

Profile character comes from the close photograph of the shrine gate and wall
coping. Millimetre offsets are a modeled fit to the existing tile shell, not a
newly measured historic dimension. Roof shells and eave axes are untouched.
"""
import math
import numpy as np
from mathutils import Vector
import bmesh
from northern_timber_sections import groups

def give_tile_shells_depth(scene):
    """Add an inward ceramic skin; 8 mm is a fitted modeling value."""
    report=[]
    for ob in scene.objects:
        if ob.type!='MESH' or not ob.get('northExtension') or ob.get('tileShellVersion',0)>=1:continue
        if 'continuous bed' in ob.name:continue
        mats=[ob.data.materials[i] for i in {p.material_index for p in ob.data.polygons}]
        if not mats or not all('source ceramic ' in m.name or m.get('surfaceKind')=='illustrated_clay' for m in mats):continue
        bm=bmesh.new();bm.from_mesh(ob.data);boundary=sum(e.is_boundary for e in bm.edges);bm.free()
        if not boundary:continue  # Ridge cylinders already have closed volume.
        modifier=ob.modifiers.new('Ceramic thickness 8 mm','SOLIDIFY');modifier.thickness=.008;modifier.offset=-1;modifier.use_even_offset=True;modifier.use_quality_normals=True
        ob['tileShellVersion']=1;ob['shellThicknessAuthority']='8 mm inward fit to modeled curved tile; not an independently surveyed dimension'
        report.append({'object':ob.name,'thicknessMeters':.008,'inward':True,'previousBoundaryEdges':boundary,'fitIsInterpretation':True})
    return report

def refine_tile_end_profiles(scene):
    report=[]
    for ob in scene.objects:
        if ob.type!='MESH' or not ob.get('northExtension') or ob.get('tilePlugVersion',0)>=1:continue
        name=ob.name
        if not any(t in name for t in ('.round tile ends','.hip round tile ends','.hip roof white ends')):continue
        if 'sadangmun.roof.round tile ends' in name:width,height,offset=.062,.052,-.025
        elif '.hip roof white ends' in name:width,height,offset=.043,.050,-.015
        elif '.hip round tile ends' in name:width,height,offset=.063,.045,-.010
        else:width,height,offset=.053,.047,-.025
        vertices=[];faces=[];parts=0;inverse=ob.matrix_world.inverted()
        for indices in groups(ob.data):
            cloud=np.array([ob.matrix_world@ob.data.vertices[i].co for i in indices]);center=cloud.mean(0)
            values,basis=np.linalg.eigh((cloud-center).T@(cloud-center))
            axis=basis[:,0];axis[2]=0;axis/=np.linalg.norm(axis)
            across=np.cross(axis,[0,0,1]);depth=(cloud-center)@axis;lo=float(depth.min());hi=float(depth.max())
            profile=[(width*math.cos(j*math.pi/12),offset+height*math.sin(j*math.pi/12)) for j in range(13)]
            start=len(vertices)
            for distance in (lo,hi):
                for u,z in profile:
                    point=center+axis*distance+across*u+np.array([0,0,z])
                    vertices.append(tuple(inverse@Vector(point)))
            faces.append(tuple(start+j for j in reversed(range(13))));faces.append(tuple(start+13+j for j in range(13)))
            for j in range(13):
                k=(j+1)%13;faces.append((start+j,start+k,start+13+k,start+13+j))
            parts+=1
        ob.data.clear_geometry();ob.data.from_pydata(vertices,[],faces);ob.data.update()
        bm=bmesh.new();bm.from_mesh(ob.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(ob.data);bm.free()
        for poly in ob.data.polygons:poly.use_smooth=len(poly.vertices)==4 and poly.normal.z>.1
        ob['tilePlugVersion']=1;ob['profileAuthority']='Shrine gate photograph: semicircular lime fill inside a dark ceramic shell; fit dimensions are modeled'
        report.append({'object':name,'components':parts,'profile':'solid half ellipse with flat base','widthMeters':2*width,'heightMeters':height,'roofShellUnchanged':True,'fitIsInterpretation':True})
    return report
