import {
  href, indexData, local, meaning, normalise, ordered, parseRoute,
  practice, resolve, stages, summary,
} from './model.mjs';
import {
  art, audioButton, button, escape as e, go, icon, layout,
  structured, tools, translator,
} from './ui.mjs';
import {extra, home, itemTitle, library, moduleArt} from './catalog.mjs';
import {
  grammarDetail, pronunciationDetail, relationDetail,
} from './detail_views.mjs';
import {packDetail, reviewHomeResult, wordCard} from './word_views.mjs';

const app = document.querySelector('#app');
const sheet = document.querySelector('#sheet');
const STORAGE_FALLBACK = 'hangulsori.c-free-learning.20261005.v1';

class PreviewStore {
  constructor(namespace) {
    this.key = `${namespace || STORAGE_FALLBACK}.state`;
    this.state = this._read();
  }
  _empty() {
    return {last:null, attempts:{}, review:{}, custom:[], planned:[], goals:{}};
  }
  _read() {
    try {
      return {...this._empty(), ...JSON.parse(sessionStorage.getItem(this.key) || '{}')};
    } catch (_) {
      return this._empty();
    }
  }
  _write() {
    sessionStorage.setItem(this.key, JSON.stringify(this.state));
  }
  last() { return this.state.last; }
  remember(route) {
    if (!['home','library','extra'].includes(route.view)) {
      this.state.last = Object.fromEntries(
        Object.entries(route).filter(([,v]) => v !== '' && v !== 0 && v !== 'all')
      );
      this._write();
    }
  }
  custom() { return this.state.custom; }
  addCustom(korean, value, lang) {
    const id = `custom:${Date.now()}`;
    this.state.custom.unshift({
      id, korean, level:'CUSTOM', pack_id:'custom', romanization:'',
      german:lang === 'de' ? value : '', english:lang === 'en' ? value : '',
      de:lang === 'de' ? value : '', en:lang === 'en' ? value : '',
      example_korean:'', example_german:'', example_english:'',
    });
    this._write();
    return id;
  }
  planned(id) { return this.state.planned.includes(id); }
  togglePlan(id) {
    const set = new Set(this.state.planned);
    set.has(id) ? set.delete(id) : set.add(id);
    this.state.planned = [...set];
    this._write();
  }
  practiceKey(route) { return `${route.m}|${route.id}|${route.mode || 'practice'}`; }
  attempts(route) {
    const key = this.practiceKey(route);
    return this.state.attempts[key] ||= {};
  }
  setAttempt(route, qid, value) {
    const key = this.practiceKey(route);
    this.state.attempts[key] ||= {};
    this.state.attempts[key][qid] = value;
    this._write();
  }
  clearAttempts(route) {
    delete this.state.attempts[this.practiceKey(route)];
    this._write();
  }
  review() { return this.state.review; }
  setReview(id, rating) {
    this.state.review[id] = {rating, at:new Date().toISOString()};
    this._write();
  }
  goal(module) { return this.state.goals[module] || 0; }
  setGoal(module, value) {
    this.state.goals[module] = value;
    this._write();
  }
}

let data;
let model;
let store;
let route;
let ui = freshUi();
let mediaStream = null;
let recorder = null;
let recordingChunks = [];
let recordTimer = null;
let audioPlayer = null;

function freshUi() {
  return {
    revealed:false, selected:{}, feedback:{}, help:{},
    recording:false, micError:false, recordUrl:null, recordingStarted:0,
  };
}

function env() {
  const t = translator(route.lang);
  return {model, route, store, ui, t, structured, href};
}

function setRoute(next, {replace=false}={}) {
  const url = href(route, next);
  if (replace) history.replaceState({}, '', url);
  else history.pushState({}, '', url);
  route = parseRoute(location.search);
  ui = freshUi();
  store.remember(route);
  render();
}

