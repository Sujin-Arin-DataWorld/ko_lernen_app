import test from 'node:test';
import assert from 'node:assert/strict';
import { createRewardPresentation } from './reward-presentation.mjs';

class Clock extends EventTarget {
  time = 0;
  sequence = 0;
  queue = new Map();
  innerHeight = 874;
  innerWidth = 402;
  performance = { now: () => this.time };
  media = Object.assign(new EventTarget(), { matches: false });
  matchMedia = () => this.media;
  getComputedStyle = node => {
    const earned = node.matches('[data-earned-value]');
    return { font: `700 ${earned ? 56 : 18}px Paperlogy`, fontSize: `${earned ? 56 : 18}px`, lineHeight: `${earned ? 67.2 : 25.2}px`, fontFamily: 'Paperlogy', fontWeight: '700', color: '#FFF4D8' };
  };
  animations = [];
  setTimeout = (callback, delay = 0) => {
    const id = ++this.sequence;
    this.queue.set(id, { callback, at: this.time + delay });
    return id;
  };
  clearTimeout = id => this.queue.delete(id);
  requestAnimationFrame = callback => this.setTimeout(() => callback(this.time), 16);
  cancelAnimationFrame = id => this.clearTimeout(id);
  tick(ms) {
    const target = this.time + ms;
    while (true) {
      const pending = [...this.queue.entries()].filter(([, item]) => item.at <= target).sort((a, b) => a[1].at - b[1].at)[0];
      if (!pending) { break; }
      const [id, item] = pending;
      this.queue.delete(id);
      this.time = item.at;
      item.callback();
    }
    this.time = target;
  }
}

class Element extends EventTarget {
  children = [];
  attributes = new Map();
  style = {};
  dataset = {};
  textContent = '';
  isConnected = true;
  hidden = false;
  keys = new Set();
  classes = new Set();
  classList = {
    toggle: (name, enabled) => enabled ? this.classes.add(name) : this.classes.delete(name),
    contains: name => this.classes.has(name),
  };
  constructor(doc, ...keys) { super(); this.ownerDocument = doc; keys.forEach(key => this.keys.add(key)); }
  matches(selector) { return selector.split(',').some(key => this.keys.has(key.trim())); }
  querySelectorAll(selector) {
    return this.children.flatMap(node => [...(node.matches(selector) ? [node] : []), ...node.querySelectorAll(selector)]);
  }
  querySelector(selector) { return this.querySelectorAll(selector)[0] || null; }
  closest(selector) { return this.matches(selector) ? this : this.parentElement?.closest(selector); }
  setAttribute(key, value) { this.attributes.set(key, value); }
  getAttribute(key) { return this.attributes.get(key) ?? null; }
  append(node) {
    if (node.parentElement) { node.parentElement.children = node.parentElement.children.filter(child => child !== node); }
    this.children.push(node);
    node.parentElement = this;
    node.isConnected = this.isConnected;
  }
  insertBefore(node, reference) {
    const index = this.children.indexOf(reference);
    if (index < 0) { throw new Error('Reference is not a child'); }
    this.children.splice(index, 0, node);
    node.parentElement = this;
  }
  replaceWith(node) {
    const parent = this.parentElement;
    parent.insertBefore(node, this);
    this.remove();
  }
  remove() {
    if (this.parentElement) { this.parentElement.children = this.parentElement.children.filter(node => node !== this); }
    this.isConnected = false;
  }
  getBoundingClientRect() {
    if (this.className === 'reward-credit-mark') {
      return { left: 0, top: 0, right: this.textContent.length * 8, bottom: 14, width: this.textContent.length * 8, height: 14 };
    }
    return { left: 16, top: 16, right: 116, bottom: 236, width: 100, height: 20 };
  }
  animate(frames, options) {
    const clock = this.ownerDocument.defaultView;
    clock.animations.push({ node: this, frames, options, values: this.children.map(child => child.textContent) });
    let resolve;
    let reject;
    const finished = new Promise((yes, no) => { resolve = yes; reject = no; });
    const timer = clock.setTimeout(resolve, (options.delay || 0) + options.duration);
    return { finished, cancel: () => { clock.clearTimeout(timer); reject(new Error('cancelled')); } };
  }
}

