"""Analysis-only contact sheets; all tiles are untouched native render pixels."""
from pathlib import Path
import json,math
from PIL import Image,ImageDraw,ImageFont
P=Path(__file__).resolve().parent;D=P/'family-r16';A=D/'analysis';A.mkdir(exist_ok=True)
font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',15)
scope=json.loads((P/'PROCESS_STYLE_SCOPE_R16.json').read_text(encoding='utf-8'))
for b in scope['buildings']:
 folder=D/b['key'];f=folder/'stage-renders.json'
 if not f.exists():continue
 report=json.loads(f.read_text(encoding='utf-8'));tiles=report['steps'];width=320;height=238
 sheet=Image.new('RGB',(width*4,height*math.ceil(len(tiles)/4)),(238,234,227));draw=ImageDraw.Draw(sheet)
 for i,row in enumerate(tiles):
  image=Image.open(folder/row['file']).convert('RGB');image.thumbnail((320,213))
  x=(i%4)*width;y=(i//4)*height;sheet.paste(image,(x,y))
  draw.text((x+6,y+214),str(row['sequence'])+' · '+row['label'],font=font,fill=(40,45,48))
 sheet.save(A/(b['key']+'.png'))
print('analysis contacts saved')
