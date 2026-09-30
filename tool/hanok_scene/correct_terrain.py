"""Restore a continuous rising earth surface in the connected final model.

V26 omitted the context terrain from GLB but retained two raised stage plates.
Keep the building connection and prior front hwalju correction unchanged.
"""
from pathlib import Path
import bpy,json,hashlib,math,numpy as np
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'assets_unused/pending_review/hwalju-blueprint-review'
OUT=SOURCE/'terrain';OUT.mkdir(exist_ok=True)
CACHE=Path('C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-warm-stone-20260923/assets_unused/pending_review/ildu_spatial_preservation_20260922/pair-construction-v26')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(SOURCE/'scene.blend'))
s=bpy.context.scene
removed=[o for o in s.objects if o.name.startswith('Terrain.') or o.name in ('Stage.Jung.site','Stage.Sarang.site')]
def fingerprint(o):
    h=hashlib.sha256()
    for v in o.data.vertices:h.update(np.asarray(v.co,dtype=np.float32).tobytes())
    for p in o.data.polygons:h.update(np.asarray(p.vertices,dtype=np.int32).tobytes())
    h.update(str([list(r) for r in o.matrix_world]).encode())
    h.update(str(sorted((k,str(o[k])) for k in o.keys())).encode())
    return h.hexdigest()
protected={o.name:fingerprint(o) for o in s.objects if o.type=='MESH' and o not in removed}
removed_names=[o.name for o in removed]
for o in removed:bpy.data.objects.remove(o,do_unlink=True)

def smooth(t):
    t=max(0.,min(1.,t));return t*t*(3.-2.*t)
def ground(x,y):
    # Existing review datum retained: lower Jung courtyard +600mm, high side
    # +1500mm, a 900mm cross-building difference printed on section042.
    west=.6*smooth(y/3.9)
    # Elevation039 shows the approach rising toward the far gate. 680mm rise
    # and its horizontal extent are scaled/interpolated, not surveyed RLs.
    west+=.68*smooth((y-11.4)/3.825)
    east=(1.2+.3*smooth((y-5.2)/3.0))*smooth((y-.5)/4.6)
    cross=smooth((x+.30)/3.0)
    return west+(east-west)*cross

# A single welded mesh. No exposed rectangular perimeter within the review
# cameras; the far terrain continues at its grade rather than dropping to a slab.
xs=sorted(set([-45,-30,-20,-12,-8]+[-6+i*.25 for i in range(113)]+[25,32,42,52]))
ys=sorted(set([-38,-25,-16,-11]+[-8+i*.25 for i in range(113)]+[24,30,40,52]))
verts=[(x,y,ground(x,y)) for y in ys for x in xs];faces=[];nx=len(xs)
for j in range(len(ys)-1):
    for i in range(nx-1):
        a=j*nx+i;faces.extend([(a,a+1,a+1+nx),(a,a+1+nx,a+nx)])
mesh=bpy.data.meshes.new('Continuous front-low rear-high courtyard');mesh.from_pydata(verts,[],faces);mesh.update()
ob=bpy.data.objects.new('TerrainFix.continuous rising courtyard',mesh);s.collection.objects.link(ob)
mat=bpy.data.materials['Courtyard compacted earth'];mesh.materials.append(mat)
for p in mesh.polygons:p.use_smooth=True
uv=mesh.uv_layers.new(name='V26 realtime')
for p in mesh.polygons:
    for li in p.loop_indices:
        co=mesh.vertices[mesh.loops[li].vertex_index].co;uv.data[li].uv=(co.x/2,co.y/2)
ob['source_object_name']=ob.name;ob['construction_building']='site';ob['construction_role']='site';ob['construction_first']=1;ob['construction_last']=99
ob['evidence']='Ground hierarchy: section042 900mm front/back ground difference; elevation039 rising gate approach. Common absolute datum absent; +600mm placement inherited from V26.'
ob['coordinate_interpretation']='Earth grading is an interpolated review reconstruction, not a measured contour survey.'
assert all(fingerprint(bpy.data.objects[n])==h for n,h in protected.items())
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'scene.blend'),compress=True)

# Keep the V26 baked earth pigment/normal/roughness; export terrain only.
mapping=json.loads((CACHE/'realtime-delivery.json').read_text())['materialMapping']
index=list(mapping).index(mat.name)
n=mat.node_tree.nodes;l=mat.node_tree.links;n.clear()
bs=n.new('ShaderNodeBsdfPrincipled');out=n.new('ShaderNodeOutputMaterial');l.new(bs.outputs[0],out.inputs[0]);bs.inputs['Roughness'].default_value=1
un=n.new('ShaderNodeUVMap');un.uv_map=uv.name
for channel in ('color','normal','roughness'):
    tex=n.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(CACHE/'textures'/f'{index:02d}-{channel}.png'),check_existing=True)
    if channel!='color':tex.image.colorspace_settings.name='Non-Color'
    l.new(un.outputs[0],tex.inputs[0])
    if channel=='normal':
        bump=n.new('ShaderNodeNormalMap');l.new(tex.outputs[0],bump.inputs['Color']);l.new(bump.outputs[0],bs.inputs['Normal'])
    else:l.new(tex.outputs[0],bs.inputs['Base Color' if channel=='color' else 'Roughness'])
