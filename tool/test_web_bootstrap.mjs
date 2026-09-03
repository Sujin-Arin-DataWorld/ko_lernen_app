import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import test from 'node:test';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const repositoryRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const indexHtml = readFileSync(resolve(repositoryRoot, 'web', 'index.html'), 'utf8');
const inlineScripts = [...indexHtml.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/gi)]
  .map((match) => match[1])
  .filter((script) => script.trim().length > 0);

function createBrowserHarness({ webdriver, search }) {
  const splash = { removed: false, remove() { this.removed = true; } };
  const branding = { removed: false, remove() { this.removed = true; } };
  const document = {
    body: { style: { background: 'initial' } },
    getElementById(id) {
      return id === 'splash' ? splash : id === 'splash-branding' ? branding : null;
    },
  };
  Object.defineProperties(document, {
    visibilityState: { configurable: true, value: 'prerender' },
    hidden: { configurable: true, value: true },
  });

  const nativeRequestAnimationFrame = () => 1;
  const nativeCancelAnimationFrame = () => {};
  const window = {
    requestAnimationFrame: nativeRequestAnimationFrame,
    cancelAnimationFrame: nativeCancelAnimationFrame,
  };
  const originalVisibilityState = Object.getOwnPropertyDescriptor(
    document,
    'visibilityState',
  );
  const originalHidden = Object.getOwnPropertyDescriptor(document, 'hidden');
  const context = vm.createContext({
    URLSearchParams,
    clearTimeout,
    document,
    location: { search },
    navigator: { webdriver },
    performance: { now: () => 42 },
    setTimeout,
    window,
  });

  return {
    branding,
    context,
    document,
    nativeCancelAnimationFrame,
    nativeRequestAnimationFrame,
    originalHidden,
    originalVisibilityState,
    splash,
    window,
  };
}

function runInlineProductionScripts(harness) {
  for (const script of inlineScripts) {
    vm.runInContext(script, harness.context, { filename: 'web/index.html' });
  }
}

function assertNativeSchedulingAndVisibility(harness) {
  assert.strictEqual(
    harness.window.requestAnimationFrame,
    harness.nativeRequestAnimationFrame,
  );
  assert.strictEqual(
    harness.window.cancelAnimationFrame,
    harness.nativeCancelAnimationFrame,
  );
  assert.deepStrictEqual(
    Object.getOwnPropertyDescriptor(harness.document, 'visibilityState'),
    harness.originalVisibilityState,
  );
  assert.deepStrictEqual(
    Object.getOwnPropertyDescriptor(harness.document, 'hidden'),
    harness.originalHidden,
  );
}

for (const scenario of [
  { name: 'a normal page', webdriver: false, search: '' },
  { name: 'a webdriver page', webdriver: true, search: '' },
  { name: 'a legacy forceRaf page', webdriver: false, search: '?forceRaf=1' },
]) {
  test(`inline bootstrap preserves browser scheduling for ${scenario.name}`, () => {
    const harness = createBrowserHarness(scenario);

    runInlineProductionScripts(harness);

    assertNativeSchedulingAndVisibility(harness);
  });
}

test('inline bootstrap retains normal splash removal', () => {
  const harness = createBrowserHarness({ webdriver: false, search: '' });

  runInlineProductionScripts(harness);
  vm.runInContext('removeSplashFromWeb()', harness.context);

  assert.equal(harness.splash.removed, true);
  assert.equal(harness.branding.removed, true);
  assert.equal(harness.document.body.style.background, 'transparent');
});
