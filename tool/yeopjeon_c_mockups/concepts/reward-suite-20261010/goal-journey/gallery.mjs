const scenes = [
  {
    "id": "R01",
    "file": "rendered/R01-first-daily",
    "original": "../../abc-20261010/C-spatial-jade",
    "de": {
      "title": "Lektion geschafft",
      "description": "Erste gespeicherte Lerneinheit heute · +20 · 10 → 30.",
      "alt": "Dokkaebi und goldener Betrag +20 mit bestätigtem Guthaben 30."
    },
    "en": {
      "title": "Lesson complete",
      "description": "First saved learning activity today · +20 · 10 → 30.",
      "alt": "Dokkaebi and a golden +20 amount with confirmed balance 30."
    }
  },
  {
    "id": "R03",
    "file": "rendered/R03-reward-received",
    "original": "layers/coins-stage-magic.png",
    "de": {
      "title": "Belohnung erhalten",
      "description": "Kursziel bestätigt · +40 · 30 → 70 · Verwendung prüfen.",
      "alt": "Goldene Yeopjeon und blaues Feuer, erhalten 40 und gespeichertes Guthaben 70."
    },
    "en": {
      "title": "Reward received",
      "description": "Course goal confirmed · +40 · 30 → 70 · review use.",
      "alt": "Golden Yeopjeon and blue fire, 40 received and saved balance 70."
    }
  },
  {
    "id": "W03",
    "file": "rendered/W03-learning-goal",
    "de": {
      "title": "Dein Lernziel",
      "description": "30 Yeopjeon · Lernziel noch offen · weiterlernen.",
      "alt": "Lernziel mit vorhandenem Kursinhalt und Guthaben 30."
    },
    "en": {
      "title": "Your learning goal",
      "description": "Balance 30 · learning goal open · continue learning.",
      "alt": "Existing course goal and a balance of 30."
    }
  },
  {
    "id": "W04",
    "file": "rendered/W04-build-ready",
    "de": {
      "title": "Bereit zum Bauen",
      "description": "Lernziel bestätigt · Guthaben 70 · Baukosten 40.",
      "alt": "Verwendungsbedingungen, Guthaben 70 und Baukosten 40."
    },
    "en": {
      "title": "Ready to build",
      "description": "Goal confirmed · balance 70 · building cost 40.",
      "alt": "Conditions for use, balance 70 and building cost 40."
    }
  },
  {
    "id": "B01",
    "file": "rendered/B01-spend-confirm",
    "de": {
      "title": "Betrag bestätigen",
      "description": "Aktuell 70 · Kosten 40 · danach voraussichtlich 30.",
      "alt": "Bestätigungsfenster mit aktuellem und voraussichtlichem Guthaben."
    },
    "en": {
      "title": "Confirm use",
      "description": "Current balance 70 · cost 40 · expected balance 30.",
      "alt": "Confirmation dialog with current and expected balances."
    }
  },
  {
    "id": "B03",
    "file": "rendered/B03-saved-progress",
    "de": {
      "title": "Guthaben gespeichert",
      "description": "40 verwendet · gespeichertes Guthaben 30 · Beleg bestätigt.",
      "alt": "Gespeicherter Verwendungsbeleg und Guthaben 30."
    },
    "en": {
      "title": "Balance saved",
      "description": "40 used · saved balance 30 · receipt confirmed.",
      "alt": "Confirmed use receipt and a saved balance of 30."
    }
  },
  {
    "id": "W05",
    "file": "rendered/W05-next-goal",
    "de": {
      "title": "Dein nächstes Lernziel",
      "description": "Name und Herkunft nennen · Guthaben bleibt 30.",
      "alt": "Nächstes vorhandenes Kursziel und gespeichertes Guthaben 30."
    },
    "en": {
      "title": "Your next learning goal",
      "description": "Say your name and where you are from · balance stays 30.",
      "alt": "Next existing course goal and saved balance 30."
    }
  }
];

