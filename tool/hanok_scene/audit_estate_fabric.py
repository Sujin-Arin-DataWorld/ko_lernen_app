"""Read-only native/delivery checks for the rear toilet and estate fabric."""
from pathlib import Path
from collections import Counter, defaultdict
import hashlib
import json
import struct
import sys
import bpy
import numpy as np

sys.path.insert(0, str(Path(__file__).parent))
from refine_northern_materials import geometry_fingerprint
from repair_masonry_coping import fingerprint, masonry_audit, TIMBER_SUFFIXES
from apply_plaster_wash_register import UV_NAME as PLASTER_UV
from apply_stone_pigment_register import UV_NAME as STONE_UV, TOILET_MATERIAL
from apply_estate_matte_register import surface_role, owner_of, timber_needs_bake
from apply_shrine_gable_art import MATERIAL as GABLE_MATERIAL
from audit_timber_arris import audit_timber_arris
from apply_heritage_wood import UV_NAME as HERITAGE_UV
from audit_requested_craft import audit_requested_craft

ROOT = Path(__file__).resolve().parents[2]
N = ROOT / 'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
D = Path('C:/dev/hangulsori/sites/ildu-survey-review-20260929/dist/estate')
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
contract = json.loads((N / 'estate-fabric-contract.json').read_text(encoding='utf8'))
replaced = set(contract['harmonizedWalls']['replacedObjects'])
aligned = set(contract.get('warehouseWallAlignment', {}).get('movedObjects', []))
clearance_walls = {row['object'] for row in contract.get('gokganRearClearance', {}).get('movedObjects', [])}
bpy.ops.wm.open_mainfile(filepath=str(N / 'detail-redraw.blend'))
geometry = {o.name: geometry_fingerprint(o) for o in bpy.context.scene.objects if o.type == 'MESH' and o.name not in replaced | aligned | clearance_walls}
protected = {o.name: fingerprint(o) for o in bpy.context.scene.objects if o.type == 'MESH' and o.name not in replaced | aligned | clearance_walls and o.get('construction_building') not in ('arae', 'angotgan', 'gokgan', 'changgo') and o.name != 'ConnectionSite.continuous earth'}
bpy.ops.wm.open_mainfile(filepath=str(N / 'estate-fabric.blend'))
changed_geometry = [name for name, value in geometry.items() if name not in bpy.data.objects or geometry_fingerprint(bpy.data.objects[name]) != value]
stone_aliases = contract.get('gyeStonePigment', {}).get('slotMaterialAliases', {})
changed_protected = [name for name, value in protected.items() if name not in bpy.data.objects or fingerprint(bpy.data.objects[name], ignore_uv_layers={PLASTER_UV, STONE_UV, HERITAGE_UV}, material_name_aliases=stone_aliases) != value]
def y_limits(name):
    ob = bpy.data.objects[name]
    values = [(ob.matrix_world @ v.co).y for v in ob.data.vertices]
    return min(values), max(values)
post_y = (y_limits('V28.changgo.bay3.leaf2.boards')[1] + y_limits('V28.changgo.bay4.leaf1.boards')[0]) / 2
wall_core = bpy.data.objects['V27.left_changgo.wall to warehouse.earth core']
wall_end_y = np.mean([(wall_core.matrix_world @ v.co).y for v in wall_core.data.vertices
                      if (wall_core.matrix_world @ v.co).x < -7.15])
wall_gate_y = np.mean([(wall_core.matrix_world @ v.co).y for v in wall_core.data.vertices
                       if (wall_core.matrix_world @ v.co).x > -4.39])
walls = [o for o in bpy.context.scene.objects if o.type == 'MESH' and o.get('construction_building') == 'estate_wall']
# Plain earth bedding and lime tile-end caps use shader colour, so do not need
# image coordinates. Check every wall mesh that actually uses an image texture.
textured_walls = [o for o in walls if any(
    m and m.use_nodes and any(n.type == 'TEX_IMAGE' and n.image for n in m.node_tree.nodes)
    for i in {p.material_index for p in o.data.polygons}
    for m in [o.data.materials[i]])]
missing_uv = [o.name for o in textured_walls if not o.data.uv_layers]
timber_on_caps = [o.name for o in walls if o.name.endswith(TIMBER_SUFFIXES)]
toilet = [o for o in bpy.context.scene.objects if o.type == 'MESH' and o.get('construction_building') == 'toilet1']
points = np.array([o.matrix_world @ v.co for o in toilet for v in o.data.vertices])
material_audit = masonry_audit(bpy.context.scene)
manifest = json.loads((D / 'manifest.json').read_text(encoding='utf8'))
assembled = hashlib.sha256()
chunk_failures = []
for part in manifest['chunks']:
    data = (D / part['file']).read_bytes()
    assembled.update(data)
    if len(data) != part['bytes'] or hashlib.sha256(data).hexdigest() != part['sha256']:
        chunk_failures.append(part['file'])
