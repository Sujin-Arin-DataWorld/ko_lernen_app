"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");
const path = require("node:path");

class MemoryFirestore {
  constructor() {
    this.store = new Map([["service_cost_controls/ai_v1", {
      schemaVersion: 1, approvedBy: "Jin", approvalRef: "local-test-only", approvedAt: new Date(0),
      dailyUnitLimit: 10000, bookReservationUnits: 10, pronunciationReservationUnits: 2, ttsReservationUnits: 3,
    }]]);
    this.tail = Promise.resolve(); this.outage = false; this.failCompleted = false;
  }
  collection(name) {
    return {doc: (id) => {
      const key = `${name}/${id}`;
      return {key, collection: (child) => this.collection(`${key}/${child}`),
        set: async (data) => this.store.set(key, data)};
    }};
  }
  runTransaction(fn) {
    const run = this.tail.then(async () => {
      if (this.outage) throw new Error("storage unavailable");
      const writes = [];
      let written = false;
      const result = await fn({
        get: async (ref) => {
          assert.equal(written, false, "Firestore requires reads before writes");
          return {exists: this.store.has(ref.key), data: () => this.store.get(ref.key)};
        },
        set: (ref, data) => { written = true; writes.push([ref.key, data]); },
        delete: (ref) => { written = true; writes.push([ref.key, undefined]); },
      });
      if (this.failCompleted && writes.some(([, data]) => data?.state === "completed")) throw new Error("save failed");
      for (const [key, data] of writes) { if (data === undefined) this.store.delete(key); else this.store.set(key, data); }
      return result;
    });
    this.tail = run.catch(() => {});
    return run;
  }
}

const azure = {RecognitionStatus: "Success", NBest: [{PronunciationAssessment: {
  PronScore: 90, AccuracyScore: 91, FluencyScore: 92, CompletenessScore: 93,
}}]};
function request(data = {}) {
  return {auth: {uid: "user-1"}, app: {appId: "app-1"}, data: {
    audioBase64: "AAECAw==", referenceText: "안녕하세요", assessmentId: "assessment-123", ...data,
  }};
}
function harness({providerTimeoutMs = 15000} = {}) {
  const db = new MemoryFirestore();
  const calls = [];
  let provider = async () => ({ok: true, json: async () => azure});
  class HttpsError extends Error { constructor(code, message, details) { super(message); this.code = code; this.details = details; } }
  const module = {exports: {}};
  const context = {module, exports: module.exports, Buffer, URL, Date, AbortController,
    setTimeout: (fn, delay) => setTimeout(fn, Math.min(delay, providerTimeoutMs)), clearTimeout,
    fetch: async (...args) => { calls.push(args); return provider(...args); },
    require: (name) => {
      if (name === "firebase-admin/app") return {initializeApp() {}};
      if (name === "firebase-admin/firestore") return {getFirestore: () => db, FieldValue: {serverTimestamp: () => "server-time"}};
      if (name === "firebase-functions/v2/https") return {HttpsError, onCall: (_options, handler) => handler};
      if (name === "firebase-functions/params") return {defineSecret: () => ({value: () => "test-only"})};
      return require(name.startsWith("./") ? path.join(__dirname, "..", name) : name);
    },
  };
  vm.runInNewContext(fs.readFileSync(path.join(__dirname, "..", "index.js"), "utf8"), context);
  require("../pronunciation_request_guard").pronunciationProviderBreaker.recordSuccess();
  return {db, calls, api: module.exports, run: module.exports.assessPronunciation, setProvider: (fn) => { provider = fn; }};
}

test("actual callable ten concurrent duplicates execute Azure once and reserve once", async () => {
  const h = harness();
  let release;
  const blocked = new Promise((resolve) => { release = resolve; });
  h.setProvider(async () => { await blocked; return {ok: true, json: async () => azure}; });
  const pending = Array.from({length: 10}, () => h.run(request()).catch((error) => error));
  await new Promise((resolve) => setTimeout(resolve, 30));
  release();
  const results = await Promise.all(pending);
  assert.equal(h.calls.length, 1);
  assert.equal(h.db.store.get("users/user-1/pronunciation_rate_limits/current").dayCount, 1);
  assert.equal(h.calls[0][0].hostname, "germanywestcentral.stt.speech.microsoft.com");
  assert.equal(results.filter((r) => r.code === "aborted").length, 9);
  assert.equal(results.filter((r) => r.pronunciationScore === 90).length, 1);
});

