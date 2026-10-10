/* A confirmed receipt owns the money. This module only presents that receipt. */
const presentedReceiptIds = new Set();
const announcedReceiptIds = new Set();
const TIMING = Object.freeze({ entrance: 180, cue: 86 / 24, credit: 840, roll: 90, glyph: 230, rim: 200, stall: 2600 });
// Reused C credit reel: refined.js:153,183–197 and refined.css:49–51.
// The native equivalent is yeopjeon_credit_badge.dart:103–104,225–233,292–325.
const STEPS = [80, 170, 260, 350, 460, 590, 740];
const FRACTIONS = [.1, .28, .47, .67, .82, .93, 1];

function confirmedReceipt(receipt) {
  if (!receipt || typeof receipt.id !== 'string' || !receipt.id.trim() || !['first', 'milestone'].includes(receipt.kind)) {
    throw new TypeError('Reward presentation requires a confirmed receipt identity and kind.');
  }
  const { amount, before, after } = receipt;
  if (![amount, before, after].every(Number.isSafeInteger) || amount <= 0 || before < 0 || before + amount !== after) {
    throw new RangeError('Reward presentation requires positive earned coins and a consistent confirmed balance.');
  }
  return Object.freeze({ id: receipt.id, amount, before, after, kind: receipt.kind });
}

/**
 * Paints a validated, already saved receipt. It never awards or stores currency.
 * `onSettled(receipt)` is a presentation notification, once per receipt identity.
 * `play({replay:true})` only repeats visual feedback and never invokes it.
 * Call destroy before replacing the scene; account owners may also dispatch
 * reward:account-stale or set data-reward-account-stale="true" on root.
 * Review clips may specify data-reward-cue in seconds on the contained stage.
 * The cue starts feedback only; full playback ends independently of that clock.
 */
