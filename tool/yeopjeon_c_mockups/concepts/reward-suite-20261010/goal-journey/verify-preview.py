"""Render and click the local design fixture in its own agent-browser session.
This verifies HTML/sample storage only; it is not Flutter or device QA.
"""
from pathlib import Path
import base64
import datetime
import json
import subprocess
import time
import sys

ROOT = Path(__file__).resolve().parent
SESSION = "goaljourney-01a1278f"
URL = "http://127.0.0.1:8793/concepts/reward-suite-20261010/goal-journey/preview.html"
RENDERED = ROOT / "rendered"
PROOF = ROOT / "qa-proof"
RENDERED.mkdir(exist_ok=True)
PROOF.mkdir(exist_ok=True)
SCENES = {"R01":"first-daily", "R03":"reward-received", "W03":"learning-goal", "W04":"build-ready", "B01":"spend-confirm", "B03":"saved-progress", "W05":"next-goal"}
report = {"boundary":"Interactive HTML with local sample storage, not Flutter/device evidence", "session":SESSION,
          "timeUtc":datetime.datetime.now(datetime.timezone.utc).isoformat(), "scope":"Yeopjeon rewards; no Hanok screen or construction-stage artwork", "flows":[], "layouts":[]}

def persist():
    (PROOF/"verification.json").write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding="utf-8")

def browser(*args):
    result = subprocess.run(["rtk","proxy","agent-browser","--session",SESSION,"--json",*map(str,args)],
                            capture_output=True,text=True,encoding="utf-8",timeout=60)
    if result.returncode: raise RuntimeError(f"{args}: {result.stdout} {result.stderr}")
    value = json.loads(result.stdout)
    if not value.get("success"): raise RuntimeError(f"{args}: {value}")
    return value.get("data",{})

def evaluate(js):
    return browser("eval","-b",base64.b64encode(js.encode()).decode()).get("result")

def state():
    return evaluate("({scene:document.querySelector('#phone').dataset.scene,balance:Number(document.querySelector('#wallet-button').dataset.balance),visualBalance:Number(document.querySelector('#wallet-value').textContent),buildDialog:document.querySelector('#build-dialog').open,active:document.activeElement?.dataset?.action,savedReceipt:document.querySelector('.debit-receipt')?.textContent?.trim(),url:location.href})")

def expect(scene,balance):
    actual=state()
    assert actual["scene"]==scene and actual["balance"]==balance,actual
    return actual

def snapshot(name):
    data=browser("snapshot","-i")
    (PROOF / (name+".snapshot.json")).write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding="utf-8")

