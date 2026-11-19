import bpy, numpy as np
from pathlib import Path
p=Path(__file__).resolve().parent
im=bpy.data.images.load(str(p.parent.parent/'numaru-detail-study/numaru-authored-material-atlas.png'))
w,h=im.size;a=np.array(im.pixels[:]).reshape(h,w,4)[h-570:h-50,50:570,:3]
print('BLENDER PIXEL MEAN',im.colorspace_settings.name,a.mean(axis=(0,1)),flush=True)
