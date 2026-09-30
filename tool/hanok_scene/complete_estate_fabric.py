"""Review-only 002 wall network and the small rear toilet.

This builds on the Sep 29 detail scene. Existing building geometry is preserved;
unfinished outbuildings receive continuous timber and plaster material mapping.
"""
from pathlib import Path
import bpy
import hashlib
import json
import math
import random
import re
import sys
from types import SimpleNamespace

import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).parent))
from register_site002 import to_pixel, to_world
from northern_mineral_surfaces import apply_mineral_surfaces
from refine_northern_materials import apply_craft_surfaces, geometry_fingerprint
from repair_masonry_coping import fingerprint, TIMBER_SUFFIXES
import canonical_surface_reuse as art
from estate_earth_and_gardens import add_gardens, soften_earth
from align_warehouse_wall import align_warehouse_wall
from apply_gye_estate_style import apply_estate_style
from apply_plaster_wash_register import apply_plaster_wash_register
from apply_stone_pigment_register import apply_stone_pigment_register
from apply_building_wood_register import apply_building_wood_register
from apply_roof_palette_register import apply_roof_palette_register
from apply_estate_matte_register import apply_estate_matte_register
from apply_shrine_gable_art import apply_shrine_gable_art
from apply_timber_arris import apply_timber_arris, write_detail_cameras
from apply_heritage_wood import apply_heritage_wood
from apply_platform_stone import apply_platform_stone
from repair_gokgan_clearance import repair_gokgan_clearance

sys.path.insert(0, 'C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-warm-stone-20260923/tool/hanok_scene')
import reconstruction_geometry as g

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
SOURCE = OUT / 'detail-redraw.blend'
TARGET = OUT / 'estate-fabric.blend'
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()


def smooth(t):
    t = max(0., min(1., t))
    return t * t * (3 - 2 * t)


def ground(x, y):
    # Same continuous approved court function as build_side_connections.py.
    west = .6 * smooth(y / 3.9) + .68 * smooth((y - 11.4) / 3.825)
    east = (1.2 + .3 * smooth((y - 5.2) / 3)) * smooth((y - .5) / 4.6)
    z = west + (east - west) * smooth((x + .3) / 3)
    west_patch = (1 - smooth((x + 6.0) / 3.5)) * smooth((y + 6.5) / 2) * (1 - smooth((y - 10.7) / 2.4))
    z = z * (1 - west_patch) + .6 * west_patch
    east_patch = smooth((x - 15.8) / 1.1) * (1 - smooth((x - 29) / 4)) * (1 - smooth((y - 3.4) / 4.4)) * smooth((y + 21) / 3)
    local = min(.72, .12 * smooth((x - 19) / 2) + .72 * smooth((y - .083 + .6) / 1.2))
    return z * (1 - east_patch) + local * east_patch


# Only stone/tile courses drawn on 002 are reconstructed. Existing forecourt
# and Byeoldang enclosure runs remain the authority wherever the new tracing
# would overlap them.
def join_heights(start_px, stop_px, start_top, stop_top):
    a, b = to_world([start_px, stop_px])
    return (start_top - ground(*a), stop_top - ground(*b))


