import { JourneyModel } from './journey-model.mjs';
import { PreviewStore } from './preview-store.mjs';
import { refreshCtaSurfaces } from './cta-surface.mjs';
import { rewardHero } from './reward-hero.mjs';
import { createRewardPresentation } from './reward-presentation.mjs';

const assets = '../../../assets/';
const screens = ['R01', 'W03', 'R03', 'W04', 'B01', 'B03', 'W05'];
// An already confirmed, read-only daily receipt for design review. This is not
// an extra granting action and never alters the connected milestone fixture.
const FIRST_RECEIPT = Object.freeze({ id: 'fixture:first-daily:10-plus-20', kind: 'first', before: 10, amount: 20, after: 30 });
const files = { W03: 'W03-learning-goal', W04: 'W04-build-ready', B01: 'B01-spend-confirm', B03: 'B03-saved-progress', W05: 'W05-next-goal' };
const createModel = () => new JourneyModel({ owned: 7, buildingId: 'fixture-sarangchae-v3-16' });
const goals = [
  { de: 'Erste Begrüßung und Nachfragen', en: 'First greetings and asking again', canDo: { de: 'Ich kann eine neue Person begrüßen und eine kurze Frage klären.', en: 'I can greet someone new and clarify a short question.' } },
  { de: 'Name und Herkunft nennen', en: 'Saying your name and where you are from', canDo: { de: 'Ich kann meinen Namen und meine Herkunft nennen und den Namen meines Gegenübers bestätigen.', en: 'I can say my name and where I am from, and confirm the other person’s name.' } },
];
const copy = {
  "de": {
    "gallery": "Alle sieben Ansichten",
    "eyebrow": "Interaktive Designvorschau",
    "reviewTitle": "Deine Yeopjeon. Dein nächster Schritt.",
    "reviewDescription": "Lernziel → bestätigte Belohnung → Verwendung → gespeichertes Guthaben. 30 → 70 → 30.",
    "restart": "Von vorne beginnen",
    "entry": "Yeopjeon-Übersicht",
    "reference": "Früherer Entwurf",
    "qaTitle": "Ansicht und QA",
    "textSize": "Schriftgröße",
    "motion": "Bewegung reduzieren",
    "saveLabel": "Nächster Speicherversuch",
    "saveSuccess": "Speichern",
    "saveFailure": "Speicherfehler prüfen",
    "qaNote": "100% ist die normale Ansicht. Größere Schrift ist ein separater QA-Modus.",
    "boundary": "Lokale Vorschau mit Beispieldaten. Flutter, echte Lernbewertung und Kontostand sind separat zu prüfen.",
    "steps": [
      "Erste Belohnung heute",
      "Lernziel",
      "Belohnung",
      "Verwendung",
      "Bestätigen",
      "Gespeichert",
      "Nächstes Ziel"
    ],
    "target": "Dachsparren",
    "learned": "Lernziel erfüllt",
    "learnedDetail": "40 Yeopjeon erhalten.",
    "remaining": "Zuerst das Lernziel abschließen.",
    "remainingDetail": "Das Lernziel öffnet deinen nächsten Bauschritt.",
    "goalHeading": "Dein Kursziel",
    "goalStatus": "Lernziel noch offen",
    "goalAction": "Lernziel fortsetzen",
    "buildAction": "Verwendung prüfen",
    "backWallet": "Zurück zu deinen Yeopjeon",
    "confirmAction": "40 Yeopjeon verwenden",
    "continue": "Weiterlernen",
    "cancel": "Abbrechen",
    "nextGoal": "Nächstes Lernziel",
    "courseLabel": "A1 · Lernen",
    "titles": {
      "R01": "Lektion geschafft",
      "W03": "Dein Lernziel",
      "R03": "Belohnung erhalten",
      "W04": "Bereit zum Bauen",
      "B01": "Betrag bestätigen",
      "B02": "Verwendung speichern",
      "B03": "Guthaben gespeichert",
      "W05": "Dein nächstes Lernziel",
      "B04": "Noch nicht gespeichert",
      "B05": "Speicherstatus offen"
    },
    "savedStatus": "Verwendung gespeichert",
    "cost": "Baukosten",
    "current": "Aktuelles Guthaben",
    "expected": "Danach voraussichtlich",
    "savedBalance": "Gespeichertes Guthaben",
    "used": "Verwendet",
    "confirmNote": "Die 40 Yeopjeon werden nach bestätigtem Speichern abgezogen.",
    "saving": "Wird gespeichert …",
    "savingNote": "Bis zur Bestätigung bleiben 70 Yeopjeon erhalten.",
    "failed": "Das Speichern ist fehlgeschlagen. Es wurden keine Yeopjeon abgezogen. Dein Guthaben bleibt 70.",
    "retry": "Erneut versuchen",
    "unknownNote": "Das Speichern konnte noch nicht bestätigt werden. Prüfe dieselbe Verwendung, bevor du erneut bestätigst.",
    "checkSave": "Speicherstatus prüfen",
    "learningKicker": "Kursziel · Designvorschau",
    "learningDescription": "Dieses Lernziel stammt aus dem vorhandenen A1-Kurs.",
    "learningNote": "Hier lässt sich die erfüllte Lernbedingung mit Beispieldaten prüfen. Echte Lernaufzeichnungen ändern sich dabei nicht.",
    "learningComplete": "Erfülltes Lernziel ansehen",
    "learningClose": "Zurück zum Lernziel",
    "nextLearningNote": "Dieses Kursziel ist der nächste Einstieg ins Lernen. In dieser Vorschau wird dafür keine weitere Bewertung oder Belohnung erzeugt.",
    "nextLearningClose": "Zurück",
    "walletTitle": "Deine Yeopjeon",
    "earned": "In diesem Ablauf erhalten",
    "spent": "In diesem Ablauf verwendet",
    "walletNote": "Die Übersicht zeigt die lokalen Beispieldaten dieser Vorschau.",
    "close": "Schließen",
    "storageFailed": "Lokales Speichern ist nicht verfügbar. Bitte den Browser-Speicher zulassen und erneut versuchen.",
    "restored": "Gespeicherte Beispieldaten wiederhergestellt: 30 Yeopjeon.",
    "reset": "Die Vorschau beginnt wieder mit 30 Yeopjeon.",
    "sceneReview": "Einzelansicht mit vorbereiteten Beispieldaten.",
    "ledgerHeading": "In dieser Vorschau",
    "useFor": "Verwendung",
    "eligibilityNote": "Das bestätigte Lernziel und dein Guthaben erfüllen die Bedingungen.",
    "receiptHeading": "Gespeicherter Beleg",
    "before": "Guthaben vorher",
    "earnedNow": "Erhalten",
    "creditSaved": "Belohnung und Guthaben bestätigt.",
    "viewUse": "Verwendung ansehen",
    "firstReason": "Deine erste Lerneinheit heute ist gespeichert.",
    "viewGoal": "Zum Kursziel",
    "milestoneReason": "Dein Kursziel ist bestätigt.",
    "creditConfirmed": "Guthaben bestätigt",
    "replay": "Noch einmal abspielen",
    "skip": "Zum Ergebnis",
    "playbackTitle": "Wiedergabe · Designprüfung",
    "playbackNote": "Wiederholen und Überspringen ändern nur die Darstellung.",
    "firstReviewNote": "Erste Tagesbelohnung: separates bestätigtes Beispiel 10 + 20 = 30."
  },
  "en": {
    "gallery": "All seven screens",
    "eyebrow": "Interactive design preview",
    "reviewTitle": "Your yeopjeon. Your next step.",
    "reviewDescription": "Learning goal → confirmed reward → use → saved balance. 30 → 70 → 30.",
    "restart": "Start again",
    "entry": "Yeopjeon overview",
    "reference": "Earlier design",
    "qaTitle": "View and QA",
    "textSize": "Text size",
    "motion": "Reduce motion",
    "saveLabel": "Next save attempt",
    "saveSuccess": "Save balance",
    "saveFailure": "Check a save failure",
    "qaNote": "100% is the normal view. Larger text is a separate QA mode.",
    "boundary": "Local preview with sample data. Flutter, real learning assessment and account balances need separate verification.",
    "steps": [
      "First reward today",
      "Learning goal",
      "Reward",
      "Use",
      "Confirm",
      "Saved",
      "Next goal"
    ],
    "target": "Rafters",
    "learned": "Learning goal completed",
    "learnedDetail": "40 yeopjeon received.",
    "remaining": "Complete your learning goal first.",
    "remainingDetail": "Your learning goal opens the next building step.",
    "goalHeading": "Your course goal",
    "goalStatus": "Learning goal still open",
    "goalAction": "Continue your goal",
    "buildAction": "Review use",
    "backWallet": "Back to your yeopjeon",
    "confirmAction": "Use 40 yeopjeon",
    "continue": "Keep learning",
    "cancel": "Cancel",
    "nextGoal": "Next learning goal",
    "courseLabel": "A1 · Learning",
    "titles": {
      "R01": "Lesson complete",
      "W03": "Your learning goal",
      "R03": "Reward received",
      "W04": "Ready to build",
      "B01": "Confirm use",
      "B02": "Saving use",
      "B03": "Balance saved",
      "W05": "Your next learning goal",
      "B04": "Not saved yet",
      "B05": "Save status unresolved"
    },
    "savedStatus": "Use saved",
    "cost": "Building cost",
    "current": "Current balance",
    "expected": "Expected balance after",
    "savedBalance": "Saved balance",
    "used": "Used",
    "confirmNote": "The 40 yeopjeon are deducted after saving is confirmed.",
    "saving": "Saving …",
    "savingNote": "Your balance stays at 70 until saving is confirmed.",
    "failed": "Saving failed. No yeopjeon were deducted. Your balance stays at 70.",
    "retry": "Try again",
    "unknownNote": "Saving could not be confirmed yet. Check the same use before confirming again.",
    "checkSave": "Check save status",
    "learningKicker": "Course goal · Design preview",
    "learningDescription": "This learning goal comes from the existing A1 course.",
    "learningNote": "Try a completed learning goal using sample data. Your real learning records stay as they are.",
    "learningComplete": "View completed goal",
    "learningClose": "Back to your learning goal",
    "nextLearningNote": "This course goal is your next starting point for learning. This preview does not create another assessment or reward for it.",
    "nextLearningClose": "Back",
    "walletTitle": "Your yeopjeon",
    "earned": "Received in this journey",
    "spent": "Used in this journey",
    "walletNote": "This summary shows the local sample data for this preview.",
    "close": "Close",
    "storageFailed": "Local saving is unavailable. Allow browser storage and try again.",
    "restored": "Saved sample data restored: balance 30.",
    "reset": "The preview starts again with a balance of 30.",
    "sceneReview": "Single-screen review with prepared sample data.",
    "ledgerHeading": "In this preview",
    "useFor": "Use",
    "eligibilityNote": "Your confirmed learning goal and balance meet the requirements.",
    "receiptHeading": "Saved receipt",
    "before": "Previous balance",
    "earnedNow": "Received",
    "creditSaved": "Reward and balance confirmed.",
    "viewUse": "View use",
    "firstReason": "Your first learning activity today is saved.",
    "viewGoal": "View course goal",
    "milestoneReason": "Your course goal is confirmed.",
    "creditConfirmed": "Balance confirmed",
    "replay": "Play again",
    "skip": "Show result",
    "playbackTitle": "Playback · Design review",
    "playbackNote": "Replay and skip only change the presentation.",
    "firstReviewNote": "First daily reward: a separate confirmed example, 10 + 20 = 30."
  }
};

