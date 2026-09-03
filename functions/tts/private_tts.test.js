"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");
const path = require("node:path");
const { cacheKey } = require("./tts_contract");

const AUDIO = Buffer.concat([Buffer.from("ID3"), Buffer.alloc(80, 7)]);
const PERSONAL = "개인용 비공개 예문 7193";
function harness({ duringSynthesis, duringSave, duringMetadata } = {}) {
  const documents = new Map([["service_cost_controls/ai_v1", {
    schemaVersion: 1, approvedBy: "Jin", approvalRef: "local-test-only", approvedAt: new Date(0),
    dailyUnitLimit: 10000, bookReservationUnits: 10, pronunciationReservationUnits: 2, ttsReservationUnits: 3,
  }]]);
  const objects = new Map();
  const reads = [];
  const writes = [];
  let syntheses = 0;
  const ref = (p) => ({ path: p, get: async () => snap(p),
    set: async (value) => documents.set(p, value) });
  const snap = (p) => ({ exists: documents.has(p), data: () => documents.get(p) });
  let tail = Promise.resolve();
  const db = { collection: (p) => ({ doc: (id) => ref(`${p}/${id}`) }),
    runTransaction: (run) => {
      const pending = tail.then(async () => {
        const mutations = [];
        const result = await run({get: async (r) => {
          assert.equal(mutations.length, 0, "Firestore requires reads before writes");
          return snap(r.path);
        }, set: (r, v) => mutations.push([r.path, v]), delete: (r) => mutations.push([r.path, null])});
        for (const [p, v] of mutations) { if (v === null) documents.delete(p); else documents.set(p, v); }
        return result;
      });
      tail = pending.catch(() => {});
      return pending;
    } };
  const bucket = { file: (p) => ({
    exists: async () => [objects.has(p)],
    getMetadata: async () => {
      if (duringMetadata) await duringMetadata({ documents, objects });
      return [objects.get(p)?.metadata || {}];
    },
    download: async () => { reads.push(p); return [objects.get(p).bytes]; },
    save: async (bytes, options) => {
      writes.push({ path: p, options });
      objects.set(p, { bytes, metadata: options.metadata });
      if (duringSave) await duringSave({ documents, objects });
    },
    delete: async () => objects.delete(p),
  }) };
  class HttpsError extends Error { constructor(code, message) { super(message); this.code = code; } }
  const exports = {};
  const guard = require("./tts_request_guard");
  const mocks = {
    "firebase-functions/v2/https": { HttpsError, onCall: (_options, handler) => handler },
    "firebase-functions/v2": { setGlobalOptions() {} },
    "firebase-admin": { initializeApp() {}, firestore: () => db,
      storage: () => ({ bucket: () => bucket }) },
    "@google-cloud/text-to-speech": { TextToSpeechClient: class {
      async synthesizeSpeech() {
        syntheses += 1;
        if (duringSynthesis) await duringSynthesis({ documents, objects });
        return [{ audioContent: AUDIO }];
      }
    } },
    "./tts_request_guard": { ...guard, ttsProviderBreaker: new guard.CircuitBreaker() },
  };
  vm.runInNewContext(fs.readFileSync(path.join(__dirname, "index.js"), "utf8"), {
    require: (name) => mocks[name] || require(name), exports, Buffer, console,
    setTimeout, clearTimeout,
  }, { filename: "tts/index.js" });
  return { documents, objects, reads, writes, syntheses: () => syntheses,
    invoke: (uid = "alice", data = {}) => exports.synthesize_tts({
      auth: { uid }, data: { text: PERSONAL, voice: "female", ...data },
    }) };
}