ROUTES = [
    ('northwest road wall', (490, 457), (915, 527), 1.26),
    ('northwest field wall', (343, 509), (490, 457), 1.26),
    ('west field wall', (343, 509), (530, 1260), 1.26),
    ('west field south return', (530, 1260), (742, 1285), 1.26),
    ('west estate edge', (742, 1285), (742, 1884), 1.27),
    ('south edge west', (742, 1884), (1117, 1898), 1.27),
    ('south edge middle', (1117, 1898), (1439.7, 1904.0),
     join_heights((1117, 1898), (1439.7, 1904.0), ground(*to_world([[1117, 1898]])[0]) + 1.27, 1.72)),
    ('road behind shrine', (915, 527), (915, 779), 1.31),
    ('shrine gwang join', (1158, 814), (1169, 818),
     join_heights((1158, 814), (1169, 818), 2.85, 2.62)),
    ('gwang byeoldang join', (1396, 857), (1484.0464, 836.5195),
     join_heights((1396, 857), (1484.0464, 836.5195), 2.62, 2.24)),
    # The earlier Byeoldang enclosure already supplies the long rear/east
    # perimeter. Rebuilding it produced the two parallel rows the user saw.
    ('jung to gotgan boundary', (1093, 1414), (1128, 1616), 1.22),
    ('jung building tie', (1093, 1414), (1111, 1416), 1.22),
    ('gotgan rear boundary', (1128, 1616), (1117, 1898), 1.22),
    ('gotgan garden return', (1128, 1616), (1192, 1617), 1.22),
    ('toilet1 outer return', (742, 1658), (834, 1658), 1.22),
    ('toilet1 west', (834, 1658), (834, 1557), 1.22),
    ('toilet1 short north', (834, 1557), (887, 1557), 1.22),
    ('toilet1 east', (914, 1558), (914, 1658), 1.22),
    ('toilet1 south', (834, 1658), (914, 1658), 1.22),
]


def copy_small_toilet(scene):
    source = [o for o in scene.objects if o.type == 'MESH' and o.get('construction_building') == 'toilet']
    assert len(source) == 78, 'The canonical-style toilet donor changed'
    centre = Vector((-18.51592333, -6.99680783, 0))
    point = to_world([[872, 1605]])[0]
    target = Vector((float(point[0]), float(point[1]), ground(*point)))
    # The donor roof axis already follows the long axis of #11 on 002.  Its
    # off-centre boarded door faces the enclosure passage.  One small unit is
    # intentional under the user's latest simplification.
    copied = []
    for ob in source:
        new = ob.copy()
        new.data = ob.data.copy()
        new.name = ob.name.replace('.toilet.', '.toilet1.')
        scene.collection.objects.link(new)
        # Keep the human-size 1.85 m doorway. Only the footprint and the roof
        # above the wall plate are reduced; uniform scaling made a toy door.
        new.matrix_world = Matrix.Identity(4)
        for src, dst in zip(ob.data.vertices, new.data.vertices):
            p = ob.matrix_world @ src.co
            z = p.z if p.z <= 2.52 else 2.52 + (p.z - 2.52) * .66
            dst.co = (target.x + .85 * (p.x - centre.x), target.y + .85 * (p.y - centre.y), target.z + z)
        new.data.update()
        new['construction_building'] = 'toilet1'
        # A distinct source name keeps the #12 door hinge control from
        # accidentally attaching this copied leaf to the front toilet pivot.
        new['source_object_name'] = new.name
        new['site002PlanNumber'] = 11
        new['sourceCanonical'] = 'assets_unused/pending_review/personal_hanok_v3/화장실.png'
        new.hide_render = False
        copied.append(new)
    return {'id': 'toilet1', 'site002PlanNumber': 11, 'sourcePixelCentre': [872, 1605],
            'center': list(map(float, point)), 'ground': float(target.z), 'planarScaleFromToilet2': .85,
            'entryHeightMeters': 1.85, 'roofVerticalScaleAboveWallPlate': .66,
            'meshes': len(copied), 'canonicalStyle': 'assets_unused/pending_review/personal_hanok_v3/화장실.png',
            'formStatus': 'One small review interpretation; 002 gives location, 2007 table lists two front bays but user requested a small single unit.'}


