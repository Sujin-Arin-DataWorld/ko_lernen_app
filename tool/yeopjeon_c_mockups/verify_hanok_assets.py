"""Read-only gate for the future approved Hanok manifest. No image rewriting."""
import json
from pathlib import Path
from PIL import Image

root=Path(__file__).resolve().parent
catalog=json.loads((root/'hanok-assets.json').read_text(encoding='utf-8'))
checked=[]
for building, config in catalog['buildings'].items():
    for stage, entry in config['approvedStages'].items():
        if entry.get('status')!='approved':
            continue
        path=(root/entry['file']).resolve()
        if not path.is_relative_to(root.resolve()):
            raise ValueError(f'Asset path escapes package: {path}')
        with Image.open(path) as source:
            rgba=source.convert('RGBA')
            extrema=rgba.getchannel('A').getextrema()
            corners=[rgba.getpixel(p)[3] for p in [(0,0),(rgba.width-1,0),(0,rgba.height-1),(rgba.width-1,rgba.height-1)]]
            if extrema[0]!=0 or extrema[1]!=255 or max(corners)>0:
                raise ValueError(f'{building}/{stage}: requires real transparent alpha and transparent corners')
            if entry.get('alphaVerified') is not True:
                raise ValueError(f'{building}/{stage}: alphaVerified must be true after review')
            checked.append({'building':building,'stage':stage,'file':entry['file'],'alphaMinMax':extrema})
print(json.dumps({'status':catalog['status'],'approvedAssetsChecked':len(checked),'assets':checked},ensure_ascii=False,indent=2))
