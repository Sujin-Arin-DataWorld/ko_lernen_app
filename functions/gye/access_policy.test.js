"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {resolveAccess, entitlementDocumentId} = require("./access_policy");
const fixture = require("../../test/fixtures/access_policy/v1.json");

test("shared snapshot fixture covers every policy case exactly once", () => {
  const names = fixture.cases.map((entry) => entry.name);
  assert.equal(new Set(names).size, names.length);
  assert.deepEqual(Object.keys(fixture.expectedSnapshots).sort(), [...names].sort());
});

for (const entry of fixture.cases) {
  test(`shared wire snapshot: ${entry.name}`, () => {
    const actual = resolveAccess({
      uid: fixture.uid, now: fixture.now,
      accountCreatedAt: Object.hasOwn(entry, "accountCreatedAt") ? entry.accountCreatedAt : fixture.accountCreatedAt,
      environment: entry.environment || "PRODUCTION",
      phase: entry.phase || "free_launch",
      grant: entry.grant ? {...fixture.grant, ...entry.grant} : null,
      entitlement: entry.entitlement ? {...fixture.entitlement, ...entry.entitlement} : null,
    });
    assert.deepEqual(actual, fixture.expectedSnapshots[entry.name]);
    assert.equal(actual.source, entry.wantSource);
    assert.equal(actual.contentAccess, entry.wantContent);
    assert.equal(actual.bookDailyLimit, entry.wantBook);
    assert.equal(actual.pronunciationDailyLimit, entry.wantPronunciation);
  });
}

const NOW = Date.parse("2026-09-03T12:00:00Z");
const DAY = 86_400_000;
const uid = "account-A";
const grant = {
  accountCreatedAt: NOW - 2 * DAY,
  schemaVersion: 1, ownerUid: uid, environment: "PRODUCTION", revision: 1,
  kind: "closed_tester_lifetime", status: "active", grantId: "approval-001",
  approvedAt: NOW - DAY, approvedBy: "Jin", approvalRef: "approved-roster-001",
};
const entitlement = {
  accountCreatedAt: NOW - 2 * DAY,
  schemaVersion: 1, ownerUid: uid, environment: "PRODUCTION", revision: 1,
  status: "active", accessUntil: NOW + 5 * DAY, providerCheckedAt: NOW - 1000,
};
function access(overrides = {}) {
  return resolveAccess({uid, now: NOW, environment: "PRODUCTION",
    accountCreatedAt: NOW - 2 * DAY,
    phase: "free_launch", ...overrides});
}

test("both premium authorities require matching server Auth creation generation", () => {
  const created = NOW - 2 * DAY;
  for (const [field, document] of [["grant", grant], ["entitlement", entitlement]]) {
    assert.equal(access({[field]: {...document, accountCreatedAt: created},
      accountCreatedAt: created}).bookDailyLimit, 20);
    for (const stored of [undefined, null, created - 1, "invalid"]) {
      assert.equal(access({[field]: {...document, accountCreatedAt: stored},
        accountCreatedAt: created}).bookDailyLimit, 20);
    }
    for (const current of [undefined, null, created + 1, NOW + 1]) {
      assert.equal(access({[field]: {...document, accountCreatedAt: created},
        accountCreatedAt: current}).bookDailyLimit, 20);
    }
  }
});

test("free launch opens content with the highest service allowance", () => {
  const actual = access();
  assert.equal(actual.contentAccess, "all");
  assert.equal(actual.source, "free_launch");
  assert.equal(actual.bookDailyLimit, 20);
  assert.equal(actual.pronunciationDailyLimit, 50);
  assert.equal(actual.nextResetAt, Date.parse("2026-09-04T00:00:00Z"));
});

test("paid-phase configuration cannot reintroduce a subscription gate", () => {
  assert.deepEqual([access({phase: "paid"}).contentAccess,
    access({phase: "paid"}).bookDailyLimit,
    access({phase: "paid"}).pronunciationDailyLimit], ["all", 20, 50]);
});

test("approved lifetime grant overrides phase and bounded subscription expiry", () => {
  for (const phase of ["free_launch", "paid"]) {
    const actual = access({phase, grant});
    assert.equal(actual.source, "closed_tester_lifetime");
    assert.equal(actual.contentAccess, "all");
    assert.equal(actual.bookDailyLimit, 20);
    assert.equal(actual.pronunciationDailyLimit, 50);
    assert.equal(actual.accessUntil, null);
    assert.equal(actual.offlineUntil, NOW + 30 * DAY);
  }
});

test("feedback passports, beta flags and malformed or foreign grants confer nothing", () => {
  for (const candidate of [
    {tester_passport: true}, {...grant, status: "revoked"},
    {...grant, ownerUid: "account-B"}, {...grant, environment: "SANDBOX"},
    {...grant, approvedBy: ""}, {...grant, approvedBy: "self"}, {...grant, approvalRef: ""},
    {...grant, approvedAt: NOW + 1}, {...grant, schemaVersion: 99},
    {...grant, revision: -1}, {...grant, kind: "beta_build"},
  ]) {
    const actual = access({phase: "paid", grant: candidate,
      betaUnlockAll: true, premium: true});
    assert.equal(actual.source, "free");
    assert.equal(actual.bookDailyLimit, 20);
  }
});

test("subscription cache cannot outlive expiry or 72h provider verification", () => {
  const actual = access({phase: "paid", entitlement});
  assert.equal(actual.source, "subscription");
  assert.equal(actual.offlineUntil, NOW - 1000 + 3 * DAY);
  assert.equal(access({entitlement: {...entitlement,
    accessUntil: NOW + 1000}}).offlineUntil, NOW + 1000);
  for (const candidate of [
    {...entitlement, accessUntil: NOW},
    {...entitlement, status: "expired"},
    {...entitlement, providerCheckedAt: NOW - 3 * DAY},
    {...entitlement, providerCheckedAt: NOW + 1},
    {...entitlement, environment: "SANDBOX"},
    {...entitlement, ownerUid: "account-B"},
  ]) {
    assert.equal(access({phase: "paid", entitlement: candidate}).source, "free");
  }
});

test("cancellation intent does not remove currently verified paid access", () => {
  assert.equal(access({entitlement: {...entitlement, willRenew: false}}).source,
    "subscription");
});

test("snapshots expose no approval records and revisions change with authority", () => {
  const actual = access({grant});
  assert.equal(actual.ownerUid, uid);
  assert.equal(actual.schemaVersion, 1);
  assert.equal(actual.environment, "PRODUCTION");
  assert.equal(actual.serverNow, NOW);
  assert.equal(actual.approvedBy, undefined);
  assert.equal(actual.approvalRef, undefined);
  assert.notEqual(actual.revision, access().revision);
  assert.notEqual(actual.revision, access({grant: {...grant, revision: 2}}).revision);
});

test("untrusted identity and unknown deployment policy fail closed", () => {
  for (const overrides of [{uid: ""}, {uid: "../other"}, {uid: "a/b"},
    {uid: "a\n"}, {uid: "a".repeat(129)}, {phase: "typo"},
    {environment: "typo"}, {now: NaN}]) {
    assert.throws(() => access(overrides));
  }
});

test("entitlement document keys separate environments without raw UID", () => {
  const production = entitlementDocumentId(uid, "PRODUCTION");
  assert.match(production, /^PRODUCTION_[a-f0-9]{64}$/);
  assert.notEqual(production, entitlementDocumentId(uid, "SANDBOX"));
  assert.notEqual(production, entitlementDocumentId("account-B", "PRODUCTION"));
});
