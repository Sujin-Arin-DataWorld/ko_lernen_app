"""Import approved independent Figma artwork, preserving source bytes.

This creates geometry constants, never rasterizes a screen or edits an image.
Run with the approved delivery directory as the sole argument.
"""
import hashlib
import json
from pathlib import Path
import shutil
import sys

root = Path(__file__).resolve().parents[1]
source = Path(sys.argv[1]).resolve()
manifest = json.loads((source / 'DELIVERY_MANIFEST.json').read_text(encoding='utf-8'))
components = json.loads((source / 'FIGMA_COMPONENTS_FINAL.json').read_text(encoding='utf-8'))
geometry = json.loads((source / 'FIGMA_GEOMETRY_FINAL.json').read_text(encoding='utf-8'))
dest = root / 'assets/illustrations/approved_games'
dest.mkdir(parents=True, exist_ok=True)
hashes = {}
for asset in manifest['assets']:
    if not asset['usedInFinalScreens']:
        continue
    src = Path(asset['path'])
    assert hashlib.sha256(src.read_bytes()).hexdigest() == asset['sha256'], src
    shutil.copyfile(src, dest / (asset['key'] + '.png'))
    hashes[asset['figmaImageHash']] = asset['key']

names = {'274:2':'quizChoice','274:13':'pairNeutral','274:24':'pairSelected',
         '274:36':'pairMatched','274:49':'jadeControl','274:60':'folio','286:723':'counter'}
def number(n):
    return f'{n:.9f}'.rstrip('0').rstrip('.') + ('.0' if float(n).is_integer() else '')
def rect(x,y,w,h):
    return 'Rect.fromLTWH(' + ', '.join(number(n) for n in (x,y,w,h)) + ')'
def crop(fill):
    m = fill['imageTransform']
    return rect(m[0][2],m[1][2],m[0][0],m[1][1])
lines = ["// Generated from approved Figma components. Do not hand-tune crop coordinates.",
         "part of 'approved_game_material.dart';", 'const _materials = <String, _MaterialSpec>{']
for comp in components:
    if comp['id'] not in names:
        continue
    nodes = {n['id']:n for n in comp['nodes']}
    base = comp['nodes'][0]
    lines.append(f"  '{names[comp['id']]}': _MaterialSpec(Size({number(base['w'])}, {number(base['h'])}), [")
    for n in comp['nodes'][1:]:
        for f in n.get('fills',[]):
            if f['type'] != 'IMAGE' or not f.get('visible', True):
                continue
            x,y=n['x'],n['y']; parent=nodes[n['parent']]
            while parent['id'] != comp['id']:
                x+=parent['x']; y+=parent['y']; parent=nodes[parent['parent']]
            h=n['constraints']['horizontal'];v=n['constraints']['vertical']
            lines.append(f"    _ArtSlice('{hashes[f['imageHash']]}', {crop(f)}, {rect(x,y,n['w'],n['h'])}, '{h}', '{v}'),")
    lines.append('  ]),')
lines.append('};')
lines.append('const _sourceCrops = <String, Rect>{')
found={}
def walk(n):
    for f in n.get('fills',[]):
        if f['type']=='IMAGE' and f.get('scaleMode')=='CROP':
            key=hashes.get(f['imageHash'])
            if key and '/' not in n.get('name','').replace('Art / ',''):
                found.setdefault(key,crop(f))
    for c in n.get('children',[]): walk(c)
for frame in geometry['frames']: walk(frame['frame'])
for key, value in found.items(): lines.append(f"  '{key}': {value},")
lines.append('};')
out=root/'lib/widgets/sori/approved_games/approved_game_material_data.dart'
out.parent.mkdir(parents=True,exist_ok=True)
out.write_text('\n'.join(lines)+'\n',encoding='utf-8')
evidence=root/'docs/design/approved_quiz_matching_20261104'
evidence.mkdir(parents=True,exist_ok=True)
for name in ['APPROVAL_20261104.json','FIGMA_GEOMETRY_FINAL.json','FIGMA_COMPONENTS_FINAL.json','FLUTTER_HANDOFF.md']:
    shutil.copyfile(source/name,evidence/name)
for asset in manifest['assets']:
    if asset['usedInFinalScreens']:
        asset['runtimePath']='assets/illustrations/approved_games/'+asset['key']+'.png'
(evidence/'ASSET_PROVENANCE.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(f'Imported {len(hashes)} verified independent artwork files and {len(names)} material definitions.')
