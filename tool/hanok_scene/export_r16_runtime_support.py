"""Export runtime views from retained native scenes without saving the inputs.

Run with Blender's Python. Each output records its source hash and alpha bounds.
"""
import argparse
import hashlib
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

BUILDINGS = ['sarang', 'jung', 'anchae', 'arae', 'angotgan', 'ansarang', 'gokgan', 'changgo', 'sadang', 'toilet', 'toilet1']
GATES = ['left', 'right', 'shrine', 'main_gate']


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def point(camera, target):
    camera.rotation_euler = (Vector(target) - camera.location).to_track_quat('-Z', 'Y').to_euler()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--package-root', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--key', choices=[*BUILDINGS, *GATES, 'context'], required=True)
    parser.add_argument('--samples', type=int, default=16)
    parser.add_argument('--pilot', action='store_true')
    args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
    package = args.package_root.resolve()
    output = args.output.resolve() / args.key
    output.mkdir(parents=True, exist_ok=True)
    drawings = package / 'runtime-support-source'
    assignments = None
    if args.key in BUILDINGS:
        native = package / 'native' / args.key / 'full.blend'
        roof_variant = package / 'roof-variants/native' / args.key / 'full.blend'
        if roof_variant.is_file():
            native = roof_variant
        names = set(read(package / 'family-r16' / args.key / 'stage-selection.json')['steps'][-1]['visibleObjects'])
    elif args.key in {'left', 'right', 'shrine'}:
        native = package / 'gates/native' / (args.key + '-material.blend')
        assignments = read(drawings / (args.key + '-object-stage-map.json'))['assignments']
        names = set(assignments)
    else:
        native = drawings / 'context-and-main-gate-pruned.blend'
        groups = read(drawings / 'owner-map.json')['groups']
        if args.key == 'main_gate':
            names = {name for group in groups if group['nativeOwner'] == 'main_gate' for name in group['sourceObjects']}
        else:
            excluded = set(BUILDINGS) | {'left_changgo', 'right_ansarang', 'sadangmun', 'main_gate'}
            names = {name for group in groups if group['nativeOwner'] not in excluded for name in group['sourceObjects']}
    source_hash = digest(native)
    bpy.ops.wm.open_mainfile(filepath=str(native), load_ui=False)
    scene = bpy.context.scene
    missing = names - set(scene.objects.keys())
    if missing:
        raise ValueError('Native members missing: ' + str(sorted(missing)[:8]))
    for obj in scene.objects:
        if obj.type == 'MESH':
            obj.hide_render = obj.name not in names
    members = [scene.objects[name] for name in names if scene.objects[name].type == 'MESH']
    if not scene.camera:
        raise ValueError('Native scene has no authored camera')
    camera = scene.camera
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = args.samples
    scene.cycles.use_denoising = True
    scene.cycles.use_adaptive_sampling = True
    scene.cycles.adaptive_threshold = .05
    scene.render.threads_mode = 'FIXED'
    scene.render.threads = 4
    scene.render.film_transparent = True
    scene.render.use_compositing = False
    scene.render.use_freestyle = False
    scene.render.resolution_x = 768
    scene.render.resolution_y = 512
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    scene.render.image_settings.color_depth = '8'
    scene.render.image_settings.media_type = 'IMAGE'
    scene.camera.data.type = 'ORTHO'
    points = [obj.matrix_world @ Vector(corner) for obj in members for corner in obj.bound_box]
    minimum = Vector(tuple(min(point[axis] for point in points) for axis in range(3)))
    maximum = Vector(tuple(max(point[axis] for point in points) for axis in range(3)))
    centre = (minimum + maximum) / 2
    distance = max((maximum - minimum).length, 1) * 2
    authored_direction = camera.location - centre
    direction = authored_direction.normalized() * distance
    camera.data.clip_end = distance * 5
    camera.data.ortho_scale = max((maximum - minimum).length, 1)
    poses = []
    for index in range(8):
        angle = index * math.pi / 4
        vector = Vector((direction.x * math.cos(angle) - direction.y * math.sin(angle),
                         direction.x * math.sin(angle) + direction.y * math.cos(angle), direction.z))
        camera.location = centre + vector
        point(camera, centre)
        bpy.context.view_layer.update()
        projected = [world_to_camera_view(scene, camera, value) for value in points]
        extent = max(max(value.x for value in projected) - min(value.x for value in projected),
                     max(value.y for value in projected) - min(value.y for value in projected))
        poses.append((camera.location.copy(), camera.rotation_euler.copy(), extent))
    camera.data.ortho_scale *= max(pose[2] for pose in poses) / .88
    jobs = [('view_' + str(index).zfill(2), index, None) for index in range(1 if args.pilot else 8)]
    if assignments and not args.pilot:
        jobs += [('stage_' + str(stage).zfill(2), 0, stage) for stage in range(1, max(assignments.values()) + 1)]
    if args.key == 'context':
        camera.location = (-32, -63, 72)
        point(camera, (8, 17, 2))
        camera.data.ortho_scale = 94
        scene.render.resolution_x, scene.render.resolution_y = 2412, 2622
        poses = [(camera.location.copy(), camera.rotation_euler.copy(), 1)]
        jobs = [('context', 0, None)]
        bpy.context.view_layer.update()
        # The retained layout contract was measured before legacy building meshes
        # were removed from this context-only scene. Current building natives stay
        # independent, with packed textures and no external libraries.
        footprints = read(drawings / 'map-projection.json')['footprints']
        (output / 'map-projection.json').write_text(json.dumps({'sourceSha256': source_hash,
            'canvas': [2412, 2622], 'footprints': footprints}, indent=2), encoding='utf8')
    records = []
    for label, index, stage in jobs:
        destination = output / (label + '.png')
        receipt = destination.with_suffix('.json')
        if receipt.is_file() and destination.is_file():
            prior = read(receipt)
            if (prior.get('exportVersion') == 2 and prior['sourceSha256'] == source_hash
                    and prior.get('size') == [scene.render.resolution_x, scene.render.resolution_y]
                    and prior['sha256'] == digest(destination)):
                records.append(prior)
                continue
        camera.location, camera.rotation_euler = poses[index][:2]
        for obj in members:
            obj.hide_render = bool(stage is not None and assignments[obj.name] > stage)
        scene.render.filepath = str(destination)
        print('EXPORT R16', args.key, label, flush=True)
        bpy.ops.render.render(write_still=True)
        image = bpy.data.images.load(str(destination), check_existing=False)
        pixels = np.empty(image.size[0] * image.size[1] * 4, dtype=np.float32)
        image.pixels.foreach_get(pixels)
        pixels = pixels.reshape(image.size[1], image.size[0], 4)
        ys, xs = np.where(pixels[:, :, 3] > 0)
        if not len(xs):
            raise ValueError('Export is empty')
        bounds = [int(xs.min()), int(image.size[1] - 1 - ys.max()), int(xs.max() + 1), int(image.size[1] - ys.min())]
        record = {'exportVersion': 2, 'key': args.key, 'label': label, 'source': str(native), 'sourceSha256': source_hash,
                  'sha256': digest(destination), 'size': [image.size[0], image.size[1]], 'bounds': bounds,
                  'direction': index, 'nativeStage': stage, 'visibleMeshes': sum(not obj.hide_render for obj in members)}
        receipt.write_text(json.dumps(record, indent=2), encoding='utf8')
        records.append(record)
        bpy.data.images.remove(image)
    if digest(native) != source_hash:
        raise ValueError('Native source changed during export')
    (output / 'manifest.json').write_text(json.dumps(records, indent=2), encoding='utf8')
    print('R16 EXPORT COMPLETE', args.key, len(records), flush=True)


if __name__ == '__main__':
    main()
