"""Fresh reopen proof for the one-building native lookdev candidate."""
import bpy
import hashlib
import json
import sys
from pathlib import Path

OUT = Path(__file__).resolve().parent
sys.path.insert(0, str(OUT))
from render_lookdev import geometry_state, PLAQUES, sha, EXPECTED, NATIVE

before = json.loads((OUT / 'geometry-before.json').read_text(encoding='utf-8'))
objects = [bpy.data.objects[name] for name in before]
actual = geometry_state(objects)
# JSON normalizes modifier tuples to arrays.
assert json.loads(json.dumps(actual)) == before
assert len([o for o in bpy.context.scene.objects if o.type == 'MESH']) == 710
plaque = {}
for name in sorted(PLAQUES):
    ob = bpy.data.objects[name]
    assert all(not s.material.name.startswith('LOOKDEV') for s in ob.material_slots)
    images = []
    for slot in ob.material_slots:
        if slot.material and slot.material.use_nodes:
            for node in slot.material.node_tree.nodes:
                if node.type == 'TEX_IMAGE' and node.image:
                    image = node.image
                    images.append(dict(name=image.name, size=list(image.size), packed=bool(image.packed_file),
                        packedSha256=hashlib.sha256(image.packed_file.data).hexdigest() if image.packed_file else None))
    plaque[name] = dict(materials=[s.material.name if s.material else None for s in ob.material_slots], images=images)
for name in ['Sarang.dark original plaque', 'Sarang.light original plaque']:
    master = next(x for x in plaque[name]['images'] if x['name'] == 'master-sarangchae.png.001')
    assert master['packedSha256'] == 'f917724120d4080d7c004b65dc51a9c336fcfbccdb9997e830de06ead1bcfc1a'
assert sha(NATIVE) == EXPECTED
result = dict(passed=True, freshReopen=True, exactGeometryUvsTransformsModifiersEqual=True,
    exactSourceMembers=710, sourceNativeSha256=EXPECTED, sourceNativeUnchanged=True,
    candidateNativeSha256=sha(OUT / 'sarang-lookdev-candidate.blend'),
    originalPlaques=plaque, candidateApproved=False, glbConverted=False, appIntegrated=False)
(OUT / 'saved-native-verification.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('FRESH SAVED NATIVE VERIFIED', len(objects), flush=True)