function showSheet(title, body, actions='') {
  sheet.innerHTML = `<div class="sheet-title"><h2 id="sheet-title">${e(title)}</h2><button class="icon" data-action="close-sheet" aria-label="Close">${icon('close')}</button></div>${body}${actions}`;
  if (!sheet.open) sheet.showModal();
}

function closeSheet() {
  if (sheet.open) sheet.close();
}

function stateView() {
  if (!route.state) return null;
  const t = translator(route.lang);
  if (route.state === 'loading') {
    return {body:`<section class="paper board inset"><div class="skeleton art"></div><div class="skeleton"></div><div class="skeleton"></div><div class="skeleton"></div></section>`};
  }
  if (route.state === 'source-error') {
    return {body:`<section class="paper board inset empty"><h1>${e(t('loadError'))}</h1><p>${e(t('adjust'))}</p>${go(route,{state:''},t('retry'),'button jade')}</section>`};
  }
  return null;
}

function listeningDetailView(x) {
  const {model, route, t} = x;
  const lesson = model.maps.listening.get(route.id);
  const linked = lesson.contentIds
    .map(id => model.maps.scenarios.get(id))
    .filter(Boolean);
  const turns = linked.flatMap(scene => scene.dialog || []);
  const dialog = turns.map(turn => `
    <div class="turn">
      <p class="speaker">${e(turn.speaker || '')}</p>
      <p class="ko">${e(turn.ko || '')}</p>
      <p class="translation">${e(turn[route.lang] || '')}</p>
      ${turn.ko ? audioButton(turn.ko, x) : ''}
    </div>`).join('');
  return {
    title: local(lesson.title, route.lang),
    subtitle: `${lesson.questions.length} ${t('question')}`,
    headingArt: moduleArt('listening', model),
    body:`<section class="paper board inset">
      <p class="eyebrow">${e(lesson.level.toUpperCase())} · ${e(t('listening'))}</p>
      <h2>${e(local(lesson.intro, route.lang))}</h2>
      <div class="rule"></div>
      <h2 class="category-title">${e(t('dialog'))}</h2>
      ${dialog || `<p class="muted">${e(t('empty'))}</p>`}
      <div class="rule"></div>
      <div class="list">${lesson.questions.map((q,i) => `
        <a class="list-row" data-go href="${e(href(route,{view:'practice',item:q.id,at:i}))}">
          <span><strong>${e(local(q.prompt,route.lang))}</strong><small>${e(q.skill || q.type)}</small></span>${icon('next')}
        </a>`).join('')}</div>
    </section>`,
    footer: go(route,{view:'practice',item:lesson.questions[0]?.id || '',at:0},t('start')),
  };
}

function scenarioIntro(scene, x) {
  const {route,t} = x;
  const image = scene.backdrop && model.data.assetHashes[`assets/illustrations/scenes/${scene.backdrop}.png`]
    ? `assets/illustrations/scenes/${scene.backdrop}.png` : '';
  return `<section class="paper board inset">
    ${image ? art(image, local(scene.title,route.lang), 'art scene-art') : ''}
    <p class="eyebrow">${e(scene.level.toUpperCase())} · ${e(scene.register || '')}</p>
    <h1>${e(local(scene.title,route.lang))}</h1>
    <p class="space">${e(local(scene.intro,route.lang))}</p>
    <div class="rule"></div>
    <p class="context"><strong>${e(t('participants'))}</strong><br>${e((scene.participantIds || []).join(' · '))}</p>
    <p class="context"><strong>${e(t('purpose'))}</strong><br>${e(scene.intent || '')}</p>
    <p class="context"><strong>${e(t('situation'))}</strong><br>${e(scene.relationshipContext || '')}</p>
  </section>`;
}

