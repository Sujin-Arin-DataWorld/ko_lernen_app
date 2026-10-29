"""Reconnect two existing interior lights to visible floor paths.

No materials, geometry, global lights, world, view settings, camera, files or
renders are changed. The stone camera suggestion is returned as data only.
"""

import hashlib
import json
import math
from types import SimpleNamespace

import bpy
from mathutils import Matrix, Vector
import warmth_material_r12 as warmth


RECEIPT_KEY = 'HS12 local interior light refine receipt'
VERSION = 'r12.1'
COLOR = (1.0, 0.5, 0.18)
CONFIG = {
    'HS3 SPEC main warm interior bounce': {
        'position': (3.93, 2.15, 3.15),
        'aim': (3.93, 0.72, 2.005),
        'powerCeilingW': 150.0,
        'reason': 'Original right-room source is blocked from open bay 2 by the real room partition',
        'targets': [('interior floor', (3.93, 2.05, 2.005)),
                    ('threshold top', (3.93, 1.27, 2.145)),
                    ('maru near threshold', (3.93, 0.72, 2.005)),
                    ('front maru', (3.93, 0.25, 2.005))],
    },
    'HS3 numaru opening bounce': {
        'position': (13.2175, -1.88, 3.15),
        'aim': (13.2175, -2.65, 2.005),
        'powerCeilingW': 65.0,
        'reason': 'Move the disk in front of the window stile and direct it onto the maru',
        'targets': [('doorway floor', (13.22, -1.50, 2.005)),
                    ('middle maru', (13.22, -2.2, 2.005)),
                    ('front maru', (13.22, -3.1, 2.005)),
                    ('left maru', (12.6, -2.6, 2.005))],
    },
}


def _state(obj):
    return dict(position=list(obj.matrix_world.translation),
                forward=list(obj.matrix_world.to_quaternion() @ Vector((0, 0, -1))),
                colorLinear=list(obj.data.color), powerW=obj.data.energy,
                shape=obj.data.shape, size=obj.data.size, sizeY=obj.data.size_y,
                spread=obj.data.spread, shader=warmth._tree_signature(obj.data.node_tree))


def _geometry_signature(sc):
    # The existing checked helper includes actual vertices, topology, UVs,
    # material indices, mesh material slots and all object names/transforms.
    # Exclude only the two authorized light transforms, never a mesh.
    return warmth._geometry_signature(SimpleNamespace(
        objects=[o for o in sc.objects if o.name not in CONFIG]))


def _protected_signature(sc):
    materials = {s.material for o in sc.objects for s in o.material_slots if s.material}
    value = dict(materials=sorted((m.name, warmth._tree_signature(m.node_tree)) for m in materials),
                 lights=[(o.name, _state(o) if o.data.type == 'AREA' else
                          [o.data.type, o.data.energy, list(o.data.color),
                           warmth._tree_signature(o.data.node_tree)])
                         for o in sc.objects if o.type == 'LIGHT' and o.name not in CONFIG],
                 world=[sc.world.name, warmth._tree_signature(sc.world.node_tree)],
                 view=[sc.view_settings.view_transform, sc.view_settings.look,
                       sc.view_settings.exposure, sc.view_settings.gamma],
                 camera=[sc.camera.name, sc.camera.data.type, sc.camera.data.lens,
                         sc.camera.data.ortho_scale, sc.camera.data.clip_start,
                         sc.camera.data.clip_end])
    return hashlib.sha256(json.dumps(value, sort_keys=True).encode()).hexdigest()


def _visible_blocker(sc, dg, start, target):
    start, target = Vector(start), Vector(target)
    direction = target - start
    remaining = direction.length - 0.003
    direction.normalize()
    while remaining > 0:
        hit, point, _normal, _index, obj, _matrix = sc.ray_cast(
            dg, start, direction, distance=remaining)
        if not hit:
            return None
        if not obj.hide_render:
            return obj.name
        advance = (point - start).length + 0.0001
        start += direction * advance
        remaining -= advance
    return None


def _path_probe(sc, obj, config):
    dg = bpy.context.evaluated_depsgraph_get()
    center = obj.matrix_world.translation
    rotation = obj.matrix_world.to_quaternion()
    forward = rotation @ Vector((0, 0, -1))
    axis_x, axis_y = rotation @ Vector((1, 0, 0)), rotation @ Vector((0, 1, 0))
    radius = obj.data.size * 0.5 * 0.65
    samples = [center] + [center + radius * (math.cos(k * math.pi / 4) * axis_x
                                            + math.sin(k * math.pi / 4) * axis_y)
                          for k in range(8)]
    results = []
    for label, target in config['targets']:
        vector = Vector(target) - center
        front_cos = float(forward.dot(vector.normalized()))
        blockers = [_visible_blocker(sc, dg, p, target) for p in samples]
        clear = sum(v is None for v in blockers)
        results.append(dict(label=label, target=list(target),
                            centerBlockedBy=blockers[0],
                            centerInEmissionHemisphere=front_cos > 0,
                            centerRayClear=blockers[0] is None and front_cos > 0,
                            clearCoreDiskSamples=clear, coreDiskSamples=len(samples),
                            blockers=sorted(set(v for v in blockers if v is not None)),
                            distanceMetres=vector.length))
    return results


