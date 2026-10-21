"""Run in Blender factory startup; exercises thin, collapsed and empty charts."""
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
sys.path.insert(0, str(Path(__file__).parent))
from r12_uv_pack import guard_and_pack, chart_loop_groups
from r12_uv_coverage import triangle_pixel_centers

# A thin ring has a >2px bounding span but no occupied pixel centers. It
# reproduces the native door-ring defect that a PCA-only guard missed.
ring_points = [(8+r*math.cos(i*math.pi/4), r*math.sin(i*math.pi/4), 0)
               for r in (1.0, .995) for i in range(8)]
ring_faces = [(11+i, 11+(i+1)%8, 19+(i+1)%8, 19+i) for i in range(8)]
ring_uvs = [((100.1+2*r*math.cos(i*math.pi/4))/512,
             (100.1+2*r*math.sin(i*math.pi/4))/512)
            for r in (1.0, .995) for i in range(8)]
assert not any(len(triangle_pixel_centers(np.array([ring_uvs[j-11] for j in tri])*512,512))
               for face in ring_faces for tri in ((face[0],face[1],face[2]),(face[0],face[2],face[3])))

mesh = bpy.data.meshes.new('UV guard fixture')
mesh.from_pydata([(0,0,0),(1,0,0),(1,1,0),(0,1,0),
                 (2,0,0),(3,0,0),(3,1,0),(2,1,0),
                 (4,0,0),(5,0,0),(6,0,0)]+ring_points, [],
                 [(0,1,2,3),(4,5,6,7),(8,9,10)]+ring_faces)
mesh.update()
obj = bpy.data.objects.new('UV guard fixture', mesh)
bpy.context.scene.collection.objects.link(obj)
bpy.ops.object.select_all(action='DESELECT')
obj.select_set(True)
bpy.context.view_layer.objects.active = obj
authored = mesh.uv_layers.new(name='protected authored UV')
authored.data.foreach_set('uv', [0.125]* (len(mesh.loops)*2))
uv = mesh.uv_layers.new(name='temporary bake UV')
mesh.uv_layers.active_index=1
uv.active_render=True
uv.data.foreach_set('uv', [0,.1, .00003,.1, .00003,.2, 0,.2,
                          .4,.4, .4,.4, .4,.4, .4,.4,
                          .7,.7, .7,.7, .7,.7]+
                         [v for face in ring_faces for j in face for v in ring_uvs[j-11]])
before = ([tuple(v.co) for v in mesh.vertices], [tuple(p.vertices) for p in mesh.polygons],
          [tuple(item.uv) for item in mesh.uv_layers['protected authored UV'].data])
print('UV_PACK_FIXTURE_START', flush=True)
result = guard_and_pack(bpy, mesh, uv, size=512, bake_margin=8)
after = ([tuple(v.co) for v in mesh.vertices], [tuple(p.vertices) for p in mesh.polygons],
         [tuple(item.uv) for item in mesh.uv_layers['protected authored UV'].data])
assert before == after, 'Original geometry or authored UV modified'
assert result['retainedZeroWorldAreaCharts'] == [2], result
assert result['projectedCollapsedAtlasCharts'] == [1], result
assert result['actualMinimumPrincipalSpanTexels'] >= 1.9999, result
assert result['packingMarginMethod']=='FRACTION'
assert 3 in result['coverageEnlargedCharts'], result
assert result['preExportVisibleZeroCenterCharts']==[], result
print('UV_PACK_FIXTURE_PASS '+json.dumps(result), flush=True)

# A common zero-length UV edge is not a raster connection. Distinct charts
# connected this way reproduced the native seam-shadow false merge.
seam = bpy.data.meshes.new('zero UV edge fixture')
seam.from_pydata([(0,0,0),(1,0,0),(0,1,0),(1,1,0)],[],[(0,1,2),(1,0,3)])
seam.update()
seam_uv = seam.uv_layers.new(name='atlas')
seam_uv.data.foreach_set('uv',[.1,.1,.1,.1,.3,.2, .1,.1,.1,.1,.4,.3])
assert len(chart_loop_groups(seam,seam_uv))==2
print('UV_ZERO_EDGE_PARTITION_PASS',flush=True)

# Numerous individually negligible source triangles can sum above epsilon.
# Use the same per-triangle exemption as the independent decoded GLB audit.
tiny = bpy.data.meshes.new('aggregate tiny area fixture')
tiny.from_pydata([(math.cos(i*math.pi/20)*1e-6, math.sin(i*math.pi/20)*1e-6,0)
                 for i in range(40)]+[(0,0,0)],[],[(i,(i+1)%40,40) for i in range(40)])
tiny.update()
tiny.calc_loop_triangles()
assert sum(t.area for t in tiny.loop_triangles)>1e-12
assert all(t.area<=1e-12 for t in tiny.loop_triangles)
tiny_uv=tiny.uv_layers.new(name='atlas')
tiny_uv.data.foreach_set('uv',[value for loop in tiny.loops
                             for value in (.5+tiny.vertices[loop.vertex_index].co.x*1e5,
                                           .5+tiny.vertices[loop.vertex_index].co.y*1e5)])
tiny_result=guard_and_pack(bpy,tiny,tiny_uv,size=512,bake_margin=2)
assert tiny_result['retainedZeroWorldAreaCharts']==[0]
assert not tiny_result['coverageEnlargedCharts']
print('UV_AGGREGATE_ZERO_AREA_PASS',flush=True)

