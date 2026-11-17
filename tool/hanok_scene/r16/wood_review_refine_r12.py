"""Bounded review correction on copied materials; never saves or renders a scene.

The pink lower strip was identified by ray casts against the saved full camera:
Projection.Numaru floor bearer, slot 1. Broad grain uses the existing authored
wood image and its attached coordinates, with no new noise or image assets.
"""
import json
from pathlib import Path

P = Path(__file__).resolve().parent
VERSION = 'r12-wood-review-1'
STRIPE_OBJECT = 'Projection.Numaru floor bearer'


def _node(tree, kind, label):
    node = tree.nodes.new(kind)
    node.label = 'HS12 review ' + label
    return node


def _attach(tree, socket, value):
    if hasattr(value, 'node'):
        tree.links.new(value, socket)
    else:
        socket.default_value = value


def _math(tree, operation, a, b, label):
    node = _node(tree, 'ShaderNodeMath', label)
    node.operation = operation
    _attach(tree, node.inputs[0], a)
    _attach(tree, node.inputs[1], b)
    return node.outputs[0]


def _vector(tree, operation, a, b, label):
    node = _node(tree, 'ShaderNodeVectorMath', label)
    node.operation = operation
    _attach(tree, node.inputs[0], a)
    _attach(tree, node.inputs[1], b)
    return node.outputs['Vector']


