'use strict';
// UI-only prototype. Canonical data and IDs are read; real storage/XP are never called.
const params = new URLSearchParams(location.search);
let lang = params.get('lang') === 'en' ? 'en' : 'de';
let view = params.get('screen') || 'path';
let stateVariant = params.get('state') || 'default';
let level = 'a1';
let data;
let unit;
let mode = params.get('mode') || 'scenario';
let questIndex = 0;
let chosen = null;
let words = [];
let verdict = null;
let assisted = false;
let audioError = false;
let vocabIndex = 0;
let packIndex = 0;
let meaningVisible = false;
let records = [];
let saveFailed = false;
const demoKey = 'hangulsori.c-course-mockup.20261005.airport.session.v1';
const app = document.getElementById('app');
const sheet = document.getElementById('sheet');
document.documentElement.lang = lang;
document.documentElement.dataset.scale = params.get('scale') === '2' ? '2' : '1';
document.documentElement.style.setProperty('--text-scale', params.get('scale') === '2' ? '2' : '1');

const strings = {
  de: {
    back:'Zurück', close:'Schließen', path:'Dein Kurs', subtitle:'Schritt für Schritt ins echte Leben.',
    next:'Dein nächster Schritt', unit:'Einheit', units:'Einheiten', openMission:'Mission öffnen', current:'Hier geht es weiter',
    preview:'Vorschau', locked:'Noch nicht freigeschaltet', progress:'Noch keine Einheit abgeschlossen', all:'Alle Einheiten ansehen',
    mission:'Deine Mission', goal:'Das lernst du', listen:'Wörter und Klänge', listenSub:'Wortpakete zum Hören und Kennenlernen',
    scene:'In einer Alltagsszene', sceneSub:'Zuhören, antworten und Sätze bilden', vocabulary:'Wörter kennenlernen',
    startWords:'Wörter lernen', sceneStart:'Alltagsszene ausprobieren', expressions:'Deine ersten Ausdrücke',
    savedPlace:'Du kannst jederzeit hier weiterlernen.', courseNote:'Wörter, Übung und Alltagsszene gehören zu derselben Einheit.',
    prerequisite:'Zuerst diese Einheit abschließen:', overviewOnly:'Du siehst dir gerade eine spätere Einheit an.',
    practice:'Alltagsszene', task:'Aufgabe', translate:'Wie sagst du das auf Koreanisch?', arrange:'Baue den passenden Satz.',
    hearing:'Was hörst du?', meaning:'Wähle die passende Bedeutung.', check:'Antwort prüfen', nextTask:'Nächste Aufgabe',
    showResult:'Ergebnis ansehen', correct:'Das passt!', incorrect:'Noch nicht ganz.', rightAnswer:'Die passende Antwort lautet:',
    firstAttempt:'Allein richtig', help:'Hilfe', helpAction:'Einen Hinweis ansehen', hintUsed:'Hinweis verwendet',
    hintCopy:'Du findest die Antwort in den Ausdrücken der Szene. Mit Hinweis bleibt diese Antwort eine Übung.',
    continue:'Weiter', later:'Später weiterlernen', resume:'Übung fortsetzen', audio:'Satz anhören',
    audioUnavailable:'Der Ton ist gerade nicht verfügbar.', transcript:'Text anzeigen und weiterüben', transcriptMark:'Mit Textunterstützung',
    well:'Tippe die Wörter in der passenden Reihenfolge an.', removeWord:'Wort entfernen',
    result:'Ein guter Anfang.', resultSub:'Du hast die Alltagsszene geübt.', recap:'Diese Ausdrücke nimmst du mit',
    helpMetric:'Mit Hilfe', saved:'Übungsstand gespeichert', saving:'Dein Übungsstand wird gespeichert …',
    saveError:'Speichern hat nicht geklappt. Deine Antworten sind noch hier.', retry:'Erneut versuchen',
    missionReturn:'Zur Mission zurück', reviewAnswers:'Antworten durchsehen', resultNote:'Hier kannst du deine Ausdrücke wiederholen und die Einheit weiterlernen.',
    empty:'Dein Kurs wartet auf dich.', emptySub:'Beginne mit einer kurzen Mission und deinen ersten koreanischen Ausdrücken.',
    error:'Der Kurs konnte nicht geladen werden.', errorSub:'Versuche es noch einmal. Dein Lernstand bleibt erhalten.',
    loading:'Dein Kurs wird geladen …', ready:'Du hast die Wörter kennengelernt.', vocabSub:'Als Nächstes kannst du sie in einer Alltagsszene verwenden.',
    showMeaning:'Bedeutung ansehen', nextWord:'Nächstes Wort', nextPack:'Nächstes Wortpaket', example:'Beispiel', known:'Ausdrücke angesehen',
    pause:'Für später merken?', pauseText:'Dein Platz in dieser Übung bleibt erhalten.', stay:'Weiterüben',
    routeHint:'Zur Kursübersicht', sampleResult:'Beispielergebnis', goalIntro:'Am Ende dieser Einheit:',
    phase:'Deine Lernphase', phaseOpen:'Lernphase ansehen', phaseTasks:'Aufgaben in dieser Lernphase', smalltalk:'Im Gespräch üben',
  },
  en: {
    back:'Back', close:'Close', path:'Your course', subtitle:'One step closer to everyday Korean.',
    next:'Your next step', unit:'Unit', units:'units', openMission:'Open mission', current:'Continue here',
    preview:'Preview', locked:'Not unlocked yet', progress:'No units completed yet', all:'Browse all units',
    mission:'Your mission', goal:'What you will learn', listen:'Words and sounds', listenSub:'Word packs to listen to and explore',
    scene:'In an everyday scene', sceneSub:'Listen, respond and build sentences', vocabulary:'Explore the words',
    startWords:'Learn the words', sceneStart:'Try the everyday scene', expressions:'Your first expressions',
    savedPlace:'You can come back and continue here.', courseNote:'Words, practice and the scene belong to the same unit.',
    prerequisite:'Complete this unit first:', overviewOnly:'You are previewing a later unit.',
    practice:'Everyday scene', task:'Task', translate:'How do you say this in Korean?', arrange:'Build the matching sentence.',
    hearing:'What do you hear?', meaning:'Choose the matching meaning.', check:'Check answer', nextTask:'Next task',
    showResult:'See results', correct:'That fits!', incorrect:'Not quite yet.', rightAnswer:'The matching answer is:',
    firstAttempt:'Unaided correct', help:'Help', helpAction:'See a hint', hintUsed:'Hint used',
    hintCopy:'The scene expressions contain the answer. An answer with a hint remains practice.',
    continue:'Continue', later:'Continue later', resume:'Resume practice', audio:'Listen to the sentence',
    audioUnavailable:'Audio is unavailable right now.', transcript:'Show the text and keep practising', transcriptMark:'With text support',
    well:'Tap the words in the matching order.', removeWord:'Remove word',
    result:'A good beginning.', resultSub:'You practised the everyday scene.', recap:'Expressions to take with you',
    helpMetric:'With help', saved:'Practice position saved', saving:'Saving your practice position …',
    saveError:'Saving failed. Your answers are still here.', retry:'Try again',
    missionReturn:'Back to the mission', reviewAnswers:'Review answers', resultNote:'Review the expressions here and keep working through your unit.',
    empty:'Your course is waiting.', emptySub:'Begin with a short mission and your first Korean expressions.',
    error:'The course could not be loaded.', errorSub:'Try again. Your learning progress is kept.',
    loading:'Loading your course …', ready:'You explored the words.', vocabSub:'Next, use them in an everyday scene.',
    showMeaning:'Show meaning', nextWord:'Next word', nextPack:'Next word pack', example:'Example', known:'Expressions explored',
    pause:'Keep your place for later?', pauseText:'You can return to this point in the practice.', stay:'Keep practising',
    routeHint:'Course overview', sampleResult:'Example result', goalIntro:'At the end of this unit:',
    phase:'Your learning phase', phaseOpen:'View learning phase', phaseTasks:'Tasks in this learning phase', smalltalk:'Practise conversation',
  },
};
const t = key => strings[lang][key] || key;
const text = item => typeof item === 'string' ? item : (item?.[lang] || item?.de || '');
const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const icons = {
  arrow:'<path d="m9 5 7 7-7 7"/>', back:'<path d="m15 5-7 7 7 7"/>', close:'<path d="m6 6 12 12M18 6 6 18"/>',
  check:'<path d="m5 12 4 4L19 6"/>', lock:'<rect x="5" y="10" width="14" height="11" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3"/>',
  sound:'<path d="M11 4 6 8H3v8h3l5 4V4ZM15 8a6 6 0 0 1 0 8M18 5a10 10 0 0 1 0 14"/>',
  book:'<path d="M12 6v14M3 4c4 0 6 1 9 2 3-1 5-2 9-2v15c-4 0-6 0-9 1-3-1-5-1-9-1V4Z"/>',
  help:'<circle cx="12" cy="12" r="9"/><path d="M9 9a3 3 0 1 1 4 3c-1 .5-1 1-1 2M12 17h.01"/>',
  retry:'<path d="M4 10a8 8 0 1 1 1 9M4 4v6h6"/>', clock:'<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
};
const icon = name => `<svg aria-hidden="true" viewBox="0 0 24 24">${icons[name] || icons.arrow}</svg>`;
const art = (name, cls='', alt='') => `<img class="${cls}" src="../../../${data.assets[name]}" alt="${esc(alt)}">`;
const button = (label, action, material='brass', disabled=false) => `<button class="button ${material}" data-action="${action}" ${disabled?'disabled':''}><span>${esc(label)}</span>${icon(material==='secondary'?'arrow':'arrow')}</button>`;

