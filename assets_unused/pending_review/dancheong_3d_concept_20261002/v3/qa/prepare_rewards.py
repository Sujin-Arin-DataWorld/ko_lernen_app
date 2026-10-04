"""Preserve reward artwork bytes and capture live economy contract sources."""
from pathlib import Path
import hashlib, json, shutil, subprocess
root = Path(__file__).resolve().parents[1]
source = Path(r"C:\dev\hangulsori\ko_lernen_app")
head = subprocess.check_output(["git","-C",str(source),"rev-parse","HEAD"],text=True).strip()
mapping = {
 "assets/illustrations/stamps/stamp_yeopjeon.png":"assets/yeopjeon-original.png",
 "assets/illustrations/reward/reward_bojagi_closed.png":"assets/bojagi-closed.png",
 "assets/illustrations/reward/reward_bojagi_open.png":"assets/bojagi-open.png",
 "assets/illustrations/decorations/decoration_seoan.png":"assets/decoration-seoan.png",
 "assets/illustrations/decorations/decoration_munbangsau.png":"assets/decoration-munbangsau.png",
 "assets/illustrations/decorations/decoration_soban.png":"assets/decoration-soban.png",
}
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
copies=[]
for original,target in mapping.items():
 src,dst=source/original,root/target
 dst.parent.mkdir(parents=True,exist_ok=True)
 shutil.copyfile(src,dst)
 assert sha(src)==sha(dst)
 copies.append(dict(source=str(src),review=str(dst),sha256=sha(src)))
contracts=["lib/models/yeopjeon_wallet.dart","lib/services/yeopjeon_service.dart","lib/services/decoration_reward_service.dart","lib/screens/bojagi_screen.dart","lib/screens/sori_stage/sori_stage_today_screen.dart"]
record={"sourceHead":head,"copies":copies,"sourceHashes":{p:sha(source/p) for p in contracts},"rules":{"firstDistinctConfirmedLesson":20,"secondDistinctConfirmedLesson":10,"constructionStage":40,"repeatCompletion":0,"bojagi":"tap to untie; choose one of three existing decoration candidates; separate from coin income"},"boundary":"REVIEW_ONLY. In-memory example balance and selection. No account read, award, spend or ownership mutation."}
assert head==subprocess.check_output(["git","-C",str(source),"rev-parse","HEAD"],text=True).strip()
(root/"qa/reward-sources.json").write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding="utf-8")
print(json.dumps({"sourceHead":head,"copied":len(copies),"verified":True}))
