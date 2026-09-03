"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {createHmac} = require("node:crypto");
const {createBillingRuntime, billingEventId} = require("./billing_runtime");
const {entitlementDocumentId, subjectHash} = require("./access_policy");

const NOW = Date.parse("2026-09-03T12:00:00Z");
const DAY = 86400000;
const uid = "account-A";
const secret = "test-signing-secret-not-a-real-key";
const authorization = "Bearer test-authorization-not-a-real-key";
const path = (environment = "PRODUCTION", owner = uid) =>
  `customer_entitlements/${entitlementDocumentId(owner, environment)}`;

function provider({sandbox = false, expires = NOW + DAY, grace = null,
  refund = null, purchase = NOW - 10000, original = uid} = {}) {
  return {request_date_ms: NOW, subscriber: {original_app_user_id: original,
    entitlements: {premium: {product_identifier: "monthly",
      expires_date: new Date(expires).toISOString(),
      grace_period_expires_date: grace === null ? null : new Date(grace).toISOString()}},
    subscriptions: {monthly: {is_sandbox: sandbox, store: "app_store",
      expires_date: new Date(expires).toISOString(),
      grace_period_expires_date: grace === null ? null : new Date(grace).toISOString(),
      original_purchase_date: new Date(purchase).toISOString(),
      purchase_date: new Date(purchase).toISOString(), refunded_at: refund,
      unsubscribe_detected_at: null}}}};
}

// Only Firestore transport, Firebase Auth and the external provider are doubled.
// Every ingest, claim, fence, retry, normalization and settlement runs real code.
function fixture() {
  const records = new Map();
  let currentTime = NOW;
  let tail = Promise.resolve();
  let storageFails = false;
  function snap(reference) {
    return {id: reference.path.split("/").at(-1), ref: reference,
      exists: records.has(reference.path), data: () => structuredClone(records.get(reference.path))};
  }
  function collection(name, constraints = [], count = Infinity) {
    const query = {doc: (id) => ({path: `${name}/${id}`}),
      where: (...args) => collection(name, [...constraints, args], count),
      limit: (value) => collection(name, constraints, value),
      get: async () => ({docs: [...records].filter(([key, value]) =>
        key.startsWith(`${name}/`) && constraints.every(([field, op, limit]) =>
          op === "<=" ? value[field] <= limit : value[field] === limit))
        .slice(0, count).map(([key]) => snap({path: key}))})};
    return query;
  }
  const firestore = {collection, runTransaction: (body) => {
    const result = tail.then(async () => {
      if (storageFails) throw new Error("storage unavailable");
      const writes = new Map();
      let wrote = false;
      const transaction = {
        get: async (reference) => {
          assert.equal(wrote, false, "Firestore reads must precede writes");
          return snap(reference);
        },
        set: (reference, value) => { wrote = true; writes.set(reference.path, value); },
        delete: (reference) => { wrote = true; writes.set(reference.path, undefined); },
      };
      const result = await body(transaction);
      for (const [key, value] of writes) {
        if (value === undefined) records.delete(key); else records.set(key, structuredClone(value));
      }
      return result;
    });
    tail = result.catch(() => {});
    return result;
  }};
  const users = new Map([[uid, {uid, providerData: [{providerId: "google.com"}],
    metadata: {creationTime: new Date(NOW - DAY).toISOString()}}]]);
  const auth = {getUser: async (id) => {
    if (!users.has(id)) throw Object.assign(new Error("missing"), {code: "auth/user-not-found"});
    return structuredClone(users.get(id));
  }};
  let fetchCount = 0;
  let response = provider();
  const options = {firestore, auth, now: () => currentTime,
    getConfig: () => ({enabled: true, restorePolicy: "keep_original", entitlementId: "premium",
      authorization, signingSecret: secret}),
    fetchSubscriber: async () => { fetchCount++; return response; }};
  let runtime = createBillingRuntime(options);
  function request(event = {}, extra = {}) {
    const rawBody = Buffer.from(JSON.stringify({api_version: "1.0", event: {
      id: "event-1", type: "INITIAL_PURCHASE", app_user_id: uid,
      environment: "PRODUCTION", event_timestamp_ms: NOW, ...event}}));
    const timestamp = String(Math.floor(currentTime / 1000));
    const digest = createHmac("sha256", secret).update(`${timestamp}.`).update(rawBody).digest("hex");
    return {method: "POST", rawBody, headers: {"content-type": "application/json", authorization,
      "x-revenuecat-webhook-signature": `t=${timestamp},v1=${digest}`}, ...extra};
  }
  async function ingest(event, extra) {
    const result = {status(value) { this.statusCode = value; return this; },
      send(value) { this.body = value; return this; }};
    await runtime.webhook(request(event, extra), result);
    return result;
  }
  return {records, users, auth, options, request, ingest,
    get runtime() { return runtime; }, rebuild() { runtime = createBillingRuntime(options); },
    setTime: (value) => { currentTime = value; }, setResponse: (value) => { response = value; },
    setStorageFails: (value) => { storageFails = value; }, fetchCount: () => fetchCount};
}