function chromeHTML(backAction='back') {
  return `<div class="topbar"><button class="icon-button" aria-label="${t('back')}" data-action="${backAction}">${icon('back')}</button><div class="brand">${art('cloud')}<span>HANGUL SORI</span></div><span class="top-label">${esc(view==='path'?level.toUpperCase():unit.level.toUpperCase())}</span></div>`;
}

function header(title, sub='', backAction='back') {
  return `<header>${chromeHTML(backAction)}<div class="page-heading"><div><h1 tabindex="-1">${esc(title)}</h1>${sub?`<p>${esc(sub)}</p>`:''}</div>${view==='path'?`<label class="level-picker" data-level="${level.toUpperCase()}"><span class="sr-only">${lang==='de'?'Kursstufe ansehen':'Browse course level'}</span><select id="level" class="level-select" aria-label="${lang==='de'?'Kursstufe ansehen':'Browse course level'}">${['a1','a2','b1','b2','c1','c2'].map(l=>`<option value="${l}" ${l===level?'selected':''}>${l.toUpperCase()}</option>`).join('')}</select></label>`:''}</div></header>`;
}

function footer(content) { return `<footer class="footer paper">${content}<div class="home-indicator" aria-hidden="true"></div></footer>`; }

function pathHTML() {
  const selected = data.units.filter(item=>item.level===level);
  const current = data.units[0];
  const rows = selected.map((item,index)=>{
    const isCurrent=item.id===current.id;
    return `<li><span class="path-node ${isCurrent?'current':''}">${index+1}</span><button class="path-link ${isCurrent?'current':''}" data-unit="${item.id}"><span class="copy"><strong>${esc(text(item.title))}</strong><span class="status">${t(isCurrent?'current':'preview')}</span></span>${icon(isCurrent?'arrow':'lock')}</button></li>`;
  }).join('');
  return `${header(t('path'),t('subtitle'))}<main class="scroll"><section class="panel paper inset"><p class="eyebrow">${t('next')} · A1 / 01</p><h2 class="hero-title">${esc(text(current.title))}</h2><p class="goal">${esc(text(current.canDo))}</p>${art('book','hero-book')}${button(savedDemo()?.view==='learn'?t('resume'):t('openMission'),savedDemo()?.view==='learn'?'resume':'mission')}<p class="caption">${t('savedPlace')}</p></section><section class="panel paper path-panel"><div class="section-head"><h2>${level.toUpperCase()} · ${lang==='de'?'Dein Weg':'Your path'}</h2><span>${selected.length} ${t('units')}</span></div><ol class="path-list">${rows}</ol></section><p class="course-count">A1–C2 · 48 ${t('units')}<br>${t('progress')}</p></main>`;
}

