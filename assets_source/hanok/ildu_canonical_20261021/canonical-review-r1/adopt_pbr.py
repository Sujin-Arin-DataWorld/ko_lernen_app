"""Promote only a verified material-containing derivative, keeping approved native immutable."""
from pathlib import Path
import hashlib,json,struct
OUT=Path(__file__).resolve().parent
cat=json.loads((OUT/'catalog.json').read_text(encoding='utf-8'))
keys={'left':'left_changgo','right':'right_ansarang','shrine':'sadangmun'}
updated=[]
for gate,key in keys.items():
 receipt=OUT/(gate+'-pbr-export.json')
 if not receipt.exists():continue
 r=json.loads(receipt.read_text(encoding='utf-8'))
 model=OUT/'models'/r['model'];assert hashlib.sha256(model.read_bytes()).hexdigest()==r['sha256']
 b=next(b for b in cat['buildings'] if b['key']==key);assert b['nativeSha256']==r['sourceNativeSha256']
 b['model']='models/'+r['model'];b['structureOnly']=False;b['materialMode']='approved-native-shader-baked-PBR'
 b['materialReceipt']=receipt.name;b['materialTextureCount']=r['imageCount'];b['nativeMaterialColorSource']=r['colorSource']
 updated.append(key)
(OUT/'catalog.json').write_text(json.dumps(cat,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Material 3D enabled',updated)

