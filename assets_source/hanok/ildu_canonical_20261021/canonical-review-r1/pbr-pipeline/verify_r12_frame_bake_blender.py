"""Isolated, opt-in Blender fixture for a freshly paired explicit-frame bake.

Run with Blender --background --factory-startup --python THIS_FILE -- --out NEW.json.
This creates disposable geometry only. It never opens/saves a native asset and
never imports the production exporter. A successful fixture is numerical shader
evidence, not native-asset, visual, device, or production approval.
"""
import argparse
from dataclasses import replace
import hashlib
import json
from pathlib import Path
import sys
import traceback

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from r12_frame_nodes import FRAME_ATTRIBUTES, frame_emission_override, read_frame_attributes
from r12_stable_frame import audit_frames, build_stable_frame, interpolated_tbn


SIZE = 128
FLOAT_ANGLE_LIMIT_DEG = .05
FLOAT_RGB_LIMIT = 3e-4
PNG_ANGLE_LIMIT_DEG = 1.
PNG_RGB_LIMIT = 1. / 255. + FLOAT_RGB_LIMIT


def unit(values):
    values = np.asarray(values, dtype=np.float64)
    lengths = np.linalg.norm(values, axis=-1, keepdims=True)
    if not np.isfinite(lengths).all() or (lengths == 0).any():
        raise ValueError('Undefined source direction in fixture')
    return values / lengths


def digest(values):
    values = np.ascontiguousarray(values)
    return hashlib.sha256(str((values.dtype.str, values.shape)).encode() + values.tobytes()).hexdigest()


def angles(a, b):
    # atan2 retains useful precision for very small reconstruction errors.
    a, b = unit(a), unit(b)
    return np.rad2deg(np.arctan2(np.linalg.norm(np.cross(a, b), axis=-1),
                               np.einsum('...i,...i->...', a, b)))


def fixture_arrays():
    positions = np.array([[[-.4, -.3, 0.], [.6, -.3, 0.], [-.4, .7, 0.]]], dtype=np.float32)
    normals = unit([[[.5, -.25, 1.], [-.65, .5, 1.], [.2, .8, 1.]]]).astype(np.float32)
    uv = np.array([[[.08, .08], [.92, .08], [.08, .92]]], dtype=np.float32)
    source = unit([[[.15, -.35, 1.], [-.4, .25, 1.], [.55, .05, 1.]]]).astype(np.float32)
    return positions, normals, uv, source


def interior_samples(uv, size=SIZE):
    """Pixel-center samples away from edges; no margin/filter ownership ambiguity."""
    y, x = np.indices((size, size))
    centers = np.stack(((x + .5) / size, (y + .5) / size), axis=-1).reshape(-1, 2)
    tri = np.asarray(uv[0], dtype=np.float64)
    ab = np.linalg.solve(np.stack((tri[1] - tri[0], tri[2] - tri[0]), axis=1),
                         (centers - tri[0]).T).T
    bary = np.column_stack((1. - ab.sum(axis=1), ab))
    selected = (bary >= .12).all(axis=1)
    if selected.sum() < 1000:
        raise AssertionError('Fixture has insufficient strict-interior samples')
    return np.flatnonzero(selected), bary[selected]


def mesh_arrays(mesh):
    positions = np.empty((len(mesh.vertices), 3), dtype=np.float32)
    mesh.vertices.foreach_get('co', positions.ravel())
    normals = np.empty((len(mesh.loops), 3), dtype=np.float32)
    mesh.corner_normals.foreach_get('vector', normals.ravel())
    loop_vertices = np.empty(len(mesh.loops), dtype=np.int32)
    mesh.loops.foreach_get('vertex_index', loop_vertices)
    uv = np.empty((len(mesh.loops), 2), dtype=np.float32)
    mesh.uv_layers.active.data.foreach_get('uv', uv.ravel())
    mesh.calc_loop_triangles()
    triangles = np.array([tuple(t.vertices) for t in mesh.loop_triangles], dtype=np.int32)
    loops = np.array([tuple(t.loops) for t in mesh.loop_triangles], dtype=np.int32)
    return dict(positions=positions, normals=normals, loopVertices=loop_vertices,
                triangles=triangles, triangleLoops=loops, uv=uv)


def geometry_hashes(mesh):
    return {name: digest(values) for name, values in mesh_arrays(mesh).items()}


def graph_state(material):
    tree = material.node_tree
    return dict(nodes=sorted((node.name, node.bl_idname, node.select) for node in tree.nodes),
                links=sorted((link.from_node.name, link.from_socket.identifier,
                              link.to_node.name, link.to_socket.identifier) for link in tree.links),
                active=tree.nodes.active.name if tree.nodes.active else None)


