"""Attach source-derived gates and warehouse to the user-approved pair.

Preserve every approved building mesh. Adapt only the surrounding earth and
placement of the western additions to the approved +600mm western court.
"""
from pathlib import Path
import bpy,json,hashlib,math,numpy as np
from mathutils import Vector,Matrix
ROOT=Path(__file__).resolve().parents[2]
REVIEW=ROOT/'assets_unused/pending_review/hwalju-blueprint-review'
BASE=REVIEW/'terrain';OUT=REVIEW/'side-connections';OUT.mkdir(exist_ok=True)
OLD=Path('C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-warm-stone-20260923/assets_unused/pending_review/ildu_spatial_preservation_20260922')
SOURCE=OLD/'existing-estate-v36'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
approved={'scene.blend':'3d183474f4475fa9fb044ce800881599cf8088d379bdd727cb4fc5c1b3b4a29d','pair-corrected.glb':'66dc4cbb3a1e30872ecb88c629c90b68308e748344dba8aa8a4e835d21f502e0'}
assert all(sha(BASE/k)==v for k,v in approved.items())
(OUT/'approved-baseline.json').write_text(json.dumps({'acceptedByUser':True,'userDecision':'이걸로 결정하자','source':'../terrain/review.html','sha256':approved,'runtimePromotionRequested':False},ensure_ascii=False,indent=2),encoding='utf8')
bpy.ops.wm.open_mainfile(filepath=str(BASE/'scene.blend'));s=bpy.context.scene
def fingerprint(o):
    h=hashlib.sha256()
    for v in o.data.vertices:h.update(np.asarray(v.co,dtype=np.float32).tobytes())
    for p in o.data.polygons:h.update(np.asarray(p.vertices,dtype=np.int32).tobytes())
    h.update(str([list(r) for r in o.matrix_world]).encode())
    h.update(str(sorted((k,str(o[k])) for k in o.keys())).encode())
    h.update(str([m.name for m in o.data.materials]).encode());return h.hexdigest()
terrain=bpy.data.objects['TerrainFix.continuous rising courtyard'];earth=terrain.data.materials[0]
protected={o.name:fingerprint(o) for o in s.objects if o.type=='MESH' and o!=terrain}
allowed={'left_changgo':6,'right_ansarang':6,'changgo':8,'ansarang':14}
with bpy.data.libraries.load(str(SOURCE/'scene.blend'),link=False) as (src,dst):
    dst.objects=[name for name in src.objects if any('.'+key+'.' in name for key in allowed)]
imported=[];placements={};materials={}
# The inherited short wall ended at the warehouse plinth edge. Extend it to
# the actual timber/post line between canonical facade bays 3 and 4.
def wall_transform(a,b,c,d):
    a,b,c,d=map(Vector,(a,b,c,d));u=(b-a).normalized();v=(d-c)/(b-a).length;vu=v.normalized()
    normal=Vector((-u.y,u.x));newnormal=Vector((-vu.y,vu.x))
    linear=np.outer(v,u)+np.outer(newnormal,normal);move=np.array(c)-linear@np.array(a)
    return Matrix(((linear[0,0],linear[0,1],0,move[0]),(linear[1,0],linear[1,1],0,move[1]),(0,0,1,0),(0,0,0,1)))
# A common straight axis through each pair of gate posts. Ends enter the
# post/warehouse junction by 12-20mm so no unbuilt strip remains in daylight.
wall_specs=[
 ('left_changgo','wall to warehouse',(-6.900624830924481,3.2950282785308875),(-4.338,3.802),(-7.23,3.802),(-4.304,3.802)),
 ('left_changgo','wall to sarang',(-2.058,3.802),(-.11,3.985),(-2.092,3.802),(-.08,3.802)),
 ('right_ansarang','wall to sarang',(14.635,.06),(17.282,.083),(14.60,.083),(17.322,.083)),
 ('right_ansarang','wall to ansarang',(18.902,.083),(23.25,.333),(18.862,.083),(23.25,.083)),
]
# Read the live donor core, since later donor revisions moved some wall ends.
# An old endpoint table silently leaves diagonal walls even after an affine.
resolved_specs=[]
for ident,key,_,_,c,d in wall_specs:
    core=next(o for o in dst.objects if o and o.type=='MESH' and o.get('construction_building')==ident and key in o.name and 'earth core' in o.name)
    cloud=np.array([(core.matrix_basis@v.co)[:2] for v in core.data.vertices]);center=cloud.mean(axis=0)
    _,basis=np.linalg.eigh((cloud-center).T@(cloud-center));along=basis[:,-1]
    if along[0]<0:along=-along
    t=(cloud-center)@along;a=(center+along*t.min()).tolist();b=(center+along*t.max()).tolist()
    resolved_specs.append((ident,key,a,b,c,d))
