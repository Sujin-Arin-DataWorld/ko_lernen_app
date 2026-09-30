import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import vm from "node:vm";
import test from "node:test";

const source = readFileSync(new URL("../app/cookiebot.tsx", import.meta.url), "utf8");
const script = source.match(/const analyticsScript = `([\s\S]*?)`;/)[1]
  .replaceAll("${GOOGLE_ANALYTICS_ID}", "G-6R9J2N1PCC");
const cleanup = source.match(/const consentCleanupScript = `([\s\S]*?)`;/)[1]
  .replaceAll("${GOOGLE_ANALYTICS_ID}", "G-6R9J2N1PCC");

function harness(consent = { method: "explicit", statistics: true }) {
  const listeners = new Map();
  const scripts = [];
  let reloads = 0;
  const location = { origin: "https://hangul-sori.com", pathname: "/en",
    search: "?token=do-not-send", hash: "#private", reload: () => {reloads++;} };
  const document = { title: "English home", referrer: "https://search.example/search?q=private",
    createElement: () => ({}), head: { appendChild: (tag) => scripts.push(tag) } };
  const window = { location, Cookiebot: { hasResponse: true, consent },
    addEventListener: (name, fn) => listeners.set(name, fn) };
  const context = vm.createContext({ window, document, URL, Date });
  Object.defineProperty(context, "dataLayer", { get: () => window.dataLayer });
  const run = () => vm.runInContext(script, context);
  const runCleanup = () => vm.runInContext(cleanup, context);
  const navigate = (path, title = "Next page") => {
    location.pathname = path; document.title = title;
    listeners.get("hangul-sori:page-view")?.();
  };
  const commands = () => Array.from(window.dataLayer || [], (v) => Array.from(v));
  const views = () => commands().filter(([type, name]) => type === "event" && name === "page_view");
  const restore = (persisted = true) => listeners.get("pageshow")?.({persisted});
  return { window, document, scripts, run, runCleanup, navigate, restore, commands, views,
    get reloads() {return reloads;} };
}

test("denied, unanswered or implied consent makes no Google script or commands", () => {
  for (const consent of [undefined, {method: "explicit", statistics: false}, {method: "implied", statistics: true}]) {
    const h = harness(); h.window.Cookiebot.consent = consent; h.run();
    assert.equal(h.scripts.length, 0); assert.equal(h.commands().length, 0);
  }
  const h = harness(); h.window.Cookiebot.hasResponse = false; h.run();
  assert.equal(h.scripts.length, 0); assert.equal(h.commands().length, 0);
});

test("opt-in initializes once, disables config pageview and sends current page once", () => {
  const h = harness(); h.run(); h.run(); h.navigate("/en");
  assert.equal(h.scripts.length, 1);
  const configs = h.commands().filter(([type]) => type === "config");
  assert.equal(configs.length, 1); assert.equal(configs[0][1], "G-6R9J2N1PCC");
  assert.equal(configs[0][2].send_page_view, false);
  assert.equal(h.views().length, 1);
  assert.equal(h.views()[0][2].page_location, "https://hangul-sori.com/en");
});

test("language transitions and back/forward get one view per visit with previous page", () => {
  const h = harness(); h.run();
  h.navigate("/ko", "Korean home"); h.navigate("/ko", "Korean home");
  h.navigate("/de"); h.navigate("/ko");
  assert.deepEqual(h.views().map((v) => v[2].page_location),
    ["/en", "/ko", "/de", "/ko"].map((p) => "https://hangul-sori.com" + p));
  assert.equal(h.views()[1][2].page_referrer, "https://hangul-sori.com/en");
  assert.equal(h.views()[1][2].page_title, "Korean home");
});

test("consent granted after navigation records only the currently visible page", () => {
  const h = harness({method: "explicit", statistics: false}); h.run();
  h.navigate("/ko"); h.window.Cookiebot.consent.statistics = true; h.run();
  assert.equal(h.views().length, 1);
  assert.equal(h.views()[0][2].page_location, "https://hangul-sori.com/ko");
});

