"""Material-only R3 reconstruction, verification and same-camera rendering."""
import hashlib
import json
import sys
import time
from pathlib import Path

import bpy

OUT = Path(__file__).resolve().parent
BASE = OUT.parent
SOURCE = BASE / 'ildu-estate-yard-wall-r1.blend'
EXPECTED = '586b8a5328e7c0deaeff5f340639708c927ea224a429aca70dc313adadddff68'
sys.path.insert(0, str(BASE))
sys.path.insert(0, str(OUT))
from audit_source import state, bindings
from material_patch import signature, reachable


def sha(path):
    with Path(path).open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def write(name, data):
    (OUT / name).write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, ensure_ascii=False).encode()).hexdigest()


def build():
    from soil_patch import patch_soil
    from wall_patch import patch_walls, wall_bindings
    assert Path(bpy.data.filepath).resolve() == SOURCE.resolve()
    assert sha(SOURCE) == EXPECTED
    scene = bpy.data.scenes['Hangul Sori | Full Ildu Estate']
    before = state()
    old_bind = bindings()
    print('GEOMETRY BASELINE', len(before), 'objects', flush=True)
    earth_name = 'YW1 yard | Illustrated lived courtyard earth'
    protected_names = {earth_name} | {r['new'] for r in wall_bindings()}
    old_mats = {name: signature(bpy.data.materials[name]) for name in protected_names}
    earth = bpy.data.materials[earth_name]
    revised = patch_soil(earth, scene)
    yard_slots = []
    for obj in scene.objects:
        for index, slot in enumerate(obj.material_slots):
            if slot.material == earth:
                assert obj.name in {
                    'GyeGrass.earth.v55.0 | R12 landing occupancy cut',
                    'GyeSite.Estate.site.west field ground extension.pigment surface v48'}, obj.name
                slot.link = 'OBJECT'
                slot.material = revised
                yard_slots.append((obj.name, index))
    cached = OUT / 'first-pass-sandy-uniform/verification.json'
    if cached.exists() and '--reuse-base-walls' in sys.argv:
        prior = json.loads(cached.read_text(encoding='utf-8'))
        assert prior['source_sha256'] == EXPECTED
        library = cached.parent / prior['library']
        assert sha(library) == prior['library_sha256']
        names = tuple({r['new'] for r in prior['bindings'] if r['role'] == 'wall'})
        with bpy.data.libraries.load(str(library), link=False) as (src, dst):
            dst.materials = list(names)
        loaded = dict(zip(names, dst.materials))
        for name, mat in loaded.items():
            assert signature(mat) == prior['material_signatures'][name]
        wall_map = {}
        for rec in prior['bindings']:
            if rec['role'] != 'wall':
                continue
            slot = bpy.data.objects[rec['object']].material_slots[rec['slot']]
            assert slot.material.name == rec['old']
            slot.link = rec['link']
            slot.material = loaded[rec['new']]
            wall_map[rec['old']] = slot.material
        contact_audit = prior['wall_contact_audit']
        print('REUSED VERIFIED WALL SHADERS', len(wall_map), flush=True)
    else:
        wall_map = patch_walls(scene)
        contact_audit = patch_walls.last_report
    print('MATERIAL PATCHED', len(wall_map), 'wall materials', flush=True)
    allowed = set(yard_slots) | {(r['object'], r['slot']) for r in wall_bindings()}
    new_bind = bindings()
    changed = []
    for name, slots in old_bind.items():
        for index, old in enumerate(slots):
            new = new_bind[name][index]
            if new != old:
                assert (name, index) in allowed, 'Unexpected object binding'
                is_yard = (name, index) in yard_slots
                assert is_yard or old[1] in wall_map, (name, index, old, new)
                changed.append({'object': name, 'slot': index, 'old': old[1], 'new': new[1],
                                'link': new[0], 'role': 'yard' if is_yard else 'wall'})
    assert len(yard_slots) == 2
    assert len(changed) == len(allowed) == 209
    assert state() == before, 'Geometry/UV/transforms/modifiers changed'
    assert all(signature(bpy.data.materials[n]) == s for n, s in old_mats.items()), 'Source shaders changed'
    mats = {bpy.data.materials[r['new']] for r in changed}
    signatures = {m.name: signature(m) for m in mats}
    for mat in mats:
        keep = reachable(mat)
        for node in list(mat.node_tree.nodes):
            if node not in keep:
                mat.node_tree.nodes.remove(node)
        assert signature(mat) == signatures[mat.name]
    library = OUT / 'living-yard-wall-r3-refined.blend'
    bpy.data.libraries.write(str(library), mats, fake_user=True, compress=True)
    with bpy.data.libraries.load(str(library), link=False) as (src, dst):
        inventory = {k: len(getattr(src, k)) for k in ('materials', 'images', 'objects', 'meshes')}
        names = tuple(src.materials)
        dst.materials = list(names)
    assert inventory['objects'] == inventory['meshes'] == 0
    for name, mat in zip(names, dst.materials):
        assert signature(mat) == signatures[name], 'Library reload mismatch'
        bpy.data.materials.remove(mat)
    report = {'passed': True, 'source_sha256': EXPECTED, 'geometry_uv_transforms_equal': True,
              'target_source_shaders_unchanged': True, 'verified_objects': len(before),
              'geometry_signature': digest(before), 'bindings': changed,
              'non_target_bindings_equal': True, 'library': library.name,
              'library_sha256': sha(library), 'library_datablocks': inventory,
              'material_signatures': signatures, 'saved_materials_reloaded_equal': True,
              'wall_contact_audit': contact_audit,
              'app_integrated': False}
    write('verification.json', report)
    print('R3 VERIFIED', len(changed), 'slots', inventory, flush=True)
    return report


