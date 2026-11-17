"""Transfer final Sarang shader templates without touching source mesh datablocks.

Call apply(scene, canonical_building_key, {role: Blender_material}). This module
does not load/save files, render, change mesh data, or change scene controls.
MappingError.receipt contains the complete, JSON-serializable failure evidence.
"""
import hashlib
import json
from collections import Counter
from pathlib import Path

P = Path(__file__).resolve().parent
WOOD = frozenset(('column', 'beam', 'apron', 'lower_board', 'floor', 'gable',
                  'rafter', 'railing', 'frame', 'lattice', 'door_panel', 'endgrain'))
NONWOOD = frozenset(('tile', 'tile-end', 'stone', 'plaster', 'paper'))
PRESERVE = frozenset(('preserve', 'paint', 'pigment', 'metal', 'earth', 'wax',
                      'fibre', 'fiber', 'backing', 'unclassified-context'))
ATTR_ALIASES = (
    ('P18 source member id', 'HS source member id'),
    ('P18 real cut face', 'HS real cut face'),
    ('P18 cut UV', 'HS cut UV'),
    ('P18 member roughness', 'HS member roughness'),
    ('P18 surface UV', 'HS wood UV', 'HS surface UV'),
    ('P18 long timber UV', 'HS long timber UV'),
    ('P18 long timber sample', 'HS long timber sample'),
    ('P18 broad timber UV', 'HS broad timber UV'),
    ('P18 broad timber body', 'HS broad timber body'),
)


class MappingError(RuntimeError):
    def __init__(self, receipt):
        self.receipt = receipt
        super().__init__('R16 material transfer failed: ' + json.dumps(receipt['errors'], ensure_ascii=False))


def _live(tree):
    found = set()
    def visit(n):
        if n in found:
            return
        found.add(n)
        for s in n.inputs:
            for link in s.links:
                visit(link.from_node)
    for n in tree.nodes:
        if n.type == 'OUTPUT_MATERIAL' and n.is_active_output:
            visit(n)
    return found


def _new(tree, kind, label):
    n = tree.nodes.new(kind)
    n.label = 'Portable R16 ' + label
    return n


def _attach(tree, socket, value):
    if hasattr(value, 'node'):
        tree.links.new(value, socket)
    else:
        socket.default_value = value


def _math(tree, op, a, b, label):
    n = _new(tree, 'ShaderNodeMath', label)
    n.operation = op
    _attach(tree, n.inputs[0], a)
    _attach(tree, n.inputs[1], b)
    return n.outputs[0]


def _schema(ob):
    return (tuple((a.name, a.domain, a.data_type) for a in ob.data.attributes),
            tuple(u.name for u in ob.data.uv_layers))


def _clone_socket(tree, socket, cache):
    """Copy only the upstream coordinate DAG; image datablocks remain shared."""
    old = socket.node
    key = old.as_pointer()
    if key not in cache:
        n = tree.nodes.new(old.bl_idname)
        cache[key] = n
        n.label = 'Portable source | ' + old.label
        n.location = old.location
        # Coordinate branches use these writable scalar/enum/ID properties.
        # Unsupported node types fail visibly rather than produce wrong mapping.
        allowed = {'UVMAP', 'ATTRIBUTE', 'MATH', 'VECT_MATH', 'COMBXYZ', 'SEPXYZ',
                   'TEX_COORD', 'MAPPING', 'MAP_RANGE', 'VALUE', 'RGB', 'MIX_RGB',
                   'TEX_NOISE', 'TEX_WHITE_NOISE', 'NEW_GEOMETRY', 'OBJECT_INFO',
                   'REROUTE', 'GROUP', 'CLAMP', 'VECTOR_ROTATE', 'SEPARATE_COLOR',
                   'COMBINE_COLOR', 'TEX_IMAGE', 'VALTORGB', 'RGBTOBW', 'MIX'}
        if old.type not in allowed:
            raise ValueError('Unsupported source coordinate node: ' + old.bl_idname)
        for name in ('operation', 'use_clamp', 'uv_map', 'from_instancer',
                     'attribute_name', 'attribute_type', 'object', 'vector_type',
                     'interpolation_type', 'clamp', 'data_type', 'blend_type',
                     'noise_dimensions', 'normalize', 'rotation_type', 'invert',
                     'node_tree', 'image', 'interpolation', 'extension',
                     'projection', 'projection_blend'):
            if hasattr(old, name):
                setattr(n, name, getattr(old, name))
        if old.type == 'VALTORGB':
            a, b = old.color_ramp, n.color_ramp
            while len(b.elements) > 2:
                b.elements.remove(b.elements[-1])
            while len(b.elements) < len(a.elements):
                b.elements.new(.5)
            b.interpolation = a.interpolation
            b.color_mode = a.color_mode
            b.hue_interpolation = a.hue_interpolation
            for src, dst in zip(a.elements, b.elements):
                dst.position, dst.color = src.position, src.color
        for src, dst in zip(old.inputs, n.inputs):
            if hasattr(src, 'default_value'):
                dst.default_value = src.default_value
            for link in src.links:
                tree.links.new(_clone_socket(tree, link.from_socket, cache), dst)
        for src, dst in zip(old.outputs, n.outputs):
            if hasattr(src, 'default_value'):
                dst.default_value = src.default_value
    index = list(old.outputs).index(socket)
    return cache[key].outputs[index]


