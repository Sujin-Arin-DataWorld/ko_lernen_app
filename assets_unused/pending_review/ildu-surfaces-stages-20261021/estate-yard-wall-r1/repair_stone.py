"""Preserve source stone pigment while retaining the new physical response."""
import bpy,sys,json
from pathlib import Path
OUT=Path(__file__).resolve().parent
sys.path.insert(0,str(OUT))
from audit_source import SOURCE,EXPECTED,state,bindings,write,sha
from build_surfaces import wall

manifest=json.loads((OUT/'manifest.json').read_text(encoding='utf-8'))
changes=json.loads((OUT/'material-changes.json').read_text(encoding='utf-8'))
stones=[r for r in changes if r['role']=='stone']
missing=sorted({r['old'] for r in stones if r['old'] not in bpy.data.materials})
if missing:
    with bpy.data.libraries.load(str(SOURCE),link=False) as (src,dst):dst.materials=missing
cache={}
for r in stones:
    if r['new'] not in cache:
        old=bpy.data.materials[r['new']]
        new=wall(bpy.data.materials[r['old']],'stone')
        cache[r['new']]=(old,new)
    bpy.data.objects[r['object']].material_slots[r['slot']].material=cache[r['new']][1]
for name,(old,new) in cache.items():
    assert old.users==0,(name,old.users)
    bpy.data.materials.remove(old);new.name=name
before=json.loads((OUT/'geometry-before.json').read_text(encoding='utf-8'))
after=json.loads(json.dumps(state()));assert before==after
write('geometry-after.json',after)
actual=json.loads(json.dumps(bindings()))
expected=json.loads((OUT/'bindings-after.json').read_text(encoding='utf-8'));assert actual==expected
assert sha(SOURCE)==EXPECTED
bpy.context.preferences.filepaths.save_version=1
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'ildu-estate-yard-wall-r1.blend'),compress=True)
manifest.update(status='stone-corrected-native-candidate-awaiting-render-review',candidate_sha256=sha(OUT/'ildu-estate-yard-wall-r1.blend'),stone_correction='source pigment and stone identities restored; roughness and shallow bump retained',initial_rejected_candidate_sha256=manifest['candidate_sha256'])
write('manifest.json',manifest)
print('STONE CORRECTED',manifest['candidate_sha256'],len(stones),'slots',flush=True)
