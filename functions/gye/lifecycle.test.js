"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  ANONYMIZED_UID,
  accountTombstoneCleanupAction,
  anonymizeFeed,
  anonymizeMeta,
  anonymizeReport,
  anonymizeSticker,
  buildGroupCleanupPlan,
  buildOwnerSuspensionPlan,
  chunkItems,
  eligibleModerationReporterUids,
  groupDeletionUserUids,
  isDurableReporterAuth,
  isAccountDeletionTombstoneOldEnough,
  memberDeleteTriggerPlan,
  processedPackKey,
  pendingReporterUids,
  selectSuccessor,
  selectPushRecipientUids,
  shouldCreditPackClear,
  shouldDeleteReportForUid,
  shouldProcessWeeklyRollover,
  weeklyRolloverKey,
} = require("./lifecycle");

test("successor selection is deterministic and excludes suspended or banned", () => {
  const members = [
    { uid: "z", role: "member", status: "active", joinedAtMillis: 100 },
    { uid: "b", role: "member", status: "suspended", joinedAtMillis: 1 },
    { uid: "a", role: "member", status: "active", joinedAtMillis: 100 },
    { uid: "c", role: "member", status: "active", joinedAtMillis: 50 },
  ];

  assert.equal(selectSuccessor(members, new Set(["c"])).uid, "a");
  assert.equal(selectSuccessor(members, new Set(["a", "c"])).uid, "z");
  assert.equal(
    selectSuccessor(members, new Set(["a", "c", "z"])),
    null,
  );
});

test("non-owner removal keeps the group and exact remaining count", () => {
  assert.deepEqual(
    buildGroupCleanupPlan({
      departingUid: "member",
      ownerId: "owner",
      members: [
        { uid: "owner", role: "owner", status: "active" },
        { uid: "member", role: "member", status: "active" },
      ],
      bannedUids: new Set(),
    }),
    {
      action: "removeMember",
      departingUid: "member",
      successorUid: null,
      memberCount: 1,
    },
  );
});

test("owner removal transfers to deterministic active successor", () => {
  const plan = buildGroupCleanupPlan({
    departingUid: "owner",
    ownerId: "owner",
    members: [
      { uid: "owner", role: "owner", status: "active" },
      { uid: "later", role: "member", status: "active", joinedAtMillis: 20 },
      { uid: "first", role: "member", status: "active", joinedAtMillis: 10 },
    ],
    bannedUids: new Set(),
  });

  assert.deepEqual(plan, {
    action: "transferOwner",
    departingUid: "owner",
    successorUid: "first",
    memberCount: 2,
  });
});

test("owner removal deletes group when only suspended or banned members remain", () => {
  const plan = buildGroupCleanupPlan({
    departingUid: "owner",
    ownerId: "owner",
    members: [
      { uid: "owner", role: "owner", status: "active" },
      { uid: "suspended", role: "member", status: "suspended" },
      { uid: "banned", role: "member", status: "active" },
    ],
    bannedUids: new Set(["banned"]),
  });

  assert.deepEqual(plan, {
    action: "deleteGroup",
    departingUid: "owner",
    successorUid: null,
    memberCount: 0,
  });
});

test("owner suspension transfers to the deterministic eligible successor", () => {
  assert.deepEqual(
    buildOwnerSuspensionPlan({
      targetUid: "owner",
      ownerId: "owner",
      members: [
        { uid: "owner", status: "active", joinedAtMillis: 1 },
        { uid: "later", status: "active", joinedAtMillis: 20 },
        { uid: "first", status: "active", joinedAtMillis: 10 },
        { uid: "banned", status: "active", joinedAtMillis: 2 },
      ],
      bannedUids: new Set(["banned"]),
    }),
    { action: "transferOwner", successorUid: "first" },
  );
});

test("owner suspension deletes a group with no eligible successor", () => {
  assert.deepEqual(
    buildOwnerSuspensionPlan({
      targetUid: "owner",
      ownerId: "owner",
      members: [
        { uid: "owner", status: "active" },
        { uid: "suspended", status: "suspended" },
        { uid: "banned", status: "active" },
      ],
      bannedUids: new Set(["banned"]),
    }),
    { action: "deleteGroup", successorUid: null },
  );
});

test("owner suspension never promotes an account deleting member", () => {
  assert.deepEqual(
    buildOwnerSuspensionPlan({
      targetUid: "owner",
      ownerId: "owner",
      members: [
        { uid: "owner", status: "active" },
        { uid: "deleting", status: "active" },
      ],
      // Runtime unions active bans and account-deletion marker UIDs here.
      bannedUids: new Set(["deleting"]),
    }),
    { action: "deleteGroup", successorUid: null },
  );
});

