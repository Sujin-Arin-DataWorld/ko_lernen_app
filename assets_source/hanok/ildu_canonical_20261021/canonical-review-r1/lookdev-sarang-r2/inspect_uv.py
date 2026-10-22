import bpy,json
from pathlib import Path
out=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(out.parent/'lookdev-sarang-r1/sarang-lookdev-candidate.blend'))
for name in ['Craft.Numaru continuous post 10.575','Sarang.room front post.wood','Sarang.main roof','V25.stair tread 3','Continuity.numaru corner posts']:
    ob=bpy.data.objects.get(name)
    if not ob:continue
    print('OBJECT',name)
    for uv in ob.data.uv_layers:
        print('UV',uv.name,[list(x.uv) for x in uv.data[:8]])
    for a in ob.data.attributes:
        if a.name in ['P18 surface UV','P18 long timber UV','P18 long timber sample','P18 image eligible','P18 real cut face']:
            print('ATTR',a.name,[list(v.vector) if hasattr(v,'vector') else v.value for v in a.data[:8]])
    for mat in {s.material for s in ob.material_slots if s.material}:
        for n in mat.node_tree.nodes:
            if n.type=='VALTORGB':print('RAMP',mat.name,[(e.position,list(e.color)) for e in n.color_ramp.elements])
        break
