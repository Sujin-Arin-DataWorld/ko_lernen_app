"""Separate illustrated 3D garden behind the shrine, for local art review.

The historic shrine, its wall, paths and doors stay untouched. This interprets
the approved Gye pavilion/garden vocabulary as native low-poly geometry.
"""
from pathlib import Path
import hashlib
import json
import math
import random
import sys

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).parent))
from apply_gye_estate_style import linear_hex


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
TARGET = OUT / 'estate-fabric.blend'
CENTRE = (35.6, 20.8)


def material(name, color, *, emission=0):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.node_tree.nodes.clear()
    shader = mat.node_tree.nodes.new('ShaderNodeBsdfPrincipled')
    shader.inputs['Base Color'].default_value = (*linear_hex(color), 1)
    shader.inputs['Roughness'].default_value = .9
    shader.inputs['Specular IOR Level'].default_value = .15
    if emission:
        shader.inputs['Emission Color'].default_value = (*linear_hex(color), 1)
        shader.inputs['Emission Strength'].default_value = emission
    output = mat.node_tree.nodes.new('ShaderNodeOutputMaterial')
    mat.node_tree.links.new(shader.outputs['BSDF'], output.inputs['Surface'])
    mat['visualAuthority'] = 'Gye pavilion and garden illustration; interpreted as distinct rear 3D extension'
    return mat


class Builder:
    def __init__(self, scene, ground):
        self.scene = scene
        self.ground = ground
        self.objects = []
        self.counts = {}
        self.materials = {
            'tile': [material('Gye garden warm ink tile ' + str(i), color)
                     for i, color in enumerate(('#474A42', '#50534A', '#595B50', '#626358', '#45483F'))],
            'wood': [material('Gye garden aged chestnut ' + str(i), color)
                     for i, color in enumerate(('#5D3C27', '#71492B', '#80532D', '#6B4930', '#90613D'))],
            'stone': [material('Gye garden chipped stone ' + str(i), color)
                      for i, color in enumerate(('#736C5C', '#8E8370', '#A79B84', '#B4A88F', '#665F51'))],
            'soil': [material('Gye garden worked soil ' + str(i), color)
                     for i, color in enumerate(('#A79578', '#B19F82', '#BAAA8D', '#9C8D74'))],
            'pine': [material('Gye garden pine needle ' + str(i), color)
                     for i, color in enumerate(('#515A49', '#606950', '#737A5C', '#454F42'))],
            'plum': [material('Gye garden plum petal ' + str(i), color)
                     for i, color in enumerate(('#C98583', '#E8ACA8', '#F0C6B8', '#B96C73'))],
            'flower': [material('Gye garden chrysanthemum ' + str(i), color)
                       for i, color in enumerate(('#BE843E', '#D6A34F', '#E6BD68', '#9D6B34'))],
            'paint': [material('Gye garden dancheong ' + str(i), color)
                      for i, color in enumerate(('#385B4B', '#926337', '#B6823E', '#4B6D5A'))],
            'paper': [material('Gye garden lantern paper', '#DFA951', emission=1.35)],
        }

    def mesh(self, name, vertices, faces, materials, indices=None):
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(vertices, [], faces)
        mesh.update()
        for mat in materials:
            mesh.materials.append(mat)
        for index, polygon in enumerate(mesh.polygons):
            polygon.material_index = indices[index] if indices else 0
            polygon.use_smooth = False
        ob = bpy.data.objects.new('GyeGarden.' + name, mesh)
        self.scene.collection.objects.link(ob)
        ob['construction_building'] = 'gye_garden'
        ob['source_object_name'] = ob.name
        ob['artInterpretation'] = True
        self.objects.append(ob.name)
        self.counts[name.split('.')[0]] = self.counts.get(name.split('.')[0], 0) + 1
        return ob

    def prism(self, name, centre, radius, bottom, top, sides, materials, *, seed=0, wobble=0):
        rng = random.Random(seed)
        angle0 = math.pi / sides
        ring = [(centre[0] + radius * (1 + rng.uniform(-wobble, wobble)) * math.cos(angle0 + 2 * math.pi * i / sides),
                 centre[1] + radius * (1 + rng.uniform(-wobble, wobble)) * math.sin(angle0 + 2 * math.pi * i / sides))
                for i in range(sides)]
        vertices = [(x, y, bottom) for x, y in ring] + [(x, y, top) for x, y in ring]
        faces = [tuple(range(sides, 2 * sides)), tuple(reversed(range(sides)))]
        faces += [(i, (i + 1) % sides, (i + 1) % sides + sides, i + sides) for i in range(sides)]
        indices = [min(1, len(materials) - 1), 0] + [rng.randrange(len(materials)) for _ in range(sides)]
        return self.mesh(name, vertices, faces, materials, indices)

    def beam(self, name, a, b, width, height, mat):
        a, b = Vector(a), Vector(b)
        axis = b - a
        normal = Vector((-axis.y, axis.x, 0)).normalized() * width / 2
        vertical = Vector((0, 0, height / 2))
        vertices = [tuple(point) for origin in (a, b)
                    for point in (origin - normal - vertical, origin + normal - vertical,
                                  origin + normal + vertical, origin - normal + vertical)]
        faces = [(0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1), (1, 5, 6, 2),
                 (2, 6, 7, 3), (3, 7, 4, 0)]
        return self.mesh(name, vertices, faces, [mat])

    def tube(self, name, a, b, radius, mat, sides=7):
        a, b = Vector(a), Vector(b)
        axis = (b - a).normalized()
        across = axis.cross(Vector((0, 0, 1)))
        if across.length < .1:
            across = axis.cross(Vector((0, 1, 0)))
        across.normalize()
        other = axis.cross(across).normalized()
        vertices = [tuple(point + radius * (across * math.cos(2 * math.pi * i / sides) +
                                          other * math.sin(2 * math.pi * i / sides)))
                    for point in (a, b) for i in range(sides)]
        faces = [tuple(reversed(range(sides))), tuple(range(sides, 2 * sides))]
        faces.extend((i, (i + 1) % sides, (i + 1) % sides + sides, i + sides)
                     for i in range(sides))
        return self.mesh(name, vertices, faces, [mat])

    def foliage_cloud(self, name, centre, radii, materials, seed, *, points=14):
        rng = random.Random(seed)
        cx, cy, cz = centre
        rx, ry, rz = radii
        outer = []
        for i in range(points):
            angle = 2 * math.pi * i / points
            spread = rng.uniform(.85, 1.17)
            outer.append((cx + rx * spread * math.cos(angle),
                          cy + ry * spread * math.sin(angle),
                          cz + rng.uniform(-.12, .12) * rz))
        vertices = outer + [(cx - .09 * rx, cy + .08 * ry, cz + rz),
                            (cx + .12 * rx, cy - .05 * ry, cz - rz)]
        faces = []
        indices = []
        for i in range(points):
            nxt = (i + 1) % points
            faces.extend(((points, i, nxt), (points + 1, nxt, i)))
            indices.extend((rng.randrange(len(materials)), rng.randrange(len(materials))))
        return self.mesh(name, vertices, faces, materials, indices)


