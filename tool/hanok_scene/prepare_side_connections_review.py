from pathlib import Path
import json,shutil,hashlib,re
ROOT=Path(__file__).resolve().parents[2];REVIEW=ROOT/'assets_unused/pending_review/hwalju-blueprint-review';OUT=REVIEW/'side-connections';OUT.mkdir(exist_ok=True)
MAIN=Path('C:/dev/hangulsori/ko_lernen_app');ART=MAIN/'assets_unused/pending_review/personal_hanok_v3';BP=ART/'ildu_Blueprint'
OLD=Path('C:/dev/hangulsori/ko_lernen_app_worktrees/hanok-warm-stone-20260923/assets_unused/pending_review/ildu_spatial_preservation_20260922')
refs={
 'main-gate-canonical.png':ART/'references/sotdaeulmun/jin_20260914/sotdaeulmun_stone_wall_right_oblique_closed.png',
 'main-gate-inner-photo.png':ART/'turnaround_2d/ildu_sotdaeulmun_v02/references/photos/03_inner_gate_signboards.png',
 'toilet-canonical.png':ART/'화장실.png',
 'photo-numaru-wall.png':Path('C:/Users/vjinn/AppData/Local/Temp/codex-clipboard-f194cb0b-9a74-43ce-af16-fd6f83628b19.png'),
 'photo-wall-corridor.png':Path('C:/Users/vjinn/AppData/Local/Temp/codex-clipboard-956c2909-42cd-4798-a2c8-17bd8d3052b9.png'),
 'photo-pine-garden.png':Path('C:/Users/vjinn/AppData/Local/Temp/codex-clipboard-be464e82-7762-406e-8f02-18428b1bdced.png'),
 'photo-numaru-front.png':Path('C:/Users/vjinn/AppData/Local/Temp/codex-clipboard-7efa0156-3cf1-4fc5-bc65-81bb74f4dfe1.png'),
 'photo-left-high-wall.png':Path('C:/Users/vjinn/AppData/Local/Temp/codex-clipboard-717a2ebf-ace8-406e-a860-ef418efca977.png'),
 'photo-right-front.png':Path('C:/Users/vjinn/Pictures/Screenshots/스크린샷 2026-09-23 113130.png'),
 'photo-right-wall.png':Path('C:/Users/vjinn/Pictures/Screenshots/스크린샷 2026-09-23 113121.png'),
 'photo-left-rear.png':Path('C:/Users/vjinn/Pictures/Screenshots/사랑채 뒤쪽 화장실 및 사랑채 뒷문.png'),
 'photo-left-front.png':Path('C:/Users/vjinn/Pictures/Screenshots/스크린샷 2026-09-22 144739.png'),
 'canonical-gate.png':ART/'hyeopmun_try03_blueprint_colored.png',
 'canonical-warehouse.png':ART/'changgo_final.png',
 'site002.jpg':next(BP.glob('*기록화보고서*전체_배치도.jpg')),
 'gate090.jpg':next((BP/'협문').glob('*안사랑채_협문_정면도,좌측면도.jpg')),
 'gate021.jpg':OLD/'side-gates-v27/references/left-door021.jpg',
 'warehouse-plan.jpg':next(BP.glob('*보수공사_창고_평면도.jpg')),
 'warehouse-front.jpg':next(BP.glob('*보수공사_창고_정면도.jpg')),
 'ansarang-canonical.png':OLD/'estate-connected-v28/references/ansarang-canonical.png',
 'ansarang048.jpg':OLD/'side-gates-v27/references/ansarang048.jpg',
 'ansarang049.jpg':next(BP.glob('*별당_정면도.jpg')),
 'ansarang055.jpg':next(BP.glob('*별당_창호도.jpg')),
 'photo-open-path.png':Path('C:/Users/vjinn/AppData/Local/Temp/codex-clipboard-6eb12040-8e63-4b71-a5c6-d22f0c3fb9a9.png'),
 'photo-open-path-right.jpg':Path('C:/Users/vjinn/.codex/codex-remote-attachments/01a0e7fc-a227-7751-9096-a43234ca27f9/34DA04A7-8E6C-4B11-A74A-D9A587D6EEDD/1-사진-1.jpg'),
 'photo-garden-wall.png':Path('C:/Users/vjinn/AppData/Local/Temp/codex-clipboard-571e512c-6ec2-49b6-abe4-56fd84cd577b.png'),
 'photo-ansarang.png':Path('C:/Users/vjinn/AppData/Local/Temp/codex-clipboard-b6658f4d-1515-4147-b5a7-cb4819f6a0f2.png'),
}
for prefix in ('ildu_changgo','ildu_sadang_hyeopmun'):
    for path in (MAIN/'assets/illustrations/personal_hanok_v3/turnarounds').glob(prefix+'_*.png'):refs[path.name]=path
