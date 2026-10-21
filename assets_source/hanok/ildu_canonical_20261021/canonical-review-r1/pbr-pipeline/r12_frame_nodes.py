"""Optional explicit-frame normal bake graph; never installed by the exporter.

The caller supplies a kernel preflight that checks the actual corner attributes
before a shader is altered. Original shading normals are evaluated independently
of the new delivery frame. This module does not launch Blender or bake images.
"""
from contextlib import contextmanager
import hashlib

import numpy as np

FRAME_ATTRIBUTES=('R12_FrameT','R12_FrameB','R12_FrameN')


def read_frame_attributes(mesh):
    arrays={}
    for name in FRAME_ATTRIBUTES:
        attribute=mesh.attributes.get(name)
        if attribute is None or attribute.domain!='CORNER' or attribute.data_type!='FLOAT_VECTOR':
            raise ValueError(name+' must be an explicit CORNER FLOAT_VECTOR attribute')
        values=np.empty((len(mesh.loops),3),dtype=np.float32)
        attribute.data.foreach_get('vector',values.ravel())
        if not np.isfinite(values).all():raise ValueError(name+' contains nonfinite values')
        arrays[name]=values
    return arrays


def attribute_hashes(arrays):
    return {key:hashlib.sha256(np.ascontiguousarray(value).tobytes()).hexdigest()
            for key,value in arrays.items()}


def _kernel_digest(values):
    values=np.asarray(values)
    return hashlib.sha256(str((values.dtype.str,values.shape)).encode()+values.tobytes()).hexdigest()


def verify_kernel_binding(audit,triangle_frames,triangle_positions):
    """Reject stale/partial audits, binding exact dtype, shape and bytes.

    This is independently testable without Blender. A sampled pass cannot
    replace the kernel's conservative whole-interior determinant certificate.
    """
    positions=np.asarray(triangle_positions)
    if (len(triangle_frames)!=3 or positions.ndim!=3 or positions.shape[1:]!=(3,3) or
            positions.dtype.kind!='f' or not np.isfinite(positions).all() or
            any(np.asarray(value).shape!=positions.shape or np.asarray(value).dtype!=np.float32
                or not np.isfinite(value).all() for value in triangle_frames)):
        raise ValueError('Exact finite triangle positions and three Float32 corner frame arrays required')
    if (not isinstance(audit,dict) or audit.get('schemaVersion')!=1 or
            audit.get('passed') is not True or audit.get('interiorGate')!='certified' or
            audit.get('requiresMatchedRebake') is not True):
        raise ValueError('Stable-frame whole-interior preflight did not pass; no bake graph was installed')
    expected={key:_kernel_digest(values) for key,values in zip(
        ('tangents','bitangents','normals'),triangle_frames)}
    expected['positions']=_kernel_digest(triangle_positions)
    bound=audit.get('inputDigests')
    if (audit.get('triangleCount')!=len(triangle_positions) or not isinstance(bound,dict) or
            any(bound.get(key)!=value for key,value in expected.items())):
        raise ValueError('Stable-frame preflight is not bound to the exact live world triangles and frame attributes')
    return expected


def read_world_triangle_inputs(mesh,world_matrix,arrays=None):
    """Return ((T, B, N) corner arrays, world triangle positions) for auditing.

    Frame arrays are exact Float32 [triangle, corner, xyz]. World positions are
    Float64, computed from exact stored Float32 vertex coordinates and the given
    affine matrix. Call after installing the explicit CORNER frame attributes.
    A cached audit is reusable only while all returned dtype/shape/bytes match.
    """
    if arrays is None:arrays=read_frame_attributes(mesh)
    matrix=np.asarray(world_matrix,dtype=np.float64)
    if matrix.shape!=(4,4) or not np.isfinite(matrix).all() or not np.array_equal(matrix[3],[0.,0.,0.,1.]):
        raise ValueError('A finite affine world_matrix is required for exact preflight binding')
    mesh.calc_loop_triangles()
    loops=np.array([tuple(triangle.loops) for triangle in mesh.loop_triangles],dtype=np.int32)
    indices=np.array([tuple(triangle.vertices) for triangle in mesh.loop_triangles],dtype=np.int32)
    if len(indices)==0:raise ValueError('Cannot bake an empty mesh')
    positions=np.empty((len(mesh.vertices),3),dtype=np.float32)
    mesh.vertices.foreach_get('co',positions.ravel())
    world=positions.astype(np.float64)@matrix[:3,:3].T+matrix[:3,3]
    return tuple(arrays[name][loops] for name in FRAME_ATTRIBUTES),world[indices]


