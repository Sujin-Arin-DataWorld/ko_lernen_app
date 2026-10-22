import bpy,json,hashlib
from pathlib import Path
from mathutils import Vector
out=Path(__file__).resolve().parent
src=out.parent/'lookdev-sarang-r2/sarang-handpaint-candidate.blend'
assert hashlib.sha256(src.read_bytes()).hexdigest()=='7f04ba42cc0431ef7789e9ab28c514da4f1f464988779fa30ca3d5c6b40a3e36'
bpy.ops.wm.open_mainfile(filepath=str(src))
bpy.context.view_layer.update()
rows=[]
for ob in bpy.context.scene.objects:
    if ob.type!='MESH' or not any(k in ob.name.lower() for k in ['left horizontal boarding','left boarding continuous','left boarding end']):continue
    bb=[ob.matrix_world@Vector(v) for v in ob.bound_box]
    rows.append(dict(name=ob.name,visible=not ob.hide_render,materials=[s.material.name if s.material else None for s in ob.material_slots],min=[min(v[i] for v in bb) for i in range(3)],max=[max(v[i] for v in bb) for i in range(3)]))
deps=bpy.context.evaluated_depsgraph_get()
rays=[]
for z in [1.1+i*.01 for i in range(91)]:
    hit,loc,norm,index,ob,matrix=bpy.context.scene.ray_cast(deps,Vector((1,-15,z)),Vector((0,1,0)))
    if hit:
        ev=ob.evaluated_get(deps);mi=ev.data.polygons[index].material_index if index<len(ev.data.polygons) else -1
        material=ob.material_slots[mi].material.name if mi>=0 else None
        rays.append(dict(z=round(z,3),y=round(loc.y,5),object=ob.name,material=material))
    else:rays.append(dict(z=round(z,3),object=None))
report=dict(boards=rows,rays=rays)
(out/'problem-audit.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(rows,ensure_ascii=False,indent=2))
last=None
for row in rays:
    current=(row.get('object'),row.get('material'))
    if current!=last:print('RAY TRANSITION',row);last=current
