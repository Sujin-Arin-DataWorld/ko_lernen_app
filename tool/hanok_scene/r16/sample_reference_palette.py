"""Read reference pixels and record colour samples; never modify the image."""
from pathlib import Path
from PIL import Image
import numpy as np, json, hashlib
P=Path(__file__).resolve().parent
ref=Path('C:/Users/vjinn/AppData/Local/Temp/codex-clipboard-c02e2044-93c6-4ef1-891d-ee6fd448abae.jpg')
a=np.array(Image.open(ref).convert('RGB'));h,w=a.shape[:2]
regions={
 'column':(.145,.36,.171,.57),
 'beam':(.18,.375,.36,.415),
 'gable':(.505,.405,.565,.47),
 'rafter':(.17,.395,.34,.425),
 'floor':(.535,.62,.61,.69),
 'railing':(.49,.72,.66,.755),
 'apron':(.20,.51,.31,.565),
 'lower_board':(.46,.795,.64,.865),
 'door_panel':(.75,.57,.81,.70),
 'frame':(.18,.42,.35,.49),
 'lattice':(.165,.41,.215,.465),
 'endgrain':(.20,.387,.35,.414),
 'tile':(.35,.14,.61,.30),
 'tile-end':(.041,.284,.048,.296),
 'stone':(.07,.595,.36,.67),
 'plaster':(.835,.58,.865,.66),
 'paper':(.164,.413,.215,.47),
}
out={}
for key,(x0,y0,x1,y1) in regions.items():
 crop=a[int(y0*h):int(y1*h),int(x0*w):int(x1*w)].reshape(-1,3).astype(float)/255
 mx=crop.max(1);mn=crop.min(1);sat=(mx-mn)/np.maximum(mx,.001)
 if key in ('tile',):mask=(crop[:,2]>=crop[:,0]*.92)&(mx<.65)&(mx>.09)
 elif key in ('stone','plaster','tile-end'):mask=(sat<.30)&(mx>(.60 if key=='tile-end' else .35))
 elif key=='paper':mask=(crop[:,0]>.85)&(crop[:,1]>.50)&(crop[:,2]<crop[:,1]*.85)
 else:mask=(crop[:,0]>crop[:,1]*1.16)&(crop[:,1]>crop[:,2]*1.18)&(sat>.36)&(mx>.22)&(mx<.94)
 crop=crop[mask];assert len(crop)>20,(key,len(crop))
 lum=crop@np.array([.2126,.7152,.0722]);order=np.argsort(lum);crop=crop[order]
 colors=[]
 for q in [.18,.50,.82]:
  i=int(q*(len(crop)-1));radius=max(2,len(crop)//50)
  c=np.median(crop[max(0,i-radius):i+radius+1],axis=0)
  colors.append(''.join(f'{round(v*255):02X}' for v in c))
 out[key]=dict(region=[x0,y0,x1,y1],pixels=len(crop),displayColors=colors)
result=dict(reference=str(ref),sha256=hashlib.file_digest(ref.open('rb'),'sha256').hexdigest(),size=[w,h],samples=out,note='Display pixel samples including reference lighting; not assumed to be measured physical albedo.')
(P/'reference-sampled-colours.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v['displayColors'] for k,v in out.items()},indent=2))

kept={}
for name in ['sarang-material-rebuild-r1','sarang-material-rebuild-r2']:
 d=P/name
 kept[name]=[dict(file=f.name,bytes=f.stat().st_size,sha256=hashlib.file_digest(f.open('rb'),'sha256').hexdigest()) for f in d.iterdir() if f.is_file()]
preservation=P/'RENDER_1_2_PRESERVATION.json'
if preservation.exists():
 assert json.loads(preservation.read_text(encoding='utf-8'))['files']==kept, 'Render 1 or 2 changed'
else:
 preservation.write_text(json.dumps(dict(userInstruction='Preserve render 1 and 2 original files',files=kept),indent=2)+'\n',encoding='utf-8')