network = json.loads((N / 'wall-network-inventory.json').read_text(encoding='utf8'))
cores = {r['name']: r for r in network['cores']}
def connected(left, right, tolerance=.12):
    a, b = cores[left], cores[right]
    return bool(min(np.linalg.norm(np.array(p) - q) for p in (a['start'], a['stop'])
                    for q in (b['start'], b['stop'])) < tolerance)
joins = {
    'gateToAnsarang': connected('Forecourt.wall.gate-ansarang.1.core', 'ConnectionGarden.wall5.ochre core'),
    'gwangToByeoldang': connected('Estate.fabric.gwang byeoldang join.earth core', 'ConnectionGarden.wall3.ochre core'),
    'jungTie': connected('Estate.fabric.jung building tie.earth core', 'Estate.fabric.jung to gotgan boundary.earth core'),
    'gotganRear': connected('Estate.fabric.jung to gotgan boundary.earth core', 'Estate.fabric.gotgan rear boundary.earth core'),
    'gotganSouthEdge': connected('Estate.fabric.gotgan rear boundary.earth core', 'Estate.fabric.south edge west.earth core'),
    'southEdgeToForecourt': connected('Estate.fabric.south edge middle.earth core', 'Forecourt.wall.warehouse-toilet.0.core'),
}
forbidden = ('Estate.fabric.byeoldang rear.', 'Estate.fabric.byeoldang east.',
             'Estate.fabric.byeoldang garden south.')
stone_groups = [r for r in bpy.context.scene.objects if r.type == 'MESH' and r.name.endswith('.uneven fieldstone')]
tile_groups = [r for r in bpy.context.scene.objects if r.type == 'MESH' and r.name.startswith(('Estate.fabric.', 'North.site.')) and r.name.endswith(('.pan', '.cover', '.ridge'))]
north_stone = [o for o in stone_groups if o.name.startswith('North.site.')]
style = contract.get('gyeStylePass', {})
style_course = bpy.data.objects.get('GyeStyle.Sarang irregular stone facing')
style_feet = bpy.data.objects.get('GyeStyle.Sarang hand-cut post feet')
garden_objects = [ob for ob in bpy.context.scene.objects if ob.type == 'MESH' and ob.name.startswith('GyeGarden.')]
def style_ramps_match():
    for record in style.get('woodAndRoofRampChanges', []):
        ramp = bpy.data.materials[record['material']].node_tree.nodes[record['ramp']].color_ramp
        for element, expected in zip(ramp.elements, record['new']):
            if max(abs(float(element.color[index]) - expected[index]) for index in range(4)) > .001:
                return False
    return bool(style.get('woodAndRoofRampChanges'))

def style_glazes_match():
    records = style.get('finalTimberGlazes', [])
    for record in records:
        nodes = bpy.data.materials[record['material']].node_tree.nodes
        glaze = nodes.get('Gye aged walnut glaze')
        if not glaze or not glaze.inputs['Color1'].is_linked:
            return False
        if max(abs(glaze.inputs['Color2'].default_value[i] - value)
               for i, value in enumerate(record['linearRgbMultiplier'])) > .001:
            return False
    return len(records) == 2

def wood_register_audit():
    records = contract.get('gyeTimberRegister', {}).get('buildings', {})
    if set(records) != {'arae', 'angotgan', 'gokgan'} or not bpy.context.scene.get('gyeTimberRegisterV1'):
        return {'valid': False, 'reason': 'building register or scene marker missing'}
    findings = {}
    for building, record in records.items():
        path = N / 'materials' / record['paintedImage']
        material = bpy.data.materials.get(record['material'])
        if not path.is_file() or not material or not material.use_nodes:
            return {'valid': False, 'reason': f'{building}: material or image missing'}
        albedos = [node for node in material.node_tree.nodes
                   if node.type == 'TEX_IMAGE' and node.image and
                   Path(node.image.filepath).name == record['paintedImage']]
        normals = [node for node in material.node_tree.nodes if node.type == 'NORMAL_MAP']
        target_faces = other_faces = old_pine_faces = 0
        for ob in bpy.context.scene.objects:
            if ob.type != 'MESH':
                continue
            for polygon in ob.data.polygons:
                current = ob.data.materials[polygon.material_index]
                if not current:
                    continue
                if current == material:
                    if ob.get('construction_building') == building:
                        target_faces += 1
                    else:
                        other_faces += 1
                elif current.name == 'Illustrated pine longgrain v1' and ob.get('construction_building') == building:
                    old_pine_faces += 1
        findings[building] = {
            'imageSha256Matches': sha(path) == record['paintedImageSha256'],
            'albedoNodePresent': len(albedos) == 1,
            'normalStrength': float(normals[0].inputs['Strength'].default_value) if len(normals) == 1 else None,
            'targetFaces': target_faces, 'otherBuildingFaces': other_faces,
            'oldPineFaces': old_pine_faces,
            'recordedFaces': record['faces'],
        }
    warehouse_faces = sum(
        1 for ob in bpy.context.scene.objects
        if ob.type == 'MESH' and ob.get('construction_building') == 'changgo'
        for polygon in ob.data.polygons
        if ob.data.materials[polygon.material_index] and
        ob.data.materials[polygon.material_index].name == 'Warehouse approved illustration wood'
    )
    good = (len({record['paintedImageSha256'] for record in records.values()}) == 3
            and all(item['imageSha256Matches'] and item['albedoNodePresent']
                    and item['normalStrength'] is not None and item['normalStrength'] <= .25
                    and item['targetFaces'] == item['recordedFaces'] and item['otherBuildingFaces'] == 0
                    and item['oldPineFaces'] == 0 for item in findings.values())
            and warehouse_faces > 30000)
    return {'valid': good, 'buildings': findings, 'warehouseApprovedWoodFaces': warehouse_faces}

