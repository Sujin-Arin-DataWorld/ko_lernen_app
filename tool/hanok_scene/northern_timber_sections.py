"""Restore measured member sections without changing column axes or openings.

Anchae plan: 210-square main posts; section 052: 330-square daeryang,
180x210 purlins and 150/135 round rafters. Angotgan section 034:
190-square posts, 180x240 beams, 180-square purlins, 135/120 rafters.
Shrine 1985 section 051: 360x390 daeryang and 240 round purlins.
Earlier sheets corroborate MEMBER sections only, not replacement bay grids.
"""
import math
import numpy as np
from mathutils import Matrix,Vector

def groups(mesh):
    parent=list(range(len(mesh.vertices)))
    def find(i):
        while parent[i]!=i:parent[i]=parent[parent[i]];i=parent[i]
        return i
    for edge in mesh.edges:
        a,b=map(find,edge.vertices);parent[b]=a
    result={}
    for v in mesh.vertices:result.setdefault(find(v.index),[]).append(v.index)
    return result.values()

def apply_sections(scene,records):
    report=[]
    for rec in records:
        ident=rec['id']
        if ident not in ('anchae','angotgan','sadang','gokgan'):continue
        origin=Vector((*rec['center'],rec['datum']));rot=Matrix.Rotation(rec['angle'],3,'Z');inv=rot.transposed()
        for ob in scene.objects:
            if ob.type!='MESH' or ob.get('construction_building')!=ident:continue
            name=ob.name;changes=[]
            ispost='frame square post' in name and ident=='anchae'
            transverse='frame transverse beam' in name
            longitudinal='frame longitudinal beam' in name
            rafters='.roof.rafters' in name
            curved='photo curved daechong beam' in name
            floorboard='floor individual boards' in name and ident in ('anchae','sadang')
            if not any((ispost,transverse,longitudinal,rafters,curved,floorboard)):continue
            # Version 2 distinguishes the lighter rear posts shown on the
            # measured plan. Do not scale already corrected rafters twice.
            if floorboard:
                if ob.get('floorSectionVersion',0)>=1:continue
            elif ob.get('measuredSectionsApplied') and (not ispost or ob.get('timberSectionVersion',1)>=2):continue
            oi=ob.matrix_world.inverted()
            if ident=='gokgan' and transverse:
                # Sheet 027 specifies a 300 mm ROUND daeryang. Rebuild its
                # cross-section, retaining the measured span and seated top.
                vertices=[];faces=[];uvs=[]
                for ids in groups(ob.data):
                    points=np.array([inv@(ob.matrix_world@ob.data.vertices[i].co-origin) for i in ids]);low=points.min(0);high=points.max(0);cx=(low[0]+high[0])/2;cz=high[2]-.150;start=len(vertices)
                    for yy in (low[1],high[1]):
                        for j in range(24):
                            angle=j*math.tau/24;p=Vector((cx+.150*math.cos(angle),yy,cz+.150*math.sin(angle)))
                            vertices.append(tuple(oi@(origin+rot@p)))
                    for j in range(24):
                        k=(j+1)%24;faces.append((start+j,start+k,start+24+k,start+24+j));uvs.append(((.425,.419),(.425,.428),(.565,.428),(.565,.419)))
                    faces.extend([tuple(start+j for j in reversed(range(24))),tuple(start+24+j for j in range(24))]);uvs.extend([[(.495+.069*math.cos(j*math.tau/24),.4235+.0044*math.sin(j*math.tau/24)) for j in reversed(range(24))],[(.495+.069*math.cos(j*math.tau/24),.4235+.0044*math.sin(j*math.tau/24)) for j in range(24)]])
                    changes.append({'member':'round daeryang','diameter':.300,'span':float(high[1]-low[1])})
                material=ob.data.materials[0];ob.data.clear_geometry();ob.data.from_pydata(vertices,[],faces);ob.data.update()
                uv=ob.data.uv_layers.get('Canonical gate pigment') or ob.data.uv_layers.new(name='Canonical gate pigment')
                for poly,coords in zip(ob.data.polygons,uvs):
                    poly.use_smooth=len(poly.vertices)==4
                    for li,co in zip(poly.loop_indices,coords):uv.data[li].uv=co
                ob.data.uv_layers.active=uv;uv.active_render=True
                ob['measuredSectionsApplied']=True;ob['timberSectionVersion']=2
                report.append({'object':name,'components':len(changes),'sections':changes});continue
            for ids in groups(ob.data):
                points=np.array([inv@(ob.matrix_world@ob.data.vertices[i].co-origin) for i in ids]);low=points.min(0);high=points.max(0);center=(low+high)/2;size=high-low;new=points.copy();target={}
                if ispost:
                    width=(.135 if center[0]>5.0 else .165) if center[1]>1.30 else .210
                    target={0:width,1:width}
                if transverse:
                    w,h={'anchae':(.330,.330),'angotgan':(.180,.240),'sadang':(.360,.390)}[ident];target={0:w,2:h}
                if curved:target={0:.330,2:.330}
                if floorboard:target={2:.045}
                if longitudinal:
                    if center[2]<1:
                        if ident=='sadang':continue
                        target={1:.090 if ident in ('angotgan','gokgan') else .135,2:.150 if ident in ('angotgan','gokgan') else .240}
                    else:target={1:.180 if ident in ('angotgan','gokgan') else .210,2:.180 if ident=='angotgan' else .300 if ident=='anchae' else .210}
                if rafters:
                    # Round section in the plane perpendicular to each rafter.
                    vals,vecs=np.linalg.eigh((points-center).T@(points-center));axis=vecs[:,2]
                    along=np.outer((points-center)@axis,axis);across=points-center-along
                    diameter=.150 if ident=='anchae' else .135 if ident=='angotgan' else .165
                    new=center+along+across*(diameter/.110)
                    changes.append({'member':'rafter','diameter':diameter})
                else:
                    for axis,value in target.items():new[:,axis]=center[axis]+(points[:,axis]-center[axis])*value/max(size[axis],1e-7)
                    # The top of the beam stays seated below the roof; the
                    # enlarged lower face gives the section its true depth.
                    if 2 in target:new[:,2]+=high[2]-new[:,2].max()
                    changes.append({'member':'floorboard' if floorboard else 'post' if ispost else 'beam','before':size.tolist(),'after':(new.max(0)-new.min(0)).tolist()})
                for i,p in zip(ids,new):ob.data.vertices[i].co=oi@(origin+rot@Vector(p))
            if changes:
                for mod in ob.modifiers:
                    if mod.type=='BEVEL':mod.width=.003 if ispost else .004;mod.segments=2
                ob.data.update();ob['measuredSectionsApplied']=True;ob['timberSectionVersion']=2
                if floorboard:ob['floorSectionVersion']=1
                report.append({'object':name,'components':len(changes),'sections':changes})
        rec['timberSectionAuthority']={'anchae':'1995 plan main 210x210, rear 165x165/135x135; 2007 section 052 daeryang 330x330; rafters 150','angotgan':'2007 section 034: posts 190x190, beams 180x240, purlins 180x180, rafters 135','sadang':'1985 section 051: main beam 360x390; front 240 round column retained; current 2007 bay grid retained','gokgan':'1993 sheet 027: round daeryang diameter 300; upper tie 180x210; lower 90x150; 195-square columns retained'}[ident]
    return report

