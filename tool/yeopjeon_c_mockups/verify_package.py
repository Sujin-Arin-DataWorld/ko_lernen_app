"""Verify preview assets and provenance without modifying source media."""
from pathlib import Path
from html.parser import HTMLParser
import argparse
import hashlib
import json
import re

ROOT=Path(__file__).resolve().parent
def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()
class References(HTMLParser):
    def __init__(self):
        super().__init__();self.paths=[]
    def handle_starttag(self,tag,attrs):
        self.paths.extend(v for k,v in attrs if k in ('src','href') and v)
def verify():
    errors=[]
    rows=json.loads((ROOT/'asset-provenance.json').read_text(encoding='utf-8'))
    for row in rows:
        p=(ROOT/row['file']).resolve()
        if not p.is_relative_to(ROOT) or not p.is_file() or sha(p)!=row['sha256']:
            errors.append('Asset provenance mismatch: '+row['file'])
    active=['index.html','refined.html','refined-tokens.css','refined.css','refined.js','approved-reference.html','media.html']
    for name in active:
        p=ROOT/name
        if not p.is_file():
            errors.append('Missing active file: '+name);continue
        data=p.read_text(encoding='utf-8');refs=[]
        if name.endswith('.html'):
            parser=References();parser.feed(data);refs.extend(parser.paths)
        refs.extend(re.findall(r'''url\(['"]?([^'"\)]+)['"]?\)''',data))
        if name=='refined.js':
            refs.extend(re.findall(r'''(?:src|href)=["']([^"']+)["']''',data))
        for ref in refs:
            if '${' in ref or ref.startswith(('#','http:','https:','data:')):
                continue
            path=ref.split('?')[0].split('#')[0]
            if path and not (p.parent/path).is_file():
                errors.append('Broken reference: '+name+' -> '+ref)
    data='\n'.join((ROOT/name).read_text(encoding='utf-8') for name in active[:5])
    for forbidden in ['design/secret-board.png','design/ab-board.png','stage_07.png','stage_08.png','stage_16.png','making_money.mp4']:
        if forbidden in data:
            errors.append('Rejected/opaque/future media connected: '+forbidden)
    if 'making_money_alpha.webm' not in data:
        errors.append('Alpha video not connected')
    for name in ['DESIGN_CRITIQUE.md','FLOW_AND_HANDOFF.md','AUDIT.md','QA.md','README.md','review-proof/proof-refined-pair.jpg']:
        if not (ROOT/name).is_file():
            errors.append('Missing deliverable: '+name)
    video=json.loads((ROOT/'media-review/video-alpha-report.json').read_text(encoding='utf-8'))
    if sha(ROOT/'assets/making_money.mp4')!=video['sourceSha256'] or sha(ROOT/'assets/making_money_alpha.webm')!=video['outputSha256']:
        errors.append('Video/report hash mismatch')
    if video.get('preEncodeRgbMaxDelta') != 0 or video.get('edgeRgbCorrection') is not False:
        errors.append('Matte must preserve original RGB and modify alpha only')
    native=json.loads((ROOT/'media-review/flutter-media-report.json').read_text(encoding='utf-8'))
    if native.get('visibleRgbMaxDeltaAll121Frames') != 0:
        errors.append('Native movie visible RGB differs from original')
    return rows,errors
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--write-manifest',action='store_true');args=parser.parse_args()
    rows,errors=verify()
    if not errors and args.write_manifest:
        records=[{'file':p.relative_to(ROOT).as_posix(),'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted(ROOT.rglob('*')) if p.is_file() and p.name!='PACKAGE_MANIFEST.json' and '__pycache__' not in p.parts and not ('server' in p.name and p.suffix=='.log')]
        (ROOT/'PACKAGE_MANIFEST.json').write_text(json.dumps({'schemaVersion':1,'previewEntry':'refined.html','reviewOnly':True,'files':records},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    if not errors and (ROOT/'PACKAGE_MANIFEST.json').exists() and not args.write_manifest:
        manifest=json.loads((ROOT/'PACKAGE_MANIFEST.json').read_text(encoding='utf-8'))
        for row in manifest['files']:
            p=ROOT/row['file']
            if not p.is_file() or sha(p)!=row['sha256']:
                errors.append('Package hash mismatch: '+row['file'])
    print(json.dumps({'ok':not errors,'provenanceAssets':len(rows),'errors':errors},ensure_ascii=False))
    raise SystemExit(1 if errors else 0)
