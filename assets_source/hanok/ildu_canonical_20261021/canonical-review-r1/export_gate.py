"""Read only source gates, export exact evaluated shape with explicit stage extras."""
import bpy,hashlib,json,sys,time
from pathlib import Path
OUT=Path(__file__).resolve().parent;ROOT=OUT.parent
gate=sys.argv[sys.argv.index('--')+1]
key={'left':'left_changgo','right':'right_ansarang','shrine':'sadangmun'}[gate]
mapping=json.loads((ROOT/'construction'/f'{gate}-object-stage-map.json').read_text(encoding='utf-8'))['assignments']
assert set(mapping)<=set(bpy.data.objects.keys())
# Isolate the exact 680/530/445 authored objects. Presentation floor, lights, cameras excluded.
scene=bpy.data.scenes.new('Structure review '+gate);bpy.context.window.scene=scene
for name,sequence in mapping.items():
 o=bpy.data.objects[name];scene.collection.objects.link(o);o['reviewStage']=sequence;o['sourceObject']=name;o['reviewOnly']=True
 o.hide_set(False);o.hide_viewport=False;o.hide_render=False
bpy.context.view_layer.update()
for o in scene.objects:o.select_set(True)
path=OUT/'models'/(key+'.glb');path.parent.mkdir(exist_ok=True)
bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_extras=True,export_materials='NONE',export_animations=False,export_cameras=False,export_lights=False,export_apply=True)
with path.open('rb') as f:h=hashlib.file_digest(f,'sha256').hexdigest()
native=ROOT/(gate+'-new.blend')
with native.open('rb') as f:n=hashlib.file_digest(f,'sha256').hexdigest()
record=dict(gate=gate,key=key,sourceNativeSha256=n,objectCount=len(mapping),model=path.name,sha256=h,bytes=path.stat().st_size,sourceNativeSaved=False,materials='neutral structural preview; native shaders untouched',geometry='exact evaluated source, no decimation or scale')
(OUT/(gate+'-export.json')).write_text(json.dumps(record,indent=2),encoding='utf-8')
print('GATE EXPORT COMPLETE',record,flush=True)

