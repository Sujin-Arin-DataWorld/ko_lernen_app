"use strict";

const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const assert = require("node:assert/strict");
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const {
  Timestamp,
  collection,
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  getDocs,
  increment,
  serverTimestamp,
  setDoc,
  writeBatch,
} = require("firebase/firestore");

const projectId = "demo-hangul-sori";
let environment;

test.before(async () => {
  environment = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: fs.readFileSync(
        path.resolve(__dirname, "../../firestore.rules"),
        "utf8",
      ),
    },
  });
});

test.after(async () => {
  await environment.cleanup();
});

test.beforeEach(async () => {
  await environment.clearFirestore();
});

function client(uid) {
  return environment.authenticatedContext(uid).firestore();
}

function membershipIdFor(uid, generation = "one") {
  return `membership-${uid}-${generation}-0123456789abcdef`;
}

function memberData(
  uid,
  role = "member",
  status = "active",
  membershipId = membershipIdFor(uid),
) {
  return {
    uid,
    membershipId,
    nickname: uid.slice(0, 12),
    joinedAt: Timestamp.now(),
    role,
    weeklyPacksContributed: 0,
    status,
    level: 1,
    streakDays: 0,
  };
}

function feedData(uid) {
  return {
    type: "sticker",
    actorUid: uid,
    actorNickname: uid.slice(0, 12),
    payload: { stickerCode: 1 },
    createdAt: serverTimestamp(),
  };
}

function packData(overrides = {}) {
  return {
    level: "A1",
    status: "inProgress",
    wordsLearned: 5,
    wordsTotal: 10,
    bossAccuracy: 0.5,
    attempts: 1,
    clearedAt: null,
    updatedAt: serverTimestamp(),
    ...overrides,
  };
}

function bookshelfRecordData(id, overrides = {}) {
  return {
    schema_version: 1,
    id,
    revision: 1,
    deleted: false,
    portable: { title: "한국어", words: [] },
    canonical_hash: "a".repeat(64),
    updated_at: serverTimestamp(),
    ...overrides,
  };
}

function bookshelfManifestData(generationId, revision, recordIds, overrides = {}) {
  return {
    schema_version: 1,
    generation_id: generationId,
    revision,
    record_ids: recordIds,
    completed: true,
    operation_id: `operation-${revision}`,
    content_hash: "b".repeat(64),
    activated_at: serverTimestamp(),
    ...overrides,
  };
}

function packMembershipData(revision, packIds, overrides = {}) {
  return {
    revision,
    pack_ids: packIds,
    updatedAt: serverTimestamp(),
    ...overrides,
  };
}

function reportRef(db, gyeId, targetUid, reporterUid) {
  return doc(
    db,
    "gye",
    gyeId,
    "reports",
    `${targetUid}_${reporterUid}`,
  );
}

async function seedUser(uid, gyeIds = []) {
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "users", uid), {
      gyeIds,
      blockedUids: [],
      fcmTokens: [],
    });
  });
}

async function seedGye(gyeId, members, {
  ownerId = members[0],
  statuses = {},
  bans = [],
} = {}) {
  await environment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, "gye", gyeId), {
      name: gyeId,
      code: gyeId,
      ownerId,
      memberCount: members.length,
      lifecycleState: "active",
      createdAt: Timestamp.now(),
      weeklyGoalPacks: 10,
      weeklyGoalProgress: 0,
      lifetimeGoalsAchieved: 0,
      xpBoostActive: false,
    });
    for (const uid of members) {
      await setDoc(
        doc(db, "gye", gyeId, "members", uid),
        memberData(
          uid,
          uid === ownerId ? "owner" : "member",
          statuses[uid] || "active",
        ),
      );
    }
    for (const uid of bans) {
      await setDoc(doc(db, "gye", gyeId, "bans", uid), {
        uid,
        active: true,
      });
    }
  });
}

function queueJoin(
  db,
  batch,
  gyeId,
  uid,
  newGyeIds,
  membershipId = membershipIdFor(uid),
) {
  batch.set(doc(db, "gye", gyeId, "members", uid), {
    ...memberData(uid, "member", "active", membershipId),
    joinedAt: serverTimestamp(),
  });
  batch.update(doc(db, "gye", gyeId), { memberCount: increment(1) });
  batch.update(doc(db, "users", uid), { gyeIds: newGyeIds });
}

function queueLeave(
  db,
  batch,
  gyeId,
  uid,
  newGyeIds,
  membershipId = membershipIdFor(uid),
) {
  batch.set(doc(db, "gye", gyeId, "departures", uid), {
    uid,
    membershipId,
    nickname: uid.slice(0, 12),
    state: "pending",
    createdAt: serverTimestamp(),
  });
  batch.delete(doc(db, "gye", gyeId, "members", uid));
  batch.update(doc(db, "gye", gyeId), { memberCount: increment(-1) });
  batch.update(doc(db, "users", uid), { gyeIds: newGyeIds });
}

function queueCreateGye(db, batch, gyeId, uid, overrides = {}) {
  batch.set(doc(db, "gye", gyeId), {
    name: "Fresh Gye",
    code: gyeId,
    ownerId: uid,
    memberCount: 1,
    lifecycleState: "active",
    createdAt: serverTimestamp(),
    weeklyGoalPacks: 10,
    weeklyGoalProgress: 0,
    lifetimeGoalsAchieved: 0,
    xpBoostActive: false,
    ...overrides,
  });
  batch.set(doc(db, "gye", gyeId, "members", uid), {
    ...memberData(uid, "owner"),
    joinedAt: serverTimestamp(),
  });
  batch.set(doc(db, "users", uid), { gyeIds: [gyeId] }, { merge: true });
}

