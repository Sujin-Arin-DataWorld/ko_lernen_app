"""Actual browser stage/surface/interaction QA for the three approved gates."""
import json
from browser_qa import run,OUT
run('reload');run('eval','reviewQA.ready().then(()=>true)')
records=[]
for key in ['left_changgo','right_ansarang','sadangmun']:
 js='''(async()=>{await reviewQA.selectBuilding(KEY);const b=reviewQA.catalog.buildings.find(b=>b.key===KEY);const states=[];for(const s of b.steps){reviewQA.setStage(s.sequence);await new Promise(r=>requestAnimationFrame(r));states.push({state:reviewQA.state(),surface:reviewQA.surfaceState()});}return states;})()'''.replace('KEY',json.dumps(key))
 states=json.loads(run('eval',js));counts=[s['state']['visibleMeshes'] for s in states]
 assert counts==sorted(counts)
 assert all(s['state']['loaded'] and not s['state']['error'] and len(s['surface']['textures'])>=4 for s in states)
 assert all(s['surface']==states[0]['surface'] for s in states)
 records.append(dict(key=key,stages=states,sharedSurfaceStable=True))
 run('eval',"document.querySelector('[data-view=hero]').click()")
 run('screenshot',str(OUT/(key+'-material-3d.png')))
 print('COLORED STAGES OK',key,len(states),flush=True)
for stage in [3,6,8]:
 run('eval',f'reviewQA.setStage({stage})')
 run('screenshot',str(OUT/f'shrine-pilot-stage-{stage}.png'))
run('select','#artLighting','source');run('screenshot',str(OUT/'shrine-source-light.png'))
run('select','#artLighting','illustrated');run('click','[data-view=back]');run('screenshot',str(OUT/'shrine-pilot-back.png'))
run('click','[data-view=hero]')
responsive=[]
for width in [402,320]:
 run('set','viewport',str(width),'874');run('eval','scrollTo(0,0)')
 data=json.loads(run('eval',"({width:innerWidth,overflow:document.documentElement.scrollWidth>innerWidth,viewer:document.getElementById('viewer').getBoundingClientRect().toJSON(),brokenImages:[...document.images].filter(i=>!i.complete||!i.naturalWidth).map(i=>i.src)})"))
 assert not data['overflow'] and not data['brokenImages'],data
 responsive.append(data);run('screenshot',str(OUT/f'shrine-pilot-mobile-{width}.png'))
run('set','viewport','1440','1000');run('eval','scrollTo(0,0)');run('screenshot',str(OUT/'shrine-pilot-final.png'))
(OUT/'material-browser-qa.json').write_text(json.dumps(dict(passed=True,gates=records,responsive=responsive),ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('MATERIAL BROWSER QA PASSED')
