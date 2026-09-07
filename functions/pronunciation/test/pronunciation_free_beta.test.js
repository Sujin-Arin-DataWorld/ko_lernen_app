"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const guard = require("../pronunciation_request_guard");
const {resolvePronunciationPolicy} = require("../ai_policy");
const {FREE_TIER_DAILY_ASSESSMENTS, FREE_MONTHLY_AUDIO_SECONDS, PCM_BYTES_PER_SECOND} = require("../pronunciation_free_tier");

const MONTHLY_LIMIT = 5 * 60 * 60;
const usagePath = "service_usage/pronunciation_free_2026-09";
const scores = {
  PronScore: 82, AccuracyScore: 83, FluencyScore: 80, CompletenessScore: 100,
};

function request(id = "recording-12345678", seconds = 10, uid = "learner-1") {
  return {
    auth: {uid}, app: {appId: "beta-app"},
    data: {
      audioBase64: Buffer.alloc(seconds * 32000).toString("base64"),
      referenceText: "안녕하세요", assessmentId: id,
    },
  };
}

function harness({mode, seed = [], provider, now = "2026-09-03T12:00:00Z"} = {}) {
  const records = new Map([["service_cost_controls/ai_v1", {
    schemaVersion: 1, approvedBy: "Jin", approvalRef: "local-test-only", approvedAt: new Date(0),
    dailyUnitLimit: 10000, bookReservationUnits: 10, pronunciationReservationUnits: 2, ttsReservationUnits: 3,
  }], ...seed]);
  const calls = {auth: 0, database: 0, reads: 0, writes: 0, provider: 0, secret: 0};
  let transactionTail = Promise.resolve();
  const document = (documentPath) => ({
    path: documentPath,
    collection: (name) => collection(`${documentPath}/${name}`),
    set: async (value) => { calls.writes++; records.set(documentPath, value); },
  });
  const collection = (collectionPath) => ({
    doc: (name) => document(`${collectionPath}/${name}`),
  });
  const db = {
    collection,
    runTransaction(callback) {
      const result = transactionTail.then(async () => {
        const updates = [];
        let written = false;
        const value = await callback({
          get: async (ref) => {
            assert.equal(written, false, "Firestore requires reads before writes");
            calls.reads++;
            return {exists: records.has(ref.path), data: () => records.get(ref.path)};
          },
          set: (ref, data) => { written = true; updates.push(() => records.set(ref.path, data)); },
          delete: (ref) => { written = true; updates.push(() => records.delete(ref.path)); },
        });
        for (const update of updates) { calls.writes++; update(); }
        return value;
      });
      transactionTail = result.catch(() => {});
      return result;
    },
  };
  class HttpsError extends Error {
    constructor(code, message, details) { super(message); this.code = code; this.details = details; }
  }
  class ClockDate extends Date {
    constructor(...args) { super(...(args.length ? args : [now])); }
    static now() { return Date.parse(now); }
  }
  const moduleStub = {exports: {}};
  const context = {
    module: moduleStub, exports: moduleStub.exports, Buffer, URL,
    Date: ClockDate, AbortController, setTimeout, clearTimeout,
    process: {env: mode == null ? {} : {PRONUNCIATION_ASSESSMENT_MODE: mode}},
    fetch: async (...args) => {
      calls.provider++;
      return provider ? provider(...args) : {
        ok: true,
        json: async () => ({RecognitionStatus: "Success", NBest: [scores]}),
      };
    },
    require(name) {
      if (name === "firebase-admin/app") {
        return {initializeApp() {}};
      }
      if (name === "firebase-admin/auth") {
        return {getAuth: () => { calls.auth++; return {getUser: async (uid) => ({uid,
          disabled: false, metadata: {creationTime: new Date(0).toISOString()}})}; }};
      }
      if (name === "firebase-admin/firestore") {
        return {
          getFirestore: () => { calls.database++; return db; },
          FieldValue: {serverTimestamp: () => new ClockDate()},
        };
      }
      if (name === "firebase-functions/v2/https") {
        return {
          HttpsError,
          onCall: (options, handler) => Object.assign(handler, {options}),
        };
      }
      if (name === "firebase-functions/params") {
        return {
          defineSecret: () => ({value: () => { calls.secret++; return "test-secret"; }}),
        };
      }
      if (name === "./pronunciation_request_guard") {
        return {...guard, pronunciationProviderBreaker: new guard.CircuitBreaker()};
      }
      if (name === "./billable_receipts") {
        const {PronunciationReceipts} = require("../billable_receipts");
        return {PronunciationReceipts: class extends PronunciationReceipts {
          constructor(database) { super(database, {now: () => new ClockDate()}); }
        }};
      }
      if (name === "./service_cost_policy") {
        return require("../service_cost_policy");
      }
      if (name === "./pronunciation_free_tier") {
        return require("../pronunciation_free_tier");
      }
      throw new Error(`Unexpected dependency: ${name}`);
    },
  };
  vm.runInNewContext(fs.readFileSync(path.join(__dirname, "..", "index.js"), "utf8"), context);
  return {assess: moduleStub.exports.assessPronunciation, calls, records};
}

