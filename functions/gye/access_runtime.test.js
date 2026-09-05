"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {createAccessRuntime} = require("./access_runtime");
const {entitlementDocumentId} = require("./access_policy");

const NOW = Date.parse("2026-09-03T12:00:00Z");
const uid = "user-A";

// Only Firestore transport and Firebase Auth are doubled. The handler,
// transactional reads/reservations, validation and policy remain production code.
function fixture(seed = {}) {
  const records = new Map(Object.entries(seed));
  let tail = Promise.resolve();
  function ref(path) {
    return {path, collection: (name) => collection(`${path}/${name}`)};
  }
  function collection(path) {
    return {doc: (id) => ref(`${path}/${id}`)};
  }
  const firestore = {
    collection,
    runTransaction: (body) => {
      const result = tail.then(async () => {
        const writes = new Map();
        const tx = {
          get: async (reference) => ({exists: records.has(reference.path),
            data: () => records.get(reference.path)}),
          set: (reference, value) => writes.set(reference.path, value),
        };
        const result = await body(tx);
        for (const [path, value] of writes) records.set(path, value);
        return result;
      });
      tail = result.catch(() => {});
      return result;
    },
  };
  let authCalls = 0;
  const auth = {getUser: async (requested) => {
    authCalls += 1;
    return {uid: requested, disabled: false, metadata: {creationTime: new Date(0).toISOString()}};
  }};
  const runtime = createAccessRuntime({firestore, auth, now: () => NOW,
    getEnvironment: () => "PRODUCTION", getPhase: () => "free_launch"});
  const request = {auth: {uid}, app: {appId: "verified-app"}, data: {}};
  return {runtime, request, records, auth, authCalls: () => authCalls};
}

test("access callable rejects unsigned, unattested and caller-supplied authority", async () => {
  const f = fixture();
  for (const request of [
    {...f.request, auth: null}, {...f.request, app: null},
    {...f.request, app: {...f.request.app, alreadyConsumed: true}},
    {...f.request, data: {uid}}, {...f.request, data: {premium: true}},
    {...f.request, data: {environment: "SANDBOX"}},
  ]) {
    await assert.rejects(f.runtime.getAccessSnapshot(request));
  }
  assert.equal(f.records.size, 0);
});

test("free guest identity receives server policy, not an RC entitlement", async () => {
  const f = fixture();
  const result = await f.runtime.getAccessSnapshot(f.request);
  assert.equal(result.ownerUid, uid);
  assert.equal(result.source, "free_launch");
  assert.equal(result.bookDailyLimit, 20);
  assert.equal(f.authCalls(), 1);
});

test("retired tester grants no longer change open access", async () => {
  const f = fixture({[`premium_grants/${uid}`]: {
    accountCreatedAt: 0,
    schemaVersion: 1, ownerUid: uid, environment: "PRODUCTION", revision: 1,
    kind: "closed_tester_lifetime", status: "active", grantId: "roster-001",
    approvedAt: NOW - 1, approvedBy: "Jin", approvalRef: "approved-001",
  }});
  const result = await f.runtime.getAccessSnapshot(f.request);
  assert.equal(result.source, "free_launch");
  assert.equal(result.pronunciationDailyLimit, 50);
});

test("manually recreated same UID cannot reuse existing subscription or tester grant", async () => {
  const created = NOW - 10000;
  for (const kind of ["tester", "subscription"]) {
    const key = kind === "tester" ? `premium_grants/${uid}` :
      `customer_entitlements/${entitlementDocumentId(uid, "PRODUCTION")}`;
    const authority = {schemaVersion: 1, ownerUid: uid, environment: "PRODUCTION",
      revision: 1, accountCreatedAt: created, status: "active",
      kind: "closed_tester_lifetime", grantId: "approved", approvedBy: "Jin",
      approvalRef: "roster", approvedAt: NOW - 1,
      providerCheckedAt: NOW, accessUntil: NOW + 60000};
    const f = fixture({[key]: authority});
    f.auth.getUser = async () => ({uid, metadata: {creationTime: new Date(created).toISOString()}});
    assert.equal((await f.runtime.getAccessSnapshot(f.request)).bookDailyLimit, 20);
    f.auth.getUser = async () => ({uid, metadata: {creationTime: new Date(created + 1000).toISOString()}});
    assert.equal((await f.runtime.getAccessSnapshot(f.request)).bookDailyLimit, 20);
    delete authority.accountCreatedAt;
    assert.equal((await f.runtime.getAccessSnapshot(f.request)).bookDailyLimit, 20);
  }
});

test("environment-specific snapshot lookup cannot consume sandbox state", async () => {
  const f = fixture({
    [`customer_entitlements/${entitlementDocumentId(uid, "SANDBOX")}`]: {
      accountCreatedAt: 0,
      schemaVersion: 1, ownerUid: uid, environment: "SANDBOX", revision: 1,
      status: "active", accessUntil: NOW + 100_000, providerCheckedAt: NOW,
    },
  });
  assert.equal((await f.runtime.getAccessSnapshot(f.request)).bookDailyLimit, 20);
});

test("deleted, disabled, missing or mismatched identities get no access snapshot", async () => {
  const deleted = fixture({[`account_deletions/${uid}`]: {phase: "completed"}});
  await assert.rejects(deleted.runtime.getAccessSnapshot(deleted.request),
    (error) => error.code === "failed-precondition");
  for (const user of [{uid, disabled: true}, {uid: "different"}]) {
    const f = fixture();
    f.auth.getUser = async () => user;
    await assert.rejects(f.runtime.getAccessSnapshot(f.request),
      (error) => error.code === "unauthenticated");
  }
  const missing = fixture();
  missing.auth.getUser = async () => { throw new Error("not-found"); };
  await assert.rejects(missing.runtime.getAccessSnapshot(missing.request));
});

test("concurrent access polling is bounded atomically", async () => {
  const f = fixture();
  const results = await Promise.allSettled(Array.from({length: 35},
    () => f.runtime.getAccessSnapshot(f.request)));
  assert.equal(results.filter((r) => r.status === "fulfilled").length, 30);
  assert.equal(results.filter((r) => r.status === "rejected" &&
    r.reason.code === "resource-exhausted").length, 5);
});

test("access remains registered and retired billing handlers are absent", () => {
  const deployed = require("./index");
  assert.equal(typeof deployed.getAccessSnapshot, "function");
  assert.equal(typeof deployed.appleOAuthCallback, "function");
  assert.equal(deployed.revenueCatWebhook, undefined);
  assert.equal(deployed.processRevenueCatEvent, undefined);
  assert.equal(deployed.refreshRevenueCatAccess, undefined);
  const secrets = (fn) => (fn.__endpoint.secretEnvironmentVariables || []).map((v) => v.key).sort();
  assert.deepEqual(secrets(deployed.getAccessSnapshot), []);
  assert.deepEqual(secrets(deployed.appleOAuthCallback), []);
});
