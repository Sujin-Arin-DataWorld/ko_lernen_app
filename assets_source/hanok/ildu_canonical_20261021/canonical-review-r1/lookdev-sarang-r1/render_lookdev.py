"""One source-preserving native Sarang material candidate; no GLB or promotion."""
import bpy
import hashlib
import json
import math
import struct
import sys
import time
from array import array
from pathlib import Path
from mathutils import Vector

OUT = Path(__file__).resolve().parent
PACKAGE = OUT.parent
NATIVE = PACKAGE.parent / 'estate-yard-wall-r1/ildu-estate-yard-wall-r1.blend'
EXPECTED = '586b8a5328e7c0deaeff5f340639708c927ea224a429aca70dc313adadddff68'
PLAQUES = {'Sarang.dark original plaque', 'Sarang.dark original plaque.board',
           'Sarang.light original plaque', 'Sarang.light original plaque.board'}
PALETTE = {
    'wood': dict(hex='#8A5B38', mode='HSV', saturation=1.10, value=.92, roughnessFloor=.68, meaning='richer chestnut; full original grain and value variation retained, no uniform color mixing'),
    'tile': dict(hex='#4C514E', mode='HSV', saturation=.75, value=.70, roughnessFloor=.78, meaning='warm charcoal direction; full original tile variation and relief retained, not a flat hex replacement'),
    'stone': dict(hex='#C7BAA3', mode='MIX', mix=.08, roughnessFloor=.87, meaning='muted limestone, source stone identity retained'),
    'plaster': dict(hex='#E5DAC4', mode='MIX', mix=.20, roughnessFloor=.92, meaning='ivory lime, existing wall relief retained'),
    'paper': dict(hex='#EADFC7', mode='MIX', mix=.10, roughnessFloor=.90, meaning='warm paper tone; opacity unchanged'),
}