test("valid createGye three-write batch succeeds", async () => {
  await seedUser("owner", []);
  const db = client("owner");
  const batch = writeBatch(db);
  queueCreateGye(db, batch, "NEW234", "owner");

  await assertSucceeds(batch.commit());
});

test("Gye creation rejects progress tampering and unknown fields", async () => {
  await seedUser("owner", []);
  const db = client("owner");
  const progressTamper = writeBatch(db);
  queueCreateGye(db, progressTamper, "BAD234", "owner", {
    lifetimeGoalsAchieved: 99,
  });
  await assertFails(progressTamper.commit());

  const unknownField = writeBatch(db);
  queueCreateGye(db, unknownField, "BAD235", "owner", { injected: true });
  await assertFails(unknownField.commit());
});

test("ordinary user backup update remains allowed when gyeIds is unchanged",
async () => {
  await seedUser("member", ["ABC234"]);
  await seedGye("ABC234", ["owner", "member"]);

  await assertSucceeds(setDoc(
    doc(client("member"), "users", "member"),
    {
      progress: { xp: 12 },
      blockedUids: ["blocked"],
    },
    { merge: true },
  ));
});

test("static pack progress accepts bounded offline cleared sync", async () => {
  await seedUser("member", []);
  const db = client("member");

  await assertSucceeds(setDoc(
    doc(db, "users", "member", "packs", "a1_body"),
    packData({
      status: "cleared",
      bossAccuracy: 0.8,
      clearedAt: "2026-07-29T12:00:00.000Z",
    }),
  ));
});

test("pack progress rejects arbitrary IDs, fields, and invalid ranges",
async () => {
  await seedUser("member", []);
  const db = client("member");

  await assertFails(setDoc(
    doc(db, "users", "member", "packs", "user_minted_pack"),
    packData(),
  ));
  await assertFails(setDoc(
    doc(db, "users", "member", "packs", "a1_body"),
    packData({ injected: true }),
  ));
  await assertFails(setDoc(
    doc(db, "users", "member", "packs", "a1_body"),
    packData({ wordsLearned: 11 }),
  ));
});

test("cleared pack progress can never be downgraded", async () => {
  await seedUser("member", []);
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), "users", "member", "packs", "a1_body"),
      {
        ...packData({
          status: "cleared",
          bossAccuracy: 0.8,
          clearedAt: "2026-07-29T12:00:00.000Z",
        }),
        updatedAt: Timestamp.now(),
      },
    );
  });

  await assertFails(setDoc(
    doc(client("member"), "users", "member", "packs", "a1_body"),
    { status: "inProgress", updatedAt: serverTimestamp() },
    { merge: true },
  ));
});

test("bookshelf generation records are owner-readable and immutable",
async () => {
  await seedUser("member", []);
  const db = client("member");
  const generationId = "g_generation_one";
  const recordRef = doc(
    db,
    "users",
    "member",
    "sync_generations",
    generationId,
    "bookshelf",
    "p_one",
  );

  await assertSucceeds(setDoc(
    recordRef,
    bookshelfRecordData("p_one"),
  ));
  await assertSucceeds(getDoc(recordRef));
  await assertFails(setDoc(
    recordRef,
    bookshelfRecordData("p_one", { revision: 2 }),
  ));
  await assertFails(deleteDoc(recordRef));
  await assertFails(setDoc(
    doc(
      db,
      "users",
      "member",
      "sync_generations",
      generationId,
      "bookshelf",
      "p_invalid",
    ),
    bookshelfRecordData("different-id"),
  ));
});

test("bookshelf active manifest requires bounded monotonic generations",
async () => {
  await seedUser("member", []);
  const db = client("member");
  const manifestRef = doc(
    db,
    "users",
    "member",
    "sync_metadata",
    "bookshelf_active",
  );

  await assertSucceeds(setDoc(
    manifestRef,
    bookshelfManifestData("g_generation_one", 1, ["p_one"]),
  ));
  await assertFails(setDoc(
    manifestRef,
    bookshelfManifestData("g_generation_same_revision", 1, ["p_one"]),
  ));
  await assertFails(setDoc(
    manifestRef,
    bookshelfManifestData("g_generation_jump", 3, ["p_one"]),
  ));
  await assertFails(setDoc(
    manifestRef,
    bookshelfManifestData("g_generation_reused_operation", 2, ["p_one"], {
      operation_id: "operation-1",
    }),
  ));
  await assertFails(setDoc(
    manifestRef,
    bookshelfManifestData("g_generation_bad_hash", 2, ["p_one"], {
      content_hash: "not-a-hash",
    }),
  ));
  await assertSucceeds(setDoc(
    manifestRef,
    bookshelfManifestData("g_generation_two", 2, ["p_one", "p_two"]),
  ));
  await assertFails(deleteDoc(manifestRef));
  await assertFails(setDoc(
    manifestRef,
    bookshelfManifestData(
      "g_generation_too_large",
      3,
      Array.from({ length: 401 }, (_, index) => `p_${index}`),
    ),
  ));
});

