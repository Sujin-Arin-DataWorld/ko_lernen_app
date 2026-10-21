"""Atlas-only chart guard. Authored UVs and all mesh coordinates stay intact.

Smart-project can produce an entire narrow bevel island with no texel center.
Widening its temporary atlas short axis prevents an opaque black unbaked strip.
This does not certify mip coverage or visual parity; post-bake QA still applies.
"""
import math


def chart_loop_groups(mesh, uv_layer):
    """Join faces only across a shared mesh edge with continuous atlas UVs."""
    import numpy as np
    uv = np.empty((len(mesh.loops), 2), dtype=np.float32)
    uv_layer.data.foreach_get('uv', uv.ravel())
    vertices = np.empty(len(mesh.loops), dtype=np.int32)
    mesh.loops.foreach_get('vertex_index', vertices)
    parent = list(range(len(mesh.polygons)))
    edges = {}

    def root(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for polygon in mesh.polygons:
        loops = list(polygon.loop_indices)
        for a, b in zip(loops, loops[1:] + loops[:1]):
            # Rounding can join a genuine subpixel seam. A zero-length UV edge
            # also cannot join two rasterized regions in the exported audit.
            if np.array_equal(uv[a], uv[b]):
                continue
            ends = sorted(((int(vertices[a]), *uv[a]),
                           (int(vertices[b]), *uv[b])))
            key = tuple(ends)
            if key in edges:
                left, right = root(polygon.index), root(edges[key])
                parent[left] = right
            else:
                edges[key] = polygon.index
    groups = {}
    for polygon in mesh.polygons:
        groups.setdefault(root(polygon.index), []).extend(polygon.loop_indices)
    return [np.array(indices, dtype=np.int32) for indices in groups.values()]


def _principal_span(points):
    import numpy as np
    # Repeated corners would bias the principal direction on triangulated caps.
    points = np.unique(np.asarray(points,dtype=np.float64), axis=0)
    center = points.mean(axis=0)
    # SVD avoids squaring the condition number of extremely thin ridge faces.
    # The UV storage stays float32, but chart measurement is float64.
    # Only the 2x2 right axes are needed. A full N x N U matrix would make
    # large connected charts consume quadratic memory for no useful result.
    axes = (np.eye(2) if len(points) == 1 else
            np.linalg.svd(points-center, full_matrices=False)[2].T)
    coordinates = (points - center) @ axes
    spans = np.ptp(coordinates, axis=0)
    return center, axes, spans


def align_chart_to_pixel_center(uv, indices, triangles, size):
    """Translate a packed chart by <= half a texel per axis, without scaling.

    Thin curved strips can miss the sample grid despite adequate overall span.
    The pack reserves two extra gap texels; opposite half-texel translations
    consume at most one, preserving the nominal bake dilation gap.
    """
    import numpy as np
    from r12_uv_coverage import triangle_pixel_centers
    selected=np.asarray(uv[np.asarray(triangles,dtype=np.int32)],dtype=np.float64)*size
    e0,e1=selected[:,1]-selected[:,0],selected[:,2]-selected[:,0]
    areas=np.abs(e0[:,0]*e1[:,1]-e0[:,1]*e1[:,0])
    original=uv[indices].copy()
    for triangle in np.argsort(areas)[::-1][:16]:
        centroid=selected[triangle].mean(axis=0)
        offset=np.floor(centroid)+.5-centroid
        moved=(original.astype(np.float64)+offset/size).astype(np.float32)
        if (moved<0).any() or (moved>1).any():
            continue
        uv[indices]=moved
        if any(len(triangle_pixel_centers(uv[list(loops)]*size,size)) for loops in triangles):
            return offset.tolist()
    uv[indices]=original
    return None


def export_stable_uv(uv):
    """Use UV32 values whose glTF V flip cannot hide a collapsed chart edge."""
    import numpy as np
    result = np.asarray(uv, dtype=np.float32).copy()
    result[:, 1] = np.float32(1) - (np.float32(1) - result[:, 1])
    return result


def _loop_partition(groups, count):
    import numpy as np
    partition = np.empty(count, dtype=np.int32)
    for indices in groups:
        partition[indices] = int(min(indices))
    return partition


def repair_collapsed_triangle_uvs(uv, loops, world_areas, *, size, minimum_minor_texels):
    """Separate positive-area triangles whose temporary atlas mapping collapsed.

    A large painted island can still contain a triangle mapped to one line.
    That surface has no valid tangent parameterization. Give it an isolated
    right triangle in the temporary atlas; the source shader coordinates and
    geometry are unchanged and the next pack/bake authors its new mapping.
    """
    import numpy as np
    loops = np.asarray(loops, dtype=np.int32)
    points = uv[loops].astype(np.float64)
    a, b = points[:,1]-points[:,0], points[:,2]-points[:,0]
    collapsed = np.flatnonzero((world_areas > 1e-12) & (a[:,0]*b[:,1]-a[:,1]*b[:,0] == 0))
    edge = minimum_minor_texels*2.6/size
    for index, triangle in enumerate(collapsed):
        # Separate locations prevent accidental joining through another chart
        # with the same mesh edge. pack_islands will put them inside [0,1].
        offset = 2 + index*edge*3
        uv[loops[triangle]] = np.array([[offset,2], [offset+edge,2], [offset,2+edge]],dtype=np.float32)
    return collapsed.tolist()


def guard_and_pack(bpy, mesh, uv_layer, *, size, bake_margin,
                   minimum_minor_texels=2.0, iterations=12, _repartition_pass=0,
                   _force_pack=False):
    import numpy as np
    from r12_uv_coverage import triangle_pixel_centers
    def require(condition, message):
        if not condition:
            raise RuntimeError(message)
    require(size >= 128 and minimum_minor_texels > 0, 'Invalid atlas chart guard')
    uv_name = uv_layer.name
    uv = np.empty((len(mesh.loops), 2), dtype=np.float32)
    uv_layer.data.foreach_get('uv', uv.ravel())
    uv = export_stable_uv(uv)
    vertices = np.empty((len(mesh.vertices), 3), dtype=np.float32)
    mesh.vertices.foreach_get('co', vertices.ravel())
    loop_vertices = np.empty(len(mesh.loops), dtype=np.int32)
    mesh.loops.foreach_get('vertex_index', loop_vertices)
    mesh.calc_loop_triangles()
    source_triangles = np.array([t.loops for t in mesh.loop_triangles],dtype=np.int32)
    points = vertices[loop_vertices[source_triangles]].astype(np.float64)
    triangle_areas = np.linalg.norm(np.cross(points[:,1]-points[:,0],points[:,2]-points[:,0]),axis=1)*.5
    # The exporter supplies an exact triangulated copy. Legacy quad-only test
    # fixtures still use the original chart projection path for shared loops.
    triangle_only = all(p.loop_total == 3 for p in mesh.polygons)
    # Repair whole collapsed charts first. Smart projection may initially put
    # thousands of their triangles on a line; separating them here explodes the
    # atlas and destroys useful shared-chart continuity. Only residual collapsed
    # triangles in otherwise repaired/packed charts are split below.
    separated = []
    uv_layer.data.foreach_set('uv',uv.ravel())
    groups = chart_loop_groups(mesh, uv_layer)
    initial_partition = _loop_partition(groups, len(mesh.loops))
    loop_charts = np.empty(len(mesh.loops), dtype=np.int32)
    for index, indices in enumerate(groups):
        loop_charts[indices] = index
    world_areas = np.zeros(len(groups), dtype=np.float64)
    chart_triangles = [[] for _ in groups]
    for triangle in mesh.loop_triangles:
        chart = loop_charts[triangle.loops[0]]
        area = float(triangle_areas[triangle.index])
        world_areas[chart] += area
        if area > 1e-12:
            chart_triangles[chart].append(list(triangle.loops))

    def has_center(index):
        return any(len(triangle_pixel_centers(uv[loops] * size, size))
                   for loops in chart_triangles[index])
    zero_area_charts = set()
    projected_charts = set()
    margin = (2 * bake_margin + 2) / size
    initial_small = 0
    widened = set()
    coverage_enlarged = set()
    history = []
    for iteration in range(iterations):
        changed = int(iteration == 0 and (bool(separated) or _force_pack))
        zero_center_diagnostics = []
        min_span = math.inf
        for index, indices in enumerate(groups):
            # Match the decoded-GLB audit: every individual world triangle
            # below epsilon is exempt, even if their aggregate exceeds epsilon.
            if not chart_triangles[index]:
                zero_area_charts.add(index)
            if index in zero_area_charts:
                continue
            center, axes, spans = _principal_span(uv[indices])
            short = int(np.argmin(spans))
            span = float(spans[short]) * size
            if span <= 1e-8:
                if world_areas[index] <= 1e-12:
                    # Preserve original zero-area triangles/identities. They
                    # rasterize no surface, so cannot require painted pixels.
                    zero_area_charts.add(index)
                    continue
                # Only the newly created atlas collapsed. Project its existing
                # 3D corners to their best-fit plane, then pack and rebake.
                # Authored shader-coordinate attributes are untouched.
                points = vertices[loop_vertices[indices]].astype(np.float64)
                origin = points.mean(axis=0)
                _, _, vectors = np.linalg.svd(points-origin,full_matrices=False)
                projected = (points-origin) @ vectors[:2].T
                projected_spans = np.ptp(projected, axis=0)
                require(float(min(projected_spans)) > 1e-12,
                        f'Nonzero world area with unprojectable UV chart {index}')
                target_span = max(float(max(spans)), minimum_minor_texels/size)
                # Expand both projected axes in float64 before storing UV32.
                # A very thin ridge triangle can otherwise collapse again at
                # its nonzero atlas offset before the short-axis guard runs.
                scales=np.maximum(target_span/max(projected_spans),
                                  (minimum_minor_texels*1.3/size)/projected_spans)
                uv[indices] = projected * scales + center
                projected_charts.add(index)
                changed += 1
                center, axes, spans = _principal_span(uv[indices])
                short = int(np.argmin(spans))
                span = float(spans[short]) * size
                require(span > 1e-8, f'Projected atlas chart {index} collapsed in UV32')
            min_span = min(min_span, span)
            if span + 1e-4 < minimum_minor_texels:
                if iteration == 0:
                    initial_small += 1
                coordinates = (uv[indices] - center) @ axes
                # Headroom compensates for the scale applied by the next pack.
                coordinates[:, short] *= (minimum_minor_texels * 1.3) / span
                uv[indices] = coordinates @ axes.T + center
                widened.add(index)
                changed += 1
            if chart_triangles[index] and not has_center(index):
                selected = uv[np.array(chart_triangles[index],dtype=np.int32)] * size
                edge0, edge1 = selected[:,1]-selected[:,0], selected[:,2]-selected[:,0]
                zero_center_diagnostics.append(dict(chart=index, triangles=len(selected),
                    uvAreaTexels=float(np.abs(edge0[:,0]*edge1[:,1]-edge0[:,1]*edge1[:,0]).sum()*.5),
                    worldArea=float(world_areas[index]), principalSpanTexels=span))
                # Thin annuli can have a large bounding box yet no covered
                # pixel. Scale the temporary chart itself, never the geometry.
                uv[indices] = (uv[indices] - center) * 2 + center
                coverage_enlarged.add(index)
                changed += 1
        history.append(dict(iteration=iteration, widenedCharts=changed,
                            minimumPrincipalSpanTexels=min_span,
                            zeroCenterDiagnostics=zero_center_diagnostics))
        if not changed:
            break
        mesh.uv_layers[uv_name].data.foreach_set('uv', uv.ravel())
        mesh.update()
        print('R12 UV PACK', iteration, 'charts', len(groups), 'changed', changed, flush=True)
        if zero_center_diagnostics:
            print('R12 UV ZERO CENTERS', zero_center_diagnostics[:12], flush=True)
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.uv.pack_islands(rotate=True, rotate_method='CARDINAL', scale=True,
                               margin_method='FRACTION', margin=margin,
                               shape_method='CONCAVE', merge_overlap=False)
        bpy.ops.object.mode_set(mode='OBJECT')
        mesh.uv_layers[uv_name].data.foreach_get('uv', uv.ravel())
    def refresh_partition(stage):
        # Packing and UV32 writeback can collapse a shared UV edge. The
        # originally connected chart then hides unpainted fragments unless
        # connectivity is rebuilt from the final coordinates. Audit the exact
        # float32 V-flip convention used by Blender's glTF exporter as well.
        nonlocal uv
        uv = export_stable_uv(uv)
        # Residual collapsed triangles are allocated to verified empty patches
        # after this whole-chart guard. A global repack here can collapse a
        # different microscopic triangle and never reach a stable atlas.
        newly_separated = []
        mesh.uv_layers[uv_name].data.foreach_set('uv', uv.ravel())
        mesh.update()
        refreshed = chart_loop_groups(mesh, mesh.uv_layers[uv_name])
        if not newly_separated and np.array_equal(initial_partition, _loop_partition(refreshed, len(mesh.loops))):
            return None
        require(_repartition_pass < 4,
                'Atlas connectivity remains unstable after final UV32 packing; split the bake group')
        print('R12 UV REPARTITION', stage, len(groups), 'to', len(refreshed), flush=True)
        result = guard_and_pack(bpy, mesh, mesh.uv_layers[uv_name], size=size,
            bake_margin=bake_margin, minimum_minor_texels=minimum_minor_texels,
            iterations=iterations, _repartition_pass=_repartition_pass+1,
            _force_pack=bool(newly_separated))
        result.setdefault('repartitionHistory', []).insert(0, dict(
            stage=stage, beforeCharts=len(groups), afterCharts=len(refreshed),
            separatedCollapsedTriangles=newly_separated,
            packingIterations=history))
        return result

    refreshed_result = refresh_partition('after-packing')
    if refreshed_result is not None:
        return refreshed_result
    final_spans = [float(min(_principal_span(uv[indices])[2])) * size
                   for index, indices in enumerate(groups) if index not in zero_area_charts]
    remaining = sum(span + 1e-4 < minimum_minor_texels for span in final_spans)
    require(not remaining, f'{remaining} atlas charts still below {minimum_minor_texels} texels; '
            f'smallest spans {sorted(final_spans)[:8]}; split the bake group')
    uncovered = [i for i in range(len(groups))
                 if chart_triangles[i] and not has_center(i)]
    aligned=[]
    for index in uncovered:
        offset=align_chart_to_pixel_center(uv,groups[index],chart_triangles[index],size)
        if offset is not None:
            aligned.append(dict(chart=index,offsetTexels=offset))
    if aligned:
        mesh.uv_layers[uv_name].data.foreach_set('uv',uv.ravel())
        mesh.update()
    refreshed_result = refresh_partition('after-pixel-alignment')
    if refreshed_result is not None:
        return refreshed_result
    uncovered = [i for i in range(len(groups))
                 if chart_triangles[i] and not has_center(i)]
    final_spans = [float(min(_principal_span(uv[indices])[2]))*size
                   for index,indices in enumerate(groups) if index not in zero_area_charts]
    require(all(span+1e-4>=minimum_minor_texels for span in final_spans),
            'Pixel alignment reduced a chart below the minor-span limit')
    require(not uncovered, f'{len(uncovered)} visible atlas charts lack pixel centers; split the bake group')
    require(bool(((uv >= 0) & (uv <= 1)).all()), 'Final temporary atlas coordinates outside [0,1]')
    return dict(chartCount=len(groups), initiallyUndersampledCharts=initial_small,
                widenedCharts=len(widened), minimumMinorTexels=minimum_minor_texels,
                coverageEnlargedCharts=sorted(coverage_enlarged),
                pixelAlignedCharts=aligned,
                preExportVisibleZeroCenterCharts=uncovered,
                retainedZeroWorldAreaCharts=sorted(zero_area_charts),
                projectedCollapsedAtlasCharts=sorted(projected_charts),
                separatedCollapsedAtlasTriangles=separated,
                actualMinimumPrincipalSpanTexels=min(final_spans, default=0),
                packingMarginMethod='FRACTION', packingMarginFraction=margin,
                nominalGapTexels=2*bake_margin+2, bakeMarginType='EXTEND',
                temporaryAtlasOnly=True, originalGeometryChanged=False,
                finalUv32PartitionRebuilt=True, exportedVFlipChecked=True,
                mipAndPixelCoverageApproved=False, iterations=history)
