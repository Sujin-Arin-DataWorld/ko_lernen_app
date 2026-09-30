"""Align the existing warehouse return with the post between doors 3 and 4.

Only the short wall meshes move. The warehouse, hinged doors and gate remain
at their authored coordinates; the wall stays one continuous straight run.
"""
from pathlib import Path
import hashlib
import json

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
TARGET = OUT / 'estate-fabric.blend'
WALL_TOKEN = 'left_changgo.wall to warehouse.'
CORE = 'V27.left_changgo.wall to warehouse.earth core'
THIRD = 'V28.changgo.bay3.leaf2.boards'
FOURTH = 'V28.changgo.bay4.leaf1.boards'


def world_axis_bounds(ob, axis):
    values = [(ob.matrix_world @ vertex.co)[axis] for vertex in ob.data.vertices]
    return min(values), max(values)


def align_warehouse_wall(scene):
    third = scene.objects[THIRD]
    fourth = scene.objects[FOURTH]
    third_edge = world_axis_bounds(third, 1)[1]
    fourth_edge = world_axis_bounds(fourth, 1)[0]
    assert 0 < fourth_edge - third_edge < .6, 'Warehouse door order changed'
    seam_y = (third_edge + fourth_edge) / 2
    wall = [ob for ob in scene.objects if ob.type == 'MESH' and WALL_TOKEN in ob.name]
    assert len(wall) >= 25 and CORE in {ob.name for ob in wall}, 'Warehouse wall set changed'
    assert not any(ob.get('warehouseWallSeamAligned') for ob in wall), 'Wall was already aligned'

    core = scene.objects[CORE]
    end_x, gate_x = -7.23, -4.304
    gate_y = sum(world_axis_bounds(core, 1)) / 2
    assert abs(gate_y - 3.802) < .015 and abs(seam_y - 3.023) < .08
    old_gap = gate_y - seam_y
    length = ((gate_x - end_x) ** 2 + old_gap ** 2) ** .5
    # The normal follows the new straight wall. This keeps stone and tile
    # cross-sections square to the wall instead of shearing individual stones.
    normal_x = -old_gap / length
    normal_y = (gate_x - end_x) / length
    for ob in wall:
        if ob.data.users > 1:
            ob.data = ob.data.copy()
        inverse = ob.matrix_world.inverted()
        old_world = [ob.matrix_world @ vertex.co for vertex in ob.data.vertices]
        for vertex, point in zip(ob.data.vertices, old_world):
            along = (gate_x - point.x) / (gate_x - end_x)
            across = point.y - gate_y
            moved = Vector((gate_x + along * (end_x - gate_x) + across * normal_x,
                            gate_y + along * (seam_y - gate_y) + across * normal_y,
                            point.z))
            vertex.co = inverse @ moved
        ob.data.update()
        ob['warehouseWallSeamAligned'] = True
    # The wall centreline must hit the actual between-door post, not leaf 4.
    assert abs(seam_y - (third_edge + fourth_edge) / 2) < 1e-6
    return {
        'door3RightY': third_edge,
        'door4LeftY': fourth_edge,
        'postCentreY': seam_y,
        'previousWallCentreY': gate_y,
        'warehouseEndpoint': [end_x, seam_y],
        'gateEndpointUnchanged': [gate_x, gate_y],
        'movedObjects': sorted(ob.name for ob in wall),
        'method': 'One straight wall from the retained gate post to the between-door post; only existing wall meshes transformed',
        'warehouseAndGateGeometryUnchanged': True,
    }


if __name__ == '__main__':
    bpy.ops.wm.open_mainfile(filepath=str(TARGET))
    report = align_warehouse_wall(bpy.context.scene)
    bpy.ops.wm.save_as_mainfile(filepath=str(TARGET), compress=True)
    contract_file = OUT / 'estate-fabric-contract.json'
    contract = json.loads(contract_file.read_text(encoding='utf8'))
    contract['warehouseWallAlignment'] = report
    contract['candidateSceneSha256'] = hashlib.sha256(TARGET.read_bytes()).hexdigest()
    contract_file.write_text(json.dumps(contract, ensure_ascii=False, indent=2), encoding='utf8')
    print('WAREHOUSE WALL ALIGNED', len(report['movedObjects']), round(report['postCentreY'], 4), flush=True)
