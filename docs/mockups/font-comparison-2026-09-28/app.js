const variants = [
  { id: 'noto', label: 'Noto Sans KR 전체', note: '이전 적용안 · 굵은 위계' },
  { id: 'plex', label: 'IBM Plex Sans + Noto Sans KR', note: '독일어·영어 + 한국어', recommended: true },
  { id: 'current', label: '기존', note: 'Paperlogy · 제목 Maru Buri' },
  { id: 'pretendard', label: 'Pretendard', note: '한국어 · 라틴어 한 서체' },
];

const copy = {
  en: {
    eyebrow: 'SCENARIO · A1',
    title: 'Your first question at the airport',
    description: 'At passport control, you hand over your passport.',
    section: 'Listen and speak',
    step: '1 / 6',
    translation: 'Hello. Your passport, please.',
    hint: 'Say the sentence aloud, then listen again.',
    audioLabel: 'Listen to the Korean sentence',
    next: 'NEXT EXPRESSION',
    second: 'Is this your first time in Korea?',
    button: 'Continue learning',
    nav: ['Today', 'Learn', 'Practice', 'Words'],
    glyphs: '한국어 · airport · learning · 0123456789',
  },
  de: {
    eyebrow: 'SZENE · A1',
    title: 'Die erste Frage am Flughafen',
    description: 'An der Passkontrolle reichst du deinen Reisepass hin.',
    section: 'Hören und sprechen',
    step: '1 / 6',
    translation: 'Guten Tag. Ihren Reisepass, bitte.',
    hint: 'Sprich den Satz laut und hör ihn dir dann noch einmal an.',
    audioLabel: 'Koreanischen Satz anhören',
    next: 'NÄCHSTER AUSDRUCK',
    second: 'Sind Sie zum ersten Mal in Korea?',
    button: 'Weiterlernen',
    nav: ['Heute', 'Lernen', 'Üben', 'Wörter'],
    glyphs: '한국어 · Äpfel · Öl · Übung · Größe · Straße',
  },
};

const icons = [
  '<path d="m3 10 9-7 9 7v10H3z"/><path d="M9 20v-6h6v6"/>',
  '<path d="M4 5h7a3 3 0 0 1 3 3v12H7a3 3 0 0 0-3 1z"/><path d="M20 5h-3a3 3 0 0 0-3 3v12h3a3 3 0 0 1 3 1z"/>',
  '<circle cx="12" cy="12" r="9"/><path d="m9 12 2 2 4-4"/>',
  '<path d="M5 4h12a2 2 0 0 1 2 2v14H7a2 2 0 0 1-2-2z"/><path d="M8 8h7M8 12h7"/>',
];

function render(locale) {
  const t = copy[locale];
  document.querySelectorAll('[data-locale]').forEach((button) => {
    button.setAttribute('aria-pressed', button.dataset.locale === locale ? 'true' : 'false');
  });
  document.querySelector('#comparison').innerHTML = variants.map((v) => `
    <article class="variant ${v.recommended ? 'recommended' : ''}">
      <div class="variant-label"><h2>${v.label}</h2><p>${v.note}</p></div>
      <div class="phone ${v.id}" lang="${locale}">
        <div class="status"><span>9:41</span><span class="status-icons" aria-hidden="true"><span></span><span></span><span></span></span></div>
        <div class="app-bar"><span class="app-brand" lang="ko">한글소리</span><span class="lesson-count">A1 · 03 / 12</span></div>
        <div class="screen-content">
          <p class="eyebrow">${t.eyebrow}</p>
          <h3 class="hero-title">${t.title}</h3>
          <p class="hero-description">${t.description}</p>
          <div class="section-heading"><strong>${t.section}</strong><span>${t.step}</span></div>
          <button class="phrase-card" type="button" aria-label="${t.audioLabel}: 안녕하세요. 여권 주세요." aria-pressed="false">
            <span class="phrase-korean" lang="ko">안녕하세요. 여권 주세요.</span>
            <span class="translation">${t.translation}</span>
            <span class="rule"></span><span class="hint-row"><span class="sound" aria-hidden="true"><svg viewBox="0 0 24 24"><path fill="currentColor" d="M3 9v6h4l5 4V5L7 9H3zm12.5-1.5a6 6 0 0 1 0 9l1.4 1.4a8 8 0 0 0 0-11.8z"/></svg></span><span class="hint">${t.hint}</span></span>
          </button>
          <div class="secondary-card"><p class="index">${t.next}</p><p class="ko" lang="ko">한국은 처음이세요?</p><p class="translated">${t.second}</p></div>
        </div>
        <button class="continue" type="button">${t.button}</button>
        <div class="bottom-nav">${t.nav.map((label, i) => `<div class="nav-item ${i === 1 ? 'active' : ''}"><svg viewBox="0 0 24 24" aria-hidden="true">${icons[i]}</svg>${label}</div>`).join('')}</div>
        <div class="home-indicator" aria-hidden="true"></div>
      </div>
      <p class="glyph-strip">${t.glyphs}</p>
    </article>`).join('');
  const params = new URLSearchParams(location.search);
  if (params.get('lang') !== locale) history.replaceState(null, '', `${location.pathname}?lang=${locale}`);
}

document.querySelectorAll('[data-locale]').forEach((button) => {
  button.addEventListener('click', () => render(button.dataset.locale));
});
let activeCard = null;
document.querySelector('#comparison').addEventListener('click', (event) => {
  const card = event.target.closest('.phrase-card');
  if (!card || !('speechSynthesis' in window)) return;
  const synthesis = window.speechSynthesis;
  if (activeCard === card && synthesis.speaking) {
    synthesis.cancel();
    card.classList.remove('is-playing');
    card.setAttribute('aria-pressed', 'false');
    activeCard = null;
    return;
  }
  synthesis.cancel();
  if (activeCard) {
    activeCard.classList.remove('is-playing');
    activeCard.setAttribute('aria-pressed', 'false');
  }
  const utterance = new SpeechSynthesisUtterance('안녕하세요. 여권 주세요.');
  utterance.lang = 'ko-KR';
  utterance.rate = 0.9;
  const koreanVoice = synthesis.getVoices().find((voice) => voice.lang.toLowerCase().startsWith('ko'));
  if (koreanVoice) utterance.voice = koreanVoice;
  activeCard = card;
  card.classList.add('is-playing');
  card.setAttribute('aria-pressed', 'true');
  utterance.onend = utterance.onerror = () => {
    card.classList.remove('is-playing');
    card.setAttribute('aria-pressed', 'false');
    if (activeCard === card) activeCard = null;
  };
  synthesis.speak(utterance);
});
render(new URLSearchParams(location.search).get('lang') === 'de' ? 'de' : 'en');