class Video extends Element {
  currentTime = 0;
  loop = true;
  plays = 0;
  pauses = 0;
  frameSequence = 0;
  frameCallbacks = new Map();
  play() { this.plays++; this.dispatchEvent(new Event('playing')); return Promise.resolve(); }
  pause() { this.pauses++; }
  requestVideoFrameCallback(callback) {
    const id = ++this.frameSequence;
    this.frameCallbacks.set(id, callback);
    return id;
  }
  cancelVideoFrameCallback(id) { this.frameCallbacks.delete(id); }
  decode(mediaTime) {
    this.currentTime = mediaTime;
    const callbacks = [...this.frameCallbacks.values()];
    this.frameCallbacks.clear();
    callbacks.forEach(callback => callback(this.ownerDocument.defaultView.time, { mediaTime }));
  }
}

let sequence = 0;
function fixture({ kind = 'milestone', id = `presentation-${++sequence}`, reduced = false, receipt, cue } = {}) {
  const clock = new Clock();
  const doc = Object.assign(new EventTarget(), { defaultView: clock, hidden: false });
  doc.createElement = () => new Element(doc);
  const root = new Element(doc);
  const stage = new Element(doc, '[data-reward-stage]');
  if (cue !== undefined) { stage.setAttribute('data-reward-cue', String(cue)); }
  root.append(stage);
  const wallet = new Element(doc, '#wallet-button');
  const coin = new Element(doc, 'img');
  wallet.append(coin);
  const walletNode = new Element(doc);
  wallet.append(walletNode);
  root.append(wallet);
  const earnedNode = new Element(doc, '[data-earned-value]');
  root.append(earnedNode);
  const replay = new Element(doc, '[data-reward-replay]');
  const skip = new Element(doc, '[data-reward-skip]');
  stage.append(replay);
  stage.append(skip);
  let video;
  let finalStill;
  if (kind === 'first') {
    video = new Video(doc, '[data-reward-video]');
    stage.append(video);
    stage.append(new Element(doc, '[data-reward-start]'));
    finalStill = new Element(doc, '[data-reward-final]');
    stage.append(finalStill);
  }
  const saved = receipt || { id, kind, amount: kind === 'first' ? 20 : 40, before: kind === 'first' ? 10 : 30, after: kind === 'first' ? 30 : 70 };
  const settled = [];
  const controller = createRewardPresentation({ root, receipt: saved, walletNode, earnedNode, reduced, onSettled: value => settled.push(value) });
  return { clock, doc, root, stage, wallet, coin, walletNode, earnedNode, video, finalStill, settled, controller, saved, replay, skip };
}

test('invalid or inconsistent receipts cannot begin a presentation', () => {
  for (const receipt of [
    { id: 'bad-negative', kind: 'milestone', before: -1, amount: 40, after: 39 },
    { id: 'bad-zero', kind: 'milestone', before: 30, amount: 0, after: 30 },
    { id: 'bad-sum', kind: 'milestone', before: 30, amount: 40, after: 71 },
    { id: 'bad-fraction', kind: 'milestone', before: 30, amount: 4.5, after: 34.5 },
  ]) { assert.throws(() => fixture({ receipt }), RangeError); }
});

test('one clock rolls both counters to the saved result and notifies once', async () => {
  const f = fixture();
  const original = structuredClone(f.saved);
  const completion = f.controller.play();
  assert.equal(f.walletNode.textContent, '30');
  assert.equal(f.earnedNode.textContent, '0');
  f.clock.tick(500);
  assert.ok(Number(f.walletNode.textContent) > 30 && Number(f.walletNode.textContent) < 70);
  assert.ok(Number(f.earnedNode.textContent) > 0 && Number(f.earnedNode.textContent) < 40);
  assert.equal(f.settled.length, 0);
  f.clock.tick(800);
  assert.equal((await completion).reason, 'completed');
  assert.equal(f.walletNode.textContent, '70');
  assert.equal(f.earnedNode.textContent, '40');
  assert.equal(f.settled.length, 1);
  assert.deepEqual(f.saved, original);
  assert.equal(f.walletNode.getAttribute('aria-hidden'), 'true');
  assert.equal(f.earnedNode.getAttribute('aria-hidden'), 'true');
  f.controller.settle();
  f.controller.destroy();
  assert.equal(f.settled.length, 1);
  assert.equal(f.clock.queue.size, 0);
});

