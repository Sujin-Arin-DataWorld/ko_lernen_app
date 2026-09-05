"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {resolveAccess, subjectHash} = require("./access_policy");
const fixture = require("../../test/fixtures/access_policy/v2.json");

test("shared v2 fixture covers every policy case exactly once", () => {
  const names = fixture.cases.map((entry) => entry.name);
  assert.equal(new Set(names).size, names.length);
  assert.deepEqual(Object.keys(fixture.expectedSnapshots).sort(), [...names].sort());
});

for (const entry of fixture.cases) {
  test(`shared universal wire snapshot: ${entry.name}`, () => {
    const actual = resolveAccess(entry);
    assert.deepEqual(actual, fixture.expectedSnapshots[entry.name]);
    assert.equal(Object.isFrozen(actual), true);
    assert.deepEqual(
      [actual.source, actual.contentAccess, actual.aiPolicyId,
        actual.bookDailyLimit, actual.pronunciationDailyLimit],
      ["universal", "all", "universal_v1", 20, 50],
    );
    assert.equal(actual.accessUntil, undefined);
    assert.equal(actual.offlineUntil, undefined);
  });
}

test("legacy authority and caller-forged premium fields cannot change access", () => {
  const context = {uid: "account-A", environment: "PRODUCTION", now: 1788436800000};
  const expected = resolveAccess(context);
  const forged = resolveAccess({
    ...context,
    phase: "paid",
    premium: true,
    betaUnlockAll: true,
    accountCreatedAt: 1,
    grant: {status: "active", kind: "closed_tester_lifetime", revision: 999},
    entitlement: {status: "active", accessUntil: Number.MAX_SAFE_INTEGER},
  });
  assert.deepEqual(forged, expected);
});

test("revision is stable across time and separated by identity and environment", () => {
  const context = {uid: "account-A", environment: "PRODUCTION", now: 1};
  const revision = resolveAccess(context).revision;
  assert.equal(resolveAccess({...context, now: 2}).revision, revision);
  assert.notEqual(resolveAccess({...context, uid: "account-B"}).revision, revision);
  assert.notEqual(resolveAccess({...context, environment: "SANDBOX"}).revision, revision);
});

test("untrusted identity, environment and clock fail closed", () => {
  const context = {uid: "account-A", environment: "PRODUCTION", now: 1};
  for (const overrides of [
    {uid: ""}, {uid: "../other"}, {uid: "a/b"}, {uid: "a\n"},
    {uid: "a".repeat(129)}, {environment: "typo"}, {now: -1},
    {now: 1.5}, {now: NaN},
  ]) {
    assert.throws(() => resolveAccess({...context, ...overrides}));
  }
});

test("rate-limit subject hashes are stable and contain no raw UID", () => {
  const hash = subjectHash("account-A");
  assert.match(hash, /^[a-f0-9]{64}$/);
  assert.notEqual(hash, subjectHash("account-B"));
  assert.throws(() => subjectHash("../account-A"));
});
