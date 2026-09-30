"""Authored earth colour, wear and unplanted garden beds for the review scene.

Building coordinates and the site's approved height field stay fixed. Garden
locations follow the user's spatial direction; the bed layout is interpretive.
"""
import math
from pathlib import Path
import bpy
import numpy as np

GARDENS = [
    {'id': 'arae', 'label': '아래채 뒤 텃밭', 'pixelBounds': [570, 1175, 740, 1240], 'rows': 3},
    {'id': 'changgo', 'label': '곳간채 ⑨ 뒤 텃밭', 'pixelBounds': [790, 1710, 1070, 1845], 'rows': 4},
]


def noise(x, y, scale, seed):
    """Continuous deterministic value noise in world metres."""
    u, v = x / scale, y / scale
    a, b = np.floor(u), np.floor(v)
    tx, ty = u - a, v - b
    tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
    def at(i, j):
        k = np.sin(i * 127.1 + j * 311.7 + seed * 74.7) * 43758.5453
        return k - np.floor(k)
    return ((at(a, b) * (1 - tx) + at(a + 1, b) * tx) * (1 - ty)
            + (at(a, b + 1) * (1 - tx) + at(a + 1, b + 1) * tx) * ty)


def material(name, color, vertex=False):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.node_tree.nodes.clear()
    shader = mat.node_tree.nodes.new('ShaderNodeBsdfPrincipled')
    shader.name = 'EarthShader'
    out = mat.node_tree.nodes.new('ShaderNodeOutputMaterial')
    mat.node_tree.links.new(shader.outputs['BSDF'], out.inputs['Surface'])
    shader.inputs['Base Color'].default_value = (*color, 1)
    shader.inputs['Roughness'].default_value = .96
    shader.inputs['Specular IOR Level'].default_value = .13
    if vertex:
        tint = mat.node_tree.nodes.new('ShaderNodeVertexColor')
        tint.layer_name = 'Earth pigment'
        mat.node_tree.links.new(tint.outputs['Color'], shader.inputs['Base Color'])
    return mat


def add_gardens(scene, to_world, ground):
    mat = material('Garden worked earth with quiet pigment', (.24, .177, .115), vertex=True)
    report = []
    for spec in GARDENS:
        x0, y0, x1, y1 = spec['pixelBounds']
        nx, ny = math.ceil((x1 - x0) / 4), math.ceil((y1 - y0) / 4)
        vertices, colors, faces = [], [], []
        for j in range(ny + 1):
            v = j / ny
            for i in range(nx + 1):
                u = i / nx
                # Light hand-shaped edges and rounded bed ends, not boxes.
                px = x0 + (x1 - x0) * u + 2.1 * math.sin(v * 19 + 2) * math.sin(math.pi * u)
                py = y0 + (y1 - y0) * v + 1.4 * math.sin(u * 22) * math.sin(math.pi * v)
                x, y = map(float, to_world([[px, py]])[0])
                edge = min(1, u * 18, (1 - u) * 18, v * 18, (1 - v) * 18)
                wave = (v * spec['rows'] + .014 * math.sin(u * 11 + v * 7)) % 1
                ridge = max(0, math.sin(math.pi * wave)) ** 2.8
                end = math.sin(math.pi * u) ** .35
                ridge_height = .12 * ridge * end
                z = ground(x, y) + .006 + edge * (.017 + ridge_height)
                tone = float(noise(x, y, .42, 84) - .5)
                # Fade to the dry courtyard colour at the irregular perimeter.
                dark = np.array((.25, .184, .121)) * (1 + .09 * tone + .16 * ridge - .06 * (1 - ridge))
                dry = np.array((.405, .336, .238))
                color = dark * edge + dry * (1 - edge)
                vertices.append((x, y, z)); colors.append((*color, 1))
        for j in range(ny):
            for i in range(nx):
                a = j * (nx + 1) + i
                faces.append((a, a + 1, a + nx + 2, a + nx + 1))
        mesh = bpy.data.meshes.new('Hand worked soil ' + spec['id'])
        mesh.from_pydata(vertices, [], faces); mesh.materials.append(mat)
        attr = mesh.color_attributes.new(name='Earth pigment', type='FLOAT_COLOR', domain='CORNER')
        mesh.color_attributes.active_color = attr
        for poly in mesh.polygons:
            poly.use_smooth = True
            for li in poly.loop_indices:
                attr.data[li].color = colors[mesh.loops[li].vertex_index]
        ob = bpy.data.objects.new('Estate.garden.' + spec['id'] + '.unplanted beds', mesh)
        scene.collection.objects.link(ob)
        ob['construction_building'] = 'garden_' + spec['id']
        ob['source_object_name'] = ob.name
        ob['interpretation'] = 'User requested garden base now; crops and tools remain future items'
        report.append({**spec, 'ridgeHeightMeters': .12, 'crops': 0, 'tools': 0,
                       'authority': 'User-directed rear service gardens; individual bed sizes are not surveyed'})
    return report