wood_register = wood_register_audit()
def roof_palette_audit():
    records = contract.get('gyeRoofPalette', {}).get('outliersAdjusted', {})
    if set(records) != {'anchae', 'sadang', 'ansarang', 'sadangmun'} or not bpy.context.scene.get('gyeRoofPaletteV1'):
        return {'valid': False, 'reason': 'roof register or scene marker missing'}
    with (N / 'review3d/current-estate.glb').open('rb') as glb:
        glb.seek(12)
        json_length = struct.unpack('<I', glb.read(4))[0]
        glb.seek(20)
        web_scene = json.loads(glb.read(json_length))
    expected_texcoords = {'anchae': {1, 2}, 'sadang': {0}, 'ansarang': {2}, 'sadangmun': {1}}
    findings = {}
    baked = set(manifest.get('legacyWoodShaderBakes', {}).get('materials', []))
    for owner, record in records.items():
        material = bpy.data.materials.get(record['material'])
        if not material or not material.use_nodes:
            return {'valid': False, 'reason': f'{owner}: roof material missing'}
        tint = material.node_tree.nodes.get('Gye low-chroma giwa')
        shader = next(node for node in material.node_tree.nodes if node.type == 'BSDF_PRINCIPLED')
        image = next((node.image for node in material.node_tree.nodes
                      if node.type == 'TEX_IMAGE' and node.image and node.image.name == record['image']), None)
        image_path = Path(bpy.path.abspath(image.filepath)).resolve() if image else None
        owner_faces = other_faces = 0
        for ob in bpy.context.scene.objects:
            if ob.type != 'MESH':
                continue
            count = sum(ob.data.materials[polygon.material_index] == material
                        for polygon in ob.data.polygons)
            if ob.get('construction_building') == owner:
                owner_faces += count
            else:
                other_faces += count
        findings[owner] = {
            'sourceImageSha256Matches': bool(image_path and image_path.is_file() and
                                             sha(image_path) == record['sourceImageSha256']),
            'nativeTintMatches': bool(tint and shader.inputs['Base Color'].links and
                                      shader.inputs['Base Color'].links[0].from_node == tint and
                                      abs(tint.inputs['Saturation'].default_value - record['saturation']) < .001 and
                                      abs(tint.inputs['Value'].default_value - record['value']) < .001 and
                                      abs(shader.inputs['Roughness'].default_value - record['roughnessAfter']) < .001),
            'webTintBaked': record['material'] in baked,
            'faces': owner_faces, 'otherBuildingFaces': other_faces,
        }
        web_materials = [item for item in web_scene['materials'] if item['name'] == record['material']]
        web_coords = [item.get('pbrMetallicRoughness', {}).get('baseColorTexture', {}).get('texCoord', 0)
                      for item in web_materials]
        findings[owner]['webUvSets'] = web_coords
        findings[owner]['webUvSetsPreserved'] = bool(web_coords and
            all(coord in expected_texcoords[owner] for coord in web_coords))
        findings[owner]['webRoughnessMatches'] = bool(web_materials and all(
            abs(item.get('pbrMetallicRoughness', {}).get('roughnessFactor', 0) - record['roughnessAfter']) < .001
            for item in web_materials))
    return {'valid': all(item['sourceImageSha256Matches'] and item['nativeTintMatches']
                         and item['webTintBaked'] and item['webUvSetsPreserved'] and item['webRoughnessMatches']
                         and item['faces'] == records[owner]['faces']
                         and not item['otherBuildingFaces']
                         for owner, item in findings.items()), 'buildings': findings}

roof_palette = roof_palette_audit()

