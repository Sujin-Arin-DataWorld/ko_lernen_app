"""Actual-surface R12 atlas baking, adapted from the preserved P17 exporter.

Donor SHA256: 15d9198286d7e349cb73f904c55d09244a1b825c74a7234df38f9d693bcec627.
The runner records the exact donor and current helper hashes separately.

Only detached copies are evaluated, packed, baked, and exported. Original scene
geometry, UVs, attributes, materials, transforms, and hierarchy are untouched.
Door/window leaves remain separate functional objects after the shared bake.
No temporary plane, camera render, native save, Draco, or meshopt is used.
"""
import hashlib
import json
import math
import re
import struct
from array import array
from contextlib import ExitStack
from pathlib import Path

import numpy as np

PREFIX = 'P17Delivery.'
ATLAS_UV = 'P17 baked surface atlas'
TANGENT_UV = 'P17 retained normal tangent UV'
GENERATED = 'P17 retained generated position'
OBJECT = 'P17 retained object position'
NORMAL = 'P17 retained object normal'
SOURCE_ID = '_P17_SOURCE_OBJECT_ID'
OBJECT_RANDOM = 'R12 retained Cycles object random'
ATTR_TYPES = {'FLOAT': ('value', 1), 'INT': ('value', 1), 'BOOLEAN': ('value', 1),
              'FLOAT_VECTOR': ('vector', 3), 'FLOAT_COLOR': ('color', 4), 'BYTE_COLOR': ('color', 4)}


def _sha(data):
    return hashlib.sha256(data).hexdigest()


def _jsonable(value):
    if isinstance(value, (str, int, float, bool)) or value is None:
        return value
    if hasattr(value, 'items'):
        return {str(k): _jsonable(v) for k, v in value.items()}
    try:
        return [_jsonable(v) for v in value]
    except TypeError:
        return str(value)


def _props(ob):
    return {k: _jsonable(ob[k]) for k in ob.keys() if k != '_RNA_UI'}


def _owner(ob):
    if ob.get('construction_building'):
        return str(ob['construction_building'])
    n = ob.name.lower()
    if any(word in n for word in ('sarang', 'numaru', 'hwalju', 'continuity.')):
        return 'sarang'
    if n.startswith(('junction.', 'landing.', 'space.', 'floorrepair.landing.', 'support.', 'correction.', 'v25.')):
        return 'sarang'
    if 'jung' in n:
        return 'jung'
    return 'unassigned'


def _digest(ob):
    h = hashlib.sha256()
    h.update(json.dumps([list(r) for r in ob.matrix_world]).encode())
    h.update(json.dumps(_props(ob), sort_keys=True).encode())
    h.update(str((ob.parent.name if ob.parent else None, ob.hide_render, ob.data.as_pointer())).encode())
    mesh = ob.data
    for collection, prop, width, code in [(mesh.vertices, 'co', 3, 'f'), (mesh.loops, 'vertex_index', 1, 'i'),
                                          (mesh.polygons, 'loop_start', 1, 'i'), (mesh.polygons, 'loop_total', 1, 'i'),
                                          (mesh.polygons, 'material_index', 1, 'i')]:
        values = array(code, [0]) * (len(collection)*width)
        collection.foreach_get(prop, values)
        h.update(values.tobytes())
    for uv in mesh.uv_layers:
        values = array('f', [0])*(len(uv.data)*2)
        uv.data.foreach_get('uv', values)
        h.update(uv.name.encode()); h.update(values.tobytes())
    for attr in mesh.attributes:
        if attr.name.startswith('.') or attr.data_type not in ATTR_TYPES:
            continue
        prop, width = ATTR_TYPES[attr.data_type]
        values = array('i' if attr.data_type in ('INT','BOOLEAN') else 'f', [0])*(len(attr.data)*width)
        attr.data.foreach_get(prop, values)
        h.update(str((attr.name, attr.domain, attr.data_type)).encode()); h.update(values.tobytes())
    h.update(str([(m.name, m.as_pointer()) if m else None for m in mesh.materials]).encode())
    return h.hexdigest()


def _attr(mesh, name, values, domain='POINT', kind='FLOAT_VECTOR'):
    attr = mesh.attributes.get(name) or mesh.attributes.new(name, kind, domain)
    if attr.domain != domain or attr.data_type != kind:
        raise ValueError(('Attribute collision', name, attr.domain, attr.data_type))
    attr.data.foreach_set(ATTR_TYPES[kind][0], np.asarray(values).ravel())
    return attr


def _uv_key(name):
    return 'P17 retained UV '+hashlib.sha256(name.encode()).hexdigest()[:12]


def _principled(mat):
    if not mat or not mat.use_nodes:
        raise ValueError(('Source must have actual node material', mat.name if mat else None))
    return next(node for node in mat.node_tree.nodes if node.type == 'BSDF_PRINCIPLED')


def _connected_outputs(mat):
    """Trace only socket dependencies of the surface that is actually baked.

    Group interfaces are followed through their used output/input sockets,
    so disconnected legacy texture and normal nodes do not require a UV.
    """
    roots = _principled(mat)
    todo = [(link.from_socket, ()) for socket in roots.inputs for link in socket.links]
    seen, result = set(), []
    def matching(sockets, reference):
        identifier = reference.identifier
        return next((s for s in sockets if s.identifier == identifier),
                    next((s for s in sockets if s.name == reference.name), None))
    while todo:
        socket, context = todo.pop()
        node = socket.node
        key = (node.as_pointer(), socket.identifier, tuple(n.as_pointer() for n in context))
        if key in seen:
            continue
        seen.add(key); result.append((node, socket))
        if node.type == 'GROUP' and node.node_tree:
            outputs = [n for n in node.node_tree.nodes if n.type == 'GROUP_OUTPUT']
            output = next((n for n in outputs if n.is_active_output), outputs[0] if outputs else None)
            inside = matching(output.inputs, socket) if output else None
            if inside:
                todo.extend((link.from_socket, context+(node,)) for link in inside.links)
        elif node.type == 'GROUP_INPUT' and context:
            outside = matching(context[-1].inputs, socket)
            if outside:
                todo.extend((link.from_socket, context[:-1]) for link in outside.links)
        else:
            todo.extend((link.from_socket, context) for input_socket in node.inputs for link in input_socket.links)
    return result


def _source_uv_dependencies(mat, active_uv):
    required = set()
    tangent = set()
    for node, socket in _connected_outputs(mat):
        if node.type == 'TEX_IMAGE' and node.image is not None and not node.inputs['Vector'].is_linked:
            required.add(active_uv)
        elif node.type == 'UVMAP':
            required.add(node.uv_map or active_uv)
        elif node.type == 'TEX_COORD' and socket.name == 'UV':
            required.add(active_uv)
        elif node.type == 'NORMAL_MAP' and node.space == 'TANGENT':
            tangent.add(node.uv_map or active_uv)
            required.add(node.uv_map or active_uv)
    return required, tangent


