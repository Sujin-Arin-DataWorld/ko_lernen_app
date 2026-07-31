"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const {
  createDeletionCleanupAdapters,
  createLegacyUserDeletionCleanupHandler,
} = require("./deletion_cleanup_adapters");
const {
  createGyeDeletionPageCleaner,
} = require("./deletion_gye_page");
const {
  anonymizeFeed,
  anonymizeMeta,
  anonymizeReport,
  anonymizeSticker,
  shouldDeleteReportForUid,
} = require("./lifecycle");

const DELETE_FIELD = Symbol("delete-field");
const ARRAY_REMOVE_FIELD = "array-remove-field";
const NOW_MILLIS = 1_000;
const WORKER_FENCE = Object.freeze({
  workerId: "worker-one",
  operationVersion: 1,
  leaseVersion: 1,
});

function clone(value) {
  return value === undefined
    ? undefined
    : structuredClone(value);
}

function fieldValue() {
  return {
    arrayRemove: (...values) => ({ kind: ARRAY_REMOVE_FIELD, values }),
    delete: () => DELETE_FIELD,
    serverTimestamp: () => "server-time",
  };
}

function applyFields(current, fields) {
  const next = { ...(current || {}) };
  for (const [key, value] of Object.entries(fields || {})) {
    if (value === DELETE_FIELD) {
      delete next[key];
    } else if (value?.kind === ARRAY_REMOVE_FIELD) {
      const currentValues = Array.isArray(next[key]) ? next[key] : [];
      next[key] = currentValues.filter(
        (entry) => !value.values.includes(entry),
      );
    } else {
      next[key] = clone(value);
    }
  }
  return next;
}

class FakeDocumentSnapshot {
  constructor(ref, data) {
    this.ref = ref;
    this.id = ref.id;
    this.exists = data !== undefined;
    this._data = data;
  }

  data() {
    return clone(this._data);
  }
}

class FakeDocumentReference {
  constructor(firestore, path) {
    this.firestore = firestore;
    this.path = path;
    this.id = path.split("/").at(-1);
    this.parent = new FakeCollectionReference(
      firestore,
      path.split("/").slice(0, -1).join("/"),
    );
  }

  collection(name) {
    return new FakeCollectionReference(
      this.firestore,
      `${this.path}/${name}`,
    );
  }

  async get() {
    return this.firestore.snapshot(this.path);
  }

  async delete() {
    this.firestore.documents.delete(this.path);
  }

  async set(fields, options) {
    this.firestore.write(this.path, fields, options);
  }
}

class FakeCollectionReference {
  constructor(firestore, path) {
    this.firestore = firestore;
    this.path = path;
    this.id = path.split("/").at(-1);
    const parentPath = path.split("/").slice(0, -1).join("/");
    this.parent = parentPath
      ? new FakeDocumentReference(firestore, parentPath)
      : null;
  }

  doc(id) {
    return new FakeDocumentReference(this.firestore, `${this.path}/${id}`);
  }

  where(field, operator, value) {
    return new FakeQuery(this.firestore, {
      collectionPath: this.path,
      filters: [{ field, operator, value }],
    });
  }

  orderBy() {
    return new FakeQuery(this.firestore, {
      collectionPath: this.path,
      ordered: true,
    });
  }
}

class FakeQuery {
  constructor(firestore, {
    collectionPath = null,
    collectionGroup = null,
    filters = [],
    limit = null,
    afterPath = null,
    ordered = false,
  }) {
    this.firestore = firestore;
    this.collectionPath = collectionPath;
    this.collectionGroup = collectionGroup;
    this.filters = filters;
    this.pageLimit = limit;
    this.afterPath = afterPath;
    this.ordered = ordered;
  }

  copy(change) {
    return new FakeQuery(this.firestore, {
      collectionPath: this.collectionPath,
      collectionGroup: this.collectionGroup,
      filters: this.filters,
      limit: this.pageLimit,
      afterPath: this.afterPath,
      ordered: this.ordered,
      ...change,
    });
  }

