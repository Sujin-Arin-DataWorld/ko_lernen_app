from pathlib import Path
import bpy,json
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'assets_unused/pending_review/hwalju-blueprint-review/scene.blend'))
for o in bpy.context.scene.objects:
    if o.type=='MESH' and (o.name.startswith(('Terrain.','Stage.Jung.site','Stage.Sarang.site','Jung.gate floor','Jung.room1 floor','Jung.maru floor')) or 'Jung.front gate stone stairs' in o.name or 'Jung.front maru stone stairs' in o.name):
        pts=[o.matrix_world@Vector(v) for v in o.bound_box]
        print(json.dumps({'name':o.name,'bounds':[[round(min(v[k] for v in pts),4),round(max(v[k] for v in pts),4)] for k in range(3)],'materials':[m.name for m in o.data.materials],'properties':{k:str(o[k]) for k in o.keys()},'hide_render':o.hide_render}))