const copy = {
  de: {
    skip: 'Zu den Ansichten', collection: 'C · Yeopjeon und Lernziele', language: 'Sprache',
    eyebrow: '2 Belohnungsszenen · 5 verbundene Ansichten', title: 'Deine Belohnung wird spürbar.',
    intro: 'Dokkaebi, goldene Yeopjeon und blaues Feuer begleiten die bestätigte Auszahlung. Danach folgen Guthaben, Verwendung und gespeicherter Beleg.',
    start: 'Belohnung erleben', experience: 'Bild und Bewegung erleben', journey: 'Ansichten', screens: 'Fünf verbundene App-Ansichten',
    rewardTitle: 'Der Moment, in dem du Yeopjeon erhältst', rewardIntro: 'Erste Tagesbelohnung und Kursziel-Belohnung haben ihre eigene Szene. Die Bewegung endet mit dem bestätigten Betrag.',
    candidateVideo: 'Neues Video im Layout ansehen',
    stepR01: 'Erste Belohnung', stepR03: 'Kursziel-Belohnung',
    stepW03: 'Lernziel', stepW04: 'Baubereit', stepB01: 'Bestätigen', stepB03: 'Gespeichert', stepW05: 'Nächstes Ziel',
    reviewNote: 'Die Bilder sind Aufnahmen der interaktiven HTML-Vorschau bei 402 × 874 und 100% Schriftgröße. Über die Schaltflächen lässt sich jede Ansicht ausprobieren.',
    source: 'Originalentwurf ansehen', open: '402 × 874 öffnen', enlarge: 'Bild vergrößern', pending: 'Das Bild wird vorbereitet. Die Vorschau lässt sich unten öffnen.',
    footer: 'Designbilder und lokale Vorschau · kein abgeschlossener Flutter-Nachweis', original: 'Aufnahme öffnen', close: 'Schließen',
    staticNote: 'Aufnahme der HTML-Vorschau. Für verbundene Aktionen die 402 × 874 Vorschau öffnen.',
    changed: 'Deutsche Ansichten geladen.',
  },
  en: {
    skip: 'Skip to screens', collection: 'C · Yeopjeon and learning goals', language: 'Language',
    eyebrow: '2 reward scenes · 5 connected screens', title: 'Feel the reward you earned.',
    intro: 'Dokkaebi, golden Yeopjeon and blue fire accompany your confirmed reward. Balance, use and the saved receipt follow.',
    start: 'Experience the reward', experience: 'Experience image and motion', journey: 'Screens', screens: 'Five connected app screens',
    rewardTitle: 'The moment you receive Yeopjeon', rewardIntro: 'Your first daily reward and course goal reward each have their own scene. Motion settles on the confirmed amount.',
    candidateVideo: 'View the new video in this layout',
    stepR01: 'First reward', stepR03: 'Course goal reward',
    stepW03: 'Learning goal', stepW04: 'Ready to build', stepB01: 'Confirm', stepB03: 'Saved', stepW05: 'Next goal',
    reviewNote: 'These images were captured from the interactive HTML preview at 402 × 874 and 100% text size. Use the buttons to try each screen.',
    source: 'View original design', open: 'Open 402 × 874', enlarge: 'Enlarge image', pending: 'This image is being prepared. Open the preview below.',
    footer: 'Design images and local preview · Flutter completion is a separate check', original: 'Open capture', close: 'Close',
    staticNote: 'HTML preview capture. Open the 402 × 874 preview for connected actions.',
    changed: 'English screens loaded.',
  },
};

const query = new URLSearchParams(window.location.search);
let language = query.get('lang') === 'en' ? 'en' : 'de';
const startScene = scenes.some(scene => scene.id === query.get('scene')) ? query.get('scene') : 'R01';
const dialog = document.querySelector('#image-dialog');
let dialogTrigger;

function previewHref(sceneId) {
  const params = new URLSearchParams({ lang: language, scene: sceneId });
  return `preview.html?${params}`;
}

function imageHref(scene) {
  return `${scene.file}-${language}.png`;
}
function openImage({ title, src, alt, kind, note }, trigger) {
  dialogTrigger = trigger;
  dialog.dataset.kind = kind;
  document.querySelector('#dialog-title').textContent = title;
  document.querySelector('#dialog-note').textContent = note;
  const img = document.querySelector('#dialog-image'); img.src = src; img.alt = alt;
  document.querySelector('#original-image').href = src;
  if (!dialog.open) { dialog.showModal(); }
  document.querySelector('[data-close-dialog]').focus();
}

