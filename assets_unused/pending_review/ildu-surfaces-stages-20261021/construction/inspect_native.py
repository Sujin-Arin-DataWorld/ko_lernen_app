import bpy
import collections
import json
from pathlib import Path

out = Path(__file__).resolve().parent
for gate in ['left', 'right', 'shrine']:
    bpy.ops.wm.open_mainfile(filepath=str(out.parent / (gate + '-new.blend')))
    sc = bpy.context.scene
    objs = [o for o in sc.objects if o.type == 'MESH' and not o.get('studio')]
    data = {
        'gate': gate, 'scene': sc.name,
        'camera': {'name': sc.camera.name, 'position': list(sc.camera.location),
                   'rotation': list(sc.camera.rotation_euler), 'orthoScale': sc.camera.data.ortho_scale},
        'objects': [{'name': o.name, 'owner': o.get('owner'), 'hideRender': o.hide_render,
                     'vertices': len(o.data.vertices),
                     'materials': [s.material.name if s.material else None for s in o.material_slots]}
                    for o in objs]}
    (out / (gate + '-inventory.json')).write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
    prefixes = collections.Counter('.'.join(o.name.split('.')[:3]) for o in objs)
    print(gate, len(objs), json.dumps(dict(prefixes), ensure_ascii=False), flush=True)
