import json,subprocess,sys
from pathlib import Path
OUT=Path(__file__).resolve().parent
SESSION='ildu-canonical-20261021'
def run(*args):
 p=subprocess.run(['rtk','proxy','agent-browser','--session',SESSION,*args],text=True,capture_output=True,encoding='utf-8',timeout=180)
 if p.returncode:raise RuntimeError(p.stdout+p.stderr)
 return p.stdout.strip()
mode=sys.argv[1] if len(sys.argv)>1 else 'groups'
if mode=='groups':
 keys=json.loads((OUT/'catalog.json').read_text(encoding='utf-8'))['buildings']
 records=[]
 for row in keys:
  js='''(async()=>{await reviewQA.selectBuilding(KEY);await new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r)));const stages=[];const b=reviewQA.catalog.buildings.find(b=>b.key===KEY);for(const s of b.steps){reviewQA.setStage(s.sequence);await new Promise(r=>requestAnimationFrame(r));const state=reviewQA.state();stages.push({stage:s.sequence,visible:state.visibleMeshes,error:state.error});}return {key:KEY,final:reviewQA.state(),stages};})()'''.replace('KEY',json.dumps(row['key']))
  data=json.loads(run('eval',js));assert data['final']['loaded'] and not data['final']['error'],data
  counts=[s['visible'] for s in data['stages']];assert counts==sorted(counts),data
  records.append(data);(OUT/'browser-groups-qa.json').write_text(json.dumps(dict(passed=True,groups=records),ensure_ascii=False,indent=2),encoding='utf-8')
  print('BROWSER OK',row['key'],len(data['stages']),data['final']['visibleMeshes'],flush=True)
elif mode=='controls':
 js='''(async()=>{await reviewQA.selectBuilding('left_changgo');await new Promise(r=>requestAnimationFrame(r));const before=reviewQA.state();const rotations=[];for(let i=0;i<4;i++){document.getElementById('turnRight').click();await new Promise(r=>requestAnimationFrame(r));rotations.push(reviewQA.state());}document.getElementById('zoomIn').click();await new Promise(r=>requestAnimationFrame(r));const zoomed=reviewQA.state();document.getElementById('zoomOut').click();await new Promise(r=>requestAnimationFrame(r));const restored=reviewQA.state();document.getElementById('viewport').focus();document.getElementById('viewport').dispatchEvent(new KeyboardEvent('keydown',{key:'ArrowLeft',bubbles:true}));await new Promise(r=>requestAnimationFrame(r));const keyboard=reviewQA.state();return {before,rotations,zoomed,restored,keyboard,overflow:document.documentElement.scrollWidth>innerWidth,brokenImages:[...document.images].filter(i=>!i.complete||!i.naturalWidth).map(i=>i.src)};})()'''
 data=json.loads(run('eval',js));assert data['zoomed']['distance']<data['before']['distance']
 assert abs(data['restored']['distance']-data['before']['distance'])<1e-5
 assert abs(data['rotations'][-1]['azimuth']-data['before']['azimuth'])<1e-5
 assert data['keyboard']['azimuth']!=data['restored']['azimuth']
 assert not data['overflow'] and not data['brokenImages']
 (OUT/'browser-controls-qa.json').write_text(json.dumps(dict(passed=True,**data),ensure_ascii=False,indent=2),encoding='utf-8')
 print('CONTROLS OK actual 4x90 orbit, zoom in/out, keyboard',flush=True)

