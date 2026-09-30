"""Replace photographic shrine gable pigment with a distinct painted walnut.

The existing plank geometry, spacing, authored UVs and other shrine paint remain.
The photographic source stays on disk; the new image is a review-only material.
"""
from collections import Counter
from pathlib import Path
import hashlib
import json
import sys

import bpy

sys.path.insert(0, str(Path(__file__).parent))
from repair_masonry_coping import fingerprint
from apply_estate_matte_register import owner_of

N = Path(__file__).resolve().parents[2] / 'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
TARGET = N / 'estate-fabric.blend'
IMAGE = N / 'materials/hanok-shrine-gable-painted-v1.png'
MATERIAL = 'Canonical gate wood pigment.004'
sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()


def apply_shrine_gable_art(scene):
    assert not scene.get('gyeShrineGableV1'), 'Shrine gable art already applied'
    before = {ob.name: fingerprint(ob) for ob in scene.objects if ob.type == 'MESH'}
    mat = bpy.data.materials[MATERIAL]
    shader = next(node for node in mat.node_tree.nodes if node.type == 'BSDF_PRINCIPLED')
    texture = shader.inputs['Base Color'].links[0].from_node
    assert texture.type == 'TEX_IMAGE' and texture.image
    source = Path(bpy.path.abspath(texture.image.filepath)).resolve()
    source_sha = sha(source)
    counts = Counter()
    objects = []
    for ob in scene.objects:
        if ob.type != 'MESH':
            continue
        count = sum(ob.data.materials[p.material_index] == mat for p in ob.data.polygons)
        if count:
            counts[owner_of(ob)] += count
            objects.append(ob.name)
    assert set(counts) == {'sadang'} and counts['sadang'] > 500, counts
    texture.image = bpy.data.images.load(str(IMAGE), check_existing=True)
    mat['gyeShrineGableV1'] = True
    mat['styleCharacter'] = 'Sun-bleached warm walnut-grey, distinct painted shrine gable fibres'
    assert all(fingerprint(bpy.data.objects[name]) == expected for name, expected in before.items())
    assert sha(source) == source_sha
    scene['gyeShrineGableV1'] = True
    return {'material': MATERIAL, 'image': IMAGE.name, 'imageSha256': sha(IMAGE),
            'originalImage': str(source), 'originalImageSha256': source_sha,
            'facesByOwner': dict(counts), 'objects': objects,
            'geometryUvAndMaterialSlotsChanged': False, 'otherShrinePaintChanged': False,
            'runtimePromotion': False}


if __name__ == '__main__':
    bpy.ops.wm.open_mainfile(filepath=str(TARGET))
    path = N / 'estate-fabric-contract.json'
    contract = json.loads(path.read_text(encoding='utf8'))
    source_sha = sha(TARGET)
    report = apply_shrine_gable_art(bpy.context.scene)
    report['sourceSceneSha256'] = source_sha
    bpy.ops.wm.save_as_mainfile(filepath=str(TARGET), compress=True)
    contract['gyeShrineGable'] = report
    contract['candidateSceneSha256'] = sha(TARGET)
    path.write_text(json.dumps(contract, ensure_ascii=False, indent=2), encoding='utf8')
    print('SHRINE GABLE ART', report['facesByOwner'], flush=True)
