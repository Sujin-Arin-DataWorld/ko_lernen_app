"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const {validateApprovedRoster, createGrantManager} = require("./premium_grants");

const now = 1788436800000;
const roster = () => ({schemaVersion: 1, approvedBy: "Jin",
  approvalRef: "approval-2026-09-03", environment: "PRODUCTION",
  action: "grant", uids: ["tester-A"]});
function harness() {
  const data = new Map();
  let writes = 0;
  const firestore = {collection: (name) => ({doc: (id) => ({path: `${name}/${id}`})}),
    async runTransaction(callback) {
      const pending = [];
      const result = await callback({
        get: async (ref) => ({exists: data.has(ref.path), data: () => data.get(ref.path)}),
        set: (ref, value) => pending.push([ref.path, value]),
      });
      for (const [path, value] of pending) { data.set(path, value); writes++; }
      return result;
    }};
  let user = {uid: "tester-A", disabled: false, providerData: [{providerId: "google.com"}],
    metadata: {creationTime: new Date(now - 86400000).toUTCString()}};
  return {data, get writes() {return writes;}, set user(value) {user = value;},
    manager: createGrantManager({firestore, auth: {getUser: async () => user}, now: () => now})};
}

test("requires an explicit bounded Jin-approved UID roster, not feedback or emails", () => {
  assert.deepEqual(validateApprovedRoster(roster()), roster());
  for (const patch of [{approvedBy: "self"}, {approvalRef: ""}, {environment: "dev"},
    {uids: []}, {uids: ["a/b"]}, {uids: ["tester-A", "tester-A"]}, {action: "anything"},
    {schemaVersion: 2}, {emails: ["private@example.test"]}]) {
    assert.throws(() => validateApprovedRoster({...roster(), ...patch}));
  }
});

test("dry-run is default and never writes grants, usage or feedback", async () => {
  const h = harness();
  const result = await h.manager.applyRoster(roster());
  assert.equal(h.writes, 0);
  assert.deepEqual(result.counts, {create: 1, update: 0, unchanged: 0});
  assert.equal(JSON.stringify(result).includes("tester-A"), false);
});

test("explicit apply creates a lifetime grant with approval evidence only", async () => {
  const h = harness();
  await h.manager.applyRoster(roster(), {apply: true});
  const grant = h.data.get("premium_grants/tester-A");
  assert.equal(grant.kind, "closed_tester_lifetime");
  assert.equal(grant.status, "active");
  assert.equal(grant.revision, 1);
  assert.equal(grant.approvedBy, "Jin");
  assert.equal(grant.ownerUid, "tester-A");
  assert.equal(grant.environment, "PRODUCTION");
  assert.equal(grant.approvedAt, now);
  assert.equal(h.data.size, 1);
  const result = await h.manager.applyRoster(roster(), {apply: true});
  assert.equal(result.counts.unchanged, 1);
  assert.equal(h.writes, 1);
});

test("revocation and reinstatement require a new approval reference and revision", async () => {
  const h = harness();
  await h.manager.applyRoster(roster(), {apply: true});
  await assert.rejects(h.manager.applyRoster({...roster(), action: "revoke"}, {apply: true}));
  await h.manager.applyRoster({...roster(), action: "revoke", approvalRef: "revoke-2"}, {apply: true});
  assert.equal(h.data.get("premium_grants/tester-A").status, "revoked");
  assert.equal(h.data.get("premium_grants/tester-A").revision, 2);
  await h.manager.applyRoster({...roster(), approvalRef: "reinstate-3"}, {apply: true});
  assert.equal(h.data.get("premium_grants/tester-A").revision, 3);
});

test("deletion, foreign environment, anonymous and disabled accounts fail closed", async () => {
  for (const setup of [
    (h) => h.data.set("account_deletions/tester-A", {state: "requested"}),
    (h) => h.data.set("premium_grants/tester-A", {environment: "SANDBOX"}),
    (h) => {h.user = {uid: "tester-A", providerData: []};},
    (h) => {h.user = {uid: "tester-A", disabled: true, providerData: [{providerId: "apple.com"}]};},
  ]) {
    const h = harness(); setup(h);
    await assert.rejects(h.manager.applyRoster(roster(), {apply: true}));
    assert.equal(h.writes, 0);
  }
});

test("a recreated UID cannot inherit an old approval automatically", async () => {
  const h = harness();
  await h.manager.applyRoster(roster(), {apply: true});
  h.user = {uid: "tester-A", providerData: [{providerId: "apple.com"}],
    metadata: {creationTime: new Date(now).toUTCString()}};
  await assert.rejects(h.manager.applyRoster(roster(), {apply: true}));
  await h.manager.applyRoster({...roster(), approvalRef: "new-account-approval"}, {apply: true});
  assert.equal(h.data.get("premium_grants/tester-A").revision, 2);
});