GEOMETRY = r"""(async () => {
 await document.fonts.ready;
 await Promise.all(document.getAnimations().map(a => a.finished.catch(() => {})));
 const phone=document.querySelector('#phone'), scroll=document.querySelector('#app-scroll'), dialog=document.querySelector('#build-dialog');
 const bounds=e=>{const r=e.getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height,bottom:r.bottom,right:r.right}};
 const shown=e=>{const s=getComputedStyle(e);return s.display!=='none' && s.visibility!=='hidden' && e.getClientRects().length && e.getBoundingClientRect().width>1 && !e.closest('.sr-only')};
 const roots=dialog.open?[dialog]:[document.querySelector('#screen'),document.querySelector('#screen-actions')];
 const all=selector=>roots.flatMap(root=>[...root.querySelectorAll(selector)]);
 const failures=[];
 const children=[...document.querySelectorAll('#screen > [data-layout]')].map(e=>({kind:e.dataset.layout,...bounds(e)}));
 for(let i=1;i<children.length;i++){if(children[i-1].bottom>children[i].y+1){failures.push('section-overlap:'+children[i-1].kind+'/'+children[i].kind)}}
 const rewardStage=document.querySelector('[data-reward-stage]');
 const rewardMedia=rewardStage?[...rewardStage.querySelectorAll('.reward-hero__still,.reward-hero__video,.reward-hero__visual')].filter(shown).map(e=>({kind:e.tagName,...bounds(e),naturalWidth:e.naturalWidth||e.videoWidth,naturalHeight:e.naturalHeight||e.videoHeight})):[];
 if(rewardStage){const r=bounds(rewardStage);for(const m of rewardMedia){if(m.x<r.x-1||m.right>r.right+1||m.y<r.y-1||m.bottom>r.bottom+1){failures.push('reward-media-clipped-by-stage:'+m.kind)}}}
 for(const e of all('h1,h2,h3,p,dt,dd,.button-label,.wallet-amount>strong,.earned-value strong,.earned-plus')){
  if(!shown(e))continue;
  if(e.scrollWidth>e.clientWidth+2){failures.push('horizontal-overflow:'+e.textContent.trim().slice(0,60))}
  const range=document.createRange();range.selectNodeContents(e);const er=e.getBoundingClientRect();
  for(const r of range.getClientRects()){if(r.left<er.left-2||r.right>er.right+2||r.top<er.top-2||r.bottom>er.bottom+2){failures.push('text-clipping:'+e.textContent.trim().slice(0,60));break}}
 }
 const buttons=all('button:not(:disabled)').filter(shown).map(e=>({label:e.textContent.trim(),...bounds(e)}));
 for(const b of buttons){if(b.height<48||b.width<48){failures.push('small-target:'+b.label)}}
 for(const e of all('.tactile')){
  const label=e.querySelector('.button-label'),arrow=e.querySelector('.button-arrow');
  if(e.querySelector('.cta-art') && label.getBoundingClientRect().left<e.getBoundingClientRect().left+54){failures.push('cta-cloud-overlap:'+label.textContent)}
  if(arrow&&label.getBoundingClientRect().right+8>arrow.getBoundingClientRect().left){failures.push('cta-arrow-overlap:'+label.textContent)}
 }
 const unloaded=[...document.images].filter(e=>shown(e)&&(!e.complete||e.naturalWidth===0)).map(e=>e.getAttribute('src'));
 if(unloaded.length)failures.push('unloaded-images:'+unloaded.join(','));
 if(dialog.open){const d=bounds(dialog),p=bounds(phone);if(d.x<p.x||d.right>p.right+1||d.y<Math.max(0,p.y)||d.bottom>Math.min(innerHeight,p.bottom)+1){failures.push('dialog-outside-phone')}}
 const dock=dialog.open?document.querySelector('.sheet-actions'):document.querySelector('#screen-actions');
 const dockBounds=bounds(dock),phoneBounds=bounds(phone);
 if(dockBounds.bottom>Math.min(innerHeight,phoneBounds.bottom-34)+1)failures.push('actions-outside-safe-area');
 for(const b of buttons.filter(b=>b.label!==document.querySelector('.back-link')?.textContent?.trim())){if(b.y<dockBounds.y-1||b.bottom>dockBounds.bottom+1){failures.push('action-outside-dock:'+b.label)}}
 const appbarButtons=[...phone.querySelectorAll('.app-bar button')].map(bounds);
 if(appbarButtons.some(b=>b.width<48||b.height<48))failures.push('small-appbar-target');
 return {scene:phone.dataset.scene,balance:Number(document.querySelector('#wallet-value').textContent),scale:getComputedStyle(document.documentElement).getPropertyValue('--scale').trim(),
 viewport:{width:innerWidth,height:innerHeight},screen:bounds(scroll),contentHeight:scroll.scrollHeight,scrollNeeded:scroll.scrollHeight>scroll.clientHeight+1,
 actions:buttons,actionDock:dockBounds,sections:children,rewardMedia,dialog:dialog.open?bounds(dialog):null,failures,
 reducedMotion:document.body.dataset.reducedMotion,animations:document.getAnimations().length};
})()"""

