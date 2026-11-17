from pathlib import Path
from PIL import Image,ImageDraw
import numpy as np,json,hashlib,sys
P=Path(__file__).resolve().parent;D=P/'sarang-palette-r13';D.mkdir(exist_ok=True)
REF=Path(r'C:/Users/vjinn/AppData/Local/Temp/codex-clipboard-5e6b97f2-5bcf-40b9-ac54-cc2e35b83c47.jpg')
SOURCE=Path(sys.argv[1]) if len(sys.argv)>1 else P/'sarang-exact-r12/full.png'
regions={
'column':([674,620,687,748],[635,591,649,678]),
'apron':([282,646,427,677],[310,602,423,625]),
'lower_board':([946,1010,995,1040],[857,875,967,922]),
'railing':([956,895,994,906],[906,811,934,817]),
'floor':([1087,862,1128,879],[1030,819,1075,838]),
'frame':([1549,733,1560,775],[1400,640,1407,687]),
'gable':([1009,553,1055,580],[910,540,953,560]),
'tile':([640,316,810,402],[645,302,790,370]),
'stone':([106,754,265,798],[175,686,276,715]),
'plaster':([1434,739,1475,803],[1263,718,1290,755]),
'paper':([1156,805,1187,844],[1133,755,1178,796]),
'ground':([50,1100,260,1180],[100,1040,300,1120]),
}
imref=Image.open(REF).convert('RGB');imsrc=Image.open(SOURCE).convert('RGB')
result={'reference':str(REF),'referenceSha256':hashlib.sha256(REF.read_bytes()).hexdigest(),'render':str(SOURCE),'samples':{}}
sheet=Image.new('RGB',(640,len(regions)*110),'#eee8de');draw=ImageDraw.Draw(sheet)
for i,(key,(a,b)) in enumerate(regions.items()):
 record={}
 for j,(im,box,size,label) in enumerate([(imref,a,(1921,1280),'target'),(imsrc,b,(1800,1200),'render')]):
  actual=[round(v*im.size[k%2]/size[k%2]) for k,v in enumerate(box)]
  crop=im.crop(tuple(actual));arr=np.asarray(crop).reshape(-1,3).astype(float)
  if key=='paper':arr=arr[(arr[:,0]>180)&(arr[:,1]>100)]
  if key in ('lower_board','railing'):arr=arr[(arr[:,0]>arr[:,1]*1.25)&(arr[:,1]>arr[:,2]*1.2)]
  lum=arr@np.array([.2126,.7152,.0722]);order=np.argsort(lum)
  colors=[]
  for q in [.15,.5,.85]:
   at=round((len(order)-1)*q);sl=order[max(0,at-len(order)//30):min(len(order),at+len(order)//30+1)]
   rgb=np.median(arr[sl],axis=0).round().astype(int).tolist();colors.append(rgb)
  record[label]={'rect':actual,'displayRGB':colors,'hex':['#'+''.join(f'{x:02X}' for x in rgb) for rgb in colors]}
  preview=crop.copy();preview.thumbnail((210,80));sheet.paste(preview,(j*320+100,i*110+25));draw.text((j*320+8,i*110+8),key+' '+label,fill='black')
  for k,c in enumerate(colors):draw.rectangle((j*320+8+k*27,i*110+35,j*320+30+k*27,i*110+65),fill=tuple(c))
 result['samples'][key]=record
sheet.save(D/'sample-regions-analysis.png')
(D/'samples.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({k:{j:v[j]['hex'] for j in ['target','render']} for k,v in result['samples'].items()},indent=2))