  where(field, operator, value) {
    return this.copy({
      filters: [...this.filters, { field, operator, value }],
    });
  }

  orderBy() {
    return this.copy({ ordered: true });
  }

  startAfter(cursor) {
    const raw = typeof cursor === "string" ? cursor : cursor.ref.path;
    return this.copy({
      afterPath: this.collectionPath &&
          typeof raw === "string" &&
          !raw.includes("/")
        ? `${this.collectionPath}/${raw}`
        : raw,
    });
  }

  limit(value) {
    return this.copy({ limit: value });
  }

  async get() {
    if (!Number.isInteger(this.pageLimit)) {
      throw new Error("test detected an unbounded query");
    }
    this.firestore.queryCalls.push({
      collectionGroup: this.collectionGroup,
      collectionPath: this.collectionPath,
      limit: this.pageLimit,
      ordered: this.ordered,
    });
    const paths = Array.from(this.firestore.documents.keys())
      .filter((path) => {
        const segments = path.split("/");
        if (this.collectionPath) {
          const prefix = `${this.collectionPath}/`;
          return path.startsWith(prefix) &&
            path.slice(prefix.length).split("/").length === 1;
        }
        return segments.length >= 2 &&
          segments.at(-2) === this.collectionGroup;
      })
      .filter((path) => {
        const data = this.firestore.documents.get(path) || {};
        return this.filters.every(({ field, operator, value }) => {
          if (operator === "==") return data[field] === value;
          if (operator === "array-contains") {
            return Array.isArray(data[field]) && data[field].includes(value);
          }
          return false;
        });
      })
      .filter((path) => !this.afterPath || path > this.afterPath)
      .sort()
      .slice(0, this.pageLimit);
    const docs = paths.map((path) => this.firestore.snapshot(path));
    return { docs, empty: docs.length === 0, size: docs.length };
  }
}

class FakeFirestore {
  constructor() {
    this.documents = new Map();
    this.queryCalls = [];
    this.failProcessedCommitOnce = false;
  }

  seed(path, data) {
    this.documents.set(path, clone(data));
  }

  value(path) {
    return clone(this.documents.get(path));
  }

  snapshot(path) {
    return new FakeDocumentSnapshot(
      new FakeDocumentReference(this, path),
      this.documents.has(path) ? this.documents.get(path) : undefined,
    );
  }

  write(path, fields, options = {}) {
    const current = options.merge ? this.documents.get(path) : {};
    this.documents.set(path, applyFields(current, fields));
  }

  collection(name) {
    return new FakeCollectionReference(this, name);
  }

  collectionGroup(name) {
    return new FakeQuery(this, { collectionGroup: name });
  }

  async runTransaction(callback) {
    const transaction = {
      get: (ref) => ref.get(),
      getAll: (...refs) => Promise.all(refs.map((ref) => ref.get())),
      set: (ref, fields, options) => this.write(ref.path, fields, options),
      update: (ref, fields) => this.write(ref.path, fields, { merge: true }),
      delete: (ref) => {
        if (this.failProcessedCommitOnce &&
            ref.path.includes("/processed_packs/")) {
          this.failProcessedCommitOnce = false;
          throw new Error("transient batch failure");
        }
        this.documents.delete(ref.path);
      },
    };
    return callback(transaction);
  }

  batch() {
    const deletes = [];
    return {
      delete: (ref) => deletes.push(ref.path),
      commit: async () => {
        if (this.failProcessedCommitOnce &&
            deletes.some((path) => path.includes("/processed_packs/"))) {
          this.failProcessedCommitOnce = false;
          throw new Error("transient batch failure");
        }
        deletes.forEach((path) => this.documents.delete(path));
      },
    };
  }
}

