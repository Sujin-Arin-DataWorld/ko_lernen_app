"""Scoped material and interior-light color warmth; no render or save.

Copies the inspected active materials and assigns OBJECT slot overrides. The
source materials, mesh slots, UVs, polygon material indices and object names
remain intact. Paper, limewash and the noncanonical display ground have
different palettes; wood, stone, tiles and papered ondol floors are excluded.
Only the three authorized existing interior lights receive a color change;
their power and pose, and every global lighting/view setting, remain intact.
"""

import hashlib
import json

import bpy
import numpy as np


VERSION = 'r12.2'
GROUND_OBJECT = 'HS2 display ground (non-canonical)'
RECEIPT_KEY = 'HS12 material warmth receipt'
GROUND_HEX = 'F2E8DB'
PLASTER_HEX = ('CFC4B1', 'DCD1BE', 'E6DCCB', 'ECE3D5')
PAPER_HEX = ('D8B77D', 'E7C98F', 'F0D8A6')
PAPER_EMISSION_HEX = ('F7BA64', 'FFC878', 'FFD38E')
PAPER_EMISSION_STRENGTH = 1.05
INTERIOR_LIGHT_NAMES = (
    'HS3 SPEC main warm interior bounce',
    'HS3 SPEC numaru warm interior bounce',
    'HS3 numaru opening bounce',
)
INTERIOR_LIGHT_COLOR = (1.0, 0.5, 0.18)