test("withdrawal stops pageview sends even before the reload completes", () => {
  const h = harness(); h.run(); h.window.Cookiebot.consent.statistics = false;
  h.navigate("/ko"); assert.equal(h.views().length, 1);
  h.window.Cookiebot.consent = undefined;
  assert.doesNotThrow(() => h.navigate("/de"));
  assert.equal(h.views().length, 1);
});

test("an unknown initial route does not load Google or send automatic metadata", () => {
  const h = harness(); h.navigate("/not-a-public-route/private"); h.run();
  assert.equal(h.scripts.length, 0); assert.equal(h.commands().length, 0);
});

test("URLs omit queries/fragments, unknown paths and full external referrers", () => {
  const h = harness(); h.run(); h.navigate("/account-deletion");
  h.navigate("/private-user/secret");
  assert.equal(h.views().length, 2);
  assert.equal(h.views()[0][2].page_referrer, "https://search.example");
  assert.doesNotMatch(JSON.stringify(h.commands()), /do-not-send|#private|q=private|private-user/);
});

test("advertising stays denied while statistics is explicitly granted", () => {
  const h = harness(); h.run();
  const consent = h.commands().find(([type]) => type === "consent")[2];
  assert.equal(consent.analytics_storage, "granted");
  for (const key of ["ad_storage", "ad_user_data", "ad_personalization"]) assert.equal(consent[key], "denied");
});

test("bfcache restoration revalidates consent even when cached consent is stale", () => {
  for (const statistics of [true, false]) {
    const h = harness({method: "explicit", statistics}); h.runCleanup(); h.run();
    const before = h.views().length; h.restore(false);
    assert.equal(h.reloads, 0);
    h.restore();
    assert.equal(h.reloads, 1);
    assert.equal(h.window["ga-disable-G-6R9J2N1PCC"], true);
    assert.equal(h.views().length, before);
  }
  const freshDenied = harness({method: "explicit", statistics: false});
  freshDenied.runCleanup(); freshDenied.run();
  assert.equal(freshDenied.views().length, 0);
  const freshAllowed = harness(); freshAllowed.runCleanup(); freshAllowed.run();
  assert.equal(freshAllowed.views().length, 1);
});

test("returning from an excluded route counts a new public visit", () => {
  const h = harness(); h.run(); h.navigate("/private-user/secret"); h.navigate("/en");
  assert.equal(h.views().length, 2);
  assert.doesNotMatch(JSON.stringify(h.commands()), /private-user|secret/);
});

test("initially excluded route can enter a public route without reloading", () => {
  const h = harness(); h.navigate("/unknown/private"); h.run(); h.run();
  assert.equal(h.scripts.length, 0);
  h.navigate("/ko"); h.navigate("/ko");
  assert.equal(h.scripts.length, 1); assert.equal(h.views().length, 1);
  assert.equal(h.views()[0][2].page_location, "https://hangul-sori.com/ko");
});

test("implicit event metadata uses current route at config-over-set precedence", () => {
  const h = harness(); h.run(); h.navigate("/ko", "Korean home");
  const global = {}; const config = {};
  for (const [command, fields, options] of h.commands()) {
    if (command === "set" && typeof fields === "object") Object.assign(global, fields);
    if (command === "config") {
      assert.equal(global.page_location, "https://hangul-sori.com/en");
      assert.doesNotMatch(JSON.stringify(global), /do-not-send|#private|q=private/);
      Object.assign(config, options);
    }
  }
  const implicit = {...global, ...config};
  assert.equal(implicit.page_location, "https://hangul-sori.com/ko");
  assert.equal(implicit.page_title, "Korean home");
  assert.equal(implicit.page_referrer, "https://hangul-sori.com/en");
});
