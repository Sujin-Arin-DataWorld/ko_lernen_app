"""Verify reversible timber corners in native meshes and delivered glTF."""
import hashlib
import json
import struct

import bpy
import numpy as np

from apply_timber_arris import WEIGHT, SCOPE, EXCLUDED, evaluated_summary, modifier_record
from repair_masonry_coping import fingerprint
from apply_heritage_wood import UV_NAME as HERITAGE_UV


def audit_timber_arris(contract, glb_path):
    register = contract.get('gyeTimberArris', {})
    records = register.get('members', [])
    if not records or not bpy.context.scene.get('gyeTimberArrisV1'):
        return {'valid': False, 'reason': 'Timber corner register missing'}
    with glb_path.open('rb') as glb:
        glb.seek(12)
        length = struct.unpack('<I', glb.read(4))[0]
        glb.seek(20)
        web = json.loads(glb.read(length))
    nodes = {node.get('name'): node for node in web['nodes'] if 'mesh' in node}
    depsgraph = bpy.context.evaluated_depsgraph_get()
    findings = {}
    for row in records:
        ob = bpy.data.objects.get(row['object'])
        if ob is None:
            findings[row['object']] = {'valid': False, 'reason': 'Native member missing'}
            continue
        attribute = ob.data.attributes.get(WEIGHT)
        weights = np.zeros(len(ob.data.edges), dtype=np.float32)
        if attribute:
            attribute.data.foreach_get('value', weights)
        modifier = ob.modifiers.get(row['modifier'])
        core_good = fingerprint(ob, ignore_uv_layers={HERITAGE_UV}) == row['coreFingerprint'] and not EXCLUDED.search(ob.name)
        weight_good = bool(attribute and hashlib.sha256(weights.tobytes()).hexdigest() == row['weightSha256']
                           and np.count_nonzero(weights) == row['weightedEdges']
                           and np.all((weights >= 0) & (weights <= 1)))
        modifier_good = bool(modifier and modifier_record(modifier) == row['afterModifier'])
        max_width = float(weights.max()) * modifier.width * max(abs(s) for s in ob.matrix_world.to_scale()) if modifier else 100
        current = evaluated_summary(ob, depsgraph)
        evaluated_good = (current['triangles'] == row['afterEvaluated']['triangles'] and
                          current['vertices'] == row['afterEvaluated']['vertices'] and
                          max(abs(a-b) for key in ('min', 'max')
                              for a, b in zip(current[key], row['afterEvaluated'][key])) < .00001)
        node = nodes.get(ob.name)
        web_triangles = (sum(web['accessors'][primitive['indices']]['count'] // 3
                             for primitive in web['meshes'][node['mesh']]['primitives']) if node else 0)
        web_good = bool(node and node.get('extras', {}).get('gyeTimberArrisV1') and
                        web_triangles == current['triangles'])
        valid = (core_good and weight_good and modifier_good and evaluated_good and web_good and
                 max_width <= .01601 and row['boundsDeviationMeters'] <= .0301)
        findings[ob.name] = {'valid': bool(valid), 'sourceCoreAndUvUnchanged': bool(core_good),
                            'edgeWeightsMatch': bool(weight_good), 'modifierMatches': bool(modifier_good),
                            'evaluatedSurfaceMatches': bool(evaluated_good), 'webSurfaceMatches': bool(web_good),
                            'maximumWeightedWidthMeters': max_width,
                            'nativeTriangles': current['triangles'], 'webTriangles': web_triangles}
    owners = {row['building'] for row in records}
    marked = {ob.name for ob in bpy.context.scene.objects if ob.get('gyeTimberArrisV1')}
    valid = (owners == SCOPE and marked == {row['object'] for row in records} and
             all(row['valid'] for row in findings.values()))
    return {'valid': bool(valid), 'membersChecked': len(records), 'countsByBuilding': register['countsByBuilding'],
            'allBuildingsCovered': owners == SCOPE, 'members': findings,
            'sourceCoreUnchanged': all(row.get('sourceCoreAndUvUnchanged') for row in findings.values()),
            'renderedCornersChanged': True, 'runtimePromotion': False}