def _inventory(building):
    manifest = json.loads((P / 'BUILDING_TRANSFER_INVENTORY_R16.json').read_text(encoding='utf8'))
    entry = next((b for b in manifest['buildings'] if b['key'] == building), None)
    if entry is None:
        raise ValueError('Not a canonical R16 building: ' + building)
    details = json.loads((P / 'BUILDING_TRANSFER_MATERIAL_DETAILS_R16.json').read_text(encoding='utf8'))
    if building not in details['buildings']:
        raise ValueError('Missing inspected material details for ' + building)
    rows = []
    if entry.get('materialInventory'):
        data = json.loads(Path(entry['materialInventory']).read_text(encoding='utf8'))
        rows = data if isinstance(data, list) else data['materialSlots']
    return entry, {(r['object'], int(r['slot'])): r for r in rows}


def _classify(ob, old, row):
    name = ob.name.lower()
    protected_words = ('plaque', 'lettering', 'inscription', 'signboard', 'calligraphy',
                       '현판', '편액', '문자', 'non-canonical', 'display ground', 'joint backings')
    if any(w in name for w in protected_words):
        return (row.get('role') if row and row.get('role') in PRESERVE else 'preserve'), 'protected object identity'
    # Explicit preservation tags win even when an older inventory is available.
    tags = [str(old.get(k, '')).lower() for k in
            ('craft_role', 'r6_role', 'r5_role', 'p18MaterialFamily', 'p15Family')]
    if row and (row.get('preserved') or row.get('role') in PRESERVE):
        return row.get('role') or 'preserve', 'inventory preservation'
    if any(t in PRESERVE for t in tags):
        return next(t for t in tags if t in PRESERVE), 'source preservation tag'
    if row:
        role, reason = row['role'], 'inventory'
    else:
        role = next((t for t in tags if t in WOOD | NONWOOD | {'wood'}), None)
        reason = 'source material tag'
        if role is None:
            profile = old.get('referenceColourProfile')
            if profile in WOOD | NONWOOD:
                return profile, 'existing referenceColourProfile'
            text = ' '.join((old.name, str(old.get('pilotRole', '')))).lower()
            matches = [('paint', ('paint', 'pigment', 'dancheong', 'lettering')),
                       ('metal', ('iron', 'metal', 'bronze', 'hinge')),
                       ('paper', ('hanji', 'paper')), ('plaster', ('plaster', 'limewash')),
                       ('stone', ('stone', 'granite')), ('tile', ('tile', 'ceramic')),
                       ('wood', ('wood', 'timber', 'pine', 'joinery')),
                       ('earth', ('earth', 'soil', 'clay'))]
            role = next((r for r, words in matches if any(w in text for w in words)), None)
            reason = 'source material name'
    if role in PRESERVE or role in NONWOOD:
        if role == 'tile' and any(w in name for w in ('tile end', 'tile-end', 'tile_end', 'end cap', 'maksae')):
            return 'tile-end', reason + ' plus tile-end object'
        return role, reason
    if role not in WOOD | {'wood'}:
        raise ValueError('Unclassified used material slot: ' + old.name)
    if role == 'endgrain' or 'end grain' in name or 'endgrain' in name:
        return 'endgrain', reason
    usage = (row or {}).get('usage', old.get('craft_usage', ''))
    member = str(old.get('gyeMemberTimberRole', old.get('p15Member', ''))).lower()
    if 'gable' in name:
        return 'gable', reason
    if any(w in name for w in ('railing', 'return rails', 'upper rail', 'no4', 'no5 plain rail', 'no5 stile')):
        return 'railing', reason
    if any(w in name for w in ('numaru lower', 'lower boarding', 'lower board enclosure')):
        return 'lower_board', reason
    if any(w in name for w in ('apron', 'horizontal boarding', 'boarding continuous')):
        return 'apron', reason
    if any(w in name for w in ('floor girder', 'floor joist', 'subfloor joist', 'maru joist', 'floor beam')):
        return 'beam', reason + ' explicit structural floor support'
    if usage == 'floor-plank' or member == 'floor' or any(w in name for w in ('floor', 'maru plank', 'deck', 'connector maru', 'maru extension', 'maru return', 'entrance maru')):
        return 'floor', reason
    if any(w in name for w in ('rafter', 'underside', 'bedding board')) or member == 'rafters':
        return 'rafter', reason
    if any(w in name for w in ('continuous post', 'corner posts', 'square post', 'post.wood', 'hwaljufix', 'column', 'upright post')) or member == 'posts':
        return 'column', reason
    if any(w in name for w in ('lattice', 'muntin', 'sal lattice')) or role == 'lattice':
        return 'lattice', reason
    if any(w in name for w in ('door panel', 'door plank', 'recessed lower board')) or usage == 'board-door':
        return 'door_panel', reason
    if any(w in name for w in ('.leaf', 'head/sill', 'jamb', 'wall frame', 'horizontal frame', 'door threshold', 'door frame', 'stile')):
        return 'frame', reason
    return 'beam', reason + ' structural wood'