function scenarioSteps(scene, x, active='intro') {
  const labels = {
    intro:x.t('intro'), vocab:x.t('vocab'), dialog:x.t('dialog'),
    grammar:x.t('grammar'), role:x.t('role'), quests:x.t('quests'), result:x.t('result'),
  };
  return `<nav class="steps">${stages.map(stage => {
    const changes = stage === 'quests'
      ? {view:'practice',stage:'quests',item:scene.quests?.[0]?.id || '',at:0}
      : stage === 'result'
        ? {view:'result',stage:'result',item:'',at:0}
        : {view:stage === 'intro' ? 'detail' : 'scenario',stage,item:'',at:0};
    return `<a data-go class="step ${stage===active?'active':''}" href="${e(href(route,changes))}">${e(labels[stage])}</a>`;
  }).join('')}</nav>`;
}

function scenarioDetailView(x) {
  const scene = x.model.maps.scenarios.get(x.route.id);
  return {
    title: local(scene.title,x.route.lang),
    subtitle: local(scene.intro,x.route.lang),
    headingArt: moduleArt('scenarios',x.model),
    body:`${scenarioSteps(scene,x,'intro')}${scenarioIntro(scene,x)}`,
    footer: go(x.route,{view:'scenario',stage:'vocab',item:'',at:0},x.t('continue')),
  };
}

function scenarioStageView(x) {
  const {model,route,t} = x;
  const scene = model.maps.scenarios.get(route.id);
  const stage = route.stage || 'intro';
  let body = '';
  if (stage === 'vocab') {
    body = (scene.vocab || []).map((v,i) => `
      <div class="turn" id="scenario-vocab-${i}">
        <p class="ko">${e(v.korean || v.ko || '')}</p>
        <p class="translation">${e(local(v.note,route.lang) || v[route.lang] || '')}</p>
        ${v.korean ? audioButton(v.korean,x) : ''}
      </div>`).join('');
  } else if (stage === 'dialog') {
    body = (scene.dialog || []).map((turn,i) => `
      <div class="turn" id="scenario-dialog-${i}">
        <p class="speaker">${e(turn.speaker || '')}</p>
        <p class="ko">${e(turn.ko || '')}</p>
        <p class="translation">${e(turn[route.lang] || '')}</p>
        ${turn.ko ? audioButton(turn.ko,x) : ''}
      </div>`).join('');
  } else if (stage === 'grammar') {
    const g = scene.grammarBlock || {};
    body = `<div class="context"><h2>${e(local(g.title,route.lang) || t('grammar'))}</h2><p class="space">${e(local(g.explanation,route.lang))}</p></div>
      ${(scene.grammarIds || []).map(id => model.maps.grammar.has(id)
        ? go(route,{view:'detail',m:'grammar',id,item:'',stage:''},model.maps.grammar.get(id).pattern,'quiet')
        : `<p class="source-id">${e(id)}</p>`).join('')}`;
  } else if (stage === 'role') {
    body = `<div class="context"><h2>${e(t('purpose'))}</h2><p>${e(scene.intent || '')}</p></div>
      <div class="context"><h2>${e(t('situation'))}</h2><p>${e(scene.relationshipContext || '')}</p></div>
      <p class="notice">${e(route.lang === 'de' ? 'Sprich die Szene mit deinen eigenen Worten. Deine freie Antwort wird in dieser Vorschau nicht automatisch bewertet.' : 'Play the scene in your own words. Free responses are not automatically graded in this preview.')}</p>`;
  } else {
    body = scenarioIntro(scene,x);
  }
  const next = stage === 'vocab' ? 'dialog' : stage === 'dialog' ? 'grammar' : stage === 'grammar' ? 'role' : 'quests';
  return {
    title: local(scene.title,route.lang),
    body:`${scenarioSteps(scene,x,stage)}<section class="paper board inset">${body || `<p class="muted">${e(t('empty'))}</p>`}</section>`,
    footer: next === 'quests'
      ? go(route,{view:'practice',stage:'quests',item:scene.quests?.[0]?.id || '',at:0},t('quests'))
      : go(route,{view:'scenario',stage:next,item:'',at:0},t('continue')),
  };
}