test("non-owner suspension preserves ownership", () => {
  assert.deepEqual(
    buildOwnerSuspensionPlan({
      targetUid: "member",
      ownerId: "owner",
      members: [
        { uid: "owner", status: "active" },
        { uid: "member", status: "active" },
      ],
      bannedUids: new Set(),
    }),
    { action: "suspendMember", successorUid: null },
  );
});

test("push recipients exclude suspended, banned, and deleting accounts", () => {
  assert.deepEqual(
    selectPushRecipientUids(
      [
        { uid: "active", status: "active" },
        { uid: "suspended", status: "suspended" },
        { uid: "banned", status: "active" },
        { uid: "deleting", status: "active" },
      ],
      new Set(["banned"]),
      new Set(["deleting"]),
    ),
    ["active"],
  );
});

test("group deletion clears every surviving member cache exactly once", () => {
  assert.deepEqual(
    groupDeletionUserUids([
      { uid: "suspended", status: "suspended" },
      { uid: "banned", status: "active" },
      { uid: "suspended", status: "suspended" },
    ], "deleted-owner"),
    ["banned", "deleted-owner", "suspended"],
  );
});

test("pack clear credit is transition and lifetime-receipt bounded", () => {
  assert.equal(shouldCreditPackClear({
    beforeStatus: "inProgress",
    afterStatus: "cleared",
  }), true);
  assert.equal(shouldCreditPackClear({
    beforeStatus: "cleared",
    afterStatus: "cleared",
  }), false);
  assert.equal(shouldCreditPackClear({
    beforeStatus: undefined,
    afterStatus: "cleared",
  }), true);
  assert.equal(shouldCreditPackClear({
    beforeStatus: "inProgress",
    afterStatus: "cleared",
    receiptExists: true,
  }), false);
});

test("automatic moderation counts only distinct pending reporters", () => {
  assert.deepEqual(
    pendingReporterUids([
      { reporterUid: "b", status: "pending" },
      { reporterUid: "a", status: "pending" },
      { reporterUid: "a", status: "pending" },
      { reporterUid: "reviewed", status: "reviewed" },
      { reporterUid: "target", status: "pending" },
      { reporterUid: ANONYMIZED_UID, status: "pending" },
    ], "target"),
    ["a", "b"],
  );
});

test("automatic moderation requires a linked durable reporter", () => {
  assert.equal(isDurableReporterAuth({
    disabled: false,
    providerData: [{ providerId: "password" }],
  }), true);
  assert.equal(isDurableReporterAuth({
    disabled: false,
    providerData: [],
  }), false);
  assert.equal(isDurableReporterAuth({
    disabled: true,
    providerData: [{ providerId: "google.com" }],
  }), false);
  assert.equal(isDurableReporterAuth(null), false);
});

test("automatic moderation ignores departed, suspended, and deleting reporters",
() => {
  assert.deepEqual(
    eligibleModerationReporterUids(
      ["active", "departed", "suspended", "deleting"],
      [
        { uid: "active", status: "active" },
        { uid: "suspended", status: "suspended" },
        { uid: "deleting", status: "active" },
      ],
      new Set(["deleting"]),
    ),
    ["active"],
  );
});

test("duplicate delivery after membership removal becomes a safe no-op", () => {
  assert.deepEqual(
    buildGroupCleanupPlan({
      departingUid: "gone",
      ownerId: "owner",
      members: [{ uid: "owner", role: "owner", status: "active" }],
      bannedUids: new Set(),
    }),
    {
      action: "noop",
      departingUid: "gone",
      successorUid: null,
      memberCount: 1,
    },
  );
});

test("partial owner cleanup repairs orphaned ownerId after member was deleted", () => {
  assert.deepEqual(
    buildGroupCleanupPlan({
      departingUid: "owner",
      ownerId: "owner",
      members: [
        { uid: "successor", role: "member", status: "active" },
      ],
      bannedUids: new Set(),
    }),
    {
      action: "transferOwner",
      departingUid: "owner",
      successorUid: "successor",
      memberCount: 1,
    },
  );
});

test("account cleanup never promotes an account deleting member", () => {
  assert.deepEqual(
    buildGroupCleanupPlan({
      departingUid: "owner",
      ownerId: "owner",
      members: [
        { uid: "owner", status: "active" },
        { uid: "deleting", status: "active" },
      ],
      bannedUids: new Set(["deleting"]),
    }),
    {
      action: "deleteGroup",
      departingUid: "owner",
      successorUid: null,
      memberCount: 0,
    },
  );
});

