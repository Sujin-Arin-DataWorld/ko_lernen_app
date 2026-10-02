'use strict';
let homeInventory, homeUsage, homePreviewState, homeCurrentPlan, discoveryObserver;
const homeObjectArt = {listening:'speaker',scenarios:'conversation',vocab_packs:'book',grammar:'grammar',hangul:'hangul'};
const homeCopy = {
 de:{heading:'Für dich',all:'Alle Übungen',unseen:'Schon ausprobiert?',dormant:'Mal wieder etwas anderes?',try:'Ausprobieren',dismiss:'Später',labels:{listening:'Hören',scenarios:'Dialog',vocab_packs:'Wörter',grammar:'Grammatik',hangul:'Hangul'},benefits:{hangul:'Buchstaben verbinden und Silben lesen.',grammar:'Entdecke, wie koreanische Sätze aufgebaut sind.',smalltalk:'Übe, ein Gespräch locker weiterzuführen.',word_web:'Finde das passende Wort für das, was du meinst.',chosung:'Erkenne Wörter an ihrem ersten Laut.'},fallback:'Entdecke eine andere Art zu üben.'},
 en:{heading:'For you',all:'All practice',unseen:'Tried this yet?',dormant:'Fancy a change?',try:'Try it',dismiss:'Later',labels:{listening:'Listening',scenarios:'Dialogue',vocab_packs:'Vocabulary',grammar:'Grammar',hangul:'Hangul'},benefits:{hangul:'Put letters together and read syllables.',grammar:'Explore how Korean sentences fit together.',smalltalk:'Practise keeping a conversation going.',word_web:'Find the word that says what you mean.',chosung:'Recognise words from their first sound.'},fallback:'Explore another way to practise.'},
 ko:{heading:'나에게 맞는 연습',all:'전체 보기',unseen:'이것도 해볼까요?',dormant:'오랜만에 해볼까요?',try:'해보기',dismiss:'다음에',labels:{listening:'듣기',scenarios:'대화',vocab_packs:'단어',grammar:'문법',hangul:'한글'},benefits:{hangul:'글자를 조합하며 음절을 읽어봐요.',grammar:'한국어 문장이 만들어지는 규칙을 알아봐요.',smalltalk:'자연스럽게 대화를 이어가는 연습을 해봐요.',word_web:'뜻이 비슷한 표현의 차이를 알아봐요.',chosung:'첫소리를 보고 단어를 떠올려봐요.'},fallback:'다른 방법으로도 연습해봐요.'}
};
const hc = () => homeCopy[state.locale];
const homeDemo = () => ['frequent','discover'].includes(query.get('demo')) ? query.get('demo') : null;
function demoHistory(now) {
 const s=SoriUsage.fresh(), DAY=86400000;
 for(const [id,n] of [['srs',12],['smalltalk',10],['listening',8],['speed_match',6]])for(let i=0;i<n;i++)s.events.push({id,at:now-(Math.floor(i/2)+1)*DAY-(i%2)*3600000});
 s.everUsed=[...new Set(s.events.map(e=>e.id))];
 s.visitCount=homeDemo()==='discover'?3:2;s.lastVisitAt=now;
 return s;
}
function initHomeContent(catalog) {
 homeInventory=catalog;
 let storage=null;try {storage=window.localStorage;}catch(_){}
 homeUsage=SoriUsage.store(storage,'hangulsori.review.content-grid.v1',catalog.activities);
 if(homeDemo())homePreviewState=demoHistory(Date.now());else homeUsage.visit();
 refreshHomePlan();
 const picker=document.getElementById('usage-demo');
 if(picker){picker.value=homeDemo()||'actual';picker.addEventListener('change',()=>{const url=new URL(location.href);url.searchParams.set('view','today');if(picker.value==='actual')url.searchParams.delete('demo');else url.searchParams.set('demo',picker.value);location.href=url;});}
 document.getElementById('clear-usage')?.addEventListener('click',()=>{if(homeDemo()){homePreviewState=demoHistory(Date.now());}else{homeUsage.reset();homeUsage.visit();}render();});
}
function refreshHomePlan() {
 if(homeDemo()){homeCurrentPlan=SoriUsage.plan(homePreviewState,homeInventory.activities,Date.now());homePreviewState=homeCurrentPlan.state;}
 else homeCurrentPlan=homeUsage.plan();
 const status=document.getElementById('usage-status');
 if(status)status.textContent=homeDemo()?'사용 기록 예시 · 실제 시안 사용 기록과 분리':'이 브라우저의 시안 사용 기록 '+homeCurrentPlan.state.events.length+'회 · 실제 계정과 연결되지 않음';
}
const homeActivity=id=>homeInventory.activities.find(a=>a.id===id);
const homeLabel=a=>hc().labels[a.id]||a.title[state.locale]||koreanHomeTitles[a.id]||a.title.en;
const koreanHomeTitles={course:'학습 경로',calligraphy:'오늘의 글자',pronunciation:'발음',srs:'복습',my_words:'내 단어',book_capture:'책 촬영',smalltalk:'스몰 토크',word_web:'뉘앙스·반대말',daily_game:'오늘의 도전',chosung:'초성 퀴즈',syllable_cross:'음절 퍼즐',cloze:'빈칸 채우기',speed_match:'빠른 짝 맞추기',sentence_arcade:'문장 아케이드',kkeunmari:'끝말잇기',custom_practice:'내 단어로 연습'};
const homeAsset=a=>homeObjectArt[a.id]?'assets/'+homeObjectArt[a.id]+'.png':a.asset;
function homeGrid() {
 refreshHomePlan();
 return `<div class="section-heading content-heading"><h3>${escapeHTML(hc().heading)}</h3><button type="button" class="text-button" data-route="learn">${escapeHTML(hc().all)}${icon('chevron')}</button></div><div class="practice-grid content-grid">${homeCurrentPlan.ids.map(id=>{const a=homeActivity(id),color={listening:'blue',scenarios:'mint',vocab_packs:'paper',grammar:'ochre',hangul:'ochre'}[id]||['blue','mint','paper','ochre'][homeCurrentPlan.ids.indexOf(id)];return `<button type="button" class="practice-tile content-tile ${color} ${homeObjectArt[id]?'':'with-print'}" data-content-id="${escapeHTML(id)}" aria-label="${escapeHTML(homeLabel(a))}"><img src="${escapeHTML(homeAsset(a))}" alt="" aria-hidden="true"><strong>${escapeHTML(homeLabel(a))}</strong>${icon('chevron')}</button>`;}).join('')}</div>`;
}
function homeDiscovery() {
 const d=homeCurrentPlan.discovery;
 if(!d)return '';
 const a=homeActivity(d.id);
 return `<section class="discovery-card" aria-label="${escapeHTML(hc()[d.reason])}" data-discovery="${escapeHTML(d.id)}"><div class="discovery-copy"><span class="discovery-kicker">${escapeHTML(hc()[d.reason])}</span><h3>${escapeHTML(homeLabel(a))}</h3><p>${escapeHTML(hc().benefits[a.id]||hc().fallback)}</p><button type="button" class="try-button" data-content-id="${escapeHTML(a.id)}">${escapeHTML(hc().try)}${icon('arrow')}</button></div><img class="discovery-art" src="${escapeHTML(homeAsset(a))}" alt="" aria-hidden="true"><button type="button" class="dismiss-discovery" data-dismiss-content="${escapeHTML(a.id)}" aria-label="${escapeHTML(hc().dismiss)}">${icon('close')}</button></section>`;
}
function trackHomeContent(id) {
 if(!homeInventory?.activities.some(a=>a.id===id))return;
 if(homeDemo())homePreviewState=SoriUsage.recordUse(homePreviewState,id,homeInventory.activities,Date.now());else homeUsage.record(id);
}
function openHomeActivity(id) {
 const a=homeActivity(id);if(!a)return;
 trackHomeContent(id);
 if(id==='listening'){route('listen');return;}
 if(id==='scenarios'){route('conversation');return;}
 if(id==='vocab_packs'){route('packs');return;}
 route(a.tab==='games'?'games':'learn',id);
}
function dismissHomeContent(id) {
 if(homeDemo())homePreviewState=SoriUsage.dismiss(homePreviewState,id,homeInventory.activities,Date.now());else homeUsage.dismiss(id);
 render();
 screen.querySelector('.content-heading')?.scrollIntoView({block:'start',behavior:'auto'});
 screen.querySelector('.content-tile')?.focus({preventScroll:true});
}
function watchDiscovery() {
 discoveryObserver?.disconnect();
 const card=screen.querySelector('[data-discovery]');if(!card)return;
 const mark=()=>{const id=card.dataset.discovery;if(homeDemo())homePreviewState=SoriUsage.impression(homePreviewState,id,homeInventory.activities,Date.now());else homeUsage.impression(id);discoveryObserver?.disconnect();};
 if('IntersectionObserver' in window){discoveryObserver=new IntersectionObserver(entries=>{if(entries.some(e=>e.isIntersecting&&e.intersectionRatio>=.5))mark();},{root:screen,threshold:.5});discoveryObserver.observe(card);}
}
window.addEventListener('pagehide',()=>discoveryObserver?.disconnect());