function detailView(x) {
  if (route.m === 'words') return packDetail(x);
  if (route.m === 'grammar') return grammarDetail(x);
  if (route.m === 'pronunciation') return pronunciationDetail(x);
  if (route.m === 'relations') return relationDetail(x);
  if (route.m === 'listening') return listeningDetailView(x);
  if (route.m === 'scenarios') return scenarioDetailView(x);
  return missingView(x);
}

function practiceQuestionView(x) {
  const p = practice(x.model,x.route);
  if (p.invalid || !p.record || !p.questions.length) {
    return {body:`<section class="paper board inset empty" data-missing-view><h1>${e(x.t('missing'))}</h1><p>${e(x.t('notQuiz'))}</p>${go(x.route,{view:'detail',item:'',at:0},x.t('detail'),'button secondary')}</section>`};
  }
  let index = Number.isFinite(x.route.at) ? x.route.at : 0;
  if (x.route.item) {
    const found = p.questions.findIndex(q => q.id === x.route.item);
    if (found >= 0) index = found;
  }
  index = Math.max(0,Math.min(index,p.questions.length-1));
  const q = p.questions[index];
  const attempts = x.store.attempts(x.route);
  const attempt = attempts[q.id] || null;
  const selected = ui.selected[q.id] ?? attempt?.answer ?? '';
  const feedback = ui.feedback[q.id] ?? attempt?.checked ?? false;
  const isCorrect = feedback && normalise(selected) === normalise(q.answer);
  const helped = ui.help[q.id] || attempt?.help;
  let control = '';
  if (q.type === 'choice') {
    control = `<div class="answers">${q.options.map((option,i) => {
      const active = String(selected) === String(option.value);
      const cls = feedback
        ? String(option.value) === String(q.answer) ? 'correct' : active ? 'wrong' : ''
        : active ? 'selected' : '';
      return `<button class="answer ${cls}" data-action="select-answer" data-value="${e(option.value)}"><span class="letter">${String.fromCharCode(65+i)}</span><span class="${option.korean?'ko':''}">${e(option.text)}</span></button>`;
    }).join('')}</div>`;
  } else if (q.type === 'order') {
    const words = ordered(
      [...String(q.answer || '').trim().split(/\s+/).filter(Boolean),
       ...(q.distractors || []).flatMap(v => String(v).trim().split(/\s+/)).filter(Boolean)],
      q.id,
    );
    const current = String(selected || '').trim().split(/\s+/).filter(Boolean);
    control = `<div class="well" data-placeholder="${e(x.t('pieces'))}">${current.map((word,i) => `<button class="tile" data-action="remove-piece" data-index="${i}">${e(word)}</button>`).join('')}</div>
      <div class="tiles">${words.map(word => `<button class="tile" data-action="add-piece" data-value="${e(word)}">${e(word)}</button>`).join('')}</div>`;
  } else {
    control = `<label><span class="field-label">${e(x.t('write'))}</span><textarea data-answer-input class="ko" placeholder="${e(x.t('write'))}">${e(selected)}</textarea></label>`;
  }
  const promptClass = /[가-힣]/.test(q.prompt || '') ? 'ko' : '';
  const feedbackBox = feedback ? `<div class="feedback ${isCorrect?'':'wrong'}">
      <h2>${e(x.t(isCorrect?'right':'wrong'))}</h2>
      ${!isCorrect ? `<p>${e(x.t('firstWrong'))}</p>` : ''}
      ${q.evidence ? `<p class="ko">${e(q.evidence)}</p>` : ''}
      ${q.explanation ? `<p>${e(q.explanation)}</p>` : ''}
    </div>` : helped ? `<div class="feedback"><h2>${e(x.t('hint'))}</h2>${q.evidence?`<p class="ko">${e(q.evidence)}</p>`:''}${q.explanation?`<p>${e(q.explanation)}</p>`:''}</div>` : '';
  const last = index === p.questions.length-1;
  const nextFooter = feedback
    ? button(last?x.t('finish'):x.t('next'),'next-question','jade',{next:index+1})
    : button(x.t('check'),'check-answer','jade');
  return {
    progress:{label:itemTitle(p.record,x),current:index+1,total:p.questions.length},
    body:`<section class="paper board inset">
      <p class="eyebrow">${e(x.route.mode || x.t('question'))}</p>
      ${q.audio ? audioButton(q.audio,x) : ''}
      <div class="question-prompt ${promptClass}">${e(q.prompt || (q.audio ? x.t('listen') : x.t('question')))}</div>
      ${control}
      ${feedbackBox}
      <div class="space chips">
        <button class="quiet" data-action="hint">${e(x.t('hint'))}</button>
        <button class="quiet" data-action="reveal">${e(x.t('reveal'))}</button>
      </div>
    </section>`,
    footer:nextFooter,
  };
}

