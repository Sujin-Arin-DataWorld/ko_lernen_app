"""Solid WD4 joinery and real room-to-hall openings in the measured plan.

Printed sizes are authoritative. Door centre along the partition is traced
from fig 4.15; sill height, clearances and small iron profiles are interpreted.
"""
from pathlib import Path
import bpy,bmesh,json,sys,shutil,hashlib
import numpy as np
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).parent))
from northern_wall_joints import basis
from northern_anchae_plan import local_parts,MAIN_REAR,ROOM_REAR
from refine_northern_materials import apply_craft_surfaces,geometry_fingerprint

OUT=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
WIDTH=.695
HEIGHT=1.740
STILE=.054
DEPTH=.045
SAL=.012
SAL_DEPTH=.030
CENTER_Y=MAIN_REAR-(330.5-252)*3.8/231
BOTTOM=.665
SILL_TOP=.650

def refine_anchae_hall_access(scene,records,doors,openings):
    rec=next(r for r in records if r['id']=='anchae')
    if rec.get('hallAccessVersion')==1:return []
    assert rec.get('rearAccessVersion')==1
    origin,rot,axes=basis(records);changed=[]
    sys.path.insert(0,'C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-warm-stone-20260923/tool/hanok_scene')
    import reconstruction_geometry as g
    assert not g.BATCHES
    wood=bpy.data.materials['North anchae wood'];beam=bpy.data.materials['North anchae beam']
    lime=bpy.data.materials['North lime plaster'];paper=bpy.data.materials['North warm hanji']
    clay=bpy.data.materials['North earthen plaster'];iron=bpy.data.materials['North forged iron']

    def remove_components(ob,predicate):
        drop=[];kept=[]
        for ids,q in local_parts(ob,origin,rot):
            if predicate(q):drop+=ids;kept.append((q.min(0),q.max(0)))
        bm=bmesh.new();bm.from_mesh(ob.data);bm.verts.ensure_lookup_table()
        bmesh.ops.delete(bm,geom=[bm.verts[i] for i in drop],context='VERTS');bm.to_mesh(ob.data);bm.free();ob.data.update()
        changed.append(ob.name);return kept

    partition=bpy.data.objects['North.anchae.interior partition']
    old=remove_components(partition,lambda q:min(abs(q[:,0].mean()-axes[i]) for i in (4,6))<.001)
    assert len(old)==2
    entries=[]
    for axis,sign,jamb_depth in ((4,1,.175),(6,-1,.140)):
        prefix='North.anchae.hall room '+('1' if axis==4 else '2')
        old_bounds=next((lo,hi) for lo,hi in old if abs((lo[0]+hi[0])/2-axes[axis])<.001)
        lo,hi=old_bounds
        # Local assembly u runs along the partition; v is its normal. This
        # is a proper rotation, retaining outward face winding and end grain.
        g.set_transform(lambda p,axis=axis:origin+rot@Vector((axes[axis]-p[1],p[0],p[2])))
        a=CENTER_Y-WIDTH/2;b=CENTER_Y+WIDTH/2;clear=WIDTH+.012
        left=CENTER_Y-clear/2;right=CENTER_Y+clear/2;top=BOTTOM+HEIGHT
        fixed=prefix+'.fixed';nm=prefix+'.leaf1'
        for u in (left-.045,right+.045):
            g.box(fixed+'.jamb',(u,0,(.605+top+.096)/2),(.090,jamb_depth,top+.096-.605),beam)
        g.box(fixed+'.head',(CENTER_Y,0,top+.051),(clear+.180,jamb_depth,.090),beam)
        g.box(fixed+'.sill',(CENTER_Y,0,SILL_TOP-.0225),(clear+.180,jamb_depth,.045),beam)
        for u0,u1 in ((float(lo[1]),left-.090),(right+.090,float(hi[1]))):
            assert u1>u0
            g.box(fixed+'.plaster',((u0+u1)/2,0,float((lo[2]+hi[2])/2)),(u1-u0,.090,float(hi[2]-lo[2])),lime)
        g.box(fixed+'.plaster',(CENTER_Y,0,(top+.096+float(hi[2]))/2),(clear+.180,.090,float(hi[2])-top-.096),lime)
        # Rebate: leaf is set into the deep jamb, with a 12 mm solid stop on
        # the room face. Its hall face rotates away from, not into, the jamb.
        v=-sign*(jamb_depth/2-DEPTH/2-.004)
        stop_v=v+sign*(DEPTH/2+.007)
        for u in (a-.004,b+.004):g.box(fixed+'.rebate stop',(u,stop_v,BOTTOM+HEIGHT/2),(.020,.012,HEIGHT),wood)
        g.box(fixed+'.rebate head',(CENTER_Y,stop_v,top-.004),(WIDTH,.012,.020),wood)
        for u in (a+STILE/2,b-STILE/2):g.box(nm+'.stile',(u,v,BOTTOM+HEIGHT/2),(STILE,DEPTH,HEIGHT),wood)
        divider=BOTTOM+(562-481)*HEIGHT/345
        for z in (BOTTOM+STILE/2,divider,top-STILE/2):
            g.box(nm+'.rail',(CENTER_Y,v,z),(WIDTH-2*STILE,DEPTH,STILE),wood)
        iw=WIDTH-2*STILE;grid_bottom=divider+STILE/2;grid_top=top-STILE;gh=grid_top-grid_bottom
        grid_v=v-sign*(DEPTH-SAL_DEPTH)/2
        for i in range(1,15):g.box(nm+'.vertical sal',(a+STILE+iw*i/15,grid_v,(grid_bottom+grid_top)/2),(SAL,SAL_DEPTH,gh),wood)
        for pixel_y in (235,244,252,261,269,330,338,347,355,364,373,434,442,451,459,468,475):
            z=BOTTOM+(562-pixel_y)*HEIGHT/345
            if grid_bottom+SAL/2<z<grid_top-SAL/2:g.box(nm+'.horizontal sal',(CENTER_Y,grid_v,z),(iw,SAL_DEPTH,SAL),wood)
        # Paper remains recessed in the timber frame, including the blank
        # lower light shown by WD4. It is not a wood plank invented from colour.
        for z0,z1 in ((BOTTOM+STILE,divider-STILE/2),(grid_bottom,grid_top)):
            g.box(nm+'.hanji',(CENTER_Y,v+sign*.004,(z0+z1)/2),(iw,.002,z1-z0),paper)
        for z in (BOTTOM+.20,top-.20):
            g.rod(nm+'.hinge pin',(a,v-sign*.025,z-.020),(a,v-sign*.025,z+.020),.006,iron,12)
            g.box(nm+'.hinge strap',(a+.025,v-sign*.025,z),(.050,.005,.022),iron)
        for side in (-1,1):
            vv=v+side*.027;z=BOTTOM+.84
            for name,u in ((nm,b-.028),(fixed,right+.047)):
                g.box(name+'.ring plate',(u,vv,z+.017),(.025,.004,.032),iron)
                g.torus(name+'.iron ring',(u,vv+side*.006,z),.018,.003,iron)
        hinge_local=[axes[axis]-v+sign*.025,a,BOTTOM]
        entry={'building':'anchae','prefix':prefix,'hinges':[list(origin+rot@Vector(hinge_local))],'rotationSigns':[-sign],
               'width':WIDTH,'height':HEIGHT,'doorBottom':BOTTOM,'state':'closed','leaves':1,'schedule':'057 WD4',
               'partitionAxis':axis,'centerLocalY':CENTER_Y,'hingeLocal':hinge_local,'jambDepth':jamb_depth,
               'authority':'057 WD4 695x1740; ulgumi54x45; sal12x30. Plan munsun90x175 / 90x140; single leaves swing into daechong.',
               'unmeasuredDetails':'Plan centre traced at y330.5px, 6mm clearance, 15mm leaf/sill gap, sill level, stops and small iron profiles interpreted.'}
        doors.append(entry);entries.append(entry)
        openings.append({'building':'anchae','tag':prefix.split('North.anchae.')[1],'type':'room-to-hall door','partitionAxis':axis,'center':[axes[axis],CENTER_Y,BOTTOM+HEIGHT/2],'width':WIDTH,'height':HEIGHT,'leaves':1,'schedule':'057 WD4'})

    # Room 1 is a continuous two-bay room. The old per-bay floors had a
    # 220 mm trench at axis 3 and stopped before the restored rear wall.
    # Extend only rooms 1/2 to their existing wall faces; retain their levels.
    g.set_transform(lambda p:origin+rot@Vector(p))
    for tag,material in (('room ondol raised clay',clay),('room warm paper floor',paper)):
        ob=bpy.data.objects['North.anchae.'+tag]
        old_floors=remove_components(ob,lambda q:axes[2]<q[:,0].mean()<axes[4] or axes[6]<q[:,0].mean()<axes[7])
        assert len(old_floors)==3
        for room,x0,x1,y1 in ((1,axes[2]+.045,axes[4]-.045,MAIN_REAR-.045),(2,axes[6]+.045,axes[7]-.045,ROOM_REAR-.045)):
            low,high=next((low,high) for low,high in old_floors if low[0]<x1 and high[0]>x0)
            y0=-1.0875+.045
            g.box('North.anchae.hall room '+str(room)+'.'+tag,((x0+x1)/2,(y0+y1)/2,float((low[2]+high[2])/2)),(x1-x0,y1-y0,float(high[2]-low[2])),material)
    added=g.flush();g.BATCHES.clear();g.set_transform(lambda p:p)
    for ob in added:
        for key,value in {'northExtension':True,'construction_building':'anchae','construction_first':1,'construction_last':99,'source_object_name':ob.name,'anchaeHallAccessVersion':1}.items():ob[key]=value
        for mod in ob.modifiers:
            if mod.type=='BEVEL':mod.width=.0007 if any(k in ob.name for k in ('sal','stile','rail')) else .002;mod.segments=2
        changed.append(ob.name)
    bpy.context.view_layer.update();craft=apply_craft_surfaces(scene)
    rec['hallAccessVersion']=1
    rec['hallAccess']={'doors':entries,'stileSection':[STILE,DEPTH],'salSection':[SAL,SAL_DEPTH],'roomFloorLevelRetained':.6335,'floorInfillInterpretation':True}
    return [{'building':'anchae','objects':changed,'illustratedTimber':craft,'mineralSurfaces':[],'fullSurveyAccuracyClaimed':False}]

