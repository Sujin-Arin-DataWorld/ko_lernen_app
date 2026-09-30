from pathlib import Path
import bpy,json,sys,numpy as np
from mathutils import Vector,Matrix
sys.path.insert(0,str(Path(__file__).parent))
from northern_timber_sections import groups
N=Path(__file__).resolve().parents[2]/'assets_unused/pending_review/hwalju-blueprint-review/northern-court'
bpy.ops.wm.open_mainfile(filepath=str(N/'detail-redraw.blend'))
c=json.loads((N/'detail-redraw-contract.json').read_text(encoding='utf8'));sc=json.loads((N.parent/'side-connections/connection-contract.json').read_text(encoding='utf8'))
rs={r['id']:r for r in c['buildings']};rs['ansarang']={**sc['buildings']['ansarang'],'datum':0};out={}
for bid in ('sadang','sadangmun','ansarang'):
 r=rs[bid];origin=Vector((*r['center'],r['datum']));inv=Matrix.Rotation(-r['angle'],3,'Z');items=[]
 for ob in bpy.context.scene.objects:
  if ob.type!='MESH' or ob.get('construction_building')!=bid:continue
  p=np.array([inv@(ob.matrix_world@v.co-origin) for v in ob.data.vertices]);lo=p.min(0);hi=p.max(0)
  if 'roof' in ob.name.lower() or len(p)>50000:continue
  item={'name':ob.name,'min':lo.round(4).tolist(),'max':hi.round(4).tolist(),'mats':[m.name for m in ob.data.materials]}
  if bid=='ansarang' and lo[0]<-2.7 and hi[2]<3.1:
   item['parts']=[{'min':p[ids].min(0).round(4).tolist(),'max':p[ids].max(0).round(4).tolist()} for ids in groups(ob.data) if p[ids][:,0].mean()<-2.7]
  items.append(item)
 out[bid]=items
out['doors']=[d for d in c['doors'] if d['building'] in ('sadang','sadangmun')]
out['images']=[{'name':im.name,'space':im.colorspace_settings.name,'path':im.filepath} for im in bpy.data.images if 'canonical' in im.name.lower()]
(N/'photo-details-before.json').write_text(json.dumps(out,indent=2),encoding='utf8')
print('PHOTO DETAIL AUDIT', {k:len(v) for k,v in out.items()},flush=True)