def add_fieldstone_courses(name, length, height, material, half_width=.216):
    """Leave varied ochre joints between individual, uneven fieldstones."""
    count = 0
    widths = []
    for side in (-1, 1):
        rng = random.Random(f'{name}:{side}')
        bottom = 0.
        while bottom < height - .025:
            course = rng.uniform(.20, .30) if bottom < .025 else rng.uniform(.17, .27)
            if height - bottom - course < .09:
                course = height - bottom
            x = 0.
            while x < length - .025:
                remaining = length - x
                width = min(remaining, rng.uniform(.29, .72) if bottom < .025 else rng.uniform(.20, .59))
                if remaining - width < .105:
                    width = remaining
                if width > .115:
                    rise = min(course * rng.uniform(.76, .96), height - bottom - .012)
                    center = min(height - rise / 2 - .006,
                                 max(rise / 2 + .006, bottom + course / 2 + rng.uniform(-.019, .019)))
                    g.rock(name + '.uneven fieldstone',
                           (x + width / 2, side * half_width, center),
                           (max(.09, width - .019), rng.uniform(.085, .117), rise), material, rng)
                    widths.append(width)
                    count += 1
                x += width
            bottom += course
    return {'stones': count, 'widthRangeMeters': [round(min(widths), 3), round(max(widths), 3)]}


def add_wall(name, start_px, stop_px, height, materials, *, world_route=None,
             base_elevation=None, prefix='Estate.fabric.', floral_plinth_only=False):
    start, stop = to_world([start_px, stop_px]) if world_route is None else world_route
    start, stop = np.asarray(start), np.asarray(stop)
    length = float(np.linalg.norm(stop - start))
    assert length > .3
    angle = math.atan2(stop[1] - start[1], stop[0] - start[0])
    co, si = math.cos(angle), math.sin(angle)
    start_height, stop_height = ((float(height), float(height))
                                 if isinstance(height, (int, float)) else map(float, height))
    assert start_height > 0 and stop_height > 0

    def world(p):
        x = float(start[0] + co * p[0] - si * p[1])
        y = float(start[1] + si * p[0] + co * p[1])
        t = max(0., min(1., p[0] / length))
        local_height = start_height + (stop_height - start_height) * t
        base = ground(x, y) if base_elevation is None else base_elevation
        return (x, y, base + p[2] * local_height / start_height)

    g.set_transform(world)
    nm = prefix + name
    core, stone, tiles, ends = materials
    if floral_plinth_only:
        return add_fieldstone_courses(nm, length, start_height, stone, half_width=.188)
    # Match the accepted forecourt's 400 mm fieldstone wall profile.
    g.box(nm + '.earth core', (length / 2, 0, start_height / 2),
          (length + .04, .40, start_height), core)
    masonry = add_fieldstone_courses(nm, length, start_height, stone)
    # Copy the existing fieldstone-wall tile rhythm, without the building roof
    # helper's exposed rafters or different pitch.
    count = max(2, math.ceil(length / .195))
    for i in range(count):
        x = (i + .5) * length / count
        for side in (-1, 1):
            for k in range(8):
                a = -math.pi / 2 + k * math.pi / 8
                b = a + math.pi / 8
                pan = lambda t, y: (x + .101 * math.sin(t), side * y,
                                    start_height + .065 + .065 * (1 - y / .31) - .028 * math.cos(t))
                g.face(nm + '.pan', [pan(a, 0), pan(b, 0), pan(b, .31), pan(a, .31)], tiles)
                a = k * math.pi / 8
                b = a + math.pi / 8
                cover = lambda t, y: (x + .099 + .043 * math.cos(t), side * y,
                                      start_height + .09 + .065 * (1 - y / .32) + .043 * math.sin(t))
                g.face(nm + '.cover', [cover(a, 0), cover(b, 0), cover(b, .32), cover(a, .32)], tiles)
            g.rod(nm + '.tile ends', (x + .099, side * .318, start_height + .108),
                  (x + .099, side * .338, start_height + .108), .034, ends, 16)
        for level in range(3):
            g.rod(nm + '.ridge', (x - length / count * .5, 0, start_height + .18 + level * .043),
                  (x + length / count * .5, 0, start_height + .18 + level * .043), .038, tiles, 12)
    return {'name': name, 'sourcePixelStart': list(start_px), 'sourcePixelStop': list(stop_px),
            'start': start.tolist(), 'stop': stop.tolist(),
            'heightStart': start_height, 'heightStop': stop_height,
            'masonry': masonry,
            'authority': '2007 plan 002 centreline, tied to retained walls; height and individual stones are photographic interpretations'}