wall_specs=resolved_specs
wall_matrices={(ident,key):wall_transform(a,b,c,d) for ident,key,a,b,c,d in wall_specs}
for o in dst.objects:
    if not o or o.type!='MESH':continue
    ident=o.get('construction_building');end=allowed.get(ident)
    if end is None or not o.get('construction_first',1)<=end<=o.get('construction_last',99):continue
    s.collection.objects.link(o);o.hide_render=False;o.hide_set(False)
    # Keep the source wall here; refine_canonical_gates adds grounded lower
    # masonry and raises its coping to the photo's eaves-level connection.
    dz=.6 if ident=='changgo' or ident=='left_changgo' and 'wall to sarang' not in o.name else 0.
    if ident=='ansarang':dz=-.6
    o.location.z+=dz
    turn_gate=ident=='right_ansarang' and '.wall ' not in o.name
    if turn_gate:
        pivot=Vector((18.092,.083,0));o.matrix_world=Matrix.Translation(pivot)@Matrix.Rotation(math.pi,4,'Z')@Matrix.Translation(-pivot)@o.matrix_basis
    wall_key=next((key for key in wall_matrices if key[0]==ident and key[1] in o.name),None)
    if wall_key:
        # Bake the affine into vertices. Object transform decomposition cannot
        # preserve the shear of a rotated wall when its length also changes.
        o.data=o.data.copy();o.data.transform(wall_matrices[wall_key]@o.matrix_basis)
        o.matrix_world=Matrix.Identity(4)
    original=o.get('source_object_name',o.name);o['source_object_name']=original
    placements[original]={'zOffset':dz,'building':ident,'nativeObject':o.name,'warehouseWallExtension':'wall to warehouse' in o.name,'rightGateRotatedToSarangForecourt':turn_gate}
    imported.append(o)
    for m in o.data.materials:materials[m.name]=True
assert sum(o.get('construction_building')!='ansarang' for o in imported)==430
assert any(o.get('construction_building')=='ansarang' for o in imported)
bpy.context.view_layer.update()
for ident,key,a,b,c,d in wall_specs:
    core=next(o for o in imported if o.get('construction_building')==ident and key in o.name and 'earth core' in o.name)
    ps=np.array([(core.matrix_world@v.co)[:] for v in core.data.vertices])
    assert np.max(np.abs(np.array([ps[:,0].min(),ps[:,0].max()])-np.array([c[0],d[0]])))<1e-4,(key,ps.min(axis=0),ps.max(axis=0))
    assert abs((ps[:,1].min()+ps[:,1].max())/2-c[1])<1e-4
old=json.loads((SOURCE/'estate.json').read_text(encoding='utf8'))
doors=[v for v in old['doors'] if v['building'] in allowed]
for d in doors:
    dz=.6 if d['building'] in ('left_changgo','changgo') else -.6 if d['building']=='ansarang' else 0
    for hinge in d['hinges']:hinge[2]+=dz
    if d['building']=='right_ansarang':
        for hinge in d['hinges']:hinge[0]=36.184-hinge[0];hinge[1]=.166-hinge[1]
