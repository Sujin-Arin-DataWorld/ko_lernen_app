from pathlib import Path
import json,hashlib
p=Path(__file__).resolve().parent;r5=p.parent/'lookdev-sarang-r5'
native=r5/'sarang-three-value-brush-candidate.blend'
sha=hashlib.file_digest(native.open('rb'),'sha256').hexdigest()
assert sha=='cab144f08a7836dc0eafc074456104cdbfe21eecd46eadf2c13b882d52efd4c8'
authority=dict(date='2026-10-22',source='direct user message in this conversation',quote='오 훨씬 좋아졌다 이런식으로 다른 건물도 건물에 맞게 적용해줘.',
 scope='Sarang R5 visual direction accepted; extend with building-specific material adaptation',native=native.name,sha256=sha,canonicalPromotion=False,appReleaseApproval=False)
(p/'STYLE_AUTHORITY.json').write_text(json.dumps(authority,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
state=json.loads((r5/'CURRENT_STATUS.json').read_text(encoding='utf-8'));state.update(status='user accepted visual direction; other-building extension authorized',approved=True,authority=authority)
(r5/'CURRENT_STATUS.json').write_text(json.dumps(state,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(authority,ensure_ascii=False))
