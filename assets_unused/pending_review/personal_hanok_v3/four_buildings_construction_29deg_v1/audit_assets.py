"""Audit generated construction assets without changing image pixels."""
from pathlib import Path
import json, hashlib
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parent
catalog=json.loads((ROOT/'construction_catalog.json').read_text(encoding='utf-8'))
rois={'jungmunganchae':(90,710,1450,800),'araechae':(165,853,1360,895),'anchae':(15,755,1510,810),'anchae-store':(110,744,1400,797)}
rows=[]
for building in catalog['buildings']:
    master_file=ROOT/building['steps'][-1]['file']
    master=np.asarray(Image.open(master_file).convert('L'),dtype=float) if master_file.exists() else None
    roi=rois[building['id']]
    for stage in building['steps']:
        p=ROOT/stage['file']
        row={'buildingId':building['id'],'stageId':stage['id'],'sequence':stage['number'],'path':stage['file'],'exists':p.exists()}
        if p.exists():
            blob=p.read_bytes()
            with Image.open(p) as im:
                im.load()
                row.update(bytes=len(blob),sha256=hashlib.sha256(blob).hexdigest(),size=list(im.size),mode=im.mode,format=im.format)
                rgb=np.asarray(im.convert('RGB'))
                foreground=np.min(rgb,axis=2)<220
                yy,xx=np.where(foreground)
                row['nonwhiteBBox']=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)] if len(xx) else None
                row['promptExists']=p.with_suffix('.prompt.txt').exists()
                row['technicalPass']=im.size==(1536,1024) and im.format=='PNG' and row['promptExists']
                if master is not None and stage['number']>=2:
                    a=master[roi[1]:roi[3]:2,roi[0]:roi[2]:2]
                    g=np.asarray(im.convert('L'),dtype=float)
                    aa=a-a.mean();dena=np.sqrt((aa*aa).sum())
                    best=(-2,None,None)
                    for dy in range(-12,13,2):
                        for dx in range(-12,13,2):
                            b=g[roi[1]+dy:roi[3]+dy:2,roi[0]+dx:roi[2]+dx:2]
                            if b.shape!=a.shape:continue
                            bb=b-b.mean()
                            score=float((aa*bb).sum()/max(1e-9,dena*np.sqrt((bb*bb).sum())))
                            if score>best[0]:best=(score,dx,dy)
                    row['foundationPatchComparison']={'ncc':round(best[0],4),'dx':best[1],'dy':best[2],'roi':roi,'meaning':'texture-registration indicator only; not proof of joinery or camera angle'}
        rows.append(row)
unique={r.get('sha256') for r in rows if r.get('exists')}
report={'expected':sum(len(b['steps']) for b in catalog['buildings']),'present':sum(r['exists'] for r in rows),'technicalPass':sum(r.get('technicalPass',False) for r in rows),'uniquePngCount':len(unique),'totalBytes':sum(r.get('bytes',0) for r in rows),'cameraStatus':'29 degrees specified in prompts; no calibrated 3D camera or geometry proof','runtimePromotion':False,'images':rows}
(ROOT/'asset_audit.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k!='images'},ensure_ascii=False))
print('Registration flags:',json.dumps([{'path':r['path'],**r['foundationPatchComparison']} for r in rows if 'foundationPatchComparison' in r and (abs(r['foundationPatchComparison']['dx'])>4 or abs(r['foundationPatchComparison']['dy'])>4 or r['foundationPatchComparison']['ncc']<.6)],ensure_ascii=False))