function createHarness({ serverOwned = true, cleanupPage } = {}) {
  const firestore = new FakeFirestore();
  firestore.seed("account_deletions/source", {
    serverOwned,
    operationId: serverOwned ? "op" : undefined,
    cleanupGyeIds: ["legacy-gye"],
    cleanupRevision: 0,
  });
  if (serverOwned) {
    firestore.seed("account_operations/op", {
      id: "op",
      kind: "deletion",
      phase: "communityCleanupPending",
      sourceUid: "source",
      version: WORKER_FENCE.operationVersion,
      workerLease: {
        workerId: WORKER_FENCE.workerId,
        leaseVersion: WORKER_FENCE.leaseVersion,
        leaseUntilMillis: NOW_MILLIS + 60_000,
      },
    });
  }
  const anonymized = [];
  const reconciled = [];
  const fakeCleanupPage = async ({
    targetRef,
    gyeId,
    uid,
    nickname,
    workerFence,
    runFencedTransaction,
  }) => {
    anonymized.push({ gyeId, uid, nickname, workerFence });
    reconciled.push(gyeId);
    assert.deepEqual(workerFence, serverOwned ? WORKER_FENCE : undefined);
    await runFencedTransaction(async ({ transaction }) => {
      transaction.set(
        targetRef,
        { workState: { stage: "done", version: 1, cursor: null } },
        { merge: true },
      );
    });
    return { done: true };
  };
  const makeAdapters = () => createDeletionCleanupAdapters({
    firestore,
    fieldValue: fieldValue(),
    documentIdFieldPath: "__name__",
    cleanupGyeForDeletedUserPage: cleanupPage || fakeCleanupPage,
    notificationOutboxBelongsToUid: (data, uid) => data.uid === uid,
    nowMillis: () => NOW_MILLIS,
    pageSize: 2,
  });
  const adapters = makeAdapters();
  return {
    adapters,
    anonymized,
    firestore,
    makeAdapters,
    reconciled,
  };
}

function createRealAdapters(firestore) {
  const values = fieldValue();
  const cleaner = createGyeDeletionPageCleaner({
    firestore,
    fieldValue: values,
    documentIdFieldPath: "__name__",
    anonymizeMeta,
    anonymizeFeed,
    anonymizeReport,
    anonymizeSticker,
    shouldDeleteReportForUid,
  });
  return createDeletionCleanupAdapters({
    firestore,
    fieldValue: values,
    documentIdFieldPath: "__name__",
    cleanupGyeForDeletedUserPage: cleaner.cleanupPage,
    notificationOutboxBelongsToUid: (data, uid) => data.uid === uid,
    nowMillis: () => NOW_MILLIS,
    pageSize: 2,
  });
}

