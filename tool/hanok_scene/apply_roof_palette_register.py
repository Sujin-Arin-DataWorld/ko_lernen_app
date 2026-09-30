"""Bring blue and overly dark roof outliers into the estate charcoal family.

Keep each original tile image, UV and roof silhouette. The gentle desaturation
is a review material layer, not a replacement for the canonical artwork.
"""
from pathlib import Path
import hashlib
import json

import bpy


ROOT = Path(__file__).resolve().parents[2]
N = ROOT / 'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
TARGET = N / 'estate-fabric.blend'
ROOFS = {
    'anchae': ('Reference anchae tile', .15, 1.75, .92),
    'sadang': ('Reference sadang roof ceramic corrected', .16, .98, .92),
    'ansarang': ('Reference ansarang tile', .18, .86, .92),
    'sadangmun': ('Reference sadangmun tile', .30, .82, .92),
}


def apply_roof_palette_register(scene, owners=None):
    assert owners is not None or not scene.get('gyeRoofPaletteV1'), 'Roof palette already applied'
    report = {}
    for owner, (name, saturation, value, roughness) in ROOFS.items():
        if owners is not None and owner not in owners:
            continue
        material = bpy.data.materials[name]
        shader = next(node for node in material.node_tree.nodes if node.type == 'BSDF_PRINCIPLED')
        assert shader.inputs['Base Color'].is_linked, name
        source = shader.inputs['Base Color'].links[0].from_socket
        assert source.node.type == 'TEX_IMAGE' and source.node.image, name
        image = source.node.image
        image_path = Path(bpy.path.abspath(image.filepath)).resolve()
        assert image_path.is_file(), image_path
        nodes, links = material.node_tree.nodes, material.node_tree.links
        assert not nodes.get('Gye low-chroma giwa'), name
        tint = nodes.new('ShaderNodeHueSaturation')
        tint.name = 'Gye low-chroma giwa'
        tint.inputs['Hue'].default_value = .5
        tint.inputs['Saturation'].default_value = saturation
        tint.inputs['Value'].default_value = value
        tint.inputs['Fac'].default_value = 1
        links.new(source, tint.inputs['Color'])
        links.new(tint.outputs['Color'], shader.inputs['Base Color'])
        old_roughness = float(shader.inputs['Roughness'].default_value)
        shader.inputs['Roughness'].default_value = roughness
        faces = other_faces = 0
        for ob in scene.objects:
            if ob.type != 'MESH':
                continue
            count = sum(ob.data.materials[polygon.material_index] == material
                        for polygon in ob.data.polygons)
            if ob.get('construction_building') == owner:
                faces += count
            else:
                other_faces += count
        assert faces > 1000 and not other_faces, (name, faces, other_faces)
        report[owner] = {
            'material': name, 'image': image.name,
            'sourceImageSha256': hashlib.sha256(image_path.read_bytes()).hexdigest(),
            'saturation': saturation, 'value': value,
            'roughnessBefore': old_roughness, 'roughnessAfter': roughness,
            'faces': faces, 'otherBuildingFaces': other_faces,
        }
    scene['gyeRoofPaletteV1'] = True
    return {'tileFamily': '#393B35', 'outliersAdjusted': report,
            'otherRoofMaterialsUntouched': True, 'sourceImagesChanged': False,
            'roofGeometryChanged': False, 'runtimePromotion': False}


if __name__ == '__main__':
    bpy.ops.wm.open_mainfile(filepath=str(TARGET))
    contract_path = N / 'estate-fabric-contract.json'
    contract = json.loads(contract_path.read_text(encoding='utf8'))
    if '--extend' in __import__('sys').argv:
        report = contract['gyeRoofPalette']
        owners = set(ROOFS) - set(report['outliersAdjusted'])
        assert owners, 'No unprocessed roof owners'
        addition = apply_roof_palette_register(bpy.context.scene, owners=owners)
        report['outliersAdjusted'].update(addition['outliersAdjusted'])
    else:
        report = apply_roof_palette_register(bpy.context.scene)
    bpy.ops.wm.save_as_mainfile(filepath=str(TARGET), compress=True)
    contract['gyeRoofPalette'] = report
    contract['candidateSceneSha256'] = hashlib.sha256(TARGET.read_bytes()).hexdigest()
    contract_path.write_text(json.dumps(contract, ensure_ascii=False, indent=2), encoding='utf8')
    print('ROOF PALETTE REGISTER', {owner: record['faces']
                                    for owner, record in report['outliersAdjusted'].items()}, flush=True)
