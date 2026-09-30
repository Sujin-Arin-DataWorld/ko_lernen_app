"""Give the three shared-pine service buildings distinct illustrated grain.

The approved timber art on the other estate buildings remains as authored.
This is a review-only color surface pass; solid geometry and UVs stay intact.
"""
from pathlib import Path
import hashlib
import json
import sys

import bpy


ROOT = Path(__file__).resolve().parents[2]
N = ROOT / 'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
TARGET = N / 'estate-fabric.blend'
SOURCE_MATERIAL = 'Illustrated pine longgrain v1'
REGISTER = {
    'arae': ('hanok-pine-arae-painted-v1.png', 'sun-warmed hand-painted fine fibre'),
    'angotgan': ('hanok-pine-angotgan-painted-v1.png', 'smoke-aged cool umber fine fibre'),
    'gokgan': ('hanok-pine-gokgan-painted-v1.png', 'drier broad fibre and rubbed pigment'),
}


def apply_building_wood_register(scene):
    assert not scene.get('gyeTimberRegisterV1'), 'Building timber register already applied'
    source = bpy.data.materials[SOURCE_MATERIAL]
    report = {}
    for building, (filename, character) in REGISTER.items():
        asset = N / 'materials' / filename
        assert asset.is_file(), f'Missing painted timber: {asset}'
        mat = source.copy()
        mat.name = f'Gye {building} painted pine v1'
        color_nodes = [node for node in mat.node_tree.nodes
                       if node.type == 'TEX_IMAGE' and node.image and
                       Path(node.image.filepath).name == 'hanok-pine-longgrain-v1.png']
        assert len(color_nodes) == 1, f'Unexpected color node for {building}'
        color_nodes[0].image = bpy.data.images.load(str(asset), check_existing=True)
        normal_nodes = [node for node in mat.node_tree.nodes if node.type == 'NORMAL_MAP']
        assert len(normal_nodes) == 1
        normal_nodes[0].inputs['Strength'].default_value = .22
        mat['styleCharacter'] = character
        mat['surfaceAuthority'] = 'Gye-inspired illustrated candidate, distinct per building'
        meshes = faces = 0
        for ob in scene.objects:
            if ob.type != 'MESH' or ob.get('construction_building') != building:
                continue
            indices = [i for i, current in enumerate(ob.data.materials)
                       if current and current.name == SOURCE_MATERIAL]
            if not indices:
                continue
            # Do not let a shared mesh datablock tint a different building.
            if ob.data.users > 1:
                ob.data = ob.data.copy()
            for index in indices:
                faces += sum(poly.material_index == index for poly in ob.data.polygons)
                ob.data.materials[index] = mat
            meshes += 1
        assert meshes and faces > 1000, f'No shared pine replaced in {building}'
        report[building] = {
            'material': mat.name, 'paintedImage': filename,
            'paintedImageSha256': hashlib.sha256(asset.read_bytes()).hexdigest(),
            'character': character, 'meshes': meshes, 'faces': faces,
            'grainUvAndGeometryPreserved': True,
        }
    assert len({item['paintedImageSha256'] for item in report.values()}) == len(report)
    scene['gyeTimberRegisterV1'] = True
    return {'buildings': report, 'otherBuildingArtworkChanged': False,
            'originalPineAlbedoBytesChanged': False, 'runtimePromotion': False}


if __name__ == '__main__':
    bpy.ops.wm.open_mainfile(filepath=str(TARGET))
    scene = bpy.context.scene
    contract_path = N / 'estate-fabric-contract.json'
    contract = json.loads(contract_path.read_text(encoding='utf8'))
    if '--refresh' in sys.argv:
        previous = contract['gyeTimberRegister']['buildings']
        source = bpy.data.materials[SOURCE_MATERIAL]
        for building, record in previous.items():
            current = bpy.data.materials[record['material']]
            for ob in scene.objects:
                if ob.type == 'MESH' and ob.get('construction_building') == building:
                    for index, mat in enumerate(ob.data.materials):
                        if mat == current:
                            ob.data.materials[index] = source
            assert current.users == 0
            bpy.data.materials.remove(current)
        del scene['gyeTimberRegisterV1']
    report = apply_building_wood_register(scene)
    bpy.ops.wm.save_as_mainfile(filepath=str(TARGET), compress=True)
    contract['gyeTimberRegister'] = report
    contract['candidateSceneSha256'] = hashlib.sha256(TARGET.read_bytes()).hexdigest()
    contract_path.write_text(json.dumps(contract, ensure_ascii=False, indent=2), encoding='utf8')
    print('BUILDING WOOD REGISTER', {key: value['faces']
                                     for key, value in report['buildings'].items()}, flush=True)