test("community cleanup retains a pre-root legacy Gye target and discovers "
    + "current relationships in bounded pages", async () => {
  const {
    anonymized,
    firestore,
    makeAdapters,
    reconciled,
  } = createHarness();
  firestore.seed(
    "gye/discovered-gye/processed_packs/pack",
    { uid: "source" },
  );
  firestore.seed(
    "gye/discovered-gye/departures/source",
    { uid: "source", nickname: "before-delete" },
  );
  firestore.seed("gye/legacy-gye/members/source", {
    uid: "source",
    nickname: "legacy-member",
  });

  let claim;
  let invocations = 0;
  do {
    const queryCount = firestore.queryCalls.length;
    claim = await makeAdapters().cleanupCommunity({
      uid: "source",
      operationId: "op",
      workerFence: WORKER_FENCE,
    });
    invocations += 1;
    assert.ok(
      firestore.queryCalls.length - queryCount <= 1,
      "one invocation must consume at most one discovery page",
    );
  } while (!claim.done && invocations < 30);

  assert.deepEqual(reconciled, ["discovered-gye", "legacy-gye"]);
  assert.deepEqual(
    anonymized.map(({ gyeId, nickname }) => ({ gyeId, nickname })),
    [
      { gyeId: "discovered-gye", nickname: "before-delete" },
      { gyeId: "legacy-gye", nickname: "legacy-member" },
    ],
  );
  assert.equal(claim.done, true);
  assert.ok(invocations > 1);
  assert.equal(
    firestore.documents.has("gye/discovered-gye/departures/source"),
    false,
  );
  assert(
    firestore.queryCalls
      .filter((call) => call.collectionGroup)
      .every((call) => call.limit <= 2 && call.ordered),
  );
});
test("processor cleanup is idempotent and deletes only source-owned "
    + "documents", async () => {
  const { adapters, firestore } = createHarness();
  firestore.seed("shared_packs/source-pack", { createdBy: "source" });
  firestore.seed("shared_packs/foreign-pack", { createdBy: "foreign" });
  firestore.seed(
    "gye/one/processed_packs/source-pack",
    { uid: "source" },
  );
  firestore.seed(
    "gye/one/processed_packs/foreign-pack",
    { uid: "foreign" },
  );
  firestore.seed(
    "gye/one/notification_outbox/source-message",
    { uid: "source" },
  );
  firestore.seed(
    "gye/one/notification_outbox/foreign-message",
    { uid: "foreign" },
  );

  let result;
  do {
    result = await adapters.cleanupProcessor({
      uid: "source",
      operationId: "op",
      workerFence: WORKER_FENCE,
    });
  } while (!result.done);
  await adapters.cleanupProcessor({
    uid: "source",
    operationId: "op",
    workerFence: WORKER_FENCE,
  });

  assert.equal(firestore.documents.has("shared_packs/source-pack"), false);
  assert.equal(
    firestore.documents.has("gye/one/processed_packs/source-pack"),
    false,
  );
  assert.equal(
    firestore.documents.has(
      "gye/one/notification_outbox/source-message",
    ),
    false,
  );
  assert.equal(firestore.documents.has("shared_packs/foreign-pack"), true);
  assert.equal(
    firestore.documents.has("gye/one/processed_packs/foreign-pack"),
    true,
  );
  assert.equal(
    firestore.documents.has(
      "gye/one/notification_outbox/foreign-message",
    ),
    true,
  );
});

test("processor cleanup retries safely after a partial category completion",
async () => {
  const { adapters, firestore } = createHarness();
  firestore.seed("shared_packs/source-pack", { createdBy: "source" });
  firestore.seed(
    "gye/one/processed_packs/source-pack",
    { uid: "source" },
  );
  firestore.seed(
    "gye/one/notification_outbox/source-message",
    { uid: "source" },
  );
  firestore.failProcessedCommitOnce = true;

  const first = await adapters.cleanupProcessor({
    uid: "source",
    operationId: "op",
    workerFence: WORKER_FENCE,
  });
  assert.equal(first.done, false);
  assert.equal(firestore.documents.has("shared_packs/source-pack"), false);
  assert.equal(
    firestore.documents.has("gye/one/processed_packs/source-pack"),
    true,
  );
  await assert.rejects(
    adapters.cleanupProcessor({
      uid: "source",
      operationId: "op",
      workerFence: WORKER_FENCE,
    }),
    /transient batch failure/,
  );

  let result;
  do {
    result = await adapters.cleanupProcessor({
      uid: "source",
      operationId: "op",
      workerFence: WORKER_FENCE,
    });
  } while (!result.done);

  assert.equal(
    Array.from(firestore.documents.keys())
      .some((path) => path.includes("source-pack") ||
        path.endsWith("source-message")),
    false,
  );
});

test("high-fanout community discovery resumes from durable bounded progress",
async () => {
  const {
    firestore,
    makeAdapters,
    reconciled,
  } = createHarness();
  for (let index = 0; index < 7; index += 1) {
    const gyeId = `gye-${index}`;
    firestore.seed(`gye/${gyeId}/members/source`, {
      uid: "source",
      nickname: `member-${index}`,
    });
  }

  let result;
  let invocations = 0;
  do {
    const beforeQueries = firestore.queryCalls.length;
    result = await makeAdapters().cleanupCommunity({
      uid: "source",
      operationId: "op",
      workerFence: WORKER_FENCE,
    });
    invocations += 1;
    assert.ok(firestore.queryCalls.length - beforeQueries <= 1);
    assert.ok(reconciled.length <= invocations);
  } while (!result.done && invocations < 50);

  assert.equal(result.done, true);
  assert.ok(invocations > 7);
  assert.deepEqual(
    reconciled.slice().sort(),
    [
      "gye-0",
      "gye-1",
      "gye-2",
      "gye-3",
      "gye-4",
      "gye-5",
      "gye-6",
      "legacy-gye",
    ],
  );
});