def put_attribute(mesh, name, values):
    attr = mesh.attributes.new(name, 'FLOAT_VECTOR', 'CORNER')
    attr.data.foreach_set('vector', np.asarray(values, dtype=np.float32).ravel())
    return attr


def world_triangle_positions(obj):
    arrays = mesh_arrays(obj.data)
    matrix = np.array(obj.matrix_world, dtype=np.float64)
    positions = arrays['positions'].astype(np.float64) @ matrix[:3, :3].T + matrix[:3, 3]
    return positions[arrays['triangles']]


def live_preflight(obj):
    def check(mesh, attributes):
        if mesh != obj.data:
            raise ValueError('Preflight object/mesh mismatch')
        loops = mesh_arrays(mesh)['triangleLoops']
        return audit_frames(*(attributes[name][loops] for name in FRAME_ATTRIBUTES),
                            world_triangle_positions(obj))
    return check


def read_pixels(image):
    pixels = np.empty(SIZE * SIZE * 4, dtype=np.float32)
    image.pixels.foreach_get(pixels)
    return pixels.reshape(-1, 4)


def evaluate_pixels(pixels, indices, bary, frame, source_corners, *, linked):
    basis = interpolated_tbn(frame, np.zeros(len(bary), dtype=np.int64), bary)
    source = unit(np.einsum('mc,ci->mi', bary, source_corners[0].astype(np.float64)))
    encoded = unit(np.linalg.solve(basis, source[..., None])[..., 0])
    expected_rgb = encoded * .5 + .5
    actual = np.asarray(pixels[indices, :3], dtype=np.float64)
    if not np.isfinite(actual).all():
        raise AssertionError('Actual baked readback contains nonfinite samples')
    reconstructed = unit(np.einsum('mij,mj->mi', basis, actual * 2. - 1.))
    errors = angles(reconstructed, source)
    rgb_error = np.abs(actual - expected_rgb)
    # These counterfactuals prove the varying fixture can detect wrong semantics.
    transpose_local = unit(np.einsum('mji,mj->mi', basis, source))
    transpose_world = unit(np.einsum('mij,mj->mi', basis, transpose_local))
    transpose_error = angles(transpose_world, source)
    wrong_source_error = angles(basis[:, :, 2], source)
    variation = angles(source, np.repeat(source[:1], len(source), axis=0))
    if linked and (transpose_error.max() < .3 or wrong_source_error.max() < 10. or variation.max() < 10.):
        raise AssertionError('Fixture no longer distinguishes inverse/source-normal semantics')
    return dict(sampleCount=len(indices), maximumAngularErrorDegrees=float(errors.max()),
                rmsAngularErrorDegrees=float(np.sqrt(np.mean(errors ** 2))),
                maximumRgbError=float(rgb_error.max()),
                expectedMinimumEncodedBlue=float(expected_rgb[:, 2].min()),
                actualMinimumEncodedBlue=float(actual[:, 2].min()),
                inverseVersusTransposeControlMaximumDegrees=float(transpose_error.max()),
                sourceVersusFrameNControlMaximumDegrees=float(wrong_source_error.max()),
                sourceVariationMaximumDegrees=float(variation.max()),
                sampledFrameMaximumCondition=float(np.linalg.cond(basis).max()),
                actualSampleRgbSha256=digest(np.asarray(pixels[indices, :3])))


def require_pixels(report, *, png):
    angle_limit = PNG_ANGLE_LIMIT_DEG if png else FLOAT_ANGLE_LIMIT_DEG
    rgb_limit = PNG_RGB_LIMIT if png else FLOAT_RGB_LIMIT
    report.update(angleLimitDegrees=angle_limit, rgbLimit=rgb_limit,
                  passed=report['maximumAngularErrorDegrees'] <= angle_limit and
                         report['maximumRgbError'] <= rgb_limit)
    if not report['passed']:
        raise AssertionError('Actual bake readback failed fixed reconstruction limits: ' + json.dumps(report))


