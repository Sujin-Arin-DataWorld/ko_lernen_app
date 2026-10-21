"""Install an explicitly baked frame in a candidate GLB, without rebasing old maps.

Only use with a new normal texture authored for these exact corner attributes.
Source positions, topology, UVs, images and node transforms are left unchanged.
This module is not wired into the default R12 exporter.
"""
import copy
import numpy as np

FRAME_N = '_R12_FRAME_N'
FRAME_T = '_R12_FRAME_T'
FRAME_W = '_R12_FRAME_W'


def _array(doc, payload, index, width):
    accessor=doc['accessors'][index]
    if accessor.get('componentType') != 5126 or accessor.get('normalized',False) or 'sparse' in accessor:
        raise ValueError('Explicit frame must contain unnormalized float32 values')
    if accessor['type'] != {1:'SCALAR',3:'VEC3'}[width]:
        raise ValueError('Unexpected explicit frame width')
    view=doc['bufferViews'][accessor['bufferView']]
    if view.get('buffer',0) != 0:
        raise ValueError('Explicit frame requires an embedded buffer')
    offset=view.get('byteOffset',0)+accessor.get('byteOffset',0)
    return np.ndarray((accessor['count'],width),dtype='<f4',buffer=payload,
        offset=offset,strides=(view.get('byteStride',width*4),4)).copy()


def install_explicit_frame(doc, payload, *, paired_normal_bake):
    if paired_normal_bake is not True:
        raise ValueError('A matched new normal bake is required; never patch the old normal map')
    result=copy.deepcopy(doc)
    data=bytearray(payload)
    receipts=[]

    def append(values, kind):
        padding=(-len(data))%4
        data.extend(b'\0'*padding)
        offset=len(data)
        raw=np.asarray(values,dtype='<f4').tobytes()
        data.extend(raw)
        view=len(result['bufferViews'])
        result['bufferViews'].append(dict(buffer=0,byteOffset=offset,byteLength=len(raw),target=34962))
        accessor=len(result['accessors'])
        result['accessors'].append(dict(bufferView=view,componentType=5126,
                                       count=len(values),type=kind))
        return accessor

    for mesh_index,mesh in enumerate(result.get('meshes',[])):
        for primitive_index,primitive in enumerate(mesh['primitives']):
            attrs=primitive['attributes']
            if not all(name in attrs for name in (FRAME_N,FRAME_T,FRAME_W)):
                raise ValueError('Missing explicit frame attributes')
            n=_array(result,data,attrs[FRAME_N],3)
            t=_array(result,data,attrs[FRAME_T],3)
            w=_array(result,data,attrs[FRAME_W],1)
            if len(n)!=len(t) or len(n)!=len(w):
                raise ValueError('Explicit frame vertex counts disagree')
            if not all(np.isfinite(a).all() for a in (n,t,w)):
                raise ValueError('Nonfinite explicit frame')
            n64,t64=n.astype(np.float64),t.astype(np.float64)
            normal_error=float(np.max(np.abs(np.linalg.norm(n64,axis=1)-1),initial=0))
            tangent_error=float(np.max(np.abs(np.linalg.norm(t64,axis=1)-1),initial=0))
            orthogonality=float(np.max(np.abs(np.sum(n64*t64,axis=1)),initial=0))
            if max(normal_error,tangent_error,orthogonality)>1e-5 or not np.isin(w,[-1.,1.]).all():
                raise ValueError('Invalid explicit frame; cannot silently repair after baking')
            # Blender custom attributes are not automatically converted to Y-up.
            # This proper rotation preserves handedness and the baked basis.
            n=n[:,[0,2,1]].copy();n[:,2]*=-1
            t=t[:,[0,2,1]].copy();t[:,2]*=-1
            attrs['NORMAL']=append(n,'VEC3')
            attrs['TANGENT']=append(np.column_stack((t,w)),'VEC4')
            for name in (FRAME_N,FRAME_T,FRAME_W):
                del attrs[name]
            receipts.append(dict(mesh=mesh_index,primitive=primitive_index,vertices=len(n),
                maximumNormalUnitError=normal_error,maximumTangentUnitError=tangent_error,
                maximumAbsoluteNormalTangentDot=orthogonality))
    result['buffers'][0]['byteLength']=len(data)
    return result,bytes(data),dict(pairedNormalBakeRequired=True,frame='explicit new bake basis',
        positionsUvsIndicesImagesTransformsChanged=False,primitives=receipts,
        visualApproval=False)
