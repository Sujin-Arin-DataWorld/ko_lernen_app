/* Review-only wallet snapshots. No native account, backend or persistent state. */
'use strict';
const params=new URLSearchParams(location.search);
const grid=document.getElementById('phone-grid');
const strings={
 de:{wallet:'Dein Guthaben',reward:'Lektion geschafft',great:'Gut gelernt!',first:'Für deine erste Lektion heute',second:'Für deine zweite Lektion heute',unit:'Yeopjeon',earnedLabel:'Belohnung',house:'Dein Ildu-Haus',nextBuild:'Nächster Bauschritt',costLabel:'Baukosten',visit:'Zum Ildu-Haus',learn:'Weiterlernen',ready:'Bereit für den nächsten Bauschritt.',cost:'Baukosten: 40',future:'Die 3D-Ansicht folgt. Dein Baufortschritt bleibt erhalten.',earning:'Mit jedem Lernen wächst dein Haus.',support:'Bauzuschuss · +40 Yeopjeon',surprise:'Was entsteht als Nächstes?',growth:'Mit deinen Yeopjeon wächst das Ildu-Haus Stück für Stück.',build:'Für 40 weiterbauen',later:'Später bauen',tap:'Tippe auf Dokkaebi',tapCoin:'Tippe auf die Münze',confirm:'Den nächsten Schritt bauen?',confirmNote:'Verwende 40 Yeopjeon für den nächsten Bauschritt.',before:'Dein Guthaben jetzt',after:'Nach dem Bauen',use:'40 Yeopjeon verwenden',back:'Zurück',building:'Baufortschritt wird gespeichert',built:'Baufortschritt gespeichert',builtNote:'Dein Lernen ist ein Teil des Ildu-Hauses geworden.',spent:'40 Yeopjeon verwendet',received:'Deine Yeopjeon sind gutgeschrieben.',saved:'Dein Lernergebnis ist gespeichert.',next:'Dein nächster Lernschritt',goal:'Zum nächsten Lernziel',locked:'Erfülle das nächste Lernziel, um weiterzubauen.',short:'Noch 10 Yeopjeon bis zum nächsten Bauschritt.',pending:'Deine Belohnung wird geprüft',pendingNote:'Dein Ergebnis ist gespeichert. Du kannst weiterlernen.',cap:'Für heute alles gesammelt',capNote:'Mit neuen Lernabschlüssen kannst du morgen wieder welche verdienen.',skip:'Überspringen'},
 en:{wallet:'Your Yeopjeon',reward:'Lesson complete',great:'Well learned!',first:'For your first lesson today',second:'For your second lesson today',unit:'Yeopjeon',earnedLabel:'Reward',house:'Your Ildu house',nextBuild:'Next build',costLabel:'Building cost',visit:'Visit my Ildu house',learn:'Keep learning',ready:'Your next building stage is ready.',cost:'Building cost: 40',future:'The 3D view will follow. Your build progress is saved.',earning:'Your house grows as you learn.',support:'Building support · +40 Yeopjeon',surprise:'What will you build next?',growth:'Use your Yeopjeon to build the Ildu house, little by little.',build:'Build for 40',later:'Build later',tap:'Tap Dokkaebi',tapCoin:'Tap the coin to awaken its light',confirm:'Build the next stage?',confirmNote:'Use 40 Yeopjeon for the next building step.',before:'Your balance now',after:'After building',use:'Use 40 Yeopjeon',back:'Back',building:'Saving build progress',built:'Build progress saved',builtNote:'Your learning has become part of the Ildu house.',spent:'40 Yeopjeon used',received:'Your Yeopjeon have been credited.',saved:'Your learning result is saved.',next:'Your next learning step',goal:'See the next learning goal',locked:'Finish your next learning goal to build further.',short:'10 more Yeopjeon for the next stage.',pending:'Checking your reward',pendingNote:'Your result is saved. You can keep learning.',cap:'All learning coins collected today',capNote:'Finish new learning tomorrow to earn more.',skip:'Skip'}
};
const motionCopy={
 de:{pause:'Bewegung aus',resume:'Bewegung an',replay:'Noch einmal',sound:'Ton an',mute:'Ton aus',visual:'Dokkaebi zeigt seine Animation noch einmal.',steps:'Zum nächsten Bauschritt',spark:'Die Münze leuchtet auf.'},
 en:{pause:'Motion off',resume:'Motion on',replay:'Replay',sound:'Sound on',mute:'Sound off',visual:'Dokkaebi is replaying the animation.',steps:'For the next building stage',spark:'The coin lights up.'}
};
let locale=['de','en'].includes(params.get('lang'))?params.get('lang'):'de',motionReduced=matchMedia('(prefers-reduced-motion: reduce)').matches;
const text=k=>strings[locale][k];
const motionText=k=>motionCopy[locale][k];
const html=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const models=[{id:0,state:'reward',homeState:'reward',beforeBalance:70,balance:90,amount:20,eligible:true,played:false,phase:'ready'},{id:1,state:'estate',homeState:'estate',beforeBalance:70,balance:110,amount:40,eligible:true,played:false,phase:'ready'}];
const motionTokens={credit:840,roll:90,glyph:230,press:80,release:240,settle:200,wandCue:86/24,easing:'cubic-bezier(.24,.76,.32,1)'};
const walletAnimations=new Map();
const isReceipt=m=>m.state==='reward'||(m.state==='estate'&&m.amount===40);
const previousBalance=m=>m.beforeBalance??Math.max(0,m.balance-(m.amount||0));
const checkIcon='<span class="state-dot" aria-hidden="true"></span>';
const assetSlice=(asset,rect,cls='')=>`<svg class="asset-slice ${cls}" viewBox="${rect.join(' ')}" aria-hidden="true" focusable="false"><image href="assets/${asset}" width="1254" height="1254"/></svg>`;
const coin=(cls='')=>assetSlice('coin_face.png',[168,156,914,938],cls);
function ctaMaterial(primary){
 return `<svg class="cta-art" data-primary="${primary}" aria-hidden="true" focusable="false" preserveAspectRatio="none"></svg>`;
}
let ctaId=0;
function paintCta(button){
 const art=button.querySelector('.cta-art');if(!art)return;
 const {width:w,height:h}=button.getBoundingClientRect(),primary=art.dataset.primary==='true',base=primary?54:48,u=base/232,top=primary?101:397,expanded=h>base+.1;
 const sx=[14,244,1101,1241],sy=[top,top+64,top+80,top+232],dx=[0,230*u,w-140*u,w],dy=[0,64*u,h-152*u,h];
 const slice=(x,y,width,height,r)=>`<svg x="${x}" y="${y}" width="${width}" height="${height}" viewBox="${r.join(' ')}" preserveAspectRatio="none"><image href="assets/cta_atlas.png" width="1254" height="1254"/></svg>`;
 const id='cta-'+(++ctaId),b=26*u;
 let face='',frame='';
 for(let row=0;row<3;row++)for(let col=0;col<3;col++){
  if(row===1&&col===1)continue;
  frame+=slice(dx[col],dy[row],dx[col+1]-dx[col],dy[row+1]-dy[row],[sx[col],sy[row],sx[col+1]-sx[col],sy[row+1]-sy[row]]);
 }
 {
  face=slice(0,0,w,h,[254,top+44,836,144]);
  const ring=`M12 0H${w-12}Q${w} 0 ${w} 12V${h-12}Q${w} ${h} ${w-12} ${h}H12Q0 ${h} 0 ${h-12}V12Q0 0 12 0Z M${12} ${b}H${w-12}Q${w-b} ${b} ${w-b} 12V${h-12}Q${w-b} ${h-b} ${w-12} ${h-b}H12Q${b} ${h-b} ${b} ${h-12}V12Q${b} ${b} 12 ${b}Z`;
  const cloud='M24 209L24 161C15 149 22 127 41 127C36 108 52 94 73 96C89 91 104 103 111 115C129 113 145 126 143 140C160 138 177 145 180 162C195 171 192 192 170 199L195 209Z';
  face=`<defs><clipPath id="${id}-outer"><rect width="${w}" height="${h}" rx="12"/></clipPath><clipPath id="${id}-frame"><path d="${ring}" clip-rule="evenodd"/><path d="${cloud}" transform="translate(0 ${h-base}) scale(${u})"/></clipPath></defs><g clip-path="url(#${id}-outer)">${face}<g clip-path="url(#${id}-frame)">${frame}</g></g>`;
 }
 art.setAttribute('viewBox',`0 0 ${w} ${h}`);art.dataset.expanded=String(expanded);art.innerHTML=face;
}
const ctaObserver=new ResizeObserver(entries=>entries.forEach(entry=>paintCta(entry.target)));
function refreshCtas(){ctaObserver.disconnect();grid.querySelectorAll('.primary,.secondary').forEach(button=>{paintCta(button);ctaObserver.observe(button);});}
const button=(label,action,primary=true)=>`<button class="${primary?'primary':'secondary'}" data-action="${action}">${ctaMaterial(primary)}<span class="cta-label">${html(label)}</span>${primary?`<span class="cta-medallion">${assetSlice('arrow.png',[390,238,506,790])}</span>`:''}</button>`;
const controlPaths={replay:'M7 5H3v4M3 9a8 8 0 1 1 1 9',skip:'m6 5 9 7-9 7V5ZM19 5v14',sound:'m11 4-6 5H2v6h3l6 5V4ZM15 8a6 6 0 0 1 0 8M18 5a10 10 0 0 1 0 14',mute:'m11 4-6 5H2v6h3l6 5V4ZM16 9l6 6M22 9l-6 6',pause:'M8 5v14M16 5v14',resume:'m7 5 11 7-11 7V5Z'};
const controlFace=(icon,label)=>`<svg viewBox="0 0 24 24" aria-hidden="true"><path d="${controlPaths[icon]}"/></svg><span>${html(label)}</span>`;
const setControl=(node,icon,label)=>{if(node)node.innerHTML=controlFace(icon,label);};
const motionControl=()=>`<button class="motion-control" data-action="motion" aria-pressed="${motionReduced}">${controlFace(motionReduced?'resume':'pause',motionText(motionReduced?'resume':'pause'))}</button>`;
const coinStage=(controls=false)=>`<div class="object-stage house-scene" data-phase="ready"><button class="object-trigger coin-trigger" data-action="coin" aria-label="${html(text('tapCoin'))}"><span class="hero-light" aria-hidden="true"></span><span class="quiet-ground" aria-hidden="true"></span><span class="object-parallax"><span class="coin-shadow" aria-hidden="true"></span>${coin('coin-companion coin-left')}${coin('coin-object')}${coin('coin-companion coin-right')}</span><img class="asset-burst" src="assets/yupjeon.png" alt=""><span class="scene-ripple" aria-hidden="true"></span></button>${controls?`<div class="hero-controls">${motionControl()}</div>`:''}</div>`;
const characterStage=(m,controls=false)=>`<div class="object-stage character-wrap" data-phase="${m.played?'settled':'ready'}"><span class="hero-light" aria-hidden="true"></span><button class="object-trigger character-stage" data-action="play" data-phase="${m.played?'settled':'ready'}" aria-label="${html(text('tap'))}"><span class="object-parallax"><img class="character" src="assets/${m.played&&m.state==='reward'?'money_alpha_end':'money_alpha_start'}.png" alt="" aria-hidden="true"><video class="reward-video" src="assets/making_money_alpha.webm" preload="none" muted playsinline hidden aria-label="${html(text('received'))}"></video></span><img class="asset-burst" src="assets/yupjeon.png" alt=""></button>${controls?`<div class="hero-controls">${m.state==='reward'?`<button class="replay-control" data-action="replay">${controlFace('replay',motionText('replay'))}</button><button class="sound-control" data-action="sound" aria-pressed="false" hidden>${controlFace('sound',motionText('sound'))}</button>`:''}${motionControl()}</div>`:''}</div>`;
const earnedAmount=m=>`<h3 class="amount earned-amount" aria-label="+${m.amount} ${html(text('unit'))}" data-started="${m.creditShown?'true':'false'}">${coin()}<span data-earned-value aria-hidden="true">${m.creditShown?'+'+m.amount:html(text('earnedLabel'))}</span><small aria-hidden="true">${html(text('unit'))}</small></h3>`;

