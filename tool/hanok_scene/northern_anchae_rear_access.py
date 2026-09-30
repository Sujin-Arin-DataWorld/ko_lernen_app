"""Match the rear room-1 access to plan fig 4.15 and 2007 WD6.

WD6 is a single 655 x 1450 lattice leaf, not the WW1 paired front window.
The rear veranda's relative ground-to-floor rise is 535 mm in section 052.
Absolute site elevations, iron profiles and operating gaps remain interpreted.
"""
from pathlib import Path
import bpy,bmesh,json,sys,shutil,hashlib,random
import numpy as np
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).parent))
from northern_wall_joints import basis
from northern_anchae_plan import local_parts,MAIN_REAR
from northern_anchae_veranda import FLOOR_TOP
from refine_northern_materials import apply_craft_surfaces,geometry_fingerprint
from northern_mineral_surfaces import apply_mineral_surfaces

OUT=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
WIDTH=.655
HEIGHT=1.450
STILE=.054
LEAF_DEPTH=.032
SAL_WIDTH=.009
SAL_DEPTH=.015
BOTTOM=FLOOR_TOP+.020
LEAF_Y=MAIN_REAR+.065
REAR_GROUND=FLOOR_TOP-.535

def refine_anchae_rear_access(scene,records,doors,openings):
    rec=next(r for r in records if r['id']=='anchae')
    if rec.get('rearAccessVersion')==1:return []
    assert rec.get('rearVerandaVersion')==1
    origin,rot,axes=basis(records);changes=[];removed=[]
    sys.path.insert(0,'C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-warm-stone-20260923/tool/hanok_scene')
    import reconstruction_geometry as g
    assert not g.BATCHES
    wood=bpy.data.materials['North anchae wood'];beam=bpy.data.materials['North anchae beam']
    stone=bpy.data.materials['North anchae stone'];soil=bpy.data.materials['North tamped earth']
    paper=bpy.data.materials['North warm hanji'];lime=bpy.data.materials['North lime plaster'];iron=bpy.data.materials['North forged iron']

    def delete_parts(ob,indices):
        bm=bmesh.new();bm.from_mesh(ob.data);bm.verts.ensure_lookup_table()
        bmesh.ops.delete(bm,geom=[bm.verts[i] for i in indices],context='VERTS')
        bm.to_mesh(ob.data);bm.free();ob.data.update();changes.append(ob.name)

    # Retain room 2's separate rear wall/window; replace only the two room-1
    # wall components. The prior double leaves must not survive in the GLB.
    prefixes=['North.anchae.room rear '+str(i) for i in (2,3)]
    for ob in list(scene.objects):
        if ob.type=='MESH' and any(ob.name.startswith(p+'.') for p in prefixes):
            removed.append(ob.name);bpy.data.objects.remove(ob,do_unlink=True)
    for suffix in ('room rear','room rear.jamb','room rear.head/sill'):
        ob=bpy.data.objects['North.anchae.'+suffix];drop=[]
        for ids,p in local_parts(ob,origin,rot):
            if axes[2]<float(p[:,0].mean())<axes[4]:drop+=ids
        delete_parts(ob,drop)
    doors[:]=[d for d in doors if d['prefix'] not in prefixes]
    g.set_transform(lambda p:origin+rot@Vector(p))
    for bay,prefix in zip((2,3),prefixes):
        cx=(axes[bay]+axes[bay+1])/2;a=cx-WIDTH/2;b=cx+WIDTH/2;top=BOTTOM+HEIGHT
        clear=WIDTH+.012;left=cx-clear/2;right=cx+clear/2
        # Plan labels the fixed munsun 90 x 120. Operating clearance is 6 mm.
        fixed=prefix+'.fixed';nm=prefix+'.leaf1'
        for x in (left-.045,right+.045):
            g.box(fixed+'.jamb',(x,MAIN_REAR,(FLOOR_TOP+top+.09)/2),(.090,.120,top+.09-FLOOR_TOP),beam)
        for z,depth in ((FLOOR_TOP,.030),(top+.051,.090)):
            g.box(fixed+'.head and sill',(cx,MAIN_REAR,z),(clear+.180,.120,depth),beam)
        # Actual wall solids stop outside the frame and above the head.
        for x0,x1 in ((axes[bay]+.100,left-.090),(right+.090,axes[bay+1]-.100)):
            g.box(fixed+'.plaster',((x0+x1)/2,MAIN_REAR,(.620+2.790)/2),(x1-x0,.090,2.790-.620),lime)
        g.box(fixed+'.plaster',(cx,MAIN_REAR,(top+.096+2.790)/2),(clear+.180,.090,2.790-top-.096),lime)
        for x in (a+STILE/2,b-STILE/2):g.box(nm+'.stile',(x,LEAF_Y,BOTTOM+HEIGHT/2),(STILE,LEAF_DEPTH,HEIGHT),wood)
        for z in (BOTTOM+STILE/2,top-STILE/2):g.box(nm+'.rail',(cx,LEAF_Y,z),(WIDTH-2*STILE,LEAF_DEPTH,STILE),wood)
        iw=WIDTH-2*STILE;ih=HEIGHT-2*STILE;grid_y=LEAF_Y+(LEAF_DEPTH-SAL_DEPTH)/2
        # Seven columns by seventeen rows traced from the WD6 lattice.
        for i in range(1,7):g.box(nm+'.vertical sal',(a+STILE+iw*i/7,grid_y,BOTTOM+HEIGHT/2),(SAL_WIDTH,SAL_DEPTH,ih),wood)
        for i in range(1,17):g.box(nm+'.horizontal sal',(cx,grid_y,BOTTOM+STILE+ih*i/17),(iw,SAL_DEPTH,SAL_WIDTH),wood)
        g.box(nm+'.hanji',(cx,LEAF_Y-.0015,BOTTOM+HEIGHT/2),(iw,.002,ih),paper)
        # Hinge handedness comes from the plan; the schedule is viewed from
        # the opposite face. Small iron profiles have no measured dimensions.
        for z in (BOTTOM+.16,top-.16):
            g.rod(nm+'.hinge pin',(b,LEAF_Y+.018,z-.018),(b,LEAF_Y+.018,z+.018),.006,iron,12)
            g.box(nm+'.hinge strap',(b-.024,LEAF_Y+.019,z),(.047,.005,.022),iron)
        for side in (-1,1):
            yy=LEAF_Y+side*.025;zz=BOTTOM+.72
            for name,xx in ((nm,a+.032),(fixed,left-.047)):
                g.box(name+'.ring plate',(xx,yy,zz+.016),(.023,.004,.032),iron)
                g.torus(name+'.iron ring',(xx,yy+side*.006,zz),.018,.003,iron)
        doors.append({'building':'anchae','prefix':prefix,'hinges':[list(origin+rot@Vector((b,LEAF_Y,BOTTOM)))],'rotationSigns':[-1],
                      'width':WIDTH,'height':HEIGHT,'doorBottom':BOTTOM,'state':'closed','leaves':1,'schedule':'057 WD6',
                      'authority':'2007 sheet057 WD6: 655x1450, ulgumi54x32, sal9x15; location and outward single-leaf swing from matching plan fig4.15',
                      'unmeasuredDetails':'6mm operating gaps, iron profiles and ring placement interpreted from drawing'})
        for op in openings:
            if op.get('building')=='anchae' and op.get('tag')=='room rear '+str(bay):
                op.update({'center':[cx,LEAF_Y,BOTTOM+HEIGHT/2],'width':WIDTH,'height':HEIGHT,'leaves':1,'type':'rear veranda door','schedule':'057 WD6'})

    # The old generic 240 mm slab buried these short veranda post feet. Keep
    # the rest of the foundation at its existing level, only lower the rear
    # three-bay strip to the explicit section's 535 mm rise below the floor.
    edge=bpy.data.objects['North.anchae.foundation'];selected=[];drop=[]
    for ids,p in local_parts(edge,origin,rot):
        center=(p.min(0)+p.max(0))/2
        if center[1]>2.4 and axes[1]-.30<center[0]<axes[4]+.30:selected.append(p);drop+=ids
    assert selected
    left=float(min(p[:,0].min() for p in selected));right=float(max(p[:,0].max() for p in selected))
    delete_parts(edge,drop)
    # Keep the complete 400 mm main-post plinth footprint supported by the
    # existing inner foundation; start the lowered strip outside that stone.
    boundary=MAIN_REAR+.250
    for tag in ('foundation.recessed earth mortar','foundation earth top'):
        ob=bpy.data.objects['North.anchae.'+tag];p=local_parts(ob,origin,rot)[0][1];lo,hi=p.min(0),p.max(0)
        material=soil if tag.endswith('earth top') else stone
        for x0,x1,y0,y1 in ((lo[0],left,lo[1],hi[1]),(right,hi[0],lo[1],hi[1]),(left,right,lo[1],boundary)):
            g.box('North.anchae.rear level '+tag,((x0+x1)/2,(y0+y1)/2,(lo[2]+hi[2])/2),(x1-x0,y1-y0,hi[2]-lo[2]),material)
        removed.append(ob.name);bpy.data.objects.remove(ob,do_unlink=True)
    rear_edge=MAIN_REAR+1.480
    g.stones('North.anchae.rear veranda low footing',left,right,boundary,rear_edge,-.060,REAR_GROUND,[stone,stone],57052)
    g.box('North.anchae.rear veranda earth surface',((left+right)/2,(boundary+rear_edge)/2,REAR_GROUND-.020),(right-left-.16,rear_edge-boundary-.12,.040),soil)
    added=g.flush();g.BATCHES.clear();g.set_transform(lambda p:p)
    for ob in added:
        for key,value in {'northExtension':True,'construction_building':'anchae','construction_first':1,'construction_last':99,'source_object_name':ob.name,'anchaeRearAccessVersion':1}.items():ob[key]=value
        for mod in ob.modifiers:
            if mod.type=='BEVEL':mod.width=.0007 if any(k in ob.name for k in ('sal','stile','rail')) else .002;mod.segments=2
        changes.append(ob.name)
    bpy.context.view_layer.update()
    craft=apply_craft_surfaces(scene);minerals=apply_mineral_surfaces(scene)
    rec['rearAccessVersion']=1
    rec['rearAccess']={'schedule':'057 WD6','bays':[2,3],'leafWidth':WIDTH,'leafHeight':HEIGHT,'leafCountPerDoor':1,'stileSection':[STILE,LEAF_DEPTH],'salSection':[SAL_WIDTH,SAL_DEPTH],'fixedJambSection':[.09,.12],
                       'rearGroundLocal':REAR_GROUND,'floorRise':.535,'absoluteSiteElevationSurveyed':False,'rearFootingBounds':[left,right,boundary,rear_edge]}
    return [{'building':'anchae','objects':changes,'removedObjects':removed,'illustratedTimber':craft,'mineralSurfaces':minerals,'fullSurveyAccuracyClaimed':False}]

