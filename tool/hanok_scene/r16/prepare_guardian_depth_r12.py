"""Analyze reference pigments into geometry fields; no source image is edited."""
from pathlib import Path
import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter,binary_closing,distance_transform_edt,label
P=Path(__file__).resolve().parent;R=Path('C:/Users/vjinn/.codex/generated_images/01a1501f-48a0-72b0-952f-b9030f42cafe')
fields={}
for role,name in [('front','exec-6dc3e9d7-0263-4476-93a4-e250cbe75c2e.png'),('side','exec-82363520-c4c8-4ac2-9137-e936bc4cdbf6.png')]:
 a=np.asarray(Image.open(R/name).convert('RGBA'),dtype=float)/255;alpha=a[:,:,3]>.5;lum=a[:,:,:3]@np.array([.2126,.7152,.0722]);base=gaussian_filter(lum,2.0)
 lo,hi=np.percentile(base[alpha],[8,92]);n=np.clip((base-lo)/(hi-lo),0,1)
 # Recessed background is below the raised ceramic region. Closing removes
 # small patina specks before measuring width of the actual carved region.
 raised=binary_closing((n>.24)&alpha,iterations=4)
 holes,count=label((~raised)&alpha);sizes=np.bincount(holes.ravel());fill=sizes<180;fill[0]=False;raised|=fill[holes]
 distance=distance_transform_edt(raised)
 # A rounded 4–6 mm edge rising into broad, quiet carved faces.
 relief=np.sin(np.clip(distance/9,0,1)*np.pi/2)
 broad=gaussian_filter(n,7)
 depth=.83*gaussian_filter(relief,1.4)+.17*broad
 fields[role]=np.flipud(depth).astype(np.float32)
 if role=='front':
  gy,gx=np.gradient(gaussian_filter(n,1.1));xx=gaussian_filter(gx*gx,3);yy=gaussian_filter(gy*gy,3);xy=gaussian_filter(gx*gy,3)
  coherence=np.sqrt((xx-yy)**2+4*xy*xy)/(xx+yy+1e-9)
  lines=(n-gaussian_filter(n,4))*np.clip((coherence-.25)/.5,0,1)
  fields['front_lines']=np.flipud(gaussian_filter(lines,.6)).astype(np.float32)
np.savez_compressed(P/'guardian-depth-fields-r12.npz',**fields)
print({k:v.shape for k,v in fields.items()})