test("authenticated raw-body ingestion persists pending before 200 and duplicates remain runnable", async () => {
  const f = fixture();
  for (let i = 0; i < 2; i++) assert.equal((await f.ingest()).statusCode, 200);
  const id = billingEventId("PRODUCTION", "event-1");
  assert.equal(f.records.get(`billing_event_receipts/${id}`).status, "pending");
  assert.equal(f.fetchCount(), 0);
  await f.runtime.processEvent(id);
  assert.equal(f.fetchCount(), 1);
  assert.equal(f.records.get(path()).status, "active");
  assert.equal((await f.ingest()).statusCode, 200);
  await f.runtime.processEvent(id);
  assert.equal(f.fetchCount(), 1);
  const receipt = f.records.get(`billing_event_receipts/${id}`);
  assert.equal(receipt.ownerUid, undefined);
  assert.equal(receipt.ownerSubjectHash, subjectHash(uid));
  assert.ok(receipt.expiresAt instanceof Date);
  assert.equal(JSON.stringify([...f.records]).includes(authorization), false);
});

test("rejects wrong auth, signature, raw bytes, stale/future timestamp, malformed/oversized body", async () => {
  const f = fixture();
  const good = f.request();
  const requests = [
    {...good, headers: {...good.headers, authorization: "wrong"}},
    {...good, headers: {...good.headers, "x-revenuecat-webhook-signature": "t=1,v1=bad"}},
    {...good, rawBody: Buffer.concat([good.rawBody, Buffer.from(" ")])},
    {...good, rawBody: Buffer.alloc(65537)}, {...good, rawBody: undefined},
    {...good, method: "GET"},
    {...good, headers: {...good.headers, "content-type": "text/plain"}},
  ];
  for (const request of requests) {
    const response = {status(code) { this.code = code; return this; }, send() {}};
    await f.runtime.webhook(request, response);
    assert.ok(response.code >= 400);
  }
  for (const offset of [-301000, 301000]) {
    f.setTime(NOW + offset);
    const response = {status(code) { this.code = code; return this; }, send() {}};
    await f.runtime.webhook(good, response);
    assert.equal(response.code, 401);
  }
  assert.equal(f.records.size, 0);
});

test("closed configuration and durable persistence failure never acknowledge accepted work", async () => {
  const f = fixture();
  f.setStorageFails(true);
  assert.equal((await f.ingest()).statusCode, 503);
  f.setStorageFails(false);
  for (const config of [{enabled: false}, {enabled: true, restorePolicy: "transfer"}]) {
    f.options.getConfig = () => config; f.rebuild();
    assert.equal((await f.ingest()).statusCode, 503);
  }
});

test("authorization-only and HMAC-only configurations authenticate without downgrade", async () => {
  for (const mode of ["authorization", "hmac", "none"]) {
    const f = fixture();
    f.options.getConfig = () => ({enabled: true, restorePolicy: "keep_original", entitlementId: "premium",
      authorization: mode === "authorization" ? authorization : undefined,
      signingSecret: mode === "hmac" ? secret : undefined});
    f.rebuild();
    assert.equal((await f.ingest()).statusCode, mode === "none" ? 401 : 200);
    if (mode === "hmac") {
      const request = f.request({id: "second"});
      delete request.headers["x-revenuecat-webhook-signature"];
      assert.equal((await f.ingest({id: "second"}, request)).statusCode, 401);
    }
  }
});

