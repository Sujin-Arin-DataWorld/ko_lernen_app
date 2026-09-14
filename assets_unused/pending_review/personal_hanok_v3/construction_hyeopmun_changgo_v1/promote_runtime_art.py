"""Promote user-selected construction art; preserve final source bytes."""
from pathlib import Path
import hashlib
import json
import shutil
from PIL import Image
import numpy as np

ROOT=Path(__file__).resolve().parent
REPO=ROOT.parents[3]
RUNTIME=REPO/"assets/illustrations/personal_hanok_v3/construction"
DATA=REPO/"assets/data/ildu_construction_art_v1.json"
DOCS=REPO/"docs/assets/ildu_hyeopmun_changgo_construction_20260914"

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def write_json(path,data):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+"\n",encoding="utf-8",newline="\n")

def main():
    learning=json.loads((ROOT/"learning.json").read_text(encoding="utf-8-sig"))
    ledger=json.loads((ROOT/"generation_ledger.json").read_text(encoding="utf-8-sig"))
    series=[]
    all_stages=[]
    for building,count,size,final_sha in [
        ("hyeopmun",6,[1568,2021],"3a6e3141f0f9c763067d40a867cf94082df04f119ba275c037b6e67645153884"),
        ("changgo",8,[2736,1536],"867495181c3507a29bca0efc43778bf6a958018b05992caba3fa40a01a3d9488")
    ]:
        rows=[]
        for s in [s for s in learning["stages"] if s["buildingId"]==building]:
            src=ROOT/s["asset"]
            if s["sequence"] < count:
                normalized=ROOT/"qa/normalized"/f'{building}_{s["sequence"]:02}.png'
                shutil.copyfile(normalized,src)
            dest=RUNTIME/building/src.name
            dest.parent.mkdir(parents=True,exist_ok=True)
            shutil.copyfile(src,dest)
            im=Image.open(dest)
            assert list(im.size)==size and im.mode=="RGBA"
            alpha=im.getchannel("A")
            assert alpha.getextrema()==(0,255)
            rgba=np.array(im)
            opaque=rgba[:,:,3]>200
            magenta=(rgba[:,:,0]>180)&(rgba[:,:,2]>180)&(rgba[:,:,1]<80)&opaque
            assert not magenta.any(),dest
            row={**s,"asset":dest.relative_to(REPO).as_posix(),"width":size[0],"height":size[1],
                 "bytes":dest.stat().st_size,"sha256":digest(dest),"alphaBBox":list(alpha.getbbox())}
            row["glossary"]=[g for g in learning["glossary"] if s["stageId"] in g["stageIds"]]
            if s["sequence"]<count:
                selected=next(a for a in ledger["attempts"] if a["building"]==building and a["stage"]==s["sequence"] and a["decision"]=="candidate")
                row["sourceAsset"]=(ROOT/selected["file"]).relative_to(REPO).as_posix()
                row["sourceSha256"]=digest(ROOT/selected["file"])
            else:
                assert row["sha256"]==final_sha
                row["sourceAsset"]=(ROOT/"references"/("hyeopmun_try03_cut.png" if building=="hyeopmun" else "changgo_final.png")).relative_to(REPO).as_posix()
                row["sourceSha256"]=final_sha
            rows.append(row);all_stages.append(row)
        series.append({"buildingId":building,"name":{"ko":"협문" if building=="hyeopmun" else "창고",
            "en":"Hyeopmun · Small gate" if building=="hyeopmun" else "Changgo · Storehouse",
            "de":"Hyeopmun · Kleines Tor" if building=="hyeopmun" else "Changgo · Lagerhaus"},
            "canonicalAsset":rows[-1]["asset"],"canonicalSha256":final_sha,"width":size[0],"height":size[1],
            "culture":learning["culture"][building],"stages":rows})
    catalog={"schemaVersion":1,"status":"approved_canonical","approvedBy":"Jin","approvedOn":"2026-09-14",
        "approval":"협문이랑 창고 설계 이미지 만든거 정본으로 채택하고 라이브 되게 해줘",
        "runtimeRoute":"/hanok/construction","presentation":"single-view construction learning; no progress or reward writes",
        "postprocessing":"Magenta matte extraction with edge decontamination, Lanczos resize to each locked canvas. Final bytes unchanged.",
        "geometryReview":"User-selected generated forms are retained. Small frame/base differences across stages remain; pixel-identical member continuity is not claimed.",
        "inheritedDefects":["The canonical Changgo final retains its existing fine green outline."],
        "series":series}
    write_json(DATA,catalog)
    write_json(DOCS/"construction_catalog.json",catalog)
    (DOCS/"README.md").write_text("# 협문·창고 승인 공정 이미지\n\nJin이 2026-09-14 생성 공정 이미지를 정본으로 채택하고 앱 연결을 요청했다.\n\n- 협문 6단계, 창고 8단계; 한 방향 고정.\n- 중간 원화 12장은 분홍 매트를 제거하고 정본 캔버스로 정규화했다.\n- 마지막 두 장은 기존 완성 정본과 SHA-256이 같다.\n- 생성 원화의 작은 기단·골조 형태 차이는 남아 있으며 부재 픽셀 동일성을 주장하지 않는다.\n- 앱 경로: /hanok/construction. 기존 보상·진행도를 쓰지 않는 공정 학습 화면이다.\n- 파일·해시·원본 연결: construction_catalog.json.\n\n원화·프롬프트·도면·3개 언어 설명은 assets_unused/pending_review/personal_hanok_v3/construction_hyeopmun_changgo_v1/에 보존한다. 해당 폴더의 초기 미완성 검수 기록은 생성 당시의 상태다.\n",encoding="utf-8",newline="\n")
    write_json(ROOT/"promotion.json",{"status":"approved_canonical","approvedOn":"2026-09-14","catalog":DATA.relative_to(REPO).as_posix(),
        "stages":[{"stageId":s["stageId"],"asset":s["asset"],"sha256":s["sha256"]} for s in all_stages],
        "remainingVisualLimitations":catalog["geometryReview"]})
    print(json.dumps({"stages":len(all_stages),"runtimeBytes":sum(s["bytes"] for s in all_stages),"catalog":str(DATA)},ensure_ascii=False))
if __name__=="__main__":
    main()

