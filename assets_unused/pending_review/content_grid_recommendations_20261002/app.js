'use strict';

const query = new URLSearchParams(location.search);
const validViews = ['today','learn','listen','conversation','result','games','hanok','gye','packs','wallet','reward','quests','bojagi'];
const state = {
  locale: ['de','en','ko'].includes(query.get('lang')) ? query.get('lang') : 'de',
  view: validViews.includes(query.get('view')) ? query.get('view') : 'today',
  choice: null, checked: false, listened: false, textVisible: false,
  conversationStep: 0, conversationError: false, translationVisible: true,
  conversationComplete: false, rate: 1, speaking: false, speakingTurn: null,
  rewardSeen: query.get('view')==='reward', giftPhase:'closed', selectedDecoration:null,
};
let data, speechEpoch = 0, speechStartTimer = null, pendingTurn = null, screenRenderEpoch=0;
const screen = document.getElementById('screen');
const sheet = document.getElementById('sheet');
const escapeHTML = value => String(value).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const t = key => data.ui[state.locale][key];
const icon = name => `<svg class="icon" aria-hidden="true"><use href="#i-${name}"/></svg>`;
const art = (name, cls = '') => `<img class="${cls}" src="assets/${name}.png" alt="" aria-hidden="true">`;
const ctaGlyph = name => ({start:'book',check:'check',retry:'repeat',result:'check',finish:'home',close:'close','show-reward':'spark','open-gift':'spark'}[name] || 'arrow');
const action = (name, label, cls = 'primary', extra = '', attrs = '') => {
  const tactile = cls.split(' ').includes('primary');
  const object={start:'book','open-gift':'bojagi-closed','show-reward':'yeopjeon'}[name];
  const face = tactile ? `<span class="cta-emblem ${object?'with-art':''}" aria-hidden="true">${object?art(object):icon(ctaGlyph(name))}</span><span class="cta-label">${escapeHTML(label)}${name==='start'?`<small class="cta-context">${escapeHTML(t('startContext'))}</small>`:''}</span>${extra?`<span class="cta-direction" aria-hidden="true">${extra}</span>`:''}` : escapeHTML(label)+extra;
  return `<button type="button" class="${cls}${tactile?' tactile-cta':''}" data-action="${name}" ${attrs}>${face}</button>`;
};
const playFace = playing => `<span class="play-emblem" aria-hidden="true">${icon(playing?'stop':'play')}</span><span class="play-label">${escapeHTML(t(playing?'stop':'play'))}</span>`;
const turn = id => data.scene.turns.find(item => item.id === id);
const localTurn = item => item[state.locale === 'ko' ? 'ko' : state.locale];
const pill = (label, cls = '') => `<span class="pill ${cls}">${escapeHTML(label)}</span>`;
const guardian = () => `<img class="guardian" src="assets/tiger.png" alt="" aria-hidden="true">`;

