"""Close the retained roof bedding and seat the existing ridge courses.

Section 052 shows sanja/jeoksim/boto beneath the Anchae tiles, not daylight.
No eave, tile, roof pitch or ridge count is changed. The existing 60 mm bed
envelope is retained as a modelling interpretation, not a surveyed thickness.
"""
from pathlib import Path
import bpy,bmesh,math,numpy as np
from mathutils import Vector,Matrix

OUT=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
SCOPE=('anchae','arae','angotgan','gokgan')

def close_mesh(mesh):
    bm=bmesh.new();bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    assert all(e.is_manifold for e in bm.edges),(mesh.name,'Open boundary')
    bm.to_mesh(mesh);bm.free();mesh.update()

def metadata(ob,ident):
    ob['northExtension']=True;ob['construction_building']=ident
    ob['construction_first']=1;ob['construction_last']=99
    ob['source_object_name']=ob.name;ob['roofEnvelopeVersion']=1

def align_hip_bed_grid(ob,rec,offset):
    # The tile overlap (row + 1.03) had also been applied to the hidden bed.
    # Join bed rows at row + 1; ceramic overlaps stay on the separate tiles.
    origin=Vector((*rec['center'],rec['datum']));rot=Matrix.Rotation(rec['angle'],3,'Z');inv=rot.transposed();oi=ob.matrix_world.inverted()
    hx,hy,hr=12.45/2,8.16/2,4.875/2
    for vertex in ob.data.vertices:
        x,y,z=inv@(ob.matrix_world@vertex.co-origin)
        ty=abs(y)/hy;tx=max(0,(abs(x)-hr)/(hx-hr));t=max(tx,ty);joined=round(t*12)/12
        if ty>=tx-1e-5:
            xx=x/(hr*(1-t)+hx*t)*(hr*(1-joined)+hx*joined);yy=math.copysign(hy*joined,y)
        else:xx=math.copysign(hr+(hx-hr)*joined,x);yy=y/t*joined if t>1e-8 else 0
        zz=3.09+(5.225-3.09)*(1-joined)**1.40+.23*(abs(xx)/hx)**8*joined*joined+offset
        vertex.co=oi@(origin+rot@Vector((xx,yy,zz)))
    bm=bmesh.new();bm.from_mesh(ob.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00003)
    bmesh.ops.dissolve_degenerate(bm,dist=.00003,edges=list(bm.edges));bm.to_mesh(ob.data);bm.free();ob.data.update()

def seal_bedding(scene,rec):
    ident=rec['id'];prefix='hip roof continuous bed' if ident=='gokgan' else 'roof continuous bed'
    old=[o for o in scene.objects if o.type=='MESH' and o.name.startswith('North.'+ident+'.'+prefix)]
    assert len(old)==2,(ident,[o.name for o in old])
    top,bottom=sorted(old,key=lambda o:sum((o.matrix_world@v.co).z for v in o.data.vertices)/len(o.data.vertices),reverse=True)
    if ident=='gokgan':
        align_hip_bed_grid(top,rec,-.040);align_hip_bed_grid(bottom,rec,-.100)
    vertices=[];faces=[];materials=[];face_mats=[];uv_rows={};color_rows={}
    source_offsets={}
    for ob in (top,bottom):
        source_offsets[ob.name]=len(vertices)
        vertices.extend(tuple(ob.matrix_world@v.co) for v in ob.data.vertices)
        for layer in ob.data.uv_layers:uv_rows.setdefault(layer.name,[])
        for layer in ob.data.color_attributes:
            assert layer.domain=='CORNER';color_rows.setdefault(layer.name,[])
    for ob in (top,bottom):
        for poly in ob.data.polygons:
            faces.append(tuple(source_offsets[ob.name]+i for i in poly.vertices))
            mat=bpy.data.materials['North lime plaster'] if ident=='anchae' and ob==bottom else ob.data.materials[poly.material_index]
            if mat not in materials:materials.append(mat)
            face_mats.append(materials.index(mat))
            for name,rows in uv_rows.items():
                layer=ob.data.uv_layers.get(name);rows.append([tuple(layer.data[i].uv) if layer else (0,0) for i in poly.loop_indices])
            for name,rows in color_rows.items():
                layer=ob.data.color_attributes.get(name);rows.append([tuple(layer.data[i].color) if layer else (1,1,1,1) for i in poly.loop_indices])
    def key(co):return (round(co[0],5),round(co[1],5))
    bottom_xy={key(ob_co):source_offsets[bottom.name]+i for i,v in enumerate(bottom.data.vertices) for ob_co in [bottom.matrix_world@v.co]}
    edges={}
    for p in top.data.polygons:
        vs=list(p.vertices)
        for a,b in zip(vs,vs[1:]+vs[:1]):edges[tuple(sorted((a,b)))]=edges.get(tuple(sorted((a,b))),0)+1
    rim=bpy.data.materials['North earthen plaster']
    if rim not in materials:materials.append(rim)
    rim_faces=0
    for (a,b),count in edges.items():
        if count!=1:continue
        ia=source_offsets[top.name]+a;ib=source_offsets[top.name]+b
        ja=bottom_xy[key(vertices[ia])];jb=bottom_xy[key(vertices[ib])]
        face=(ia,ib,jb,ja);faces.append(face);face_mats.append(materials.index(rim));rim_faces+=1
        for rows in uv_rows.values():rows.append([(vertices[i][0],vertices[i][2]) for i in face])
        for rows in color_rows.values():rows.append([(1,1,1,1)]*4)
    mesh=bpy.data.meshes.new('North.'+ident+'.closed bedding mesh');mesh.from_pydata(vertices,[],faces);mesh.update()
    for mat in materials:mesh.materials.append(mat)
    for poly,index in zip(mesh.polygons,face_mats):poly.material_index=index
    for name,rows in uv_rows.items():
        layer=mesh.uv_layers.new(name=name)
        for poly,coords in zip(mesh.polygons,rows):
            for li,co in zip(poly.loop_indices,coords):layer.data[li].uv=co
    for name,rows in color_rows.items():
        layer=mesh.color_attributes.new(name=name,type='FLOAT_COLOR',domain='CORNER')
        for poly,colors in zip(mesh.polygons,rows):
            for li,color in zip(poly.loop_indices,colors):layer.data[li].color=color
    close_mesh(mesh)
    ob=bpy.data.objects.new('North.'+ident+'.roof solid bedding',mesh);scene.collection.objects.link(ob);metadata(ob,ident)
    ob['mineralSurfaceVersion']=1
    ob['retainedBedThickness']=.060
    ob['authority']='Retained roof envelope; bedding volume is an interpretation of surveyed roof layering'
    if ident=='anchae':ob['photographedLimeSoffit']=True
    removed=[o.name for o in old]
    for source in old:bpy.data.objects.remove(source,do_unlink=True)
    return ob,{'building':ident,'object':ob.name,'replacedPlanes':removed,'surfaceVerticesRetained':len(vertices),'closedRimFaces':rim_faces,'surveyThicknessClaimed':False}