@contextmanager
def frame_emission_override(material,mesh,*,preflight,world_matrix):
    """Temporarily encode the original world shading normal into supplied TBN.

    ``preflight`` is a required callable taking (mesh, frame_arrays), returning a
    JSON-safe stable-kernel audit. A caller may cache that expensive audit across
    materials. This helper independently binds its whole-interior certificate
    to exact live dtype/shape/bytes, so a changed mesh/frame requires a new audit.
    A saved approval or a sampled pass cannot substitute for that certificate.

    ``world_matrix`` is the actual bake object's affine world transform. Its
    positions and the frame arrays must match the live kernel report exactly.
    Frame attributes must be expressed in the world-space basis used by the
    source normal graph on this bake object. No implicit object transform or
    geometry-normal replacement is performed here.
    """
    if not callable(preflight):raise ValueError('A stable-frame kernel preflight provider is required')
    arrays=read_frame_attributes(mesh);before=attribute_hashes(arrays)
    frame_inputs,world_positions=read_world_triangle_inputs(mesh,world_matrix,arrays)
    audit=preflight(mesh,arrays)
    binding=verify_kernel_binding(audit,frame_inputs,world_positions)
    current_frames,current_positions=read_world_triangle_inputs(mesh,world_matrix)
    if (attribute_hashes(read_frame_attributes(mesh))!=before or
            verify_kernel_binding(audit,current_frames,current_positions)!=binding):
        raise ValueError('Preflight changed live geometry/frame inputs; no bake graph was installed')
    # ExitStack may keep one override alive per material during a single bake.
    # Only compact hashes are needed while yielded: retaining per-material
    # copies of every triangle/attribute would multiply mesh memory needlessly.
    del arrays,frame_inputs,world_positions,current_frames,current_positions
    if not material.use_nodes or material.node_tree is None:raise ValueError('Node material required')
    tree=material.node_tree
    outputs=[node for node in tree.nodes if node.type=='OUTPUT_MATERIAL' and node.is_active_output]
    if len(outputs)!=1:raise ValueError('Exactly one active material output required')
    output=outputs[0];old_links=[link.from_socket for link in output.inputs['Surface'].links]
    if len(old_links)!=1 or old_links[0].node.type!='BSDF_PRINCIPLED':
        raise ValueError('Original surface must be the directly linked Principled BSDF')
    principled=old_links[0].node;normal_input=principled.inputs['Normal']
    if len(normal_input.links)>1:raise ValueError('Ambiguous original Principled Normal input')
    original_active=tree.nodes.active
    original_selected={node:node.select for node in tree.nodes}
    created=[]

    def node(kind,label):
        result=tree.nodes.new(kind);result.label='R12 frame bake: '+label;created.append(result);return result

    def vector(operation,*inputs):
        result=node('ShaderNodeVectorMath',operation);result.operation=operation
        for i,socket in enumerate(inputs):tree.links.new(socket,result.inputs[i])
        return result.outputs['Value' if operation=='DOT_PRODUCT' else 'Vector']

    try:
        axes=[]
        for name in FRAME_ATTRIBUTES:
            attr=node('ShaderNodeAttribute',name);attr.attribute_name=name;attr.attribute_type='GEOMETRY'
            axes.append(vector('NORMALIZE',attr.outputs['Vector']))
        tangent,bitangent,normal=axes
        if normal_input.is_linked:
            source_normal=normal_input.links[0].from_socket;source_kind='original_linked_principled_normal'
        else:
            geometry=node('ShaderNodeNewGeometry','original shading normal')
            source_normal=geometry.outputs['Normal'];source_kind='original_geometry_normal'
        source_normal=vector('NORMALIZE',source_normal)
        bn=vector('CROSS_PRODUCT',bitangent,normal)
        nt=vector('CROSS_PRODUCT',normal,tangent)
        tb=vector('CROSS_PRODUCT',tangent,bitangent)
        determinant=vector('DOT_PRODUCT',tangent,bn)
        combine=node('ShaderNodeCombineXYZ','inverse TBN coefficients')
        for i,cofactor in enumerate((bn,nt,tb)):
            numerator=vector('DOT_PRODUCT',source_normal,cofactor)
            divide=node('ShaderNodeMath','cofactor / determinant');divide.operation='DIVIDE'
            tree.links.new(numerator,divide.inputs[0]);tree.links.new(determinant,divide.inputs[1])
            tree.links.new(divide.outputs[0],combine.inputs[i])
        encoded=vector('NORMALIZE',combine.outputs['Vector'])
        scale=node('ShaderNodeVectorMath','signed normal to linear RGB');scale.operation='SCALE'
        tree.links.new(encoded,scale.inputs[0]);scale.inputs['Scale'].default_value=.5
        shift=node('ShaderNodeVectorMath','linear RGB offset');shift.operation='ADD'
        tree.links.new(scale.outputs['Vector'],shift.inputs[0]);shift.inputs[1].default_value=(.5,.5,.5)
        emission=node('ShaderNodeEmission','fresh encoded normal');emission.inputs['Strength'].default_value=1.
        tree.links.new(shift.outputs['Vector'],emission.inputs['Color'])
        tree.links.new(emission.outputs[0],output.inputs['Surface'])
        yield dict(sourceNormalKind=source_kind,frameAttributeHashes=before,kernelPreflight=audit,
            exactLiveKernelBinding=binding,
            encoding='normalize(inverse(columns(normalize(T),normalize(B),normalize(N))) * originalWorldShadingNormal) * 0.5 + 0.5',
            newFrameNormalUsedAsSource=False,oldNormalTextureReused=False,visualApproval=False,runtimePromoted=False)
    finally:
        for link in list(output.inputs['Surface'].links):tree.links.remove(link)
        for socket in old_links:tree.links.new(socket,output.inputs['Surface'])
        for created_node in reversed(created):tree.nodes.remove(created_node)
        for original,selected in original_selected.items():original.select=selected
        tree.nodes.active=original_active
        if attribute_hashes(read_frame_attributes(mesh))!=before:
            raise ValueError('Frame attributes changed while the temporary bake graph was active')
