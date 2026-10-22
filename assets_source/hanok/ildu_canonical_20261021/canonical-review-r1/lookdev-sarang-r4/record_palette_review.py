from pathlib import Path
import json
from PIL import Image
import numpy as np
p=Path(__file__).resolve().parent
a=np.asarray(Image.open(p/'before-numaru.png').convert('RGB'),float)
b=np.asarray(Image.open(p/'selective-numaru.png').convert('RGB'),float)
def metrics(im):
 crop=im[765:875,480:970];lum=crop@np.array([.2126,.7152,.0722])
 return dict(meanRGB=crop.mean(axis=(0,1)).tolist(),meanEncodedLuma=float(lum.mean()),stdEncodedLuma=float(lum.std()))
data=dict(status='reconsider_after_user_washed_out_feedback',approved=False,newPaletteApplied=False,
 direction='maintained Hanok illustrated with care; no copied weathering or global hue warming',before=metrics(a),after=metrics(b),
 sourceBase='../lookdev-sarang-r3/sarang-r3-fix-checkpoint.blend',latestStudy='sarang-palette-brush-selective.blend',research='PALETTE_RESEARCH.md',
 originalGeometryPreserved=True,glbConverted=False,appIntegrated=False)
(p/'CURRENT_STATUS.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
f=p/'index.html';t=f.read_text(encoding='utf-8')
t=t.replace('검토용 후보, 360도 공정 화면 적용 전','허옇게 보인다는 피드백으로 재검토 중 · 새 팔레트 적용 전 · 360도 공정 화면 적용 전')
t=t.replace('after-numaru.png','selective-numaru.png').replace('brush-r4-1','brush-r4-review-2')
t=t.replace("im.src=prefix+'-'+v", "im.src=(prefix==='after'?'selective':'before')+'-'+v")
t=t.replace('href="sarang-palette-brush-study.blend"','href="sarang-palette-brush-selective.blend"').replace('href="verification.json"','href="selective-verification.json"')
t=t.replace('<h1>색보다, 붓이 지나간 방식</h1>','<h1>색보다, 붓이 지나간 방식</h1><p><strong>현재 후보 재검토 중.</strong> 관리한 한옥의 중간톤과 재료색을 되찾는 방향을 정리했습니다. <a href="PALETTE_RESEARCH.md">색채 조사와 다음 방향</a></p>')
f.write_text(t,encoding='utf-8')
for name in ['phase-status.json','verification.json']:
 f=p.parent/'lookdev-sarang-r3'/name;record=json.loads(f.read_text(encoding='utf-8'))
 record.update(temperatureGlazeWithdrawn=True,currentAllowedBase='sarang-r3-fix-checkpoint.blend',newPaletteApproved=False)
 f.write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(data,ensure_ascii=False,indent=2))