if __name__=='__main__':
    from pathlib import Path
    import bpy,json,hashlib
    root=Path(__file__).resolve().parents[2];out=root/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
    bpy.ops.wm.open_mainfile(filepath=str(out/'scene.blend'));scene=bpy.context.scene
    contract=json.loads((out/'northern-contract.json').read_text(encoding='utf8'))
    # A perspective floor-pigment sample baked dark plank edges into every
    # flat board. Use the unchanged canonical long-grain timber sample,
    # orienting it along the solid floorboard instead of repeating edge shade.
    floor=bpy.data.objects.get('North.anchae.floor individual boards')
    if floor and floor.data.materials[0].get('surfaceKind')=='floor':
        wood=next(m for m in bpy.data.materials if m.name.startswith('North anchae ') and m.get('surfaceKind')=='wood')
        uv=floor.data.uv_layers.get('Canonical gate pigment')
        for loop in uv.data:
            along=(loop.uv.x-.584)/.031;across=(loop.uv.y-.390)/.015
            loop.uv=(.242+across*.013,.410+along*.113)
        floor.data.materials.clear();floor.data.materials.append(wood)
        floor['floorGrainCorrected']=True
    report=apply_sections(scene,contract['buildings'])
    updated={r['object']:r for r in contract.get('timberSections',[])}
    updated.update({r['object']:r for r in report});contract['timberSections']=list(updated.values())
    (out/'northern-contract.json').write_text(json.dumps(contract,ensure_ascii=False,indent=2),encoding='utf8')
    bpy.ops.wm.save_as_mainfile(filepath=str(out/'scene.blend'),compress=True)
    for o in scene.objects:o.select_set(False)
    obs=[o for o in scene.objects if o.type=='MESH' and o.get('northExtension')]
    for o in obs:o.select_set(True);o.hide_set(False);o.hide_render=False
    bpy.context.view_layer.objects.active=obs[0]
    bpy.ops.export_scene.gltf(filepath=str(out/'northern.glb'),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True,export_extras=True)
    print('Measured sections restored',len(report),'mesh groups',flush=True)