test("pack sync metadata and reconciliation fields use bounded schemas",
async () => {
  await seedUser("member", []);
  const db = client("member");
  const packRef = doc(db, "users", "member", "packs", "a1_body");
  const membershipRef = doc(
    db,
    "users",
    "member",
    "sync_metadata",
    "pack_progress",
  );

  await assertSucceeds(setDoc(
    packRef,
    packData({
      sync_revision: 1,
      reconciliation_operation_id: "operation-one",
    }),
  ));
  await assertSucceeds(setDoc(
    membershipRef,
    packMembershipData(1, ["a1_body"], {
      reconciliation_operation_id: "operation-one",
    }),
  ));
  await assertFails(setDoc(
    membershipRef,
    packMembershipData(1, ["a1_body", "a1_body"]),
  ));
  await assertFails(setDoc(
    membershipRef,
    packMembershipData(1, ["user_minted_pack"]),
  ));
  await assertFails(setDoc(
    membershipRef,
    packMembershipData(3, ["a1_body"]),
  ));
  await assertSucceeds(setDoc(
    membershipRef,
    packMembershipData(2, ["a1_body", "a1_food_1"]),
  ));
  await assertFails(deleteDoc(membershipRef));
  await assertFails(setDoc(
    doc(db, "users", "member", "sync_metadata", "arbitrary"),
    { injected: true },
  ));
});

test("valid join batch atomically creates the tenth membership", async () => {
  const existing = Array.from({ length: 9 }, (_, index) => `u${index}`);
  await seedGye("ABC234", existing);
  await seedUser("joiner", []);
  const db = client("joiner");
  const batch = writeBatch(db);
  queueJoin(db, batch, "ABC234", "joiner", ["ABC234"]);

  await assertSucceeds(batch.commit());
});

test("eleventh member is rejected", async () => {
  const existing = Array.from({ length: 10 }, (_, index) => `u${index}`);
  await seedGye("ABC234", existing);
  await seedUser("joiner", []);
  const db = client("joiner");
  const batch = writeBatch(db);
  queueJoin(db, batch, "ABC234", "joiner", ["ABC234"]);

  await assertFails(batch.commit());
});

test("fourth Gye is rejected", async () => {
  const uid = "joiner";
  for (const gyeId of ["AAA234", "BBB234", "CCC234"]) {
    await seedGye(gyeId, [`owner-${gyeId}`, uid]);
  }
  await seedGye("DDD234", ["new-owner"]);
  await seedUser(uid, ["AAA234", "BBB234", "CCC234"]);
  const db = client(uid);
  const batch = writeBatch(db);
  queueJoin(
    db,
    batch,
    "DDD234",
    uid,
    ["AAA234", "BBB234", "CCC234", "DDD234"],
  );

  await assertFails(batch.commit());
});

test("removing an old gyeId without membership deletion cannot open a fourth slot",
async () => {
  const uid = "joiner";
  for (const gyeId of ["AAA234", "BBB234", "CCC234"]) {
    await seedGye(gyeId, [`owner-${gyeId}`, uid]);
  }
  await seedGye("DDD234", ["new-owner"]);
  await seedUser(uid, ["AAA234", "BBB234", "CCC234"]);
  const db = client(uid);
  const batch = writeBatch(db);
  queueJoin(db, batch, "DDD234", uid, ["BBB234", "CCC234", "DDD234"]);

  await assertFails(batch.commit());
});

test("member creation without meta and user companion writes is rejected",
async () => {
  await seedGye("ABC234", ["owner"]);
  await seedUser("joiner", []);
  const db = client("joiner");

  await assertFails(setDoc(
    doc(db, "gye", "ABC234", "members", "joiner"),
    { ...memberData("joiner"), joinedAt: serverTimestamp() },
  ));
});

test("client lifecycle timestamps must equal the server request time",
async () => {
  await seedGye("ABC234", ["owner", "member"]);
  await seedUser("joiner", []);
  const joinerDb = client("joiner");
  for (const joinedAt of [
    Timestamp.fromMillis(1),
    Timestamp.fromMillis(Date.now() + 24 * 60 * 60 * 1000),
  ]) {
    const batch = writeBatch(joinerDb);
    batch.set(doc(joinerDb, "gye", "ABC234", "members", "joiner"), {
      ...memberData("joiner"),
      joinedAt,
    });
    batch.update(doc(joinerDb, "gye", "ABC234"), {
      memberCount: increment(1),
    });
    batch.update(doc(joinerDb, "users", "joiner"), {
      gyeIds: ["ABC234"],
    });
    await assertFails(batch.commit());
  }

  const memberDb = client("member");
  for (const createdAt of [
    Timestamp.fromMillis(1),
    Timestamp.fromMillis(Date.now() + 24 * 60 * 60 * 1000),
  ]) {
    await assertFails(setDoc(
      doc(collection(memberDb, "gye", "ABC234", "feed")),
      { ...feedData("member"), createdAt },
    ));
  }
});

test("direct memberCount change is rejected", async () => {
  await seedGye("ABC234", ["owner", "member"]);
  await seedUser("member", ["ABC234"]);
  const db = client("member");

  await assertFails(setDoc(
    doc(db, "gye", "ABC234"),
    { memberCount: 9 },
    { merge: true },
  ));
});

test("suspended member cannot self-delete", async () => {
  await seedGye("ABC234", ["owner", "member"], {
    statuses: { member: "suspended" },
  });
  await seedUser("member", ["ABC234"]);
  const db = client("member");
  const batch = writeBatch(db);
  queueLeave(db, batch, "ABC234", "member", []);

  await assertFails(batch.commit());
});

test("ban prevents recreation and feed writes", async () => {
  await seedGye("ABC234", ["owner"], { bans: ["banned"] });
  await seedUser("banned", []);
  const bannedDb = client("banned");
  const join = writeBatch(bannedDb);
  queueJoin(bannedDb, join, "ABC234", "banned", ["ABC234"]);
  await assertFails(join.commit());

  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), "gye", "ABC234", "members", "banned"),
      memberData("banned"),
    );
    await setDoc(doc(context.firestore(), "users", "banned"), {
      gyeIds: ["ABC234"],
    });
  });
  await assertFails(setDoc(
    doc(collection(bannedDb, "gye", "ABC234", "feed")),
    feedData("banned"),
  ));
});