export function createRewardPresentation({ root, receipt, walletNode, earnedNode, reduced = false, onSettled } = {}) {
  const saved = confirmedReceipt(receipt);
  if (!root?.querySelector || !walletNode || !earnedNode) {
    throw new TypeError('Reward presentation requires a root and both numeral nodes.');
  }
  const doc = root.ownerDocument;
  const view = doc.defaultView;
  const stage = root.matches?.('[data-reward-stage]') ? root : root.querySelector('[data-reward-stage]');
  if (!stage) {
    throw new TypeError('Reward presentation requires a contained reward stage.');
  }
  const cueAttribute = stage.getAttribute('data-reward-cue');
  const cue = cueAttribute === null ? TIMING.cue : Number(cueAttribute);
  if (!Number.isFinite(cue) || cue <= 0 || cue >= 30) {
    throw new RangeError('Reward presentation cue must be finite and between 0 and 30 seconds.');
  }
  const video = stage.querySelector('[data-reward-video]');
  const startStill = stage.querySelector('[data-reward-start]');
  const finalStill = stage.querySelector('[data-reward-final]');
  const wallet = walletNode.closest?.('[data-reward-wallet], #wallet-button, .wallet') || walletNode.parentElement;
  const media = view.matchMedia?.('(prefers-reduced-motion: reduce)');
  const now = () => view.performance.now();
  const motionReduced = () => Boolean((typeof reduced === 'function' ? reduced() : reduced?.matches ?? reduced) || media?.matches);
  const targets = [...new Set([root, stage])];
  const timers = new Set();
  const effects = new Set();
  const created = new Set();
  const listeners = [];
  let destroyed = false;
  let running = false;
  let autoRun = false;
  let replayRun = false;
  let creditStarted = false;
  let creditDone = false;
  let videoDone = true;
  let raf = 0;
  let videoFrame = 0;
  let lastDecodeAt = 0;
  let lastMediaTime = -1;
  let creditStart = 0;
  let step = -1;
  let runPromise = null;
  let resolveRun = null;
  let walletEffects = null;

  walletNode.setAttribute('aria-hidden', 'true');
  earnedNode.setAttribute('aria-hidden', 'true');
  stage.dataset.rewardReceiptId = saved.id;

  function classes(name, enabled) {
    targets.forEach(node => node.classList.toggle(name, enabled));
  }

  function later(callback, delay) {
    const timer = view.setTimeout(() => { timers.delete(timer); callback(); }, delay);
    timers.add(timer);
    return timer;
  }

  function listen(node, name, callback) {
    node?.addEventListener(name, callback);
    if (node) { listeners.push(() => node.removeEventListener(name, callback)); }
  }

  function move(node, frames, options) {
    if (!node?.animate || motionReduced() || !running) { return null; }
    const effect = node.animate(frames, { fill: 'none', ...options });
    effects.add(effect);
    effect.finished?.then(() => effects.delete(effect)).catch(() => effects.delete(effect));
    return effect;
  }

  function inertSpan(className, parent, styles = {}) {
    const node = doc.createElement('span');
    node.className = className;
    node.setAttribute('aria-hidden', 'true');
    Object.assign(node.style, styles);
    parent.append(node);
    created.add(node);
    return node;
  }

  function numberReel(valueNode, name, finalNumber, minimumDigits) {
    const font = view.getComputedStyle?.(valueNode);
    const fontSize = Number.parseFloat(font?.fontSize) || (name === 'wallet' ? 18 : 56);
    const line = name === 'wallet' ? 28 * fontSize / 16 : Number.parseFloat(font?.lineHeight) || fontSize * 1.2;
    const originalStyle = Object.fromEntries(['opacity', 'display', 'width', 'height', 'lineHeight', 'textAlign'].map(key => [key, valueNode.style[key]]));
    const slot = doc.createElement('span');
    slot.className = `reward-number-slot reward-number-slot--${name}`;
    slot.setAttribute('aria-hidden', 'true');
    slot.dataset.rewardNumberSlot = name;
    // Local clipped slots reuse the old wallet-number anatomy. Each slot has
    // its own coordinate system, so reels cannot drift into a button or image.
    Object.assign(slot.style, {
      position: 'relative', display: 'inline-block', flex: 'none', overflow: name === 'earned' ? 'visible' : 'hidden', verticalAlign: 'bottom',
      width: `${Math.max(minimumDigits, String(finalNumber).length)}ch`, height: `${line}px`,
      font: font?.font || 'inherit', fontFamily: font?.fontFamily || 'inherit', fontSize: `${fontSize}px`, fontWeight: font?.fontWeight || 'inherit',
      color: font?.color || 'inherit', textShadow: font?.textShadow || 'inherit',
      letterSpacing: font?.letterSpacing || 'inherit', lineHeight: `${line}px`, textAlign: 'center', fontVariantNumeric: 'tabular-nums',
    });
    valueNode.parentElement.insertBefore(slot, valueNode);
    slot.append(valueNode);
    Object.assign(valueNode.style, { display: 'block', width: '100%', height: '100%', lineHeight: `${line}px`, textAlign: 'center' });
    const clip = doc.createElement('span');
    clip.className = 'reward-number-roll';
    clip.setAttribute('aria-hidden', 'true');
    clip.hidden = true;
    Object.assign(clip.style, { display: 'none', position: 'absolute', inset: '0', width: '100%', height: `${line}px`, overflow: 'hidden', pointerEvents: 'none' });
    const reel = doc.createElement('span');
    reel.dataset.rewardNumberReel = name;
    Object.assign(reel.style, { display: 'block', width: '100%', height: `${line * 2}px`, willChange: 'transform' });
    const rows = ['from', 'to'].map(rowName => {
      const row = doc.createElement('span');
      row.dataset.rewardNumberRow = rowName;
      Object.assign(row.style, { display: 'block', width: '100%', height: `${line}px`, lineHeight: `${line}px` });
      reel.append(row);
      return row;
    });
    clip.append(reel);
    slot.append(clip);
    let animation = null;

    function clear() {
      animation?.cancel();
      animation = null;
      clip.hidden = true;
      clip.style.display = 'none';
      valueNode.style.opacity = originalStyle.opacity;
    }

    return {
      slot,
      set(number) { clear(); valueNode.textContent = String(number); },
      rollTo(number) {
        const previous = Number(valueNode.textContent);
        if (previous === number) { return; }
        clear();
        valueNode.textContent = String(number);
        rows[0].textContent = String(previous);
        rows[1].textContent = String(number);
        valueNode.style.opacity = '0';
        clip.hidden = false;
        clip.style.display = 'block';
        // Exact two-row C reel: outgoing line rises while the new line enters.
        const next = move(reel, [{ transform: 'translateY(0)' }, { transform: 'translateY(-50%)' }], {
          duration: TIMING.roll, easing: 'cubic-bezier(.16,.65,.32,1)',
        });
        animation = next;
        if (!next) { clear(); return; }
        next.finished.then(() => { if (animation === next) { clear(); } }).catch(() => {});
      },
      destroy() {
        clear();
        Object.assign(valueNode.style, originalStyle);
        slot.replaceWith(valueNode);
      },
    };
  }

  const walletReel = numberReel(walletNode, 'wallet', saved.after, Math.max(3, String(saved.before).length));
  const earnedReel = numberReel(earnedNode, 'earned', saved.amount, 2);

  function walletGlyphs() {
    if (!wallet) { return; }
    const coin = wallet.querySelector('[data-reward-wallet-coin], .wallet-coin, img');
    if (!coin) { return; }
    const coinBounds = coin.getBoundingClientRect();
    const walletBounds = wallet.getBoundingClientRect();
    const numeralBounds = walletReel.slot.getBoundingClientRect();
    // Original C glyphs belong to wallet-coin/wallet-credits, not the amount.
    // Clip to the coin's horizontal bounds and keep a four-pixel numeral gap
    // even if a larger text scale reduces the available space beside the coin.
    const width = Math.min(coinBounds.right, numeralBounds.left - 4) - coinBounds.left;
    if (width <= 0 || coinBounds.height <= 0) { return; }
    const rise = 18;
    walletEffects = wallet.querySelector('[data-reward-wallet-effects]') || inertSpan('reward-wallet-effects', wallet);
    walletEffects.dataset.rewardCoinLocal = 'true';
    Object.assign(walletEffects.style, {
      position: 'absolute', left: `${coinBounds.left - walletBounds.left - (wallet.clientLeft || 0)}px`,
      top: `${coinBounds.top - walletBounds.top - (wallet.clientTop || 0) - rise}px`,
      width: `${width}px`, height: `${coinBounds.height + rise}px`, right: 'auto', bottom: 'auto',
      transform: 'none', pointerEvents: 'none', overflow: 'hidden', zIndex: '3',
    });
    ['+', '++', '+', '++'].forEach((glyph, index) => {
      const mark = inertSpan('reward-credit-mark', walletEffects, {
        position: 'absolute', left: '0', top: `${rise + 1}px`, opacity: '0', color: '#D59F58',
        fontSize: '14px', fontWeight: '800', lineHeight: '1', whiteSpace: 'nowrap', pointerEvents: 'none', transformOrigin: 'center',
      });
      mark.textContent = glyph;
      const glyphWidth = mark.getBoundingClientRect().width || glyph.length * 10;
      const margin = Math.max(1, glyphWidth * .05);
      const left = Math.max(margin, Math.min([1, 17, 7, 16][index], width - glyphWidth - margin));
      mark.style.left = `${left}px`;
      const y = [6, 11, 15, 7][index];
      move(mark, [
        { opacity: 0, transform: `translateY(${y}px) scale(.6)` },
        { offset: .25, opacity: 1, transform: `translateY(${y - 7}px) scale(1.1)` },
        { opacity: 0, transform: `translateY(${y - 18}px) scale(.9)` },
      ], { duration: TIMING.glyph, delay: [0, 170, 350, 590][index], easing: 'ease-out' });
    });
  }

  function still() {
    video?.pause();
    if (video) { video.hidden = true; }
    if (startStill) { startStill.hidden = true; }
    if (finalStill) { finalStill.hidden = false; }
    classes('is-video-ready', false);
  }

  function paintFinal() {
    walletReel.set(saved.after);
    earnedReel.set(saved.amount);
  }

  function finish(reason = 'settled', notify = true) {
    const wasRunning = running;
    running = false;
    if (raf) { view.cancelAnimationFrame(raf); raf = 0; }
    if (videoFrame && video?.cancelVideoFrameCallback) { video.cancelVideoFrameCallback(videoFrame); videoFrame = 0; }
    timers.forEach(timer => view.clearTimeout(timer));
    timers.clear();
    effects.forEach(effect => effect.cancel());
    effects.clear();
    created.forEach(node => node.remove());
    created.clear();
    walletEffects = null;
    paintFinal();
    still();
    classes('is-presenting', false);
    classes('is-crediting', false);
    classes('is-settled', true);
    classes('is-reduced', motionReduced());
    stage.dataset.rewardPhase = 'settled';
    stage.dataset.rewardSettleReason = reason;
    root.dataset.creditPhase = 'settled';
    const result = { receipt: saved, replay: replayRun, reason };
    resolveRun?.(result);
    resolveRun = null;
    if (wasRunning && autoRun && notify && !announcedReceiptIds.has(saved.id)) {
      announcedReceiptIds.add(saved.id);
      onSettled?.(saved);
    }
    return result;
  }

  function blockedReason() {
    if (!root.isConnected || !stage.isConnected) { return 'left'; }
    if (root.dataset.rewardAccountStale === 'true' || root.dataset.rewardState === 'stale' || stage.dataset.rewardReceiptId !== saved.id) { return 'account-stale'; }
    if (doc.hidden) { return 'background'; }
    if (motionReduced()) { return 'reduced-motion'; }
    return null;
  }

  function checkLifecycle() {
    const reason = blockedReason();
    if (reason) { finish(reason, reason !== 'account-stale'); return false; }
    return running;
  }

  function maybeFinish() {
    if (running && creditDone && videoDone) { finish('completed'); }
  }

  function rimSettle() {
    paintFinal();
    root.dataset.creditPhase = 'rim-settling';
    if (wallet) {
      const rim = wallet.querySelector('[data-reward-wallet-rim]') || inertSpan('reward-wallet-rim', wallet, {
        position: 'absolute', inset: '0', border: '1px solid #D59F58', borderRadius: 'inherit',
        boxShadow: 'inset 0 1px 0 #FFE6A8', opacity: '0', pointerEvents: 'none',
      });
      move(rim, [{ opacity: 0 }, { offset: .3, opacity: .85 }, { opacity: 0 }], { duration: TIMING.rim, easing: 'ease-out' });
    }
    later(() => {
      if (!checkLifecycle()) { return; }
      creditDone = true;
      classes('is-crediting', false);
      root.dataset.creditPhase = 'settled';
      maybeFinish();
    }, TIMING.rim);
  }

  function creditFrame(timestamp) {
    raf = 0;
    if (!checkLifecycle()) { return; }
    const elapsed = Math.max(0, timestamp - creditStart);
    let next = step;
    while (next + 1 < STEPS.length && elapsed >= STEPS[next + 1]) { next++; }
    if (next !== step) {
      step = next;
      const number = Math.min(saved.after, saved.before + Math.max(1, Math.round(saved.amount * FRACTIONS[step])));
      walletReel.rollTo(number);
      earnedReel.rollTo(Math.min(saved.amount, Math.max(1, Math.round(saved.amount * FRACTIONS[step]))));
    }
    if (elapsed >= TIMING.credit) { rimSettle(); }
    else { raf = view.requestAnimationFrame(creditFrame); }
  }

  function beginCredit() {
    if (!running || creditStarted || !checkLifecycle()) { return; }
    creditStarted = true;
    creditStart = now();
    root.dataset.creditPhase = 'collecting';
    root.dataset.rewardReel = 'c-two-row';
    stage.dataset.rewardPhase = 'crediting';
    classes('is-crediting', true);
    walletGlyphs();
    move(earnedReel.slot, [{ transform: 'scale(1)' }, { offset: .4, transform: 'scale(1.025)' }, { transform: 'scale(1)' }], { duration: 320, easing: 'ease-out' });
    raf = view.requestAnimationFrame(creditFrame);
  }

  function videoReady() {
    if (!running || videoDone) { return; }
    classes('is-video-ready', true);
    if (startStill) { startStill.hidden = true; }
  }

  function decoded(mediaTime) {
    if (!running || videoDone) { return; }
    if (Number.isFinite(mediaTime) && mediaTime > lastMediaTime + .001) {
      lastMediaTime = mediaTime;
      lastDecodeAt = now();
      videoReady();
    }
    if (mediaTime >= cue) { beginCredit(); }
  }

  function watchDecodedFrames() {
    if (!running || videoDone || !video.requestVideoFrameCallback) { return; }
    videoFrame = video.requestVideoFrameCallback((_timestamp, metadata) => {
      videoFrame = 0;
      decoded(metadata.mediaTime);
      watchDecodedFrames();
    });
  }

  function watchVideo() {
    if (!checkLifecycle() || videoDone) { return; }
    if (!video.requestVideoFrameCallback) { decoded(video.currentTime); }
    if (now() - lastDecodeAt >= TIMING.stall) { finish('decode-stalled'); return; }
    later(watchVideo, 250);
  }

  function play({ replay = false } = {}) {
    if (destroyed) { return Promise.resolve({ receipt: saved, replay, reason: 'destroyed' }); }
    if (running) { return runPromise; }
    replayRun = Boolean(replay);
    autoRun = !replay;
    if (!replay && presentedReceiptIds.has(saved.id)) {
      autoRun = false;
      return Promise.resolve(finish('already-presented', false));
    }
    if (!replay) { presentedReceiptIds.add(saved.id); }
    running = true;
    creditStarted = false;
    creditDone = false;
    videoDone = saved.kind !== 'first' || !video;
    step = -1;
    runPromise = new Promise(resolve => { resolveRun = resolve; });
    classes('is-settled', false);
    classes('is-reduced', motionReduced());
    classes('is-presenting', true);
    stage.dataset.rewardPhase = 'entering';
    root.dataset.creditPhase = 'waiting';
    if (!checkLifecycle()) { return runPromise; }
    const box = stage.getBoundingClientRect();
    if (box.bottom <= 0 || box.top >= view.innerHeight || box.right <= 0 || box.left >= view.innerWidth) {
      finish('offscreen');
      return runPromise;
    }
    walletReel.set(saved.before);
    earnedReel.set(0);
    if (saved.kind === 'first' && video) {
      if (finalStill) { finalStill.hidden = true; }
      if (startStill) { startStill.hidden = false; }
      video.hidden = false;
      video.loop = false;
      video.muted = true;
      try { video.currentTime = 0; } catch { /* Metadata may still be loading. */ }
      lastMediaTime = -1;
      lastDecodeAt = now();
      watchDecodedFrames();
      watchVideo();
      try {
        const attempt = video.play();
        attempt?.catch(() => { if (running) { finish('playback-unavailable'); } });
      } catch { finish('playback-unavailable'); }
    } else {
      later(beginCredit, TIMING.entrance);
    }
    return runPromise;
  }

  listen(video, 'loadeddata', videoReady);
  listen(video, 'playing', videoReady);
  listen(video, 'timeupdate', () => {
    if (!video?.requestVideoFrameCallback) { decoded(video.currentTime); }
  });
  listen(video, 'ended', () => {
    if (!running || videoDone) { return; }
    videoDone = true;
    still();
    if (!creditStarted) { finish('completed'); }
    else { maybeFinish(); }
  });
  listen(video, 'error', () => { if (running) { finish('playback-unavailable'); } });
  listen(doc, 'visibilitychange', () => { if (running && doc.hidden) { finish('background'); } });
  listen(view, 'pagehide', () => { if (running) { finish('left'); } });
  listen(root, 'reward:leave', () => { if (running) { finish('left'); } });
  listen(root, 'reward:account-stale', () => { if (running) { finish('account-stale', false); } });
  listen(media, 'change', () => { if (running && motionReduced()) { finish('reduced-motion'); } });
  root.querySelectorAll('[data-reward-replay]').forEach(node => listen(node, 'click', () => play({ replay: true })));
  root.querySelectorAll('[data-reward-skip]').forEach(node => listen(node, 'click', () => finish('skipped')));
  const observer = view.IntersectionObserver ? new view.IntersectionObserver(entries => {
    if (running && entries.some(entry => !entry.isIntersecting)) { finish('offscreen'); }
  }, { threshold: .01 }) : null;
  observer?.observe(stage);
  const staleObserver = view.MutationObserver ? new view.MutationObserver(() => {
    if (running) { checkLifecycle(); }
  }) : null;
  staleObserver?.observe(root, { attributes: true, attributeFilter: ['data-reward-account-stale', 'data-reward-state'] });
  if (stage !== root) { staleObserver?.observe(stage, { attributes: true, attributeFilter: ['data-reward-receipt-id'] }); }
  paintFinal();

  return {
    play,
    settle: () => finish('settled'),
    destroy() {
      if (destroyed) { return; }
      finish('destroyed');
      destroyed = true;
      listeners.splice(0).forEach(remove => remove());
      observer?.disconnect();
      staleObserver?.disconnect();
      walletReel.destroy();
      earnedReel.destroy();
    },
  };
}