function resultView(x) {
  if (x.route.m === 'review') return reviewHomeResult(x);
  const p = practice(x.model,x.route);
  if (p.invalid || !p.record) return missingView(x);
  const attempts = x.store.attempts(x.route);
  const s = summary(p.questions,attempts);
  return {
    body:`<section class="paper board inset">
      <div class="line">${art('assets/illustrations/concept_c/seal_v2.png','','seal')}<div><p class="eyebrow">${e(x.t('result'))}</p><h1>${e(itemTitle(p.record,x))}</h1></div></div>
      <div class="metrics"><div class="metric"><strong>${s.unaided}</strong><small>${e(x.t('unaided'))}</small></div><div class="metric"><strong>${s.assisted}</strong><small>${e(x.t('assisted'))}</small></div></div>
      <p class="muted">${s.answered} / ${s.total}</p>
      <div class="list">${p.questions.map(q => {
        const a=attempts[q.id];
        return `<div class="list-row"><span><strong>${e(q.prompt || q.id)}</strong><small>${a ? (a.firstCorrect&&!a.help ? e(x.t('unaided')) : e(x.t('assisted'))) : e(x.t('noAttempt'))}</small></span></div>`;
      }).join('')}</div>
      <p class="save-status ${x.route.state==='save-error'?'error':''}">${e(x.route.state==='save-error'?x.t('saveError'):x.t('saved'))}</p>
    </section>`,
    footer:`${button(x.t('reset'),'reset-practice','secondary')}${go(x.route,{view:'detail',item:'',at:0,state:''},x.t('detail'),'button')}`,
  };
}

function missingView(x) {
  return {body:`<section class="paper board inset empty" data-missing-view><h1>${e(x.t('missing'))}</h1><p>${e(x.t('adjust'))}</p>${go(x.route,{view:'library',id:'',item:'',mode:'',state:''},x.t('library'),'button secondary')}</section>`};
}

function currentView(x) {
  const special = stateView();
  if (special) return special;
  if (route.view === 'home') return home(x);
  if (route.view === 'library') return library(x);
  if (route.view === 'extra') return extra(x);
  if (route.view === 'detail') return detailView(x);
  if (route.view === 'card') return wordCard(x);
  if (route.view === 'scenario') return scenarioStageView(x);
  if (route.view === 'practice') return practiceQuestionView(x);
  if (route.view === 'result') return resultView(x);
  return missingView(x);
}

function render() {
  document.documentElement.dataset.scale = String(route.scale || 1);
  const resolved = resolve(model,route);
  if (!['home','library'].includes(route.view) && route.m !== 'extras' && !resolved.valid && !route.state) {
    app.innerHTML = layout(env(),missingView(env()));
    bindPage();
    return;
  }
  const x = env();
  app.innerHTML = layout(x,currentView(x));
  bindPage();
  if (!window.__C_FREE_LEARNING_HEADLESS_BATCH__) requestAnimationFrame(() => {
    document.querySelector('[data-page-heading]')?.focus({preventScroll:true});
    if (route.view === 'scenario' && route.item) {
      const prefix = route.stage === 'dialog' ? 'scenario-dialog-' : route.stage === 'vocab' ? 'scenario-vocab-' : '';
      if (prefix) document.getElementById(`${prefix}${route.at || 0}`)?.scrollIntoView({block:'center'});
    }
  });
}