for o in s.objects:o.select_set(False)
ob.select_set(True);bpy.context.view_layer.objects.active=ob
bpy.ops.export_scene.gltf(filepath=str(OUT/'corrected-parts.glb'),export_format='GLB',use_selection=True,export_apply=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True,export_extras=True)

# Validate the actual mesh and structure, not only the grading function.
checks=[]
def height_at(x,y):
    hit,p,n,face=ob.ray_cast(Vector((x,y,6)),Vector((0,0,-1)))
    assert hit,(x,y);return p.z
def add(name,ok,**detail):checks.append({'check':name,'pass':bool(ok),**detail})
front=height_at(-2,-2);near=height_at(-2,6.8);far=height_at(-2,15.225);rear=height_at(4,9)
add('Sarang foreground < Jung lower courtyard < far gate approach < high courtyard',front<near<far<rear,heights=[front,near,far,rear])
add('Section042 cross-building grade difference 900mm',abs(height_at(4,9)-height_at(-2,9)-.9)<.001)
for x in (-3.,-.8,4.):
    samples=[height_at(x,-1+i*.1) for i in range(181)]
    add(f'Continuous rising grade at x={x}',min(b-a for a,b in zip(samples,samples[1:]))>=-.0001,maxRisePer100mm=max(b-a for a,b in zip(samples,samples[1:])))
# Foot of maru stair, exposed plinth, far gate approach: solid ground reaches
# stone. Lower far-gate stair courses can be buried by the rising approach.
for name,x,y in [('maru stair',-2.34,6.795),('room plinth',-1.0,10.0)]:
    hits=[]
    for part in s.objects:
        if part.type!='MESH' or part==ob or 'Jung' not in part.name:continue
        hit,p,n,face=part.ray_cast(part.matrix_world.inverted()@Vector((x,y,5)),part.matrix_world.inverted().to_3x3()@Vector((0,0,-1)))
        if hit:hits.append(((part.matrix_world@p).z,part.name))
    ground_z=height_at(x,y)
    if hits:
        z,stone_name=min(hits)
        add(name+' ground below usable stone surface',ground_z<=z+.02,groundZ=ground_z,stoneZ=z,stone=stone_name)
    else:add(name+' documented sample',False,xy=[x,y],groundZ=ground_z)
# The ramp deliberately meets the upper gate steps; original lower courses
# stay buried, like a foundation. Check the actual walkable upper envelope,
# rather than incorrectly requiring all buried stone tops above the earth.
route=[]
for i in range(38):
    x=-2.9+i*.05;y=14.175;gz=height_at(x,y);stone=[]
    for part in s.objects:
        if part.type!='MESH' or not part.name.startswith('Jung.front gate stone stairs'):continue
        hit,p,n,face=part.ray_cast(part.matrix_world.inverted()@Vector((x,y,5)),part.matrix_world.inverted().to_3x3()@Vector((0,0,-1)))
        if hit:stone.append((part.matrix_world@p).z)
    z=max([gz]+stone);route.append({'x':x,'groundZ':gz,'surfaceZ':z})
rises=[b['surfaceZ']-a['surfaceZ'] for a,b in zip(route,route[1:])]
add('Gate approach meets three exposed risers and retained 1640mm top course',max(rises)<.30 and sum(d>.10 for d in rises)==3 and abs(route[-1]['surfaceZ']-1.64)<.02,maxRiser=max(rises),exposedRiserCount=sum(d>.10 for d in rises),route=route)
add('All other meshes retain world geometry and construction metadata',all(fingerprint(bpy.data.objects[n])==h for n,h in protected.items()),meshCount=len(protected))
add('No stage display plates in corrected scene',not any(bpy.data.objects.get(n) for n in ('Stage.Sarang.site','Stage.Jung.site')))
report={'sourceSceneSha256':sha(SOURCE/'scene.blend'),'sceneSha256':sha(OUT/'scene.blend'),'removedObjects':removed_names,'addedObjects':[ob.name],'protectedMeshes':len(protected),'protectedMeshFingerprintsUnchanged':True,'checks':checks,'allPass':all(c['pass'] for c in checks),'limitations':['Common surveyed datum between the buildings is unavailable; V26 +600mm courtyard registration is retained.','The rising gate approach and smooth slopes are interpreted from039/042, not surveyed contour points.','Building floors, roof connection and hwalju correction are unchanged.']}
(OUT/'geometry-validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps(report),flush=True)
