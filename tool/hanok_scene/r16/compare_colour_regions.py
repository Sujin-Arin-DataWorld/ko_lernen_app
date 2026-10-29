from pathlib import Path
from PIL import Image
import numpy as np, json
P=Path(__file__).resolve().parent
def region(path,box,kind):
 a=np.array(Image.open(path).convert('RGB'))/255;h,w=a.shape[:2]
 x0,y0,x1,y1=box;c=a[int(y0*h):int(y1*h),int(x0*w):int(x1*w)].reshape(-1,3)
 mx=c.max(1);mn=c.min(1);sat=(mx-mn)/np.maximum(mx,.001)
 if kind=='wood':mask=(c[:,0]>c[:,1]*1.20)&(c[:,1]>c[:,2]*1.2)&(sat>.4)&(mx>.2)&(mx<.95)
 elif kind=='tile':mask=(c[:,2]>=c[:,0]*.98)&(mx<.65)&(mx>.09)
 else:mask=(sat<.4)&(mx>.25)&(mx<.97)
 c=c[mask];lum=c@np.array([.2126,.7152,.0722]);c=c[np.argsort(lum)]
 return [np.median(c[max(0,int(len(c)*q)-max(2,len(c)//50)):int(len(c)*q)+max(2,len(c)//50)],axis=0).tolist() for q in [.2,.5,.8]]
pairs={
 'lower_board':('wood',(.49,.80,.61,.86),(.51,.755,.63,.795)),
 'apron':('wood',(.14,.48,.24,.55),(.17,.48,.265,.515)),
 'gable':('wood',(.535,.413,.572,.468),(.55,.436,.579,.475)),
 'railing':('wood',(.50,.72,.62,.755),(.52,.70,.63,.735)),
 'stone':('stone',(.07,.595,.28,.67),(.08,.54,.27,.63)),
 'tile':('tile',(.66,.44,.71,.52),(.64,.44,.71,.52)),
}
result={}
for key,(kind,rbox,cbox) in pairs.items():
 ref=region('C:/Users/vjinn/AppData/Local/Temp/codex-clipboard-c02e2044-93c6-4ef1-891d-ee6fd448abae.jpg',rbox,kind)
 current=region(P/'sarang-reference-colour-r3/preview.png',cbox,kind)
 result[key]=dict(referenceBox=rbox,candidateBox=cbox,reference=ref,current=current)
 print(key,'target',[[round(v*255) for v in c] for c in ref],'render',[[round(v*255) for v in c] for c in current])
(P/'sarang-reference-colour-r3/colour-check.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
