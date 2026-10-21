"""Reconstruct verified R3, change only two soil bindings, and render whole first."""
import hashlib
import importlib.util
import json
import shutil
import sys
import time
from pathlib import Path

import bpy

OUT = Path(__file__).resolve().parent
BASE = OUT.parent
R3 = BASE / 'living-r3'
sys.path.insert(0, str(BASE))
sys.path.insert(0, str(OUT))
from audit_source import state, bindings
from material_patch import signature
from soil_patch import patch_soil


def sha(path):
    with Path(path).open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def write(name, data):
    (OUT / name).write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, ensure_ascii=False).encode()).hexdigest()


def reconstruct_r3():
    spec = importlib.util.spec_from_file_location('verified_r3_runner', R3 / 'run.py')
    runner = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(runner)
    report = runner.apply_saved()
    assert report['library_sha256'] == 'f7bbe968db527719cc160d4bb403b5f1dbd262a0d7b49a307982025968e3012a'
    return report


def build(prior):
    scene = bpy.data.scenes['Hangul Sori | Full Ildu Estate']
    before, old_bind = state(), bindings()
    print('R4 GEOMETRY BASELINE',len(before),flush=True)
    targets = [r for r in prior['bindings'] if r['role'] == 'yard']
    assert len(targets) == 2
    original = bpy.data.materials[targets[0]['new']]
    protected = {r['new']: signature(bpy.data.materials[r['new']]) for r in prior['bindings']}
    for name in ('YW1 garden | Garden worked earth with quiet pigment',):
        if name in bpy.data.materials:
            protected[name] = signature(bpy.data.materials[name])
    print('R4 SOURCE SHADERS SNAPSHOT',len(protected),flush=True)
    revised = patch_soil(original, scene, json.loads((OUT / 'ground-scope.json').read_text(encoding='utf-8')))
    print('R4 SHADER BUILT',len(revised.node_tree.nodes),'nodes',flush=True)
    changed = []
    for rec in targets:
        slot = bpy.data.objects[rec['object']].material_slots[rec['slot']]
        assert slot.material == original
        slot.material = revised
        changed.append(dict(rec, old=original.name, new=revised.name))
    assert state() == before
    allowed = {(r['object'], r['slot']) for r in changed}
    new_bind = bindings()
    assert all(new_bind[n][i] == v for n, slots in old_bind.items() for i, v in enumerate(slots) if (n,i) not in allowed)
    assert all(signature(bpy.data.materials[n]) == sig for n,sig in protected.items())
    library = OUT / 'courtyard-soil-r4.blend'
    signatures = {revised.name: signature(revised)}
    bpy.data.libraries.write(str(library), {revised}, fake_user=True, compress=True)
    with bpy.data.libraries.load(str(library), link=False) as (src, dst):
        inventory = {k:len(getattr(src,k)) for k in ('materials','objects','meshes','images')}
        names = tuple(src.materials)
        dst.materials = list(names)
    assert inventory['objects'] == inventory['meshes'] == 0
    for name, mat in zip(names,dst.materials):
        assert signature(mat) == signatures[name]
        bpy.data.materials.remove(mat)
    report = dict(passed=True, source_sha256=prior['source_sha256'],
        r3_library_sha256=prior['library_sha256'], library=library.name,
        library_sha256=sha(library), bindings=changed, material_signatures=signatures,
        geometry_signature=digest(before), verified_objects=len(before),
        geometry_uv_transforms_equal=True, non_target_bindings_equal=True,
        r3_wall_and_garden_shaders_unchanged=True, saved_materials_reloaded_equal=True,
        library_datablocks=inventory, ground_scope_sha256=sha(OUT/'ground-scope.json'),
        soil_code_sha256=sha(OUT/'soil_patch.py'),shader_nodes=len(revised.node_tree.nodes),
        app_integrated=False, visual_status='unreviewed')
    write('verification.json', report)
    print('R4 VERIFIED', len(changed), 'soil slots only', inventory, flush=True)
    return report


def apply_saved(prior):
    report = json.loads((OUT/'verification.json').read_text(encoding='utf-8'))
    assert prior['library_sha256'] == report['r3_library_sha256']
    assert digest(state()) == report['geometry_signature']
    library = OUT/report['library']
    assert sha(library) == report['library_sha256']
    names = tuple(report['material_signatures'])
    with bpy.data.libraries.load(str(library), link=False) as (src,dst):
        dst.materials = list(names)
    loaded = dict(zip(names,dst.materials))
    for name,mat in loaded.items():
        assert signature(mat) == report['material_signatures'][name]
    for rec in report['bindings']:
        slot = bpy.data.objects[rec['object']].material_slots[rec['slot']]
        assert slot.material.name == rec['old']
        slot.material = loaded[rec['new']]
    return report


def render(report, views):
    scene = bpy.data.scenes['Hangul Sori | Full Ildu Estate']
    r3_manifest = json.loads((R3/'render-manifest.json').read_text(encoding='utf-8'))
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 24
    scene.cycles.seed = 15
    scene.cycles.use_denoising = True
    scene.render.use_persistent_data = True
    scene.render.threads_mode = 'FIXED'
    scene.render.threads = 8
    scene.render.resolution_percentage = 100
    scene.render.resolution_x, scene.render.resolution_y = 1280,960
    scene.render.image_settings.file_format = 'PNG'
    path = OUT/'render-manifest.json'
    manifest = json.loads(path.read_text(encoding='utf-8')) if path.exists() else dict(
        source_sha256=report['source_sha256'],r3_library_sha256=report['r3_library_sha256'],
        library_sha256=report['library_sha256'],renders=[])
    assert manifest['library_sha256'] == report['library_sha256']
    for view in views:
        prior = next(r for r in r3_manifest['renders'] if r['view']==view and r['variant']=='B')
        camera = prior['camera']
        scene.camera.location = camera['location']
        scene.camera.rotation_euler = camera['rotation']
        scene.camera.data.ortho_scale = camera['ortho_scale']
        baseline = R3/prior['file']
        assert sha(baseline) == prior['sha256']
        target = OUT/(view+'-A.png')
        shutil.copyfile(baseline,target)
        manifest['renders'] = [r for r in manifest['renders'] if r['view']!=view]
        common = dict(view=view,camera=camera,resolution=[1280,960],samples=24,seed=15)
        manifest['renders'].append(dict(common,variant='A',file=target.name,
            sha256=sha(target),reused_from=str(baseline),material_library_sha256=report['r3_library_sha256']))
        target = OUT/(view+'-B.png')
        scene.render.filepath = str(target)
        print('RENDER R4', view, flush=True)
        start = time.monotonic()
        bpy.ops.render.render(write_still=True,scene=scene.name)
        manifest['renders'].append(dict(common,variant='B',file=target.name,
            sha256=sha(target),material_library_sha256=report['library_sha256'],
            light_and_color_management_preserved=True,seconds=round(time.monotonic()-start,2)))
        write('render-manifest.json',manifest)
        print('SAVED R4',view,flush=True)


if __name__ == '__main__':
    args = sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
    prior = reconstruct_r3()
    report = apply_saved(prior) if 'apply' in args else build(prior)
    if 'render' in args:
        render(report,args[args.index('render')+1:] or ['full'])
