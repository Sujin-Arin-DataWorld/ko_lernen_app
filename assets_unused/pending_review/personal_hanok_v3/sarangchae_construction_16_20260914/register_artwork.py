"""Inventory unchanged generated PNGs and diagnose retained stonework alignment.

Reads image pixels for analysis only. Never edits, resizes or re-encodes artwork.
The numeric diagnostic is not a geometry, joinery or historical certification.
"""
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.signal import correlate

HERE=Path(__file__).resolve().parent
REPO=HERE.parents[3]
MASTER=HERE.parent/'canonical/sarangchae/sarangchae-v3-canonical.png'
RUNTIME=REPO/'assets/illustrations/personal_hanok_v3/sarangchae'
EXPECTED='f917724120d4080d7c004b65dc51a9c336fcfbccdb9997e830de06ead1bcfc1a'
NAMES=['site','foundation','choseok','fitting','columns','beams','purlins','rafters','decking','earth_roof','tiles','walls','ondol','maru','changho','complete']
# Visible original masonry corners, not inferred 3D structural coordinates.
ANCHORS={'left_outer_footing':[173,716],'right_outer_footing':[1321,802],'left_stair_cheek':[588,870],'right_stair_cheek':[825,866],'left_base_corner':[119,855],'right_base_corner':[1440,846]}

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def gray(path):
    with Image.open(path) as im:return np.asarray(im.convert('L'),dtype=float)

def diagnose(image,source,anchors=ANCHORS):
    records=[];radius=20;search=18
    for name,(x,y) in anchors.items():
        template=source[y-radius:y+radius,x-radius:x+radius]
        area=image[y-radius-search:y+radius+search,x-radius-search:x+radius+search]
        centered=template-template.mean();count=template.size
        sums=correlate(area,np.ones(template.shape),mode='valid',method='fft')
        sums2=correlate(area*area,np.ones(template.shape),mode='valid',method='fft')
        numerator=correlate(area,centered,mode='valid',method='fft')
        denominator=np.sqrt(np.maximum(sums2-sums*sums/count,0)*np.sum(centered*centered))
        scores=np.divide(numerator,denominator,out=np.zeros_like(numerator),where=denominator>1e-9)
        yy,xx=np.unravel_index(np.argmax(scores),scores.shape)
        records.append({'region':name,'sourceCenter':[x,y],'bestOffsetPx':[int(xx-search),int(yy-search)],'correlation':round(float(scores[yy,xx]),3)})
    return records

assert sha(MASTER)==EXPECTED,'Approved source changed'
manifest=json.loads((HERE/'MANIFEST.json').read_text(encoding='utf-8'))
source=gray(MASTER);entries=[];index={}
for n,name in enumerate(NAMES,1):
    p=RUNTIME/f'stage_{n:02d}_{name}.png'
    assert p.is_file(),f'Approved runtime artwork missing: {p}'
    with Image.open(p) as im:size=list(im.size);mode=im.mode
    assert size==[1536,1024],f'Wrong canvas: {p.name}: {size}'
    digest=sha(p)
    if n==16:assert digest==EXPECTED,'Stage 16 must be byte-identical'
    else:assert digest!=EXPECTED,f'Completed source incorrectly used at {n}'
    entry={'stage':n,'file':p.name,'runtimeAsset':p.relative_to(REPO).as_posix(),'sha256':digest,'bytes':p.stat().st_size,'size':size,'mode':mode,'status':'approved_runtime'}
    if n>=2:
        anchors=ANCHORS if n>=5 else {k:v for k,v in ANCHORS.items() if 'footing' not in k}
        entry['stoneworkAlignmentDiagnostic']=diagnose(gray(p),source,anchors)
    entries.append(entry)
    if n<16:index[n]={'src':'../../../'+p.relative_to(REPO).as_posix(),'sha256':digest}
manifest['stages']=entries
manifest['status']='approved_runtime_sequence'
manifest['runtimePromoted']=True
manifest['generatedIntermediateCount']=len(index)
manifest['diagnosticScope']='Local normalized grayscale patch correlation in retained masonry only. Column/background appearance changes make texture correlation unsuitable for asserting column position. Column and roof contacts are visually reviewed; the masonry diagnostic does not certify them or historical accuracy.'
(HERE/'MANIFEST.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
destination=REPO/'docs/mockups/sarangchae-16/artwork-index.js'
destination.write_text("'use strict';\nconst HANOK_ARTWORKS="+json.dumps(index,ensure_ascii=False,indent=2)+';\n',encoding='utf-8')
print(json.dumps({'status':manifest['status'],'intermediateCount':len(index),'finalSha256':EXPECTED,'files':[x['file'] for x in entries]},indent=2))