function missionHTML() {
  const sample=unit.id===data.sampleUnitId;
  const packs=unit.packIds;
  const scenarioIds=unit.explicitLinks.filter(link=>link.contentKind==='scenario').map(link=>link.contentId);
  const expressions=data.sampleVocab.slice(0,3);
  const phases=data.learningPhases.phases.filter(phase=>phase.practiceUnitIds.includes(unit.id));
  const conversationIds=unit.explicitLinks.filter(link=>link.contentKind==='smalltalk');
  const sceneContents=`<span class="step-index">${unit.grammarIds.length?3:2}</span><div><strong>${t('scene')}</strong><small>${sample?esc(text(data.sampleScenario.title)):`${scenarioIds.length} ${lang==='de'?'verknüpfte Situationen':'linked scenes'}`}</small></div>${icon('arrow')}`;
  const previewNote=!sample?`<p class="preview-note">${t('overviewOnly')} ${unit.prerequisiteUnitIds?.length?`${t('prerequisite')} <strong>${esc(text(data.units.find(item=>item.id===unit.prerequisiteUnitIds[0])?.title))}</strong>`:''}</p>`:'';
  const phaseCard=phases.length?`<section class="panel jade phase-context"><p class="eyebrow">${t('phase')}</p><h2>${esc(text(phases[0].title))}</h2><button class="quiet-link" data-action="phase"><span>${t('phaseOpen')}</span>${icon('arrow')}</button></section>`:'';
  return `<header>${chromeHTML()}</header>
    <main class="scroll detail-scroll"><section class="panel paper inset">
      <p class="eyebrow">${t('mission')} · ${t('unit')} ${String(unit.order).padStart(2,'0')}</p>
      ${art('book','mission-book')}
      <h1 class="details-title" tabindex="-1">${esc(text(unit.title))}</h1>
      <p class="mission-goal">${esc(text(unit.canDo))}</p>
      <ol class="step-list">
        <li class="step"><span class="step-index active">1</span><div><strong>${t('listen')}</strong><small>${packs.length} ${lang==='de'?'Wortpakete':'word packs'} · ${unit.vocabIds.length} ${lang==='de'?'Wörter':'words'}</small></div>${icon('sound')}</li>
        ${unit.grammarIds.length?`<li class="step"><span class="step-index">2</span><div><strong>${lang==='de'?'Ausdrücke verstehen':'Understand expressions'}</strong><small>${unit.grammarIds.length} ${lang==='de'?'Grammatikthemen':'grammar topics'}</small></div>${icon('book')}</li>`:''}
        ${sample?`<li><button class="step step-entry" data-action="start-scene" aria-label="${t('sceneStart')}">${sceneContents}</button></li>`:`<li class="step">${sceneContents}</li>`}
        ${conversationIds.length?`<li class="step"><span class="step-index">${unit.grammarIds.length?4:3}</span><div><strong>${t('smalltalk')}</strong><small>${conversationIds.length} Small Talk</small></div>${icon('arrow')}</li>`:''}
      </ol>
      ${sample?`<div style="border-top:1px solid var(--line);padding-top:18px;margin-top:10px"><h3 style="font-size:.9375rem;margin-bottom:11px">${t('expressions')}</h3>${expressions.map(item=>`<p class="expression" style="display:flex;gap:10px;justify-content:space-between;margin:8px 0;font-size:.8125rem"><strong class="korean" lang="ko" style="font-weight:600">${esc(item.korean)}</strong><span class="muted">${esc(item[lang==='de'?'german':'english'])}</span></p>`).join('')}</div>`:''}
      ${previewNote}</section>${phaseCard}<p class="section-caption">${t('courseNote')}</p>
    </main>${footer(button(t('startWords'),'start-vocab','brass',!sample))}`;
}

