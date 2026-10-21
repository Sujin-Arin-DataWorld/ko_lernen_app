"""Read-only floor ownership/visibility investigation. No render or saves."""
import json
from pathlib import Path

import bpy
from mathutils import Vector, Euler

OUT = Path(__file__).resolve().parent
BASE = OUT.parent
scene = bpy.data.scenes['Hangul Sori | Full Ildu Estate']
graph = bpy.context.evaluated_depsgraph_get()
manifest = json.loads((BASE / 'living-r3/render-manifest.json').read_text(encoding='utf-8'))
camera = next(r['camera'] for r in manifest['renders'] if r['view'] == 'full' and r['variant'] == 'B')
rotation = Euler(camera['rotation'], 'XYZ').to_matrix()
right, up, back = (rotation @ Vector(v) for v in ((1,0,0),(0,1,0),(0,0,1)))
pos = Vector(camera['location'])
direction = -back
probes = [(650,200),(780,230),(590,290),(490,300),(750,330),
          (840,760),(790,800),(950,720),(680,805),
          (680,500),(760,580),(530,620),(700,470),(950,620),
          (250,570),(420,355)]
hits = []
for px, py in probes:
    origin = pos + right*((px/1280-.5)*camera['ortho_scale']) + up*((.5-py/960)*camera['ortho_scale']*.75)
    hit, loc, normal, face, obj, matrix = scene.ray_cast(graph, origin, direction)
    mat = None
    if hit and obj.type == 'MESH' and face >= 0:
        evaluated = obj.evaluated_get(graph)
        index = evaluated.data.polygons[face].material_index
        mat = obj.material_slots[index].material.name if obj.material_slots[index].material else None
    hits.append({'pixel':[px,py], 'object':obj.name if hit else None,
                 'position':list(loc) if hit else None, 'material':mat,
                 'hide_render':bool(obj.hide_render) if hit else None})
objects = []
for obj in scene.objects:
    if obj.type != 'MESH':
        continue
    mats = [s.material.name if s.material else None for s in obj.material_slots]
    if any(m and ('courtyard earth' in m or 'worked earth' in m) for m in mats):
        points = [obj.matrix_world @ Vector(v) for v in obj.bound_box]
        objects.append({'object':obj.name,'materials':mats,'hide_render':obj.hide_render,
            'visible':obj.visible_get(),'bounds':[[min(v[i] for v in points) for i in range(3)],
                                                 [max(v[i] for v in points) for i in range(3)]]})
report = {'source':bpy.data.filepath, 'method':'viewport depsgraph first-hit, alpha-unaware; sampled actual full-view pixels',
          'camera':camera,'hits':hits,'earth_objects':objects}
(OUT/'ground-ownership.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=False),flush=True)