def run_case(bpy, scene, name, out, *, linked, rotated, mirrored=False):
    from mathutils import Euler, Matrix
    positions, requested_normals, uv, source_local = fixture_arrays()
    if mirrored:
        uv[:, :, 0] = 1. - uv[:, :, 0]
    if not linked:
        requested_normals[:] = (0., 0., 1.)
    mesh = bpy.data.meshes.new('R12_FrameFixture_' + name)
    mesh.from_pydata(positions.reshape(-1, 3).tolist(), [], [(0, 1, 2)])
    mesh.update()
    mesh.polygons[0].use_smooth = True
    mesh.normals_split_custom_set(requested_normals.reshape(-1, 3).tolist())
    mesh.uv_layers.new(name='FixtureUV')
    mesh.uv_layers.active.data.foreach_set('uv', uv.ravel())
    obj = bpy.data.objects.new(mesh.name, mesh)
    scene.collection.objects.link(obj)
    if rotated:
        obj.matrix_world = Matrix.Translation((2., -3., 1.)) @ Euler((.37, -.52, .29), 'XYZ').to_matrix().to_4x4()
    matrix = np.array(obj.matrix_world, dtype=np.float64)
    captured = mesh_arrays(mesh)
    # Use the exact stored normal after Blender's custom-normal representation.
    local_normals = captured['normals'][captured['triangleLoops']]
    normal_matrix = np.linalg.inv(matrix[:3, :3]).T
    frame_normals = unit(local_normals.astype(np.float64) @ normal_matrix.T).astype(np.float32)
    source_world = unit(source_local.astype(np.float64) @ normal_matrix.T).astype(np.float32) if linked else frame_normals.copy()
    frame = build_stable_frame(world_triangle_positions(obj), frame_normals, uv)
    for attr_name, values in zip(FRAME_ATTRIBUTES, (frame.tangents, frame.bitangents, frame.normals)):
        put_attribute(mesh, attr_name, values)
    if linked:
        put_attribute(mesh, 'R12_FixtureOriginalWorldNormal', source_world)
    material = bpy.data.materials.new(mesh.name + '_Material')
    material.use_nodes = True
    mesh.materials.append(material)
    tree = material.node_tree
    principled = next(node for node in tree.nodes if node.type == 'BSDF_PRINCIPLED')
    if linked:
        original = tree.nodes.new('ShaderNodeAttribute')
        original.attribute_name = 'R12_FixtureOriginalWorldNormal'
        original.attribute_type = 'GEOMETRY'
        normalizer = tree.nodes.new('ShaderNodeVectorMath')
        normalizer.operation = 'NORMALIZE'
        tree.links.new(original.outputs['Vector'], normalizer.inputs[0])
        tree.links.new(normalizer.outputs['Vector'], principled.inputs['Normal'])
    image = bpy.data.images.new(mesh.name + '_FreshNormal', width=SIZE, height=SIZE, alpha=True, float_buffer=True)
    image.colorspace_settings.name = 'Non-Color'
    image.generated_color = (0., 0., 0., 0.)
    target = tree.nodes.new('ShaderNodeTexImage')
    target.image = image
    for node in tree.nodes:
        node.select = False
    target.select = True
    tree.nodes.active = target
    before_geometry, before_graph = geometry_hashes(mesh), graph_state(material)
    for other in scene.objects:
        other.select_set(False)
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    with frame_emission_override(material, mesh, preflight=live_preflight(obj), world_matrix=obj.matrix_world) as graph_proof:
        expected_kind = 'original_linked_principled_normal' if linked else 'original_geometry_normal'
        if graph_proof['sourceNormalKind'] != expected_kind:
            raise AssertionError('Original source normal route changed')
        tree.nodes.active = target
        target.select = True
        bpy.ops.object.bake(type='EMIT', use_clear=True, margin=0, use_selected_to_active=False)
        image.update()
        pixels = read_pixels(image)
    if graph_state(material) != before_graph or geometry_hashes(mesh) != before_geometry:
        raise AssertionError('Disposable source geometry/material graph changed during bake')
    actual_attrs = read_frame_attributes(mesh)
    frame = replace(frame, tangents=actual_attrs[FRAME_ATTRIBUTES[0]].reshape(-1, 3, 3),
                    bitangents=actual_attrs[FRAME_ATTRIBUTES[1]].reshape(-1, 3, 3),
                    normals=actual_attrs[FRAME_ATTRIBUTES[2]].reshape(-1, 3, 3))
    indices, bary = interior_samples(uv)
    float_report = evaluate_pixels(pixels, indices, bary, frame, source_world, linked=linked)
    require_pixels(float_report, png=False)
    png = out.with_name(out.stem + '-' + name + '.png')
    if png.exists():
        raise FileExistsError(png)
    image.filepath_raw = str(png)
    image.file_format = 'PNG'
    image.save()
    reloaded = bpy.data.images.load(str(png), check_existing=False)
    try:
        reloaded.colorspace_settings.name = 'Non-Color'
        png_report = evaluate_pixels(read_pixels(reloaded), indices, bary, frame, source_world, linked=linked)
        require_pixels(png_report, png=True)
    finally:
        bpy.data.images.remove(reloaded)
    payload = png.read_bytes()
    # Blender writes float-buffer PNGs at 16 bits regardless of the scene's
    # requested 8-bit setting. Test actual 8-bit storage as a separate artifact.
    png8 = out.with_name(out.stem + '-' + name + '-8bit.png')
    if png8.exists():
        raise FileExistsError(png8)
    byte_image = bpy.data.images.new(mesh.name + '_FreshNormal8', width=SIZE, height=SIZE, alpha=True, float_buffer=False)
    byte_image.colorspace_settings.name = 'Non-Color'
    byte_image.pixels.foreach_set(pixels.ravel())
    byte_image.update()
    byte_image.filepath_raw = str(png8)
    byte_image.file_format = 'PNG'
    byte_image.save()
    payload8 = png8.read_bytes()
    if payload8[24] != 8:
        raise AssertionError('Explicit byte-buffer image did not serialize as an 8-bit PNG')
    reloaded8 = bpy.data.images.load(str(png8), check_existing=False)
    try:
        reloaded8.colorspace_settings.name = 'Non-Color'
        png8_report = evaluate_pixels(read_pixels(reloaded8), indices, bary, frame, source_world, linked=linked)
        require_pixels(png8_report, png=True)
    finally:
        bpy.data.images.remove(reloaded8)
    gltf_uv = captured['uv'].copy()
    gltf_uv[:, 1] = np.float32(1.) - gltf_uv[:, 1]
    return dict(name=name, passed=True, linkedOriginalNormal=linked, matrixWorld=matrix.tolist(),
                sourceNormalCornerSha256=digest(source_world),
                frameGeneration=frame.report, graph=graph_proof,
                geometryBefore=before_geometry, geometryAfter=geometry_hashes(mesh),
                sourceGeometryUnchanged=True, materialGraphRestored=True,
                sourceNormalUndefined=False, floatImage=float_report, savedPng=png_report,
                savedPng8bit=png8_report,
                image=dict(path=str(png), sha256=hashlib.sha256(payload).hexdigest(),
                           bytes=len(payload), pngBitDepth=payload[24], colorSpace='Non-Color'),
                image8bit=dict(path=str(png8), sha256=hashlib.sha256(payload8).hexdigest(),
                               bytes=len(payload8), pngBitDepth=payload8[24], colorSpace='Non-Color'),
                fixtureData=dict(schemaVersion=1, coordinatePrecision='exact Float32 values serialized as JSON numbers',
                    positionsLocal=captured['positions'].tolist(), triangleIndices=captured['triangles'].tolist(),
                    triangleLoops=captured['triangleLoops'].tolist(), cornerNormalsLocal=captured['normals'].tolist(),
                    atlasUvBlender=captured['uv'].tolist(), atlasUvGltf=gltf_uv.tolist(),
                    frameTangentsWorld=frame.tangents.tolist(), frameBitangentsWorld=frame.bitangents.tolist(),
                    frameNormalsWorld=frame.normals.tolist(), frameHandedness=frame.handedness.tolist(),
                    sourceNormalsWorld=source_world.tolist(), imageWidth=SIZE, imageHeight=SIZE,
                    pixelReadbackOrigin='Blender image.pixels row0 is UV v=0 (bottom)',
                    pngTextureConvention='glTF TEXCOORD_0 v=float32(1-BlenderUV.v), GLTFLoader texture.flipY=false',
                    sourceNormalInterpolation='normalize(sum(barycentric * sourceNormalsWorld))',
                    frameInterpolation='normalize each interpolated T/B/N independently; no re-orthogonalization'),
                blenderCustomNormalMaximumDifference=float(np.abs(local_normals-requested_normals).max()))


