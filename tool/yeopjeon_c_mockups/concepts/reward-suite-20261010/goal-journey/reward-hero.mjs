const ASSETS = Object.freeze({
  firstStart: new URL('../../../assets/money_alpha_start.png', import.meta.url).href,
  firstFinal: new URL('../../../assets/money_alpha_end.png', import.meta.url).href,
  firstVideo: new URL('../../../assets/making_money_alpha.webm', import.meta.url).href,
  milestone: new URL('./layers/coins-stage-magic.png', import.meta.url).href,
});

const COPY = Object.freeze({
  de: {
    first: 'Dokkaebi lässt die erhaltenen Yeopjeon erscheinen.',
    milestone: 'Goldene Yeopjeon auf einem geschnitzten Jadesockel mit blauem Dokkaebi-Feuer.',
    replay: 'Wiederholen',
    skip: 'Überspringen',
    replayAccessible: 'Belohnungsszene erneut ansehen',
    skipAccessible: 'Belohnungsszene überspringen und bestätigten Betrag anzeigen',
    controls: 'Wiedergabe zur Vorschau',
  },
  en: {
    first: 'Dokkaebi brings the earned Yeopjeon into view.',
    milestone: 'Golden Yeopjeon on a carved jade pedestal with blue Dokkaebi fire.',
    replay: 'Replay',
    skip: 'Skip',
    replayAccessible: 'Watch the reward scene again',
    skipAccessible: 'Skip the reward scene and show the confirmed amount',
    controls: 'Preview playback',
  },
});

function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, (character) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  })[character]);
}

function reviewMediaSource(media) {
  const width = Number(media.width);
  const height = Number(media.height);
  const cue = Number(media.cue);
  if (!Number.isSafeInteger(width) || width < 1 || !Number.isSafeInteger(height) || height < 1) {
    throw new RangeError('Review media dimensions must be positive integers');
  }
  if (!Number.isFinite(cue) || cue < 0) {
    throw new RangeError('Review media cue must be a finite nonnegative number');
  }
  const sourceUrl = (value) => {
    if (typeof value !== 'string' || !value.trim()) {
      throw new TypeError('Review media requires video, start and final URLs');
    }
    const url = new URL(value, import.meta.url);
    if (!['https:', 'http:', 'file:', 'blob:'].includes(url.protocol)) {
      throw new TypeError('Unsupported review media URL protocol');
    }
    return url.href;
  };
  return {
    video: sourceUrl(media.video),
    start: sourceUrl(media.start),
    final: sourceUrl(media.final),
    width,
    height,
    cue,
  };
}

/**
 * Presentation-only acquisition artwork. The caller owns the confirmed amount,
 * wallet text, receipt and playback lifecycle. Controls and optional first-scene
 * media overrides are opt-in review UI; default original sources stay intact.
 */
export function rewardHero({ kind, lang = 'de', amount, replayLabel, skipLabel, media } = {}) {
  if (kind !== 'first' && kind !== 'milestone') {
    throw new RangeError('rewardHero kind must be first or milestone');
  }
  if (kind !== 'first' && media != null) {
    throw new TypeError('Review media overrides are only supported for first rewards');
  }
  const hasMediaOverride = kind === 'first' && media != null;
  const firstSource = hasMediaOverride ? reviewMediaSource(media) : {
    video: ASSETS.firstVideo,
    start: ASSETS.firstStart,
    final: ASSETS.firstFinal,
    width: 960,
    height: 960,
    cue: 3.583,
  };
  const locale = lang === 'en' ? 'en' : 'de';
  const copy = COPY[locale];
  const confirmedAmount = Number(amount);
  const amountAttribute = Number.isSafeInteger(confirmedAmount) && confirmedAmount >= 0
    ? ` data-reward-amount="${confirmedAmount}"`
    : '';
  const mediaMarkup = kind === 'first'
    ? `<div class="reward-hero__media reward-hero__media--dokkaebi">
        <img class="reward-hero__still reward-hero__start" data-reward-start
          src="${escapeHtml(firstSource.start)}" width="${firstSource.width}" height="${firstSource.height}"
          alt="" aria-hidden="true" decoding="async">
        <img class="reward-hero__still reward-hero__final" data-reward-final hidden
          src="${escapeHtml(firstSource.final)}" width="${firstSource.width}" height="${firstSource.height}"
          alt="" aria-hidden="true" decoding="async">
        <video class="reward-hero__video" data-reward-video hidden
          src="${escapeHtml(firstSource.video)}" poster="${escapeHtml(firstSource.final)}"
          width="${firstSource.width}" height="${firstSource.height}" preload="metadata" playsinline muted
          disablepictureinpicture disableremoteplayback aria-hidden="true" tabindex="-1"></video>
      </div>`
    : `<div class="reward-hero__media reward-hero__media--coins">
        <img class="reward-hero__visual" data-reward-visual
          src="${escapeHtml(ASSETS.milestone)}" width="1536" height="1024"
          alt="" aria-hidden="true" decoding="async">
      </div>`;

  const cueAttribute = kind === 'first' ? ` data-reward-cue="${escapeHtml(firstSource.cue)}"` : '';
  const reviewAttribute = hasMediaOverride ? ' data-reward-media="review"' : '';
  return `<figure class="reward-hero reward-hero--${kind}${hasMediaOverride ? ' reward-hero--cinematic' : ''}" data-reward-stage data-layout="reward"
      data-reward-kind="${kind}"${amountAttribute}${cueAttribute}${reviewAttribute} lang="${locale}"
      aria-label="${escapeHtml(copy[kind])}">
    <span class="reward-hero__back" data-reward-back aria-hidden="true"></span>
    <span class="reward-hero__backlight" data-reward-fx aria-hidden="true"></span>
    <span class="reward-hero__contact-shadow" data-reward-contact-shadow aria-hidden="true"></span>
    <span class="reward-hero__flare" data-reward-fx aria-hidden="true"></span>
    <span class="reward-hero__foreground" data-reward-foreground aria-hidden="true"></span>
    ${mediaMarkup}
    <div class="reward-hero__controls" data-reward-controls role="group"
        aria-label="${escapeHtml(copy.controls)}">
      <button type="button" class="reward-hero__control" data-reward-replay
          aria-label="${escapeHtml(copy.replayAccessible)}">${escapeHtml(replayLabel ?? copy.replay)}</button>
      <button type="button" class="reward-hero__control" data-reward-skip
          aria-label="${escapeHtml(copy.skipAccessible)}">${escapeHtml(skipLabel ?? copy.skip)}</button>
    </div>
  </figure>`;
}