test("stale cleanup worker cannot delete after a successor reclaims the lease",
async () => {
  const { adapters, firestore, reconciled } = createHarness();
  firestore.seed("shared_packs/source-pack", { createdBy: "source" });
  firestore.seed("account_operations/op", {
    id: "op",
    kind: "deletion",
    phase: "processorCleanupPending",
    sourceUid: "source",
    version: WORKER_FENCE.operationVersion,
    workerLease: {
      workerId: "successor",
      leaseVersion: WORKER_FENCE.leaseVersion + 1,
      leaseUntilMillis: NOW_MILLIS + 60_000,
    },
  });

  await assert.rejects(
    adapters.cleanupProcessor({
      uid: "source",
      operationId: "op",
      workerFence: WORKER_FENCE,
    }),
    { code: "stale-worker-lease" },
  );
  assert.equal(firestore.documents.has("shared_packs/source-pack"), true);
  assert.deepEqual(reconciled, []);

  const successorFence = {
    workerId: "successor",
    operationVersion: WORKER_FENCE.operationVersion,
    leaseVersion: WORKER_FENCE.leaseVersion + 1,
  };
  const successor = await adapters.cleanupProcessor({
    uid: "source",
    operationId: "op",
    workerFence: successorFence,
  });
  assert.equal(successor.done, false);
  assert.equal(firestore.documents.has("shared_packs/source-pack"), false);
});

test("per-Gye cleanup pages bound high-fanout work and resume to tree deletion",
async () => {
  const { firestore } = createHarness();
  firestore.seed("account_deletions/source", {
    serverOwned: true,
    operationId: "op",
    cleanupGyeIds: ["fanout-gye"],
    cleanupRevision: 0,
  });
  firestore.seed("gye/fanout-gye", {
    ownerId: "source",
    memberCount: 4,
    lifecycleState: "active",
    lastWeekMvpUid: "source",
    lastWeekMvp: "Source",
  });
  for (const [index, memberUid] of [
    "source",
    "inactive-a",
    "inactive-b",
    "inactive-c",
  ].entries()) {
    firestore.seed(`gye/fanout-gye/members/${memberUid}`, {
      uid: memberUid,
      nickname: memberUid,
      status: memberUid === "source" ? "active" : "inactive",
      joinedAtMillis: index,
    });
    firestore.seed(`users/${memberUid}`, {
      gyeIds: ["fanout-gye", "retained-gye"],
    });
  }
  for (let index = 0; index < 7; index += 1) {
    firestore.seed(`gye/fanout-gye/feed/feed-${index}`, {
      actorUid: "source",
      actorNickname: "Source",
      payload: {},
    });
  }
  const adapters = createRealAdapters(firestore);

  let result = { done: false };
  let invocations = 0;
  while (!result.done && invocations < 100) {
    result = await adapters.cleanupCommunity({
      uid: "source",
      operationId: "op",
      workerFence: WORKER_FENCE,
    });
    invocations += 1;
  }

  assert.equal(result.done, true);
  assert.ok(invocations > 20);
  assert.equal(
    Array.from(firestore.documents.keys())
      .some((path) => path === "gye/fanout-gye" ||
        path.startsWith("gye/fanout-gye/")),
    false,
  );
  for (const memberUid of [
    "source",
    "inactive-a",
    "inactive-b",
    "inactive-c",
  ]) {
    assert.deepEqual(
      firestore.value(`users/${memberUid}`).gyeIds,
      ["retained-gye"],
    );
  }
  assert(
    firestore.queryCalls.every(
      (call) => call.ordered && call.limit <= 2,
    ),
  );
});