function goalPanel(m){
 const ready=m.eligible&&m.balance>=40;
  return `<section class="goal-panel" aria-label="${html(text('house'))}"><div class="goal-line"><strong>${html(text('nextBuild'))}</strong><span class="cost-pill">${html(text('cost'))}</span></div><div class="goal-meter" role="progressbar" aria-label="${html(motionText('steps'))}" aria-valuemin="0" aria-valuemax="40" aria-valuenow="${Math.min(m.balance,40)}"><span style="--progress:${Math.min(m.balance/40,1)*100}%"></span></div><p>${ready?checkIcon:!m.eligible?'<span class="goal-lock" aria-hidden="true"></span>':''}<span class="goal-message">${html(ready?text('ready'):m.eligible?text('short'):text('locked'))}</span></p></section>`;
}
function render(m){
 if(motionReduced||params.get('play')==='0'){m.creditShown=true;if(m.state==='reward')m.played=true;}
 const displayedBalance=isReceipt(m)&&!m.creditShown?previousBalance(m):m.balance;
 let body='',foot='';
 if(m.state==='reward'){
   body=`<h2 class="screen-title" tabindex="-1">${html(text('reward'))}</h2><div class="reward-event">${m.amount===10?coinStage(false):characterStage(m,false)}${earnedAmount(m)}</div><p class="reason">${html(text(m.amount===10?'second':'first'))}</p>${goalPanel(m)}`;
  foot=button(m.eligible&&m.balance>=40?text('visit'):text('learn'),m.eligible&&m.balance>=40?'estate':'learn')+button(m.eligible&&m.balance>=40?text('learn'):text('visit'),m.eligible&&m.balance>=40?'learn':'estate',false);
 }else if(m.state==='estate'){
  body=`<h2 class="screen-title" tabindex="-1">${html(text('house'))}</h2><h3 class="next-title">${html(text('surprise'))}</h3><p class="state-label">${html(text('earning'))}</p>${m.amount===40?`<p class="support-badge">${html(text('support'))}</p>`:''}${coinStage()}<p class="touch-hint">${html(text('tapCoin'))}</p><section class="goal-panel"><div class="ready-line">${m.eligible&&m.balance>=40?checkIcon:''}<span>${html(m.eligible&&m.balance>=40?text('ready'):m.eligible?text('short'):text('locked'))}</span></div><div class="goal-line"><strong>${html(text('costLabel'))}</strong><span class="coin-cost"><img src="assets/coin.png" alt="">40</span></div><p>${html(text('future'))}</p></section>`;
  foot=button(m.eligible&&m.balance>=40?text('build'):m.eligible?text('learn'):text('goal'),m.eligible&&m.balance>=40?'confirm':'learn')+button(text('later'),'learn',false);
 }else if(m.state==='confirm'){
  body=`<p class="state-label">${html(text('house'))}</p><h2 class="screen-title" tabindex="-1">${html(text('confirm'))}</h2>${coinStage()}<p class="plain-note">${html(text('confirmNote'))}</p><div class="price-lines"><div><span>${html(text('before'))}</span><strong>${m.balance} ${html(text('unit'))}</strong></div><div><span>${html(text('after'))}</span><strong>${m.balance-40} ${html(text('unit'))}</strong></div></div><p class="plain-note">${html(text('future'))}</p>`;
  foot=button(text('use'),'build')+button(text('back'),'estate',false);
 }else if(m.state==='building'||m.state==='built'){
  body=`<p class="state-label">${html(text('house'))}</p><h2 class="screen-title" tabindex="-1">${html(text(m.state==='built'?'built':'building'))}</h2>${coinStage()}<p class="receipt-summary">${html(text('spent'))}</p><p class="plain-note">${html(text('builtNote'))}</p><p class="plain-note">${html(text('future'))}</p>`;
  foot=button(text('learn'),'learn')+button(text('visit'),'estate',false);
 }else if(m.state==='pending'||m.state==='cap'){
  body=`<p class="state-label">${html(text('reward'))}</p><h2 class="screen-title" tabindex="-1">${html(text(m.state))}</h2>${characterStage(m)}<p class="plain-note">${html(text(m.state+'Note'))}</p>${goalPanel(m)}`;
  foot=button(text('learn'),'learn')+button(text('visit'),'estate',false);
 }else{
  body=`<p class="state-label">${html(text('saved'))}</p><h2 class="screen-title" tabindex="-1">${html(text('next'))}</h2>${characterStage(m)}<p class="plain-note">${html(text('saved'))}</p>${goalPanel(m)}`;
  foot=button(text('visit'),'estate')+button(text('back'),m.homeState||'estate',false);
 }
  const view=m.id===0?'reward':'estate';
  const title=body.match(/<h2 class="screen-title"[^>]*>.*?<\/h2>/)?.[0]||'';
  body=body.replace(title,'').replace(/<img src="assets\/coin.png" alt="">/g,coin());
  return `<article class="phone-wrap" data-id="${m.id}"><p class="phone-label">${m.id===0?(locale==='de'?'01 · Lernen abgeschlossen':'01 · Learning complete'):(locale==='de'?'02 · Dein Ildu-Haus wächst':'02 · Your Ildu house grows')}<a href="refined.html?solo=1&view=${view}&lang=${locale}">${locale==='de'?'Einzelansicht ↗':'Single screen ↗'}</a></p><div class="device"><div class="app" lang="${locale}" data-state="${m.state}" data-balance="${m.balance}" data-eligible="${m.eligible}" data-spends="${m.spends||0}"><div class="system-bar" aria-hidden="true"><span>9:41</span><i class="dynamic-island"></i></div><header class="app-top"><div class="header-copy"><span class="brand">${assetSlice('brand_seal.png',[218,231,828,804],'brand-seal')}HANGUL SORI</span>${title}</div><button class="wallet" data-action="estate" aria-label="${html(text('wallet'))}: ${m.balance} ${html(text('unit'))}"><span class="wallet-coin" aria-hidden="true">${coin()}<span class="wallet-credits"></span></span><span class="wallet-number" aria-hidden="true" style="--digits:${Math.max(3,String(m.balance).length)}"><span class="wallet-value" data-wallet-value>${displayedBalance}</span><span class="wallet-roll" data-wallet-roll hidden><span></span><span></span></span></span><span class="wallet-flash" aria-hidden="true"></span></button></header><div class="app-sheet"><div class="app-main">${body}</div><footer class="app-foot">${foot}</footer></div><div class="home-area" aria-hidden="true"><i></i></div><div class="sr-only" role="status" data-live></div></div></div></article>`;
}
function draw(id){
 walletAnimations.forEach((run,key)=>{if(id===undefined||id===key)run.finish();});
 models.forEach(m=>{if(m.phase==='playing'&&(id===undefined||m.id===id)){m.phase='settled';m.creditShown=true;}});
 if(id===undefined){grid.querySelectorAll('video').forEach(v=>v.pause());grid.innerHTML=models.map(render).join('');}
 else{const node=grid.querySelector(`[data-id="${id}"]`);node.querySelector('video')?.pause();node.outerHTML=render(models[id]);}
 refreshCtas();observeScenes();queueEntryMoments();
}
const sceneObserver=new IntersectionObserver(entries=>entries.forEach(entry=>{
 const article=entry.target;article.classList.toggle('scene-away',!entry.isIntersecting);
 if(!entry.isIntersecting){const m=models[Number(article.dataset.id)];if(m.phase==='playing')settleVideo(article,m);finishWallet(article,m);article.getAnimations({subtree:true}).filter(a=>!('animationName' in a)).forEach(a=>a.cancel());}
}),{threshold:.05});
function observeScenes(){sceneObserver.disconnect();grid.querySelectorAll('[data-id]').forEach(article=>sceneObserver.observe(article));}
const motionOff=()=>motionReduced||document.hidden;
const move=(node,frames,options)=>{if(!node||motionOff())return null;return node.animate(frames,{fill:'none',...options});};
function announce(article,key){article.querySelector('[data-live]').textContent=strings[locale][key]||motionCopy[locale][key];}
function queueEntryMoments(){
 if(document.hidden){grid.querySelectorAll('[data-id]').forEach(article=>{const m=models[Number(article.dataset.id)];if(isReceipt(m)){m.played=true;settleVideo(article,m);finishWallet(article,m);}});return;}
 if(motionOff()||params.get('play')==='0')return;
 requestAnimationFrame(()=>grid.querySelectorAll('[data-id]').forEach(article=>{
  const m=models[Number(article.dataset.id)];
  const box=article.getBoundingClientRect();if(!box.height||box.bottom<=0||box.top>=innerHeight)return;
  if(m.state==='estate'&&m.amount===40&&!m.creditShown){awaken(article);creditMoment(article,m);return;}
  if(m.state!=='reward'||m.played)return;
  if(m.amount===10){m.played=true;awaken(article);creditMoment(article,m);}
  else playMoment(article,m);
 }));
}
function burst(article){
 if(article.querySelector('.character-wrap[data-phase="playing"],.character-wrap[data-phase="opening"]'))return;
 const node=article.querySelector('.asset-burst');
 move(node,[{opacity:0,transform:'translateY(18px) scale(.7)'},{offset:.35,opacity:.7,transform:'translateY(-8px) scale(1)'},{opacity:0,transform:'translateY(-36px) scale(1.1)'}],{duration:1250,easing:'ease-out'});
}
function announceBalance(article,m){
 article.querySelector('[data-live]').textContent=text('received')+' '+(locale==='de'?'Dein Guthaben: ':'Your balance: ')+m.balance+' '+text('unit')+'.';
}
function paintEarned(article,m,elapsed=motionTokens.credit){
 const slot=article.querySelector('[data-earned-value]');if(!slot)return;
 const p=Math.max(0,Math.min(1,elapsed/motionTokens.credit));
 const value=p>=1?m.amount:Math.floor(m.amount*Math.sin(p*Math.PI/2));
 slot.textContent='+'+value;slot.closest('.earned-amount')?.setAttribute('data-started','true');
 if(article.dataset.earnedValue!==String(value))article.dataset.earnedValues=[article.dataset.earnedValues,value].filter(v=>v!==undefined&&v!=='').join(',');
 article.dataset.earnedValue=String(value);
}
function finishWallet(article,m){
 const run=walletAnimations.get(m.id);
 if(run&&run.model===m){run.finish();return;}
 const fresh=isReceipt(m)&&!m.creditShown;
 m.creditShown=true;paintEarned(article,m);
 const value=article.querySelector('[data-wallet-value]'),reel=article.querySelector('[data-wallet-roll]');
 if(value){value.textContent=String(m.balance);value.style.opacity='';}if(reel)reel.hidden=true;
 article.querySelectorAll('.credit-mark,.goal-feedback').forEach(node=>node.remove());
 article.dataset.creditPhase='settled';
 if(fresh){article.dataset.counterValues=[previousBalance(m),m.balance].join(',');announceBalance(article,m);}
}
function creditMoment(article,m){
 // The receipt already owns the balance. This timeline only presents it once.
 if(!article.isConnected||!isReceipt(m)||m.creditShown||article.dataset.creditPhase==='collecting')return;
 if(motionOff()){finishWallet(article,m);return;}
 const value=article.querySelector('[data-wallet-value]'),reel=article.querySelector('[data-wallet-roll]'),wallet=article.querySelector('.wallet');
 const from=previousBalance(m),to=m.balance;
 if(!value||!reel||to<=from){finishWallet(article,m);return;}
 walletAnimations.get(m.id)?.finish();
 const lead=m.state==='estate'?140:0,started=performance.now()+lead,steps=[80,170,260,350,460,590,740],fractions=[.1,.28,.47,.67,.82,.93,1];
 paintEarned(article,m,0);
 const values=[from],effects=[],marks=[],rows=reel.querySelectorAll('span');
 let raf=0,finished=false,frames=0,previousFrame=0,maxFrameGap=0,step=-1,rolling=null;
 const tracked=(node,keyframes,options)=>{const animation=move(node,keyframes,options);if(animation)effects.push(animation);return animation;};
 const finish=(natural=false)=>{
  if(finished)return;finished=true;cancelAnimationFrame(raf);rolling?.cancel();effects.forEach(animation=>animation.cancel());marks.forEach(mark=>mark.remove());
  value.textContent=String(to);value.style.opacity='';reel.hidden=true;m.creditShown=true;paintEarned(article,m);
  if(values.at(-1)!==to)values.push(to);
  article.dataset.creditPhase='settled';article.dataset.counterValues=values.join(',');article.dataset.counterFrames=String(frames);article.dataset.counterMaxGap=String(Math.round(maxFrameGap));article.dataset.counterElapsed=String(Math.round(performance.now()-started));
  if(walletAnimations.get(m.id)?.model===m)walletAnimations.delete(m.id);
  announceBalance(article,m);
  if(natural&&article.isConnected&&!motionOff()){
   move(wallet.querySelector('.wallet-flash'),[{opacity:0},{offset:.3,opacity:.8},{opacity:0}],{duration:motionTokens.settle,easing:'ease-out'});
   const panel=article.querySelector('.goal-panel');
   if(panel){const gleam=document.createElement('span');gleam.className='goal-feedback';gleam.setAttribute('aria-hidden','true');panel.append(gleam);const animation=move(gleam,[{opacity:0},{offset:.3,opacity:.55},{opacity:0}],{duration:180});animation?.finished.then(()=>gleam.remove()).catch(()=>gleam.remove());}
  }
 };
 walletAnimations.set(m.id,{model:m,finish});
 article.dataset.creditMode='wallet-local';article.dataset.creditPhase='collecting';article.dataset.counterFrom=String(from);article.dataset.counterTo=String(to);article.dataset.creditGlyphs='4';
  const coin=wallet.querySelector('.wallet-coin .asset-slice'),layer=wallet.querySelector('.wallet-credits');
 ['+','++','+','++'].forEach((glyph,index)=>{
  const mark=document.createElement('span');mark.className='credit-mark';mark.textContent=glyph;layer.append(mark);marks.push(mark);
  const x=[-12,7,-6,6][index],y=[6,11,15,7][index],delay=lead+[0,170,350,590][index];
  tracked(mark,[{opacity:0,transform:'translate('+x+'px,'+y+'px) scale(.6)'},{offset:.25,opacity:1,transform:'translate('+x+'px,'+(y-7)+'px) scale(1.1)'},{opacity:0,transform:'translate('+x+'px,'+(y-18)+'px) scale(.9)'}],{duration:motionTokens.glyph,delay,easing:'ease-out'});
  tracked(coin,[{transform:'perspective(180px) rotateY(0deg) scale(1)'},{offset:.35,transform:'perspective(180px) rotateY(-24deg) scale(.9)'},{offset:.7,transform:'perspective(180px) rotateY(18deg) scale(1.09)'},{transform:'perspective(180px) rotateY(0deg) scale(1)'}],{duration:motionTokens.press,delay,easing:motionTokens.easing});
 });
 const meter=article.querySelector('.goal-meter span');
 if(meter&&Math.min(from,40)!==Math.min(to,40))tracked(meter,[{transform:'scaleX('+Math.min(from/Math.min(to,40),1)+')'},{transform:'scaleX(1)'}],{duration:motionTokens.credit,delay:lead,easing:motionTokens.easing});
 tracked(article.querySelector('.amount'),[{transform:'scale(1)'},{offset:.4,transform:'scale(1.025)'},{transform:'scale(1)'}],{duration:320,easing:'ease-out'});
 const rollTo=number=>{
  const previous=Number(value.textContent);rolling?.cancel();value.textContent=String(number);rows[0].textContent=String(previous);rows[1].textContent=String(number);value.style.opacity='0';reel.hidden=false;
  const animation=tracked(reel,[{transform:'translateY(0)'},{transform:'translateY(-50%)'}],{duration:motionTokens.roll,easing:'cubic-bezier(.16,.65,.32,1)'});
  rolling=animation;
  animation?.finished.then(()=>{if(!finished&&rolling===animation){value.style.opacity='';reel.hidden=true;}}).catch(()=>{});
 };
 const frame=now=>{
  if(!article.isConnected||motionOff()){finish();return;}
  if(previousFrame)maxFrameGap=Math.max(maxFrameGap,now-previousFrame);previousFrame=now;frames++;
  const elapsed=now-started;
  paintEarned(article,m,elapsed);
  let next=step;while(next+1<steps.length&&elapsed>=steps[next+1])next++;
  if(next!==step){step=next;const number=Math.min(to,from+Math.max(1,Math.round((to-from)*fractions[step])));if(values.at(-1)!==number){rollTo(number);values.push(number);}}
  if(elapsed>=motionTokens.credit)finish(true);else raf=requestAnimationFrame(frame);
 };
 raf=requestAnimationFrame(frame);
}
function awaken(article){
 const stage=article.querySelector('.object-stage');if(!stage)return;
 if(stage.dataset.phase==='playing')return;
 if(motionOff()){announce(article,'spark');return;}
 stage.dataset.phase='playing';
 const object=stage.querySelector('.object-parallax');
 move(object,[{transform:'perspective(800px) rotateY(0deg) translateY(0)'},{offset:.4,transform:'perspective(800px) rotateY(14deg) translateY(-3px)'},{transform:'perspective(800px) rotateY(0deg) translateY(0)'}],{duration:520,easing:'cubic-bezier(.22,1,.36,1)'});
 move(stage.querySelector('.coin-shadow'),[{opacity:.8,scale:1},{offset:.4,opacity:.65,scale:1.05},{opacity:.8,scale:1}],{duration:520,easing:'ease-out'});
 setTimeout(()=>{if(stage.isConnected)stage.dataset.phase='settled';},520);
 burst(article);announce(article,'spark');
}
function settleVideo(article,m){
 finishWallet(article,m);
 const stage=article.querySelector('.character-stage');if(!stage)return;
 const video=stage.querySelector('video');video.pause();video.hidden=true;const poster=stage.querySelector('.character');poster.hidden=false;poster.src='assets/money_alpha_end.png';stage.dataset.phase='settled';stage.parentElement.dataset.phase='settled';stage.disabled=false;m.phase='settled';
 const replay=article.querySelector('.replay-control')||document.getElementById('qa-replay');if(replay){replay.dataset.action='replay';setControl(replay,'replay',motionText('replay'));}
 const sound=article.querySelector('.sound-control')||document.getElementById('qa-sound');if(sound)sound.hidden=true;if(m.replay)announce(article,'visual');
}
async function playMoment(article,m,replay=false){
 const stage=article.querySelector('.character-stage'),video=stage?.querySelector('video');
 if(!stage||!video)return;
 if(m.phase==='playing')return;
 if(m.state!=='reward'||(m.played&&!replay)||motionOff()){awaken(article);return;}
 grid.querySelectorAll('[data-id]').forEach(other=>{if(other!==article&&other.querySelector('.character-stage')?.dataset.phase==='playing')settleVideo(other,models[Number(other.dataset.id)]);});
 m.played=true;m.replay=replay;m.phase='playing';stage.disabled=true;stage.dataset.phase='opening';stage.parentElement.dataset.phase='opening';video.currentTime=0;video.dataset.cued='';video.hidden=false;stage.querySelector('.character').hidden=false;
 video.onplaying=()=>{if(stage.isConnected&&m.phase==='playing')stage.querySelector('.character').hidden=true;};
 const replayControl=article.querySelector('.replay-control')||document.getElementById('qa-replay');if(replayControl){replayControl.dataset.action='skip';setControl(replayControl,'skip',text('skip'));}const soundControl=article.querySelector('.sound-control')||document.getElementById('qa-sound');if(soundControl)soundControl.hidden=false;
 const cue=time=>{if(article.isConnected&&m.phase==='playing'&&time>=motionTokens.wandCue&&!video.dataset.cued){video.dataset.cued='1';creditMoment(article,m);}};
 video.ontimeupdate=()=>cue(video.currentTime);
 if(video.requestVideoFrameCallback){
  const frame=(_,metadata)=>{if(!stage.isConnected||m.phase!=='playing')return;cue(metadata.mediaTime);if(!video.ended&&!video.paused)video.requestVideoFrameCallback(frame);};
  const onPlaying=video.onplaying;video.onplaying=event=>{onPlaying?.call(video,event);video.requestVideoFrameCallback(frame);};
 }
 video.onended=()=>settleVideo(article,m);video.onerror=()=>settleVideo(article,m);
 try{await video.play();if(stage.isConnected){stage.dataset.phase='playing';stage.parentElement.dataset.phase='playing';}}catch{settleVideo(article,m);}
}
grid.addEventListener('click',event=>{
 const control=event.target.closest('[data-action]');if(!control)return;const article=control.closest('[data-id]');if(!article)return;
 const m=models[Number(article.dataset.id)],action=control.dataset.action;
 if(m.state==='building')return;
 if(action==='tools'){document.getElementById('tools-toggle').click();return;}
 if(action==='coin'){awaken(article);if(isReceipt(m))creditMoment(article,m);return;}
 if(action==='play'){playMoment(article,m);return;}
 if(action==='replay'){playMoment(article,m,true);return;}
 if(action==='skip'){settleVideo(article,m);return;}
 if(action==='motion'){setReduced(!motionReduced);return;}
 if(action==='sound'){const video=article.querySelector('video');if(video){video.muted=!video.muted;setControl(control,video.muted?'sound':'mute',motionText(video.muted?'sound':'mute'));control.setAttribute('aria-pressed',String(!video.muted));}return;}
 finishWallet(article,m);
 if(action==='confirm'){if(!m.eligible||m.balance<40)return;m.state='confirm';}
 else if(action==='build'){
  if(m.state!=='confirm'||!m.eligible||m.balance<40)return;
  m.balance-=40;m.spends=(m.spends||0)+1;m.eligible=false;m.amount=0;m.homeState='estate';m.state=motionOff()?'built':'building';draw(m.id);
  const builtArticle=grid.querySelector(`[data-id="${m.id}"]`);awaken(builtArticle);
  move(builtArticle.querySelector('.coin-object'),[{transform:'rotateY(-12deg) translateY(0)',opacity:1},{transform:'rotateY(85deg) translateY(70px) scale(.3)',opacity:0}],{duration:720,easing:'ease-in'});
  if(m.state==='building')setTimeout(()=>{if(models[m.id]===m&&m.state==='building'){m.state='built';draw(m.id);}},900);
  return;
 }else m.state=action;
 draw(m.id);grid.querySelector(`[data-id="${m.id}"] .screen-title`)?.focus({preventScroll:true});
});
grid.addEventListener('pointerdown',e=>{if(motionOff())return;const surface=e.target.closest('.primary,.secondary');if(!surface)return;const r=surface.getBoundingClientRect();surface.style.setProperty('--press-x',((e.clientX-r.x)/r.width*2-1).toFixed(2));surface.style.setProperty('--press-y',((e.clientY-r.y)/r.height*2-1).toFixed(2));},{passive:true});
grid.addEventListener('pointermove',e=>{if(motionOff()||e.pointerType==='touch')return;const stage=e.target.closest('.house-scene');if(!stage)return;const r=stage.getBoundingClientRect();stage.style.setProperty('--tilt-x',((e.clientX-r.x)/r.width-.5).toFixed(2));stage.style.setProperty('--tilt-y',((e.clientY-r.y)/r.height-.5).toFixed(2));},{passive:true});
grid.addEventListener('pointerout',e=>{const stage=e.target.closest('.object-stage');if(stage&&!stage.contains(e.relatedTarget)){stage.style.setProperty('--tilt-x','0');stage.style.setProperty('--tilt-y','0');}});
document.getElementById('qa-replay').addEventListener('click',()=>{const article=grid.querySelector('[data-id="0"]'),m=models[0];if(!article||m.state!=='reward')return;if(m.phase==='playing')settleVideo(article,m);else playMoment(article,m,true);});
document.getElementById('qa-sound').addEventListener('click',event=>{const video=grid.querySelector('[data-id="0"] video');if(!video)return;video.muted=!video.muted;setControl(event.currentTarget,video.muted?'sound':'mute',motionText(video.muted?'sound':'mute'));event.currentTarget.setAttribute('aria-pressed',String(!video.muted));});
document.getElementById('locale').addEventListener('change',e=>{locale=e.target.value;draw();});
document.getElementById('scenario').addEventListener('change',e=>{
 const snapshots={first:{state:'reward',homeState:'reward',beforeBalance:70,balance:90,amount:20,eligible:true},second:{state:'reward',homeState:'reward',beforeBalance:20,balance:30,amount:10,eligible:true},support:{state:'estate',homeState:'estate',beforeBalance:70,balance:110,amount:40,eligible:true},pending:{state:'pending',homeState:'pending',balance:20,amount:null,eligible:true},cap:{state:'cap',homeState:'cap',balance:30,amount:0,eligible:true},short:{state:'estate',homeState:'estate',balance:30,amount:0,eligible:true},locked:{state:'estate',homeState:'estate',balance:70,amount:0,eligible:false}};
 models[0]={id:0,played:false,phase:'ready',...snapshots[e.target.value]};draw(0);
});
document.getElementById('text-size').addEventListener('change',e=>{document.documentElement.style.setProperty('--font-scale',e.target.value);document.body.classList.toggle('large-text',e.target.value!=='1');document.querySelector('.tools-toggle').textContent=e.target.value==='1'?'Review':`QA ${Number(e.target.value)*100}%`;draw();});
const reducedCheckbox=document.getElementById('motion-reduced');
function setReduced(value){motionReduced=value;reducedCheckbox.checked=value;document.body.classList.toggle('motion-off',value);draw();}
reducedCheckbox.addEventListener('change',e=>setReduced(e.target.checked));
matchMedia('(prefers-reduced-motion: reduce)').addEventListener('change',e=>setReduced(e.matches));
document.getElementById('tools-toggle').addEventListener('click',e=>{const opened=document.body.classList.toggle('tools-open');e.target.setAttribute('aria-expanded',String(opened));});
document.querySelector('.review-tools').id='review-settings';
document.addEventListener('keydown',e=>{if(e.key==='Escape'){document.body.classList.remove('tools-open');document.getElementById('tools-toggle').setAttribute('aria-expanded','false');}});
document.addEventListener('visibilitychange',()=>{document.body.classList.toggle('page-away',document.hidden);if(document.hidden)grid.querySelectorAll('[data-id]').forEach(article=>{const m=models[Number(article.dataset.id)];if(m.phase==='playing')settleVideo(article,m);finishWallet(article,m);article.querySelectorAll('.credit-mark,.goal-feedback').forEach(node=>node.remove());article.getAnimations({subtree:true}).filter(animation=>!('animationName' in animation)).forEach(animation=>animation.cancel());});});
if(params.get('solo')==='1'){
 document.body.classList.add('solo');
 if(params.get('view')==='estate'||params.get('screen')==='milestone')models[0]={...models[1],id:0};
}
document.getElementById('locale').value=locale;
setReduced(motionReduced);