def pack_ridge(scene,rec,bed):
    ident=rec['id'];ridge=bpy.data.objects['North.'+ident+('.hip roof five ridge courses' if ident=='gokgan' else '.roof.ridge stack')]
    origin=Vector((*rec['center'],rec['datum']));rotation=Matrix.Rotation(rec['angle'],3,'Z');inverse=rotation.transposed()
    points=np.array([inverse@(ridge.matrix_world@v.co-origin) for v in ridge.data.vertices]);lo,hi=points.min(0),points.max(0)
    # The narrow internal fill stays inside the 134 mm ridge tile profile.
    x0,x1=lo[0]+.025,hi[0]-.025;y=float((lo[1]+hi[1])/2);width=.086
    scene.view_layers[0].update();dep=bpy.context.evaluated_depsgraph_get()
    def height(ob,x):
        ev=ob.evaluated_get(dep);inv=ev.matrix_world.inverted()
        direction=inv.to_3x3()@Vector((0,0,-1))
        heights=[]
        # A ray exactly on the end cap shared by two tile segments can miss
        # their upper course. Probe either side of that numerical edge.
        for dx in (-.001,0,.001):
            for dy in (-.001,0,.001):
                start=inv@(origin+rotation@Vector((float(x)+dx,y+dy,30)))
                hit,co,_,_=ev.ray_cast(start,direction,distance=40)
                if hit:heights.append(float((inverse@(ev.matrix_world@co-origin)).z))
        assert heights,(ident,ob.name,float(x))
        return max(heights)
    vertices=[];faces=[];sections=[]
    for x in np.linspace(x0,x1,65):
        bottom=height(bed,x)-.018;top=height(ridge,x)-.050
        assert top>bottom
        sections.append([float(x),bottom,top])
        for yy,zz in ((y-width/2,bottom),(y+width/2,bottom),(y+width/2,top),(y-width/2,top)):
            vertices.append(tuple(origin+rotation@Vector((float(x),yy,zz))))
    for i in range(64):
        a=i*4;b=a+4
        for j in range(4):k=(j+1)%4;faces.append((a+j,a+k,b+k,b+j))
    faces.extend([(3,2,1,0),(256,257,258,259)])
    mesh=bpy.data.meshes.new('North.'+ident+'.ridge bedding mesh');mesh.from_pydata(vertices,[],faces);mesh.update();close_mesh(mesh)
    mesh.materials.append(bpy.data.materials['Ansarang retained V33 main_gate source ceramic 2'])
    ob=bpy.data.objects.new('North.'+ident+'.roof packed ridge core',mesh);scene.collection.objects.link(ob);metadata(ob,ident)
    ob['packingWidth']=width;ob['authority']='Internal ridge fill; existing tile course silhouette and count retained'
    return {'building':ident,'object':ob.name,'internalWidth':width,'sections':sections,'surveyThicknessClaimed':False}

def refine_roof_envelopes(scene,records):
    report=[]
    for ident in SCOPE:
        if bpy.data.objects.get('North.'+ident+'.roof solid bedding'):continue
        bed,record=seal_bedding(scene,next(r for r in records if r['id']==ident));report.append(record)
        report.append(pack_ridge(scene,next(r for r in records if r['id']==ident),bed))
    return report
