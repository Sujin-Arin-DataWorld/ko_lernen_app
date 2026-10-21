"""Experimental paired normal-map basis. Never imported by the R12 exporter.

This is not MikkTSpace compatibility or a repair for an existing normal map.
The basis requires a matched rebake. Geometry/UVs and valid authored normals are
never edited; zero normals may be recovered on detached positive-area corners
only, with explicit diagnostics. Undefined parameterizations fail closed.
"""
from dataclasses import dataclass
import copy
import hashlib
import itertools
import numpy as np


class FrameError(ValueError):
    def __init__(self, code, message, **details):
        self.code, self.details = code, details
        super().__init__(f'{code}: {message}; {details}')


def _require(condition, code, message, **details):
    if not condition:
        raise FrameError(code, message, **details)


def _reject_mask(mask, code, message):
    if np.any(mask):
        where = np.argwhere(mask)
        raise FrameError(code, message, count=len(where), firstIndices=where[:16].tolist())


def _digest(values):
    values = np.asarray(values)
    return hashlib.sha256(str((values.dtype.str, values.shape)).encode() + values.tobytes()).hexdigest()


def _unit(values, code, minimum=1e-12):
    lengths = np.linalg.norm(values, axis=-1)
    _reject_mask(~np.isfinite(lengths) | (lengths <= minimum), code, 'Cannot normalize a finite nonzero vector')
    return values / lengths[..., None]


@dataclass(frozen=True)
class StableFrame:
    # Float32 arrays are the proposed explicit bake/export attribute values.
    # Do not regenerate a different basis during encoding or after serialization.
    normals: np.ndarray
    tangents: np.ndarray
    bitangents: np.ndarray
    handedness: np.ndarray
    corner_group_ids: np.ndarray
    renderable_triangles: np.ndarray
    report: dict