test("authenticated invalid schema and excessive identity arrays reject without persisting private attributes", async () => {
  const f = fixture();
  for (const event of [{id: ""}, {environment: "DEVELOPMENT"}, {type: null},
    {event_timestamp_ms: NOW + 300001}, {app_user_id: "invalid/path"},
    {aliases: Array(21).fill("account-B")}]) {
    assert.equal((await f.ingest(event)).statusCode, 400);
  }
  assert.equal(f.records.size, 0);
  await f.ingest({subscriber_attributes: {email: "private-email-do-not-retain@example.test"},
    transaction_id: "private-transaction-do-not-retain"});
  assert.equal(JSON.stringify([...f.records]).includes("do-not-retain"), false);
});

test("same event ID changed subject/payload is rejected, while environments are independent", async () => {
  const f = fixture();
  await f.ingest();
  assert.equal((await f.ingest({type: "EXPIRATION"})).statusCode, 409);
  await f.ingest({environment: "SANDBOX"});
  f.setResponse(provider({sandbox: true}));
  await f.runtime.processEvent(billingEventId("SANDBOX", "event-1"));
  assert.equal(f.records.get(path("SANDBOX")).status, "active");
  await f.runtime.processEvent(billingEventId("PRODUCTION", "event-1"));
  assert.equal(f.records.get(path()).status, "inactive");
});

test("cancellation/grace retain current access; expiry/refund/hold revoke; renewal restores", async () => {
  const f = fixture();
  for (const [index, type, response, expected] of [
    [1, "CANCELLATION", provider(), "active"],
    [2, "BILLING_ISSUE", provider({expires: NOW - 1000, grace: NOW + 10000}), "active"],
    [3, "BILLING_ISSUE", provider({expires: NOW - 1000}), "inactive"],
    [4, "EXPIRATION", provider({expires: NOW - 1000}), "inactive"],
    [5, "CANCELLATION", provider({refund: new Date(NOW).toISOString()}), "inactive"],
    [6, "RENEWAL", provider(), "active"],
    [7, "EXPIRATION", provider(), "active"], // delayed old event cannot undo current renewal
  ]) {
    await f.ingest({id: `event-${index}`, type}); f.setResponse(response);
    await f.runtime.processEvent(billingEventId("PRODUCTION", `event-${index}`));
    assert.equal(f.records.get(path()).status, expected);
  }
  assert.equal(f.records.get(path()).revision, 7);
});

test("transient provider failure remains pending and scheduler retries without trusting webhook expiry", async () => {
  const f = fixture();
  f.options.fetchSubscriber = async () => { throw new Error("external detail must not persist"); };
  f.rebuild(); await f.ingest();
  await f.runtime.processEvent(billingEventId("PRODUCTION", "event-1"));
  assert.equal(f.records.get(path()), undefined);
  assert.equal(f.records.get(`billing_event_receipts/${billingEventId("PRODUCTION", "event-1")}`).status, "pending");
  f.options.fetchSubscriber = async () => provider(); f.rebuild(); f.setTime(NOW + 120000);
  await f.runtime.sweep();
  assert.equal(f.records.get(path()).status, "active");
  assert.equal(JSON.stringify([...f.records]).includes("external detail"), false);
});

test("ten workers use one lease; newer ingestion invalidates old refresh until a new fetch", async () => {
  const f = fixture();
  let release; let entered;
  const called = new Promise((resolve) => { entered = resolve; });
  const blocked = new Promise((resolve) => { release = resolve; });
  let calls = 0;
  f.options.fetchSubscriber = async () => { calls++; entered(); await blocked; return provider(); };
  f.rebuild(); await f.ingest();
  const id = billingEventId("PRODUCTION", "event-1");
  const tasks = Array.from({length: 10}, () => f.runtime.processEvent(id));
  await called;
  await f.ingest({id: "event-2", type: "EXPIRATION"});
  release(); await Promise.all(tasks);
  assert.equal(calls, 1);
  assert.equal(f.records.get(path()), undefined);
  f.options.fetchSubscriber = async () => provider({expires: NOW - 1}); f.rebuild();
  await f.runtime.processEvent(billingEventId("PRODUCTION", "event-2"));
  assert.equal(f.records.get(path()).status, "inactive");
});

