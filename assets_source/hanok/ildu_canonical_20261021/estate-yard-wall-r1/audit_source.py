import bpy, json, hashlib
from array import array
from pathlib import Path
from mathutils import Vector

OUT=Path(__file__).resolve().parent
SOURCE=OUT.parents[3]/'canonical/native/ildu-estate-r12-packed.blend'
EXPECTED='b3b51dec9f2d4a7629912326bb224e8cf5595c2a874a1c3c85075a5f742af434'

def write(name,data):
    (OUT/name).write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')

def sha(p):
    with open(p,'rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()

def dh(data,prop,n,kind='f'):
    a=array(kind,[0])*n
    if n:data.foreach_get(prop,a)
    return hashlib.sha256(a.tobytes()).hexdigest()

def state():
    states={}
    for o in bpy.data.objects:
        r={'type':o.type,'matrix':[list(x) for x in o.matrix_world], 'parent':o.parent.name if o.parent else None, 'hide_render':o.hide_render}
        if o.type=='MESH':
            m=o.data
            r.update(mesh=m.name, vertices=dh(m.vertices,'co',len(m.vertices)*3), edges=dh(m.edges,'vertices',len(m.edges)*2,'i'), loops=dh(m.loops,'vertex_index',len(m.loops),'i'), starts=dh(m.polygons,'loop_start',len(m.polygons),'i'), totals=dh(m.polygons,'loop_total',len(m.polygons),'i'), material_indices=dh(m.polygons,'material_index',len(m.polygons),'i'), uv={u.name:dh(u.data,'uv',len(u.data)*2) for u in m.uv_layers}, modifiers=[(x.name,x.type,x.show_render) for x in o.modifiers])
        states[o.name]=r
    return states

def bindings():return {o.name:[(s.link,s.material.name if s.material else None) for s in o.material_slots] for o in bpy.data.objects if o.type=='MESH'}

def bounds(o):
    p=[o.matrix_world@Vector(x) for x in o.bound_box]
    return [[min(v[i] for v in p) for i in range(3)],[max(v[i] for v in p) for i in range(3)]]

if __name__=='__main__':
    SOURCE=Path(bpy.data.filepath).resolve()
    assert SOURCE.is_file() and sha(SOURCE)==EXPECTED
    write('geometry-before.json',state());write('bindings-before.json',bindings())
    scene=bpy.data.scenes['Hangul Sori | Full Ildu Estate']
    scope_path=OUT.parents[2]/'WALL_SCOPE.json'
    wall_scope=json.loads(scope_path.read_text(encoding='utf-8')) if scope_path.exists() else {'knownDedicatedWallGroups':[]}
    known={s for g in wall_scope['knownDedicatedWallGroups'] for s in g['sourceObjects']}
    items=[]
    for o in scene.objects:
        if o.type!='MESH':continue
        mats=[s.material.name if s.material else None for s in o.material_slots]
        n=o.name.lower()
        if o.name in known or any(w in n for w in ['wall','boundary','courtyard','gyegrass.earth','unplanted beds','pigment surface']):
            items.append({'name':o.name,'known':o.name in known,'bounds':bounds(o),'materials':mats,'hide':o.hide_render,'collections':[c.name for c in o.users_collection]})
    cams=[{'name':o.name,'position':list(o.location),'rotation':list(o.rotation_euler),'type':o.data.type,'ortho':o.data.ortho_scale} for o in scene.objects if o.type=='CAMERA']
    write('source-audit.json',{'source':str(SOURCE),'source_sha256':EXPECTED,'named_wall_scope_available':scope_path.exists(),'scene':scene.name,'scene_camera':scene.camera.name,'cameras':cams,'engine':scene.render.engine,'units':scene.unit_settings.scale_length,'render':[scene.render.resolution_x,scene.render.resolution_y,scene.render.resolution_percentage], 'objects':items})
    print('AUDIT',len(items),'potential scope objects',len(bpy.data.objects),'total')
