"""Seat shrine beams, expose shaped brackets and give roof boarding real depth.

059: rafters 165 (150 at tip), buyeon 87x120. 061: wind boards T30,
battens 45x27. The retained roof envelope is unchanged. Curves and pigment
are illustration interpretations of the supplied photographs, not new surveys.
"""
from pathlib import Path
import bpy,math,sys,numpy as np
from mathutils import Matrix,Vector
from northern_timber_sections import groups
OUT=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
OLD=Path('C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-warm-stone-20260923/tool/hanok_scene')
sys.path.insert(0,str(OLD))
import reconstruction_geometry as g
import reference_detail_geometry as d

def frieze_material():
    name='Illustrated shrine dancheong frieze v1'
    if name in bpy.data.materials:return bpy.data.materials[name]
    m=bpy.data.materials.new(name);m.use_nodes=True
    nodes=m.node_tree.nodes;links=m.node_tree.links;nodes.clear()
    p=nodes.new('ShaderNodeBsdfPrincipled');p.inputs['Roughness'].default_value=.93;p.inputs['Specular IOR Level'].default_value=.16
    out=nodes.new('ShaderNodeOutputMaterial');links.new(p.outputs['BSDF'],out.inputs['Surface'])
    tex=nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(OUT/'materials/hanok-dancheong-frieze-v1.png'),check_existing=True);tex.extension='REPEAT'
    uv=nodes.new('ShaderNodeUVMap');uv.uv_map='Shrine frieze pigment';links.new(uv.outputs['UV'],tex.inputs['Vector']);links.new(tex.outputs['Color'],p.inputs['Base Color'])
    m['surfaceKind']='illustrated_dancheong';m['authority']='New illustrated pigment from canonical and actual shrine photograph, not an exact historic paint tracing'
    return m

def retain_lime_soffit():
    ob=bpy.data.objects.get('North.sadang.joinery.solid roof bedding')
    if ob is None or ob.get('limeSoffitVersion'):return
    index=len(ob.data.materials);ob.data.materials.append(bpy.data.materials['North lime plaster'])
    for face in ob.data.polygons:
        if (ob.matrix_world.to_3x3()@face.normal).z<-.01:face.material_index=index
    ob['limeSoffitVersion']=1