function progressHTML(label,index,total) {
  return `<div class="progress-header"><div class="progress-copy"><span>${esc(label)}</span><span>${index} / ${total}</span></div><div class="progress-track" role="progressbar" aria-label="${t('task')}" aria-valuenow="${index}" aria-valuemin="0" aria-valuemax="${total}"><span style="width:${index/total*100}%"></span></div></div>`;
}

function vocabHTML() {
  const item=vocabItems()[vocabIndex];
  return `${header(t('vocabulary'),`${unit.level.toUpperCase()} · ${t('unit')} 01`)}${progressHTML(t('expressions')+' · '+(packIndex+1),vocabIndex+1,vocabItems().length)}<main class="scroll"><section class="panel paper inset task-panel"><p class="eyebrow">${t('listen')}</p>${art('book','hero-book')}<h2 class="korean" style="font-size:2.2rem;text-align:center;line-height:1.4;margin:18px 0">${esc(item.korean)}</h2><p class="muted" style="text-align:center;font-size:.9375rem">${esc(item.romanization)}</p>${meaningVisible?`<div style="margin:24px 0 10px;text-align:center"><p style="font-weight:600;font-size:1.25rem">${esc(item[lang==='de'?'german':'english'])}</p><p class="eyebrow" style="margin-top:24px">${t('example')}</p><p class="korean" style="margin-top:10px">${esc(item.example_korean)}</p><p class="muted small" style="margin-top:8px">${esc(item[lang==='de'?'example_german':'example_english'])}</p></div>`:''}<div class="task-actions"><button class="text-action" data-action="audio">${icon('sound')}${t('audio')}</button>${audioError?`<p class="audio-error" role="status">${t('audioUnavailable')}</p>`:''}</div></section></main>${footer(button(t(meaningVisible?'nextWord':'showMeaning'),meaningVisible?'next-vocab':'meaning'))}`;
}