def build_stable_frame(positions, normals, uv, *, world_area_epsilon=1e-12,
                       unit_tolerance=1e-3, projection_tolerance=1e-12,
                       cancellation_tolerance=1e-10,
                       undefined_frame_policy='reject', source_part_ids=None):
    """Build an experimental angle-weighted frame for exact triangle corners.

    positions: (triangles, 3, 3), common-coordinate-space floating point values.
    normals: same shape, Float32; valid values remain byte-identical in output.
    uv: (triangles, 3, 2), the exact Float32 atlas that will be baked/exported.

    Derivatives and atan2 corner weights use float64. Exact numeric position,
    stored normal, UV and effective handedness define seam groups. Each corner's
    projected unit dP/du is angle weighted, so a skinny triangle's derivative
    magnitude cannot dominate its neighbors. Cancelled groups fail explicitly.
    Triangles at/below the explicit area threshold remain present, with no
    invented frame (T/B/handedness zero, group -1, renderable mask false).

    undefined_frame_policy='geometric_face' explicitly permits a constant
    geometric render frame only on triangles with an undefined corner
    derivative frame. These triangles are isolated from smooth seam groups and
    fully reported. Their authored normals are unchanged in the input; output
    frame normals differ as declared. A matched bake MUST still sample the
    ORIGINAL shading normal, not these frame normals. Whole-interior failure
    and cancelled smooth groups still reject; they are not silently flattened.
    """
    raw_p, raw_n, raw_uv = np.asarray(positions), np.asarray(normals), np.asarray(uv)
    _require(raw_p.ndim == 3 and raw_p.shape[1:] == (3, 3) and len(raw_p) > 0,
             'input_shape', 'Expected nonempty triangle positions (N,3,3)')
    _require(raw_n.shape == raw_p.shape and raw_uv.shape == (len(raw_p), 3, 2),
             'input_shape', 'Normal/UV corner shapes differ')
    _require(raw_p.dtype.kind == 'f' and raw_n.dtype == np.float32 and raw_uv.dtype == np.float32,
             'input_precision', 'Positions must be floating point; normals and UV must be exact Float32')
    _require(all(np.isfinite(a).all() for a in (raw_p, raw_n, raw_uv)), 'nonfinite_input', 'Nonfinite source values')
    _require(undefined_frame_policy in ('reject', 'geometric_face'),
             'invalid_policy', 'Unknown undefined-frame policy')
    part_ids = None if source_part_ids is None else np.asarray(source_part_ids)
    if part_ids is not None:
        _require(part_ids.shape == (len(raw_p),) and part_ids.dtype.kind in 'iuUSf',
                 'source_part_shape', 'Expected one scalar source part identity per triangle')
        if part_ids.dtype.kind == 'f':
            _require(np.isfinite(part_ids).all() and np.all(part_ids == np.floor(part_ids)),
                     'source_part_identity', 'Numeric source part identities must be exact finite integers')
    _require(np.isfinite(world_area_epsilon) and world_area_epsilon >= 0 and
             all(np.isfinite(v) and 0 < v < 1 for v in
                 (unit_tolerance, projection_tolerance, cancellation_tolerance)),
             'invalid_tolerance', 'Invalid explicit thresholds')
    points, tex = raw_p.astype(np.float64), raw_uv.astype(np.float64)
    e1, e2 = points[:, 1] - points[:, 0], points[:, 2] - points[:, 0]
    cross = np.cross(e1, e2)
    twice_area = np.linalg.norm(cross, axis=1)
    _reject_mask(~np.isfinite(twice_area), 'world_area_overflow', 'World triangle area is not finite')
    areas = twice_area * .5
    positive = areas > world_area_epsilon
    normal_values = raw_n.copy()
    tangent_values = np.zeros_like(raw_n)
    bitangent_values = np.zeros_like(raw_n)
    handedness = np.zeros(raw_n.shape[:2], dtype=np.float32)
    group_ids = np.full(raw_n.shape[:2], -1, dtype=np.int64)
    report = dict(schemaVersion=1, experimental=True, requiresMatchedRebake=True,
                  compatibleWithExistingNormalMap=False, mikkTSpaceParityClaimed=False,
                  basisStorage='float32', geometryChanged=False, atlasUvChanged=False,
                  nativeWritten=False, triangleCount=len(points),
                  positiveWorldAreaTriangles=int(positive.sum()),
                  retainedAtOrBelowAreaThresholdTriangles=int((~positive).sum()),
                  exactZeroAreaTriangles=int((areas == 0).sum()),
                  tolerances=dict(worldAreaEpsilon=world_area_epsilon, unitLength=unit_tolerance,
                                  projectedDerivativeRelative=projection_tolerance,
                                  weightedDirectionCancellation=cancellation_tolerance),
                  inputDigests=dict(positions=_digest(raw_p), normals=_digest(raw_n), uv=_digest(raw_uv)),
                  recoveredZeroNormalCorners=[], recoveredZeroNormalCornerCount=0, seamGroups=0,
                  undefinedFramePolicy=undefined_frame_policy, geometricRenderFrameTriangles=[],
                  geometricRenderFrameTriangleCount=0, nativeAuthoredNormalsUnchanged=True,
                  originalShadingNormalRequiredForBake=True)
    if not positive.any():
        report['validAuthoredNormalsUnchanged'] = True
        return StableFrame(normal_values, tangent_values, bitangent_values, handedness, group_ids, positive, report)
    selected = np.flatnonzero(positive)
    dp1, dp2 = e1[positive], e2[positive]
    dt1, dt2 = tex[positive, 1] - tex[positive, 0], tex[positive, 2] - tex[positive, 0]
    determinant = dt1[:, 0] * dt2[:, 1] - dt1[:, 1] * dt2[:, 0]
    if np.any(determinant == 0):
        raise FrameError('collapsed_positive_area_uv', 'Positive-area surface has no UV parameterization; rebake atlas first',
                         triangles=selected[determinant == 0][:16].tolist(), count=int((determinant == 0).sum()))
    du = (dp1 * dt2[:, 1, None] - dp2 * dt1[:, 1, None]) / determinant[:, None]
    dv = (dp2 * dt1[:, 0, None] - dp1 * dt2[:, 0, None]) / determinant[:, None]
    _reject_mask(~np.isfinite(du).all(axis=1) | ~np.isfinite(dv).all(axis=1),
                 'derivative_overflow', 'UV derivatives are not finite')
    n = normal_values[positive].astype(np.float64)
    lengths = np.linalg.norm(n, axis=2)
    zero = lengths == 0
    _reject_mask((np.abs(lengths - 1) > unit_tolerance) & ~zero,
                 'nonunit_authored_normal', 'Nonzero authored normals must already be unit vectors')
    face_normals = cross[positive] / twice_area[positive, None]
    for ti, ci in np.argwhere(zero):
        source_triangle = int(selected[ti])
        recovered = face_normals[ti].astype(np.float32)
        normal_values[source_triangle, ci] = recovered
        report['recoveredZeroNormalCorners'].append(dict(triangle=source_triangle, corner=int(ci),
            worldArea=float(areas[source_triangle]), recoveredNormal=recovered.tolist(),
            source='positive-area geometric face normal; detached experimental basis only'))
    n = normal_values[positive].astype(np.float64)
    unit_n = _unit(n, 'invalid_corner_normal')
    unit_du = _unit(du, 'invalid_derivative_u')
    unit_dv = _unit(dv, 'invalid_derivative_v')
    # Project unit derivatives first: this bounds arithmetic for narrow UVs.
    projected = unit_du[:, None, :] - unit_n * np.einsum('tci,ti->tc', unit_n, unit_du)[..., None]
    projected_length = np.linalg.norm(projected, axis=2)
    invalid_projected = projected_length <= projection_tolerance
    unit_t = np.divide(projected, projected_length[..., None], out=np.zeros_like(projected),
                       where=projected_length[..., None] > projection_tolerance)
    orientation = np.einsum('tci,ti->tc', np.cross(unit_n, unit_t), unit_dv)
    invalid_orientation = np.abs(orientation) <= projection_tolerance
    signs = np.sign(orientation)
    mixed_handedness = np.any(signs != signs[:, :1], axis=1)
    fallback = invalid_projected.any(axis=1) | invalid_orientation.any(axis=1) | mixed_handedness
    if undefined_frame_policy == 'reject':
        _reject_mask(invalid_projected, 'singular_corner_tangent', 'Projected derivative is undefined against the authored corner normal')
    if invalid_orientation.any() and undefined_frame_policy == 'reject':
        corners = np.argwhere(invalid_orientation)
        raise FrameError('singular_corner_orientation',
            'Derivative handedness is undefined against the authored corner normal; no replacement policy was applied',
            count=len(corners), sourceTriangleCorners=[[int(selected[ti]), int(ci)] for ti, ci in corners[:16]],
            recoveredZeroNormalCornerCount=int(zero.sum()),
            recoveredZeroNormalCorners=report['recoveredZeroNormalCorners'])
    if undefined_frame_policy == 'reject':
        _reject_mask(mixed_handedness,
                     'mixed_triangle_handedness', 'A triangle cannot interpolate conflicting handedness')
    if fallback.any():
        # Explicit optional render-coordinate policy, not a native normal edit.
        face_n = face_normals[fallback].astype(np.float32).astype(np.float64)
        unit_face_n = _unit(face_n, 'invalid_geometric_policy_normal')
        face_t = unit_du[fallback] - unit_face_n * np.einsum('ti,ti->t', unit_du[fallback], unit_face_n)[:, None]
        face_t = _unit(face_t, 'invalid_geometric_policy_tangent', minimum=projection_tolerance)
        face_w = np.sign(determinant[fallback])
        for fi, ti in enumerate(np.flatnonzero(fallback)):
            source_triangle = int(selected[ti])
            reasons = []
            if invalid_projected[ti].any():
                reasons.append('undefined projected dPdu against authored normal')
            if invalid_orientation[ti].any():
                reasons.append('undefined derivative handedness against authored normal')
            if mixed_handedness[ti]:
                reasons.append('conflicting derivative handedness across authored corner normals')
            record = dict(triangle=source_triangle,
                sourcePartId=None if part_ids is None else part_ids[source_triangle].item(),
                worldArea=float(areas[source_triangle]), reasons=reasons,
                authoredNormals=raw_n[source_triangle].tolist(),
                frameNormal=face_n[fi].tolist(), frameTangent=face_t[fi].astype(np.float32).tolist(),
                frameBitangent=(np.cross(unit_face_n[fi], face_t[fi])*face_w[fi]).astype(np.float32).tolist(),
                handedness=float(face_w[fi]), isolatedFromSmoothGroups=True,
                originalShadingNormalRequiredForBake=True)
            report['geometricRenderFrameTriangles'].append(record)
            normal_values[source_triangle] = face_n[fi]
            unit_n[ti] = unit_face_n[fi]
            unit_t[ti] = face_t[fi]
            signs[ti] = face_w[fi]
        n = normal_values[positive].astype(np.float64)
    selected_points = points[positive]
    weights = np.empty((len(selected), 3), dtype=np.float64)
    for corner in range(3):
        a = selected_points[:, (corner + 1) % 3] - selected_points[:, corner]
        b = selected_points[:, (corner + 2) % 3] - selected_points[:, corner]
        weights[:, corner] = np.arctan2(np.linalg.norm(np.cross(a, b), axis=1), np.einsum('ij,ij->i', a, b))
    _reject_mask(~np.isfinite(weights) | (weights <= 0), 'invalid_corner_weight', 'Positive-area corner has no stable angle')
    isolation = np.zeros((len(selected), 3, 1), dtype=np.float64)
    isolation[fallback] = (selected[fallback] + 1)[:, None, None]
    keys = np.concatenate((selected_points, n, tex[positive], signs[..., None], isolation), axis=2).reshape(-1, 10)
    unique, inverse = np.unique(keys, axis=0, return_inverse=True)
    weighted = (unit_t * weights[..., None]).reshape(-1, 3)
    totals = np.column_stack([np.bincount(inverse, weights=weighted[:, axis], minlength=len(unique)) for axis in range(3)])
    total_weights = np.bincount(inverse, weights=weights.ravel(), minlength=len(unique))
    group_n = _unit(unique[:, 3:6], 'invalid_group_normal')
    totals -= group_n * np.einsum('ij,ij->i', group_n, totals)[:, None]
    ratio = np.linalg.norm(totals, axis=1) / total_weights
    _reject_mask(~np.isfinite(ratio) | (ratio <= cancellation_tolerance),
                 'cancelled_group_tangent', 'Angle-weighted shared tangent directions cancel')
    group_t = _unit(totals / total_weights[:, None], 'invalid_group_tangent', minimum=cancellation_tolerance)
    group_b = np.cross(group_n, group_t) * unique[:, 8, None]
    tangent_values[positive] = group_t[inverse].reshape(-1, 3, 3).astype(np.float32)
    bitangent_values[positive] = group_b[inverse].reshape(-1, 3, 3).astype(np.float32)
    handedness[positive] = signs.astype(np.float32)
    group_ids[positive] = inverse.reshape(-1, 3)
    for record in report['geometricRenderFrameTriangles']:
        ti = record['triangle']
        # The policy promises one constant Float32 frame across the triangle;
        # do not let independent weight sums introduce a last-bit difference.
        tangent_values[ti] = record['frameTangent']
        bitangent_values[ti] = record['frameBitangent']
    valid_normals = np.linalg.norm(raw_n.astype(np.float64), axis=2) != 0
    preserved_normals = valid_normals.copy()
    preserved_normals[selected[fallback]] = False
    _require(normal_values[preserved_normals].tobytes() == raw_n[preserved_normals].tobytes(),
             'normal_mutation', 'Valid authored normals changed')
    report.update(seamGroups=len(unique), recoveredZeroNormalCornerCount=int(zero.sum()),
                  minimumWeightedDirectionRatio=float(ratio.min()),
                  validAuthoredNormalsUnchanged=not bool(fallback.any()),
                  validAuthoredNormalsOutsideDeclaredRenderPolicyUnchanged=True,
                  geometricRenderFrameTriangleCount=int(fallback.sum()))
    return StableFrame(normal_values, tangent_values, bitangent_values, handedness, group_ids, positive, report)