test("completed replay and payload mismatch never execute Azure again", async () => {
  const h = harness();
  const first = await h.run(request());
  assert.deepEqual(await h.run(request()), first);
  await assert.rejects(h.run(request({referenceText: "다른 내용"})), {code: "invalid-argument"});
  assert.equal(h.calls.length, 1);
});

test("storage outage and quota denial fail closed with no partial receipt", async () => {
  const h = harness();
  h.db.outage = true;
  await assert.rejects(h.run(request()), {code: "unavailable"});
  assert.equal(h.calls.length, 0);
  h.db.outage = false;
  const now = new Date().toISOString();
  h.db.store.set("users/user-1/pronunciation_rate_limits/current", {
    dayBucket: now.slice(0, 10), dayCount: 50, minuteBucket: now.slice(0, 16), minuteCount: 0,
  });
  await assert.rejects(h.run(request()), {code: "resource-exhausted"});
  assert.equal(h.calls.length, 0);
  assert.equal([...h.db.store.keys()].some((key) => key.startsWith("service_idempotency/")), false);
});

test("provider error retains uncertain reservation and blocks blind retry", async () => {
  const h = harness();
  h.setProvider(async () => { throw new Error("provider may have processed"); });
  await assert.rejects(h.run(request()), {code: "unavailable"});
  await assert.rejects(h.run(request()), (error) => error.code === "unavailable" && error.details.state === "uncertain");
  assert.equal(h.calls.length, 1);
  assert.equal(h.db.store.get("users/user-1/pronunciation_rate_limits/current").dayCount, 1);
});

test("provider success before receipt-save failure cannot dispatch a second time", async () => {
  const h = harness();
  h.db.failCompleted = true;
  await assert.rejects(h.run(request()), {code: "unavailable"});
  await assert.rejects(h.run(request()), {code: "unavailable"});
  assert.equal(h.calls.length, 1);
});

test("deletion fence denies completed replay", async () => {
  const h = harness();
  await h.run(request());
  h.db.store.set("account_deletions/user-1", {state: "pending"});
  await assert.rejects(h.run(request()), {code: "permission-denied"});
  assert.equal(h.calls.length, 1);
});

module.exports = {harness, request, azure, MemoryFirestore};

function seedDaily(h, dayCount) {
  const now = new Date().toISOString();
  h.db.store.set("users/user-1/pronunciation_rate_limits/current", {
    dayBucket: now.slice(0, 10), dayCount, minuteBucket: now.slice(0, 16), minuteCount: 0,
  });
}

function testerGrant(overrides = {}) {
  return {schemaVersion: 1, ownerUid: "user-1", environment: "PRODUCTION", revision: 1,
    kind: "closed_tester_lifetime", status: "active", approvedBy: "Jin", approvedAt: new Date(0),
    approvalRef: "local-test-roster", grantId: "local-test-grant", ...overrides};
}

test("free launch full content never elevates actual AI quota from five", async () => {
  const h = harness(); seedDaily(h, 5);
  await assert.rejects(h.run(request({tier: "premium", isPremium: true, FREE_LAUNCH: true,
    premiumGrant: testerGrant(), feedbackPassport: true, uid: "tester"})), {code: "resource-exhausted"});
  assert.equal(h.calls.length, 0);
});

test("consumed App Check token is rejected before authority IO or provider", async () => {
  const h = harness();
  await assert.rejects(h.run({...request(), app: {appId: "app-1", alreadyConsumed: true}}), {code: "failed-precondition"});
  assert.equal(h.calls.length, 0);
  assert.equal(h.db.store.size, 1);
});

