"""Read-only paired rays on the user-reported diagonal; no render or save."""
import json
import math
from pathlib import Path
import bpy
from mathutils import Vector, Euler

OUT=Path(__file__).resolve().parent
scene=bpy.data.scenes['Hangul Sori | Full Ildu Estate']
graph=bpy.context.evaluated_depsgraph_get()
manifest=json.loads((OUT/'render-manifest.json').read_text(encoding='utf-8'))
camera=next(r['camera'] for r in manifest['renders'] if r['view']=='overview' and r['variant']=='B')
rotation=Euler(camera['rotation'],'XYZ').to_matrix()
right,up,back=(rotation@Vector(v) for v in ((1,0,0),(0,1,0),(0,0,1)))
pos=Vector(camera['location'])
zones=json.loads((OUT/'ground-scope.json').read_text(encoding='utf-8'))['zones']

def mask(zone, point):
    poly=zone['polygon']; signed=sum(a[0]*b[1]-a[1]*b[0] for a,b in zip(poly,poly[1:]+poly[:1]))
    orient=1 if signed>0 else -1
    ds=[]
    for a,b in zip(poly,poly[1:]+poly[:1]):
        dx,dy=b[0]-a[0],b[1]-a[1]; length=math.hypot(dx,dy)
        ds.append(((-dy*(point[0]-a[0])+dx*(point[1]-a[1]))*orient)/length)
    hard=zone.get('hard_edges',[])
    if hard and min(ds)<=-1e-6:return 0.0
    external=[v for i,v in enumerate(ds) if i not in hard]
    value=max(0,min(1,min(external,default=1e6)/zone['feather']))
    return value*value*(3-2*value)

probes=[(x,y) for x,ys in [(1100,(90,100,150,170,180,190,200,210)),
                           (1000,(140,150,200,220,230,240,250,270)),
                           (900,(190,200,250,270,280,290,300,310))] for y in ys]
hits=[]
for px,py in probes:
    origin=pos+right*((px/1280-.5)*camera['ortho_scale'])+up*((.5-py/960)*camera['ortho_scale']*.75)
    direction=-back
    for _ in range(20):
        hit,loc,normal,face,obj,matrix=scene.ray_cast(graph,origin,direction)
        if not hit or not obj.hide_render:break
        origin=loc+direction*.002
    material=None; mesh_details={}
    if hit and obj.type=='MESH' and face>=0:
        evaluated=obj.evaluated_get(graph)
        index=evaluated.data.polygons[face].material_index
        material=obj.material_slots[index].material.name if obj.material_slots[index].material else None
        poly=evaluated.data.polygons[face]
        mesh_details=dict(face=face,smooth=poly.use_smooth,face_normal=list(poly.normal),
            corner_normals=[list(evaluated.data.corner_normals[i].vector) for i in poly.loop_indices],
            vertex_z=[round((obj.matrix_world@evaluated.data.vertices[i].co).z,7) for i in poly.vertices])
    values={z['name']:round(mask(z,loc),6) for z in zones} if hit else {}
    scope=max((values[z['name']] for z in zones if z['type']=='scope'),default=0)
    hits.append(dict(pixel=[px,py],object=obj.name if hit else None,material=material,
                     position=list(loc) if hit else None,normal=list(normal) if hit else None,
                     mesh_details=mesh_details,scope=scope,masks=values))
floors=[]
for o in scene.objects:
    if o.type!='MESH' or o.hide_render:continue
    points=[o.matrix_world@Vector(p) for p in o.bound_box]
    lo=[min(v[i] for v in points) for i in range(3)]; hi=[max(v[i] for v in points) for i in range(3)]
    if hi[0]<-3 or lo[0]>9 or hi[1]<-8 or lo[1]>1 or hi[2]>3 or hi[2]-lo[2]>2.5:continue
    if (hi[0]-lo[0])*(hi[1]-lo[1])<2:continue
    floors.append(dict(name=o.name,bounds=[lo,hi],hide_viewport=o.hide_viewport,hidden_eye=o.hide_get(),
                       visible=o.visible_get(),materials=[s.material.name if s.material else None for s in o.material_slots],
                       collections=[dict(name=c.name,hide_render=c.hide_render,hide_viewport=c.hide_viewport) for c in o.users_collection]))
(OUT/'seam-probe-normals.json').write_text(json.dumps(dict(camera=camera,hits=hits,floor_candidates=floors),ensure_ascii=False,indent=2),encoding='utf-8')
for h in hits:print(json.dumps({k:v for k,v in h.items() if k not in ('masks','mesh_details')},ensure_ascii=False),flush=True)
print('FLOOR CANDIDATES',json.dumps(floors,ensure_ascii=False),flush=True)
