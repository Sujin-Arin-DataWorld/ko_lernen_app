"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const fixtures = require("../../../test/fixtures/access_policy/v2.json");
const {resolveAccess} = require("../access_policy");

test("deployment-package access policy is identical to canonical Gye source", () => {
  const read = (p) => fs.readFileSync(path.join(__dirname, p), "utf8")
    .replace(/\r\n/g, "\n").trimEnd();
  assert.equal(read("../access_policy.js"), read("../../gye/access_policy.js"));
});

for (const entry of fixtures.cases) {
  test(`shared universal access contract: ${entry.name}`, () => {
    assert.deepEqual(resolveAccess(entry), fixtures.expectedSnapshots[entry.name]);
  });
}

test("retired authority inputs cannot alter pronunciation allowance", () => {
  const context = {uid: "account-A", environment: "PRODUCTION", now: 1788436800000};
  const access = resolveAccess({...context, premium: true,
    grant: {status: "active"}, entitlement: {status: "active"}});
  assert.deepEqual(
    [access.source, access.aiPolicyId, access.pronunciationDailyLimit],
    ["universal", "universal_v1", 50],
  );
});