def write(name, value):
    (OUT / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def sequence_hash(data, prop, width, kind='f'):
    values = array(kind, [0]) * (len(data) * width)
    if values:
        data.foreach_get(prop, values)
    return hashlib.sha256(values.tobytes()).hexdigest()


def geometry_state(objects):
    result = {}
    for ob in objects:
        mesh = ob.data
        result[ob.name] = dict(
            mesh=mesh.name, vertices=sequence_hash(mesh.vertices, 'co', 3),
            edges=sequence_hash(mesh.edges, 'vertices', 2, 'i'),
            loops=sequence_hash(mesh.loops, 'vertex_index', 1, 'i'),
            faceStarts=sequence_hash(mesh.polygons, 'loop_start', 1, 'i'),
            faceSizes=sequence_hash(mesh.polygons, 'loop_total', 1, 'i'),
            materialIndices=sequence_hash(mesh.polygons, 'material_index', 1, 'i'),
            uv={uv.name: sequence_hash(uv.data, 'uv', 2) for uv in mesh.uv_layers},
            matrix=[list(row) for row in ob.matrix_world],
            parent=ob.parent.name if ob.parent else None, hidden=ob.hide_render,
            modifiers=[(m.name, m.type, m.show_viewport, m.show_render,
                        getattr(m, 'width', None), getattr(m, 'segments', None),
                        getattr(m, 'thickness', None)) for m in ob.modifiers])
    return result


def serialize(value):
    if isinstance(value, (int, float, bool, str)) or value is None:
        return value
    try:
        return [float(v) for v in value]
    except (TypeError, ValueError):
        return str(value)


def material_state(mat):
    if not mat.use_nodes:
        return dict(name=mat.name, color=list(mat.diffuse_color))
    return dict(name=mat.name, nodes=[dict(name=n.name, type=n.bl_idname,
        image=n.image.name if n.type == 'TEX_IMAGE' and n.image else None,
        inputs={s.name: serialize(s.default_value) for s in n.inputs if hasattr(s, 'default_value')})
        for n in mat.node_tree.nodes],
        links=[(l.from_node.name, l.from_socket.name, l.to_node.name, l.to_socket.name) for l in mat.node_tree.links])


def role(mat):
    text = mat.name.lower()
    if any(k in text for k in ['original plaque', 'original pigment', 'finial pigment']):
        return None
    if any(k in text for k in ['.tile.', 'charcoal clay', 'ceramic', 'tile_end', 'tile ends']):
        return 'tile'
    if any(k in text for k in ['.stone.', 'fieldstone', 'limestone', 'masonry']):
        return 'stone'
    if any(k in text for k in ['.plaster.', 'limewash', '| plaster |']):
        return 'plaster'
    if any(k in text for k in ['.paper.', 'hanji', 'papered']):
        return 'paper'
    if any(k in text for k in ['pine', '.wood.', 'end grain', 'endgrain']):
        return 'wood'
    return None


def linear(hex_color):
    values = [int(hex_color[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    return tuple(v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4 for v in values) + (1,)


def soften_copy(original, category):
    material = original.copy()
    material.name = 'LOOKDEV CANDIDATE r1 | ' + original.name
    settings = PALETTE[category]
    modifications = []
    if material.use_nodes:
        tree = material.node_tree
        for node in list(tree.nodes):
            if node.type != 'BSDF_PRINCIPLED':
                continue
            base = node.inputs['Base Color']
            previous = base.links[0].from_socket if base.links else None
            color = tuple(base.default_value)
            if settings['mode'] == 'HSV':
                grade = tree.nodes.new('ShaderNodeHueSaturation')
                grade.name = 'Lookdev source signal grade, no uniform repaint'
                grade.inputs['Hue'].default_value = .5
                grade.inputs['Saturation'].default_value = settings['saturation']
                grade.inputs['Value'].default_value = settings['value']
                grade.inputs['Fac'].default_value = 1
                source_input = grade.inputs['Color']
                source_input.default_value = color
            else:
                grade = tree.nodes.new('ShaderNodeMixRGB')
                grade.name = 'Lookdev restrained source color grade'
                grade.blend_type = 'MIX'
                grade.inputs[0].default_value = settings['mix']
                grade.inputs[1].default_value = color
                grade.inputs[2].default_value = linear(settings['hex'])
                source_input = grade.inputs[1]
            grade.label = 'Candidate only; original texture/grain retained'
            if previous:
                tree.links.new(previous, source_input)
            tree.links.new(grade.outputs[0], base)
            roughness = node.inputs['Roughness']
            if roughness.is_linked:
                prior = roughness.links[0].from_socket
                floor = tree.nodes.new('ShaderNodeMath')
                floor.operation = 'MAXIMUM'
                floor.inputs[1].default_value = settings['roughnessFloor']
                tree.links.new(prior, floor.inputs[0])
                tree.links.new(floor.outputs[0], roughness)
            else:
                roughness.default_value = max(roughness.default_value, settings['roughnessFloor'])
            modifications.append(dict(shader=node.name, category=category, **settings))
    return material, modifications


def point(ob, target):
    ob.rotation_euler = (Vector(target) - ob.location).to_track_quat('-Z', 'Y').to_euler()


def light(scene, name, location, power, size, color):
    data = bpy.data.lights.new(name, 'AREA')
    data.energy = power
    data.shape = 'DISK'
    data.size = size
    data.color = color
    ob = bpy.data.objects.new(name, data)
    scene.collection.objects.link(ob)
    ob.location = location
    point(ob, (7, 1, 2.5))
    return ob


def render(scene, camera, name, position, target, ortho, resolution):
    camera.location = position
    point(camera, target)
    camera.data.ortho_scale = ortho
    scene.render.resolution_x, scene.render.resolution_y = resolution
    scene.render.filepath = str(OUT / name)
    bpy.context.view_layer.update()
    print('RENDER START', name, flush=True)
    bpy.ops.render.render(write_still=True, scene=scene.name)
    record = dict(file=name, cameraLocation=list(position), target=list(target),
                  orthoScale=ortho, resolution=list(resolution), sha256=sha(OUT / name))
    print('RENDER COMPLETE', name, record['sha256'], flush=True)
    return record


def main():
    start = time.monotonic()
    assert sha(NATIVE) == EXPECTED
    with (PACKAGE / 'models/sarang.glb').open('rb') as stream:
        stream.read(12)
        length, kind = struct.unpack('<II', stream.read(8))
        assert kind == 0x4E4F534A
        gltf = json.loads(stream.read(length))
    assignments = {n['extras']['sourceObject']: n['extras'] for n in gltf['nodes'] if 'reviewStage' in n.get('extras', {})}
    assert len(assignments) == 710 and PLAQUES <= assignments.keys()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    with bpy.data.libraries.load(str(NATIVE), link=False) as (source, destination):
        assert set(assignments) <= set(source.objects)
        destination.objects = list(assignments)
    scene = bpy.context.scene
    scene.name = 'Sarang connected 710 | native material lookdev candidate'
    for ob in list(bpy.data.objects):
        if ob.name not in scene.objects:
            scene.collection.objects.link(ob)
    bpy.context.view_layer.update()
    objects = [bpy.data.objects[name] for name in assignments]
    assert len(objects) == 710 and all(ob.type == 'MESH' and ob.parent is None for ob in objects)
    before = geometry_state(objects)
    write('geometry-before.json', before)
    originals = {mat.name: mat for ob in objects for mat in (s.material for s in ob.material_slots) if mat}
    material_before = {name: material_state(mat) for name, mat in originals.items()}
    plaque_bindings = {name: [s.material.name if s.material else None for s in bpy.data.objects[name].material_slots] for name in PLAQUES}
    for image in bpy.data.images:
        if image.source == 'FILE':
            assert image.size[0] and image.size[1], image.name
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 12
    scene.cycles.seed = 217
    scene.cycles.use_denoising = True
    scene.render.threads_mode = 'FIXED'
    scene.render.threads = 6
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGB'
    scene.render.film_transparent = False
    scene.world = bpy.data.worlds.new('Lookdev warm open sky')
    scene.world.use_nodes = True
    scene.world.node_tree.nodes['Background'].inputs['Color'].default_value = (.78, .74, .66, 1)
    scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value = .65
    # Camera-only cream canvas does not add light or alter the building materials.
    world_tree = scene.world.node_tree
    camera_canvas = world_tree.nodes.new('ShaderNodeBackground')
    camera_canvas.name = 'Warm paper camera backdrop only'
    camera_canvas.inputs['Color'].default_value = (.72, .60, .43, 1)
    camera_canvas.inputs['Strength'].default_value = 5
    rays = world_tree.nodes.new('ShaderNodeLightPath')
    world_mix = world_tree.nodes.new('ShaderNodeMixShader')
    world_tree.links.new(rays.outputs['Is Camera Ray'], world_mix.inputs[0])
    world_tree.links.new(world_tree.nodes['Background'].outputs[0], world_mix.inputs[1])
    world_tree.links.new(camera_canvas.outputs[0], world_mix.inputs[2])
    world_tree.links.new(world_mix.outputs[0], world_tree.nodes['World Output'].inputs['Surface'])
    scene.view_settings.view_transform = 'AgX'
    scene.view_settings.look = 'AgX - Medium Low Contrast'
    scene.view_settings.exposure = 0
    scene.view_settings.gamma = 1
    light(scene, 'Broad warm daylight', (-5, -8, 16), 3200, 14, (1, .91, .79))
    light(scene, 'Open front fill', (13, -9, 9), 1500, 12, (1, .98, .91))
    light(scene, 'Soft rear daylight', (8, 10, 13), 1800, 11, (.91, .95, 1))
    cam_data = bpy.data.cameras.new('Identical comparison camera')
    cam_data.type = 'ORTHO'
    cam_data.sensor_fit = 'HORIZONTAL'
    camera = bpy.data.objects.new('Identical comparison camera', cam_data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    hero = dict(position=(29.4, -30.2, 15.45), target=(7.4, 1.8, 2.85), ortho=22, resolution=(1200, 900))
    detail = dict(position=(6.4, -22, 3.5), target=(6.4, 0, 3.35), ortho=12.8, resolution=(1200, 750))
    renders = []
    if '--candidate-only' in sys.argv:
        prior = json.loads((OUT / 'render-manifest.json').read_text(encoding='utf-8'))
        renders = [item for item in prior['renders'] if item['variant'] == 'original native material control']
        assert len(renders) == 2 and all(sha(OUT / item['file']) == item['sha256'] for item in renders)
    else:
        renders.append(dict(variant='original native material control', view='hero', **render(scene, camera, 'original-control-hero.png', **hero)))
        renders.append(dict(variant='original native material control', view='front detail', **render(scene, camera, 'original-control-front.png', **detail)))
    replacements = {}
    changes = []
    for ob in objects:
        if ob.name in PLAQUES:
            continue
        for slot in ob.material_slots:
            mat = slot.material
            category = role(mat) if mat else None
            if not category:
                continue
            if mat.name not in replacements:
                candidate, edits = soften_copy(mat, category)
                replacements[mat.name] = candidate
                changes.append(dict(original=mat.name, candidate=candidate.name, edits=edits))
            slot.link = 'OBJECT'
            slot.material = replacements[mat.name]
    bpy.context.view_layer.update()
    after = geometry_state(objects)
    assert before == after, 'Source geometry/UV/transforms changed'
    assert material_before == {name: material_state(mat) for name, mat in originals.items()}, 'Original source materials changed'
    assert plaque_bindings == {name: [s.material.name if s.material else None for s in bpy.data.objects[name].material_slots] for name in PLAQUES}, 'Plaque materials changed'
    write('material-changes.json', changes)
    write('geometry-after.json', after)
    write('geometry-verification.json', dict(passed=True, sourceNative=str(NATIVE), sourceNativeSha256=EXPECTED,
        exactSourceMembers=710, geometryUvsTransformsModifiersEqual=True, originalMaterialsUnchanged=True,
        plaqueMaterialsImagesUvsUnchanged=True, plaqueBindings=plaque_bindings,
        sourceNativeSaved=False, candidateApproved=False, appIntegrated=False, glbConverted=False))
    renders.append(dict(variant='lookdev r1 candidate, unapproved', view='hero', **render(scene, camera, 'candidate-hero.png', **hero)))
    renders.append(dict(variant='lookdev r1 candidate, unapproved', view='front detail', **render(scene, camera, 'candidate-front.png', **detail)))
    camera.location = hero['position']
    point(camera, hero['target'])
    camera.data.ortho_scale = hero['ortho']
    scene.render.resolution_x, scene.render.resolution_y = hero['resolution']
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT / 'sarang-lookdev-candidate.blend'), check_existing=False)
    assert sha(NATIVE) == EXPECTED
    write('palette.json', dict(candidateOnly=True, palette=PALETTE,
        sourceNativeSha256=EXPECTED, lighting='same three broad area lights and warm open world for both variants',
        viewTransform='AgX', look='Medium Low Contrast', samples=12,
        noNewGeometry=True, noAddedDanCheong=True, noGoldTrim=True, noNewProps=True,
        preservedSourcePlaques=True, preservedLongGrainInputs=True,
        officialSources=[dict(url='https://docs.blender.org/manual/en/latest/render/shader_nodes/shader/principled.html', checked='2026-10-22', application='roughness floor preserves diffuse tactile response'),
                         dict(url='https://docs.blender.org/manual/en/4.4/render/color_management.html', checked='2026-10-22', application='AgX with controlled open shadow contrast; identical control/candidate transform')]))
    write('render-manifest.json', dict(sourceNative=str(NATIVE), sourceNativeSha256=EXPECTED,
        sourceNativeUnchanged=True, memberCount=710, candidateNative='sarang-lookdev-candidate.blend',
        candidateNativeSha256=sha(OUT / 'sarang-lookdev-candidate.blend'), candidateApproved=False,
        exactGeometryUvsTransformsPreserved=True, seconds=round(time.monotonic()-start, 1), renders=renders))
    print('LOOKDEV COMPLETE', time.monotonic() - start, flush=True)


if __name__ == '__main__':
    main()