const query = new URLSearchParams(location.search);
const candidateVideo = query.get('video') === 'candidate';
const CANDIDATE_MEDIA = Object.freeze({
  video: new URL('./qa-proof/video-candidate-20261011/candidate.mp4', import.meta.url).href,
  start: new URL('./qa-proof/video-candidate-20261011/start.png', import.meta.url).href,
  final: new URL('./qa-proof/video-candidate-20261011/final.png', import.meta.url).href,
  cue: 4.75, width: 1280, height: 720,
});
let language = query.get('lang') === 'en' ? 'en' : 'de';
let model = createModel();
let store;
let stored = { learningSaved: false, buildingSaved: false };
let view = 'JOURNEY';
let lastScene;
let learningTrigger;
let saveBusy = false;
let isNextLesson = false;
let presentation = null;
let firstReceiptReviewed = false;
const $ = selector => document.querySelector(selector);
const text = () => copy[language];
const escape = value => String(value).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

try { store = new PreviewStore(window.localStorage); stored = store.load(); }
catch { $('#review-feedback').textContent = text().storageFailed; }
function prepareReady() { model.startLearning(); model.beginLearningSave(); model.confirmLearningSave(); model.go('W04'); }
function prepareBuilt() { prepareReady(); model.openBuild(); model.beginBuild(); model.confirmBuildSave(); }
if (stored.buildingSaved) { prepareBuilt(); }
else if (stored.learningSaved) { prepareReady(); }
const requested = query.get('scene');
if (screens.includes(requested)) {
  // Gallery links explicitly seed sample views, never an account or live route.
  model = createModel();
  if (requested === 'R01') { view = 'R01'; firstReceiptReviewed = true; }
  else if (requested === 'B03' || requested === 'W05') { prepareBuilt(); }
  else if (requested !== 'W03') { prepareReady(); }
  if (requested === 'R03') { model.go('R03'); }
  if (requested === 'B01') { model.openBuild(); }
  if (requested === 'W05') { model.nextGoal(); }
  $('#review-feedback').textContent = requested === 'R01' ? text().firstReviewNote : text().sceneReview;
} else if (requested === 'WALLET') { view = 'WALLET'; }
else if (stored.buildingSaved) { $('#review-feedback').textContent = text().restored; }
document.body.dataset.embed = String(query.get('embed') === '1');
$('#text-size').value = ['1.5', '2'].includes(query.get('scale')) ? query.get('scale') : '1';
$('#reduce-motion').checked = query.get('motion') === 'reduce';

