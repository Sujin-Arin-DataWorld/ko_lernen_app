"""Read canonical native sources without editing, saving Blender data, or rendering."""
import bpy
import collections
import datetime
import hashlib
import json
import struct
from pathlib import Path

P = Path(__file__).resolve().parent
ROOT = P.parents[3]
CAN = P.parents[2]
DEST = P / 'BUILDING_TRANSFER_INVENTORY_R16.json'


def read(path):
    return json.loads(path.read_text(encoding='utf-8')) if path.exists() else {}


def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def plain(value):
    if isinstance(value, (str, int, float, bool)) or value is None:
        return value
    if hasattr(value, 'to_dict'):
        return {str(k): plain(v) for k, v in value.to_dict().items()}
    if hasattr(value, '__iter__'):
        return [plain(v) for v in value]
    return str(value)


manifest_path = ROOT / 'canonical-11-20261023/CANONICAL_MANIFEST.json'
manifest = read(manifest_path)
all_candidates = list(P.rglob('*.blend'))
out = dict(
    schemaVersion=1,
    generatedAt=datetime.datetime.now(datetime.timezone.utc).isoformat(),
    inspection='Read-only canonical Blender scene inspection, filesystem hashes and JSON/GLB metadata; no native saves or renders',
    root=str(ROOT), canonicalReview=str(CAN), productionRoot=str(P),
    canonicalManifest=str(manifest_path), buildings=[],
    constraints=[
        'Preserve exact registered native source bytes and use separate review candidates.',
        'Preserve original object names, geometry, transforms, normals, UVs, attributes, hierarchy and custom properties.',
        'Retain sourceObject/reviewStage/processId from CAN/models/key.glb for every canonical mesh; native fallback requires an existing explicit reviewStage.',
        'Protect plaques, calligraphy, painted patterns, pigment/paint/preserve/backing slots, source image bytes and original material graphs.',
        'Do not recreate retired V2 folders or imply canonical promotion/runtime integration.',
        'Keep window-paper and paper-floor emissions separate; do not copy Sarang-only visual replacement geometry to other buildings.',
    ],
    compatibilityWarnings=[
        'CURRENT_SCOPE.json still says sarang-only and is superseded by the new direct user request reported by root.',
        'produce.material_rows expects a list; changgo inventory is a materialSlots dictionary and requires normalization.',
        'toilet/toilet1 have no source material-inventory.json; classify occupied native slots from actual material evidence.',
        'sarang_wood.profile has Sarang-specific name rules and unmatched timber defaults to beam; review building-specific roles.',
        'wood_individual_r14.apply enforces exactly three Sarang ondol floor corrections; decouple this before reuse.',
        'wood14 requires hs12_wood_direction/referenceColourProfile and HS12 ramps; grain15 requires hs14_individual_wood and authored wood texture.',
    ],
)

