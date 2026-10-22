import bpy,json
from pathlib import Path
p=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(p.parent/'lookdev-sarang-r3'/'sarang-r3-fix-checkpoint.blend'))
for name in ['Projection.Numaru floor bearer','Craft.Numaru continuous post 12.56']:
 o=bpy.data.objects[name];uv=o.data.uv_layers['Gye cared member grain v52'];faces=sorted(o.data.polygons,key=lambda f:f.area,reverse=True)[:3]
 print(name,json.dumps([dict(area=f.area,uv=[list(uv.data[i].uv) for i in f.loop_indices],world=[list(o.matrix_world@o.data.vertices[o.data.loops[i].vertex_index].co) for i in f.loop_indices]) for f in faces]))
