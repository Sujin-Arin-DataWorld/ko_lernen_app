"""Detached Blender glue for a newly baked, explicitly declared normal frame.

Native geometry and authored shading normals remain untouched. This optional
path must freshly bake the original shading normal, never reuse an old map.
"""
import hashlib
import json
from pathlib import Path

import numpy as np

from r12_frame_export import FRAME_N, FRAME_T, FRAME_W


def put_corner_attribute(mesh, name, values, *, scalar=False):
    kind='FLOAT' if scalar else 'FLOAT_VECTOR'
    attr=mesh.attributes.get(name) or mesh.attributes.new(name, kind, 'CORNER')
    if attr.domain!='CORNER' or attr.data_type!=kind:
        raise ValueError('Explicit frame attribute collision: '+name)
    attr.data.foreach_set('value' if scalar else 'vector',np.asarray(values,dtype=np.float32).ravel())


def transform_export_frame(normals, tangents, handedness, matrix=None):
    """Convert the already baked world frame to a rigid object's local frame.

    Nonuniform scaling needs a separately matched interpolation policy; fail
    before silently changing it. This function never modifies source arrays.
    """
    n=np.array(normals,dtype=np.float64,copy=True)
    t=np.array(tangents,dtype=np.float64,copy=True)
    w=np.array(handedness,dtype=np.float32,copy=True)
    if matrix is not None:
        transform=np.asarray(matrix,dtype=np.float64)[:3,:3]
        gram=transform.T@transform
        scale2=float(np.trace(gram)/3)
        if scale2<=0 or not np.allclose(gram,np.eye(3)*scale2,atol=1e-7,rtol=1e-6):
            raise ValueError('Paired frame requires a rigid or uniformly scaled object transform')
        if np.linalg.det(transform)<=0:
            raise ValueError('Reflected paired-frame transforms require a matched runtime fixture')
        n=n@transform
        t=t@np.linalg.inv(transform).T
        n/=np.linalg.norm(n,axis=-1,keepdims=True)
        t/=np.linalg.norm(t,axis=-1,keepdims=True)
    n,t=n.astype(np.float32),t.astype(np.float32)
    if not all(np.isfinite(a).all() for a in (n,t,w)):
        raise ValueError('Nonfinite transformed explicit frame')
    return n,t,w


def copy_export_frame(combined, target, source_loop_indices, matrix=None):
    """Copy exact corner frame values alongside the already preserved triangles."""
    values=[]
    for name,width in ((FRAME_N,3),(FRAME_T,3),(FRAME_W,1)):
        attr=combined.attributes.get(name)
        if attr is None:
            raise ValueError('Missing matched bake/export frame '+name)
        data=np.empty((len(combined.loops),width),dtype=np.float32)
        attr.data.foreach_get('value' if width==1 else 'vector',data.ravel())
        values.append(data[np.asarray(source_loop_indices,dtype=np.int64)])
    n,t,w=transform_export_frame(*values,matrix=matrix)
    put_corner_attribute(target,FRAME_N,n)
    put_corner_attribute(target,FRAME_T,t)
    put_corner_attribute(target,FRAME_W,w,scalar=True)


def write_report(path, report):
    Path(path).write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')


def source_triangle_ids(records, triangle_count):
    parts = np.full(triangle_count, -1, dtype=np.int32)
    seen = set()
    for record in records:
        start, end, pid = record['faceStart'], record['faceEnd'], record['partId']
        if (not all(type(value) is int for value in (start, end, pid))
                or not 0 <= start <= end <= triangle_count
                or not 0 <= pid <= np.iinfo(np.int32).max or pid in seen):
            raise ValueError('Invalid or duplicate source triangle identity/range')
        seen.add(pid)
        if np.any(parts[start:end] != -1):
            raise ValueError('Overlapping source triangle ranges')
        parts[start:end] = pid
    if np.any(parts < 0):
        raise ValueError('Unassigned source triangle')
    return parts