def _coordinate(tree, ob, old, role, changes):
    """Return old authored atlas DAG or a bounded, directional source adapter."""
    authored = next((n for n in old.node_tree.nodes if n.type == 'TEX_IMAGE' and
                     n.label == 'Craft authored wood detail' and n.inputs['Vector'].is_linked), None)
    if authored:
        changes.append(dict(method='grafted-source-authored-wood-vector', sourceNode=authored.name))
        cloned = {}
        coordinate = _clone_socket(tree, authored.inputs['Vector'].links[0].from_socket, cloned)
        # Joined Anchae square posts span a whole building in local Y. The old
        # object-extent mapper chose that assembly axis as grain length even
        # though the individual posts are upright local Z. Correct the copied
        # branch only when that exact legacy mapping is present and verified.
        if role == 'column' and 'square post' in ob.name.lower():
            axis = ob.matrix_world.to_3x3().col[2].normalized()
            if abs(axis.z) < .999:
                raise ValueError('Square-post coordinate adaptation requires verified upright local Z')
            selector = next((n for n in cloned.values() if n.label ==
                             'Portable source | Longitudinal strokes on member axis'), None)
            if selector:
                xlink = selector.inputs['X'].links
                ylink = selector.inputs['Y'].links
                if not xlink or not ylink:
                    raise ValueError('Incomplete legacy joined-post coordinate selector')
                xsource, ysource = xlink[0].from_socket, ylink[0].from_socket
                if xsource.name in ('X', 'Y', 'Z') and ysource.name in ('X', 'Y') and xsource.node == ysource.node and xsource.node.type == 'SEPXYZ':
                    separator = xsource.node
                    across = _math(tree, 'ADD', separator.outputs['X'], separator.outputs['Y'],
                                   'upright joined-post both side planes')
                    tree.links.new(across, selector.inputs['X'])
                    tree.links.new(separator.outputs['Z'], selector.inputs['Y'])
                    changes.append(dict(method='correct-verified-upright-joined-post-grain-axis',
                                        originalAtlasAxes=[xsource.name, ysource.name], actualAtlasAxes=['X+Y', 'Z'],
                                        verifiedObjectLocalZ=list(axis)))
                elif ysource.name != 'Z':
                    raise ValueError('Unexpected square-post grain selector: refusing assumed rotation')
        return coordinate
    # For the three non-craft buildings preserve the original side-grain mapping
    # DAG, then explicitly fold its coordinates into the SAME wood-only quadrant.
    candidates = [n for n in old.node_tree.nodes if n.type == 'TEX_IMAGE' and n.image and
                  n.inputs['Vector'].is_linked and
                  any(w in (n.label + ' ' + n.image.name).lower() for w in ('wood', 'pine', 'timber')) and
                  not any(w in (n.label + ' ' + n.image.name).lower() for w in ('endgrain', 'end grain', 'wood_end'))]
    candidates.sort(key=lambda n: ('longitudinal' not in (n.label + n.image.name).lower(), n.name))
    if candidates:
        src = candidates[0]
        co = _clone_socket(tree, src.inputs['Vector'].links[0].from_socket, {})
        changes.append(dict(method='bounded-original-directional-wood-vector', sourceNode=src.name,
                            image=src.image.name))
        # HS/P18 longitudinal images encode a 4x4 swatch address. Its cell
        # number is pigment identity, not grain position. Decode the within-cell
        # position before re-encoding into the single Craft wood quadrant;
        # otherwise a whole member samples only ~one quarter of that quadrant.
        # Source grid is documented by build_pilot.wood_phase (4x4, trim 8x1).
        image_name = src.image.name.lower()
        grid = (4., 4.) if 'wood-longitudinal-atlas-v1' in image_name else (8., 1.) if 'wood-long-members-trim-v1' in image_name else None
        if grid:
            split = _new(tree, 'ShaderNodeSeparateXYZ', 'decode original source atlas swatch')
            tree.links.new(co, split.inputs[0])
            decoded = _new(tree, 'ShaderNodeCombineXYZ', 'original grain position within swatch')
            for axis, cells in zip(('X', 'Y'), grid):
                scaled = _math(tree, 'MULTIPLY', split.outputs[axis], cells, 'original source atlas cells ' + axis)
                local = _math(tree, 'FRACT', scaled, 0., 'decode within-cell grain ' + axis)
                tree.links.new(local, decoded.inputs[axis])
            co = decoded.outputs[0]
            changes.append(dict(method='decode-original-packed-wood-swatch', sourceGrid=list(grid),
                                sourceImage=src.image.name, targetWoodQuadrant=[.02, .48, .52, .98]))
    else:
        uvs = {u.name for u in ob.data.uv_layers}
        uv = next((n.uv_map for n in old.node_tree.nodes if n.type == 'UVMAP' and
                   n.uv_map in uvs and any(w in n.uv_map.lower() for w in ('grain', 'timber'))), None)
        if uv is None:
            uv = next((u for u in sorted(uvs) if any(w in u.lower() for w in ('grain', 'timber'))), None)
        if uv:
            n = _new(tree, 'ShaderNodeUVMap', 'existing source directional UV')
            n.uv_map = uv
            co = n.outputs['UV']
            changes.append(dict(method='bounded-existing-directional-UV', uv=uv))
        else:
            # Explicit local-space projection: longest local bounding-box axis is
            # timber length. Both cross-plane components form the side address.
            coords = list(ob.data.vertices)
            if not coords:
                raise ValueError('Cannot map empty wood mesh')
            extents = [max(v.co[a] for v in coords) - min(v.co[a] for v in coords) for a in range(3)]
            length = max(range(3), key=lambda a: extents[a])
            cross = [a for a in range(3) if a != length]
            if extents[length] <= 1e-8:
                raise ValueError('Degenerate directional wood extent')
            tc = _new(tree, 'ShaderNodeTexCoord', 'explicit local member metres')
            split = _new(tree, 'ShaderNodeSeparateXYZ', 'source local axes')
            tree.links.new(tc.outputs['Object'], split.inputs[0])
            combine = _new(tree, 'ShaderNodeCombineXYZ', 'actual member length along grain Y')
            width = _math(tree, 'ADD', split.outputs[cross[0]], split.outputs[cross[1]], 'both side planes')
            width = _math(tree, 'DIVIDE', width, max(extents[cross[0]], extents[cross[1]], .02), 'member width normalization')
            along = _math(tree, 'DIVIDE', split.outputs[length], extents[length], 'full member grain length')
            tree.links.new(width, combine.inputs['X'])
            tree.links.new(along, combine.inputs['Y'])
            co = combine.outputs[0]
            changes.append(dict(method='explicit-object-local-directional-projection', lengthAxis=length,
                                crossAxes=cross, localExtents=extents))
    split = _new(tree, 'ShaderNodeSeparateXYZ', 'source grain without quadrant bleed')
    tree.links.new(co, split.inputs[0])
    combine = _new(tree, 'ShaderNodeCombineXYZ', 'wood-only authored atlas address')
    for axis, offset in (('X', .02), ('Y', .52)):
        folded = _math(tree, 'PINGPONG', split.outputs[axis], 1., 'mirrored source ' + axis)
        scaled = _math(tree, 'MULTIPLY', folded, .46, 'safe wood quadrant ' + axis)
        tree.links.new(_math(tree, 'ADD', scaled, offset, 'atlas offset ' + axis), combine.inputs[axis])
    return combine.outputs[0]