def refine_shrine_joinery(scene,records):
    retain_lime_soffit()
    # Earlier review retained a 50 mm clearance above the thin gable skin.
    # Seat the solid replacement against the underside of the roof bedding.
    old_gable=bpy.data.objects.get('North.sadang.joinery.gable thirty millimetre planks')
    if old_gable and not old_gable.get('gableRoofSeatVersion'):
        datum=next(r['datum'] for r in records if r['id']=='sadang')
        delta=old_gable.matrix_world.inverted().to_3x3()@Vector((0,0,.052))
        for v in old_gable.data.vertices:
            if (old_gable.matrix_world@v.co).z>datum+3.706:v.co+=delta
        old_gable.data.update();old_gable['gableRoofSeatVersion']=1
    if any(o.get('shrineJoineryVersion') for o in scene.objects):return []
    rec=next(r for r in records if r['id']=='sadang');rot=Matrix.Rotation(rec['angle'],3,'Z');inv=rot.transposed();origin=Vector((*rec['center'],rec['datum']))
    world=lambda p:origin+rot@Vector(p)
    local=lambda ob,v:inv@(ob.matrix_world@v-origin)
    xs=[-sum(rec['bays'])/2]
    for bay in rec['bays']:xs.append(xs[-1]+bay)
    changes=[]
    # The old helper averaged three support rows with /2. That shifted the
    # beam forward 420 mm, leaving its rear end short of the rear column.
    beam=bpy.data.objects['North.sadang.frame transverse beam'];oi=beam.matrix_world.inverted()
    for ids in groups(beam.data):
        pts=np.array([local(beam,beam.data.vertices[i].co) for i in ids]);center=(pts[:,1].min()+pts[:,1].max())/2
        for i in ids:
            p=local(beam,beam.data.vertices[i].co);p.y-=float(center);beam.data.vertices[i].co=oi@world(p)
        changes.append({'member':'transverse beam','shiftY':-float(center),'supportRows':[-2.10,2.10],'sectionUnchanged':True})
    beam.data.update();beam['shrineBeamSeatingVersion']=1
    buyeon=bpy.data.objects['North.sadang.double eave square buyeon'];oi=buyeon.matrix_world.inverted()
    for ids in groups(buyeon.data):
        pts=np.array([local(buyeon,buyeon.data.vertices[i].co) for i in ids]);lo=pts.min(0);hi=pts.max(0);center=(lo+hi)/2
        for i,p in zip(ids,pts):
            p[0]=center[0]+(p[0]-center[0])*.087/(hi[0]-lo[0]);p[2]=hi[2]-(hi[2]-p[2])*.120/(hi[2]-lo[2]);buyeon.data.vertices[i].co=oi@world(p)
    buyeon.data.update();buyeon['surveySection']=[.087,.120]
    # Replace stretched thumbnail pigment on both existing solid beam faces.
    for ob in scene.objects:
        if ob.type!='MESH' or ob.get('construction_building')!='sadang' or not any(t in ob.name for t in ('dancheong floral panel','canonical dancheong frieze')):continue
        mesh=ob.data;uv=mesh.uv_layers.get('Shrine frieze pigment') or mesh.uv_layers.new(name='Shrine frieze pigment')
        boxes={};owner={}
        for ci,ids in enumerate(groups(mesh)):
            pts=np.array([local(ob,mesh.vertices[i].co) for i in ids]);boxes[ci]=(pts.min(0),pts.max(0))
            for i in ids:owner[i]=ci
        for poly in mesh.polygons:
            lo,hi=boxes[owner[poly.vertices[0]]];h=hi[2]-lo[2]
            for li in poly.loop_indices:
                p=local(ob,mesh.vertices[mesh.loops[li].vertex_index].co)
                # UV window omits the generated white margins, retaining the
                # source pixels. Repeat count preserves painted flower aspect.
                u=(p.x-lo[0])/max(h*4.90,.01);v=.232+(p.z-lo[2])/max(h,.001)*.536
                uv.data[li].uv=(u,v)
            poly.material_index=0
        mesh.materials.clear();mesh.materials.append(frieze_material());mesh.uv_layers.active=uv;uv.active_render=True
        for attr in list(mesh.color_attributes):mesh.color_attributes.remove(attr)
        ob['shrineFriezeVersion']=1
    removed=[]
    for ob in list(scene.objects):
        if ob.get('construction_building')=='sadang' and (ob.name.startswith('North.sadang.roof continuous bed') or '.roof.gable timber' in ob.name or '.dancheong carved bracket.shaped timber shoulder' in ob.name):
            removed.append(ob.name);bpy.data.objects.remove(ob,do_unlink=True)
    green=bpy.data.materials['North aged blue green'];red=bpy.data.materials['North weathered vermilion'];lime=bpy.data.materials['North lime plaster'];gold=bpy.data.materials['North ochre painted line']
    earth=bpy.data.materials['North earthen plaster'];ceramic=bpy.data.materials['Ansarang retained V33 main_gate source ceramic 2']
    nm='North.sadang.joinery';g.BATCHES.clear();g.set_transform(world)
    def field(x,y):
        t=abs(y)/2.97;r=abs(x)/4.18
        return 3.70+1.46*(1-t)**1.45+.20*r**8*t*t+.08*r**8*(1-t)
    # Closed earthen roof bed. Top and underside are joined at the perimeter.
    nx,ny=42,38
    for i in range(nx):
        for j in range(ny):
            quad=[(-4.18+(i+a)*8.36/nx,-2.97+(j+b)*5.94/ny) for a,b in ((0,0),(1,0),(1,1),(0,1))]
            top=[(x,y,field(x,y)-.040) for x,y in quad];bottom=[(x,y,field(x,y)-.100) for x,y in quad]
            g.face(nm+'.solid roof bedding',top,earth);g.face(nm+'.solid roof bedding',bottom[::-1],earth)
            for k,edge in ((0,j==0),(1,i==nx-1),(2,j==ny-1),(3,i==0)):
                if edge:g.face(nm+'.solid roof bedding',[top[k],bottom[k],bottom[(k+1)%4],top[(k+1)%4]],earth)
    # Packed material beneath the five ridge courses closes the daylight slot.
    for i in range(42):
        x0=-4.179+i*8.358/42;x1=-4.179+(i+1)*8.358/42
        def section(x):
            lift=.08*(abs(x)/4.18)**8
            return [(x,y,z+lift) for y,z in ((-.043,5.065),(-.043,5.48),(.043,5.48),(.043,5.065))]
        a,b=section(x0),section(x1)
        if i==0:g.face(nm+'.packed ridge core',a[::-1],ceramic)
        if i==41:g.face(nm+'.packed ridge core',b,ceramic)
        for k in range(4):g.face(nm+'.packed ridge core',[a[k],a[(k+1)%4],b[(k+1)%4],b[k]],ceramic)
    # The current gable envelope is retained, but individual 30 mm planks and
    # measured 45x27 battens now exist on both faces, instead of zero-depth skin.
    for side in (-1,1):
        old=g.TRANSFORM;g.set_transform(lambda p,side=side:world((side*(4.15+p[1]),p[0],p[2])))
        for j in range(34):
            seam=-2.97+j*5.94/34;a=seam+.0005;b=-2.97+(j+1)*5.94/34-.0005;mid=(a+b)/2
            poly=[(a,3.705),(b,3.705),(b,field(4.18,b)-.098),(mid,field(4.18,mid)-.098),(a,field(4.18,a)-.098)]
            d.extruded_profile(nm+'.gable thirty millimetre planks',poly,-.015,.015,red)
            if 0<j<34:
                high=field(4.18,seam)-.17
                if high>3.73:g.box(nm+'.gable 45x27 cover batten',(seam,.0285,(3.705+high)/2),(.045,.027,high-3.705),red)
        g.set_transform(old)
    # Existing column centres and upper/lower bearing blocks remain. The
    # shoulder underside follows the curled silhouette seen in the photo.
    profile=[(-.28,-.045),(.54,-.045),(.57,-.075),(.55,-.107),(.515,-.126),(.47,-.128),(.44,-.155),(.41,-.179),(.36,-.191),(.32,-.198),(.285,-.222),(.24,-.231),(.207,-.237),(.18,-.267),(.13,-.286),(.08,-.296),(.035,-.288),(-.015,-.266),(-.07,-.229),(-.12,-.216),(-.16,-.207),(-.20,-.17),(-.235,-.134),(-.28,-.12)]
    def painted_ribbon(tag,path,depth,width,mat):
        for a,b in zip(path,path[1:]):
            dx,dz=b[0]-a[0],b[1]-a[1];length=math.hypot(dx,dz);ux,uz=-dz/length*width/2,dx/length*width/2
            g.face(tag,[(a[0]+ux,depth,a[1]+uz),(b[0]+ux,depth,b[1]+uz),(b[0]-ux,depth,b[1]-uz),(a[0]-ux,depth,a[1]-uz)],mat)
    for side in (-1,1):
        for x in xs:
            g.set_transform(lambda p,x=x,side=side:world((x+p[1],side*2.10+side*p[0],3.38+p[2])))
            d.extruded_profile(nm+'.sculpted bracket shoulder',profile,-.108,.108,green)
            path=[(-.23,-.085),(-.17,-.11),(-.13,-.16),(-.08,-.176),(-.015,-.192),(.045,-.244),(.10,-.251),(.14,-.231),(.17,-.203),(.23,-.194),(.27,-.179),(.30,-.15),(.35,-.143),(.39,-.129),(.42,-.10),(.47,-.088),(.51,-.088)]
            for depth in (-.1086,.1086):
                painted_ribbon(nm+'.bracket painted cream contour',path,depth,.012,lime)
                painted_ribbon(nm+'.bracket painted vermilion contour',[(u,z+.014) for u,z in path],depth,.007,red)
                painted_ribbon(nm+'.bracket painted ochre hairline',[(u,z+.026) for u,z in path],depth,.004,gold)
    g.set_transform(world);objects=g.flush();g.BATCHES.clear()
    for ob in objects:
        if ob.name==nm+'.gable thirty millimetre planks':ob['gableRoofSeatVersion']=1
        for k,v in {'construction_building':'sadang','construction_first':1,'construction_last':99,'source_object_name':ob.name,'northExtension':True,'shrineJoineryVersion':1}.items():ob[k]=v
        for mod in ob.modifiers:
            if mod.type=='BEVEL':mod.width=.0015 if 'painted' in ob.name else .0025;mod.segments=3
    # Paint follows the broad carved faces; the narrow cut edges keep their
    # green wood surface, so the bracket remains legible as a solid member.
    for ob,normal_axis,across in ((bpy.data.objects['North.sadang.photo carved wing bracket'],1,0),(bpy.data.objects[nm+'.sculpted bracket shoulder'],0,1)):
        mesh=ob.data;index=len(mesh.materials);mesh.materials.append(frieze_material());uv=mesh.uv_layers.get('Shrine frieze pigment') or mesh.uv_layers.new(name='Shrine frieze pigment')
        owner={};bounds={}
        for ci,ids in enumerate(groups(mesh)):
            pts=np.array([local(ob,mesh.vertices[i].co) for i in ids]);bounds[ci]=(pts.min(0),pts.max(0))
            for i in ids:owner[i]=ci
        for poly in mesh.polygons:
            normal=inv@(ob.matrix_world.to_3x3()@poly.normal)
            if abs(normal[normal_axis])<.9:continue
            lo,hi=bounds[owner[poly.vertices[0]]];height=hi[2]-lo[2];center=(hi[across]+lo[across])/2
            for li in poly.loop_indices:
                p=local(ob,mesh.vertices[mesh.loops[li].vertex_index].co);uv.data[li].uv=(.5+(p[across]-center)/(height*4.975),.232+(p.z-lo[2])/height*.536)
            poly.material_index=index
        mesh.uv_layers.active=uv;uv.active_render=True;ob['shrineFriezeVersion']=1
    retain_lime_soffit()
    return [{'building':'sadang','beamSeating':changes,'buyeonSection':[.087,.120],'windBoardThickness':.030,'windBoardBattens':[.045,.027],'removed':removed,'newMeshes':[o.name for o in objects],'sourceSheets':['059','061'],'unmeasuredCurves':'Retained envelope and photograph-guided bracket contour; not a measured joint survey'}]
