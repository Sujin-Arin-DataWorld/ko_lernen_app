'use strict';
const $=id=>document.getElementById(id),ROOT='../../../',DATA='../../assets/ildu_ansarang_shrine_construction_20260914/construction_design.json';
let data,building,index=0,timer,guideOpacity=32;
const svgNS='http://www.w3.org/2000/svg';
function stop(){clearInterval(timer);timer=null;$('play').textContent='▷ 설계 순서 재생';$('play').setAttribute('aria-pressed','false')}
function guide(){
 const stage=building.steps[index],g=building.geometry,svg=$('guide');svg.replaceChildren();svg.setAttribute('viewBox','0 0 '+building.canonical.canvas.join(' '));
 if(stage.id==='complete'){return;}
 const included=new Set(stage.installed),focused=new Set(stage.focus);
 for(const member of g.members){
  if(!included.has(member.group)||member.hidden&&!$('rear').checked||member.displayOnly&&!focused.has('site'))continue;
  const pts=member.nodes.map(id=>g.nodes[id].xy),active=focused.has(member.group),color=active?'#ce7a1d':'#16795f';
  const element=document.createElementNS(svgNS,pts.length===1?'circle':'polyline');
  if(pts.length===1){element.setAttribute('cx',pts[0][0]);element.setAttribute('cy',pts[0][1]);element.setAttribute('r','9');element.setAttribute('fill',color)}
  else{element.setAttribute('points',pts.map(p=>p.join(',')).join(' '));element.setAttribute('fill','none')}
  element.setAttribute('stroke',color);element.setAttribute('stroke-width',active?'3':'1.4');element.setAttribute('vector-effect','non-scaling-stroke');element.setAttribute('stroke-linejoin','round');element.setAttribute('stroke-linecap','round');element.setAttribute('opacity',active?'1':'.6');
  if(member.hidden)element.setAttribute('stroke-dasharray','5 5');
  element.dataset.member=member.id;element.dataset.group=member.group;svg.append(element);
 }
}
function setOpacity(){const complete=building.steps[index].id==='complete',value=complete?100:guideOpacity;$('master').style.opacity=String(value/100);$('opacity').value=String(value);$('opacity-value').value=value+'%';$('opacity').disabled=complete;}
function show(n){
 index=Math.max(0,Math.min(building.steps.length-1,Number.isFinite(n)?Math.trunc(n):0));
 const s=building.steps[index],lang=$('language').value,complete=s.id==='complete';
 $('master').src=ROOT+building.canonical.assetPath;$('master').alt=building.name+' 승인 완성 정본';
 $('role').textContent=building.role[lang];$('role').lang=lang;$('count').textContent=String(s.number).padStart(2,'0')+' / '+building.steps.length+' · '+building.name;
 $('title').textContent=s.title.ko;$('translation').textContent=lang==='ko'?'':s.title[lang];$('translation').lang=lang;
 $('sentence').textContent=s.sentence.ko;$('sentence-translation').textContent=lang==='ko'?'':s.sentence[lang];$('sentence-translation').lang=lang;
 $('observe').textContent=s.observe[lang];$('observe').lang=lang;$('term').textContent=s.term;
 $('status').textContent=complete?'승인 완료 · 원본 그대로':'공정 설계 · 구조 기준선';$('status').classList.toggle('complete',complete);
 $('art-note').textContent=complete?'마지막 단계는 승인한 PNG 원본입니다. 크기·색·알파·구도를 다시 만들지 않습니다.':s.id==='ondol'?'온돌은 별도 설명용 절개로 제작합니다. 현재 화면은 정본과 공간 위치를 확인하는 설계 화면입니다.':'현재 공정의 부재와 접점을 정본 위에서 확인하는 설계 화면입니다. 점선의 가려진 구조는 학습용 재구성입니다.';
 $('previous').disabled=index===0;$('next').disabled=complete;
 $('timeline-title').textContent=building.name+' · '+building.steps.length+'단계';
 document.querySelectorAll('#timeline button').forEach((b,i)=>b.setAttribute('aria-pressed',String(i===index)));
 $('download').href=ROOT+building.canonical.assetPath;
 guide();setOpacity();
 const u=new URL(location);u.searchParams.set('building',building.id);u.searchParams.set('stage',String(s.number));u.searchParams.set('lang',lang);history.replaceState(null,'',u);
}
function select(id,stage=0){stop();building=data.buildings.find(b=>b.id===id)||data.buildings[0];$('timeline').replaceChildren();
 document.querySelectorAll('#buildings button').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.building===building.id)));
 for(const [i,s]of building.steps.entries()){const b=document.createElement('button'),n=document.createElement('b'),title=document.createElement('span');n.textContent=String(s.number).padStart(2,'0');title.textContent=s.title.ko;b.append(n,title);b.setAttribute('aria-label',s.number+' · '+s.title.ko);b.onclick=()=>{stop();show(i)};$('timeline').append(b)}show(stage);
}
$('next').onclick=()=>{stop();show(index+1)};$('previous').onclick=()=>{stop();show(index-1)};$('opacity').oninput=()=>{guideOpacity=Number($('opacity').value);setOpacity()};$('rear').onchange=guide;$('language').onchange=()=>show(index);
$('play').onclick=()=>{if(timer){stop();return}if(index===building.steps.length-1)show(0);$('play').textContent='Ⅱ 재생 멈추기';$('play').setAttribute('aria-pressed','true');timer=setInterval(()=>{if(index===building.steps.length-1){stop();return}show(index+1)},3000)};
$('zoom-open').onclick=()=>{$('zoom-image').src=$('master').src;$('zoom').showModal()};$('zoom-close').onclick=()=>$('zoom').close();
document.addEventListener('keydown',e=>{if(['INPUT','SELECT','BUTTON'].includes(e.target.tagName)||$('zoom').open)return;if(e.key==='ArrowRight'){stop();show(index+1)}if(e.key==='ArrowLeft'){stop();show(index-1)}});
fetch(DATA).then(r=>{if(!r.ok)throw Error('설계 파일을 불러오지 못했습니다: '+r.status);return r.json()}).then(d=>{data=d;for(const b of data.buildings){const button=document.createElement('button'),name=document.createElement('strong'),meta=document.createElement('small');name.textContent=b.name;meta.textContent=b.en+' · '+b.steps.length+'단계';button.append(name,meta);button.dataset.building=b.id;button.onclick=()=>select(b.id);$('buildings').append(button)}const q=new URLSearchParams(location.search),lang=q.get('lang');$('language').value=['en','de','ko'].includes(lang)?lang:'ko';select(q.get('building'),Number(q.get('stage')||1)-1)}).catch(e=>{$('error').hidden=false;$('error').textContent=String(e)});