test("feed anonymization covers actor, payload target, and MVP identities", () => {
  const source = {
    type: "goal_achieved",
    actorUid: "departing",
    actorNickname: "PII actor",
    payload: {
      targetUid: "departing",
      targetNickname: "PII target",
      mvpUid: "departing",
      mvp: "PII MVP",
      untouched: 7,
    },
    unrelated: true,
  };

  const once = anonymizeFeed(source, "departing");
  const twice = anonymizeFeed(once, "departing");
  assert.deepEqual(twice, once);
  assert.equal(once.actorUid, ANONYMIZED_UID);
  assert.equal(once.actorNickname, "Deleted member");
  assert.equal(once.payload.targetUid, ANONYMIZED_UID);
  assert.equal(once.payload.targetNickname, "Deleted member");
  assert.equal(once.payload.mvpUid, ANONYMIZED_UID);
  assert.equal(once.payload.mvp, "Deleted member");
  assert.equal(once.payload.untouched, 7);
  assert.equal(once.unrelated, true);
});

test("reports anonymize reporter/target and erase free-text PII note", () => {
  const source = {
    reporterUid: "reporter",
    targetUid: "target",
    note: "name@example.com",
    reason: "spam",
    status: "pending",
  };

  const reporterGone = anonymizeReport(source, "reporter");
  assert.equal(reporterGone.reporterUid, ANONYMIZED_UID);
  assert.equal(reporterGone.targetUid, "target");
  assert.equal(reporterGone.note, "");
  assert.equal(reporterGone.reason, "spam");

  const targetGone = anonymizeReport(source, "target");
  assert.equal(targetGone.targetUid, ANONYMIZED_UID);
  assert.equal(targetGone.note, "");
});

test("leaving either side deletes deterministic and legacy report documents",
() => {
  const report = { reporterUid: "reporter", targetUid: "target" };
  assert.equal(shouldDeleteReportForUid(report, "reporter"), true);
  assert.equal(shouldDeleteReportForUid(report, "target"), true);
  assert.equal(shouldDeleteReportForUid(report, "other"), false);
});

test("stickers anonymize sender and preserve unrelated fields", () => {
  const source = {
    senderUid: "departing",
    senderNickname: "PII",
    stickerCode: 5,
    targetEventId: "event",
  };
  const result = anonymizeSticker(source, "departing");
  assert.equal(result.senderUid, ANONYMIZED_UID);
  assert.equal(result.senderNickname, "Deleted member");
  assert.equal(result.stickerCode, 5);
  assert.equal(result.targetEventId, "event");
  assert.deepEqual(anonymizeSticker(result, "departing"), result);
});

test("meta MVP identity is matchable and anonymized without touching counts", () => {
  const result = anonymizeMeta({
    ownerId: "owner",
    lastWeekMvpUid: "departing",
    lastWeekMvp: "PII",
    lastWeekMvpPacks: 9,
    memberCount: 3,
  }, "departing");

  assert.equal(result.lastWeekMvpUid, ANONYMIZED_UID);
  assert.equal(result.lastWeekMvp, "Deleted member");
  assert.equal(result.lastWeekMvpPacks, 9);
  assert.equal(result.memberCount, 3);
});

test("legacy MVP/feed records use exact departing nickname when UID is absent", () => {
  const feed = anonymizeFeed({
    actorUid: "other",
    actorNickname: "Other",
    payload: { mvp: "Legacy PII" },
  }, "departing", "Legacy PII");
  assert.equal(feed.payload.mvpUid, ANONYMIZED_UID);
  assert.equal(feed.payload.mvp, "Deleted member");

  const meta = anonymizeMeta({
    lastWeekMvp: "Legacy PII",
    lastWeekMvpPacks: 4,
  }, "departing", "Legacy PII");
  assert.equal(meta.lastWeekMvpUid, ANONYMIZED_UID);
  assert.equal(meta.lastWeekMvp, "Deleted member");
});

test("unrelated documents remain byte-for-byte equivalent", () => {
  const source = {
    actorUid: "someone-else",
    actorNickname: "Safe",
    payload: { targetUid: "other", mvpUid: "another", value: 1 },
  };
  assert.deepEqual(anonymizeFeed(source, "departing"), source);
});

test("chunk partition stays below batch limit for 500+ mutations", () => {
  const items = Array.from({ length: 1203 }, (_, index) => index);
  const chunks = chunkItems(items, 450);

  assert.deepEqual(chunks.map((chunk) => chunk.length), [450, 450, 303]);
  assert.deepEqual(chunks.flat(), items);
  assert.ok(chunks.every((chunk) => chunk.length < 500));
});

test("partial retry is deterministic and duplicate-safe", () => {
  const documents = [
    { actorUid: "departing", actorNickname: "A", payload: {} },
    { actorUid: "departing", actorNickname: "B", payload: {} },
    { actorUid: "other", actorNickname: "C", payload: {} },
  ];
  const partial = [
    anonymizeFeed(documents[0], "departing"),
    documents[1],
    documents[2],
  ];
  const retried = partial.map((doc) => anonymizeFeed(doc, "departing"));
  const singlePass = documents.map((doc) => anonymizeFeed(doc, "departing"));

  assert.deepEqual(retried, singlePass);
});