function questHTML() {
  const quest=data.sampleScenario.quests[questIndex];
  const q=quest.data;
  const type=quest.type;
  const heading=t(type==='uebersetzen'?'translate':type==='satzBauen'?'arrange':'hearing');
  let taskContent='';
  if(type==='hoerverstehen') {
    taskContent=`<p class="task-prompt">${t('meaning')}</p><button class="audio-button" data-action="audio">${icon('sound')}<span class="sr-only">${t('audio')}</span><span class="audio-lines" aria-hidden="true">${[12,22,17,31,24,14,28,32,15,26,18,30,12,24,17,28,14,23].map(n=>`<i style="--bar:${n}px"></i>`).join('')}</span></button>${audioError?`<p class="audio-error" role="status">${t('audioUnavailable')}</p>`:''}${assisted?`<p class="task-prompt korean" lang="ko">${esc(q.audioKo)}</p><p class="task-hint">${t('transcriptMark')}</p>`:`<button class="text-action" data-action="transcript">${t('transcript')}</button>`}`;
  } else {
    taskContent=`<p class="task-prompt">${esc(q[lang==='de'?'promptDe':'promptEn'])}</p>`;
  }
  if(type==='satzBauen') {
    const pieces=q.targetKo.split(' ');
    const sequence=[...pieces].reverse();
    taskContent+=`<div class="word-well" data-placeholder="${esc(t('well'))}" aria-label="${t('arrange')}">${words.map((word,index)=>`<button class="word-tile" data-remove="${index}" aria-label="${esc(t('removeWord')+': '+word)}" ${verdict?'disabled':''}>${esc(word)}</button>`).join('')}</div><div class="word-bank">${sequence.map(word=>`<button class="word-tile" data-word="${esc(word)}" ${words.filter(w=>w===word).length>=pieces.filter(w=>w===word).length||verdict?'disabled':''}>${esc(word)}</button>`).join('')}</div>`;
  } else {
    taskContent+=`<div class="answer-options">${q.options.map((option,index)=>{
      const selected=chosen===index;
      const clazz=verdict&&(selected||index===q.correctIndex)?(index===q.correctIndex?'right':'wrong'):(selected?'selected':'');
      const value=type==='uebersetzen'?option.ko:text(option);
      return `<button class="answer ${clazz}" data-option="${index}" aria-pressed="${selected}" ${verdict?'disabled':''}><span class="letter">${String.fromCharCode(65+index)}</span><span class="answer-text ${type==='uebersetzen'?'korean':''}" ${type==='uebersetzen'?'lang="ko"':''}>${esc(value)}</span>${verdict&&(selected||index===q.correctIndex)?`<span class="state-icon">${icon(index===q.correctIndex?'check':'close')}</span>`:''}</button>`;
    }).join('')}</div>`;
  }
  const correctAnswer=type==='satzBauen'?q.targetKo:(type==='uebersetzen'?q.options[q.correctIndex].ko:text(q.options[q.correctIndex]));
  const canCheck=type==='satzBauen'?words.length>0:chosen!==null;
  const doneLabel=records.length>=data.sampleScenario.quests.length?t('showResult'):t('nextTask');
  return `<div class="topbar"><button class="icon-button" aria-label="${t('back')}" data-action="pause">${icon('back')}</button><div class="brand">${art('cloud')}<span>HANGUL SORI</span></div><button class="icon-button" aria-label="${t('close')}" data-action="pause">${icon('close')}</button></div>${progressHTML(t('practice'),questIndex+1,data.sampleScenario.quests.length)}<main class="scroll"><section class="panel paper inset task-panel"><p class="eyebrow">${unit.level.toUpperCase()} · ${t('unit')} 01</p><h1 class="task-heading" tabindex="-1">${heading}</h1><div class="context-strip">${art('airport')}<div><strong>${esc(text(data.sampleScenario.title))}</strong><p>${esc(text(data.sampleScenario.intro))}</p></div></div>${taskContent}<div class="task-actions">${assisted&&type!=='hoerverstehen'?`<p class="helper">${t('hintUsed')} · <span class="korean" lang="ko">${esc(correctAnswer)}</span></p>`:''}${!verdict&&type!=='hoerverstehen'?`<button class="text-action" data-action="hint">${icon('help')}${t('helpAction')}</button>`:''}</div>${verdict?`<div class="feedback ${verdict==='wrong'?'wrong':''}" role="status"><h2>${icon(verdict==='right'?'check':'help')}${t(verdict==='right'?'correct':'incorrect')}</h2><p>${verdict==='wrong'?`${t('rightAnswer')} <strong class="korean">${esc(correctAnswer)}</strong>`:esc(type==='uebersetzen'?q[lang==='de'?'promptDe':'promptEn']:correctAnswer)}</p>${assisted?`<p>${t('hintUsed')} · ${t('hintCopy')}</p>`:''}</div>`:''}</section></main>${footer(button(verdict?doneLabel:t('check'),verdict?'next-task':'check','brass',!verdict&&!canCheck))}`;
}