if "--layouts-only" not in sys.argv:
    # Actual click journeys, including cancel, Escape, duplicate press and reload.
    for lang in ["de","en"]:
        browser("set","viewport",1200,1060)
        browser("open",f"{URL}?lang={lang}")
        snapshot("flow-start-"+lang)
        browser("click","#restart"); expect("WALLET",30)
        browser("click",'[data-action="goal"]'); expect("W03",30)
        browser("click",'[data-action="learn"]')
        snapshot("learning-dialog-"+lang)
        browser("click","#learning-close"); expect("W03",30)
        browser("click",'[data-action="learn"]')
        browser("click","#learning-complete"); expect("R03",70)
        browser("click",'[data-action="ready"]'); expect("W04",70)
        browser("click",'[data-action="build"]'); expect("B01",70)
        snapshot("confirm-"+lang)
        browser("click",'#build-content [data-action="cancel"]')
        assert expect("W04",70)["active"]=="build"
        browser("click",'[data-action="build"]'); browser("press","Escape")
        assert expect("W04",70)["active"]=="build"
        browser("click",'[data-action="build"]')
        browser("dblclick",'#build-content [data-action="save"]')
        saved=state(); assert saved["balance"]==30 and saved["scene"] in ["B03","W05"],saved
        browser("reload"); restored=expect("B03",30)
        assert "40" in restored["savedReceipt"] and "scene=" not in restored["url"],restored
        browser("click",'[data-action="next"]'); expect("W05",30)
        browser("click",'[data-action="learn-next"]')
        assert evaluate("document.querySelector('#learning-complete').hidden") is True
        browser("click","#learning-close")
        browser("click",'[data-action="wallet-root"]'); expect("WALLET",30)
        browser("click","#wallet-button")
        assert evaluate("document.querySelector('#wallet-summary').textContent.includes('40')") is True
        browser("click","#wallet-close"); expect("WALLET",30)
        report["flows"].append({"language":lang,"passed":["Yeopjeon overview","course goal dialog","confirmed reward 30 + 40 = 70","review use conditions","cancel preserves 70","Escape restores focus","double press spends once","reload restores debit receipt and 30","next goal keeps 30","wallet shows earned 40, used 40, balance 30"]})
        persist()
        print("Click journey passed: "+lang,flush=True)
    
    # A visible QA control injects a known failure before any local write.
    browser("open",URL+"?lang=de&scene=W04")
    snapshot("failure-entry")
    browser("click","#qa-tools > summary")
    browser("select","#save-outcome","failure")
    browser("click",'[data-action="build"]'); browser("click",'#build-content [data-action="save"]')
    expect("B04",70)
    browser("screenshot",str(PROOF/"save-failure-de.png"))
    browser("click",'#build-content [data-action="retry"]'); expect("B01",70)
    browser("click",'#build-content [data-action="cancel"]'); expect("W04",70)
    browser("select","#save-outcome","success")
    browser("click",'[data-action="build"]'); browser("click",'#build-content [data-action="save"]')
    expect("B03",30)
    report["flows"].append({"language":"de","passed":["failed write keeps 70","retry confirms the same use target","successful retry saves debit receipt and 30"]})
    persist()
    print("Failure and retry passed",flush=True)
    
else:
    report["flows"] = json.loads((PROOF/"verification.json").read_text(encoding="utf-8")).get("flows",[])

for width,height in [(402,874),(375,812)]:
 for lang in ["de","en"]:
  for scale in ["1","2"]:
   for scene,file in SCENES.items():
    browser("set","viewport",width,height)
    browser("open",f"{URL}?lang={lang}&scene={scene}&embed=1&scale={scale}")
    if scene in ["R01","R03"]:
     browser("wait","--fn","document.querySelector('[data-reward-stage]')?.dataset.rewardPhase === 'settled'")
    result=evaluate(GEOMETRY)
    assert not result["failures"],result
    # All primary actions must fit without scrolling in the requested normal view.
    if width==402 and scale=="1":
     assert not result["scrollNeeded"],result
     if not result["dialog"]:
      assert all(b["bottom"]<=result["actionDock"]["bottom"] for b in result["actions"]),result
     browser("screenshot",str(RENDERED/f"{scene}-{file}-{lang}.png"))
    if width==402 and scale=="2":
     browser("screenshot",str(PROOF/f"{scene}-{lang}-200pct-top.png"))
     browser("scrollintoview",'.build-sheet .tactile' if result["dialog"] else '#screen-actions .tactile')
     browser("screenshot",str(PROOF/f"{scene}-{lang}-200pct-action.png"))
    report["layouts"].append({"language":lang,**result})
   persist()
   print(f"Layout passed: {width}x{height} {lang} {scale}",flush=True)

# Motion setting and a short landscape viewport preserve the same reachable flow.
for scene in ["W04","B01"]:
 browser("set","viewport",874,402)
 browser("open",f"{URL}?lang=en&scene={scene}&embed=1&motion=reduce")
 result=evaluate(GEOMETRY)
 assert not result["failures"] and result["animations"]==0,result
 report["layouts"].append({"language":"en","mode":"landscape-reduced-motion",**result})
browser("set","viewport",402,874)
browser("open",URL+"?lang=de&scene=WALLET&embed=1")
evaluate(GEOMETRY)
browser("screenshot",str(PROOF/"Yeopjeon-overview-de.png"))
report["browserErrors"]=browser("errors")
(PROOF/"verification.json").write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding="utf-8")
print(f"Verified {len(report['flows'])} click journeys and {len(report['layouts'])} rendered layouts. Evidence: {PROOF}",flush=True)