def garden_ground(builder):
    rng = random.Random(2030)
    # Small planted pockets let the approved continuous courtyard ground stay
    # visible. The earlier single dark disk looked like a digital platform.
    for name, (cx, cy), (rx, ry) in (
        ('pine', (31.4, 24.2), (2.48, 2.03)),
        ('plum', (39.1, 18.2), (2.20, 2.75)),
        ('chrysanthemum', (38.45, 22.75), (1.38, 1.40)),
    ):
        segments = 23
        edge = [rng.uniform(.88, 1.08) for _ in range(segments)]
        vertices = [(cx, cy, builder.ground(cx, cy) + .018)]
        for ring, scale in enumerate((.48, .76, 1.0)):
            for i in range(segments):
                angle = 2 * math.pi * i / segments
                x = cx + rx * scale * edge[i] * math.cos(angle)
                y = cy + ry * scale * edge[i] * math.sin(angle)
                height = .017 * (1 - scale) + .003
                vertices.append((x, y, builder.ground(x, y) + height))
        faces, indices = [], []
        for i in range(segments):
            faces.append((0, 1 + i, 1 + (i + 1) % segments))
            indices.append(i % 4)
        for ring in range(2):
            inner = 1 + ring * segments
            outer = 1 + (ring + 1) * segments
            for i in range(segments):
                faces.append((inner + i, outer + i, outer + (i + 1) % segments,
                              inner + (i + 1) % segments))
                indices.append((i + ring) % 4)
        builder.mesh('earth.hand-shaped ' + name + ' bed', vertices, faces,
                     builder.materials['soil'], indices)