function resultHTML() {
  const compact=document.documentElement.dataset.scale==='2';
  const seeded=records.length===0;
  const right=seeded?2:records.filter(record=>record.correct&&!record.assisted).length;
  const helped=seeded?1:records.filter(record=>record.assisted).length;
  const sample=data.sampleScenario;
  const recap=sample.vocab.filter((_,index)=>[1,3,5].includes(index));
  const saveState=saveFailed||stateVariant==='save-error'?'error':stateVariant==='saving'?'saving':'saved';
  return `<header>${chromeHTML()}</header><main class="scroll detail-scroll"><section class="panel paper inset">
    <div class="result-head">${art('seal','result-seal')}<div><p class="eyebrow">${t('practice')} · ${unit.level.toUpperCase()} / 01</p><h1 tabindex="-1">${t('result')}</h1></div></div>
    <div class="result-metrics"><div class="metric"><strong>${right} / 3</strong><span>${t('firstAttempt')}</span></div><div class="metric"><strong>${helped}</strong><span>${t('helpMetric')}</span></div></div>
    <h2 class="result-summary">${t('recap')}</h2>
    ${recap.map(item=>`<div class="recap">${icon('check')}<div><strong class="korean" lang="ko">${esc(item.korean)}</strong><p>${esc(text(item.note))}</p></div></div>`).join('')}
    <p class="save-status ${saveState==='error'?'error':''}" role="status">${icon(saveState==='error'?'retry':saveState==='saving'?'clock':'check')}<span>${t(saveState==='error'?'saveError':saveState==='saving'?'saving':'saved')}</span></p>
    ${saveState==='error'?`<button class="text-action" data-action="retry-save">${icon('retry')}${t('retry')}</button>`:''}
    ${compact?`<div class="result-scroll-actions">${button(t('reviewAnswers'),'review','secondary')}</div>`:''}
    </section></main>${footer(`${button(t('missionReturn'),'mission','brass',saveState==='saving')}${compact?'':button(t('reviewAnswers'),'review','secondary')}`)}`;
}

function emptyHTML(kind) {
  const isError=kind==='error';
  return `${header(t('path'))}<main class="scroll"><section class="panel paper empty-panel">${art('book')}<h2>${t(isError?'error':'empty')}</h2><p>${t(isError?'errorSub':'emptySub')}</p>${button(t(isError?'retry':'openMission'),'reset-state')}</section></main>`;
}

function render(focus=false) {
  app.setAttribute('aria-busy',String(stateVariant==='loading'));
  if(stateVariant==='error'||stateVariant==='empty') { app.innerHTML=emptyHTML(stateVariant); }
  else if(stateVariant==='loading') {
    app.innerHTML=`${header(t('path'))}<main class="scroll"><section class="panel paper inset" role="status"><p>${t('loading')}</p><div class="skeleton wide"></div><div class="skeleton"></div><div class="skeleton short"></div></section></main>`;
  } else {
    app.innerHTML=view==='path'?pathHTML():view==='mission'?missionHTML():view==='learn'?(mode==='vocab'?vocabHTML():questHTML()):resultHTML();
  }
  if(focus) { app.querySelector('h1')?.focus({preventScroll:true}); }
}

function navigate(destination) {
  view=destination;stateVariant='default';verdict=null;chosen=null;words=[];audioError=false;assisted=false;
  history.replaceState(null,'',`${location.pathname}?screen=${view}&lang=${lang}&scale=${params.get('scale')==='2'?'2':'1'}&unit=${unit.id}&mode=${mode}`);
  render(true);
}

function savedDemo() {
  try { return JSON.parse(sessionStorage.getItem(demoKey)||'null'); } catch { return null; }
}

function vocabItems() {
  return data.sampleVocab.filter(item=>item.pack_id===data.units[0].packIds[packIndex]);
}