def harmonize_north_walls(scene, materials):
    """Use the same rubble profile on pale northern runs; keep shrine petals."""
    source = json.loads((OUT / 'detail-redraw-contract.json').read_text(encoding='utf8'))
    removed = []
    flower_ornaments = []
    report = []
    for spec in source['walls']:
        stem = 'North.site.' + spec['name']
        if spec['floral']:
            old = [o for o in scene.objects if o.name.startswith(stem + ' irregular stone')]
            flower_ornaments.extend(o.name for o in scene.objects
                                    if o.name.startswith(stem + ' inset '))
        else:
            old = [o for o in scene.objects if o.name.startswith(stem + ' ')]
        assert old, f'Expected pale wall meshes: {stem}'
        removed.extend(o.name for o in old)
        for ob in old:
            bpy.data.objects.remove(ob, do_unlink=True)
        start, stop = np.asarray(spec['start']), np.asarray(spec['stop'])
        masonry = add_wall(spec['name'], spec['start'], spec['stop'],
                           .52 if spec['floral'] else spec['height'], materials,
                           world_route=(start, stop), base_elevation=spec['base'],
                           prefix='North.site.', floral_plinth_only=spec['floral'])
        report.append({'name': spec['name'], 'floral': spec['floral'],
                       'stoneVariation': masonry if spec['floral'] else masonry['masonry']})
    return {'replacedObjects': removed, 'preservedFlowerOrnaments': flower_ornaments,
            'segments': report, 'reference': 'Current HTML dark ochre rubble wall; shrine floral plaster and petals remain'}


def photo_materials(scene):
    scope = ('arae', 'angotgan', 'gokgan', 'changgo')
    targets = [o for o in scene.objects if o.type == 'MESH' and o.get('construction_building') in scope]
    for ob in targets:
        ob.data = ob.data.copy()
    timber = apply_craft_surfaces(scene, scope=scope)
    art.ART = ROOT / 'assets_unused/pending_review/personal_hanok_v3/화장실.png'
    art.base_image = bpy.data.images.load(str(art.ART), check_existing=True)
    art.materials = {}
    art.mapped = []
    art.regions = {'plaster': [(.375, .51, .44, .67)]}
    plaster = []
    for ob in targets:
        used = [ob.data.materials[i] for i in {p.material_index for p in ob.data.polygons}]
        if used and all(m and 'lime plaster' in m.name.lower() for m in used):
            art.art_uv(ob, 'plaster')
            plaster.append(ob.name)
    warehouse = canonical_warehouse_timbers(scene)
    return {'buildings': list(scope), 'timberMeshes': timber, 'plasterMeshes': plaster,
            'warehouseCanonicalTimber': warehouse,
            'woodAuthority': 'Existing illustrated pine surface with grain aligned to each solid member and separate end grain',
            'plasterAuthority': 'Unedited canonical toilet plaster pigment, applied only to unfinished outbuilding lime panels',
            'photoComparison': 'Naver 2013 and 2026 photos show grey-brown aged wood, visible fibres and warm uneven plaster; the prior narrow repeated dark stripes are replaced'}