if __name__=='__main__':
    apply='--apply' in sys.argv
    bpy.ops.wm.open_mainfile(filepath=str(OUT/'scene.blend'));scene=bpy.context.scene
    c=json.loads((OUT/'northern-contract.json').read_text(encoding='utf8'))
    protected={o.name:(geometry_fingerprint(o),tuple(m.name for m in o.data.materials)) for o in scene.objects if o.type=='MESH' and o.get('construction_building')!='anchae'}
    report=refine_anchae_rear_access(scene,c['buildings'],c['doors'],c['openings'])
    assert all((geometry_fingerprint(bpy.data.objects[n]),tuple(m.name for m in bpy.data.objects[n].data.materials))==f for n,f in protected.items())
    name='scene.blend' if apply else 'anchae-access-study.blend'
    if apply and not (OUT/'before-anchae-rear-access.blend').exists():shutil.copy2(OUT/'scene.blend',OUT/'before-anchae-rear-access.blend')
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/name),compress=True)
    c['anchaeRearAccess']=report
    for field in ('illustratedTimber','mineralSurfaces'):
        merged={r['object']:r for r in c.get(field,[]) if r['object'] in bpy.data.objects}
        for item in report:merged.update({r['object']:r for r in item[field]})
        c[field]=list(merged.values())
    for rec in c['buildings']:rec['meshes']=sum(o.type=='MESH' and o.get('construction_building')==rec['id'] for o in scene.objects)
    target='northern-contract.json' if apply else 'anchae-access-study-contract.json'
    (OUT/target).write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf8')
    (OUT/'anchae-rear-access-repair.json').write_text(json.dumps({'nativeScene':name,'nativeSha256':hashlib.sha256((OUT/name).read_bytes()).hexdigest(),'unchangedOtherMeshes':len(protected),'changes':report},ensure_ascii=False,indent=2),encoding='utf8')
    if apply:
        for ob in scene.objects:ob.select_set(False)
        obs=[o for o in scene.objects if o.type=='MESH' and o.get('northExtension')]
        for ob in obs:ob.select_set(True);ob.hide_set(False);ob.hide_render=False
        bpy.context.view_layer.objects.active=obs[0]
        bpy.ops.export_scene.gltf(filepath=str(OUT/'northern.glb'),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True,export_extras=True)
    print('REAR ACCESS',len(report),'groups;',len(protected),'other meshes unchanged',flush=True)
