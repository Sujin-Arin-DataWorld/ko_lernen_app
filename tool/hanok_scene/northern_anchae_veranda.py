"""Rear veranda and roof section, from the matching 2007 section 052.

The explicit dimensions define the structure. Roof curvature is a traced
interpretation of that section, not a claim of a millimetre survey. The native
scene is only replaced with --apply after candidate inspection.
"""
from pathlib import Path
import sys, json, math, hashlib, shutil, random
import bpy, bmesh, numpy as np
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).parent))
from northern_wall_joints import basis
from northern_anchae_plan import local_parts, FRONT, MAIN_REAR
from refine_northern_materials import apply_craft_surfaces, geometry_fingerprint
from northern_mineral_surfaces import apply_mineral_surfaces

OUT=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
VERANDA_Y=MAIN_REAR+1.200
FLOOR_TOP=.605
PURLIN_BOTTOM=FLOOR_TOP+1.525
PURLIN_TOP=PURLIN_BOTTOM+.165
POST_BASE=.100
RIDGE_Y=(FRONT+MAIN_REAR)/2
FRONT_EAVE=FRONT-1.140
REAR_EAVE=MAIN_REAR+1.740
# Digitized upper roof line. Source pixel positions are retained so that the
# interpretation can be checked without treating these as printed dimensions.
TRACE=[(54,356),(126,323),(282,242),(472,135),(530,95),(592,135),(781,242),(931,321)]
PROFILE=sorted([(MAIN_REAR-(px-282)*3.8/499,4.905-(py-31)*1.115/147) for px,py in TRACE])

def roof_profile(y):
    return float(np.interp(y,[p[0] for p in PROFILE],[p[1] for p in PROFILE]))