function applyLanguage(announce = false) {
  const text = copy[language];
  document.documentElement.lang = language;
  document.title = `Hangul Sori · ${text.title}`;
  document.querySelectorAll('[data-i18n]').forEach(node => { node.textContent = text[node.dataset.i18n]; });
  document.querySelectorAll('[data-i18n-aria]').forEach(node => { node.setAttribute('aria-label', text[node.dataset.i18nAria]); });
  document.querySelectorAll('[data-language]').forEach(button => { button.setAttribute('aria-pressed', String(button.dataset.language === language)); });
  document.querySelector('[data-start-preview]').href = previewHref(startScene);
  document.querySelector('[data-candidate-video]').href = `${previewHref('R01')}&video=candidate`;
  document.querySelector('.wordmark').href = `index.html?lang=${language}`;

  scenes.forEach(scene => {
    const article = document.querySelector(`[data-scene="${scene.id}"]`);
    const sceneCopy = scene[language];
    article.querySelector('[data-scene-title]').textContent = sceneCopy.title;
    article.querySelector('[data-scene-description]').textContent = sceneCopy.description;
    article.querySelector('[data-preview-scene]').href = previewHref(scene.id);
    article.querySelector('[data-original-scene]').href = scene.original ? (scene.original.endsWith('.png') ? scene.original : `${scene.original}-${language}.png`) : imageHref(scene).replace('rendered/', '');
    const trigger = article.querySelector('[data-image-scene]');
    const img = trigger.querySelector('img');
    const pending = trigger.querySelector('[data-image-pending]');
    trigger.setAttribute('aria-label', `${sceneCopy.title}: ${text.enlarge}`);
    pending.textContent = text.pending;
    pending.hidden = true;
    img.hidden = false;
    trigger.disabled = false;
    img.alt = sceneCopy.alt;
    const requested = imageHref(scene);
    img.onload = () => {
      if (img.getAttribute('src') === requested) {
        img.hidden = false;
        pending.hidden = true;
        trigger.disabled = false;
      }
    };
    img.onerror = () => {
      if (img.getAttribute('src') === requested) {
        img.hidden = true;
        pending.hidden = false;
        trigger.disabled = true;
      }
    };
    img.src = requested;
  });

  if (announce) { document.querySelector('#gallery-status').textContent = text.changed; }
}

document.querySelectorAll('[data-language]').forEach(button => {
  button.addEventListener('click', () => {
    language = button.dataset.language;
    applyLanguage(true);
  });
});

document.querySelectorAll('[data-image-scene]').forEach(trigger => {
  trigger.addEventListener('click', () => {
    const scene = scenes.find(item => item.id === trigger.dataset.imageScene);
    openImage({ title: `${scene.id} · ${scene[language].title}`, src: imageHref(scene), alt: scene[language].alt, kind: 'screen', note: copy[language].staticNote }, trigger);
  });
});

document.querySelectorAll('[data-material]').forEach(trigger => {
  trigger.addEventListener('click', () => {
    const isReference = trigger.dataset.material === 'reference';
    openImage({ title: isReference ? copy[language].reference : copy[language].candidate, src: trigger.querySelector('img').getAttribute('src'), alt: trigger.querySelector('img').alt, kind: 'material', note: isReference ? copy[language].referenceDialogNote : copy[language].candidateDialogNote }, trigger);
  });
});

document.querySelector('[data-close-dialog]').addEventListener('click', () => { dialog.close(); });
dialog.addEventListener('click', event => {
  if (event.target === dialog) {
    const rect = dialog.getBoundingClientRect();
    if (event.clientX < rect.left || event.clientX > rect.right || event.clientY < rect.top || event.clientY > rect.bottom) {
      dialog.close();
    }
  }
});
dialog.addEventListener('close', () => { dialogTrigger?.focus(); });
applyLanguage();