def _rgba(hex_color):
    srgb = [int(hex_color[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    return tuple(v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
                 for v in srgb) + (1.0,)


def _socket_value(socket):
    if not hasattr(socket, 'default_value'):
        return None
    value = socket.default_value
    if isinstance(value, (float, int, str, bool)):
        return value
    try:
        return list(value)
    except TypeError:
        return str(value)


def _tree_signature(tree):
    if tree is None:
        return None
    rows = []
    for node in tree.nodes:
        row = [node.name, node.bl_idname,
               [(s.identifier, _socket_value(s)) for s in node.inputs]]
        if node.type == 'VALTORGB':
            row.append([(e.position, list(e.color)) for e in node.color_ramp.elements])
        if node.type == 'TEX_IMAGE':
            row.append(node.image.name if node.image else None)
        rows.append(row)
    links = [(l.from_node.name, l.from_socket.identifier,
              l.to_node.name, l.to_socket.identifier) for l in tree.links]
    return hashlib.sha256(json.dumps([rows, links], sort_keys=True).encode()).hexdigest()


def _geometry_signature(sc):
    digest = hashlib.sha256()
    seen = set()
    mesh_count = 0
    for obj in sorted(sc.objects, key=lambda o: o.name):
        digest.update(json.dumps([obj.name, obj.type, obj.data.name if obj.data else None,
                                  [list(row) for row in obj.matrix_world],
                                  obj.parent.name if obj.parent else None]).encode())
        if obj.type != 'MESH':
            continue
        mesh_count += 1
        mesh = obj.data
        if mesh.as_pointer() in seen:
            continue
        seen.add(mesh.as_pointer())
        # Include actual geometry and the material/UV mapping, not just bounds.
        for collection, field, count, dtype in [
            (mesh.vertices, 'co', len(mesh.vertices) * 3, np.float32),
            (mesh.loops, 'vertex_index', len(mesh.loops), np.int32),
            (mesh.polygons, 'loop_start', len(mesh.polygons), np.int32),
            (mesh.polygons, 'loop_total', len(mesh.polygons), np.int32),
            (mesh.polygons, 'material_index', len(mesh.polygons), np.int32),
        ]:
            values = np.empty(count, dtype=dtype)
            collection.foreach_get(field, values)
            digest.update(values.tobytes())
        digest.update(json.dumps([m.name if m else None for m in mesh.materials]).encode())
        for uv in mesh.uv_layers:
            digest.update(uv.name.encode())
            values = np.empty(len(uv.data) * 2, dtype=np.float32)
            uv.data.foreach_get('uv', values)
            digest.update(values.tobytes())
    return digest.hexdigest(), mesh_count


def _scene_signature(sc):
    lights = [[o.name, o.data.type, o.data.energy,
               'authorized interior color' if o.name in INTERIOR_LIGHT_NAMES else list(o.data.color),
               [list(row) for row in o.matrix_world], o.hide_render,
               _tree_signature(o.data.node_tree)] for o in sc.objects if o.type == 'LIGHT']
    cameras = [[o.name, o.data.type, o.data.lens, o.data.ortho_scale,
                [list(row) for row in o.matrix_world]] for o in sc.objects if o.type == 'CAMERA']
    value = [lights, cameras, sc.camera.name if sc.camera else None,
             sc.world.name if sc.world else None,
             _tree_signature(sc.world.node_tree) if sc.world else None,
             sc.view_settings.view_transform, sc.view_settings.look,
             sc.view_settings.exposure, sc.view_settings.gamma]
    return hashlib.sha256(json.dumps(value, sort_keys=True).encode()).hexdigest()


def _light_state(obj):
    return {'colorLinear': list(obj.data.color), 'powerW': obj.data.energy,
            'worldLocation': list(obj.matrix_world.translation),
            'matrixWorld': [list(row) for row in obj.matrix_world]}


def _role(obj, material):
    if obj.name == GROUND_OBJECT:
        return 'ground'
    if 'P18 image.sarang.plaster.' in material.name:
        return 'plaster'
    if ('Warm hanji in timber lattice' in material.name
            and ('hanji backing' in obj.name or obj.name.endswith('.paper'))):
        return 'paper'
    return None


def _active_bsdf(material):
    if not material.use_nodes or not material.node_tree:
        raise ValueError('Expected a node material: ' + material.name)
    outputs = [n for n in material.node_tree.nodes
               if n.type == 'OUTPUT_MATERIAL' and n.is_active_output]
    if len(outputs) != 1 or len(outputs[0].inputs['Surface'].links) != 1:
        raise ValueError('Ambiguous active material output: ' + material.name)
    node = outputs[0].inputs['Surface'].links[0].from_node
    if node.type != 'BSDF_PRINCIPLED':
        raise ValueError('Inspect this new surface shader before recoloring: ' + material.name)
    return node


def _base_ramp(bsdf):
    links = bsdf.inputs['Base Color'].links
    if len(links) != 1 or links[0].from_node.type != 'VALTORGB':
        raise ValueError('Expected inspected paper/limewash color ramp: ' + bsdf.id_data.name)
    return links[0].from_node


def _describe(material):
    bsdf = _active_bsdf(material)
    result = {'activeBSDF': bsdf.name,
              'baseDefaultLinear': list(bsdf.inputs['Base Color'].default_value),
              'emissionDefaultLinear': list(bsdf.inputs['Emission Color'].default_value),
              'emissionStrength': bsdf.inputs['Emission Strength'].default_value}
    for key in ('Base Color', 'Emission Color', 'Normal', 'Roughness'):
        result[key + 'Links'] = [[l.from_node.name, l.from_socket.name]
                                 for l in bsdf.inputs[key].links]
        if bsdf.inputs[key].is_linked:
            node = bsdf.inputs[key].links[0].from_node
            if node.type == 'VALTORGB':
                result[key + 'RampLinear'] = [[e.position, list(e.color)]
                                              for e in node.color_ramp.elements]
    return result


def apply_warmth(sc):
    """Return a JSON-compatible receipt; source materials stay untouched."""
    if RECEIPT_KEY in sc:
        receipt = json.loads(sc[RECEIPT_KEY])
        if receipt['version'] != VERSION:
            raise ValueError('A previous warmth version exists; rebuild from the saved source')
        receipt['alreadyApplied'] = True
        return receipt
    bpy.context.view_layer.update()
    targets = []
    for obj in sc.objects:
        for index, slot in enumerate(obj.material_slots):
            if slot.material:
                role = _role(obj, slot.material)
                if role:
                    targets.append((obj, index, slot.material, role))
    counts = {role: sum(r == role for _o, _i, _m, r in targets)
              for role in ('ground', 'plaster', 'paper')}
    if counts['ground'] != 1 or not counts['plaster'] or not counts['paper']:
        raise ValueError('Unexpected Sarang warmth target set: ' + str(counts))
    interior_lights = [sc.objects.get(name) for name in INTERIOR_LIGHT_NAMES]
    if any(o is None or o.type != 'LIGHT' for o in interior_lights):
        raise ValueError('The three existing local interior lights are required; none are created')
    light_receipts = [{'name': o.name, 'before': _light_state(o)} for o in interior_lights]

    # Inspect all active links before any assignment. Never recolor an inactive
    # legacy BSDF or silently replace the existing normal/roughness networks.
    sources = {(mat, role) for _o, _i, mat, role in targets}
    for material, role in sources:
        bsdf = _active_bsdf(material)
        if role == 'ground':
            if bsdf.inputs['Base Color'].is_linked:
                raise ValueError('Ground has a new linked base-color network; inspect first')
        else:
            ramp = _base_ramp(bsdf)
            if len(ramp.color_ramp.elements) != (3 if role == 'paper' else 4):
                raise ValueError('Source pigment palette has changed: ' + material.name)
        if bsdf.inputs['Emission Strength'].is_linked or bsdf.inputs['Emission Color'].is_linked:
            raise ValueError('Source emission has changed; inspect before overriding')
        if role != 'paper' and bsdf.inputs['Emission Strength'].default_value != 0:
            raise ValueError('Ground/plaster should remain nonemissive')

    geometry_before, mesh_count = _geometry_signature(sc)
    scene_before = _scene_signature(sc)
    source_trees = {mat: _tree_signature(mat.node_tree) for mat, _role_name in sources}
    slots_before = {(o.name, i): (s.link, s.material.name if s.material else None)
                    for o in sc.objects for i, s in enumerate(o.material_slots)}
    copies = {}
    material_receipts = []
    for material, role in sorted(sources, key=lambda item: (item[1], item[0].name)):
        before = _describe(material)
        copied = material.copy()
        copied.name = 'HS12 warmth ' + role + ' | ' + material.name
        copied['warmth_version'] = VERSION
        copied['warmth_role'] = role
        copied['source_material_name'] = material.name
        bsdf = _active_bsdf(copied)
        if role == 'ground':
            bsdf.inputs['Base Color'].default_value = _rgba(GROUND_HEX)
            copied.diffuse_color = _rgba(GROUND_HEX)
        else:
            ramp = _base_ramp(bsdf)
            palette = PAPER_HEX if role == 'paper' else PLASTER_HEX
            for element, color in zip(ramp.color_ramp.elements, palette):
                element.color = _rgba(color)
            copied.diffuse_color = _rgba(palette[len(palette) // 2])
            if role == 'paper':
                # Existing paper fibre factor drives both body and glow. The
                # lower-energy amber emission avoids an extra white flat layer.
                emission = copied.node_tree.nodes.new('ShaderNodeValToRGB')
                emission.name = 'HS12 quiet golden paper emission'
                emission.label = 'Same paper fibres; distinct golden illumination'
                emission.color_ramp.elements.new(0.5)
                for element, color in zip(emission.color_ramp.elements, PAPER_EMISSION_HEX):
                    element.color = _rgba(color)
                if ramp.inputs[0].is_linked:
                    copied.node_tree.links.new(ramp.inputs[0].links[0].from_socket, emission.inputs[0])
                else:
                    emission.inputs[0].default_value = ramp.inputs[0].default_value
                copied.node_tree.links.new(emission.outputs['Color'], bsdf.inputs['Emission Color'])
                bsdf.inputs['Emission Strength'].default_value = PAPER_EMISSION_STRENGTH
        copies[(material, role)] = copied
        material_receipts.append({'source': material.name, 'copy': copied.name, 'role': role,
                                  'before': before, 'after': _describe(copied)})
    assignments = []
    for obj, index, original, role in targets:
        slot = obj.material_slots[index]
        previous_link = slot.link
        slot.link = 'OBJECT'
        slot.material = copies[(original, role)]
        assignments.append({'object': obj.name, 'slot': index, 'role': role,
                            'previousLink': previous_link, 'newLink': slot.link,
                            'source': original.name, 'copy': slot.material.name})
    for obj, row in zip(interior_lights, light_receipts):
        obj.data.color = INTERIOR_LIGHT_COLOR
        row['after'] = _light_state(obj)
    bpy.context.view_layer.update()

    allowed = {(o.name, i) for o, i, _m, _r in targets}
    changed_elsewhere = [key for key, old in slots_before.items() if key not in allowed
                        and (sc.objects[key[0]].material_slots[key[1]].link,
                             sc.objects[key[0]].material_slots[key[1]].material.name
                             if sc.objects[key[0]].material_slots[key[1]].material else None) != old]
    geometry_after, after_count = _geometry_signature(sc)
    checks = {'geometryObjectNamesTransformsUVsAndMaterialIndicesUnchanged': geometry_before == geometry_after,
              'meshObjectCountUnchanged': mesh_count == after_count,
              'sourceMaterialNodesUnchanged': all(_tree_signature(m.node_tree) == sig
                                                  for m, sig in source_trees.items()),
              'nonTargetMaterialSlotsUnchanged': not changed_elsewhere,
              'globalLightsInteriorPowerPoseCamerasWorldAndViewUnchanged': scene_before == _scene_signature(sc),
              'interiorColorsMatchDeclaredGoldenColor': all(
                  max(abs(float(o.data.color[i]) - INTERIOR_LIGHT_COLOR[i]) for i in range(3)) < 1e-6
                  for o in interior_lights)}
    receipt = {'version': VERSION, 'alreadyApplied': False, 'meshObjectsChecked': mesh_count,
               'targetSlotCounts': counts, 'copiedMaterials': len(copies),
               'checks': checks, 'allChecksPassed': all(checks.values()),
               'geometrySignatureBefore': geometry_before, 'geometrySignatureAfter': geometry_after,
               'palettesSRGB': {'ground': GROUND_HEX, 'plaster': PLASTER_HEX,
                                'paper': PAPER_HEX, 'paperEmission': PAPER_EMISSION_HEX},
               'paperEmissionStrength': PAPER_EMISSION_STRENGTH,
               'localInteriorLightColorChanges': light_receipts,
               'interiorLightColorLinear': INTERIOR_LIGHT_COLOR,
               'fixedSceneException': ('Noncanonical display ground object material override; '
                                       'color only on the three named existing interior lights'),
               'excluded': ['wood', 'stone', 'tiles', 'papered ondol floors',
                            'global lights', 'all light power and pose', 'world', 'exposure'],
               'materials': material_receipts, 'assignments': assignments,
               'needsRenderReview': 'Cream backdrop, nonemissive limewash and golden paper must be checked together'}
    if not receipt['allChecksPassed']:
        raise AssertionError(receipt)
    sc[RECEIPT_KEY] = json.dumps(receipt, ensure_ascii=False)
    return receipt