test('both confirmed awards reuse the visible original two-row90ms C reels', async () => {
  for (const kind of ['first', 'milestone']) {
    const f = fixture({ kind });
    const completion = f.controller.play();
    if (f.video) { f.video.decode(86 / 24); }
    else { f.clock.tick(180); }
    f.clock.tick(80);
    const slots = [f.walletNode.parentElement, f.earnedNode.parentElement];
    assert.equal(slots[0].dataset.rewardNumberSlot, 'wallet');
    assert.equal(slots[1].dataset.rewardNumberSlot, 'earned');
    assert.equal(slots[0].style.width, '3ch');
    assert.equal(slots[1].style.width, '2ch');
    for (const [index, slot] of slots.entries()) {
      const clip = slot.children[1];
      assert.equal(clip.parentElement, slot);
      assert.equal(clip.hidden, false);
      assert.equal(clip.style.display, 'block');
      assert.equal(slot.children[0].style.opacity, '0');
      assert.equal(clip.getAttribute('aria-hidden'), 'true');
      assert.equal(clip.children[0].children.length, 2);
      assert.deepEqual(clip.children[0].children.map(row => row.textContent), index === 0
        ? [String(f.saved.before), String(f.saved.before + Math.round(f.saved.amount * .1))]
        : ['0', String(Math.round(f.saved.amount * .1))]);
    }
    f.clock.tick(1100);
    if (f.video) { f.video.dispatchEvent(new Event('ended')); }
    await completion;
    const reels = f.clock.animations.filter(animation => animation.node.dataset.rewardNumberReel);
    assert.equal(reels.length, 14);
    for (const animation of reels) {
      assert.equal(animation.options.duration, 90);
      assert.equal(animation.options.easing, 'cubic-bezier(.16,.65,.32,1)');
      assert.deepEqual(animation.frames, [{ transform: 'translateY(0)' }, { transform: 'translateY(-50%)' }]);
    }
    assert.deepEqual(reels.filter(animation => animation.node.dataset.rewardNumberReel === 'earned').map(animation => animation.values[1]), kind === 'first'
      ? ['2', '6', '9', '13', '16', '19', '20']
      : ['4', '11', '19', '27', '33', '37', '40']);
    assert.equal(slots[1].style.overflow, 'visible');
    assert.equal(slots[1].children[1].hidden, true);
    assert.equal(f.walletNode.textContent, String(f.saved.after));
    assert.equal(f.earnedNode.textContent, String(f.saved.amount));
    f.controller.destroy();
    assert.notEqual(f.walletNode.parentElement.dataset.rewardNumberSlot, 'wallet');
    assert.notEqual(f.earnedNode.parentElement.dataset.rewardNumberSlot, 'earned');
  }
});

test('skip and reduced motion leave no visible reel or outgoing numeral', async () => {
  const f = fixture();
  const completion = f.controller.play();
  f.clock.tick(260);
  f.skip.dispatchEvent(new Event('click'));
  await completion;
  for (const valueNode of [f.walletNode, f.earnedNode]) {
    assert.equal(valueNode.parentElement.children[1].hidden, true);
    assert.notEqual(valueNode.style.opacity, '0');
  }
  const reduced = fixture({ reduced: true });
  await reduced.controller.play();
  assert.equal(reduced.clock.animations.length, 0);
  for (const valueNode of [reduced.walletNode, reduced.earnedNode]) {
    assert.equal(valueNode.parentElement.children[1].hidden, true);
    assert.notEqual(valueNode.style.opacity, '0');
  }
});