test("server approved tester and verified subscription allow fifty, preserving usage", async () => {
  for (const source of ["tester", "subscription"]) {
    const h = harness(); seedDaily(h, 49);
    if (source === "tester") h.db.store.set("premium_grants/user-1", testerGrant());
    else h.db.store.set(`customer_entitlements/PRODUCTION_${require("node:crypto").createHash("sha256").update("user-1").digest("hex")}`, {
      schemaVersion: 1, ownerUid: "user-1", environment: "PRODUCTION", revision: 1,
      status: "active", providerCheckedAt: Date.now() - 1000, accessUntil: Date.now() + 60000,
    });
    await h.run(request());
    await assert.rejects(h.run(request({assessmentId: "next-request"})), {code: "resource-exhausted"});
    assert.equal(h.calls.length, 1);
    assert.equal(h.db.store.get("users/user-1/pronunciation_rate_limits/current").dayCount, 50);
  }
});

test("forged or mismatched server grant and stale subscription do not raise quota", async () => {
  for (const grant of [testerGrant({ownerUid: "another"}), testerGrant({environment: "SANDBOX"}),
    testerGrant({schemaVersion: 2}), testerGrant({status: "revoked"}), testerGrant({approvedAt: Date.now() + 100000})]) {
    const h = harness(); seedDaily(h, 5); h.db.store.set("premium_grants/user-1", grant);
    await assert.rejects(h.run(request()), {code: "resource-exhausted"});
    assert.equal(h.calls.length, 0);
  }
  const h = harness(); seedDaily(h, 5);
  h.db.store.set(`customer_entitlements/PRODUCTION_${require("node:crypto").createHash("sha256").update("user-1").digest("hex")}`, {
    schemaVersion: 1, ownerUid: "user-1", environment: "PRODUCTION", revision: 1, status: "active",
    providerCheckedAt: Date.now() - 4 * 86400000, accessUntil: Date.now() + 60000,
  });
  await assert.rejects(h.run(request()), {code: "resource-exhausted"});
  assert.equal(h.calls.length, 0);
});

test("tier transitions keep original same-UID UTC counts", async () => {
  const h = harness(); seedDaily(h, 5);
  h.db.store.set("premium_grants/user-1", testerGrant());
  await h.run(request());
  h.db.store.delete("premium_grants/user-1");
  await assert.rejects(h.run(request({assessmentId: "downgraded-request"})), {code: "resource-exhausted"});
  assert.equal(h.db.store.get("users/user-1/pronunciation_rate_limits/current").dayCount, 6);
});

test("missing, unapproved or zero service cap denies provider without quota writes", async () => {
  for (const change of [null, {approvedBy: "self"}, {dailyUnitLimit: 0}, {pronunciationReservationUnits: 0},
    {approvedAt: Date.now() + 60000}]) {
    const h = harness();
    if (change === null) h.db.store.delete("service_cost_controls/ai_v1");
    else h.db.store.set("service_cost_controls/ai_v1", {...h.db.store.get("service_cost_controls/ai_v1"), ...change});
    await assert.rejects(h.run(request()), (error) => ["unavailable", "resource-exhausted"].includes(error.code));
    assert.equal(h.calls.length, 0);
    assert.equal(h.db.store.has("users/user-1/pronunciation_rate_limits/current"), false);
  }
});

test("global cap atomic last slot across different UIDs, uncertain retains service units", async () => {
  const h = harness();
  h.db.store.set("service_cost_controls/ai_v1", {...h.db.store.get("service_cost_controls/ai_v1"), dailyUnitLimit: 2});
  h.setProvider(async () => { throw new Error("uncertain"); });
  const results = await Promise.allSettled(Array.from({length: 10}, (_, i) =>
    h.run({...request(), auth: {uid: `user-${i}`}})));
  assert.equal(h.calls.length, 1);
  assert.equal(results.filter((r) => r.reason?.code === "resource-exhausted").length, 9);
  assert.equal(h.db.store.get(`service_cost_ledgers/${new Date().toISOString().slice(0, 10)}`).reservedUnits, 2);
});

test("a lowered nonzero cost cap fences dispatch of an existing claim", async () => {
  const {PronunciationReceipts} = require("../billable_receipts");
  const {validatePronunciationRequest} = require("../pronunciation_request_guard");
  const db = new MemoryFirestore();
  const receipts = new PronunciationReceipts(db);
  const input = validatePronunciationRequest(request());
  const owner = await receipts.claim(input);
  db.store.get("service_cost_controls/ai_v1").dailyUnitLimit = 1;
  await assert.rejects(receipts.transition(input, owner.ownerToken, "pending"), {code: "resource-exhausted"});
  assert.equal(db.store.get(receipts.refs(input).receipt.key).state, "claimed");
});

