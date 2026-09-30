from pathlib import Path
import bpy,json
root=Path(__file__).resolve().parents[2];out=root/'assets_unused/pending_review/hwalju-blueprint-review/side-connections'
bpy.ops.wm.open_mainfile(filepath=str(out/'scene.blend'))
rows=[]
for o in bpy.context.scene.objects:
 if o.type=='MESH' and o.get('construction_building') in ('left_changgo','right_ansarang'):
  rows.append({'name':o.name,'material':[m.name for m in o.data.materials],'uv':[u.name for u in o.data.uv_layers],'verts':len(o.data.vertices),'faces':len(o.data.polygons),'bounds':[list(c) for c in o.bound_box]})
(out/'gate-parts.json').write_text(json.dumps(rows,indent=2))
print('INSPECTION',len(rows))
