"""Actual Blender regression for identical bake/export triangle geometry."""
import sys
import hashlib
from pathlib import Path
import bpy
import numpy as np
sys.path.insert(0,str(Path(__file__).parent))
from r12_pbr_delivery import _triangulate_bake_copy, _attr, _exact_corner_normals

source=bpy.data.meshes.new('native polygon fixture')
source.from_pydata([(0,0,0),(2,0,0),(2,2,0),(0,2,0),
                    (4,0,0),(6,0,0),(6,2,0),(5,1,0),(4,2,0)],[],
                   [(0,1,2,3),(4,5,6,7,8)])
source.update()
for polygon in source.polygons: polygon.use_smooth=True
source.normals_split_custom_set([(0,0,1)]*len(source.loops))
_attr(source,'authored coordinate',np.arange(27,dtype=np.float32).reshape(-1,3))
_attr(source,'authored corner',np.arange(27,dtype=np.float32).reshape(-1,3),domain='CORNER')
_attr(source,'authored face',[7,9],domain='FACE',kind='INT')
uv=source.uv_layers.new(name='protected source UV')
uv.data.foreach_set('uv',np.arange(18,dtype=np.float32)/18)
source.calc_loop_triangles()
loops=np.array([li for tri in source.loop_triangles for li in tri.loops])
face_ids=np.array([tri.polygon_index for tri in source.loop_triangles])
original=([tuple(v.co) for v in source.vertices],[tuple(p.vertices) for p in source.polygons],
          [tuple(item.uv) for item in uv.data])
records=[dict(faceStart=0,faceEnd=1,loopStart=0,loopEnd=4,evaluatedFaceCount=1,evaluatedLoopCount=4),
         dict(faceStart=1,faceEnd=2,loopStart=4,loopEnd=9,evaluatedFaceCount=1,evaluatedLoopCount=5)]
result,proof=_triangulate_bake_copy(bpy,source,records)
assert len(result.polygons)==5 and all(len(p.vertices)==3 for p in result.polygons)
assert records[0]['faceEnd']==2 and records[1]['faceStart']==2 and records[1]['faceEnd']==5
assert [(r['evaluatedFaceCount'],r['evaluatedLoopCount']) for r in records]==[(1,4),(1,5)]
assert [tuple(v.co) for v in result.vertices]==original[0]
assert [tuple(v.uv) for v in result.uv_layers[uv.name].data]==[original[2][i] for i in loops]
assert [v.value for v in result.attributes['authored face'].data]==[[7,9][i] for i in face_ids]
assert [tuple(v.vector) for v in result.attributes['authored corner'].data]==[
    tuple(source.attributes['authored corner'].data[i].vector) for i in loops]
assert original==([tuple(v.co) for v in source.vertices],[tuple(p.vertices) for p in source.polygons],
                  [tuple(item.uv) for item in uv.data])
assert proof['exactEvaluatedTrianglePositions'] and proof['originalNativeChanged'] is False
assert proof['tessellationCapturedBeforeWorldJoin'] is False
print('R12_BAKE_TESSELLATION_PASS',proof,flush=True)

# Non-coplanar flat faces exercise sharp_face: writing that attribute after
# custom normals silently changes their encoding basis in Blender.
sharp=bpy.data.meshes.new('sharp face normal fixture')
sharp.from_pydata([(0,0,0),(1,0,0),(1,1,.4),(0,1,0),(0,0,1),(1,0,1)],[],
                  [(0,1,2,3),(0,4,5,1)])
sharp.update()
for polygon in sharp.polygons: polygon.use_smooth=False
sharp.normals_split_custom_set([(0.2,0.3,0.9327379)]*len(sharp.loops))
sharp_records=[dict(faceStart=0,faceEnd=2,loopStart=0,loopEnd=8,
                    evaluatedFaceCount=2,evaluatedLoopCount=8)]
_,sharp_proof=_triangulate_bake_copy(bpy,sharp,sharp_records)
assert sharp_proof['maximumCornerNormalComponentError']<1e-4
print('R12_SHARP_FACE_NORMAL_PASS',sharp_proof,flush=True)

# The captured object-space triangulation must win even when the joined polygon
# would choose the other diagonal. Select the opposite valid diagonal dynamically
# so this test cannot accidentally pass by repeating Blender's default choice.
# A leading triangle also exercises nonzero face/loop/vertex offsets and records.
captured=bpy.data.meshes.new('captured original triangulation fixture')
captured.from_pydata([(-2,0,0),(-1,0,0),(-2,1,0),
                      (0,0,0),(2,0,0),(2,1,.35),(0,1,0)],[],
                     [(0,1,2),(3,4,5,6)])
captured.update()
for index,polygon in enumerate(captured.polygons):
    polygon.use_smooth=index==0
for index in range(2):
    captured.materials.append(bpy.data.materials.new('captured fixture material '+str(index)))
