"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");
const path = require("node:path");
const { cacheKey } = require("./tts_contract");

const AUDIO = Buffer.concat([Buffer.from("ID3"), Buffer.alloc(80, 7)]);
const PERSONAL = "개인용 비공개 예문 7193";

function assertSafeDiagnostic(logs, stage, code) {
  assert.equal(logs.length, 1);
  assert.equal(logs[0].length, 2);
  assert.equal(logs[0][0], "synthesize_tts error");
  assert.equal(logs[0][1].stage, stage);
  assert.equal(logs[0][1].code, code);
  assert.deepEqual(Object.keys(logs[0][1]).sort(), ["code", "stage"]);
}

function harness({
  duringSynthesis,
  duringSave,
  duringMetadata,
  duringAccountRead,
  duringStorageRead,
} = {}) {
  const documents = new Map([["service_cost_controls/ai_v1", {
    schemaVersion: 1, approvedBy: "Jin", approvalRef: "local-test-only", approvedAt: new Date(0),
    dailyUnitLimit: 10000, bookReservationUnits: 10, pronunciationReservationUnits: 2, ttsReservationUnits: 3,
  }]]);
  const objects = new Map();
  const reads = [];
  const writes = [];
  const logs = [];
  let syntheses = 0;
  const ref = (p) => ({ path: p, get: async () => {
    if (p.startsWith("account_deletions/") && duringAccountRead) await duringAccountRead();
    return snap(p);
  },
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
    exists: async () => {
      if (duringStorageRead) await duringStorageRead({ documents, objects });
      return [objects.has(p)];
    },
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
    require: (name) => mocks[name] || require(name), exports, Buffer, Date,
    console: { ...console, error: (...args) => logs.push(args), warn: (...args) => logs.push(args) },
    setTimeout, clearTimeout,
  }, { filename: "tts/index.js" });
  return { documents, objects, reads, writes, logs, syntheses: () => syntheses,
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
  assert.equal(typeof response.serverNowMillis, "number");
  assert.ok(response.expiresAtMillis > response.serverNowMillis);
  assert.ok(response.expiresAtMillis - response.serverNowMillis <= 86400000);
  assert.equal(JSON.stringify(response).includes(PERSONAL), false);
  assert.equal("storagePath" in response, false);
});

test("private cache hits return fresh server time without extending object expiry", async (t) => {
  let now = Date.now();
  t.mock.method(Date, "now", () => now);
  const h = harness();
  const first = await h.invoke("alice", {serverNowMillis: 0, expiresAtMillis: Number.MAX_SAFE_INTEGER});
  now += 86340000;
  const cached = await h.invoke();
  assert.equal(cached.expiresAtMillis, first.expiresAtMillis);
  assert.equal(cached.serverNowMillis, now);
  assert.equal(cached.expiresAtMillis - cached.serverNowMillis, 60000);
  assert.equal(h.syntheses(), 1);
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
  assertSafeDiagnostic(h.logs, "provider", "internal");
});

test("unexpected provider failure logs only its fixed stage and allowlisted code", async () => {
  const h = harness({duringSynthesis: async () => {
    throw Object.assign(new Error("PRIVATE_CANARY_7193"), {code: 7});
  }});

  await assert.rejects(h.invoke(), {code: "internal"});

  const serialized = JSON.stringify(h.logs);
  assert.equal(serialized.includes("PRIVATE_CANARY_7193"), false);
  assert.equal(serialized.includes(PERSONAL), false);
  assertSafeDiagnostic(h.logs, "provider", "permission-denied");
});

test("unexpected account, cache-read, and cache-save failures have distinct safe stages", async () => {
  const account = harness({duringAccountRead: async () => {
    throw Object.assign(new Error("ACCOUNT_PRIVATE_CANARY"), {code: 14});
  }});
  await assert.rejects(account.invoke(), {code: "internal"});
  assertSafeDiagnostic(account.logs, "account", "unavailable");

  const cacheRead = harness({duringStorageRead: async () => {
    throw Object.assign(new Error("CACHE_READ_PRIVATE_CANARY"), {code: 13});
  }});
  await assert.rejects(cacheRead.invoke(), {code: "internal"});
  assertSafeDiagnostic(cacheRead.logs, "cache_read", "internal");

  const cacheMetadata = harness({duringMetadata: async () => {
    throw Object.assign(new Error("CACHE_METADATA_PRIVATE_CANARY"), {code: 14});
  }});
  await assert.rejects(cacheMetadata.invoke(), {code: "internal"});
  assertSafeDiagnostic(cacheMetadata.logs, "cache_read", "unavailable");

  const cacheSave = harness({duringSave: async () => {
    throw Object.assign(new Error("CACHE_SAVE_PRIVATE_CANARY"), {code: 8});
  }});
  await assert.rejects(cacheSave.invoke(), {code: "internal"});
  assertSafeDiagnostic(cacheSave.logs, "cache_save", "resource-exhausted");

  const serialized = JSON.stringify([
    account.logs,
    cacheRead.logs,
    cacheMetadata.logs,
    cacheSave.logs,
  ]);
  assert.equal(serialized.includes("PRIVATE_CANARY"), false);
  assert.equal(serialized.includes(PERSONAL), false);
});

test("success and expected callable errors do not emit unexpected-error diagnostics", async () => {
  const success = harness();
  await success.invoke();
  assert.deepEqual(success.logs, []);

  const expected = harness();
  expected.documents.get("service_cost_controls/ai_v1").dailyUnitLimit = 0;
  await assert.rejects(expected.invoke(), {code: "resource-exhausted"});
  assert.equal(
    expected.logs.some(([message]) => message === "synthesize_tts error"),
    false,
  );
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

test("expiry crossed during final account read never returns private bytes", async (t) => {
  let now = Date.now();
  t.mock.method(Date, "now", () => now);
  let finalMetadataRead = false;
  const h = harness({
    duringMetadata: () => { finalMetadataRead = true; },
    duringAccountRead: () => {
      if (finalMetadataRead) now += 86400000;
    },
  });
  await assert.rejects(h.invoke(), { code: "unavailable" });
  assert.equal(h.objects.size, 0);
});
