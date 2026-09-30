"""Read-only register for the requested timber, platform tops and rear clearance."""
from collections import Counter, defaultdict
from pathlib import Path
import json
import sys
import bpy
import numpy as np
sys.path.insert(0,str(Path(__file__).parent))
from apply_estate_matte_register import owner_of
N=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
bpy.ops.wm.open_mainfile(filepath=str(N/'estate-fabric.blend'))
objects=defaultdict(list)
materials={}
for ob in bpy.context.scene.objects:
    if ob.type!='MESH' or ob.hide_render:continue
    owner=owner_of(ob)
    stage=16 if owner=='sarang' else 12
    if owner in ('sarang','jung') and not ob.get('construction_first',0)<=stage<=ob.get('construction_last',99):continue
    if owner not in ('sarang','jung','gokgan','estate_wall','north_site') and not any(x in ob.name.lower() for x in ('foundation','platform','plinth','stone base','ground slab')):continue
    used=Counter(poly.material_index for poly in ob.data.polygons)
    points=np.array([ob.matrix_world@v.co for v in ob.data.vertices])
    row={'name':ob.name,'bounds':[points.min(0).tolist(),points.max(0).tolist()],
         'materials':{ob.data.materials[i].name:count for i,count in used.items()},'vertices':len(points)}
    if any(x in ob.name.lower() for x in ('foundation','platform','plinth','stone','core','floor','cap')):
        row['xyPoints']=np.unique(np.round(points[:,:2],5),axis=0).tolist()
    objects[owner].append(row)
    for i in used:
        mat=ob.data.materials[i]
        if mat.name in materials:continue
        record={'images':[],'colorSource':None,'baseColor':None}
        for node in mat.node_tree.nodes if mat.use_nodes else []:
            if node.type=='TEX_IMAGE' and node.image:
                record['images'].append({'name':node.name,'path':bpy.path.abspath(node.image.filepath)})
            elif node.type=='BSDF_PRINCIPLED':
                record['baseColor']=list(node.inputs['Base Color'].default_value)
                record['colorSource']=node.inputs['Base Color'].links[0].from_node.name if node.inputs['Base Color'].is_linked else None
        materials[mat.name]=record
report={'objects':dict(objects),'materials':materials}
(N/'craft-surface-register.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
print('CRAFT SURFACE REGISTER',{owner:len(rows) for owner,rows in objects.items()},flush=True)