def plaster_wash_audit():
    register = contract.get('gyePlasterWash', {})
    image_path = N / 'materials' / register.get('image', '')
    if not bpy.context.scene.get('gyePlasterWashV1') or not image_path.is_file():
        return {'valid': False, 'reason': 'Plaster register or image missing'}
    with (N / 'review3d/current-estate.glb').open('rb') as glb:
        glb.seek(12)
        length = struct.unpack('<I', glb.read(4))[0]
        glb.seek(20)
        web_scene = json.loads(glb.read(length))
    findings = {}
    for name, record in register.get('materials', {}).items():
        material = bpy.data.materials.get(name)
        if not material or not material.use_nodes:
            return {'valid': False, 'reason': name + ': missing material'}
        nodes = material.node_tree.nodes
        shader = next(node for node in nodes if node.type == 'BSDF_PRINCIPLED')
        glaze = nodes.get('Gye plaster register glaze')
        mapped = [ob for ob in bpy.context.scene.objects if ob.type == 'MESH' and any(
            ob.data.materials[p.material_index] == material for p in ob.data.polygons)]
        faces = sum(sum(ob.data.materials[p.material_index] == material for p in ob.data.polygons)
                    for ob in mapped)
        mapping_good = all(ob.get('gyePlasterWashV1') and ob.data.uv_layers.get(PLASTER_UV)
                           for ob in mapped)
        native_good = bool(glaze and shader.inputs['Base Color'].is_linked and
            shader.inputs['Base Color'].links[0].from_node == glaze and all(
            abs(glaze.inputs['Color2'].default_value[i] - factor) < .001
            for i, factor in enumerate(record['linearMultiplier'])))
        web_indices = {i for i, item in enumerate(web_scene['materials']) if item.get('name') == name}
        web_good = bool(web_indices)
        uv_sets = []
        for index in web_indices:
            item = web_scene['materials'][index]
            pbr = item.get('pbrMetallicRoughness', {})
            uv_index = pbr.get('baseColorTexture', {}).get('texCoord', 0)
            uv_sets.append(uv_index)
            web_good &= (name in manifest.get('legacyWoodShaderBakes', {}).get('materials', []) and
                         abs(pbr.get('roughnessFactor', 0) - .96) < .001 and
                         'baseColorTexture' in pbr)
            primitives = [p for mesh in web_scene['meshes'] for p in mesh['primitives']
                          if p.get('material') == index]
            web_good &= bool(primitives) and all('TEXCOORD_' + str(uv_index) in p['attributes']
                                                for p in primitives)
        findings[name] = {'nativeGlazeMatches': native_good, 'mappedFaces': faces,
                          'newUvPresent': mapping_good, 'webPigmentAndUvValid': bool(web_good),
                          'webUvSets': uv_sets, 'objects': len(mapped)}
    mapped_names = {row['object'] for row in register.get('mapping', [])}
    actual_new_uv = {ob.name for ob in bpy.context.scene.objects if ob.type == 'MESH' and
                     ob.data.uv_layers.get(PLASTER_UV)}
    valid = (actual_new_uv == mapped_names and sha(image_path) == register['imageSha256'] and len(findings) == 3 and
             all(item['nativeGlazeMatches'] and item['newUvPresent'] and item['webPigmentAndUvValid']
                 and item['mappedFaces'] == register['materials'][name]['faces']
                 for name, item in findings.items()))
    return {'valid': valid, 'materials': findings, 'mappedObjectsMatch': actual_new_uv == mapped_names,
            'imageSha256Matches': sha(image_path) == register['imageSha256']}

plaster_wash = plaster_wash_audit()