def _graft(tree, ob, old, role, changes):
    if role not in WOOD or role == 'endgrain':
        return
    textures = [n for n in _live(tree) if n.type == 'TEX_IMAGE' and n.label == 'Craft authored wood detail']
    if len(textures) != 1:
        raise ValueError('Template requires exactly one live Craft authored wood detail image')
    anchor = next((n for n in _live(tree) if n.label.endswith('R15 original wood centre')), None)
    source = _coordinate(tree, ob, old, role, changes)
    if anchor:
        if not anchor.inputs[0].is_linked:
            raise ValueError('R15 pre-crop ingress is not linked')
        original = anchor.inputs[0].links[0].from_socket
        for link in list(original.links):
            tree.links.new(source, link.to_socket)
        changes.append(dict(retainedTemplateCrop=True, ingress=anchor.label))
    else:
        raise ValueError('Missing R15 crop ingress; refusing to bypass final member crop')


def _source_surface_coordinate(tree, ob, old, role, changes):
    """Explicit source-coordinate adapter for legacy nonwood shader taps."""
    attrs = {a.name for a in ob.data.attributes}
    uvs = {u.name for u in ob.data.uv_layers}
    words = {'tile': ('ceramic', 'tile', 'roof'), 'tile-end': ('ceramic', 'tile', 'roof'),
             'stone': ('stone', 'mineral'), 'plaster': ('lime', 'plaster'),
             'paper': ('paper', 'hanji')}.get(role, ('grain', 'timber'))
    old_uvs = list(dict.fromkeys(n.uv_map for n in old.node_tree.nodes
                                if n.type == 'UVMAP' and n.uv_map in uvs))
    preferred = next((u for u in old_uvs if any(w in u.lower() for w in words)), None)
    if preferred is None:
        preferred = next((u for u in sorted(uvs) if any(w in u.lower() for w in words)), None)
    if preferred:
        n = _new(tree, 'ShaderNodeUVMap', 'existing ' + role + ' surface UV')
        n.uv_map = preferred
        changes.append(dict(method='explicit-existing-source-surface-UV', role=role, uv=preferred))
        return n.outputs['UV']
    attribute = next((a for a in ('P18 surface UV', 'HS surface UV', 'HS wood UV') if a in attrs), None)
    if attribute:
        n = _new(tree, 'ShaderNodeAttribute', 'existing original architectural surface address')
        n.attribute_name = attribute
        changes.append(dict(method='explicit-existing-source-surface-attribute', role=role, attribute=attribute))
        return n.outputs['Vector']
    # A source shader can legitimately use its original architectural pigment UV.
    # It must actually occur in that source shader and exist on this mesh.
    if old_uvs:
        n = _new(tree, 'ShaderNodeUVMap', 'retained source architectural pigment UV')
        n.uv_map = old_uvs[0]
        changes.append(dict(method='explicit-source-shader-architectural-UV', role=role, uv=n.uv_map))
        return n.outputs['UV']
    old_object = next((n.outputs['Object'] for n in old.node_tree.nodes
                       if n.type == 'TEX_COORD' and n.outputs['Object'].is_linked), None)
    if old_object:
        changes.append(dict(method='grafted-original-object-space-surface-coordinate', role=role))
        return _clone_socket(tree, old_object, {})
    raise ValueError('No existing original source surface coordinates for ' + role)