captured.polygons.foreach_set('material_index',[0,1])
source_normals=np.array([(0.13+index*.031,0.22-index*.009,0.91)
                         for index in range(len(captured.loops))],dtype=np.float32)
source_normals/=np.linalg.norm(source_normals,axis=1)[:,None]
_exact_corner_normals(captured,source_normals)
_attr(captured,'captured corner identity',np.arange(len(captured.loops)),domain='CORNER',kind='INT')
_attr(captured,'captured face identity',[201,202],domain='FACE',kind='INT')
captured_uv=captured.uv_layers.new(name='captured authored UV')
uv_values=np.arange(len(captured.loops)*2,dtype=np.float32).reshape(-1,2)/16
captured_uv.data.foreach_set('uv',uv_values.ravel())
captured.calc_loop_triangles()
default_triangles=[(tuple(t.vertices),tuple(t.loops),t.polygon_index)
                   for t in captured.loop_triangles]
quad_loops=tuple(captured.polygons[1].loop_indices)
diagonal_a=((quad_loops[0],quad_loops[1],quad_loops[2]),
            (quad_loops[0],quad_loops[2],quad_loops[3]))
diagonal_b=((quad_loops[0],quad_loops[1],quad_loops[3]),
            (quad_loops[1],quad_loops[2],quad_loops[3]))
default_quad={frozenset(loops) for _,loops,face in default_triangles if face==1}
alternative=diagonal_b if default_quad=={frozenset(t) for t in diagonal_a} else diagonal_a
assert {frozenset(t) for t in alternative}!=default_quad
supplied=[t for t in default_triangles if t[2]==0]
supplied.extend((tuple(captured.loops[li].vertex_index for li in loops),loops,1)
                for loops in alternative)
supplied_snapshot=tuple(supplied)
expected_vertices=np.array([vertices for vertices,_,_ in supplied],dtype=np.int32)
expected_loops=np.array([li for _,loops,_ in supplied for li in loops],dtype=np.int32)
source_coords=np.array([tuple(v.co) for v in captured.vertices],dtype=np.float32)
expected_positions=source_coords[expected_vertices].tobytes()
source_polygons=[tuple(p.vertices) for p in captured.polygons]
captured_records=[dict(faceStart=0,faceEnd=1,loopStart=0,loopEnd=3,
                       evaluatedFaceCount=1,evaluatedLoopCount=3),
                  dict(faceStart=1,faceEnd=2,loopStart=3,loopEnd=7,
                       evaluatedFaceCount=1,evaluatedLoopCount=4)]
captured_result,captured_proof=_triangulate_bake_copy(
    bpy,captured,captured_records,source_triangles=supplied)
captured_result.calc_loop_triangles()
actual_vertices=np.array([tuple(t.vertices) for t in captured_result.loop_triangles],dtype=np.int32)
actual_coords=np.array([tuple(v.co) for v in captured_result.vertices],dtype=np.float32)
actual_normals=np.array([tuple(n.vector) for n in captured_result.corner_normals],dtype=np.float32)
assert captured_proof['tessellationCapturedBeforeWorldJoin'] is True
assert captured_proof['maximumCornerNormalComponentError']==0.0
assert captured_proof['bakeTriangles']==3 and captured_proof['sourcePolygons']==2
assert captured_proof['trianglePositionsSha256']==hashlib.sha256(expected_positions).hexdigest()
assert np.array_equal(actual_vertices,expected_vertices)
assert actual_coords[actual_vertices].tobytes()==expected_positions
assert actual_normals.tobytes()==source_normals[expected_loops].tobytes()
assert [tuple(item.uv) for item in captured_result.uv_layers[captured_uv.name].data]==[
    tuple(uv_values[i]) for i in expected_loops]
assert [item.value for item in captured_result.attributes['captured corner identity'].data]==expected_loops.tolist()
assert [item.value for item in captured_result.attributes['captured face identity'].data]==[201,202,202]
assert [p.material_index for p in captured_result.polygons]==[0,1,1]
assert [(r['faceStart'],r['faceEnd'],r['loopStart'],r['loopEnd']) for r in captured_records]==[
    (0,1,0,3),(1,3,3,9)]
assert [(r['evaluatedFaceCount'],r['evaluatedLoopCount']) for r in captured_records]==[(1,3),(1,4)]
assert tuple(supplied)==supplied_snapshot
assert np.array([tuple(v.co) for v in captured.vertices],dtype=np.float32).tobytes()==source_coords.tobytes()
assert [tuple(p.vertices) for p in captured.polygons]==source_polygons
assert [tuple(item.uv) for item in captured_uv.data]==[tuple(uv) for uv in uv_values]
assert np.array([tuple(n.vector) for n in captured.corner_normals],dtype=np.float32).tobytes()==source_normals.tobytes()
print('R12_CAPTURED_NATIVE_DIAGONAL_PASS',dict(captured_proof,
    differsFromJoinedPolygonDefault=True,sourceCornerAttributesAndUvsExact=True,
    sourceMeshAndSuppliedTrianglesUnchanged=True),flush=True)
