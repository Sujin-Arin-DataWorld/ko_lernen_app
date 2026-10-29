"""Read-only scene inspection and optional in-memory validation; never saves a blend."""
import bpy, json, sys
from pathlib import Path
from mathutils import Vector
P = Path(__file__).resolve().parent
sys.path.insert(0, str(P))
bpy.ops.wm.open_mainfile(filepath=str(P / 'sarang-exact-r12/sarang-exact-r12.blend'))
sc = bpy.context.scene
objects = []
materials = {}
for ob in sc.objects:
    if ob.type != 'MESH':
        continue
    bounds = [ob.matrix_world @ Vector(v) for v in ob.bound_box]
    lo = [min(v[i] for v in bounds) for i in range(3)]
    hi = [max(v[i] for v in bounds) for i in range(3)]
    keep = ('numaru' in ob.name.lower() and hi[2] < 2.51 and hi[2] > 1.3) or 'broad apron' in ob.name.lower()
    if not keep:
        continue
    slots = []
    for i, slot in enumerate(ob.material_slots):
        m = slot.material
        count = sum(poly.material_index == i for poly in ob.data.polygons)
        if not m or not count:
            continue
        slots.append(dict(slot=i, faces=count, material=m.name, profile=m.get('referenceColourProfile')))
        if m.name not in materials and m.use_nodes:
            nodes = []
            for n in m.node_tree.nodes:
                row = dict(name=n.name, label=n.label, type=n.type)
                if n.type == 'VALTORGB':
                    row['ramp'] = [(e.position, list(e.color)) for e in n.color_ramp.elements]
                if n.type == 'TEX_IMAGE':
                    row['image'] = n.image.filepath if n.image else None
                if n.type == 'ATTRIBUTE':
                    row['attribute'] = n.attribute_name
                if n.type == 'MATH':
                    row.update(op=n.operation, values=[s.default_value for s in n.inputs])
                if n.type == 'VECT_MATH':
                    row.update(op=n.operation, values=[list(s.default_value) if hasattr(s.default_value, '__len__') else s.default_value for s in n.inputs])
                nodes.append(row)
            materials[m.name] = dict(nodes=nodes, links=[(l.from_node.name, l.from_socket.name, l.to_node.name, l.to_socket.name) for l in m.node_tree.links])
    objects.append(dict(name=ob.name, low=lo, high=hi, slots=slots))
report = dict(objects=objects, materials=materials)
cam = sc.camera
frame = cam.data.view_frame(scene=sc)
xs, ys = [v.x for v in frame], [v.y for v in frame]
report['pixelRays'] = []
for px, py in [(900, 838), (950, 860), (1000, 875), (1050, 885), (1120, 886), (950, 822), (1050, 862), (1180, 854)]:
    x = min(xs) + (max(xs) - min(xs)) * px / 1800
    y = min(ys) + (max(ys) - min(ys)) * (1 - py / 1200)
    origin = cam.matrix_world @ Vector((x, y, 0))
    direction = cam.matrix_world.to_quaternion() @ Vector((0, 0, -1))
    hit, loc, normal, face, ob, matrix = sc.ray_cast(bpy.context.evaluated_depsgraph_get(), origin, direction)
    if hit:
        evaluated = ob.evaluated_get(bpy.context.evaluated_depsgraph_get())
        slot = evaluated.data.polygons[face].material_index
        mat = ob.material_slots[slot].material
        report['pixelRays'].append(dict(pixel=[px, py], object=ob.name, face=face, slot=slot, location=list(loc), material=mat.name, profile=mat.get('referenceColourProfile')))
if '--validate' in sys.argv:
    import wood_review_refine_r12
    report['validation'] = wood_review_refine_r12.apply(sc)
    second = wood_review_refine_r12.apply(sc)
    assert second['changedSlots'] == 0
    report['validation']['idempotencyVerified'] = True
    (P / 'wood-review-refine-r12-receipt.json').write_text(json.dumps(report['validation'], ensure_ascii=False, indent=2), encoding='utf-8')
(P / 'wood-review-diagnostic-r12.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
print('WOOD_REVIEW_DIAGNOSTIC', len(objects), len(materials), report.get('validation', {}).get('changedSlots'), flush=True)