test("expired lease takeover fences stale worker settlement", async () => {
  const f = fixture(); let release; let entered;
  const called = new Promise((resolve) => { entered = resolve; });
  const blocked = new Promise((resolve) => { release = resolve; });
  f.options.fetchSubscriber = async () => { entered(); await blocked; return provider(); };
  f.rebuild(); await f.ingest();
  const id = billingEventId("PRODUCTION", "event-1");
  const old = f.runtime.processEvent(id); await called;
  f.setTime(NOW + 61000);
  f.options.fetchSubscriber = async () => provider({expires: NOW - 1}); f.rebuild();
  await f.runtime.processEvent(id);
  release(); await old;
  assert.equal(f.records.get(path()).status, "inactive");
  assert.equal(f.records.get(path()).revision, 1);
});

test("deleted, disabled, anonymous, recreated, or event-before-creation identities cannot grant", async () => {
  for (const mode of ["deleted", "disabled", "anonymous", "recreated", "old-event"]) {
    const f = fixture();
    if (mode === "old-event") f.users.get(uid).metadata.creationTime = new Date(NOW + 1).toISOString();
    await f.ingest();
    if (mode === "deleted") f.records.set(`account_deletions/${uid}`, {});
    if (mode === "disabled") f.users.get(uid).disabled = true;
    if (mode === "anonymous") f.users.get(uid).providerData = [];
    if (mode === "recreated") f.users.get(uid).metadata.creationTime = new Date(NOW - 100).toISOString();
    await f.runtime.processEvent(billingEventId("PRODUCTION", "event-1"));
    assert.equal(f.records.get(path()), undefined, mode);
  }
});

test("deletion or Auth replacement during provider fetch is fenced before writing", async () => {
  for (const mode of ["deletion", "replacement", "disabled"]) {
    const f = fixture();
    f.options.fetchSubscriber = async () => {
      if (mode === "deletion") f.records.set(`account_deletions/${uid}`, {});
      if (mode === "replacement") f.users.get(uid).metadata.creationTime = new Date(NOW - 1).toISOString();
      if (mode === "disabled") f.users.get(uid).disabled = true;
      return provider();
    };
    f.rebuild(); await f.ingest();
    await f.runtime.processEvent(billingEventId("PRODUCTION", "event-1"));
    assert.equal(f.records.get(path()), undefined);
  }
});

test("late webhook after deletion marker creates no new owner-linked receipt or customer", async () => {
  const f = fixture();
  // Auth can still exist while the deletion worker has already purged billing.
  f.records.set(`account_deletions/${uid}`, {phase: "cleanup"});
  assert.equal((await f.ingest()).statusCode, 200);
  assert.equal([...f.records.keys()].some((key) => key.startsWith("billing_")), false);
});

test("transfer of distinct durable accounts quarantines subscription only; anonymous alias is not ownership", async () => {
  const f = fixture();
  f.users.set("account-B", {...f.users.get(uid), uid: "account-B"});
  f.records.set(`premium_grants/${uid}`, {approvedBy: "Jin"});
  await f.ingest(); await f.runtime.processEvent(billingEventId("PRODUCTION", "event-1"));
  assert.equal(f.records.get(path()).status, "active");
  await f.ingest({id: "transfer", type: "TRANSFER", app_user_id: undefined,
    transferred_from: [uid], transferred_to: ["account-B"]});
  assert.equal(f.records.get(path()).status, "inactive");
  assert.equal(f.records.get(path("PRODUCTION", "account-B"))?.status, "inactive");
  assert.deepEqual(f.records.get(`premium_grants/${uid}`), {approvedBy: "Jin"});
  await f.ingest({id: "later"}); await f.runtime.processEvent(billingEventId("PRODUCTION", "later"));
  assert.equal(f.records.get(path()).status, "inactive");
  const normal = fixture();
  await normal.ingest({aliases: ["$RCAnonymousID:old", uid]});
  normal.setResponse(provider({original: "$RCAnonymousID:old"}));
  await normal.runtime.processEvent(billingEventId("PRODUCTION", "event-1"));
  assert.equal(normal.records.get(path()).status, "active");
});

