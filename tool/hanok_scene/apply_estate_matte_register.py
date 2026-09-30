"""Unify matte ceramic/timber finish and quiet two golden timber outliers.

Retain authored pigment, component grain UVs, forms and door hinges. This is
a shader pass on the existing illustrated candidate, not source-image editing.
"""
from collections import Counter, defaultdict
from pathlib import Path
import hashlib
import json
import sys

import bpy

sys.path.insert(0, str(Path(__file__).parent))
from repair_masonry_coping import fingerprint

N = Path(__file__).resolve().parents[2] / 'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
TARGET = N / 'estate-fabric.blend'
WOOD_OUTLIERS = {
    'Reference ansarang wood': ('ansarang', .74, .67),
    'Reference anchae wood': ('anchae', .84, .86),
}


def surface_role(name):
    name = name.lower()
    if any(word in name for word in ('plaque', 'finial', 'hanji', 'fissures')):
        return None
    if any(word in name for word in ('tile', 'ceramic', 'giwa')) or name.startswith('illustrated clay v1 '):
        return 'roof'
    if any(word in name for word in ('wood', 'timber', 'walnut', 'pine')):
        return 'wood'
    return None


def owner_of(ob):
    return ob.get('construction_building') or ('jung' if 'jung' in ob.name.lower() else 'sarang')


def timber_needs_bake(material):
    """A direct image/UV pair exports intact; colour/vector math needs baking."""
    shader = next(node for node in material.node_tree.nodes if node.type == 'BSDF_PRINCIPLED')
    if not shader.inputs['Base Color'].is_linked:
        return False
    source = shader.inputs['Base Color'].links[0].from_node
    if source.type != 'TEX_IMAGE':
        return True
    vector = source.inputs['Vector']
    return vector.is_linked and vector.links[0].from_node.type not in ('UVMAP', 'TEX_COORD')


def apply_estate_matte_register(scene, extend=False):
    assert extend or not scene.get('gyeMatteSurfaceV1'), 'Matte finish already applied'
    protected = {ob.name: fingerprint(ob) for ob in scene.objects if ob.type == 'MESH'}
    owners = defaultdict(Counter)
    for ob in scene.objects:
        if ob.type != 'MESH':
            continue
        for slot, count in Counter(poly.material_index for poly in ob.data.polygons).items():
            material = ob.data.materials[slot]
            if material and surface_role(material.name):
                owners[material.name][owner_of(ob)] += count
    images = {}
    finishes = {}
    timber = {}
    for name, counts in sorted(owners.items()):
        material = bpy.data.materials[name]
        if extend and material.get('gyeMatteSurfaceV1'):
            continue
        role = surface_role(name)
        nodes, links = material.node_tree.nodes, material.node_tree.links
        shader = next(node for node in nodes if node.type == 'BSDF_PRINCIPLED')
        roughness = .92 if role == 'roof' else .90
        before = {}
        for socket, value in (('Roughness', roughness), ('Specular IOR Level', .12),
                              ('Metallic', 0), ('Coat Weight', 0)):
            inp = shader.inputs[socket]
            before[socket] = {'value': float(inp.default_value),
                              'source': inp.links[0].from_node.name if inp.is_linked else None}
            for link in list(inp.links):
                links.remove(link)
            inp.default_value = value
        normal_changes = []
        for node in nodes:
            if node.type == 'TEX_IMAGE' and node.image:
                path = Path(bpy.path.abspath(node.image.filepath)).resolve()
                if path.is_file():
                    images[str(path)] = hashlib.sha256(path.read_bytes()).hexdigest()
            elif node.type in ('NORMAL_MAP', 'BUMP'):
                strength = node.inputs['Strength']
                old = float(strength.default_value)
                strength.default_value = min(old, .15 if role == 'roof' else .18)
                normal_changes.append({'node': node.name, 'before': old,
                                       'after': float(strength.default_value)})
        material['gyeMatteSurfaceV1'] = role
        finishes[name] = {'role': role, 'roughness': roughness, 'specular': .12,
                          'metallic': 0, 'coat': 0, 'before': before,
                          'normalStrength': normal_changes, 'facesByOwner': dict(counts)}
        if name not in WOOD_OUTLIERS:
            continue
        owner, saturation, value = WOOD_OUTLIERS[name]
        assert set(counts) == {owner}, (name, counts)
        assert shader.inputs['Base Color'].is_linked
        source = shader.inputs['Base Color'].links[0].from_socket
        assert source.node.type == 'TEX_IMAGE' and source.node.image, name
        tint = nodes.new('ShaderNodeHueSaturation')
        tint.name = 'Gye sun-aged walnut pigment'
        tint.inputs['Saturation'].default_value = saturation
        tint.inputs['Value'].default_value = value
        tint.inputs['Fac'].default_value = 1
        links.new(source, tint.inputs['Color'])
        links.new(tint.outputs['Color'], shader.inputs['Base Color'])
        material['gyeWalnutPigmentV1'] = True
        timber[owner] = {'material': name, 'saturation': saturation, 'value': value,
                         'sourceImage': source.node.image.name, 'faces': counts[owner]}
    assert (not timber if extend else set(timber) == {'anchae', 'ansarang'})
    assert all(fingerprint(bpy.data.objects[name]) == expected for name, expected in protected.items())
    assert all(hashlib.sha256(Path(path).read_bytes()).hexdigest() == value for path, value in images.items())
    scene['gyeMatteSurfaceV1'] = True
    return {'materials': finishes, 'timberOutliers': timber, 'originalImages': images,
            'geometryUvAndMaterialSlotsChanged': False, 'runtimePromotion': False}


if __name__ == '__main__':
    bpy.ops.wm.open_mainfile(filepath=str(TARGET))
    path = N / 'estate-fabric-contract.json'
    contract = json.loads(path.read_text(encoding='utf8'))
    source_sha = hashlib.sha256(TARGET.read_bytes()).hexdigest()
    extend = '--extend' in sys.argv
    report = apply_estate_matte_register(bpy.context.scene, extend=extend)
    if extend:
        existing = contract['gyeMatteSurface']
        existing['materials'].update(report['materials'])
        existing['originalImages'].update(report['originalImages'])
        existing['extendedMaterials'] = sorted(report['materials'])
        report = existing
    else:
        report['sourceSceneSha256'] = source_sha
    bpy.ops.wm.save_as_mainfile(filepath=str(TARGET), compress=True)
    contract['gyeMatteSurface'] = report
    contract['candidateSceneSha256'] = hashlib.sha256(TARGET.read_bytes()).hexdigest()
    path.write_text(json.dumps(contract, ensure_ascii=False, indent=2), encoding='utf8')
    print('MATTE SURFACE REGISTER', len(report['materials']), report['timberOutliers'], flush=True)