test("caller flags cannot publish personal audio, and UIDs never share its cache", async () => {
  const h = harness();
  const response = await h.invoke("alice", { canonical: true, scope: "public", storagePath: "tts/v3/female/forced.mp3" });
  assert.equal(response.audioBase64, AUDIO.toString("base64"));
  assert.match(h.writes[0].path, /^tts_private\/alice\/v3\/female\/[a-f0-9]{40}\.mp3$/);
  assert.equal(h.writes[0].options.metadata.cacheControl, "private, no-store");
  assert.equal(h.writes[0].options.metadata.metadata.firebaseStorageDownloadTokens, undefined);
  await h.invoke("bob");
  assert.equal(h.syntheses(), 2);
  assert.match(h.writes[1].path, /^tts_private\/bob\//);
});

test("private response exposes only cache policy metadata, never text or object address", async () => {
  const h = harness();
  const response = await h.invoke();
  assert.equal(response.cacheScope, "private");
  assert.equal(typeof response.expiresAtMillis, "number");
  assert.equal(JSON.stringify(response).includes(PERSONAL), false);
  assert.equal("storagePath" in response, false);
});

test("unknown legacy public objects are never downloaded for private text", async () => {
  const h = harness();
  const legacy = cacheKey("female", PERSONAL).storagePath;
  h.objects.set(legacy, { bytes: AUDIO });
  await h.invoke();
  assert.equal(h.reads.includes(legacy), false);
  assert.equal(h.syntheses(), 1);
});

test("expired private bytes are never replayed after the 24-hour boundary", async () => {
  const h = harness();
  const key = cacheKey("female", PERSONAL);
  const privatePath = `tts_private/alice/v3/female/${key.hash}.mp3`;
  h.objects.set(privatePath, { bytes: AUDIO, metadata: { metadata: {
    expiresAtMillis: String(Date.now() - 1),
  } } });
  await h.invoke();
  assert.equal(h.reads.includes(privatePath), false);
  assert.equal(h.syntheses(), 1);
  assert.ok(Number(h.writes[0].options.metadata.metadata.expiresAtMillis) <= Date.now() + 86400000);
});

test("canonical corpus preserves the existing v3 voice/hash path", async () => {
  const h = harness();
  const canonical = "tts/v3/female/cad639c2539393f15c209d28e6fafca1a5b2f1fa.mp3";
  h.objects.set(canonical, { bytes: AUDIO });
  await h.invoke("alice", { text: "아", voice: "female" });
  assert.deepEqual(h.reads, [canonical]);
  assert.equal(h.syntheses(), 0);
});

test("missing or zero global approved budget blocks new TTS but not canonical cache", async () => {
  for (const cap of [null, 0]) {
    const h = harness();
    if (cap === null) h.documents.delete("service_cost_controls/ai_v1");
    else h.documents.get("service_cost_controls/ai_v1").dailyUnitLimit = cap;
    await assert.rejects(h.invoke(), (e) => ["resource-exhausted", "unavailable"].includes(e.code));
    assert.equal(h.syntheses(), 0);
    h.objects.set("tts/v3/female/cad639c2539393f15c209d28e6fafca1a5b2f1fa.mp3", {bytes: AUDIO});
    assert.equal((await h.invoke("alice", {text: "아", voice: "female"})).cacheScope, "canonical");
    assert.equal(h.syntheses(), 0);
  }
});

test("TTS concurrent different accounts share one remaining service-cost slot", async () => {
  const h = harness();
  h.documents.get("service_cost_controls/ai_v1").dailyUnitLimit = 3;
  const results = await Promise.allSettled(Array.from({length: 10}, (_, i) => h.invoke(`account-${i}`)));
  assert.equal(results.filter((r) => r.status === "fulfilled").length, 1);
  assert.equal(h.syntheses(), 1);
  assert.equal(h.documents.get(`service_cost_ledgers/${new Date().toISOString().slice(0, 10)}`).reservedUnits, 3);
});

test("definite budget denial releases undispatched TTS claim without quota mutation", async () => {
  const h = harness();
  h.documents.get("service_cost_controls/ai_v1").dailyUnitLimit = 0;
  await assert.rejects(h.invoke(), {code: "resource-exhausted"});
  assert.equal([...h.documents.keys()].some((key) => key.startsWith("service_idempotency/")), false);
  assert.equal([...h.documents.keys()].some((key) => key.startsWith("usage/")), false);
  h.documents.get("service_cost_controls/ai_v1").dailyUnitLimit = 3;
  assert.equal((await h.invoke()).cacheScope, "private");
  assert.equal(h.syntheses(), 1);
});

test("uncertain TTS retains cost reservation and cannot retry past whole service cap", async () => {
  const h = harness({duringSynthesis: async () => { throw new Error("unknown provider outcome"); }});
  h.documents.get("service_cost_controls/ai_v1").dailyUnitLimit = 3;
  await assert.rejects(h.invoke());
  await assert.rejects(h.invoke(), {code: "resource-exhausted"});
  assert.equal(h.syntheses(), 1);
});

test("TTS cached private response remains available while service spending is paused", async () => {
  const h = harness();
  await h.invoke();
  h.documents.delete("service_cost_controls/ai_v1");
  assert.equal((await h.invoke()).cacheScope, "private");
  assert.equal(h.syntheses(), 1);
});

test("deletion during synthesis fences the final private write", async () => {
  const h = harness({ duringSynthesis: ({ documents }) =>
    documents.set("account_deletions/alice", { state: "active" }) });
  await assert.rejects(h.invoke(), { code: "failed-precondition" });
  assert.equal(h.writes.length, 0);
});

test("deletion racing a save removes the new object and never returns its bytes", async () => {
  const h = harness({ duringSave: ({ documents }) =>
    documents.set("account_deletions/alice", { state: "active" }) });
  await assert.rejects(h.invoke(), { code: "failed-precondition" });
  assert.equal(h.objects.size, 0);
});

test("deletion during the final metadata read cannot escape the response fence", async () => {
  const h = harness({ duringMetadata: ({ documents }) =>
    documents.set("account_deletions/alice", { state: "active" }) });
  await assert.rejects(h.invoke(), { code: "failed-precondition" });
  assert.equal(h.objects.size, 0);
});
