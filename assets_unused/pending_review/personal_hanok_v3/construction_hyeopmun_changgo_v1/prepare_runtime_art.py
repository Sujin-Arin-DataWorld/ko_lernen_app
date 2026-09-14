from pathlib import Path
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parent
SIZES={"hyeopmun":(1568,2021),"changgo":(2736,1536)}

def remove_key(path):
    im=Image.open(path).convert("RGB")
    rgb=np.array(im,dtype=np.float32)
    chroma=np.minimum(rgb[:,:,0],rgb[:,:,2])-rgb[:,:,1]
    a=np.clip((250-chroma)/245,0,1)
    a[chroma<5]=1
    # Remove the known magenta matte from partially covered edge pixels.
    bg=np.array([255,0,255],np.float32)
    recovered=np.clip((rgb-(1-a[:,:,None])*bg)/np.maximum(a[:,:,None],0.01),0,255)
    recovered[a==0]=0
    rgba=np.dstack([recovered,np.round(a*255)]).astype(np.uint8)
    return Image.fromarray(rgba)

def main():
    ledger=json.loads((ROOT/"generation_ledger.json").read_text())
    out=ROOT/"qa"/"normalized"
    out.mkdir(exist_ok=True)
    for item in ledger["attempts"]:
        if item["decision"]!="candidate":
            continue
        im=remove_key(ROOT/item["file"])
        im=im.resize(SIZES[item["building"]],Image.Resampling.LANCZOS)
        im.save(out/f'{item["building"]}_{item["stage"]:02}.png')
    for building in SIZES:
        canon=Image.open(ROOT/"references"/("hyeopmun_try03_cut.png" if building=="hyeopmun" else "changgo_final.png"))
        maxstage=6 if building=="hyeopmun" else 8
        images=[Image.open(out/f'{building}_{s:02}.png') for s in range(1,maxstage)]+[canon]
        thumbw=300 if building=="hyeopmun" else 480
        thumbh=390 if building=="hyeopmun" else 270
        cols=3 if building=="hyeopmun" else 2
        rows=(maxstage+cols-1)//cols
        sheet=Image.new("RGB",(cols*thumbw,rows*(thumbh+35)),(239,238,228))
        draw=ImageDraw.Draw(sheet)
        for i,im in enumerate(images):
            image=im.copy();image.thumbnail((thumbw,thumbh))
            x=i%cols*thumbw;y=i//cols*(thumbh+35)
            sheet.paste(image,(x+(thumbw-image.width)//2,y),image)
            draw.text((x+10,y+thumbh+5),f"{building} {i+1}",fill="black")
        sheet.save(ROOT/"qa"/f"{building}-normalized-contact.png")
        grid=Image.new("RGB",canon.size,(235,239,230));grid.paste(canon,(0,0),canon)
        draw=ImageDraw.Draw(grid)
        font=ImageFont.truetype("C:/Windows/Fonts/arial.ttf",22)
        for x in range(0,grid.width,200):
            draw.line((x,0,x,grid.height),fill=(120,190,220),width=1)
            draw.text((x+2,grid.height//2),str(x),fill=(0,70,170),font=font)
        for y in range(0,grid.height,200):
            draw.line((0,y,grid.width,y),fill=(120,190,220),width=1)
            draw.text((10,y+2),str(y),fill=(0,70,170),font=font)
        grid.save(ROOT/"qa"/f"{building}-canonical-grid.png")
    print("12 intermediate candidates keyed and normalized for visual alignment review.")

if __name__=="__main__":
    main()

