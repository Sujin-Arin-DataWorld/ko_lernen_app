"""Seat existing Anchae/Arae beams on their posts; retain measured sections.

The old frame helper summed all three post rows and divided by two. Correct
the span centre, including Anchae's measured 725 mm rear-wall step. This is
a focused migration of the review scene, not a rebuild of accepted buildings.
"""
from pathlib import Path
import sys,json,hashlib,shutil,math
import bpy,numpy as np
from mathutils import Matrix,Vector
sys.path.insert(0,str(Path(__file__).parent))
from northern_timber_sections import groups
from refine_northern_materials import geometry_fingerprint

OUT=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'

def bearing_hits(scene,ident):
    bpy.context.view_layer.update()
    beam=bpy.data.objects['North.'+ident+'.frame transverse beam'].evaluated_get(bpy.context.evaluated_depsgraph_get())
    post=bpy.data.objects['North.'+ident+'.frame square post']
    misses=[];count=0
    for ids in groups(post.data):
        points=np.array([post.matrix_world@post.data.vertices[i].co for i in ids])
        lo,hi=points.min(0),points.max(0);center=(lo+hi)/2
        start=beam.matrix_world.inverted()@Vector((center[0],center[1],hi[2]+.50))
        direction=beam.matrix_world.inverted().to_3x3()@Vector((0,0,-1))
        hit,location,normal,index=beam.ray_cast(start,direction,distance=.90)
        count+=1
        if not hit:misses.append(center.tolist())
    return {'postCount':count,'missedPosts':misses}

def repair(scene,records):
    reports=[]
    for ident,offset in (('anchae',.54375),('arae',.410)):
        rec=next(r for r in records if r['id']==ident)
        ob=bpy.data.objects['North.'+ident+'.frame transverse beam']
        if ob.get('beamSeatingVersion')==1:continue
        origin=Vector((*rec['center'],rec['datum']));rot=Matrix.Rotation(rec['angle'],3,'Z');inv=rot.transposed();oi=ob.matrix_world.inverted()
        step_x=-rec['bodyWidth']/2+sum(rec['bays'][:4]) if ident=='anchae' else -math.inf
        def unwarp(p):
            q=np.array(p,copy=True)
            if ident=='anchae' and q[0]<step_x and q[1]>-.9875:
                q[1]=q[1]+.725 if q[1]>=1.5375 else (q[1]+.725*.9875/3.25)/(1-.725/3.25)
            return q
        def warp(p):
            q=np.array(p,copy=True)
            if ident=='anchae' and q[0]<step_x and q[1]>-.9875:q[1]-=.725*min(1,(q[1]+.9875)/3.25)
            return q
        before=bearing_hits(scene,ident);changes=[]
        for ids in groups(ob.data):
            pts=np.array([unwarp(inv@(ob.matrix_world@ob.data.vertices[i].co-origin)) for i in ids])
            lo,hi=pts.min(0),pts.max(0);cy=(lo[1]+hi[1])/2
            assert abs(cy+offset)<2e-5,(ident,'Unexpected beam centre',cy)
            moved=pts.copy();moved[:,1]+=offset
            assert np.allclose(np.ptp(moved,axis=0),np.ptp(pts,axis=0),atol=1e-8)
            for i,p in zip(ids,moved):ob.data.vertices[i].co=oi@(origin+rot@Vector(warp(p)))
            changes.append({'beforeCentre':float(cy),'afterCentre':float(cy+offset),'retainedSection':[float(hi[0]-lo[0]),float(hi[2]-lo[2])]})
        ob.data.update();ob['beamSeatingVersion']=1
        after=bearing_hits(scene,ident)
        assert not after['missedPosts'],(ident,after)
        reports.append({'building':ident,'object':ob.name,'before':before,'after':after,'members':changes})
    return reports

if __name__=='__main__':
    bpy.ops.wm.open_mainfile(filepath=str(OUT/'scene.blend'));scene=bpy.context.scene
    contract=json.loads((OUT/'northern-contract.json').read_text(encoding='utf8'))
    if '--apply' not in sys.argv:
        print(json.dumps({ident:bearing_hits(scene,ident) for ident in ('anchae','arae')},indent=2));sys.exit(0)
    names={'North.'+ident+'.frame transverse beam' for ident in ('anchae','arae')}
    protected={o.name:geometry_fingerprint(o) for o in scene.objects if o.type=='MESH' and o.name not in names}
    changed=repair(scene,contract['buildings'])
    assert all(geometry_fingerprint(bpy.data.objects[n])==fp for n,fp in protected.items())
    if changed:
        backup=OUT/'before-anchae-arae-beam-seating.blend'
        if not backup.exists():shutil.copy2(OUT/'scene.blend',backup)
        bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'scene.blend'),compress=True)
        contract['beamSeating']=changed
        (OUT/'northern-contract.json').write_text(json.dumps(contract,ensure_ascii=False,indent=2),encoding='utf8')
        for ob in scene.objects:ob.select_set(False)
        obs=[o for o in scene.objects if o.type=='MESH' and o.get('northExtension')]
        for ob in obs:ob.select_set(True);ob.hide_set(False);ob.hide_render=False
        bpy.context.view_layer.objects.active=obs[0]
        bpy.ops.export_scene.gltf(filepath=str(OUT/'northern.glb'),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True,export_extras=True)
    proof={'nativeSha256':hashlib.sha256((OUT/'scene.blend').read_bytes()).hexdigest(),'unchangedOtherMeshes':len(protected),'changes':changed}
    (OUT/'beam-seating-validation.json').write_text(json.dumps(proof,ensure_ascii=False,indent=2),encoding='utf8')
    print('Beam seating corrected:',len(changed),'mesh groups;',len(protected),'other meshes unchanged')