manifest=[]
prior={r['copy']:r for r in json.loads((OUT/'reference-manifest.json').read_text(encoding='utf8'))} if (OUT/'reference-manifest.json').exists() else {}
for name,path in refs.items():
    if not path.exists() and (OUT/name).exists() and name in prior:
        assert hashlib.sha256((OUT/name).read_bytes()).hexdigest()==prior[name]['sha256'];manifest.append(prior[name]);continue
    shutil.copyfile(path,OUT/name);digest=hashlib.sha256(path.read_bytes()).hexdigest();assert hashlib.sha256((OUT/name).read_bytes()).hexdigest()==digest
    manifest.append({'source':str(path),'copy':name,'sha256':digest,'bytes':path.stat().st_size})
(OUT/'reference-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
js=(REVIEW/'terrain/viewer.js').read_text(encoding='utf8')
js=js.replace('중문채 지면 수정 전후를 회전하고 확대하는 3D 공간','사랑채 양쪽 협문과 창고를 회전하고 문을 여닫는 3D 공간')
js=js.replace("ground.receiveShadow=true;scene.add(ground);","ground.receiveShadow=true;")
start=js.index('const views=');end=js.index(';',start)
js=js[:start]+"const views={whole:[[-25,-36,27],[8,-2,1.5]],left:[[-6,-5,4.1],[-3.2,3.8,2.2]],leftRear:[[-5,12,4.4],[-2.1,3.8,2.4]],right:[[17,-10,3.6],[18.092,.083,1.9]],rightRear:[[22,10,4.2],[18.092,.083,1.9]],warehouse:[[-.5,3.5,5.5],[-8.634,3.105,2]],plan:[[8,-2,50],[8,-2,0]],detail:[[17.3,-5.8,3],[18.092,.083,2.15]],ansarang:[[12,-17,6],[24,-9.7,2]],path:[[11,-9.75,2],[24,-9.75,1.8]]}"+js[end:]
js=js.replace('path:[[11,-9.75,2],[24,-9.75,1.8]]','path:[[13,-13.5,1.72],[24,-14.2,1.8]],ansarangRight:[[16,-22,3.7],[23.7,-13.9,1.9]],joinery:[[19.7,-14,2.2],[23.3,-13.7,1.75]]')
js=js.replace('path:[[13,-13.5,1.72]','path:[[11.3,-13.5,1.72]')
js=js.replace('whole:[[-25,-36,27],[8,-2,1.5]]','whole:[[-30,-43,35],[9,-3,1.5]]').replace('plan:[[8,-2,50],[8,-2,0]]','plan:[[10,-4,59],[10,-4,0]]')
js=js.replace('const views={','const views={enclosure:[[6,-30,27],[22,-10,1.3]],numaruWall:[[21,-19,8],[12.7,-5.5,1.7]],leftJoint:[[-3,10,6],[-5,3.8,1.9]],wallCorridor:[[18,-18,3.5],[18,.1,1.8]],')
js=js.replace("active='connection'","active='enclosure'")
js=js.replace('Math.max(.45,1.2/camera.aspect)','Math.max(1,1.2/camera.aspect)')
js=js.replace('sun.shadow.mapSize.set(4096,4096)','sun.shadow.mapSize.set(Math.min(8192,renderer.capabilities.maxTextureSize),Math.min(8192,renderer.capabilities.maxTextureSize))')
js=js.replace('left:-18,right:18,top:18,bottom:-18,near:1,far:65','left:-36,right:36,top:30,bottom:-30,near:.1,far:100')
js=js.replace('sun.shadow.bias=-.00005;sun.shadow.normalBias=.008','sun.shadow.bias=.00002;sun.shadow.normalBias=.003')
js=js.replace("after?'이어지는 흙 지면':'수정 전 바닥판'","after?'양쪽 협문·창고 연결':'확정 사랑채·중문채'")
js=js.replace("loadAsync('pair-corrected.glb'","loadAsync('connected.glb'")
old="if(d.source_object_name.startsWith('TerrainFix.'))changed.push(o);else {const end=d.construction_building==='jung'?12:16;"
new="if(d.source_object_name.startsWith('ConnectionSite.')||['left_changgo','right_ansarang','changgo','ansarang','connection_garden'].includes(d.construction_building))changed.push(o);else {const end=d.construction_building==='jung'?12:16;"
assert old in js;js=js.replace(old,new)
js=js.replace("state(true);host.dataset.loaded", "await setupDoors();state(true);host.dataset.loaded")
js=js.replace('controls.update();if(dirty){','controls.update();animateDoors();if(dirty){')
js=js.replace("status.textContent='같은 시점에서 수정 전·후를 바꾸세요. 드래그로 회전 · 휠로 확대'","status.textContent='드래그로 회전 · 휠로 확대 · 협문을 열어 안쪽 길을 확인하세요'")
anchor="try{\n const gltf="
doorcode='''const pivots=[];
async function setupDoors(){
 const contract=await(await fetch('connection-contract.json')).json();scene.updateMatrixWorld(true);
 for(const door of contract.doors){if(!['left_changgo','right_ansarang'].includes(door.building))continue;
  for(let i=0;i<door.hinges.length;i++){
   const parts=changed.filter(o=>o.userData.source_object_name?.startsWith(door.prefix+'.leaf'+(i+1)+'.'));
   const pivot=new THREE.Group();pivot.position.copy(vec(door.hinges[i]));scene.add(pivot);pivot.updateMatrixWorld(true);
   for(const part of parts)pivot.attach(part);
   pivots.push({pivot,building:door.building,leaf:i,sign:door.rotationSigns[i],target:0});
  }
 }
 doorMode('photo',true);
}
function doorMode(mode,instant=false){
 for(const p of pivots){const deg=mode==='closed'?0:mode==='open'?78:p.building==='left_changgo'||p.leaf===1?78:0;p.target=THREE.MathUtils.degToRad(deg)*p.sign;if(instant)p.pivot.rotation.y=p.target;}
 for(const b of document.querySelectorAll('[data-door]'))b.setAttribute('aria-pressed',String(b.dataset.door===mode));dirty=shadowDirty=true;
}
for(const b of document.querySelectorAll('[data-door]'))b.onclick=()=>doorMode(b.dataset.door);
function animateDoors(){for(const p of pivots){const d=p.target-p.pivot.rotation.y;if(Math.abs(d)>.0001){p.pivot.rotation.y+=d*.2;dirty=shadowDirty=true;}}}
'''
assert anchor in js;js=js.replace(anchor,doorcode+anchor)
if (OUT/'forecourt-build-validation.json').exists():
 js=js.replace("'changgo','ansarang','connection_garden'","'changgo','ansarang','connection_garden','main_gate','toilet','forecourt_wall'")
 js=js.replace("['left_changgo','right_ansarang'].includes(door.building)","['left_changgo','right_ansarang','main_gate','toilet'].includes(door.building)")
 js=js.replace("p.building==='left_changgo'||p.leaf===1?78:0","p.building==='left_changgo'||p.building==='main_gate'||p.leaf===1?78:0")
 js=js.replace('const views={','const views={estate:[[-39,-51,44],[3,-5,1.5]],estatePlan:[[3,-6,76],[3,-6,0]],mainGate:[[-14,-24,7],[-6.5,-13.18,2.35]],mainInside:[[0,-2,6.8],[-6.5,-13.18,2.3]],mainDetail:[[-8,-19,3.4],[-6.6,-14.4,2.1]],toilet:[[-24,-15,5.5],[-18.5,-7,1.7]],westBoundary:[[-31,-19,20],[-13,-7,1.1]],eastBoundary:[[28,-36,26],[6,-15,1.3]],')
 js=js.replace("active='enclosure'","active='estate'")
 js=js.replace('양쪽 협문·창고 연결','대문·화장실까지 연결')
 js=js.replace('toilet:[[-24,-15,5.5],[-18.5,-7,1.7]]','toilet:[[-16,-10,3.5],[-18.5,-7,1.5]]')
 js=js.replace('estatePlan:[[3,-6,76],[3,-6,0]]','estatePlan:[[3,0,86],[3,0,0]]')
 js=js.replace("드래그로 회전 · 휠로 확대 · 협문을 열어 안쪽 길을 확인하세요","드래그로 회전 · 휠로 확대 · 문을 열어 마당과 방 안쪽을 확인하세요")
 js=js.replace("loadAsync('connected.glb'", "loadAsync('connected.glb?v="+hashlib.sha256((OUT/'connected.glb').read_bytes()).hexdigest()[:12]+"'")
if (OUT/'photo-gate-build-validation.json').exists():
 js=js.replace("active='estate'","active='mainGate'")
 js=js.replace('const views={','const views={warehouseEnd:[[-9.6,-9,3.3],[-8.65,-3.535,2.2]],photoFront:[[-8.85,-31.0,3.3],[-6.5,-13.18,2.25]],photoInside:[[-5.33,-4.26,3.2],[-6.5,-13.18,2.25]],soffit:[[-6.95,-16.6,1.65],[-6.45,-12.8,3.4]],')
 js=js.replace('function view(id){active=id;','function view(id){active=id;host.dataset.view=id;for(const b of document.querySelectorAll("[data-view]"))b.setAttribute("aria-pressed",String(b.dataset.view===id));')
 js=js.replace('controls.maxDistance=65','controls.maxDistance=160').replace('PerspectiveCamera(42,1,.04,100)','PerspectiveCamera(42,1,.04,250)')
 js=js.replace('사랑채 양쪽 협문과 창고를 회전하고 문을 여닫는 3D 공간','사랑채와 안사랑채, 솟을대문과 화장실을 회전하고 문을 여닫는 3D 공간')
(OUT/'viewer.js').write_text(js,encoding='utf8')
style=re.search(r'<style>.*?</style>',(REVIEW/'review.html').read_text(encoding='utf8'),re.S)[0]
style=style.replace('</style>','.triplet{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:12px}.triplet img{width:100%}.eight{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:6px}.eight img{width:100%}.tag{font-size:13px;color:#75634b}#space{height:min(70vh,760px)}@media(max-width:750px){.triplet{grid-template-columns:1fr}.eight{grid-template-columns:repeat(2,minmax(0,1fr))}}</style>')
html='''<!doctype html><html lang="ko"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>사랑채 양쪽 협문과 창고 연결</title>STYLE
<script type="importmap">{"imports":{"three":"../vendor/build/three.module.js","three/addons/":"../vendor/examples/jsm/"}}</script>
<main><div class="eyebrow">한글소리 · 확정 사랑채–중문채에서 이어지는 공간</div><h1>왼쪽은 창고로, 오른쪽은 안사랑채 길로</h1>
<p>사랑채 양쪽에 서로 다른 협문과 돌담을 연결했습니다. 왼쪽은 창고 옆 낮은 담장과 마당으로, 오른쪽은 돌계단을 올라 안쪽 높은 마당으로 이어집니다.</p>
<fieldset id="controls" disabled><button id="before" aria-pressed="false">확정 사랑채·중문채</button><button id="after" aria-pressed="true">양쪽 협문·창고 연결</button><span id="state">양쪽 협문·창고 연결</span><br><button data-view="whole">전체 연결</button><button data-view="left">왼쪽 협문 앞</button><button data-view="leftRear">왼쪽 협문 뒤</button><button data-view="right">오른쪽 돌계단</button><button data-view="rightRear">오른쪽 안마당</button><button data-view="warehouse">창고 가까이</button><button data-view="plan">위에서 배치 보기</button><br><button data-door="photo" aria-pressed="true">사진처럼 열기</button><button data-door="open" aria-pressed="false">협문 모두 열기</button><button data-door="closed" aria-pressed="false">협문 닫기</button></fieldset>
<div id="space"></div><p id="status" role="status">3D 준비 중…</p>
<p class="notice">확정한 사랑채·중문채와 활주를 유지했습니다. 왼쪽 협문은 창고의 기둥선까지 낮은 담장으로 연결하고, 오른쪽 협문에는 앞뒤 높이가 다른 지면과 돌계단을 맞췄습니다. 안사랑채 본체는 이번 제작 범위에 포함하지 않았습니다.</p>
<section><h2>왼쪽 협문 · 창고</h2><div class="grid">LEFT</div></section>
<section><h2>오른쪽 협문 · 돌담</h2><div class="grid">RIGHT</div></section>
<section><h2>채택된 원화와 창고 제작본</h2><div class="triplet">CANONICAL</div><p class="tag">창고는 정본의 여섯 쌍 널문과 황토색 상부 벽, 낮고 긴 맞배지붕을 따랐습니다. 도면의 전체 치수는 13,280 × 2,880mm입니다. 정본의 여섯 문 배치는 실측 평면도의 출입구 배치와 다릅니다.</p></section>
<section><details><summary>정본 8방향 이미지 펼치기</summary><h3>협문</h3><div class="eight">GATE8</div><h3>창고</h3><div class="eight">STORE8</div></details></section>
<section><h2>배치와 도면</h2><div class="grid">PLANS</div></section>
<section><details><summary>제작 근거와 남은 추정</summary><p>오른쪽은 090 정면·측면의 서로 다른 지붕 곡선, 다섯 단 돌계단과 높은 안마당을 참고했습니다. 왼쪽은 전체 배치도 002와 양쪽 실사로 위치·방향을 대조했습니다. 큰 왼쪽 문과 021 도면의 대응은 배치와 사진을 통한 해석입니다.</p><p>왼쪽 마당과 창고는 확정 지면의 +600mm에 맞췄고, 오른쪽 안쪽 마당은 +720mm로 이어집니다. 이는 공통 측량 기준점이 없는 검토 좌표입니다. 기단 주위 경사와 담장 접합부의 세부 돌 쌓기는 재구성입니다.</p><p>확정 연결본의 건물 부재 940개를 보존하고, 이전 3D에서 도면·정본과 대조한 협문·창고 부재 430개를 재사용했습니다. 앱 에셋은 교체하지 않았습니다.</p><p><a href="../terrain/review.html">확정한 사랑채·중문채</a> · <a href="reference-manifest.json">사진·정본·도면 원본 기록</a> · <a href="connection-contract.json">배치와 치수 근거</a> · <a href="delivery-validation.json">기존 3D 보존 검사</a></p></details></section></main><script type="module" src="viewer.js"></script></html>'''
def fig(name,caption):return f'<figure><a href="{name}"><img loading="lazy" src="{name}" alt="{caption}"></a><figcaption>{caption}</figcaption></figure>'
left=''.join(fig(a,b) for a,b in [('photo-left-front.png','첨부 실사 · 창고 쪽에서 바라본 협문'),('left-front.png','3D · 창고와 왼쪽 협문 연결'),('photo-left-rear.png','첨부 실사 · 사랑채 뒤에서 바라본 협문'),('left-rear.png','3D · 왼쪽 협문 뒷면')])
right=''.join(fig(a,b) for a,b in [('photo-right-front.png','첨부 실사 · 별도 협문의 돌계단'),('right-front.png','3D · 오른쪽 협문 앞'),('photo-right-wall.png','첨부 실사 · 사랑채 옆 기와 얹은 돌담'),('right-rear.png','3D · 오른쪽 협문과 안쪽 높은 마당')])
canonical=''.join(fig(a,b) for a,b in [('canonical-gate.png','채택된 협문 원화 · 재료와 세부의 기준'),('canonical-warehouse.png','채택된 창고 원화'),('warehouse.png','이번 연결본의 창고 · 단독 검토 시점')])
plans=''.join(fig(a,b) for a,b in [('plan.png','이번 3D · 위에서 본 연결 배치'),('site002.jpg','002 · 전체 배치도'),('gate090.jpg','090 · 오른쪽 협문 정면과 측면'),('gate021.jpg','021 · 왼쪽 큰 문과 대응시킨 참고 도면'),('warehouse-plan.jpg','창고 평면 · 13,280 × 2,880mm'),('warehouse-front.jpg','창고 정면 · 정본과 다른 개구부 배치는 구분')])
eight=lambda prefix:''.join(fig(name,Path(name).stem.split('_',3)[-1]) for name in sorted(refs) if name.startswith(prefix))
for key,value in [('STYLE',style),('LEFT',left),('RIGHT',right),('CANONICAL',canonical),('PLANS',plans),('GATE8',eight('ildu_sadang_hyeopmun_')),('STORE8',eight('ildu_changgo_'))]:html=html.replace(key,value)
html=html.replace('왼쪽은 창고로, 오른쪽은 안사랑채 길로','협문과 기와담, 열린 안사랑채 마당')
html=html.replace('사랑채 양쪽에 서로 다른 협문과 돌담을 연결했습니다. 왼쪽은 창고 옆 낮은 담장과 마당으로, 오른쪽은 돌계단을 올라 안쪽 높은 마당으로 이어집니다.','정본의 나뭇결과 돌의 색면, 겹기와와 고리 철물을 입체 부재에 옮겼습니다. 사랑마당과 안사랑채 앞마당은 문 없는 통로로 이어집니다. 돌계단 협문은 그 옆의 별도 출입구입니다.')
html=html.replace('안사랑채 본체는 이번 제작 범위에 포함하지 않았습니다.','안사랑채 본체와 앞마당을 연결하고, 낮은 기와담 사이에 문 없는 길을 열었습니다.')
html=html.replace('오른쪽 협문에는 앞뒤 높이가 다른 지면과 돌계단을 맞췄습니다.','오른쪽 협문 계단은 사랑마당 쪽을 향하고, 문 뒤쪽은 높은 안쪽 지면으로 이어집니다.')
html=html.replace('<button data-view="warehouse">','<button data-view="detail">협문 세부 확대</button><button data-view="path">문 없는 연결길</button><button data-view="ansarang">안사랑채 앞마당</button><button data-view="warehouse">')
html=html.replace('오른쪽 안마당</button>','협문 뒤쪽</button>')
html=html.replace('오른쪽 안쪽 마당은 +720mm로 이어집니다.','별도 협문 뒤쪽은 +720mm, 안사랑채 앞마당은 +120mm로 이어집니다.')
html=html.replace('이전 3D에서 도면·정본과 대조한 협문·창고 부재 430개를 재사용했습니다.','창고 부재 199개를 재사용하고, 안사랑채 361개 부재의 표면과 작은 세부를 보강했습니다. 협문과 기와담에는 정본 표면과 새 철물을 적용했습니다.')
html=html.replace('<button data-view="ansarang">안사랑채 앞마당</button>','<button data-view="ansarang">안사랑채 앞마당</button><button data-view="ansarangRight">안사랑채 오른쪽</button><button data-view="joinery">창호·마루 가까이</button>')
detail='<section><h2>협문 정본 · 실사 · 이번 3D</h2><div class="triplet">'+''.join(fig(a,b) for a,b in [('canonical-gate.png','협문 정본 · 목재와 돌, 기와의 표현 기준'),('photo-right-front.png','실사 · 계단과 문의 비례'),('gate-detail.png','이번 3D · 닫힌 문과 철물 세부')])+'</div><p>정본의 원본 픽셀을 부재별 표면에 사용했습니다. 고리, 꽃 모양 철판, 연결핀은 실제 입체입니다. 양쪽 협문의 서로 다른 문폭과 지붕 깊이는 도면 기준을 유지했습니다.</p></section>'
route='<section><h2>사랑마당에서 안사랑채로 · 문 없는 길</h2><div class="grid">'+''.join(fig(a,b) for a,b in [('photo-open-path.png','첨부 실사 · 담 끝 사이의 열린 통로'),('open-path.png','이번 3D · 사랑마당에서 안사랑채로'),('photo-ansarang.png','실사 · 안사랑채 앞마루'),('ansarang.png','이번 3D · 안사랑채 앞마당'),('photo-garden-wall.png','실사 · 층층이 기와를 얹은 낮은 돌담'),('ansarang048.jpg','048 · 안사랑채 평면')])+'</div><p class="tag">열린 동선은 첨부 사진으로 확인했습니다. 정원 담장의 세부 좌표와 지면 높이는 배치도와 사진에 맞춘 재구성이며 실측 확정값은 아닙니다.</p></section>'
html=html.replace('<section><h2>왼쪽 협문',detail+route+'<section><h2>왼쪽 협문')
comparison='<section><h2>안사랑채 · 목재와 창호의 깊이</h2><div class="triplet">'+''.join(fig(a,b) for a,b in [('ansarang-canonical.png','채택 원화 · 네 칸 구성과 창호의 기준'),('ansarang-before.png','같은 시점 · 표면 보강 전'),('ansarang.png','같은 시점 · 나뭇결과 기단 보강 후'),('ansarang-left.png','왼쪽 첫 칸과 옆면'),('ansarang-joinery.png','문살 · 문틀 · 마루의 깊이'),('ansarang055.jpg','055 · 창호 치수와 살 구성')])+'</div><p>문 없는 길은 왼쪽 첫 칸 앞으로 옮겼습니다. 목재의 결과 옹이, 문틀 안쪽 그림자, 기와의 색 차이와 기단의 돌결을 보강했습니다. 나무의 잔갈라짐과 돌의 마모는 실측 손상을 복제한 것이 아닌 일러스트 표현입니다.</p></section>'
html=html.replace('<section><h2>왼쪽 협문',comparison+'<section><h2>왼쪽 협문')
html=html.replace('photo-open-path.png','photo-open-path-right.jpg').replace('첨부 실사 · 담 끝 사이의 열린 통로','최신 첨부 장면 · 열린 담 너머 안사랑채 오른쪽 끝')
html=html.replace('ansarang-left.png','ansarang-right.png').replace('왼쪽 첫 칸과 옆면','오른쪽 끝 칸과 옆마루').replace('문 없는 길은 왼쪽 첫 칸 앞으로 옮겼습니다.','최신 영상 장면에 맞춰 문 없는 길을 오른쪽 끝 칸 앞으로 옮겼습니다.')
html=html.replace('<button data-view="whole">전체 연결</button>','<button data-view="whole">전체 연결</button><button data-view="numaruWall">누마루 앞 담장</button><button data-view="wallCorridor">담장 안쪽 길</button>')
wall_review='<section><h2>누마루 앞 담장과 왼쪽 협문의 높은 담</h2><div class="grid">'+''.join(fig(a,b) for a,b in [('photo-numaru-front.png','실사 · 누마루 앞 기단과 돌담'),('numaru-wall.png','이번 3D · 누마루 앞쪽 선을 따라 이어지는 담'),('photo-left-high-wall.png','실사 · 왼쪽 협문 오른쪽의 높은 연결 담'),('left-front.png','이번 3D · 문 위쪽 높이까지 올라간 돌쌓기'),('photo-wall-corridor.png','실사 · 안사랑채 앞마당과 정원 담'),('wall-corridor.png','이번 3D · 담장 안쪽 연결길')])+'</div><p>긴 담장은 누마루 앞쪽 정원 경계로 옮겼습니다. 왼쪽 협문과 사랑채 사이 담은 아래 돌쌓기를 보충해 높였습니다. 문 없는 길에서는 안사랑채 오른쪽 끝 칸이 먼저 보입니다.</p></section>'
html=html.replace('<section><h2>협문 정본',wall_review+'<section><h2>협문 정본')
html=html.replace('긴 담장은 누마루 앞쪽 정원 경계로 옮겼습니다.','긴 담장은 표시하신 누마루 오른쪽 앞 모서리에서 곧게 이어집니다. 창고와 협문 사이 담장의 꺾임을 없애고 문기둥·건물 접합부를 연결했습니다.')
html=html.replace('<button data-view="leftRear">','<button data-view="leftJoint">창고·협문 접합</button><button data-view="leftRear">')
html=html.replace(fig('left-rear.png','3D · 왼쪽 협문 뒷면'),fig('left-rear.png','3D · 왼쪽 협문 뒷면')+fig('left-junction.png','3D · 곧은 창고 담장과 협문 기둥의 접합'))
html=html.replace('정본의 원본 픽셀을 부재별 표면에 사용했습니다.','정본의 목재와 돌 표면을 입체 부재에 사용했습니다. 기와는 주변 지붕과 이어지는 회색 도자기 질감을 적용했습니다.')
html=html.replace('<button data-view="plan">','<button data-view="enclosure">안사랑채 ㅁ자 담장</button><button data-view="plan">')
enclosure_review='<section><h2>안사랑채를 둘러싼 독립된 마당</h2><div class="grid">'+fig('ansarang-enclosure.png','이번 3D · 건물과 떨어진 ㅁ자 외곽 담장')+fig('site002.jpg','002 배치도 · 별당 건물 바깥을 도는 담장 경계')+'</div><p>안사랑채 벽에 붙였던 담은 제거했습니다. 외곽 담장은 건물 뒤와 양옆의 공간을 남기고 마당을 감싸며, 돌계단 협문과 문 없는 열린 길을 각각 유지합니다.</p></section>'
html=html.replace('<section><h2>누마루 앞 담장',enclosure_review+'<section><h2>누마루 앞 담장')
html=html.replace('src="viewer.js"','src="viewer.js?v=ansarang-enclosure-8"')
if (OUT/'forecourt-build-validation.json').exists():
 html=html.replace('협문과 기와담, 열린 안사랑채 마당','안사랑채에서 솟을대문까지')
 html=html.replace('사랑채 양쪽 협문과 창고 연결','안사랑채 · 솟을대문 · 화장실 연결')
 html=html.replace('정본의 나뭇결과 돌의 색면, 겹기와와 고리 철물을 입체 부재에 옮겼습니다. 사랑마당과 안사랑채 앞마당은 문 없는 통로로 이어집니다. 돌계단 협문은 그 옆의 별도 출입구입니다.','안사랑채의 독립된 마당에서 솟을대문으로, 창고에서 왼쪽 화장실 공간을 돌아 대문으로 이어집니다. 높은 대문 지붕과 낮은 양옆 지붕, 문살과 판문, 돌담 위 겹기와를 가까이 살펴보세요.')
 buttons=''.join(f'<button data-view="{k}">{v}</button>' for k,v in [('estate','대문까지 전체'),('mainGate','솟을대문 앞'),('mainInside','대문 안쪽'),('mainDetail','대문 철물·현판'),('toilet','왼쪽 화장실'),('westBoundary','창고–대문 담장'),('eastBoundary','안사랑채–대문 담장'),('estatePlan','전체 배치 위에서')])
 html=html.replace('<button data-view="whole">',buttons+'<button data-view="whole">')
 html=html.replace('협문 모두 열기','문 모두 열기').replace('협문 닫기','문 모두 닫기')
 html=html.replace('양쪽 협문·창고 연결','대문·화장실까지 연결')
 forecourt='<section><h2>솟을대문과 왼쪽 화장실</h2><div class="grid">'+''.join(fig(a,b) for a,b in [('main-gate-canonical.png','솟을대문 정본 · 높은 중앙 문과 양쪽 두 칸'),('main-gate-front.png','이번 3D · 솟을대문과 이어지는 기와담'),('main-gate-inner-photo.png','보관 실사 · 대문 안쪽의 목구조와 현판'),('main-gate-inner.png','이번 3D · 대문 안쪽과 양옆 툇마루'),('toilet-canonical.png','화장실 정본 · 치우친 판문과 팔작지붕'),('toilet.png','이번 3D · 창고와 대문 사이 왼쪽 화장실'),('warehouse-to-gate.png','창고에서 화장실 공간 바깥을 돌아 대문으로'),('ansarang-to-gate.png','안사랑채 외곽 담장에서 솟을대문으로'),('estate-plan.png','전체 3D 배치'),('site002.jpg','002 · 대문채 10번과 화장실2 12번')])+'</div><p class="tag">건물 위치와 외곽 담장 경로는 002 배치도를 대조했습니다. 대문·화장실의 개별 실측 입면은 찾지 못해 정본 비례를 사용했으며, 높이·숨은 깊이·돌쌓기는 제작 해석입니다.</p></section>'
 html=html.replace('<section><h2>안사랑채를 둘러싼 독립된 마당',forecourt+'<section><h2>안사랑채를 둘러싼 독립된 마당')
 html=html.replace('viewer.js?v=ansarang-enclosure-8','viewer.js?v=forecourt-10')
if (OUT/'photo-gate-build-validation.json').exists():
 buttons=''.join(f'<button data-view="{k}">{v}</button>' for k,v in [('photoFront','실사 정면 시점'),('photoInside','안쪽 창호·마루'),('soffit','처마 밑·다섯 현판'),('warehouseEnd','드러난 창고 끝면')])
 html=html.replace('<button data-view="mainGate">',buttons+'<button data-view="mainGate">')
 photo_review='<section><h2>첨부 실사로 다시 만든 솟을대문</h2><div class="grid">'+''.join(fig(a,b) for a,b in [('photo-gate-references/09.png','첨부 실사 · 높은 돌쌓기와 낮은 가로살 창'),('main-gate-photo-front.png','이번 3D · 같은 정면 방향의 대문'),('photo-gate-references/07.png','첨부 실사 · 안쪽 네 창호문과 긴 툇마루'),('main-gate-photo-inner.png','이번 3D · 안쪽 창호와 마루'),('photo-gate-references/06.png','첨부 실사 · 처마 밑 흰 회벽과 현판'),('main-gate-soffit.png','이번 3D · 통로의 깊이와 다섯 현판'),('photo-gate-references/11.png','첨부 실사 · 창고 끝면 옆에 붙은 낮은 담'),('warehouse-end.png','이번 3D · 끝면을 가리지 않는 모서리 접합'),('photo-gate-references/08.png','첨부 전체 한옥도 · 건물과 마당의 관계'),('estate.png','이번 3D · 대문과 창고, 화장실 연결')])+'</div><p>솟을대문은 실사에 맞춰 돌바닥 통로, 깊숙한 두 짝 문, 작은 가로살 창과 다섯 장 현판을 다시 구성했습니다. 창고 끝면에는 황토와 회벽 마감을 두고, 낮은 담장을 바깥 모서리에 연결했습니다. 계량 치수와 보이지 않는 부분은 사진을 통한 재구성입니다.</p></section>'
 html=html.replace('<section><h2>솟을대문과 왼쪽 화장실',photo_review+'<section><h2>솟을대문과 왼쪽 화장실')
 html=html.replace('솟을대문 정본 · 높은 중앙 문과 양쪽 두 칸','기존 원화 · 목재와 돌의 일러스트 표현 참고')
 html=html.replace('대문·화장실의 개별 실측 입면은 찾지 못해 정본 비례를 사용했으며, 높이·숨은 깊이·돌쌓기는 제작 해석입니다.','솟을대문의 형상은 새로 첨부한 실사를, 화장실은 채택 원화를 기준으로 했습니다. 실측 입면이 없는 높이·숨은 깊이·돌쌓기는 제작 해석입니다.')
 html=html.replace('viewer.js?v=forecourt-10','viewer.js?v=photo-gate-12')
(OUT/'review.html').write_text(html,encoding='utf8');print(OUT/'review.html')