function topbar() {
  return `<div class="topbar"><div class="brand-mark" aria-label="Hangul Sori">한</div><div class="top-actions">${coinBadge()}<span class="pill gold">${icon('flame')}${escapeHTML(t('streak'))}</span>${action('settings','', 'icon-button',icon('settings'),`aria-label="${escapeHTML(t('settings'))}"`)}</div></div>`;
}
const previewBalance=()=>state.rewardSeen?40:20;
function coinBadge(){return `<button class="coin-badge" type="button" data-route="wallet" aria-label="${escapeHTML(t('walletTitle'))}: ${previewBalance()} ${escapeHTML(t('coinUnit'))} · ${escapeHTML(t('walletExample'))}">${art('yeopjeon')}<strong>${previewBalance()}</strong></button>`;}
function walletCard(){return `<button class="wallet-peek" type="button" data-route="wallet">${art('yeopjeon')}<span><small>${escapeHTML(t('walletTitle'))} · ${escapeHTML(t('walletExample'))}</small><strong>${previewBalance()} ${escapeHTML(t('coinUnit'))}</strong><small>${escapeHTML(t('constructionCost'))}</small></span>${icon('chevron')}</button>`;}
function giftPeek(){return `<button class="gift-peek" type="button" data-route="quests">${art('bojagi-closed')}<span><strong>${escapeHTML(t(state.selectedDecoration?'giftEmpty':'questTitle'))}</strong><small>${escapeHTML(t('questSample'))}</small></span>${icon('chevron')}</button>`;}
function tile(name, label, sub, target, color) {
  return `<button class="practice-tile ${color || ''}" type="button" data-route="${target}">${art(name)}<strong>${escapeHTML(label)}</strong><small>${escapeHTML(sub)}</small>${icon('chevron')}</button>`;
}
function practiceTiles(full = false) {
  return `<div class="practice-grid">${tile('speaker',t('listening'),t('listenSub'),'listen','blue')}${tile('conversation',t('dialogue'),t('dialogueSub'),'conversation','mint')}${full ? tile('book',t('words'),t('wordsSub'),'catalog','gold') + tile('coffee',t('review'),t('reviewSub'),'listen','') : ''}</div>`;
}
function hanokPeek() {
  return `<button class="compact-card" type="button" data-route="hanok"><img class="thumb" src="assets/hanok.webp" alt="" aria-hidden="true"><div><h4>${escapeHTML(t('hanok'))}</h4><p>${escapeHTML(t('hanokDesc'))}</p></div>${icon('chevron')}</button>`;
}
function today() {
  return `${topbar()}<div class="greeting"><div><p>${escapeHTML(t('greeting'))}</p><h2 class="render-focus" tabindex="-1">${escapeHTML(t('nav')[0])}</h2></div>${guardian()}</div>
  <section class="hero"><div class="hero-meta"><span class="eyebrow">${escapeHTML(t('mission'))}</span>${pill(t('level'),'green')}</div><h3>${escapeHTML(t('missionTitle'))}</h3><p>${escapeHTML(t('missionDesc'))}</p><div class="hero-art">${art('coffee')}</div><div class="hero-context"><span class="small-portrait">${art('sujin')}</span><span>${escapeHTML(t('friend'))}</span><span class="duration">${icon('clock')}${escapeHTML(t('duration'))}</span></div>${action('start',t('start'),'primary',icon('arrow'))}${action('path',t('path'),'text-button',icon('chevron'))}</section>
  ${homeGrid()}${homeDiscovery()}
  ${walletCard()}${hanokPeek()}${giftPeek()}`;
}
function pathMarkup() {
  return `<div class="skill-path"><div class="path-row"><span class="path-node done">${icon('check')}</span><div class="path-copy">${escapeHTML(t('path1'))}<small>${escapeHTML(t('pathDone'))}</small></div></div><button class="path-row path-action" type="button" data-route="conversation"><span class="path-node active">2</span><div class="path-copy">${escapeHTML(t('path2'))}<small>${escapeHTML(t('pathNow'))}</small></div>${icon('chevron')}</button><div class="path-row"><span class="path-node">3</span><div class="path-copy">${escapeHTML(t('path3'))}<small>${escapeHTML(t('pathLater'))}</small></div></div></div>`;
}
function catalogFrame(mode) {
  const options=new URLSearchParams({section:mode,lang:state.locale,clean:'1',embed:'1'});
  if(state.catalogActivity)options.set('open',state.catalogActivity);
  if(document.body.classList.contains('reduced'))options.set('motion','reduce');
  if(document.body.classList.contains('large-text'))options.set('text','large');
  return `<iframe class="catalog-frame" data-catalog-frame src="catalog-review.html?${options}" title="${escapeHTML(mode==='games'?t('gamesTitle'):mode==='packs'?t('words'):t('learnTitle'))}" tabindex="0"></iframe>`;
}
function learn() { return catalogFrame('learn'); }
function packs() { return catalogFrame('packs'); }
function lessonTop(width, step) {
  return `<div class="lesson-top">${action('back','','icon-button',icon('back'),`aria-label="${escapeHTML(t('back'))}"`)}<div class="lesson-progress" role="progressbar" aria-valuemin="0" aria-valuemax="3" aria-valuenow="${step}" aria-label="${escapeHTML(t('pathTitle'))}"><span style="width:${width}%"></span></div><span class="lesson-count">${step} / 3</span></div>`;
}
function audioCard() {
  const bars = [12,18,26,16,30,24,15,23,32,18,12].map((h,i)=>`<i style="--bar:${h}px;--delay:${(i%5)*-110}ms"></i>`).join('');
  return `<div class="audio-card"><div class="audio-art">${art('speaker')}</div><div class="player-row">${action('play-invitation','','play-button play-cta',playFace(false),`aria-label="${escapeHTML(t('play'))}"`)}<div class="sound-bars" aria-hidden="true">${bars}</div>${action('rate',state.rate === 1 ? '1×' : '0.75×','rate-button','',`aria-label="${state.locale==='ko'?'재생 속도':state.locale==='de'?'Wiedergabegeschwindigkeit':'Playback speed'}"`)}</div><span class="audio-state" role="status" aria-live="polite">${escapeHTML(t('ready'))}</span></div>`;
}
function listen() {
  const choice = data.scene.listeningChoices.find(c=>c.id===state.choice);
  const passed = state.checked && choice?.correct;
  const choices = data.scene.listeningChoices.map(c=>`<button class="answer ${state.choice===c.id?'selected':''} ${state.checked&&state.choice===c.id?(c.correct?'correct':'wrong'):''}" role="radio" aria-checked="${state.choice===c.id}" type="button" data-choice="${c.id}" ${state.checked?'disabled':''}><span class="radio-dot" aria-hidden="true"></span><span>${escapeHTML(localTurn(c))}</span></button>`).join('');
  return `${lessonTop(33,1)}<span class="eyebrow">${escapeHTML(t('listening'))}</span><h2 class="lesson-heading render-focus" tabindex="-1">${escapeHTML(t('listenTitle'))}</h2><div class="context-line"><span class="small-portrait">${art('sujin')}</span>${escapeHTML(t('listenContext'))}</div>${audioCard()}${state.textVisible?`<div class="info-block"><p class="ko-inline" lang="ko">${escapeHTML(turn('invitation').ko)}</p></div>`:''}<h3 class="question">${escapeHTML(t('listenQuestion'))}</h3><div class="answer-list" role="radiogroup" aria-label="${escapeHTML(t('listenQuestion'))}">${choices}</div>
  ${state.checked?`<div class="feedback ${passed?'':'error'}" role="status">${icon(passed?'check':'help')}<span>${escapeHTML(t(passed?'correct':'wrong'))}</span></div>`:''}<div class="lesson-action">${action(passed?'listen-next':state.checked?'retry':'check',t(passed?'next':state.checked?'tryAgain':'check'),'primary',passed?icon('arrow'):'',!state.choice?'disabled':'')}</div><div class="sub-actions">${action('text',t(state.textVisible?'hideText':'showText'),'text-button')}${action('hint',t('hint'),'text-button',icon('help'))}</div>`;
}
function message(item, mine = false) {
  return `<div class="chat-message ${mine?'mine':''}"><span class="chat-label">${escapeHTML(t(mine?'you':'sujin'))}</span><div class="bubble"><p class="ko" lang="ko">${escapeHTML(item.ko)}</p>${state.translationVisible&&state.locale!=='ko'?`<p class="translation" lang="${state.locale}">${escapeHTML(localTurn(item))}</p>`:''}${!mine?action(`speak:${item.id}`,'','bubble-play',icon('volume'),`aria-label="${escapeHTML(t('play'))}: ${escapeHTML(item.ko)}"`):''}</div></div>`;
}
function conversation() {
  const step = state.conversationStep;
  const messages = step===0 ? message(turn('invitation')) : message(turn('accept_place'),true)+message(turn('propose_place_time'))+(step===2?message(turn('confirm_time'),true):'');
  const choiceSet = data.scene.responseChoices[Math.min(step,1)];
  const choices = step<2 ? `<div class="my-turn">${escapeHTML(t('yourTurn'))}</div><p class="role-cue">${escapeHTML(t(step===0?'dialogueTask0':'dialogueTask1'))}</p><div class="answer-list">${choiceSet.map((c,i)=>{const item=c.turn?turn(c.turn):c;return `<button type="button" class="answer conversation-choice" data-response="${i}"><span lang="ko">${escapeHTML(item.ko)}</span>${state.locale!=='ko'?`<small lang="${state.locale}">${escapeHTML(localTurn(item))}</small>`:''}</button>`;}).join('')}</div>` : '';
  return `${lessonTop(step===2?100:66,step===2?3:2)}<h2 class="lesson-heading render-focus" tabindex="-1">${escapeHTML(t('dialogueTitle'))}</h2><p class="role-cue">${escapeHTML(t('role'))}</p><div class="conversation-context"><span class="profile-portrait">${art('sujin')}</span><div><strong>${escapeHTML(t('sujin'))}</strong><small>${escapeHTML(t('friendLabel'))}</small></div>${icon('chat')}</div><div class="chat">${messages}</div>${choices}${state.conversationError?`<div class="feedback error" role="status">${icon('help')}<span>${escapeHTML(t('dialogueWrong'))}</span></div>`:''}<div class="conversation-footer">${step===2?action('result',t('showResult'),'primary',icon('arrow')):action('hint',t('hint'),'secondary',icon('help'))}${state.locale!=='ko'?action('translation',t(state.translationVisible?'translationHide':'translation'),'text-button'):''}</div>`;
}
function weekMarkup() {
  return `<div class="week-row">${t('weekdays').map((day,i)=>`<span class="day ${i<2?'done':i===2?'today':''}"><span>${escapeHTML(day)}</span><i>${i<3?icon('check'):'·'}</i></span>`).join('')}</div>`;
}
function result() {
  const sample = !state.conversationComplete;
  return `${lessonTop(100,3)}<div class="result-top ${sample?'':'earned'}">${sample?pill(t('example'),'gold'):''}<div class="result-art">${art('coffee')}<span class="result-seal" aria-hidden="true">${icon('check')}</span></div><h2 class="render-focus" tabindex="-1">${escapeHTML(t('resultTitle'))}</h2><p>${escapeHTML(t('resultDesc'))}</p></div><section class="achievement"><h3>${escapeHTML(t('achievements'))}</h3><div class="achievement-row">${icon('check')}<span>${escapeHTML(t('achievement1'))}</span></div><div class="achievement-row">${icon('check')}<span>${escapeHTML(t('achievement2'))}</span></div></section><section class="achievement"><span class="eyebrow">${escapeHTML(t('keepPhrase'))}</span><p class="retained-phrase" lang="ko">${escapeHTML(turn('invitation').ko)}</p>${state.locale!=='ko'?`<p class="retained-translation">${escapeHTML(localTurn(turn('invitation')))}</p>`:''}${action('play-invitation',t('play'),'text-button',icon('volume'))}</section>${hanokPeek()}<div class="lesson-action">${action('finish',t('finish'),'primary',icon('arrow'))}${action('restart',t('repeat'),'text-button',icon('repeat'))}</div>`;
}
function games() { return catalogFrame('games'); }
function rewardTop(back='today'){return `<div class="reward-top"><button class="icon-button" type="button" data-route="${back}" aria-label="${escapeHTML(t('back'))}">${icon('back')}</button>${pill(t('reviewBadge'),'gold')}${coinBadge()}</div>`;}
function wallet(){return `${rewardTop()}<h2 class="page-title render-focus" tabindex="-1">${escapeHTML(t('walletTitle'))}</h2><p class="page-intro">${escapeHTML(t('walletIntro'))}</p><section class="wallet-stage"><span class="eyebrow">${escapeHTML(t('walletExample'))}</span>${art('yeopjeon')}<strong class="wallet-amount">${previewBalance()} <small>${escapeHTML(t('coinUnit'))}</small></strong></section><section class="construction-goal"><h3>${escapeHTML(t('constructionCost'))}</h3><div class="goal-meter" role="progressbar" aria-label="${escapeHTML(t('constructionCost'))}" aria-valuemin="0" aria-valuemax="40" aria-valuenow="${Math.min(previewBalance(),40)}"><span style="width:${Math.min(previewBalance(),40)/40*100}%"></span></div><p>${escapeHTML(t('constructionCondition'))}</p><button class="primary tactile-cta" type="button" data-route="hanok"><span class="cta-emblem" aria-hidden="true">${icon('hanok')}</span><span class="cta-label">${escapeHTML(t('constructionAction'))}</span><span class="cta-direction" aria-hidden="true">${icon('arrow')}</span></button></section><details class="wallet-rules"><summary>${escapeHTML(t('walletTitle'))} · ${escapeHTML(t('walletRulesLabel'))}</summary><p>${escapeHTML(t('walletRule'))}</p></details>${giftPeek()}<p class="reward-disclaimer">${escapeHTML(t('rewardBoundary'))}</p>`;}
function reward(){return `${rewardTop('result')}<section class="reward-stage"><span class="eyebrow">${escapeHTML(t('rewardReason'))}</span><h2 class="render-focus" tabindex="-1">${escapeHTML(t('rewardTitle'))}</h2><div class="reward-object">${art('yeopjeon')}<span class="reward-spark s1" aria-hidden="true">✦</span><span class="reward-spark s2" aria-hidden="true">✦</span></div><strong class="earned-amount">+20 <span>${escapeHTML(t('coinUnit'))}</span></strong><div class="reward-total"><span>${escapeHTML(t('rewardBalance'))}</span><span>20 ${icon('arrow')} <strong>40</strong></span></div></section><div class="reward-footer"><button class="primary tactile-cta" type="button" data-route="wallet"><span class="cta-emblem" aria-hidden="true">${icon('check')}</span><span class="cta-label">${escapeHTML(t('rewardContinue'))}</span><span class="cta-direction" aria-hidden="true">${icon('arrow')}</span></button><p class="reward-disclaimer">${escapeHTML(t('rewardBoundary'))}</p></div>`;}
function quests(){return `${rewardTop()}<h2 class="page-title render-focus" tabindex="-1">${escapeHTML(t('questTitle'))}</h2><p class="page-intro">${escapeHTML(t('questIntro'))}</p><section class="quest-preview"><span class="pill gold">${escapeHTML(t('questSample'))}</span><div class="quest-receipt"><h3>${escapeHTML(t('questProgress'))}</h3><div class="quest-meter"><span></span>${art('bojagi-closed')}</div><span class="quest-count">1 / 1</span></div><button class="primary tactile-cta" type="button" data-route="bojagi"><span class="cta-emblem with-art" aria-hidden="true">${art('bojagi-closed')}</span><span class="cta-label">${escapeHTML(t('openGift'))}</span><span class="cta-direction" aria-hidden="true">${icon('arrow')}</span></button></section><p class="reward-disclaimer">${escapeHTML(t('rewardBoundary'))}</p>`;}
const decorations=[['seoan','decorSeoan'],['munbangsau','decorMunbangsau'],['soban','decorSoban']];
function bojagi(){
  const selected=decorations.find(([id])=>id===state.selectedDecoration);
  if(selected)return `${rewardTop('quests')}<section class="gift-chosen"><span class="eyebrow">BOJAGI · SARANGBANG</span><h2 class="render-focus" tabindex="-1">${escapeHTML(t('giftChosenTitle'))}</h2>${art('decoration-'+selected[0])}<strong>${escapeHTML(t(selected[1]))}</strong><p>${escapeHTML(t('giftChosenBody'))}</p></section><button class="primary tactile-cta" type="button" data-route="hanok"><span class="cta-emblem" aria-hidden="true">${icon('hanok')}</span><span class="cta-label">${escapeHTML(t('giftRoom'))}</span><span class="cta-direction" aria-hidden="true">${icon('arrow')}</span></button>${action('gift-again',t('giftAgain'),'text-button',icon('repeat'))}`;
  const closed=state.giftPhase==='closed';
  return `${rewardTop('quests')}<section class="gift-stage ${closed?'closed':'unwrapped'}"><span class="eyebrow">BOJAGI</span><h2 class="render-focus" tabindex="-1">${escapeHTML(t(closed?'questTitle':'giftPickTitle'))}</h2>${closed?`<button class="gift-knot" type="button" data-action="open-gift" aria-label="${escapeHTML(t('giftHint'))}">${art('bojagi-closed')}</button><p>${escapeHTML(t('giftHint'))}</p>`:`<div class="opened-gift">${art('bojagi-open')}</div><p>${escapeHTML(t('giftPickBody'))}</p>`}</section>${closed?action('open-gift',t('openGift'),'primary',icon('arrow')):`<div class="gift-candidates">${decorations.map(([id,label],i)=>`<button class="gift-candidate" type="button" data-decoration="${id}" style="--candidate:${i}">${art('decoration-'+id)}<strong>${escapeHTML(t(label))}</strong>${icon('chevron')}</button>`).join('')}</div>`}<p class="reward-disclaimer">${escapeHTML(t('rewardBoundary'))}</p>`;
}
function hanok() {
  return `<h2 class="page-title render-focus" tabindex="-1">${escapeHTML(t('hanokTitle'))}</h2><p class="page-intro">${escapeHTML(t('hanokIntro'))}</p><img class="feature-image" src="assets/hanok.webp" alt="${escapeHTML(t('hanokTitle'))}">${walletCard()}${giftPeek()}<div class="info-block"><h3>${escapeHTML(t('hanokDetail'))}</h3><p>${escapeHTML(t('hanokBody'))}</p></div>${action('hanok-zoom',t('hanokExplore'),'secondary',icon('hanok'))}<div class="section-heading"><h3>${escapeHTML(t('week'))}</h3></div><div class="info-block">${weekMarkup()}</div>${action('finish',t('finish'),'text-button',icon('arrow'))}`;
}
function gye() {
  return `<h2 class="page-title render-focus" tabindex="-1">${escapeHTML(t('gyeTitle'))}</h2><p class="page-intro">${escapeHTML(t('gyeIntro'))}</p><div class="conversation-context"><span class="profile-portrait">${art('christian')}</span><div><strong>${escapeHTML(t('profile'))}</strong><small>${escapeHTML(t('level'))}</small></div></div><div class="info-block"><h3>${escapeHTML(t('goal'))}</h3><p>${escapeHTML(t('goalText'))}</p></div><div class="stat-row"><div class="stat"><strong>12</strong><span>${escapeHTML(t('lessons'))}</span></div><div class="stat"><strong>3</strong><span>${escapeHTML(t('days'))}</span></div></div><div class="section-heading"><h3>${escapeHTML(t('week'))}</h3></div><div class="info-block">${weekMarkup()}</div>${action('settings',t('sound'),'secondary',icon('settings'))}`;
}
const captions = {today:'홈 콘텐츠를 그림과 짧은 제목의 2×2로 정리했습니다. 최근 사용을 반영하되 하루 동안 위치를 고정하고, 가끔 새로운 콘텐츠를 별도로 제안합니다. 이 브라우저의 시안 사용 기록만 저장합니다.',learn:'현재 메인의 실제 학습 카탈로그 13개와 원본 그림을 연결했습니다. 한글·문법·단어·듣기·발음·생활 장면·복습을 그대로 담았습니다.',listen:'문장과 선택지가 중심입니다. 실제 음성 재생 중에만 소리 표시가 움직입니다.',conversation:'작은 상대 프로필, 큰 한국어 문장, 상황에 맞는 답변. 거절 문장도 자연스러운 한국어이며 과제 목적과 구분합니다.',result:'수행한 일을 먼저 보여주고, 다시 쓸 문장과 한옥으로 이어집니다. AI 발음 점수나 실제 계정 보상을 만들지 않습니다.',games:'현재 메인의 실제 게임 8개를 원래 ID·이름·그림·소요 시간으로 연결했습니다. 게임별 엔진은 디자인 시안과 연결하지 않았습니다.',packs:'현재 CSV의 252개 팩과 기존 전용·공유 모티프 그림을 원본 바이트 그대로 사용했습니다.',hanok:'현재 한옥 그림을 보존하여 사용했습니다. 학습 성장과 공간의 연결을 검토하는 화면입니다.',gye:'현재 5탭을 유지하는 학습 기록 표현 시안입니다. 숫자는 예시이며 실제 계정 데이터를 읽거나 쓰지 않습니다.'};
Object.assign(captions,{wallet:'현재 앱의 엽전 지갑과 40엽전 건축 목표를 복원했습니다. 잔액은 시안 예시이며 실제 거래를 하지 않습니다.',reward:'밝은 단청 황색 화면과 주조 황동의 엽전. 첫 레슨 20엽전 규칙의 표시 예시이며 지급하지 않습니다.',quests:'실제 퀘스트·팩·마일스톤 보자기 흐름의 완료 표시 예시입니다.',bojagi:'현재 보자기 원본을 탭해 열고 장식 셋 중 하나를 고릅니다. 실제 보상 소유권은 변경하지 않습니다.'});
const viewNames = {today:'01 · 홈',learn:'02 · 학습',listen:'03 · 듣기',conversation:'04 · 대화',result:'05 · 결과',games:'06 · 실제 게임',packs:'07 · 실제 Packs',wallet:'08 · 엽전 지갑',reward:'09 · 엽전 획득',quests:'10 · 보자기 도착',bojagi:'11 · 보자기 열기'};

