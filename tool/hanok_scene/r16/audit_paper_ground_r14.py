import bpy,json,sys
from pathlib import Path
P=Path(__file__).resolve().parent
sys.path.insert(0,str(P))
import warmth_material_r12 as w
bpy.ops.wm.open_mainfile(filepath=str(P/'sarang-palette-r13/sarang-palette-r13.blend'))
sc=bpy.context.scene
rows=[]
for o in sc.objects:
 for i,s in enumerate(o.material_slots):
  m=s.material
  if not m or not m.use_nodes:continue
  role=m.get('warmth_role') or m.get('referenceColourProfile')
  if role not in ('paper','ground') and 'ondol floor' not in o.name:continue
  rows.append(dict(object=o.name,hidden=o.hide_render,slot=i,material=m.name,role=role,props=dict(m.items()),shader=w._describe(m),meshSources=[x.name if x else None for x in o.data.materials]))
report=dict(rows=rows,lights=[dict(name=o.name,power=o.data.energy,color=list(o.data.color)) for o in sc.objects if o.type=='LIGHT'],view=dict(transform=sc.view_settings.view_transform,look=sc.view_settings.look,exposure=sc.view_settings.exposure))
(P/'paper-ground-source-audit-r14.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))