def stone_camera_proposal(sc):
    """Return an unchanged orthographic framing with all ray origins above ground."""
    camera = sc.objects.get('Identical comparison camera') or sc.camera
    target = Vector((3.9, -0.6, 1.25))
    direction = (camera.matrix_world.translation - Vector((7, 0, 3))).normalized()
    rotation = (-direction).to_track_quat('-Z', 'Y')
    up, right = rotation @ Vector((0, 1, 0)), rotation @ Vector((1, 0, 0))
    scale = 5.1
    ground = sc.objects['HS2 display ground (non-canonical)']
    ground_z = float((ground.matrix_world @ Vector(ground.bound_box[0])).z)
    def minimum_ray_z(distance):
        location = target + direction * distance
        return float(location.z - scale * 0.5 * (abs(up.z) + abs(right.z))
                     - camera.data.clip_start * direction.z)
    location = target + direction * 10.0
    return dict(target=list(target), direction=list(direction), position=list(location),
                rotationEuler=list(rotation.to_euler()), orthoScale=scale,
                distanceMetres=10.0, previousDistanceMetres=3.0,
                previousMinimumRayOriginZ=minimum_ray_z(3.0),
                proposedMinimumRayOriginZ=minimum_ray_z(10.0), groundZ=ground_z,
                groundUntouched=True, applied=False,
                reason='The 3 m camera puts bottom orthographic rays below the ground plane; this is not a ground edge')


def apply(sc):
    """Apply only the two existing local lights and return a measured receipt."""
    if RECEIPT_KEY in sc:
        receipt = json.loads(sc[RECEIPT_KEY])
        receipt['alreadyApplied'] = True
        return receipt
    lights = {}
    for name, config in CONFIG.items():
        obj = sc.objects.get(name)
        if obj is None or obj.type != 'LIGHT' or obj.data.type != 'AREA':
            raise ValueError('Expected existing interior area light: ' + name)
        if not 0 < obj.data.energy <= config['powerCeilingW'] + 1e-6:
            raise ValueError('Interior power is outside the declared bound: ' + name)
        lights[name] = obj
    bpy.context.view_layer.update()
    geometry_before, mesh_count = _geometry_signature(sc)
    protected_before = _protected_signature(sc)
    changes = []
    for name, config in CONFIG.items():
        obj = lights[name]
        before = _state(obj)
        before_probe = _path_probe(sc, obj, config)
        position = Vector(config['position'])
        quaternion = (Vector(config['aim']) - position).to_track_quat('-Z', 'Y')
        obj.matrix_world = Matrix.LocRotScale(position, quaternion, obj.matrix_world.to_scale())
        obj.data.color = COLOR
        bpy.context.view_layer.update()
        after = _state(obj)
        changes.append(dict(name=name, reason=config['reason'], aim=list(config['aim']),
                            before=before, after=after,
                            positionChangeMetres=(Vector(after['position']) - Vector(before['position'])).length,
                            beforePaths=before_probe, afterPaths=_path_probe(sc, obj, config)))
    geometry_after, after_count = _geometry_signature(sc)
    power_and_shape = all(all(row['before'][key] == row['after'][key]
                              for key in ('powerW', 'shape', 'size', 'sizeY', 'spread', 'shader'))
                          for row in changes)
    connected = all(path['centerRayClear'] and path['clearCoreDiskSamples'] > 0
                    for row in changes for path in row['afterPaths'])
    camera = stone_camera_proposal(sc)
    checks = dict(allMeshDataAndProtectedObjectMapsUnchanged=geometry_before == geometry_after,
                  meshObjectCountUnchanged=mesh_count == after_count,
                  materialsOtherLightsWorldViewAndCameraUnchanged=protected_before == _protected_signature(sc),
                  editedLightPowerSizeSpreadAndShadersUnchanged=power_and_shape,
                  doorwayThresholdFloorCenterPathsClear=connected,
                  proposedStoneCameraRaysAboveGround=camera['proposedMinimumRayOriginZ'] > camera['groundZ'])
    receipt = dict(version=VERSION, alreadyApplied=False, meshObjectsChecked=mesh_count,
                   changes=changes, checks=checks, allChecksPassed=all(checks.values()),
                   unchangedInteriorLight='HS3 SPEC numaru warm interior bounce',
                   stoneCameraProposal=camera,
                   visualStatus='Geometry/light-path diagnostic only; no render performed',
                   limitation='Bay 2 receives the main source; bay 3 remains separated by the real interior partition')
    if not receipt['allChecksPassed']:
        raise AssertionError(receipt)
    sc[RECEIPT_KEY] = json.dumps(receipt, ensure_ascii=False)
    return receipt