def prepare_atlas_patches(mesh, atlas_name, records, *, size, bake_margin, report_path):
    """Relocate collapsed atlas triangles without repacking valid UVs.

    Audit the resulting per-part islands independently: removing a collapsed
    connector can expose a fragment that the preceding whole-chart guard did
    not see. A failure leaves this detached candidate unbaked.
    """
    from r12_uv_patch import patch_collapsed_triangles, patch_failed_islands
    if not all(poly.loop_total == 3 for poly in mesh.polygons):
        raise ValueError('Atlas patches require preserved source triangles')
    vertices = np.empty((len(mesh.vertices), 3), dtype=np.float32)
    mesh.vertices.foreach_get('co', vertices.ravel())
    loop_vertices = np.empty(len(mesh.loops), dtype=np.int32)
    mesh.loops.foreach_get('vertex_index', loop_vertices)
    triangles = np.array([list(p.loop_indices) for p in mesh.polygons], dtype=np.int32)
    positions = vertices[loop_vertices[triangles]].astype(np.float64)
    areas = np.linalg.norm(np.cross(positions[:, 1]-positions[:, 0],
                                   positions[:, 2]-positions[:, 0]), axis=1)*.5
    uv = np.empty((len(mesh.loops), 2), dtype=np.float32)
    mesh.uv_layers[atlas_name].data.foreach_get('uv', uv.ravel())
    parts = source_triangle_ids(records, len(triangles))
    patched, allocation = patch_collapsed_triangles(uv, triangles, areas,
        size=size, bake_margin=bake_margin)
    patched, isolated_islands = patch_failed_islands(patched, triangles, areas, parts,
        size=size, bake_margin=bake_margin, source_parts=records,
        maximum_additional_triangles=8)
    mesh.uv_layers[atlas_name].data.foreach_set('uv', patched.ravel())
    stored = np.empty_like(patched)
    mesh.uv_layers[atlas_name].data.foreach_get('uv', stored.ravel())
    if stored.tobytes() != patched.tobytes():
        raise ValueError('Blender did not retain exact patched atlas coordinates')
    coverage = isolated_islands['postCoverage']
    report = dict(schemaVersion=1, allocation=allocation,
                  isolatedIslandRepair=isolated_islands,
                  storedUvBytesExact=True, postPatchCoverage=coverage,
                  originalNativeWritten=False)
    write_report(report_path, report)
    if not (coverage['centerCoveragePass'] and coverage['minorSpanPass']
            and coverage['allInputTrianglesRetained']
            and coverage['sourceTriangleCountsExact'] is True):
        raise ValueError('Patched atlas failed the independent per-part coverage audit')
    return dict(file=Path(report_path).name,
        sha256=hashlib.sha256(Path(report_path).read_bytes()).hexdigest(),
        relocatedCollapsedTriangles=allocation['relocatedTriangleCount'],
        relocatedExposedIslandTriangles=len(isolated_islands['eligibleTriangles']),
        nonTargetUvBytesUnchanged=True, globalRepack=False,
        centerCoveragePass=True, minorSpanPass=True, freshBakeRequired=True)


def prepare_paired_frame(mesh, atlas_name, records, world_matrix, report_path,
                         *, maximum_interior_fallbacks=64):
    from r12_stable_frame import (build_stable_frame, audit_frames,
        apply_uncertified_interior_policy, serialize_degenerate_frames)
    from r12_frame_nodes import read_world_triangle_inputs
    if not all(poly.loop_total==3 for poly in mesh.polygons):
        raise ValueError('Explicit paired frame requires preserved source triangles')
    p=np.empty((len(mesh.vertices),3),dtype=np.float32)
    mesh.vertices.foreach_get('co',p.ravel())
    loops=np.empty(len(mesh.loops),dtype=np.int32)
    mesh.loops.foreach_get('vertex_index',loops)
    matrix=np.asarray(world_matrix,dtype=np.float64)
    if not np.array_equal(matrix,np.eye(4)):
        raise ValueError('Combined bake frame currently requires identity object transform')
    positions=p[loops].reshape(-1,3,3)
    normals=np.array([tuple(n.vector) for n in mesh.corner_normals],dtype=np.float32).reshape(-1,3,3)
    uv=np.empty((len(mesh.loops),2),dtype=np.float32)
    mesh.uv_layers[atlas_name].data.foreach_get('uv',uv.ravel())
    uv=uv.reshape(-1,3,2)
    parts=source_triangle_ids(records,len(mesh.polygons))
    frame=build_stable_frame(positions,normals,uv,
        undefined_frame_policy='geometric_face',source_part_ids=parts)
    frame=apply_uncertified_interior_policy(frame,positions,normals,uv,
        maximum_triangles=maximum_interior_fallbacks,source_part_ids=parts)
    frame=serialize_degenerate_frames(frame)
    for name,values in (('R12_FrameT',frame.tangents),('R12_FrameB',frame.bitangents),
                        ('R12_FrameN',frame.normals),(FRAME_N,frame.normals),(FRAME_T,frame.tangents)):
        put_corner_attribute(mesh,name,values)
    put_corner_attribute(mesh,FRAME_W,frame.handedness,scalar=True)
    axes,world_positions=read_world_triangle_inputs(mesh,world_matrix)
    audit=audit_frames(*axes,world_positions)
    if audit.get('passed') is not True:
        raise ValueError('Stored live corner frame did not pass the full-interior audit')
    report=dict(schemaVersion=1,experimental=True,requiresMatchedFreshBake=True,
        originalShadingNormalsUnchanged=True,originalPositionsTopologyUnchanged=True,
        originalNativeWritten=False,sourcePartIdsComplete=True,
        generation=frame.report,liveAttributeAudit=audit,
        policyMaximumInteriorFallbacks=maximum_interior_fallbacks,
        renderApproval=False,deviceApproval=False)
    write_report(report_path,report)
    return audit,report
