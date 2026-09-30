from pathlib import Path
import bpy, json
from mathutils import Vector

SOURCE = Path('C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-warm-stone-20260923/assets_unused/pending_review/ildu_spatial_preservation_20260922/pair-construction-v26/scene.blend')
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
s=bpy.context.scene
for o in s.objects:
    if o.type=='MESH' and ('hwalju' in o.name.lower()):
        points=[o.matrix_world@v.co for v in o.data.vertices]
        print(json.dumps({'object':o.name,'matrix':[list(row) for row in o.matrix_world], 'bounds':[[min(v[k] for v in points),max(v[k] for v in points)] for k in range(3)],'vertices':len(points),'materials':[m.name for m in o.data.materials]}))
for o in s.objects:
    if o.type=='MESH' and any(t in o.name.lower() for t in ('stone','foundation','plinth','landing','terrain')) and not o.name.startswith(('Jung','Ref.Jung','V26.Jung','Craft.Jung')):
        points=[o.matrix_world@Vector(p) for p in o.bound_box]
        print(json.dumps({'foundation':o.name,'bounds':[[round(min(v[k] for v in points),3),round(max(v[k] for v in points),3)] for k in range(3)]}))
for xy in [(-.91,-.90),(-.65,-.90),(-.91,-.65),(9.68,-4.90),(9.8,-4.4),(10.3,-4.5),(15.76,-5.205),(-.91,4.855)]:
    hits=[]
    for o in s.objects:
        if o.type!='MESH' or 'hwalju' in o.name.lower() or o.hide_render: continue
        lo=o.matrix_world.inverted()@Vector((*xy,10))
        direction=o.matrix_world.inverted().to_3x3()@Vector((0,0,-1))
        hit,p,n,idx=o.ray_cast(lo,direction)
        if hit:
            wp=o.matrix_world@p
            hits.append((round(wp.z,4),o.name))
    print(json.dumps({'xy':xy,'hits':sorted(hits)}))
print('CAMERAS',[(o.name,tuple(o.location)) for o in s.objects if o.type=='CAMERA'])
