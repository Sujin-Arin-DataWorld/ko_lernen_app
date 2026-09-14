'use strict';
const BASE='./';
const $=id=>document.getElementById(id);
let data,building,step=0,timer=null;
const notes={
'site-route':'문과 방, 마루가 생길 자리와 앞뒤로 이어지는 통행길을 살펴보세요.',
'site-rooms':'방 세 칸과 앞 툇마루에 필요한 깊이를 함께 확보해요.',
'site-household':'부엌·방·대청은 서로 다른 높이와 동선으로 연결돼요.',
'site-storage':'문으로 들어온 짐을 두 보관 공간으로 옮길 수 있어야 해요.',
'stone-foundation':'초석은 나무기둥을 받쳐요. 기단의 높이는 건물마다 달라요.',
'posts':'앞쪽과 뒤쪽 기둥 사이의 거리가 실내 깊이를 만들어요.',
'posts-floor-support':'툇마루 아래에도 기둥과 받침이 필요해요.',
'beams-purlins':'보는 기둥 사이를 잇고, 도리는 서까래를 받아요. 연결점을 따라가 보세요.',
'hip-frame':'안채의 팔작지붕은 모서리에서도 부재가 맞물려야 해요.',
'rafters-eaves':'서까래는 도리에 걸쳐 처마까지 뻗어요. 처마가 벽 밖으로 나온 길이를 살펴보세요.',
'roof-bed':'서까래 위의 바탕층이 기와를 받을 면을 만들어요.',
'tiles':'기와가 겹쳐진 방향과 지붕 경사를 따라 빗물이 흘러요.',
'room-walls':'벽은 기둥 사이를 채워요. 창과 문 안쪽에도 방의 깊이가 남아 있어요.',
'walls-kitchen':'부엌과 온돌방의 바닥 높이가 달라요. 모든 바닥을 한 높이로 만들지 않아요.',
'kitchen-loft':'다락 바닥을 받치는 나무와 그 아래 부엌 공간을 함께 살펴보세요.',
'ondol':'따뜻한 방바닥과 통풍되는 나무 마루는 서로 다른 생활 공간이에요.',
'ondol-floors':'중문채에도 사람이 쓰던 두 방이 있어요. 방과 열린 마루의 바닥을 비교해 보세요.',
'open-maru':'청판이 귀틀과 받침 위에 놓여요. 마루 아래 빈 공간도 구조의 일부예요.',
'maru':'마루방과 앞 툇마루에 놓인 판재 아래로 받침 구조가 이어져요.',
'daecheong-maru':'대청은 앞뒤를 잇는 깊은 공간이에요. 바닥을 받치는 귀틀이 먼저 있어야 해요.',
'compacted-floor':'안채 창고의 기록에는 다진 흙바닥이 나와요. 마루나 온돌과 구별해요.',
'walls-partition':'중앙 칸막이를 기준으로 두 보관 공간이 생겨요.',
'gate-changho':'문을 열어도 문틀과 기둥은 제자리에 있어요. 문 너머의 길을 살펴보세요.',
'changho':'문짝이 걸리는 곳과 문 뒤의 방을 함께 살펴보세요.',
'doors-vents':'물건을 드나들게 하는 문과 작은 환기구의 역할이 달라요.',
'complete-use':'방·마루·부엌·보관 공간은 사람의 생활을 위한 자리였어요.'
};
function stop(){clearInterval(timer);timer=null;$('play').textContent='▷ 흐름 재생';$('play').setAttribute('aria-pressed','false')}
function selectBuilding(id){stop();building=data.buildings.find(b=>b.id===id)||data.buildings[0];step=0;$('overlay').value=0;$('complete-image').style.opacity=0;$('opacity').textContent='0%';$('buildings').querySelectorAll('button').forEach(b=>b.classList.toggle('active',b.dataset.id===building.id));$('timeline').replaceChildren();$('overview').replaceChildren();for(const [i,s]of building.steps.entries()){const b=document.createElement('button');b.innerHTML='<b>'+String(i+1).padStart(2,'0')+'</b><span>'+s.ko+'</span>';b.onclick=()=>{stop();show(i)};$('timeline').append(b);const c=document.createElement('button'),im=document.createElement('img'),t=document.createElement('span');im.src=BASE+s.file;im.alt=s.ko;im.loading='lazy';t.textContent=String(i+1).padStart(2,'0')+' · '+s.ko;c.append(im,t);c.onclick=()=>{stop();show(i);$('canvas').scrollIntoView({block:'center',behavior:'smooth'})};$('overview').append(c)}$('timeline-title').textContent=building.name+' · '+building.steps.length+'번의 공정';show(0)}
function show(i){step=Math.max(0,Math.min(building.steps.length-1,i));const s=building.steps[step],lang=$('language').value;$('stage-image').src=BASE+s.file;$('stage-image').alt=building.name+' '+s.number+'단계 '+s.ko;$('complete-image').src=BASE+building.steps.at(-1).file;$('count').textContent=String(step+1).padStart(2,'0')+' / '+building.steps.length+' · '+building.name;$('stage-title').textContent=s.ko;$('stage-translation').textContent=s[lang];$('sentence-ko').textContent=s.sentence.ko;$('sentence-translation').textContent=s.sentence[lang];$('building-role').textContent=building.desc;$('note').textContent=s.observe?.[lang]||notes[s.id]||'';$('download').href=BASE+s.file;$('previous').disabled=step===0;$('next').disabled=step===building.steps.length-1;$('timeline').querySelectorAll('button').forEach((b,n)=>{b.classList.toggle('active',n===step);b.setAttribute('aria-pressed',String(n===step))});const u=new URL(location);u.searchParams.set('building',building.id);u.searchParams.set('stage',String(step+1));u.searchParams.set('lang',lang);history.replaceState(null,'',u)}
$('previous').onclick=()=>{stop();show(step-1)};$('next').onclick=()=>{stop();show(step+1)};$('language').onchange=()=>show(step);
$('overlay').oninput=e=>{$('complete-image').style.opacity=e.target.value/100;$('opacity').textContent=e.target.value+'%'};
$('play').onclick=()=>{if(timer){stop();return}if(step===building.steps.length-1)show(0);$('play').textContent='Ⅱ 일시 정지';$('play').setAttribute('aria-pressed','true');timer=setInterval(()=>{if(step===building.steps.length-1){stop();return}show(step+1)},3000)};
$('overview-toggle').onclick=()=>{const h=!$('overview').hidden;$('overview').hidden=h;$('overview-toggle').setAttribute('aria-expanded',String(!h))};
$('enlarge').onclick=()=>{$('zoom-image').src=$('stage-image').src;$('zoom-image').alt=$('stage-image').alt;$('zoom').showModal()};$('close-zoom').onclick=()=>$('zoom').close();
document.addEventListener('keydown',e=>{if(['INPUT','SELECT'].includes(e.target.tagName)||$('zoom').open)return;if(e.key==='ArrowRight'){stop();show(step+1)}if(e.key==='ArrowLeft'){stop();show(step-1)}});
fetch(BASE+'construction_catalog.json').then(r=>{if(!r.ok)throw Error(r.status);return r.json()}).then(d=>{data=d;for(const b of d.buildings){const el=document.createElement('button');el.dataset.id=b.id;el.innerHTML='<b>'+b.name+'</b><small>'+b.en+' · '+b.steps.length+'단계</small>';el.onclick=()=>selectBuilding(b.id);$('buildings').append(el)}const q=new URLSearchParams(location.search);$('language').value=q.get('lang')==='de'?'de':'en';const requested=Number(q.get('stage')||1)-1;selectBuilding(q.get('building'));show(requested)}).catch(err=>{$('stage-title').textContent='공정 목록을 열지 못했습니다.';$('stage-translation').textContent=String(err)});
