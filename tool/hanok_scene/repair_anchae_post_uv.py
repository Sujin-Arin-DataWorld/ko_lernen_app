"""Correct square-post semantic artwork selection on the saved candidate."""
from pathlib import Path
import sys,json,hashlib,bpy
sys.path.insert(0,str(Path(__file__).parent))
import canonical_surface_reuse as surface
from repair_masonry_coping import fingerprint,OUT
path=OUT/'detail-redraw.blend';before=hashlib.sha256(path.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(path));s=bpy.context.scene
c=json.loads((OUT/'detail-redraw-contract.json').read_text(encoding='utf8'))
selected=[o for o in s.objects if o.type=='MESH' and o.get('construction_building')=='anchae' and any(k in o.name.lower() for k in ('column','post'))]
protected={o.name:fingerprint(o) for o in s.objects if o.type=='MESH' and o not in selected}
src=surface.MAP['anchae'];surface.ART=src['path'];surface.base_image=bpy.data.images.load(str(src['path']),check_existing=True);surface.materials={};surface.regions=src['regions'];surface.mapped=[]
for o in selected:
    surface.art_uv(o,'post');o.data.materials[0].name='Reference anchae post corrected';o['canonicalSurfaceKind']='post'
assert all(fingerprint(bpy.data.objects[n])==fp for n,fp in protected.items())
manifest=json.loads((OUT/'atlas-part-map.json').read_text(encoding='utf8'))
for r in manifest['sources']:
    if r['building']=='anchae':r['regionsNormalizedXY']['post']=src['regions']['post']
names={o.name for o in selected};manifest['mapped']=[r for r in manifest['mapped'] if r['object'] not in names]+surface.mapped
(OUT/'atlas-part-map.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8');c['canonicalSurfaceReuse']=manifest
bpy.ops.wm.save_as_mainfile(filepath=str(path),compress=True)
c['postSurfaceCorrection']={'previousSceneSha256':before,'correctedSceneSha256':hashlib.sha256(path.read_bytes()).hexdigest(),'changedObjects':sorted(names),'unchangedMeshCount':len(protected),'unchangedMeshFingerprintSha256':hashlib.sha256(json.dumps(protected,sort_keys=True).encode()).hexdigest(),'changedBuilding':'anchae','sourceRegion':src['regions']['post']}
(OUT/'detail-redraw-contract.json').write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf8')
print('ANchae POST UV CORRECTED',len(names),flush=True)