def stone_pigment_audit():
    from collections import Counter, defaultdict
    register = contract.get('gyeStonePigment', {})
    image_path = N / 'materials' / register.get('image', '')
    if not bpy.context.scene.get('gyeStonePigmentV2') or not image_path.is_file():
        return {'valid': False, 'reason': 'Stone register or painted image missing'}
    aliases_good = register.get('slotMaterialAliases') == {TOILET_MATERIAL: 'Canonical gate stone pigment.002'}
    original_images_good = all(Path(path).is_file() and sha(Path(path)) == digest
                               for path, digest in register.get('originalImages', {}).items())
    actual_mapping = {ob.name for ob in bpy.context.scene.objects if ob.type == 'MESH' and
                      ob.data.uv_layers.get(STONE_UV)}
    expected_mapping = {row['object'] for row in register.get('mapping', [])}
    scoped_good = all(bpy.data.objects[row['object']].get('construction_building') in ('toilet', 'toilet1') and
                      bpy.data.objects[row['object']].data.materials[row['slot']].name == row['candidate']
                      for row in register.get('scopedMaterialCopies', []))
    counts = Counter()
    objects = defaultdict(set)
    for ob in bpy.context.scene.objects:
        if ob.type != 'MESH':
            continue
        slot_counts = Counter(poly.material_index for poly in ob.data.polygons)
        for slot, count in slot_counts.items():
            material = ob.data.materials[slot]
            if material and material.name in register.get('materials', {}):
                counts[material.name] += count
                objects[material.name].add(ob.name)
    with (N / 'review3d/current-estate.glb').open('rb') as glb:
        glb.seek(12)
        length = struct.unpack('<I', glb.read(4))[0]
        glb.seek(20)
        web = json.loads(glb.read(length))
    findings = {}
    baked = set(manifest.get('legacyWoodShaderBakes', {}).get('materials', []))
    for name, record in register.get('materials', {}).items():
        material = bpy.data.materials[name]
        shader = next(node for node in material.node_tree.nodes if node.type == 'BSDF_PRINCIPLED')
        glaze = material.node_tree.nodes.get('Gye mineral pigment glaze')
        texture = material.node_tree.nodes.get('Gye broad mineral paint')
        native_good = bool(glaze and texture and texture.image and
            Path(bpy.path.abspath(texture.image.filepath)).resolve() == image_path.resolve() and
            shader.inputs['Base Color'].is_linked and shader.inputs['Base Color'].links[0].from_node == glaze and
            abs(shader.inputs['Roughness'].default_value - .96) < .001 and not shader.inputs['Roughness'].is_linked and
            all(abs(glaze.inputs['Color2'].default_value[i] - factor) < .001
                for i, factor in enumerate(record['linearMultiplier'])))
        uv_good = bool(objects[name]) and all(bpy.data.objects[obj].get('gyeStonePigmentV2') and
                    bpy.data.objects[obj].data.uv_layers.get(STONE_UV) for obj in objects[name])
        indices = {i for i, item in enumerate(web['materials']) if item.get('name') == name}
        web_good = bool(indices) and name in baked
        uv_sets = set()
        primitives_checked = 0
        for node in web['nodes']:
            if 'mesh' not in node:
                continue
            for primitive in web['meshes'][node['mesh']]['primitives']:
                if primitive.get('material') not in indices:
                    continue
                primitives_checked += 1
                native = bpy.data.objects.get(node.get('name', ''))
                pbr = web['materials'][primitive['material']].get('pbrMetallicRoughness', {})
                coord = pbr.get('baseColorTexture', {}).get('texCoord', 0)
                uv_sets.add(coord)
                native_index = ([layer.name for layer in native.data.uv_layers].index(STONE_UV)
                                if native and native.type == 'MESH' and native.data.uv_layers.get(STONE_UV) else None)
                web_good &= ('baseColorTexture' in pbr and coord == native_index and coord <= 3 and
                             'TEXCOORD_' + str(coord) in primitive['attributes'] and
                             abs(pbr.get('roughnessFactor', 0) - .96) < .001)
        findings[name] = {'nativePigmentMatches': native_good, 'faces': counts[name],
                          'newUvPresent': uv_good, 'webPigmentAndUvValid': bool(web_good),
                          'webUvSets': sorted(uv_sets), 'webPrimitivesChecked': primitives_checked}
    owner_set = {row['building'] for row in register.get('mapping', [])}
    buildings = {'sarang', 'jung', 'anchae', 'ansarang', 'sadang', 'sadangmun',
                 'arae', 'angotgan', 'gokgan', 'changgo', 'main_gate', 'toilet', 'toilet1'}
    valid = (aliases_good and scoped_good and original_images_good and
             actual_mapping == expected_mapping and buildings <= owner_set and len(findings) == 29 and
             sha(image_path) == register['imageSha256'] and all(
             item['nativePigmentMatches'] and item['newUvPresent'] and item['webPigmentAndUvValid'] and
             item['faces'] == register['materials'][name]['faces'] and item['webPrimitivesChecked'] > 0
             for name, item in findings.items()))
    return {'valid': valid, 'materials': findings, 'originalImagesUnchanged': original_images_good,
            'scopedMaterialCopiesValid': scoped_good and aliases_good,
            'mappedObjectsMatch': actual_mapping == expected_mapping,
            'buildingsCovered': sorted(buildings & owner_set)}

stone_pigment = stone_pigment_audit()