test("expired pending cannot reclaim, settle, or refund another owner", async () => {
  const {PronunciationReceipts} = require("../billable_receipts");
  const {validatePronunciationRequest} = require("../pronunciation_request_guard");
  const db = new MemoryFirestore();
  let now = new Date("2026-09-03T10:00:00Z");
  const receipts = new PronunciationReceipts(db, {now: () => now});
  const input = validatePronunciationRequest(request());
  const owner = await receipts.claim(input);
  assert.equal(await receipts.transition(input, "wrong-owner", "pending"), false);
  assert.equal(await receipts.transition(input, owner.ownerToken, "pending"), true);
  now = new Date("2026-09-03T10:01:01Z");
  assert.equal((await receipts.claim(input)).state, "uncertain");
  assert.equal(await receipts.transition(input, owner.ownerToken, "completed", {assessmentId: input.assessmentId}), false);
  assert.equal(await receipts.transition(input, owner.ownerToken, "refunded"), false);
  assert.equal(db.store.get("users/user-1/pronunciation_rate_limits/current").dayCount, 1);
});

test("expired undispatched claim changes owner but reserves only once", async () => {
  const {PronunciationReceipts} = require("../billable_receipts");
  const {validatePronunciationRequest} = require("../pronunciation_request_guard");
  const db = new MemoryFirestore();
  let now = new Date("2026-09-03T10:00:00Z");
  const receipts = new PronunciationReceipts(db, {now: () => now});
  const input = validatePronunciationRequest(request());
  const old = await receipts.claim(input);
  now = new Date("2026-09-03T10:01:01Z");
  const current = await receipts.claim(input);
  assert.notEqual(current.ownerToken, old.ownerToken);
  assert.equal(await receipts.transition(input, old.ownerToken, "refunded"), false);
  assert.equal(await receipts.transition(input, current.ownerToken, "refunded"), true);
  assert.equal(await receipts.transition(input, current.ownerToken, "refunded"), false);
  assert.equal(db.store.get("users/user-1/pronunciation_rate_limits/current").dayCount, 0);
});

test("refund uses reservation buckets across UTC midnight", async () => {
  const {PronunciationReceipts} = require("../billable_receipts");
  const {validatePronunciationRequest} = require("../pronunciation_request_guard");
  const db = new MemoryFirestore();
  let now = new Date("2026-09-03T23:59:59Z");
  const receipts = new PronunciationReceipts(db, {now: () => now});
  const input = validatePronunciationRequest(request());
  const old = await receipts.claim(input);
  now = new Date("2026-09-04T00:00:00Z");
  await receipts.claim({...input, assessmentId: "other-request"});
  assert.equal(await receipts.transition(input, old.ownerToken, "refunded"), true);
  assert.equal(db.store.get("users/user-1/pronunciation_rate_limits/current").dayCount, 1);
  assert.equal(db.store.get("users/user-1/pronunciation_rate_limits/current").minuteCount, 1);
});

test("completed response expiry blocks dispatch through 24h recovery window", async () => {
  const h = harness();
  await h.run(request());
  const [key, receipt] = [...h.db.store].find(([key]) => key.startsWith("service_idempotency/"));
  h.db.store.set(key, {...receipt, responseExpiresAt: new Date(0)});
  await assert.rejects(h.run(request()), {code: "unavailable"});
  assert.equal(h.calls.length, 1);
});

test("pre-dispatch breaker rejection refunds its reservation once", async () => {
  const h = harness();
  const breaker = require("../pronunciation_request_guard").pronunciationProviderBreaker;
  for (let i = 0; i < 5; i++) breaker.recordFailure();
  await assert.rejects(h.run(request()), {code: "unavailable"});
  assert.equal(h.calls.length, 0);
  assert.equal(h.db.store.get("users/user-1/pronunciation_rate_limits/current").dayCount, 0);
});

