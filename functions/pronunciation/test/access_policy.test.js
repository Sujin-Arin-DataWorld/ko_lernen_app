"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const fixtures = require("../../../test/fixtures/access_policy/v1.json");
const {resolveAccess} = require("../access_policy");

test("deployment-package access policy is identical to canonical Gye source", () => {
  const read = (p) => fs.readFileSync(path.join(__dirname, p), "utf8").replace(/\r\n/g, "\n").trimEnd();
  assert.equal(read("../access_policy.js"), read("../../gye/access_policy.js"));
});

for (const c of fixtures.cases) {
  test(`shared access contract: ${c.name}`, () => {
    const access = resolveAccess({uid: fixtures.uid, now: fixtures.now,
      accountCreatedAt: Object.hasOwn(c, "accountCreatedAt") ? c.accountCreatedAt : fixtures.accountCreatedAt,
      environment: c.environment || "PRODUCTION", phase: c.phase || "free_launch",
      grant: c.grant ? {...fixtures.grant, ...c.grant} : null,
      entitlement: c.entitlement ? {...fixtures.entitlement, ...c.entitlement} : null});
    assert.equal(access.source, c.wantSource);
    assert.equal(access.contentAccess, c.wantContent);
    assert.equal(access.bookDailyLimit, c.wantBook);
    assert.equal(access.pronunciationDailyLimit, c.wantPronunciation);
  });
}