def matte_surface_audit():
    register = contract.get('gyeMatteSurface', {})
    records = register.get('materials', {})
    if not records or not bpy.context.scene.get('gyeMatteSurfaceV1'):
        return {'valid': False, 'reason': 'matte surface register missing'}
    counts = defaultdict(Counter)
    exported = set()
    owner_roles = defaultdict(set)
    for ob in bpy.context.scene.objects:
        if ob.type != 'MESH':
            continue
        owner = owner_of(ob)
        exported_owner = ob.get('construction_building', 'site')
        stage = 16 if exported_owner == 'sarang' else 12
        selected = (not ob.hide_render and exported_owner != 'context' and
                    (exported_owner not in ('sarang', 'jung') or
                     ob.get('construction_first', 0) <= stage <= ob.get('construction_last', 99)))
        for slot, count in Counter(poly.material_index for poly in ob.data.polygons).items():
            material = ob.data.materials[slot]
            role = surface_role(material.name) if material else None
            if not role:
                continue
            counts[material.name][owner] += count
            owner_roles[owner].add(role)
            if selected:
                exported.add(material.name)
    with (N / 'review3d/current-estate.glb').open('rb') as glb:
        glb.seek(12)
        length = struct.unpack('<I', glb.read(4))[0]
        glb.seek(20)
        web = json.loads(glb.read(length))
    findings = {}
    baked_matte = set(manifest.get('legacyWoodShaderBakes', {}).get('materials', []))
    for name, record in records.items():
        material = bpy.data.materials[name]
        shader = next(node for node in material.node_tree.nodes if node.type == 'BSDF_PRINCIPLED')
        native_good = material.get('gyeMatteSurfaceV1') == record['role']
        for socket, expected in (('Roughness', record['roughness']), ('Specular IOR Level', .12),
                                  ('Metallic', 0), ('Coat Weight', 0)):
            inp = shader.inputs[socket]
            native_good &= not inp.is_linked and abs(inp.default_value - expected) < .001
        native_good &= all(node.inputs['Strength'].default_value <= (.151 if record['role'] == 'roof' else .181)
                           for node in material.node_tree.nodes if node.type in ('NORMAL_MAP', 'BUMP'))
        mats = [item for item in web['materials'] if item.get('name') == name]
        web_good = bool(mats) if name in exported else True
        for item in mats:
            pbr = item.get('pbrMetallicRoughness', {})
            web_good &= (abs(pbr.get('roughnessFactor', 0) - record['roughness']) < .001 and
                         pbr.get('metallicFactor', 1) == 0 and 'metallicRoughnessTexture' not in pbr and
                         item.get('extras', {}).get('gyeMatteSurfaceV1') == record['role'])
            if record['role'] == 'wood' and timber_needs_bake(material):
                web_good &= name in baked_matte and 'baseColorTexture' in pbr
        findings[name] = {'nativeFinishMatches': bool(native_good), 'webFinishMatches': bool(web_good),
                          'facesMatch': dict(counts[name]) == record['facesByOwner'],
                          'webMaterialCount': len(mats)}
    timber_findings = {}
    baked = set(manifest.get('legacyWoodShaderBakes', {}).get('materials', []))
    for owner, record in register.get('timberOutliers', {}).items():
        name = record['material']
        material = bpy.data.materials[name]
        shader = next(node for node in material.node_tree.nodes if node.type == 'BSDF_PRINCIPLED')
        tint = material.node_tree.nodes.get('Gye sun-aged walnut pigment')
        good = bool(tint and shader.inputs['Base Color'].links and
                    shader.inputs['Base Color'].links[0].from_node == tint and
                    abs(tint.inputs['Saturation'].default_value - record['saturation']) < .001 and
                    abs(tint.inputs['Value'].default_value - record['value']) < .001 and name in baked)
        texture = tint.inputs['Color'].links[0].from_node if tint else None
        vector = texture.inputs['Vector'].links[0].from_node if texture and texture.inputs['Vector'].is_linked else None
        uv_name = vector.uv_map if vector and vector.type == 'UVMAP' else None
        indices = {i for i, item in enumerate(web['materials']) if item.get('name') == name}
        uv_good = bool(indices)
        primitives = 0
        coords = set()
        for node in web['nodes']:
            if 'mesh' not in node:
                continue
            for primitive in web['meshes'][node['mesh']]['primitives']:
                if primitive.get('material') not in indices:
                    continue
                primitives += 1
                ob = bpy.data.objects.get(node.get('name', ''))
                layers = ob.data.uv_layers if ob and ob.type == 'MESH' else []
                uv_index = ([layer.name for layer in layers].index(uv_name) if uv_name and layers.get(uv_name)
                            else next((i for i, layer in enumerate(layers) if layer.active_render), None))
                pbr = web['materials'][primitive['material']].get('pbrMetallicRoughness', {})
                coord = pbr.get('baseColorTexture', {}).get('texCoord', 0)
                coords.add(coord)
                uv_good &= ('baseColorTexture' in pbr and coord == uv_index and
                            'TEXCOORD_' + str(coord) in primitive['attributes'])
        timber_findings[owner] = {'nativePigmentAndBakeMatch': good,
                                 'grainUvPreserved': bool(uv_good and primitives),
                                 'webUvSets': sorted(coords), 'webPrimitivesChecked': primitives}
    images_good = all(Path(path).is_file() and sha(Path(path)) == expected
                      for path, expected in register.get('originalImages', {}).items())
    buildings = {'sarang', 'jung', 'anchae', 'ansarang', 'sadang', 'sadangmun',
                 'arae', 'angotgan', 'gokgan', 'changgo', 'main_gate', 'toilet', 'toilet1'}
    coverage_good = all(owner_roles[owner] == {'roof', 'wood'} for owner in buildings)
    valid = (set(counts) == set(records) and images_good and coverage_good and
             set(timber_findings) == {'anchae', 'ansarang'} and
             all(all(row[key] for key in ('nativeFinishMatches', 'webFinishMatches', 'facesMatch'))
                 for row in findings.values()) and
             all(row['nativePigmentAndBakeMatch'] and row['grainUvPreserved'] for row in timber_findings.values()))
    return {'valid': valid, 'materials': findings, 'timberOutliers': timber_findings,
            'sourceImagesUnchanged': images_good, 'allBuildingWoodAndRoofsCovered': coverage_good}

matte_surface = matte_surface_audit()