gates=[v for v in old['gates'] if v['id'] in allowed]
for gate in gates:
    if gate['id']=='right_ansarang':
        gate['orientationRadians']=0
        for hinge in gate['hinges']:hinge[0]=36.184-hinge[0];hinge[1]=.166-hinge[1]
    if gate['id']=='left_changgo':
        for k in ('ground','landing','doorBottom','threshold','eave','ridge'):gate[k]+=.6
        for hinge in gate['hinges']:hinge[2]+=.6

def smooth(t):
    t=max(0.,min(1.,t));return t*t*(3-2*t)
def approved_ground(x,y):
    west=.6*smooth(y/3.9)+.68*smooth((y-11.4)/3.825)
    east=(1.2+.3*smooth((y-5.2)/3))*smooth((y-.5)/4.6)
    return west+(east-west)*smooth((x+.3)/3)
def ground(x,y):
    z=approved_ground(x,y)
    # Continuous western yard at the gate's datum, including all six warehouse
    # bays. Transition ends outside the protected pair (x<-2.5).
    west=(1-smooth((x+6.0)/3.5))*smooth((y+6.5)/2)*(1-smooth((y-10.7)/2.4))
    z=z*(1-west)+.6*west
    # The right stair faces the Sarang forecourt (-Y). The Ansarang forecourt
    # is reached without passing through that gate, across a low open path.
    east=smooth((x-15.8)/1.1)*(1-smooth((x-29)/4))*(1-smooth((y-3.4)/4.4))*smooth((y+21)/3)
    local=.12*smooth((x-19)/2)+.72*smooth((y-.083+.6)/1.2)
    local=min(.72,local)
    return z*(1-east)+local*east
# Loose stepping stones follow the sloping approach instead of hanging at the
# gate's raised floor datum. Slight partial burial is intentional.
for part in imported:
    if part.get('construction_building')=='left_changgo' and '.finish.approach' in part.name:
        points=[part.matrix_world@Vector(c) for c in part.bound_box]
        center=sum(points,Vector())/len(points);top=max(p.z for p in points)
        delta=ground(center.x,center.y)+.035-top;part.location.z+=delta
        placements[part['source_object_name']]['zOffset']+=delta
old_samples=[(v.co.x,v.co.y,v.co.z) for v in terrain.data.vertices]
unchanged=[]
for x,y,z in old_samples:
    if -2.5<=x<=15.8:unchanged.append(abs(ground(x,y)-z)<1e-6)
assert all(unchanged)
bpy.data.objects.remove(terrain,do_unlink=True)
xs=sorted(set([-45,-30,-20,-16]+[-14+i*.2 for i in range(241)]+[38,45,52]))
ys=sorted(set([-38,-25,-20]+[-17+i*.2 for i in range(196)]+[26,34,42,52]))
verts=[(x,y,ground(x,y)) for y in ys for x in xs];faces=[];nx=len(xs)
for j in range(len(ys)-1):
    for i in range(nx-1):
        a=j*nx+i;faces.extend([(a,a+1,a+1+nx),(a,a+1+nx,a+nx)])
mesh=bpy.data.meshes.new('Continuous courtyard with both gate approaches');mesh.from_pydata(verts,[],faces);mesh.update()
terrain=bpy.data.objects.new('ConnectionSite.continuous earth',mesh);s.collection.objects.link(terrain);mesh.materials.append(earth)
for p in mesh.polygons:p.use_smooth=True
uv=mesh.uv_layers.new(name='Site realtime')
for p in mesh.polygons:
    for i in p.loop_indices:
        co=mesh.vertices[mesh.loops[i].vertex_index].co;uv.data[i].uv=(co.x/2,co.y/2)
