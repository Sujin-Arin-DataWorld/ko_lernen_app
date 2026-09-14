'use strict';
const BASE='../../../assets_unused/pending_review/personal_hanok_v3/four_buildings_construction_29deg_v1/';
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

const copy = {
  en: {
    edition: 'Building four hanok houses', language: 'Read together',
    eyebrow: 'Building a place for everyday life',
    intro: 'Rooms take shape between the posts, with space for everyday life beneath the eaves.',
    camera: 'Front · 29° target view', buildings: 'Choose a building', stages: 'Choose a construction stage',
    enlarge: 'Enlarge artwork ↗', overlay: 'Compare with the completed building',
    speak: 'Say it in Korean', observe: 'Look at the space', download: 'Download this PNG ↓',
    next: 'Next stage →', previous: '← Previous', play: '▷ Play sequence', pause: 'Ⅱ Pause',
    overview: 'All stages', close: 'Close ×', count: 'stages',
    footer: 'Explore the structure of hanok buildings where people lived and worked, together with Korean.',
    error: 'The construction catalog could not be loaded.',
    roles: {
      jungmunganchae: 'Passage · two rooms · open maru',
      araechae: 'Rooms · wooden porch · everyday life',
      anchae: 'Kitchen · rooms · main hall',
      'anchae-store': 'Two storage spaces · stored objects'
    }
  },
  de: {
    edition: 'Vier Hanok-Gebäude entstehen', language: 'Gemeinsam lesen',
    eyebrow: 'Ein Haus für den Alltag entsteht',
    intro: 'Zwischen den Pfosten entstehen Räume, unter dem Dach findet der Alltag seinen Platz.',
    camera: 'Vorderansicht · Zielwinkel 29°', buildings: 'Gebäude wählen', stages: 'Bauschritt wählen',
    enlarge: 'Bild vergrößern ↗', overlay: 'Mit dem fertigen Gebäude vergleichen',
    speak: 'Sag es auf Koreanisch', observe: 'Betrachte den Raum', download: 'Dieses PNG herunterladen ↓',
    next: 'Nächster Bauschritt →', previous: '← Zurück', play: '▷ Ablauf abspielen', pause: 'Ⅱ Pause',
    overview: 'Alle Bauschritte', close: 'Schließen ×', count: 'Bauschritte',
    footer: 'Entdecke den Aufbau von Hanok-Gebäuden, in denen Menschen lebten und arbeiteten, und übe dabei Koreanisch.',
    error: 'Die Bauanleitung konnte nicht geladen werden.',
    roles: {
      jungmunganchae: 'Durchgang · zwei Räume · offener Maru',
      araechae: 'Räume · Holzvorbau · Alltag',
      anchae: 'Küche · Zimmer · Haupthalle',
      'anchae-store': 'Zwei Lagerräume · Gegenstände'
    }
  }
};
function ui() { return copy[$('language').value] || copy.en; }
function translateUi() {
  const lang = $('language').value, text = ui();
  const labels = {
    '.edition': text.edition, '.heading .eyebrow': text.eyebrow,
    '.intro': text.intro, '.camera': text.camera,
    '#enlarge': text.enlarge, 'label[for="overlay"]': text.overlay,
    'aside .eyebrow:not(#count)': text.speak, '.structure-note strong': text.observe,
    '#download': text.download, '#next': text.next, '#previous': text.previous,
    '#play': timer ? text.pause : text.play, '#overview-toggle': text.overview,
    '#close-zoom': text.close, '#building-role': text.roles[building.id],
    '#timeline-title': building.name + ' · ' + building.steps.length + ' ' + text.count
  };
  for (const [selector, value] of Object.entries(labels)) {
    const element = document.querySelector(selector);
    element.textContent = value;
    element.lang = lang;
  }
  $('language').setAttribute('aria-label', text.language);
  $('buildings').setAttribute('aria-label', text.buildings);
  $('timeline').setAttribute('aria-label', text.stages);
  $('close-zoom').setAttribute('aria-label', text.close);
  document.querySelector('header label').firstChild.textContent = text.language + ' ';
  for (const button of $('buildings').querySelectorAll('button')) {
    const entry = data.buildings.find(item => item.id === button.dataset.id);
    button.querySelector('b').lang = 'ko';
    const subtitle = button.querySelector('small');
    subtitle.lang = lang;
    subtitle.textContent = entry[lang] + ' · ' + entry.steps.length + ' ' + text.count;
  }
  $('timeline').querySelectorAll('button').forEach((button, index) => {
    const stage = building.steps[index];
    button.title = stage[lang];
    button.setAttribute('aria-label', stage.number + ' · ' + stage.ko + ' · ' + stage[lang]);
  });
  $('stage-translation').lang = lang;
  $('sentence-translation').lang = lang;
  $('note').lang = lang;
  if (!document.querySelector('.review-scope')) {
    document.querySelector('footer').textContent = text.footer;
    document.querySelector('footer').lang = lang;
  }
}

