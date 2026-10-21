"""Allocate empty atlas patches for collapsed UV triangles before a NEW bake.

This does not patch an existing texture or repack any existing chart. Only
positive-world-area, exact-zero-UV-determinant triangles may move. Every other
triangle, including world degenerates, reserves its expanded UV AABB. Missing
space or shared target loops fail closed; source arrays are never modified.
"""
import hashlib
import json
import numpy as np


class PatchAllocationError(ValueError):
    def __init__(self, code, message, **details):
        self.code, self.details = code, details
        super().__init__(f'{code}: {message}; {details}')


def _require(condition, code, message, **details):
    if not condition:
        raise PatchAllocationError(code, message, **details)


def _digest(array):
    array = np.asarray(array)
    return hashlib.sha256(str((array.dtype.str, array.shape)).encode()+array.tobytes()).hexdigest()


def _stable_v(uv):
    result = uv.copy()
    result[:, 1] = np.float32(1) - (np.float32(1) - result[:, 1])
    return result


def _triangle_determinants(points):
    a, b = points[:, 1]-points[:, 0], points[:, 2]-points[:, 0]
    return a[:, 0]*b[:, 1]-a[:, 1]*b[:, 0]


def _occupied_cells(uv, loops, mask, size, padding):
    """Reserve every pixel cell intersecting an expanded triangle AABB.

    Floor/ceil rounding is outward. A zero-width AABB still reserves cells on
    both sides when padding is positive. Rectangle upper indices are exclusive.
    A difference grid avoids iterating over huge triangle bounding rectangles.
    """
    points = uv[loops[mask]].astype(np.float64)*size
    lo = np.floor(points.min(axis=1)-padding).astype(np.int64)
    hi = np.ceil(points.max(axis=1)+padding).astype(np.int64)
    lo, hi = np.clip(lo, 0, size), np.clip(hi, 0, size)
    difference = np.zeros((size+1, size+1), dtype=np.int32)
    for x, y, value in ((lo[:,0],lo[:,1],1),(hi[:,0],lo[:,1],-1),
                         (lo[:,0],hi[:,1],-1),(hi[:,0],hi[:,1],1)):
        np.add.at(difference,(y,x),value)
    np.cumsum(difference,axis=0,dtype=np.int32,out=difference)
    np.cumsum(difference,axis=1,dtype=np.int32,out=difference)
    return difference[:-1,:-1] > 0


def _empty_square_origins(occupied, side):
    size = len(occupied)
    prefix = np.zeros((size+1,size+1), dtype=np.int32)
    prefix[1:,1:] = occupied
    np.cumsum(prefix,axis=0,dtype=np.int32,out=prefix)
    np.cumsum(prefix,axis=1,dtype=np.int32,out=prefix)
    sums = prefix[side:,side:] - prefix[:-side,side:] - prefix[side:,:-side] + prefix[:-side,:-side]
    return sums == 0