test('all four C glyphs stay coin-local and clear of the wallet reel at100% and200%', async () => {
  for (const textScale of [1, 2]) {
    const f = fixture();
    const walletLeft = textScale === 1 ? 288 : 260;
    const walletHeight = textScale === 1 ? 48 : 77;
    const coinLeft = walletLeft + 11;
    const coinTop = 62 + (walletHeight - 28) / 2;
    const slotLeft = coinLeft + 28 + 8;
    f.wallet.clientLeft = 1;
    f.wallet.clientTop = 1;
    f.wallet.getBoundingClientRect = () => ({ left: walletLeft, top: 62, right: 386, bottom: 62 + walletHeight, width: 386 - walletLeft, height: walletHeight });
    f.coin.getBoundingClientRect = () => ({ left: coinLeft, top: coinTop, right: coinLeft + 28, bottom: coinTop + 28, width: 28, height: 28 });
    f.walletNode.parentElement.getBoundingClientRect = () => ({ left: slotLeft, top: 68, right: slotLeft + 30 * textScale, bottom: 68 + 31.5 * textScale, width: 30 * textScale, height: 31.5 * textScale });
    const completion = f.controller.play();
    f.clock.tick(180);
    const marks = f.clock.animations.filter(animation => animation.node.className === 'reward-credit-mark');
    assert.equal(marks.length, 4);
    assert.deepEqual(marks.map(animation => animation.node.textContent), ['+', '++', '+', '++']);
    assert.deepEqual(marks.map(animation => animation.options.delay), [0, 170, 350, 590]);
    for (const animation of marks) {
      const layer = animation.node.parentElement;
      const left = walletLeft + f.wallet.clientLeft + Number.parseFloat(layer.style.left);
      const right = left + Number.parseFloat(layer.style.width);
      assert.equal(layer.dataset.rewardCoinLocal, 'true');
      assert.equal(layer.style.overflow, 'hidden');
      assert.equal(layer.style.transform, 'none');
      assert.equal(layer.style.right, 'auto');
      assert.equal(left, coinLeft);
      assert.ok(right <= coinLeft + 28);
      assert.ok(right <= slotLeft - 4);
      assert.equal(animation.options.duration, 230);
      assert.equal(animation.frames[1].opacity, 1);
      const glyphWidth = animation.node.getBoundingClientRect().width;
      const center = left + Number.parseFloat(animation.node.style.left) + glyphWidth / 2;
      for (const frame of animation.frames) {
        const scale = Number(frame.transform.match(/scale\(([\d.]+)\)/)[1]);
        assert.ok(center - glyphWidth * scale / 2 >= left);
        assert.ok(center + glyphWidth * scale / 2 <= right);
      }
    }
    f.clock.tick(1300);
    await completion;
    assert.equal(f.wallet.children.some(node => node.dataset.rewardCoinLocal === 'true'), false);
  }
});

test('double play uses the active presentation; replay never repeats its callback', async () => {
  const f = fixture();
  const first = f.controller.play();
  assert.equal(f.controller.play(), first);
  f.clock.tick(1300);
  await first;
  const replay = f.controller.play({ replay: true });
  f.clock.tick(1300);
  assert.equal((await replay).replay, true);
  assert.equal(f.settled.length, 1);
  assert.equal(f.walletNode.textContent, '70');
});

test('a remount with the same receipt identity shows the result without another award effect', async () => {
  const id = `dedupe-${++sequence}`;
  const first = fixture({ id });
  first.controller.play();
  first.clock.tick(300);
  first.controller.destroy();
  const next = fixture({ id });
  assert.equal((await next.controller.play()).reason, 'already-presented');
  assert.equal(next.walletNode.textContent, '70');
  assert.equal(next.earnedNode.textContent, '40');
  assert.equal(next.settled.length, 0);
  assert.equal(next.clock.queue.size, 0);
});

test('first receipt waits for the original wand cue and the entire video', async () => {
  const f = fixture({ kind: 'first' });
  const completion = f.controller.play();
  f.video.decode(3.5);
  f.clock.tick(100);
  assert.equal(f.root.dataset.creditPhase, 'waiting');
  f.video.decode(86 / 24);
  assert.equal(f.root.dataset.creditPhase, 'collecting');
  f.clock.tick(1100);
  assert.equal(f.walletNode.textContent, '30');
  assert.equal(f.earnedNode.textContent, '20');
  assert.equal(f.settled.length, 0);
  assert.equal(f.video.hidden, false);
  f.video.dispatchEvent(new Event('ended'));
  assert.equal((await completion).reason, 'completed');
  assert.equal(f.video.hidden, true);
  assert.equal(f.finalStill.hidden, false);
  assert.equal(f.settled.length, 1);
  assert.equal(f.video.loop, false);
  assert.equal(f.video.muted, true);
});

test('a review clip uses its validated cue and keeps playing after the credit clock settles', async () => {
  const f = fixture({ kind: 'first', cue: 5.2 });
  const completion = f.controller.play();
  for (let mediaTime = 1; mediaTime <= 5; mediaTime++) {
    f.clock.tick(1000);
    f.video.decode(mediaTime);
  }
  assert.equal(f.root.dataset.creditPhase, 'waiting');
  assert.equal(f.walletNode.textContent, '10');
  assert.equal(f.earnedNode.textContent, '0');
  f.clock.tick(200);
  f.video.decode(5.2);
  assert.equal(f.root.dataset.creditPhase, 'collecting');
  f.clock.tick(1100);
  f.video.decode(6.3);
  assert.equal(f.root.dataset.creditPhase, 'settled');
  assert.equal(f.walletNode.textContent, '30');
  assert.equal(f.earnedNode.textContent, '20');
  assert.equal(f.video.hidden, false);
  assert.equal(f.stage.classList.contains('is-video-ready'), true);
  assert.equal(f.settled.length, 0);
  for (const mediaTime of [7.3, 8.3, 9.3, 10.005]) {
    f.clock.tick(1000);
    f.video.decode(mediaTime);
    assert.equal(f.video.hidden, false);
  }
  f.video.dispatchEvent(new Event('ended'));
  assert.equal((await completion).reason, 'completed');
  assert.equal(f.video.hidden, true);
  assert.equal(f.finalStill.hidden, false);
  assert.equal(f.video.plays, 1);
  assert.equal(f.settled.length, 1);
});