def canonical_warehouse_timbers(scene):
    """Map the approved six-door art to complete door bays and solid timbers.

    The legacy native shader uses a crop of this image via vector nodes. glTF
    ignores that graph and repeats the entire facade on each board. Mapping a
    tiny wood swatch to each board removed that bug but lost the door design.
    The door fields now share one UV frame per bay; iron remains a solid mesh.
    """
    source = ROOT / 'assets/illustrations/personal_hanok_v3/construction/changgo/stage_08_complete.png'
    art.ART = source
    art.base_image = bpy.data.images.load(str(source), check_existing=True)
    art.materials = {}
    art.mapped = []
    width, height = art.base_image.size
    def rect(x0, y0, x1, y1):
        return (x0 / width, y0 / height, x1 / width, y1 / height)
    art.regions = {
        'wood': [rect(a, 935, b, 1100) for a, b in
                 ((230, 297), (567, 632), (907, 970), (1246, 1307),
                  (1587, 1650), (1928, 1990))],
        'post': [rect(a, 781, b, 1110) for a, b in
                 ((477, 518), (1133, 1176), (1854, 1894))],
        'beam': [rect(a, 838, b, 865) for a, b in
                 ((206, 448), (536, 778), (878, 1110), (1212, 1450))],
    }
    door_name = re.compile(r'bay([1-6])\.leaf[12]\.boards(?:\.\d+)?$')
    door_objects = {}
    for ob in scene.objects:
        if ob.type != 'MESH' or ob.get('construction_building') != 'changgo':
            continue
        match = door_name.search(ob.name.lower())
        if match and ob.data.materials and ob.data.materials[0].name.startswith('V31 changgo source timber '):
            door_objects.setdefault(int(match.group(1)), []).append(ob)
    assert len(door_objects) == 6 and all(len(part) == 8 for part in door_objects.values()), 'Warehouse twelve-leaf geometry changed'
    # Six fields from the approved 2736 x 1536 illustration. These include
    # the painted rails and worn plank faces, instead of a repeated narrow
    # vertical strip. The original pixel data is neither recolored nor baked.
    door_pixels = {bay: (left - 80, 870, left + 250, 1200)
                   for bay, left in enumerate((230, 567, 907, 1246, 1587, 1928), 1)}
    door_bounds = {}
    for bay, parts in door_objects.items():
        points = [ob.matrix_world @ vertex.co for ob in parts for vertex in ob.data.vertices]
        door_bounds[bay] = (min(p.y for p in points), max(p.y for p in points),
                            min(p.z for p in points), max(p.z for p in points))

    def map_door(ob, bay):
        before = geometry_fingerprint(ob)
        mesh = ob.data
        uv = mesh.uv_layers.get('Canonical gate pigment') or mesh.uv_layers.new(name='Canonical gate pigment')
        side0, side1, bottom, top = door_bounds[bay]
        x0, y0, x1, y1 = door_pixels[bay]
        for poly in mesh.polygons:
            for li in poly.loop_indices:
                point = ob.matrix_world @ mesh.vertices[mesh.loops[li].vertex_index].co
                across = max(0., min(1., (point.y - side0) / (side1 - side0)))
                upward = max(0., min(1., (point.z - bottom) / (top - bottom)))
                uv.data[li].uv = ((x0 + across * (x1 - x0)) / width,
                                   1 - (y1 - upward * (y1 - y0)) / height)
        mesh.uv_layers.active = uv
        uv.active_render = True
        for attr in list(mesh.color_attributes):
            mesh.color_attributes.remove(attr)
        mesh.materials.clear()
        mesh.materials.append(art.pigment('door'))
        assert geometry_fingerprint(ob) == before, 'Warehouse door geometry changed'
        ob['canonicalWarehouseTimber'] = True
        ob['canonicalWarehouseDoorBay'] = bay

    mapped = []
    for ob in scene.objects:
        if ob.type != 'MESH' or ob.get('construction_building') != 'changgo':
            continue
        if not ob.data.materials or not ob.data.materials[0].name.startswith('V31 changgo source timber '):
            continue
        match = door_name.search(ob.name.lower())
        if match:
            bay = int(match.group(1))
            map_door(ob, bay)
            mapped.append({'object': ob.name, 'kind': 'door', 'bay': bay})
            continue
        before = geometry_fingerprint(ob)
        name = ob.name.lower()
        kind = ('post' if any(k in name for k in ('frame.post', 'king post', 'gable upright'))
                else 'beam' if any(k in name for k in ('beam', 'rail', 'rafter', 'fascia',
                                                       'brace', 'tie', 'lintel', 'bracket',
                                                       'sill', 'eave', 'threshold'))
                else 'wood')
        art.art_uv(ob, kind)
        assert geometry_fingerprint(ob) == before, 'Warehouse geometry changed'
        ob['canonicalWarehouseTimber'] = True
        mapped.append({'object': ob.name, 'kind': kind})
    for kind, mat in art.materials.items():
        mat.name = 'Warehouse approved illustration ' + kind
        mat['surfaceAuthority'] = 'Approved six-door changgo art, continuous door fields and clean wood regions on solid members'
    return {'source': str(source), 'sha256': sha(source), 'mappedMeshes': mapped,
            'doorLeaves': 12, 'sourceImageUnchanged': True,
            'doorFieldPixels': door_pixels, 'doorFieldUv': 'Shared world-space frame per bay; no repeated facade on each plank',
            'geometryUnchanged': True}