def _adapt(tree, ob, old, role, changes):
    attrs = {a.name for a in ob.data.attributes}
    uvs = {u.name for u in ob.data.uv_layers}
    random_socket = None
    surface_socket = None
    def surface_coordinate():
        nonlocal surface_socket
        if surface_socket is None:
            surface_socket = _source_surface_coordinate(tree, ob, old, role, changes)
        return surface_socket
    def object_random():
        nonlocal random_socket
        if random_socket is None:
            n = _new(tree, 'ShaderNodeObjectInfo', 'explicit object identity when no member attribute exists')
            random_socket = n.outputs['Random']
        return random_socket
    for n in list(_live(tree)):
        if n.type == 'ATTRIBUTE' and n.attribute_name not in attrs:
            original = n.attribute_name
            family = next((f for f in ATTR_ALIASES if original in f), ())
            alternate = next((a for a in family if a in attrs), None)
            if alternate:
                n.attribute_name = alternate
                changes.append(dict(attributeFrom=original, attributeTo=alternate))
            elif original in ('P18 surface UV', 'HS surface UV', 'HS wood UV'):
                replacement = surface_coordinate()
                for socket in n.outputs:
                    for link in list(socket.links):
                        tree.links.new(replacement, link.to_socket)
                changes.append(dict(attributeFrom=original, replacement='explicit original source surface coordinate'))
            elif any(w in original.lower() for w in ('member id', 'member phase', 'member tone', 'member roughness', 'roof member value')):
                for socket in n.outputs:
                    for link in list(socket.links):
                        tree.links.new(object_random(), link.to_socket)
                changes.append(dict(attributeFrom=original, replacement='explicit Object Info Random identity',
                                    reason='source mesh has no equivalent member attribute'))
            elif any(w in original.lower() for w in ('cut', 'eligible', 'timber sample', 'timber body')):
                for socket in n.outputs:
                    for link in list(socket.links):
                        link_socket = link.to_socket
                        tree.links.remove(link)
                        if hasattr(link_socket, 'default_value'):
                            value = link_socket.default_value
                            link_socket.default_value = tuple(0. for _ in value) if hasattr(value, '__len__') else 0.
                changes.append(dict(attributeFrom=original, replacement='explicit zero: source has no authored mask/address'))
            else:
                raise ValueError('No source attribute mapping for ' + original)
        elif n.type == 'UVMAP' and n.uv_map not in uvs:
            original = n.uv_map
            old_uvs = [x.uv_map for x in old.node_tree.nodes if x.type == 'UVMAP' and x.uv_map in uvs]
            words = next((words for words in (('end grain', 'endgrain'), ('grain', 'timber'),
                          ('stone', 'mineral'), ('ceramic', 'tile'), ('lime', 'plaster'))
                          if any(w in original.lower() for w in words)), ())
            candidates = [u for u in old_uvs if any(w in u.lower() for w in words)]
            if not candidates:
                candidates = [u for u in sorted(uvs) if any(w in u.lower() for w in words)]
            if not candidates:
                replacement = surface_coordinate()
                for socket in n.outputs:
                    for link in list(socket.links):
                        tree.links.new(replacement, link.to_socket)
                changes.append(dict(uvFrom=original, replacement='explicit original source surface coordinate'))
            else:
                n.uv_map = candidates[0]
                changes.append(dict(uvFrom=original, uvTo=n.uv_map))


