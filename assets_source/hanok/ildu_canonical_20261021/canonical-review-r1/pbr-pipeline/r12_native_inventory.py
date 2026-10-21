"""Read-only native inventory. Run with factory-startup Blender; never saves."""
import argparse
import hashlib
import json
import sys
import time
from array import array
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from r12_native_source import verified_r12_sha

import bpy
from mathutils import Vector


def jsonable(value):
    if isinstance(value, (str, int, float, bool)) or value is None:
        return value
    if hasattr(value, 'items'):
        return {str(k): jsonable(v) for k, v in value.items()}
    try:
        return [jsonable(v) for v in value]
    except TypeError:
        return str(value)


def properties(value):
    return {k: jsonable(value[k]) for k in value.keys() if k != '_RNA_UI'}


def sha(path):
    with Path(path).open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def mesh_hash(mesh):
    digest = hashlib.sha256()
    for seq, field, count, code in [
        (mesh.vertices, 'co', 3, 'f'),
        (mesh.loops, 'vertex_index', 1, 'i'),
        (mesh.polygons, 'loop_start', 1, 'i'),
        (mesh.polygons, 'loop_total', 1, 'i'),
        (mesh.polygons, 'material_index', 1, 'i'),
    ]:
        values = array(code, [0]) * (len(seq) * count)
        seq.foreach_get(field, values)
        digest.update(field.encode())
        digest.update(values.tobytes())
    return digest.hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--native', required=True)
    parser.add_argument('--out', required=True)
    args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
    native, out = Path(args.native).resolve(), Path(args.out).resolve()
    before = verified_r12_sha(native)
    start = time.time()
    with bpy.data.libraries.load(str(native), link=False) as (src, dst):
        dst.scenes = [n for n in src.scenes if n == 'Hangul Sori | Full Ildu Estate' or n.startswith('Standalone source reconstruction |')]
    scenes = dst.scenes
    print('R12 appended; collecting raw data', flush=True)
    hashes, all_scenes = {}, []
    for scene in scenes:
        objects = []
        for ob in sorted(scene.objects, key=lambda o: o.name):
            row = dict(name=ob.name, type=ob.type, parent=ob.parent.name if ob.parent else None,
                       collections=[c.name for c in ob.users_collection], properties=properties(ob),
                       matrixWorld=[list(r) for r in ob.matrix_world], matrixBasis=[list(r) for r in ob.matrix_basis],
                       hideRender=ob.hide_render, materials=[s.material.name if s.material else None for s in ob.material_slots])
            if ob.type == 'MESH':
                mesh = ob.data
                if mesh.as_pointer() not in hashes:
                    hashes[mesh.as_pointer()] = mesh_hash(mesh)
                corners = [ob.matrix_world @ Vector(c) for c in ob.bound_box]
                row.update(mesh=mesh.name, meshProperties=properties(mesh), vertices=len(mesh.vertices),
                           polygons=len(mesh.polygons), rawGeometrySha256=hashes[mesh.as_pointer()],
                           rawWorldBounds=[[min(c[i] for c in corners) for i in range(3)], [max(c[i] for c in corners) for i in range(3)]],
                           modifiers=[dict(name=m.name, type=m.type, render=m.show_render) for m in ob.modifiers])
            objects.append(row)
        all_scenes.append(dict(name=scene.name, properties=properties(scene), unitScale=scene.unit_settings.scale_length, objects=objects))
    images, unresolved = [], []
    for image in bpy.data.images:
        if image.name in ('Render Result', 'Viewer Node'):
            continue
        packed = bool(image.packed_file) or bool(getattr(image, 'packed_files', []))
        path = Path(bpy.path.abspath(image.filepath, start=str(native.parent))) if image.filepath else None
        row = dict(name=image.name, source=image.source, packed=packed, filepath=image.filepath,
                   resolved=str(path) if path else None, size=list(image.size), users=image.users)
        if path and path.is_file():
            row.update(bytes=path.stat().st_size, sha256=sha(path))
        if image.source in ('FILE', 'TILED', 'MOVIE', 'SEQUENCE') and not packed:
            unresolved.append(row)
        images.append(row)
    after = sha(native)
    result = dict(schemaVersion=1, native=str(native), nativeSha256=before, nativeBytes=native.stat().st_size,
                  nativeUnchanged=before == after, saved=False, evaluatedFullScene=False,
                  seconds=round(time.time()-start, 2), scenes=all_scenes, images=images,
                  externalImageDependencies=unresolved,
                  libraries=[dict(name=l.name, filepath=l.filepath) for l in bpy.data.libraries],
                  note='Raw authored metadata only; bound_box may be stale without dependency evaluation.')
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(dict(output=str(out), scenes=[(s['name'], len(s['objects'])) for s in all_scenes],
                          images=len(images), externalImages=len(unresolved), nativeUnchanged=before == after)), flush=True)


if __name__ == '__main__':
    main()
