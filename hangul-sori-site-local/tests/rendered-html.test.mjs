import assert from "node:assert/strict";
import test from "node:test";

test("renders finished site metadata", async () => {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("test", `${process.pid}-${Date.now()}`);
  const { default: worker } = await import(workerUrl.href);

  const response = await worker.fetch(
    new Request("http://localhost/", {
      headers: { accept: "text/html" },
    }),
    {
      ASSETS: {
        fetch: async () => new Response("Not found", { status: 404 }),
      },
    },
    {
      waitUntil() {},
      passThroughOnException() {},
    },
  );

  assert.equal(response.status, 200);
  assert.match(
    response.headers.get("content-type") ?? "",
    /^text\/html\b/i,
  );
  assert.equal(response.headers.get("x-content-type-options"), "nosniff");
  assert.equal(response.headers.get("x-frame-options"), "DENY");
  assert.equal(response.headers.get("referrer-policy"), "no-referrer");
  const html = await response.text();
  assert.match(html, /Learn Korean and build your own hanok\./i);
  assert.match(html, /한글을, 소리로 배우다/);
  assert.match(html, /name=["']theme-color["'][^>]*content=["']#1f7a6b["']/i);
  assert.doesNotMatch(html, /codex-preview/i);
  assert.match(html, /app-assets\/taego-joy-duo\.png/i);
  assert.match(html, /hangul-sori-logo\.png/i);
  assert.match(html, /icon-192\.png/i);
  assert.match(html, /G-6R9J2N1PCC/);
  assert.match(html, /id=["']Cookiebot["']/i);
  assert.match(html, /4693fd59-1476-40b9-b6f2-091898b6732e/i);
  assert.match(html, /type=["']text\/plain["'][^>]+data-cookieconsent=["']statistics["']/i);
  assert.match(html, /consent\.method\s*!==\s*["']explicit["']/i);
  assert.match(html, /cookie_expires:\s*15552000/i);
  assert.doesNotMatch(html, /<script[^>]+src=["']https:\/\/www\.googletagmanager\.com\/gtag\/js/i);
  assert.doesNotMatch(html, /id=["']CookieDeclaration["']/i);
  assert.doesNotMatch(html, /class=["'][^"']*analytics-consent/i);
  assert.match(html, /instagram\.com\/hangulsori_learnkorean/i);
  assert.match(html, /social\/sori-check-01\.png/i);
  assert.match(html, /href=["']#tester-access["']/i);
  assert.match(html, /name=["']platform["']/i);
  assert.match(html, /name=["']focus["']/i);
  assert.match(html, /name=["']privacyAcknowledged["']/i);
  assert.match(html, /Send test application/i);
  assert.doesNotMatch(html, /mailto:[^"']*Testzugang/i);
  assert.doesNotMatch(html, /<button[^>]*class=["'][^"']*tester-submit[^"']*["'][^>]*disabled/i);
});

test("provides an accurate first-party consent panel with equal choices", async () => {
  const source = await import("node:fs/promises").then(({ readFile }) =>
    readFile(new URL("../app/privacy-consent-panel.tsx", import.meta.url), "utf8"),
  );
  assert.match(source, /Du entscheidest über Statistik/i);
  assert.match(source, /Nur notwendige/i);
  assert.match(source, /Statistik erlauben/i);
  assert.match(source, /submitCustomConsent\(false, nextStatistics, false\)/i);
  assert.match(source, /save\(true\)/i);
  assert.match(source, /runScripts/i);
  assert.doesNotMatch(source, /type="checkbox"/i);
  assert.doesNotMatch(source, /ads personalisation|social media partners/i);
});

test("adds production-only CSP and HSTS headers", async () => {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("security-headers", `${process.pid}-${Date.now()}`);
  const { default: worker } = await import(workerUrl.href);
  const response = await worker.fetch(
    new Request("https://www.hangul-sori.com/de", { headers: { accept: "text/html" } }),
    { ASSETS: { fetch: async () => new Response("Not found", { status: 404 }) } },
    { waitUntil() {}, passThroughOnException() {} },
  );

  assert.equal(response.status, 200);
  const csp = response.headers.get("content-security-policy") ?? "";
  assert.match(csp, /consent\.cookiebot\.com/);
  assert.match(csp, /frame-ancestors 'none'/);
  assert.match(csp, /script-src 'nonce-[^']+' 'strict-dynamic'/);
  assert.doesNotMatch(csp, /script-src[^;]*'unsafe-inline'/);
  assert.match(response.headers.get("strict-transport-security") ?? "", /max-age=63072000/);
  assert.match(response.headers.get("permissions-policy") ?? "", /camera=\(\)/);
  const html = await response.text();
  assert.doesNotMatch(html, /<script(?![^>]*\snonce=)/i);
});

test("validates and emails a tester application without storing it", async () => {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("tester-api", `${process.pid}-${Date.now()}`);
  const { default: worker } = await import(workerUrl.href);
  const sent = [];
  const env = {
    ASSETS: { fetch: async () => new Response("Not found", { status: 404 }) },
    TESTER_EMAIL: { send: async (message) => sent.push(message) },
    TESTER_RATE_LIMIT: { limit: async () => ({ success: true }) },
  };
  const payload = {
    locale: "de",
    name: "Test Person",
    email: "tester@example.com",
    platform: "android",
    device: "Pixel 8",
    osVersion: "Android 15",
    explanationLanguage: "de",
    koreanLevel: "hangul-learning",
    focus: ["hangul-reading", "pronunciation-listening"],
    notes: "I can test the first lessons.",
    ageConfirmed: true,
    commitment: true,
    privacyAcknowledged: true,
    website: "",
  };

  const response = await worker.fetch(
    new Request("http://localhost/api/tester-application", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "origin": "http://localhost",
        "x-hangul-sori-form": "tester-application",
      },
      body: JSON.stringify(payload),
    }),
    env,
    { waitUntil() {}, passThroughOnException() {} },
  );

  assert.equal(response.status, 201);
  assert.deepEqual(await response.json(), { ok: true });
  assert.equal(sent.length, 1);
  assert.equal(sent[0].to, "vjinny2@gmail.com");
  assert.equal(sent[0].replyTo, "tester@example.com");
  assert.match(sent[0].subject, /Android · DE/);
  assert.match(sent[0].text, /Pixel 8/);

  const rejected = await worker.fetch(
    new Request("http://localhost/api/tester-application", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "origin": "http://localhost",
        "x-hangul-sori-form": "tester-application",
      },
      body: JSON.stringify({ ...payload, privacyAcknowledged: false }),
    }),
    env,
    { waitUntil() {}, passThroughOnException() {} },
  );
  assert.equal(rejected.status, 400);
  assert.equal(sent.length, 1);
});

test("rejects tester submissions without a same-origin browser request", async () => {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("tester-csrf", `${process.pid}-${Date.now()}`);
  const { default: worker } = await import(workerUrl.href);
  const sent = [];
  const response = await worker.fetch(
    new Request("https://www.hangul-sori.com/api/tester-application", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-hangul-sori-form": "tester-application",
      },
      body: JSON.stringify({}),
    }),
    {
      ASSETS: { fetch: async () => new Response("Not found", { status: 404 }) },
      TESTER_EMAIL: { send: async (message) => sent.push(message) },
    },
    { waitUntil() {}, passThroughOnException() {} },
  );

  assert.equal(response.status, 403);
  assert.equal(sent.length, 0);
});

test("renders every public route with the expected launch content", async () => {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("routes", `${process.pid}-${Date.now()}`);
  const { default: worker } = await import(workerUrl.href);
  const routes = new Map([
    ["/de", "Lerne Koreanisch und baue deinen eigenen Hanok"],
    ["/en", "Learn Korean and build your own hanok"],
    ["/ko", "한국어를 배우며 나만의 한옥을 지어요"],
    ["/features", "Alle Funktionen"],
    ["/support", "Direkter Kontakt"],
    ["/privacy", "Einwilligungsverwaltung mit Cookiebot"],
    ["/terms", "Kostenloser Start"],
    ["/account-deletion", "Konto direkt in der App löschen"],
    ["/impressum", "Anbieterkennzeichnung"],
    ["/press", "Hangul Sori in Kürze"],
  ]);

  for (const [path, expected] of routes) {
    const response = await worker.fetch(
      new Request(`http://localhost${path}`, { headers: { accept: "text/html" } }),
      { ASSETS: { fetch: async () => new Response("Not found", { status: 404 }) } },
      { waitUntil() {}, passThroughOnException() {} },
    );
    assert.equal(response.status, 200, `${path} should render`);
    const html = await response.text();
    assert.match(html, new RegExp(expected, "i"), `${path} should contain its primary content`);
    if (path === "/impressum") {
      assert.match(html, /Kurfürstenstraße 14/i);
      assert.match(html, /60486 Frankfurt am Main/i);
      assert.doesNotMatch(html, /Launch-Blocker|Platzhalter/i);
    }
  }
});