function render(focus = false) {
  const renderEpoch=++screenRenderEpoch;
  document.documentElement.removeAttribute('data-screen-ready');
  document.documentElement.removeAttribute('data-catalog-ready');
  const renderers = {today,learn,listen,conversation,result,games,hanok,gye,packs,wallet,reward,quests,bojagi};
  screen.innerHTML = `<div class="page ${['learn','games','packs'].includes(state.view)?'catalog-host':''}" data-view="${state.view}">${renderers[state.view]()}</div>`;
  watchDiscovery();
  if(state.view==='result')screen.querySelector('.result-top').insertAdjacentHTML('afterend',`<div class="reward-preview-action">${action('show-reward',t('rewardPreview'),'primary',icon('arrow'))}</div>`);
  const active = ['listen','conversation','result','packs','reward'].includes(state.view)?'learn':['wallet','bojagi'].includes(state.view)?'hanok':state.view==='quests'?'today':state.view;
  const navRoutes = ['today','learn','games','hanok','gye'];
  const icons = ['home','book','game','hanok','user'];
  document.getElementById('nav').innerHTML = navRoutes.map((view,i)=>`<button type="button" class="nav-button" data-route="${view}" ${active===view?'aria-current="page"':''}><span class="icon-wrap">${icon(icons[i])}</span><span>${escapeHTML(t('nav')[i])}</span></button>`).join('');
  document.getElementById('nav').setAttribute('aria-label',state.locale==='de'?'Hauptnavigation':state.locale==='en'?'Main navigation':'주 메뉴');
  document.getElementById('view-controls').innerHTML = Object.entries(viewNames).map(([key,label])=>`<button type="button" data-route="${key}" aria-pressed="${state.view===key}">${label}</button>`).join('');
  document.getElementById('caption').textContent = captions[state.view];
  document.getElementById('locale').value = state.locale;
  document.documentElement.lang = state.locale;
  if (focus) (screen.querySelector('.render-focus')||screen.querySelector('iframe'))?.focus({preventScroll:true});
  if(!['learn','games','packs'].includes(state.view)){
    const initialImages=[...screen.querySelectorAll('img')].slice(0,5);
    Promise.all(initialImages.map(i=>i.decode().catch(()=>{}))).then(()=>document.fonts?.ready).then(()=>new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve)))).then(()=>{if(renderEpoch===screenRenderEpoch)document.documentElement.dataset.screenReady='true';});
  }
}
function stopSpeech() {
  speechEpoch++;
  clearTimeout(speechStartTimer);speechStartTimer=null;pendingTurn=null;
  if ('speechSynthesis' in window) window.speechSynthesis.cancel();
  state.speaking = false;
  state.speakingTurn = null;
  updateAudio(false,t('ready'));
}
function updateAudio(playing, text) {
  screen.querySelector('.audio-card')?.classList.toggle('playing',playing);
  const status = screen.querySelector('.audio-state');
  if (status) status.textContent = text;
  const button = screen.querySelector('[data-action="play-invitation"]');
  if (button?.classList.contains('play-button')) button.innerHTML = playFace(playing);
  if (button) button.setAttribute('aria-label',t(playing?'stop':'play'));
}
function speak(id) {
  if (state.speakingTurn === id || pendingTurn === id) { stopSpeech(); return; }
  stopSpeech();
  if (!('speechSynthesis' in window)) { showUnavailable(); return; }
  const voice = window.speechSynthesis.getVoices().find(v=>/^ko(?:-|_)/i.test(v.lang));
  if (!voice) { showUnavailable(); return; }
  const epoch = speechEpoch;
  const utterance = new SpeechSynthesisUtterance(turn(id).ko);
  utterance.voice = voice;
  utterance.lang = 'ko-KR';
  utterance.rate = state.rate;
  pendingTurn=id;updateAudio(false,t('starting'));
  speechStartTimer=setTimeout(()=>{if(epoch!==speechEpoch||state.speaking)return;stopSpeech();showUnavailable();},3500);
  utterance.onstart = () => { if (epoch!==speechEpoch) return;clearTimeout(speechStartTimer);pendingTurn=null;state.speaking=true;state.speakingTurn=id;updateAudio(true,t('playing')); };
  utterance.onend = () => { if (epoch!==speechEpoch) return;clearTimeout(speechStartTimer);pendingTurn=null;state.speaking=false;state.speakingTurn=null;state.listened=true;updateAudio(false,t('ready')); };
  utterance.onerror = () => { if(epoch!==speechEpoch)return;clearTimeout(speechStartTimer);pendingTurn=null;state.speaking=false;state.speakingTurn=null;showUnavailable(); };
  window.speechSynthesis.speak(utterance);
}
function showUnavailable() {
  updateAudio(false,t('audioUnavailable'));
  if (!screen.querySelector('.audio-state')) showSheet(t('showText'),`<p class="ko" lang="ko">${escapeHTML(turn('invitation').ko)}</p><p>${escapeHTML(t('audioUnavailable'))}</p>`);
}
function route(view, activity = null) {
  state.catalogActivity=activity;
  if (sheet.open) sheet.close();
  stopSpeech();
  if (view==='catalog') view='packs';
  state.view = validViews.includes(view)?view:'today';
  render(true);
  screen.scrollTop = 0;
  const url = new URL(location.href);url.searchParams.set('view',state.view);url.searchParams.set('lang',state.locale);history.replaceState(null,'',url);
}
function restart() {
  stopSpeech();state.choice=null;state.checked=false;state.listened=false;state.textVisible=false;state.conversationStep=0;state.conversationError=false;state.conversationComplete=false;route('listen');
}
function showSheet(title, body) {
  stopSpeech();
  document.getElementById('sheet-content').innerHTML = `<h2>${escapeHTML(title)}</h2>${body}${action('close',t('close'))}`;
  sheet.showModal();
}
document.addEventListener('click', event => {
  const target = event.target.closest('button');
  if (!target || target.disabled || !data) return;
  if(target.dataset.contentId){openHomeActivity(target.dataset.contentId);return;}
  if(target.dataset.dismissContent){dismissHomeContent(target.dataset.dismissContent);return;}
  if(target.dataset.decoration){state.selectedDecoration=target.dataset.decoration;render(true);screen.scrollTop=0;return;}
  if (target.dataset.route) { route(target.dataset.route);return; }
  if (target.dataset.choice) { state.choice=target.dataset.choice;state.checked=false;render();return; }
  if (target.dataset.response !== undefined) {
    const selected = data.scene.responseChoices[Math.min(state.conversationStep,1)][Number(target.dataset.response)];
    if (selected.correct) { stopSpeech();state.conversationStep++;state.conversationError=false;if(state.conversationStep===2)state.conversationComplete=true;render();screen.querySelector(state.conversationStep===2?'.conversation-footer':'.my-turn')?.scrollIntoView({block:'nearest',behavior:'auto'}); }
    else { state.conversationError=true;render();screen.querySelector('.feedback')?.scrollIntoView({block:'nearest',behavior:'auto'}); }
    return;
  }
  const name = target.dataset.action;
  if (name?.startsWith('speak:')) { speak(name.slice(6));return; }
  switch (name) {
    case 'start': trackHomeContent('listening');restart();break;
    case 'back': route(state.view==='result'?'conversation':'learn');break;
    case 'check': if(state.choice){state.checked=true;stopSpeech();render();screen.querySelector('.feedback')?.scrollIntoView({block:'nearest'});}break;
    case 'retry': state.choice=null;state.checked=false;render();break;
    case 'listen-next': trackHomeContent('scenarios');route('conversation');break;
    case 'result': route('result');break;
    case 'finish': route('today');break;
    case 'restart': restart();break;
    case 'play-invitation': speak('invitation');break;
    case 'rate': stopSpeech();state.rate=state.rate===1?.75:1;render();break;
    case 'text': stopSpeech();state.textVisible=!state.textVisible;render();break;
    case 'translation': stopSpeech();state.translationVisible=!state.translationVisible;render();break;
    case 'hint': showSheet(t('hintTitle'),`<p class="ko" lang="ko">${escapeHTML(turn('invitation').ko)}</p><p>${escapeHTML(t('hintBody'))}</p>`);break;
    case 'path': showSheet(t('pathTitle'),pathMarkup());break;
    case 'bojagi': route('quests');break;
    case 'show-reward': state.rewardSeen=true;route('reward');break;
    case 'open-gift': state.giftPhase='open';render(true);screen.scrollTop=0;break;
    case 'gift-again': state.giftPhase='closed';state.selectedDecoration=null;route('bojagi');break;
    case 'hanok-zoom': showSheet(t('hanokTitle'),`<img src="assets/hanok.webp" alt="${escapeHTML(t('hanokTitle'))}">`);break;
    case 'settings': showSheet(t('sound'),`<p>${state.locale==='ko'?'움직임을 줄이려면 왼쪽 검토 도구의 옵션을 켜세요. 기기의 움직임 감소 설정도 자동으로 반영해요.':state.locale==='de'?'Du kannst Bewegungen in den Vorschau-Einstellungen reduzieren. Auch die entsprechende Systemeinstellung wird berücksichtigt.':'Reduce motion in the preview controls. Your system preference is respected too.'}</p>`);break;
    case 'close': sheet.close();break;
  }
});
sheet.addEventListener('close',stopSpeech);
document.addEventListener('visibilitychange',()=>{if(document.hidden)stopSpeech();});
window.addEventListener('pagehide',stopSpeech);
document.getElementById('locale').addEventListener('change',event=>{if(sheet.open)sheet.close();stopSpeech();state.locale=event.target.value;render();const url=new URL(location.href);url.searchParams.set('lang',state.locale);history.replaceState(null,'',url);});
document.getElementById('reduce').addEventListener('change',event=>{document.body.classList.toggle('reduced',event.target.checked);screen.querySelector('iframe')?.contentWindow?.postMessage({soriReviewMotion:event.target.checked},location.origin);});
window.addEventListener('message',event=>{if(event.origin!==location.origin||event.source!==screen.querySelector('iframe')?.contentWindow)return;if(typeof event.data?.soriActivityOpened==='string')trackHomeContent(event.data.soriActivityOpened);if(event.data?.soriReviewArtReady===true)document.documentElement.dataset.catalogReady='true';if(['listen','conversation','packs'].includes(event.data?.soriReviewRoute))route(event.data.soriReviewRoute);});