test("actual callable abort marks uncertain and never refunds or blindly retries", async () => {
  const h = harness({providerTimeoutMs: 5});
  h.setProvider((_url, {signal}) => new Promise((resolve, reject) => {
    signal.addEventListener("abort", () => reject(new Error("response unknown")));
  }));
  await assert.rejects(h.run(request()), {code: "unavailable"});
  assert.equal(h.calls[0][1].signal.aborted, true);
  await assert.rejects(h.run(request()), {code: "unavailable"});
  assert.equal(h.calls.length, 1);
  assert.equal(h.db.store.get("users/user-1/pronunciation_rate_limits/current").dayCount, 1);
});

test("completed settlement is owner-fenced, idempotent, and keeps only15m result", async () => {
  const {PronunciationReceipts} = require("../billable_receipts");
  const {validatePronunciationRequest, parseAzureAssessment} = require("../pronunciation_request_guard");
  const db = new MemoryFirestore();
  const now = new Date("2026-09-03T10:00:00Z");
  const receipts = new PronunciationReceipts(db, {now: () => now});
  const input = validatePronunciationRequest(request());
  const owner = await receipts.claim(input);
  await receipts.transition(input, owner.ownerToken, "pending");
  const scores = parseAzureAssessment(azure, input.assessmentId);
  assert.equal(await receipts.transition(input, "wrong", "completed", scores), false);
  assert.equal(await receipts.transition(input, owner.ownerToken, "completed", scores), true);
  assert.equal(await receipts.transition(input, owner.ownerToken, "completed", {...scores, pronunciationScore: 1}), false);
  assert.equal(await receipts.transition(input, owner.ownerToken, "refunded"), false);
  assert.equal((await receipts.claim(input)).replay.pronunciationScore, 90);
  const receipt = db.store.get(receipts.refs(input).receipt.key);
  const result = db.store.get(receipts.refs(input).result.key);
  assert.equal(receipt.pronunciationScore, undefined);
  assert.equal(receipt.result, undefined);
  assert.equal(result.expiresAt.toISOString(), "2026-09-03T10:15:00.000Z");
  assert.equal(receipt.expiresAt.toISOString(), "2026-09-04T10:00:00.000Z");
});

test("request IDs are UID scoped and bind audio as well as text", async () => {
  const h = harness();
  await h.run(request());
  await assert.rejects(h.run(request({audioBase64: "AQIDBA=="})), {code: "invalid-argument"});
  await h.run({...request(), auth: {uid: "user-2"}});
  assert.equal(h.calls.length, 2);
});

test("atomic server policy resolves last quota slot without partial extra receipt", async () => {
  const {PronunciationReceipts} = require("../billable_receipts");
  const {validatePronunciationRequest} = require("../pronunciation_request_guard");
  const db = new MemoryFirestore();
  const receipts = new PronunciationReceipts(db, {resolvePolicy: async () => ({minuteLimit: 5, dayLimit: 1})});
  const input = validatePronunciationRequest(request({tier: "premium"}));
  const results = await Promise.allSettled([receipts.claim(input), receipts.claim({...input, assessmentId: "other-request"})]);
  assert.equal(results.filter((r) => r.status === "fulfilled").length, 1);
  assert.equal(results.filter((r) => r.reason?.code === "resource-exhausted").length, 1);
  assert.equal([...db.store.keys()].filter((key) => key.startsWith("service_idempotency/")).length, 1);
});

test("late recovered claim gets a full recovery window from actual dispatch", async () => {
  const {PronunciationReceipts} = require("../billable_receipts");
  const {validatePronunciationRequest} = require("../pronunciation_request_guard");
  const db = new MemoryFirestore();
  let now = new Date("2026-09-03T10:00:00Z");
  const receipts = new PronunciationReceipts(db, {now: () => now});
  const input = validatePronunciationRequest(request());
  await receipts.claim(input);
  now = new Date("2026-09-04T09:59:59Z");
  const owner = await receipts.claim(input);
  await receipts.transition(input, owner.ownerToken, "pending");
  now = new Date("2026-09-04T10:00:01Z");
  assert.equal((await receipts.claim(input)).state, "pending");
});