test('an invalid review cue cannot start feedback', () => {
  for (const cue of [0, -1, 30, 31, '', 'not-a-number', Infinity]) {
    assert.throws(() => fixture({ kind: 'first', cue }), RangeError);
  }
});

test('the watchdog permits slow playback while decoded frames continue to advance', async () => {
  const f = fixture({ kind: 'first' });
  const completion = f.controller.play();
  for (let frame = 1; frame <= 13; frame++) {
    f.clock.tick(1000);
    f.video.decode(frame * .4);
    assert.equal(f.stage.classList.contains('is-settled'), false);
  }
  f.video.dispatchEvent(new Event('ended'));
  f.clock.tick(1300);
  assert.equal((await completion).reason, 'completed');
  assert.equal(f.settled.length, 1);
});

test('stalled decoding settles to the same confirmed result', async () => {
  const f = fixture({ kind: 'first' });
  const completion = f.controller.play();
  f.clock.tick(2800);
  assert.equal((await completion).reason, 'decode-stalled');
  assert.equal(f.walletNode.textContent, '30');
  assert.equal(f.earnedNode.textContent, '20');
  assert.equal(f.finalStill.hidden, false);
  assert.equal(f.video.frameCallbacks.size, 0);
});

test('skip, background and leave preserve the saved amount without leftover work', async () => {
  for (const reason of ['skipped', 'background', 'left']) {
    const f = fixture({ kind: 'first' });
    const completion = f.controller.play();
    f.video.decode(86 / 24);
    f.clock.tick(300);
    if (reason === 'skipped') { f.skip.dispatchEvent(new Event('click')); }
    if (reason === 'background') { f.doc.hidden = true; f.doc.dispatchEvent(new Event('visibilitychange')); }
    if (reason === 'left') { f.root.dispatchEvent(new Event('reward:leave')); }
    assert.equal((await completion).reason, reason);
    assert.equal(f.walletNode.textContent, '30');
    assert.equal(f.earnedNode.textContent, '20');
    assert.equal(f.settled.length, 1);
    assert.equal(f.clock.queue.size, 0);
    assert.equal(f.video.frameCallbacks.size, 0);
    f.controller.destroy();
  }
});

test('reduced motion presents final values immediately and replay stays silent', async () => {
  const f = fixture({ kind: 'first', reduced: true });
  assert.equal((await f.controller.play()).reason, 'reduced-motion');
  assert.equal(f.video.plays, 0);
  assert.equal(f.walletNode.textContent, '30');
  assert.equal(f.earnedNode.textContent, '20');
  assert.equal(f.stage.classList.contains('is-reduced'), true);
  await f.controller.play({ replay: true });
  assert.equal(f.settled.length, 1);
  assert.equal(f.clock.queue.size, 0);
});

test('an account-stale scene settles without announcing the former account receipt', async () => {
  const f = fixture();
  const completion = f.controller.play();
  f.clock.tick(300);
  f.root.dispatchEvent(new Event('reward:account-stale'));
  assert.equal((await completion).reason, 'account-stale');
  assert.equal(f.walletNode.textContent, '70');
  assert.equal(f.earnedNode.textContent, '40');
  assert.equal(f.settled.length, 0);
  assert.equal(f.clock.queue.size, 0);
});

test('offscreen scene skips its decorative work and exposes the confirmed result', async () => {
  const f = fixture();
  f.stage.getBoundingClientRect = () => ({ left: 16, right: 116, top: 900, bottom: 1120 });
  assert.equal((await f.controller.play()).reason, 'offscreen');
  assert.equal(f.walletNode.textContent, '70');
  assert.equal(f.earnedNode.textContent, '40');
  assert.equal(f.settled.length, 1);
  assert.equal(f.clock.queue.size, 0);
});