test("scheduled refresh persists a new job and refreshes long lived entitlement", async () => {
  const f = fixture();
  f.setResponse(provider({expires: NOW + 30 * DAY}));
  await f.ingest(); await f.runtime.processEvent(billingEventId("PRODUCTION", "event-1"));
  f.setTime(NOW + DAY + 1);
  f.setResponse({...provider({expires: NOW + 30 * DAY}), request_date_ms: NOW + DAY + 1});
  await f.runtime.sweep();
  assert.equal(f.fetchCount(), 2);
  assert.equal(f.records.get(path()).revision, 2);
});

test("non-anonymous different original owner stays quarantined even after its Firebase identity vanished", async () => {
  const f = fixture();
  await f.ingest();
  f.setResponse(provider({original: "previous-owner-no-longer-in-Auth"}));
  await f.runtime.processEvent(billingEventId("PRODUCTION", "event-1"));
  assert.equal(f.records.get(path()).status, "inactive");
  assert.equal(f.records.get(`billing_customers/${entitlementDocumentId(uid, "PRODUCTION")}`).identityBlocked, true);
});

test("disabled workers/scheduler never evaluate webhook secret getters or call providers", async () => {
  const f = fixture(); let secretReads = 0;
  f.options.getConfig = () => ({enabled: false, get authorization() { secretReads++; throw new Error(); },
    get signingSecret() { secretReads++; throw new Error(); }});
  f.rebuild();
  assert.equal(await f.runtime.processEvent(billingEventId("PRODUCTION", "event-1")), "disabled");
  assert.deepEqual(await f.runtime.sweep(), {disabled: true});
  assert.equal(secretReads, 0);
  assert.equal(f.fetchCount(), 0);
});

test("provider success followed by storage outage cannot produce a completed receipt or grant", async () => {
  const f = fixture();
  f.options.fetchSubscriber = async () => { f.setStorageFails(true); return provider(); };
  f.rebuild(); await f.ingest();
  const id = billingEventId("PRODUCTION", "event-1");
  await assert.rejects(f.runtime.processEvent(id));
  assert.equal(f.records.get(path()), undefined);
  assert.equal(f.records.get(`billing_event_receipts/${id}`).status, "processing");
  f.setStorageFails(false); f.setTime(NOW + 61000);
  f.options.fetchSubscriber = async () => provider({expires: NOW - 1}); f.rebuild();
  await f.runtime.processEvent(id);
  assert.equal(f.records.get(path()).status, "inactive");
});

test("seven-day unfinished work flags review, retains minimal work and retries hourly until recovery", async () => {
  const f = fixture();
  f.options.fetchSubscriber = async () => { throw new Error("provider outage"); }; f.rebuild();
  await f.ingest(); f.setTime(NOW + 8 * DAY);
  const result = await f.runtime.sweep();
  const id = billingEventId("PRODUCTION", "event-1");
  const job = f.records.get(`billing_event_receipts/${id}`);
  assert.equal(job.status, "pending");
  assert.equal(job.needsReview, true);
  assert.equal(job.ownerUid, uid);
  assert.equal(job.expiresAt, undefined);
  assert.equal(job.nextAttemptAt, NOW + 8 * DAY + 3600000);
  assert.equal(result.needsReviewCandidates, 1);
  assert.equal((await f.ingest()).statusCode, 200);
  assert.equal(f.records.get(`billing_event_receipts/${id}`).status, "pending");
  f.setTime(NOW + 8 * DAY + 3600001);
  f.options.fetchSubscriber = async () => ({...provider({expires: NOW + 30 * DAY}),
    request_date_ms: NOW + 8 * DAY + 3600001}); f.rebuild();
  assert.equal((await f.runtime.sweep()).needsReviewCandidates, 0);
  assert.equal(f.records.get(path()).status, "active");
});

module.exports = {fixture, provider, NOW};