test("client feed rejects server event and nickname spoofing", async () => {
  await seedGye("ABC234", ["owner", "member"]);
  const db = client("member");

  await assertFails(setDoc(
    doc(collection(db, "gye", "ABC234", "feed")),
    {
      type: "pack_cleared",
      actorUid: "member",
      actorNickname: "member",
      payload: { packId: "a1_body" },
      createdAt: serverTimestamp(),
    },
  ));
  await assertFails(setDoc(
    doc(collection(db, "gye", "ABC234", "feed")),
    {
      type: "sticker",
      actorUid: "member",
      actorNickname: "spoofed",
      payload: { stickerCode: 1 },
      createdAt: serverTimestamp(),
    },
  ));
  await assertFails(setDoc(
    doc(collection(db, "gye", "ABC234", "feed")),
    {
      type: "sticker",
      actorUid: "member",
      actorNickname: "member",
      payload: { stickerCode: 31, injected: true },
      createdAt: serverTimestamp(),
    },
  ));
});

test("cheers require an eligible target and canonical nickname", async () => {
  await seedGye(
    "ABC234",
    ["owner", "sender", "eligible", "deleting", "suspended", "banned"],
    {
      statuses: { suspended: "suspended" },
      bans: ["banned"],
    },
  );
  await seedUser("deleting", ["ABC234"]);
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), "account_deletions", "deleting"),
      { state: "active", createdAt: Timestamp.now() },
    );
  });
  const db = client("sender");
  const cheer = (targetUid, targetNickname = targetUid) => ({
    type: "cheer",
    actorUid: "sender",
    actorNickname: "sender",
    payload: { targetUid, targetNickname, cheerCode: 1 },
    createdAt: serverTimestamp(),
  });

  await assertSucceeds(setDoc(
    doc(collection(db, "gye", "ABC234", "feed")),
    cheer("eligible"),
  ));
  await assertFails(setDoc(
    doc(collection(db, "gye", "ABC234", "feed")),
    cheer("eligible", "spoofed"),
  ));
  for (const target of ["deleting", "suspended", "banned"]) {
    await assertFails(setDoc(
      doc(collection(db, "gye", "ABC234", "feed")),
      cheer(target),
    ));
  }
});

test("known Gye codes resolve but authenticated users cannot list all Gyes",
async () => {
  await seedGye("ABC234", ["owner"]);
  const db = client("outsider");

  await assertSucceeds(getDoc(doc(db, "gye", "ABC234")));
  await assertFails(getDocs(collection(db, "gye")));
});

test("suspended or banned users cannot list private Gye collections",
async () => {
  await seedGye("ABC234", ["owner", "active", "suspended"], {
    statuses: { suspended: "suspended" },
    bans: ["suspended"],
  });
  await environment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, "gye", "ABC234", "feed", "event"), {
      type: "sticker",
      actorUid: "owner",
      actorNickname: "owner",
      payload: { stickerCode: 1 },
      createdAt: Timestamp.now(),
    });
    await setDoc(doc(db, "gye", "ABC234", "stickers", "sticker"), {
      senderUid: "owner",
      senderNickname: "owner",
      stickerCode: 1,
      createdAt: Timestamp.now(),
    });
  });

  const activeDb = client("active");
  await assertSucceeds(getDocs(
    collection(activeDb, "gye", "ABC234", "members"),
  ));
  await assertSucceeds(getDocs(
    collection(activeDb, "gye", "ABC234", "feed"),
  ));
  await assertSucceeds(getDocs(
    collection(activeDb, "gye", "ABC234", "stickers"),
  ));
  await assertSucceeds(getDocs(
    collection(activeDb, "gye", "ABC234", "bans"),
  ));

  const suspendedDb = client("suspended");
  await assertSucceeds(getDoc(
    doc(suspendedDb, "gye", "ABC234", "members", "suspended"),
  ));
  await assertSucceeds(getDoc(
    doc(suspendedDb, "gye", "ABC234", "bans", "suspended"),
  ));
  await assertFails(getDocs(
    collection(suspendedDb, "gye", "ABC234", "members"),
  ));
  await assertFails(getDocs(
    collection(suspendedDb, "gye", "ABC234", "feed"),
  ));
  await assertFails(getDocs(
    collection(suspendedDb, "gye", "ABC234", "stickers"),
  ));
  await assertFails(getDocs(
    collection(suspendedDb, "gye", "ABC234", "bans"),
  ));
});

test("suspended owner loses owner-only privileges", async () => {
  await seedGye("ABC234", ["owner", "active"], {
    statuses: { owner: "suspended" },
  });
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(
      context.firestore(),
      "gye",
      "ABC234",
      "reports",
      "report",
    ), {
      reporterUid: "active",
      targetUid: "owner",
      reason: "spam",
      note: "",
      createdAt: Timestamp.now(),
      status: "pending",
      reviewedBy: null,
      actionTaken: null,
    });
  });
  const suspendedOwnerDb = client("owner");

  await assertFails(setDoc(
    doc(suspendedOwnerDb, "gye", "ABC234"),
    { name: "Still owner" },
    { merge: true },
  ));
  await assertFails(getDocs(
    collection(suspendedOwnerDb, "gye", "ABC234", "reports"),
  ));
});

