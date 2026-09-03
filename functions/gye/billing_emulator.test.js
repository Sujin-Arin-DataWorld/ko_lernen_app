"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {createBillingRuntime, billingEventId} = require("./billing_runtime");
const {entitlementDocumentId} = require("./access_policy");

const emulator = process.env.FIRESTORE_EMULATOR_HOST;
const NOW = Date.parse("2026-09-03T12:00:00Z");
const DAY = 86400000;
let app;
let firestore;

test.before(async () => {
  if (!emulator) return;
  assert.match(emulator, /^(?:localhost|127\.0\.0\.1):\d+$/u, "Never connect these tests to production");
  const {initializeApp} = require("firebase-admin/app");
  const {getFirestore} = require("firebase-admin/firestore");
  app = initializeApp({projectId: "demo-hangul-sori"}, "billing-emulator");
  firestore = getFirestore(app);
});

test.after(async () => {
  if (app) await require("firebase-admin/app").deleteApp(app);
});

function setup(uid) {
  let currentTime = NOW;
  let calls = 0;
  let transport = async () => ({request_date_ms: currentTime, subscriber: {
    entitlements: {premium: {product_identifier: "monthly", expires_date: new Date(NOW + 30 * DAY).toISOString()}},
    subscriptions: {monthly: {store: "play_store", is_sandbox: false,
      original_purchase_date: new Date(NOW - 1000).toISOString(),
      expires_date: new Date(NOW + 30 * DAY).toISOString()}},
  }});
  const runtime = createBillingRuntime({firestore, now: () => currentTime,
    auth: {getUser: async (id) => ({uid: id, providerData: [{providerId: "apple.com"}],
      metadata: {creationTime: new Date(NOW - DAY).toISOString()}})},
    fetchSubscriber: async () => { calls++; return transport(); },
    getConfig: () => ({enabled: true, restorePolicy: "keep_original", entitlementId: "premium",
      authorization: "Bearer emulator-not-a-real-secret"})});
  const eventId = billingEventId("PRODUCTION", uid);
  const customerRef = firestore.collection("billing_customers").doc(entitlementDocumentId(uid, "PRODUCTION"));
  const entitlementRef = firestore.collection("customer_entitlements").doc(entitlementDocumentId(uid, "PRODUCTION"));
  const jobRef = firestore.collection("billing_event_receipts").doc(eventId);
  const markerRef = firestore.collection("account_deletions").doc(uid);
  async function ingest() {
    const response = {status(code) { this.code = code; return this; }, send() {}};
    await runtime.webhook({method: "POST", rawBody: Buffer.from(JSON.stringify({api_version: "1.0",
      event: {id: uid, type: "INITIAL_PURCHASE", environment: "PRODUCTION", app_user_id: uid,
        event_timestamp_ms: NOW}})), headers: {"content-type": "application/json",
      authorization: "Bearer emulator-not-a-real-secret"}}, response);
    return response.code;
  }
  async function cleanup() {
    for (const ref of [customerRef, entitlementRef, jobRef, markerRef]) await ref.delete();
  }
  return {runtime, ingest, eventId, customerRef, entitlementRef, jobRef, markerRef, cleanup,
    calls: () => calls, setTransport: (value) => { transport = value; },
    setTime: (value) => { currentTime = value; }};
}

test("emulator: concurrent ingestion and workers atomically claim once and settle hash-only receipt",
  {skip: !emulator}, async () => {
    const f = setup("billing-emulator-concurrent");
    await f.cleanup();
    try {
      assert.deepEqual(await Promise.all(Array.from({length: 10}, () => f.ingest())), Array(10).fill(200));
      assert.equal((await f.jobRef.get()).data().status, "pending");
      await Promise.all(Array.from({length: 10}, () => f.runtime.processEvent(f.eventId)));
      assert.equal(f.calls(), 1);
      const entitlement = (await f.entitlementRef.get()).data();
      assert.equal(entitlement.status, "active");
      assert.equal(entitlement.revision, 1);
      const receipt = (await f.jobRef.get()).data();
      assert.equal(receipt.status, "completed");
      assert.equal(receipt.ownerUid, undefined);
      assert.ok(receipt.expiresAt.toMillis() > NOW);
      assert.equal((await f.customerRef.get()).data().leaseOwner, null);
    } finally { await f.cleanup(); }
  });

test("emulator: deletion marker written during refresh prevents any entitlement resurrection",
  {skip: !emulator}, async () => {
    const f = setup("billing-emulator-deletion");
    await f.cleanup();
    f.setTransport(async () => {
      await f.markerRef.set({phase: "pending"});
      return {request_date_ms: NOW, subscriber: {entitlements: {}, subscriptions: {}}};
    });
    try {
      assert.equal(await f.ingest(), 200);
      await f.runtime.processEvent(f.eventId);
      assert.equal((await f.entitlementRef.get()).exists, false);
      assert.equal((await f.jobRef.get()).data().status, "ignored");
      await f.jobRef.delete();
      await f.customerRef.delete();
      assert.equal(await f.ingest(), 200);
      assert.equal((await f.jobRef.get()).exists, false);
      assert.equal((await f.customerRef.get()).exists, false);
    } finally { await f.cleanup(); }
  });

test("emulator: transient provider failure is durably recovered by scheduler query",
  {skip: !emulator}, async () => {
    const f = setup("billing-emulator-retry");
    await f.cleanup();
    f.setTransport(async () => { throw new Error("unavailable"); });
    try {
      assert.equal(await f.ingest(), 200);
      await f.runtime.processEvent(f.eventId);
      assert.equal((await f.jobRef.get()).data().status, "pending");
      assert.equal((await f.jobRef.get()).data().expiresAt, undefined);
      f.setTime(NOW + 120000);
      f.setTransport(async () => ({request_date_ms: NOW + 120000,
        subscriber: {entitlements: {}, subscriptions: {}}}));
      await f.runtime.sweep();
      assert.equal((await f.jobRef.get()).data().status, "completed");
      assert.equal((await f.entitlementRef.get()).data().status, "inactive");
      assert.equal((await f.customerRef.get()).data().refreshDueAt, undefined);
    } finally { await f.cleanup(); }
  });