def _copy_material(bpy, source, active_uv, tangent_uv, owner, coordinate_warnings, missing_tangent=False):
    """Make all coordinate dependencies explicit before changing active bake UV."""
    mat = source.copy()
    mat.name = PREFIX+owner+'.source material.'+source.name
    def rewrite(nt):
        for node in list(nt.nodes):
            if node.type == 'GROUP' and node.node_tree:
                node.node_tree = node.node_tree.copy()
                node.node_tree.name = PREFIX+'retained group.'+node.node_tree.name
                rewrite(node.node_tree)
            if node.type == 'NORMAL_MAP' and node.space == 'TANGENT':
                node.uv_map = '__R12 intentionally missing native tangent__' if missing_tangent else TANGENT_UV
            if node.type == 'OBJECT_INFO' and node.outputs['Random'].is_linked:
                replacement = nt.nodes.new('ShaderNodeAttribute')
                replacement.attribute_name = OBJECT_RANDOM
                for link in list(node.outputs['Random'].links):
                    nt.links.new(replacement.outputs['Fac'], link.to_socket)
            if node.type == 'UVMAP':
                replacement = nt.nodes.new('ShaderNodeAttribute')
                replacement.attribute_name = _uv_key(node.uv_map or active_uv)
                for link in list(node.outputs['UV'].links):
                    nt.links.new(replacement.outputs['Vector'], link.to_socket)
            if node.type == 'TEX_IMAGE' and not node.inputs['Vector'].is_linked:
                explicit = nt.nodes.new('ShaderNodeAttribute')
                explicit.attribute_name = _uv_key(active_uv)
                nt.links.new(explicit.outputs['Vector'], node.inputs['Vector'])
            if node.type == 'TEX_COORD':
                fields = {'UV': _uv_key(active_uv), 'Generated': GENERATED, 'Normal': NORMAL,
                          'Object': OBJECT if node.object is None else 'P17 retained external '+_sha(node.object.name.encode())[:12]}
                for output, name in fields.items():
                    if node.outputs[output].is_linked:
                        explicit = nt.nodes.new('ShaderNodeAttribute')
                        explicit.attribute_name = name
                        for link in list(node.outputs[output].links):
                            nt.links.new(explicit.outputs['Vector'], link.to_socket)
                for output in ('Camera','Window','Reflection'):
                    if node.outputs[output].is_linked:
                        coordinate_warnings.append(source.name+': view-dependent '+output+' coordinate requires visual review')
    rewrite(mat.node_tree)
    return mat


def _node_trees(mat):
    todo, visited = [mat.node_tree], set()
    while todo:
        nt = todo.pop()
        if not nt or nt.as_pointer() in visited:
            continue
        visited.add(nt.as_pointer())
        yield nt
        todo.extend(n.node_tree for n in nt.nodes if n.type == 'GROUP' and n.node_tree)


def _glb_read(path):
    blob = Path(path).read_bytes()
    magic, version, length = struct.unpack_from('<III', blob)
    assert (magic, version, length) == (0x46546c67, 2, len(blob))
    chunks, offset = [], 12
    while offset < len(blob):
        size, kind = struct.unpack_from('<II', blob, offset)
        chunks.append((kind, blob[offset+8:offset+8+size])); offset += 8+size
    doc = json.loads(next(data for kind,data in chunks if kind == 0x4e4f534a))
    payload = next(data for kind,data in chunks if kind == 0x004e4942)
    return blob, doc, payload


def _glb_write(path, doc, payload):
    header = json.dumps(doc, separators=(',',':'), ensure_ascii=False).encode()
    header += b' '*((-len(header))%4)
    payload += b'\0'*((-len(payload))%4)
    blob = struct.pack('<III',0x46546c67,2,28+len(header)+len(payload))
    blob += struct.pack('<II',len(header),0x4e4f534a)+header
    blob += struct.pack('<II',len(payload),0x004e4942)+payload
    Path(path).write_bytes(blob)


def _accessor(doc, payload, index):
    a = doc['accessors'][index]; v = doc['bufferViews'][a['bufferView']]
    dtype = {5120:'i1',5121:'u1',5122:'<i2',5123:'<u2',5125:'<u4',5126:'<f4'}[a['componentType']]
    width = {'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']]
    offset = v.get('byteOffset',0)+a.get('byteOffset',0)
    stride = v.get('byteStride',np.dtype(dtype).itemsize*width)
    return np.ndarray((a['count'],width), dtype=dtype, buffer=payload, offset=offset,
                      strides=(stride,np.dtype(dtype).itemsize)).copy()


def _exact_corner_normals(mesh, normals):
    """Blender 5.2 float-vector normals avoid legacy short2 fan re-encoding.

    The official mesh_normals.cc reads CORNER/FLOAT_VECTOR custom_normal
    directly. Preserve these values through tessellation, including sharp faces.
    """
    values=np.asarray(normals,dtype=np.float32).reshape(-1,3)
    assert len(values)==len(mesh.loops) and np.isfinite(values).all()
    previous=mesh.attributes.get('custom_normal')
    if previous is not None:
        mesh.attributes.remove(previous)
    _attr(mesh,'custom_normal',values,domain='CORNER',kind='FLOAT_VECTOR')
    actual=np.array([tuple(n.vector) for n in mesh.corner_normals],dtype=np.float32)
    assert np.array_equal(actual,values), 'Explicit float corner normals were not preserved'