def pavilion(builder):
    cx, cy = CENTRE
    z = builder.ground(cx, cy)
    stone = builder.materials['stone']
    wood = builder.materials['wood']
    tile = builder.materials['tile']
    paint = builder.materials['paint']
    builder.prism('pavilion.eight-sided stone foundation', (cx, cy), 2.55, z + .02, z + .35,
                  8, stone, seed=18, wobble=.02)
    builder.prism('pavilion.octagonal chestnut deck', (cx, cy), 2.26, z + .35, z + .52,
                  8, wood, seed=38, wobble=.008)
    post_points = []
    for i in range(8):
        angle = math.pi / 8 + i * math.pi / 4
        x, y = cx + 1.94 * math.cos(angle), cy + 1.94 * math.sin(angle)
        post_points.append((x, y))
        builder.prism(f'pavilion.post {i+1}', (x, y), .105, z + .52, z + 2.63,
                      8, wood[i % 3:i % 3 + 2] or wood[:2], seed=60 + i, wobble=.025)
        builder.prism(f'pavilion.post foot {i+1}', (x, y), .19, z + .45, z + .62,
                      8, stone, seed=80 + i, wobble=.06)
    for i in range(8):
        a = post_points[i]
        b = post_points[(i + 1) % 8]
        builder.beam(f'pavilion.dancheong eave beam {i+1}', (*a, z + 2.58), (*b, z + 2.58),
                     .17, .18, paint[i % len(paint)])
        # Keep the shrine-facing western bay open for the stepping-stone route.
        if i != 3:
            for level in (z + .88, z + 1.22):
                builder.beam(f'pavilion.open low rail {i+1}', (*a, level), (*b, level),
                             .07, .09, wood[(i + 1) % len(wood)])
    radial = [(0.16, 3.96), (.84, 3.76), (1.57, 3.40), (2.20, 2.91), (2.73, 2.88)]
    sectors = 32
    vertices = []
    for ring, (radius, height) in enumerate(radial):
        for i in range(sectors):
            angle = math.pi / 8 + 2 * math.pi * i / sectors
            wave = .017 * math.sin(i * 5.2 + ring * 1.7)
            vertices.append((cx + radius * math.cos(angle), cy + radius * math.sin(angle),
                             z + height + wave))
    faces, indices = [], []
    for ring in range(len(radial) - 1):
        for i in range(sectors):
            a = ring * sectors + i
            b = ring * sectors + (i + 1) % sectors
            c = (ring + 1) * sectors + (i + 1) % sectors
            d = (ring + 1) * sectors + i
            faces.append((a, d, c, b))
            indices.append((i // 2 + ring) % len(tile))
    builder.mesh('pavilion.warm ink faceted tile roof', vertices, faces, tile, indices)
    # Narrow raised tile seams read at the same scale as the estate giwa.
    # Varying face tone keeps the roof from becoming one smooth dark umbrella.
    seam_vertices, seam_faces, seam_indices = [], [], []
    for i in range(sectors):
        angle = math.pi / 8 + 2 * math.pi * i / sectors
        for ring in range(1, len(radial) - 1):
            start = len(seam_vertices)
            for radius, height, side in ((radial[ring][0], radial[ring][1], -.014),
                                         (radial[ring + 1][0], radial[ring + 1][1], -.014),
                                         (radial[ring + 1][0], radial[ring + 1][1], .014),
                                         (radial[ring][0], radial[ring][1], .014)):
                seam_vertices.append((cx + radius * math.cos(angle + side),
                                      cy + radius * math.sin(angle + side), z + height + .026))
            seam_faces.append((start, start + 1, start + 2, start + 3))
            seam_indices.append(2 + (i + ring) % 3)
    builder.mesh('pavilion.hand-laid radial tile seams', seam_vertices, seam_faces,
                 tile, seam_indices)
    for i in range(8):
        angle = math.pi / 8 + i * math.pi / 4
        path = [(cx + radius * math.cos(angle), cy + radius * math.sin(angle), z + height)
                for radius, height in radial]
        for j in range(len(path) - 1):
            builder.tube(f'pavilion.eight raised roof ridges {i+1}', path[j], path[j + 1],
                         .042, tile[(i + 1) % len(tile)], 6)
    for i in range(sectors):
        angle = math.pi / 8 + 2 * math.pi * i / sectors
        x, y = cx + 2.72 * math.cos(angle), cy + 2.72 * math.sin(angle)
        builder.prism(f'pavilion.weathered eave tile end {i+1}', (x, y), .045,
                      z + 2.85, z + 2.94, 7, [tile[3], tile[2]], seed=130 + i, wobble=.05)
    builder.prism('pavilion.carved stone finial base', (cx, cy), .22, z + 3.89, z + 4.11,
                  8, stone, seed=99, wobble=.02)
    builder.prism('pavilion.carved stone finial crown', (cx, cy), .145, z + 4.11, z + 4.30,
                  8, stone, seed=100, wobble=.03)
    # Two low, visibly hand-set approach slabs preserve a usable entrance.
    for i, x in enumerate((cx - 2.45, cx - 2.98)):
        builder.prism(f'pavilion.worn entry step {i+1}', (x, cy), .54,
                      z + .17 - i * .08, z + .34 - i * .08, 8, stone, seed=110 + i, wobble=.08)
    return {'centre': [cx, cy], 'radiusMeters': 2.73, 'posts': 8, 'roofHeightMeters': 4.30,
            'opening': 'west approach toward the shrine'}


def path_and_lanterns(builder):
    stone = builder.materials['stone']
    paint = builder.materials['paint']
    wood = builder.materials['wood']
    path = [(28.55, 20.35), (30.3, 20.20), (32.4, 20.50), (33.5, 20.75)]
    stones = 0
    for a, b in zip(path, path[1:]):
        length = math.dist(a, b)
        count = max(1, round(length / .55))
        for i in range(count):
            t = (i + .5) / count
            x = a[0] + (b[0] - a[0]) * t
            y = a[1] + (b[1] - a[1]) * t + .12 * math.sin((stones + 1) * 1.7)
            z = builder.ground(x, y)
            builder.prism(f'path.worn stepping stone {stones+1}', (x, y), .32 + .035 * math.sin(i * 3),
                          z + .008, z + .074, 7, stone, seed=150 + stones, wobble=.14)
            stones += 1
    lantern_centres = [(30.05, 21.15), (32.65, 21.78), (34.15, 22.35)]
    for index, (x, y) in enumerate(lantern_centres):
        z = builder.ground(x, y)
        builder.prism(f'lantern.stone foot {index+1}', (x, y), .29, z + .02, z + .20,
                      8, stone, seed=180 + index, wobble=.07)
        builder.prism(f'lantern.square shaft {index+1}', (x, y), .16, z + .20, z + .87,
                      4, stone, seed=190 + index, wobble=.015)
        builder.prism(f'lantern.warm paper chamber {index+1}', (x, y), .27, z + .83, z + 1.20,
                      4, builder.materials['paper'], seed=200 + index)
        builder.prism(f'lantern.four-sided eave {index+1}', (x, y), .39, z + 1.20, z + 1.31,
                      4, paint[1:3], seed=210 + index, wobble=.025)
        builder.prism(f'lantern.ceramic cap {index+1}', (x, y), .21, z + 1.31, z + 1.44,
                      4, stone, seed=220 + index, wobble=.05)
        for side in range(4):
            angle = math.pi / 4 + side * math.pi / 2
            dx, dy = .235 * math.cos(angle), .235 * math.sin(angle)
            builder.tube(f'lantern.window lattice {index+1}',
                         (x + dx, y + dy, z + .88), (x + dx, y + dy, z + 1.16),
                         .018, wood[(index + side) % len(wood)], 5)
    return {'steppingStones': stones, 'lanterns': len(lantern_centres),
            'pathWorldPoints': path, 'lanternWorldCentres': lantern_centres}


def trees_and_planting(builder):
    rng = random.Random(2031)
    wood = builder.materials['wood']
    pine = builder.materials['pine']
    stone = builder.materials['stone']
    plum = builder.materials['plum']
    flower = builder.materials['flower']
    px, py = (31.4, 24.2)
    pz = builder.ground(px, py)
    pine_path = [(px, py, pz + .08), (px + .22, py + .07, pz + 1.25),
                 (px - .17, py + .17, pz + 2.55), (px + .28, py + .30, pz + 3.56)]
    for i in range(len(pine_path) - 1):
        builder.tube(f'pine.aged bending trunk {i+1}', pine_path[i], pine_path[i + 1],
                     .24 - .052 * i, wood[i % len(wood)], 7)
    canopy_centres = [(px - 1.30, py + .26, 3.12), (px + 1.15, py + .36, 3.38),
                      (px - .50, py - .85, 3.78), (px + .66, py - .75, 3.95),
                      (px + .2, py + .85, 4.08)]
    for i, (x, y, height) in enumerate(canopy_centres):
        start = pine_path[min(2, i // 2)]
        builder.tube(f'pine.angular spreading branch {i+1}', start, (x, y, pz + height),
                     .09, wood[(i + 2) % len(wood)], 6)
        # Layer several ragged needle masses, rather than one flat polygon lid.
        builder.foliage_cloud(f'pine.angled needle canopy {i+1}', (x, y, pz + height),
                              (.92, .66, .24), pine, 240 + i)
        builder.foliage_cloud(f'pine.shadowed needle canopy {i+1}',
                              (x + .24, y - .18, pz + height - .09),
                              (.73, .56, .18), pine[1:] + pine[:1], 260 + i)
    bx, by = (39.10, 17.00)
    bz = builder.ground(bx, by)
    builder.tube('plum.twisted trunk', (bx, by, bz + .04), (bx - .08, by, bz + 2.12),
                 .15, wood[0], 7)
    blossoms = 0
    for i in range(6):
        angle = i * 2 * math.pi / 6 + .32
        tip = (bx + 1.45 * math.cos(angle), by + 1.12 * math.sin(angle), bz + 2.50 + .22 * math.sin(i * 2))
        builder.tube(f'plum.spring bough {i+1}', (bx - .08, by, bz + 1.93), tip,
                     .055, wood[(i + 1) % len(wood)], 6)
        builder.foliage_cloud(f'plum.pink layered bloom canopy {i+1}',
                              (tip[0], tip[1], tip[2]), (.49, .42, .26),
                              plum[i % len(plum):] + plum[:i % len(plum)], 280 + i, points=11)
        for j in range(5):
            t = .42 + .11 * j
            x = bx - .08 + (tip[0] - bx + .08) * t + rng.uniform(-.10, .10)
            y = by + (tip[1] - by) * t + rng.uniform(-.10, .10)
            z = bz + 1.93 + (tip[2] - bz - 1.93) * t + rng.uniform(-.07, .07)
            builder.foliage_cloud(f'plum.painted five-petal blossoms {blossoms+1}',
                                  (x, y, z), (.17, .14, .065), plum, 300 + blossoms,
                                  points=5)
            blossoms += 1
    boulders = 0
    for cluster, (cx, cy, count) in enumerate(((30.2, 25.0, 5), (32.7, 25.6, 4),
                                               (40.4, 17.7, 5), (38.2, 23.0, 4))):
        for i in range(count):
            x = cx + rng.uniform(-.76, .76)
            y = cy + rng.uniform(-.61, .61)
            z = builder.ground(x, y)
            builder.prism(f'planting.hand placed boulder {boulders+1}', (x, y),
                          rng.uniform(.24, .53), z + .01, z + rng.uniform(.19, .49),
                          7, stone, seed=410 + boulders, wobble=.18)
            boulders += 1
    flowers = 0
    for i in range(18):
        x = 38.4 + .9 * math.cos(i * 2.4)
        y = 22.8 + 1.25 * math.sin(i * 1.7)
        z = builder.ground(x, y)
        builder.tube(f'planting.chrysanthemum stem {i+1}', (x, y, z + .02),
                     (x + .04 * math.sin(i), y, z + .25), .018, pine[i % len(pine)], 5)
        builder.foliage_cloud(f'planting.gold chrysanthemum {i+1}',
                              (x, y, z + .27), (.21, .18, .08),
                              flower[i % len(flower):] + flower[:i % len(flower)],
                              500 + i, points=11)
        flowers += 1
    return {'pineTrees': 1, 'plumTrees': 1, 'plumBlossoms': blossoms,
            'chrysanthemums': flowers, 'boulders': boulders}


def add_gye_shrine_garden(scene, ground):
    assert not scene.get('gyeShrineGardenV1'), 'Rear Gye garden already exists'
    builder = Builder(scene, ground)
    garden_ground(builder)
    pavilion_report = pavilion(builder)
    path_report = path_and_lanterns(builder)
    planting_report = trees_and_planting(builder)
    roof = scene.objects['GyeGarden.pavilion.warm ink faceted tile roof']
    assert all(polygon.normal.z > 0 for polygon in roof.data.polygons)
    points = [ob.matrix_world @ vertex.co for name in builder.objects
              for ob in (scene.objects[name],) for vertex in ob.data.vertices]
    bounds = [[round(min(point[axis] for point in points), 3),
               round(max(point[axis] for point in points), 3)] for axis in range(3)]
    scene['gyeShrineGardenV1'] = True
    report = {'pavilion': pavilion_report, 'path': path_report,
              'planting': planting_report, 'objects': builder.objects,
              'objectCounts': builder.counts, 'historicMeshesChanged': 0,
              'roofFacesUp': len(roof.data.polygons),
              'boundsWorld': bounds, 'rearWallBeginsAtY': 28.2,
              'authority': 'User approved distinct Gye-inspired rear expansion. 2007 site plan governs historic structures only; garden composition is new art interpretation.',
              'sourceReferences': ['assets/illustrations/gye/gye_jeongja.png',
                                   'assets/illustrations/gye/gye_garden.png'],
              'runtimePromotion': False}
    return report


def repair_candidate_roof(scene):
    ob = scene.objects['GyeGarden.pavilion.warm ink faceted tile roof']
    old = ob.data
    assert old.polygons and all(polygon.normal.z < 0 for polygon in old.polygons)
    mesh = bpy.data.meshes.new(old.name + ' upward faces')
    mesh.from_pydata([tuple(vertex.co) for vertex in old.vertices], [],
                     [tuple(reversed(polygon.vertices)) for polygon in old.polygons])
    mesh.update()
    for mat in old.materials:
        mesh.materials.append(mat)
    for before, after in zip(old.polygons, mesh.polygons):
        after.material_index = before.material_index
    ob.data = mesh
    assert all(polygon.normal.z > 0 for polygon in mesh.polygons)
    if not old.users:
        bpy.data.meshes.remove(old)
    return len(mesh.polygons)


if __name__ == '__main__':
    bpy.ops.wm.open_mainfile(filepath=str(TARGET))
    contract_path = OUT / 'estate-fabric-contract.json'
    contract = json.loads(contract_path.read_text(encoding='utf8'))
    if '--remove' in sys.argv:
        expected = set(contract['gyeShrineGarden']['objects'])
        actual = {ob.name for ob in bpy.context.scene.objects if ob.name.startswith('GyeGarden.')}
        assert actual == expected and len(actual) >= 200, 'Garden object set changed outside this pass'
        for name in expected:
            bpy.data.objects.remove(bpy.data.objects[name], do_unlink=True)
        del bpy.context.scene['gyeShrineGardenV1']
        contract['deferredGyeShrineGardenStudy'] = {
            'reason': 'The current tree and pavilion study did not meet the requested illustration quality.',
            'removedObjects': len(expected), 'runtimePromotion': False,
        }
        del contract['gyeShrineGarden']
        report = None
        polygons = None
    elif '--repair-roof' in sys.argv:
        polygons = repair_candidate_roof(bpy.context.scene)
        report = None
    else:
        from complete_estate_fabric import ground
        if '--refresh' in sys.argv:
            expected = set(contract['gyeShrineGarden']['objects'])
            actual = {ob.name for ob in bpy.context.scene.objects if ob.name.startswith('GyeGarden.')}
            assert actual == expected and len(actual) >= 200, 'Garden object set changed outside this pass'
            for name in expected:
                bpy.data.objects.remove(bpy.data.objects[name], do_unlink=True)
            del bpy.context.scene['gyeShrineGardenV1']
        report = add_gye_shrine_garden(bpy.context.scene, ground)
    bpy.ops.wm.save_as_mainfile(filepath=str(TARGET), compress=True)
    if '--remove' in sys.argv:
        pass
    elif report:
        contract['gyeShrineGarden'] = report
    else:
        contract['gyeShrineGarden']['roofFacesUp'] = polygons
    contract['candidateSceneSha256'] = hashlib.sha256(TARGET.read_bytes()).hexdigest()
    contract_path.write_text(json.dumps(contract, ensure_ascii=False, indent=2), encoding='utf8')
    print('GYE SHRINE GARDEN', len(report['objects']) if report else ('removed' if '--remove' in sys.argv else 'roof face repair'),
          report['path']['lanterns'] if report else polygons, flush=True)