// Keep the radio group operable with arrow keys, then restore focus after rendering.
document.addEventListener('keydown',event=>{
  const target=event.target.closest('[data-choice]');
  if(!target || target.disabled || !['ArrowDown','ArrowUp','ArrowLeft','ArrowRight','Home','End'].includes(event.key))return;
  event.preventDefault();
  const choices=data.scene.listeningChoices;
  const current=choices.findIndex(choice=>choice.id===target.dataset.choice);
  const next=event.key==='Home'?0:event.key==='End'?choices.length-1:(current+(['ArrowDown','ArrowRight'].includes(event.key)?1:-1)+choices.length)%choices.length;
  state.choice=choices[next].id;state.checked=false;render();
  screen.querySelector(`[data-choice="${state.choice}"]`)?.focus();
});
document.getElementById('reset').addEventListener('click',()=>{state.rewardSeen=false;state.giftPhase='closed';state.selectedDecoration=null;restart();route('today');});
if(query.get('clean')==='1')document.body.classList.add('clean');
if(query.get('motion')==='reduce'){document.body.classList.add('reduced');document.getElementById('reduce').checked=true;}
if(query.get('text')==='large')document.body.classList.add('large-text');
Promise.all(['content.json','catalog-data.json'].map(file=>fetch(file).then(response=>{if(!response.ok)throw new Error(file);return response.json();}))).then(([content,catalog])=>{data=content;initHomeContent(catalog);render();document.documentElement.dataset.ready='true';}).catch(()=>{screen.innerHTML='<div class="page"><h2>시안을 불러오지 못했습니다.</h2><p>로컬 검토 서버에서 열어 주세요.</p></div>';});