# A positive-area triangle whose projected minor dimension is lost when
# prematurely cast to UV32 at a large atlas offset must still receive paint.
ridge=bpy.data.meshes.new('thin positive ridge fixture')
ridge.from_pydata([(0,0,0),(1,0,0),(.5,3e-11,0)],[],[(0,1,2)])
ridge.update()
ridge_uv=ridge.uv_layers.new(name='atlas')
ridge_uv.data.foreach_set('uv',[.75,.75]*3)
ridge_obj=bpy.data.objects.new('thin positive ridge fixture',ridge)
bpy.context.scene.collection.objects.link(ridge_obj)
bpy.ops.object.select_all(action='DESELECT')
ridge_obj.select_set(True)
bpy.context.view_layer.objects.active=ridge_obj
ridge_result=guard_and_pack(bpy,ridge,ridge_uv,size=512,bake_margin=2)
assert ridge_result['projectedCollapsedAtlasCharts']==[0]
assert ridge_result['separatedCollapsedAtlasTriangles']==[]
assert ridge_result['preExportVisibleZeroCenterCharts']==[]
assert not ridge_result['retainedZeroWorldAreaCharts']
print('UV_THIN_POSITIVE_RIDGE_PASS',flush=True)

# A whole chart flattened by the initial projection must stay a connected chart
# when repaired, rather than being split into one atlas island per triangle.
fan=bpy.data.meshes.new('whole collapsed connected chart')
fan.from_pydata([(0,0,0)]+[(math.cos(i*math.pi/6),math.sin(i*math.pi/6),0)
    for i in range(12)],[],[(0,i+1,(i+1)%12+1) for i in range(12)])
fan.update()
fan_uv=fan.uv_layers.new(name='atlas')
fan_uv.data.foreach_set('uv',[value for loop in fan.loops for value in (.1+loop.vertex_index*.01,.4)])
fan_obj=bpy.data.objects.new('whole collapsed connected chart',fan)
bpy.context.scene.collection.objects.link(fan_obj)
bpy.ops.object.select_all(action='DESELECT');fan_obj.select_set(True)
bpy.context.view_layer.objects.active=fan_obj
fan_before=([tuple(v.co) for v in fan.vertices],[tuple(p.vertices) for p in fan.polygons])
assert len(chart_loop_groups(fan,fan_uv))==1
fan_result=guard_and_pack(bpy,fan,fan_uv,size=512,bake_margin=2)
assert fan_result['chartCount']==1,fan_result
assert fan_result['projectedCollapsedAtlasCharts']==[0],fan_result
assert fan_before==([tuple(v.co) for v in fan.vertices],[tuple(p.vertices) for p in fan.polygons])
print('UV_WHOLE_CHART_BEFORE_TRIANGLE_REPAIR_PASS',flush=True)

# Inject the observed packing boundary failure once: an originally connected
# chart acquires a collapsed shared edge after UV32 writeback. The final guard
# must discover two fragments and give each one painted texels. Only temporary
# UV coordinates are changed by this fault injection, never source geometry.
from types import SimpleNamespace
split = bpy.data.meshes.new('post-pack collapsed shared edge fixture')
split.from_pydata([(0,0,0),(1,0,0),(0,1,0),(1,-1,0)],[],[(0,1,2),(1,0,3)])
split.update()
split_uv = split.uv_layers.new(name='atlas')
split_uv.data.foreach_set('uv',[.1,.1, .100001,.1, .1,.3,
                              .100001,.1, .1,.1, .100001,-.1])
split_obj = bpy.data.objects.new('post-pack collapsed shared edge fixture',split)
bpy.context.scene.collection.objects.link(split_obj)
bpy.ops.object.select_all(action='DESELECT')
split_obj.select_set(True)
bpy.context.view_layer.objects.active=split_obj
split_before=([tuple(v.co) for v in split.vertices], [tuple(p.vertices) for p in split.polygons])
assert len(chart_loop_groups(split,split_uv))==1
injected=[]
def inject_after_mode_switch(*args, **kwargs):
    result=bpy.ops.object.mode_set(*args,**kwargs)
    if kwargs.get('mode')=='OBJECT' and not injected:
        packed=np.empty((len(split.loops),2),dtype=np.float32)
        split.uv_layers['atlas'].data.foreach_get('uv',packed.ravel())
        packed[[0,1,3,4]]=packed[0]
        split.uv_layers['atlas'].data.foreach_set('uv',packed.ravel())
        split.update()
        injected.append(True)
    return result
proxy=SimpleNamespace(ops=SimpleNamespace(object=SimpleNamespace(mode_set=inject_after_mode_switch),
                                         mesh=bpy.ops.mesh,uv=bpy.ops.uv))
split_result=guard_and_pack(proxy,split,split_uv,size=512,bake_margin=2)
assert injected and split_result['chartCount']==2,split_result
assert split_result['repartitionHistory'][0]['stage']=='after-packing',split_result
assert split_result['preExportVisibleZeroCenterCharts']==[],split_result
assert split_before==([tuple(v.co) for v in split.vertices], [tuple(p.vertices) for p in split.polygons])
print('UV_POST_PACK_REPARTITION_PASS '+json.dumps(split_result),flush=True)