def refine_anchae_veranda(scene,records,doors=None,openings=None):
    rec=next(r for r in records if r['id']=='anchae')
    if rec.get('rearVerandaVersion')==1:return []
    assert rec.get('rearPlanVersion')==1
    origin,rot,axes=basis(records);inv=rot.transposed();changes=[]
    sys.path.insert(0,'C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-warm-stone-20260923/tool/hanok_scene')
    import reconstruction_geometry as g
    assert not g.BATCHES
    old_field=g.roof('trace only',(-10.3175,10.3175,-3.4,3.4),3.55,4.62,None,None,None,kind='paljak',turn=.20,ridge_turn=.08,field_only=True)
    def source_height(x,y):
        # Clamp Python doubles: np.float32 rounds 3.4 outward and triggers
        # the field's outside-domain sentinel, producing a 100 m edge wall.
        return old_field(max(-10.3175,min(10.3175,float(x))),max(-3.4,min(3.4,float(y))))
    def mapped_y(y):return RIDGE_Y+y/3.4*((REAR_EAVE-RIDGE_Y) if y>=0 else (RIDGE_Y-FRONT_EAVE))
    def roof_height(x,y):
        half=10.3175;hip=1.904
        t=abs((y-RIDGE_Y)/((REAR_EAVE-RIDGE_Y) if y>=RIDGE_Y else (RIDGE_Y-FRONT_EAVE)))
        q=max(0,(abs(x)-(half-hip))/hip)
        tt=max(t,.48+.52*q) if q>0 else t
        yy=RIDGE_Y+tt*((REAR_EAVE-RIDGE_Y) if y>=RIDGE_Y else FRONT_EAVE-RIDGE_Y)
        corner=.20*min(1,abs(x)/half)**8*t*t
        ridge=.08*min(1,abs(x)/(half-hip))**8*(1-tt)
        return roof_profile(yy)+corner+ridge
    def write(ob,index,p):ob.data.vertices[index].co=ob.matrix_world.inverted()@(origin+rot@Vector(p))
    def finish(ob):
        ob.data.update();bm=bmesh.new();bm.from_mesh(ob.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(ob.data);bm.free()
        ob['anchaeSection052Version']=1;changes.append(ob.name)

    # Move each structural timber as a solid; shortening posts changes only
    # their length. Neither their width nor the 330 mm beam section is scaled.
    for tag in ('frame square post','frame transverse beam','frame longitudinal beam','room projection square post','room projection longitudinal timber','room projection return timber','photo curved daechong beam','frame mortise peg'):
        ob=bpy.data.objects['North.anchae.'+tag]
        for ids,points in local_parts(ob,origin,rot):
            lo,hi=points.min(0),points.max(0);center=(lo+hi)/2
            if 'square post' in tag:
                for p in points:
                    if abs(p[2]-hi[2])<.001:p[2]=2.790
            elif center[2]>1:
                if tag=='frame transverse beam':points[:,2]+=2.790-hi[2]
                elif tag=='frame longitudinal beam':
                    # Section 052 gives the square purlin 180 x 210.
                    points[:,1]=center[1]+(points[:,1]-center[1])*.180/(hi[1]-lo[1])
                    points[:,2]=2.790+(points[:,2]-center[2])*.210/(hi[2]-lo[2])
                elif tag=='photo curved daechong beam':points[:,2]-=.48
                else:points[:,2]-=.360
            for index,p in zip(ids,points):write(ob,index,p)
        finish(ob)

    # Upper plaster and ceilings meet the lowered frame. Window and door
    # leaves retain their dimensions; only the high kitchen vent is lowered.
    for ob in list(scene.objects):
        if ob.type!='MESH' or ob.get('construction_building')!='anchae':continue
        if ob.name in changes:continue
        if any(word in ob.name for word in ('kitchen high ventilator','photo sireong')):
            for vertex in ob.data.vertices:
                p=inv@(ob.matrix_world@vertex.co-origin);p.z-=.36;write(ob,vertex.index,p)
            finish(ob);continue
        if 'room ceiling' in ob.name:
            for vertex in ob.data.vertices:
                p=inv@(ob.matrix_world@vertex.co-origin);p.z-=.40;write(ob,vertex.index,p)
            finish(ob);continue
        if any(mat and mat.name in ('North lime plaster','North earthen plaster') for mat in ob.data.materials) and '.roof' not in ob.name and '.annex' not in ob.name:
            modified=False
            for vertex in ob.data.vertices:
                p=inv@(ob.matrix_world@vertex.co-origin)
                if p.z>2.79:p.z=2.79+(p.z-3.12)*.05;write(ob,vertex.index,p);modified=True
            if modified:finish(ob)

    # The plan has two swinging room-1 doors onto this veranda. Lower the
    # retained lattice assemblies to floor level and remove the wall under
    # their old window openings, rather than hiding a wall behind an open door.
    door_bottom=FLOOR_TOP+.020;door_height=1.430;door_top=door_bottom+door_height
    selected_centres=[(axes[i]+axes[i+1])/2 for i in (2,3)]
    for suffix in ('room rear','room rear.jamb','room rear.head/sill'):
        ob=bpy.data.objects['North.anchae.'+suffix];deleted=[]
        for ids,points in local_parts(ob,origin,rot):
            lo,hi=points.min(0),points.max(0);center=(lo+hi)/2
            if not axes[2]<center[0]<axes[4]:continue
            cx=min(selected_centres,key=lambda x:abs(x-center[0]))
            if suffix=='room rear':
                if abs(center[0]-cx)<.01 and hi[2]<1.0:deleted.extend(ids);continue
                if abs(center[0]-cx)<.01 and lo[2]>2.3:
                    for p in points:
                        if abs(p[2]-lo[2])<.001:p[2]=door_top+.083
            elif suffix.endswith('jamb'):points[:,2]+=door_bottom-.950
            else:
                if center[2]<1.0:points[:,2]=FLOOR_TOP+(points[:,2]-center[2])*.030/(hi[2]-lo[2])
                else:points[:,2]+=door_top+.043-center[2]
            for index,p in zip(ids,points):write(ob,index,p)
        if deleted:
            bm=bmesh.new();bm.from_mesh(ob.data);bm.verts.ensure_lookup_table();bmesh.ops.delete(bm,geom=[bm.verts[i] for i in deleted],context='VERTS');bm.to_mesh(ob.data);bm.free()
        finish(ob)
    for bay in (2,3):
        prefix='North.anchae.room rear '+str(bay);cx=(axes[bay]+axes[bay+1])/2
        for ob in list(scene.objects):
            if ob.type!='MESH' or not ob.name.startswith(prefix+'.'):continue
            for vertex in ob.data.vertices:
                p=inv@(ob.matrix_world@vertex.co-origin)
                p.z+=door_bottom-.950;p.y=1.600-(p.y-1.475);write(ob,vertex.index,p)
            finish(ob)
        if doors is not None:
            doors.append({'building':'anchae','prefix':prefix,'hinges':[list(origin+rot@Vector((cx-.555+.005,1.600,door_bottom))),list(origin+rot@Vector((cx+.555-.005,1.600,door_bottom)))],'rotationSigns':[1,-1],'width':1.110,'height':door_height,'doorBottom':door_bottom,'state':'closed','authority':'Swinging rear room doors from matching 2007 plan; retained 1110 x 1430 review opening, not a newly measured rear door size'})
        if openings is not None:
            for opening in openings:
                if opening.get('building')=='anchae' and opening.get('tag')=='room rear '+str(bay):
                    opening['center']=[cx,1.600,door_bottom+door_height/2];opening['type']='rear veranda door'

    # Reprofile the existing closed ceramic pieces and bedding together.
    # Their independent shell modifiers, painted surfaces and hip topology
    # remain intact. The bedding deepens to the section's roof construction.
    for ob in list(scene.objects):
        if ob.type!='MESH' or not ob.name.startswith('North.anchae.roof'):continue
        if 'rafters' in ob.name:continue
        for vertex in ob.data.vertices:
            p=np.array(inv@(ob.matrix_world@vertex.co-origin));x,y,z=p
            ynew=mapped_y(y);offset=z-source_height(x,y)
            if 'solid bedding' in ob.name:
                # old closed bed has its top at -40 mm and underside -100 mm
                offset=-.04+(offset+.04)*4.0
            p[1]=ynew;p[2]=roof_height(x,ynew)+offset;write(ob,vertex.index,p)
        finish(ob)
        if 'solid bedding' in ob.name:
            ob['retainedBedThickness']=.240
            ob['authority']='240 mm vertical roof build-up traced from section 052; not a printed measured thickness'
    # Round rafters receive new endpoints, retaining their circular section.
    # A rigid reorientation avoids flattening their diameter on a steeper roof.
    for ob in list(scene.objects):
        if ob.type!='MESH' or not ob.name.startswith('North.anchae.roof') or 'rafters' not in ob.name:continue
        for ids,points in local_parts(ob,origin,rot):
            center=points.mean(0);_,eig=np.linalg.eigh((points-center).T@(points-center));axis=eig[:,-1]
            along=(points-center)@axis;a=center+axis*along.min();b=center+axis*along.max()
            target=[]
            for endpoint in (a,b):
                x,y,z=endpoint;yy=mapped_y(y)
                # Centre lies 75 mm below the lower roof bed.
                target.append(Vector((x,yy,roof_height(x,yy)-.355)))
            aa,bb=target;new_axis=(bb-aa).normalized();rotation=Vector(axis).rotation_difference(new_axis).to_matrix()
            for index,p,t in zip(ids,points,along):
                fraction=(t-along.min())/(along.max()-along.min())
                across=Vector(p-center-axis*t);q=aa+(bb-aa)*fraction+rotation@across;write(ob,index,q)
        finish(ob)

    # The rear veranda is a real 1200 mm deep floor with four separate posts,
    # purlin and jangyeo sections. Keep the undersides and ventilation open.
    postmat=bpy.data.materials['North anchae post'];wood=bpy.data.materials['North anchae wood'];beammat=bpy.data.materials['North anchae beam'];stone=bpy.data.materials['North anchae stone']
    g.set_transform(lambda p:origin+rot@Vector(p));rng=random.Random(52007)
    for index in range(1,5):
        x=axes[index];depth=.167 if index==4 else .165
        g.box('North.anchae.rear veranda square post',(x,VERANDA_Y,(POST_BASE+PURLIN_TOP)/2),(.165,depth,PURLIN_TOP-POST_BASE),postmat)
        g.rock('North.anchae.rear veranda stone foot',(x,VERANDA_Y,.045),(.32,.31,.110),stone,rng)
    for a,b in zip(axes[1:4],axes[2:5]):
        cx=(a+b)/2;length=b-a
        g.box('North.anchae.rear veranda purlin',(cx,VERANDA_Y,(PURLIN_BOTTOM+PURLIN_TOP)/2),(length+.10,.165,.165),beammat)
        g.box('North.anchae.rear veranda jangyeo',(cx,VERANDA_Y,PURLIN_BOTTOM-.075),(length+.07,.090,.150),beammat)
        for y in (MAIN_REAR,VERANDA_Y):
            g.box('North.anchae.rear veranda floor girder',(cx,y,FLOOR_TOP-.045-.0675),(length+.08,.090,.135),beammat)
        for x in np.arange(a+.34,b-.10,.45):
            g.box('North.anchae.rear veranda floor joist',(x,(MAIN_REAR+VERANDA_Y)/2,FLOOR_TOP-.045-.0675),(.09,1.20,.135),beammat)
        g.planks('North.anchae.rear veranda floor boards',a+.0825,b-.0825,MAIN_REAR,VERANDA_Y,FLOOR_TOP-.0225,[wood],axis='Y',thick=.045,width=.17)
    added=g.flush();g.BATCHES.clear();g.set_transform(lambda p:p)
    for ob in added:
        for key,value in {'northExtension':True,'construction_building':'anchae','construction_first':1,'construction_last':99,'source_object_name':ob.name,'anchaeSection052Version':1}.items():ob[key]=value
        for mod in ob.modifiers:
            if mod.type=='BEVEL':mod.width=.002;mod.segments=2
        changes.append(ob.name)
    bpy.context.view_layer.update()
    craft=apply_craft_surfaces(scene);minerals=apply_mineral_surfaces(scene)
    rec['rearVerandaVersion']=1
    rec['rearVerandaPlan'].update({'geometryComplete':True,'floorTop':FLOOR_TOP,'floorboardThickness':.045,'purlinSection':[.165,.165],'jangyeoSection':[.090,.150],'floorGirderSection':[.090,.135],'purlinBottom':PURLIN_BOTTOM,'postBase':POST_BASE})
    rec['roofSection052']={'profile':PROFILE,'sourcePixels':TRACE,'sourceCropOrigin':[980,740],'ridgeY':RIDGE_Y,'frontEave':FRONT_EAVE,'rearEave':REAR_EAVE,'authority':'2007 section 052: explicit spans/member sizes, traced upper roof line; full rear elevation and absolute terrain registration still unverified','tracedNotSurveyed':True}
    return [{'building':'anchae','objects':changes,'illustratedTimber':craft,'mineralSurfaces':minerals,'fullSurveyAccuracyClaimed':False}]

if __name__=='__main__':
    apply='--apply' in sys.argv
    bpy.ops.wm.open_mainfile(filepath=str(OUT/'scene.blend'));scene=bpy.context.scene
    contract=json.loads((OUT/'northern-contract.json').read_text(encoding='utf8'))
    protected={o.name:(geometry_fingerprint(o),tuple(m.name for m in o.data.materials)) for o in scene.objects if o.type=='MESH' and o.get('construction_building')!='anchae'}
    report=refine_anchae_veranda(scene,contract['buildings'],contract['doors'],contract['openings'])
    assert all((geometry_fingerprint(bpy.data.objects[n]),tuple(m.name for m in bpy.data.objects[n].data.materials))==fp for n,fp in protected.items())
    name='scene.blend' if apply else 'anchae-veranda-study.blend'
    if apply and not (OUT/'before-anchae-veranda.blend').exists():shutil.copy2(OUT/'scene.blend',OUT/'before-anchae-veranda.blend')
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/name),compress=True)
    contract['anchaeVeranda']=report
    for field in ('illustratedTimber','mineralSurfaces'):
        merged={r['object']:r for r in contract.get(field,[])}
        for item in report:merged.update({r['object']:r for r in item[field]})
        contract[field]=list(merged.values())
    for rec in contract['buildings']:rec['meshes']=sum(o.type=='MESH' and o.get('construction_building')==rec['id'] for o in scene.objects)
    target='northern-contract.json' if apply else 'anchae-veranda-study-contract.json'
    (OUT/target).write_text(json.dumps(contract,ensure_ascii=False,indent=2),encoding='utf8')
    (OUT/'anchae-veranda-repair.json').write_text(json.dumps({'nativeScene':name,'nativeSha256':hashlib.sha256((OUT/name).read_bytes()).hexdigest(),'unchangedOtherMeshes':len(protected),'changes':report},ensure_ascii=False,indent=2),encoding='utf8')
    if apply:
        for ob in scene.objects:ob.select_set(False)
        obs=[o for o in scene.objects if o.type=='MESH' and o.get('northExtension')]
        for ob in obs:ob.select_set(True);ob.hide_set(False);ob.hide_render=False
        bpy.context.view_layer.objects.active=obs[0]
        bpy.ops.export_scene.gltf(filepath=str(OUT/'northern.glb'),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True,export_extras=True)
    print('AN CHAE VERANDA',len(report),'groups;',len(protected),'other meshes unchanged',flush=True)
