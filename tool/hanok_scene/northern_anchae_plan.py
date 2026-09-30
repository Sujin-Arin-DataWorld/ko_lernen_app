"""Restore Anchae's straight main rear frame from the 2007 measured plan.

The plan reproduced as fig. 4.15 (p.136) of NRICH's 2009 seismic study
has the same eight bay dimensions as sheet 047. Its 725 mm projection
belongs to rooms 2/3, not the two-bay daechong. Earlier vertex warping
put that change at bay axis 4 and sheared solid structural members.
"""
from pathlib import Path
import bpy, bmesh, math, json, hashlib, shutil, sys
import numpy as np
from mathutils import Vector
sys.path.insert(0, str(Path(__file__).parent))
from northern_wall_joints import basis, rear_joint_audit
from northern_timber_sections import groups
from refine_northern_materials import apply_craft_surfaces, geometry_fingerprint
from northern_mineral_surfaces import apply_mineral_surfaces

OUT=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
FRONT=-2.2625
MAIN_REAR=FRONT+3.800
ROOM_REAR=MAIN_REAR+.725
FACES=((0,3,2,1),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7),(4,5,6,7))
POST_FRONT={2:(.203,.219),3:(.205,.215),4:(.220,.225),5:(.230,.220),6:(.225,.215),7:(.220,.217),8:(.205,.210)}
POST_REAR={1:(.225,.223),4:(.212,.215),5:(.225,.210),7:(.215,.230),8:(.242,.237)}

def expected_post_section(axis, row):
    # Unlabelled positions retain the earlier 210 mm nominal member size.
    if row==0:return POST_FRONT.get(axis,(.210,.210))
    if row==2:return POST_REAR.get(axis,(.210,.210))
    if axis==1:return (.225,.240)
    if axis==8:return (.165,.162)
    return (.210,.210)

def local_parts(ob, origin, rot):
    inv=rot.transposed()
    return [(list(ids),np.array([inv@(ob.matrix_world@ob.data.vertices[i].co-origin) for i in ids])) for ids in groups(ob.data)]

def rewrite_boxes(ob, boxes, origin, rot):
    """Build rigid solids rather than stretching corners across a plan step."""
    mat=next(m for m in ob.data.materials if m and m.get('surfaceKind') in ('beam','post','wood'))
    vertices=[];faces=[];oi=ob.matrix_world.inverted()
    for center,size in boxes:
        x,y,z=center;a,b,c=np.array(size)/2;start=len(vertices)
        for p in ((x-a,y-b,z-c),(x+a,y-b,z-c),(x+a,y+b,z-c),(x-a,y+b,z-c),(x-a,y-b,z+c),(x+a,y-b,z+c),(x+a,y+b,z+c),(x-a,y+b,z+c)):
            vertices.append(tuple(oi@(origin+rot@Vector(p))))
        faces.extend(tuple(start+i for i in face) for face in FACES)
    mesh=bpy.data.meshes.new(ob.name+' measured plan');mesh.from_pydata(vertices,[],faces);mesh.materials.append(mat);mesh.update()
    ob.data=mesh
    ob['illustratedPineV1']=False
    ob['anchaePlanFrameVersion']=1
    for mod in ob.modifiers:
        if mod.type=='BEVEL':mod.width=.003;mod.segments=2

