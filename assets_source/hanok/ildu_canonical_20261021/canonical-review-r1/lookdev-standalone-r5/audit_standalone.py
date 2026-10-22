import bpy,json,struct,hashlib
from pathlib import Path
OUT=Path(__file__).resolve().parent;PACKAGE=OUT.parent;ROOT=PACKAGE.parent
NATIVE=ROOT/'estate-yard-wall-r1/ildu-estate-yard-wall-r1.blend'
def sha(p):
 with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def glb_names(key):
 with (PACKAGE/'models'/f'{key}-standalone.glb').open('rb') as f:
  f.read(12);n,_=struct.unpack('<II',f.read(8));doc=json.loads(f.read(n))
 return {n['extras']['sourceObject']:n['extras'] for n in doc['nodes'] if 'reviewStage' in n.get('extras',{})}
results=[]
for key in ['sarang','jung']:
 bpy.ops.wm.read_factory_settings(use_empty=True);names=glb_names(key)
 with bpy.data.libraries.load(str(NATIVE),link=False) as (src,dst):dst.objects=list(names)
 scene=bpy.context.scene
 for o in dst.objects:scene.collection.objects.link(o)
 bpy.context.view_layer.update();obs=[bpy.data.objects[n] for n in names]
 mats={sl.material.name:sl.material for o in obs for sl in o.material_slots if sl.material}
 materials=[]
 for name,m in mats.items():
  t=m.node_tree
  materials.append(dict(name=name,images=[dict(image=n.image.name if n.image else None,label=n.label) for n in t.nodes if n.type=='TEX_IMAGE'],
    ramps=[dict(name=n.name,label=n.label,colors=[list(e.color) for e in n.color_ramp.elements]) for n in t.nodes if n.type=='VALTORGB']))
 entry=dict(key=key+'-standalone',basekey=key,name={'sarang':'사랑채 · 독립형','jung':'중문간채 · 독립형'}[key],native=str(NATIVE),sha256=sha(NATIVE),count=len(obs),names=list(names),assignments=names,materials=materials,
  objects={o.name:dict(props={k:str(o[k]) for k in o.keys()},uvs=[v.name for v in o.data.uv_layers],materials=[sl.material.name if sl.material else None for sl in o.material_slots],parent=o.parent.name if o.parent else None) for o in obs})
 results.append(entry)
 (OUT/'source-audit.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
 print('AUDITED',key,len(obs),len(mats),flush=True)
 print('SAMPLES',json.dumps([(o.name,entry['objects'][o.name]) for o in obs[:3]],ensure_ascii=False),flush=True)
print('COMPLETE',flush=True)
