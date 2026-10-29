import bpy,json
from pathlib import Path
p=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(p/'sarang/sarang-hangulsori-r2.blend'))
s=bpy.context.scene
data={'cameraClip':[s.camera.data.clip_start,s.camera.data.clip_end],'compositor':[],'floor':[],'whiteCaps':[],'papers':[]}
g=s.compositing_node_group
if g:
 data['compositor']=[dict(name=n.name,type=n.type,scene=n.scene.name if n.type=='R_LAYERS' and n.scene else '',inputs={i.name:str(i.default_value) for i in n.inputs if hasattr(i,'default_value')}) for n in g.nodes]
for o in s.objects:
 if o.type!='MESH':continue
 if o.get('displayOnly'):data['floor'].append(dict(name=o.name,scale=list(o.scale),loc=list(o.location),dim=list(o.dimensions)))
 if any(x in o.name.lower() for x in ['white','baekto','tile end','lime']):data['whiteCaps'].append(o.name)
 if any(sl.material and sl.material.get('hs2_role')=='paper' for sl in o.material_slots):
  data['papers'].append(dict(name=o.name,bounds=[list(o.matrix_world@__import__('mathutils').Vector(v)) for v in o.bound_box]))
(p/'inspect-result.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8');print(data['cameraClip'],data['compositor'],len(data['papers']),data['whiteCaps'],flush=True)
