/*
 * The user's approved composition is the visual authority. Original art is
 * projected through CSS apertures: no regenerated face, frame or lettering.
 * Real buttons and semantic receipt content remain HTML. This is a review
 * prototype; localized/large-text/edge states use the editable HTML layout.
 */
'use strict';
const VISUAL_LOCK={
  first:{board:'approved-board.png',x:77,y:99,w:447,h:853,title:'Deine Belohnung',amount:20,balance:40,primary:'Zum Haus',action:'wallet',secondary:'Weiterlernen',secondAction:'learn',why:'Für deine erste Lektion heute.'},
  second:{board:'approved-board.png',x:545,y:99,w:448,h:853,title:'Gut gelernt!',amount:10,balance:30,primary:'Weiterlernen',action:'learn',secondary:'Mein Haus',secondAction:'wallet',why:'Zweite Lektion heute.'},
  milestone:{board:'secret-board.png',x:1015,y:99,w:447,h:853,title:'Ein neuer Bauschritt!',amount:40,balance:70,primary:'Für 40 bauen',action:'confirm',secondary:'Später',secondAction:'learn',why:'Bauzuschuss. Der nächste Bauschritt bleibt geheim.'}
};
let exactVisual=true;
function lockedArtStyle(v){return `--art:url('design/${v.board}');--board-w:${1536/v.w*100}%;--board-h:${1024/v.h*100}%;--board-x:${v.x/(1536-v.w)*100}%;--board-y:${v.y/(1024-v.h)*100}%;--phone-ratio:${v.w}/${v.h}`;}
function useLockedVisual(m){
  const v=VISUAL_LOCK[m.state];
  return exactVisual&&!matchMedia('(max-height:639px)').matches&&lang==='de'&&document.getElementById('size-select').value==='1'&&v&&m.balance===v.balance&&m.owned===7&&m.eligible===8&&m.surface===(m.state==='second'?'jade':'paper');
}
function renderLocked(m){
 const v=VISUAL_LOCK[m.state],isFirst=m.state==='first';
 const aLabel=isFirst?'Dokkaebis Moment ansehen':m.state==='second'?'Dokkaebi antippen':'Das Geheimnis bewegt sich';
 const captions={first:'01 · 승인 원본 · 첫 학습 +20',second:'02 · 승인 원본 · 두 번째 학습 +10',milestone:'03 · 한옥 비공개 · 건축 지원 +40'};
 return `<article class="screen-wrap visual-locked" data-screen="${m.id}" style="${lockedArtStyle(v)}"><p class="screen-caption">${captions[m.state]}</p><div class="phone"><div class="screen locked-screen" lang="de" data-state="${m.state}" data-balance="${m.balance}" data-owned="${m.owned}" data-eligible="${m.eligible}"><div class="locked-art" aria-hidden="true"></div><div class="locked-semantic sr-only"><span>HANGUL SORI</span><h2 class="app-title" tabindex="-1">${v.title}</h2><h3>+${v.amount} Yeopjeon</h3><p>${v.why}</p><p>Dein Guthaben: ${m.balance} Yeopjeon.</p>${m.state==='milestone'?'<p>Ildu-Haus, Sarangchae. 7 von 16 gebaut. Der nächste Bauschritt bleibt geheim.</p>':''}</div><button class="wallet-badge locked-wallet" data-action="wallet" aria-label="Dein Guthaben: ${m.balance} Yeopjeon"><span class="sr-only">${m.balance}</span></button><button class="hero locked-hero" data-action="${isFirst?'play':'magic'}" aria-label="${aLabel}"><span class="locked-depth" aria-hidden="true"></span>${isFirst?`<span class="locked-video-surface alpha-media" hidden><video class="hero-video" hidden playsinline muted preload="none" src="assets/making_money_alpha.webm" aria-label="Dokkaebi schenkt dir Yeopjeon"></video></span><span class="video-cue" aria-hidden="true">▶ Video ansehen</span>`:''}</button>${isFirst?'<button class="locked-skip motion-button skip" hidden data-action="skip">Überspringen</button>':''}<footer class="locked-foot"><button class="locked-primary" data-action="${v.action}"><span class="sr-only">${v.primary}</span></button><button class="locked-secondary" data-action="${v.secondAction}"><span class="sr-only">${v.secondary}</span></button></footer><div class="motion-layer" aria-hidden="true"></div><div class="sr-only" aria-live="polite" data-live></div></div></div></article>`;
}
function secretHero(bok=false){
 return `<div class="hero secret-hero" data-action="magic" role="button" tabindex="0" aria-label="${lang==='ko'?'봉인된 다음 공정의 빛 보기':lang==='de'?'Das versiegelte Geheimnis antippen':'Tap the sealed surprise'}"><div class="sealed-art" aria-hidden="true"></div>${bok?'<img src="assets/bok.png" class="secret-pouches" alt="" aria-hidden="true">':''}<span class="sr-only">${esc(t('mystery'))}</span></div>`;
}