for k,v in {'source_object_name':terrain.name,'construction_building':'site','construction_role':'site','construction_first':1,'construction_last':99}.items():terrain[k]=v
assert all(fingerprint(bpy.data.objects[n])==f for n,f in protected.items())
contract={'approvedBaseline':approved,'sourceNativeSha256':sha(SOURCE/'scene.blend'),'sourceRealtimeSha256':sha(SOURCE/'pair-v26.glb'),'source':'existing-estate-v36 components rechecked against canonical references and site002','placements':placements,'gates':gates,'doors':doors,'buildings':{'changgo':old['buildings']['changgo']},'preservedPairMeshes':len(protected),'preservedCoreGroundSamples':len(unchanged),'coreGroundDomain':{'xMin':-2.5,'xMax':15.8},'newGroundInterpretation':'West gate and warehouse datum +600mm; right low approach to +720mm inner yard. Grading outside approved core is interpreted, not surveyed.','artAuthority':'Six paired warehouse facade doors follow the locked canonical artwork; measured plan supplies 13280x2880 envelope. Door positions differ from historical plan.','leftGateAuthority':'Larger left portal linked to sheet021 by site002/photo association; sheet identity remains interpreted. Right uses sheet090 scaled elevations.','ansarangScope':'Right gate, wall and raised entrance yard toward Ansarang; Ansarang building is outside this extension.'}
contract['buildings']['ansarang']=old['buildings']['ansarang']
for key in ('ground','floor','wallTop','eave','ridge'):contract['buildings']['ansarang'][key]-=.6
contract['ansarangScope']='Ansarang native building from V36, sheet048 four2730mm bays, site002 XY placement. Open gate-free path from Sarang forecourt to Ansarang forecourt at interpreted +120mm. Separate right gate rises northwards to inner court.'
contract['newGroundInterpretation']='West gate/warehouse +600mm. Ansarang forecourt +120mm, open route without gate. Separate right portal rises to +720mm inner court. Heights are review registration, not a surveyed datum.'
contract['wallJunctionRegistration']=[{'building':ident,'part':key,'oldEndpoints':[a,b],'newEndpoints':[c,d],'worldMatrixRows':[list(row) for row in wall_matrices[(ident,key)]]} for ident,key,a,b,c,d in wall_specs]
contract['warehouseWallExtension']={'oldEndpoint':wall_specs[0][2],'newEndpoint':wall_specs[0][4],'newGateEndpoint':wall_specs[0][5],'worldMatrixRows':[list(row) for row in wall_matrices[('left_changgo','wall to warehouse')]],'reason':'Latest user correction: straight wall on the gate post axis, joined to the warehouse facade without an angled stub or daylight gap.'}
(OUT/'connection-contract.json').write_text(json.dumps(contract,ensure_ascii=False,indent=2),encoding='utf8')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'scene.blend'),compress=True)
import shutil
shutil.copyfile(OUT/'scene.blend',OUT/'structure-base.blend')

# Export only the new earth surface. The appended buildings use their existing
# detailed UVs and baked maps directly from the donor GLB, without rebaking.
cache=OLD/'pair-construction-v26';mapping=json.loads((cache/'realtime-delivery.json').read_text())['materialMapping'];idx=list(mapping).index('Courtyard compacted earth')
n=earth.node_tree.nodes;l=earth.node_tree.links;n.clear();bs=n.new('ShaderNodeBsdfPrincipled');out=n.new('ShaderNodeOutputMaterial');l.new(bs.outputs[0],out.inputs[0]);un=n.new('ShaderNodeUVMap');un.uv_map=uv.name
for ch in ('color','normal','roughness'):
    tex=n.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(cache/'textures'/f'{idx:02d}-{ch}.png'),check_existing=True)
    if ch!='color':tex.image.colorspace_settings.name='Non-Color'
    l.new(un.outputs[0],tex.inputs[0])
    if ch=='normal':
        normal=n.new('ShaderNodeNormalMap');l.new(tex.outputs[0],normal.inputs['Color']);l.new(normal.outputs[0],bs.inputs['Normal'])
    else:l.new(tex.outputs[0],bs.inputs['Base Color' if ch=='color' else 'Roughness'])
for o in s.objects:o.select_set(False)
terrain.select_set(True);bpy.context.view_layer.objects.active=terrain
bpy.ops.export_scene.gltf(filepath=str(OUT/'terrain-patch.glb'),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True,export_extras=True)
print('SIDE CONNECTIONS BUILT',len(imported),'source components;',len(protected),'approved meshes unchanged',flush=True)