def interpolated_tbn(frame, triangle_indices, barycentrics, *, maximum_condition=1e6, minimum_column_length=1e-12):
    """Columns are separately normalized interpolated T/B/N, not re-orthogonalized.

    Use perspective-correct barycentric weights from the actual bake sample.
    Float32 corner attributes are interpreted exactly as supplied by the frame.
    This call validates only requested samples, not every point of a triangle.
    """
    indices, bary = np.asarray(triangle_indices), np.asarray(barycentrics, dtype=np.float64)
    _require(indices.ndim == 1 and len(indices) > 0 and indices.dtype.kind in 'iu' and bary.shape == (len(indices), 3),
             'sample_shape', 'Expected triangle indices (M,) and barycentrics (M,3)')
    _require(np.isfinite(bary).all() and np.all(bary >= -1e-12) and np.all(bary <= 1+1e-12)
             and np.all(np.abs(bary.sum(axis=1)-1) <= 1e-10), 'invalid_barycentrics', 'Invalid triangle weights')
    _require(np.all(indices >= 0) and np.all(indices < len(frame.renderable_triangles)),
             'sample_index', 'Triangle sample index out of range')
    _require(np.isfinite(maximum_condition) and maximum_condition >= 1 and
             np.isfinite(minimum_column_length) and minimum_column_length > 0,
             'invalid_tolerance', 'Invalid interpolation condition threshold')
    _require(frame.renderable_triangles[indices].all(), 'degenerate_triangle_sample', 'No frame is fabricated for retained degenerate triangles')
    columns = []
    for values in (frame.tangents, frame.bitangents, frame.normals):
        interpolated = np.einsum('mc,mci->mi', bary, values[indices].astype(np.float64))
        columns.append(_unit(interpolated, 'singular_interpolated_column', minimum=minimum_column_length))
    basis = np.stack(columns, axis=2)
    singular = np.linalg.svd(basis, compute_uv=False)
    _reject_mask(~np.isfinite(singular).all(axis=1) | (singular[:, -1] <= singular[:, 0]/maximum_condition),
                 'singular_interpolated_tbn', 'Normalized interpolated frame is singular or ill-conditioned')
    return basis