function clearSeed() {
  const url = new URL(location.href); url.searchParams.delete('scene'); history.replaceState(null, '', url);
}
function button(label, action, secondary = false, disabled = false) {
  return `<button type="button" class="${secondary ? 'text-action' : 'tactile primary'}" data-action="${action}" ${disabled ? 'disabled' : ''}><svg class="cta-art" data-primary="${!secondary}" aria-hidden="true" focusable="false" preserveAspectRatio="none"></svg><span class="button-label">${escape(label)}</span>${secondary ? '' : `<img class="button-arrow" src="${assets}arrow.png" alt="">`}</button>`;
}

function balanceCard(saved = false) {
  const t = text();
  return `<section class="paper-card balance-card" data-layout="balance"><p class="card-kicker">${escape(saved ? t.savedBalance : t.current)}</p><div class="wallet-amount"><img src="${assets}coin_face.png" alt="" width="46" height="46"><strong>${model.wallet.balance}</strong><span>Yeopjeon</span></div></section>`;
}
function learningCard(next = false) {
  const t = text(), goal = goals[next ? 1 : 0];
  return `<section class="paper-card course-card" data-layout="course"><p class="card-kicker">${escape(t.courseLabel)}</p><div class="course-heading"><img src="${assets}book.png" alt="" width="84" height="76"><h2>${escape(goal[language])}</h2></div><p class="can-do">${escape(goal.canDo[language])}</p>${next ? '' : `<p class="course-status">${escape(t.goalStatus)}</p>`}</section>`;
}
function useSummary() {
  const t = text();
  return `<section class="paper-card use-summary" data-layout="target"><p class="card-kicker">${escape(t.useFor)}</p><h2>${escape(t.target)}</h2><div class="use-cost"><span>${escape(t.cost)}</span><strong>40 Yeopjeon</strong></div></section>`;
}
function readyContent() {
  const t = text();
  return `${balanceCard()}<section class="readiness" data-layout="conditions"><h2>${escape(t.learned)}</h2><p>${escape(t.learnedDetail)}</p></section>${useSummary()}<p class="saved-context" data-layout="context">${escape(t.eligibilityNote)}</p><div class="actions" data-layout="actions">${button(t.buildAction, 'build')}${button(t.continue, 'learn-next', true)}</div>`;
}
function heading(title, subtitle, back = false) {
  const t = text();
  return `<header class="screen-heading" data-layout="heading">${back ? `<button class="back-link" type="button" data-action="wallet-root"><img src="${assets}arrow.png" alt=""><span>${escape(t.walletTitle)}</span></button>` : ''}<h1 id="screen-title" tabindex="-1">${escape(title)}</h1>${subtitle ? `<p class="screen-subtitle">${escape(subtitle)}</p>` : ''}</header>`;
}
function currentReward() {
  if (view === 'R01') { return FIRST_RECEIPT; }
  if (model.scene === 'R03' && model.receipt) {
    return { ...model.receipt, id: model.receipt.claimId, kind: 'milestone' };
  }
  return null;
}
function receivedAmount() { return model.receipt?.amount ?? (firstReceiptReviewed ? FIRST_RECEIPT.amount : 0); }
function rewardContent(receipt) {
  const t = text(), first = receipt.kind === 'first';
  const title = t.titles[first ? 'R01' : 'R03'];
  return `${heading(title, '')}${rewardHero({ kind: receipt.kind, lang: language, amount: receipt.amount, replayLabel: t.replay, skipLabel: t.skip, media: first && candidateVideo ? CANDIDATE_MEDIA : undefined })}<section class="earned-event" data-layout="earned" aria-label="${escape(`${t.earnedNow}: ${receipt.amount} Yeopjeon`)}"><div class="earned-value" aria-hidden="true"><span class="earned-plus">+</span><strong data-earned-value>${receipt.amount}</strong><img src="${assets}coin_face.png" alt="" width="44" height="44"></div><p class="earned-unit">Yeopjeon</p><p class="earned-reason">${escape(first ? t.firstReason : t.milestoneReason)}</p></section><section class="paper-card reward-receipt" data-layout="receipt"><p class="card-kicker">${escape(t.creditConfirmed)}</p><dl class="reward-equation"><div><dt>${escape(t.before)}</dt><dd>${receipt.before}</dd></div><div><dt>${escape(t.earnedNow)}</dt><dd>+${receipt.amount}</dd></div><div><dt>${escape(t.savedBalance)}</dt><dd>${receipt.after}</dd></div></dl></section><div class="actions" data-layout="actions">${button(first ? t.viewGoal : t.viewUse, first ? 'first-goal' : 'ready')}${button(t.continue, first ? 'first-learn' : 'learn-next', true)}</div>`;
}
function buildSheet() {
  const scene = model.scene, t = text(), pending = scene === 'B02', failed = scene === 'B04', unknown = scene === 'B05';
  const dialog = $('#build-dialog');
  $('#build-content').innerHTML = `<div class="sheet-scroll"><p class="card-kicker">${escape(t.useFor)}: ${escape(t.target)}</p><h2 id="build-title" tabindex="-1">${escape(t.titles[scene])}</h2><dl class="price-lines"><div><dt>${escape(t.current)}</dt><dd>70</dd></div><div><dt>${escape(t.cost)}</dt><dd>−40</dd></div><div><dt>${escape(t.expected)}</dt><dd>30</dd></div></dl><p id="build-note" class="dialog-note ${failed ? 'error-note' : ''}">${escape(pending ? t.savingNote : failed ? t.failed : unknown ? t.unknownNote : t.confirmNote)}</p></div><footer class="actions sheet-actions">${button(pending ? t.saving : failed ? t.retry : unknown ? t.checkSave : t.confirmAction, failed ? 'retry' : unknown ? 'check' : 'save', false, pending)}${button(t.cancel, 'cancel', true, pending || unknown)}</footer>`;
  if (!dialog.open) { dialog.showModal(); }
  refreshCtaSurfaces();
  positionBuildSheet();
  $('#build-title').focus({ preventScroll: true });
}
function positionBuildSheet() {
  const dialog = $('#build-dialog');
  if (!dialog.open) { return; }
  const rect = $('#phone').getBoundingClientRect();
  const safeTop = Math.max(16, rect.top + 96);
  const safeBottom = Math.min(innerHeight - 16, rect.bottom - 34);
  dialog.style.width = `${Math.min(370, rect.width - 32)}px`;
  dialog.style.maxHeight = `${Math.max(180, safeBottom - safeTop)}px`;
  dialog.style.left = `${Math.max(16, rect.left + (rect.width - dialog.getBoundingClientRect().width) / 2)}px`;
  dialog.style.top = `${Math.max(safeTop, safeBottom - dialog.getBoundingClientRect().height)}px`;
}