function restoreDemo(saved) {
  mode=saved.mode;questIndex=saved.questIndex;vocabIndex=saved.vocabIndex;packIndex=saved.packIndex||0;
  records=saved.records;chosen=saved.chosen;words=saved.words;assisted=saved.assisted;
  verdict=saved.verdict;meaningVisible=saved.meaningVisible;view=saved.view==='result'?'result':'learn';
}

function saveDemo() {
  try { sessionStorage.setItem(demoKey,JSON.stringify({view,mode,questIndex,vocabIndex,packIndex,records,chosen,words,assisted,verdict,meaningVisible,unitId:unit.id}));saveFailed=false; }
  catch { saveFailed=true; }
}

function openSheet(title,content,actionButton='') {
  sheet.innerHTML=`<div class="sheet-header"><h2 id="sheet-title">${esc(title)}</h2><button class="icon-button" data-action="close-sheet" aria-label="${t('close')}">${icon('close')}</button></div>${content}${actionButton}`;
  sheet.showModal();
}

function startScene() { mode='scenario';questIndex=0;records=[];navigate('learn');saveDemo(); }

function perform(action) {
  switch(action) {
    case 'back': if(view==='path') {openSheet(t('routeHint'),`<p>${lang==='de'?'Dein Kurs ist Teil von Lernen. Die anderen Lernangebote bleiben dort erreichbar.':'Your course is part of Learn. The other learning activities remain available there.'}</p>`,`<a class="button jade" target="_top" href="http://127.0.0.1:8253/c-live.html">${lang==='de'?'Lernen im C-Entwurf öffnen':'Open Learn in the C preview'}${icon('arrow')}</a>`);} else {navigate(view==='mission'?'path':'mission');} break;
    case 'mission': unit=data.units[0];navigate('mission');break;
    case 'start-vocab': mode='vocab';vocabIndex=0;packIndex=0;meaningVisible=false;navigate('learn');saveDemo();break;
    case 'start-scene': startScene();break;
    case 'meaning': meaningVisible=true;saveDemo();render();break;
    case 'next-vocab':
      if(vocabIndex+1<vocabItems().length) {vocabIndex++;meaningVisible=false;audioError=false;saveDemo();render();}
      else {openSheet(t('ready'),`<p>${t('vocabSub')}</p>`,`${packIndex+1<data.units[0].packIds.length?button(t('nextPack'),'next-pack'):''}${button(t('sceneStart'),'start-scene',packIndex+1<data.units[0].packIds.length?'secondary':'brass')}`);}
      break;
    case 'next-pack': packIndex++;vocabIndex=0;meaningVisible=false;audioError=false;sheet.close();saveDemo();render();break;
    case 'audio': audioError=true;render();break;
    case 'transcript': assisted=true;saveDemo();render();break;
    case 'hint': assisted=true;saveDemo();render();break;
    case 'check': {
      const quest=data.sampleScenario.quests[questIndex];
      // No substitute audio: text-backed listening stays supported practice.
      if(quest.type==='hoerverstehen') {assisted=true;}
      const correct=quest.type==='satzBauen'?words.join(' ')===quest.data.targetKo:chosen===quest.data.correctIndex;
      verdict=correct?'right':'wrong';
      if(!records.some(record=>record.questId===quest.id)) { records.push({questId:quest.id,correct,assisted,firstAttempt:true}); }
      saveDemo();render();app.querySelector('[data-action="next-task"]')?.focus({preventScroll:true});break;
    }
    case 'next-task':
      if(records.length>=data.sampleScenario.quests.length) {navigate('result');saveDemo();}
      else {questIndex++;chosen=null;words=[];verdict=null;assisted=false;audioError=false;saveDemo();render(true);}
      break;
    case 'review': openSheet(t('reviewAnswers'),`<p>${t('resultNote')}</p><ul class="sheet-list">${data.sampleScenario.dialog.map(item=>`<li><strong class="korean" lang="ko">${esc(item.ko)}</strong><br>${esc(item[lang])}</li>`).join('')}</ul>`);break;
    case 'phase': {
      const phases=data.learningPhases.phases.filter(phase=>phase.practiceUnitIds.includes(unit.id));
      openSheet(t('phase'),phases.map(phase=>`<section class="phase-sheet"><h3>${esc(text(phase.title))}</h3><p>${esc(text(phase.goal))}</p><p class="eyebrow">${phase.levelPhase} · ${phase.taskIds.length} ${t('phaseTasks')}</p><ol class="sheet-list">${phase.taskIds.map(id=>data.phaseTaskIndex.find(task=>task.id===id)).map(task=>`<li data-task-id="${esc(task.id)}">${esc(text(task.title))}</li>`).join('')}</ol></section>`).join(''));
      break;
    }
    case 'pause': saveDemo();openSheet(t('pause'),`<p>${t('pauseText')}</p>`,`${button(t('later'),'pause-leave')}${button(t('stay'),'close-sheet','secondary')}`);break;
    case 'pause-leave': sheet.close();navigate('path');break;
    case 'resume': {
      const saved=savedDemo();
      if(saved?.view==='learn') {restoreDemo(saved);history.replaceState(null,'',`${location.pathname}?screen=learn&lang=${lang}&scale=${params.get('scale')==='2'?'2':'1'}&unit=${unit.id}&mode=${mode}`);render(true);}
      else {navigate('mission');}
      break;
    }
    case 'close-sheet': sheet.close();break;
    case 'retry-save': stateVariant='default';saveDemo();render();break;
    case 'reset-state': stateVariant='default';render(true);break;
  }
  if(action==='start-scene'||action==='start-vocab') { if(sheet.open) {sheet.close();} }
}