def _sample_unit_vectors(vectors, count, code):
    values = np.asarray(vectors, dtype=np.float64)
    _require(values.shape == (count, 3) and np.isfinite(values).all(), code, 'Expected finite sample vectors (M,3)')
    return _unit(values, code)


def encode_world_normals(frame, triangle_indices, barycentrics, world_normals, **basis_options):
    """Normalize(inv(normalized interpolated TBN) @ sampled world normal).

    Only this paired encoding is compatible with this experimental basis. This
    does not edit or convert an old tangent-space normal map.
    """
    basis = interpolated_tbn(frame, triangle_indices, barycentrics, **basis_options)
    target = _sample_unit_vectors(world_normals, len(basis), 'invalid_world_normal')
    local = np.linalg.solve(basis, target[..., None])[..., 0]
    return _unit(local, 'invalid_encoded_normal')


def decode_world_normals(frame, triangle_indices, barycentrics, encoded_normals, **basis_options):
    basis = interpolated_tbn(frame, triangle_indices, barycentrics, **basis_options)
    local = _sample_unit_vectors(encoded_normals, len(basis), 'invalid_encoded_normal')
    return _unit(np.einsum('mij,mj->mi', basis, local), 'invalid_decoded_normal')


def audit_frames(tangents, bitangents, normals, triangle_positions, *,
                 barycentric_points=None, world_area_epsilon=1e-12,
                 maximum_condition=1e6, corner_unit_tolerance=1e-5,
                 corner_orthogonality_tolerance=1e-5):
    """Fail-closed preflight for the exact Float32 CORNER attribute arrays.

    The determinant of the three *unnormalized* interpolated columns is a
    cubic triangular Bernstein polynomial. Its ten coefficients are averages
    of the corresponding mixed corner determinants. If all coefficients have
    one strict sign, their convex hull bounds the determinant everywhere in
    the closed triangle, including edges. Dividing the bound by the product of
    maximum corner-column lengths also bounds the separately normalized TBN.
    For its three unit columns, sigma_max <= sqrt(3) and sigma_min >= det/3;
    hence 3*sqrt(3)/det is a conservative condition-number upper bound.

    A 64-epsilon product-norm allowance covers ordinary Float64 roundoff; this
    is an algebraic numerical certificate, not interval arithmetic or proof of
    GPU arithmetic. A mixed coefficient sign means *uncertified*, not proof of
    a singularity. This function never substitutes sampled success for the
    all-interior certificate. barycentric_points optionally supplies common
    (M,3) locations tested on every positive-area triangle, in bounded batches.

    Degenerate triangles are retained and hashed but excluded explicitly.
    A successful result is numerical preflight only, never art/device approval.
    """
    values = [np.asarray(v) for v in (tangents, bitangents, normals)]
    raw_p = np.asarray(triangle_positions)
    _require(raw_p.ndim == 3 and raw_p.shape[1:] == (3, 3) and len(raw_p) > 0,
             'input_shape', 'Expected nonempty triangle positions (N,3,3)')
    _require(all(v.shape == raw_p.shape and v.dtype == np.float32 for v in values)
             and raw_p.dtype.kind == 'f', 'input_precision', 'Frame corners must be exact Float32')
    _require(all(np.isfinite(v).all() for v in values + [raw_p]),
             'nonfinite_input', 'Nonfinite frame or position')
    _require(np.isfinite(world_area_epsilon) and world_area_epsilon >= 0 and
             np.isfinite(maximum_condition) and maximum_condition >= 1 and
             all(np.isfinite(v) and 0 < v < 1 for v in
                 (corner_unit_tolerance, corner_orthogonality_tolerance)),
             'invalid_tolerance', 'Invalid preflight thresholds')
    p = raw_p.astype(np.float64)
    area = np.linalg.norm(np.cross(p[:, 1] - p[:, 0], p[:, 2] - p[:, 0]), axis=1) * .5
    _reject_mask(~np.isfinite(area), 'world_area_overflow', 'World triangle area is not finite')
    positive = area > world_area_epsilon
    selected = np.flatnonzero(positive)
    t, b, n = [v[positive].astype(np.float64) for v in values]
    lengths = [np.linalg.norm(v, axis=2) for v in (t, b, n)]
    bad_units = np.zeros(len(selected), dtype=bool)
    for length in lengths:
        bad_units |= np.any(np.abs(length - 1) > corner_unit_tolerance, axis=1)
    dots = [np.einsum('tci,tci->tc', a, c) for a, c in ((t, b), (t, n), (b, n))]
    bad_orthogonal = np.zeros(len(selected), dtype=bool)
    for dot in dots:
        bad_orthogonal |= np.any(np.abs(dot) > corner_orthogonality_tolerance, axis=1)
    corner_det = np.einsum('tci,tci->tc', t, np.cross(b, n))
    bad_orientation = np.any(np.sign(corner_det) != np.sign(corner_det[:, :1]), axis=1)
    coefficients = []
    for multiset in itertools.combinations_with_replacement(range(3), 3):
        terms = []
        for i, j, k in sorted(set(itertools.permutations(multiset))):
            terms.append(np.einsum('ti,ti->t', t[:, i], np.cross(b[:, j], n[:, k])))
        coefficients.append(np.mean(terms, axis=0))
    coefficients = np.stack(coefficients, axis=1)
    max_length_product = np.prod(np.stack([length.max(axis=1) for length in lengths], axis=1), axis=1)
    roundoff = 64 * np.finfo(np.float64).eps * max_length_product
    # Negative orientation is equally valid. Cross-zero coefficients fail.
    raw_bound = np.maximum(coefficients.min(axis=1), -coefficients.max(axis=1)) - roundoff
    normalized_bound = np.divide(raw_bound, max_length_product,
                                 out=np.zeros_like(raw_bound), where=max_length_product > 0)
    required_det = 3 * np.sqrt(3) / maximum_condition
    bad_condition = normalized_bound <= required_det
    bad = bad_units | bad_orthogonal | bad_orientation | bad_condition
    sample_fail = np.zeros(len(selected), dtype=bool)
    sampled_points = 0
    minimum_sample_determinant = None
    maximum_sample_condition = None
    if barycentric_points is not None:
        bary = np.asarray(barycentric_points, dtype=np.float64)
        _require(bary.ndim == 2 and bary.shape[1:] == (3,) and len(bary) > 0 and
                 np.isfinite(bary).all() and np.all(bary >= 0) and np.all(bary <= 1) and
                 np.all(np.abs(bary.sum(axis=1) - 1) <= 1e-10),
                 'invalid_barycentrics', 'Expected nonempty common barycentric sample locations')
        sampled_points = len(selected) * len(bary)
        for start in range(0, len(selected), max(1, 65536 // len(bary))):
            end = min(len(selected), start + max(1, 65536 // len(bary)))
            columns = [np.einsum('sc,tci->tsi', bary, v[start:end]) for v in (t, b, n)]
            column_lengths = [np.linalg.norm(v, axis=2) for v in columns]
            invalid = np.zeros((end-start, len(bary)), dtype=bool)
            for col, length in zip(columns, column_lengths):
                invalid |= ~np.isfinite(length) | (length <= 1e-12)
                np.divide(col, length[..., None], out=col, where=length[..., None] > 1e-12)
            basis = np.stack(columns, axis=3)
            singular = np.linalg.svd(basis, compute_uv=False)
            condition = np.divide(singular[..., 0], singular[..., -1],
                                  out=np.full(invalid.shape, np.inf), where=singular[..., -1] > 0)
            determinant = np.abs(np.linalg.det(basis))
            invalid |= ~np.isfinite(condition) | (condition >= maximum_condition)
            sample_fail[start:end] = invalid.any(axis=1)
            sample_min, sample_max = float(determinant.min()), float(condition.max())
            minimum_sample_determinant = sample_min if minimum_sample_determinant is None else min(minimum_sample_determinant, sample_min)
            maximum_sample_condition = sample_max if maximum_sample_condition is None else max(maximum_sample_condition, sample_max)
    passed = len(selected) > 0 and not bad.any() and not sample_fail.any()
    return dict(schemaVersion=1, experimental=True, requiresMatchedRebake=True,
        passed=bool(passed), interiorGate='certified' if len(selected) > 0 and not bad.any() else 'not_certified',
        sampledGate=('failed' if sample_fail.any() else 'passed') if barycentric_points is not None else 'not_requested',
        proofMethod='cubic triangular Bernstein determinant convex hull; Float64 with roundoff allowance',
        coordinateSpaceRequirement='common world space for positions and all three corner frame attributes',
        gpuArithmeticVerified=False, artApproved=False, deviceApproved=False,
        triangleCount=len(raw_p), positiveWorldAreaTriangles=len(selected),
        retainedAtOrBelowAreaThresholdTriangles=int((~positive).sum()),
        uncertifiedPositiveAreaTriangles=int(bad.sum()),
        invalidCornerUnitTriangles=int(bad_units.sum()),
        invalidCornerOrthogonalityTriangles=int(bad_orthogonal.sum()),
        mixedCornerHandednessTriangles=int(bad_orientation.sum()),
        uncertifiedDeterminantTriangles=int(bad_condition.sum()),
        firstUncertifiedTriangles=selected[bad][:16].tolist(),
        uncertifiedTriangles=selected[bad].tolist(),
        minimumNormalizedDeterminantLowerBound=float(normalized_bound.min()) if len(selected) else None,
        conditionUpperBound=(float((3*np.sqrt(3)/normalized_bound).max())
                             if len(selected) and np.all(normalized_bound > 0) else None),
        sampledPointCount=sampled_points, sampledFailingTriangles=int(sample_fail.sum()),
        firstSampleFailingTriangles=selected[sample_fail][:16].tolist(),
        minimumSampleAbsDeterminant=minimum_sample_determinant,
        maximumSampleCondition=maximum_sample_condition if maximum_sample_condition is None or np.isfinite(maximum_sample_condition) else None,
        inputDigests=dict(zip(('tangents', 'bitangents', 'normals', 'positions'),
                             [_digest(v) for v in values + [raw_p]])),
        tolerances=dict(worldAreaEpsilon=world_area_epsilon, maximumCondition=maximum_condition,
                        requiredNormalizedDeterminantLowerBound=float(required_det),
                        cornerUnitAbsolute=corner_unit_tolerance,
                        cornerOrthogonalityAbsolute=corner_orthogonality_tolerance,
                        roundoffProductNormMultiplier=64))


def apply_uncertified_interior_policy(frame, positions, source_normals, uv, *,
                                       maximum_triangles, source_part_ids=None):
    """Explicit bounded render-coordinate policy, requiring a fresh matched bake.

    Only triangles rejected by the conservative interior certificate are
    changed. 'Uncertified' is not a claim of an actual singularity. This policy
    never edits source arrays and does not retry until an arbitrary full-flat
    mesh happens to pass. A fresh audit must certify the resulting whole mesh.
    Caller supplies a deliberate maximum triangle count for this operation.
    """
    _require(isinstance(maximum_triangles, (int, np.integer)) and maximum_triangles >= 0,
             'invalid_policy_bound', 'A nonnegative explicit triangle bound is required')
    raw_p, raw_n, raw_uv = map(np.asarray, (positions, source_normals, uv))
    expected = frame.report.get('inputDigests', {})
    _require(all(expected.get(name) == _digest(value) for name, value in
                 (('positions', raw_p), ('normals', raw_n), ('uv', raw_uv))),
             'policy_source_mismatch', 'Policy inputs must be the exact arrays used to build this frame')
    epsilon = frame.report['tolerances']['worldAreaEpsilon']
    before = audit_frames(frame.tangents, frame.bitangents, frame.normals, raw_p,
                          world_area_epsilon=epsilon)
    _require(not any(before[key] for key in ('invalidCornerUnitTriangles',
             'invalidCornerOrthogonalityTriangles', 'mixedCornerHandednessTriangles')),
             'policy_not_interior_only', 'This policy cannot conceal invalid corner frames')
    indices = np.array(before['uncertifiedTriangles'], dtype=np.int64)
    _require(len(indices) <= maximum_triangles, 'interior_policy_bound_exceeded',
             'Uncertified triangles exceed the explicit policy bound',
             count=len(indices), maximumTriangles=int(maximum_triangles),
             firstTriangles=indices[:16].tolist())
    part_ids = None if source_part_ids is None else np.asarray(source_part_ids)
    if part_ids is not None:
        _require(part_ids.shape == (len(raw_p),) and part_ids.dtype.kind in 'iuUSf',
                 'source_part_shape', 'Expected one scalar source part identity per triangle')
        if part_ids.dtype.kind == 'f':
            _require(np.isfinite(part_ids).all() and np.all(part_ids == np.floor(part_ids)),
                     'source_part_identity', 'Numeric source part identities must be exact finite integers')
    normal_values, tangent_values, bitangent_values = [v.copy() for v in
        (frame.normals, frame.tangents, frame.bitangents)]
    handedness, groups = frame.handedness.copy(), frame.corner_group_ids.copy()
    report = copy.deepcopy(frame.report)
    records = []
    if len(indices):
        p, tex = raw_p[indices].astype(np.float64), raw_uv[indices].astype(np.float64)
        a, b = p[:, 1] - p[:, 0], p[:, 2] - p[:, 0]
        geometric = np.cross(a, b)
        area = np.linalg.norm(geometric, axis=1) * .5
        _require(np.all(area > epsilon) and frame.renderable_triangles[indices].all(),
                 'policy_area_mismatch', 'Only positive-area renderable triangles may use this policy')
        fn = _unit(geometric, 'invalid_policy_face_normal').astype(np.float32)
        unit_n = _unit(fn.astype(np.float64), 'invalid_policy_frame_normal')
        duv, dvv = tex[:, 1] - tex[:, 0], tex[:, 2] - tex[:, 0]
        det = duv[:, 0]*dvv[:, 1] - duv[:, 1]*dvv[:, 0]
        _require(np.all(det != 0), 'collapsed_positive_area_uv', 'Interior policy cannot invent UVs')
        du = (a*dvv[:, 1, None] - b*duv[:, 1, None]) / det[:, None]
        du = _unit(du, 'invalid_policy_derivative')
        ft = _unit(du - unit_n*np.einsum('ti,ti->t', unit_n, du)[:, None], 'invalid_policy_tangent')
        fw = np.sign(det)
        fb = np.cross(unit_n, ft)*fw[:, None]
        ft, fb = ft.astype(np.float32), fb.astype(np.float32)
        next_group = int(groups.max()) + 1
        for offset, ti in enumerate(indices):
            record = dict(triangle=int(ti),
                sourcePartId=None if part_ids is None else part_ids[ti].item(),
                worldArea=float(area[offset]), reason='uncertified_interior',
                actualSingularityClaimed=False, authoredNormals=raw_n[ti].tolist(),
                previousFrameNormals=normal_values[ti].tolist(),
                previousFrameTangents=tangent_values[ti].tolist(),
                previousFrameBitangents=bitangent_values[ti].tolist(),
                frameNormal=fn[offset].tolist(), frameTangent=ft[offset].tolist(),
                frameBitangent=fb[offset].tolist(), handedness=float(fw[offset]),
                isolatedFromSmoothGroups=True, originalShadingNormalRequiredForBake=True)
            records.append(record)
            normal_values[ti], tangent_values[ti], bitangent_values[ti] = fn[offset], ft[offset], fb[offset]
            handedness[ti] = fw[offset]
            groups[ti] = np.arange(next_group + offset*3, next_group + offset*3 + 3)
    report['interiorRenderFramePolicy'] = dict(policy='constant geometric frame on uncertified interiors',
        maximumTriangles=int(maximum_triangles), triangleCount=len(indices), triangles=records,
        inputPreflight=before, originalShadingNormalRequiredForBake=True)
    report['seamGroups'] = len(np.unique(groups[groups >= 0]))
    if len(indices):
        report['validAuthoredNormalsUnchanged'] = False
    result = StableFrame(normal_values, tangent_values, bitangent_values, handedness, groups,
                         frame.renderable_triangles.copy(), report)
    after = audit_frames(result.tangents, result.bitangents, result.normals, raw_p,
                         world_area_epsilon=epsilon)
    report['interiorRenderFramePolicy']['outputPreflight'] = after
    _require(after['passed'], 'interior_policy_still_uncertified',
             'Bounded policy failed fresh whole-interior verification', audit=after)
    return result


def serialize_degenerate_frames(frame):
    """Assign legal finite glTF values only on retained nonrenderable corners.

    This is a serialization convention, not a measured source or render basis.
    The renderable mask remains false and sampling these triangles still fails.
    No positions, indices, source normals, native files, or triangle counts are
    edited. Caller must preserve corner splits from incident visible surfaces.
    """
    excluded = ~frame.renderable_triangles
    n, t, b = [v.copy() for v in (frame.normals, frame.tangents, frame.bitangents)]
    w = frame.handedness.copy()
    n[excluded], t[excluded], b[excluded], w[excluded] = [0,0,1], [1,0,0], [0,1,0], 1
    report = copy.deepcopy(frame.report)
    report['degenerateSerializationConvention'] = dict(
        triangleCount=int(excluded.sum()), cornerCount=int(excluded.sum())*3,
        triangleIndices=np.flatnonzero(excluded).tolist(), normal=[0,0,1], tangent=[1,0,0],
        bitangent=[0,1,0], handedness=1, serializationOnly=True,
        sourceFrameObserved=False, sourceGeometryChanged=False, renderableMaskChanged=False)
    if excluded.any():
        report['validAuthoredNormalsUnchanged'] = False
    return StableFrame(n,t,b,w,frame.corner_group_ids.copy(),frame.renderable_triangles.copy(),report)
