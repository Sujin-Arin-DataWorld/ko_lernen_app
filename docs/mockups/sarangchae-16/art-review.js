'use strict';

// Approved runtime artwork. Stage 16 continues to use app.js's immutable canonical source.
let artworkView=new URLSearchParams(location.search).get('view')==='diagram'?'diagram':'art';
const artCopy={
  ko:{art:'단계 원화',diagram:'구조 도해',candidate:'승인한 단계 원화',compare:'완성본과 겹쳐 보기',overlay:'완성본 겹침',note:'승인한 16단계 원화입니다. 구조 도해는 원리를 설명하며, 마지막 단계는 완성 원본 그대로입니다.',compareNote:'겹침을 움직여 기둥·보·처마 받침·계단 위치를 대조하세요. 숨은 구조는 실측 복원이 아닙니다.'},
  en:{art:'Stage artwork',diagram:'Structure sketch',candidate:'Approved stage artwork',compare:'Overlay the completed house',overlay:'Completed image opacity',note:'All sixteen stage artworks are approved. Structure sketches explain principles; stage 16 uses the unchanged original.',compareNote:'Move the overlay to compare posts, beams, eave supports and stairs. Concealed structure is not a measured reconstruction.'},
  de:{art:'Bauabschnitt',diagram:'Konstruktionsskizze',candidate:'Freigegebene Illustration',compare:'Fertiges Haus überlagern',overlay:'Deckkraft des fertigen Hauses',note:'Alle sechzehn Illustrationen sind freigegeben. Die Konstruktionsskizzen erklären Prinzipien; Schritt 16 zeigt das unveränderte Original.',compareNote:'Verschiebe die Überlagerung und vergleiche Stützen, Balken, Traufstützen und Treppe. Verdeckte Bauteile sind keine vermessene Rekonstruktion.'}
};
const artworkFor=n=>HANOK_ARTWORKS[n]||null;
const stageArtworkHtml=(n,className='')=>{
  const a=artworkFor(n);
  return `<img class="${className}" data-artwork-stage="${n}" data-sha256="${a.sha256}" src="${a.src}" alt="${esc(tr(stages[n-1].title))} · ${esc(artCopy[language].candidate)}">`;
};
const artControls=document.createElement('div');
artControls.className='art-controls';
artControls.id='art-controls';
$('scene').before(artControls);
artControls.addEventListener('click',e=>{
  const button=e.target.closest('button');if(!button)return;
  if(button.dataset.artView){stop();artworkView=button.dataset.artView;render();}
  else if(button.id==='compare-artwork')showArtworkComparison();
});
const renderOriginalMockup=render;
render=function(){
  renderOriginalMockup();
  const c=artCopy[language],available=current<16&&!!artworkFor(current);
  artControls.hidden=!available;
  artControls.innerHTML=available?`<div class="art-view-choice" role="group" aria-label="${esc(c.art)}"><button data-art-view="art" aria-pressed="${artworkView==='art'}">${c.art}</button><button data-art-view="diagram" aria-pressed="${artworkView==='diagram'}">${c.diagram}</button></div><button id="compare-artwork">${c.compare} ↗</button>`:'';
  if(available&&artworkView==='art'){
    $('scene').innerHTML=stageArtworkHtml(current);
    $('art-state').textContent=c.candidate;
  }
  if(Object.keys(HANOK_ARTWORKS).length)$('prototype-note').textContent=c.note;
  const url=new URL(location.href);url.searchParams.set('view',artworkView);history.replaceState(null,'',url);
};
function showArtworkLarge(){
  if(current===16||artworkView==='diagram'||!artworkFor(current)){showDetail();return;}
  stop();$('dialog-kicker').textContent=`${pad(current)} / 16 · ${artCopy[language].candidate}`;
  $('dialog-title').textContent=tr(stages[current-1].title);
  $('detail-content').innerHTML=stageArtworkHtml(current,'detail-image')+`<p class="detail-copy">${esc(tr(stages[current-1].body))}</p>`;
  $('detail-dialog').showModal();
}
function showArtworkComparison(){
  if(current===16||!artworkFor(current))return;
  stop();const c=artCopy[language];
  $('dialog-kicker').textContent=`${pad(current)} / 16 · ${c.candidate}`;
  $('dialog-title').textContent=c.compare;
  $('detail-content').innerHTML=`<div class="art-comparison">${stageArtworkHtml(current)}<img id="comparison-master" src="${CANONICAL}" alt="${esc(ui[language].complete)}" style="opacity:.5"></div><label class="overlay-control" for="art-overlay">${c.overlay}<input id="art-overlay" type="range" min="0" max="100" value="50"><output id="overlay-value">50%</output></label><p class="detail-copy">${c.compareNote}</p>`;
  $('art-overlay').addEventListener('input',e=>{$('comparison-master').style.opacity=Number(e.target.value)/100;$('overlay-value').textContent=e.target.value+'%';});
  $('detail-dialog').showModal();
}
$('inspect').removeEventListener('click',showDetail);
$('inspect').addEventListener('click',showArtworkLarge);
const originalOverview=showOverview;
$('overview').removeEventListener('click',showOverview);
showOverview=function(){
  originalOverview();
  if(artworkView==='art')for(const card of $('overview-grid').querySelectorAll('[data-stage]')){
    const n=Number(card.dataset.stage),diagram=card.querySelector('svg');if(n<16&&artworkFor(n)&&diagram)diagram.outerHTML=stageArtworkHtml(n);
  }
};
$('overview').addEventListener('click',showOverview);
render();