function stop(){clearInterval(timer);timer=null;$('play').textContent=ui().play;$('play').setAttribute('aria-pressed','false')}
function selectBuilding(id){stop();building=data.buildings.find(b=>b.id===id)||data.buildings[0];step=0;$('overlay').value=0;$('complete-image').style.opacity=0;$('opacity').textContent='0%';$('buildings').querySelectorAll('button').forEach(b=>b.classList.toggle('active',b.dataset.id===building.id));$('timeline').replaceChildren();$('overview').replaceChildren();for(const [i,s]of building.steps.entries()){const b=document.createElement('button');b.innerHTML='<b>'+String(i+1).padStart(2,'0')+'</b><span>'+s.ko+'</span>';b.onclick=()=>{stop();show(i)};$('timeline').append(b);const c=document.createElement('button'),im=document.createElement('img'),t=document.createElement('span');im.src=BASE+s.file;im.alt=s.ko;im.loading='lazy';t.textContent=String(i+1).padStart(2,'0')+' · '+s.ko;c.append(im,t);c.onclick=()=>{stop();show(i);$('canvas').scrollIntoView({block:'center',behavior:'smooth'})};$('overview').append(c)}$('timeline-title').textContent=building.name+' · '+building.steps.length+'번의 공정';show(0)}
function show(i){step=Number.isInteger(i)?Math.max(0,Math.min(building.steps.length-1,i)):0;const s=building.steps[step],lang=$('language').value;$('stage-image').src=BASE+s.file;$('stage-image').alt=building.name+' '+s.number+'단계 '+s.ko;$('complete-image').src=BASE+building.steps.at(-1).file;$('count').textContent=String(step+1).padStart(2,'0')+' / '+building.steps.length+' · '+building.name;$('stage-title').textContent=s.ko;$('stage-translation').textContent=s[lang];$('sentence-ko').textContent=s.sentence.ko;$('sentence-translation').textContent=s.sentence[lang];$('building-role').textContent=building.desc;$('note').textContent=s.observe?.[lang]||notes[s.id]||'';$('download').href=BASE+s.file;$('previous').disabled=step===0;$('next').disabled=step===building.steps.length-1;$('timeline').querySelectorAll('button').forEach((b,n)=>{b.classList.toggle('active',n===step);b.setAttribute('aria-pressed',String(n===step))});translateUi();const u=new URL(location);u.searchParams.set('building',building.id);u.searchParams.set('stage',String(step+1));u.searchParams.set('lang',lang);history.replaceState(null,'',u)}
$('previous').onclick=()=>{stop();show(step-1)};$('next').onclick=()=>{stop();show(step+1)};$('language').onchange=()=>show(step);
$('overlay').oninput=e=>{$('complete-image').style.opacity=e.target.value/100;$('opacity').textContent=e.target.value+'%'};
$('play').onclick=()=>{if(timer){stop();return}if(step===building.steps.length-1)show(0);$('play').textContent=ui().pause;$('play').setAttribute('aria-pressed','true');timer=setInterval(()=>{if(step===building.steps.length-1){stop();return}show(step+1)},3000)};
$('overview-toggle').onclick=()=>{const h=!$('overview').hidden;$('overview').hidden=h;$('overview-toggle').setAttribute('aria-expanded',String(!h))};
$('enlarge').onclick=()=>{$('zoom-image').src=$('stage-image').src;$('zoom-image').alt=$('stage-image').alt;$('zoom').showModal()};$('close-zoom').onclick=()=>$('zoom').close();
document.addEventListener('keydown',e=>{if(['INPUT','SELECT'].includes(e.target.tagName)||$('zoom').open)return;if(e.key==='ArrowRight'){stop();show(step+1)}if(e.key==='ArrowLeft'){stop();show(step-1)}});
fetch(BASE+'construction_catalog.json').then(r=>{if(!r.ok)throw Error(r.status);return r.json()}).then(d=>{data=d;for(const b of d.buildings){const el=document.createElement('button');el.dataset.id=b.id;el.innerHTML='<b>'+b.name+'</b><small>'+b.en+' · '+b.steps.length+'단계</small>';el.onclick=()=>selectBuilding(b.id);$('buildings').append(el)}const q=new URLSearchParams(location.search);$('language').value=q.get('lang')==='de'?'de':'en';const requested=Number(q.get('stage')||1)-1;selectBuilding(q.get('building'));show(requested)}).catch(err=>{$('stage-title').textContent=ui().error;$('stage-translation').textContent=String(err)});