if __name__=='__main__':
    apply='--apply' in sys.argv
    bpy.ops.wm.open_mainfile(filepath=str(OUT/'scene.blend'));scene=bpy.context.scene
    c=json.loads((OUT/'northern-contract.json').read_text(encoding='utf8'))
    allowed={'North.anchae.interior partition','North.anchae.room ondol raised clay','North.anchae.room warm paper floor'}
    protected={o.name:(geometry_fingerprint(o),tuple(m.name for m in o.data.materials)) for o in scene.objects if o.type=='MESH' and o.name not in allowed}
    report=refine_anchae_hall_access(scene,c['buildings'],c['doors'],c['openings'])
    assert all((geometry_fingerprint(bpy.data.objects[n]),tuple(m.name for m in bpy.data.objects[n].data.materials))==f for n,f in protected.items())
    name='scene.blend' if apply else 'anchae-hall-study.blend'
    if apply and not (OUT/'before-anchae-hall-access.blend').exists():shutil.copy2(OUT/'scene.blend',OUT/'before-anchae-hall-access.blend')
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/name),compress=True)
    c['anchaeHallAccess']=report
    merged={r['object']:r for r in c.get('illustratedTimber',[]) if r['object'] in bpy.data.objects}
    for item in report:merged.update({r['object']:r for r in item['illustratedTimber']})
    c['illustratedTimber']=list(merged.values())
    for rec in c['buildings']:rec['meshes']=sum(o.type=='MESH' and o.get('construction_building')==rec['id'] for o in scene.objects)
    (OUT/('northern-contract.json' if apply else 'anchae-hall-study-contract.json')).write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf8')
    (OUT/'anchae-hall-access-repair.json').write_text(json.dumps({'nativeScene':name,'nativeSha256':hashlib.sha256((OUT/name).read_bytes()).hexdigest(),'unchangedExistingMeshes':len(protected),'changes':report},ensure_ascii=False,indent=2),encoding='utf8')
    if apply:
        for ob in scene.objects:ob.select_set(False)
        obs=[o for o in scene.objects if o.type=='MESH' and o.get('northExtension')]
        for ob in obs:ob.select_set(True);ob.hide_set(False);ob.hide_render=False
        bpy.context.view_layer.objects.active=obs[0]
        bpy.ops.export_scene.gltf(filepath=str(OUT/'northern.glb'),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True,export_extras=True)
    print('HALL ACCESS',len(report),'groups;',len(protected),'existing meshes unchanged',flush=True)