function activeQuestion() {
  const p = practice(model,route);
  if (p.invalid || !p.questions.length) return {p,q:null,index:-1};
  let index = route.at || 0;
  if (route.item) {
    const found = p.questions.findIndex(q => q.id === route.item);
    if (found >= 0) index = found;
  }
  index = Math.max(0,Math.min(index,p.questions.length-1));
  return {p,q:p.questions[index],index};
}

async function playCanonical(text, buttonNode) {
  const t = translator(route.lang);
  const status = buttonNode?.parentElement?.querySelector('[data-audio-status]');
  if (audioPlayer) {
    audioPlayer.pause();
    audioPlayer = null;
  }
  const entry = data.audio?.[text];
  if (!entry?.canonical || !entry?.url) {
    if (status) status.textContent = t('audioMissing');
    return;
  }
  try {
    if (status) status.textContent = '';
    audioPlayer = new Audio(entry.url);
    await audioPlayer.play();
  } catch (_) {
    if (status) status.textContent = t('audioError');
  }
}

function addWordSheet() {
  const t = translator(route.lang);
  showSheet(
    t('add'),
    `<form data-add-word><label><span class="field-label">${e(t('korean'))}</span><input name="ko" class="ko" required></label><div class="space"></div><label><span class="field-label">${e(t('translation'))}</span><input name="meaning" required></label><p class="audio-status" data-form-error></p><button class="button jade" type="submit"><span>${e(t('addWord'))}</span>${icon('next')}</button></form>`,
  );
}

function goalSheet() {
  const t = translator(route.lang);
  const current = store.goal('listening') || 5;
  showSheet(
    t('setGoal'),
    `<p>${e(t('goalCopy'))}</p><form data-goal-form class="space"><label><span class="field-label">${e(t('lessons'))}</span><input name="goal" type="number" min="1" max="50" value="${current}"></label><button class="button jade" type="submit"><span>${e(t('setGoal'))}</span>${icon('next')}</button></form>`,
  );
}

function infoSheet() {
  const t = translator(route.lang);
  const boundary = data.boundary || {};
  showSheet(
    t('info'),
    `<p>${e(t('preview'))}</p><div class="rule"></div><p class="notice">realAccountWrites: ${e(String(boundary.realAccountWrites))}</p><p class="notice">paidServices: ${e(String(boundary.paidServices))}</p><p class="notice">scoreOrRewards: ${e(String(boundary.scoreOrRewards))}</p><p class="notice">${e(boundary.audioPolicy || '')}</p>`,
  );
}

async function startRecording() {
  const t = translator(route.lang);
  ui.micError = false;
  if (!navigator.mediaDevices?.getUserMedia || !window.MediaRecorder) {
    ui.micError = true;
    render();
    return;
  }
  try {
    mediaStream = await navigator.mediaDevices.getUserMedia({audio:true});
    recordingChunks = [];
    recorder = new MediaRecorder(mediaStream);
    recorder.addEventListener('dataavailable', event => {
      if (event.data?.size) recordingChunks.push(event.data);
    });
    recorder.addEventListener('stop', () => {
      if (ui.recordUrl) URL.revokeObjectURL(ui.recordUrl);
      const blob = new Blob(recordingChunks,{type:recorder?.mimeType || 'audio/webm'});
      ui.recordUrl = URL.createObjectURL(blob);
      ui.recording = false;
      mediaStream?.getTracks().forEach(track => track.stop());
      mediaStream = null;
      clearInterval(recordTimer);
      render();
    });
    recorder.start();
    ui.recording = true;
    ui.recordingStarted = Date.now();
    render();
    recordTimer = setInterval(() => {
      const node = document.querySelector('[data-record-timer]');
      if (!node) return;
      const seconds = Math.floor((Date.now()-ui.recordingStarted)/1000);
      node.textContent = `${String(Math.floor(seconds/60)).padStart(2,'0')}:${String(seconds%60).padStart(2,'0')}`;
    },250);
  } catch (_) {
    ui.micError = true;
    ui.recording = false;
    if (mediaStream) mediaStream.getTracks().forEach(track => track.stop());
    mediaStream = null;
    render();
  }
}

