"""Fit rigid building placements to explicitly traced 002 column centres.

Pixel coordinates refer to the untouched 3284x2203 scan, not a resized view.
No mesh scaling: building dimensions remain on their individual measured plans.
"""
from pathlib import Path
import json,hashlib,math
import numpy as np
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'assets_unused/pending_review/hwalju-blueprint-review';OUT=BASE/'northern-court'
WORLD=np.array([[0,0,1],[10.575,0,1],[14.545,0,1],[0,5.205,1]],float)
PIXELS=np.array([[1421,1425],[1444,1214],[1453,1135],[1317,1413]],float)
M=np.linalg.lstsq(WORLD,PIXELS,rcond=None)[0]
def to_pixel(points):return np.c_[points,np.ones(len(points))]@M
def to_world(points):return (np.array(points)-M[2])@np.linalg.inv(M[:2])
def rotate(points,angle):
 r=np.array([[math.cos(angle),-math.sin(angle)],[math.sin(angle),math.cos(angle)]])
 return np.asarray(points)@r.T

def registration(c):
 records={r['id']:r for r in c['buildings']};x=np.r_[-9.0475,-9.0475+np.cumsum(records['anchae']['bays'])]
 traces={
 'anchae':{'local':[[float(a),-2.2625] for a in x]+[[float(x[i]),1.5375] for i in (0,1,4,8)],
  'pixels':[[890,1195],[919,1197],[971,1202],[1022,1205],[1073,1209],[1119,1210],[1169,1213],[1219,1215],[1246,1217],[891,1120],[922,1124],[1077,1131],[1248,1140]]},
 'arae':{'local':[[-3.75,-2],[3.75,-2],[3.75,2],[-3.75,2]],'pixels':[[920,1389],[920,1244],[846,1240],[837,1385]]},
 'angotgan':{'local':[[-4.68,-1.35],[4.68,-1.35],[4.68,1.35],[-4.68,1.35]],'pixels':[[1072,1437],[887,1437],[887,1490],[1071,1490]]},
 'gokgan':{'local':[[-4.875,-2.73],[4.875,-2.73],[4.875,2.73],[-4.875,2.73]],'pixels':[[1168,933],[1354,968],[1376,862],[1187,826]]},
 'sadang':{'local':[[-3.38,-2.1],[3.38,-2.1],[3.38,2.1],[-3.38,2.1]],'pixels':[[952,925],[1086,934],[1092,848],[960,842]]},
 'sadangmun':{'local':[[-.675,0],[.675,0]],'pixels':[[1125,1004],[1129,978]]}}
 report=[]
 for ident,trace in traces.items():
  rec=records[ident];local=np.array(trace['local']);target=to_world(trace['pixels']);lc=local.mean(0);tc=target.mean(0)
  a=local-lc;b=target-tc;angle=math.atan2(np.sum(a[:,0]*b[:,1]-a[:,1]*b[:,0]),np.sum(a*b))
  center=tc-rotate([lc],angle)[0];fitted=to_pixel(rotate(local,angle)+center)
  before=to_pixel(rotate(local,rec['angle'])+rec['center']);dist=np.linalg.norm(fitted-np.array(trace['pixels']),axis=1)
  report.append({'id':ident,'beforeCenter':rec['center'],'beforeAngle':rec['angle'],'center':center.tolist(),'angle':angle,
   'localColumnAnchors':trace['local'],'sourcePixelAnchors':trace['pixels'],'fittedPixelAnchors':fitted.tolist(),
   'rmsBeforePixels':float(np.sqrt(np.mean(np.sum((before-np.array(trace['pixels']))**2,axis=1)))),
   'rmsAfterPixels':float(np.sqrt(np.mean(dist**2))),'maxAfterPixels':float(dist.max()),
   'dimensionScale':1,'traceTolerancePixels':3,'source':'002 site plan column centres; hand traced, individual plan dimensions retained'})
 return {'sourceSha256':hashlib.sha256((BASE/'side-connections/site002.jpg').read_bytes()).hexdigest(),'worldToPixelMatrix':M.tolist(),'buildings':report,
  'interpretation':'Rigid least squares only. Raster line thickness and individual-plan/site-plan discrepancies remain visible as residuals. No exact-survey accuracy claimed.',
  'legendConflict':'002 positions 6 and 7 have names reversed relative to individual 029 and 038 drawings and the user-confirmed attached Jung model. Preserve existing model identities; fit their physical footprints.'}

if __name__=='__main__':
 c=json.loads((OUT/'northern-contract.json').read_text(encoding='utf8'));result=registration(c)
 (OUT/'site002-registration.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf8')
 svg=['<svg xmlns="http://www.w3.org/2000/svg" width="100%" viewBox="780 795 1140 880"><image x="0" y="0" width="3284" height="2203" href="../side-connections/site002.jpg"/>']
 for fit in result['buildings']:
  for p,q in zip(fit['sourcePixelAnchors'],fit['fittedPixelAnchors']):
   svg.append(f'<circle cx="{p[0]}" cy="{p[1]}" r="4" fill="none" stroke="#bc3023" stroke-width="1.5"/><path d="M{q[0]-4},{q[1]}h8 M{q[0]},{q[1]-4}v8" stroke="#008579" stroke-width="1.5"/>')
  pts=' '.join(f'{p[0]:.3f},{p[1]:.3f}' for p in fit['fittedPixelAnchors'][:9 if fit['id']=='anchae' else 4])
  svg.append(f'<polyline points="{pts}" fill="none" stroke="#008579" stroke-width="1.8"/>')
 svg.append('</svg>');(OUT/'site002-fit.svg').write_text('\n'.join(svg),encoding='utf8')
 print(json.dumps([{k:r[k] for k in ('id','center','angle','rmsBeforePixels','rmsAfterPixels','maxAfterPixels')} for r in result['buildings']],indent=2))