def repair_anchae_plan(scene, records, doors=None, fresh_body=False):
    rec=next(r for r in records if r['id']=='anchae')
    if rec.get('rearPlanVersion')==1:return []
    origin,rot,axes=basis(records);inv=rot.transposed();changed=[]
    def object_by(tag):return bpy.data.objects['North.anchae.'+tag]
    def write(ob, index, p):ob.data.vertices[index].co=ob.matrix_world.inverted()@(origin+rot@Vector(p))
    def finish(ob):
        ob.data.update();bm=bmesh.new();bm.from_mesh(ob.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(ob.data);bm.free()
        changed.append(ob.name)
    def unwarp(p):
        q=p.copy()
        if q[0]<axes[4] and q[1]>-.9875:
            q[1]=q[1]+.725 if q[1]>=1.5375 else (q[1]+.725*.9875/3.25)/(1-.725/3.25)
        return q

    posts=object_by('frame square post');boxes=[]
    for ids,points in local_parts(posts,origin,rot):
        lo,hi=points.min(0),points.max(0);center=(lo+hi)/2
        axis=min(range(9),key=lambda i:abs(center[0]-axes[i]))
        row=2 if center[1]>1.3 else 0 if center[1]<-1.8 else 1
        yy=(FRONT,-1.0875,MAIN_REAR)[row]
        if row==1 and axis in (0,8):yy=FRONT+1.900
        width,depth=expected_post_section(axis,row)
        boxes.append(((axes[axis],yy,center[2]),(width,depth,hi[2]-lo[2])))
    assert len(boxes)==27
    rewrite_boxes(posts,boxes,origin,rot);changed.append(posts.name)

    ob=object_by('frame transverse beam');boxes=[]
    for ids,points in local_parts(ob,origin,rot):
        lo,hi=points.min(0),points.max(0);cx=(lo[0]+hi[0])/2
        axis=min(axes,key=lambda x:abs(x-cx))
        boxes.append(((axis,(FRONT+MAIN_REAR)/2,(lo[2]+hi[2])/2),(.330,3.800+.260,.330)))
    rewrite_boxes(ob,boxes,origin,rot);changed.append(ob.name)
    ob=object_by('frame longitudinal beam');boxes=[]
    for ids,points in local_parts(ob,origin,rot):
        lo,hi=points.min(0),points.max(0);center=(lo+hi)/2;size=hi-lo
        if center[1]>1.3:center[1]=MAIN_REAR
        size[1]=.135 if center[2]<1 else .210
        boxes.append((center,size))
    rewrite_boxes(ob,boxes,origin,rot);changed.append(ob.name)

    if not fresh_body:
        # Stones and pegs were warped before section correction. Undo that
        # exact map, then move each complete member to the straight main row.
        for tag in ('foundation individual plinth','frame mortise peg'):
            ob=object_by(tag)
            for ids,points in local_parts(ob,origin,rot):
                points=np.array([unwarp(p) for p in points]);center=(points.min(0)+points.max(0))/2
                if center[1]>1.3:points[:,1]-=.725
                elif -.6>center[1]>-1.6 and min(abs(center[0]-axes[i]) for i in (0,8))<.15:points[:,1]+=.725
                for index,p in zip(ids,points):write(ob,index,p)
            finish(ob)
        # Rear infill and actual door assemblies of the two-bay hall move
        # together, retaining window/door dimensions and opening clearance.
        for ob in list(scene.objects):
            if ob.type!='MESH' or not ob.name.startswith('North.anchae.daechong rear'):continue
            for v in ob.data.vertices:
                p=inv@(ob.matrix_world@v.co-origin);p.y-=.725;write(ob,v.index,p)
            finish(ob)
        # Shorten only hall floor members; the front porch remains untouched.
        for tag in ('floor individual boards','floor under joists'):
            ob=object_by(tag)
            for ids,points in local_parts(ob,origin,rot):
                center=(points.min(0)+points.max(0))/2
                if not axes[4]-.01<center[0]<axes[6]+.01 or points[:,1].max()<=-.98:continue
                new_center=-1.09+(center[1]+1.09)*(MAIN_REAR+1.09)/(ROOM_REAR+1.09)
                for index,p in zip(ids,points):
                    p[1]=p[1]+new_center-center[1] if tag=='floor under joists' else -1.09+(p[1]+1.09)*(MAIN_REAR+1.09)/(ROOM_REAR+1.09)
                    write(ob,index,p)
            finish(ob)
        ob=object_by('interior partition')
        for ids,points in local_parts(ob,origin,rot):
            cx=(points[:,0].min()+points[:,0].max())/2
            if abs(cx-axes[4])<.01:
                for index,p in zip(ids,points):
                    if p[1]>1.3:p[1]=MAIN_REAR+.030;write(ob,index,p)
        finish(ob)
    # Keep the photographed camber, but fit the solid beam to the actual hall.
    ob=object_by('photo curved daechong beam')
    if not fresh_body:
        for v in ob.data.vertices:
            p=inv@(ob.matrix_world@v.co-origin);p.y=-1.07+(p.y+1.07)*(MAIN_REAR+1.07)/(2.25+1.07);write(ob,v.index,p)
        finish(ob)
    # The two small outer posts are separate members. The previous generic
    # rear row confused these 155 mm supports with the main house columns.
    sys.path.insert(0,'C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-warm-stone-20260923/tool/hanok_scene')
    import reconstruction_geometry as g
    import random
    assert not g.BATCHES
    g.set_transform(lambda p:origin+rot@Vector(p))
    post_mat=next(m for m in posts.data.materials if m.get('surfaceKind')=='post')
    beam_mat=next(m for m in object_by('frame longitudinal beam').data.materials if m.get('surfaceKind')=='beam')
    stone_mat=next(m for m in object_by('foundation individual plinth').data.materials if m.get('surfaceKind')=='stone')
    for axis in (6,7):
        g.box('North.anchae.room projection square post',(axes[axis],ROOM_REAR,1.725),(.155,.155,2.85),post_mat)
        g.rock('North.anchae.room projection stone foot',(axes[axis],ROOM_REAR,.22),(.36,.34,.20),stone_mat,random.Random(991+axis))
    for z,depth,height in ((.49,.135,.240),(3.04,.180,.210)):
        g.box('North.anchae.room projection longitudinal timber',((axes[6]+axes[8])/2,ROOM_REAR,z),(axes[8]-axes[6]+.15,depth,height),beam_mat)
        for axis in (6,7,8):
            g.box('North.anchae.room projection return timber',(axes[axis],(MAIN_REAR+ROOM_REAR)/2,z),(depth,.725+.15,height),beam_mat)
    added=g.flush();g.BATCHES.clear();g.set_transform(lambda p:p)
    for part in added:
        for key,value in {'northExtension':True,'construction_building':'anchae','construction_first':1,'construction_last':99,'source_object_name':part.name,'anchaePlanFrameVersion':1}.items():part[key]=value
        part['authority']='2007 plan room projection and 155 mm posts; height retained from adjoining review infill, not a new height measurement'
        for mod in part.modifiers:
            if mod.type=='BEVEL':mod.width=.003;mod.segments=2
        changed.append(part.name)
    minerals=apply_mineral_surfaces(scene)
    bpy.context.view_layer.update()
    craft=apply_craft_surfaces(scene)
    rec['rearPlanVersion']=1
    rec['mainBodyDepth']=3.800
    rec['leftBodyDepth']=3.800
    rec['rightBodyDepth']=4.525
    rec['rearProjectionBays']=[6,7]
    rec['rearVerandaPlan']={'bays':[1,2,3],'depth':1.200,'outerPostSections':[[.165,.165],[.165,.165],[.165,.165],[.165,.167]],'geometryComplete':False}
    rec['planAuthority']='NRICH 2009 Development of the Seismic Capacity Evaluation Item on Wooden Structure, p136 fig4.15; matches 2007 sheet047 bay dimensions'
    rec['postSectionAuthority']='Labelled 2007 plan posts used individually; unlabelled main positions retain nominal 210 mm and are not newly surveyed'
    if doors is not None:
        delta=rot@Vector((0,-.725,0))
        for door in doors:
            if door.get('building')=='anchae' and 'daechong rear' in door.get('prefix',''):
                door['hinges']=[list(Vector(hinge)+delta) for hinge in door['hinges']]
    after=rear_joint_audit(scene,records)
    return [{'building':'anchae','objects':sorted(set(changed)),'rearJointAudit':after,'illustratedTimber':craft,'mineralSurfaces':minerals,'fullSurveyAccuracyClaimed':False}]

if __name__=='__main__':
    apply='--apply' in sys.argv
    bpy.ops.wm.open_mainfile(filepath=str(OUT/'scene.blend'));scene=bpy.context.scene
    contract=json.loads((OUT/'northern-contract.json').read_text(encoding='utf8'))
    allowed=('frame square post','frame transverse beam','frame longitudinal beam','foundation individual plinth','frame mortise peg','daechong rear','floor individual boards','floor under joists','interior partition','photo curved daechong beam')
    protected={o.name:(geometry_fingerprint(o),tuple(m.name for m in o.data.materials)) for o in scene.objects if o.type=='MESH' and not (o.name.startswith('North.anchae.') and any(o.name.startswith('North.anchae.'+p) for p in allowed))}
    report=repair_anchae_plan(scene,contract['buildings'],contract['doors'])
    assert all((geometry_fingerprint(bpy.data.objects[n]),tuple(m.name for m in bpy.data.objects[n].data.materials))==fp for n,fp in protected.items())
    name='scene.blend' if apply else 'anchae-plan-study.blend'
    if apply and not (OUT/'before-anchae-plan-repair.blend').exists():shutil.copy2(OUT/'scene.blend',OUT/'before-anchae-plan-repair.blend')
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/name),compress=True)
    contract['anchaePlanRepair']=report
    for field in ('illustratedTimber','mineralSurfaces'):
        merged={item['object']:item for item in contract.get(field,[])}
        for item in report:
            merged.update({entry['object']:entry for entry in item[field]})
        contract[field]=list(merged.values())
    for rec in contract['buildings']:rec['meshes']=sum(o.type=='MESH' and o.get('construction_building')==rec['id'] for o in scene.objects)
    target='northern-contract.json' if apply else 'anchae-plan-study-contract.json'
    (OUT/target).write_text(json.dumps(contract,ensure_ascii=False,indent=2),encoding='utf8')
    proof={'nativeScene':name,'nativeSha256':hashlib.sha256((OUT/name).read_bytes()).hexdigest(),'unchangedOtherMeshes':len(protected),'changes':report}
    (OUT/'anchae-plan-repair.json').write_text(json.dumps(proof,ensure_ascii=False,indent=2),encoding='utf8')
    if apply:
        for ob in scene.objects:ob.select_set(False)
        obs=[o for o in scene.objects if o.type=='MESH' and o.get('northExtension')]
        for ob in obs:ob.select_set(True);ob.hide_set(False);ob.hide_render=False
        bpy.context.view_layer.objects.active=obs[0]
        bpy.ops.export_scene.gltf(filepath=str(OUT/'northern.glb'),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True,export_extras=True)
    print('AN CHAE PLAN REPAIR',len(report),'groups;',len(protected),'other meshes unchanged',flush=True)