test("reports cannot create new PII references to ineligible targets",
async () => {
  await seedGye(
    "ABC234",
    ["owner", "reporter", "active", "suspended", "banned"],
    {
      statuses: { suspended: "suspended" },
      bans: ["banned"],
    },
  );
  await seedUser("active", ["ABC234"]);
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), "account_deletions", "active"),
      { state: "active", createdAt: Timestamp.now() },
    );
  });
  const db = client("reporter");
  const report = (targetUid) => ({
    reporterUid: "reporter",
    targetUid,
    reason: "spam",
    note: "",
    createdAt: serverTimestamp(),
    status: "pending",
    reviewedBy: null,
    actionTaken: null,
  });

  await assertFails(setDoc(
    reportRef(db, "ABC234", "active", "reporter"),
    report("active"),
  ));
  await assertFails(setDoc(
    reportRef(db, "ABC234", "suspended", "reporter"),
    report("suspended"),
  ));
  await assertFails(setDoc(
    reportRef(db, "ABC234", "banned", "reporter"),
    report("banned"),
  ));
});

test("one deterministic report is allowed per reporter-target pair",
async () => {
  await seedGye("ABC234", ["owner", "reporter", "target"]);
  const db = client("reporter");
  const payload = {
    reporterUid: "reporter",
    targetUid: "target",
    reason: "spam",
    note: "",
    createdAt: serverTimestamp(),
    status: "pending",
    reviewedBy: null,
    actionTaken: null,
  };

  const deterministicRef = reportRef(
    db,
    "ABC234",
    "target",
    "reporter",
  );
  await assertSucceeds(setDoc(deterministicRef, payload));
  await assertFails(setDoc(deterministicRef, payload));
  await assertFails(setDoc(
    doc(db, "gye", "ABC234", "reports", "arbitrary"),
    payload,
  ));
});

test("self update cannot tamper with role or status", async () => {
  await seedGye("ABC234", ["owner", "member"]);
  await seedUser("member", ["ABC234"]);
  const db = client("member");

  await assertFails(setDoc(
    doc(db, "gye", "ABC234", "members", "member"),
    { role: "owner" },
    { merge: true },
  ));
  await assertFails(setDoc(
    doc(db, "gye", "ABC234", "members", "member"),
    { status: "suspended" },
    { merge: true },
  ));
});

test("legacy member without membershipId can update stats and leave", async () => {
  await seedGye("ABC234", ["owner", "legacy"]);
  await seedUser("legacy", ["ABC234"]);
  await environment.withSecurityRulesDisabled(async (context) => {
    const ref = doc(
      context.firestore(),
      "gye",
      "ABC234",
      "members",
      "legacy",
    );
    await setDoc(ref, { membershipId: deleteField() }, { merge: true });
  });
  const db = client("legacy");
  await assertSucceeds(setDoc(
    doc(db, "gye", "ABC234", "members", "legacy"),
    { level: 2, streakDays: 3 },
    { merge: true },
  ));
  const leave = writeBatch(db);
  queueLeave(db, leave, "ABC234", "legacy", [], "legacy");
  await assertSucceeds(leave.commit());
});

test("owner cannot self-delete membership or parent", async () => {
  await seedGye("ABC234", ["owner", "member"]);
  await seedUser("owner", ["ABC234"]);
  const db = client("owner");
  const leave = writeBatch(db);
  queueLeave(db, leave, "ABC234", "owner", []);

  await assertFails(leave.commit());
  await assertFails(deleteDoc(doc(db, "gye", "ABC234")));
});

test("valid active non-owner leave batch succeeds", async () => {
  await seedGye("ABC234", ["owner", "member"]);
  await seedUser("member", ["ABC234"]);
  const db = client("member");
  const batch = writeBatch(db);
  queueLeave(db, batch, "ABC234", "member", []);

  await assertSucceeds(batch.commit());
});

test("departure marker blocks rapid rejoin until server cleanup", async () => {
  await seedGye("ABC234", ["owner", "member"]);
  await seedUser("member", ["ABC234"]);
  const db = client("member");
  const leave = writeBatch(db);
  queueLeave(db, leave, "ABC234", "member", []);
  await assertSucceeds(leave.commit());

  const prematureJoin = writeBatch(db);
  queueJoin(db, prematureJoin, "ABC234", "member", ["ABC234"]);
  await assertFails(prematureJoin.commit());

  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(
        context.firestore(),
        "gye",
        "ABC234",
        "departures",
        "member",
      ),
      {
        state: "complete",
        nickname: deleteField(),
        completedAt: Timestamp.now(),
      },
      { merge: true },
    );
  });
  const allowedJoin = writeBatch(db);
  queueJoin(
    db,
    allowedJoin,
    "ABC234",
    "member",
    ["ABC234"],
    membershipIdFor("member", "two"),
  );
  await assertSucceeds(allowedJoin.commit());

  const missingNewMarker = writeBatch(db);
  missingNewMarker.delete(doc(db, "gye", "ABC234", "members", "member"));
  missingNewMarker.update(doc(db, "gye", "ABC234"), {
    memberCount: increment(-1),
  });
  missingNewMarker.update(doc(db, "users", "member"), { gyeIds: [] });
  await assertFails(missingNewMarker.commit());

  const secondLeave = writeBatch(db);
  queueLeave(
    db,
    secondLeave,
    "ABC234",
    "member",
    [],
    membershipIdFor("member", "two"),
  );
  await assertSucceeds(secondLeave.commit());
});