function stopRecording() {
  if (recorder && recorder.state !== 'inactive') recorder.stop();
}

function bindPage() {
  const input = document.querySelector('[data-answer-input]');
  if (input) {
    input.addEventListener('input', () => {
      const {q} = activeQuestion();
      if (q) ui.selected[q.id] = input.value;
    });
  }
}

async function handleAction(action, node) {
  const t = translator(route.lang);
  if (action === 'close-sheet') return closeSheet();
  if (action === 'info') return infoSheet();
  if (action === 'audio') return playCanonical(node.dataset.text || '',node);
  if (action === 'flip') { ui.revealed = true; return render(); }
  if (action === 'plan') { store.togglePlan(route.id); return render(); }
  if (action === 'add-word') return addWordSheet();
  if (action === 'goal') return goalSheet();
  if (action === 'record') return startRecording();
  if (action === 'stop-record') return stopRecording();
  if (action === 'play-record') {
    if (ui.recordUrl) await new Audio(ui.recordUrl).play();
    return;
  }
  if (action === 'select-answer') {
    const {q} = activeQuestion();
    if (q) ui.selected[q.id] = node.dataset.value || '';
    return render();
  }
  if (action === 'add-piece' || action === 'remove-piece') {
    const {q} = activeQuestion();
    if (!q) return;
    const parts = String(ui.selected[q.id] || '').trim().split(/\s+/).filter(Boolean);
    if (action === 'add-piece') parts.push(node.dataset.value || '');
    else parts.splice(Number(node.dataset.index) || 0,1);
    ui.selected[q.id] = parts.join(' ');
    return render();
  }
  if (action === 'hint') {
    const {q} = activeQuestion();
    if (q) ui.help[q.id] = true;
    return render();
  }
  if (action === 'reveal') {
    const {q} = activeQuestion();
    if (!q) return;
    ui.help[q.id] = true;
    ui.selected[q.id] = q.answer;
    ui.feedback[q.id] = true;
    store.setAttempt(route,q.id,{answer:q.answer,checked:true,firstCorrect:false,help:true,correct:true,at:new Date().toISOString()});
    return render();
  }
  if (action === 'check-answer') {
    const {q} = activeQuestion();
    if (!q) return;
    const selected = ui.selected[q.id] ?? '';
    if (!String(selected).trim()) return;
    const old = store.attempts(route)[q.id];
    const correct = normalise(selected) === normalise(q.answer);
    const firstCorrect = old ? old.firstCorrect : correct;
    const help = Boolean(ui.help[q.id] || old?.help);
    store.setAttempt(route,q.id,{answer:selected,checked:true,firstCorrect,help,correct,at:new Date().toISOString()});
    ui.feedback[q.id] = true;
    return render();
  }
  if (action === 'next-question') {
    const {p,index} = activeQuestion();
    const next = index + 1;
    if (next >= p.questions.length) return setRoute({view:'result',item:'',at:0});
    return setRoute({item:p.questions[next].id,at:next});
  }
  if (action === 'reset-practice') {
    store.clearAttempts(route);
    return setRoute({view:'practice',item:'',at:0,state:''});
  }
  if (action === 'review-grade') {
    store.setReview(route.id,node.dataset.rating || 'again');
    const index = model.data.vocab.findIndex(v => v.id === route.id);
    const next = model.data.vocab[index+1];
    if (next) return setRoute({view:'card',m:'review',id:next.id,item:'',at:0});
    return setRoute({view:'result',m:'review',id:'',item:'',at:0});
  }
  if (action === 'leave') {
    if (confirm(`${t('leave')}\n${t('keep')}`)) return setRoute({view:'detail',item:'',at:0});
  }
}