def soften_earth(scene, output, to_world, projection, routes):
    targets = [o for o in scene.objects if o.name in (
        'ConnectionSite.continuous earth', 'Estate.site.west field ground extension')]
    coords = np.array([o.matrix_world @ v.co for o in targets for v in o.data.vertices])
    xmin, ymin = coords[:, :2].min(0); xmax, ymax = coords[:, :2].max(0)
    size = 2048
    x, y = np.meshgrid(np.linspace(xmin, xmax, size), np.linspace(ymin, ymax, size))
    broad = noise(x, y, 6.7, 21) - .5
    medium = noise(x, y, 1.35, 38) - .5
    small = noise(x, y, .18, 13) - .5
    grain = noise(x, y, .063, 15) - .5
    tone = .082 * broad + .033 * medium + .017 * small + .012 * grain
    def distance(a, b):
        dx, dy = b[0] - a[0], b[1] - a[1]
        t = np.clip(((x - a[0]) * dx + (y - a[1]) * dy) / (dx * dx + dy * dy), 0, 1)
        return np.sqrt((x - a[0] - t * dx) ** 2 + (y - a[1] - t * dy) ** 2)
    # Subtle accumulation beside wall bases. All paths are world-registered.
    edge_distance = np.full(x.shape, 100., dtype=np.float32)
    for route in routes:
        a, b = to_world([route[1], route[2]])
        edge_distance = np.minimum(edge_distance, distance(a, b))
    tone -= .028 * np.exp(-edge_distance / .34) * (.7 + noise(x, y, .60, 33))
    paths = [[(1568, 1710), (1460, 1490), (1230, 1475)],
             [(1100, 1425), (1080, 1190), (1430, 1060)],
             [(1440, 1470), (1560, 1360)]]
    wear = np.zeros(x.shape, dtype=np.float32)
    for path in paths:
        points = to_world(path)
        for a, b in zip(points, points[1:]):
            d = distance(a, b)
            wear = np.maximum(wear, np.exp(-(d / (.58 + .1 * noise(x, y, 2., 17))) ** 2))
    tone += .019 * wear
    rgba = np.ones((size, size, 4), dtype=np.float32)
    base = np.array((.655, .601, .510))
    rgba[:, :, :3] = np.clip(base + tone[:, :, None], 0, 1)
    output.mkdir(exist_ok=True)
    image = bpy.data.images.new('Quiet courtyard earth pigment', width=size, height=size, alpha=False)
    image.colorspace_settings.name = 'sRGB'
    image.pixels.foreach_set(rgba.ravel())
    image.filepath_raw = str(output / 'estate-earth-pigment.png'); image.file_format = 'PNG'; image.save()
    # Pixel file and native scene share the same material, including the web export.
    mat = material('Illustrated lived courtyard earth', (.4, .34, .24))
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    uv = nodes.new('ShaderNodeUVMap'); uv.uv_map = 'Estate earth world'
    tex = nodes.new('ShaderNodeTexImage'); tex.image = image
    links.new(uv.outputs['UV'], tex.inputs['Vector'])
    links.new(tex.outputs['Color'], nodes['EarthShader'].inputs['Base Color'])
    # Fine relief is a normal map; it does not move the approved sloping terrain.
    height = .0017 * small + .0008 * grain
    dy, dx = np.gradient(height, (ymax - ymin) / (size - 1), (xmax - xmin) / (size - 1))
    normal = np.dstack((-dx, -dy, np.ones_like(dx)))
    normal /= np.linalg.norm(normal, axis=2)[:, :, None]
    rgba[:, :, :3] = normal * .5 + .5
    normal_image = bpy.data.images.new('Quiet courtyard fine relief', width=size, height=size, alpha=False)
    normal_image.colorspace_settings.name = 'Non-Color'; normal_image.pixels.foreach_set(rgba.ravel())
    normal_image.filepath_raw = str(output / 'estate-earth-normal.png'); normal_image.file_format = 'PNG'; normal_image.save()
    relief = nodes.new('ShaderNodeTexImage'); relief.image = normal_image
    links.new(uv.outputs['UV'], relief.inputs['Vector'])
    normal_node = nodes.new('ShaderNodeNormalMap'); normal_node.uv_map = uv.uv_map
    normal_node.inputs['Strength'].default_value = .65
    links.new(relief.outputs['Color'], normal_node.inputs['Color'])
    links.new(normal_node.outputs['Normal'], nodes['EarthShader'].inputs['Normal'])
    for ob in targets:
        ob.data = ob.data.copy(); ob.data.materials.clear(); ob.data.materials.append(mat)
        layer = ob.data.uv_layers.get(uv.uv_map) or ob.data.uv_layers.new(name=uv.uv_map)
        for poly in ob.data.polygons:
            poly.material_index = 0
            for li in poly.loop_indices:
                p = ob.matrix_world @ ob.data.vertices[ob.data.loops[li].vertex_index].co
                layer.data[li].uv = ((p.x - xmin) / (xmax - xmin), (p.y - ymin) / (ymax - ymin))
        ob.data.uv_layers.active = layer; layer.active_render = True
    return {'objects': [o.name for o in targets], 'terrainGeometryChanged': False,
            'textureSize': size, 'walkedPathsPixels': paths, 'fineReliefMeters': .0025,
            'style': 'Quiet broad dry-earth colour, subtle footpath wear and wall-base accumulation; no generic dirt overlay',
            'authority': 'Photo-informed art interpretation, not measured historic wear'}
