"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  buildDeletionCleanupTargetClaim,
  cleanupGyeForDeletedUser,
  deletionCleanupTargetClaimMatches,
  mergeDeletionCleanupGyeIds,
  orphanGyeCleanupUserIds,
  processNotificationDocuments,
  runDeletedUserCleanupRuntime,
  stageNotificationOutboxWrites,
} = require("./runtime");

test("cleanup target receipt survives a retry after membership disappeared",
() => {
  const firstAttempt = mergeDeletionCleanupGyeIds([], ["ABC234"]);
  const secondAttempt = mergeDeletionCleanupGyeIds(firstAttempt, []);
  assert.deepEqual(firstAttempt, ["ABC234"]);
  assert.deepEqual(secondAttempt, ["ABC234"]);
});

test("concurrent discovery cannot certify an older incomplete target snapshot",
() => {
  const first = buildDeletionCleanupTargetClaim({
    retainedGyeIds: [],
    discoveredGyeIds: ["ABC234"],
    currentRevision: 0,
  });
  const concurrent = buildDeletionCleanupTargetClaim({
    retainedGyeIds: first.gyeIds,
    discoveredGyeIds: ["XYZ789"],
    currentRevision: first.revision,
  });
  assert.deepEqual(concurrent, {
    gyeIds: ["ABC234", "XYZ789"],
    revision: 2,
  });
  assert.equal(deletionCleanupTargetClaimMatches({
    cleanupGyeIds: concurrent.gyeIds,
    cleanupRevision: concurrent.revision,
  }, first), false);
  assert.equal(deletionCleanupTargetClaimMatches({
    cleanupGyeIds: concurrent.gyeIds,
    cleanupRevision: concurrent.revision,
  }, concurrent), true);
});

test("orphan cleanup includes stale user caches after member docs disappeared",
() => {
  assert.deepEqual(orphanGyeCleanupUserIds(
    ["surviving-member"],
    ["surviving-member", "member-doc-already-deleted"],
  ), ["member-doc-already-deleted", "surviving-member"]);
});

test("missing Gye parent routes through orphan cleanup before completion",
async () => {
  const calls = [];
  await runDeletedUserCleanupRuntime({
    cleanupGyes: async () => {
      await cleanupGyeForDeletedUser({
        anonymizeIdentity: async () => calls.push("anonymize"),
        reconcileMembership: async () => {
          calls.push("reconcile");
          return "missing";
        },
        cleanupOrphanTree: async () => calls.push("orphan-tree"),
      });
    },
    cleanupSharedPacks: async () => calls.push("shared-packs"),
    cleanupProcessedPacks: async () => calls.push("processed-packs"),
    cleanupNotificationOutboxes: async () => calls.push("outboxes"),
    markCleanupComplete: async () => calls.push("complete"),
  });
  assert.deepEqual(calls, [
    "anonymize",
    "reconcile",
    "orphan-tree",
    "shared-packs",
    "processed-packs",
    "outboxes",
    "complete",
  ]);
});

test("orphan recursive cleanup failure prevents completion receipt", async () => {
  const calls = [];
  await assert.rejects(runDeletedUserCleanupRuntime({
    cleanupGyes: async () => {
      await cleanupGyeForDeletedUser({
        anonymizeIdentity: async () => calls.push("anonymize"),
        reconcileMembership: async () => "missing",
        cleanupOrphanTree: async () => {
          calls.push("orphan-tree");
          throw new Error("recursive delete failed");
        },
      });
    },
    cleanupSharedPacks: async () => calls.push("shared-packs"),
    cleanupProcessedPacks: async () => calls.push("processed-packs"),
    cleanupNotificationOutboxes: async () => calls.push("outboxes"),
    markCleanupComplete: async () => calls.push("complete"),
  }), /recursive delete failed/);
  assert.deepEqual(calls, ["anonymize", "orphan-tree"]);
});

test("weekly outboxes are staged through the caller's transaction", () => {
  const writes = [];
  const transaction = {
    set: (ref, data) => writes.push({ ref, data }),
  };
  const outboxCollection = {
    doc: (id) => `notification_outbox/${id}`,
  };
  stageNotificationOutboxWrites({
    transaction,
    outboxCollection,
    notifications: [
      {
        id: "one",
        uid: "member-a",
        eventKey: "weekly:ABC234:2026-07-27",
        title: "Title",
        body: "Body",
        state: "pending",
      },
      {
        id: "two",
        uid: "member-b",
        eventKey: "weekly:ABC234:2026-07-27",
        title: "Title",
        body: "Body",
        state: "pending",
      },
    ],
    serverTimestamp: "SERVER_TIME",
  });
  assert.equal(writes.length, 2);
  assert.deepEqual(writes.map((write) => write.ref), [
    "notification_outbox/one",
    "notification_outbox/two",
  ]);
  assert.ok(writes.every((write) =>
    write.data.createdAt === "SERVER_TIME" &&
    write.data.nextAttemptAt === "SERVER_TIME" &&
    write.data.attemptCount === 0));
});

test("notification batch continues after failures then reports aggregate",
async () => {
  const attempted = [];
  await assert.rejects(processNotificationDocuments(
    [{ id: "bad" }, { id: "good" }],
    async (document) => {
      attempted.push(document.id);
      if (document.id === "bad") throw new Error("temporary");
    },
  ), /failed for 1 document/);
  assert.deepEqual(attempted, ["bad", "good"]);
});
