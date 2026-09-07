"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {createAccessRuntime} = require("./access_runtime");
const {subjectHash} = require("./access_policy");

const NOW = Date.parse("2026-09-03T12:00:00Z");
const uid = "user-A";

// Only Firestore transport and Firebase Auth are doubled. The handler,
// transactional reads/reservations, validation and policy remain production code.
function fixture(seed = {}) {
  const records = new Map(Object.entries(seed));
  const reads = [];
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
          get: async (reference) => {
            reads.push(reference.path);
            return {exists: records.has(reference.path),
              data: () => records.get(reference.path)};
          },
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
    getEnvironment: () => "PRODUCTION"});
  const request = {auth: {uid}, app: {appId: "verified-app"}, data: {}};
  return {runtime, request, records, reads, auth, authCalls: () => authCalls};
}

test("both access callables reject unsigned, unattested and caller-supplied authority", async () => {
  for (const method of ["getAccessSnapshot", "getUniversalAccessSnapshot"]) {
    const f = fixture();
    for (const request of [
      {...f.request, auth: null}, {...f.request, app: null},
      {...f.request, app: {...f.request.app, alreadyConsumed: true}},
      {...f.request, data: {uid}}, {...f.request, data: {premium: true}},
      {...f.request, data: {environment: "SANDBOX"}},
    ]) {
      await assert.rejects(f.runtime[method](request));
    }
    assert.equal(f.records.size, 0);
  }
});

test("legacy callable returns a fixed v1 compatibility snapshot", async () => {
  const f = fixture();
  const result = await f.runtime.getAccessSnapshot(f.request);
  assert.equal(result.ownerUid, uid);
  assert.equal(result.schemaVersion, 1);
  assert.equal(result.source, "closed_tester_lifetime");
  assert.equal(result.aiPolicyId, "premium_v1");
  assert.equal(result.contentAccess, "all");
  assert.equal(result.bookDailyLimit, 20);
  assert.equal(result.pronunciationDailyLimit, 50);
  assert.equal(result.accessUntil, null);
  assert.equal(result.offlineUntil, NOW + 30 * 86_400_000);
  assert.equal(f.authCalls(), 1);
});

test("v2 callable returns the universal server policy", async () => {
  const f = fixture();
  const result = await f.runtime.getUniversalAccessSnapshot(f.request);
  assert.equal(result.ownerUid, uid);
  assert.equal(result.schemaVersion, 2);
  assert.equal(result.source, "universal");
  assert.equal(result.aiPolicyId, "universal_v1");
  assert.equal(result.contentAccess, "all");
  assert.equal(result.bookDailyLimit, 20);
  assert.equal(result.pronunciationDailyLimit, 50);
  assert.equal(result.accessUntil, undefined);
  assert.equal(result.offlineUntil, undefined);
});

test("retired billing documents are not read by either wire format", async () => {
  for (const method of ["getAccessSnapshot", "getUniversalAccessSnapshot"]) {
    const f = fixture({
      [`premium_grants/${uid}`]: {
        schemaVersion: 1, ownerUid: uid, status: "active",
      },
      [`customer_entitlements/PRODUCTION_${subjectHash(uid)}`]: {
        schemaVersion: 1, ownerUid: uid, status: "active",
      },
    });
    const result = await f.runtime[method](f.request);
    assert.equal(result.contentAccess, "all");
    assert.deepEqual(f.reads, [
      `account_deletions/${uid}`,
      `access_rate_limits/${subjectHash(uid)}`,
    ]);
  }
});

test("legacy billing records cannot change a recreated account's access", async () => {
  const created = NOW - 10000;
  for (const kind of ["tester", "subscription"]) {
    const key = kind === "tester" ? `premium_grants/${uid}` :
      `customer_entitlements/PRODUCTION_${subjectHash(uid)}`;
    const authority = {schemaVersion: 1, ownerUid: uid, environment: "PRODUCTION",
      revision: 1, accountCreatedAt: created, status: "active",
      kind: "closed_tester_lifetime", grantId: "approved", approvedBy: "Jin",
      approvalRef: "roster", approvedAt: NOW - 1,
      providerCheckedAt: NOW, accessUntil: NOW + 60000};
    const f = fixture({[key]: authority});
    f.auth.getUser = async () => ({uid, metadata: {creationTime: new Date(created).toISOString()}});
    assert.equal((await f.runtime.getUniversalAccessSnapshot(f.request)).bookDailyLimit, 20);
    f.auth.getUser = async () => ({uid, metadata: {creationTime: new Date(created + 1000).toISOString()}});
    assert.equal((await f.runtime.getUniversalAccessSnapshot(f.request)).bookDailyLimit, 20);
    delete authority.accountCreatedAt;
    assert.equal((await f.runtime.getUniversalAccessSnapshot(f.request)).bookDailyLimit, 20);
  }
});

test("legacy sandbox billing state cannot change production access", async () => {
  const f = fixture({
    [`customer_entitlements/SANDBOX_${subjectHash(uid)}`]: {
      accountCreatedAt: 0,
      schemaVersion: 1, ownerUid: uid, environment: "SANDBOX", revision: 1,
      status: "active", accessUntil: NOW + 100_000, providerCheckedAt: NOW,
    },
  });
  assert.equal((await f.runtime.getUniversalAccessSnapshot(f.request)).bookDailyLimit, 20);
});

test("both formats enforce deleted, disabled, missing and mismatched identities", async () => {
  for (const method of ["getAccessSnapshot", "getUniversalAccessSnapshot"]) {
    const deleted = fixture({[`account_deletions/${uid}`]: {phase: "completed"}});
    await assert.rejects(deleted.runtime[method](deleted.request),
      (error) => error.code === "failed-precondition");
    for (const user of [{uid, disabled: true}, {uid: "different"}]) {
      const f = fixture();
      f.auth.getUser = async () => user;
      await assert.rejects(f.runtime[method](f.request),
        (error) => error.code === "unauthenticated");
    }
    const missing = fixture();
    missing.auth.getUser = async () => { throw new Error("not-found"); };
    await assert.rejects(missing.runtime[method](missing.request));
  }
});

test("shared rate limit cannot be bypassed by alternating wire versions", async () => {
  const f = fixture();
  const results = await Promise.allSettled(Array.from({length: 35}, (_, index) =>
    index % 2 === 0 ? f.runtime.getAccessSnapshot(f.request) :
      f.runtime.getUniversalAccessSnapshot(f.request)));
  assert.equal(results.filter((r) => r.status === "fulfilled").length, 30);
  assert.equal(results.filter((r) => r.status === "rejected" &&
    r.reason.code === "resource-exhausted").length, 5);
});

test("access remains registered and retired billing handlers are absent", () => {
  const deployed = require("./index");
  assert.equal(typeof deployed.getAccessSnapshot, "function");
  assert.equal(typeof deployed.getUniversalAccessSnapshot, "function");
  assert.equal(typeof deployed.appleOAuthCallback, "function");
  assert.equal(deployed.revenueCatWebhook, undefined);
  assert.equal(deployed.processRevenueCatEvent, undefined);
  assert.equal(deployed.refreshRevenueCatAccess, undefined);
  const secrets = (fn) => (fn.__endpoint.secretEnvironmentVariables || []).map((v) => v.key).sort();
  assert.deepEqual(secrets(deployed.getAccessSnapshot), []);
  assert.deepEqual(secrets(deployed.getUniversalAccessSnapshot), []);
  assert.deepEqual(secrets(deployed.appleOAuthCallback), []);
});
