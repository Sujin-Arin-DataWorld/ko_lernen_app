"""Read-only native tile UV capacity probe, not a material export or approval."""
import argparse
import hashlib
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix

sys.path.insert(0, str(Path(__file__).parent))
from r12_uv_pack import guard_and_pack
from r12_native_source import verified_r12_sha


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--native', type=Path, required=True)
    parser.add_argument('--selection', type=Path, required=True)
    parser.add_argument('--contract', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--group', default='ildu.sadangmun-tiles')
    args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
    source_hash = verified_r12_sha(args.native)
    names = json.loads(args.selection.read_bytes())['atlasGroups'][args.group]
    contract = json.loads(args.contract.read_bytes())['objects']
    with bpy.data.libraries.load(str(args.native), link=False) as (available, dest):
        assert set(names) <= set(available.objects)
        dest.objects = names
    scene = bpy.data.scenes.new('R12 tile UV capacity probe')
    bpy.context.window.scene = scene
    for obj in dest.objects:
        name = obj.name
        obj.parent = None
        obj.animation_data_clear()
        for constraint in list(obj.constraints):
            obj.constraints.remove(constraint)
        obj.matrix_world = Matrix(contract[name]['matrixWorld'])
        scene.collection.objects.link(obj)
    bpy.context.view_layer.update()
    deps = bpy.context.evaluated_depsgraph_get()
    coords, faces = [], []
    for obj in dest.objects:
        mesh = bpy.data.meshes.new_from_object(obj.evaluated_get(deps))
        offset = len(coords)
        coords.extend(tuple(obj.matrix_world @ vertex.co) for vertex in mesh.vertices)
        faces.extend(tuple(offset + i for i in poly.vertices) for poly in mesh.polygons)
        bpy.data.meshes.remove(mesh)
    for obj in dest.objects:
        bpy.data.objects.remove(obj, do_unlink=True)
    mesh = bpy.data.meshes.new('R12 tile probe exact evaluated geometry')
    mesh.from_pydata(coords, [], faces)
    mesh.update()
    atlas = mesh.uv_layers.new(name='probe atlas')
    obj = bpy.data.objects.new('R12 tile probe', mesh)
    scene.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    rows = []
    for size, margin in ((2048, 2), (4096, 8)):
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=(2*margin+2)/size,
                                 margin_method='FRACTION', area_weight=0,
                                 correct_aspect=True, scale_to_bounds=True)
        bpy.ops.object.mode_set(mode='OBJECT')
        row = dict(size=size, margin=margin, passed=False)
        try:
            row['guard'] = guard_and_pack(bpy, mesh, mesh.uv_layers['probe atlas'],
                                          size=size, bake_margin=margin)
            row['passed'] = True
        except RuntimeError as exc:
            row['error'] = str(exc)
        rows.append(row)
        print('R12_TILE_UV_PROBE', json.dumps(row), flush=True)
        args.out.write_text(json.dumps(dict(nativeSha256=source_hash, sourceMembers=len(names),
            vertices=len(coords), faces=len(faces), uvOnly=True, visualApproval=False, rows=rows), indent=2))
    assert hashlib.file_digest(args.native.open('rb'), 'sha256').hexdigest() == source_hash


if __name__ == '__main__':
    main()
