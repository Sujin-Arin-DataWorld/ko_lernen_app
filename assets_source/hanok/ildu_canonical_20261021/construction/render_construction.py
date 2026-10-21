"""Subset-only construction views of the immutable R6c gate natives.

Run inside Blender: -b -t 4 --python construction/render_construction.py -- --render
No native save, object edits, material edits or camera fitting occurs here.
"""
import argparse
from array import array
import hashlib
import json
from pathlib import Path
import shutil
import sys
import time
import bpy

OUT = Path(__file__).resolve().parent
ROOT = OUT.parent
BASE = ROOT.parents[2]
GATES = {'left': 'left_changgo', 'right': 'right_ansarang', 'shrine': 'sadangmun'}


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def write(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def digest(data):
    return hashlib.sha256(json.dumps(data, sort_keys=True, ensure_ascii=False).encode()).hexdigest()


def vector(value):
    if isinstance(value, (str, int, float, bool)) or value is None:
        return value
    try:
        return list(value)
    except TypeError:
        return str(value)


def state(objects):
    """Hash real mesh buffers, transforms, UVs, modifiers and material nodes."""
    result = {}
    materials = set()
    for ob in objects:
        h = hashlib.sha256()
        mesh = ob.data
        for values, attr, count, kind in [
                (mesh.vertices, 'co', len(mesh.vertices) * 3, 'f'),
                (mesh.edges, 'vertices', len(mesh.edges) * 2, 'i'),
                (mesh.loops, 'vertex_index', len(mesh.loops), 'i'),
                (mesh.polygons, 'loop_total', len(mesh.polygons), 'i'),
                (mesh.polygons, 'material_index', len(mesh.polygons), 'i')]:
            buffer = array(kind, [0]) * count
            values.foreach_get(attr, buffer)
            h.update(buffer.tobytes())
        for uv in mesh.uv_layers:
            buffer = array('f', [0]) * (len(uv.data) * 2)
            uv.data.foreach_get('uv', buffer)
            h.update(uv.name.encode())
            h.update(buffer.tobytes())
        mods = []
        for mod in ob.modifiers:
            props = {}
            for prop in mod.bl_rna.properties:
                if prop.identifier != 'rna_type' and prop.type not in {'POINTER', 'COLLECTION'}:
                    props[prop.identifier] = vector(getattr(mod, prop.identifier))
            mods.append(props)
        slots = [(s.link, s.material.name if s.material else None) for s in ob.material_slots]
        materials.update(s.material for s in ob.material_slots if s.material)
        result[ob.name] = {'mesh': h.hexdigest(), 'matrix': [list(r) for r in ob.matrix_world],
                           'modifiers': mods, 'materials': slots, 'hideRender': ob.hide_render}
    material_state = {}
    for mat in materials:
        nodes = []
        for node in mat.node_tree.nodes if mat.use_nodes else []:
            entry = {'name': node.name, 'type': node.bl_idname,
                     'inputs': [(s.identifier, vector(s.default_value)) for s in node.inputs if hasattr(s, 'default_value')]}
            for key in ['operation', 'blend_type', 'noise_dimensions', 'wave_type', 'wave_profile', 'bands_direction', 'interpolation', 'extension']:
                if hasattr(node, key):
                    entry[key] = getattr(node, key)
            if hasattr(node, 'color_ramp'):
                entry['ramp'] = [(e.position, list(e.color)) for e in node.color_ramp.elements]
            if hasattr(node, 'image') and node.image:
                entry['image'] = {'name': node.image.name, 'path': node.image.filepath,
                                  'packed': hashlib.sha256(node.image.packed_file.data).hexdigest() if node.image.packed_file else None}
            nodes.append(entry)
        material_state[mat.name] = {'nodes': nodes,
            'links': [(l.from_node.name, l.from_socket.identifier, l.to_node.name, l.to_socket.identifier)
                      for l in mat.node_tree.links] if mat.use_nodes else []}
    return {'objects': result, 'materials': material_state}


def camera_state(camera):
    return {'name': camera.name, 'matrix': [list(r) for r in camera.matrix_world],
            'position': list(camera.location), 'rotation': list(camera.rotation_euler),
            'type': camera.data.type, 'orthoScale': camera.data.ortho_scale,
            'lens': camera.data.lens, 'shift': [camera.data.shift_x, camera.data.shift_y]}


def classify(gate, name):
    """Every original object belongs to exactly one construction delta."""
    role = name.removeprefix(gate + '.')
    if role.startswith('foundation.'):
        return 1
    if gate == 'shrine':
        if role.startswith(('timber.round main post', 'timber.fore aft support')):
            return 2
        if role.startswith('timber.'):
            return 3
        if role.startswith('roof.square rafter'):
            return 4
        if role.startswith(('door.', 'iron.')):
            return 7
        if role.startswith('paint.'):
            return 8
        bed = ('roof.boarding', 'roof.compacted earth', 'roof.gable lining', 'roof.wing boarding',
               'roof.wing support', 'roof.eave thin tile bedding', 'roof.eave timber edge',
               'roof.diagonal barge board', 'roof.ridge bedding')
        if role.startswith(bed):
            return 5
        tile_stage = 6
    else:
        if role.startswith('timber.'):
            return 2
        if role.startswith(('door.', 'iron.')):
            return 6
        if role.startswith(('roof.round rafter', 'roof.square rafter', 'roof.pitched boarding',
                            'roof.side return boarding', 'roof.side return bearing')):
            return 3
        if role.startswith(('roof.internal compacted fill', 'roof.gable plank', 'roof.pyeonggodae',
                            'roof.yeonham', 'roof.thin tile bedding', 'roof.ridge bedding')):
            return 4
        tile_stage = 5
    if role.startswith(('roof.pan.', 'roof.cover.', 'roof.cover lip', 'roof.lime half moon closure',
                        'roof.wing pan', 'roof.wing cover', 'roof.barge course', 'roof.barge cap tile',
                        'roof.barge end face', 'roof.barge end relief', 'roof.main ridge', 'roof.ridge end finial')):
        return tile_stage
    raise ValueError('Unclassified source member: ' + name)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--render', action='store_true')
    parser.add_argument('--gates', nargs='+', default=list(GATES))
    parser.add_argument('--samples', type=int, default=20)
    parser.add_argument('--width', type=int, default=1024)
    args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else [])
    manifest = read(ROOT / 'manifest.json')
    upstream_paths = [BASE / 'building-workbench-20261017/catalog.json',
                      BASE / 'mapping/r12-curriculum-display-policy.json',
                      BASE / 'mapping/r12-owner-map.json']
    # Prefer byte-identical bundled contracts so a cloned package is self-contained.
    contract_paths = [OUT / 'contracts' / p.name if (OUT / 'contracts' / p.name).exists() else p
                      for p in upstream_paths]
    catalog_path, policy_path, owner_path = contract_paths
    catalog = read(catalog_path)
    policy = read(policy_path)
    contract = {s['processId']: s for s in policy['stages']}
    old = read(OUT / 'manifest.json') if (OUT / 'manifest.json').exists() else {'gates': []}
    results = {g['gate']: g for g in old['gates']}
    for gate in args.gates:
        native = ROOT / (gate + '-new.blend')
        expected = next(r['sha256'] for r in manifest['nativeFiles'] if r['gate'] == gate)
        assert sha(native) == expected, 'Native SHA mismatch'
        bpy.ops.wm.open_mainfile(filepath=str(native))
        source = bpy.context.scene
        members = [o for o in source.objects if o.type == 'MESH' and not o.get('studio')]
        assert all(not o.hide_render for o in members), 'Unexpected hidden member'
        before = state(members)
        before_camera = camera_state(source.camera)
        hero = next(r for r in manifest['renders'] if r['gate'] == gate and r['view'] == 'hero')
        assert before_camera['position'] == hero['camera'] and before_camera['orthoScale'] == hero['orthoScale']
        building = next(b for b in catalog['buildings'] if b['key'] == GATES[gate])
        assignments = {o.name: classify(gate, o.name) for o in members}
        steps = []
        previous = set()
        for step in building['steps']:
            seq = step['sequence']
            delta = sorted(n for n, assigned in assignments.items() if assigned == seq)
            cumulative = sorted(n for n, assigned in assignments.items() if assigned <= seq)
            assert not previous - set(cumulative), 'Nonmonotonic stage'
            assert not previous & set(delta), 'Overlapping delta'
            previous = set(cumulative)
            policy_stage = contract[step['id']]
            record = {'instanceKey': GATES[gate] + ':' + step['id'], 'processId': step['id'],
                      'sequence': seq, 'label': step['label'], 'isFinal': step['isFinal'],
                      'unitCount': step['unitCount'], 'curriculumContract': policy_stage['curriculumContract'],
                      'lessonEvidence': policy_stage['lessonEvidence'],
                      'deltaObjects': delta, 'sourceObjects': cumulative, 'deltaCount': len(delta),
                      'memberCount': len(cumulative), 'noNewGeometry': not delta,
                      'camera': before_camera, 'image': 'renders/' + gate + '-' + str(seq).zfill(2) + '.png',
                      'createsCredit': False, 'earnedRuntimeStageAllowed': False,
                      'sourceNativeSha256': expected, 'sourceObjectStateUnchanged': True,
                      'visuallyReviewed': False}
            steps.append(record)
        assert previous == set(assignments), 'Final geometry coverage mismatch'
        stage_scene = bpy.data.scenes.new('Construction subset | ' + gate)
        stage_scene.world = source.world
        stage_scene.camera = source.camera
        stage_scene.collection.objects.link(source.camera)
        stage_scene.render.engine = 'CYCLES'
        stage_scene.cycles.device = 'CPU'
        stage_scene.cycles.samples = args.samples
        stage_scene.cycles.use_denoising = True
        stage_scene.cycles.seed = source.cycles.seed
        stage_scene.cycles.max_bounces = source.cycles.max_bounces
        stage_scene.render.resolution_x = args.width
        stage_scene.render.resolution_y = args.width
        stage_scene.render.resolution_percentage = 100
        stage_scene.render.film_transparent = False
        stage_scene.render.image_settings.file_format = 'PNG'
        stage_scene.render.image_settings.color_mode = 'RGBA'
        stage_scene.render.use_persistent_data = True
        for setting in ['view_transform', 'look', 'exposure', 'gamma']:
            setattr(stage_scene.view_settings, setting, getattr(source.view_settings, setting))
        for ob in source.objects:
            if ob.type == 'LIGHT' or ob.get('studio'):
                stage_scene.collection.objects.link(ob)
        if args.render:
            (OUT / 'renders').mkdir(exist_ok=True)
            for record in steps:
                path = OUT / record['image']
                if record['isFinal']:
                    # Same source bytes and exact saved hero camera: use the existing 1400px/48spp hero.
                    assert hero['nativeSha256'] == expected
                    shutil.copyfile(ROOT / (gate + '-hero.png'), path)
                    record.update(reusedHero=True, imageSha256=sha(path), samples=48, resolution=[1400, 1400])
                    continue
                previous_record = next((s for s in results.get(gate, {}).get('steps', [])
                                        if s['sequence'] == record['sequence']), None)
                if (path.exists() and previous_record and previous_record.get('imageSha256') == sha(path)
                        and previous_record['sourceNativeSha256'] == expected
                        and previous_record['sourceObjects'] == record['sourceObjects']
                        and previous_record.get('samples') == args.samples):
                    record.update({k: previous_record[k] for k in ['imageSha256', 'samples', 'resolution', 'seconds']})
                    print('VERIFIED SKIP', gate, record['sequence'], flush=True)
                    continue
                for ob in list(stage_scene.collection.objects):
                    if ob.type == 'MESH' and not ob.get('studio'):
                        stage_scene.collection.objects.unlink(ob)
                for name in record['sourceObjects']:
                    stage_scene.collection.objects.link(source.objects[name])
                stage_scene.render.filepath = str(path)
                started = time.monotonic()
                print('RENDER START', gate, record['sequence'], record['memberCount'], flush=True)
                bpy.ops.render.render(write_still=True, scene=stage_scene.name)
                assert state(members) == before, 'Source mesh/material state changed'
                assert camera_state(source.camera) == before_camera, 'Source camera changed'
                record.update(imageSha256=sha(path), samples=args.samples,
                              resolution=[args.width, args.width], seconds=round(time.monotonic() - started, 2))
                print('RENDER DONE', gate, record['sequence'], record['seconds'], flush=True)
        after = state(members)
        assert before == after and sha(native) == expected
        assert camera_state(source.camera) == before_camera
        geometry_sha = digest(before['objects'])
        result = {'gate': gate, 'gateKey': GATES[gate], 'name': building['name'], 'buildingId': building['buildingId'],
                  'native': str(native), 'sourceNativeSha256': expected, 'objectCount': len(members),
                  'geometryAndAssignmentsSha256': geometry_sha, 'materialStateSha256': digest(before['materials']),
                  'stageCount': len(steps), 'steps': steps,
                  'validation': {'passed': True, 'unclassified': [], 'overlappingDeltaAssignments': [],
                                 'missingFinalObjects': [], 'extraFinalObjects': [], 'cumulativeMonotonic': True,
                                 'finalGeometryExactlyMatchesSource': True, 'sourceMeshMaterialStateUnchanged': before == after,
                                 'sameCameraAllStagesAndHero': True, 'nativeBytesUnchanged': True}}
        results[gate] = result
        write(OUT / (gate + '-object-stage-map.json'), {'gate': gate, 'assignments': assignments, 'sourceState': before})
        output = {'kind': 'independent construction review, not runtime progression', 'version': 'R6c-subset-1',
                  'bindings': {(str(p.relative_to(OUT)).replace('\\', '/') if p.is_relative_to(OUT) else str(p)): sha(p)
                               for p in contract_paths},
                  'upstreamBindings': old.get('upstreamBindings',
                      {str(upstream): sha(current) for upstream, current in zip(upstream_paths, contract_paths)}),
                  'sourceGeometryEdited': False, 'sourceMaterialsEdited': False, 'sourceCameraEdited': False,
                  'nativeSaved': False, 'appIntegrated': False, 'rewardOrEligibilityModified': False,
                  'classificationNotes': [
                      'Gate instances retain the shared hyeopmun process IDs; instanceKey includes gateKey.',
                      'Left/right stage 3 includes original rafters, pitched boarding and side return boarding/support.',
                      'Roof bed stages include original earthen packing, gable lining, eave timber and bedding.',
                      'Shrine door hardware appears with doors at stage 7; original taegeuk paint objects appear at final stage 8.',
                      'These subsets explain assembly; they do not assert the chronological order of historic construction.',
                      'Existing lesson copy is preserved as evidence; three-step legacy gate copy can conflict with new source geometry.'],
                  'gates': [results[g] for g in GATES if g in results]}
        write(OUT / 'manifest.json', output)
        print('VALIDATED', gate, len(members), [s['deltaCount'] for s in steps], flush=True)


if __name__ == '__main__':
    main()
