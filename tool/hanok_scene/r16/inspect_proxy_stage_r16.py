import bpy,json,sys
from pathlib import Path
P=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(P/'sarang-wood-r16/sarang-wood-r16.blend'))
names=set(json.loads((P/'sarang/geometry-lock.json').read_text())['objects'])
rows=[]
for ob in bpy.context.scene.objects:
 if ob.type!='MESH' or ob.name in names or 'display ground' in ob.name.lower():continue
 props={k:(list(v) if hasattr(v,'to_list') else v) for k,v in ob.items()}
 rows.append(dict(name=ob.name,parent=ob.parent.name if ob.parent else None,hidden=ob.hide_render,props=props))
(P/'proxy-stage-state-r16.json').write_text(json.dumps(rows,indent=2,default=str))
print('extraMeshes',len(rows));print(json.dumps(rows[:3]+[r for r in rows if not r['props'].get('construction_parent')],indent=2,default=str)[:11000])
