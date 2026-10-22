import bpy,json,struct,hashlib,sys
from pathlib import Path
OUT=Path(__file__).resolve().parent;PACKAGE=OUT.parent;ROOT=PACKAGE.parent
catalog=json.loads((PACKAGE/'catalog.json').read_text(encoding='utf-8'))
owners=json.loads((ROOT/'construction/contracts/r12-owner-map.json').read_text(encoding='utf-8'))
groups={g['nativeOwner']:g['sourceObjects'] for g in owners['groups']}
def names_for(b):
 if b['newGate']:
  gate={'left_changgo':'left','right_ansarang':'right','sadangmun':'shrine'}[b['key']]
  return list(json.loads((ROOT/'construction'/f'{gate}-object-stage-map.json').read_text(encoding='utf-8'))['assignments'])
 return groups[b['key']]
results=[]
for b in catalog['buildings']:
 if b['key'] in ['sarang','estate-context']:continue
 bpy.ops.wm.read_factory_settings(use_empty=True)
 native=(PACKAGE/b['native']).resolve();names=names_for(b)
 with bpy.data.libraries.load(str(native),link=False) as (src,dst):
  assert set(names)<=set(src.objects),b['key'];dst.objects=list(names)
 obs=[o for o in dst.objects if o]
 mats={s.material.name:s.material for o in obs for s in o.material_slots if s.material}
 material=[]
 for name,m in mats.items():
  t=m.node_tree
  material.append(dict(name=name,bsdf=[dict(baseLinked=n.inputs['Base Color'].is_linked,base=list(n.inputs['Base Color'].default_value),source=n.inputs['Base Color'].links[0].from_node.name if n.inputs['Base Color'].is_linked else None) for n in t.nodes if n.type=='BSDF_PRINCIPLED'] if t else [],
   images=[dict(node=n.name,label=n.label,image=n.image.name if n.image else None,uv=n.inputs['Vector'].links[0].from_node.name if n.inputs['Vector'].is_linked else None) for n in t.nodes if n.type=='TEX_IMAGE'] if t else [],
   pigments=[dict(name=n.name,label=n.label,color=list(n.outputs[0].default_value)) for n in t.nodes if n.type=='RGB'] if t else [],
   ramps=[dict(name=n.name,label=n.label,colors=[list(e.color) for e in n.color_ramp.elements]) for n in t.nodes if n.type=='VALTORGB'] if t else []))
 entry=dict(key=b['key'],name=b['name'],native=str(native),sha256=hashlib.file_digest(native.open('rb'),'sha256').hexdigest(),count=len(obs),materials=material,
  uvs=sorted({uv.name for o in obs for uv in o.data.uv_layers}),parents=[o.name for o in obs if o.parent],names=names)
 results.append(entry)
 (OUT/'source-audit.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
 print('AUDIT',b['key'],len(obs),len(mats),entry['uvs'],flush=True)
(OUT/'source-audit.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
print('AUDIT COMPLETE',len(results),flush=True)
