"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const { cleanupGyeForDeletedUser } = require("./runtime");
const {
  createDeletionCleanupAdapters,
  createLegacyUserDeletionCleanupHandler,
} = require("./deletion_cleanup_adapters");

const DELETE_FIELD = Symbol("delete-field");

function clone(value) {
  return value === undefined
    ? undefined
    : structuredClone(value);
}

function fieldValue() {
  return {
    delete: () => DELETE_FIELD,
    serverTimestamp: () => "server-time",
  };
}

function applyFields(current, fields) {
  const next = { ...(current || {}) };
  for (const [key, value] of Object.entries(fields || {})) {
    if (value === DELETE_FIELD) {
      delete next[key];
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

  startAfter(snapshot) {
    return this.copy({ afterPath: snapshot.ref.path });
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
        return this.filters.every(({ field, operator, value }) =>
          operator === "==" && data[field] === value);
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
      set: (ref, fields, options) => this.write(ref.path, fields, options),
      update: (ref, fields) => this.write(ref.path, fields, { merge: true }),
      delete: (ref) => this.documents.delete(ref.path),
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

function createHarness({ serverOwned = true } = {}) {
  const firestore = new FakeFirestore();
  firestore.seed("account_deletions/source", {
    serverOwned,
    operationId: serverOwned ? "op" : undefined,
    cleanupGyeIds: ["legacy-gye"],
    cleanupRevision: 0,
  });
  const anonymized = [];
  const reconciled = [];
  const orphaned = [];
  const adapters = createDeletionCleanupAdapters({
    firestore,
    fieldValue: fieldValue(),
    documentIdFieldPath: "__name__",
    cleanupGyeForDeletedUser,
    anonymizeGyeIdentity: async (gyeId, uid, nickname) => {
      anonymized.push({ gyeId, uid, nickname });
    },
    reconcileMembershipAfterDeletion: async (gyeId) => {
      reconciled.push(gyeId);
      return "retained";
    },
    cleanupOrphanedGyeTree: async (_gref, gyeId) => {
      orphaned.push(gyeId);
    },
    notificationOutboxBelongsToUid: (data, uid) => data.uid === uid,
    commitDocumentChunks: async (documents, appendMutation) => {
      const batch = firestore.batch();
      documents.forEach((document) => appendMutation(batch, document));
      await batch.commit();
    },
    pageSize: 2,
  });
  return { adapters, anonymized, firestore, orphaned, reconciled };
}

test("community cleanup retains a pre-root legacy Gye target and discovers "
    + "current relationships in bounded pages", async () => {
  const { adapters, anonymized, firestore, reconciled } = createHarness();
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

  const claim = await adapters.cleanupCommunity({
    uid: "source",
    operationId: "op",
  });

  assert.deepEqual(reconciled, ["discovered-gye", "legacy-gye"]);
  assert.deepEqual(
    anonymized.map(({ gyeId, nickname }) => ({ gyeId, nickname })),
    [
      { gyeId: "discovered-gye", nickname: "before-delete" },
      { gyeId: "legacy-gye", nickname: "legacy-member" },
    ],
  );
  assert.deepEqual(claim.gyeIds, ["discovered-gye", "legacy-gye"]);
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

  await adapters.cleanupProcessor({ uid: "source", operationId: "op" });
  await adapters.cleanupProcessor({ uid: "source", operationId: "op" });

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

  await assert.rejects(
    adapters.cleanupProcessor({ uid: "source", operationId: "op" }),
    /transient batch failure/,
  );
  assert.equal(firestore.documents.has("shared_packs/source-pack"), false);
  assert.equal(
    firestore.documents.has("gye/one/processed_packs/source-pack"),
    true,
  );

  await adapters.cleanupProcessor({ uid: "source", operationId: "op" });

  assert.equal(
    Array.from(firestore.documents.keys())
      .some((path) => path.includes("source-pack") ||
        path.endsWith("source-message")),
    false,
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