def add_paths(stone):
    # The stones are centred on the dotted approach on 002. Their individual
    # outlines and wear are interpretations supported by photos 7695/IMG_0975.
    paths = [[(1494, 1356), (1566, 1500)], [(1200, 1472), (1566, 1508)],
             [(899, 1547), (902, 1593), (892, 1607)]]
    g.BATCHES.clear()
    g.set_transform(lambda p: p)
    rng = random.Random(20260929)
    count = 0
    for pi, path in enumerate(paths):
        for pa, pb in zip(path, path[1:]):
            a, b = to_world([pa, pb])
            length = float(np.linalg.norm(b - a))
            count_segment = max(1, round(length / .68))
            for i in range(count_segment):
                x, y = a + (b - a) * ((i + .5) / count_segment)
                g.rock('Estate.path.worn stepping stones', (float(x), float(y), ground(x, y) + .018),
                       (rng.uniform(.37, .52), rng.uniform(.32, .47), .085), stone, rng)
                count += 1
    obs = g.flush()
    g.BATCHES.clear()
    for ob in obs:
        ob['construction_building'] = 'estate_path'
        ob['northExtension'] = True
        ob['source_object_name'] = ob.name
    return obs, {'sourcePixelPaths': paths, 'stoneCount': count,
                 'authority': '002 approach centreline; individual stones are photo-informed interpretations'}


def extend_terrain(scene):
    terrain = bpy.data.objects['ConnectionSite.continuous earth']
    coords = np.asarray([v.co[:] for v in terrain.data.vertices])
    xmin, ymin = coords[:, :2].min(0)
    xmax, ymax = coords[:, :2].max(0)
    wall_points = to_world([p for route in ROUTES for p in route[1:3]])
    wanted_y = float(wall_points[:, 1].max()) + 2
    if wanted_y <= ymax:
        return None
    xs = sorted(set(float(p) for p in coords[:, 0]))
    ys = np.linspace(ymax, wanted_y, max(2, math.ceil(wanted_y - ymax) + 1))
    vertices = [(x, float(y), ground(x, y)) for y in ys for x in xs]
    faces = []
    for j in range(len(ys) - 1):
        for i in range(len(xs) - 1):
            a = j * len(xs) + i
            faces.extend([(a, a + 1, a + 1 + len(xs)), (a, a + 1 + len(xs), a + len(xs))])
    mesh = bpy.data.meshes.new('Estate edge terrain beyond original court')
    mesh.from_pydata(vertices, [], faces)
    mesh.materials.append(terrain.data.materials[0])
    for p in mesh.polygons:
        p.use_smooth = True
    ob = bpy.data.objects.new('Estate.site.west field ground extension', mesh)
    scene.collection.objects.link(ob)
    ob['construction_building'] = 'site'
    ob['source_object_name'] = ob.name
    return {'previousYMax': float(ymax), 'newYMax': wanted_y,
            'existingTerrainVerticesChanged': 0, 'overlapWithExistingTerrainArea': 0}


