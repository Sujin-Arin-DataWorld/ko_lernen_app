"""Inspect concurrent additions without including this task's generated boards."""
from pathlib import Path
from datetime import datetime, timezone, timedelta
from PIL import Image, ImageDraw, ImageFont
import hashlib, json, shutil

ROOT = Path(__file__).resolve().parent
SOURCE = Path('C:/Users/vjinn/.codex/generated_images')
INVENTORY = ROOT / 'audit/source-image-inventory.json'
ZONE = timezone(timedelta(hours=2))
START = datetime(2026,10,2,tzinfo=ZONE).timestamp()
END = datetime(2026,10,10,tzinfo=ZONE).timestamp()
data = json.loads(INVENTORY.read_text(encoding='utf-8'))
known = {str(Path(x['path'])).casefold() for x in data}
hashes = {x['sha256']: x['id'] for x in data}
added = []
for p in sorted(SOURCE.rglob('*')):
    if not p.is_file() or p.suffix.lower() not in {'.png','.jpg','.jpeg','.webp','.gif'} or p.parent.name == '01a12252-a369-74c1-a37d-25e1f0933b5d' or str(p).casefold() in known:
        continue
    st = p.stat()
    if not (START <= st.st_ctime < END or START <= st.st_mtime < END):
        continue
    digest = hashlib.sha256(p.read_bytes()).hexdigest()
    with Image.open(p) as image:
        width, height = image.size
    row = {'id': 'src-add-' + str(len(added)+1).zfill(3), 'path':str(p), 'rel':p.relative_to(SOURCE).as_posix(), 'media':p.suffix.lower(), 'bytes':st.st_size, 'width':width, 'height':height, 'created':datetime.fromtimestamp(st.st_ctime,ZONE).isoformat(), 'modified':datetime.fromtimestamp(st.st_mtime,ZONE).isoformat(), 'sha256':digest, 'duplicateOf':hashes.get(digest), 'review':'supplement-01.jpg'}
    hashes.setdefault(digest,row['id'])
    added.append(row)
if added:
    data.extend(added)
    INVENTORY.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
    sheet = Image.new('RGB',(1440,520*((len(added)+3)//4)),(238,232,223))
    draw = ImageDraw.Draw(sheet)
    for i,row in enumerate(added):
        im = Image.open(row['path']).convert('RGB')
        im.thumbnail((344,472))
        x,y=(i%4)*360,(i//4)*520
        sheet.paste(im,(x+(360-im.width)//2,y+32+(472-im.height)//2))
        draw.text((x+12,y+8),row['id'],fill=(30,37,32))
    dest=ROOT/'audit/inspection/supplement-01.jpg'
    sheet.save(dest,quality=88)
    shutil.copy2(dest,Path('C:/dev/hangulsori/_codex_artifacts/yeopjeon-c-design-20261009/inspection/supplement-01.jpg'))
    (ROOT/'audit/concurrent-additions.json').write_text(json.dumps(added,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'added':len(added),'files':len(data),'unique_images':len({x['sha256'] for x in data if x['media'] not in ['.mp4','.mov','.webm']})},ensure_ascii=False))
