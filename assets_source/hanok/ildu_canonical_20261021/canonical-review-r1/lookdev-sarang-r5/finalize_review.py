from pathlib import Path
import json,hashlib
p=Path(__file__).resolve().parent
f=p/'index.html';t=f.read_text(encoding='utf-8').replace('*{box-sizing:border-box}','*{box-sizing:border-box}body{margin:0}')
f.write_text(t,encoding='utf-8')
f=p/'WORK.md';t=f.read_text(encoding='utf-8').replace('Other materials and source architecture remain unchanged.','Source architecture remains unchanged; all materials retain their individual profiles.')
f.write_text(t,encoding='utf-8')
proof=json.loads((p/'verification.json').read_text(encoding='utf-8'))
record=dict(status='native review candidate saved and technically verified',approved=False,appIntegrated=False,glbConverted=False,
 sourceSha256=proof['sourceSha256'],native=proof['candidateNative'],nativeSha256=proof['candidateSha256'],
 originalMeshCount=711,originalGeometryUvsAttributesPlaquesLightingPreserved=True,renderedImagePairs=4,
 visualAssessment='Broad colour planes, reduced wood grain; whole-building and 402px whole-Numaru effect restrained. User review pending.',
 externalResourcesInstalled=False,canonicalPromotion=False)
(p/'CURRENT_STATUS.json').write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(record,ensure_ascii=False,indent=2))
