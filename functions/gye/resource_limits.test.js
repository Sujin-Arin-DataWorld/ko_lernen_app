"use strict";

// B2 — explicit resource bounds on the pack/mastery/rollover triggers, and a
// batched (non-serial) member read inside the weekly rollover transaction.
//
// weekly_goal_rollover has no dedicated unit test today (it is exercised only
// via manual/emulator runs), so the parallel-read assertion below drives the
// real exported trigger (`deployed.weekly_goal_rollover.run(event)`) through
// a minimal hand-built Firestore double that records the order in which
// `transaction.get` calls are requested vs. resolved.

const test = require("node:test");
const assert = require("node:assert/strict");

const deployed = require("./index");
const { getFirestore } = require("firebase-admin/firestore");

test("deleteCloudBackup preserves its deployed resource limits and secret", () => {
  const endpoint = deployed.deleteCloudBackup.__endpoint;
  assert.equal(endpoint.maxInstances, 20);
  assert.equal(endpoint.timeoutSeconds, 60);
  assert.equal(endpoint.availableMemoryMb, 256);
  assert.equal(endpoint.cpu, 1);
  assert.deepEqual(endpoint.region, ["europe-west3"]);
  assert.deepEqual(
    endpoint.secretEnvironmentVariables.map((secret) => secret.key),
    ["DELETION_PROOF_HMAC_KEY"],
  );
});

test("on_pack_cleared carries explicit resource limits", () => {
  const endpoint = deployed.on_pack_cleared.__endpoint;
  assert.equal(endpoint.maxInstances, 20);
  assert.equal(endpoint.timeoutSeconds, 60);
  assert.equal(endpoint.availableMemoryMb, 256);
  assert.equal(endpoint.eventTrigger.retry, true);
});

test("on_course_mastery_checkpoint_written carries explicit resource limits", () => {
  const endpoint = deployed.on_course_mastery_checkpoint_written.__endpoint;
  assert.equal(endpoint.maxInstances, 20);
  assert.equal(endpoint.timeoutSeconds, 60);
  assert.equal(endpoint.availableMemoryMb, 256);
  assert.equal(endpoint.eventTrigger.retry, true);
});

test("weekly_goal_rollover carries explicit resource limits and never overlaps", () => {
  const endpoint = deployed.weekly_goal_rollover.__endpoint;
  assert.equal(endpoint.maxInstances, 1,
    "the scheduler must never run two overlapping rollovers");
  assert.equal(endpoint.timeoutSeconds, 540);
  assert.equal(endpoint.availableMemoryMb, 512);
  assert.equal(endpoint.scheduleTrigger.schedule, "0 0 * * 1");
});

function makeMemberDoc(uid) {
  return {
    id: uid,
    data: () => ({status: "active", nickname: uid, weeklyPacksContributed: 0}),
    ref: {__kind: "memberRef", uid},
  };
}

function makeFeedCollectionFake() {
  const feedFake = {
    doc: (id) => ({__kind: "feedDocRef", id}),
    orderBy: () => feedFake,
    offset: () => feedFake,
    limit: () => feedFake,
    get: async () => ({empty: true, docs: []}),
  };
  return feedFake;
}

test("weekly_goal_rollover requests every member's account_deletions read " +
"before any of them resolves (batched, not serial N+1)", async () => {
  const db = getFirestore();
  const originalCollection = db.collection.bind(db);
  const originalRunTransaction = db.runTransaction.bind(db);

  const memberUids = ["member-1", "member-2", "member-3", "member-4"];
  const memberDocs = memberUids.map(makeMemberDoc);

  const gyeMetaRef = {
    __kind: "gyeMetaRef",
    id: "gye-1",
    collection(name) {
      if (name === "members") return {__kind: "membersCollection"};
      if (name === "bans") return {__kind: "bansCollection"};
      if (name === "feed") return makeFeedCollectionFake();
      if (name === "notification_outbox") {
        return {__kind: "notificationOutboxCollection"};
      }
      throw new Error(`unexpected gye subcollection requested: ${name}`);
    },
  };
  const gyeDoc = {id: "gye-1", ref: gyeMetaRef};

  const callLog = [];
  const fakeTransaction = {
    get: async (ref) => {
      if (ref === gyeMetaRef) {
        return {
          exists: true,
          data: () => ({
            lifecycleState: "active",
            weeklyGoalPacks: 0,
            weeklyGoalProgress: 0,
          }),
        };
      }
      if (ref && ref.__kind === "membersCollection") {
        return {docs: memberDocs};
      }
      if (ref && ref.__kind === "bansCollection") {
        return {docs: []};
      }
      if (ref && ref.__kind === "accountDeletionDocRef") {
        callLog.push({uid: ref.uid, at: "requested"});
        // Yield the event loop so a serial (await-in-loop) implementation
        // would resolve this get before requesting the next member's get.
        await new Promise((resolve) => setImmediate(resolve));
        callLog.push({uid: ref.uid, at: "resolved"});
        return {exists: false};
      }
      throw new Error(`unexpected transaction.get ref: ${JSON.stringify(ref)}`);
    },
    set: () => {},
    update: () => {},
  };

  db.collection = (path) => {
    if (path === "gye") {
      return {get: async () => ({docs: [gyeDoc]})};
    }
    if (path === "account_deletions") {
      return {doc: (uid) => ({__kind: "accountDeletionDocRef", uid})};
    }
    throw new Error(`unexpected top-level collection requested: ${path}`);
  };
  db.runTransaction = async (updateFn) => updateFn(fakeTransaction);

  try {
    await deployed.weekly_goal_rollover.run({
      scheduleTime: new Date().toISOString(),
    });
  } finally {
    db.collection = originalCollection;
    db.runTransaction = originalRunTransaction;
  }

  const requestedUids = callLog
    .filter((entry) => entry.at === "requested")
    .map((entry) => entry.uid)
    .sort();
  assert.deepEqual(requestedUids, [...memberUids].sort(),
    "every member's account_deletions doc must be read exactly once");

  const firstResolvedIndex = callLog.findIndex((entry) => entry.at === "resolved");
  assert.notEqual(firstResolvedIndex, -1, "expected at least one resolved get");
  const requestsBeforeFirstResolve = callLog
    .slice(0, firstResolvedIndex)
    .filter((entry) => entry.at === "requested").length;
  assert.equal(requestsBeforeFirstResolve, memberUids.length,
    "all member account_deletions reads must be in flight before the first " +
    "one resolves — a serial for-loop would interleave request/resolve pairs");
});
