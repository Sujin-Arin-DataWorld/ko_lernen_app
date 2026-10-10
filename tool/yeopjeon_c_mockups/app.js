/* Review-only UI. No account APIs, persistent wallet, or app storage. */
'use strict';
const A='assets/';
const esc=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const copy={
 de:{brand:'HANGUL SORI',reward:'Deine Belohnung',good:'Gut gelernt!',first:'Für deine erste Lektion heute',second:'Für deine zweite Lektion heute',balance:'Dein Guthaben',house:'Zum Haus',learn:'Weiterlernen',myhouse:'Mein Ildu-Haus',build:'Für 40 bauen',later:'Später',ready:'Der nächste Bauschritt ist bereit.',rafters:'Dachsparren',next:'Als Nächstes',stage:'Bauschritt',of:'von',cost:'Baukosten',playing:'Dokkaebi schenkt dir Yeopjeon',play:'Moment ansehen',skip:'Überspringen',received:'Deine Yeopjeon sind gutgeschrieben.',saved:'Dein Lernfortschritt ist gespeichert.',capTitle:'Gut weitergelernt!',cap:'Heute hast du alle Lern-Yeopjeon gesammelt. Morgen kannst du mit neuen Lektionen wieder welche verdienen.',repeatTitle:'Noch einmal gefestigt!',repeat:'Für diese Lektion hast du schon Yeopjeon erhalten. Dein Üben zählt weiter für deinen Lernfortschritt.',pendingTitle:'Lektion abgeschlossen',pending:'Deine Belohnung wird geprüft.',pendingNote:'Dein Ergebnis ist gespeichert. Du kannst weiterlernen. Sobald die Gutschrift bestätigt ist, erscheint sie hier.',retry:'Erneut prüfen',recovered:'Deine Belohnung ist wieder da',recoveryNote:'Eine bereits abgeschlossene Lektion wurde nachgetragen.',failed:'Deine Yeopjeon sind da.',failedNote:'Der Film konnte nicht geladen werden. Deine Gutschrift bleibt erhalten.',milestoneTitle:'Ein neuer Bauschritt!',subsidy:'Bauzuschuss',milestone:'Für deinen Lernfortschritt',unlocked:'Dachsparren freigeschaltet',lockedTitle:'Dein Haus wächst mit dir',locked:'Für den nächsten Bauschritt fehlt noch ein Lernziel.',lockedNote:'Deine Yeopjeon bleiben in deinem Geldbeutel. Erfülle das nächste Lernziel, um weiterzubauen.',goal:'Zum Lernziel',short:'Noch 10 Yeopjeon bis zum Bauschritt',shortNote:'Deine gesammelten Yeopjeon bleiben erhalten. Weitere neue Lernabschlüsse und freigeschaltete Bauschritte können neue Yeopjeon bringen.',builtTitle:'Dein Haus wächst!',built:'Dachsparren gebaut',builtNote:'Die Sparren tragen das Dach. Ein neuer Teil deines Hauses ist fertig.',view:'Mein Haus ansehen',today:'Heute durch Lernen gesammelt',held:'Bereits gebaut',confirmTitle:'Dachsparren bauen?',confirm:'Du setzt 40 Yeopjeon für diesen Bauschritt ein.',before:'Guthaben vorher',after:'Guthaben danach',cancel:'Zurück',nextLesson:'Dein nächster Lernschritt',close:'Zurück zum Ergebnis',question:'Beantwortet',result:'Lektion abgeschlossen',noCoins:'Heute vollständig gesammelt',walletNote:'Yeopjeon bauen dein Haus. Dein Lernfortschritt öffnet die nächsten Bauschritte.'},
 ko:{brand:'HANGUL SORI',reward:'도깨비가 건네는 엽전',good:'오늘도 잘 배웠어요!',first:'오늘 첫 학습 완료 보상',second:'오늘 두 번째 학습 완료 보상',balance:'내 엽전',house:'일두고택으로',learn:'계속 공부하기',myhouse:'나의 일두고택',build:'40엽전으로 짓기',later:'나중에',ready:'다음 공정을 지을 수 있어요.',rafters:'서까래',next:'다음 공정',stage:'공정',of:'/',cost:'건축 비용',playing:'도깨비가 엽전을 건네고 있어요',play:'도깨비 만나기',skip:'연출 넘기기',received:'엽전이 지갑에 들어왔어요.',saved:'학습 진도가 저장됐어요.',capTitle:'오늘도 더 익혔어요!',cap:'오늘의 학습 엽전을 모두 받았어요. 내일 새로운 수업을 마치면 다시 받을 수 있어요.',repeatTitle:'한 번 더 익혔어요!',repeat:'이 수업의 엽전은 이미 받았어요. 복습한 내용은 학습 진도에 계속 반영돼요.',pendingTitle:'공부를 마쳤어요',pending:'엽전 지급을 확인하고 있어요.',pendingNote:'학습 결과는 저장됐어요. 계속 공부해도 괜찮아요. 지급이 확인되면 지갑에서 볼 수 있어요.',retry:'다시 확인',recovered:'받을 엽전을 찾았어요',recoveryNote:'이미 완료한 수업의 누락된 보상을 받았어요.',failed:'엽전은 잘 받았어요.',failedNote:'영상을 불러오지 못했어요. 지급된 엽전은 지갑에 있어요.',milestoneTitle:'집을 더 지을 수 있어요!',subsidy:'건축 지원',milestone:'학습 진도로 열린 새 공정',unlocked:'서까래 공정이 열렸어요',lockedTitle:'배움과 함께 자라는 집',locked:'다음 공정의 학습 목표가 아직 남아 있어요.',lockedNote:'엽전은 지갑에 그대로 있어요. 다음 학습 목표를 채우면 이어서 지을 수 있어요.',goal:'학습 목표 보기',short:'다음 공정까지 10엽전 남았어요',shortNote:'모은 엽전은 지갑에 있어요. 새로운 학습 완료와 공정 해금으로 엽전을 더 모을 수 있어요.',builtTitle:'집이 한 뼘 자랐어요!',built:'서까래를 올렸어요',builtNote:'서까래는 지붕을 받치는 나무예요. 집의 새로운 부분이 완성됐어요.',view:'내 집 둘러보기',today:'오늘 학습으로 받은 엽전',held:'지은 공정',confirmTitle:'서까래를 올릴까요?',confirm:'이 공정을 짓는 데 40엽전을 써요.',before:'지금 엽전',after:'짓고 난 뒤',cancel:'돌아가기',nextLesson:'다음 학습으로 이어가요',close:'결과로 돌아가기',question:'답한 문제',result:'수업 완료',noCoins:'오늘의 학습 엽전 완료',walletNote:'엽전으로 집을 짓고, 학습 진도로 다음 공정을 열어요.'},
 en:{brand:'HANGUL SORI',reward:'Your reward',good:'Well learned!',first:'For your first lesson today',second:'For your second lesson today',balance:'Your Yeopjeon',house:'Go to my house',learn:'Keep learning',myhouse:'My Ildu house',build:'Build for 40',later:'Later',ready:'Your next building stage is ready.',rafters:'Roof rafters',next:'Next stage',stage:'Stage',of:'of',cost:'Building cost',playing:'Dokkaebi is giving you Yeopjeon',play:'Meet Dokkaebi',skip:'Skip animation',received:'Your Yeopjeon have been credited.',saved:'Your learning progress is saved.',capTitle:'You learned more today!',cap:'You have collected all learning Yeopjeon for today. Finish new lessons tomorrow to earn more.',repeatTitle:'Practised once more!',repeat:'You have already earned Yeopjeon for this lesson. Your practice still adds to your learning progress.',pendingTitle:'Lesson completed',pending:'Checking your reward.',pendingNote:'Your result is saved. You can keep learning. Your reward will appear once it is confirmed.',retry:'Check again',recovered:'Your missing reward is here',recoveryNote:'A completed lesson has been recovered.',failed:'Your Yeopjeon are here.',failedNote:'The video could not load. Your confirmed reward is still in your wallet.',milestoneTitle:'A new building stage!',subsidy:'Building support',milestone:'For your learning progress',unlocked:'Roof rafters unlocked',lockedTitle:'Your house grows with you',locked:'There is a learning goal to finish before the next stage.',lockedNote:'Your Yeopjeon stay in your wallet. Finish the next learning goal to build further.',goal:'See learning goal',short:'10 more Yeopjeon for this stage',shortNote:'Your collected Yeopjeon remain in your wallet. New lesson completions and unlocked building stages can earn more.',builtTitle:'Your house has grown!',built:'Roof rafters built',builtNote:'The rafters support the roof. Another part of your house is complete.',view:'Visit my house',today:'Earned through learning today',held:'Stages built',confirmTitle:'Build the roof rafters?',confirm:'You will use 40 Yeopjeon for this stage.',before:'Balance now',after:'Balance afterwards',cancel:'Back',nextLesson:'Your next learning step',close:'Back to the result',question:'Questions answered',result:'Lesson completed',noCoins:'All learning Yeopjeon collected today',walletNote:'Yeopjeon build your house. Learning opens the next building stages.'}
};
let lang='de', reduced=matchMedia('(prefers-reduced-motion: reduce)').matches;
Object.assign(copy.de,{mystery:'Der nächste Schritt bleibt geheim',secretNote:'Erst nach dem Bauen zeigt sich, was neu entstanden ist.',unlocked:'Ein neuer Bauschritt ist bereit',confirmTitle:'Den nächsten Schritt bauen?',building:'Dein Haus entsteht …',reveal:'Jetzt enthüllen',current:'Schon gebaut'});
Object.assign(copy.ko,{mystery:'다음 공정은 아직 비밀',secretNote:'짓고 나면 새로 달라진 모습을 볼 수 있어요.',unlocked:'새 공정을 지을 준비가 됐어요',confirmTitle:'다음 공정을 지을까요?',building:'집이 자라고 있어요 …',reveal:'새 모습 보기',current:'지금까지 지은 모습'});
Object.assign(copy.en,{mystery:'The next step is a surprise',secretNote:'Build to discover what has changed.',unlocked:'A new building stage is ready',confirmTitle:'Build the next stage?',building:'Your house is growing …',reveal:'Reveal the new stage',current:'Already built'});
let contentDemo={id:'smalltalk.a1.weather.outside',title:{ko:'밖의 날씨',de:'Das Wetter draußen',en:'The weather outside'},questions:3};
const defaults={first:{balance:40,amount:20},second:{balance:30,amount:10},milestone:{balance:70,amount:40},cap:{balance:30,amount:0},repeat:{balance:40,amount:0},pending:{balance:20,amount:null},recovery:{balance:40,amount:20},failure:{balance:40,amount:20},wallet:{balance:40,amount:0},locked:{balance:70,amount:0,eligible:7},short:{balance:30,amount:0},built:{balance:0,amount:0,owned:8,eligible:8,returnState:'wallet'}};
const make=(id,state,surface)=>({id,state,surface,owned:7,eligible:8,phase:'ready',...defaults[state]});
let models=[make(0,'first','paper'),make(1,'second','jade'),make(2,'milestone','paper')];
const root=document.getElementById('screens');
const t=key=>copy[lang][key];
const img=(file,alt='',cls='')=>`<img src="${A+file}" alt="${esc(alt)}" class="${cls}" ${alt?'':'aria-hidden="true"'}>`;
const btn=(text,action,cls='primary')=>`<button class="${cls}" data-action="${action}">${esc(text)}</button>`;
const line=(label,value)=>`<div class="receipt-line ${label===t('balance')?'balance-line':''}"><span>${esc(label)}</span><strong>${esc(value)}</strong></div>`;
const progress=(label,now,max)=>`<div class="progress-label"><span>${esc(label)}</span><strong>${now} ${esc(t('of'))} ${max}</strong></div><div class="progress-bar" role="progressbar" aria-label="${esc(label)}" aria-valuemin="0" aria-valuemax="${max}" aria-valuenow="${now}" style="--progress:${100*now/max}%"><span></span></div>`;
const nextBuild=m=>`<div class="next-build"><div><strong>${esc(m.balance>=40&&m.eligible>m.owned?t('ready'):t('short'))}</strong>${esc(t('mystery'))}</div></div>`;
function rewardHero(m){
 const video=m.state==='first'&&m.surface==='paper'&&!reduced;
 if(video)return `<div class="hero alpha-media" data-phase="ready"><img src="media-review/frame-120.png" alt="방망이를 들고 엽전을 건네는 도깨비" class="hero-poster"><video class="hero-video" hidden playsinline muted preload="metadata" aria-label="${esc(t('playing'))}" src="${A}making_money_alpha.webm"></video></div><div class="motion-controls">${btn(t('play'),'play','motion-button')}${btn(t('skip'),'skip','motion-button skip')}</div>`;
 if(m.surface==='paper'&&m.state==='first')return `<div class="hero alpha-media"><img src="media-review/frame-120.png" alt="엽전을 건네는 도깨비" class="hero-poster"></div>`;
 return `<div class="hero ${['cap','repeat','pending','failure','recovery'].includes(m.state)?'compact':''}" data-action="magic" role="button" tabindex="0" aria-label="${lang==='ko'?'도깨비와 놀기':lang==='de'?'Dokkaebi antippen':'Play with Dokkaebi'}">${['first','second','recovery','failure'].includes(m.state)?img('yupjeon.png','','coin-burst'):''}${img('dokkaebi_ready.png','도깨비','character')}<div class="ground-shadow" aria-hidden="true"></div></div>`;
}
function render(m){
 if(useLockedVisual(m))return renderLocked(m);
 let title=t('reward'),sub='도깨비 · 엽전',body='',foot='';
 const jade=m.surface==='jade'&&['first','second','recovery','failure'].includes(m.state);
 if(['first','second','recovery','failure'].includes(m.state)){
   const why=m.state==='first'?t('first'):m.state==='second'?t('second'):m.state==='recovery'?t('recoveryNote'):t('failedNote');
   title=m.state==='second'?t('good'):m.state==='recovery'?t('recovered'):t('reward');
   body=`<p class="lead">${esc(contentDemo.title[lang])} · ${contentDemo.questions}/${contentDemo.questions}</p>${rewardHero(m)}<section class="receipt" aria-label="${esc(t('reward'))}"><h2 class="reward-amount">+${m.amount}<span class="unit">${lang==='ko'?'엽전':'Yeopjeon'}</span></h2><p class="reward-why">${esc(why)}</p>${line(t('balance'),m.balance)}${m.state==='second'?progress(t('today'),30,30):''}${nextBuild(m)}</section>`;
   const ready=m.balance>=40&&m.eligible>m.owned;
   foot=btn(ready?t('house'):t('learn'),ready?'wallet':'learn')+btn(ready?t('learn'):t('house'),ready?'learn':'wallet','secondary');
 }else if(m.state==='milestone'){
   title=t('milestoneTitle');sub='일두고택 · 사랑채';
   body=`<p class="lead">${esc(t('unlocked'))}</p>${secretHero(true)}<section class="receipt"><p class="small-label">${esc(t('subsidy'))}</p><h2 class="reward-amount">+40<span class="unit">${lang==='ko'?'엽전':'Yeopjeon'}</span></h2><p class="reward-why">${esc(t('mystery'))}</p>${line(t('balance'),m.balance)}${progress(t('held'),m.owned,16)}</section>`;
   foot=btn(t('build'),'confirm')+btn(t('later'),'learn','secondary');
 }else if(['cap','repeat','pending'].includes(m.state)){
   title=t(m.state+'Title');
   body=`<p class="lead">${esc(contentDemo.title[lang])}</p>${rewardHero(m)}<section class="receipt"><h2 class="quiet-title">${esc(m.state==='pending'?t('pending'):t('result'))}</h2><p class="status-text"><span class="status-marker" aria-hidden="true"></span>${esc(t('saved'))}</p><p class="note">${esc(t(m.state==='pending'?'pendingNote':m.state))}</p>${line(t('balance'),m.balance)}${m.state==='cap'?progress(t('today'),30,30):''}</section>`;
   foot=btn(t('learn'),'learn')+btn(t(m.state==='pending'?'retry':'house'),m.state==='pending'?'retry':'wallet','secondary');
 }else if(['wallet','locked','short'].includes(m.state)){
   title=t(m.state==='locked'?'lockedTitle':'myhouse');sub='일두고택 · 사랑채';
   body=`<p class="small-label">${esc(t('balance'))}</p><div class="wallet-big"><span class="coin-sprite" aria-hidden="true"></span>${m.balance}</div><p class="stage-label">${esc(t('current'))}</p>${ownedHanokVisual(m)}<section class="receipt">${progress(t('held'),m.owned,16)}${line(t('cost'),'40 Yeopjeon')}<p class="note">${esc(m.state==='locked'?t('lockedNote'):m.balance<40?t('shortNote'):t('secretNote'))}</p></section>`;
   foot=btn(m.eligible<=m.owned?t('goal'):m.balance<40?t('learn'):t('build'),m.eligible<=m.owned||m.balance<40?'learn':'confirm')+btn(t('later'),'back','secondary');
 }else if(m.state==='confirm'){
   title=t('confirmTitle');sub='일두고택 · 사랑채';
   body=`<p class="lead">${esc(t('confirm'))}</p>${secretHero()}<section class="receipt">${line(t('cost'),'40 Yeopjeon')}${line(t('before'),m.balance)}${line(t('after'),m.balance-40)}<p class="stage-note">${esc(t('secretNote'))}</p></section>`;
   foot=btn(t('build'),'build')+btn(t('cancel'),'wallet','secondary');
 }else if(m.state==='building'){
   title=t('building');sub='일두고택 · 사랑채';
   body=`<p class="lead">${esc(t('secretNote'))}</p>${secretHero()}<section class="receipt"><h2 class="quiet-title">${esc(t('building'))}</h2><div class="construction-light" aria-hidden="true"></div></section>`;
   foot=btn(t('reveal'),'reveal');
 }else if(m.state==='built'){
   title=t('builtTitle');sub='일두고택 · 사랑채';
   body=`<p class="lead">${esc(t('builtTitle'))}</p>${ownedHanokVisual(m)}<section class="receipt"><h2 class="quiet-title">${lang==='ko'?'새 공정을 완성했어요':lang==='de'?'Ein neuer Schritt ist fertig':'A new stage is complete'}</h2>${progress(t('held'),m.owned,16)}<p class="note">${esc(t('walletNote'))}</p>${line(t('balance'),m.balance)}<p class="stage-note">40 Yeopjeon · ${esc(t('cost'))}</p></section>`;
   foot=btn(t('view'),'house')+btn(t('learn'),'learn','secondary');
 }else if(m.state==='house'){
   title=t('myhouse');sub='일두고택 · 사랑채';body=`${ownedHanokVisual(m)}<section class="receipt">${progress(t('held'),m.owned,16)}${line(t('balance'),m.balance)}<p class="note">${esc(t('walletNote'))}</p></section>`;foot=btn(t('learn'),'learn')+btn(t('close'),'back','secondary');
 }else{
   title=t('nextLesson');sub='배움은 계속 이어져요';
   body=`${rewardHero({...m,state:'repeat'})}<section class="receipt"><div class="next-lesson">${img('book.png')}<p><strong>${esc(contentDemo.title[lang])}</strong><br><span lang="ko">날씨 좋네요.</span></p></div><p class="note">${esc(t('saved'))}</p>${line(t('balance'),m.balance)}</section>`;
   foot=btn(t('close'),'back')+btn(t('house'),'house','secondary');
 }
 const captions=['01 · 한지에 스며드는 영상','02 · 녹청 위의 엽전 에셋','03 · 새 공정, 복주머니 축하'];
 return `<article class="screen-wrap" data-screen="${m.id}"><p class="screen-caption">${captions[m.id]}<small>390 × 844 · ${m.state}</small></p><div class="phone"><div class="screen paper-texture ${jade?'jade-scene':''}" lang="${lang}" data-state="${m.state}" data-balance="${m.balance}" data-owned="${m.owned}" data-eligible="${m.eligible}"><header class="app-head"><div class="topline"><span class="wordmark">${esc(t('brand'))}</span><button class="wallet-badge" data-action="wallet" aria-label="${esc(t('balance'))}: ${m.balance} Yeopjeon"><span class="coin-sprite" aria-hidden="true"></span><span>${m.balance}</span></button></div><h2 class="app-title" tabindex="-1">${esc(title)}</h2><p class="app-subtitle" lang="ko">${sub}</p></header><div class="app-body paper-texture">${body}</div><footer class="app-foot paper-texture">${foot}</footer><div class="motion-layer" aria-hidden="true"></div><div class="sr-only" aria-live="polite" data-live></div></div></div></article>`;
}
function draw(id){
 if(id===undefined){stopVideos();root.innerHTML=models.map(render).join('');}
 else{const old=root.querySelector(`[data-screen="${id}"]`);const v=old?.querySelector('video');if(v)v.pause();old.outerHTML=render(models[id]);}
 document.dispatchEvent(new CustomEvent('sori:screen',{detail:{id}}));
}
function stopVideos(){root.querySelectorAll('video').forEach(v=>v.pause());}
function revealBuilding(m){if(m.state!=='building'||models[m.id]!==m)return;m.state='built';draw(m.id);document.dispatchEvent(new CustomEvent('sori:built',{detail:{id:m.id}}));}
function live(article,message){article.querySelector('[data-live]').textContent=message;}
function settle(m,article){
 const v=article.querySelector('video');if(v){v.pause();v.hidden=true;}
 const poster=article.querySelector('.hero-poster');if(poster){poster.src='media-review/frame-120.png';poster.hidden=false;}
 article.querySelector('.motion-controls')?.remove();m.phase='settled';live(article,t('received'));
 article.querySelector('.hero')?.setAttribute('data-phase','settled');
 article.querySelector('.locked-video-surface')?.setAttribute('hidden','');
 article.querySelector('.locked-skip')?.setAttribute('hidden','');
}
root.addEventListener('click',async event=>{
 const button=event.target.closest('[data-action]');if(!button)return;
 const article=button.closest('[data-screen]'),id=Number(article.dataset.screen),m=models[id],action=button.dataset.action;
 if(action==='magic')return;
 if(m.state==='building'&&action!=='reveal')return;
 if(action==='reveal'){revealBuilding(m);return;}
 if(action==='play'){
   stopVideos();const v=article.querySelector('video');if(!v||reduced){settle(m,article);return;}
   button.disabled=true;if(!article.classList.contains('visual-locked'))button.textContent=t('playing');v.hidden=false;const poster=article.querySelector('.hero-poster');if(poster)poster.hidden=true;m.phase='video';
   article.querySelector('.locked-video-surface')?.removeAttribute('hidden');article.querySelector('.locked-skip')?.removeAttribute('hidden');
   article.querySelector('.hero')?.setAttribute('data-phase','opening');
   v.addEventListener('timeupdate',()=>{if(v.currentTime>=3.7&&!v.dataset.cued){v.dataset.cued='1';article.querySelector('.wallet-badge').classList.add('accent');document.dispatchEvent(new CustomEvent('sori:coins',{detail:{id}}));}},{passive:true});
   v.addEventListener('ended',()=>settle(m,article),{once:true});
   v.addEventListener('error',()=>{m.state='failure';draw(id);},{once:true});
   try{await v.play();article.querySelector('.hero')?.setAttribute('data-phase','playing');}catch{m.state='failure';draw(id);}return;
 }
 if(action==='skip'){settle(m,article);return;}
 if(action==='build'){
   if(m.state!=='confirm'||m.balance<40||m.eligible<=m.owned)return;
   m.balance-=40;m.owned+=1;m.amount=0;m.returnState='wallet';m.state='building';draw(id);
   if(reduced)revealBuilding(m);else setTimeout(()=>revealBuilding(m),1250);
 }else if(action==='confirm'){
   if(m.balance<40||m.eligible<=m.owned)return;m.state='confirm';draw(id);
 }else if(action==='back'){m.state=m.returnState||'first';draw(id);}
 else if(action==='retry'){m.state='recovery';m.amount=20;m.balance=40;draw(id);}
 else{if(['first','second','milestone','repeat','cap','recovery','failure','pending'].includes(m.state))m.returnState=m.state;m.state=action;draw(id);}
 root.querySelector(`[data-screen="${id}"] .app-title`)?.focus({preventScroll:true});
});
document.getElementById('state-select').addEventListener('change',e=>{const surface=e.target.value==='second'?'jade':'paper';models[0]=make(0,e.target.value,surface);document.getElementById('surface-select').value=surface;draw(0);});
document.getElementById('surface-select').addEventListener('change',e=>{models[0].surface=e.target.value;models[0].phase='ready';draw(0);});
document.getElementById('language-select').addEventListener('change',e=>{lang=e.target.value;draw();});
document.getElementById('size-select').addEventListener('change',e=>{document.documentElement.style.setProperty('--font-scale',e.target.value);document.body.classList.toggle('large-type',Number(e.target.value)>1);draw();});
document.getElementById('exact-visual').addEventListener('change',e=>{exactVisual=e.target.checked;draw();});
document.getElementById('reduce-motion').checked=reduced;
document.getElementById('reduce-motion').addEventListener('change',e=>{reduced=e.target.checked;document.body.classList.toggle('reduced',reduced);draw();});
document.getElementById('night-view').addEventListener('change',e=>document.body.classList.toggle('night',e.target.checked));
document.getElementById('review-toggle').addEventListener('click',e=>{const open=document.body.classList.toggle('settings-open');e.target.setAttribute('aria-expanded',String(open));});
document.addEventListener('keydown',e=>{if(e.key==='Escape'){document.body.classList.remove('settings-open');document.getElementById('review-toggle').setAttribute('aria-expanded','false');}});
matchMedia('(prefers-reduced-motion: reduce)').addEventListener('change',e=>{reduced=e.matches;document.getElementById('reduce-motion').checked=reduced;document.body.classList.toggle('reduced',reduced);draw();});
matchMedia('(max-height:639px)').addEventListener('change',()=>draw());
document.addEventListener('visibilitychange',()=>{if(document.hidden){root.querySelectorAll('[data-screen]').forEach(article=>{const m=models[Number(article.dataset.screen)];if(m.phase==='video')settle(m,article);});}});
const reviewParams=new URLSearchParams(location.search);
if(reviewParams.get('solo')==='1'){document.body.classList.add('solo');const initial=reviewParams.get('screen');if(defaults[initial]){models[0]=make(0,initial,initial==='second'?'jade':'paper');document.getElementById('state-select').value=initial;document.getElementById('surface-select').value=models[0].surface;}}
document.body.classList.toggle('reduced',reduced);draw();
Promise.all([fetch('content-demo.json').then(r=>r.ok?r.json():null),hanokCatalogReady]).then(([d])=>{if(d){contentDemo=d;draw();}if(reviewParams.get('play')==='1'&&!reduced)root.querySelector('[data-screen="0"] [data-action="play"]')?.click();}).catch(()=>{});
