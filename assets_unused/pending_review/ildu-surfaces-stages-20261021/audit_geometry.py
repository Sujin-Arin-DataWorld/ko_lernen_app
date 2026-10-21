"""Fingerprint native gate geometry independently of shader and render settings."""

import bpy
import hashlib
import json
import struct
import sys
from pathlib import Path


def fingerprint():
    digest = hashlib.sha256()
    meshes = sorted((ob for ob in bpy.context.scene.objects if ob.type == 'MESH'), key=lambda ob: ob.name)
    counts = {'objects': len(meshes), 'vertices': 0, 'polygons': 0}
    for ob in meshes:
        data = ob.data
        digest.update(ob.name.encode('utf-8'))
        for row in ob.matrix_world:
            digest.update(struct.pack('<4d', *row))
        digest.update(struct.pack('<2I', len(data.vertices), len(data.polygons)))
        counts['vertices'] += len(data.vertices)
        counts['polygons'] += len(data.polygons)
        for vert in data.vertices:
            digest.update(struct.pack('<3d', *vert.co))
        for poly in data.polygons:
            digest.update(struct.pack('<I', len(poly.vertices)))
            for index in poly.vertices:
                digest.update(struct.pack('<I', index))
        for modifier in ob.modifiers:
            info = {'name': modifier.name, 'type': modifier.type}
            if modifier.type == 'BEVEL':
                info.update(width=modifier.width, segments=modifier.segments)
            digest.update(json.dumps(info, sort_keys=True).encode('utf-8'))
    return {'geometrySha256': digest.hexdigest(), **counts}


if __name__ == '__main__':
    args = sys.argv[sys.argv.index('--') + 1:]
    result = fingerprint()
    if args:
        Path(args[0]).write_text(json.dumps(result, indent=2), encoding='utf-8')
    print(json.dumps(result))