def _linear(hex_color):
    values = [int(hex_color[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple(v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4 for v in values) + (1,)


def _ancestors(socket):
    pending, found = [socket.node], set()
    while pending:
        node = pending.pop()
        if node in found:
            continue
        found.add(node)
        pending.extend(link.from_node for inp in node.inputs for link in inp.links)
    return found


def _ramp_state(material, family):
    return [(n.label, [(e.position, tuple(e.color)) for e in n.color_ramp.elements])
            for n in material.node_tree.nodes
            if n.type == 'VALTORGB' and n.label.startswith('HS12 ' + family + ' grain palette ')]


def _select(ob, material):
    if material.get('hs12_wood_review_refine') == VERSION:
        return None
    family = material.get('referenceColourProfile')
    name = ob.name.lower()
    if ob.name == STRIPE_OBJECT and family == 'floor':
        return 'stripe'
    if family == 'lower_board' and name.startswith('enclosure.numaru lower'):
        if 'vertical board' in name or 'closed corner' in name:
            return 'lower_board'
    if family == 'apron' and 'backing' not in name:
        return 'apron'
    return None


def _refine_stripe(material, profiles):
    tree = material.node_tree
    source_family = material['referenceColourProfile']
    changed = []
    for suffix, key in [('A', 'paletteA'), ('B', 'paletteB')]:
        node = next(n for n in tree.nodes if n.label == 'HS12 ' + source_family + ' grain palette ' + suffix)
        for elem, color in zip(node.color_ramp.elements, profiles['railing'][key]):
            rgb = _linear(color)
            elem.color = tuple(v * .90 for v in rgb[:3]) + (1,)
        node.label = 'HS12 railing grain palette ' + suffix
        changed.append(node.label)
    spread = next(n for n in tree.nodes if n.label == 'HS12 ' + source_family + ' bounded member variation')
    spread.inputs['To Min'].default_value = .46
    spread.inputs['To Max'].default_value = .54
    spread.label = 'HS12 railing bounded member variation'
    mix = next(n for n in tree.nodes if n.label == 'HS12 ' + source_family + ' object and island pigment')
    mix.label = 'HS12 railing object and island pigment'
    material['referenceColourProfile'] = 'railing'
    return dict(action='railing amber on exterior floor bearer only', ramps=changed,
                linearAlbedoScale=.90, memberMixRange=[.46, .54],
                grainNormalRoughnessAndEndCutUnchanged=True)


def _broad_grain(material, family):
    tree = material.node_tree
    ramps = [next(n for n in tree.nodes if n.label == 'HS12 ' + family + ' grain palette ' + suffix)
             for suffix in ('A', 'B')]
    old_factor = ramps[0].inputs['Fac'].links[0].from_socket
    assert ramps[1].inputs['Fac'].links[0].from_socket == old_factor
    upstream = _ancestors(old_factor)
    source = next(n for n in upstream if n.type == 'TEX_IMAGE' and n.label == 'Craft authored wood detail')
    gray = next(n for n in upstream if n.type == 'RGBTOBW' and
                any(link.from_node == source for link in n.inputs[0].links))
    assert source.inputs['Vector'].is_linked
    coord = source.inputs['Vector'].links[0].from_socket
    # Stay in the original wood quadrant, retaining the source's orientation and
    # stable crop identity. A 0.58 cross-grain scale enlarges existing growth
    # curves, not the mesh UV. Three close taps quiet the fine etched fibres.
    centered = _vector(tree, 'SUBTRACT', coord, (.25, .75, 0), family + ' original panel centre')
    stretched = _vector(tree, 'MULTIPLY', centered, (.58, .82, 1), family + ' broad original growth')
    broad_coord = _vector(tree, 'ADD', stretched, (.25, .75, 0), family + ' safe wood quadrant')
    samples = []
    for index, delta in enumerate((0, -.003, .003)):
        vector = broad_coord if not delta else _vector(tree, 'ADD', broad_coord, (delta, 0, 0), family + ' fibre tap ' + str(index))
        tex = _node(tree, 'ShaderNodeTexImage', family + ' original growth sample ' + str(index))
        tex.image = source.image
        tex.interpolation = 'Linear'
        tex.extension = 'EXTEND'
        tree.links.new(vector, tex.inputs['Vector'])
        lum = _node(tree, 'ShaderNodeRGBToBW', family + ' original growth luminance ' + str(index))
        tree.links.new(tex.outputs['Color'], lum.inputs[0])
        samples.append(lum.outputs[0])
    side_mean = _math(tree, 'MULTIPLY', _math(tree, 'ADD', samples[1], samples[2], family + ' adjacent growth'), .25, family + ' quiet fine fibres')
    broad = _math(tree, 'ADD', _math(tree, 'MULTIPLY', samples[0], .5, family + ' source growth centre'), side_mean, family + ' broad source mask')
    weight, contrast = (.38, 1.18) if family == 'lower_board' else (.32, 1.14)
    difference = _math(tree, 'SUBTRACT', broad, gray.outputs[0], family + ' broad minus original')
    combined = _math(tree, 'ADD', gray.outputs[0], _math(tree, 'MULTIPLY', difference, weight, family + ' broad contribution'), family + ' retain original fibres')
    centered_mask = _math(tree, 'SUBTRACT', combined, .075, family + ' preserve body midpoint')
    refined = _math(tree, 'ADD', _math(tree, 'MULTIPLY', centered_mask, contrast, family + ' restrained growth contrast'), .075, family + ' restored body midpoint')
    # Emphasize only the already-dark source knots; never synthesize random dots.
    knot_tail = _math(tree, 'MAXIMUM', _math(tree, 'SUBTRACT', .035, broad, family + ' existing dark knot tail'), 0, family + ' sparse authored knots')
    refined = _math(tree, 'SUBTRACT', refined, _math(tree, 'MULTIPLY', knot_tail, .22, family + ' knot depth bound'), family + ' growth and authored knots')
    delta = _math(tree, 'SUBTRACT', refined, gray.outputs[0], family + ' scalar detail correction only')
    factor = _math(tree, 'ADD', old_factor, delta, family + ' preserve existing member offset')
    factor = _math(tree, 'MINIMUM', _math(tree, 'MAXIMUM', factor, .012, family + ' lower palette bound'), .255, family + ' upper palette bound')
    for ramp in ramps:
        tree.links.new(factor, ramp.inputs['Fac'])
    return dict(action='broader existing growth and sparse existing knots', sourceImage=source.image.filepath,
                broadWeight=weight, contrastAboutBodyMidpoint=contrast,
                sampleScale=[.58, .82], fineFibreTap=.003,
                paletteColorsAndMemberMixUnchanged=True,
                originalUVNormalRoughnessAndEndCutUnchanged=True)


def apply(sc):
    """Apply only object-slot copies and return a detailed validation receipt."""
    import sarang_reference_colour_r3 as c
    profiles = json.loads((P / 'WOOD_DIRECTION_R12.json').read_text(encoding='utf-8'))['profiles']
    originals = [sc.objects[name] for name in c.p.read(P / 'sarang/geometry-lock.json')['objects']]
    architecture_before = c.p.architecture(originals)
    scene_before = c.fixed_scene(sc)
    slots_before = {(ob.name, i): (slot.link, slot.material)
                    for ob in originals for i, slot in enumerate(ob.material_slots)}
    cache, source_states, assignments, material_changes = {}, {}, [], []
    for ob in originals:
        if ob.type != 'MESH':
            continue
        used_slots = {poly.material_index for poly in ob.data.polygons}
        for index, slot in enumerate(ob.material_slots):
            old = slot.material
            if index not in used_slots or old is None:
                continue
            action = _select(ob, old)
            if not action:
                continue
            key = (old.as_pointer(), action)
            if key not in cache:
                source_states[old] = c.p.s.material_state(old)
                endgrain_before = _ramp_state(old, 'endgrain')
                palette_before = _ramp_state(old, action) if action != 'stripe' else None
                material = old.copy()
                material.name = 'HS12 review ' + action + ' | ' + old.name
                details = _refine_stripe(material, profiles) if action == 'stripe' else _broad_grain(material, action)
                assert _ramp_state(material, 'endgrain') == endgrain_before
                if palette_before is not None:
                    assert _ramp_state(material, action) == palette_before
                material['hs12_wood_review_refine'] = VERSION
                material['hs12_wood_review_source'] = old.name
                cache[key] = material
                material_changes.append(dict(source=old.name, material=material.name,
                                             sourceProfile=old.get('referenceColourProfile'),
                                             profile=material.get('referenceColourProfile'), **details))
            slot.link = 'OBJECT'
            slot.material = cache[key]
            assignments.append(dict(object=ob.name, slot=index, action=action,
                                    source=old.name, material=slot.material.name))
    changed = {(a['object'], a['slot']) for a in assignments}
    assert c.p.architecture(originals) == architecture_before
    assert c.fixed_scene(sc) == scene_before
    assert all(c.p.s.material_state(m) == state for m, state in source_states.items())
    assert all((sc.objects[name].material_slots[i].link, sc.objects[name].material_slots[i].material) == before
               for (name, i), before in slots_before.items() if (name, i) not in changed)
    return dict(version=VERSION, changedSlots=len(assignments), changedObjects=len({a['object'] for a in assignments}),
                copiedMaterials=len(cache), assignments=assignments, materials=material_changes,
                architectureAndUVUnchanged=True, originalMaterialsUnchanged=True,
                untargetedSlotsUnchanged=True, lightsWorldExposureAndCameraUnchanged=True,
                roleAndMemberPalettesPreservedOutsideIdentifiedStripe=True,
                endgrainPalettesPreserved=True, savedNative=False, rendered=False,
                visualAcceptance='pending root stone/full render comparison')