def _triangulate_bake_copy(bpy, source, records, source_triangles=None):
    """Use the exact same evaluated triangles for atlas bake and GLB output.

    Polygon-level UV charts can conceal a collapsed subtriangle of a near-zero
    ridge face. Only this detached bake mesh is tessellated; native vertices,
    triangle positions, shader coordinate values and normals remain unchanged.
    """
    source.calc_loop_triangles()
    triangles = source_triangles if source_triangles is not None else [
        (tuple(tri.vertices),tuple(tri.loops),tri.polygon_index) for tri in source.loop_triangles]
    coverage=np.zeros(len(source.polygons),dtype=np.int64)
    for vertices,loops,face in triangles:
        assert isinstance(face,(int,np.integer)) and 0<=face<len(source.polygons), 'Invalid triangle face'
        assert len(vertices)==len(loops)==3, 'Triangle triplets required'
        polygon=source.polygons[face]
        for vertex,loop in zip(vertices,loops):
            assert isinstance(vertex,(int,np.integer)) and 0<=vertex<len(source.vertices), 'Invalid triangle vertex'
            assert isinstance(loop,(int,np.integer)) and polygon.loop_start<=loop<polygon.loop_start+polygon.loop_total, 'Invalid triangle loop'
            assert source.loops[loop].vertex_index==vertex, 'Triangle vertex/loop mismatch'
        coverage[face]+=1
    assert np.array_equal(coverage,[max(0,p.loop_total-2) for p in source.polygons]), 'Incomplete native tessellation'
    loop_ids = np.array([li for _,loops,_ in triangles for li in loops],dtype=np.int32)
    face_ids = np.array([face for _,_,face in triangles],dtype=np.int32)
    assert np.all(np.diff(face_ids)>=0), 'Native tessellation order is not polygon-contiguous'
    coords = np.empty((len(source.vertices),3),dtype=np.float32)
    source.vertices.foreach_get('co',coords.ravel())
    faces = [vertices for vertices,_,_ in triangles]
    before_positions = coords[np.array(faces,dtype=np.int32)].tobytes()
    normals = np.array([tuple(n.vector) for n in source.corner_normals],dtype=np.float32)
    result = bpy.data.meshes.new(source.name+'.exact triangles')
    result.from_pydata(coords,[],faces)
    result.update()
    for mat in source.materials:
        result.materials.append(mat)
    result.polygons.foreach_set('material_index',[source.polygons[i].material_index for i in face_ids])
    for polygon in result.polygons:
        polygon.use_smooth=True
    uv_names={uv.name for uv in source.uv_layers}
    for attr in source.attributes:
        # Blender regenerates these internal normal encodings from the explicit
        # split corner normals above; copying their packed form is invalid.
        if attr.name.startswith('.') or attr.name in ('position','material_index','custom_normal','sharp_edge') or attr.name in uv_names:
            continue
        if attr.data_type not in ATTR_TYPES or attr.domain not in ('POINT','CORNER','FACE'):
            raise ValueError('Unpreserved bake attribute '+attr.name)
        prop,width=ATTR_TYPES[attr.data_type]
        values=np.empty((len(attr.data),width),dtype=np.int32 if attr.data_type in ('INT','BOOLEAN') else np.float32)
        attr.data.foreach_get(prop,values.ravel())
        selected=values if attr.domain=='POINT' else values[loop_ids if attr.domain=='CORNER' else face_ids]
        _attr(result,attr.name,selected,attr.domain,attr.data_type)
    for uv in source.uv_layers:
        values=np.empty((len(source.loops),2),dtype=np.float32)
        uv.data.foreach_get('uv',values.ravel())
        layer=result.uv_layers.new(name=uv.name)
        layer.data.foreach_set('uv',values[loop_ids].ravel())
        layer.active_render=uv.active_render
    # FACE sharpness affects Blender's custom-normal encoding basis. Set the
    # explicit normals only after all source face attributes have been copied.
    _exact_corner_normals(result,normals[loop_ids])
    for record in records:
        record['preTessellationBakeRanges']={key:record[key] for key in ('faceStart','faceEnd','loopStart','loopEnd')}
        start,end=np.searchsorted(face_ids,[record['faceStart'],record['faceEnd']])
        record.update(faceStart=int(start),faceEnd=int(end),loopStart=int(start)*3,loopEnd=int(end)*3)
    result.calc_loop_triangles()
    actual_coords=np.array([tuple(v.co) for v in result.vertices],dtype=np.float32)
    actual_faces=np.array([tuple(t.vertices) for t in result.loop_triangles],dtype=np.int32)
    assert before_positions==actual_coords[actual_faces].tobytes(), 'Bake tessellation changed source triangles'
    actual_normals=np.array([tuple(n.vector) for n in result.corner_normals])
    normal_deltas=np.max(np.abs(actual_normals-normals[loop_ids]),axis=1)
    normal_error=float(np.max(normal_deltas,initial=0))
    if normal_error>=1e-4:
        indices=np.flatnonzero(normal_deltas>=1e-4)
        print('R12 TESSELLATION NORMAL DIAGNOSTICS',dict(maximum=normal_error,count=len(indices),
            samples=[dict(loop=int(i), sourceFace=int(face_ids[i//3]),
                before=normals[loop_ids[i]].tolist(),after=actual_normals[i].tolist(),
                triangleArea=float(result.loop_triangles[i//3].area)) for i in indices[:12]]),flush=True)
    assert normal_error<1e-4, 'Bake tessellation changed explicit source normals'
    return result,dict(exactEvaluatedTrianglePositions=True,
        trianglePositionsSha256=_sha(before_positions),sourcePolygons=len(source.polygons),
        maximumCornerNormalComponentError=normal_error,
        tessellationCapturedBeforeWorldJoin=source_triangles is not None,
        bakeTriangles=len(triangles),originalNativeChanged=False,
        purpose='Bake and export use identical triangle chart boundaries')


def _bake_geometry_digest(mesh):
    """Prove edit-mode UV operators did not alter positions/topology/normals."""
    vertices=np.empty((len(mesh.vertices),3),dtype=np.float32)
    mesh.vertices.foreach_get('co',vertices.ravel())
    loops=np.empty(len(mesh.loops),dtype=np.int32)
    mesh.loops.foreach_get('vertex_index',loops)
    faces=np.array([(p.loop_start,p.loop_total) for p in mesh.polygons],dtype=np.int32)
    normals=np.array([tuple(n.vector) for n in mesh.corner_normals],dtype=np.float32)
    return _sha(vertices.tobytes()+loops.tobytes()+faces.tobytes()+normals.tobytes())


def _extract(bpy, combined, records, indices, name, matrix=None):
    """Copy exact evaluated faces and baked UVs back to functional objects."""
    vertices, faces, atlas, normals, source_ids = [], [], [], [], []
    source_loops=[]
    lookup = {}
    inv = matrix.inverted() if matrix is not None else None
    normal_matrix = matrix.transposed().to_3x3() if matrix is not None else None
    from mathutils import Vector
    # Use Blender's exact evaluated tessellation. Ngons otherwise make glTF's
    # tangent export fail, changing the response of the baked normal map.
    cache_key=(combined.as_pointer(),len(combined.polygons),len(combined.loops))
    cached=getattr(_extract,'_triangulation_cache',None)
    if cached is not None and cached[0]==cache_key:
        face_triangles=cached[1]
    else:
        combined.calc_loop_triangles()
        face_triangles = {}
        for triangle in combined.loop_triangles:
            face_triangles.setdefault(triangle.polygon_index, []).append(tuple(triangle.loops))
        _extract._triangulation_cache=(cache_key,face_triangles)
    for record in records:
        if record['partId'] not in indices:
            continue
        triangle_loops = (loops for face_index in range(record['faceStart'],record['faceEnd'])
                          for loops in face_triangles.get(face_index, []))
        for loops in triangle_loops:
            face = []
            for li in loops:
                source_loops.append(li)
                old = combined.loops[li].vertex_index
                if old not in lookup:
                    lookup[old] = len(vertices)
                    co = combined.vertices[old].co
                    vertices.append(tuple(inv@co if inv is not None else co))
                    source_ids.append(float(record['partId']))
                face.append(lookup[old])
                atlas.append(tuple(combined.uv_layers[ATLAS_UV].data[li].uv))
                n = combined.corner_normals[li].vector
                normals.append(tuple((normal_matrix@n).normalized() if normal_matrix is not None else n))
            faces.append(face)
    mesh = bpy.data.meshes.new(PREFIX+name+'.mesh')
    mesh.from_pydata(vertices, [], faces); mesh.update()
    for poly in mesh.polygons:
        poly.use_smooth = True
    _exact_corner_normals(mesh,normals)
    uv = mesh.uv_layers.new(name=ATLAS_UV)
    uv.data.foreach_set('uv',np.asarray(atlas,dtype=np.float32).ravel())
    uv.active_render = True
    _attr(mesh,SOURCE_ID,source_ids,kind='FLOAT')
    if combined.attributes.get('_R12_FRAME_N') is not None:
        from r12_paired_surface import copy_export_frame
        copy_export_frame(combined,mesh,source_loops,matrix)
    return mesh


def _capture_tangent_inputs(mesh, path, matrix=None):
    """Persist exact read-only pre-bake/export inputs for numerical diagnosis."""
    assert all(poly.loop_total == 3 for poly in mesh.polygons)
    positions=np.empty((len(mesh.vertices),3),dtype=np.float32)
    mesh.vertices.foreach_get('co',positions.ravel())
    loops=np.empty(len(mesh.loops),dtype=np.int32)
    mesh.loops.foreach_get('vertex_index',loops)
    uv=np.empty((len(mesh.loops),2),dtype=np.float32)
    mesh.uv_layers[ATLAS_UV].data.foreach_get('uv',uv.ravel())
    normals=np.array([tuple(n.vector) for n in mesh.corner_normals],dtype=np.float32)
    source_ids=np.full(len(mesh.vertices),-1,dtype=np.float32)
    source_attr=mesh.attributes.get(SOURCE_ID)
    if source_attr is not None:
        assert source_attr.domain=='POINT' and source_attr.data_type=='FLOAT'
        source_attr.data.foreach_get('value',source_ids)
    path=Path(path)
    path.parent.mkdir(parents=True,exist_ok=True)
    with path.open('xb') as stream:
        np.savez_compressed(stream,positions=positions,triangles=loops.reshape(-1,3),
            normals=normals,uv=uv,sourceIds=source_ids,
            matrixWorld=np.asarray(matrix if matrix is not None else np.eye(4),dtype=np.float64))
    return dict(file=path.name,sha256=_sha(path.read_bytes()),bytes=path.stat().st_size)


def export_review(bpy, OUT, candidate_sha, source_sha,
                  owners_selection=('sarang','anchae','garden_p17'), atlas_size=2048,
                  samples=4, object_filter=None, door_definitions=None, bake_margin=8,
                  native_path=None, capture_tangent_inputs=False,
                  paired_normal_frame=False,maximum_interior_fallbacks=64):
    """Bake/export one actual-mesh atlas per owner; return pilot manifest.

    ``owners_selection`` may be an iterable of owner tags, or a mapping from
    owner to exact source object names (useful for a bounded foreground wall).
    ``atlas_size`` may be an integer or per-owner mapping. ``object_filter`` is
    optional ``(owner, object)->bool``. Door definitions retain source prefixes,
    hinges, rotationSigns and leafGroups and are copied to each owner's sidecar.
    The caller must pass the SHA of the already saved native candidate.
    """
    from mathutils import Vector, Matrix
    out = Path(OUT); out.mkdir(parents=True,exist_ok=True)
    source_scene = bpy.context.scene
    original_scene = bpy.context.window.scene
    native = Path(native_path or bpy.data.filepath)
    if native.is_file():
        with native.open('rb') as stream:
            actual_sha = hashlib.file_digest(stream, 'sha256').hexdigest()
        if actual_sha != candidate_sha:
            raise ValueError('Loaded native candidate SHA differs from supplied candidate_sha')
    before = {o.name:_digest(o) for o in source_scene.objects if o.type == 'MESH'}
    original_ids = {kind:{x.as_pointer() for x in getattr(bpy.data,kind)}
                    for kind in ('objects','meshes','materials','images','node_groups','scenes')}
    selected = {}
    for owner in owners_selection:
        exact = set(owners_selection[owner]) if isinstance(owners_selection,dict) else None
        selected[owner] = sorted((o for o in source_scene.objects if o.type == 'MESH' and not o.hide_render
                                 and (o.name in exact if exact is not None else _owner(o)==owner)
                                 and (object_filter is None or object_filter(owner,o))),key=lambda o:o.name)
        if not selected[owner]:
            raise ValueError('No visible source meshes selected for '+owner)
    if door_definitions is None:
        candidates = [native.parent/'doors.json',
                      Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/northern-court/review3d/anchae-gye-p12-craft-details/doors.json']
        door_path = next((p for p in candidates if p.is_file()),None)
        door_definitions = json.loads(door_path.read_text(encoding='utf8')) if door_path else []
    manifest = {'version':12,'scope':'R12 exact selected-member PBR candidate','candidateSha256':candidate_sha,
                'sourceSha256':source_sha,'native':str(native),'owners':[], 'allEstateDelivered':False,
                'runtimePromoted':False,'visualApproval':False,'doors':[],'bakeSurface':'actual evaluated source mesh',
                'directLightingBaked':False,'temporaryPlaneUsed':False,'meshCompression':None}
    try:
        for owner, sources in selected.items():
            size = int(atlas_size.get(owner,2048) if isinstance(atlas_size,dict) else atlas_size)
            if size not in (256,512,1024,2048,4096):
                raise ValueError('Atlas size must be 256/512/1024/2048/4096')
            scene = bpy.data.scenes.new(PREFIX+owner+'.bake scene')
            bpy.context.window.scene = scene
            scene.render.engine = 'CYCLES'; scene.cycles.samples = samples; scene.cycles.device = 'CPU'
            scene.render.bake.margin = bake_margin
            scene.render.bake.use_selected_to_active = False
            scene.render.image_settings.file_format = 'PNG'
            copies, copied_data, records, material_cache, coord_warnings = [], [], [], {}, []
            for part_id, original in enumerate(sources):
                ob = original.copy(); ob.data = original.data.copy()
                ob.name = PREFIX+owner+'.evaluating.'+original.name
                ob.data.name = PREFIX+owner+'.raw copy.'+original.name
                scene.collection.objects.link(ob)
                ob.parent = None; ob.animation_data_clear()
                for constraint in list(ob.constraints): ob.constraints.remove(constraint)
                ob.matrix_world = original.matrix_world.copy()
                raw = ob.data
                co = np.empty(len(raw.vertices)*3,dtype=np.float32); raw.vertices.foreach_get('co',co); co=co.reshape(-1,3)
                loc=np.array(raw.texspace_location); span=np.maximum(np.array(raw.texspace_size)*2,1e-9)
                _attr(raw,GENERATED,(co-loc)/span+.5)
                copies.append((original,ob)); copied_data.append(raw)
            bpy.context.view_layer.update(); deps=bpy.context.evaluated_depsgraph_get()
            pieces=[]
            for part_id,(original,ob) in enumerate(copies):
                ev=ob.evaluated_get(deps)
                mesh=bpy.data.meshes.new_from_object(ev,preserve_all_data_layers=True,depsgraph=deps)
                mesh.name=PREFIX+owner+'.evaluated.'+original.name; copied_data.append(mesh)
                # Mesh data slots do not necessarily carry OBJECT-linked R12
                # overrides. Resolve the evaluated object's effective surface.
                if len(mesh.materials) != len(ev.material_slots):
                    raise ValueError(('Evaluated material slot count differs', original.name))
                for slot_index, effective in enumerate(ev.material_slots):
                    if mesh.materials[slot_index] != effective.material:
                        mesh.materials[slot_index] = effective.material
                active=next((uv.name for uv in original.data.uv_layers if uv.active_render),
                            original.data.uv_layers.active.name if original.data.uv_layers.active else '')
                uv_maps={}
                for uv in mesh.uv_layers:
                    vals=np.empty(len(mesh.loops)*2,dtype=np.float32); uv.data.foreach_get('uv',vals)
                    uv_maps[uv.name]=vals.reshape(-1,2)
                    _attr(mesh,_uv_key(uv.name),np.column_stack((uv_maps[uv.name],np.zeros(len(mesh.loops)))),domain='CORNER')
                if not active:
                    _attr(mesh,_uv_key(''),np.zeros((len(mesh.loops),3)),domain='CORNER')
                co=np.empty(len(mesh.vertices)*3,dtype=np.float32); mesh.vertices.foreach_get('co',co); co=co.reshape(-1,3)
                _attr(mesh,OBJECT,co)
                from cycles_object_random import object_random
                _attr(mesh, OBJECT_RANDOM,
                      np.full(len(mesh.vertices), object_random(original.name), dtype=np.float32), kind='FLOAT')
                normal_local=np.array([tuple(n.vector) for n in mesh.corner_normals],dtype=np.float32)
                _attr(mesh,NORMAL,normal_local,domain='CORNER')
                # External Object coordinates must also survive joining into estate space.
                for mat in mesh.materials:
                    if not mat or not mat.use_nodes: continue
                    for nt in _node_trees(mat):
                        for n in nt.nodes:
                            if n.type=='TEX_COORD' and n.object is not None and n.outputs['Object'].is_linked:
                                inv=n.object.matrix_world.inverted()
                                vals=[tuple(inv@(original.matrix_world@v.co)) for v in mesh.vertices]
                                _attr(mesh,'P17 retained external '+_sha(n.object.name.encode())[:12],vals)
                tangent=np.zeros((len(mesh.loops),2),dtype=np.float32)
                mats=[]
                required_source_uvs=set()
                used_material_slots={poly.material_index for poly in mesh.polygons}
                for slot,source_mat in enumerate(mesh.materials):
                    if source_mat is None:
                        if slot in used_material_slots:
                            raise ValueError(('Empty source material slot on used face',original.name,slot))
                        # Keep its index in the detached bake mesh. No source
                        # face samples this placeholder and the original empty
                        # slot remains untouched, including its source receipt.
                        key=('unused-empty-source-slot',owner)
                        if key not in material_cache:
                            placeholder=bpy.data.materials.new(PREFIX+owner+'.unused empty source slot')
                            placeholder.use_nodes=True
                            material_cache[key]=placeholder
                        mats.append(material_cache[key])
                        continue
                    _principled(source_mat)
                    # An unused legacy slot contributes no evaluated surface.
                    # Retain its detached copy and its index, but do not demand
                    # coordinates that no baked face will ever sample. Used
                    # slots still require every connected native UV unchanged.
                    required,maps=(_source_uv_dependencies(source_mat,active)
                                   if slot in used_material_slots else (set(),set()))
                    missing_uvs = required - set(uv_maps)
                    for missing_uv in missing_uvs:
                        _attr(mesh, _uv_key(missing_uv), np.zeros((len(mesh.loops),3)), domain='CORNER')
                    if missing_uvs:
                        coord_warnings.append(original.name+': native missing UV returns zero; preserved explicitly: '+repr(sorted(missing_uvs)))
                    required_source_uvs.update(required)
                    if len(maps)>1: raise ValueError('Multiple normal-map tangent UVs in one material: '+source_mat.name)
                    source_tangent=next(iter(maps),active)
                    missing_tangent = bool(source_tangent and source_tangent not in uv_maps)
                    for poly in mesh.polygons:
                        if poly.material_index==slot and source_tangent and not missing_tangent:
                            tangent[list(poly.loop_indices)]=uv_maps[source_tangent][list(poly.loop_indices)]
                    key=(source_mat.as_pointer(),active,source_tangent,missing_tangent)
                    if key not in material_cache:
                        material_cache[key]=_copy_material(bpy,source_mat,active,source_tangent,owner,coord_warnings,missing_tangent)
                    mats.append(material_cache[key])
                world=original.matrix_world.copy(); normal_matrix=world.inverted().transposed().to_3x3()
                world_co=np.array([tuple(world@Vector(v)) for v in co],dtype=np.float32)
                world_normals=np.array([tuple((normal_matrix@Vector(n)).normalized()) for n in normal_local],dtype=np.float32)
                attrs={}
                for a in mesh.attributes:
                    # Built-ins already have their explicit joined world-space
                    # coordinate/material-slot construction above. Copying them
                    # as generic attributes would silently replace that result.
                    if a.name.startswith('.') or a.name in ('position','material_index','custom_normal') or a.data_type not in ATTR_TYPES or a.domain not in ('POINT','CORNER','FACE'): continue
                    prop,width=ATTR_TYPES[a.data_type]
                    values=np.empty(len(a.data)*width,dtype=np.int32 if a.data_type in ('INT','BOOLEAN') else np.float32)
                    a.data.foreach_get(prop,values)
                    attrs[a.name]=(a.domain,a.data_type,values.reshape(-1,width))
                pieces.append({'mesh':mesh,'coords':world_co,'normals':world_normals,'attrs':attrs,'tangent':tangent,'materials':mats})
                movable=True  # retain each original member for reviewed construction-stage filtering
                records.append({'partId':part_id,'sourceObject':original.name,'sourceWorld':[list(r) for r in original.matrix_world],
                                'evaluatedWorldBounds':{'min':world_co.min(axis=0).tolist(),'max':world_co.max(axis=0).tolist()} if len(world_co) else None,
                                'evaluatedEmpty':not (len(mesh.vertices) or len(mesh.loops) or len(mesh.polygons)),
                                'evaluatedVertexCount':len(mesh.vertices),'evaluatedLoopCount':len(mesh.loops),'evaluatedFaceCount':len(mesh.polygons),
                                'sourceParent':original.parent.name if original.parent else None,'sourceProperties':_props(original),
                                'rawUvNames':[uv.name for uv in original.data.uv_layers],'evaluatedUvNames':list(uv_maps),
                                'unusedSourceMaterialSlots':[{'slot':i,'material':m.name if m else None}
                                    for i,m in enumerate(mesh.materials) if i not in used_material_slots],
                                'connectedSourceUvDependencies':sorted(required_source_uvs),
                                'sourceUvDigests':{name:_sha(vals.tobytes()) for name,vals in uv_maps.items()},
                                'movable':movable,'sourceGeometryDigest':before[original.name]})
            verts,faces,normals,tangents,material_ids,all_mats=[],[],[],[],[],[]
            native_triangles=[]
            vstart=lstart=fstart=0
            for record,piece in zip(records,pieces):
                mesh=piece['mesh']; record.update(vertexStart=vstart,vertexEnd=vstart+len(mesh.vertices),
                    loopStart=lstart,loopEnd=lstart+len(mesh.loops),faceStart=fstart,faceEnd=fstart+len(mesh.polygons))
                # Preserve evaluated object-space tessellation before any
                # world-space float32 join can choose a different ngon diagonal.
                mesh.calc_loop_triangles()
                native_triangles.extend((tuple(vstart+i for i in triangle.vertices),
                    tuple(lstart+i for i in triangle.loops),fstart+triangle.polygon_index)
                    for triangle in mesh.loop_triangles)
                verts.extend(piece['coords']); normals.extend(piece['normals']); tangents.extend(piece['tangent'])
                offset=len(all_mats); all_mats.extend(piece['materials'])
                for poly in mesh.polygons:
                    faces.append(tuple(vstart+i for i in poly.vertices)); material_ids.append(offset+poly.material_index)
                vstart+=len(mesh.vertices); lstart+=len(mesh.loops); fstart+=len(mesh.polygons)
            combined=bpy.data.meshes.new(PREFIX+owner+'.actual atlas mesh')
            combined.from_pydata(verts,[],faces); combined.update()
            for mat in all_mats: combined.materials.append(mat)
            combined.polygons.foreach_set('material_index',material_ids)
            for poly in combined.polygons: poly.use_smooth=True
            specifications={}
            for piece in pieces:
                for name,(domain,kind,values) in piece['attrs'].items():
                    if name in specifications and specifications[name]!=(domain,kind): raise ValueError('Inconsistent attribute '+name)
                    specifications[name]=(domain,kind)
            for name,(domain,kind) in specifications.items():
                width=ATTR_TYPES[kind][1]; count={'POINT':vstart,'CORNER':lstart,'FACE':fstart}[domain]
                values=np.zeros((count,width),dtype=np.int32 if kind in ('INT','BOOLEAN') else np.float32)
                for record,piece in zip(records,pieces):
                    if name in piece['attrs']:
                        key={'POINT':'vertex','CORNER':'loop','FACE':'face'}[domain]
                        values[record[key+'Start']:record[key+'End']]=piece['attrs'][name][2]
                _attr(combined,name,values,domain,kind)
            _exact_corner_normals(combined,normals)
            tangent_uv=combined.uv_layers.new(name=TANGENT_UV)
            tangent_uv.data.foreach_set('uv',np.asarray(tangents,dtype=np.float32).ravel())
            polygon_copy=combined
            combined,tessellation_proof=_triangulate_bake_copy(bpy,polygon_copy,records,native_triangles)
            bpy.data.meshes.remove(polygon_copy)
            atlas=combined.uv_layers.new(name=ATLAS_UV); atlas.active_render=True
            combined.uv_layers.active_index=len(combined.uv_layers)-1
            bake_ob=bpy.data.objects.new(PREFIX+owner+'.actual bake surface',combined); scene.collection.objects.link(bake_ob)
            for original,ob in copies: bpy.data.objects.remove(ob,do_unlink=True)
            for mesh in copied_data:
                if mesh.users==0: bpy.data.meshes.remove(mesh)
            # World geometry/attributes are already copied and fingerprinted in
            # combined. Release Python construction buffers before UV packing
            # and the float-image bakes; large buildings otherwise retain GBs.
            del verts, faces, normals, tangents, material_ids, native_triangles
            pieces.clear()
            import gc
            gc.collect()
            bpy.context.view_layer.objects.active=bake_ob; bake_ob.select_set(True)
            pre_pack_geometry=_bake_geometry_digest(combined)
            bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
            bpy.ops.uv.smart_project(angle_limit=math.radians(66),island_margin=(2*bake_margin+2)/size,
                                     margin_method='FRACTION',area_weight=.0,
                                    correct_aspect=True,scale_to_bounds=True)
            bpy.ops.object.mode_set(mode='OBJECT')
            from r12_uv_pack_fast import guard_and_pack
            atlas_guard = guard_and_pack(bpy, combined, combined.uv_layers[ATLAS_UV],
                                        size=size, bake_margin=bake_margin)
            assert _bake_geometry_digest(combined)==pre_pack_geometry, 'UV operators changed bake geometry or normals'
            tessellation_proof['afterUvOperatorsGeometryAndNormalsUnchanged']=True
            tessellation_proof['geometryAndNormalsSha256']=pre_pack_geometry
            frame_audit=None; frame_proof=None; normal_graph_receipts=[]
            if paired_normal_frame:
                from r12_paired_surface import (prepare_atlas_patches,
                    prepare_paired_frame,transform_export_frame)
                atlas_guard['isolatedTrianglePatches']=prepare_atlas_patches(
                    combined,ATLAS_UV,records,size=size,bake_margin=bake_margin,
                    report_path=out/(owner+'-atlas-patches.json'))
                # Reject unsupported interpolation transforms before expensive bake.
                for record in records:
                    if record['movable']:
                        transform_export_frame([[0,0,1]],[[1,0,0]],[[1]],record['sourceWorld'])
                frame_audit,frame_proof=prepare_paired_frame(combined,ATLAS_UV,records,
                    bake_ob.matrix_world,out/(owner+'-paired-frame.json'),
                    maximum_interior_fallbacks=maximum_interior_fallbacks)
                assert _bake_geometry_digest(combined)==pre_pack_geometry, 'Frame preparation changed original geometry or shading normals'
            if capture_tangent_inputs:
                _capture_tangent_inputs(combined,out/'tangent-inputs'/(owner+'-bake.npz'))
            scene.render.bake.margin_type = 'EXTEND'
            used_mats=list(dict.fromkeys(all_mats))
            images={}; channel_receipts=[]
            def bake(channel,kind='EMIT'):
                image=bpy.data.images.new(PREFIX+owner+'.'+channel,width=size,height=size,alpha=channel=='baseColor',float_buffer=True)
                image.colorspace_settings.name='sRGB' if channel in ('baseColor','emission') else 'Non-Color'
                image.generated_color=(.5,.5,1,1) if channel=='normal' else (0,0,0,1)
                restore=[]
                with ExitStack() as frame_stack:
                    for mat in used_mats:
                        nt=mat.node_tree; bs=_principled(mat)
                        target=nt.nodes.new('ShaderNodeTexImage'); target.image=image
                        for n in nt.nodes: n.select=False
                        target.select=True; nt.nodes.active=target
                        if channel=='normal' and paired_normal_frame:
                            from r12_frame_nodes import frame_emission_override
                            graph_receipt=frame_stack.enter_context(frame_emission_override(mat,combined,
                                preflight=lambda _mesh,_arrays:frame_audit,world_matrix=bake_ob.matrix_world))
                            normal_graph_receipts.append(dict(material=mat.name,**graph_receipt))
                        elif kind=='EMIT':
                            out_node=next(n for n in nt.nodes if n.type=='OUTPUT_MATERIAL' and n.is_active_output)
                            old=[link.from_socket for link in out_node.inputs['Surface'].links]
                            emission=nt.nodes.new('ShaderNodeEmission')
                            socket={'baseColor':'Base Color','roughness':'Roughness','metallic':'Metallic','specular':'Specular IOR Level','alpha':'Alpha','emission':'Emission Color'}[channel]
                            inp=bs.inputs[socket]
                            if inp.is_linked: nt.links.new(inp.links[0].from_socket,emission.inputs['Color'])
                            else: emission.inputs['Color'].default_value=tuple(inp.default_value) if hasattr(inp.default_value,'__len__') else (inp.default_value,)*3+(1,)
                            if channel=='emission':
                                strength=bs.inputs['Emission Strength']
                                if strength.is_linked: nt.links.new(strength.links[0].from_socket,emission.inputs['Strength'])
                                else: emission.inputs['Strength'].default_value=strength.default_value
                            nt.links.new(emission.outputs[0],out_node.inputs['Surface']); restore.append((nt,out_node,old,emission))
                    print('R12 ACTUAL SURFACE BAKE',owner,channel,size,'faces',len(combined.polygons),flush=True)
                    # EMIT otherwise clears unused atlas pixels to black. Keep
                    # the declared neutral normal outside painted/dilated charts.
                    bpy.ops.object.bake(type=kind,use_clear=not(channel=='normal' and paired_normal_frame),
                                        margin=bake_margin,normal_space='TANGENT')
                    for nt,out_node,old,emission in restore:
                        for link in list(out_node.inputs['Surface'].links): nt.links.remove(link)
                        for socket in old: nt.links.new(socket,out_node.inputs['Surface'])
                        nt.nodes.remove(emission)
                images[channel]=image
                return image
            bake('baseColor'); bake('normal','EMIT' if paired_normal_frame else 'NORMAL'); bake('roughness'); bake('metallic'); bake('specular')
            # glTF specular uses the alpha channel and twice Blender's IOR level.
            # Explicitly pack it; a grayscale RGB PNG silently samples alpha=1.
            spec=np.empty(size*size*4,dtype=np.float32); images['specular'].pixels.foreach_get(spec)
            if float(spec[0::4].max()) > .5001:
                raise ValueError(('Specular above 0.5 needs explicit glTF color-strength handling', float(spec[0::4].max())))
            spec_rgba=np.ones_like(spec); spec_rgba[3::4]=np.clip(spec[0::4]*2,0,1)
            spec_image=bpy.data.images.new(PREFIX+owner+'.specularRGBA',width=size,height=size,alpha=True)
            spec_image.colorspace_settings.name='Non-Color'; spec_image.pixels.foreach_set(spec_rgba); spec_image.update()
            images['specular']=spec_image
            needs_alpha=any(_principled(mat).inputs['Alpha'].is_linked or _principled(mat).inputs['Alpha'].default_value<.999 for mat in used_mats)
            if needs_alpha:
                bake('alpha')
                pixels=np.empty(size*size*4,dtype=np.float32); images['baseColor'].pixels.foreach_get(pixels)
                alpha_values=np.empty_like(pixels); images['alpha'].pixels.foreach_get(alpha_values)
                pixels[3::4]=alpha_values[0::4]; images['baseColor'].pixels.foreach_set(pixels); images['baseColor'].update()
            needs_emission=any(_principled(mat).inputs['Emission Strength'].is_linked or _principled(mat).inputs['Emission Strength'].default_value>0 for mat in used_mats)
            if needs_emission: bake('emission')
            # glTF roughness is G and metalness is B; both use actual source values.
            rough=np.empty(size*size*4,dtype=np.float32); images['roughness'].pixels.foreach_get(rough)
            metal=np.empty_like(rough); images['metallic'].pixels.foreach_get(metal)
            packed=np.ones_like(rough); packed[1::4]=rough[0::4]; packed[2::4]=metal[0::4]
            orm=bpy.data.images.new(PREFIX+owner+'.roughnessMetallic',width=size,height=size,alpha=False)
            orm.colorspace_settings.name='Non-Color'; orm.pixels.foreach_set(packed); orm.update(); images['roughnessMetallic']=orm
            for channel in ('baseColor','normal','roughnessMetallic','specular')+ (('emission',) if needs_emission else ()):
                image=images[channel]; path=out/(owner+'-'+channel+'.png')
                image.filepath_raw=str(path); image.file_format='PNG'; image.save()
                pixels=np.empty(size*size*4,dtype=np.float32); image.pixels.foreach_get(pixels)
                channel_receipts.append({'channel':channel,'file':path.name,'bytes':path.stat().st_size,
                    'sha256':_sha(path.read_bytes()),'size':[size,size],'colorSpace':image.colorspace_settings.name,
                    'pixelMin':float(pixels[0::4].min()),'pixelMax':float(pixels[0::4].max()),
                    'pixelStd':float(pixels[0::4].std())})
                if channel=='normal':
                    channel_receipts[-1]['blueMinimum']=float(pixels[2::4].min())
                    channel_receipts[-1]['blueAtOrBelowHalfPixels']=int(np.count_nonzero(pixels[2::4]<=.5))
                    channel_receipts[-1]['normalHemisphereCompatibilityApproved']=False
            final_mat=bpy.data.materials.new(PREFIX+owner+'.actual baked PBR'); final_mat.use_nodes=True
            nt=final_mat.node_tree; bs=_principled(final_mat)
            uvnode=nt.nodes.new('ShaderNodeUVMap'); uvnode.uv_map=ATLAS_UV
            def texture(channel):
                node=nt.nodes.new('ShaderNodeTexImage'); node.image=images[channel]
                nt.links.new(uvnode.outputs['UV'],node.inputs['Vector']); return node
            nt.links.new(texture('baseColor').outputs['Color'],bs.inputs['Base Color'])
            spec_scale=nt.nodes.new('ShaderNodeMath'); spec_scale.operation='MULTIPLY'; spec_scale.inputs[1].default_value=.5
            nt.links.new(texture('specular').outputs['Alpha'],spec_scale.inputs[0])
            nt.links.new(spec_scale.outputs[0],bs.inputs['Specular IOR Level'])
            nm=nt.nodes.new('ShaderNodeNormalMap'); nm.uv_map=ATLAS_UV; nm.inputs['Strength'].default_value=1
            nt.links.new(texture('normal').outputs['Color'],nm.inputs['Color']); nt.links.new(nm.outputs['Normal'],bs.inputs['Normal'])
            sep=nt.nodes.new('ShaderNodeSeparateColor'); sep.mode='RGB'
            nt.links.new(texture('roughnessMetallic').outputs['Color'],sep.inputs['Color'])
            nt.links.new(sep.outputs['Green'],bs.inputs['Roughness']); nt.links.new(sep.outputs['Blue'],bs.inputs['Metallic'])
            if needs_alpha:
                nt.links.new(texture('baseColor').outputs['Alpha'],bs.inputs['Alpha'])
                final_mat.surface_render_method='DITHERED'
            if needs_emission:
                nt.links.new(texture('emission').outputs['Color'],bs.inputs['Emission Color']); bs.inputs['Emission Strength'].default_value=1
            final_mat['p17ActualSurfaceAtlas']=True
            bake_ob.hide_render=True; bake_ob.hide_set(True); bake_ob.select_set(False)
            exports={}
            static={r['partId'] for r in records if not r['movable'] and not r['evaluatedEmpty']}
            if static:
                mesh=_extract(bpy,combined,records,static,owner+'.static')
                mesh.materials.append(final_mat)
                ob=bpy.data.objects.new(PREFIX+owner+'.static',mesh); scene.collection.objects.link(ob)
                ob['p17Owner']=owner; ob['p17SourcePartIds']=sorted(static); exports[ob.name]=ob
            parent_copies={}
            def parent_copy(original):
                if original is None: return None
                if original.name in parent_copies: return parent_copies[original.name]
                ob=bpy.data.objects.new(PREFIX+owner+'.functional parent.'+original.name,None)
                scene.collection.objects.link(ob); ob['sourceObjectName']=original.name
                for k,v in _props(original).items():
                    try: ob[k]=v
                    except (TypeError,ValueError): ob[k]=json.dumps(v)
                ob.parent=parent_copy(original.parent)
                ob.matrix_world=original.matrix_world.copy(); parent_copies[original.name]=ob
                exports[ob.name]=ob; return ob
            exported_parts={}
            for record,original in zip(records,sources):
                if record['evaluatedEmpty']:
                    ob=bpy.data.objects.new(PREFIX+owner+'.empty.'+original.name,None)
                    scene.collection.objects.link(ob)
                    ob.parent=parent_copy(original.parent); ob.matrix_world=original.matrix_world.copy()
                    for k,v in record['sourceProperties'].items():
                        try: ob[k]=v
                        except (TypeError,ValueError): ob[k]=json.dumps(v)
                    ob['sourceObjectName']=original.name; ob['p17SourcePartId']=record['partId']
                    ob['p17EmptyEvaluatedMesh']=True
                    exports[ob.name]=ob
                    if record['movable']: exported_parts[original.name]=ob
                    continue
                if not record['movable']: continue
                mesh=_extract(bpy,combined,records,{record['partId']},owner+'.part.'+str(record['partId']),original.matrix_world)
                mesh.materials.append(final_mat)
                ob=bpy.data.objects.new(PREFIX+owner+'.'+original.name,mesh); scene.collection.objects.link(ob)
                ob.parent=parent_copy(original.parent); ob.matrix_world=original.matrix_world.copy()
                for k,v in record['sourceProperties'].items():
                    try: ob[k]=v
                    except (TypeError,ValueError): ob[k]=json.dumps(v)
                ob['sourceObjectName']=original.name; ob['p17SourcePartId']=record['partId']; ob['p17MovableLeaf']=True
                exports[ob.name]=ob; exported_parts[original.name]=ob
            # Only source-authored hinges can become interactive pivots. The
            # original leaf world matrices stay exactly in their closed pose.
            relevant_doors=[]; owner_doors=[]; bound_names=set()
            for di,definition in enumerate(door_definitions):
                prefix=definition.get('prefix','__no_prefix__')
                matching={n:o for n,o in exported_parts.items() if n.startswith(prefix+'.leaf')}
                if not matching: continue
                relevant_doors.append(definition)
                hinges=definition.get('hinges',[])
                groups=definition.get('leafGroups',[[j+1] for j in range(len(hinges))])
                signs=definition.get('rotationSigns',[])
                if len(groups)!=len(hinges) or len(signs)!=len(hinges):
                    raise ValueError('Incomplete source hinge definition '+prefix)
                for hi,hinge in enumerate(hinges):
                    members={n:o for n,o in matching.items()
                             if any(n.startswith(prefix+'.leaf'+str(k)+'.') or n==prefix+'.leaf'+str(k) for k in groups[hi])}
                    if not members: continue
                    if bound_names.intersection(members):
                        raise ValueError('Source leaf bound to multiple pivots '+prefix)
                    pivot_name='P17DoorPivot.'+owner+'.'+str(di)+'.'+str(hi)
                    pivot=bpy.data.objects.new(PREFIX+pivot_name,None); scene.collection.objects.link(pivot)
                    pivot.matrix_world=Matrix.Translation(Vector(hinge))
                    pivot['sourceObjectName']=pivot_name; pivot['p17VerifiedSourceHinge']=True
                    pivot['p17HingeSourceWorld']=hinge; pivot['p17DoorPrefix']=prefix
                    pivot['p17LeafGroups']=groups[hi]; pivot['p17RotationSign']=signs[hi]
                    exports[pivot.name]=pivot
                    bpy.context.view_layer.update()
                    for name,ob in members.items():
                        closed=ob.matrix_world.copy(); ob.parent=pivot; ob.matrix_world=closed
                        bpy.context.view_layer.update()
                        assert max(abs(ob.matrix_world[r][c]-closed[r][c]) for r in range(4) for c in range(4))<1e-6
                    bound_names.update(members)
                    owner_doors.append({'id':pivot_name,'assetId':owner,'nodeName':pivot_name,
                        'axis':'y','closedAngle':0,'openAngle':math.radians(76)*signs[hi],
                        'sourcePrefix':prefix,'sourceHingeWorld':hinge,
                        'hingeGltfWorld':[hinge[0],hinge[2],-hinge[1]],
                        'sourceLeafGroups':groups[hi],'sourceObjects':sorted(members)})
            bpy.context.view_layer.update()
            for ob in scene.objects: ob.select_set(False)
            for ob in exports.values(): ob.select_set(True)
            bpy.context.view_layer.objects.active=next(iter(exports.values()))
            if capture_tangent_inputs:
                for export_index,ob in enumerate(exports.values()):
                    if ob.type=='MESH':
                        _capture_tangent_inputs(ob.data,
                            out/'tangent-inputs'/f'{owner}-export-{export_index:03d}.npz',ob.matrix_world)
            glb=out/(owner+'.glb')
            options={'filepath':str(glb),'export_format':'GLB','use_selection':True,'use_active_scene':True,'export_apply':False,
                     'export_texcoords':True,'export_normals':True,'export_tangents':not paired_normal_frame,'export_materials':'EXPORT',
                     'export_image_format':'AUTO','export_extras':True,'export_attributes':True,'export_colors':False,
                     'export_vertex_color':'NONE','export_draco_mesh_compression_enable':False,'export_use_gltfpack':False,
                     'export_animations':False,'export_yup':True}
            accepted=set(bpy.ops.export_scene.gltf.get_rna_type().properties.keys())
            bpy.ops.export_scene.gltf(**{k:v for k,v in options.items() if k in accepted})
            blob,doc,payload=_glb_read(glb)
            if paired_normal_frame:
                from r12_frame_export import install_explicit_frame
                assert normal_graph_receipts and all(r['oldNormalTextureReused'] is False for r in normal_graph_receipts)
                doc,payload,frame_install=install_explicit_frame(doc,payload,paired_normal_bake=True)
                frame_proof.update(normalBakeGraphs=normal_graph_receipts,glbFrameInstallation=frame_install)
                from r12_paired_surface import write_report
                write_report(out/(owner+'-paired-frame.json'),frame_proof)
            forbidden={'KHR_draco_mesh_compression','EXT_meshopt_compression'}
            assert not forbidden.intersection(doc.get('extensionsUsed',[])+doc.get('extensionsRequired',[]))
            for node in doc.get('nodes',[]):
                if node.get('extras',{}).get('sourceObjectName'): node['name']=node['extras']['sourceObjectName']
            for door in owner_doors:
                matches=[(i,n) for i,n in enumerate(doc.get('nodes',[])) if n.get('name')==door['nodeName']]
                assert len(matches)==1,('Missing or duplicated door pivot',door['nodeName'])
                ni,node=matches[0]; door['glbNodeIndex']=ni
                assert np.allclose(node.get('translation',[0,0,0]),door['hingeGltfWorld'],atol=1e-5),door
                assert node.get('children'),('Pivot without leaf children',door['nodeName'])
            by_id={r['partId']:r for r in records}
            for r in records: r['glbTriangleRanges']=[]; r['glbNodeIndices']=[]
            for ni,node in enumerate(doc.get('nodes',[])):
                extras=node.get('extras',{})
                if 'p17SourcePartId' in extras: by_id[int(extras['p17SourcePartId'])]['glbNodeIndices'].append(ni)
                if 'mesh' not in node: continue
                for pi,primitive in enumerate(doc['meshes'][node['mesh']]['primitives']):
                    ids_key=next((k for k in primitive['attributes'] if k.startswith(SOURCE_ID)),None)
                    if ids_key is None: raise ValueError('Exporter omitted source part identity attribute')
                    ids=_accessor(doc,payload,primitive['attributes'][ids_key])[:,0].astype(int)
                    tri=_accessor(doc,payload,primitive['indices'])[:,0].reshape(-1,3)
                    part=ids[tri]; assert np.all(part==part[:,0:1]),'Triangle mixes source part IDs'
                    values=part[:,0]
                    starts=np.r_[0,np.flatnonzero(values[1:]!=values[:-1])+1,len(values)]
                    for a,b in zip(starts[:-1],starts[1:]):
                        r=by_id[int(values[a])]
                        r['glbTriangleRanges'].append({'node':ni,'mesh':node['mesh'],'primitive':pi,'firstTriangle':int(a),'endTriangle':int(b)})
                        if ni not in r['glbNodeIndices']: r['glbNodeIndices'].append(ni)
            for r in records:
                if r['evaluatedEmpty']:
                    assert r['glbNodeIndices'] and not r['glbTriangleRanges'],('Missing empty source identity',r['sourceObject'])
                    assert all('mesh' not in doc['nodes'][i] and doc['nodes'][i].get('extras',{}).get('p17EmptyEvaluatedMesh') for i in r['glbNodeIndices'])
                else:
                    assert r['glbTriangleRanges'],('Missing exported source',r['sourceObject'])
            normal_materials=sum('normalTexture' in m for m in doc.get('materials',[]))
            assert normal_materials>0,'No tangent normal texture in GLB'
            assert all('specularTexture' in m.get('extensions',{}).get('KHR_materials_specular',{}) for m in doc['materials']), 'Specular response lost'
            assert all('TANGENT' in p['attributes'] for m in doc['meshes'] for p in m['primitives']), 'Missing glTF tangents'
            if needs_alpha:
                # Atlas alpha can include opaque and cutout geometry. Preserve crisp
                # ornate cutouts without sorting every opaque building face as BLEND.
                for m in doc.get('materials',[]): m['alphaMode']='MASK'; m['alphaCutoff']=.5
            _glb_write(glb,doc,payload); blob,doc,payload=_glb_read(glb)
            unknown_leaves=sorted(n for n in exported_parts if re.search(r'\.leaf\d+(?:\.|$)',n) and n not in bound_names)
            sidecar={'owner':owner,'candidateSha256':candidate_sha,'sourceSha256':source_sha,'parts':records,
                     'doors':relevant_doors,'interactiveDoors':owner_doors,'unboundLeafParts':unknown_leaves,
                     'unboundLeafReason':'No source-authoritative hinge definition; individual geometry preserved',
                     'movingLeavesPreserved':True,'sourceParentHierarchyPreserved':True,
                     'sourceUvDataPreservedAsCornerAttributesForBake':True,'originalSourceUvsUnchanged':True,
                     'atlasUv':ATLAS_UV,'normalConvention':'glTF tangent +X +Y +Z; original normal graph rebaked',
                     'baseColorLighting':'unlit source Base Color only','channels':channel_receipts,
                      'alphaBoundary':'cutout MASK' if needs_alpha else 'opaque','coordinateWarnings':sorted(set(coord_warnings)),
                       'atlasChartGuard':atlas_guard,'bakeTessellation':tessellation_proof}
            if paired_normal_frame:
                frame_path=out/(owner+'-paired-frame.json')
                sidecar['pairedNormalFrame']=dict(file=frame_path.name,sha256=_sha(frame_path.read_bytes()),
                    freshOriginalWorldNormalBake=True,oldNormalTextureReused=False,
                    originalShadingNormalsUnchanged=True,renderApproval=False)
            mapping=out/(owner+'-source-parts.json'); mapping.write_text(json.dumps(sidecar,ensure_ascii=False,indent=2),encoding='utf8')
            receipt={'owner':owner,'file':glb.name,'bytes':len(blob),'sha256':_sha(blob),'sourceParts':len(records),
                     'candidateSha256':candidate_sha,'sourceSha256':source_sha,'bakeSamples':samples,
                     'movableParts':sum(r['movable'] for r in records),'doorDefinitions':len(relevant_doors),
                     'interactivePivots':len(owner_doors),'unboundLeafParts':len(unknown_leaves),
                     'meshes':len(doc.get('meshes',[])),'nodes':len(doc.get('nodes',[])),
                     'materials':len(doc.get('materials',[])),'images':len(doc.get('images',[])),
                     'normalMaterials':normal_materials,'uncompressed':True,'atlasSize':size,'channels':channel_receipts,
                     'sourcePartsFile':mapping.name,'sourcePartsSha256':_sha(mapping.read_bytes()),
                     'coordinateWarnings':sorted(set(coord_warnings))}
            manifest['owners'].append(receipt)
            manifest['doors'].extend(owner_doors)
            receipt_path=out/(owner+'-receipt.json')
            receipt_path.write_text(json.dumps(receipt,ensure_ascii=False,indent=2),encoding='utf8')
            print('R12 OWNER GLB COMPLETE',owner,len(blob),'bytes',len(records),'source parts',flush=True)
            bpy.context.window.scene=source_scene
            bpy.data.scenes.remove(scene)
            # Drop only detached copy data; original datablocks stay alive throughout.
            for kind in ('objects','meshes','materials','images','node_groups'):
                store=getattr(bpy.data,kind)
                for block in list(store):
                    if block.as_pointer() not in original_ids[kind] and block.name.startswith(PREFIX):
                        store.remove(block,do_unlink=True)
        assert all(_digest(bpy.data.objects[name])==digest for name,digest in before.items()),'Original scene modified'
        manifest['originalGeometryUvsAttributesMaterialsTransformsUnchanged']=True
        manifest['totalBytes']=sum(r['bytes'] for r in manifest['owners'])
        path=out/'manifest.json'; path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
        return manifest
    finally:
        bpy.context.window.scene=original_scene
        for kind in ('scenes','objects','meshes','materials','images','node_groups'):
            store=getattr(bpy.data,kind)
            for block in list(store):
                if block.as_pointer() not in original_ids[kind] and block.name.startswith(PREFIX):
                    store.remove(block,do_unlink=True)