test("clients cannot create deletion markers or delete user roots",
async () => {
  await seedGye("ABC234", ["owner", "member"]);
  await seedUser("member", ["ABC234"]);
  const db = client("member");
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), "users", "member", "packs", "existing"),
      { status: "active" },
    );
  });

  await assertFails(deleteDoc(doc(db, "users", "member")));
  await assertFails(setDoc(doc(db, "account_deletions", "member"), {
    state: "active",
    createdAt: serverTimestamp(),
  }));
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), "account_deletions", "member"),
      {
        state: "active",
        serverOwned: true,
        operationId: "operation-member",
      },
    );
  });
  await assertSucceeds(getDoc(doc(db, "account_deletions", "member")));
  await assertFails(setDoc(
    doc(db, "account_deletions", "member"),
    { state: "complete" },
    { merge: true },
  ));
  await assertFails(deleteDoc(doc(db, "account_deletions", "member")));
  await assertFails(deleteDoc(doc(db, "users", "member")));
});

test("clients cannot directly delete any server-owned cloud-backup state",
async () => {
  await seedUser("member", []);
  const backupPaths = [
    ["packs", "a1_body"],
    ["quests", "daily"],
    ["bookshelf", "book"],
    ["custom_packs", "pack"],
    ["custom_words", "word"],
    ["sync_generations", "generation", "bookshelf", "record"],
    ["sync_metadata", "bookshelf_active"],
    ["sync_metadata", "pack_progress"],
  ];
  await environment.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    for (const segments of backupPaths) {
      await setDoc(
        doc(adminDb, "users", "member", ...segments),
        { seeded: true },
      );
    }
    await setDoc(
      doc(adminDb, "cloud_backup_deletions", "member"),
      {
        uid: "member",
        requestDigest: "digest",
        state: { status: "pending" },
      },
    );
  });

  const db = client("member");
  for (const segments of backupPaths) {
    await assertFails(
      deleteDoc(doc(db, "users", "member", ...segments)),
    );
  }
  await assertFails(
    getDoc(doc(db, "cloud_backup_deletions", "member")),
  );
  await assertFails(
    setDoc(
      doc(db, "cloud_backup_deletions", "member"),
      { state: { status: "completed" } },
      { merge: true },
    ),
  );
  await assertFails(
    deleteDoc(doc(db, "cloud_backup_deletions", "member")),
  );
});

test("tester feedback is server-only at every depth", async () => {
  const uid = "feedback-owner";
  await seedUser(uid, []);
  await environment.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await setDoc(
      doc(adminDb, "users", uid, "tester_feedback", "completion-existing"),
      { message: "server-owned" },
    );
    await setDoc(
      doc(
        adminDb,
        "users",
        uid,
        "tester_feedback",
        "completion-existing",
        "private",
        "server-note",
      ),
      { serverOwned: true },
    );
  });

  const db = client(uid);
  const existingPaths = [
    ["tester_feedback", "completion-existing"],
    [
      "tester_feedback",
      "completion-existing",
      "private",
      "server-note",
    ],
  ];
  const newPaths = [
    ["tester_feedback", "completion-new"],
    ["tester_feedback", "completion-new", "private", "client-note"],
  ];

  for (const segments of existingPaths) {
    const protectedRef = doc(db, "users", uid, ...segments);
    await assertFails(getDoc(protectedRef));
    await assertFails(setDoc(protectedRef, { clientWrite: true }, { merge: true }));
    await assertFails(deleteDoc(protectedRef));
  }
  for (const segments of newPaths) {
    await assertFails(
      setDoc(doc(db, "users", uid, ...segments), { clientWrite: true }),
    );
  }
  await assertFails(
    getDocs(collection(db, "users", uid, "tester_feedback")),
  );
  await assertFails(getDocs(collection(
    db,
    "users",
    uid,
    "tester_feedback",
    "completion-existing",
    "private",
  )));
});

test("tester feedback rate limits are server-only at every depth", async () => {
  const uid = "feedback-rate-owner";
  const appHash = "a".repeat(64);
  await seedUser(uid, []);
  await environment.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await setDoc(
      doc(adminDb, "users", uid, "tester_feedback_rate_limits", appHash),
      {
        schemaVersion: 1,
        acceptedAtMillis: [1],
        serverOwned: true,
      },
    );
    await setDoc(
      doc(
        adminDb,
        "users",
        uid,
        "tester_feedback_rate_limits",
        appHash,
        "private",
        "server-note",
      ),
      { serverOwned: true },
    );
  });

  const db = client(uid);
  const existingPaths = [
    ["tester_feedback_rate_limits", appHash],
    [
      "tester_feedback_rate_limits",
      appHash,
      "private",
      "server-note",
    ],
  ];
  for (const segments of existingPaths) {
    const protectedRef = doc(db, "users", uid, ...segments);
    await assertFails(getDoc(protectedRef));
    await assertFails(setDoc(protectedRef, { clientWrite: true }, { merge: true }));
    await assertFails(deleteDoc(protectedRef));
  }
  await assertFails(setDoc(
    doc(db, "users", uid, "tester_feedback_rate_limits", "b".repeat(64)),
    { acceptedAtMillis: [] },
  ));
  await assertFails(getDocs(collection(
    db,
    "users",
    uid,
    "tester_feedback_rate_limits",
  )));
});

test("tester passport state permits only an owner get", async () => {
  const uid = "passport-owner";
  const emptyUid = "passport-empty";
  await seedUser(uid, []);
  await seedUser(emptyUid, []);
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), "users", uid, "tester_passport", "state"),
      { status: "eligible", serverOwned: true },
    );
  });

  const ownerDb = client(uid);
  const stateRef = doc(ownerDb, "users", uid, "tester_passport", "state");
  await assertSucceeds(getDoc(stateRef));
  await assertFails(getDoc(
    doc(client("passport-other"), "users", uid, "tester_passport", "state"),
  ));
  await assertFails(
    getDocs(collection(ownerDb, "users", uid, "tester_passport")),
  );
  await assertFails(setDoc(
    doc(
      client(emptyUid),
      "users",
      emptyUid,
      "tester_passport",
      "state",
    ),
    { status: "client-created" },
  ));
  await assertFails(setDoc(
    stateRef,
    { status: "client-updated" },
    { merge: true },
  ));
  await assertFails(deleteDoc(stateRef));
});