function render({ focus = false } = {}) {
  presentation?.destroy(); presentation = null;
  const t = text(), scene = model.scene;
  const modal = ['B01', 'B02', 'B04', 'B05'].includes(scene);
  const visualScene = view === 'R01' ? 'R01' : view === 'WALLET' ? 'WALLET' : scene;
  let html, title;
  if (visualScene === 'WALLET') {
    title = t.walletTitle;
    html = `${heading(title, '', false)}${balanceCard(model.wallet.spent > 0)}<section class="paper-card ledger-card" data-layout="ledger"><h2>${escape(t.ledgerHeading)}</h2><dl><div><dt>${escape(t.earned)}</dt><dd>${receivedAmount()}</dd></div><div><dt>${escape(t.spent)}</dt><dd>${model.wallet.spent}</dd></div></dl></section><div class="actions" data-layout="actions">${button(model.wallet.owned === 8 ? t.nextGoal : model.wallet.eligible > model.wallet.owned ? t.buildAction : t.goalHeading, 'goal')}</div>`;
  } else if (visualScene === 'W03') {
    title = t.titles.W03;
    html = `${heading(title, t.remaining)}${balanceCard()}${learningCard()}<p class="saved-context" data-layout="context">${escape(t.remainingDetail)}</p><div class="actions" data-layout="actions">${button(t.goalAction, 'learn')}${button(t.backWallet, 'wallet-root', true)}</div>`;
  } else if (visualScene === 'R01' || visualScene === 'R03') {
    title = t.titles[visualScene]; html = rewardContent(currentReward());
  } else if (visualScene === 'W04' || modal) {
    title = t.titles.W04;
    html = `${heading(title, '')}${readyContent()}`;
  } else if (visualScene === 'B03') {
    title = t.titles.B03;
    html = `${heading(title, t.savedStatus)}${balanceCard(true)}<section class="paper-card debit-receipt" data-layout="receipt"><p class="card-kicker">${escape(t.receiptHeading)}</p><h2>−40 Yeopjeon</h2><p>${escape(t.useFor)}: ${escape(t.target)}</p><dl class="saved-ledger"><div><dt>${escape(t.before)}</dt><dd>70</dd></div><div><dt>${escape(t.used)}</dt><dd>40</dd></div><div><dt>${escape(t.savedBalance)}</dt><dd>30</dd></div></dl></section><div class="actions" data-layout="actions">${button(t.nextGoal, 'next')}${button(t.backWallet, 'wallet-root', true)}</div>`;
  } else if (visualScene === 'W05') {
    title = t.titles.W05;
    html = `${heading(title, t.courseLabel)}${learningCard(true)}<p class="saved-context" data-layout="context">${escape(t.savedBalance)}: 30 Yeopjeon</p><div class="actions" data-layout="actions">${button(t.continue, 'learn-next')}${button(t.backWallet, 'wallet-root', true)}</div>`;
  } else { return; }
  $('#screen').innerHTML = html;
  const actions = $('#screen').querySelector('.actions');
  $('#screen-actions').replaceChildren(...(actions ? [actions] : []));
  $('#screen-actions').setAttribute('aria-label', language === 'de' ? 'Aktionen' : 'Actions');
  $('#wallet-value').textContent = model.wallet.balance;
  $('#wallet-value').setAttribute('aria-hidden', 'true');
  $('#wallet-button').dataset.balance = model.wallet.balance;
  $('#wallet-button').setAttribute('aria-label', `${t.current}: ${model.wallet.balance} Yeopjeon. ${t.walletTitle}`);
  $('#phone').dataset.scene = visualScene;
  $('#phone').dataset.saving = String(scene === 'B02');
  const reward = ['R01', 'R03'].includes(visualScene) ? currentReward() : null;
  $('#playback-tools').hidden = !reward;
  if (lastScene !== visualScene) {
    $('#app-scroll').scrollTop = 0;
    $('#screen').classList.remove('entering');
    requestAnimationFrame(() => $('#screen').classList.add('entering'));
    $('#announcement').textContent = `${modal ? t.titles[scene] : title}. ${t.current}: ${model.wallet.balance} Yeopjeon.`;
    if (focus && !modal) { $('#screen-title').focus({ preventScroll: true }); }
  }
  lastScene = visualScene;
  if (reward) {
    $('#phone').dataset.rewardAmount = reward.amount;
    presentation = createRewardPresentation({ root: $('#phone'), receipt: reward, walletNode: $('#wallet-value'), earnedNode: $('[data-earned-value]'), reduced: $('#reduce-motion').checked || matchMedia('(prefers-reduced-motion: reduce)').matches, onSettled: r => { $('#announcement').textContent = `${t.earnedNow}: ${r.amount} Yeopjeon. ${t.savedBalance}: ${r.after} Yeopjeon.`; } });
    presentation.play();
  } else { delete $('#phone').dataset.rewardAmount; }
  if (modal && view !== 'WALLET') { buildSheet(); }
  else if ($('#build-dialog').open) { $('#build-dialog').close(); }
  $('#reference-link').href = visualScene === 'R01' ? `../../abc-20261010/C-spatial-jade-${language}.png` : visualScene === 'R03' ? 'layers/coins-stage-magic.png' : `${files[files[visualScene] ? visualScene : 'W03']}-${language}.png`;
  $('#flow-list').innerHTML = screens.map((id, i) => `<li ${id === visualScene ? 'aria-current="step"' : ''}><span>${escape(t.steps[i])}</span><small>${['R01','W03','B03','W05'].includes(id) ? '30' : '70'} Yeopjeon</small></li>`).join('');
  refreshCtaSurfaces();
  document.title = `Hangul Sori · ${modal ? t.titles[scene] : title}`;
}
function applyLanguage() {
  const t = text(); document.documentElement.lang = language;
  const labels = { '#gallery-link': t.gallery, '#review-eyebrow': t.eyebrow, '#review-title': t.reviewTitle, '#review-description': t.reviewDescription, '#restart': t.restart, '#wallet-entry': t.entry, '#reference-link': t.reference, '#qa-title': t.qaTitle, '#text-size-label': t.textSize, '#motion-label': t.motion, '#save-label': t.saveLabel, '#save-success': t.saveSuccess, '#save-failure': t.saveFailure, '#qa-note': t.qaNote, '#review-boundary': t.boundary, '#wallet-close': t.close };
  for (const [selector, label] of Object.entries(labels)) { $(selector).textContent = label; }
  $('#playback-title').textContent = t.playbackTitle; $('#playback-note').textContent = t.playbackNote;
  $('#replay-reward').textContent = t.replay; $('#skip-reward').textContent = t.skip;
  $('#new-video-preview').textContent = language === 'de' ? 'Neues Video im Layout ansehen' : 'View the new video in this layout';
  $('#original-video-preview').textContent = language === 'de' ? 'Bisheriges Video vergleichen' : 'Compare the previous video';
  $('#new-video-preview').href = `preview.html?lang=${language}&scene=R01&video=candidate`;
  $('#original-video-preview').href = `preview.html?lang=${language}&scene=R01`;
  $('#gallery-link').href = `index.html?lang=${language}`;
  document.querySelectorAll('[data-language]').forEach(el => el.setAttribute('aria-pressed', String(el.dataset.language === language)));
  const url = new URL(location.href); url.searchParams.set('lang', language); history.replaceState(null, '', url);
  render();
}
function applyPreferences() {
  const scale = $('#text-size').value;
  document.documentElement.style.setProperty('--scale', scale);
  $('#phone').dataset.largeText = String(scale !== '1');
  document.body.dataset.largeText = String(scale !== '1');
  $('#status-time').textContent = scale === '1' ? '9:41' : `${Math.round(Number(scale) * 100)}% · QA`;
  document.body.dataset.reducedMotion = String($('#reduce-motion').checked);
  if ($('#reduce-motion').checked) { presentation?.settle(); }
  refreshCtaSurfaces();
  positionBuildSheet();
}
function showLearning(next, trigger) {
  learningTrigger = trigger; isNextLesson = next;
  const goal = goals[next ? 1 : 0], t = text();
  $('#learning-kicker').textContent = t.learningKicker;
  $('#learning-title').textContent = goal[language];
  $('#learning-description').textContent = t.learningDescription;
  $('#learning-content').textContent = goal.canDo[language];
  $('#learning-note').textContent = next ? t.nextLearningNote : t.learningNote;
  $('#learning-complete').hidden = next;
  $('#learning-complete .button-label').textContent = t.learningComplete;
  $('#learning-close').textContent = next ? t.nextLearningClose : t.learningClose;
  $('#learning-dialog').showModal(); refreshCtaSurfaces();
  $('#learning-title').setAttribute('tabindex', '-1'); $('#learning-title').focus();
}
async function saveBuild() {
  if (saveBusy || !model.beginBuild()) { return; }
  saveBusy = true; render();
  $('#restart').disabled = true; $('#wallet-entry').disabled = true;
  try {
    // Paint pending once; saving is owned by storage write/readback, not motion.
    await new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)));
    if ($('#save-outcome').value === 'failure' || !store) { throw new Error('Storage unavailable'); }
    store.save({ learningSaved: true, buildingSaved: true });
    stored = { learningSaved: true, buildingSaved: true };
    model.confirmBuildSave(); clearSeed();
    $('#review-feedback').textContent = '';
  } catch (error) {
    if (error.outcome === 'unknown') { model.unknownBuild(); }
    else { model.failBuild(); }
    $('#review-feedback').textContent = text().storageFailed;
  } finally {
    saveBusy = false; $('#restart').disabled = false; $('#wallet-entry').disabled = false;
    render({ focus: true });
  }
}
function action(event) {
  const trigger = event.target.closest('[data-action]');
  if (!trigger || trigger.disabled || saveBusy) { return; }
  switch (trigger.dataset.action) {
    case 'learn': showLearning(false, trigger); return;
    case 'learn-next': showLearning(true, trigger); return;
    case 'build': case 'retry': model.openBuild(); break;
    case 'cancel': model.cancelBuild(); break;
    case 'save': saveBuild(); return;
    case 'check':
      try {
        const actual = store.load();
        if (actual.learningSaved) {
          model.checkOriginalTarget(actual.buildingSaved ? 'saved' : 'not-saved');
          stored = actual;
          if (actual.buildingSaved) { clearSeed(); }
        }
      } catch { $('#review-feedback').textContent = text().storageFailed; }
      break;
    case 'next': model.nextGoal(); break;
    case 'wallet-root': view = 'WALLET'; break;
    case 'ready': model.go('W04'); break;
    case 'first-goal': view = 'JOURNEY'; model.go('W03'); break;
    case 'first-learn': showLearning(false, trigger); return;
    case 'goal':
      view = 'JOURNEY';
      if (model.wallet.owned === 8) { model.nextGoal(); }
      else if (model.wallet.eligible > model.wallet.owned) { model.go('W04'); }
      else { model.go('W03'); }
      break;
    default: return;
  }
  render({ focus: true });
  if (trigger.dataset.action === 'cancel') { $('[data-action="build"]')?.focus(); }
}
$('#screen').addEventListener('click', action);
$('#screen-actions').addEventListener('click', action);
$('#build-content').addEventListener('click', action);
$('#build-dialog').addEventListener('cancel', event => {
  event.preventDefault();
  if (saveBusy) { return; }
  model.cancelBuild(); render(); $('[data-action="build"]')?.focus();
});
$('#learning-complete').addEventListener('click', () => {
  if (isNextLesson || saveBusy || model.wallet.eligible > model.wallet.owned) { return; }
  try {
    if (!store) { throw new Error('Storage unavailable'); }
    store.save({ learningSaved: true, buildingSaved: false });
    stored = { learningSaved: true, buildingSaved: false };
    model.startLearning(); model.beginLearningSave(); model.confirmLearningSave(); clearSeed(); view = 'JOURNEY';
    $('#learning-dialog').close(); $('#review-feedback').textContent = ''; render({ focus: true });
  } catch { $('#learning-note').textContent = text().storageFailed; }
});
$('#learning-dialog').addEventListener('close', () => { if (learningTrigger?.isConnected) { learningTrigger.focus(); } });
$('#wallet-button').addEventListener('click', () => {
  const t = text(), w = model.wallet;
  $('#wallet-title').textContent = t.walletTitle;
  $('#wallet-summary').innerHTML = [[t.current,w.balance],[t.earned,receivedAmount()],[t.spent,w.spent]].map(([label, value]) => `<div><dt>${escape(label)}</dt><dd>${value}</dd></div>`).join('');
  $('#wallet-note').textContent = t.walletNote; $('#wallet-dialog').showModal(); $('#wallet-close').focus();
});
$('#wallet-dialog').addEventListener('close', () => $('#wallet-button').focus());
$('#wallet-entry').addEventListener('click', () => { if (!saveBusy) { view = 'WALLET'; render({ focus: true }); } });
$('#restart').addEventListener('click', () => {
  if (saveBusy) { return; }
  try {
    if (!store) { store = new PreviewStore(window.localStorage); }
    store.reset(); model = createModel(); stored = { learningSaved: false, buildingSaved: false }; view = 'WALLET'; firstReceiptReviewed = false; clearSeed();
    $('#review-feedback').textContent = text().reset; render({ focus: true });
  } catch { $('#review-feedback').textContent = text().storageFailed; }
});
document.querySelectorAll('[data-language]').forEach(button => button.addEventListener('click', () => { language = button.dataset.language; applyLanguage(); }));
$('#text-size').addEventListener('change', () => { applyPreferences(); render(); });
$('#reduce-motion').addEventListener('change', applyPreferences);
window.addEventListener('resize', positionBuildSheet);
window.addEventListener('scroll', positionBuildSheet, { passive: true });
const sheetResize = new ResizeObserver(positionBuildSheet);
sheetResize.observe($('#build-dialog'));
sheetResize.observe($('#phone'));
document.fonts.ready.then(() => { refreshCtaSurfaces(); positionBuildSheet(); });
$('#replay-reward').addEventListener('click', () => presentation?.play({ replay: true }));
$('#skip-reward').addEventListener('click', () => presentation?.settle());
window.addEventListener('pagehide', () => presentation?.destroy());
document.addEventListener('visibilitychange', () => { if (document.hidden) { presentation?.settle(); document.getAnimations().forEach(animation => animation.finish()); } });
applyPreferences(); applyLanguage();