def shrine_gable_audit():
    register = contract.get('gyeShrineGable', {})
    image_path = N / 'materials' / register.get('image', '')
    if not register or not image_path.is_file() or not bpy.context.scene.get('gyeShrineGableV1'):
        return {'valid': False, 'reason': 'shrine gable art missing'}
    material = bpy.data.materials[GABLE_MATERIAL]
    shader = next(node for node in material.node_tree.nodes if node.type == 'BSDF_PRINCIPLED')
    texture = shader.inputs['Base Color'].links[0].from_node
    native_good = (texture.type == 'TEX_IMAGE' and texture.image and
                   Path(bpy.path.abspath(texture.image.filepath)).resolve() == image_path.resolve() and
                   sha(image_path) == register['imageSha256'])
    source = Path(register['originalImage'])
    source_good = source.is_file() and sha(source) == register['originalImageSha256']
    counts = Counter()
    objects = set()
    for ob in bpy.context.scene.objects:
        if ob.type != 'MESH':
            continue
        count = sum(ob.data.materials[p.material_index] == material for p in ob.data.polygons)
        if count:
            counts[owner_of(ob)] += count
            objects.add(ob.name)
    vector = texture.inputs['Vector'].links[0].from_node if texture.inputs['Vector'].is_linked else None
    uv_name = vector.uv_map if vector and vector.type == 'UVMAP' else None
    embedded_good = uv_good = True
    uv_sets = set()
    primitives = 0
    with (N / 'review3d/current-estate.glb').open('rb') as glb:
        glb.seek(12)
        length = struct.unpack('<I', glb.read(4))[0]
        glb.seek(20)
        web = json.loads(glb.read(length))
        binary_start = 28 + length
        indices = {i for i, item in enumerate(web['materials']) if item.get('name') == GABLE_MATERIAL}
        for index in indices:
            pbr = web['materials'][index]['pbrMetallicRoughness']
            tex = pbr.get('baseColorTexture', {})
            if 'index' not in tex:
                embedded_good = False
                continue
            image = web['images'][web['textures'][tex['index']]['source']]
            view = web['bufferViews'][image['bufferView']]
            glb.seek(binary_start + view.get('byteOffset', 0))
            raw = glb.read(view['byteLength'])
            embedded_good &= hashlib.sha256(raw).hexdigest() == register['imageSha256']
        for node in web['nodes']:
            if 'mesh' not in node:
                continue
            for primitive in web['meshes'][node['mesh']]['primitives']:
                if primitive.get('material') not in indices:
                    continue
                primitives += 1
                ob = bpy.data.objects.get(node.get('name', ''))
                layers = ob.data.uv_layers if ob and ob.type == 'MESH' else []
                expected = ([layer.name for layer in layers].index(uv_name) if uv_name and layers.get(uv_name)
                            else next((i for i, layer in enumerate(layers) if layer.active_render), None))
                coord = web['materials'][primitive['material']]['pbrMetallicRoughness']['baseColorTexture'].get('texCoord', 0)
                uv_sets.add(coord)
                uv_good &= coord == expected and 'TEXCOORD_' + str(coord) in primitive['attributes']
    valid = (native_good and source_good and embedded_good and uv_good and primitives > 0 and
             dict(counts) == register['facesByOwner'] and set(counts) == {'sadang'} and
             objects == set(register['objects']))
    return {'valid': bool(valid), 'nativeImageMatches': bool(native_good),
            'sourcePhotographUnchanged': source_good, 'webImageBytesMatch': bool(embedded_good),
            'webUvMatchesOriginal': bool(uv_good), 'facesByOwner': dict(counts),
            'webPrimitivesChecked': primitives, 'webUvSets': sorted(uv_sets)}