test("paused legacy Gye page cannot mutate after server takeover", async () => {
  let pageStarted;
  let releasePage;
  const started = new Promise((resolve) => {
    pageStarted = resolve;
  });
  const gate = new Promise((resolve) => {
    releasePage = resolve;
  });
  const cleanupPage = async ({ targetRef, runFencedTransaction }) => {
    pageStarted();
    await gate;
    await runFencedTransaction(async ({ transaction }) => {
      transaction.set(
        targetRef,
        { staleLegacyMutation: true },
        { merge: true },
      );
    });
    return { done: false };
  };
  const { adapters, firestore } = createHarness({
    serverOwned: false,
    cleanupPage,
  });
  firestore.seed("account_deletions/source", {
    serverOwned: false,
    legacyCleanupGeneration: "legacy-generation-one",
    communityCleanupState: {
      operationId: "legacy-source",
      collectionIndex: 5,
      cursor: null,
      discoveryComplete: true,
      done: false,
    },
  });
  firestore.seed(
    "account_deletions/source/cleanup_targets/gye-one",
    { operationId: "legacy-source", gyeId: "gye-one" },
  );

  const paused = adapters.cleanupCommunity({
    uid: "source",
    operationId: "legacy-source",
    legacyGeneration: "legacy-generation-one",
  });
  await started;
  firestore.seed("account_deletions/source", {
    serverOwned: true,
    operationId: "op",
  });
  firestore.seed("account_operations/op", {
    sourceUid: "source",
    version: WORKER_FENCE.operationVersion,
    workerLease: {
      workerId: WORKER_FENCE.workerId,
      leaseVersion: WORKER_FENCE.leaseVersion,
      leaseUntilMillis: NOW_MILLIS + 60_000,
    },
  });
  releasePage();

  await assert.rejects(paused, {
    code: "cleanup-operation-mismatch",
  });
  assert.equal(
    firestore.value(
      "account_deletions/source/cleanup_targets/gye-one",
    ).staleLegacyMutation,
    undefined,
  );
});

test("legacy trigger uses the same adapters, records its receipt, and skips "
    + "server-owned markers", async () => {
  const legacy = createHarness({ serverOwned: false });
  legacy.firestore.seed(
    "gye/discovered-gye/members/source",
    { uid: "source", nickname: "member" },
  );
  legacy.firestore.seed(
    "gye/discovered-gye/processed_packs/pack",
    { uid: "source" },
  );
  const handler = createLegacyUserDeletionCleanupHandler({
    firestore: legacy.firestore,
    fieldValue: fieldValue(),
    cleanupAdapters: legacy.adapters,
  });

  await handler({
    uid: "source",
    before: { gyeIds: ["before-gye"] },
  });

  assert.deepEqual(
    legacy.reconciled,
    ["before-gye", "discovered-gye", "legacy-gye"],
  );
  const receipt = legacy.firestore.value("account_deletions/source");
  assert.equal(receipt.cleanupComplete, true);
  assert.equal(receipt.cleanupCompletedAt, "server-time");
  assert.equal(Object.hasOwn(receipt, "cleanupGyeIds"), false);
  assert.equal(Object.hasOwn(receipt, "cleanupRevision"), false);

  const server = createHarness({ serverOwned: true });
  server.firestore.seed(
    "gye/discovered-gye/members/source",
    { uid: "source" },
  );
  const serverHandler = createLegacyUserDeletionCleanupHandler({
    firestore: server.firestore,
    fieldValue: fieldValue(),
    cleanupAdapters: server.adapters,
  });

  const result = await serverHandler({
    uid: "source",
    before: { gyeIds: ["before-gye"] },
  });

  assert.deepEqual(result, { status: "server-owned" });
  assert.deepEqual(server.reconciled, []);
  assert.equal(
    server.firestore.documents.has(
      "gye/discovered-gye/members/source",
    ),
    true,
  );
});