def main():
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
    scene = bpy.context.scene
    # The original gate-to-Ansarang return and independent Byeoldang enclosure
    # form one continuous, accepted perimeter. The duplicate is in ROUTES.
    retained = [o.name for o in scene.objects if o.name.startswith('Forecourt.wall.gate-ansarang.1.')]
    assert retained, 'Expected original gate-to-Ansarang boundary was not found'
    clay = bpy.data.materials['Forecourt ochre lime mortar']
    stone = bpy.data.materials['North anchae stone']
    ends = bpy.data.materials['Forecourt aged lime tile ends']
    tiles = bpy.data.materials['Ansarang retained V33 main_gate source ceramic 2']
    materials = (clay, stone, tiles, ends)
    g.BATCHES.clear()
    harmonized = harmonize_north_walls(scene, materials)
    warehouse_wall_alignment = align_warehouse_wall(scene)
    old = {o.name: geometry_fingerprint(o) for o in scene.objects if o.type == 'MESH'}
    protected = {o.name: fingerprint(o) for o in scene.objects if o.type == 'MESH' and o.get('construction_building') not in ('arae', 'angotgan', 'gokgan', 'changgo') and o.name != 'ConnectionSite.continuous earth'}
    toilet = copy_small_toilet(scene)
    walls = [add_wall(*route, materials) for route in ROUTES]
    new_walls = g.flush()
    g.BATCHES.clear()
    g.set_transform(lambda p: p)
    for ob in new_walls:
        ob['construction_building'] = 'north_site' if ob.name.startswith('North.site.') else 'estate_wall'
        ob['source_object_name'] = ob.name
        ob['site002PlanNumber'] = 0
        ob['construction_first'] = 1
        ob['construction_last'] = 99
        ob['northExtension'] = True
    art.ART = ROOT / 'assets_unused/pending_review/personal_hanok_v3/hyeopmun_try03_blueprint_colored.png'
    art.base_image = bpy.data.images.load(str(art.ART), check_existing=True)
    art.materials = {}
    art.mapped = []
    art.regions = {'stone': [(.192, .728, .286, .756), (.391, .786, .498, .810),
                             (.620, .795, .690, .821)]}
    for ob in new_walls:
        if ob.name.endswith('.uneven fieldstone'):
            art.art_uv(ob, 'stone')
        elif ob.data.materials[0] == tiles:
            mesh = ob.data
            uv = mesh.uv_layers.new(name='Ansarang retained PBR')
            for poly in mesh.polygons:
                axes = [a for a in range(3) if a != int(np.argmax(np.abs(poly.normal)))]
                for li in poly.loop_indices:
                    uv.data[li].uv = np.array(mesh.vertices[mesh.loops[li].vertex_index].co)[axes] / .8
            uv.active_render = True
            attr = mesh.color_attributes.new(name='Craft tonal variation', type='FLOAT_COLOR', domain='CORNER')
            for item in attr.data:
                item.color = (1, 1, 1, 1)
    path_objects, paths = add_paths(stone)
    minerals = apply_mineral_surfaces(SimpleNamespace(objects=path_objects))
    surfaces = photo_materials(scene)
    terrain_extension = extend_terrain(scene)
    gardens = add_gardens(scene, to_world, ground)
    earth = soften_earth(scene, OUT / 'materials', to_world, {}, ROUTES)
    assert all(geometry_fingerprint(bpy.data.objects[name]) == value for name, value in old.items()), 'Existing building geometry changed'
    assert all(fingerprint(bpy.data.objects[name]) == value for name, value in protected.items()), 'Protected building surface changed'
    gye_style = apply_estate_style(scene)
    timber_register = apply_building_wood_register(scene)
    roof_palette = apply_roof_palette_register(scene)
    plaster_wash = apply_plaster_wash_register(scene)
    stone_pigment = apply_stone_pigment_register(scene)
    matte_surface = apply_estate_matte_register(scene)
    shrine_gable = apply_shrine_gable_art(scene)
    timber_arris = apply_timber_arris(scene)
    write_detail_cameras(timber_arris)
    gokgan_clearance = repair_gokgan_clearance(scene, OUT)
    heritage_wood = apply_heritage_wood(scene, OUT)
    platform_stone = apply_platform_stone(scene)
    report = {'sourceSceneSha256': sha(SOURCE), 'site002Sha256': sha(OUT.parent / 'side-connections/site002.jpg'),
              'nativeCandidate': TARGET.name, 'toilet1': toilet, 'toilet2PreservedMeshes': 78,
              'originalGeometryMeshesPreserved': len(old), 'protectedSurfaceMeshes': len(protected),
              'wallMeshCount': len(new_walls), 'wallRoutes': walls, 'harmonizedWalls': harmonized,
              'mineralSurfaces': minerals,
              'outbuildingSurfaces': surfaces, 'paths': paths, 'terrainExtension': terrain_extension,
              'retainedGateAnsarangWallObjects': retained,
              'warehouseWallAlignment': warehouse_wall_alignment,
              'removedDuplicateRoutes': ['byeoldang rear', 'byeoldang east', 'byeoldang garden south'],
              'removedIsolatedRoute': 'road court division and redundant Byeoldang rear/east tracing',
              'gardens': gardens, 'earthSurface': earth, 'gyeStylePass': gye_style,
              'gyeTimberRegister': timber_register,
              'gyeRoofPalette': roof_palette,
              'gyePlasterWash': plaster_wash,
              'gyeStonePigment': stone_pigment,
              'gyeMatteSurface': matte_surface,
              'gyeShrineGable': shrine_gable,
              'gyeTimberArris': timber_arris,
              'gokganRearClearance': gokgan_clearance,
              'gyeHeritageWood': heritage_wood,
              'gyePlatformStone': platform_stone,
              'blogReferences': [
                  {'url': 'https://blog.naver.com/mijuko/224423105270', 'photos': '2013-11-12 watermark; published 2026-09-26', 'usedFor': 'weathered wood, rough stone and tile coping'},
                  {'url': 'https://blog.naver.com/tree_onetwothreefour/224292534177', 'photos': 'published 2026-05-21', 'usedFor': 'courtyard aging and small service-building vocabulary, identity of #11 unverified'}],
              'runtimePromotion': False}
    bpy.ops.wm.save_as_mainfile(filepath=str(TARGET), compress=True)
    report['candidateSceneSha256'] = sha(TARGET)
    projection_file = OUT / 'estate-plan-projection.json'
    if projection_file.exists():
        projection = json.loads(projection_file.read_text(encoding='utf8'))
        old_centre = to_pixel([[-18.51592333, -6.99680783]])[0]
        projection['toilet1'] = {
            key: [[round(872 + .85 * (p[0] - old_centre[0]), 3),
                   round(1605 + .85 * (p[1] - old_centre[1]), 3)] for p in polygon]
            for key, polygon in projection['toilet'].items() if key in ('roof', 'posts')
        }
        projection_file.write_text(json.dumps(projection, ensure_ascii=False, indent=2), encoding='utf8')
    (OUT / 'estate-fabric-contract.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf8')
    print('ESTATE FABRIC COMPLETE', toilet['meshes'], len(new_walls), len(walls), flush=True)


def refresh_garden_clearance():
    """Rebuild only garden bases after reviewing the gate route on 002."""
    bpy.ops.wm.open_mainfile(filepath=str(TARGET))
    for ob in list(bpy.context.scene.objects):
        if ob.name.startswith('Estate.garden.'):
            bpy.data.objects.remove(ob, do_unlink=True)
    report_path = OUT / 'estate-fabric-contract.json'
    report = json.loads(report_path.read_text(encoding='utf8'))
    report['gardens'] = add_gardens(bpy.context.scene, to_world, ground)
    bpy.ops.wm.save_as_mainfile(filepath=str(TARGET), compress=True)
    report['candidateSceneSha256'] = sha(TARGET)
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf8')
    print('GARDEN GATE CLEARANCE UPDATED', flush=True)


if __name__ == '__main__':
    if '--garden-only' in sys.argv:
        refresh_garden_clearance()
    else:
        main()