test("concurrent identity transforms compose in either order", () => {
  const source = {
    actorUid: "actor-a",
    actorNickname: "Actor A",
    payload: {
      targetUid: "target-b",
      targetNickname: "Target B",
    },
  };
  const aThenB = anonymizeFeed(
    anonymizeFeed(source, "actor-a"),
    "target-b",
  );
  const bThenA = anonymizeFeed(
    anonymizeFeed(source, "target-b"),
    "actor-a",
  );
  assert.deepEqual(aThenB, bThenA);
  assert.equal(aThenB.actorUid, ANONYMIZED_UID);
  assert.equal(aThenB.payload.targetUid, ANONYMIZED_UID);
});

test("member-delete trigger never removes a rapid rejoin", () => {
  assert.deepEqual(memberDeleteTriggerPlan(null, "old"), {
    anonymizeIdentity: false,
    completeDepartureMarker: false,
    reconcileMembership: false,
  });
  assert.deepEqual(memberDeleteTriggerPlan({
    state: "complete",
    membershipId: "old",
  }, "old"), {
    anonymizeIdentity: false,
    completeDepartureMarker: false,
    reconcileMembership: false,
  });
  assert.deepEqual(memberDeleteTriggerPlan({
    state: "pending",
    membershipId: "new",
  }, "old"), {
    anonymizeIdentity: false,
    completeDepartureMarker: false,
    reconcileMembership: false,
  });
  assert.deepEqual(memberDeleteTriggerPlan({
    state: "pending",
    membershipId: "old",
  }, "old"), {
    anonymizeIdentity: true,
    completeDepartureMarker: true,
    reconcileMembership: false,
  });
});

test("account deletion tombstones require the full safety window", () => {
  const day = 24 * 60 * 60 * 1000;
  const now = 10 * day;
  assert.equal(
    isAccountDeletionTombstoneOldEnough(now - day + 1, now),
    false,
  );
  assert.equal(
    isAccountDeletionTombstoneOldEnough(now - day, now),
    true,
  );
  assert.equal(isAccountDeletionTombstoneOldEnough(undefined, now), false);
});

test("account tombstone cleanup uses a second post-Auth safety window", () => {
  const day = 24 * 60 * 60 * 1000;
  const now = 10 * day;
  assert.equal(accountTombstoneCleanupAction({
    authUserExists: false,
    firestoreUserExists: false,
    authMissingSinceMillis: undefined,
    nowMillis: now,
  }), "markMissing");
  assert.equal(accountTombstoneCleanupAction({
    authUserExists: false,
    firestoreUserExists: false,
    authMissingSinceMillis: now - day + 1,
    nowMillis: now,
  }), "retain");
  assert.equal(accountTombstoneCleanupAction({
    authUserExists: false,
    firestoreUserExists: false,
    authMissingSinceMillis: now - day,
    nowMillis: now,
  }), "delete");
  assert.equal(accountTombstoneCleanupAction({
    authUserExists: true,
    firestoreUserExists: false,
    authMissingSinceMillis: now - day,
    nowMillis: now,
  }), "clearMissing");
});

test("abandoned account deletion unbricks only while both records exist", () => {
  const day = 24 * 60 * 60 * 1000;
  const now = 10 * day;
  assert.equal(accountTombstoneCleanupAction({
    authUserExists: true,
    firestoreUserExists: true,
    authMissingSinceMillis: undefined,
    nowMillis: now,
  }), "cancel");
  assert.equal(accountTombstoneCleanupAction({
    authUserExists: true,
    firestoreUserExists: false,
    authMissingSinceMillis: undefined,
    nowMillis: now,
  }), "retain");
});

test("pack processing key is deterministic and does not expose the UID", () => {
  const first = processedPackKey("private-user", "pack-1");
  assert.equal(first, processedPackKey("private-user", "pack-1"));
  assert.notEqual(first, processedPackKey("private-user", "pack-2"));
  assert.equal(first.length, 64);
  assert.equal(first.includes("private-user"), false);
});

test("weekly rollover key is stable in Korea time and monotonic", () => {
  const key = weeklyRolloverKey("2026-07-26T15:00:00.000Z");
  assert.equal(key, "2026-07-27");
  assert.equal(shouldProcessWeeklyRollover(undefined, key), true);
  assert.equal(shouldProcessWeeklyRollover("2026-07-20", key), true);
  assert.equal(shouldProcessWeeklyRollover(key, key), false);
  assert.equal(shouldProcessWeeklyRollover("2026-08-03", key), false);
  assert.equal(
    shouldProcessWeeklyRollover(key, "2026-08-03"),
    true,
  );
});