def _allocate_patches(uv, triangle_loops, triangle_world_areas, *,
                              size, bake_margin, side_texels=8,
                              world_area_epsilon=1e-12, explicit_targets=None):
    """Return (new_uv_float32, report), with no mutation of caller arrays.

    uv is (loop_count,2) Float32; triangle_loops is (N,3) integer indices;
    triangle_world_areas is (N,) finite nonnegative world area. Target corners
    must be exclusive to one triangle, as in the preserved triangulated bake
    copy. Existing coordinates must already be within [0,1]; non-target values
    must survive the export Float32 V flip unchanged.

    A right triangle has an exact side_texels span and half-pixel vertices. Its
    reserved square is side_texels+2*(bake_margin+1)+1 cells: for side=8 and
    margin=2 this is 15x15, giving 3.5 pixels of padding on every extreme.
    Existing AABBs are expanded by bake_margin+1 as well, so both sides of a
    possible dilation boundary have independent protected space.

    This intentionally conservative allocator may reject an atlas that a more
    exact polygon allocator could fill. It never relaxes padding or relocates
    extra geometry to make a failing allocation pass.
    """
    raw_uv, loops, areas = map(np.asarray, (uv, triangle_loops, triangle_world_areas))
    _require(raw_uv.ndim == 2 and raw_uv.shape[1:] == (2,) and raw_uv.dtype == np.float32,
             'uv_shape_precision','Expected exact Float32 loop UVs (L,2)')
    _require(loops.ndim == 2 and loops.shape[1:] == (3,) and len(loops)>0 and loops.dtype.kind in 'iu',
             'triangle_shape','Expected nonempty integer triangle loops (N,3)')
    _require(areas.shape == (len(loops),) and areas.dtype.kind in 'fiu' and
             np.isfinite(areas).all() and np.all(areas>=0),
             'world_area_input','Expected one finite nonnegative world area per triangle')
    _require(np.isfinite(raw_uv).all() and np.all(raw_uv>=0) and np.all(raw_uv<=1),
             'uv_bounds','Existing atlas coordinates must be finite and within [0,1]')
    _require(np.all(loops>=0) and np.all(loops<len(raw_uv)), 'loop_bounds','Triangle loop index out of range')
    _require(isinstance(size,(int,np.integer)) and 16<=size<=4096 and
             isinstance(bake_margin,(int,np.integer)) and 0<=bake_margin<size and
             isinstance(side_texels,(int,np.integer)) and side_texels>=2 and
             np.isfinite(world_area_epsilon) and world_area_epsilon>=0,
             'invalid_parameters','Invalid atlas size, padding, side or area threshold')
    padding = int(bake_margin)+1
    block = int(side_texels)+2*padding+1
    _require(block<=size,'patch_larger_than_atlas','Protected patch does not fit the atlas')
    determinant = _triangle_determinants(raw_uv[loops].astype(np.float64))
    positive = areas>world_area_epsilon
    collapsed_mask = positive & (determinant==0)
    target_mask = collapsed_mask.copy()
    if explicit_targets is not None:
        requested = np.asarray(explicit_targets)
        _require(requested.ndim==1 and requested.dtype.kind in 'iu' and
                 np.all(requested>=0) and np.all(requested<len(loops)) and
                 len(np.unique(requested))==len(requested),
                 'invalid_internal_targets','Internal relocation indices must be unique and bounded')
        target_mask[:] = False
        target_mask[requested] = True
        _require(np.all(positive[target_mask]),'nonpositive_internal_target',
                 'Only positive-area triangles may be relocated')
    targets = np.flatnonzero(target_mask)
    target_loops = loops[target_mask].ravel()
    # Shared loops would silently alter a non-target or previously placed patch.
    uses = np.bincount(loops.ravel().astype(np.int64),minlength=len(raw_uv))
    _require(np.all(uses[target_loops]==1), 'shared_target_loop',
             'Relocation targets require exclusive original triangle corner loops')
    changed_loop_mask = np.zeros(len(raw_uv),dtype=bool)
    changed_loop_mask[target_loops] = True
    stable = _stable_v(raw_uv)
    _require(np.array_equal(raw_uv[~changed_loop_mask],stable[~changed_loop_mask]),
             'unstable_existing_uv','Non-target UVs are not already export-V stable; refusing an implicit edit')
    output = raw_uv.copy()
    occupied = _occupied_cells(raw_uv,loops,~target_mask,size,padding)
    available = _empty_square_origins(occupied,block)
    reservations = []
    records = []
    for triangle in targets:
        flat_index = int(available.argmax())
        _require(bool(available.ravel()[flat_index]),'insufficient_empty_patches',
                 'No proven empty protected patch remains; no source UVs were changed',
                 requiredPatches=len(targets),allocatedPatches=len(records),
                 protectedSquareTexels=block,occupiedCellCount=int(occupied.sum()))
        y,x = np.unravel_index(flat_index,available.shape)
        x,y = int(x),int(y)
        # Invalidate every candidate square intersecting this reserved square.
        available[max(0,y-block+1):min(len(available),y+block),
                  max(0,x-block+1):min(len(available),x+block)] = False
        a = np.array([x+padding+.5,y+padding+.5],dtype=np.float64)
        pixels = np.array([a,a+[side_texels,0],a+[0,side_texels]])
        candidate = (pixels/size).astype(np.float32)
        _require(np.array_equal(candidate,_stable_v(candidate)), 'unstable_patch_uv',
                 'Atlas size cannot represent this half-pixel patch with export-stable UV32')
        _require(np.array_equal(candidate.astype(np.float64)*size,pixels), 'inexact_patch_pixels',
                 'Patch vertices are not exactly representable at half-pixel coordinates')
        ids = loops[triangle]
        output[ids] = candidate
        reservations.append((x,y,x+block,y+block))
        records.append(dict(triangle=int(triangle),loopIndices=ids.tolist(),worldArea=float(areas[triangle]),
            originalUv=raw_uv[ids].tolist(),newUv=candidate.tolist(),pixelVertices=pixels.tolist(),
            reservedCells=dict(min=[x,y],maxExclusive=[x+block,y+block]),
            paddingTexels=padding+.5,sideTexels=int(side_texels),
            strictInteriorTexelCenters=(int(side_texels)-1)*(int(side_texels)-2)//2))
    # Verify independently from the origin invalidation decisions.
    reserved = np.zeros_like(occupied)
    for x0,y0,x1,y1 in reservations:
        _require(not occupied[y0:y1,x0:x1].any() and not reserved[y0:y1,x0:x1].any(),
                 'patch_overlap','Protected patch overlaps occupied cells or another patch')
        reserved[y0:y1,x0:x1] = True
    _require(output[~changed_loop_mask].tobytes()==raw_uv[~changed_loop_mask].tobytes(),
             'non_target_mutation','A non-target UV changed')
    final_det = _triangle_determinants(output[loops].astype(np.float64))
    _require(not np.any(positive & (final_det==0)), 'residual_collapsed_triangle',
             'Positive-area UV determinant remains zero')
    _require(np.array_equal(output,_stable_v(output)) and np.all(output>=0) and np.all(output<=1),
             'output_uv_invalid','Final UV array is not bounded and export-V stable')
    return output, dict(schemaVersion=1,experimental=True,requiresFreshBake=True,
        compatibleWithExistingBakedTextures=False,globalRepack=False,nativeGeometryChanged=False,
        triangleCount=len(loops),positiveWorldAreaTriangles=int(positive.sum()),
        retainedAtOrBelowWorldAreaThresholdTriangles=int((~positive).sum()),
        relocatedTriangleCount=len(targets),relocatedLoopCount=len(target_loops),
        sourceCollapsedPositiveAreaTriangles=np.flatnonzero(collapsed_mask).tolist(),
        relocatedTriangleIndices=targets.tolist(),remainingCollapsedPositiveAreaTriangles=[],
        nonTargetUvBytesUnchanged=True,allTriangleCountsRetained=True,
        occupancyIncludesNonTargetWorldDegenerates=True,conservativeUvAabbOccupancy=True,
        occupiedCellCount=int(occupied.sum()),reservedPatchCellCount=int(reserved.sum()),
        atlasSize=int(size),bakeMarginTexels=int(bake_margin),existingAabbExpansionTexels=padding,
        protectedSquareTexels=block,patchSideTexels=int(side_texels),
        minimumPatchPaddingTexels=padding+.5,worldAreaEpsilon=float(world_area_epsilon),
        inBounds=True,exportVStable=True,protectedPatchesDoNotOverlap=True,
        inputDigests=dict(uv=_digest(raw_uv),triangleLoops=_digest(loops),worldAreas=_digest(areas)),
        outputUvDigest=_digest(output),patches=records,
        sourceShadingCoordinatesChanged=False,visualApproval=False,deviceApproval=False)


def patch_collapsed_triangles(uv, triangle_loops, triangle_world_areas, *,
                              size, bake_margin, side_texels=8,
                              world_area_epsilon=1e-12):
    """Move only positive-area exact-zero-UV-det triangles; return UV copy/report.

    Source arrays are untouched even on failure. All non-target AABBs, including
    world-degenerate triangles, occupy protected cells. See _allocate_patches
    for the conservative cell/padding proof and exact Float32 requirements.
    """
    return _allocate_patches(uv,triangle_loops,triangle_world_areas,size=size,
        bake_margin=bake_margin,side_texels=side_texels,world_area_epsilon=world_area_epsilon)


def _coverage_summary(audit):
    result = {key:value for key,value in audit.items() if key!='parts'}
    result['parts'] = [{key:value for key,value in part.items() if key!='islands'} for part in audit['parts']]
    visible = [island['principalMinorSpanTexels'] for part in audit['parts']
               for island in part['islands'] if island['paintedPixelRequirement']]
    result['minimumPositiveIslandMinorSpanTexels'] = min(visible,default=None)
    return result


def patch_failed_islands(uv, triangle_loops, triangle_world_areas, part_ids, *,
                         size, bake_margin, source_parts,
                         maximum_additional_triangles=8):
    """Freshly audit then relocate at most eight positive-area failed-island cells.

    This is a separate explicitly bounded policy after collapsed-UV relocation.
    Eligibility comes only from a fresh per-part audit of the actual input UVs,
    loop indices, world areas and source identities. Callers cannot supply a
    target list or prior approval. A failed island has no texel center or a minor
    span below 2 pixels. Only its positive-world-area triangles may move; source
    degenerates remain untouched. Previous patches are ordinary non-target
    geometry in the conservative occupancy mask.

    A complete fresh post-audit must retain all expected source triangles and
    pass both coverage gates. Failure never mutates caller arrays. The hard
    maximum is eight; callers may lower it, never silently increase it.
    """
    from r12_uv_coverage import audit_triangle_uvs
    raw_uv, loops, areas, ids = map(np.asarray,(uv,triangle_loops,triangle_world_areas,part_ids))
    _require(isinstance(maximum_additional_triangles,(int,np.integer)) and
             0<=maximum_additional_triangles<=8,'invalid_island_policy_bound',
             'Additional failed-island relocation has a hard maximum of eight triangles')
    _require(source_parts is not None,'source_parts_required','Exact source part records are required')
    _require(raw_uv.ndim==2 and raw_uv.shape[1:]==(2,) and raw_uv.dtype==np.float32 and
             loops.ndim==2 and loops.shape[1:]==(3,) and len(loops)>0 and loops.dtype.kind in 'iu' and
             np.all(loops>=0) and np.all(loops<len(raw_uv)),
             'island_input_shape','Expected Float32 loop UVs and bounded integer triangle loops')
    _require(areas.shape==(len(loops),) and np.isfinite(areas).all() and np.all(areas>=0),
             'world_area_input','Expected finite nonnegative source world areas')
    epsilon = 1e-12
    before = audit_triangle_uvs(raw_uv[loops],ids,size,source_parts=source_parts,
        minimum_minor_texels=2.0,triangle_world_areas=areas,world_area_epsilon=epsilon)
    _require(before['sourceTriangleCountsExact'] is True and before['allInputTrianglesRetained'],
             'source_count_proof_missing','Fresh audit must verify each expected source triangle count')
    determinant = _triangle_determinants(raw_uv[loops].astype(np.float64))
    _require(not np.any((areas>epsilon)&(determinant==0)),
             'collapsed_stage_required','Run the separate collapsed-only allocator first')
    failed = []
    eligible = set()
    reasons = {}
    for part in before['parts']:
        for island in part['islands']:
            if not (island['zeroCenterFailure'] or island['minorSpanFailure']):
                continue
            positive_members = [int(ti) for ti in island['triangleIndices'] if areas[ti]>epsilon]
            reason = dict(partId=part['partId'],sourceObject=part['sourceObject'],islandId=island['islandId'],
                zeroCenterFailure=island['zeroCenterFailure'],minorSpanFailure=island['minorSpanFailure'],
                pixelCenterCount=island['pixelCenterCount'],principalMinorSpanTexels=island['principalMinorSpanTexels'],
                islandTriangleIndices=island['triangleIndices'],eligiblePositiveAreaTriangles=positive_members,
                retainedNonpositiveAreaTriangles=[int(ti) for ti in island['triangleIndices'] if areas[ti]<=epsilon])
            failed.append(reason)
            for ti in positive_members:
                eligible.add(ti)
                reasons[ti] = reason
    targets = np.array(sorted(eligible),dtype=np.int64)
    _require(len(targets)<=maximum_additional_triangles,'failed_island_bound_exceeded',
             'Fresh failed-island membership exceeds the explicit hard bound',
             eligibleTriangleCount=len(targets),maximumAdditionalTriangles=int(maximum_additional_triangles),
             eligibleTriangles=targets.tolist(),failedIslands=failed)
    output, allocation = _allocate_patches(raw_uv,loops,areas,size=size,bake_margin=bake_margin,
        side_texels=8,world_area_epsilon=epsilon,explicit_targets=targets)
    after = audit_triangle_uvs(output[loops],ids,size,source_parts=source_parts,
        minimum_minor_texels=2.0,triangle_world_areas=areas,world_area_epsilon=epsilon)
    _require(after['centerCoveragePass'] and after['minorSpanPass'] and
             after['sourceTriangleCountsExact'] is True and after['allInputTrianglesRetained'],
             'post_patch_coverage_failed','Fresh complete coverage failed after bounded relocation',
             postAudit=_coverage_summary(after))
    for patch in allocation['patches']:
        patch['eligibility'] = reasons[patch['triangle']]
        patch['sourcePartId'] = int(ids[patch['triangle']])
    return output, dict(schemaVersion=1,policy='fresh_failed_island_membership',
        maximumAdditionalTriangles=int(maximum_additional_triangles),worldAreaEpsilon=epsilon,
        minimumMinorSpanTexels=2.0,eligibleTriangles=targets.tolist(),failedInputIslands=failed,
        inputCoverage=_coverage_summary(before),postCoverage=_coverage_summary(after),allocation=allocation,
        bindingDigests=dict(uv=_digest(raw_uv),triangleLoops=_digest(loops),worldAreas=_digest(areas),
            partIds=_digest(ids),sourcePartsSha256=hashlib.sha256(json.dumps(source_parts,sort_keys=True,
                separators=(',',':'),ensure_ascii=False,allow_nan=False).encode()).hexdigest()),
        requiresFreshBake=True,compatibleWithExistingBakedTextures=False,
        nonTargetUvBytesUnchanged=True,allSourceTriangleCountsExact=True,globalRepack=False,
        nativeGeometryChanged=False,visualApproval=False,deviceApproval=False)