test("generic owner subcollections keep their legacy CRUD behavior", async () => {
  const uid = "generic-owner";
  await seedUser(uid, []);
  const ownerDb = client(uid);
  const legacyRef = doc(
    ownerDb,
    "users",
    uid,
    "legacy_preferences",
    "display",
  );

  await assertSucceeds(setDoc(legacyRef, { theme: "dark" }));
  await assertSucceeds(getDoc(legacyRef));
  await assertSucceeds(setDoc(
    legacyRef,
    { theme: "light" },
    { merge: true },
  ));
  await assertFails(getDoc(doc(
    client("generic-other"),
    "users",
    uid,
    "legacy_preferences",
    "display",
  )));
  await assertSucceeds(deleteDoc(legacyRef));
});

test("pending cloud-backup deletion fences every backup write but preserves FCM", async () => {
  const normalUid = "backup-normal";
  const pendingUid = "backup-pending";
  const backupFields = [
    "vok",
    "chosung",
    "wordle",
    "grammar",
    "app",
    "progress",
    "srs_json",
    "custom_packs_json",
    "bookshelf_json",
    "updated_at",
  ];
  const genericRoots = ["quests", "bookshelf", "custom_packs", "custom_words"];

  await seedUser(normalUid, []);
  const normal = client(normalUid);
  await assertSucceeds(setDoc(
    doc(normal, "users", normalUid),
    { progress: { rounds: 1 } },
    { merge: true },
  ));
  await assertSucceeds(setDoc(
    doc(normal, "users", normalUid, "packs", "a1_body"),
    packData(),
  ));
  for (const root of genericRoots) {
    await assertSucceeds(setDoc(
      doc(normal, "users", normalUid, root, "normal"),
      { normal: true },
    ));
  }
  await assertSucceeds(setDoc(
    doc(
      normal,
      "users",
      normalUid,
      "sync_generations",
      "generation-one",
      "bookshelf",
      "record-one",
    ),
    bookshelfRecordData("record-one"),
  ));
  await assertSucceeds(setDoc(
    doc(normal, "users", normalUid, "sync_metadata", "bookshelf_active"),
    bookshelfManifestData("generation-one", 1, ["record-one"]),
  ));
  await assertSucceeds(setDoc(
    doc(normal, "users", normalUid, "sync_metadata", "pack_progress"),
    packMembershipData(1, ["a1_body"]),
  ));

  await seedUser(pendingUid, []);
  await environment.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await setDoc(
      doc(adminDb, "users", pendingUid, "packs", "a1_body"),
      packData(),
    );
    for (const root of genericRoots) {
      await setDoc(
        doc(adminDb, "users", pendingUid, root, "existing"),
        { seeded: true },
      );
    }
    await setDoc(
      doc(
        adminDb,
        "users",
        pendingUid,
        "sync_generations",
        "generation-existing",
        "bookshelf",
        "record-existing",
      ),
      bookshelfRecordData("record-existing"),
    );
    await setDoc(
      doc(
        adminDb,
        "users",
        pendingUid,
        "sync_metadata",
        "bookshelf_active",
      ),
      bookshelfManifestData("generation-existing", 1, ["record-existing"]),
    );
    await setDoc(
      doc(
        adminDb,
        "users",
        pendingUid,
        "sync_metadata",
        "pack_progress",
      ),
      packMembershipData(1, ["a1_body"]),
    );
    await setDoc(
      doc(adminDb, "cloud_backup_deletions", pendingUid),
      {
        uid: pendingUid,
        requestDigest: "a".repeat(64),
        state: { status: "pending" },
      },
    );
  });

  const pending = client(pendingUid);
  for (const field of backupFields) {
    await assertFails(setDoc(
      doc(pending, "users", pendingUid),
      { [field]: field == "updated_at" ? serverTimestamp() : { blocked: true } },
      { merge: true },
    ));
  }
  await assertSucceeds(setDoc(
    doc(pending, "users", pendingUid),
    { fcmTokens: ["still-operational"] },
    { merge: true },
  ));

  await assertFails(setDoc(
    doc(pending, "users", pendingUid, "packs", "a1_body"),
    packData({ attempts: 2 }),
    { merge: true },
  ));
  await assertFails(setDoc(
    doc(pending, "users", pendingUid, "packs", "a1_colors"),
    packData(),
  ));
  for (const root of genericRoots) {
    await assertFails(setDoc(
      doc(pending, "users", pendingUid, root, "existing"),
      { client: "update" },
      { merge: true },
    ));
  }
  await assertFails(setDoc(
    doc(
      pending,
      "users",
      pendingUid,
      "sync_generations",
      "generation-recreated",
      "bookshelf",
      "record-recreated",
    ),
    bookshelfRecordData("record-recreated"),
  ));
  await assertFails(setDoc(
    doc(
      pending,
      "users",
      pendingUid,
      "sync_metadata",
      "bookshelf_active",
    ),
    bookshelfManifestData("generation-next", 2, ["record-existing"]),
  ));
  await assertFails(setDoc(
    doc(
      pending,
      "users",
      pendingUid,
      "sync_metadata",
      "pack_progress",
    ),
    packMembershipData(2, ["a1_body"]),
  ));

  // Simulate the worker having just removed records: clients still cannot
  // recreate any backup payload while the authoritative marker is pending.
  await environment.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await deleteDoc(
      doc(adminDb, "users", pendingUid, "packs", "a1_body"),
    );
    for (const root of genericRoots) {
      await deleteDoc(doc(adminDb, "users", pendingUid, root, "existing"));
    }
    await deleteDoc(
      doc(
        adminDb,
        "users",
        pendingUid,
        "sync_generations",
        "generation-existing",
        "bookshelf",
        "record-existing",
      ),
    );
    await deleteDoc(
      doc(
        adminDb,
        "users",
        pendingUid,
        "sync_metadata",
        "bookshelf_active",
      ),
    );
    await deleteDoc(
      doc(
        adminDb,
        "users",
        pendingUid,
        "sync_metadata",
        "pack_progress",
      ),
    );
  });

  await assertFails(setDoc(
    doc(pending, "users", pendingUid, "packs", "a1_body"),
    packData(),
  ));
  for (const root of genericRoots) {
    await assertFails(setDoc(
      doc(pending, "users", pendingUid, root, "existing"),
      { client: "recreate" },
    ));
  }
  await assertFails(setDoc(
    doc(
      pending,
      "users",
      pendingUid,
      "sync_generations",
      "generation-existing",
      "bookshelf",
      "record-existing",
    ),
    bookshelfRecordData("record-existing"),
  ));
  await assertFails(setDoc(
    doc(
      pending,
      "users",
      pendingUid,
      "sync_metadata",
      "bookshelf_active",
    ),
    bookshelfManifestData("generation-recreated", 1, ["record-existing"]),
  ));
  await assertFails(setDoc(
    doc(
      pending,
      "users",
      pendingUid,
      "sync_metadata",
      "pack_progress",
    ),
    packMembershipData(1, ["a1_body"]),
  ));
});