def singular_rejection(bpy, scene):
    """Every corner is valid; the interpolated frame cancels on an edge."""
    positions, normals, uv, _ = fixture_arrays()
    mesh = bpy.data.meshes.new('R12_FrameFixture_Singular')
    mesh.from_pydata(positions.reshape(-1, 3).tolist(), [], [(0, 1, 2)])
    mesh.update()
    mesh.uv_layers.new(name='FixtureUV')
    mesh.uv_layers.active.data.foreach_set('uv', uv.ravel())
    obj = bpy.data.objects.new(mesh.name, mesh)
    scene.collection.objects.link(obj)
    t = np.array([[1., 0., 0.], [-1., 0., 0.], [1., 0., 0.]], dtype=np.float32)
    b = np.array([[0., 1., 0.], [0., -1., 0.], [0., 1., 0.]], dtype=np.float32)
    n = np.array([[0., 0., 1.]] * 3, dtype=np.float32)
    for name, values in zip(FRAME_ATTRIBUTES, (t, b, n)):
        put_attribute(mesh, name, values)
    material = bpy.data.materials.new(mesh.name + '_Material')
    material.use_nodes = True
    mesh.materials.append(material)
    before, geo_before = graph_state(material), geometry_hashes(mesh)
    entered = False
    try:
        with frame_emission_override(material, mesh, preflight=live_preflight(obj), world_matrix=obj.matrix_world):
            entered = True
    except ValueError as exc:
        reason = str(exc)
    else:
        raise AssertionError('Singular interpolation was accepted')
    if entered or before != graph_state(material) or geo_before != geometry_hashes(mesh):
        raise AssertionError('Singular preflight changed graph or geometry before rejection')
    return dict(passed=True, rejectedBeforeGraphInstallation=True, bakeAttempted=False,
                eachCornerFrameValid=True, cancellationAtBarycentrics=[.5, .5, 0.], reason=reason)