for building in manifest['buildings']:
    key = building['key']
    source = ROOT / building['native']['path']
    source_hash = sha(source)
    inventory_path = source.parent / 'material-inventory.json'
    inventory = read(inventory_path)
    rows = inventory if isinstance(inventory, list) else inventory.get('materialSlots', [])
    verification_path = source.parent / 'verification.json'
    verification = read(verification_path)
    glb = CAN / 'models' / (key + '.glb')
    with glb.open('rb') as stream:
        stream.read(12)
        size, chunk_type = struct.unpack('<II', stream.read(8))
        gltf = json.loads(stream.read(size))
    stage_nodes = [n['extras'] for n in gltf.get('nodes', []) if 'reviewStage' in n.get('extras', {})]
    bpy.ops.wm.open_mainfile(filepath=str(source))
    scene = bpy.context.scene
    meshes = [ob for ob in scene.objects if ob.type == 'MESH']
    attributes = collections.Counter()
    uv_names = collections.Counter()
    mats = {}
    occupied_slots = 0
    objects_missing_member_id = []
    for ob in meshes:
        for uv in ob.data.uv_layers:
            uv_names[uv.name] += 1
        for attr in ob.data.attributes:
            if attr.name.startswith('P18') or 'member' in attr.name.lower() or 'cut' in attr.name.lower():
                attributes[(attr.name, attr.domain, attr.data_type)] += 1
        used = {poly.material_index for poly in ob.data.polygons}
        for index, slot in enumerate(ob.material_slots):
            mat = slot.material
            if index not in used or mat is None:
                continue
            occupied_slots += 1
            if mat.name not in mats:
                props = {name: plain(mat[name]) for name in mat.keys() if name != '_RNA_UI'}
                nodes = list(mat.node_tree.nodes) if mat.use_nodes and mat.node_tree else []
                relevant = [dict(type=n.type, label=n.label, image=n.image.filepath if n.type == 'TEX_IMAGE' and n.image else None)
                            for n in nodes if n.type == 'TEX_IMAGE' or ('member' in n.label.lower()) or ('cut' in n.label.lower())]
                tags = {k: v for k, v in props.items() if k in ('craft_role', 'craft_usage', 'r6_role', 'r5_role', 'referenceColourProfile', 'freshMaterialProfile', 'hs2_role', 'hs12_wood_direction', 'hs14_individual_wood', 'hs15_individual_grain')}
                mats[mat.name] = dict(name=mat.name, properties=props, roleTags=tags, relevantNodes=relevant,
                                      hasAuthoredWood=any(n.type == 'TEX_IMAGE' and n.label == 'Craft authored wood detail' for n in nodes),
                                      hasOriginalCutAtlas=any(n.type == 'TEX_IMAGE' and ('endgrain' in n.label.lower() or 'cut wood atlas' in n.label.lower()) for n in nodes))
    material_rows = list(mats.values())
    candidate_paths = [f for f in all_candidates if f.parts[-2] == key or f.name.startswith(key + '-')]
    base = P / key / (key + '-hangulsori-r2-refined.blend')
    candidate_receipt = read(P / key / 'verification.json')
    record = dict(
        key=key, name=building['name'], canonicalRevision=building['revision'],
        canonicalNative=str(source), canonicalExpectedSha256=building['native']['sha256'], canonicalActualSha256=source_hash,
        canonicalHashMatches=source_hash == building['native']['sha256'], canonicalBytes=source.stat().st_size,
        sourceVerification=str(verification_path), sourceMeshCount=verification.get('meshCount'), actualMeshCount=len(meshes),
        materialInventory=str(inventory_path) if inventory_path.exists() else None,
        inventorySchema='list' if isinstance(inventory, list) else 'materialSlots dictionary' if inventory_path.exists() else 'missing',
        inventorySlotCount=len(rows), inventoryRoles=dict(collections.Counter(r.get('role') for r in rows)),
        inventoryPreservedSlots=sum(bool(r.get('preserved')) for r in rows),
        constructionGLB=str(glb), glbStageBindingCount=len(stage_nodes),
        existingProductionCandidates=[str(f) for f in candidate_paths],
        existingProductionBase=str(base) if base.exists() else None,
        productionGeometryLock=str(P / key / 'geometry-lock.json') if (P / key / 'geometry-lock.json').exists() else None,
        productionBinding=str(P / key / 'construction-binding.json') if (P / key / 'construction-binding.json').exists() else None,
        uvLayers=[dict(name=k, objects=v) for k, v in uv_names.items()],
        memberAndCutAttributes=[dict(name=k[0], domain=k[1], type=k[2], objects=v) for k, v in attributes.items()],
        occupiedMaterialSlots=occupied_slots, uniqueMaterials=len(material_rows),
        authoredWoodMaterialCount=sum(m['hasAuthoredWood'] for m in material_rows),
        originalCutAtlasMaterialCount=sum(m['hasOriginalCutAtlas'] for m in material_rows),
        hs12TaggedMaterialCount=sum(bool(m['properties'].get('hs12_wood_direction')) for m in material_rows),
        referenceProfileMaterialCount=sum(bool(m['properties'].get('referenceColourProfile')) for m in material_rows),
        materials=material_rows,
        sourceUnchangedAfterInspection=sha(source) == source_hash,
    )
    if base.exists():
        record['productionBaseActualSha256'] = sha(base)
        record['productionBaseReceiptMatches'] = record['productionBaseActualSha256'] == candidate_receipt.get('nativeSha256')
        record['productionGeometry'] = candidate_receipt.get('geometry')
    out['buildings'].append(record)
    out['buildingCount'] = len(out['buildings'])
    out['allCanonicalHashesMatch'] = all(r['canonicalHashMatches'] for r in out['buildings'])
    DEST.write_text(json.dumps(out, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('TRANSFER INSPECTED', key, len(meshes), 'meshes', len(material_rows), 'materials', record['authoredWoodMaterialCount'], 'authored wood', flush=True)

out['complete'] = len(out['buildings']) == manifest['buildingCount']
material_details = dict(schemaVersion=1, inspection=out['inspection'], buildings={})
details_path = P / 'BUILDING_TRANSFER_MATERIAL_DETAILS_R16.json'
for record in out['buildings']:
    material_details['buildings'][record['key']] = record.pop('materials')
    record['materialDetailsFile'] = str(details_path)
    record['materialDetailsKey'] = record['key']
details_path.write_text(json.dumps(material_details, ensure_ascii=False, separators=(',', ':')) + '\n', encoding='utf-8')
DEST.write_text(json.dumps(out, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('TRANSFER INVENTORY COMPLETE', str(DEST), flush=True)
