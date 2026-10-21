"""Final soil-only revision after close rendered review found the first too smooth."""
import bpy,sys,json
from pathlib import Path
OUT=Path(__file__).resolve().parent
sys.path.insert(0,str(OUT))
from audit_source import SOURCE,EXPECTED,state,bindings,write,sha
from build_surfaces import ground

manifest=json.loads((OUT/'manifest.json').read_text(encoding='utf-8'))
changes=json.loads((OUT/'material-changes.json').read_text(encoding='utf-8'))
targets=[r for r in changes if r['role'] in ('yard','garden')]
missing=sorted({r['old'] for r in targets if r['old'] not in bpy.data.materials})
if missing:
    with bpy.data.libraries.load(str(SOURCE),link=False) as (src,dst):dst.materials=missing
cache={}
for r in targets:
    if r['new'] not in cache:
        old=bpy.data.materials[r['new']];new=ground(bpy.data.materials[r['old']],r['role']);cache[r['new']]=(old,new)
    bpy.data.objects[r['object']].material_slots[r['slot']].material=cache[r['new']][1]
for name,(old,new) in cache.items():
    assert old.users==0;(bpy.data.materials.remove(old));new.name=name
before=json.loads((OUT/'geometry-before.json').read_text(encoding='utf-8'))
after=json.loads(json.dumps(state()));assert before==after;write('geometry-after.json',after)
assert json.loads(json.dumps(bindings()))==json.loads((OUT/'bindings-after.json').read_text(encoding='utf-8'))
assert sha(SOURCE)==EXPECTED
bpy.context.preferences.filepaths.save_version=1
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'ildu-estate-yard-wall-r1.blend'),compress=True)
manifest.update(status='soil-refined-native-candidate-awaiting-render-review',soil_pilot_candidate_sha256=manifest['candidate_sha256'],candidate_sha256=sha(OUT/'ildu-estate-yard-wall-r1.blend'),soil_correction='30-50cm restrained loam variation, 1.6mm effective normal, subtle source stone-route consolidation')
write('manifest.json',manifest);print('SOIL REFINED',manifest['candidate_sha256'],flush=True)
