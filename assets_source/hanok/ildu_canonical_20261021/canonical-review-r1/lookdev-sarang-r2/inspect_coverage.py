import bpy,json,importlib.util
from pathlib import Path
out=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('tools',out.parent/'lookdev-sarang-r1/render_lookdev.py')
s=importlib.util.module_from_spec(spec);spec.loader.exec_module(s)
bpy.ops.wm.open_mainfile(filepath=str(out.parent/'lookdev-sarang-r1/sarang-lookdev-candidate.blend'))
counts={}
for ob in bpy.context.scene.objects:
    if ob.type!='MESH':continue
    for sl in ob.material_slots:
        m=sl.material
        if m and not s.role(m):counts.setdefault(m.name,[]).append(ob.name)
print(json.dumps({k:dict(count=len(v),examples=v[:3]) for k,v in counts.items()},ensure_ascii=False,indent=2))