shrine_gable = shrine_gable_audit()
timber_arris = audit_timber_arris(contract, N / 'review3d/current-estate.glb')
requested_craft = audit_requested_craft(contract, N / 'review3d/current-estate.glb', N)
checks = {
    'baseSceneUnchanged': sha(N / 'detail-redraw.blend') == contract['sourceSceneSha256'],
    'originalGeometryUnchanged': not changed_geometry,
    'originalUvAndMaterialSlotsPreserved': not changed_protected,
    'warehouseWallMeetsDoor3And4Post': bool(len(aligned) >= 25 and all(bpy.data.objects[n].get('warehouseWallSeamAligned') for n in aligned)
        and abs(wall_end_y - post_y) < .035 and abs(wall_gate_y - contract['warehouseWallAlignment']['gateEndpointUnchanged'][1]) < .035),
    'imageTexturedWallUvPresent': not missing_uv,
    'masonryCopingHasNoBuildingTimbers': not timber_on_caps,
    'masonryHasNoWoodMaterials': not material_audit['woodOnMasonry'],
    'toilet1HasSeparateSourceNames': all('.toilet1.' in o.get('source_object_name', '') for o in toilet),
    'toilet1MatchesGround': abs(float(points[:, 2].min()) - contract['toilet1']['ground']) < .12,
    'deliveryMatchesCandidate': manifest['sceneSha256'] == sha(N / 'estate-fabric.blend'),
    'deliveryChunksIntact': not chunk_failures and assembled.hexdigest() == manifest['glbSha256'],
    'originalGateAnsarangWallRetained': all(n in bpy.data.objects for n in contract['retainedGateAnsarangWallObjects']),
    'paleNorthWallsReplaced': not any(n in bpy.data.objects for n in replaced),
    'flowerOrnamentsPreserved': all(n in bpy.data.objects for n in contract['harmonizedWalls']['preservedFlowerOrnaments']),
    'northWallStoneRebuilt': len(north_stone) == len(contract['harmonizedWalls']['segments']),
    'duplicateByeoldangRoutesAbsent': not any(o.name.startswith(forbidden) for o in walls),
    'wallJunctionsConnected': all(joins.values()),
    'newStoneUsesCanonicalPigment': bool(stone_groups) and all('Canonical gate stone pigment' in o.data.materials[0].name for o in stone_groups),
    'newCopingUsesRetainedCeramic': bool(tile_groups) and all('source ceramic 2' in o.data.materials[0].name for o in tile_groups),
    'twoEmptyServiceGardens': len([o for o in bpy.context.scene.objects if o.name.startswith('Estate.garden.')]) == 2,
    'gyeWoodRoofPaletteApplied': bool(bpy.context.scene.get('gyeEstateStyleV1')) and style_ramps_match() and style_glazes_match(),
    'sarangStoneIsHandFaceted': bool(style_course and style_feet and
        len(style_course.data.polygons) > 1000 and len(style_feet.data.polygons) > 100 and
        len({polygon.material_index for polygon in style_course.data.polygons}) >= 5 and
        style.get('stoneCourses', 0) >= 130 and style.get('stoneFeet', 0) >= 20 and
        bool(style_course.data.uv_layers.get('Dressed stone pigment UV'))),
    'rejectedGardenAbsent': not garden_objects and not contract.get('gyeShrineGarden')
        and manifest['meshCounts'].get('gye_garden', 0) == 0,
    'distinctBuildingWoodPreservesWarehouse': wood_register['valid'],
    'roofOutliersUseWarmCharcoalFamily': roof_palette['valid'],
    'paintedPlasterPreservesOriginalUvAndWebMapping': plaster_wash['valid'],
    'buildingStoneUsesPaintedPigmentAndPreservesOriginals': stone_pigment['valid'],
    'buildingWoodAndRoofShareMatteFinishAndKeepGrain': matte_surface['valid'],
    'shrineGableUsesDistinctPaintedWoodAndKeepsSource': shrine_gable['valid'],
    'timberCornersVaryWhileSourceCoreAndDoorPartsRemain': timber_arris['valid'],
    'sarangAndJungUseDistinctFullPaintedGrain': requested_craft['heritageWood']['valid'],
    'platformTopsUseIrregularStoneAndKeepEarthCourtyards': requested_craft['platformStone']['valid'],
    'gokganRearWallHasClearanceAndKeepsBuildingPosition': requested_craft['gokganClearance']['valid'],
}
report = {'checks': checks, 'originalMeshesChecked': len(geometry), 'protectedSurfacesChecked': len(protected),
          'changedGeometry': changed_geometry, 'changedProtectedSurfaces': changed_protected,
          'deliberatelyAlignedWallMeshes': sorted(aligned), 'door3And4PostY': float(post_y),
          'wallEndY': float(wall_end_y), 'wallGateY': float(wall_gate_y),
          'imageTexturedWallMeshesChecked': len(textured_walls), 'missingWallUv': missing_uv, 'timberOnCaps': timber_on_caps,
          'woodOnMasonry': material_audit['woodOnMasonry'], 'chunkFailures': chunk_failures,
          'toilet1Bounds': {'min': points.min(0).tolist(), 'max': points.max(0).tolist()},
          'sceneSha256': manifest['sceneSha256'], 'glbSha256': manifest['glbSha256'],
          'gyeStylePass': {'stoneCourses': style.get('stoneCourses'), 'stoneFeet': style.get('stoneFeet'),
                           'palette': style.get('palette')},
          'gyeTimberRegister': wood_register,
          'gyeRoofPalette': roof_palette,
          'gyePlasterWash': plaster_wash,
          'gyeStonePigment': stone_pigment,
          'gyeMatteSurface': matte_surface,
          'gyeShrineGable': shrine_gable,
          'gyeTimberArris': timber_arris,
          'requestedCraft': requested_craft,
          'deferredGyeShrineGardenStudy': contract.get('deferredGyeShrineGardenStudy'),
          'wallJunctions': joins, 'retainedWallObjects': contract['retainedGateAnsarangWallObjects'],
          'visualReview': 'Awaiting current browser review', 'runtimePromotion': False}
(N / 'estate-fabric-validation.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf8')
print('ESTATE FABRIC AUDIT', json.dumps(checks), flush=True)
assert all(checks.values()), report