def apply_saved():
    report = json.loads((OUT / 'verification.json').read_text(encoding='utf-8'))
    assert sha(SOURCE) == report['source_sha256'] == EXPECTED
    assert Path(bpy.data.filepath).resolve() == SOURCE.resolve()
    assert digest(state()) == report['geometry_signature']
    original_bindings = bindings()
    library = OUT / report['library']
    assert sha(library) == report['library_sha256']
    with bpy.data.libraries.load(str(library), link=False) as (src, dst):
        dst.materials = list(report['material_signatures'])
    loaded = dict(zip(report['material_signatures'], dst.materials))
    for name, mat in loaded.items():
        assert signature(mat) == report['material_signatures'][name]
    for rec in report['bindings']:
        slot = bpy.data.objects[rec['object']].material_slots[rec['slot']]
        assert slot.material.name == rec['old']
        slot.link = rec['link']
        slot.material = loaded[rec['new']]
    assert digest(state()) == report['geometry_signature']
    allowed = {(r['object'], r['slot']) for r in report['bindings']}
    after_bindings = bindings()
    assert all(after_bindings[name][i] == value
               for name, slots in original_bindings.items() for i, value in enumerate(slots)
               if (name, i) not in allowed)
    write('reconstruction-verification.json', {'passed': True, 'source_sha256': EXPECTED,
          'library_sha256': report['library_sha256'], 'geometry_signature': report['geometry_signature'],
          'geometry_uv_transforms_equal': True, 'non_target_bindings_equal': True,
          'material_signatures_equal': True, 'applied_slots': len(allowed)})
    print('R3 RECONSTRUCTED', len(report['bindings']), 'slots', flush=True)
    return report