def main():
    import bpy
    args_after = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args(args_after)
    out = args.out.resolve()
    if out.exists():
        raise FileExistsError(out)
    out.parent.mkdir(parents=True, exist_ok=True)
    case_names = ('linked-identity', 'linked-rotated', 'geometry-rotated', 'linked-negative-handedness')
    for name in case_names:
        for suffix in ('', '-8bit'):
            if out.with_name(out.stem + '-' + name + suffix + '.png').exists():
                raise FileExistsError('Refusing to overwrite fixture PNG for ' + name + suffix)
    old_scene = bpy.context.window.scene
    # Cleanup only data blocks created during this fixture; never native data.
    collections = ('objects', 'meshes', 'materials', 'images', 'scenes')
    prior = {key: {block.as_pointer() for block in getattr(bpy.data, key)} for key in collections}
    result = dict(schemaVersion=1, experimental=True, passed=False, visualApproval=False,
                  deviceApproved=False, runtimePromoted=False, nativeWritten=False,
                  productionExporterImported=False, requiresMatchedFreshBake=True,
                  blenderVersion=bpy.app.version_string, fixtureSha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                  helperSha256=hashlib.sha256(Path(__file__).with_name('r12_frame_nodes.py').read_bytes()).hexdigest(),
                  kernelSha256=hashlib.sha256(Path(__file__).with_name('r12_stable_frame.py').read_bytes()).hexdigest(),
                  sampling=dict(size=SIZE, cyclesSamples=1, samplePosition='first-sample pixel center',
                                strictInteriorMinimumBarycentric=.12, bakeMargin=0,
                                textureFilterAndMipQualityEvaluated=False), cases=[])
    failure = None
    try:
        scene = bpy.data.scenes.new('R12_FrameBakeFixture')
        bpy.context.window.scene = scene
        scene.render.engine = 'CYCLES'
        scene.cycles.device = 'CPU'
        scene.cycles.samples = 1
        scene.cycles.use_denoising = False
        scene.render.bake.margin = 0
        scene.render.bake.use_selected_to_active = False
        scene.render.image_settings.file_format = 'PNG'
        scene.render.image_settings.color_mode = 'RGBA'
        scene.render.image_settings.color_depth = '8'
        scene.view_settings.view_transform = 'Standard'
        result['singularFrame'] = singular_rejection(bpy, scene)
        for name, linked, rotated, mirrored in (('linked-identity', True, False, False),
                                               ('linked-rotated', True, True, False),
                                               ('geometry-rotated', False, True, False),
                                               ('linked-negative-handedness', True, False, True)):
            result['cases'].append(run_case(bpy, scene, name, out, linked=linked, rotated=rotated, mirrored=mirrored))
        result['passed'] = True
    except Exception as exc:
        failure = exc
        result['failure'] = dict(type=type(exc).__name__, message=str(exc), traceback=traceback.format_exc())
    finally:
        bpy.context.window.scene = old_scene
        for key in collections:
            blocks = getattr(bpy.data, key)
            for block in list(blocks):
                if block.as_pointer() not in prior[key]:
                    blocks.remove(block, do_unlink=True)
        out.write_text(json.dumps(result, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    print(json.dumps(dict(passed=result['passed'], report=str(out), cases=len(result['cases']))))
    if failure:
        raise failure


if __name__ == '__main__':
    main()