test("owners can get only their own operation status and cannot write it",
async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await setDoc(doc(adminDb, "account_operations", "owner-operation"), {
      sourceUid: "owner",
      kind: "deletion",
      phase: "userTreeDeleting",
      version: 2,
    });
    await setDoc(doc(adminDb, "account_operations", "other-operation"), {
      sourceUid: "other",
      kind: "deletion",
      phase: "deletionRequested",
      version: 1,
    });
  });
  const ownerDb = client("owner");

  await assertSucceeds(getDoc(
    doc(ownerDb, "account_operations", "owner-operation"),
  ));
  await assertFails(getDoc(
    doc(ownerDb, "account_operations", "other-operation"),
  ));
  await assertFails(getDocs(collection(ownerDb, "account_operations")));
  await assertFails(setDoc(
    doc(ownerDb, "account_operations", "owner-operation"),
    { phase: "completed" },
    { merge: true },
  ));
});

test("deleting lifecycle blocks all late client mutations", async () => {
  await seedGye("ABC234", ["owner", "member"]);
  await seedUser("member", ["ABC234"]);
  await seedUser("joiner", []);
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), "gye", "ABC234"),
      { lifecycleState: "deleting" },
      { merge: true },
    );
  });
  const db = client("member");
  await assertFails(setDoc(
    doc(collection(db, "gye", "ABC234", "feed")),
    feedData("member"),
  ));
  await assertFails(setDoc(
    doc(collection(db, "gye", "ABC234", "stickers")),
    {
      senderUid: "member",
      senderNickname: "member",
      stickerCode: 1,
      createdAt: serverTimestamp(),
    },
  ));
  await assertFails(setDoc(
    reportRef(db, "ABC234", "owner", "member"),
    {
      reporterUid: "member",
      targetUid: "owner",
      reason: "spam",
      note: "",
      createdAt: serverTimestamp(),
      status: "pending",
      reviewedBy: null,
      actionTaken: null,
    },
  ));
  const leave = writeBatch(db);
  queueLeave(db, leave, "ABC234", "member", []);
  await assertFails(leave.commit());

  const joinerDb = client("joiner");
  const join = writeBatch(joinerDb);
  queueJoin(joinerDb, join, "ABC234", "joiner", ["ABC234"]);
  await assertFails(join.commit());
});

test("notification outbox and delivery receipts are server-only", async () => {
  await seedGye("ABC234", ["owner"]);
  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(
        context.firestore(),
        "gye",
        "ABC234",
        "notification_outbox",
        "message",
      ),
      {
        uid: "owner",
        eventKey: "weekly:ABC234:2026-07-27",
        state: "pending",
      },
    );
  });
  const db = client("owner");
  const outboxRef = doc(
    db,
    "gye",
    "ABC234",
    "notification_outbox",
    "message",
  );
  await assertFails(getDoc(outboxRef));
  await assertFails(setDoc(outboxRef, { state: "sent" }, { merge: true }));
  await assertFails(deleteDoc(outboxRef));
});

test("only one of concurrent tenth and eleventh joins can succeed", async () => {
  const existing = Array.from({ length: 9 }, (_, index) => `u${index}`);
  await seedGye("ABC234", existing);
  await seedUser("join-a", []);
  await seedUser("join-b", []);
  const dbA = client("join-a");
  const dbB = client("join-b");
  const a = writeBatch(dbA);
  const b = writeBatch(dbB);
  queueJoin(dbA, a, "ABC234", "join-a", ["ABC234"]);
  queueJoin(dbB, b, "ABC234", "join-b", ["ABC234"]);

  const results = await Promise.allSettled([a.commit(), b.commit()]);
  assert.equal(
    results.filter((result) => result.status === "fulfilled").length,
    1,
  );
  assert.equal(
    results.filter((result) => result.status === "rejected").length,
    1,
  );
});