def _state(ob):
    return (ob.name, ob.data.as_pointer(), len(ob.data.vertices), len(ob.data.edges),
            len(ob.data.polygons), len(ob.data.loops), _schema(ob),
            ob.parent.as_pointer() if ob.parent else None,
            tuple(tuple(row) for row in ob.matrix_world))


def apply(sc, buildingKey, masterMaterials):
    """Apply only preflighted OBJECT slot copies; raise MappingError on any gap.

    No slot is changed until every used slot is classified and every shader is
    built. Copies are cached by role, source material, existing attribute/UV
    schema and directional projection dimensions, never by building alone.
    """
    entry, inventory = _inventory(buildingKey)
    receipt = dict(schemaVersion=1, building=buildingKey, passed=False,
                   sourceCanonical=entry['canonicalNative'], sourceCanonicalSha256=entry['canonicalActualSha256'],
                   assignments=[], preserved=[], errors=[], materials=[],
                   unusedSlots=[], sourceMeshMutation=False, nativeSaved=False, rendered=False)
    meshes = [o for o in sc.objects if o.type == 'MESH']
    before = {o.as_pointer(): _state(o) for o in meshes}
    cache, planned = {}, []
    for ob in meshes:
        counts = Counter(p.material_index for p in ob.data.polygons)
        for invalid in sorted(set(counts) - set(range(len(ob.material_slots)))):
            receipt['errors'].append(dict(object=ob.name, slot=invalid,
                                          faces=counts[invalid], error='Used polygon index has no material slot'))
        for index, slot in enumerate(ob.material_slots):
            if not counts[index]:
                receipt['unusedSlots'].append(dict(object=ob.name, slot=index))
                continue
            old = slot.material
            row = dict(object=ob.name, slot=index, faces=counts[index], oldMaterial=old.name if old else None)
            try:
                if old is None:
                    raise ValueError('Used material slot is empty')
                role, reason = _classify(ob, old, inventory.get((ob.name, index)))
                row.update(role=role, classification=reason)
                if role in PRESERVE:
                    receipt['preserved'].append(row)
                    continue
                if role not in WOOD | NONWOOD:
                    raise ValueError('Unsupported classified role: ' + str(role))
                template = masterMaterials.get(role)
                if template is None or not template.use_nodes:
                    raise ValueError('Missing node-based master material for ' + role)
                schema = _schema(ob)
                paper_floor = role == 'paper' and 'floor' in ob.name.lower()
                # Object-local fallback depends on exact local dimensions.
                source_vectors = [n for n in old.node_tree.nodes if n.type == 'TEX_IMAGE'
                                  and n.image and n.inputs['Vector'].is_linked
                                  and any(w in (n.label + n.image.name).lower()
                                          for w in ('wood', 'pine', 'timber'))]
                has_grain_uv = any(any(w in u.name.lower() for w in ('grain', 'timber'))
                                   for u in ob.data.uv_layers)
                bounds = tuple(tuple(v) for v in ob.bound_box) if role in WOOD and not source_vectors and not has_grain_uv else ()
                key = (role, old.as_pointer(), schema, bounds, paper_floor)
                if key not in cache:
                    material = template.copy()
                    digest = hashlib.sha256(repr(key).encode()).hexdigest()[:10]
                    material.name = 'HS16 portable ' + buildingKey + ' ' + role + ' ' + digest
                    changes = []
                    _graft(material.node_tree, ob, old, role, changes)
                    _adapt(material.node_tree, ob, old, role, changes)
                    if role == 'floor' and buildingKey != 'sarang':
                        # Review-directed calibration for exposed maru in the
                        # other buildings. The frozen Sarang master stays byte
                        # identical; no other timber role or scene light changes.
                        for bsdf in list(_live(material.node_tree)):
                            if bsdf.type != 'BSDF_PRINCIPLED':
                                continue
                            socket = bsdf.inputs['Base Color']
                            source = socket.links[0].from_socket if socket.is_linked else tuple(socket.default_value)
                            balance = _new(material.node_tree, 'ShaderNodeMixRGB',
                                           'other building exposed maru pigment balance')
                            balance.blend_type = 'MULTIPLY'
                            balance.inputs[0].default_value = 1.
                            balance.inputs[2].default_value = (.94, 1.20, 1., 1.)
                            _attach(material.node_tree, balance.inputs[1], source)
                            material.node_tree.links.new(balance.outputs[0], socket)
                        changes.append(dict(method='other-building-exposed-maru-pigment-balance',
                                            linearRGBGain=[.94, 1.20, 1.],
                                            appliesTo='final active floor Base Color only',
                                            sarangMasterUnchanged=True))
                    if paper_floor:
                        for bsdf in _live(material.node_tree):
                            if bsdf.type == 'BSDF_PRINCIPLED':
                                strength = bsdf.inputs['Emission Strength']
                                for link in list(strength.links):
                                    material.node_tree.links.remove(link)
                                strength.default_value = 0.
                        changes.append(dict(paperFloorNonemissive=True, objectRole='ondol/floor'))
                    # Remove disconnected Sarang-only coordinate branches so a
                    # later graph audit cannot mistake them for active mappings.
                    keep = _live(material.node_tree)
                    for node in list(material.node_tree.nodes):
                        if node not in keep:
                            material.node_tree.nodes.remove(node)
                    material['portableR16Building'] = buildingKey
                    material['referenceColourProfile'] = role
                    material['portableR16SourceMaterial'] = old.name
                    material['portableR16Template'] = template.name
                    material['portableR16Schema'] = json.dumps(schema)
                    cache[key] = material
                    receipt['materials'].append(dict(material=material.name, role=role,
                        source=old.name, template=template.name, mapping=changes,
                        masterRoleAuthoritative=True,
                        masterTags={tag: str(template.get(tag)) for tag in
                                    ('hs16_master_role', 'warmth_role', 'referenceColourProfile')
                                    if template.get(tag) is not None},
                        attributeSchema=[list(a) for a in schema[0]], uvLayers=list(schema[1])))
                row.update(material=cache[key].name, template=template.name)
                planned.append((ob, index, old, slot.link, cache[key], row))
            except Exception as exc:
                receipt['errors'].append(dict(**row, error=str(exc), errorType=type(exc).__name__))
    if buildingKey == 'sadang':
        paint = [r for r in receipt['preserved'] if r['role'] == 'paint']
        receipt['sadangProtectedPaintSlots'] = len(paint)
        if len(paint) != 105:
            receipt['errors'].append(dict(error='Expected exactly 105 protected Sadang paint slots', actual=len(paint)))
    if receipt['errors']:
        raise MappingError(receipt)
    applied = []
    try:
        for ob, index, old, link, material, row in planned:
            slot = ob.material_slots[index]
            slot.link = 'OBJECT'
            slot.material = material
            applied.append((ob, index, old, link))
            receipt['assignments'].append(row)
        if before != {o.as_pointer(): _state(o) for o in meshes}:
            raise RuntimeError('Source mesh, schema, hierarchy or transform changed')
        for row in receipt['preserved']:
            if sc.objects[row['object']].material_slots[row['slot']].material.name != row['oldMaterial']:
                raise RuntimeError('Protected material slot changed: ' + row['object'])
    except Exception as exc:
        for ob, index, old, link in reversed(applied):
            ob.material_slots[index].material = old
            ob.material_slots[index].link = link
        receipt['assignments'] = []
        receipt['errors'].append(dict(error=str(exc), rolledBackSlots=len(applied)))
        raise MappingError(receipt) from exc
    receipt.update(passed=True, changedSlots=len(planned), copiedMaterials=len(cache),
                   changedObjects=len({o.name for o, *_ in planned}),
                   roleCounts=dict(Counter(r['role'] for r in receipt['assignments'])),
                   sourceMeshSchemaHierarchyTransformsUnchanged=True,
                   changedSlotsAllObjectLinked=True)
    return receipt