def render(report, requested):
    scene = bpy.data.scenes['Hangul Sori | Full Ildu Estate']
    source_manifest = json.loads((BASE / 'render-manifest.json').read_text(encoding='utf-8'))
    pilot_manifest = json.loads((BASE / 'entry-pilot-r2/render-manifest.json').read_text(encoding='utf-8'))
    overview = next(r for r in source_manifest['renders'] if r['view'] == 'courtyard' and r['variant'] == 'after')
    full = next(r for r in source_manifest['renders'] if r['view'] == 'full' and r['variant'] == 'after')
    wall = next(r for r in source_manifest['renders'] if r['view'] == 'wall' and r['variant'] == 'after')
    detail = next(r for r in pilot_manifest['renders'] if r['view'] == 'detail' and r['variant'] == 'A')
    views = {'detail': detail['camera'], 'overview': overview['view_settings'],
             'wall': wall['view_settings'], 'full': full['view_settings']}
    reused = {'detail': (BASE / 'entry-pilot-r2/detail-A.png', detail),
              'overview': (BASE / 'courtyard-after.png', overview),
              'full': (BASE / 'full-after.png', full)}
    prior_wall = OUT / 'second-pass-swept-strong/render-manifest.json'
    if prior_wall.exists():
        prior = json.loads(prior_wall.read_text(encoding='utf-8'))
        baseline = next((r for r in prior['renders'] if r['view'] == 'wall' and r['variant'] == 'A'), None)
        if baseline:
            assert prior['source_sha256'] == EXPECTED and baseline['camera'] == views['wall']
            reused['wall'] = (prior_wall.parent / baseline['file'], baseline)
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 24
    scene.cycles.seed = 15
    scene.cycles.use_denoising = True
    scene.render.use_persistent_data = True
    scene.render.threads_mode = 'FIXED'
    scene.render.threads = 8
    scene.render.resolution_percentage = 100
    scene.render.resolution_x, scene.render.resolution_y = 1280, 960
    scene.render.image_settings.file_format = 'PNG'
    manifest_path = OUT / 'render-manifest.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8')) if manifest_path.exists() else {
        'source_sha256': EXPECTED, 'library_sha256': report['library_sha256'], 'renders': []}
    assert manifest['library_sha256'] == report['library_sha256'], 'Stale manifest; archive prior pass before rendering'
    for view in requested:
        camera = views[view]
        scene.camera.location = camera['location']
        scene.camera.rotation_euler = camera['rotation']
        scene.camera.data.ortho_scale = camera['ortho_scale']
        variants = ['A', 'B'] if view == 'wall' else ['B']
        if view in reused and not any(r['view'] == view and r['variant'] == 'A' for r in manifest['renders']):
            path, old = reused[view]
            assert sha(path) == old['sha256']
            import shutil
            out = OUT / (view + '-A.png')
            shutil.copyfile(path, out)
            manifest['renders'].append({'view': view, 'variant': 'A', 'file': out.name,
                'sha256': sha(out), 'camera': camera, 'reused_from': str(path),
                'source_sha256': EXPECTED, 'samples': 24, 'seed': 15, 'resolution': [1280, 960]})
        for variant in variants:
            done = next((r for r in manifest['renders'] if r['view'] == view and r['variant'] == variant), None)
            if done and sha(OUT / done['file']) == done['sha256']:
                continue
            for rec in report['bindings']:
                slot = bpy.data.objects[rec['object']].material_slots[rec['slot']]
                slot.material = bpy.data.materials[rec['old'] if variant == 'A' else rec['new']]
            path = OUT / (view + '-' + variant + '.png')
            scene.render.filepath = str(path)
            start = time.monotonic()
            print('RENDER', view, variant, flush=True)
            bpy.ops.render.render(write_still=True, scene=scene.name)
            manifest['renders'].append({'view': view, 'variant': variant, 'file': path.name,
                'sha256': sha(path), 'camera': camera, 'source_sha256': EXPECTED,
                'material_library_sha256': report['library_sha256'] if variant == 'B' else None,
                'samples': 24, 'seed': 15, 'resolution': [1280, 960],
                'light_and_color_management_preserved': True, 'seconds': round(time.monotonic()-start, 2)})
            write('render-manifest.json', manifest)
            print('SAVED', path.name, flush=True)
    assert sha(SOURCE) == EXPECTED


if __name__ == '__main__':
    args = sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
    report = apply_saved() if 'apply' in args else build()
    if 'render' in args:
        i = args.index('render')
        render(report, args[i+1:] or ['detail', 'overview', 'wall', 'full'])
    if '--output' in args:
        output = Path(args[args.index('--output')+1]).resolve()
        assert output != SOURCE.resolve()
        bpy.ops.wm.save_as_mainfile(filepath=str(output), compress=True)