document.addEventListener('click',event=>{
  const target=event.target.closest('button');
  if(!target||target.disabled) {return;}
  if(target.dataset.action) {perform(target.dataset.action);}
  else if(target.dataset.unit) {unit=data.units.find(item=>item.id===target.dataset.unit);navigate('mission');}
  else if(target.dataset.option!==undefined) {chosen=Number(target.dataset.option);saveDemo();render();app.querySelector(`[data-option="${chosen}"]`)?.focus({preventScroll:true});}
  else if(target.dataset.word) {words.push(target.dataset.word);saveDemo();render();(app.querySelector('.word-bank button:not(:disabled)')||app.querySelector('[data-action="check"]'))?.focus({preventScroll:true});}
  else if(target.dataset.remove!==undefined) {words.splice(Number(target.dataset.remove),1);saveDemo();render();app.querySelector('.word-bank button:not(:disabled)')?.focus({preventScroll:true});}
});
document.addEventListener('change',event=>{if(event.target.id==='level') {level=event.target.value;render();app.querySelector('#level')?.focus({preventScroll:true});}});
document.addEventListener('keydown',event=>{if(event.key==='Escape'&&!sheet.open&&parent!==window) {parent.postMessage({type:'close-course-preview'},location.origin);}});

fetch('content.json').then(response=>{
  if(!response.ok) {throw new Error('Course snapshot unavailable');}
  return response.json();
}).then(content=>{
  data=content;
  unit=data.units.find(item=>item.id===params.get('unit'))||data.units[0];
  if((view==='learn'||view==='result')&&unit.id!==data.sampleUnitId) {view='mission';}
  if(view==='learn'&&mode==='scenario') {
    // The board previews task 2. Starting from a mission begins at task 1.
    questIndex=1;
    records=[{questId:data.sampleScenario.quests[0].id,correct:true,assisted:false,exampleOnly:true}];
  }
  const resumeRecord=savedDemo();
  if(view==='learn'&&stateVariant==='default'&&params.get('fresh')!=='1'&&resumeRecord?.view==='learn'&&resumeRecord.unitId===unit.id) {restoreDemo(resumeRecord);}
  if(view==='result'&&stateVariant==='default'&&params.get('fresh')!=='1'&&resumeRecord?.view==='result'&&resumeRecord.unitId===unit.id) {restoreDemo(resumeRecord);}
  if(stateVariant==='locked') {unit=data.units[1];view='mission';}
  if(stateVariant==='saving'||stateVariant==='save-error') {view='result';}
  if(stateVariant==='correct'||stateVariant==='wrong'||stateVariant==='help') {
    view='learn';mode='scenario';questIndex=1;chosen=stateVariant==='wrong'?1:0;
    if(stateVariant==='help') {assisted=true;}
    else {verdict=stateVariant==='correct'?'right':'wrong';records=[{questId:data.sampleScenario.quests[0].id,correct:true,assisted:false,exampleOnly:true},{questId:data.sampleScenario.quests[1].id,correct:verdict==='right',assisted:false}];}
  }
  render();
}).catch(()=>{
  app.setAttribute('aria-busy','false');
  app.innerHTML=`<main class="boot paper"><h1>${t('error')}</h1><p style="margin-top:16px">${t('errorSub')}</p><button class="button brass" style="margin-top:24px" onclick="location.reload()">${t('retry')}</button></main>`;
});