test("default and paid modes perform no auth, database, secret, or provider work", async () => {
  for (const mode of [undefined, "disabled", "azure_s0", "true", "AZURE_F0"]) {
    const app = harness({mode});
    // Bound in every mode (CLI discovery cannot see the mode); calls.secret proves it is never read.
    assert.equal(app.assess.options.secrets.length, 1);
    await assert.rejects(app.assess(request()), (error) => error.code === "unavailable");
    assert.deepEqual(app.calls, {auth: 0, database: 0, reads: 0, writes: 0, provider: 0, secret: 0});
  }
});

test("free beta has no warm instances and serializes provider requests", () => {
  const {assess} = harness({mode: "azure_f0"});
  assert.equal(assess.options.secrets.length, 1);
  assert.equal(assess.options.minInstances, 0);
  assert.equal(assess.options.maxInstances, 1);
  assert.equal(assess.options.concurrency, 1);
});

test("free audio usage is shared across learners and rounded up to seconds", async () => {
  const app = harness({mode: "azure_f0"});
  await app.assess(request("recording-12345678", 1.25));
  await app.assess(request("recording-87654321", 2, "learner-2"));
  assert.equal(app.records.get(usagePath)?.audioSeconds, 4);
  assert.equal(app.calls.provider, 2);
  const usage = JSON.stringify(app.records.get(usagePath));
  assert.equal(usage.includes("learner"), false);
  assert.equal(usage.includes("안녕하세요"), false);
});

test("monthly free limit is reserved atomically before sending audio", async () => {
  const app = harness({mode: "azure_f0", seed: [[usagePath, {audioSeconds: MONTHLY_LIMIT - 10}]]});
  const attempts = await Promise.allSettled([
    app.assess(request("recording-12345678")),
    app.assess(request("recording-87654321", 10, "learner-2")),
  ]);
  assert.equal(attempts.filter((result) => result.status === "fulfilled").length, 1);
  const failure = attempts.find((result) => result.status === "rejected");
  assert.equal(failure.reason.code, "resource-exhausted");
  assert.equal(app.calls.provider, 1);
  assert.equal(app.records.get(usagePath).audioSeconds, MONTHLY_LIMIT);
});

test("a provider failure does not refund audio that may already have been billed", async () => {
  const app = harness({mode: "azure_f0", provider: async () => { throw new Error("timeout"); }});
  await assert.rejects(app.assess(request()), (error) => error.code === "unavailable");
  assert.equal(app.records.get(usagePath)?.audioSeconds, 10);
  assert.equal(app.records.get("users/learner-1/pronunciation_rate_limits/current").dayCount, 1);
  await assert.rejects(app.assess(request()), (error) => error.code === "unavailable");
  assert.equal(app.calls.provider, 1);
  assert.equal(app.records.get(usagePath).audioSeconds, 10);
});

test("a pending duplicate never sends the same recording twice", async () => {
  let finish;
  let started;
  let sent = false;
  const providerStarted = new Promise((resolve) => { started = resolve; });
  const app = harness({mode: "azure_f0", provider: () => {
    if (sent) {
      throw new Error("duplicate provider invocation");
    }
    sent = true;
    started();
    return new Promise((resolve) => { finish = resolve; });
  }});
  const first = app.assess(request());
  await providerStarted;
  const duplicate = app.assess(request());
  // The rejection must happen before the first provider response is released.
  await assert.rejects(duplicate, (error) => error.code === "aborted");
  finish({ok: true, json: async () => ({RecognitionStatus: "Success", NBest: [scores]})});
  await first;
  assert.equal(app.calls.provider, 1);
  assert.equal(app.records.get(usagePath).audioSeconds, 10);
  const replay = await app.assess(request());
  assert.equal(replay.pronunciationScore, 82);
  assert.equal(app.calls.provider, 1);
});

test("the next UTC month has a separate free audio allowance", async () => {
  const app = harness({mode: "azure_f0", now: "2026-10-01T00:00:00Z",
    seed: [[usagePath, {audioSeconds: MONTHLY_LIMIT}]],
  });
  await app.assess(request());
  assert.equal(app.records.get("service_usage/pronunciation_free_2026-10")?.audioSeconds, 10);
  assert.equal(app.records.get(usagePath).audioSeconds, MONTHLY_LIMIT);
});

test("malformed or already exhausted usage fails closed", async () => {
  for (const audioSeconds of [-1, "0", NaN, MONTHLY_LIMIT, MONTHLY_LIMIT + 1]) {
    const app = harness({mode: "azure_f0", seed: [[usagePath, {audioSeconds}]]});
    await assert.rejects(app.assess(request()), (error) => error.code === "resource-exhausted");
    assert.equal(app.calls.provider, 0);
    const receipt = [...app.records].find(([key]) => key.startsWith("service_idempotency/"))[1];
    assert.equal(receipt.state, "claimed", "failed reservation must not commit a dispatch marker");
  }
});

test("free beta caps each learner at eight scored assessments per UTC day", async () => {
  const policy = await resolvePronunciationPolicy(null, "learner-1", null, new Date("2026-09-03T12:00:00Z"));
  assert.deepEqual(policy, {minuteLimit: 5, dayLimit: 8});
});

test("one learner cannot consume more than a fifth of the shared monthly audio pool", () => {
  const worstCaseSecondsPerLearner = FREE_TIER_DAILY_ASSESSMENTS * Math.ceil(guard.MAX_PCM_BYTES / PCM_BYTES_PER_SECOND) * 31;
  assert.ok(worstCaseSecondsPerLearner <= FREE_MONTHLY_AUDIO_SECONDS / 5);
});