document.addEventListener('click', async event => {
  const actionNode = event.target.closest('[data-action]');
  if (actionNode) {
    event.preventDefault();
    await handleAction(actionNode.dataset.action,actionNode);
    return;
  }
  const link = event.target.closest('a[data-go]');
  if (link) {
    const url = new URL(link.href,location.href);
    if (url.origin === location.origin && url.pathname.endsWith('/screen.html')) {
      event.preventDefault();
      history.pushState({},'',url.pathname+url.search);
      route = parseRoute(location.search);
      ui = freshUi();
      store.remember(route);
      render();
    }
  }
});

document.addEventListener('submit', event => {
  const filter = event.target.closest('[data-filter]');
  if (filter) {
    event.preventDefault();
    const form = new FormData(filter);
    setRoute({q:String(form.get('q')||''),level:String(form.get('level')||'all'),topic:String(form.get('topic')||''),page:0});
    return;
  }
  const add = event.target.closest('[data-add-word]');
  if (add) {
    event.preventDefault();
    const form = new FormData(add);
    const ko = String(form.get('ko')||'').trim();
    const value = String(form.get('meaning')||'').trim();
    if (!ko || !value) {
      add.querySelector('[data-form-error]').textContent = translator(route.lang)('required');
      return;
    }
    const id = store.addCustom(ko,value,route.lang);
    closeSheet();
    setRoute({view:'card',m:'review',id,item:'',mode:'',at:0});
    return;
  }
  const goal = event.target.closest('[data-goal-form]');
  if (goal) {
    event.preventDefault();
    const value = Math.max(1,Math.min(50,Number(new FormData(goal).get('goal'))||5));
    store.setGoal('listening',value);
    closeSheet();
    render();
  }
});

window.addEventListener('popstate', () => {
  route = parseRoute(location.search);
  ui = freshUi();
  render();
});

sheet.addEventListener('click', event => {
  if (event.target === sheet) closeSheet();
});

async function boot() {
  try {
    const response = await fetch('./content.json',{cache:'no-store'});
    if (!response.ok) throw new Error(`content ${response.status}`);
    data = await response.json();
    model = indexData(data);
    store = new PreviewStore(data.boundary?.storageNamespace);
    route = parseRoute(location.search);
    store.remember(route);
    window.__C_FREE_LEARNING_AUDIT__ = {
      navigate(url) {
        try {
          const target = new URL(url,location.href);
          route = parseRoute(target.search);
          ui = freshUi();
          render();
          const text = app.textContent || '';
          const missingView = Boolean(app.querySelector('[data-missing-view]'));
          return {
            ok: !text.includes('Content could not be loaded.') && !missingView,
            textLength: text.trim().length,
            missing: missingView,
            route: {...route},
          };
        } catch (error) {
          return {ok:false,error:String(error),stack:error?.stack || ''};
        }
      },
      snapshot() {
        return {route:{...route},text:(app.textContent||'').trim().slice(0,500)};
      },
    };
    render();
    window.__C_FREE_LEARNING_READY__ = true;
  } catch (error) {
    console.error(error);
    window.__C_FREE_LEARNING_BOOT_ERROR__ = {message:String(error),stack:error?.stack || ''};
    app.innerHTML = `<section class="paper boot" role="alert"><h1>Hangul Sori</h1><p>Content could not be loaded.</p><p class="source-id">${e(String(error))}</p></section>`;
  }
}

boot();
